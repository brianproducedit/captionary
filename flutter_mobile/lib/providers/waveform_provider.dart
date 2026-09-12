import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/waveform_data.dart';

/// Peaks come from extracted WAV (backend). Until then the timeline is honest
/// about having no audio samples.
final waveformProvider = Provider.family<WaveformData, String>((ref, videoPath) {
  if (videoPath.isEmpty) {
    return WaveformData.noAudio(
      'No media loaded. Timeline uses caption times.',
    );
  }
  return WaveformData.noAudio(
    'Waveform peaks are not extracted yet. Playhead and captions still follow time.',
  );
});
