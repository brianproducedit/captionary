import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:captionary/data/models/caption_style.dart';
import 'package:captionary/data/models/export_job.dart';
import 'package:captionary/data/models/subtitle_segment.dart';
import 'package:captionary/data/services/ffmpeg_export_service.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/return_code.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_session.dart';

class _FakeSession implements FFmpegSession {
  final int _id;
  final ReturnCode _code;
  _FakeSession(this._id, this._code);

  @override
  Future<ReturnCode?> getReturnCode() async => _code;

  @override
  int? getSessionId() => _id;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late File sampleVideo;
  late File sampleLogo;
  late List<SubtitleSegment> segments;
  late CaptionStyle style;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('captionary_wm_test_');
    sampleVideo = File('${tempDir.path}/input.mp4')..writeAsStringSync('dummy');
    sampleLogo = File('${tempDir.path}/captionary_logo.png')
      ..writeAsStringSync('logo_data');

    segments = [
      SubtitleSegment(
        index: 1,
        text: 'Test watermark',
        startTime: const Duration(seconds: 1),
        endTime: const Duration(seconds: 4),
        isSelected: false,
      ),
    ];

    style = CaptionStyle(
      name: 'Default',
      previewText: 'Preview',
      fontSize: 24,
      boxOpacity: 0.0,
      accentColor: const Color(0xFFFFFFFF),
      animationType: CaptionStyle.animationNone,
      targetPlatform: 'tiktok',
    );
  });

  tearDown(() {
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  test('burnCaptions enforces 720p scaling on portrait 1080x1920 video', () async {
    String? executedCommand;
    final outputPath = '${tempDir.path}/output_720p.mp4';

    final service = FfmpegExportService(
      tempDirResolver: () async => tempDir,
      fontDirResolver: () async => null,
      metadataExtractor: (path) async => {
        'resolution': '1080x1920',
        'duration': const Duration(seconds: 5),
      },
      ffmpegAsyncRunner: (cmd, onComplete, logCb, statCb) async {
        executedCommand = cmd;
        final partFile = File('$outputPath.part');
        partFile.writeAsStringSync('video content');
        onComplete(_FakeSession(1, ReturnCode(0)));
      },
    );

    final stream = service.burnCaptions(
      videoPath: sampleVideo.path,
      segments: segments,
      style: style,
      outputPath: outputPath,
      videoDuration: const Duration(seconds: 5),
      includeWatermark: false,
      targetMaxResolution: 720,
    );

    final events = await stream.toList();

    expect(executedCommand, isNotNull);
    expect(executedCommand, contains('scale=720:1280'));
    expect(events.any((e) => e.resolution == '720x1280'), isTrue);
    expect(events.last.state, ExportState.complete);
  });

  test('burnCaptions overlays logo and includes watermark when enabled', () async {
    String? executedCommand;
    final outputPath = '${tempDir.path}/output_wm.mp4';

    final service = FfmpegExportService(
      tempDirResolver: () async => tempDir,
      fontDirResolver: () async => null,
      logoPathResolver: () async => sampleLogo.path,
      metadataExtractor: (path) async => {
        'resolution': '720x1280',
        'duration': const Duration(seconds: 5),
      },
      ffmpegAsyncRunner: (cmd, onComplete, logCb, statCb) async {
        executedCommand = cmd;
        final partFile = File('$outputPath.part');
        partFile.writeAsStringSync('video content');
        onComplete(_FakeSession(1, ReturnCode(0)));
      },
    );

    final stream = service.burnCaptions(
      videoPath: sampleVideo.path,
      segments: segments,
      style: style,
      outputPath: outputPath,
      videoDuration: const Duration(seconds: 5),
      includeWatermark: true,
      targetMaxResolution: 720,
    );

    final events = await stream.toList();

    expect(executedCommand, isNotNull);
    expect(executedCommand, contains('-filter_complex'));
    expect(executedCommand, contains(sampleLogo.path));
    expect(executedCommand, contains('overlay=W-w-24:24'));
    expect(events.last.state, ExportState.complete);
  });
}
