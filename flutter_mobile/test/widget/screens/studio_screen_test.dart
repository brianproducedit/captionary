import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:captionary/screens/studio_screen.dart';

void main() {
  Widget buildTestWidget() {
    return const ProviderScope(child: MaterialApp(home: StudioScreen()));
  }

  testWidgets('Style button opens the stylization sheet with equal presets', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    await tester.tap(find.text('Style'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('TikTok Bold'), findsWidgets);
    expect(find.text('IG Highlight'), findsOneWidget);
    expect(find.text('Presets'), findsOneWidget);
  });

  testWidgets('Timeline chip is visible on the studio canvas', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    expect(find.text('Mhoroi mose, ndinofara kuva pano'), findsWidgets);
  });

  testWidgets('Export captions opens the format sheet', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildTestWidget());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final export = find.text('Export captions');
    expect(export, findsOneWidget);

    await tester.tap(export);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('SRT'), findsOneWidget);
    expect(find.text('VTT'), findsOneWidget);
    expect(find.text('ASS'), findsOneWidget);
  });
}
