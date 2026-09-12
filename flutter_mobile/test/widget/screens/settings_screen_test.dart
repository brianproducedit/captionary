import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:captionary/core/constants/app_constants.dart';
import 'package:captionary/core/user_preferences.dart';
import 'package:captionary/providers/engagement_provider.dart';
import 'package:captionary/providers/preferences_provider.dart';
import 'package:captionary/providers/url_open_provider.dart';
import 'package:captionary/screens/settings_screen.dart';

void main() {
  Future<Widget> buildSettings({
    Map<String, Object> initial = const {},
    UrlOpenHandler? openUrl,
  }) async {
    SharedPreferences.setMockInitialValues(initial);
    final prefs = await SharedPreferences.getInstance();
    final router = GoRouter(
      initialLocation: '/settings',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('Home')),
        ),
        GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
        GoRoute(
          path: '/donate',
          builder: (_, _) => const Scaffold(body: Text('Donate')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appPackageInfoProvider.overrideWithValue(
          const AppPackageInfo(version: '1.0.0', buildNumber: '1'),
        ),
        if (openUrl != null)
          urlOpenHandlerProvider.overrideWith((ref) => openUrl),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  testWidgets('Settings renders persisted playback and ram values', (
    tester,
  ) async {
    await tester.pumpWidget(
      await buildSettings(
        initial: {
          PreferenceKeys.ramTier: 'High (6GB+)',
          PreferenceKeys.exportQuality: '720p',
          PreferenceKeys.autoPlay: true,
        },
      ),
    );
    await tester.pump();

    expect(find.text('GENERAL'), findsOneWidget);
    expect(find.text('High (6GB+)'), findsOneWidget);
    expect(find.text('720p'), findsOneWidget);
    expect(find.text('1.0.0+1'), findsOneWidget);
    expect(find.text('Clear'), findsOneWidget);
  });

  testWidgets('Auto-play switch persists', (tester) async {
    await tester.pumpWidget(await buildSettings());
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('settings-autoplay')));
    await tester.pump();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(PreferenceKeys.autoPlay), isTrue);
  });

  testWidgets('License row opens the AGPL URL', (tester) async {
    Uri? opened;
    await tester.pumpWidget(
      await buildSettings(
        openUrl: (uri) async {
          opened = uri;
          return true;
        },
      ),
    );
    await tester.pump();

    await tester.dragUntilVisible(
      find.byKey(const ValueKey('settings-license')),
      find.byType(SingleChildScrollView),
      const Offset(0, -240),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('settings-license')));
    await tester.pump();

    expect(opened, Uri.parse(AppConstants.licenseUrl));
  });

  testWidgets('Reset restores defaults', (tester) async {
    await tester.pumpWidget(
      await buildSettings(
        initial: {PreferenceKeys.exportQuality: '1440p'},
      ),
    );
    await tester.pump();
    expect(find.text('1440p'), findsOneWidget);

    await tester.dragUntilVisible(
      find.byKey(const ValueKey('settings-reset')),
      find.byType(SingleChildScrollView),
      const Offset(0, -240),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('settings-reset')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(PreferenceKeys.exportQuality), '1080p');
  });
}
