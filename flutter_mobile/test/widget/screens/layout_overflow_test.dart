import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:captionary/data/models/media_item.dart';
import 'package:captionary/data/services/media_service.dart';
import 'package:captionary/providers/media_provider.dart';
import 'package:captionary/screens/media_library_screen.dart';
import 'package:captionary/screens/donate_screen.dart';

class _FakeMediaService implements MediaService {
  _FakeMediaService(this.items);
  final List<MediaItem> items;
  @override
  Future<List<MediaItem>> getRecentMedia() async => List.of(items);
  @override
  Future<MediaItem?> importVideo() async => null;
  @override
  Future<void> deleteMedia(String id) async {}
  @override
  Future<MediaItem> getMediaById(String id) async => items.first;
}

void main() {
  testWidgets(
    'MediaLibraryScreen renders without overflow on phone dimensions',
    (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final item1 = MediaItem(
        id: 'item1',
        fileName: 'Afrobeats_Snippet.mp4',
        filePath: '/tmp/afro.mp4',
        fileSizeBytes: 11 * 1024 * 1024,
        resolution: '1080x1920',
        duration: const Duration(seconds: 15),
        status: MediaStatus.readyToEdit,
        importedAt: DateTime.now(),
      );

      final router = GoRouter(
        initialLocation: '/library',
        routes: [
          GoRoute(
            path: '/library',
            builder: (_, _) => const MediaLibraryScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mediaServiceProvider.overrideWithValue(_FakeMediaService([item1])),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('media-card-item1')), findsOneWidget);

      final gridFinder = find.byKey(const ValueKey('library-grid'));
      expect(gridFinder, findsOneWidget);
      final gridWidget = tester.widget<GridView>(gridFinder);
      expect(gridWidget.padding, EdgeInsets.zero);
    },
  );

  testWidgets('DonateScreen renders correctly with distinct mission cards', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: DonateScreen())),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
    expect(find.text('Donate to Independent AI Speech'), findsOneWidget);
    expect(find.text('Web Donation Gateway'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Cloudflare R2 Bandwidth'), 100);
    expect(find.text('Cloudflare R2 Bandwidth'), findsOneWidget);
  });
}
