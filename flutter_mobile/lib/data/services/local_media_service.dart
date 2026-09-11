import 'package:uuid/uuid.dart';
import '../models/media_item.dart';
import 'media_service.dart';
import 'file_import_service.dart';
import 'ffmpeg_metadata_service.dart';

class LocalMediaService implements MediaService {
  final FileImportService _importService = FileImportService();
  final FFmpegMetadataService _metadataService = FFmpegMetadataService();
  
  final List<MediaItem> _cache = [];

  @override
  Future<List<MediaItem>> getRecentMedia() async {
    return _cache;
  }

  @override
  Future<MediaItem?> importVideo() async {
    final originalPath = await _importService.pickVideoFile();
    if (originalPath == null) return null;

    final cachedPath = await _importService.copyToCache(originalPath);
    final metadata = await _metadataService.extractMetadata(cachedPath);

    final item = MediaItem(
      id: const Uuid().v4(),
      fileName: originalPath.split(RegExp(r'[\\/]')).last,
      filePath: cachedPath,
      thumbnailPath: '', // Generate thumbnail later if needed
      duration: metadata?['duration'] ?? Duration.zero,
      resolution: metadata?['resolution'] ?? 'Unknown',
      fileSizeBytes: metadata?['sizeBytes'] ?? 0,
      status: MediaStatus.newItem,
      detectedLanguage: null,
      importedAt: DateTime.now(),
    );

    _cache.insert(0, item);
    return item;
  }

  @override
  Future<void> deleteMedia(String id) async {
    _cache.removeWhere((item) => item.id == id);
  }

  @override
  Future<MediaItem> getMediaById(String id) async {
    return _cache.firstWhere((item) => item.id == id);
  }
}
