import 'package:flutter_test/flutter_test.dart';
import 'package:captionary/data/models/language_pack.dart';

void main() {
  group('LanguagePack Tests', () {
    test('should create a valid LanguagePack', () {
      final pack = LanguagePack(
        code: 'en',
        name: 'English',
        nativeName: 'English',
        region: 'US',
        modelFile: 'model.bin',
        sizeBytes: 1000,
        sha256: 'abc',
        accuracy: 'high',
        engine: 'whisper',
        isBundled: true,
        priority: 1,
        status: LanguagePackStatus.installed,
        downloadProgress: 1.0,
      );

      expect(pack.code, 'en');
      expect(pack.name, 'English');
      expect(pack.status, LanguagePackStatus.installed);
    });
  });
}
