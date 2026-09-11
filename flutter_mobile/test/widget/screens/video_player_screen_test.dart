import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:captionary/screens/video_player_screen.dart';

void main() {
  testWidgets('empty video path shows an error instead of a spinner', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: VideoPlayerScreen(videoPath: '')),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('No video selected.'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byKey(const ValueKey('player-play-pause')), findsOneWidget);
    expect(find.byKey(const ValueKey('player-skip-back')), findsOneWidget);
    expect(find.byKey(const ValueKey('player-skip-forward')), findsOneWidget);
    expect(find.byKey(const ValueKey('player-mute')), findsOneWidget);
    expect(find.byKey(const ValueKey('player-speed')), findsOneWidget);
    expect(find.byKey(const ValueKey('player-fullscreen')), findsOneWidget);
  });
}
