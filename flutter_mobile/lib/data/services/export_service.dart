import '../../core/caption_export.dart';
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

  /// Adapter method for ASS format export.
  ///
  /// Implemented with a default adapter to avoid breaking existing implementations.
  Future<String> exportASS(
    List<SubtitleSegment> segments, {
    CaptionStyle? style,
  }) async {
    return CaptionExport.ass(segments, style: style);
  }

  /// Cancels any in-flight export session and cleans up temporary resources.
  Future<void> cancel() async {}
}
