import '../../core/caption_export.dart';
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
    _isCancelled = false;
    for (int i = 0; i <= 50; i++) {
      if (_isCancelled) {
        yield ExportJob(
          id: 'mock_export_1',
          sourceFileName: 'Source_Video.mp4',
          outputFileName: 'Output_Video.mp4',
          state: ExportState.cancelled,
          progress: i * 0.02,
          resolution: '1080x1920',
          codec: 'h264',
          bitrateMbps: 8,
          estimatedTimeRemaining: Duration.zero,
          outputSizeBytes: (35000000 * (i * 0.02)).toInt(),
          hardwareAcceleration: true,
        );
        return;
      }
      await Future.delayed(const Duration(milliseconds: 1));
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
    return CaptionExport.srt(segments);
  }

  @override
  Future<String> exportVTT(List<SubtitleSegment> segments) async {
    return CaptionExport.vtt(segments);
  }

  @override
  Future<String> exportASS(
    List<SubtitleSegment> segments, {
    CaptionStyle? style,
  }) async {
    return CaptionExport.ass(segments, style: style);
  }

  bool _isCancelled = false;

  @override
  Future<void> cancel() async {
    _isCancelled = true;
  }
}
