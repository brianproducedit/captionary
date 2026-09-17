import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../core/media_file_name.dart';

class FileImportService {
  final Future<Directory> Function()? getTempDirectory;
  final Future<String?> Function()? filePicker;

  FileImportService({this.getTempDirectory, this.filePicker});

  Future<String?> pickVideoFile() async {
    if (filePicker != null) {
      return filePicker!();
    }
    final result = await FilePicker.pickFile(type: FileType.video);

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
