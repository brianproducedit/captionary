import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/waveform_data.dart';
import '../data/services/waveform_extraction_service.dart';
import 'transcription_provider.dart';

final waveformExtractionServiceProvider = Provider<WaveformExtractionService>((
  ref,
) {
  final audioService = ref.watch(audioExtractionServiceProvider);
  return WaveformExtractionService(audioExtractionService: audioService);
});

class WaveformNotifier extends StateNotifier<WaveformData> {
  final WaveformExtractionService _service;
  final String videoPath;

  WaveformNotifier(this._service, this.videoPath)
    : super(
        videoPath.isEmpty
            ? WaveformData.noAudio(
                'No media loaded. Timeline uses caption times.',
              )
            : WaveformData.loading(),
      ) {
    if (videoPath.isNotEmpty) {
      _load();
    }
  }

  Future<void> _load() async {
    final result = await _service.extractWaveform(videoPath);
    if (mounted) {
      state = result;
    }
  }
}

final waveformProvider =
    StateNotifierProvider.family<WaveformNotifier, WaveformData, String>((
      ref,
      videoPath,
    ) {
      final service = ref.watch(waveformExtractionServiceProvider);
      return WaveformNotifier(service, videoPath);
    });
