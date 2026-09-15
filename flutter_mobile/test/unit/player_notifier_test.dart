import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:captionary/data/mock/mock_media_player_service.dart';
import 'package:captionary/data/services/media_player_service.dart';
import 'package:captionary/providers/player_provider.dart';

class _HangingMediaPlayerService implements MediaPlayerService {
  @override
  Future<PlayerHandle> open(String videoPath) {
    return Completer<PlayerHandle>().future;
  }

  @override
  Future<void> dispose(PlayerHandle handle) async {}
}

class _FailingMediaPlayerService implements MediaPlayerService {
  @override
  Future<PlayerHandle> open(String videoPath) {
    throw Exception('unsupported format');
  }

  @override
  Future<void> dispose(PlayerHandle handle) async {}
}

void main() {
  test('empty path sets a visible error instead of spinning', () async {
    final notifier = PlayerNotifier(_FailingMediaPlayerService());
    await notifier.initPlayer('  ');
    expect(notifier.state.error, 'No video selected.');
    expect(notifier.state.isInitialized, isFalse);
    notifier.dispose();
  });

  test('open timeout surfaces an unsupported/corrupt error', () async {
    final notifier = PlayerNotifier(
      _HangingMediaPlayerService(),
      initTimeout: const Duration(milliseconds: 20),
    );
    await notifier.initPlayer('clip.mp4');
    expect(notifier.state.error, contains('took too long'));
    notifier.dispose();
  });

  test('open failures surface the service error', () async {
    final notifier = PlayerNotifier(_FailingMediaPlayerService());
    await notifier.initPlayer('clip.mp4');
    expect(notifier.state.error, contains('unsupported format'));
    notifier.dispose();
  });

  test('mute and speed cycle without a controller', () async {
    final notifier = PlayerNotifier(_FailingMediaPlayerService());
    expect(notifier.state.playbackSpeed, 1.0);
    await notifier.cyclePlaybackSpeed();
    expect(notifier.state.playbackSpeed, 1.25);
    await notifier.toggleMute();
    expect(notifier.state.isMuted, isTrue);
    await notifier.toggleMute();
    expect(notifier.state.volume, 1.0);
    notifier.dispose();
  });

  test(
    'MockMediaPlayerService initializes properly and controls playback',
    () async {
      final service = MockMediaPlayerService(
        mockDuration: const Duration(seconds: 45),
      );
      final notifier = PlayerNotifier(service);

      await notifier.initPlayer('sample.mp4');
      expect(notifier.state.isInitialized, isTrue);
      expect(notifier.state.error, isNull);
      expect(notifier.state.duration, const Duration(seconds: 45));
      expect(notifier.state.isPlaying, isFalse);

      await notifier.play();
      expect(notifier.state.isPlaying, isTrue);

      await notifier.pause();
      expect(notifier.state.isPlaying, isFalse);

      await notifier.togglePlay();
      expect(notifier.state.isPlaying, isTrue);

      await notifier.seekTo(const Duration(seconds: 15));
      expect(notifier.state.position, const Duration(seconds: 15));

      await notifier.seekRelative(const Duration(seconds: 5));
      expect(notifier.state.position, const Duration(seconds: 20));

      await notifier.seekRelative(const Duration(seconds: -10));
      expect(notifier.state.position, const Duration(seconds: 10));

      await notifier.setPlaybackSpeed(1.5);
      expect(notifier.state.playbackSpeed, 1.5);

      await notifier.disposePlayer();
      expect(notifier.state.handle, isNull);
      expect(notifier.state.isInitialized, isFalse);

      notifier.dispose();
    },
  );
}
