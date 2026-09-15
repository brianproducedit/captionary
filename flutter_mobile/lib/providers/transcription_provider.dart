import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock/mock_audio_extraction_service.dart';
import '../data/mock/mock_transcription_service.dart';
import '../data/services/audio_extraction_service.dart';
import '../data/services/audio_preprocessor.dart';
import '../data/services/transcription_service.dart';
import 'backend_mode_provider.dart';
import 'language_provider.dart';

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
  StreamSubscription? _transcriptionSubscription;
  bool _isAborted = false;

  @override
  TranscriptionState build() {
    ref.onDispose(() {
      _transcriptionSubscription?.cancel();
      ref.read(audioExtractionServiceProvider).cancel();
    });
    return const TranscriptionState();
  }

  Future<void> startTranscription(String videoPath) async {
    _isAborted = false;
    state = state.copyWith(
      status: TranscriptionStatus.extractingAudio,
      progress: 0.0,
      currentAction: "Extracting Audio (Mono 16kHz)...",
      errorMessage: null,
    );

    final extractor = ref.read(audioExtractionServiceProvider);
    final audioPath = await extractor.extractAudio(videoPath);

    if (_isAborted) return;

    if (audioPath == null) {
      state = state.copyWith(
        status: TranscriptionStatus.error,
        errorMessage:
            "Could not extract audio. The video may contain no audio track or is unsupported.",
      );
      return;
    }

    state = state.copyWith(
      status: TranscriptionStatus.transcribing,
      progress: 0.0,
      currentAction: "Transcribing with Whisper...",
    );

    final service = ref.read(transcriptionServiceProvider);
    final activeLang = await ref.read(activeLanguageProvider.future);

    _transcriptionSubscription = service
        .transcribeAudioStream(
          audioPath: audioPath,
          modelPath: activeLang.modelFile,
          languageCode: activeLang.code,
        )
        .listen(
          (segment) {
            if (_isAborted) return;

            state = state.copyWith(
              currentAction: "Transcribing...",
            );
          },
          onError: (e) {
            state = state.copyWith(
              status: TranscriptionStatus.error,
              errorMessage: e.toString(),
            );
          },
          onDone: () {
            if (!_isAborted && state.status != TranscriptionStatus.error) {
              state = state.copyWith(
                status: TranscriptionStatus.success,
                progress: 1.0,
                currentAction: "Transcription Complete",
              );
            }
          },
        );
  }

  void abortTranscription() {
    _isAborted = true;
    _transcriptionSubscription?.cancel();
    ref.read(audioExtractionServiceProvider).cancel();
    final service = ref.read(transcriptionServiceProvider);
    if (service is WhisperTranscriptionService) {
      service.cancel();
    }
    state = const TranscriptionState();
  }

  void retryTranscription(String videoPath) {
    startTranscription(videoPath);
  }

  void simulateError() {
    _transcriptionSubscription?.cancel();
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
