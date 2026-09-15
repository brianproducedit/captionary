import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:captionary/data/exceptions/language_pack_exceptions.dart';
import 'package:captionary/data/models/catalog_manifest.dart';
import 'package:captionary/data/models/download_progress.dart';
import 'package:captionary/data/models/language_pack.dart';
import 'package:captionary/data/services/r2_language_pack_service.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('CatalogManifest Parsing and Security', () {
    test('parses valid manifest with models', () {
      const validJson = '''
      {
        "schema_version": 1,
        "catalog_version": 1,
        "updated_at": "2026-09-15T00:00:00Z",
        "base_url": "https://pub-6315c0ddbd0d44b4856162c00e47e86e.r2.dev/",
        "default_language": "en",
        "models": [
          {
            "id": "tiny.en",
            "engine": "whisper_flutter_new",
            "file": "models/ggml-tiny.en.bin",
            "language_codes": ["en"],
            "display_name": "English Tiny",
            "size_bytes": 77704715,
            "sha256": "921e4cf8686fdd993dcd081a5da5b6c365bfde1162e72b08d75ac75289920b1f",
            "quantization": "none",
            "bundled": false,
            "min_android_sdk": 21,
            "recommended_ram_gb": 4,
            "license": "MIT",
            "source_url": "https://huggingface.co/ggerganov/whisper.cpp"
          }
        ]
      }
      ''';

      final manifest = CatalogManifest.fromJsonString(validJson);
      expect(manifest.schemaVersion, 1);
      expect(manifest.catalogVersion, 1);
      expect(manifest.defaultLanguage, 'en');
      expect(manifest.models.length, 1);

      final model = manifest.models.first;
      expect(model.id, 'tiny.en');
      expect(model.displayName, 'English Tiny');
      expect(model.sizeBytes, 77704715);
      expect(
        model.sha256,
        '921e4cf8686fdd993dcd081a5da5b6c365bfde1162e72b08d75ac75289920b1f',
      );

      final pack = model.toLanguagePack(
        status: LanguagePackStatus.notDownloaded,
      );
      expect(pack.code, 'en');
      expect(pack.name, 'English Tiny');
      expect(pack.modelFile, 'ggml-tiny.en.bin');
    });

    test('rejects schema_version < 1', () {
      const invalidJson = '{"schema_version": 0, "models": []}';
      expect(
        () => CatalogManifest.fromJsonString(invalidJson),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects path traversal in model file path', () {
      const traversalJson = '''
      {
        "schema_version": 1,
        "models": [
          {
            "id": "bad",
            "file": "models/../../etc/passwd",
            "language_codes": ["en"],
            "size_bytes": 100,
            "sha256": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
          }
        ]
      }
      ''';
      expect(
        () => CatalogManifest.fromJsonString(traversalJson),
        throwsA(isA<SecurityException>()),
      );
    });

    test('rejects absolute paths in model file path', () {
      const absoluteJson = '''
      {
        "schema_version": 1,
        "models": [
          {
            "id": "bad",
            "file": "/var/data/model.bin",
            "language_codes": ["en"],
            "size_bytes": 100,
            "sha256": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
          }
        ]
      }
      ''';
      expect(
        () => CatalogManifest.fromJsonString(absoluteJson),
        throwsA(isA<SecurityException>()),
      );
    });

    test('rejects invalid SHA256 strings', () {
      const badHashJson = '''
      {
        "schema_version": 1,
        "models": [
          {
            "id": "bad",
            "file": "models/ggml.bin",
            "language_codes": ["en"],
            "size_bytes": 100,
            "sha256": "not-a-valid-sha256"
          }
        ]
      }
      ''';
      expect(
        () => CatalogManifest.fromJsonString(badHashJson),
        throwsA(isA<FormatException>()),
      );
    });

    test('resolves model URL safely against baseUrl', () {
      final manifest = CatalogManifest(
        schemaVersion: 1,
        catalogVersion: 1,
        updatedAt: null,
        baseUrl: 'https://models.captionary.co.zw',
        defaultLanguage: 'en',
        models: [
          const CatalogModel(
            id: 'tiny.en',
            engine: 'whisper_flutter_new',
            file: 'models/ggml-tiny.en.bin',
            languageCodes: ['en'],
            displayName: 'Tiny English',
            sizeBytes: 100,
            sha256: '921e4cf8686fdd993dcd081a5da5b6c365bfde1162e72b08d75ac75289920b1f',
          ),
        ],
      );

      final url = manifest.resolveModelUrl(manifest.models.first);
      expect(
        url.toString(),
        'https://models.captionary.co.zw/models/ggml-tiny.en.bin',
      );
    });
  });

  group('R2LanguagePackService Network & Resumable Downloads', () {
    late Directory tempDir;
    late HttpServer server;
    late String serverBaseUrl;

    // Test model payload (100 bytes)
    final testPayload = List<int>.generate(100, (i) => i % 256);
    final expectedSha256 = sha256.convert(testPayload).toString().toLowerCase();

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('captionary_b7_test_');

      // Spin up local HTTP server to act as R2 public bucket
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      serverBaseUrl = 'http://${server.address.host}:${server.port}';
    });

    tearDown(() async {
      await server.close(force: true);
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    void handleRequests({
      bool force200OnRange = false,
      bool simulateCorruptBytes = false,
    }) {
      server.listen((HttpRequest request) async {
        final path = request.uri.path;

        if (path == '/manifest.json') {
          final manifestJson = jsonEncode({
            'schema_version': 1,
            'catalog_version': 1,
            'base_url': '$serverBaseUrl/',
            'default_language': 'en',
            'models': [
              {
                'id': 'test.en',
                'engine': 'whisper_flutter_new',
                'file': 'models/ggml-test.en.bin',
                'language_codes': ['en'],
                'display_name': 'Test English',
                'size_bytes': testPayload.length,
                'sha256': expectedSha256,
              },
            ],
          });
          request.response.statusCode = HttpStatus.ok;
          request.response.headers.contentType = ContentType.json;
          request.response.write(manifestJson);
          await request.response.close();
          return;
        }

        if (path == '/models/ggml-test.en.bin') {
          final rangeHeader = request.headers.value(HttpHeaders.rangeHeader);

          if (rangeHeader != null && !force200OnRange) {
            // Range request: bytes=X-
            final match = RegExp(r'bytes=(\d+)-').firstMatch(rangeHeader);
            if (match != null) {
              final startByte = int.parse(match.group(1)!);
              final slice = testPayload.sublist(startByte);

              request.response.statusCode = HttpStatus.partialContent;
              request.response.headers.set(
                HttpHeaders.contentRangeHeader,
                'bytes $startByte-${testPayload.length - 1}/${testPayload.length}',
              );
              request.response.headers.contentLength = slice.length;

              final bytesToSend = simulateCorruptBytes
                  ? List<int>.generate(slice.length, (i) => 0xFF)
                  : slice;
              request.response.add(bytesToSend);
              await request.response.close();
              return;
            }
          }

          // Full GET (200 OK)
          request.response.statusCode = HttpStatus.ok;
          request.response.headers.contentLength = testPayload.length;
          final bytesToSend = simulateCorruptBytes
              ? List<int>.generate(testPayload.length, (i) => 0xFF)
              : testPayload;
          request.response.add(bytesToSend);
          await request.response.close();
          return;
        }

        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
      });
    }

    test(
      'manifest fetch caches to disk and flags stale when offline',
      () async {
        handleRequests();

        final service = R2LanguagePackService(
          manifestUrl: '$serverBaseUrl/manifest.json',
          r2BaseUrl: serverBaseUrl,
          getModelsDirectory: () async => tempDir,
        );

        // 1. Initial fetch over network
        final manifest = await service.fetchManifest();
        expect(manifest.models.length, 1);
        expect(service.isCatalogStale, false);

        final cacheFile = File(p.join(tempDir.path, 'manifest_cache.json'));
        expect(cacheFile.existsSync(), true);

        // 2. Shut down server to simulate offline state
        await server.close(force: true);

        // 3. Second service instance pointing to same modelsDirectory
        final offlineService = R2LanguagePackService(
          manifestUrl: '$serverBaseUrl/manifest.json',
          r2BaseUrl: serverBaseUrl,
          getModelsDirectory: () async => tempDir,
        );

        final cachedManifest = await offlineService.fetchManifest();
        expect(cachedManifest.models.length, 1);
        expect(offlineService.isCatalogStale, true);
      },
    );

    test(
      'resumable download: 206 Partial Content appends to .part and completes',
      () async {
        handleRequests();

        final service = R2LanguagePackService(
          manifestUrl: '$serverBaseUrl/manifest.json',
          r2BaseUrl: serverBaseUrl,
          getModelsDirectory: () async => tempDir,
        );

        // Pre-create partial .part file with first 40 bytes
        final partFile = File(p.join(tempDir.path, 'ggml-test.en.bin.part'));
        await partFile.writeAsBytes(testPayload.sublist(0, 40));

        final progressEvents = <DownloadProgress>[];
        await for (final event in service.downloadLanguagePack('en')) {
          progressEvents.add(event);
        }

        // Check events
        expect(
          progressEvents.any((e) => e.state == DownloadState.complete),
          true,
        );

        // Final .bin file must exist with full content
        final binFile = File(p.join(tempDir.path, 'ggml-test.en.bin'));
        expect(binFile.existsSync(), true);
        expect(binFile.readAsBytesSync(), testPayload);

        // .part file must be cleaned up (renamed)
        expect(partFile.existsSync(), false);

        // Metadata JSON file must exist
        final metaFile = File(
          p.join(tempDir.path, 'ggml-test.en.bin.meta.json'),
        );
        expect(metaFile.existsSync(), true);
        final metaJson = jsonDecode(metaFile.readAsStringSync());
        expect(metaJson['sha256'], expectedSha256);
        expect(metaJson['size_bytes'], testPayload.length);
      },
    );

    test(
      'full-GET fallback: restarts from byte 0 if server returns 200 on Range',
      () async {
        // Configure server to return 200 OK even when Range is sent
        handleRequests(force200OnRange: true);

        final service = R2LanguagePackService(
          manifestUrl: '$serverBaseUrl/manifest.json',
          r2BaseUrl: serverBaseUrl,
          getModelsDirectory: () async => tempDir,
        );

        // Pre-create partial .part file with first 40 bytes
        final partFile = File(p.join(tempDir.path, 'ggml-test.en.bin.part'));
        await partFile.writeAsBytes(testPayload.sublist(0, 40));

        await for (final _ in service.downloadLanguagePack('en')) {}

        // Final .bin file must have exactly 100 bytes (not 140)
        final binFile = File(p.join(tempDir.path, 'ggml-test.en.bin'));
        expect(binFile.existsSync(), true);
        expect(binFile.lengthSync(), testPayload.length);
        expect(binFile.readAsBytesSync(), testPayload);
      },
    );

    test(
      'checksum mismatch deletes .part and throws ChecksumMismatchException',
      () async {
        // Server will return corrupted bytes
        handleRequests(simulateCorruptBytes: true);

        final service = R2LanguagePackService(
          manifestUrl: '$serverBaseUrl/manifest.json',
          r2BaseUrl: serverBaseUrl,
          getModelsDirectory: () async => tempDir,
        );

        final partFile = File(p.join(tempDir.path, 'ggml-test.en.bin.part'));
        final binFile = File(p.join(tempDir.path, 'ggml-test.en.bin'));

        expect(() async {
          await for (final _ in service.downloadLanguagePack('en')) {}
        }, throwsA(isA<ChecksumMismatchException>()));

        // Neither .bin nor .part must exist on disk after mismatch
        expect(binFile.existsSync(), false);
        expect(partFile.existsSync(), false);
      },
    );

    test('cancel keeps .part file intact when deletePart is false', () async {
      // Simulate slow streaming server
      server.listen((HttpRequest request) async {
        if (request.uri.path == '/manifest.json') {
          final manifestJson = jsonEncode({
            'schema_version': 1,
            'catalog_version': 1,
            'base_url': '$serverBaseUrl/',
            'default_language': 'en',
            'models': [
              {
                'id': 'test.en',
                'file': 'models/ggml-test.en.bin',
                'language_codes': ['en'],
                'display_name': 'Test English',
                'size_bytes': 1000,
                'sha256': expectedSha256,
              },
            ],
          });
          request.response.statusCode = HttpStatus.ok;
          request.response.headers.contentType = ContentType.json;
          request.response.write(manifestJson);
          await request.response.close();
          return;
        }

        if (request.uri.path == '/models/ggml-test.en.bin') {
          request.response.statusCode = HttpStatus.ok;
          request.response.headers.contentLength = 1000;
          // Send 200 bytes then pause
          request.response.add(List<int>.filled(200, 1));
          await request.response.flush();
          // Hold stream open
          await Future.delayed(const Duration(seconds: 5));
          request.response.add(List<int>.filled(800, 2));
          await request.response.close();
          return;
        }
      });

      final service = R2LanguagePackService(
        manifestUrl: '$serverBaseUrl/manifest.json',
        r2BaseUrl: serverBaseUrl,
        getModelsDirectory: () async => tempDir,
      );

      final stream = service.downloadLanguagePack('en');
      final completer = Completer<void>();

      final sub = stream.listen((progress) {
        if (progress.downloadedBytes >= 200 && !completer.isCompleted) {
          completer.complete();
        }
      });

      await completer.future;

      // Cancel with deletePart: false (pause)
      await service.cancelDownload('en', deletePart: false);
      await sub.cancel();

      final partFile = File(p.join(tempDir.path, 'ggml-test.en.bin.part'));
      expect(partFile.existsSync(), true);
      expect(partFile.lengthSync(), greaterThanOrEqualTo(200));
    });

    test('deleteLanguagePack removes bin, meta, and part files and recounts storage', () async {
      handleRequests();

      final service = R2LanguagePackService(
        manifestUrl: '$serverBaseUrl/manifest.json',
        r2BaseUrl: serverBaseUrl,
        getModelsDirectory: () async => tempDir,
      );

      // Download completely
      await for (final _ in service.downloadLanguagePack('en')) {}

      final binFile = File(p.join(tempDir.path, 'ggml-test.en.bin'));
      final metaFile = File(p.join(tempDir.path, 'ggml-test.en.bin.meta.json'));
      expect(binFile.existsSync(), true);
      expect(metaFile.existsSync(), true);

      final storageUsed = await service.getStorageUsedGBAsync();
      expect(storageUsed, greaterThan(0));

      // Delete language pack
      await service.deleteLanguagePack('en');

      expect(binFile.existsSync(), false);
      expect(metaFile.existsSync(), false);

      final storageAfterDelete = await service.getStorageUsedGBAsync();
      expect(storageAfterDelete, 0.0);
    });
  });
}
