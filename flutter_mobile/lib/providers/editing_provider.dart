import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/subtitle_segment.dart';
import 'player_provider.dart';
import 'subtitle_provider.dart';

/// Computed provider that automatically determines the currently active 
/// subtitle segment based on the video player's current position.
final activeSubtitleProvider = Provider<SubtitleSegment?>((ref) {
  final playerState = ref.watch(playerProvider);
  final segments = ref.watch(subtitleProvider);
  
  if (playerState.controller == null || !playerState.isInitialized) {
    return null;
  }
  
  final position = playerState.controller!.value.position;
  
  try {
    // Find the segment that spans the current video position
    return segments.firstWhere(
      (segment) => segment.startTime <= position && segment.endTime >= position,
    );
  } catch (_) {
    // No active segment at this position
    return null;
  }
});
