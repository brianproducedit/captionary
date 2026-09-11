import 'package:flutter_test/flutter_test.dart';
import 'package:captionary/core/media_library_query.dart';
import 'package:captionary/data/models/media_item.dart';

void main() {
  final older = DateTime(2026, 1, 1);
  final newer = DateTime(2026, 1, 2);

  MediaItem item({
    required String id,
    required String fileName,
    required DateTime importedAt,
    Duration duration = const Duration(seconds: 10),
    String filePath = '',
  }) {
    return MediaItem(
      id: id,
      fileName: fileName,
      filePath: filePath.isEmpty ? '/tmp/$fileName' : filePath,
      fileSizeBytes: 1000,
      resolution: '1080x1920',
      duration: duration,
      status: MediaStatus.newItem,
      importedAt: importedAt,
    );
  }

  test('sorts by recent with importedAt tie-break', () {
    final a = item(id: 'a', fileName: 'a.mp4', importedAt: older);
    final b = item(id: 'b', fileName: 'b.mp4', importedAt: newer);
    final result = MediaLibraryQuery.apply(
      items: [a, b],
      filter: MediaLibraryFilter.all,
      sort: MediaLibrarySort.recent,
    );
    expect(result.map((e) => e.id), ['b', 'a']);
  });

  test('sorts by name then importedAt', () {
    final a = item(id: 'a', fileName: 'clip.mp4', importedAt: older);
    final b = item(id: 'b', fileName: 'Clip.mp4', importedAt: newer);
    final c = item(id: 'c', fileName: 'zebra.mp4', importedAt: newer);
    final result = MediaLibraryQuery.apply(
      items: [c, a, b],
      filter: MediaLibraryFilter.all,
      sort: MediaLibrarySort.name,
    );
    expect(result.map((e) => e.id), ['b', 'a', 'c']);
  });

  test('sorts by duration then importedAt', () {
    final shortOld = item(
      id: 'short-old',
      fileName: 's.mp4',
      importedAt: older,
      duration: const Duration(seconds: 5),
    );
    final shortNew = item(
      id: 'short-new',
      fileName: 's2.mp4',
      importedAt: newer,
      duration: const Duration(seconds: 5),
    );
    final long = item(
      id: 'long',
      fileName: 'l.mp4',
      importedAt: older,
      duration: const Duration(seconds: 50),
    );
    final result = MediaLibraryQuery.apply(
      items: [shortOld, long, shortNew],
      filter: MediaLibraryFilter.all,
      sort: MediaLibrarySort.duration,
    );
    expect(result.map((e) => e.id), ['long', 'short-new', 'short-old']);
  });

  test('filters video, audio, and exported', () {
    final video = item(id: 'v', fileName: 'talk.mp4', importedAt: newer);
    final audio = item(id: 'a', fileName: 'voice.mp3', importedAt: newer);
    final exported = item(
      id: 'e',
      fileName: 'talk_captionary_1.mp4',
      importedAt: newer,
    );

    expect(
      MediaLibraryQuery.apply(
        items: [video, audio, exported],
        filter: MediaLibraryFilter.audio,
        sort: MediaLibrarySort.recent,
      ).map((e) => e.id),
      ['a'],
    );
    expect(
      MediaLibraryQuery.apply(
        items: [video, audio, exported],
        filter: MediaLibraryFilter.exported,
        sort: MediaLibrarySort.recent,
      ).map((e) => e.id),
      ['e'],
    );
    expect(
      MediaLibraryQuery.apply(
        items: [video, audio, exported],
        filter: MediaLibraryFilter.video,
        sort: MediaLibrarySort.recent,
      ).map((e) => e.id),
      ['v', 'e'],
    );
  });
}
