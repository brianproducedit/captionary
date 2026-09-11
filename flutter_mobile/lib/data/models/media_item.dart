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

enum MediaStatus { newItem, pendingAudioSync, readyToEdit, transcribed }
