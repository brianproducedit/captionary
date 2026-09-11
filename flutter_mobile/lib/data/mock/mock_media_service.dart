import '../services/media_service.dart';
import '../models/media_item.dart';
import 'seed_data.dart';

class MockMediaService implements MediaService {
  @override
  Future<List<MediaItem>> getRecentMedia() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return SeedData.recentMedia;
  }

  @override
  Future<MediaItem?> importVideo() async {
    await Future.delayed(const Duration(seconds: 1));
    return SeedData.recentMedia.first;
  }

  @override
  Future<void> deleteMedia(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<MediaItem> getMediaById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return SeedData.recentMedia.firstWhere(
      (m) => m.id == id,
      orElse: () => SeedData.recentMedia.first,
    );
  }
}
