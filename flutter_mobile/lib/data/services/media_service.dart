import '../models/media_item.dart';

abstract class MediaService {
  Future<List<MediaItem>> getRecentMedia();
  Future<MediaItem?> importVideo();
  Future<void> deleteMedia(String id);
  Future<MediaItem> getMediaById(String id);
}
