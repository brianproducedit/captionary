import '../data/models/subtitle_segment.dart';

/// Pure caption-timeline edits. The notifier records undo around these.
class SubtitleTimeline {
  static const Duration minDuration = Duration(milliseconds: 200);

  static List<SubtitleSegment> reindex(List<SubtitleSegment> segments) {
    final copy = [...segments]
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    return [
      for (var i = 0; i < copy.length; i++) copy[i].copyWith(index: i + 1),
    ];
  }

  static List<SubtitleSegment> move(
    List<SubtitleSegment> segments,
    int index, {
    required Duration delta,
    Duration? mediaDuration,
  }) {
    final ordered = reindex(segments);
    final i = ordered.indexWhere((s) => s.index == index);
    if (i < 0) return segments;
    final seg = ordered[i];
    final duration = seg.endTime - seg.startTime;
    if (duration < minDuration) return segments;

    final prevEnd = i == 0 ? Duration.zero : ordered[i - 1].endTime;
    final nextStart = i == ordered.length - 1
        ? (mediaDuration ?? seg.endTime + duration)
        : ordered[i + 1].startTime;

    var newStart = seg.startTime + delta;
    if (newStart < prevEnd) newStart = prevEnd;
    if (newStart + duration > nextStart) {
      newStart = nextStart - duration;
    }
    if (newStart < prevEnd || newStart + duration > nextStart) {
      return ordered;
    }
    if (newStart.isNegative) newStart = Duration.zero;

    ordered[i] = seg.copyWith(
      startTime: newStart,
      endTime: newStart + duration,
    );
    return reindex(ordered);
  }

  static List<SubtitleSegment> trimStart(
    List<SubtitleSegment> segments,
    int index,
    Duration newStart,
  ) {
    final ordered = reindex(segments);
    final i = ordered.indexWhere((s) => s.index == index);
    if (i < 0) return segments;
    final seg = ordered[i];
    final minStart = i == 0 ? Duration.zero : ordered[i - 1].endTime;
    final maxStart = seg.endTime - minDuration;
    var start = newStart;
    if (start < minStart) start = minStart;
    if (start > maxStart) start = maxStart;
    if (start >= seg.endTime) return ordered;
    ordered[i] = seg.copyWith(startTime: start);
    return reindex(ordered);
  }

  static List<SubtitleSegment> trimEnd(
    List<SubtitleSegment> segments,
    int index,
    Duration newEnd, {
    Duration? mediaDuration,
  }) {
    final ordered = reindex(segments);
    final i = ordered.indexWhere((s) => s.index == index);
    if (i < 0) return segments;
    final seg = ordered[i];
    final minEnd = seg.startTime + minDuration;
    final maxEnd = i == ordered.length - 1
        ? (mediaDuration ?? newEnd)
        : ordered[i + 1].startTime;
    var end = newEnd;
    if (end < minEnd) end = minEnd;
    if (maxEnd > Duration.zero && end > maxEnd) end = maxEnd;
    if (end <= seg.startTime) return ordered;
    ordered[i] = seg.copyWith(endTime: end);
    return reindex(ordered);
  }

  static List<SubtitleSegment> splitAt(
    List<SubtitleSegment> segments,
    int index,
    Duration at,
  ) {
    final ordered = reindex(segments);
    final i = ordered.indexWhere((s) => s.index == index);
    if (i < 0) return segments;
    final seg = ordered[i];
    if (at < seg.startTime + minDuration || at > seg.endTime - minDuration) {
      return ordered;
    }
    final parts = _splitText(seg.text);
    ordered[i] = seg.copyWith(endTime: at, text: parts.$1, isSelected: false);
    ordered.insert(
      i + 1,
      seg.copyWith(startTime: at, text: parts.$2, isSelected: true),
    );
    return reindex(ordered);
  }

  static List<SubtitleSegment> mergeWithNext(
    List<SubtitleSegment> segments,
    int index,
  ) {
    final ordered = reindex(segments);
    final i = ordered.indexWhere((s) => s.index == index);
    if (i < 0 || i >= ordered.length - 1) return ordered;
    final a = ordered[i];
    final b = ordered[i + 1];
    final mergedText = [
      a.text.trim(),
      b.text.trim(),
    ].where((part) => part.isNotEmpty).join(' ');
    ordered[i] = a.copyWith(
      endTime: b.endTime,
      text: mergedText,
      isSelected: true,
    );
    ordered.removeAt(i + 1);
    return reindex(ordered);
  }

  static List<SubtitleSegment> duplicate(
    List<SubtitleSegment> segments,
    int index, {
    Duration? mediaDuration,
  }) {
    final ordered = reindex(segments);
    final i = ordered.indexWhere((s) => s.index == index);
    if (i < 0) return ordered;
    final seg = ordered[i];
    final dur = seg.endTime - seg.startTime;
    final nextStart = i == ordered.length - 1
        ? (mediaDuration ?? seg.endTime + dur)
        : ordered[i + 1].startTime;
    final gap = nextStart - seg.endTime;
    if (gap < minDuration) return ordered;
    final copyDur = dur <= gap ? dur : gap;
    ordered.insert(
      i + 1,
      seg.copyWith(
        startTime: seg.endTime,
        endTime: seg.endTime + copyDur,
        isSelected: true,
      ),
    );
    ordered[i] = seg.copyWith(isSelected: false);
    return reindex(ordered);
  }

  static List<SubtitleSegment> delete(
    List<SubtitleSegment> segments,
    int index,
  ) {
    final ordered = reindex(segments);
    ordered.removeWhere((s) => s.index == index);
    if (ordered.isEmpty) return ordered;
    final select = (index - 2).clamp(0, ordered.length - 1);
    return reindex([
      for (var i = 0; i < ordered.length; i++)
        ordered[i].copyWith(isSelected: i == select),
    ]);
  }

  static List<SubtitleSegment> updateText(
    List<SubtitleSegment> segments,
    int index,
    String text,
  ) {
    return [
      for (final segment in segments)
        if (segment.index == index) segment.copyWith(text: text) else segment,
    ];
  }

  static (String, String) _splitText(String text) {
    final words = text.trim().split(RegExp(r'\s+'));
    if (words.length < 2) return (text, text);
    final mid = words.length ~/ 2;
    return (words.sublist(0, mid).join(' '), words.sublist(mid).join(' '));
  }
}
