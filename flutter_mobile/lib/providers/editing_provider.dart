import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/subtitle_segment.dart';
import 'player_provider.dart';
import 'subtitle_provider.dart';

/// Computed provider that automatically determines the currently active
/// subtitle segment based on the video player's current position.
final activeSubtitleProvider = Provider<SubtitleSegment?>((ref) {
  final playerState = ref.watch(playerProvider);
  final segments = ref.watch(subtitleProvider);

  final position = playerState.position;

  // 1. If player is playing, strictly track playback timecode
  if (playerState.isPlaying) {
    for (final segment in segments) {
      if (segment.startTime <= position && segment.endTime >= position) {
        return segment;
      }
    }
    return null;
  }

  // 2. When paused: if a segment is actively selected, prioritize showing it
  // so live edits and corrections are visible in real-time on the video canvas.
  for (final segment in segments) {
    if (segment.isSelected) {
      return segment;
    }
  }

  // 3. Fallback: match by current playback position
  for (final segment in segments) {
    if (segment.startTime <= position && segment.endTime >= position) {
      return segment;
    }
  }
  return null;
});
