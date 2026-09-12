import 'package:flutter_test/flutter_test.dart';
import 'package:captionary/core/timeline_mapping.dart';
import 'package:captionary/data/models/subtitle_segment.dart';

void main() {
  const mapping = TimelineMapping(
    pixelsPerSecond: 40,
    duration: Duration(seconds: 10),
  );

  test('maps time to x and back', () {
    expect(mapping.timeToX(const Duration(seconds: 2)), 80);
    expect(mapping.xToTime(80), const Duration(seconds: 2));
  });

  test('clamps and snaps to 100ms', () {
    const snapping = TimelineMapping(
      pixelsPerSecond: 40,
      duration: Duration(seconds: 10),
      snapEnabled: true,
    );
    expect(snapping.clampTime(const Duration(seconds: 99)), const Duration(seconds: 10));
    expect(
      snapping.snap(const Duration(milliseconds: 140)),
      const Duration(milliseconds: 100),
    );
  });

  test('media duration falls back to last caption', () {
    final duration = TimelineMapping.mediaDuration(
      playerDuration: Duration.zero,
      segments: [
        SubtitleSegment(
          index: 1,
          startTime: Duration.zero,
          endTime: const Duration(seconds: 4),
          text: 'Hi',
          isSelected: false,
        ),
      ],
    );
    expect(duration, const Duration(seconds: 5));
  });
}
