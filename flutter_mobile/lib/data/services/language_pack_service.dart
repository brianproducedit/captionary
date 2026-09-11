import '../models/language_pack.dart';
import '../models/download_progress.dart';

abstract class LanguagePackService {
  Future<List<LanguagePack>> getAvailableLanguages();
  Future<LanguagePack> getActiveLanguage();
  Stream<DownloadProgress> downloadLanguagePack(String code);
  Future<void> deleteLanguagePack(String code);
  Future<String> detectLanguage(String audioPath);
  double getStorageUsedGB();
  double getStorageTotalGB();
}
