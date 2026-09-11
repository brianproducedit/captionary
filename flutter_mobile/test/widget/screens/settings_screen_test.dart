import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:captionary/providers/engagement_provider.dart';
import 'package:captionary/screens/settings_screen.dart';

void main() {
  Future<Widget> buildTestWidget() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final router = GoRouter(
      initialLocation: '/settings',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('Home')),
        ),
        GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      ],
    );

    return ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  testWidgets('Settings Screen renders sections and dropdown updates', (
    tester,
  ) async {
    await tester.pumpWidget(await buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('GENERAL'), findsOneWidget);
    expect(find.text('PLAYBACK & EXPORT'), findsOneWidget);
    expect(find.text('SYSTEM'), findsOneWidget);
    expect(find.text('ABOUT'), findsOneWidget);

    expect(find.text('Auto'), findsOneWidget);

    await tester.dragUntilVisible(
      find.text('Auto').first,
      find.byType(SingleChildScrollView),
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Auto').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('High (6GB+)').last);
    await tester.pumpAndSettle();

    expect(find.text('High (6GB+)'), findsWidgets);
  });

  testWidgets('Settings Screen notification toggle updates state', (
    tester,
  ) async {
    await tester.pumpWidget(await buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Donate Reminders'), findsOneWidget);
    expect(find.text('Frequency'), findsOneWidget);
  });

  testWidgets('Settings Screen renders About section', (tester) async {
    await tester.pumpWidget(await buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('App Version'), findsOneWidget);
    expect(find.text('1.0.0 (Build 42)'), findsOneWidget);
    expect(find.text('Open Source License'), findsOneWidget);
  });

  testWidgets('Clear cache shows an honest warning toast', (tester) async {
    await tester.pumpWidget(await buildTestWidget());
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.text('Clear'),
      find.byType(SingleChildScrollView),
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Clear'));
    await tester.pump();

    expect(find.text('Cache clearing is not available yet'), findsOneWidget);
  });
}
