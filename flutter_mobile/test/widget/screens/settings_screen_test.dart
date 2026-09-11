import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:captionary/screens/settings_screen.dart';

void main() {
  Widget buildTestWidget() {
    final router = GoRouter(
      initialLocation: '/settings',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('Home')),
        ),
        GoRoute(
          path: '/settings',
          builder: (_, _) => const SettingsScreen(),
        ),
      ],
    );

    return MaterialApp.router(
      routerConfig: router,
    );
  }

  testWidgets('Settings Screen renders sections and dropdown updates', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Verify sections exist
    expect(find.text('GENERAL'), findsOneWidget);
    expect(find.text('PLAYBACK & EXPORT'), findsOneWidget);
    expect(find.text('SYSTEM'), findsOneWidget);
    expect(find.text('ABOUT'), findsOneWidget);

    // Verify default dropdown value
    expect(find.text('Auto'), findsOneWidget);

    // Scroll to the Auto dropdown before tapping
    await tester.dragUntilVisible(
      find.text('Auto').first,
      find.byType(SingleChildScrollView),
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();

    // Open Dropdown
    await tester.tap(find.text('Auto').first);
    await tester.pumpAndSettle();

    // Select new value
    await tester.tap(find.text('High (6GB+)').last);
    await tester.pumpAndSettle();

    // Verify new value is selected
    expect(find.text('High (6GB+)'), findsWidgets);
  });

  testWidgets('Settings Screen notification toggle updates state', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Verify list tile exists
    expect(find.text('Donate Reminders'), findsOneWidget);

    // Verify frequency dropdown exists when switch is on (default is true)
    expect(find.text('Frequency'), findsOneWidget);

    // Toggle switch off by tapping the Custom Switch (which contains AnimatedAlign)
    await tester.tap(find.byType(AnimatedAlign).first);
    await tester.pumpAndSettle();

    // Verify switch is off by checking if frequency dropdown disappeared
    expect(find.text('Frequency'), findsNothing);
  });

  testWidgets('Settings Screen renders About section', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('App Version'), findsOneWidget);
    expect(find.text('1.0.0 (Build 42)'), findsOneWidget);
    expect(find.text('Open Source License'), findsOneWidget);
  });
}
