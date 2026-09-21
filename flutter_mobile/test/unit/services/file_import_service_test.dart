import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:captionary/data/services/file_import_service.dart';

void main() {
  group('FileImportService', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('file_import_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('picks file via custom filePicker delegate without requesting permissions', () async {
      final service = FileImportService(
        filePicker: () async => '/mock/path/sample.mp4',
        permissionRequester: () async {
          fail(
            'Should not request permissions when filePicker delegate is provided',
          );
        },
      );

      final result = await service.pickVideoFile();
      expect(result, '/mock/path/sample.mp4');
    });

    test('returns null when permission requester returns false', () async {
      final service = FileImportService(permissionRequester: () async => false);

      final result = await service.pickVideoFile();
      expect(result, isNull);
    });

    test('copies file to cache directory and sanitizes file name', () async {
      final sourceFile = File('${tempDir.path}/original#video#sample.mp4');
      await sourceFile.writeAsString('test video bytes');

      final cacheDir = Directory('${tempDir.path}/cache');
      await cacheDir.create(recursive: true);

      final service = FileImportService(getTempDirectory: () async => cacheDir);

      final cachedPath = await service.copyToCache(sourceFile.path);
      expect(File(cachedPath).existsSync(), isTrue);
      expect(cachedPath.contains('media'), isTrue);
      expect(cachedPath.endsWith('original_video_sample.mp4'), isTrue);

      // Verify deletion
      await service.deleteCachedFile(cachedPath);
      expect(File(cachedPath).existsSync(), isFalse);
    });

    test('clearMediaCache deletes all files in media directory', () async {
      final cacheDir = Directory('${tempDir.path}/cache');
      final mediaDir = Directory('${cacheDir.path}/media');
      await mediaDir.create(recursive: true);

      final file1 = File('${mediaDir.path}/vid1.mp4');
      await file1.writeAsString('bytes1');
      expect(await file1.exists(), isTrue);

      final service = FileImportService(getTempDirectory: () async => cacheDir);

      await service.clearMediaCache();
      expect(await mediaDir.exists(), isFalse);
    });
  });
}
