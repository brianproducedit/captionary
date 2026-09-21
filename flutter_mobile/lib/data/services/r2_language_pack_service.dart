import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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
               connectTimeout: const Duration(seconds: 5),
               receiveTimeout: const Duration(seconds: 15),
               sendTimeout: const Duration(seconds: 5),
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
    catalogVersion: 2,
    updatedAt: DateTime.parse('2026-09-21T00:00:00Z'),
    baseUrl: 'https://pub-6315c0ddbd0d44b4856162c00e47e86e.r2.dev',
    defaultLanguage: 'en',
    models: [
      const CatalogModel(
        id: 'tiny.en',
        engine: 'whisper_flutter_new',
        file: 'models/ggml-tiny.en.bin',
        languageCodes: ['en'],
        displayName: 'English Tiny',
        sizeBytes: 77704715,
        sha256:
            '921e4cf8686fdd993dcd081a5da5b6c365bfde1162e72b08d75ac75289920b1f',
        quantization: 'none',
        bundled: false,
        minAndroidSdk: 21,
        recommendedRamGb: 4,
        license: 'MIT',
        sourceUrl:
            'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.en.bin',
      ),
      const CatalogModel(
        id: 'base',
        engine: 'whisper_flutter_new',
        file: 'models/ggml-base.bin',
        languageCodes: [
          'sn',
          'zu',
          'sw',
          'af',
          'nd',
          'st',
          'nso',
          'tn',
          'to',
          'xh',
          'yo',
          'en',
          'fr',
          'es',
          'pt',
          'de',
          'it',
          'ru',
          'nl',
          'ar',
          'hi',
          'ja',
          'zh',
          'ko',
          'tr',
        ],
        displayName: 'Multilingual Base (High Accuracy)',
        sizeBytes: 147964211,
        sha256:
            '60ed5bc3dd14eea856493d334349b405782ddcaf00287874b079a3249e5a4d84',
        quantization: 'none',
        bundled: false,
        minAndroidSdk: 21,
        recommendedRamGb: 4,
        license: 'MIT',
        sourceUrl:
            'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin',
      ),
      const CatalogModel(
        id: 'tiny',
        engine: 'whisper_flutter_new',
        file: 'models/ggml-tiny.bin',
        languageCodes: [
          'sn',
          'zu',
          'sw',
          'af',
          'nd',
          'st',
          'nso',
          'tn',
          'to',
          'xh',
          'yo',
          'en',
          'fr',
          'es',
          'pt',
          'de',
          'it',
          'ru',
          'nl',
          'ar',
          'hi',
          'ja',
          'zh',
          'ko',
          'tr',
        ],
        displayName: 'Multilingual Tiny',
        sizeBytes: 77704715,
        sha256:
            'bd577a113a864445d4c299885e8aa977798604f7922c7477048034da473fe205',
        quantization: 'none',
        bundled: false,
        minAndroidSdk: 21,
        recommendedRamGb: 3,
        license: 'MIT',
        sourceUrl:
            'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.bin',
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

    int priority = 1;
    for (final model in catalog.models) {
      final localPath = _resolveSafeLocalPath(dir, model.file);
      final binFile = File(localPath);
      final metaFile = File('$localPath.meta.json');
      final partFile = File('$localPath.part');

      LanguagePackStatus status;
      double progress = 0.0;
      int? bytesDownloaded;

      if (await binFile.exists() && await metaFile.exists()) {
        final currentSize = await binFile.length();
        if (currentSize == model.sizeBytes) {
          status = model.bundled
              ? LanguagePackStatus.bundled
              : LanguagePackStatus.installed;
          progress = 1.0;
          bytesDownloaded = currentSize;
        } else {
          // Incomplete or corrupted file without valid size
          status = LanguagePackStatus.notDownloaded;
        }
      } else if (await partFile.exists()) {
        final partSize = await partFile.length();
        if (partSize > 0 && partSize < model.sizeBytes) {
          status = LanguagePackStatus.paused;
          progress = partSize / model.sizeBytes;
          bytesDownloaded = partSize;
        } else {
          status = LanguagePackStatus.notDownloaded;
        }
      } else {
        status = LanguagePackStatus.notDownloaded;
      }

      if (model.languageCodes.length == 1) {
        final code = model.languageCodes.first;
        if (!addedCodes.contains(code)) {
          addedCodes.add(code);
          packs.add(
            model.toLanguagePack(
              status: status,
              downloadProgress: progress,
              bytesDownloaded: bytesDownloaded,
              priority: priority++,
            ),
          );
        }
      } else {
        for (final code in model.languageCodes) {
          if (!addedCodes.contains(code)) {
            addedCodes.add(code);
            packs.add(
              model.toLanguagePackForLanguage(
                code,
                status: status,
                downloadProgress: progress,
                bytesDownloaded: bytesDownloaded,
                priority: priority++,
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
    final model = catalog.models.firstWhere(
      (m) => m.languageCodes.contains(code) || m.id == code,
      orElse: () => throw ArgumentError('Language code not found: $code'),
    );

    final dir = await modelsDirectory;
    final finalPath = _resolveSafeLocalPath(dir, model.file);
    final finalFile = File(finalPath);
    final partFile = File('$finalPath.part');
    final metaFile = File('$finalPath.meta.json');

    // If already installed and valid, yield complete immediately
    if (await finalFile.exists() && await metaFile.exists()) {
      final currentSize = await finalFile.length();
      if (currentSize == model.sizeBytes) {
        yield DownloadProgress(
          languageCode: code,
          downloadedBytes: model.sizeBytes,
          totalBytes: model.sizeBytes,
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
      if (existingBytes >= model.sizeBytes) {
        await partFile.delete();
        existingBytes = 0;
      }
    }

    IOSink? sink;
    try {
      final Map<String, dynamic> headers = {};
      bool isResume = existingBytes > 0;
      if (isResume) {
        headers['Range'] = 'bytes=$existingBytes-';
      }

      final response = await _dio.get<ResponseBody>(
        downloadUrl.toString(),
        options: Options(headers: headers, responseType: ResponseType.stream),
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
          final speed = elapsedSec > 0 ? bytesSinceLastTick / elapsedSec : 0.0;
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
        // Paused/cancelled: keep .part file intact (deleteOnError: false)
        return;
      }

      // Check SHA256 integrity
      yield DownloadProgress(
        languageCode: code,
        downloadedBytes: downloadedBytes,
        totalBytes: totalBytes,
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
        downloadedBytes: totalBytes,
        totalBytes: totalBytes,
        speedBytesPerSec: 0,
        estimatedTimeRemaining: Duration.zero,
        state: DownloadState.complete,
      );
    } catch (e) {
      if (sink != null) {
        try {
          await sink.flush();
          await sink.close();
        } catch (_) {}
      }

      _activeTokens.remove(code);

      // If cancelled, keep the .part file
      if (cancelToken.isCancelled) {
        return;
      }

      // If it's a checksum mismatch, the part file was already deleted
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
        final model = catalog.models.firstWhere(
          (m) => m.languageCodes.contains(code) || m.id == code,
        );
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
    final model = catalog.models.firstWhere(
      (m) => m.languageCodes.contains(code) || m.id == code,
      orElse: () => throw ArgumentError('Language code not found: $code'),
    );

    final dir = await modelsDirectory;
    final localPath = _resolveSafeLocalPath(dir, model.file);
    final binFile = File(localPath);
    final metaFile = File('$localPath.meta.json');
    final partFile = File('$localPath.part');

    if (await binFile.exists()) {
      await binFile.delete();
    }
    if (await metaFile.exists()) {
      await metaFile.delete();
    }
    if (await partFile.exists()) {
      await partFile.delete();
    }
  }

  @override
  Future<String> detectLanguage(String audioPath) async {
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
