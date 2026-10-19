import 'package:flutter_test/flutter_test.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:captionary/data/models/playback_quality.dart';
import 'package:captionary/data/services/system_memory_service.dart';
import 'package:captionary/data/mock/mock_media_player_service.dart';

void main() {
  group('PlaybackQuality & RAM optimization', () {
    test('VideoControllerConfiguration accepts width and height', () {
      const config = VideoControllerConfiguration(width: 854, height: 480);
      expect(config.width, 854);
      expect(config.height, 480);
    });

    test('targetHeight matches quality settings', () {
      expect(PlaybackQuality.p360.targetHeight, 360);
      expect(PlaybackQuality.p480.targetHeight, 480);
      expect(PlaybackQuality.p720.targetHeight, 720);
      expect(PlaybackQuality.original.targetHeight, isNull);
      expect(PlaybackQuality.auto.targetHeight, isNull);
    });

    test('resolveMaxResolution dynamically resolves based on RAM tier in auto mode', () {
      const lowRam = SystemMemoryInfo(
        totalRamBytes: 2048 * 1024 * 1024,
        availableRamBytes: 800 * 1024 * 1024,
        thresholdBytes: 400 * 1024 * 1024,
        isLowMemory: true,
        currentRssBytes: 100 * 1024 * 1024,
        maxRssBytes: 150 * 1024 * 1024,
      );
      const midRam = SystemMemoryInfo(
        totalRamBytes: 4096 * 1024 * 1024,
        availableRamBytes: 1800 * 1024 * 1024,
        thresholdBytes: 400 * 1024 * 1024,
        isLowMemory: false,
        currentRssBytes: 100 * 1024 * 1024,
        maxRssBytes: 150 * 1024 * 1024,
      );
      const highRam = SystemMemoryInfo(
        totalRamBytes: 8192 * 1024 * 1024,
        availableRamBytes: 4000 * 1024 * 1024,
        thresholdBytes: 400 * 1024 * 1024,
        isLowMemory: false,
        currentRssBytes: 100 * 1024 * 1024,
        maxRssBytes: 150 * 1024 * 1024,
      );

      // In auto mode:
      expect(PlaybackQuality.auto.resolveMaxResolution(lowRam), 360);
      expect(PlaybackQuality.auto.resolveMaxResolution(midRam), 480);
      expect(PlaybackQuality.auto.resolveMaxResolution(highRam), 720);
      expect(PlaybackQuality.auto.resolveMaxResolution(null), 480);

      // Explicit quality ignores system RAM:
      expect(PlaybackQuality.p360.resolveMaxResolution(highRam), 360);
      expect(PlaybackQuality.p720.resolveMaxResolution(lowRam), 720);
      expect(PlaybackQuality.original.resolveMaxResolution(lowRam), isNull);
    });

    test(
      'MockMediaPlayerService opens with maxResolution without error',
      () async {
        final mock = MockMediaPlayerService(
          mockDuration: const Duration(seconds: 10),
        );
        final handle = await mock.open('test.mp4', maxResolution: 480);
        expect(handle.duration, const Duration(seconds: 10));
        await mock.dispose(handle);
      },
    );
  });
}
