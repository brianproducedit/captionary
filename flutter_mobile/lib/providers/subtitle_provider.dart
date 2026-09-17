import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/subtitle_timeline.dart';
import '../data/models/subtitle_segment.dart';
import '../data/mock/seed_data.dart';

class SubtitleNotifier extends StateNotifier<List<SubtitleSegment>> {
  final List<List<SubtitleSegment>> _undoStack = [];
  final List<List<SubtitleSegment>> _redoStack = [];

  SubtitleNotifier([List<SubtitleSegment>? initial])
    : super(initial ?? SeedData.sampleSubtitles);

  /// Replaces the current subtitles with [segments], optionally clearing the undo/redo history.
  void setSegments(List<SubtitleSegment> segments, {bool clearHistory = true}) {
    if (clearHistory) {
      _undoStack.clear();
      _redoStack.clear();
    } else {
      _saveState();
    }
    state = List.from(segments);
  }

  void _saveState() {
    _undoStack.add(List.from(state));
    if (_undoStack.length > 50) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(List.from(state));
    state = _undoStack.removeLast();
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(List.from(state));
    state = _redoStack.removeLast();
  }

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void checkpoint() => _saveState();

  SubtitleSegment? get selected {
    for (final segment in state) {
      if (segment.isSelected) return segment;
    }
    return null;
  }

  void updateSegment(SubtitleSegment updatedSegment) {
    _saveState();
    state = state
        .map((s) => s.index == updatedSegment.index ? updatedSegment : s)
        .toList();
  }

  void selectSegment(int index) {
    state = [
      for (final segment in state)
        segment.copyWith(isSelected: segment.index == index),
    ];
  }

  void updateTimecodes(
    int index, {
    Duration? startTime,
    Duration? endTime,
    bool recordHistory = true,
    Duration? mediaDuration,
  }) {
    if (recordHistory) _saveState();
    var next = state;
    if (startTime != null && endTime != null) {
      final current = state.firstWhere((s) => s.index == index);
      final duration = current.endTime - current.startTime;
      final delta = startTime - current.startTime;
      if (endTime - startTime == duration) {
        next = SubtitleTimeline.move(
          state,
          index,
          delta: delta,
          mediaDuration: mediaDuration,
        );
      } else {
        next = SubtitleTimeline.trimStart(state, index, startTime);
        next = SubtitleTimeline.trimEnd(
          next,
          index,
          endTime,
          mediaDuration: mediaDuration,
        );
      }
    } else if (startTime != null) {
      next = SubtitleTimeline.trimStart(state, index, startTime);
    } else if (endTime != null) {
      next = SubtitleTimeline.trimEnd(
        state,
        index,
        endTime,
        mediaDuration: mediaDuration,
      );
    }
    state = next;
  }

  void moveSegment(
    int index,
    Duration delta, {
    Duration? mediaDuration,
    bool recordHistory = true,
  }) {
    if (recordHistory) _saveState();
    state = SubtitleTimeline.move(
      state,
      index,
      delta: delta,
      mediaDuration: mediaDuration,
    );
  }

  void trimStart(int index, Duration start, {bool recordHistory = true}) {
    if (recordHistory) _saveState();
    state = SubtitleTimeline.trimStart(state, index, start);
  }

  void trimEnd(
    int index,
    Duration end, {
    Duration? mediaDuration,
    bool recordHistory = true,
  }) {
    if (recordHistory) _saveState();
    state = SubtitleTimeline.trimEnd(
      state,
      index,
      end,
      mediaDuration: mediaDuration,
    );
  }

  void updateSegmentText(int index, String text) {
    _saveState();
    state = SubtitleTimeline.updateText(state, index, text);
  }

  void splitSelected(Duration at) {
    SubtitleSegment? target;
    for (final segment in state) {
      if (segment.startTime <= at && segment.endTime >= at) {
        target = segment;
        break;
      }
    }
    target ??= selected;
    if (target == null) return;
    _saveState();
    state = SubtitleTimeline.splitAt(state, target.index, at);
  }

  void mergeSelected() {
    final target = selected;
    if (target == null) return;
    _saveState();
    state = SubtitleTimeline.mergeWithNext(state, target.index);
  }

  void duplicateSelected({Duration? mediaDuration}) {
    final target = selected;
    if (target == null) return;
    _saveState();
    state = SubtitleTimeline.duplicate(
      state,
      target.index,
      mediaDuration: mediaDuration,
    );
  }

  void deleteSelected() {
    final target = selected;
    if (target == null) return;
    _saveState();
    state = SubtitleTimeline.delete(state, target.index);
  }

  void addSegmentAt(
    Duration startTime, {
    Duration length = const Duration(seconds: 2),
    Duration? mediaDuration,
    String defaultText = 'New Caption',
  }) {
    _saveState();
    final effectiveEnd = mediaDuration != null &&
            mediaDuration > startTime &&
            startTime + length > mediaDuration
        ? mediaDuration
        : startTime + length;

    final unselected = [
      for (final s in state) s.copyWith(isSelected: false),
    ];
    final newSegment = SubtitleSegment(
      index: unselected.length + 1,
      startTime: startTime,
      endTime: effectiveEnd > startTime
          ? effectiveEnd
          : startTime + const Duration(milliseconds: 500),
      text: defaultText,
      isSelected: true,
    );
    state = SubtitleTimeline.reindex([...unselected, newSegment]);
  }
}

final subtitleProvider =
    StateNotifierProvider<SubtitleNotifier, List<SubtitleSegment>>((ref) {
      return SubtitleNotifier();
    });
