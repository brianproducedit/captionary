import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:whisper_flutter_new/whisper_flutter_new.dart';

import '../../core/whisper_chunker.dart';
import '../../core/whisper_output_parser.dart';
import '../models/subtitle_segment.dart';
import 'transcription_service.dart';

/// Runner abstraction for executing the underlying Whisper model.
/// Enables hermetic unit testing on desktop platforms where native Android/iOS
/// whisper.cpp shared libraries (`libwhisper.so`) are not present.
typedef WhisperEngineRunner = Future<WhisperTranscribeResponse> Function({
  required String audioPath,
  required String modelPath,
  required String languageCode,
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

  /// Global lock to guarantee only one model runs in memory at any time.
  static final _AsyncLock _globalLock = _AsyncLock();

  bool _isCancelled = false;

  WhisperTranscriptionService({
    WhisperEngineRunner? runner,
    this.getTempDirectory,
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
  }) async {
    final List<SubtitleSegment> segments = [];
    await for (final segment in transcribeAudioStream(
      audioPath: audioPath,
      languageCode: languageCode,
      modelPath: modelPath,
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

      // 3. Slice audio into 30s overlapping chunks if necessary
      try {
        chunks = await WhisperChunker.chunkAudio(
          audioFile,
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
        final WhisperTranscribeResponse response;

        if (_customRunner != null) {
          response = await _customRunner(
            audioPath: chunk.file.path,
            modelPath: resolvedModelPath,
            languageCode: languageCode,
          );
        } else {
          response = await _defaultRunWhisper(
            audioPath: chunk.file.path,
            modelPath: resolvedModelPath,
            languageCode: languageCode,
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
      // Clean up temporary chunks
      if (chunks.isNotEmpty) {
        await WhisperChunker.cleanupChunks(chunks);
      }
      // Release memory lock
      _globalLock.release();
    }
  }

  /// Default production execution using whisper_flutter_new
  Future<WhisperTranscribeResponse> _defaultRunWhisper({
    required String audioPath,
    required String modelPath,
    required String languageCode,
  }) async {
    final modelEnum = _resolveModelEnum(modelPath);
    final modelDir = p.dirname(modelPath);

    final whisper = Whisper(
      model: modelEnum,
      modelDir: modelDir,
      downloadHost: null, // Prohibits remote Hugging Face calls
    );

    final request = TranscribeRequest(
      audio: audioPath,
      language: languageCode.isEmpty ? 'auto' : languageCode,
      isNoTimestamps: false,
      splitOnWord: false,
      threads: 4,
    );

    return await whisper.transcribe(transcribeRequest: request);
  }

  /// Resolves the model path and ensures the file exists in the directory format
  /// expected by whisper.cpp (`$dir/ggml-$name.bin`).
  Future<String> _resolveModelFile(String modelPath) async {
    final originalFile = File(modelPath);
    if (await originalFile.exists()) {
      final modelEnum = _resolveModelEnum(modelPath);
      final expectedFileName = 'ggml-${modelEnum.modelName}.bin';

      if (p.basename(modelPath) == expectedFileName) {
        return originalFile.path;
      }

      // Copy/link to expected file name in the same directory or temp directory
      final targetDir = originalFile.parent;
      final targetFile = File('${targetDir.path}/$expectedFileName');
      if (!await targetFile.exists()) {
        try {
          await originalFile.copy(targetFile.path);
          return targetFile.path;
        } catch (_) {
          return originalFile.path;
        }
      }
      return targetFile.path;
    }

    // If model file is missing, check if it exists in app support directory
    Directory appSupport;
    if (getTempDirectory != null) {
      appSupport = await getTempDirectory!();
    } else {
      try {
        appSupport = await getApplicationSupportDirectory();
      } catch (_) {
        appSupport = Directory.systemTemp;
      }
    }

    final candidate = File('${appSupport.path}/${p.basename(modelPath)}');
    if (await candidate.exists()) {
      return candidate.path;
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

/// Simple asynchronous Mutex lock to enforce single-model execution.
class _AsyncLock {
  Completer<void>? _lock;

  Future<void> acquire() async {
    while (_lock != null) {
      await _lock!.future;
    }
    _lock = Completer<void>();
  }

  void release() {
    if (_lock != null && !_lock!.isCompleted) {
      final lockToRelease = _lock!;
      _lock = null;
      lockToRelease.complete();
    }
  }
}
