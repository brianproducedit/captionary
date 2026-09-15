import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/media_item.dart';
import 'media_service.dart';
import 'file_import_service.dart';
import 'ffmpeg_metadata_service.dart';
import 'ffmpeg_thumbnail_service.dart';

class LocalMediaService implements MediaService {
  final FileImportService _importService;
  final FFmpegMetadataService _metadataService;
  final FFmpegThumbnailService _thumbnailService;
  final Future<Directory> Function()? _getAppSupportDir;
  final Future<String?> Function(String videoPath)? _customThumbnailGenerator;

  final List<MediaItem> _cache = [];
  bool _isLoaded = false;

  LocalMediaService({
    FileImportService? importService,
    FFmpegMetadataService? metadataService,
    FFmpegThumbnailService? thumbnailService,
    this._getAppSupportDir,
    this._customThumbnailGenerator,
  }) : _importService = importService ?? FileImportService(),
       _metadataService = metadataService ?? FFmpegMetadataService(),
       _thumbnailService = thumbnailService ?? FFmpegThumbnailService();

  Future<File> _getMetadataFile() async {
    final Directory dir;
    if (_getAppSupportDir != null) {
      dir = await _getAppSupportDir();
    } else {
      dir = await getApplicationSupportDirectory();
    }
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return File('${dir.path}/media_items.json');
  }

  Future<void> _ensureLoaded() async {
    if (_isLoaded) return;
    try {
      final file = await _getMetadataFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.trim().isNotEmpty) {
          final List<dynamic> jsonList = jsonDecode(content) as List<dynamic>;
          _cache.clear();
          for (final raw in jsonList) {
            if (raw is Map<String, dynamic>) {
              final item = MediaItem.fromJson(raw);
              // Verify file existence on disk; if missing, flag as error
              final exists = await File(item.filePath).exists();
              if (!exists) {
                _cache.add(item.copyWith(status: MediaStatus.error));
              } else {
                _cache.add(item);
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[LocalMediaService] Error loading media metadata: $e');
    } finally {
      _isLoaded = true;
    }
  }

  Future<void> _saveToDisk() async {
    try {
      final file = await _getMetadataFile();
      final jsonList = _cache.map((item) => item.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList), flush: true);
    } catch (e) {
      debugPrint('[LocalMediaService] Error saving media metadata: $e');
    }
  }

  @override
  Future<List<MediaItem>> getRecentMedia() async {
    await _ensureLoaded();
    // Return a defensive copy with refreshed existence check
    final result = <MediaItem>[];
    for (final item in _cache) {
      final exists = await File(item.filePath).exists();
      if (!exists && item.status != MediaStatus.error) {
        result.add(item.copyWith(status: MediaStatus.error));
      } else {
        result.add(item);
      }
    }
    return result;
  }

  @override
  Future<MediaItem?> importVideo() async {
    await _ensureLoaded();

    final originalPath = await _importService.pickVideoFile();
    if (originalPath == null) return null;

    String? cachedPath;
    try {
      cachedPath = await _importService.copyToCache(originalPath);
      final metadata = await _metadataService.extractMetadata(cachedPath);

      final isAudio = MediaItem(
        id: '',
        fileName: originalPath.split(RegExp(r'[\\/]')).last,
        filePath: cachedPath,
        fileSizeBytes: 0,
        resolution: '',
        duration: Duration.zero,
        status: MediaStatus.newItem,
        importedAt: DateTime.now(),
      ).isAudio;

      String? thumbnailPath;
      if (!isAudio) {
        if (_customThumbnailGenerator != null) {
          thumbnailPath = await _customThumbnailGenerator(cachedPath);
        } else {
          thumbnailPath = await _thumbnailService.generateThumbnail(cachedPath);
        }
      }

      final item = MediaItem(
        id: const Uuid().v4(),
        fileName: originalPath.split(RegExp(r'[\\/]')).last,
        filePath: cachedPath,
        thumbnailPath: thumbnailPath ?? '',
        duration: metadata?['duration'] ?? Duration.zero,
        resolution: metadata?['resolution'] ?? 'Unknown',
        fileSizeBytes:
            metadata?['sizeBytes'] ?? (await File(cachedPath).length()),
        status: MediaStatus.newItem,
        detectedLanguage: null,
        importedAt: DateTime.now(),
      );

      _cache.insert(0, item);
      await _saveToDisk();
      return item;
    } catch (e) {
      debugPrint('[LocalMediaService] Failed to import video: $e');
      // Failed copy cleanup
      if (cachedPath != null) {
        await _importService.deleteCachedFile(cachedPath);
      }
      return null;
    }
  }

  @override
  Future<void> deleteMedia(String id) async {
    await _ensureLoaded();
    final index = _cache.indexWhere((item) => item.id == id);
    if (index != -1) {
      final item = _cache[index];
      // Clean up cached media file
      await _importService.deleteCachedFile(item.filePath);
      // Clean up thumbnail
      if (item.thumbnailPath != null && item.thumbnailPath!.isNotEmpty) {
        await _thumbnailService.deleteThumbnail(item.thumbnailPath);
      }
      _cache.removeAt(index);
      await _saveToDisk();
    }
  }

  @override
  Future<MediaItem> getMediaById(String id) async {
    await _ensureLoaded();
    return _cache.firstWhere(
      (item) => item.id == id,
      orElse: () => throw Exception('Media item with id $id not found'),
    );
  }
}
