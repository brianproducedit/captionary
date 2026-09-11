import 'package:flutter_test/flutter_test.dart';
import 'package:captionary/data/mock/mock_media_service.dart';

void main() {
  group('MockMediaService Tests', () {
    late MockMediaService service;

    setUp(() {
      service = MockMediaService();
    });

    test('getRecentMedia should return items', () async {
      final items = await service.getRecentMedia();
      expect(items.isNotEmpty, true);
    });

    test('importVideo should return an item', () async {
      final item = await service.importVideo();
      expect(item, isNotNull);
    });

    test('getMediaById should return correct item', () async {
      final items = await service.getRecentMedia();
      final id = items.first.id;
      final item = await service.getMediaById(id);
      expect(item.id, id);
    });

    test('deleteMedia should complete successfully', () async {
      final items = await service.getRecentMedia();
      final id = items.first.id;
      await expectLater(service.deleteMedia(id), completes);
    });
  });
}
