import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:captionary/widgets/donate_pill.dart';
import 'package:material_symbols_icons/symbols.dart';

void main() {
  testWidgets('DonatePill renders correctly and taps', (
    WidgetTester tester,
  ) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DonatePill(
            onTap: () {
              tapped = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('Donate'), findsOneWidget);
    expect(find.byIcon(Symbols.local_cafe), findsOneWidget);

    await tester.tap(find.byType(DonatePill));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });
}
