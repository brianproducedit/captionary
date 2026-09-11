import '../services/export_service.dart';
import '../models/export_job.dart';
import '../models/subtitle_segment.dart';
import '../models/caption_style.dart';

class MockExportService implements ExportService {
  @override
  Stream<ExportJob> burnCaptions({
    required String videoPath,
    required List<SubtitleSegment> segments,
    required CaptionStyle style,
    required String outputPath,
    required Duration videoDuration,
  }) async* {
    for (int i = 0; i <= 50; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      yield ExportJob(
        id: 'mock_export_1',
        sourceFileName: 'Source_Video.mp4',
        outputFileName: 'Output_Video.mp4',
        state: i == 50 ? ExportState.complete : ExportState.encoding,
        progress: i * 0.02,
        resolution: '1080x1920',
        codec: 'h264',
        bitrateMbps: 8,
        estimatedTimeRemaining: Duration(seconds: 50 - i),
        outputSizeBytes: (35000000 * (i * 0.02)).toInt(),
        hardwareAcceleration: true,
      );
    }
  }

  @override
  Future<String> exportSRT(List<SubtitleSegment> segments) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return '1\n00:00:00,000 --> 00:00:03,000\nMhoroi mose, ndinofara kuva pano\n\n';
  }

  @override
  Future<String> exportVTT(List<SubtitleSegment> segments) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return 'WEBVTT\n\n00:00.000 --> 00:03.000\nMhoroi mose, ndinofara kuva pano\n\n';
  }
}
