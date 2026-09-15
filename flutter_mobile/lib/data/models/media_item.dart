class MediaItem {
  final String id;
  final String fileName;
  final String filePath;
  final int fileSizeBytes;
  final String resolution;
  final Duration duration;
  final String? thumbnailPath;
  final MediaStatus status;
  final String? detectedLanguage;
  final DateTime importedAt;

  MediaItem({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.fileSizeBytes,
    required this.resolution,
    required this.duration,
    this.thumbnailPath,
    required this.status,
    this.detectedLanguage,
    required this.importedAt,
  });

  MediaItem copyWith({
    String? id,
    String? fileName,
    String? filePath,
    int? fileSizeBytes,
    String? resolution,
    Duration? duration,
    String? thumbnailPath,
    MediaStatus? status,
    String? detectedLanguage,
    DateTime? importedAt,
  }) {
    return MediaItem(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      resolution: resolution ?? this.resolution,
      duration: duration ?? this.duration,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      status: status ?? this.status,
      detectedLanguage: detectedLanguage ?? this.detectedLanguage,
      importedAt: importedAt ?? this.importedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'filePath': filePath,
      'fileSizeBytes': fileSizeBytes,
      'resolution': resolution,
      'durationMs': duration.inMilliseconds,
      'thumbnailPath': thumbnailPath,
      'status': status.name,
      'detectedLanguage': detectedLanguage,
      'importedAt': importedAt.toIso8601String(),
    };
  }

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      filePath: json['filePath'] as String,
      fileSizeBytes: json['fileSizeBytes'] as int? ?? 0,
      resolution: json['resolution'] as String? ?? 'Unknown',
      duration: Duration(milliseconds: json['durationMs'] as int? ?? 0),
      thumbnailPath: json['thumbnailPath'] as String?,
      status: MediaStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => MediaStatus.newItem,
      ),
      detectedLanguage: json['detectedLanguage'] as String?,
      importedAt: json['importedAt'] != null
          ? DateTime.tryParse(json['importedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  bool get isAudio {
    final name = fileName.toLowerCase();
    const extensions = [
      '.mp3',
      '.wav',
      '.m4a',
      '.aac',
      '.ogg',
      '.flac',
      '.wma',
    ];
    return extensions.any(name.endsWith);
  }

  bool get isExported {
    final haystack = '${fileName.toLowerCase()} ${filePath.toLowerCase()}';
    return haystack.contains('_captionary_');
  }

  bool get isVideo => !isAudio;
}

enum MediaStatus { newItem, pendingAudioSync, readyToEdit, transcribed, error }
