import 'package:flutter_test/flutter_test.dart';
import 'package:captionary/data/models/media_item.dart';

void main() {
  group('MediaItem Tests', () {
    test('should create a valid MediaItem', () {
      final item = MediaItem(
        id: '1',
        fileName: 'test.mp4',
        filePath: '/path/test.mp4',
        fileSizeBytes: 1024,
        resolution: '1080p',
        duration: const Duration(seconds: 10),
        status: MediaStatus.newItem,
        importedAt: DateTime(2026, 1, 1),
      );

      expect(item.id, '1');
      expect(item.fileName, 'test.mp4');
      expect(item.status, MediaStatus.newItem);
    });
  });
}
