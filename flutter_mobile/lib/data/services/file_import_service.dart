import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

import '../../core/media_file_name.dart';

class MediaPermissionException implements Exception {
  final String message;
  final bool isPermanentlyDenied;

  const MediaPermissionException({
    required this.message,
    this.isPermanentlyDenied = false,
  });

  @override
  String toString() => message;
}

class FileImportService {
  final Future<Directory> Function()? getTempDirectory;
  final Future<String?> Function()? filePicker;
  final Future<bool> Function()? permissionRequester;

  FileImportService({
    this.getTempDirectory,
    this.filePicker,
    this.permissionRequester,
  });

  Future<bool> _requestStorageOrMediaPermission() async {
    if (permissionRequester != null) {
      return permissionRequester!();
    }

    if (kIsWeb) return true;

    if (Platform.isAndroid) {
      // Android 13+ (API 33+) granular media permission check
      final videoStatus = await Permission.videos.status;
      if (videoStatus.isGranted || videoStatus.isLimited) {
        return true;
      }

      // Android 12 and below storage permission check
      final storageStatus = await Permission.storage.status;
      if (storageStatus.isGranted || storageStatus.isLimited) {
        return true;
      }

      // Request permissions
      final statuses = await [Permission.videos, Permission.storage].request();

      final videoGranted = statuses[Permission.videos]?.isGranted ?? false;
      final storageGranted = statuses[Permission.storage]?.isGranted ?? false;

      if (videoGranted || storageGranted) {
        return true;
      }

      final isPermanentlyDenied =
          (statuses[Permission.videos]?.isPermanentlyDenied ?? false) ||
          (statuses[Permission.storage]?.isPermanentlyDenied ?? false);

      throw MediaPermissionException(
        message: isPermanentlyDenied
            ? 'Storage permission is permanently denied. Please allow video access in App Settings.'
            : 'Storage permission was denied. Captionary needs permission to select video files.',
        isPermanentlyDenied: isPermanentlyDenied,
      );
    } else if (Platform.isIOS) {
      final photoStatus = await Permission.photos.request();
      if (photoStatus.isGranted || photoStatus.isLimited) {
        return true;
      }
      final isPermanentlyDenied = photoStatus.isPermanentlyDenied;
      throw MediaPermissionException(
        message: isPermanentlyDenied
            ? 'Photo Library permission is permanently denied. Please allow access in Settings.'
            : 'Photo Library permission was denied.',
        isPermanentlyDenied: isPermanentlyDenied,
      );
    }

    return true;
  }

  Future<String?> pickVideoFile() async {
    if (filePicker != null) {
      return filePicker!();
    }

    final hasPermission = await _requestStorageOrMediaPermission();
    if (!hasPermission) {
      return null;
    }

    final result = await FilePicker.pickFile(
      type: FileType.video,
      dialogTitle: 'Select video to caption',
    );

    if (result != null && result.path != null) {
      return result.path;
    }
    return null;
  }

  Future<String> copyToCache(String sourcePath) async {
    final Directory cacheDir;
    if (getTempDirectory != null) {
      cacheDir = await getTempDirectory!();
    } else {
      cacheDir = await getTemporaryDirectory();
    }

    final mediaDir = Directory('${cacheDir.path}/media');
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }

    final fileName = sanitizeImportedFileName(p.basename(sourcePath));
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final destinationPath = '${mediaDir.path}/${timestamp}_$fileName';

    final sourceFile = File(sourcePath);
    await sourceFile.copy(destinationPath);

    return destinationPath;
  }

  Future<void> deleteCachedFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  Future<void> clearMediaCache() async {
    final Directory cacheDir;
    if (getTempDirectory != null) {
      cacheDir = await getTempDirectory!();
    } else {
      cacheDir = await getTemporaryDirectory();
    }

    final mediaDir = Directory('${cacheDir.path}/media');
    if (await mediaDir.exists()) {
      await mediaDir.delete(recursive: true);
    }
  }
}
