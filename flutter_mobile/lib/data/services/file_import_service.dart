import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class FileImportService {
  Future<String?> pickVideoFile() async {
    PlatformFile? result = await FilePicker.pickFile(
      type: FileType.video,
    );

    if (result != null && result.path != null) {
      return result.path;
    }
    return null;
  }

  Future<String> copyToCache(String sourcePath) async {
    final cacheDir = await getTemporaryDirectory();
    final mediaDir = Directory('${cacheDir.path}/media');
    
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }

    final fileName = p.basename(sourcePath);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final destinationPath = '${mediaDir.path}/${timestamp}_$fileName';

    final sourceFile = File(sourcePath);
    await sourceFile.copy(destinationPath);
    
    return destinationPath;
  }

  Future<void> clearMediaCache() async {
    final cacheDir = await getTemporaryDirectory();
    final mediaDir = Directory('${cacheDir.path}/media');
    if (await mediaDir.exists()) {
      await mediaDir.delete(recursive: true);
    }
  }
}
