import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock/mock_transcription_service.dart';
import '../data/services/transcription_service.dart';
import '../data/services/audio_preprocessor.dart';

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
  return MockTranscriptionService();
});

final audioPreprocessorProvider = Provider<AudioPreprocessor>((ref) {
  return AudioPreprocessor();
});

class TranscriptionNotifier extends Notifier<TranscriptionState> {
  StreamSubscription? _transcriptionSubscription;
  bool _isAborted = false;

  @override
  TranscriptionState build() {
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

    final preprocessor = ref.read(audioPreprocessorProvider);
    final audioPath = await preprocessor.transcodeToMono(videoPath);

    if (_isAborted) return;

    if (audioPath == null) {
      state = state.copyWith(
        status: TranscriptionStatus.error,
        errorMessage: "Failed to extract audio from video.",
      );
      return;
    }

    state = state.copyWith(
      status: TranscriptionStatus.transcribing,
      progress: 0.0,
      currentAction: "Initializing Whisper Model...",
    );

    final service = ref.read(transcriptionServiceProvider);

    // Simulate some artificial delay for UX and to test abort
    await Future.delayed(const Duration(seconds: 1));
    if (_isAborted) return;

    _transcriptionSubscription = service
        .transcribeAudioStream(
          audioPath: audioPath,
          languageCode: 'en',
          modelPath: 'dummy_model.bin',
        )
        .listen(
          (segment) {
            double currentProgress = state.progress + 0.1;
            if (currentProgress > 0.95) currentProgress = 0.95;
            state = state.copyWith(
              status: TranscriptionStatus.transcribing,
              progress: currentProgress,
              currentAction:
                  "Transcribing (${(currentProgress * 100).toInt()}%)...",
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
