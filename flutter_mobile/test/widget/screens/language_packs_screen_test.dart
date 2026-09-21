import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:captionary/providers/backend_mode_provider.dart';
import 'package:captionary/screens/language_packs_screen.dart';
import 'package:material_symbols_icons/symbols.dart';

void main() {
  Widget buildTestWidget() {
    return ProviderScope(
      overrides: [backendModeProvider.overrideWithValue(BackendMode.mock)],
      child: const MaterialApp(home: LanguagePacksScreen()),
    );
  }

  testWidgets('LanguagePacksScreen renders and filters properly', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildTestWidget());
    await tester.pump();
    await tester.pump(
      const Duration(milliseconds: 600),
    ); // wait for Provider data

    // Check if initial items are rendered
    expect(find.text('English (English)'), findsOneWidget);
    expect(find.text('Shona (chiShona)'), findsOneWidget);
    expect(find.text('Swahili (Kiswahili)'), findsOneWidget);

    // Search for "Shona"
    await tester.enterText(find.byType(TextField), 'shona');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify filter results
    expect(find.text('Shona (chiShona)'), findsOneWidget);
    expect(find.text('Swahili (Kiswahili)'), findsNothing);
    expect(find.text('English (English)'), findsNothing);
  });

  testWidgets('Download flow triggers correctly', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildTestWidget());
    await tester.pump();
    await tester.pump(
      const Duration(milliseconds: 600),
    ); // wait for Provider data

    // Swahili should be available to download
    final downloadButton = find.textContaining('Download').first;
    expect(downloadButton, findsWidgets);

    // Tap "Download" button for the first not-downloaded pack
    await tester.tap(downloadButton);
    await tester.pump();

    // The state changes to downloading
    await tester.pump(const Duration(milliseconds: 300));

    // Check if "Close/Abort" icon button appears indicating downloading state
    expect(find.byIcon(Symbols.close), findsWidgets);

    // Fast forward to complete the download mock (takes about 4 seconds mock time)
    for (int i = 0; i < 25; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  });

  testWidgets('Delete confirmation dialog works', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildTestWidget());
    await tester.pump();
    await tester.pump(
      const Duration(milliseconds: 600),
    ); // wait for Provider data

    // Let's trigger a long press on the Shona card.
    await tester.longPress(find.text('Shona (chiShona)'));
    await tester.pumpAndSettle();

    // Verify dialog shows
    expect(find.text('Delete Shona?'), findsOneWidget);

    // Tap cancel
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // Tap delete button icon directly
    final deleteIconBtn = find.byType(IconButton).first;
    await tester.tap(deleteIconBtn);
    await tester.pumpAndSettle();

    expect(find.text('Delete Shona?'), findsOneWidget);

    // Tap Delete
    await tester.tap(find.text('Delete'));
    await tester.pump();
    await tester.pump(
      const Duration(milliseconds: 400),
    ); // Wait for mock delete

    // Shona is now deleted and shows a download button again
    expect(find.textContaining('Download'), findsWidgets);
  });
}
