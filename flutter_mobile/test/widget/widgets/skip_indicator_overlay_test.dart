import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:captionary/widgets/skip_indicator_overlay.dart';

void main() {
  testWidgets(
    'SkipIndicatorOverlay renders forward indicator and triggers onDismissed',
    (tester) async {
      bool dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkipIndicatorOverlay(
              direction: SkipDirection.forward,
              skipAmount: const Duration(seconds: 10),
              onDismissed: () {
                dismissed = true;
              },
            ),
          ),
        ),
      );

      // Initial render
      expect(find.text('+10s'), findsOneWidget);
      expect(find.byIcon(Symbols.forward_10), findsOneWidget);
      expect(dismissed, isFalse);

      // After animation completes
      await tester.pumpAndSettle();
      expect(dismissed, isTrue);
    },
  );

  testWidgets('SkipIndicatorOverlay renders rewind indicator', (tester) async {
    bool dismissed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SkipIndicatorOverlay(
            direction: SkipDirection.rewind,
            skipAmount: const Duration(seconds: 10),
            onDismissed: () {
              dismissed = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('-10s'), findsOneWidget);
    expect(find.byIcon(Symbols.replay_10), findsOneWidget);

    await tester.pumpAndSettle();
    expect(dismissed, isTrue);
  });
}
