import 'package:flutter_test/flutter_test.dart';
import 'package:captionary/data/mock/mock_language_service.dart';
import 'package:captionary/data/models/download_progress.dart';

void main() {
  group('MockLanguageService Tests', () {
    late MockLanguageService service;

    setUp(() {
      service = MockLanguageService();
    });

    test('getAvailableLanguages should return languages', () async {
      final langs = await service.getAvailableLanguages();
      expect(langs.isNotEmpty, true);
    });

    test('getActiveLanguage should return Shona by default', () async {
      final lang = await service.getActiveLanguage();
      expect(lang.code, 'sn');
    });

    test('detectLanguage should return sn', () async {
      final code = await service.detectLanguage('path');
      expect(code, 'sn');
    });

    test('getStorageUsedGB and getStorageTotalGB', () {
      expect(service.getStorageUsedGB(), greaterThan(0));
      expect(service.getStorageTotalGB(), equals(10.0));
    });

    test('downloadLanguagePack streams progress', () async {
      final stream = service.downloadLanguagePack('zu');
      final events = await stream.toList();
      expect(events.isNotEmpty, true);
      expect(events.last.state, DownloadState.complete);
    });

    test('deleteLanguagePack completes successfully', () async {
      await expectLater(service.deleteLanguagePack('sn'), completes);
    });
  });
}
