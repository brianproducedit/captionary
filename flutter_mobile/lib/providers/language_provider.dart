import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/language_pack.dart';
import '../data/models/download_progress.dart';
import '../data/mock/mock_language_service.dart';
import '../data/services/language_pack_service.dart';
import '../data/services/r2_language_pack_service.dart';
import 'backend_mode_provider.dart';

final languageServiceProvider = Provider<LanguagePackService>((ref) {
  final mode = ref.watch(backendModeProvider);
  switch (mode) {
    case BackendMode.mock:
      return MockLanguageService();
    case BackendMode.local:
    case BackendMode.real:
      return R2LanguagePackService();
  }
});

/// Indicates whether the catalog was loaded from disk cache while offline.
final isCatalogStaleProvider = Provider<bool>((ref) {
  final service = ref.watch(languageServiceProvider);
  if (service is R2LanguagePackService) {
    return service.isCatalogStale;
  }
  return false;
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

  bool _matchesTarget(LanguagePack p, String target) {
    final t = target.toLowerCase().trim();
    final pCode = p.code.toLowerCase().trim();
    final pModelBase = p.modelFile.toLowerCase().trim();
    final pModelStripped =
        pModelBase.replaceAll('ggml-', '').replaceAll('.bin', '');
    return pCode == t ||
        pModelBase == t ||
        pModelBase == 'ggml-$t.bin' ||
        pModelStripped == t;
  }

  void updateLanguageState(LanguagePack updatedPack) {
    state = state.whenData((packs) {
      return packs.map((p) {
        if (p.code == updatedPack.code &&
            p.modelFile == updatedPack.modelFile) {
          return updatedPack;
        }
        return p;
      }).toList();
    });
  }

  Future<void> startDownload(String code) async {
    if (_activeDownloads.containsKey(code)) {
      final sub = _activeDownloads[code]!;
      if (sub.isPaused) {
        sub.resume();
        state.whenData((packs) {
          state = AsyncData(
            packs.map((p) {
              if (_matchesTarget(p, code)) {
                return p.copyWith(status: LanguagePackStatus.downloading);
              }
              return p;
            }).toList(),
          );
        });
        return;
      }
    }

    final service = ref.read(languageServiceProvider);

    // Mark as downloading for all packs sharing this model/code
    state.whenData((packs) {
      final matching = packs.where((p) => _matchesTarget(p, code));
      final targetModelFile =
          matching.isNotEmpty ? matching.first.modelFile : null;

      state = AsyncData(
        packs.map((p) {
          if (_matchesTarget(p, code) ||
              (targetModelFile != null && p.modelFile == targetModelFile)) {
            return p.copyWith(
              status: LanguagePackStatus.downloading,
              downloadProgress: p.downloadProgress,
            );
          }
          return p;
        }).toList(),
      );
    });

    // Listen to download stream
    final stream = service.downloadLanguagePack(code);
    final subscription = stream.listen(
      (progress) {
        state.whenData((packs) {
          final matching = packs.where((p) => _matchesTarget(p, code));
          final targetModelFile =
              matching.isNotEmpty ? matching.first.modelFile : null;

          final status = progress.state == DownloadState.complete
              ? LanguagePackStatus.installed
              : progress.state == DownloadState.error
              ? LanguagePackStatus.error
              : LanguagePackStatus.downloading;

          state = AsyncData(
            packs.map((p) {
              if (_matchesTarget(p, code) ||
                  (targetModelFile != null && p.modelFile == targetModelFile)) {
                return p.copyWith(
                  status: status,
                  downloadProgress: progress.totalBytes > 0
                      ? progress.downloadedBytes / progress.totalBytes
                      : 0.0,
                  downloadSpeedMbps: progress.speedBytesPerSec / (1024 * 1024),
                  bytesDownloaded: progress.downloadedBytes,
                );
              }
              return p;
            }).toList(),
          );
        });
      },
      onError: (err) {
        _activeDownloads.remove(code);
        state.whenData((packs) {
          final matching = packs.where((p) => _matchesTarget(p, code));
          final targetModelFile =
              matching.isNotEmpty ? matching.first.modelFile : null;

          state = AsyncData(
            packs.map((p) {
              if (_matchesTarget(p, code) ||
                  (targetModelFile != null && p.modelFile == targetModelFile)) {
                return p.copyWith(
                  status: LanguagePackStatus.error,
                  downloadSpeedMbps: 0.0,
                );
              }
              return p;
            }).toList(),
          );
        });
      },
      onDone: () {
        _activeDownloads.remove(code);
      },
    );

    _activeDownloads[code] = subscription;
  }

  /// Backwards-compatible alias for startDownload
  Future<void> simulateDownload(String code) => startDownload(code);

  void pauseDownload(String code) {
    if (_activeDownloads.containsKey(code)) {
      _activeDownloads[code]!.cancel();
      _activeDownloads.remove(code);
    }

    final service = ref.read(languageServiceProvider);
    if (service is R2LanguagePackService) {
      service.cancelDownload(code, deletePart: false);
    }

    state.whenData((packs) {
      final matching = packs.where((p) => _matchesTarget(p, code));
      final targetModelFile =
          matching.isNotEmpty ? matching.first.modelFile : null;

      state = AsyncData(
        packs.map((p) {
          if (_matchesTarget(p, code) ||
              (targetModelFile != null && p.modelFile == targetModelFile)) {
            return p.copyWith(
              status: LanguagePackStatus.paused,
              downloadSpeedMbps: 0.0,
            );
          }
          return p;
        }).toList(),
      );
    });
  }

  Future<void> deleteLanguagePack(String code) async {
    if (_activeDownloads.containsKey(code)) {
      _activeDownloads[code]!.cancel();
      _activeDownloads.remove(code);
    }

    final service = ref.read(languageServiceProvider);
    await service.deleteLanguagePack(code);

    state.whenData((packs) {
      final matching = packs.where((p) => _matchesTarget(p, code));
      final targetModelFile =
          matching.isNotEmpty ? matching.first.modelFile : null;

      state = AsyncData(
        packs.map((p) {
          if (_matchesTarget(p, code) ||
              (targetModelFile != null && p.modelFile == targetModelFile)) {
            return p.copyWith(
              status: LanguagePackStatus.notDownloaded,
              downloadProgress: 0.0,
              downloadSpeedMbps: 0.0,
              bytesDownloaded: 0,
            );
          }
          return p;
        }).toList(),
      );
    });
  }

  /// Backwards-compatible alias for deleteLanguagePack
  Future<void> simulateDelete(String code) => deleteLanguagePack(code);
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
