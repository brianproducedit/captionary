import '../data/models/subtitle_segment.dart';

/// Converts between caption time and timeline pixels.
class TimelineMapping {
  static const double defaultPixelsPerSecond = 40;
  static const double minPixelsPerSecond = 16;
  static const double maxPixelsPerSecond = 220;
  static const Duration snapStep = Duration(milliseconds: 100);

  final double pixelsPerSecond;
  final Duration duration;
  final bool snapEnabled;

  const TimelineMapping({
    required this.pixelsPerSecond,
    required this.duration,
    this.snapEnabled = false,
  });

  double get totalWidth {
    final width = timeToX(duration);
    return width < 1 ? 1 : width;
  }

  double timeToX(Duration time) {
    return time.inMilliseconds / 1000.0 * pixelsPerSecond;
  }

  Duration xToTime(double x) {
    final ms = (x / pixelsPerSecond * 1000).round();
    return Duration(milliseconds: ms);
  }

  Duration clampTime(Duration time) {
    if (time.isNegative) return Duration.zero;
    if (duration > Duration.zero && time > duration) return duration;
    return time;
  }

  Duration snap(Duration time) {
    final clamped = clampTime(time);
    if (!snapEnabled) return clamped;
    final step = snapStep.inMilliseconds;
    final snapped = ((clamped.inMilliseconds / step).round() * step).clamp(
      0,
      duration.inMilliseconds,
    );
    return Duration(milliseconds: snapped);
  }

  static double clampZoom(double pixelsPerSecond) {
    return pixelsPerSecond.clamp(minPixelsPerSecond, maxPixelsPerSecond);
  }

  static Duration mediaDuration({
    required Duration playerDuration,
    required List<SubtitleSegment> segments,
    Duration position = Duration.zero,
  }) {
    if (playerDuration > Duration.zero && playerDuration >= position) {
      return playerDuration;
    }
    var maxTime = playerDuration > position ? playerDuration : position;
    for (final segment in segments) {
      if (segment.endTime > maxTime) maxTime = segment.endTime;
    }
    if (maxTime > Duration.zero) {
      return maxTime + const Duration(seconds: 1);
    }
    if (segments.isEmpty) return const Duration(seconds: 15);
    return const Duration(seconds: 15);
  }
}
