import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:captionary/widgets/donate_banner.dart';
import 'package:material_symbols_icons/symbols.dart';

void main() {
  testWidgets('DonateBanner renders correctly and taps', (
    WidgetTester tester,
  ) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DonateBanner(
            onTap: () {
              tapped = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('Help keep Captionary free'), findsOneWidget);
    expect(find.text('Donate'), findsOneWidget);
    expect(find.byIcon(Symbols.local_cafe), findsOneWidget);

    await tester.tap(find.byType(DonateBanner));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });
}
