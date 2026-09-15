import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:captionary/data/services/storage_service.dart';

void main() {
  late Directory tempDir;
  late Directory supportDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('storage_temp_test_');
    supportDir = await Directory.systemTemp.createTemp('storage_support_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
    if (await supportDir.exists()) await supportDir.delete(recursive: true);
  });

  test('StorageService calculates used storage and clears cache', () async {
    final storageService = StorageService(
      getTempDir: () async => tempDir,
      getAppSupportDir: () async => supportDir,
    );

    // Initial storage should be 0
    final initialGB = await storageService.getStorageUsedGB();
    expect(initialGB, 0.0);
    expect(storageService.getStorageTotalGB(), 10.0);

    // Create dummy files in audio, media, thumbnails, models
    final audioDir = Directory('${tempDir.path}/audio')
      ..createSync(recursive: true);
    final mediaDir = Directory('${tempDir.path}/media')
      ..createSync(recursive: true);
    final thumbDir = Directory('${tempDir.path}/thumbnails')
      ..createSync(recursive: true);
    final modelsDir = Directory('${supportDir.path}/models')
      ..createSync(recursive: true);

    final dummy1MB = List<int>.filled(1024 * 1024, 0); // 1 MB
    File('${audioDir.path}/audio1.wav').writeAsBytesSync(dummy1MB);
    File('${mediaDir.path}/video1.mp4').writeAsBytesSync(dummy1MB);
    File('${thumbDir.path}/thumb1.jpg').writeAsBytesSync(dummy1MB);
    File('${modelsDir.path}/model1.bin').writeAsBytesSync(dummy1MB);

    // Total 4 MB = 4 / 1024 GB ≈ 0.0039 GB
    final usedGB = await storageService.getStorageUsedGB();
    expect(usedGB, greaterThan(0.003));
    expect(usedGB, lessThan(0.005));

    // Clear temporary cache without media
    await storageService.clearCache(includeMedia: false);

    expect(await File('${audioDir.path}/audio1.wav').exists(), isFalse);
    expect(await File('${thumbDir.path}/thumb1.jpg').exists(), isFalse);
    expect(await File('${mediaDir.path}/video1.mp4').exists(), isTrue);
    expect(await File('${modelsDir.path}/model1.bin').exists(), isTrue);

    // Clear temporary cache including media
    await storageService.clearCache(includeMedia: true);
    expect(await File('${mediaDir.path}/video1.mp4').exists(), isFalse);
  });
}
