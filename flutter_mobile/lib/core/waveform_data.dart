enum WaveformLoadState { loading, ready, noAudio, error, lowMemory }

/// Peak samples for the studio waveform. Empty peaks must not look like audio.
class WaveformData {
  static const int maxDisplayPeaks = 2000;

  final WaveformLoadState state;
  final List<double> peaks;
  final String message;

  const WaveformData({
    required this.state,
    this.peaks = const [],
    this.message = '',
  });

  factory WaveformData.noAudio([String? message]) {
    return WaveformData(
      state: WaveformLoadState.noAudio,
      message:
          message ??
          'No audio waveform yet. Playhead and captions still follow time.',
    );
  }

  factory WaveformData.loading() {
    return const WaveformData(
      state: WaveformLoadState.loading,
      message: 'Loading waveform…',
    );
  }

  factory WaveformData.error([String? message]) {
    return WaveformData(
      state: WaveformLoadState.error,
      message: message ?? 'Could not load waveform peaks.',
    );
  }

  List<double> get displayPeaks {
    if (peaks.length <= maxDisplayPeaks) return peaks;
    final bucket = peaks.length / maxDisplayPeaks;
    return [
      for (var i = 0; i < maxDisplayPeaks; i++)
        _bucketMax(peaks, (i * bucket).floor(), ((i + 1) * bucket).ceil()),
    ];
  }

  bool get isLowMemoryDownsampled => peaks.length > maxDisplayPeaks;

  static double _bucketMax(List<double> source, int start, int end) {
    var max = 0.0;
    final last = end.clamp(0, source.length);
    final first = start.clamp(0, source.length);
    for (var i = first; i < last; i++) {
      if (source[i] > max) max = source[i];
    }
    return max;
  }
}
