class DownloadProgress {
  final String languageCode;
  final int downloadedBytes;
  final int totalBytes;
  final double speedBytesPerSec;
  final Duration estimatedTimeRemaining;
  final DownloadState state;

  DownloadProgress({
    required this.languageCode,
    required this.downloadedBytes,
    required this.totalBytes,
    required this.speedBytesPerSec,
    required this.estimatedTimeRemaining,
    required this.state,
  });
}

enum DownloadState { idle, downloading, verifying, complete, error }
