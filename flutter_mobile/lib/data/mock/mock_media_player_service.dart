import 'dart:async';

import 'package:flutter/material.dart';

import '../services/media_player_service.dart';

class MockPlayerHandle implements PlayerHandle {
  Duration _position = Duration.zero;
  Duration _duration = const Duration(seconds: 60);
  bool _isPlaying = false;
  final bool _isBuffering = false;
  double _volume = 1.0;
  double _playbackSpeed = 1.0;
  final double _aspectRatio = 16 / 9;

  final _posController = StreamController<Duration>.broadcast();
  final _durController = StreamController<Duration>.broadcast();
  final _playController = StreamController<bool>.broadcast();
  final _bufController = StreamController<bool>.broadcast();
  final _errController = StreamController<String>.broadcast();

  MockPlayerHandle({Duration? duration}) {
    if (duration != null) _duration = duration;
  }

  @override
  Duration get position => _position;
  @override
  Duration get duration => _duration;
  @override
  bool get isPlaying => _isPlaying;
  @override
  bool get isBuffering => _isBuffering;
  @override
  double get volume => _volume;
  @override
  double get playbackSpeed => _playbackSpeed;
  @override
  double get aspectRatio => _aspectRatio;

  @override
  Stream<Duration> get positionStream => _posController.stream;
  @override
  Stream<Duration> get durationStream => _durController.stream;
  @override
  Stream<bool> get playingStream => _playController.stream;
  @override
  Stream<bool> get bufferingStream => _bufController.stream;
  @override
  Stream<String> get errorStream => _errController.stream;

  @override
  Future<void> play() async {
    _isPlaying = true;
    _playController.add(true);
  }

  @override
  Future<void> pause() async {
    _isPlaying = false;
    _playController.add(false);
  }

  @override
  Future<void> seekTo(Duration position) async {
    _position = position;
    _posController.add(position);
  }

  @override
  Future<void> setVolume(double volume) async {
    _volume = volume;
  }

  @override
  Future<void> setPlaybackSpeed(double speed) async {
    _playbackSpeed = speed;
  }

  @override
  Future<void> dispose() async {
    await _posController.close();
    await _durController.close();
    await _playController.close();
    await _bufController.close();
    await _errController.close();
  }

  @override
  Widget buildWidget(BuildContext context) {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Icon(Icons.play_circle_outline, color: Colors.white54, size: 48),
      ),
    );
  }
}

class MockMediaPlayerService implements MediaPlayerService {
  final Duration? mockDuration;
  MockMediaPlayerService({this.mockDuration});

  @override
  Future<PlayerHandle> open(String videoPath) async {
    if (videoPath.trim().isEmpty) {
      throw const FormatException('No video selected.');
    }
    return MockPlayerHandle(duration: mockDuration);
  }

  @override
  Future<void> dispose(PlayerHandle handle) => handle.dispose();
}
