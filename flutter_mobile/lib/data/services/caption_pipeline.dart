import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../../core/performance_logger.dart';
import '../../core/whisper_output_parser.dart';
import '../models/download_progress.dart';
import '../models/language_pack.dart';
import '../models/subtitle_segment.dart';
import 'audio_extraction_service.dart';
import 'language_pack_service.dart';
import 'system_memory_service.dart';
import 'transcription_service.dart';
import 'whisper_transcription_service.dart';

/// Typed status states of the caption pipeline.
enum CaptionPipelineStatus {
  idle,
  importing,
  extracting,
  detecting,
  checkingModel,
  downloadingModel,
  transcribing,
  merging,
  ready,
  error,
  cancelled,
}

/// Thrown when a caption pipeline is attempted on a media ID that is already executing.
class CaptionPipelineConflictException implements Exception {
  final String mediaId;

  const CaptionPipelineConflictException(this.mediaId);

  @override
  String toString() =>
      'CaptionPipeline is already running for mediaId: $mediaId';
}

/// Immutable state representation for the caption pipeline.
@immutable
class CaptionPipelineState {
  final CaptionPipelineStatus status;
  final double progress; // 0.0 to 1.0
  final String? currentAction;
  final String? errorMessage;
  final List<SubtitleSegment> segments;
  final String? detectedLanguage;
  final DownloadProgress? downloadProgress;
  final String? mediaId;
  final String? videoPath;

  const CaptionPipelineState({
    this.status = CaptionPipelineStatus.idle,
    this.progress = 0.0,
    this.currentAction,
    this.errorMessage,
    this.segments = const [],
    this.detectedLanguage,
    this.downloadProgress,
    this.mediaId,
    this.videoPath,
  });

  CaptionPipelineState copyWith({
    CaptionPipelineStatus? status,
    double? progress,
    String? currentAction,
    String? errorMessage,
    List<SubtitleSegment>? segments,
    String? detectedLanguage,
    DownloadProgress? downloadProgress,
    String? mediaId,
    String? videoPath,
  }) {
    return CaptionPipelineState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      currentAction: currentAction ?? this.currentAction,
      errorMessage: errorMessage ?? this.errorMessage,
      segments: segments ?? this.segments,
      detectedLanguage: detectedLanguage ?? this.detectedLanguage,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      mediaId: mediaId ?? this.mediaId,
      videoPath: videoPath ?? this.videoPath,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CaptionPipelineState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          progress == other.progress &&
          currentAction == other.currentAction &&
          errorMessage == other.errorMessage &&
          detectedLanguage == other.detectedLanguage &&
          mediaId == other.mediaId;

  @override
  int get hashCode => Object.hash(
    status,
    progress,
    currentAction,
    errorMessage,
    detectedLanguage,
    mediaId,
  );
}

/// Orchestrates the end-to-end pipeline:
/// import -> extract audio -> detect language -> check model -> download model (if missing)
/// -> transcribe audio -> merge subtitles -> ready.
class CaptionPipeline {
  final AudioExtractionService audioExtractionService;
  final LanguagePackService languagePackService;
  final TranscriptionService transcriptionService;
  final void Function(CaptionPipelineState state)? onStateChange;

  /// Concurrency lock: guarantees strictly one run per mediaId.
  static final Set<String> _activeMediaIds = {};

  CaptionPipelineState _state = const CaptionPipelineState();
  CaptionPipelineState get state => _state;

  final StreamController<CaptionPipelineState> _stateController =
      StreamController<CaptionPipelineState>.broadcast();
  Stream<CaptionPipelineState> get stateStream => _stateController.stream;

  bool _isCancelled = false;
  StreamSubscription<DownloadProgress>? _downloadSub;
  StreamSubscription<SubtitleSegment>? _transcriptionSub;
  Completer<void>? _downloadCompleter;
  Completer<List<SubtitleSegment>>? _transcriptionCompleter;
  String? _currentTempAudioPath;
  final List<String> _tempOutputPaths = [];

  final SystemMemoryService? systemMemoryService;

  CaptionPipeline({
    required this.audioExtractionService,
    required this.languagePackService,
    required this.transcriptionService,
    this.systemMemoryService,
    this.onStateChange,
  });

  /// Check whether a pipeline is currently executing for [mediaId].
  static bool isRunningFor(String mediaId) => _activeMediaIds.contains(mediaId);

  /// Test helper to clear lock state.
  @visibleForTesting
  static void clearActiveMediaIds() => _activeMediaIds.clear();

  void _emit(CaptionPipelineState newState) {
    _state = newState;
    if (!_stateController.isClosed) {
      _stateController.add(newState);
    }
    onStateChange?.call(newState);
  }

  /// Request pipeline cancellation. Immediately signals all underlying services.
  void cancel() {
    _isCancelled = true;
    audioExtractionService.cancel();
    _downloadSub?.cancel();
    final ts = transcriptionService;
    if (ts is WhisperTranscriptionService) {
      ts.cancel();
    } else {
      try {
        (ts as dynamic).cancel();
      } catch (_) {}
    }
    _transcriptionSub?.cancel();
    if (_downloadCompleter != null && !_downloadCompleter!.isCompleted) {
      _downloadCompleter!.complete();
    }
    if (_transcriptionCompleter != null &&
        !_transcriptionCompleter!.isCompleted) {
      _transcriptionCompleter!.complete([]);
    }
    _emit(
      _state.copyWith(
        status: CaptionPipelineStatus.cancelled,
        currentAction: 'Pipeline cancelled',
      ),
    );
  }

  /// Execute the pipeline for [videoPath] and [mediaId].
  Future<List<SubtitleSegment>> run({
    required String videoPath,
    required String mediaId,
    String? languageCode,
  }) async {
    if (_activeMediaIds.contains(mediaId)) {
      throw CaptionPipelineConflictException(mediaId);
    }
    _activeMediaIds.add(mediaId);
    _isCancelled = false;
    _currentTempAudioPath = null;
    _tempOutputPaths.clear();

    PerformanceLogger.recordCheckpoint(
      'import',
      metadata: {'mediaId': mediaId, 'video': p.basename(videoPath)},
    );

    try {
      // 1. Idle -> Importing
      _emit(
        CaptionPipelineState(
          status: CaptionPipelineStatus.importing,
          progress: 0.05,
          currentAction: 'Importing media...',
          mediaId: mediaId,
          videoPath: videoPath,
        ),
      );

      if (videoPath.trim().isEmpty) {
        throw ArgumentError('Video path cannot be empty.');
      }

      final videoFile = File(videoPath);
      if (!await videoFile.exists()) {
        throw FileSystemException('Video file does not exist', videoPath);
      }

      if (_isCancelled) {
        _emit(_state.copyWith(status: CaptionPipelineStatus.cancelled));
        return [];
      }

      // 2. Extracting Audio (mono 16kHz WAV)
      _emit(
        _state.copyWith(
          status: CaptionPipelineStatus.extracting,
          progress: 0.15,
          currentAction: 'Extracting audio (mono 16kHz)...',
        ),
      );

      final audioPath = await audioExtractionService.extractAudio(videoPath);
      if (audioPath != null) {
        _currentTempAudioPath = audioPath;
      }

      if (_isCancelled) {
        _emit(_state.copyWith(status: CaptionPipelineStatus.cancelled));
        return [];
      }

      if (audioPath == null || !await File(audioPath).exists()) {
        throw StateError(
          'Audio extraction failed: extracted audio file not found or unsupported.',
        );
      }

      // 3. Detecting Language
      _emit(
        _state.copyWith(
          status: CaptionPipelineStatus.detecting,
          progress: 0.30,
          currentAction: 'Detecting language...',
        ),
      );

      String targetLang =
          (languageCode != null &&
              languageCode.isNotEmpty &&
              languageCode != 'auto')
          ? languageCode
          : '';

      if (targetLang.isEmpty) {
        try {
          final detected = await languagePackService.detectLanguage(audioPath);
          if (detected.isNotEmpty) {
            targetLang = detected;
          }
        } catch (e) {
          debugPrint('Language detection error, falling back: $e');
        }
      }

      if (targetLang.isEmpty) {
        final active = await languagePackService.getActiveLanguage();
        targetLang = active.code;
      }

      if (_isCancelled) {
        _emit(_state.copyWith(status: CaptionPipelineStatus.cancelled));
        return [];
      }

      _emit(
        _state.copyWith(
          detectedLanguage: targetLang,
          progress: 0.40,
          currentAction: 'Language resolved: $targetLang',
        ),
      );

      // 4. Checking Model
      _emit(
        _state.copyWith(
          status: CaptionPipelineStatus.checkingModel,
          progress: 0.45,
          currentAction: 'Checking model availability...',
        ),
      );

      final availableLangs = await languagePackService.getAvailableLanguages();
      LanguagePack? targetPack = availableLangs.firstWhere(
        (p) => p.code == targetLang,
        orElse: () => availableLangs.firstWhere(
          (p) => p.code == 'en',
          orElse: () => availableLangs.first,
        ),
      );

      // Memory threshold safety guard before model download / load
      final memService = systemMemoryService ?? const SystemMemoryService();
      final memInfo = await memService.getMemoryInfo();
      if (!memService.canSafelyRunModel(
        modelNameOrPath: targetPack.modelFile,
        memoryInfo: memInfo,
      )) {
        final availMb = (memInfo.availableRamBytes / (1024 * 1024)).round();
        _emit(
          _state.copyWith(
            status: CaptionPipelineStatus.error,
            errorMessage:
                'Device memory too low (< ${availMb}MB available). Please close background apps before transcribing.',
            currentAction: 'Memory check failed',
          ),
        );
        return [];
      }

      bool isModelInstalled = false;
      if (targetPack.status == LanguagePackStatus.installed ||
          targetPack.status == LanguagePackStatus.bundled) {
        final modelFile = File(targetPack.modelFile);
        if (await modelFile.exists() && (await modelFile.length()) > 0) {
          isModelInstalled = true;
        }
      }

      // 5. Downloading Model (if not installed)
      if (!isModelInstalled) {
        _emit(
          _state.copyWith(
            status: CaptionPipelineStatus.downloadingModel,
            progress: 0.50,
            currentAction: 'Downloading language model (${targetPack.code})...',
          ),
        );

        final downloadStream = languagePackService.downloadLanguagePack(
          targetPack.code,
        );
        final downloadCompleter = Completer<void>();
        _downloadCompleter = downloadCompleter;

        _downloadSub = downloadStream.listen(
          (progress) {
            if (_isCancelled) {
              _downloadSub?.cancel();
              if (!downloadCompleter.isCompleted) {
                downloadCompleter.complete();
              }
              return;
            }

            final pct = progress.totalBytes > 0
                ? progress.downloadedBytes / progress.totalBytes
                : 0.0;
            final overallProgress = 0.50 + (pct * 0.20); // 0.50 -> 0.70

            _emit(
              _state.copyWith(
                status: CaptionPipelineStatus.downloadingModel,
                progress: overallProgress,
                downloadProgress: progress,
                currentAction: progress.state == DownloadState.verifying
                    ? 'Verifying model checksum...'
                    : 'Downloading model (${(pct * 100).toStringAsFixed(0)}%)...',
              ),
            );

            if (progress.state == DownloadState.complete) {
              if (!downloadCompleter.isCompleted) {
                downloadCompleter.complete();
              }
            } else if (progress.state == DownloadState.error) {
              if (!downloadCompleter.isCompleted) {
                downloadCompleter.completeError(
                  StateError(
                    'Model download failed for ${progress.languageCode}',
                  ),
                );
              }
            }
          },
          onError: (err) {
            if (!downloadCompleter.isCompleted) {
              downloadCompleter.completeError(err);
            }
          },
          onDone: () {
            if (!downloadCompleter.isCompleted) {
              downloadCompleter.complete();
            }
          },
        );

        await downloadCompleter.future;

        if (_isCancelled) {
          _emit(_state.copyWith(status: CaptionPipelineStatus.cancelled));
          return [];
        }

        // Refresh pack reference after download
        final refreshedLangs = await languagePackService
            .getAvailableLanguages();
        targetPack = refreshedLangs.firstWhere(
          (p) => p.code == targetPack!.code,
          orElse: () => targetPack!,
        );
      }

      if (_isCancelled) {
        _emit(_state.copyWith(status: CaptionPipelineStatus.cancelled));
        return [];
      }

      // 6. Transcribing Audio
      _emit(
        _state.copyWith(
          status: CaptionPipelineStatus.transcribing,
          progress: 0.70,
          currentAction: 'Transcribing audio with Whisper...',
        ),
      );

      final accumulatedSegments = <SubtitleSegment>[];
      final transcriptionCompleter = Completer<List<SubtitleSegment>>();
      _transcriptionCompleter = transcriptionCompleter;

      final stream = transcriptionService.transcribeAudioStream(
        audioPath: audioPath,
        languageCode: targetLang,
        modelPath: targetPack.modelFile,
      );

      _transcriptionSub = stream.listen(
        (segment) {
          if (_isCancelled) return;
          accumulatedSegments.add(segment);
          final segProgress =
              0.70 +
              (0.20 *
                  (accumulatedSegments.length /
                      (accumulatedSegments.length + 5)));
          _emit(
            _state.copyWith(
              progress: segProgress,
              currentAction:
                  'Transcribing: ${accumulatedSegments.length} segments...',
            ),
          );
        },
        onError: (err) {
          if (!transcriptionCompleter.isCompleted) {
            transcriptionCompleter.completeError(err);
          }
        },
        onDone: () {
          if (!transcriptionCompleter.isCompleted) {
            transcriptionCompleter.complete(accumulatedSegments);
          }
        },
      );

      final rawSegments = await transcriptionCompleter.future;

      if (_isCancelled) {
        _emit(_state.copyWith(status: CaptionPipelineStatus.cancelled));
        return [];
      }

      // 7. Merging and Normalizing
      _emit(
        _state.copyWith(
          status: CaptionPipelineStatus.merging,
          progress: 0.95,
          currentAction: 'Merging and ordering subtitles...',
        ),
      );

      final mergedSegments = WhisperOutputParser.mergeSegments(rawSegments);

      // 8. Ready
      _emit(
        _state.copyWith(
          status: CaptionPipelineStatus.ready,
          progress: 1.0,
          currentAction: 'Transcription complete',
          segments: mergedSegments,
        ),
      );

      return mergedSegments;
    } catch (e) {
      if (_isCancelled) {
        _emit(
          _state.copyWith(
            status: CaptionPipelineStatus.cancelled,
            currentAction: 'Pipeline cancelled',
          ),
        );
        return [];
      }
      _emit(
        _state.copyWith(
          status: CaptionPipelineStatus.error,
          errorMessage: e.toString(),
          currentAction: 'Transcription failed',
        ),
      );
      rethrow;
    } finally {
      // 3. finally deletes temp audio / failed outputs
      if (_currentTempAudioPath != null) {
        try {
          final f = File(_currentTempAudioPath!);
          if (await f.exists()) {
            await f.delete();
          }
        } catch (err) {
          debugPrint('CaptionPipeline temp audio cleanup error: $err');
        }
        _currentTempAudioPath = null;
      }

      if (_state.status == CaptionPipelineStatus.error ||
          _state.status == CaptionPipelineStatus.cancelled) {
        for (final outPath in _tempOutputPaths) {
          try {
            final f = File(outPath);
            if (await f.exists()) {
              await f.delete();
            }
          } catch (_) {}
        }
        _tempOutputPaths.clear();
      }

      _activeMediaIds.remove(mediaId);
    }
  }

  void dispose() {
    cancel();
    _stateController.close();
  }
}
