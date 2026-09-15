import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:captionary/data/models/media_item.dart';
import 'package:captionary/data/services/local_media_service.dart';
import 'package:captionary/data/services/file_import_service.dart';
import 'package:captionary/data/services/ffmpeg_metadata_service.dart';

class _FakeMetadataService extends FFmpegMetadataService {
  @override
  Future<Map<String, dynamic>?> extractMetadata(String filePath) async {
    return {
      'duration': const Duration(seconds: 45),
      'resolution': '1920x1080',
      'sizeBytes': 1024 * 1024 * 5, // 5MB
    };
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late Directory supportDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('captionary_temp_test_');
    supportDir = await Directory.systemTemp.createTemp(
      'captionary_support_test_',
    );
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
    if (await supportDir.exists()) await supportDir.delete(recursive: true);
  });

  test('LocalMediaService imports video, generates thumbnail, and persists to JSON', () async {
    // Create source test file
    final sourceVideo = File('${tempDir.path}/sample_video.mp4');
    await sourceVideo.writeAsString('fake video content');

    final importService = FileImportService(
      getTempDirectory: () async => tempDir,
      filePicker: () async => sourceVideo.path,
    );

    final service1 = LocalMediaService(
      importService: importService,
      metadataService: _FakeMetadataService(),
      getAppSupportDir: () async => supportDir,
      customThumbnailGenerator: (path) async {
        final thumb = File('${tempDir.path}/thumb_1.jpg');
        await thumb.writeAsString('fake thumb');
        return thumb.path;
      },
    );

    final item = await service1.importVideo();
    expect(item, isNotNull);
    expect(item!.fileName, 'sample_video.mp4');
    expect(item.thumbnailPath, contains('thumb_1.jpg'));
    expect(item.status, MediaStatus.newItem);

    // Verify file was written to support directory
    final jsonFile = File('${supportDir.path}/media_items.json');
    expect(await jsonFile.exists(), isTrue);

    // Re-instantiate service (simulating app restart)
    final service2 = LocalMediaService(
      importService: importService,
      metadataService: _FakeMetadataService(),
      getAppSupportDir: () async => supportDir,
    );

    final recent = await service2.getRecentMedia();
    expect(recent.length, 1);
    expect(recent.first.id, item.id);
    expect(recent.first.fileName, item.fileName);
    expect(recent.first.thumbnailPath, item.thumbnailPath);
    expect(recent.first.status, MediaStatus.newItem);
  });

  test(
    'LocalMediaService marks status as error if cached file is missing',
    () async {
      final sourceVideo = File('${tempDir.path}/temp_clip.mp4');
      await sourceVideo.writeAsString('video data');

      final importService = FileImportService(
        getTempDirectory: () async => tempDir,
        filePicker: () async => sourceVideo.path,
      );

      final service = LocalMediaService(
        importService: importService,
        metadataService: _FakeMetadataService(),
        getAppSupportDir: () async => supportDir,
      );

      final item = await service.importVideo();
      expect(item, isNotNull);

      // Now delete the cached file from disk
      final cachedFile = File(item!.filePath);
      expect(await cachedFile.exists(), isTrue);
      await cachedFile.delete();

      // Re-read media from service
      final recent = await service.getRecentMedia();
      expect(recent.length, 1);
      expect(recent.first.status, MediaStatus.error);
    },
  );

  test('LocalMediaService deletes media and removes cached files', () async {
    final sourceVideo = File('${tempDir.path}/to_delete.mp4');
    await sourceVideo.writeAsString('data');

    final thumbFile = File('${tempDir.path}/to_delete_thumb.jpg');
    await thumbFile.writeAsString('thumb');

    final importService = FileImportService(
      getTempDirectory: () async => tempDir,
      filePicker: () async => sourceVideo.path,
    );

    final service = LocalMediaService(
      importService: importService,
      metadataService: _FakeMetadataService(),
      getAppSupportDir: () async => supportDir,
      customThumbnailGenerator: (_) async => thumbFile.path,
    );

    final item = await service.importVideo();
    expect(item, isNotNull);
    expect(await File(item!.filePath).exists(), isTrue);
    expect(await File(item.thumbnailPath!).exists(), isTrue);

    await service.deleteMedia(item.id);

    final remaining = await service.getRecentMedia();
    expect(remaining, isEmpty);
    expect(await File(item.filePath).exists(), isFalse);
    expect(await File(item.thumbnailPath!).exists(), isFalse);
  });

  test(
    'LocalMediaService skips thumbnail generation for audio files',
    () async {
      final sourceAudio = File('${tempDir.path}/podcast.mp3');
      await sourceAudio.writeAsString('fake audio');

      bool thumbGeneratorCalled = false;
      final importService = FileImportService(
        getTempDirectory: () async => tempDir,
        filePicker: () async => sourceAudio.path,
      );

      final service = LocalMediaService(
        importService: importService,
        metadataService: _FakeMetadataService(),
        getAppSupportDir: () async => supportDir,
        customThumbnailGenerator: (_) async {
          thumbGeneratorCalled = true;
          return null;
        },
      );

      final item = await service.importVideo();
      expect(item, isNotNull);
      expect(item!.isAudio, isTrue);
      expect(thumbGeneratorCalled, isFalse);
      expect(item.thumbnailPath, isEmpty);
    },
  );
}
