import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:captionary/widgets/player_transport_bar.dart';

void main() {
  testWidgets('transport controls invoke callbacks', (tester) async {
    var play = 0;
    var back = 0;
    var forward = 0;
    var mute = 0;
    var speed = 0;
    var fullscreen = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlayerTransportBar(
            isPlaying: false,
            isMuted: false,
            isFullscreen: false,
            position: const Duration(seconds: 5),
            duration: const Duration(seconds: 90),
            playbackSpeed: 1.0,
            onPlayPause: () => play++,
            onSkipBack: () => back++,
            onSkipForward: () => forward++,
            onToggleMute: () => mute++,
            onCycleSpeed: () => speed++,
            onToggleFullscreen: () => fullscreen++,
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('player-time-position')), findsOneWidget);
    expect(find.text('00:05'), findsOneWidget);
    expect(find.text('01:30'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('player-play-pause')));
    await tester.tap(find.byKey(const ValueKey('player-skip-back')));
    await tester.tap(find.byKey(const ValueKey('player-skip-forward')));
    await tester.tap(find.byKey(const ValueKey('player-mute')));
    await tester.tap(find.byKey(const ValueKey('player-speed')));
    await tester.tap(find.byKey(const ValueKey('player-fullscreen')));
    await tester.pump();

    expect(play, 1);
    expect(back, 1);
    expect(forward, 1);
    expect(mute, 1);
    expect(speed, 1);
    expect(fullscreen, 1);

    final playButton = tester.getSize(
      find.byKey(const ValueKey('player-play-pause')),
    );
    expect(playButton.width, greaterThanOrEqualTo(48));
    expect(playButton.height, greaterThanOrEqualTo(48));
  });
}
