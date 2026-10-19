import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/constants/app_constants.dart';

class StorageService {
  final Future<Directory> Function()? getTempDir;
  final Future<Directory> Function()? getAppSupportDir;
  final Future<Directory> Function()? getExportDir;

  StorageService({this.getTempDir, this.getAppSupportDir, this.getExportDir});

  Future<Directory> get tempDirectory async {
    if (getTempDir != null) return getTempDir!();
    return getTemporaryDirectory();
  }

  Future<Directory> get appSupportDirectory async {
    if (getAppSupportDir != null) return getAppSupportDir!();
    return getApplicationSupportDirectory();
  }

  /// Resolves the dedicated export directory for videos in internal storage Download/Captionary/Output.
  Future<Directory> getExportDirectory() async {
    if (getExportDir != null) return getExportDir!();

    if (!kIsWeb && Platform.isAndroid) {
      try {
        final publicDir = Directory(
          '/storage/emulated/0/Download/Captionary/Output',
        );

        if (!await publicDir.exists()) {
          await publicDir.create(recursive: true);
        }

        // Verify write access with a probe file
        final probeFile = File(
          p.join(
            publicDir.path,
            '.probe_${DateTime.now().millisecondsSinceEpoch}',
          ),
        );
        await probeFile.writeAsString('probe');
        await probeFile.delete();

        return publicDir;
      } catch (e) {
        debugPrint(
          '[StorageService] Error accessing public /storage/emulated/0/Download/Captionary/Output ($e), falling back',
        );
      }
    }

    try {
      final dl = await getDownloadsDirectory();
      if (dl != null) {
        final dir = Directory(p.join(dl.path, 'Captionary', 'Output'));
        if (!await dir.exists()) await dir.create(recursive: true);
        return dir;
      }
    } catch (_) {}

    final appDoc = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDoc.path, 'Captionary', 'Output'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Resolves a full video export path within the Download/Captionary directory,
  /// sanitizing the filename and appending unique timestamp if a collision exists.
  Future<String> resolveExportVideoPath(String baseFileName) async {
    final dir = await getExportDirectory();
    String sanitized = baseFileName
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .trim();
    if (sanitized.isEmpty) {
      sanitized = 'captioned_video';
    }
    if (!sanitized.toLowerCase().endsWith('.mp4')) {
      sanitized = '$sanitized.mp4';
    }

    var candidate = p.join(dir.path, sanitized);
    if (File(candidate).existsSync()) {
      final nameWithoutExt = p.basenameWithoutExtension(sanitized);
      candidate = p.join(
        dir.path,
        '${nameWithoutExt}_${DateTime.now().millisecondsSinceEpoch}.mp4',
      );
    }
    return candidate;
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
  /// Includes both app-internal and public Download/Captionary/models directories on Android.
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

    // Also account for models stored in the public downloads directory
    // (survives app uninstallation on Android)
    int publicModelsBytes = 0;
    if (!kIsWeb && Platform.isAndroid) {
      final publicModelsDir = Directory(
        '/storage/emulated/0/Download/Captionary/models',
      );
      if (publicModelsDir.path != modelsDir.path) {
        publicModelsBytes = await _calculateDirectorySize(publicModelsDir);
      }
    }

    final totalBytes =
        audioBytes + mediaBytes + thumbBytes + modelsBytes + publicModelsBytes;
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
