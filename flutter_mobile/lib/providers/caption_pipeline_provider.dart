import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/subtitle_segment.dart';
import '../data/services/caption_pipeline.dart';
import 'language_provider.dart';
import 'subtitle_provider.dart';
import 'system_memory_provider.dart';
import 'transcription_provider.dart';

/// Provider for creating or accessing the CaptionPipeline service.
final captionPipelineServiceProvider = Provider<CaptionPipeline>((ref) {
  final audioService = ref.watch(audioExtractionServiceProvider);
  final languageService = ref.watch(languageServiceProvider);
  final transcriptionService = ref.watch(transcriptionServiceProvider);
  final memoryService = ref.watch(systemMemoryServiceProvider);

  final pipeline = CaptionPipeline(
    audioExtractionService: audioService,
    languagePackService: languageService,
    transcriptionService: transcriptionService,
    systemMemoryService: memoryService,
  );

  ref.onDispose(() {
    pipeline.dispose();
  });

  return pipeline;
});

/// Riverpod notifier managing caption pipeline execution and reactive UI state.
class CaptionPipelineNotifier extends Notifier<CaptionPipelineState> {
  CaptionPipeline? _currentPipeline;

  @override
  CaptionPipelineState build() {
    return const CaptionPipelineState();
  }

  /// Runs the full caption pipeline for [videoPath].
  /// On successful completion, automatically updates [subtitleProvider] with the generated segments.
  Future<List<SubtitleSegment>> run({
    required String videoPath,
    required String mediaId,
    String? languageCode,
    bool updateSubtitlesOnSuccess = true,
  }) async {
    final pipeline = CaptionPipeline(
      audioExtractionService: ref.read(audioExtractionServiceProvider),
      languagePackService: ref.read(languageServiceProvider),
      transcriptionService: ref.read(transcriptionServiceProvider),
      systemMemoryService: ref.read(systemMemoryServiceProvider),
      onStateChange: (newState) {
        state = newState;
      },
    );
    _currentPipeline = pipeline;

    try {
      final segments = await pipeline.run(
        videoPath: videoPath,
        mediaId: mediaId,
        languageCode: languageCode,
      );

      if (updateSubtitlesOnSuccess &&
          state.status == CaptionPipelineStatus.ready &&
          segments.isNotEmpty) {
        ref.read(subtitleProvider.notifier).setSegments(segments);
      }

      return segments;
    } finally {
      if (_currentPipeline == pipeline) {
        _currentPipeline = null;
      }
    }
  }

  /// Cancels in-flight pipeline run.
  void cancel() {
    _currentPipeline?.cancel();
    if (state.status != CaptionPipelineStatus.ready &&
        state.status != CaptionPipelineStatus.error) {
      state = state.copyWith(
        status: CaptionPipelineStatus.cancelled,
        currentAction: 'Pipeline cancelled',
      );
    }
  }

  /// Reset state back to idle.
  void reset() {
    cancel();
    state = const CaptionPipelineState();
  }
}

/// Global provider for the active CaptionPipeline notifier and its reactive state.
final captionPipelineProvider =
    NotifierProvider<CaptionPipelineNotifier, CaptionPipelineState>(() {
      return CaptionPipelineNotifier();
    });
