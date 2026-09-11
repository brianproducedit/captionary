import 'package:flutter_test/flutter_test.dart';
import 'package:captionary/data/models/download_progress.dart';

void main() {
  group('DownloadProgress Tests', () {
    test('should create a valid DownloadProgress', () {
      final dp = DownloadProgress(
        languageCode: 'en',
        downloadedBytes: 500,
        totalBytes: 1000,
        speedBytesPerSec: 10,
        estimatedTimeRemaining: const Duration(seconds: 50),
        state: DownloadState.downloading,
      );

      expect(dp.languageCode, 'en');
      expect(dp.state, DownloadState.downloading);
      expect(dp.downloadedBytes, 500);
    });
  });
}
