import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/constants/app_constants.dart';

class StorageService {
  final Future<Directory> Function()? _getTempDir;
  final Future<Directory> Function()? _getAppSupportDir;

  StorageService({this._getTempDir, this._getAppSupportDir});

  Future<Directory> get tempDirectory async {
    if (_getTempDir != null) return _getTempDir();
    return getTemporaryDirectory();
  }

  Future<Directory> get appSupportDirectory async {
    if (_getAppSupportDir != null) return _getAppSupportDir();
    return getApplicationSupportDirectory();
  }

  /// Recursively sums all file sizes within a directory in bytes.
  Future<int> _calculateDirectorySize(Directory dir) async {
    if (!await dir.exists()) return 0;
    int total = 0;
    try {
      await for (final entity in dir.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is File) {
          try {
            total += await entity.length();
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint(
        '[StorageService] Error reading directory size for ${dir.path}: $e',
      );
    }
    return total;
  }

  /// Calculates real storage used across temp audio, media cache, thumbnails, and models.
  /// Returns size in gigabytes (GB).
  Future<double> getStorageUsedGB() async {
    final temp = await tempDirectory;
    final support = await appSupportDirectory;

    final audioDir = Directory('${temp.path}/audio');
    final mediaDir = Directory('${temp.path}/media');
    final thumbDir = Directory('${temp.path}/thumbnails');
    final modelsDir = Directory('${support.path}/models');

    final audioBytes = await _calculateDirectorySize(audioDir);
    final mediaBytes = await _calculateDirectorySize(mediaDir);
    final thumbBytes = await _calculateDirectorySize(thumbDir);
    final modelsBytes = await _calculateDirectorySize(modelsDir);

    final totalBytes = audioBytes + mediaBytes + thumbBytes + modelsBytes;
    return totalBytes / (1024 * 1024 * 1024);
  }

  /// Returns storage capacity in gigabytes. Defaults to [AppConstants.storageCapacityGB].
  double getStorageTotalGB() {
    return AppConstants.storageCapacityGB;
  }

  /// Clears temporary cache directories (transcoded audio, generated thumbnails).
  /// If [includeMedia] is true, also clears the imported media cache.
  Future<void> clearCache({bool includeMedia = false}) async {
    final temp = await tempDirectory;

    final dirsToClean = [
      Directory('${temp.path}/audio'),
      Directory('${temp.path}/thumbnails'),
    ];

    if (includeMedia) {
      dirsToClean.add(Directory('${temp.path}/media'));
    }

    for (final dir in dirsToClean) {
      if (await dir.exists()) {
        try {
          await dir.delete(recursive: true);
        } catch (e) {
          debugPrint(
            '[StorageService] Error clearing cache dir ${dir.path}: $e',
          );
        }
      }
    }
  }
}

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});
