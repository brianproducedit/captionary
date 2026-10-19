import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:captionary/data/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempTestDir;
  late Directory exportTestDir;
  late StorageService storageService;

  setUp(() async {
    tempTestDir = await Directory.systemTemp.createTemp('storage_test_temp_');
    exportTestDir = await Directory.systemTemp.createTemp(
      'storage_test_export_',
    );
    storageService = StorageService(
      getTempDir: () async => tempTestDir,
      getAppSupportDir: () async => tempTestDir,
      getExportDir: () async => exportTestDir,
    );
  });

  tearDown(() async {
    if (await tempTestDir.exists()) {
      await tempTestDir.delete(recursive: true);
    }
    if (await exportTestDir.exists()) {
      await exportTestDir.delete(recursive: true);
    }
  });

  group('StorageService export path resolution', () {
    test(
      'getExportDirectory returns the designated export directory',
      () async {
        final dir = await storageService.getExportDirectory();
        expect(dir.path, exportTestDir.path);
      },
    );

    test(
      'resolveExportVideoPath sanitizes filename and appends .mp4',
      () async {
        final path = await storageService.resolveExportVideoPath(
          'my:test/video?',
        );
        final fileName = path.split(Platform.pathSeparator).last;
        expect(fileName.endsWith('.mp4'), isTrue);
        expect(fileName.contains(':'), isFalse);
        expect(fileName.contains('?'), isFalse);
      },
    );

    test(
      'resolveExportVideoPath appends timestamp on file collision',
      () async {
        final file1 = File('${exportTestDir.path}/colliding_video.mp4');
        await file1.writeAsString('existing content');

        final path = await storageService.resolveExportVideoPath(
          'colliding_video',
        );
        expect(path, isNot(equals(file1.path)));
        expect(path.contains('colliding_video_'), isTrue);
        expect(path.endsWith('.mp4'), isTrue);
      },
    );
  });
}
