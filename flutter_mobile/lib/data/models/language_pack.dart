class LanguagePack {
  final String code;
  final String name;
  final String nativeName;
  final String region;
  final String modelFile;
  final int sizeBytes;
  final String sha256;
  final String accuracy;
  final String engine;
  final bool isBundled;
  final int priority;
  final LanguagePackStatus status;
  final double downloadProgress; // 0.0 to 1.0
  final double? downloadSpeedMbps;
  final int? bytesDownloaded;

  LanguagePack({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.region,
    required this.modelFile,
    required this.sizeBytes,
    required this.sha256,
    required this.accuracy,
    required this.engine,
    required this.isBundled,
    required this.priority,
    required this.status,
    required this.downloadProgress,
    this.downloadSpeedMbps,
    this.bytesDownloaded,
  });

  LanguagePack copyWith({
    String? code,
    String? name,
    String? nativeName,
    String? region,
    String? modelFile,
    int? sizeBytes,
    String? sha256,
    String? accuracy,
    String? engine,
    bool? isBundled,
    int? priority,
    LanguagePackStatus? status,
    double? downloadProgress,
    double? downloadSpeedMbps,
    int? bytesDownloaded,
  }) {
    return LanguagePack(
      code: code ?? this.code,
      name: name ?? this.name,
      nativeName: nativeName ?? this.nativeName,
      region: region ?? this.region,
      modelFile: modelFile ?? this.modelFile,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      sha256: sha256 ?? this.sha256,
      accuracy: accuracy ?? this.accuracy,
      engine: engine ?? this.engine,
      isBundled: isBundled ?? this.isBundled,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      downloadSpeedMbps: downloadSpeedMbps ?? this.downloadSpeedMbps,
      bytesDownloaded: bytesDownloaded ?? this.bytesDownloaded,
    );
  }
}

enum LanguagePackStatus { notDownloaded, downloading, paused, installed, bundled, error }
