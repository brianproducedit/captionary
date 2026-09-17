import 'dart:convert';

import 'package:path/path.dart' as p;

import '../exceptions/language_pack_exceptions.dart';
import 'language_pack.dart';

class CatalogModel {
  final String id;
  final String engine;
  final String file;
  final List<String> languageCodes;
  final String displayName;
  final int sizeBytes;
  final String sha256;
  final String quantization;
  final bool bundled;
  final int minAndroidSdk;
  final int recommendedRamGb;
  final String? license;
  final String? sourceUrl;

  const CatalogModel({
    required this.id,
    required this.engine,
    required this.file,
    required this.languageCodes,
    required this.displayName,
    required this.sizeBytes,
    required this.sha256,
    this.quantization = 'none',
    this.bundled = false,
    this.minAndroidSdk = 21,
    this.recommendedRamGb = 4,
    this.license,
    this.sourceUrl,
  });

  factory CatalogModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    if (id == null || id.trim().isEmpty) {
      throw const FormatException('CatalogModel id is required.');
    }

    final file = json['file'] as String?;
    if (file == null || file.trim().isEmpty) {
      throw FormatException('CatalogModel "$id" is missing "file".');
    }

    // Path traversal and safety checks
    if (file.contains('..') ||
        file.startsWith('/') ||
        file.startsWith('\\') ||
        file.contains(':')) {
      throw SecurityException(
        'Path traversal detected in model file path',
        file,
      );
    }

    final sha256 = json['sha256'] as String?;
    if (sha256 == null || !RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(sha256)) {
      throw FormatException('Invalid SHA256 for model "$id": $sha256');
    }

    final sizeBytes = json['size_bytes'] as int?;
    if (sizeBytes == null || sizeBytes <= 0) {
      throw FormatException('Invalid size_bytes for model "$id": $sizeBytes');
    }

    final rawCodes = json['language_codes'];
    final List<String> languageCodes;
    if (rawCodes is List) {
      languageCodes = rawCodes
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } else {
      languageCodes = [];
    }
    if (languageCodes.isEmpty) {
      throw FormatException(
        'Model "$id" must have at least one language code.',
      );
    }

    return CatalogModel(
      id: id,
      engine: json['engine'] as String? ?? 'whisper_flutter_new',
      file: file,
      languageCodes: languageCodes,
      displayName: json['display_name'] as String? ?? id,
      sizeBytes: sizeBytes,
      sha256: sha256.toLowerCase(),
      quantization: json['quantization'] as String? ?? 'none',
      bundled: json['bundled'] as bool? ?? false,
      minAndroidSdk: json['min_android_sdk'] as int? ?? 21,
      recommendedRamGb: json['recommended_ram_gb'] as int? ?? 4,
      license: json['license'] as String?,
      sourceUrl: json['source_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'engine': engine,
    'file': file,
    'language_codes': languageCodes,
    'display_name': displayName,
    'size_bytes': sizeBytes,
    'sha256': sha256,
    'quantization': quantization,
    'bundled': bundled,
    'min_android_sdk': minAndroidSdk,
    'recommended_ram_gb': recommendedRamGb,
    if (license != null) 'license': license,
    if (sourceUrl != null) 'source_url': sourceUrl,
  };

  /// Converts this catalog entry into an app-level [LanguagePack].
  LanguagePack toLanguagePack({
    required LanguagePackStatus status,
    double downloadProgress = 0.0,
    int? bytesDownloaded,
    double? downloadSpeedMbps,
    int priority = 1,
  }) {
    final primaryLang = languageCodes.first;
    return LanguagePack(
      code: primaryLang,
      name: displayName,
      nativeName: _resolveNativeName(primaryLang, displayName),
      region: _resolveRegion(primaryLang),
      modelFile: p.basename(file),
      sizeBytes: sizeBytes,
      sha256: sha256,
      accuracy: _resolveAccuracy(id),
      engine: engine,
      isBundled: bundled,
      priority: priority,
      status: status,
      downloadProgress: downloadProgress,
      downloadSpeedMbps: downloadSpeedMbps,
      bytesDownloaded: bytesDownloaded,
      recommendedRamGb: recommendedRamGb,
    );
  }

  static String _resolveNativeName(String code, String defaultName) {
    switch (code) {
      case 'en':
        return 'English';
      case 'sn':
        return 'chiShona';
      case 'zu':
        return 'isiZulu';
      case 'nso':
        return 'Sesotho sa Leboa';
      case 'fr':
        return 'Français';
      case 'tn':
        return 'Setswana';
      case 'to':
        return 'chiTonga';
      case 'sw':
        return 'Kiswahili';
      case 'yo':
        return 'Èdè Yorùbá';
      case 'af':
        return 'Afrikaans';
      case 'pt':
        return 'Português';
      case 'es':
        return 'Español';
      default:
        return defaultName;
    }
  }

  static String _resolveRegion(String code) {
    switch (code) {
      case 'en':
        return 'Global';
      case 'sn':
        return 'Zimbabwe';
      case 'zu':
        return 'South Africa';
      case 'nso':
        return 'South Africa';
      case 'fr':
        return 'Global';
      case 'tn':
        return 'Southern Africa';
      case 'to':
        return 'Zambia & Zimbabwe';
      case 'sw':
        return 'East Africa';
      case 'yo':
        return 'West Africa';
      case 'af':
        return 'Southern Africa';
      case 'pt':
      case 'es':
        return 'Global';
      default:
        return 'General';
    }
  }

  static String _resolveAccuracy(String modelId) {
    final lower = modelId.toLowerCase();
    if (lower.contains('tiny')) return 'Fast';
    if (lower.contains('base')) return 'Standard';
    if (lower.contains('small')) return 'Good';
    if (lower.contains('medium')) return 'High';
    if (lower.contains('large')) return 'Ultra';
    return 'High';
  }
}

class CatalogManifest {
  final int schemaVersion;
  final int catalogVersion;
  final DateTime? updatedAt;
  final String baseUrl;
  final String defaultLanguage;
  final List<CatalogModel> models;

  const CatalogManifest({
    required this.schemaVersion,
    required this.catalogVersion,
    required this.updatedAt,
    required this.baseUrl,
    required this.defaultLanguage,
    required this.models,
  });

  factory CatalogManifest.fromJson(Map<String, dynamic> json) {
    final schemaVersion = json['schema_version'] as int?;
    if (schemaVersion == null || schemaVersion < 1) {
      throw const FormatException(
        'CatalogManifest schema_version must be >= 1.',
      );
    }

    final catalogVersion = json['catalog_version'] as int? ?? 1;
    final updatedAtStr = json['updated_at'] as String?;
    final updatedAt = updatedAtStr != null
        ? DateTime.tryParse(updatedAtStr)
        : null;
    final baseUrl = json['base_url'] as String? ?? '';
    final defaultLanguage = json['default_language'] as String? ?? 'en';

    final rawModels = json['models'];
    if (rawModels is! List) {
      throw const FormatException(
        'CatalogManifest "models" must be a non-empty list.',
      );
    }

    final models = rawModels
        .map((m) => CatalogModel.fromJson(m as Map<String, dynamic>))
        .toList();

    return CatalogManifest(
      schemaVersion: schemaVersion,
      catalogVersion: catalogVersion,
      updatedAt: updatedAt,
      baseUrl: baseUrl,
      defaultLanguage: defaultLanguage,
      models: models,
    );
  }

  factory CatalogManifest.fromJsonString(String rawJson) {
    final dynamic decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Catalog manifest JSON must be an object.');
    }
    return CatalogManifest.fromJson(decoded);
  }

  Map<String, dynamic> toJson() => {
    'schema_version': schemaVersion,
    'catalog_version': catalogVersion,
    if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    'base_url': baseUrl,
    'default_language': defaultLanguage,
    'models': models.map((m) => m.toJson()).toList(),
  };

  /// Resolves the absolute download URL for a model against this catalog's [baseUrl]
  /// or a fallback base URL.
  Uri resolveModelUrl(CatalogModel model, {String? fallbackBaseUrl}) {
    final base = baseUrl.trim().isNotEmpty ? baseUrl : (fallbackBaseUrl ?? '');
    if (base.isEmpty) {
      throw SecurityException('Base URL is empty and cannot resolve model URL');
    }

    // Traversal check
    if (model.file.contains('..') ||
        model.file.startsWith('/') ||
        model.file.startsWith('\\') ||
        model.file.contains(':')) {
      throw SecurityException(
        'Path traversal rejected in model file',
        model.file,
      );
    }

    final normalizedBase = base.endsWith('/') ? base : '$base/';
    return Uri.parse(normalizedBase).resolve(model.file);
  }
}
