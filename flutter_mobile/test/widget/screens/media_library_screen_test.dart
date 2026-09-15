import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:captionary/data/models/media_item.dart';
import 'package:captionary/data/services/media_service.dart';
import 'package:captionary/providers/media_provider.dart';
import 'package:captionary/screens/media_library_screen.dart';
import 'package:captionary/widgets/donate_banner.dart';

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

MediaItem _item({
  required String id,
  required String fileName,
  required DateTime importedAt,
  Duration duration = const Duration(seconds: 12),
}) {
  return MediaItem(
    id: id,
    fileName: fileName,
    filePath: '/tmp/$fileName',
    fileSizeBytes: 2 * 1024 * 1024,
    resolution: '1080x1920',
    duration: duration,
    status: MediaStatus.readyToEdit,
    importedAt: importedAt,
  );
}

void main() {
  final older = DateTime(2026, 1, 1);
  final newer = DateTime(2026, 2, 1);

  List<MediaItem> sampleItems() => [
    _item(id: 'video', fileName: 'Zebra.mp4', importedAt: older),
    _item(
      id: 'audio',
      fileName: 'Alpha.mp3',
      importedAt: newer,
      duration: const Duration(seconds: 90),
    ),
    _item(
      id: 'export',
      fileName: 'clip_captionary_9.mp4',
      importedAt: DateTime(2026, 1, 15),
    ),
  ];

  Future<void> pumpLibrary(
    WidgetTester tester, {
    required List<MediaItem> items,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: '/library',
      routes: [
        GoRoute(
          path: '/library',
          builder: (_, _) => const MediaLibraryScreen(),
        ),
        GoRoute(
          path: '/donate',
          builder: (_, _) => const Scaffold(body: Text('Donate page')),
        ),
        GoRoute(
          path: '/languages',
          builder: (_, _) => const Scaffold(body: Text('Languages page')),
        ),
        GoRoute(
          path: '/studio',
          builder: (_, _) => const Scaffold(body: Text('Studio page')),
        ),
        GoRoute(
          path: '/player',
          builder: (_, _) => const Scaffold(body: Text('Player page')),
        ),
        GoRoute(
          path: '/transcription',
          builder: (_, _) => const Scaffold(body: Text('Transcription page')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mediaServiceProvider.overrideWithValue(_FakeMediaService(items)),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('shows empty state when there is no media', (tester) async {
    await pumpLibrary(tester, items: []);

    expect(find.text('No media yet'), findsOneWidget);
    expect(find.text('Browse Media'), findsOneWidget);
    expect(find.text('2.4 GB Cached'), findsNothing);
    expect(find.text('5 Models Installed'), findsNothing);
  });

  testWidgets('sorts by name and filters audio', (tester) async {
    await pumpLibrary(tester, items: sampleItems());

    expect(find.byKey(const ValueKey('media-card-video')), findsOneWidget);
    expect(find.byKey(const ValueKey('media-card-audio')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('library-sort')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Name').last);
    await tester.pumpAndSettle();

    final cards = tester
        .widgetList<GestureDetector>(
          find.byWidgetPredicate(
            (widget) =>
                widget is GestureDetector &&
                widget.key is ValueKey<String> &&
                (widget.key as ValueKey<String>).value.startsWith(
                  'media-card-',
                ),
          ),
        )
        .toList();
    expect((cards.first.key as ValueKey<String>).value, 'media-card-audio');

    await tester.tap(find.byKey(const ValueKey('library-filter-Audio')));
    await tester.pump();

    expect(find.byKey(const ValueKey('media-card-audio')), findsOneWidget);
    expect(find.byKey(const ValueKey('media-card-video')), findsNothing);
    expect(find.text('1'), findsWidgets);
  });

  testWidgets('filtered-empty state can clear filters', (tester) async {
    await pumpLibrary(
      tester,
      items: [_item(id: 'v', fileName: 'only.mp4', importedAt: newer)],
    );

    await tester.tap(find.byKey(const ValueKey('library-filter-Audio')));
    await tester.pump();

    expect(find.text('No matching media'), findsOneWidget);
    await tester.tap(find.text('Clear filters'));
    await tester.pump();

    expect(find.byKey(const ValueKey('media-card-v')), findsOneWidget);
  });

  testWidgets('toggles list and grid with the same cards', (tester) async {
    await pumpLibrary(tester, items: sampleItems());

    expect(find.byKey(const ValueKey('library-grid')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('library-view-toggle')));
    await tester.pump();

    expect(find.byKey(const ValueKey('library-list')), findsOneWidget);
    expect(find.byKey(const ValueKey('media-card-video')), findsOneWidget);
    expect(find.byKey(const ValueKey('media-card-audio')), findsOneWidget);
  });

  testWidgets('Donate banner navigates to donate', (tester) async {
    await pumpLibrary(tester, items: sampleItems());

    await tester.tap(find.byType(DonateBanner));
    await tester.pumpAndSettle();

    expect(find.text('Donate page'), findsOneWidget);
  });

  testWidgets('long titles do not overflow', (tester) async {
    await pumpLibrary(
      tester,
      items: [
        _item(
          id: 'long',
          fileName: 'this_is_an_extremely_long_media_file_name_that_should_ellipsis.mp4',
          importedAt: newer,
        ),
      ],
    );

    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('media-card-long')), findsOneWidget);
  });

  testWidgets(
    'missing file displays Missing File chip and shows dialog on tap',
    (tester) async {
      final missingItem = MediaItem(
        id: 'missing-1',
        fileName: 'deleted_video.mp4',
        filePath: '/non/existent/path/deleted_video.mp4',
        fileSizeBytes: 1024,
        resolution: '1920x1080',
        duration: const Duration(seconds: 10),
        status: MediaStatus.error,
        importedAt: DateTime.now(),
      );

      await pumpLibrary(tester, items: [missingItem]);

      expect(find.text('Missing File'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('media-card-missing-1')));
      await tester.pumpAndSettle();

      expect(find.text('Missing Media File'), findsOneWidget);
      expect(find.text('Remove from Library'), findsOneWidget);
    },
  );
}
