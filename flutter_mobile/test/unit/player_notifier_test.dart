import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';
import 'package:captionary/data/services/media_player_service.dart';
import 'package:captionary/providers/player_provider.dart';

class _HangingMediaPlayerService implements MediaPlayerService {
  @override
  Future<VideoPlayerController> open(String videoPath) {
    return Completer<VideoPlayerController>().future;
  }

  @override
  Future<void> dispose(VideoPlayerController controller) async {}
}

class _FailingMediaPlayerService implements MediaPlayerService {
  @override
  Future<VideoPlayerController> open(String videoPath) {
    throw Exception('unsupported format');
  }

  @override
  Future<void> dispose(VideoPlayerController controller) async {}
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
}
