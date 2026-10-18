import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import '../../core/wav_header_validator.dart';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';
import '../exceptions/language_pack_exceptions.dart';
import '../models/catalog_manifest.dart';
import '../models/download_progress.dart';
import '../models/language_pack.dart';
import 'language_pack_service.dart';

/// Production language pack service that fetches catalogs from Cloudflare R2,
/// supports resumable Range downloads via Dio, validates SHA256 hashes, and
/// safely manages model persistence and storage accounting on-device.
class R2LanguagePackService implements LanguagePackService {
  final Dio _dio;
  final Future<Directory> Function()? _getModelsDirectory;
  final String _manifestUrl;
  final String _r2BaseUrl;

  CatalogManifest? _cachedManifest;
  bool _isCatalogStale = false;
  final Map<String, CancelToken> _activeTokens = {};
  Directory? _resolvedDir;

  R2LanguagePackService({
    Dio? dio,
    this._getModelsDirectory,
    String? manifestUrl,
    String? r2BaseUrl,
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               connectTimeout: const Duration(seconds: 30),
               receiveTimeout: const Duration(seconds: 60),
               sendTimeout: const Duration(seconds: 30),
             ),
           ),
       _manifestUrl = manifestUrl ?? AppConstants.manifestUrl,
       _r2BaseUrl = r2BaseUrl ?? AppConstants.r2BaseUrl;

  /// Indicates whether the active catalog was loaded from offline disk cache
  /// due to network unavailability or failure.
  bool get isCatalogStale => _isCatalogStale;

  /// The active manifest if loaded.
  CatalogManifest? get manifest => _cachedManifest;

  /// Resolves the dedicated directory on disk where models are stored.
  /// On Android, prioritizes public Download directory so downloaded language
  /// models persist even if the application is uninstalled or updated, while allowing
  /// users to manage/delete them via their phone's file manager or the app.
  Future<Directory> get modelsDirectory async {
    if (_resolvedDir != null && await _resolvedDir!.exists()) {
      return _resolvedDir!;
    }

    if (_getModelsDirectory != null) {
      final dir = await _getModelsDirectory();
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      _resolvedDir = dir;
      return dir;
    }

    // On Android, use persistent shared directory that survives app uninstallation:
    // /storage/emulated/0/Download/Captionary/models
    if (!kIsWeb && Platform.isAndroid) {
      try {
        Directory? publicDir;
        try {
          final dl = await getDownloadsDirectory();
          if (dl != null) {
            publicDir = Directory(p.join(dl.path, 'Captionary', 'models'));
          }
        } catch (_) {}
        publicDir ??= Directory(
          '/storage/emulated/0/Download/Captionary/models',
        );

        if (!await publicDir.exists()) {
          await publicDir.create(recursive: true);
        }
        // Test write probe to verify write permissions
        final testFile = File('${publicDir.path}/.probe');
        await testFile.writeAsString('probe');
        await testFile.delete();
        _resolvedDir = publicDir;
        return publicDir;
      } catch (e) {
        debugPrint(
          '[R2LanguagePackService] Public download dir not accessible ($e), falling back to app support dir',
        );
      }
    }

    final baseDir = await getApplicationSupportDirectory();
    final dir = Directory(p.join(baseDir.path, 'models'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _resolvedDir = dir;
    return dir;
  }

  /// Fetches the model catalog manifest.
  /// First attempts a network request with timeout.
  /// If network fails, falls back to the cached manifest on disk.
  Future<CatalogManifest> fetchManifest({bool forceRefresh = false}) async {
    if (_cachedManifest != null && !forceRefresh && !_isCatalogStale) {
      return _cachedManifest!;
    }

    final dir = await modelsDirectory;
    final cacheFile = File(p.join(dir.path, 'manifest_cache.json'));

    try {
      final response = await _dio.get<String>(
        _manifestUrl,
        options: Options(
          responseType: ResponseType.plain,
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final parsed = CatalogManifest.fromJsonString(response.data!);
        _cachedManifest = parsed;
        _isCatalogStale = false;

        // Persist to disk cache
        try {
          await cacheFile.writeAsString(response.data!);
        } catch (_) {
          // Non-critical cache write error
        }

        return parsed;
      } else {
        throw CatalogUnavailableException(
          'Failed to load manifest: HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      // Network failure or timeout: try offline cache
      if (await cacheFile.exists()) {
        try {
          final cachedContent = await cacheFile.readAsString();
          final cachedManifest = CatalogManifest.fromJsonString(cachedContent);
          _cachedManifest = cachedManifest;
          _isCatalogStale = true;
          return cachedManifest;
        } catch (cacheErr) {
          throw CatalogUnavailableException(
            'Failed to read cached manifest after network failure: $e',
            cacheErr,
          );
        }
      }

      throw CatalogUnavailableException(
        'Cannot fetch catalog from network and no offline cache is available.',
        e,
      );
    }
  }

  static final CatalogManifest _defaultEmbeddedManifest = CatalogManifest(
    schemaVersion: 1,
    catalogVersion: 1791797971155,
    updatedAt: DateTime.parse('2026-10-12T09:39:31.155Z'),
    baseUrl: 'https://pub-6315c0ddbd0d44b4856162c00e47e86e.r2.dev',
    defaultLanguage: 'en',
    models: [
      const CatalogModel(
        id: 'tiny.en',
        engine: 'whisper_flutter_new',
        file: 'models/ggml-tiny.en.bin',
        languageCodes: ['en'],
        displayName: 'English Tiny (Fast)',
        sizeBytes: 77704715,
        sha256:
            '921e4cf8686fdd993dcd081a5da5b6c365bfde1162e72b08d75ac75289920b1f',
        quantization: 'none',
        bundled: false,
        minAndroidSdk: 21,
        recommendedRamGb: 2,
        license: 'MIT',
        sourceUrl: 'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.en.bin',
      ),
      const CatalogModel(
        id: 'tiny',
        engine: 'whisper_flutter_new',
        file: 'models/ggml-tiny.bin',
        languageCodes: [
          'sn',
          'zu',
          'nso',
          'sw',
          'yo',
          'af',
          'xh',
          'st',
          'tn',
          'ts',
          'ss',
          've',
          'nr',
          'en',
          'fr',
          'pt',
          'es',
          'ar',
          'de',
          'it',
          'nl',
          'ru',
          'hi',
          'zh',
          'ja',
          'ko',
        ],
        displayName: 'Multilingual Tiny (Fast)',
        sizeBytes: 77691713,
        sha256:
            'be07e048e1e599ad46341c8d2a135645097a538221678b7acdd1b1919c6e1b21',
        quantization: 'none',
        bundled: false,
        minAndroidSdk: 21,
        recommendedRamGb: 2,
        license: 'MIT',
        sourceUrl: 'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.bin',
      ),
      const CatalogModel(
        id: 'tiny.q5_1',
        engine: 'whisper_flutter_new',
        file: 'models/ggml-tiny-q5_1.bin',
        languageCodes: [
          'sn',
          'zu',
          'nso',
          'sw',
          'yo',
          'af',
          'xh',
          'st',
          'tn',
          'ts',
          'ss',
          've',
          'nr',
          'en',
          'fr',
          'pt',
          'es',
          'ar',
          'de',
          'it',
          'nl',
          'ru',
          'hi',
          'zh',
          'ja',
          'ko',
        ],
        displayName: 'Multilingual Tiny (Q5_1 Quantized)',
        sizeBytes: 32152673,
        sha256:
            '818710568da3ca15689e31a743197b520007872ff9576237bda97bd1b469c3d7',
        quantization: 'q5_1',
        bundled: false,
        minAndroidSdk: 21,
        recommendedRamGb: 2,
        license: 'MIT',
        sourceUrl: 'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny-q5_1.bin',
      ),
      const CatalogModel(
        id: 'base.en',
        engine: 'whisper_flutter_new',
        file: 'models/ggml-base.en.bin',
        languageCodes: ['en'],
        displayName: 'English Base',
        sizeBytes: 147964211,
        sha256:
            'a03779c86df3323075f5e796cb2ce5029f00ec8869eee3fdfb897afe36c6d002',
        quantization: 'none',
        bundled: false,
        minAndroidSdk: 21,
        recommendedRamGb: 4,
        license: 'MIT',
        sourceUrl: 'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin',
      ),
      const CatalogModel(
        id: 'base',
        engine: 'whisper_flutter_new',
        file: 'models/ggml-base.bin',
        languageCodes: [
          'sn',
          'zu',
          'nso',
          'sw',
          'yo',
          'af',
          'xh',
          'st',
          'tn',
          'ts',
          'ss',
          've',
          'nr',
          'en',
          'fr',
          'pt',
          'es',
          'ar',
          'de',
          'it',
          'nl',
          'ru',
          'hi',
          'zh',
          'ja',
          'ko',
        ],
        displayName: 'Multilingual Base (Recommended)',
        sizeBytes: 147951465,
        sha256:
            '60ed5bc3dd14eea856493d334349b405782ddcaf0028d4b5df4088345fba2efe',
        quantization: 'none',
        bundled: false,
        minAndroidSdk: 21,
        recommendedRamGb: 4,
        license: 'MIT',
        sourceUrl: 'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin',
      ),
      const CatalogModel(
        id: 'base.q5_1',
        engine: 'whisper_flutter_new',
        file: 'models/ggml-base-q5_1.bin',
        languageCodes: [
          'sn',
          'zu',
          'nso',
          'sw',
          'yo',
          'af',
          'xh',
          'st',
          'tn',
          'ts',
          'ss',
          've',
          'nr',
          'en',
          'fr',
          'pt',
          'es',
          'ar',
          'de',
          'it',
          'nl',
          'ru',
          'hi',
          'zh',
          'ja',
          'ko',
        ],
        displayName: 'Multilingual Base (Q5_1 Quantized)',
        sizeBytes: 59707625,
        sha256:
            '422f1ae452ade6f30a004d7e5c6a43195e4433bc370bf23fac9cc591f01a8898',
        quantization: 'q5_1',
        bundled: false,
        minAndroidSdk: 21,
        recommendedRamGb: 4,
        license: 'MIT',
        sourceUrl: 'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base-q5_1.bin',
      ),
      const CatalogModel(
        id: 'small',
        engine: 'whisper_flutter_new',
        file: 'models/ggml-small.bin',
        languageCodes: [
          'sn',
          'zu',
          'nso',
          'sw',
          'yo',
          'af',
          'xh',
          'st',
          'tn',
          'ts',
          'ss',
          've',
          'nr',
          'en',
          'fr',
          'pt',
          'es',
          'ar',
          'de',
          'it',
          'nl',
          'ru',
          'hi',
          'zh',
          'ja',
          'ko',
        ],
        displayName: 'Multilingual Small (High Accuracy)',
        sizeBytes: 487601967,
        sha256:
            '1be3a9b2063867b937e64e2ec7483364a79917e157fa98c5d94b5c1fffea987b',
        quantization: 'none',
        bundled: false,
        minAndroidSdk: 24,
        recommendedRamGb: 4,
        license: 'MIT',
        sourceUrl: 'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.bin',
      ),
      const CatalogModel(
        id: 'medium',
        engine: 'whisper_flutter_new',
        file: 'models/ggml-medium.bin',
        languageCodes: [
          'sn',
          'zu',
          'nso',
          'sw',
          'yo',
          'af',
          'xh',
          'st',
          'tn',
          'ts',
          'ss',
          've',
          'nr',
          'en',
          'fr',
          'pt',
          'es',
          'ar',
          'de',
          'it',
          'nl',
          'ru',
          'hi',
          'zh',
          'ja',
          'ko',
        ],
        displayName: 'Multilingual Medium (Maximum Accuracy)',
        sizeBytes: 1533774781,
        sha256:
            'fd9727b6e1217c2f614f9b698455c4ffd82463b4c8aaec2c4f21a1b0c5860571',
        quantization: 'none',
        bundled: false,
        minAndroidSdk: 24,
        recommendedRamGb: 6,
        license: 'MIT',
        sourceUrl: 'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-medium.bin',
      ),
    ],
  );

  @override
  Future<List<LanguagePack>> getAvailableLanguages() async {
    CatalogManifest catalog;
    try {
      catalog = await fetchManifest();
    } catch (_) {
      catalog = _defaultEmbeddedManifest;
      _cachedManifest = catalog;
      _isCatalogStale = true;
    }

    final dir = await modelsDirectory;
    final List<LanguagePack> packs = [];
    final Set<String> addedCodes = {};

    // Candidate directories to search for existing models:
    // 1. Primary models directory
    // 2. Persistent public Android download directory
    // 3. Application Support directory / models
    // 4. Application Documents directory / models
    final candidateDirs = <Directory>[dir];
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final dl = await getDownloadsDirectory();
        if (dl != null) {
          candidateDirs.add(Directory(p.join(dl.path, 'Captionary', 'models')));
        }
      } catch (_) {}
      candidateDirs.add(
        Directory('/storage/emulated/0/Download/Captionary/models'),
      );
    }
    try {
      final appSupport = await getApplicationSupportDirectory();
      candidateDirs.add(Directory(p.join(appSupport.path, 'models')));
      candidateDirs.add(appSupport);
    } catch (_) {}
    try {
      final appDocs = await getApplicationDocumentsDirectory();
      candidateDirs.add(Directory(p.join(appDocs.path, 'models')));
      candidateDirs.add(appDocs);
    } catch (_) {}

    int priority = 1;
    for (final model in catalog.models) {
      LanguagePackStatus status = LanguagePackStatus.notDownloaded;
      double progress = 0.0;
      int? bytesDownloaded;
      String? foundPath;

      final filename = p.basename(model.file);

      // Check all candidate directories for existing valid model
      for (final cDir in candidateDirs) {
        if (!await cDir.exists()) continue;
        final binFile = File(p.join(cDir.path, filename));
        final partFile = File(p.join(cDir.path, '$filename.part'));

        if (await binFile.exists()) {
          final currentSize = await binFile.length();
          final bool isComplete = model.sizeBytes > 0
              ? currentSize == model.sizeBytes
              : currentSize > 0;
          if (isComplete) {
            status = model.bundled
                ? LanguagePackStatus.bundled
                : LanguagePackStatus.installed;
            progress = 1.0;
            bytesDownloaded = currentSize;
            foundPath = binFile.path;
            break;
          } else if (currentSize > 0) {
            // Incomplete or corrupt model on device - delete so it doesn't cause native SIGSEGV
            try {
              await binFile.delete();
            } catch (_) {}
          }
        } else if (await partFile.exists()) {
          final partSize = await partFile.length();
          if (partSize > 0 && partSize < model.sizeBytes) {
            status = LanguagePackStatus.paused;
            progress = partSize / model.sizeBytes;
            bytesDownloaded = partSize;
            foundPath = partFile.path;
          }
        }
      }

      final effectiveLocalPath =
          foundPath ?? _resolveSafeLocalPath(dir, model.file);

      if (model.languageCodes.length == 1) {
        final code = model.languageCodes.first;
        final key = '${model.id}_$code';
        if (!addedCodes.contains(key)) {
          addedCodes.add(key);
          packs.add(
            model.toLanguagePack(
              status: status,
              downloadProgress: progress,
              bytesDownloaded: bytesDownloaded,
              priority: priority++,
              localPath:
                  status == LanguagePackStatus.installed ||
                      status == LanguagePackStatus.bundled
                  ? effectiveLocalPath
                  : null,
            ),
          );
        }
      } else {
        for (final code in model.languageCodes) {
          final key = '${model.id}_$code';
          if (!addedCodes.contains(key)) {
            addedCodes.add(key);
            packs.add(
              model.toLanguagePackForLanguage(
                code,
                status: status,
                downloadProgress: progress,
                bytesDownloaded: bytesDownloaded,
                priority: priority++,
                localPath:
                    status == LanguagePackStatus.installed ||
                        status == LanguagePackStatus.bundled
                    ? effectiveLocalPath
                    : null,
              ),
            );
          }
        }
      }
    }

    return packs;
  }

  @override
  Future<LanguagePack> getActiveLanguage() async {
    final langs = await getAvailableLanguages();
    // Default to 'en' or first installed, or first available
    final installed = langs.where(
      (l) =>
          l.status == LanguagePackStatus.installed ||
          l.status == LanguagePackStatus.bundled,
    );
    if (installed.isNotEmpty) {
      final defaultLang = installed.firstWhere(
        (l) => l.code == (_cachedManifest?.defaultLanguage ?? 'en'),
        orElse: () => installed.first,
      );
      return defaultLang;
    }

    return langs.first;
  }

  @override
  Stream<DownloadProgress> downloadLanguagePack(String code) async* {
    final catalog = await fetchManifest();
    final model = catalog.findModel(code);

    final dir = await modelsDirectory;
    final finalPath = _resolveSafeLocalPath(dir, model.file);
    final finalFile = File(finalPath);
    final partFile = File('$finalPath.part');
    final metaFile = File('$finalPath.meta.json');

    // If already installed and valid, yield complete immediately (restores metadata if missing after reinstallation)
    if (await finalFile.exists()) {
      final currentSize = await finalFile.length();
      final bool isComplete = model.sizeBytes > 0
          ? currentSize == model.sizeBytes
          : currentSize > 0;
      if (isComplete) {
        if (!await metaFile.exists()) {
          final metadata = {
            'id': model.id,
            'engine': model.engine,
            'file': p.basename(model.file),
            'language_codes': model.languageCodes,
            'display_name': model.displayName,
            'size_bytes': model.sizeBytes,
            'sha256': model.sha256,
            'installed_at': DateTime.now().toIso8601String(),
            'catalog_version': catalog.catalogVersion,
          };
          try {
            await metaFile.writeAsString(jsonEncode(metadata));
          } catch (_) {}
        }
        yield DownloadProgress(
          languageCode: code,
          downloadedBytes: currentSize,
          totalBytes: model.sizeBytes > 0 ? model.sizeBytes : currentSize,
          speedBytesPerSec: 0,
          estimatedTimeRemaining: Duration.zero,
          state: DownloadState.complete,
        );
        return;
      }
    }

    final downloadUrl = catalog.resolveModelUrl(
      model,
      fallbackBaseUrl: _r2BaseUrl,
    );

    final cancelToken = CancelToken();
    _activeTokens[code] = cancelToken;

    int existingBytes = 0;
    if (await partFile.exists()) {
      existingBytes = await partFile.length();
      // If .part file is already larger than expected, discard and restart
      if (existingBytes > model.sizeBytes) {
        await partFile.delete();
        existingBytes = 0;
      }
    }

    const int maxRetries = 4;
    int retryCount = 0;
    bool isComplete = false;

    while (!isComplete) {
      if (cancelToken.isCancelled) {
        _activeTokens.remove(code);
        return;
      }

      IOSink? sink;
      try {
        if (await partFile.exists()) {
          existingBytes = await partFile.length();
          if (existingBytes > model.sizeBytes) {
            await partFile.delete();
            existingBytes = 0;
          }
        } else {
          existingBytes = 0;
        }

        // If part file already has full bytes, skip to verification
        if (existingBytes >= model.sizeBytes && model.sizeBytes > 0) {
          isComplete = true;
          break;
        }

        final Map<String, dynamic> headers = {};
        bool isResume = existingBytes > 0;
        if (isResume) {
          headers['Range'] = 'bytes=$existingBytes-';
        }

        final response = await _dio.get<ResponseBody>(
          downloadUrl.toString(),
          options: Options(
            headers: headers,
            responseType: ResponseType.stream,
            receiveTimeout: const Duration(seconds: 60),
            sendTimeout: const Duration(seconds: 30),
          ),
          cancelToken: cancelToken,
        );

        final statusCode = response.statusCode ?? 200;

        // Roadmap requirement:
        // Download to *.part; Range resume; require 206 for resume;
        // if server returns 200, restart.
        if (isResume && statusCode != 206) {
          // Server returned 200 instead of 206 or ignored Range. Restart from byte 0.
          if (await partFile.exists()) {
            await partFile.delete();
          }
          existingBytes = 0;
          isResume = false;
        }

        final fileMode = isResume ? FileMode.append : FileMode.write;
        sink = partFile.openWrite(mode: fileMode);

        int totalBytes = model.sizeBytes;
        int downloadedBytes = existingBytes;
        final stopwatch = Stopwatch()..start();
        int bytesSinceLastTick = 0;
        DateTime lastYieldTime = DateTime.now();

        yield DownloadProgress(
          languageCode: code,
          downloadedBytes: downloadedBytes,
          totalBytes: totalBytes,
          speedBytesPerSec: 0,
          estimatedTimeRemaining: const Duration(seconds: 30),
          state: DownloadState.downloading,
        );

        await for (final chunk in response.data!.stream) {
          if (cancelToken.isCancelled) break;

          sink.add(chunk);
          downloadedBytes += chunk.length;
          bytesSinceLastTick += chunk.length;

          final now = DateTime.now();
          if (now.difference(lastYieldTime).inMilliseconds >= 250 ||
              downloadedBytes == totalBytes) {
            final elapsedSec = stopwatch.elapsedMilliseconds / 1000.0;
            final speed = elapsedSec > 0
                ? bytesSinceLastTick / elapsedSec
                : 0.0;
            final remainingBytes = totalBytes - downloadedBytes;
            final eta = speed > 0
                ? Duration(seconds: (remainingBytes / speed).ceil())
                : Duration.zero;

            yield DownloadProgress(
              languageCode: code,
              downloadedBytes: downloadedBytes,
              totalBytes: totalBytes,
              speedBytesPerSec: speed,
              estimatedTimeRemaining: eta,
              state: DownloadState.downloading,
            );

            stopwatch.reset();
            bytesSinceLastTick = 0;
            lastYieldTime = now;
          }
        }

        await sink.flush();
        await sink.close();
        sink = null;

        if (cancelToken.isCancelled) {
          _activeTokens.remove(code);
          return;
        }

        if (await partFile.exists() &&
            (await partFile.length()) >= totalBytes) {
          isComplete = true;
          break;
        }
      } catch (e) {
        if (sink != null) {
          try {
            await sink.flush();
            await sink.close();
          } catch (_) {}
          sink = null;
        }

        if (cancelToken.isCancelled) {
          _activeTokens.remove(code);
          return;
        }

        if (retryCount < maxRetries) {
          retryCount++;
          debugPrint(
            '[R2LanguagePackService] Connection interrupted ($e), retrying attempt $retryCount/$maxRetries...',
          );
          if (await partFile.exists()) {
            existingBytes = await partFile.length();
          }
          yield DownloadProgress(
            languageCode: code,
            downloadedBytes: existingBytes,
            totalBytes: model.sizeBytes,
            speedBytesPerSec: 0,
            estimatedTimeRemaining: Duration(
              seconds: 15 * (maxRetries - retryCount + 1),
            ),
            state: DownloadState.downloading,
          );
          await Future.delayed(Duration(seconds: math.min(1 << retryCount, 6)));
          continue;
        }

        _activeTokens.remove(code);

        yield DownloadProgress(
          languageCode: code,
          downloadedBytes: existingBytes,
          totalBytes: model.sizeBytes,
          speedBytesPerSec: 0,
          estimatedTimeRemaining: Duration.zero,
          state: DownloadState.error,
        );

        rethrow;
      }
    }

    // Check SHA256 integrity
    yield DownloadProgress(
      languageCode: code,
      downloadedBytes: model.sizeBytes,
      totalBytes: model.sizeBytes,
      speedBytesPerSec: 0,
      estimatedTimeRemaining: Duration.zero,
      state: DownloadState.verifying,
    );

    final calculatedSha256 = await _computeSha256(partFile);
    if (calculatedSha256 != model.sha256.toLowerCase()) {
      // Checksum mismatch: delete .part file and throw
      if (await partFile.exists()) {
        await partFile.delete();
      }
      _activeTokens.remove(code);
      throw ChecksumMismatchException(
        modelId: model.id,
        expectedSha256: model.sha256,
        actualSha256: calculatedSha256,
      );
    }

    // Atomic rename: .part -> .bin
    if (await finalFile.exists()) {
      await finalFile.delete();
    }
    await partFile.rename(finalFile.path);

    // Write install metadata JSON
    final metadata = {
      'id': model.id,
      'engine': model.engine,
      'file': p.basename(model.file),
      'language_codes': model.languageCodes,
      'display_name': model.displayName,
      'size_bytes': model.sizeBytes,
      'sha256': model.sha256,
      'installed_at': DateTime.now().toIso8601String(),
      'catalog_version': catalog.catalogVersion,
    };
    await metaFile.writeAsString(jsonEncode(metadata));

    _activeTokens.remove(code);

    yield DownloadProgress(
      languageCode: code,
      downloadedBytes: model.sizeBytes,
      totalBytes: model.sizeBytes,
      speedBytesPerSec: 0,
      estimatedTimeRemaining: Duration.zero,
      state: DownloadState.complete,
    );
  }

  /// Cancels an active download.
  /// If [deletePart] is true, deletes any partial `.part` file.
  /// If [deletePart] is false (pause), keeps `.part` file for later resumption.
  Future<void> cancelDownload(String code, {bool deletePart = false}) async {
    final token = _activeTokens.remove(code);
    if (token != null && !token.isCancelled) {
      token.cancel('Download cancelled by user');
    }

    if (deletePart) {
      try {
        final catalog = await fetchManifest();
        final model = catalog.findModel(code);
        final dir = await modelsDirectory;
        final localPath = _resolveSafeLocalPath(dir, model.file);
        final partFile = File('$localPath.part');
        if (await partFile.exists()) {
          await partFile.delete();
        }
      } catch (_) {}
    }
  }

  @override
  Future<void> deleteLanguagePack(String code) async {
    await cancelDownload(code, deletePart: true);

    final catalog = await fetchManifest();
    final model = catalog.findModel(code);

    final dir = await modelsDirectory;
    final filename = p.basename(model.file);
    final candidateDirs = <Directory>[dir];
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final dl = await getDownloadsDirectory();
        if (dl != null) {
          candidateDirs.add(Directory(p.join(dl.path, 'Captionary', 'models')));
        }
      } catch (_) {}
      candidateDirs.add(
        Directory('/storage/emulated/0/Download/Captionary/models'),
      );
    }
    try {
      final appSupport = await getApplicationSupportDirectory();
      candidateDirs.add(Directory(p.join(appSupport.path, 'models')));
      candidateDirs.add(appSupport);
    } catch (_) {}

    for (final cDir in candidateDirs) {
      try {
        if (!await cDir.exists()) continue;
        final binFile = File(p.join(cDir.path, filename));
        final metaFile = File(p.join(cDir.path, '$filename.meta.json'));
        final partFile = File(p.join(cDir.path, '$filename.part'));

        if (await binFile.exists()) {
          await binFile.delete();
        }
        if (await metaFile.exists()) {
          await metaFile.delete();
        }
        if (await partFile.exists()) {
          await partFile.delete();
        }
      } catch (_) {}
    }
  }

  @override
  Future<String> detectLanguage(String audioPath) async {
    final file = File(audioPath);
    if (await file.exists()) {
      try {
        final validation = await WavHeaderValidator.validateFile(file);
        if (!validation.isValid) {
          debugPrint(
            '[R2LanguagePackService] Audio verification notice: ${validation.errorMessage}',
          );
        }
      } catch (e) {
        debugPrint('[R2LanguagePackService] Audio check note: $e');
      }
    }
    return _cachedManifest?.defaultLanguage ?? 'en';
  }

  @override
  double getStorageUsedGB() {
    try {
      final dir = _resolvedDir;
      if (dir != null && dir.existsSync()) {
        int totalBytes = 0;
        for (final entity in dir.listSync(recursive: false)) {
          if (entity is File &&
              (entity.path.endsWith('.bin') || entity.path.endsWith('.part'))) {
            totalBytes += entity.lengthSync();
          }
        }
        return totalBytes / (1024.0 * 1024.0 * 1024.0);
      }
      return 0.0;
    } catch (_) {
      return 0.0;
    }
  }

  /// Asynchronous storage calculation for accurate disk usage recount.
  Future<double> getStorageUsedGBAsync() async {
    final dir = await modelsDirectory;
    int totalBytes = 0;
    if (await dir.exists()) {
      await for (final entity in dir.list(recursive: false)) {
        if (entity is File &&
            (entity.path.endsWith('.bin') || entity.path.endsWith('.part'))) {
          totalBytes += await entity.length();
        }
      }
    }
    return totalBytes / (1024.0 * 1024.0 * 1024.0);
  }

  @override
  double getStorageTotalGB() => AppConstants.storageCapacityGB;

  /// Ensures that the local file path is strictly located within the models directory.
  String _resolveSafeLocalPath(Directory baseDir, String modelFile) {
    if (modelFile.contains('..') ||
        modelFile.startsWith('/') ||
        modelFile.startsWith('\\') ||
        modelFile.contains(':')) {
      throw SecurityException(
        'Path traversal detected in model file',
        modelFile,
      );
    }

    final filename = p.basename(modelFile);
    final targetPath = p.normalize(p.join(baseDir.path, filename));
    final normalizedBase = p.normalize(baseDir.path);

    if (!targetPath.startsWith(normalizedBase)) {
      throw SecurityException(
        'Resolved path escapes model directory',
        targetPath,
      );
    }

    return targetPath;
  }

  /// Computes SHA256 of a local file efficiently via stream.
  Future<String> _computeSha256(File file) async {
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString().toLowerCase();
  }
}
