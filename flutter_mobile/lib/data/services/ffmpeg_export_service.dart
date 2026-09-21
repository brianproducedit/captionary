import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/return_code.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/statistics.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffprobe_kit.dart';

import '../../core/async_lock.dart';
import '../../core/ass_file_writer.dart';
import '../../core/caption_export.dart';
import '../../core/performance_logger.dart';
import '../models/caption_style.dart';
import '../models/export_job.dart';
import '../models/subtitle_segment.dart';
import 'export_service.dart';

typedef FFmpegAsyncRunner = Future<void> Function(
  String command,
  void Function(FFmpegSession session) completeCallback,
  dynamic logCallback,
  void Function(Statistics statistics)? statisticsCallback,
);

typedef VideoMetadataExtractor = Future<Map<String, dynamic>?> Function(
  String videoPath,
);

typedef FontDirectoryResolver = Future<String?> Function();
typedef LogoPathResolver = Future<String?> Function();
typedef TempDirectoryResolver = Future<Directory> Function();
typedef FFmpegCancelRunner = Future<void> Function([int? sessionId]);

class FfmpegExportService implements ExportService {
  /// Concurrency lock to enforce strictly one heavy FFmpeg job at a time.
  static final AsyncLock _heavyJobLock = AsyncLock();

  /// Visible for testing whether the heavy job lock is held.
  @visibleForTesting
  static bool get isHeavyJobRunning => _heavyJobLock.isLocked;

  final FFmpegAsyncRunner? ffmpegAsyncRunner;
  final VideoMetadataExtractor? metadataExtractor;
  final FontDirectoryResolver? fontDirResolver;
  final LogoPathResolver? logoPathResolver;
  final TempDirectoryResolver? tempDirResolver;
  final FFmpegCancelRunner? cancelRunner;
  final String preferredVideoCodec;

  FFmpegSession? _activeSession;
  int? _activeSessionId;
  bool _cancelRequested = false;

  FfmpegExportService({
    this.ffmpegAsyncRunner,
    this.metadataExtractor,
    this.fontDirResolver,
    this.logoPathResolver,
    this.tempDirResolver,
    this.cancelRunner,
    this.preferredVideoCodec = 'libx264',
  });

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

  @override
  Future<void> cancel() async {
    _cancelRequested = true;
    try {
      if (cancelRunner != null) {
        await cancelRunner!(_activeSessionId);
      } else if (_activeSession != null) {
        await _activeSession!.cancel();
      } else {
        await FFmpegKit.cancel();
      }
    } catch (e) {
      debugPrint('FfmpegExportService: cancel error: $e');
    }
  }

  @override
  Stream<ExportJob> burnCaptions({
    required String videoPath,
    required List<SubtitleSegment> segments,
    required CaptionStyle style,
    required String outputPath,
    required Duration videoDuration,
    bool includeWatermark = false,
    int targetMaxResolution = 720,
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
      includeWatermark: includeWatermark,
      targetMaxResolution: targetMaxResolution,
    );

    return controller.stream;
  }

  /// Escapes a filesystem path for inclusion in FFmpeg `-vf` filter arguments.
  ///
  /// Replaces backward slashes with forward slashes, escapes colons (`:` -> `\:`),
  /// and escapes single quotes (`'` -> `\'`).
  static String escapeFilterPath(String path) {
    return path
        .replaceAll(r'\', '/')
        .replaceAll(':', r'\:')
        .replaceAll("'", r"\'");
  }

  Future<void> _executeBurn({
    required String videoPath,
    required List<SubtitleSegment> segments,
    required CaptionStyle style,
    required String outputPath,
    required Duration videoDuration,
    required StreamController<ExportJob> controller,
    bool includeWatermark = false,
    int targetMaxResolution = 720,
  }) async {
    await _heavyJobLock.acquire();
    try {
      _cancelRequested = false;
      final jobId = DateTime.now().millisecondsSinceEpoch.toString();
      final sourceName = p.basename(videoPath);

      PerformanceLogger.recordCheckpoint(
        'burn-in',
        metadata: {'phase': 'start', 'video': sourceName},
      );

      // Initial Job state
      var job = ExportJob(
        id: jobId,
        sourceFileName: sourceName,
        outputFileName: outputPath,
        state: ExportState.encoding,
        progress: 0.0,
        resolution: 'Resolving…',
        codec: preferredVideoCodec,
        bitrateMbps: 0,
        estimatedTimeRemaining: const Duration(seconds: 30),
        outputSizeBytes: 0,
        hardwareAcceleration: true,
      );

      // Guard 1: Reject identical input and output paths
      try {
        final canonicalIn = p.canonicalize(videoPath);
        final canonicalOut = p.canonicalize(outputPath);
        if (canonicalIn == canonicalOut) {
          controller.add(
            job.copyWith(
              state: ExportState.error,
              fallbackReason:
                  'Output path cannot be identical to input video path.',
            ),
          );
          controller.close();
          return;
        }
      } catch (_) {
        if (videoPath == outputPath) {
          controller.add(
            job.copyWith(
              state: ExportState.error,
              fallbackReason:
                  'Output path cannot be identical to input video path.',
            ),
          );
          controller.close();
          return;
        }
      }

      // Guard 2: Source video must exist
      if (!File(videoPath).existsSync()) {
        controller.add(
          job.copyWith(
            state: ExportState.error,
            fallbackReason: 'Source video file does not exist: $videoPath',
          ),
        );
        controller.close();
        return;
      }

      controller.add(job);

      // Resolve directories and files
      final Directory tempDir = tempDirResolver != null
          ? await tempDirResolver!()
          : await getTemporaryDirectory();

      final partOutputPath = '$outputPath.part';
      final partFile = File(partOutputPath);
      final finalOutputFile = File(outputPath);

      // Ensure destination directory exists
      try {
        final parentDir = finalOutputFile.parent;
        if (!parentDir.existsSync()) {
          parentDir.createSync(recursive: true);
        }
      } catch (_) {}

      // Clean up any stale .part file from previous failed run
      if (partFile.existsSync()) {
        try {
          partFile.deleteSync();
        } catch (_) {}
      }

      // Resolve resolution and duration from probe
      int width = 1080;
      int height = 1920;
      var resolvedDuration = videoDuration;
      String resolutionStr = '1080x1920';

      try {
        final meta = metadataExtractor != null
            ? await metadataExtractor!(videoPath)
            : await _extractMetadata(videoPath);

        if (meta != null) {
          final res = meta['resolution'] as String?;
          if (res != null && res.contains('x') && res != 'Unknown') {
            resolutionStr = res;
            final parts = res.split('x');
            width = int.tryParse(parts[0]) ?? 1080;
            height = int.tryParse(parts[1]) ?? 1920;
          }
          final dur = meta['duration'] as Duration?;
          if (dur != null && dur > Duration.zero) {
            resolvedDuration = dur;
          }
        }
      } catch (e) {
        debugPrint('FfmpegExportService: Metadata extraction failed: $e');
      }

      // Resolution constraints (e.g. 720p cap for free tier)
      int outWidth = width;
      int outHeight = height;
      if (targetMaxResolution <= 720 && (width > 720 || height > 720)) {
        if (width <= height) {
          // Portrait (vertical video, e.g. 1080x1920 -> 720x1280)
          if (width > 720) {
            outWidth = 720;
            outHeight = ((height * 720) / width).round();
            if (outHeight % 2 != 0) outHeight -= 1;
          }
        } else {
          // Landscape (horizontal video, e.g. 1920x1080 -> 1280x720)
          if (height > 720) {
            outHeight = 720;
            outWidth = ((width * 720) / height).round();
            if (outWidth % 2 != 0) outWidth -= 1;
          }
        }
        resolutionStr = '${outWidth}x$outHeight';
      }

      job = job.copyWith(resolution: resolutionStr);
      controller.add(job);

      // Prepare font directory (Lexend)
      final String? fontsDir = fontDirResolver != null
          ? await fontDirResolver!()
          : await _ensureFontExtracted(tempDir);

      // Prepare logo file if watermark requested
      final String? logoPath = includeWatermark
          ? (logoPathResolver != null
                ? await logoPathResolver!()
                : await _ensureLogoExtracted(tempDir))
          : null;
      final bool hasLogo = logoPath != null && File(logoPath).existsSync();
      final bool needsScale = outWidth != width || outHeight != height;

      // Attempt 1: ASS burn-in
      final assFile = File('${tempDir.path}/subs_$jobId.ass');
      final srtFile = File('${tempDir.path}/subs_$jobId.srt');

      try {
        final assContent = AssFileWriter.generate(
          segments: segments,
          style: style,
          playResX: outWidth,
          playResY: outHeight,
          showWatermark: includeWatermark,
          watermarkText: 'Captioned by Captionary',
          videoDuration: resolvedDuration,
        );
        await assFile.writeAsString(assContent);

        final escapedAssPath = escapeFilterPath(assFile.path);
        final baseAssFilter = fontsDir != null && fontsDir.isNotEmpty
            ? "ass='$escapedAssPath':fontsdir='${escapeFilterPath(fontsDir)}'"
            : "ass='$escapedAssPath'";

        final String command;
        if (hasLogo) {
          final scalePrefix = needsScale ? "scale=$outWidth:$outHeight," : "";
          final filterComplex =
              "[0:v]$scalePrefix$baseAssFilter[vsub];"
              "[1:v]scale=36:36:force_original_aspect_ratio=decrease,format=rgba,colorchannelmixer=aa=0.85[logo];"
              "[vsub][logo]overlay=W-w-24:24[vout]";
          command =
              "-y -i \"$videoPath\" -i \"$logoPath\" -filter_complex \"$filterComplex\" -map \"[vout]\" -map 0:a? -c:v $preferredVideoCodec -c:a copy \"$partOutputPath\"";
        } else {
          final scaleSuffix = needsScale ? ",scale=$outWidth:$outHeight" : "";
          final filterString = "$baseAssFilter$scaleSuffix";
          command =
              "-y -i \"$videoPath\" -vf \"$filterString\" -map 0:a? -c:v $preferredVideoCodec -c:a copy \"$partOutputPath\"";
        }

        final success = await _runFfmpeg(
          command: command,
          job: job,
          videoDuration: resolvedDuration,
          partFile: partFile,
          finalFile: finalOutputFile,
          controller: controller,
        );

        if (success) {
          _safeDelete(assFile);
          controller.close();
          return;
        }
      } catch (e) {
        debugPrint('FfmpegExportService: ASS burn-in attempt error: $e');
      } finally {
        _safeDelete(assFile);
      }

      if (_cancelRequested) {
        _cleanupPart(partFile);
        controller.add(job.copyWith(state: ExportState.cancelled));
        controller.close();
        return;
      }

      // Attempt 2: Fallback to SRT burn-in with force_style
      debugPrint(
        'FfmpegExportService: ASS burn-in failed; falling back to SRT burn-in with user-visible reason.',
      );
      job = job.copyWith(
        fallbackReason: 'Styled ASS filter unavailable; fell back to standard SRT captions.',
      );
      controller.add(job);

      try {
        final srtContent = CaptionExport.srt(segments);
        await srtFile.writeAsString(srtContent);

        final escapedSrtPath = escapeFilterPath(srtFile.path);
        final alignment = AssFileWriter.assAlignment(
          style.position,
          style.textAlign,
        );
        final forceStyle = 'FontSize=${style.fontSize},Alignment=$alignment';

        // Use mpeg4 fallback if preferred codec failed
        final videoCodec = preferredVideoCodec == 'libx264'
            ? 'libx264'
            : 'mpeg4';
        final String srtCommand;
        if (hasLogo) {
          final scalePrefix = needsScale ? "scale=$outWidth:$outHeight," : "";
          final filterComplex =
              "[0:v]${scalePrefix}subtitles='$escapedSrtPath':force_style='$forceStyle'[vsub];"
              "[1:v]scale=36:36:force_original_aspect_ratio=decrease,format=rgba,colorchannelmixer=aa=0.85[logo];"
              "[vsub][logo]overlay=W-w-24:24[vout]";
          srtCommand =
              "-y -i \"$videoPath\" -i \"$logoPath\" -filter_complex \"$filterComplex\" -map \"[vout]\" -map 0:a? -c:v $videoCodec -c:a copy \"$partOutputPath\"";
        } else {
          final scaleSuffix = needsScale ? ",scale=$outWidth:$outHeight" : "";
          srtCommand =
              "-y -i \"$videoPath\" -vf \"subtitles='$escapedSrtPath':force_style='$forceStyle'$scaleSuffix\" -map 0:a? -c:v $videoCodec -c:a copy \"$partOutputPath\"";
        }

        final success = await _runFfmpeg(
          command: srtCommand,
          job: job,
          videoDuration: resolvedDuration,
          partFile: partFile,
          finalFile: finalOutputFile,
          controller: controller,
        );

        if (success) {
          controller.close();
          return;
        }
      } catch (e) {
        debugPrint('FfmpegExportService: SRT fallback failed: $e');
      } finally {
        _safeDelete(srtFile);
      }

      // Both attempts failed or canceled
      _cleanupPart(partFile);
      if (_cancelRequested) {
        controller.add(job.copyWith(state: ExportState.cancelled));
      } else {
        controller.add(job.copyWith(state: ExportState.error));
      }
      controller.close();
    } finally {
      _heavyJobLock.release();
    }
  }

  Future<bool> _runFfmpeg({
    required String command,
    required ExportJob job,
    required Duration videoDuration,
    required File partFile,
    required File finalFile,
    required StreamController<ExportJob> controller,
  }) async {
    final completer = Completer<bool>();

    void onComplete(FFmpegSession session) async {
      _activeSession = null;
      _activeSessionId = null;
      final ReturnCode? returnCode = await session.getReturnCode();

      if (_cancelRequested || ReturnCode.isCancel(returnCode)) {
        _cleanupPart(partFile);
        PerformanceLogger.recordCheckpoint(
          'burn-in',
          metadata: {'phase': 'complete', 'success': false, 'cancelled': true},
        );
        completer.complete(false);
        return;
      }

      if (ReturnCode.isSuccess(returnCode) && partFile.existsSync()) {
        try {
          // Atomic rename from .part to final output
          if (finalFile.existsSync()) {
            finalFile.deleteSync();
          }
          partFile.renameSync(finalFile.path);

          final int size = finalFile.existsSync() ? finalFile.lengthSync() : 0;
          controller.add(
            job.copyWith(
              state: ExportState.complete,
              progress: 1.0,
              outputSizeBytes: size,
              estimatedTimeRemaining: Duration.zero,
            ),
          );
          PerformanceLogger.recordCheckpoint(
            'burn-in',
            metadata: {
              'phase': 'complete',
              'success': true,
              'outputBytes': size,
            },
          );
          completer.complete(true);
          return;
        } catch (e) {
          debugPrint('FfmpegExportService: Atomic rename failed: $e');
          _cleanupPart(partFile);
          PerformanceLogger.recordCheckpoint(
            'burn-in',
            metadata: {'phase': 'complete', 'success': false, 'error': '$e'},
          );
          completer.complete(false);
          return;
        }
      }

      _cleanupPart(partFile);
      PerformanceLogger.recordCheckpoint(
        'burn-in',
        metadata: {'phase': 'complete', 'success': false},
      );
      completer.complete(false);
    }

    void onStatistics(Statistics statistics) {
      final timeMs = statistics.getTime();
      if (timeMs > 0 && videoDuration.inMilliseconds > 0) {
        double progress = timeMs / videoDuration.inMilliseconds;
        if (progress > 1.0) progress = 1.0;

        final double speed = statistics.getSpeed();
        final int remainingMs = (speed > 0)
            ? ((videoDuration.inMilliseconds - timeMs) / speed).round()
            : 0;

        controller.add(
          job.copyWith(
            progress: progress,
            outputSizeBytes: statistics.getSize(),
            bitrateMbps: (statistics.getBitrate() / 1000).round(),
            estimatedTimeRemaining: Duration(
              milliseconds: remainingMs.clamp(0, 3600000),
            ),
          ),
        );
      }
    }

    try {
      if (ffmpegAsyncRunner != null) {
        await ffmpegAsyncRunner!(command, onComplete, null, onStatistics);
      } else {
        await FFmpegKit.executeAsync(
          command,
          (session) {
            _activeSession = session;
            _activeSessionId = session.getSessionId();
            onComplete(session);
          },
          null,
          onStatistics,
        );
      }
      return await completer.future;
    } catch (e) {
      debugPrint('FfmpegExportService: Execution runner threw: $e');
      _cleanupPart(partFile);
      return false;
    }
  }

  Future<String?> _ensureFontExtracted(Directory tempDir) async {
    try {
      final fontsDir = Directory('${tempDir.path}/fonts');
      if (!fontsDir.existsSync()) {
        fontsDir.createSync(recursive: true);
      }
      final fontFile = File('${fontsDir.path}/Lexend-VariableFont_wght.ttf');
      if (fontFile.existsSync() && fontFile.lengthSync() > 0) {
        return fontsDir.path;
      }

      final ByteData data = await rootBundle.load(
        'assets/fonts/Lexend-VariableFont_wght.ttf',
      );
      final List<int> bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      await fontFile.writeAsBytes(bytes, flush: true);
      return fontsDir.path;
    } catch (e) {
      debugPrint('FfmpegExportService: Could not extract font asset: $e');
      return null;
    }
  }

  Future<String?> _ensureLogoExtracted(Directory tempDir) async {
    try {
      final logoFile = File('${tempDir.path}/captionary_logo.png');
      if (logoFile.existsSync() && logoFile.lengthSync() > 0) {
        return logoFile.path;
      }

      final ByteData data = await rootBundle.load(
        'assets/images/captionary_logo.png',
      );
      final List<int> bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      await logoFile.writeAsBytes(bytes, flush: true);
      return logoFile.path;
    } catch (e) {
      debugPrint('FfmpegExportService: Could not extract logo asset: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _extractMetadata(String filePath) async {
    try {
      final session = await FFprobeKit.getMediaInformation(filePath);
      final information = session.getMediaInformation();
      if (information == null) return null;

      String resolution = 'Unknown';
      for (final stream in information.getStreams()) {
        if (stream.getType() == 'video') {
          final width = stream.getWidth();
          final height = stream.getHeight();
          if (width != null && height != null) {
            resolution = '${width}x$height';
          }
          break;
        }
      }

      final durationStr = information.getDuration();
      Duration duration = Duration.zero;
      if (durationStr != null) {
        final sec = double.tryParse(durationStr);
        if (sec != null) {
          duration = Duration(milliseconds: (sec * 1000).round());
        }
      }

      return {'resolution': resolution, 'duration': duration};
    } catch (_) {
      return null;
    }
  }

  void _cleanupPart(File partFile) {
    try {
      if (partFile.existsSync()) {
        partFile.deleteSync();
      }
    } catch (_) {}
  }

  void _safeDelete(File file) {
    try {
      if (file.existsSync()) {
        file.deleteSync();
      }
    } catch (_) {}
  }
}
