import '../data/models/media_item.dart';

enum MediaLibrarySort { recent, name, duration }

enum MediaLibraryFilter { all, video, audio, exported }

/// Pure sort/filter used by the media library UI.
class MediaLibraryQuery {
  static List<MediaItem> apply({
    required List<MediaItem> items,
    required MediaLibraryFilter filter,
    required MediaLibrarySort sort,
  }) {
    final filtered = items.where((item) {
      switch (filter) {
        case MediaLibraryFilter.all:
          return true;
        case MediaLibraryFilter.video:
          return item.isVideo;
        case MediaLibraryFilter.audio:
          return item.isAudio;
        case MediaLibraryFilter.exported:
          return item.isExported;
      }
    }).toList();

    filtered.sort((a, b) {
      final comparison = switch (sort) {
        MediaLibrarySort.recent => b.importedAt.compareTo(a.importedAt),
        MediaLibrarySort.name => a.fileName.toLowerCase().compareTo(
          b.fileName.toLowerCase(),
        ),
        MediaLibrarySort.duration => b.duration.compareTo(a.duration),
      };
      if (comparison != 0) return comparison;
      return b.importedAt.compareTo(a.importedAt);
    });

    return filtered;
  }
}
