import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

class PlayerState {
  final VideoPlayerController? controller;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final double volume;
  final double playbackSpeed;
  final bool isInitialized;
  final String? error;

  PlayerState({
    this.controller,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.volume = 1.0,
    this.playbackSpeed = 1.0,
    this.isInitialized = false,
    this.error,
  });

  PlayerState copyWith({
    VideoPlayerController? controller,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    double? volume,
    double? playbackSpeed,
    bool? isInitialized,
    String? error,
  }) {
    return PlayerState(
      controller: controller ?? this.controller,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      volume: volume ?? this.volume,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      isInitialized: isInitialized ?? this.isInitialized,
      error: error ?? this.error,
    );
  }
}

class PlayerNotifier extends StateNotifier<PlayerState> {
  PlayerNotifier() : super(PlayerState());

  @override
  void dispose() {
    state.controller?.removeListener(_onControllerTick);
    state.controller?.dispose();
    super.dispose();
  }

  Future<void> initPlayer(String videoPath) async {
    // Clean up old controller if any
    state.controller?.removeListener(_onControllerTick);
    await state.controller?.dispose();
    
    state = PlayerState(); // Reset state
    
    final controller = VideoPlayerController.file(File(videoPath));
    
    try {
      await controller.initialize();
      controller.addListener(_onControllerTick);
      state = state.copyWith(
        controller: controller,
        isInitialized: true,
        duration: controller.value.duration,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void _onControllerTick() {
    final controller = state.controller;
    if (controller != null && controller.value.isInitialized) {
      // Only emit state changes if needed to reduce rebuilds
      if (state.position != controller.value.position || state.isPlaying != controller.value.isPlaying) {
        state = state.copyWith(
          position: controller.value.position,
          isPlaying: controller.value.isPlaying,
        );
      }
    }
  }

  Future<void> togglePlay() async {
    final controller = state.controller;
    if (controller != null && controller.value.isInitialized) {
      if (controller.value.isPlaying) {
        await controller.pause();
      } else {
        await controller.play();
      }
    }
  }

  Future<void> seekTo(Duration position) async {
    final controller = state.controller;
    if (controller != null && controller.value.isInitialized) {
      await controller.seekTo(position);
    }
  }

  Future<void> seekRelative(Duration offset) async {
    final controller = state.controller;
    if (controller != null && controller.value.isInitialized) {
      final newPos = controller.value.position + offset;
      // Clamp to duration boundaries
      final clampedPos = newPos < Duration.zero 
          ? Duration.zero 
          : newPos > controller.value.duration 
              ? controller.value.duration 
              : newPos;
      await controller.seekTo(clampedPos);
    }
  }

  Future<void> setVolume(double volume) async {
    final controller = state.controller;
    if (controller != null) {
      await controller.setVolume(volume);
      state = state.copyWith(volume: volume);
    }
  }

  Future<void> setPlaybackSpeed(double speed) async {
    final controller = state.controller;
    if (controller != null) {
      await controller.setPlaybackSpeed(speed);
      state = state.copyWith(playbackSpeed: speed);
    }
  }
}

final playerProvider = StateNotifierProvider<PlayerNotifier, PlayerState>((ref) {
  return PlayerNotifier();
});
