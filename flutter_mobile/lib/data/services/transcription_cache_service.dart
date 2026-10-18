import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/cached_transcription.dart';

/// Service responsible for persisting and retrieving cached video transcriptions.
///
/// Prevents redundant AI transcription runs when a video has already been
/// transcribed in a previous session, even if the user didn't export or save.
class TranscriptionCacheService {
  final Future<Directory> Function()? customDirProvider;
  final Map<String, CachedTranscription> _memoryCache = {};
  bool _initialized = false;

  TranscriptionCacheService({this.customDirProvider});

  Future<Directory> _getCacheDirectory() async {
    final Directory baseDir;
    if (customDirProvider != null) {
      baseDir = await customDirProvider!();
    } else {
      baseDir = await getApplicationSupportDirectory();
    }
    final cacheDir = Directory(p.join(baseDir.path, 'transcription_cache'));
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  /// Generates a deterministic hash key from the video path.
  String _cacheKeyForPath(String videoPath) {
    final normalized = p.normalize(videoPath).toLowerCase();
    return sha256.convert(utf8.encode(normalized)).toString().substring(0, 32);
  }

  /// Generates a secondary fallback key from a mediaId.
  String _cacheKeyForMediaId(String mediaId) {
    final normalized = mediaId.trim().toLowerCase();
    return 'mid_${sha256.convert(utf8.encode(normalized)).toString().substring(0, 24)}';
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    try {
      final dir = await _getCacheDirectory();
      if (await dir.exists()) {
        await for (final entity in dir.list()) {
          if (entity is File && entity.path.endsWith('.json')) {
            try {
              final content = await entity.readAsString();
              if (content.trim().isNotEmpty) {
                final json = jsonDecode(content) as Map<String, dynamic>;
                final cached = CachedTranscription.fromJson(json);
                if (cached.segments.isNotEmpty) {
                  final key = _cacheKeyForPath(cached.videoPath);
                  _memoryCache[key] = cached;
                  if (cached.mediaId.isNotEmpty) {
                    _memoryCache[_cacheKeyForMediaId(cached.mediaId)] = cached;
                  }
                }
              }
            } catch (e) {
              debugPrint(
                '[TranscriptionCache] Corrupted cache file ${entity.path}: $e',
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[TranscriptionCache] Init error: $e');
    } finally {
      _initialized = true;
    }
  }

  /// Saves or updates a cached transcription to persistent disk storage.
  Future<void> saveTranscription(CachedTranscription transcription) async {
    if (transcription.segments.isEmpty) return;

    await _ensureInitialized();

    // Populate file metadata if video exists on disk
    int? fileSize;
    DateTime? lastModified;
    try {
      final file = File(transcription.videoPath);
      if (await file.exists()) {
        fileSize = await file.length();
        lastModified = await file.lastModified();
      }
    } catch (_) {}

    final enriched = transcription.copyWith(
      fileSizeBytes: fileSize ?? transcription.fileSizeBytes,
      lastModified: lastModified ?? transcription.lastModified,
      updatedAt: DateTime.now(),
    );

    final pathKey = _cacheKeyForPath(transcription.videoPath);
    _memoryCache[pathKey] = enriched;
    if (transcription.mediaId.isNotEmpty) {
      _memoryCache[_cacheKeyForMediaId(transcription.mediaId)] = enriched;
    }

    try {
      final dir = await _getCacheDirectory();
      final targetFile = File(p.join(dir.path, '$pathKey.json'));
      await targetFile.writeAsString(
        jsonEncode(enriched.toJson()),
        flush: true,
      );
    } catch (e) {
      debugPrint(
        '[TranscriptionCache] Error saving cache for ${transcription.videoPath}: $e',
      );
    }
  }

  /// Retrieves cached transcription by [videoPath] or fallback [mediaId].
  Future<CachedTranscription?> getCachedTranscription({
    required String videoPath,
    String? mediaId,
  }) async {
    if (videoPath.trim().isEmpty &&
        (mediaId == null || mediaId.trim().isEmpty)) {
      return null;
    }

    await _ensureInitialized();

    // 1. Try matching by exact normalized video path
    if (videoPath.trim().isNotEmpty) {
      final pathKey = _cacheKeyForPath(videoPath);
      final match = _memoryCache[pathKey];
      if (match != null && match.segments.isNotEmpty) {
        return match;
      }

      // Check directly on disk if not in memory
      try {
        final dir = await _getCacheDirectory();
        final file = File(p.join(dir.path, '$pathKey.json'));
        if (await file.exists()) {
          final content = await file.readAsString();
          final json = jsonDecode(content) as Map<String, dynamic>;
          final parsed = CachedTranscription.fromJson(json);
          _memoryCache[pathKey] = parsed;
          return parsed;
        }
      } catch (_) {}
    }

    // 2. Try matching by mediaId fallback
    if (mediaId != null && mediaId.trim().isNotEmpty) {
      final mediaKey = _cacheKeyForMediaId(mediaId);
      final match = _memoryCache[mediaKey];
      if (match != null && match.segments.isNotEmpty) {
        return match;
      }
    }

    // 3. Fallback: match by file basename
    if (videoPath.trim().isNotEmpty) {
      final targetBasename = p.basename(videoPath).toLowerCase();
      for (final cached in _memoryCache.values) {
        if (p.basename(cached.videoPath).toLowerCase() == targetBasename) {
          return cached;
        }
      }
    }

    return null;
  }

  /// Checks whether a valid cached transcription exists for this video.
  Future<bool> hasCachedTranscription({
    required String videoPath,
    String? mediaId,
  }) async {
    final cached = await getCachedTranscription(
      videoPath: videoPath,
      mediaId: mediaId,
    );
    return cached != null && cached.segments.isNotEmpty;
  }

  /// Deletes cached transcription for the specified video.
  Future<void> deleteCachedTranscription({
    required String videoPath,
    String? mediaId,
  }) async {
    await _ensureInitialized();

    final pathKey = _cacheKeyForPath(videoPath);
    _memoryCache.remove(pathKey);
    if (mediaId != null) {
      _memoryCache.remove(_cacheKeyForMediaId(mediaId));
    }

    try {
      final dir = await _getCacheDirectory();
      final file = File(p.join(dir.path, '$pathKey.json'));
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('[TranscriptionCache] Error deleting cache: $e');
    }
  }

  /// Returns all cached transcriptions.
  Future<List<CachedTranscription>> getAllCached() async {
    await _ensureInitialized();
    final unique = <String, CachedTranscription>{};
    for (final item in _memoryCache.values) {
      unique[item.videoPath] = item;
    }
    return unique.values.toList();
  }

  /// Clears the entire cache.
  Future<void> clearAll() async {
    _memoryCache.clear();
    try {
      final dir = await _getCacheDirectory();
      if (await dir.exists()) {
        await for (final entity in dir.list()) {
          try {
            await entity.delete(recursive: true);
          } catch (_) {}
        }
      }
    } catch (_) {}
  }
}
