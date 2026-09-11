import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/return_code.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/statistics.dart';

import '../models/subtitle_segment.dart';
import '../models/caption_style.dart';
import '../models/export_job.dart';
import 'export_service.dart';

class FfmpegExportService implements ExportService {
  @override
  Future<String> exportSRT(List<SubtitleSegment> segments) async {
    final StringBuffer sb = StringBuffer();
    for (int i = 0; i < segments.length; i++) {
      final seg = segments[i];
      sb.writeln('${i + 1}');
      sb.writeln(
        '${_formatSRTTime(seg.startTime)} --> ${_formatSRTTime(seg.endTime)}',
      );
      sb.writeln(seg.text);
      sb.writeln();
    }
    return sb.toString();
  }

  @override
  Future<String> exportVTT(List<SubtitleSegment> segments) async {
    final StringBuffer sb = StringBuffer();
    sb.writeln('WEBVTT\n');
    for (int i = 0; i < segments.length; i++) {
      final seg = segments[i];
      sb.writeln(
        '${_formatVTTTime(seg.startTime)} --> ${_formatVTTTime(seg.endTime)}',
      );
      sb.writeln(seg.text);
      sb.writeln();
    }
    return sb.toString();
  }

  String _formatSRTTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String threeDigits(int n) => n.toString().padLeft(3, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    String milliseconds = threeDigits(duration.inMilliseconds.remainder(1000));
    return '$hours:$minutes:$seconds,$milliseconds';
  }

  String _formatVTTTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String threeDigits(int n) => n.toString().padLeft(3, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    String milliseconds = threeDigits(duration.inMilliseconds.remainder(1000));
    return '$hours:$minutes:$seconds.$milliseconds';
  }

  @override
  Stream<ExportJob> burnCaptions({
    required String videoPath,
    required List<SubtitleSegment> segments,
    required CaptionStyle style,
    required String outputPath,
    required Duration videoDuration,
  }) {
    final StreamController<ExportJob> controller =
        StreamController<ExportJob>();

    _executeBurn(
      videoPath: videoPath,
      segments: segments,
      style: style,
      outputPath: outputPath,
      videoDuration: videoDuration,
      controller: controller,
    );

    return controller.stream;
  }

  Future<void> _executeBurn({
    required String videoPath,
    required List<SubtitleSegment> segments,
    required CaptionStyle style,
    required String outputPath,
    required Duration videoDuration,
    required StreamController<ExportJob> controller,
  }) async {
    try {
      // 1. Generate SRT content
      final srtContent = await exportSRT(segments);

      // 2. Save SRT to temp file
      final Directory tempDir = await getTemporaryDirectory();
      final File srtFile = File('${tempDir.path}/temp_subs.srt');
      await srtFile.writeAsString(srtContent);

      // Convert path to FFmpeg friendly path (replace backward slashes for Windows)
      final String srtFilterPath = srtFile.path
          .replaceAll('\\', '/')
          .replaceAll(':', '\\\\:');

      // 3. Build styling string for FFmpeg 'force_style'
      // ASS format uses &HAABBGGRR instead of AARRGGBB, we will just pass primary color.
      // For simplicity, we just set FontSize and Alignment.
      final int alignment = _getAssAlignment(style.position);
      final String forceStyle =
          'FontSize=${style.fontSize},Alignment=$alignment';

      // 4. Construct FFmpeg command
      // -y : overwrite output
      // -i : input file
      // -vf : video filter (subtitles)
      // -c:a copy : copy audio codec
      final String command =
          "-y -i \"$videoPath\" -vf \"subtitles='$srtFilterPath':force_style='$forceStyle'\" -c:a copy \"$outputPath\"";

      // Initialize job
      final job = ExportJob(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sourceFileName: videoPath.split(Platform.pathSeparator).last,
        outputFileName: outputPath,
        state: ExportState.encoding,
        progress: 0.0,
        resolution: 'Unknown',
        codec: 'Unknown',
        bitrateMbps: 0,
        estimatedTimeRemaining: const Duration(minutes: 1), // placeholder
        outputSizeBytes: 0,
        hardwareAcceleration: true,
      );
      controller.add(job);

      // 5. Execute FFmpeg async with progress callback
      await FFmpegKit.executeAsync(
        command,
        (FFmpegSession session) async {
          final ReturnCode? returnCode = await session.getReturnCode();
          if (ReturnCode.isSuccess(returnCode)) {
            final File outputFile = File(outputPath);
            final int size = outputFile.existsSync()
                ? outputFile.lengthSync()
                : 0;
            controller.add(
              job.copyWith(
                state: ExportState.complete,
                progress: 1.0,
                outputSizeBytes: size,
                estimatedTimeRemaining: Duration.zero,
              ),
            );
          } else if (ReturnCode.isCancel(returnCode)) {
            controller.add(job.copyWith(state: ExportState.cancelled));
          } else {
            controller.add(job.copyWith(state: ExportState.error));
          }
          await srtFile.delete(); // cleanup
          controller.close();
        },
        null, // log callback
        (Statistics statistics) {
          // Progress calculation
          final timeInMilliseconds = statistics.getTime();
          if (timeInMilliseconds > 0 && videoDuration.inMilliseconds > 0) {
            double progress = timeInMilliseconds / videoDuration.inMilliseconds;
            if (progress > 1.0) progress = 1.0;

            controller.add(
              job.copyWith(
                progress: progress,
                outputSizeBytes: statistics.getSize(),
                resolution: '1080x1920', // FFmpegKit doesn't easily expose resolution here without ffprobe
              ),
            );
          }
        },
      );
    } catch (e) {
      controller.add(
        ExportJob(
          id: 'error',
          sourceFileName: videoPath,
          outputFileName: outputPath,
          state: ExportState.error,
          progress: 0.0,
          resolution: '',
          codec: '',
          bitrateMbps: 0,
          estimatedTimeRemaining: Duration.zero,
          outputSizeBytes: 0,
          hardwareAcceleration: false,
        ),
      );
      controller.close();
    }
  }

  int _getAssAlignment(SubtitlePosition position) {
    // ASS Alignment:
    // 1: Bottom Left, 2: Bottom Center, 3: Bottom Right
    // 4: Mid Left, 5: Mid Center, 6: Mid Right
    // 7: Top Left, 8: Top Center, 9: Top Right
    switch (position) {
      case SubtitlePosition.top:
        return 8; // Top Center
      case SubtitlePosition.center:
        return 5; // Mid Center
      case SubtitlePosition.bottom:
      case SubtitlePosition.custom:
        return 2; // Bottom Center
    }
  }
}
