import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

abstract class PlayerHandle {
  Duration get position;
  Duration get duration;
  bool get isPlaying;
  bool get isBuffering;
  double get volume;
  double get playbackSpeed;
  double get aspectRatio;

  Stream<Duration> get positionStream;
  Stream<Duration> get durationStream;
  Stream<bool> get playingStream;
  Stream<bool> get bufferingStream;
  Stream<String> get errorStream;

  Future<void> play();
  Future<void> pause();
  Future<void> seekTo(Duration position);
  Future<void> setVolume(double volume);
  Future<void> setPlaybackSpeed(double speed);
  Future<void> dispose();

  Widget buildWidget(BuildContext context);
}

class MediaKitPlayerHandle implements PlayerHandle {
  final Player player;
  final VideoController controller;

  MediaKitPlayerHandle({
    required this.player,
    required this.controller,
  });

  @override
  Duration get position => player.state.position;

  @override
  Duration get duration => player.state.duration;

  @override
  bool get isPlaying => player.state.playing;

  @override
  bool get isBuffering => player.state.buffering;

  @override
  double get volume => player.state.volume / 100.0;

  @override
  double get playbackSpeed => player.state.rate;

  @override
  double get aspectRatio {
    final width = player.state.width;
    final height = player.state.height;
    if (width != null && height != null && height > 0) {
      return width / height;
    }
    return 16 / 9;
  }

  @override
  Stream<Duration> get positionStream => player.stream.position;

  @override
  Stream<Duration> get durationStream => player.stream.duration;

  @override
  Stream<bool> get playingStream => player.stream.playing;

  @override
  Stream<bool> get bufferingStream => player.stream.buffering;

  @override
  Stream<String> get errorStream => player.stream.error;

  @override
  Future<void> play() => player.play();

  @override
  Future<void> pause() => player.pause();

  @override
  Future<void> seekTo(Duration position) => player.seek(position);

  @override
  Future<void> setVolume(double volume) {
    return player.setVolume((volume * 100).clamp(0.0, 100.0));
  }

  @override
  Future<void> setPlaybackSpeed(double speed) => player.setRate(speed);

  @override
  Future<void> dispose() async {
    await player.dispose();
  }

  @override
  Widget buildWidget(BuildContext context) {
    return Video(
      controller: controller,
      controls: NoVideoControls,
    );
  }
}

abstract class MediaPlayerService {
  Future<PlayerHandle> open(String videoPath);
  Future<void> dispose(PlayerHandle handle);
}

class MediaKitMediaService implements MediaPlayerService {
  @override
  Future<PlayerHandle> open(String videoPath) async {
    if (videoPath.trim().isEmpty) {
      throw const FormatException('No video selected.');
    }
    if (videoPath.contains('?') || videoPath.contains('#')) {
      throw const FormatException(
        'This file name cannot be played. Rename it to remove ? or #.',
      );
    }
    final file = File(videoPath);
    if (!file.existsSync()) {
      throw FileSystemException('The video file is missing.', videoPath);
    }

    final player = Player();
    final controller = VideoController(player);

    await player.open(Media(videoPath), play: false);

    // Wait until video properties are ready or timeout
    final completer = Completer<void>();
    late final StreamSubscription sub;
    sub = player.stream.duration.listen((d) {
      if (d > Duration.zero && !completer.isCompleted) {
        completer.complete();
      }
    });

    try {
      await completer.future.timeout(const Duration(seconds: 4));
    } catch (_) {
      // Continue if timeout elapsed
    } finally {
      await sub.cancel();
    }

    return MediaKitPlayerHandle(player: player, controller: controller);
  }

  @override
  Future<void> dispose(PlayerHandle handle) {
    return handle.dispose();
  }
}
