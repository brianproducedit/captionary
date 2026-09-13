import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:captionary/data/models/media_item.dart';
import 'package:captionary/data/services/media_service.dart';
import 'package:captionary/providers/engagement_provider.dart';
import 'package:captionary/providers/media_provider.dart';
import 'package:captionary/screens/media_library_screen.dart';
import 'package:captionary/screens/settings_screen.dart';
import 'package:captionary/widgets/donate_banner.dart';

/// Required tappable controls. Fail this test if a handler is removed.
void main() {
  Future<SharedPreferences> prefs() async {
    SharedPreferences.setMockInitialValues({});
    return SharedPreferences.getInstance();
  }

  testWidgets('library view toggle and donate banner are wired', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(await prefs()),
          mediaServiceProvider.overrideWithValue(_EmptyMedia()),
        ],
        child: MaterialApp(
          home: const MediaLibraryScreen(),
          routes: {'/donate': (_) => const Scaffold(body: Text('Donate'))},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final viewToggle = tester.widget<IconButton>(
      find.byKey(const ValueKey('library-view-toggle')),
    );
    expect(viewToggle.onPressed, isNotNull);
    expect(find.byType(DonateBanner), findsOneWidget);
  });

  testWidgets('settings autoplay and license rows are wired', (tester) async {
    tester.view.physicalSize = const Size(1080, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(await prefs())],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/settings',
            routes: [
              GoRoute(
                path: '/settings',
                builder: (_, _) => const SettingsScreen(),
              ),
              GoRoute(
                path: '/donate',
                builder: (_, _) => const Scaffold(body: Text('Donate')),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('settings-autoplay')), findsOneWidget);
    final license = tester.widget<ListTile>(
      find.byKey(const ValueKey('settings-license')),
    );
    expect(license.onTap, isNotNull);
  });
}

class _EmptyMedia implements MediaService {
  @override
  Future<List<MediaItem>> getRecentMedia() async => [];

  @override
  Future<MediaItem?> importVideo() async => null;

  @override
  Future<void> deleteMedia(String id) async {}

  @override
  Future<MediaItem> getMediaById(String id) async {
    throw StateError('empty');
  }
}
