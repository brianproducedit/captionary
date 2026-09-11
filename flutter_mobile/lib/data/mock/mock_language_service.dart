import '../services/language_pack_service.dart';
import '../models/language_pack.dart';
import '../models/download_progress.dart';
import 'seed_data.dart';

class MockLanguageService implements LanguagePackService {
  @override
  Future<List<LanguagePack>> getAvailableLanguages() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return SeedData.languagePacks;
  }

  @override
  Future<LanguagePack> getActiveLanguage() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return SeedData.languagePacks.firstWhere((p) => p.code == 'sn');
  }

  @override
  Stream<DownloadProgress> downloadLanguagePack(String code) async* {
    for (int i = 0; i <= 20; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      yield DownloadProgress(
        languageCode: code,
        downloadedBytes: (150000000 * (i * 0.05)).toInt(),
        totalBytes: 150000000,
        speedBytesPerSec: 2500000,
        estimatedTimeRemaining: Duration(seconds: 20 - i),
        state: i == 20 ? DownloadState.complete : DownloadState.downloading,
      );
    }
  }

  @override
  Future<void> deleteLanguagePack(String code) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<String> detectLanguage(String audioPath) async {
    await Future.delayed(const Duration(seconds: 2));
    return 'sn';
  }

  @override
  double getStorageUsedGB() => 2.5;

  @override
  double getStorageTotalGB() => 10.0;
}
