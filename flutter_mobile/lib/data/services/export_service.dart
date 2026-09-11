import '../models/subtitle_segment.dart';
import '../models/caption_style.dart';
import '../models/export_job.dart';

abstract class ExportService {
  Stream<ExportJob> burnCaptions({
    required String videoPath,
    required List<SubtitleSegment> segments,
    required CaptionStyle style,
    required String outputPath,
    required Duration videoDuration,
  });
  Future<String> exportSRT(List<SubtitleSegment> segments);
  Future<String> exportVTT(List<SubtitleSegment> segments);
}
