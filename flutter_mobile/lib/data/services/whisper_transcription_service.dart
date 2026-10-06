import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:whisper_flutter_new/whisper_flutter_new.dart';

import '../../core/async_lock.dart';
import '../../core/performance_logger.dart';
import '../../core/whisper_chunker.dart';
import '../../core/whisper_output_parser.dart';
import '../exceptions/language_pack_exceptions.dart';
import '../models/subtitle_segment.dart';
import 'system_memory_service.dart';
import 'transcription_service.dart';

/// Runner abstraction for executing the underlying Whisper model.
/// Enables hermetic unit testing on desktop platforms where native Android/iOS
/// whisper.cpp shared libraries (`libwhisper.so`) are not present.
typedef WhisperEngineRunner = Future<WhisperTranscribeResponse> Function({
  required String audioPath,
  required String modelPath,
  required String languageCode,
  bool? isTranslate,
});

/// Production on-device Whisper transcription service.
/// Features:
/// - Single-model in-memory concurrency lock (prevents OOM on 4 GB devices).
/// - 30s overlapping audio chunking with boundary stitching.
/// - Offline-only execution (`downloadHost: null`).
/// - Clean cleanup in finally blocks.
class WhisperTranscriptionService implements TranscriptionService {
  final WhisperEngineRunner? _customRunner;
  final Future<Directory> Function()? getTempDirectory;
  final SystemMemoryService? systemMemoryService;

  /// Global lock to guarantee only one model runs in memory at any time.
  static final AsyncLock _globalLock = AsyncLock();

  bool _isCancelled = false;

  WhisperTranscriptionService({
    WhisperEngineRunner? runner,
    this.getTempDirectory,
    this.systemMemoryService,
  }) : _customRunner = runner;

  /// Cancel in-flight transcription.
  void cancel() {
    _isCancelled = true;
  }

  @override
  Future<List<SubtitleSegment>> transcribeAudio({
    required String audioPath,
    required String languageCode,
    required String modelPath,
    bool isTranslate = false,
  }) async {
    final List<SubtitleSegment> segments = [];
    await for (final segment in transcribeAudioStream(
      audioPath: audioPath,
      languageCode: languageCode,
      modelPath: modelPath,
      isTranslate: isTranslate,
    )) {
      segments.add(segment);
    }
    return segments;
  }

  @override
  Stream<SubtitleSegment> transcribeAudioStream({
    required String audioPath,
    required String languageCode,
    required String modelPath,
    bool isTranslate = false,
  }) async* {
    _isCancelled = false;

    if (audioPath.trim().isEmpty) {
      throw ArgumentError('Audio path cannot be empty.');
    }

    final audioFile = File(audioPath);
    if (!await audioFile.exists()) {
      throw FileSystemException('Audio file not found.', audioPath);
    }

    if (modelPath.trim().isEmpty) {
      throw ArgumentError('Model path cannot be empty.');
    }

    // 1. Acquire single-model memory lock
    await _globalLock.acquire();

    List<AudioChunk> chunks = [];

    try {
      if (_isCancelled) return;

      // 2. Prepare model file on disk
      final resolvedModelPath = await _resolveModelFile(modelPath);

      // Memory threshold safety guard with RAM delegation before model load
      final memService = systemMemoryService ?? const SystemMemoryService();
      final memInfo = await memService.getMemoryInfo();
      final plan = memService.getDelegationPlan(
        modelNameOrPath: resolvedModelPath,
        memoryInfo: memInfo,
      );

      if (!memService.canRunModelWithDelegation(
        modelNameOrPath: resolvedModelPath,
        memoryInfo: memInfo,
      )) {
        throw LowMemoryException(
          'Available memory (${memInfo.availableRamGb.toStringAsFixed(1)} GB) is below minimum safe threshold for model.',
          availableBytes: memInfo.availableRamBytes,
          requiredBytes: 150 * 1024 * 1024,
        );
      }

      PerformanceLogger.recordCheckpoint(
        'model load',
        metadata: {
          'model': p.basename(resolvedModelPath),
          'availRamMb': (memInfo.availableRamBytes / (1024 * 1024)).round(),
          'delegated': plan.isDelegated,
          'chunkSec': plan.chunkDuration.inSeconds,
          'threads': plan.threadCount,
        },
      );

      // 3. Slice audio into overlapping chunks (respecting RAM delegation chunk size)
      try {
        chunks = await WhisperChunker.chunkAudio(
          audioFile,
          chunkDuration: plan.chunkDuration,
          getTempDirectory: getTempDirectory,
        );
      } catch (e) {
        // Fallback: if chunking fails (e.g. non-canonical header), treat as single chunk
        chunks = [
          AudioChunk(
            file: audioFile,
            timeOffset: Duration.zero,
            duration: const Duration(seconds: 30),
            isTemporary: false,
          ),
        ];
      }

      final List<SubtitleSegment> allAccumulated = [];

      for (int i = 0; i < chunks.length; i++) {
        if (_isCancelled) break;

        final chunk = chunks[i];

        PerformanceLogger.recordCheckpoint(
          'transcribe',
          metadata: {
            'chunk': i + 1,
            'totalChunks': chunks.length,
            'chunkDurationMs': chunk.duration.inMilliseconds,
          },
        );

        final WhisperTranscribeResponse response;

        if (_customRunner != null) {
          response = await _customRunner(
            audioPath: chunk.file.path,
            modelPath: resolvedModelPath,
            languageCode: languageCode,
            isTranslate: isTranslate,
          );
        } else {
          response = await _defaultRunWhisper(
            audioPath: chunk.file.path,
            modelPath: resolvedModelPath,
            languageCode: languageCode,
            isTranslate: isTranslate,
            threadsOverride: plan.threadCount,
          );
        }

        if (plan.aggressiveMemoryCleanup) {
          PerformanceLogger.recordCheckpoint(
            'ram-cleanup',
            metadata: {'chunk': i + 1, 'delegation': true},
          );
        }

        if (_isCancelled) break;

        // Parse response segments
        List<SubtitleSegment> chunkSegments = [];
        final segs = response.segments;
        if (segs != null && segs.isNotEmpty) {
          chunkSegments = WhisperOutputParser.parseSegments(
            segs,
            timeOffset: chunk.timeOffset,
            startIndex: allAccumulated.length,
          );
        } else if (response.text.isNotEmpty) {
          chunkSegments = WhisperOutputParser.parseRawText(
            response.text,
            timeOffset: chunk.timeOffset,
            startIndex: allAccumulated.length,
            fallbackDuration: chunk.duration,
          );
        }

        allAccumulated.addAll(chunkSegments);

        // Merge and re-align segments across chunk boundaries
        final merged = WhisperOutputParser.mergeSegments(allAccumulated);
        allAccumulated
          ..clear()
          ..addAll(merged);

        // Yield any newly formed segments
        for (final seg in chunkSegments) {
          yield seg;
        }
      }
    } finally {
      PerformanceLogger.recordCheckpoint(
        'unload',
        metadata: {'chunksCleaned': chunks.length},
      );
      // Clean up temporary chunks
      if (chunks.isNotEmpty) {
        await WhisperChunker.cleanupChunks(chunks);
      }
      // Release memory lock
      _globalLock.release();
    }
  }

  /// Default production execution using whisper_flutter_new.
  ///
  /// Thread count is dynamically scaled per model size and delegation plan:
  /// - tiny/base: 4 threads (small footprint, parallelism helps)
  /// - small/medium: 6 threads (heavier compute, benefits from more cores)
  /// - large: 4 threads (very heavy, excessive threading causes thrashing)
  /// - under RAM delegation: capped at 2 threads to prevent peak memory thrashing
  Future<WhisperTranscribeResponse> _defaultRunWhisper({
    required String audioPath,
    required String modelPath,
    required String languageCode,
    bool isTranslate = false,
    int? threadsOverride,
  }) async {
    final modelFile = File(modelPath);
    if (!await modelFile.exists() || (await modelFile.length()) == 0) {
      if (await modelFile.exists()) {
        try {
          await modelFile.delete();
        } catch (_) {}
      }
      throw FileSystemException(
        'Whisper model file is empty or missing: $modelPath. Redownload required.',
        modelPath,
      );
    }

    final modelEnum = _resolveModelEnum(modelPath);
    final modelDir = p.dirname(modelPath);

    final whisper = Whisper(
      model: modelEnum,
      modelDir: modelDir,
      downloadHost: null, // Prohibits remote Hugging Face calls
    );

    // Scale thread count to model weight and RAM delegation
    final int threads;
    if (threadsOverride != null) {
      threads = threadsOverride;
    } else {
      switch (modelEnum) {
        case WhisperModel.tiny:
        case WhisperModel.base:
          threads = 4;
          break;
        case WhisperModel.small:
        case WhisperModel.medium:
          threads = 6;
          break;
        default:
          threads = 4; // large models – avoid excessive thread overhead
      }
    }

    final request = TranscribeRequest(
      audio: audioPath,
      language: languageCode.isEmpty ? 'auto' : languageCode,
      isTranslate: isTranslate,
      isNoTimestamps: false,
      splitOnWord: true,
      threads: threads,
    );

    return await whisper.transcribe(transcribeRequest: request);
  }

  Future<String> _ensureExpectedWhisperName(
    File file,
    WhisperModel modelEnum,
  ) async {
    final expectedFileName = 'ggml-${modelEnum.modelName}.bin';
    if (p.basename(file.path) == expectedFileName) {
      return file.path;
    }

    final targetDir = file.parent;
    final targetFile = File('${targetDir.path}/$expectedFileName');
    if (await targetFile.exists()) {
      final len = await targetFile.length();
      if (len > 0) {
        return targetFile.path;
      }
      try {
        await targetFile.delete();
      } catch (_) {}
    }

    try {
      await file.copy(targetFile.path);
      return targetFile.path;
    } catch (_) {
      return file.path;
    }
  }

  /// Resolves the model path and ensures the file exists in the directory format
  /// expected by whisper.cpp (`$dir/ggml-$name.bin`).
  Future<String> _resolveModelFile(String modelPath) async {
    final modelEnum = _resolveModelEnum(modelPath);
    final expectedFileName = 'ggml-${modelEnum.modelName}.bin';

    final originalFile = File(modelPath);
    if (await originalFile.exists()) {
      final len = await originalFile.length();
      if (len > 0) {
        return _ensureExpectedWhisperName(originalFile, modelEnum);
      }
      try {
        await originalFile.delete();
      } catch (_) {}
    }

    // Candidate directories to search for existing models:
    // 1. Injected temp directory (tests)
    // 2. Persistent public Android download directory
    // 3. Application support directory / models
    // 4. Application documents directory / models
    final candidateDirs = <Directory>[];
    if (getTempDirectory != null) {
      try {
        candidateDirs.add(await getTempDirectory!());
      } catch (_) {}
    }
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final dl = await getDownloadsDirectory();
        if (dl != null) {
          candidateDirs.add(Directory(p.join(dl.path, 'Captionary', 'models')));
        }
      } catch (_) {}
      candidateDirs.add(
        Directory('/storage/emulated/0/Download/Captionary/models'),
      );
    }
    try {
      final appSupport = await getApplicationSupportDirectory();
      candidateDirs.add(Directory(p.join(appSupport.path, 'models')));
      candidateDirs.add(appSupport);
    } catch (_) {}
    try {
      final appDocs = await getApplicationDocumentsDirectory();
      candidateDirs.add(Directory(p.join(appDocs.path, 'models')));
      candidateDirs.add(appDocs);
    } catch (_) {}

    final filename = p.basename(modelPath);
    for (final cDir in candidateDirs) {
      if (!await cDir.exists()) continue;

      // 1. Direct filename match
      final candidate = File(p.join(cDir.path, filename));
      if (await candidate.exists()) {
        final len = await candidate.length();
        if (len > 0) {
          return _ensureExpectedWhisperName(candidate, modelEnum);
        }
        try {
          await candidate.delete();
        } catch (_) {}
      }

      // 2. Expected whisper filename match (e.g. ggml-tiny.bin)
      final expectedCandidate = File(p.join(cDir.path, expectedFileName));
      if (await expectedCandidate.exists()) {
        final len = await expectedCandidate.length();
        if (len > 0) {
          return expectedCandidate.path;
        }
        try {
          await expectedCandidate.delete();
        } catch (_) {}
      }
    }

    throw FileSystemException(
      'Whisper model file not found on device.',
      modelPath,
    );
  }

  static WhisperModel _resolveModelEnum(String modelPath) {
    final lower = modelPath.toLowerCase();
    if (lower.contains('tiny')) return WhisperModel.tiny;
    if (lower.contains('base')) return WhisperModel.base;
    if (lower.contains('small')) return WhisperModel.small;
    if (lower.contains('medium')) return WhisperModel.medium;
    if (lower.contains('large-v2') || lower.contains('large_v2')) {
      return WhisperModel.largeV2;
    }
    if (lower.contains('large')) return WhisperModel.largeV1;
    return WhisperModel.base;
  }
}
