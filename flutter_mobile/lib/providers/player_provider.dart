import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../data/services/media_player_service.dart';
import '../core/user_preferences.dart';
import 'preferences_provider.dart';

class PlayerState {
  final VideoPlayerController? controller;
  final bool isPlaying;
  final bool isBuffering;
  final Duration position;
  final Duration duration;
  final double volume;
  final double playbackSpeed;
  final bool isInitialized;
  final String? error;

  PlayerState({
    this.controller,
    this.isPlaying = false,
    this.isBuffering = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.volume = 1.0,
    this.playbackSpeed = 1.0,
    this.isInitialized = false,
    this.error,
  });

  bool get isMuted => volume <= 0;

  PlayerState copyWith({
    VideoPlayerController? controller,
    bool? isPlaying,
    bool? isBuffering,
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
      isBuffering: isBuffering ?? this.isBuffering,
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
  static const skipInterval = Duration(seconds: 10);
  static const defaultInitTimeout = Duration(seconds: 8);
  static const playbackSpeeds = [0.5, 1.0, 1.25, 1.5, 2.0];

  final MediaPlayerService _mediaPlayerService;
  final Duration initTimeout;
  final UserPreferences Function()? readPreferences;
  double _volumeBeforeMute = 1.0;

  PlayerNotifier(
    this._mediaPlayerService, {
    this.initTimeout = defaultInitTimeout,
    this.readPreferences,
  }) : super(PlayerState());

  @override
  void dispose() {
    state.controller?.removeListener(_onControllerTick);
    state.controller?.dispose();
    super.dispose();
  }

  Future<void> initPlayer(String videoPath) async {
    state.controller?.removeListener(_onControllerTick);
    if (state.controller != null) {
      await _mediaPlayerService.dispose(state.controller!);
    }

    if (videoPath.trim().isEmpty) {
      state = PlayerState(error: 'No video selected.');
      return;
    }

    state = PlayerState();

    try {
      final controller = await _mediaPlayerService
          .open(videoPath)
          .timeout(initTimeout);
      controller.addListener(_onControllerTick);
      final prefs = readPreferences?.call() ?? UserPreferences.defaults;
      await controller.setVolume(prefs.volume);
      await controller.setPlaybackSpeed(prefs.playbackSpeed);
      if (prefs.autoPlay) {
        await controller.play();
      }
      state = state.copyWith(
        controller: controller,
        isInitialized: true,
        duration: controller.value.duration,
        volume: prefs.volume,
        playbackSpeed: prefs.playbackSpeed,
        isPlaying: prefs.autoPlay,
        isBuffering: controller.value.isBuffering,
      );
    } on TimeoutException {
      state = PlayerState(
        error: 'This video took too long to open. It may be unsupported or corrupt.',
      );
    } catch (e) {
      state = PlayerState(error: e.toString());
    }
  }

  Future<void> disposePlayer() async {
    final controller = state.controller;
    if (controller == null) return;

    controller.removeListener(_onControllerTick);
    await _mediaPlayerService.dispose(controller);
    state = PlayerState();
  }

  void _onControllerTick() {
    final controller = state.controller;
    if (controller != null && controller.value.isInitialized) {
      if (state.position != controller.value.position ||
          state.isPlaying != controller.value.isPlaying ||
          state.isBuffering != controller.value.isBuffering ||
          state.duration != controller.value.duration) {
        state = state.copyWith(
          position: controller.value.position,
          isPlaying: controller.value.isPlaying,
          isBuffering: controller.value.isBuffering,
          duration: controller.value.duration,
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

  Future<void> pause() async {
    final controller = state.controller;
    if (controller?.value.isPlaying == true) {
      await controller!.pause();
    }
  }

  Future<void> seekTo(Duration position) async {
    var target = position;
    if (target.isNegative) target = Duration.zero;
    if (state.duration > Duration.zero && target > state.duration) {
      target = state.duration;
    }
    final controller = state.controller;
    if (controller != null && controller.value.isInitialized) {
      await controller.seekTo(target);
    } else {
      state = state.copyWith(position: target);
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
    }
    state = state.copyWith(volume: volume);
  }

  Future<void> setPlaybackSpeed(double speed) async {
    final controller = state.controller;
    if (controller != null) {
      await controller.setPlaybackSpeed(speed);
      state = state.copyWith(playbackSpeed: speed);
    } else {
      state = state.copyWith(playbackSpeed: speed);
    }
  }

  Future<void> skipBack() => seekRelative(-skipInterval);

  Future<void> skipForward() => seekRelative(skipInterval);

  Future<void> toggleMute() async {
    if (state.volume > 0) {
      _volumeBeforeMute = state.volume;
      await setVolume(0);
    } else {
      await setVolume(_volumeBeforeMute > 0 ? _volumeBeforeMute : 1.0);
    }
  }

  Future<void> cyclePlaybackSpeed() async {
    final index = playbackSpeeds.indexOf(state.playbackSpeed);
    final next = playbackSpeeds[(index + 1) % playbackSpeeds.length];
    await setPlaybackSpeed(next);
  }
}

final playerProvider = StateNotifierProvider<PlayerNotifier, PlayerState>((
  ref,
) {
  return PlayerNotifier(
    ref.watch(mediaPlayerServiceProvider),
    readPreferences: () {
      try {
        return ref.read(preferencesProvider);
      } catch (_) {
        return UserPreferences.defaults;
      }
    },
  );
});

final mediaPlayerServiceProvider = Provider<MediaPlayerService>((ref) {
  return VideoPlayerMediaService();
});
