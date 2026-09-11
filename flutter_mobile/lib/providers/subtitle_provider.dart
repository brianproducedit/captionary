import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/subtitle_segment.dart';
import '../data/mock/seed_data.dart';

class SubtitleNotifier extends StateNotifier<List<SubtitleSegment>> {
  final List<List<SubtitleSegment>> _undoStack = [];
  final List<List<SubtitleSegment>> _redoStack = [];

  SubtitleNotifier() : super(SeedData.sampleSubtitles);

  void _saveState() {
    _undoStack.add(List.from(state));
    if (_undoStack.length > 50) {
      _undoStack.removeAt(0); // Max 50 history states
    }
    _redoStack.clear();
  }

  void undo() {
    if (_undoStack.isNotEmpty) {
      _redoStack.add(List.from(state));
      state = _undoStack.removeLast();
    }
  }

  void redo() {
    if (_redoStack.isNotEmpty) {
      _undoStack.add(List.from(state));
      state = _redoStack.removeLast();
    }
  }

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void updateSegment(SubtitleSegment updatedSegment) {
    _saveState();
    state = state.map((s) => s.index == updatedSegment.index ? updatedSegment : s).toList();
  }
  
  void selectSegment(int index) {
    // We don't save selection in undo stack as it's just UI state
    state = state.map((s) => s.copyWith(isSelected: s.index == index)).toList();
  }

  void updateTimecodes(int index, {Duration? startTime, Duration? endTime}) {
    _saveState();
    state = state.map((s) {
      if (s.index != index) return s;
      final newStart = startTime ?? s.startTime;
      final newEnd = endTime ?? s.endTime;
      // Ensure start < end and durations are non-negative
      if (newStart >= newEnd || newStart.isNegative) return s;
      return s.copyWith(startTime: newStart, endTime: newEnd);
    }).toList();
  }

  void updateSegmentText(int index, String text) {
    _saveState();
    state = state.map((s) {
      if (s.index != index) return s;
      return s.copyWith(text: text);
    }).toList();
  }
}

final subtitleProvider = StateNotifierProvider<SubtitleNotifier, List<SubtitleSegment>>((ref) {
  return SubtitleNotifier();
});

