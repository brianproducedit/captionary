import 'package:flutter_test/flutter_test.dart';
import 'package:captionary/core/subtitle_timeline.dart';
import 'package:captionary/data/models/subtitle_segment.dart';
import 'package:captionary/providers/subtitle_provider.dart';

SubtitleSegment _seg({
  required int index,
  required int startMs,
  required int endMs,
  String text = 't',
  bool selected = false,
}) {
  return SubtitleSegment(
    index: index,
    startTime: Duration(milliseconds: startMs),
    endTime: Duration(milliseconds: endMs),
    text: text,
    isSelected: selected,
  );
}

void main() {
  final base = [
    _seg(index: 1, startMs: 0, endMs: 1000, text: 'One two three four'),
    _seg(index: 2, startMs: 1500, endMs: 2500, text: 'Next', selected: true),
    _seg(index: 3, startMs: 3000, endMs: 4000, text: 'Last'),
  ];

  test('move keeps duration and will not overlap neighbors', () {
    final moved = SubtitleTimeline.move(
      base,
      1,
      delta: const Duration(milliseconds: 800),
    );
    expect(moved.first.startTime, const Duration(milliseconds: 500));
    expect(moved.first.endTime, const Duration(milliseconds: 1500));
  });

  test('trim enforces min duration', () {
    final trimmed = SubtitleTimeline.trimStart(
      base,
      1,
      const Duration(milliseconds: 950),
    );
    expect(
      trimmed.first.endTime - trimmed.first.startTime,
      SubtitleTimeline.minDuration,
    );
  });

  test('splitAt splits words and times', () {
    final split = SubtitleTimeline.splitAt(
      base,
      1,
      const Duration(milliseconds: 500),
    );
    expect(split.length, 4);
    expect(split[0].text, 'One two');
    expect(split[1].text, 'three four');
    expect(split[1].startTime, const Duration(milliseconds: 500));
  });

  test('mergeWithNext joins text and span', () {
    final merged = SubtitleTimeline.mergeWithNext(base, 2);
    expect(merged.length, 2);
    expect(merged.last.text, 'Next Last');
    expect(merged.last.endTime, const Duration(milliseconds: 4000));
  });

  test('duplicate uses the following gap', () {
    final dup = SubtitleTimeline.duplicate(base, 1);
    expect(dup.length, 4);
    expect(dup[1].startTime, const Duration(milliseconds: 1000));
    expect(dup[1].endTime, const Duration(milliseconds: 1500));
  });

  test('delete reindexes remaining captions', () {
    final next = SubtitleTimeline.delete(base, 2);
    expect(next.length, 2);
    expect(next.map((s) => s.index).toList(), [1, 2]);
  });

  test('notifier undo restores prior times', () {
    final notifier = SubtitleNotifier(base);
    notifier.checkpoint();
    notifier.moveSegment(1, const Duration(milliseconds: 200));
    expect(notifier.state.first.startTime, const Duration(milliseconds: 200));
    notifier.undo();
    expect(notifier.state.first.startTime, Duration.zero);
  });
}
