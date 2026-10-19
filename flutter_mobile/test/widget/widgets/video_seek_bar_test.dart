import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:captionary/data/mock/mock_media_player_service.dart';
import 'package:captionary/providers/player_provider.dart';
import 'package:captionary/widgets/video_seek_bar.dart';

void main() {
  testWidgets('VideoSeekBar displays timestamps and slider correctly', (
    tester,
  ) async {
    final mockService = MockMediaPlayerService();
    final container = ProviderContainer(
      overrides: [mediaPlayerServiceProvider.overrideWithValue(mockService)],
    );
    addTearDown(container.dispose);

    // Initialize player with dummy video
    await container.read(playerProvider.notifier).initPlayer('test.mp4');
    // Set duration to 60s and position to 15s
    await container
        .read(playerProvider.notifier)
        .seekTo(const Duration(seconds: 15));

    final seekBarKey = GlobalKey<VideoSeekBarState>();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: VideoSeekBar(
              key: seekBarKey,
              autoHideDuration: const Duration(seconds: 3),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('video-seekbar-current-time')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('video-seekbar-slider')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('video-seekbar-total-duration')),
      findsOneWidget,
    );

    expect(find.text('00:15'), findsOneWidget);
    expect(find.text('01:00'), findsOneWidget);

    // Test slider interaction
    final slider = find.byKey(const ValueKey('video-seekbar-slider'));
    expect(slider, findsOneWidget);

    // Test auto-hide timer
    expect(seekBarKey.currentState?.isVisible, isTrue);
    await tester.pump(const Duration(seconds: 4));
    expect(seekBarKey.currentState?.isVisible, isFalse);

    // Test showControls reveals it again
    seekBarKey.currentState?.showControls();
    await tester.pump();
    expect(seekBarKey.currentState?.isVisible, isTrue);
  });
}
