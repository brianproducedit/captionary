import 'package:flutter_test/flutter_test.dart';
import 'package:captionary/data/models/export_job.dart';

void main() {
  group('ExportJob Tests', () {
    test('should create a valid ExportJob', () {
      final job = ExportJob(
        id: 'job1',
        sourceFileName: 'source.mp4',
        outputFileName: 'output.mp4',
        state: ExportState.encoding,
        progress: 0.5,
        resolution: '1080p',
        codec: 'h264',
        bitrateMbps: 5,
        estimatedTimeRemaining: const Duration(minutes: 1),
        outputSizeBytes: 5000,
        hardwareAcceleration: true,
      );

      expect(job.id, 'job1');
      expect(job.state, ExportState.encoding);
      expect(job.progress, 0.5);
    });
  });
}
