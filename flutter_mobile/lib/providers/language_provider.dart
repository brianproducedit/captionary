import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/language_pack.dart';
import '../data/models/download_progress.dart';
import '../data/mock/mock_language_service.dart';
import '../data/services/language_pack_service.dart';
import 'backend_mode_provider.dart';

final languageServiceProvider = Provider<LanguagePackService>((ref) {
  final mode = ref.watch(backendModeProvider);
  switch (mode) {
    case BackendMode.mock:
      return MockLanguageService();
    case BackendMode.local:
    case BackendMode.real:
      return MockLanguageService();
  }
});

class AvailableLanguagesNotifier extends AsyncNotifier<List<LanguagePack>> {
  final Map<String, StreamSubscription<DownloadProgress>> _activeDownloads = {};

  @override
  Future<List<LanguagePack>> build() async {
    ref.onDispose(() {
      for (final sub in _activeDownloads.values) {
        sub.cancel();
      }
      _activeDownloads.clear();
    });
    final service = ref.watch(languageServiceProvider);
    // Clone the list to allow modification if needed
    final list = await service.getAvailableLanguages();
    return List.of(list);
  }

  void updateLanguageState(LanguagePack updatedPack) {
    state = state.whenData((packs) {
      return packs
          .map((p) => p.code == updatedPack.code ? updatedPack : p)
          .toList();
    });
  }

  Future<void> simulateDownload(String code) async {
    if (_activeDownloads.containsKey(code)) {
      final sub = _activeDownloads[code]!;
      if (sub.isPaused) {
        sub.resume();
        state.whenData((packs) {
          final pack = packs.firstWhere((p) => p.code == code);
          updateLanguageState(
            pack.copyWith(status: LanguagePackStatus.downloading),
          );
        });
        return;
      }
    }

    final service = ref.read(languageServiceProvider);

    // Mark as downloading
    state.whenData((packs) {
      final pack = packs.firstWhere((p) => p.code == code);
      updateLanguageState(
        pack.copyWith(
          status: LanguagePackStatus.downloading,
          downloadProgress: 0.0,
        ),
      );
    });

    // Listen to mock stream
    final stream = service.downloadLanguagePack(code);
    final subscription = stream.listen(
      (progress) {
        state.whenData((packs) {
          final pack = packs.firstWhere((p) => p.code == code);
          updateLanguageState(
            pack.copyWith(
              status: progress.state == DownloadState.complete
                  ? LanguagePackStatus.installed
                  : pack.status == LanguagePackStatus.paused
                  ? LanguagePackStatus.paused
                  : LanguagePackStatus.downloading,
              downloadProgress: progress.totalBytes > 0
                  ? progress.downloadedBytes / progress.totalBytes
                  : 0.0,
              downloadSpeedMbps: progress.speedBytesPerSec / (1024 * 1024),
              bytesDownloaded: progress.downloadedBytes,
            ),
          );
        });
      },
      onDone: () {
        _activeDownloads.remove(code);
      },
    );

    _activeDownloads[code] = subscription;
  }

  void pauseDownload(String code) {
    if (_activeDownloads.containsKey(code)) {
      _activeDownloads[code]!.pause();
      state.whenData((packs) {
        final pack = packs.firstWhere((p) => p.code == code);
        updateLanguageState(
          pack.copyWith(
            status: LanguagePackStatus.paused,
            downloadSpeedMbps: 0.0, // Clear speed when paused
          ),
        );
      });
    }
  }

  Future<void> simulateDelete(String code) async {
    if (_activeDownloads.containsKey(code)) {
      _activeDownloads[code]!.cancel();
      _activeDownloads.remove(code);
    }

    final service = ref.read(languageServiceProvider);
    await service.deleteLanguagePack(code);

    state.whenData((packs) {
      final pack = packs.firstWhere((p) => p.code == code);
      updateLanguageState(
        pack.copyWith(
          status: LanguagePackStatus.notDownloaded,
          downloadProgress: 0.0,
          downloadSpeedMbps: 0.0,
        ),
      );
    });
  }
}

final availableLanguagesProvider =
    AsyncNotifierProvider<AvailableLanguagesNotifier, List<LanguagePack>>(() {
      return AvailableLanguagesNotifier();
    });

final activeLanguageProvider = FutureProvider<LanguagePack>((ref) async {
  final service = ref.watch(languageServiceProvider);
  return service.getActiveLanguage();
});

final downloadProgressProvider =
    StreamProvider.family<DownloadProgress, String>((ref, code) {
      final service = ref.watch(languageServiceProvider);
      return service.downloadLanguagePack(code);
    });
