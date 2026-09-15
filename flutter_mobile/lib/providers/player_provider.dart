import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock/mock_media_player_service.dart';
import '../data/services/media_player_service.dart';
import '../core/user_preferences.dart';
import 'backend_mode_provider.dart';
import 'preferences_provider.dart';

class PlayerState {
  final PlayerHandle? handle;
  final bool isPlaying;
  final bool isBuffering;
  final Duration position;
  final Duration duration;
  final double volume;
  final double playbackSpeed;
  final bool isInitialized;
  final String? error;

  PlayerState({
    this.handle,
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
  double get aspectRatio => handle?.aspectRatio ?? (16 / 9);

  Widget buildVideoView(BuildContext context) {
    if (handle != null && isInitialized) {
      return handle!.buildWidget(context);
    }
    return const SizedBox.shrink();
  }

  PlayerState copyWith({
    PlayerHandle? handle,
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
      handle: handle ?? this.handle,
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

  final List<StreamSubscription> _subscriptions = [];
  PlayerHandle? _currentHandle;

  PlayerNotifier(
    this._mediaPlayerService, {
    this.initTimeout = defaultInitTimeout,
    this.readPreferences,
  }) : super(PlayerState());

  void _cancelSubscriptions() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
  }

  @override
  void dispose() {
    if (!mounted) return;
    _cancelSubscriptions();
    final handle = _currentHandle;
    _currentHandle = null;
    if (handle != null) {
      _mediaPlayerService.dispose(handle);
    }
    super.dispose();
  }

  Future<void> initPlayer(String videoPath) async {
    _cancelSubscriptions();
    if (state.handle != null) {
      await _mediaPlayerService.dispose(state.handle!);
    }

    if (videoPath.trim().isEmpty) {
      state = PlayerState(error: 'No video selected.');
      return;
    }

    state = PlayerState();

    try {
      final handle = await _mediaPlayerService
          .open(videoPath)
          .timeout(initTimeout);

      final prefs = readPreferences?.call() ?? UserPreferences.defaults;
      await handle.setVolume(prefs.volume);
      await handle.setPlaybackSpeed(prefs.playbackSpeed);
      if (prefs.autoPlay) {
        await handle.play();
      }

      _currentHandle = handle;
      state = state.copyWith(
        handle: handle,
        isInitialized: true,
        duration: handle.duration,
        position: handle.position,
        volume: prefs.volume,
        playbackSpeed: prefs.playbackSpeed,
        isPlaying: prefs.autoPlay,
        isBuffering: handle.isBuffering,
      );

      _subscriptions.add(
        handle.positionStream.listen((pos) {
          if (mounted) state = state.copyWith(position: pos);
        }),
      );
      _subscriptions.add(
        handle.durationStream.listen((dur) {
          if (mounted && dur > Duration.zero) {
            state = state.copyWith(duration: dur);
          }
        }),
      );
      _subscriptions.add(
        handle.playingStream.listen((playing) {
          if (mounted) state = state.copyWith(isPlaying: playing);
        }),
      );
      _subscriptions.add(
        handle.bufferingStream.listen((buffering) {
          if (mounted) state = state.copyWith(isBuffering: buffering);
        }),
      );
      _subscriptions.add(
        handle.errorStream.listen((err) {
          if (mounted && err.isNotEmpty) state = state.copyWith(error: err);
        }),
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
    _cancelSubscriptions();
    final handle = _currentHandle;
    _currentHandle = null;
    if (handle != null) {
      await _mediaPlayerService.dispose(handle);
    }
    if (mounted) {
      await Future.microtask(() {
        if (mounted) {
          state = PlayerState();
        }
      });
    }
  }

  Future<void> togglePlay() async {
    final handle = state.handle;
    if (handle != null && state.isInitialized) {
      if (state.isPlaying) {
        await handle.pause();
      } else {
        await handle.play();
      }
    }
  }

  Future<void> play() async {
    final handle = state.handle;
    if (handle != null && state.isInitialized && !state.isPlaying) {
      await handle.play();
    }
  }

  Future<void> pause() async {
    final handle = state.handle;
    if (handle != null && state.isPlaying) {
      await handle.pause();
    }
  }

  Future<void> seekTo(Duration position) async {
    var target = position;
    if (target.isNegative) target = Duration.zero;
    if (state.duration > Duration.zero && target > state.duration) {
      target = state.duration;
    }
    final handle = state.handle;
    if (handle != null && state.isInitialized) {
      await handle.seekTo(target);
    }
    state = state.copyWith(position: target);
  }

  Future<void> seekRelative(Duration offset) async {
    final newPos = state.position + offset;
    final clampedPos = newPos < Duration.zero
        ? Duration.zero
        : (state.duration > Duration.zero && newPos > state.duration)
        ? state.duration
        : newPos;
    await seekTo(clampedPos);
  }

  Future<void> setVolume(double volume) async {
    final handle = state.handle;
    if (handle != null) {
      await handle.setVolume(volume);
    }
    state = state.copyWith(volume: volume);
  }

  Future<void> setPlaybackSpeed(double speed) async {
    final handle = state.handle;
    if (handle != null) {
      await handle.setPlaybackSpeed(speed);
    }
    state = state.copyWith(playbackSpeed: speed);
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
  final notifier = PlayerNotifier(
    ref.watch(mediaPlayerServiceProvider),
    readPreferences: () {
      try {
        return ref.read(preferencesProvider);
      } catch (_) {
        return UserPreferences.defaults;
      }
    },
  );
  return notifier;
});

final mediaPlayerServiceProvider = Provider<MediaPlayerService>((ref) {
  final mode = ref.watch(backendModeProvider);
  switch (mode) {
    case BackendMode.mock:
      return MockMediaPlayerService();
    case BackendMode.local:
    case BackendMode.real:
      return MediaKitMediaService();
  }
});
