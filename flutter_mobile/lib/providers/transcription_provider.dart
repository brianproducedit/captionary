import 'dart:async';
import 'package:path/path.dart' as p;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock/mock_audio_extraction_service.dart';
import '../data/mock/mock_transcription_service.dart';
import '../data/services/audio_extraction_service.dart';
import '../data/services/audio_preprocessor.dart';
import '../data/services/caption_pipeline.dart';
import '../data/services/transcription_service.dart';
import 'backend_mode_provider.dart';
import 'language_provider.dart';
import 'subtitle_provider.dart';

import '../data/services/whisper_transcription_service.dart';

enum TranscriptionStatus { idle, extractingAudio, transcribing, success, error }

class TranscriptionState {
  final TranscriptionStatus status;
  final double progress; // 0.0 to 1.0
  final String? errorMessage;
  final String? currentAction;

  const TranscriptionState({
    this.status = TranscriptionStatus.idle,
    this.progress = 0.0,
    this.errorMessage,
    this.currentAction,
  });

  TranscriptionState copyWith({
    TranscriptionStatus? status,
    double? progress,
    String? errorMessage,
    String? currentAction,
  }) {
    return TranscriptionState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      errorMessage:
          errorMessage, // We allow clearing error message by just passing it
      currentAction: currentAction ?? this.currentAction,
    );
  }
}

final transcriptionServiceProvider = Provider<TranscriptionService>((ref) {
  final mode = ref.watch(backendModeProvider);
  switch (mode) {
    case BackendMode.mock:
      return MockTranscriptionService();
    case BackendMode.local:
    case BackendMode.real:
      return WhisperTranscriptionService();
  }
});

final audioExtractionServiceProvider = Provider<AudioExtractionService>((ref) {
  final mode = ref.watch(backendModeProvider);
  switch (mode) {
    case BackendMode.mock:
      return MockAudioExtractionService();
    case BackendMode.local:
    case BackendMode.real:
      return AudioPreprocessor();
  }
});

/// Backwards-compatible provider alias for AudioPreprocessor.
final audioPreprocessorProvider = Provider<AudioExtractionService>((ref) {
  return ref.watch(audioExtractionServiceProvider);
});

class TranscriptionNotifier extends Notifier<TranscriptionState> {
  CaptionPipeline? _activePipeline;

  @override
  TranscriptionState build() {
    ref.onDispose(() {
      _activePipeline?.cancel();
    });
    return const TranscriptionState();
  }

  Future<void> startTranscription(String videoPath, {String? mediaId}) async {
    final effectiveMediaId = mediaId ?? p.basenameWithoutExtension(videoPath);
    state = state.copyWith(
      status: TranscriptionStatus.extractingAudio,
      progress: 0.0,
      currentAction: "Importing Media...",
      errorMessage: null,
    );

    final pipeline = CaptionPipeline(
      audioExtractionService: ref.read(audioExtractionServiceProvider),
      languagePackService: ref.read(languageServiceProvider),
      transcriptionService: ref.read(transcriptionServiceProvider),
      onStateChange: (pipelineState) {
        switch (pipelineState.status) {
          case CaptionPipelineStatus.idle:
            state = const TranscriptionState();
            break;
          case CaptionPipelineStatus.importing:
          case CaptionPipelineStatus.extracting:
            state = state.copyWith(
              status: TranscriptionStatus.extractingAudio,
              progress: pipelineState.progress,
              currentAction: pipelineState.currentAction,
            );
            break;
          case CaptionPipelineStatus.detecting:
          case CaptionPipelineStatus.checkingModel:
          case CaptionPipelineStatus.downloadingModel:
          case CaptionPipelineStatus.transcribing:
          case CaptionPipelineStatus.merging:
            state = state.copyWith(
              status: TranscriptionStatus.transcribing,
              progress: pipelineState.progress,
              currentAction: pipelineState.currentAction,
            );
            break;
          case CaptionPipelineStatus.ready:
            state = state.copyWith(
              status: TranscriptionStatus.success,
              progress: 1.0,
              currentAction: "Transcription Complete",
            );
            break;
          case CaptionPipelineStatus.error:
            state = state.copyWith(
              status: TranscriptionStatus.error,
              errorMessage: pipelineState.errorMessage,
            );
            break;
          case CaptionPipelineStatus.cancelled:
            state = const TranscriptionState();
            break;
        }
      },
    );

    _activePipeline = pipeline;

    try {
      final segments = await pipeline.run(
        videoPath: videoPath,
        mediaId: effectiveMediaId,
      );

      if (segments.isNotEmpty) {
        ref.read(subtitleProvider.notifier).setSegments(segments);
      }
    } catch (e) {
      if (state.status != TranscriptionStatus.error) {
        state = state.copyWith(
          status: TranscriptionStatus.error,
          errorMessage: e.toString(),
        );
      }
    } finally {
      if (_activePipeline == pipeline) {
        _activePipeline = null;
      }
    }
  }

  void abortTranscription() {
    _activePipeline?.cancel();
    _activePipeline = null;
    state = const TranscriptionState();
  }

  void retryTranscription(String videoPath) {
    startTranscription(videoPath);
  }

  void simulateError() {
    _activePipeline?.cancel();
    _activePipeline = null;
    state = state.copyWith(
      status: TranscriptionStatus.error,
      errorMessage: "Simulated transcription engine failure.",
    );
  }
}

final transcriptionProvider =
    NotifierProvider<TranscriptionNotifier, TranscriptionState>(() {
      return TranscriptionNotifier();
    });
