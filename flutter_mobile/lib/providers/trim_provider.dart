import 'package:flutter_riverpod/flutter_riverpod.dart';

class TrimState {
  final Duration start;
  final Duration? end;
  final bool isEnabled;

  const TrimState({
    this.start = Duration.zero,
    this.end,
    this.isEnabled = false,
  });

  Duration duration(Duration totalVideoDuration) {
    final effectiveEnd = (end != null && end! <= totalVideoDuration)
        ? end!
        : totalVideoDuration;
    final diff = effectiveEnd - start;
    return diff.isNegative ? Duration.zero : diff;
  }

  TrimState copyWith({Duration? start, Duration? end, bool? isEnabled}) {
    return TrimState(
      start: start ?? this.start,
      end: end ?? this.end,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}

class TrimNotifier extends StateNotifier<TrimState> {
  TrimNotifier() : super(const TrimState());

  void setTrim({required Duration start, Duration? end}) {
    state = state.copyWith(start: start, end: end, isEnabled: true);
  }

  void updateStart(Duration start) {
    state = state.copyWith(start: start, isEnabled: true);
  }

  void updateEnd(Duration? end) {
    state = state.copyWith(end: end, isEnabled: true);
  }

  void reset() {
    state = const TrimState();
  }

  void toggleEnabled() {
    state = state.copyWith(isEnabled: !state.isEnabled);
  }
}

final trimProvider = StateNotifierProvider<TrimNotifier, TrimState>((ref) {
  return TrimNotifier();
});
