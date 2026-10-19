import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:captionary/providers/crop_provider.dart';
import 'package:captionary/providers/player_provider.dart';
import 'package:captionary/data/mock/mock_media_player_service.dart';
import 'package:captionary/widgets/trim_bar.dart';
import 'package:captionary/widgets/crop_overlay.dart';

void main() {
  group('TrimBar Widget', () {
    testWidgets('renders when total video duration > zero and updates trim range', (tester) async {
      final mockPlayer = MockPlayerHandle(duration: const Duration(seconds: 30));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            playerProvider.overrideWith((ref) {
              final notifier = PlayerNotifier(MockMediaPlayerService());
              notifier.state = PlayerState(
                handle: mockPlayer,
                duration: const Duration(seconds: 30),
                position: const Duration(seconds: 5),
                isInitialized: true,
              );
              return notifier;
            }),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: TrimBar(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Video Trim Range'), findsOneWidget);
      expect(find.byType(RangeSlider), findsOneWidget);
    });

    testWidgets('hidden when video duration is zero', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            playerProvider.overrideWith((ref) {
              final notifier = PlayerNotifier(MockMediaPlayerService());
              notifier.state = PlayerState(
                duration: Duration.zero,
                isInitialized: false,
              );
              return notifier;
            }),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: TrimBar(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Video Trim Range'), findsNothing);
      expect(find.byType(RangeSlider), findsNothing);
    });
  });

  group('CropOverlay Widget', () {
    testWidgets('hidden when crop is disabled', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CropOverlay(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('9:16 (TikTok/Reels)'), findsNothing);
      expect(find.text('1:1 (Square)'), findsNothing);
    });

    testWidgets('renders preset chips and canvas when crop is enabled', (tester) async {
      final container = ProviderContainer();
      container.read(cropProvider.notifier).setAspectRatio(CropAspectRatio.portrait916);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 600,
                child: CropOverlay(videoAspectRatio: 16 / 9),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('9:16 (TikTok/Reels)'), findsOneWidget);
      expect(find.text('1:1 (Square)'), findsOneWidget);
      expect(find.text('16:9 (Landscape)'), findsOneWidget);
    });
  });
}
