class ExportJob {
  final String id;
  final String sourceFileName;
  final String outputFileName;
  final ExportState state;
  final double progress; // 0.0 to 1.0
  final String resolution;
  final String codec;
  final int bitrateMbps;
  final Duration estimatedTimeRemaining;
  final int outputSizeBytes;
  final bool hardwareAcceleration;
  final String? fallbackReason;

  ExportJob({
    required this.id,
    required this.sourceFileName,
    required this.outputFileName,
    required this.state,
    required this.progress,
    required this.resolution,
    required this.codec,
    required this.bitrateMbps,
    required this.estimatedTimeRemaining,
    required this.outputSizeBytes,
    required this.hardwareAcceleration,
    this.fallbackReason,
  });

  ExportJob copyWith({
    String? id,
    String? sourceFileName,
    String? outputFileName,
    ExportState? state,
    double? progress,
    String? resolution,
    String? codec,
    int? bitrateMbps,
    Duration? estimatedTimeRemaining,
    int? outputSizeBytes,
    bool? hardwareAcceleration,
    String? fallbackReason,
  }) {
    return ExportJob(
      id: id ?? this.id,
      sourceFileName: sourceFileName ?? this.sourceFileName,
      outputFileName: outputFileName ?? this.outputFileName,
      state: state ?? this.state,
      progress: progress ?? this.progress,
      resolution: resolution ?? this.resolution,
      codec: codec ?? this.codec,
      bitrateMbps: bitrateMbps ?? this.bitrateMbps,
      estimatedTimeRemaining:
          estimatedTimeRemaining ?? this.estimatedTimeRemaining,
      outputSizeBytes: outputSizeBytes ?? this.outputSizeBytes,
      hardwareAcceleration: hardwareAcceleration ?? this.hardwareAcceleration,
      fallbackReason: fallbackReason ?? this.fallbackReason,
    );
  }
}

enum ExportState { idle, encoding, complete, error, cancelled }
