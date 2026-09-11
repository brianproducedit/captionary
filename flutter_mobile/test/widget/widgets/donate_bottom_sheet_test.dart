import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:captionary/widgets/donate_bottom_sheet.dart';
import 'package:material_symbols_icons/symbols.dart';

void main() {
  testWidgets('DonateBottomSheet renders correctly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: DonateBottomSheet())),
    );

    expect(find.text('Fuel Our Mission 🚀'), findsOneWidget);
    expect(find.text('Donate Now'), findsOneWidget);
    expect(find.text('Maybe Later'), findsOneWidget);
    expect(find.byIcon(Symbols.local_cafe), findsOneWidget);
  });
}
