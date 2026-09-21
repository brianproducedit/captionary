import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:captionary/providers/engagement_provider.dart';
import 'package:captionary/screens/upgrade_pro_screen.dart';
import 'package:captionary/widgets/pro_teaser_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'captionary_anonymous_device_id': 'test-uuid-1234-5678-90ab',
    });
    prefs = await SharedPreferences.getInstance();
  });

  Widget buildTestableWidget() {
    return ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const MaterialApp(home: UpgradeProScreen()),
    );
  }

  testWidgets('UpgradeProScreen displays all three tiers and device id', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    // Verify header and title
    expect(find.text('Supercharge Your Videos'), findsOneWidget);
    expect(find.text('Choose Your Plan'), findsOneWidget);

    // Verify 3 tiers
    expect(find.text('Creator Pro'), findsOneWidget);
    expect(find.text('\$7.99'), findsOneWidget);

    expect(find.text('24-Hour Pass'), findsOneWidget);
    expect(find.text('\$0.99'), findsOneWidget);

    expect(find.text('Free Beta'), findsOneWidget);
    expect(find.text('\$0'), findsOneWidget);

    // Scroll down to reveal Device ID card in ListView
    await tester.scrollUntilVisible(
      find.text('test-uuid-1234-5678-90ab'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    // Verify Device ID display
    expect(find.text('test-uuid-1234-5678-90ab'), findsOneWidget);
  });

  testWidgets('Tapping Unlock Creator Pro opens ProTeaserSheet', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    // Tap Creator Pro action button
    final ctaButton = find.text('Unlock Creator Pro (Coming Soon)');
    expect(ctaButton, findsOneWidget);

    await tester.tap(ctaButton);
    await tester.pumpAndSettle();

    // Verify teaser modal is opened
    expect(find.byType(ProTeaserSheet), findsOneWidget);
    expect(find.text('PREMIUM UNLOCKS COMING SOON'), findsOneWidget);
  });
}
