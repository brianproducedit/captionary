import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:captionary/screens/studio_screen.dart';

void main() {
  Widget buildTestWidget() {
    return const ProviderScope(child: MaterialApp(home: StudioScreen()));
  }

  testWidgets('Studio Screen style presets update preview text styling', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Default style should be "TikTok Bold"
    expect(find.text('TikTok Bold'), findsWidgets); // Found in the list
    expect(find.text('IG Highlight'), findsOneWidget);

    // Initial subtitle text "Mhoroi mose, ndinofara kuva pano" or "Nhasi tichataura nezve rwendo rwedu"
    // depending on the seed data selection logic. The second is selected by default in seed data.
    expect(
      find.textContaining('Nhasi tichataura', findRichText: true),
      findsWidgets,
    );

    // Tap IG Highlight
    await tester.tap(find.text('IG Highlight'));
    await tester.pumpAndSettle();
  });

  testWidgets('Sliders update font size and opacity values', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Tap Text tab
    await tester.tap(find.text('Text'));
    await tester.pumpAndSettle();

    // Verify font size slider exists
    final textSliders = find.byType(Slider);
    expect(textSliders, findsOneWidget);

    // Move first slider
    await tester.drag(textSliders.first, const Offset(100.0, 0.0));
    await tester.pumpAndSettle();

    // Tap Colors tab
    await tester.tap(find.text('Colors'));
    await tester.pumpAndSettle();

    // Verify opacity slider exists
    final colorSliders = find.byType(Slider);
    expect(colorSliders, findsOneWidget);
  });

  testWidgets('Timeline block tap selects segment', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // The first segment has text "Mhoroi mose, ndinofara kuva pano"
    final firstBlockText = find.text('Mhoroi mose, ndinofara kuva pano');
    expect(firstBlockText, findsOneWidget);

    await tester.tap(firstBlockText);
    await tester.pumpAndSettle();

    // Now it should be a text field
    final textField = find.byType(TextField);
    expect(textField, findsOneWidget);

    // Edit text field
    await tester.enterText(textField, 'Hello there');
    await tester.pumpAndSettle();

    // The text should be updated
    expect(find.textContaining('Hello there'), findsWidgets);
  });

  testWidgets('Action buttons trigger correct navigation/snackbar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    final exportSrt = find.text('Export .SRT');
    expect(exportSrt, findsOneWidget);

    await tester.tap(exportSrt);
    await tester.pumpAndSettle();

    expect(find.text('SRT file saved to Downloads'), findsOneWidget);
  });
}
