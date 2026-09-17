import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/return_code.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/statistics.dart';
import 'package:captionary/data/models/caption_style.dart';
import 'package:captionary/data/models/export_job.dart';
import 'package:captionary/data/models/subtitle_segment.dart';
import 'package:captionary/data/services/ffmpeg_export_service.dart';

class FakeSession implements FFmpegSession {
  final int id;
  final ReturnCode code;

  FakeSession({required this.id, required this.code});

  @override
  int getSessionId() => id;

  @override
  Future<ReturnCode> getReturnCode() async => code;

  @override
  Future<void> cancel() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeStatistics implements Statistics {
  final int time;
  final int size;
  final double bitrate;
  final double speed;

  FakeStatistics({
    required this.time,
    required this.size,
    required this.bitrate,
    required this.speed,
  });

  @override
  int getTime() => time;

  @override
  int getSize() => size;

  @override
  double getBitrate() => bitrate;

  @override
  double getSpeed() => speed;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late File sampleVideo;
  late CaptionStyle style;
  late List<SubtitleSegment> segments;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('ffmpeg_export_test');
    sampleVideo = File('${tempDir.path}/input.mp4');
    sampleVideo.writeAsStringSync('dummy video content');

    style = CaptionStyle(
      name: 'TestStyle',
      previewText: 'Preview',
      fontSize: 24.0,
      boxOpacity: 0.5,
      accentColor: const Color(0xFFFFFFFF),
      animationType: 'none',
      targetPlatform: 'generic',
    );

    segments = [
      SubtitleSegment(
        index: 1,
        startTime: Duration.zero,
        endTime: const Duration(seconds: 5),
        text: 'Test caption',
        isSelected: false,
      ),
    ];
  });

  tearDown(() {
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  test('escapeFilterPath escapes backslashes, colons, and single quotes', () {
    expect(
      FfmpegExportService.escapeFilterPath(
        r'C:\Program Files\sub'
        "'"
        r's.ass',
      ),
      r"C\:/Program Files/sub\'s.ass",
    );
  });

  test(
    'burnCaptions rejects identical input and output paths immediately',
    () async {
      final service = FfmpegExportService(tempDirResolver: () async => tempDir);

      final stream = service.burnCaptions(
        videoPath: sampleVideo.path,
        segments: segments,
        style: style,
        outputPath: sampleVideo.path,
        videoDuration: const Duration(seconds: 10),
      );

      final events = await stream.toList();
      expect(events.last.state, ExportState.error);
      expect(events.last.fallbackReason, contains('cannot be identical'));
    },
  );

  test('burnCaptions rejects non-existent input video', () async {
    final service = FfmpegExportService(tempDirResolver: () async => tempDir);

    final stream = service.burnCaptions(
      videoPath: '${tempDir.path}/does_not_exist.mp4',
      segments: segments,
      style: style,
      outputPath: '${tempDir.path}/output.mp4',
      videoDuration: const Duration(seconds: 10),
    );

    final events = await stream.toList();
    expect(events.last.state, ExportState.error);
    expect(events.last.fallbackReason, contains('does not exist'));
  });

  test('burnCaptions completes ASS burn-in with atomic .part rename', () async {
    String? executedCommand;
    final outputPath = '${tempDir.path}/output_burned.mp4';

    final service = FfmpegExportService(
      tempDirResolver: () async => tempDir,
      fontDirResolver: () async => '${tempDir.path}/fonts',
      metadataExtractor: (path) async => {
        'resolution': '720x1280',
        'duration': const Duration(seconds: 5),
      },
      ffmpegAsyncRunner: (cmd, onComplete, logCb, statCb) async {
        executedCommand = cmd;
        // Simulate writing to .part file
        final partFile = File('$outputPath.part');
        partFile.writeAsStringSync('completed video output');

        // Simulate statistics event
        statCb?.call(
          FakeStatistics(
            time: 2500,
            size: 1048576,
            bitrate: 4000.0,
            speed: 2.0,
          ),
        );

        // Complete with success
        onComplete(FakeSession(id: 1, code: ReturnCode(0)));
      },
    );

    final stream = service.burnCaptions(
      videoPath: sampleVideo.path,
      segments: segments,
      style: style,
      outputPath: outputPath,
      videoDuration: const Duration(seconds: 5),
    );

    final events = await stream.toList();

    // Verify command construction
    expect(executedCommand, isNotNull);
    expect(executedCommand, contains('-vf "ass='));
    expect(executedCommand, contains(':fontsdir='));
    expect(executedCommand, contains('$outputPath.part"'));

    // Verify metadata was resolved
    expect(events.any((e) => e.resolution == '720x1280'), isTrue);

    // Verify atomic rename
    final finalFile = File(outputPath);
    final partFile = File('$outputPath.part');
    expect(finalFile.existsSync(), isTrue);
    expect(partFile.existsSync(), isFalse);

    // Verify final state
    expect(events.last.state, ExportState.complete);
    expect(events.last.progress, 1.0);
    expect(events.last.outputSizeBytes, greaterThan(0));
  });

  test(
    'burnCaptions falls back to SRT burn-in when ASS filter fails',
    () async {
      final commands = <String>[];
      final outputPath = '${tempDir.path}/output_fallback.mp4';

      final service = FfmpegExportService(
        tempDirResolver: () async => tempDir,
        fontDirResolver: () async => null,
        metadataExtractor: (path) async => {
          'resolution': '1080x1920',
          'duration': const Duration(seconds: 5),
        },
        ffmpegAsyncRunner: (cmd, onComplete, logCb, statCb) async {
          commands.add(cmd);
          if (cmd.contains('-vf "ass=')) {
            // ASS fails (e.g. libass filter not compiled)
            onComplete(FakeSession(id: 1, code: ReturnCode(1)));
          } else if (cmd.contains('subtitles=')) {
            // SRT succeeds
            final partFile = File('$outputPath.part');
            partFile.writeAsStringSync('fallback srt video');
            onComplete(FakeSession(id: 2, code: ReturnCode(0)));
          }
        },
      );

      final stream = service.burnCaptions(
        videoPath: sampleVideo.path,
        segments: segments,
        style: style,
        outputPath: outputPath,
        videoDuration: const Duration(seconds: 5),
      );

      final events = await stream.toList();

      // Verify two attempts were made: first ASS, then SRT
      expect(commands.length, 2);
      expect(commands[0], contains('-vf "ass='));
      expect(commands[1], contains('subtitles='));

      // Verify fallback reason is populated
      expect(
        events.any(
          (e) => e.fallbackReason != null && e.fallbackReason!.contains('SRT'),
        ),
        isTrue,
      );

      // Verify output file exists
      final finalFile = File(outputPath);
      expect(finalFile.existsSync(), isTrue);
      expect(events.last.state, ExportState.complete);
    },
  );

  test('burnCaptions handles cancellation and cleans up .part files', () async {
    final outputPath = '${tempDir.path}/output_cancelled.mp4';
    bool cancelCalled = false;
    late final FfmpegExportService service;

    service = FfmpegExportService(
      tempDirResolver: () async => tempDir,
      fontDirResolver: () async => null,
      metadataExtractor: (path) async => null,
      cancelRunner: ([id]) async {
        cancelCalled = true;
      },
      ffmpegAsyncRunner: (cmd, onComplete, logCb, statCb) async {
        // Create partial file
        final partFile = File('$outputPath.part');
        partFile.writeAsStringSync('partial data');

        // Trigger cancel via service
        await service.cancel();

        // Return code 255 represents cancelled
        onComplete(FakeSession(id: 99, code: ReturnCode(255)));
      },
    );

    final stream = service.burnCaptions(
      videoPath: sampleVideo.path,
      segments: segments,
      style: style,
      outputPath: outputPath,
      videoDuration: const Duration(seconds: 10),
    );

    final events = await stream.toList();

    expect(cancelCalled, isTrue);
    expect(events.last.state, ExportState.cancelled);

    // Verify .part file was deleted
    final partFile = File('$outputPath.part');
    final finalFile = File(outputPath);
    expect(partFile.existsSync(), isFalse);
    expect(finalFile.existsSync(), isFalse);
  });

  test('enforces single heavy job concurrency lock during burnCaptions', () async {
    final outputPath1 = '${tempDir.path}/out1.mp4';
    final outputPath2 = '${tempDir.path}/out2.mp4';
    int runningJobs = 0;
    int maxConcurrentJobs = 0;

    final service = FfmpegExportService(
      tempDirResolver: () async => tempDir,
      fontDirResolver: () async => tempDir.path,
      metadataExtractor: (path) async => {
        'resolution': '1080x1920',
        'duration': const Duration(seconds: 5),
      },
      ffmpegAsyncRunner: (cmd, onComplete, logCb, statCb) async {
        runningJobs++;
        if (runningJobs > maxConcurrentJobs) {
          maxConcurrentJobs = runningJobs;
        }
        await Future.delayed(const Duration(milliseconds: 30));
        runningJobs--;
        onComplete(FakeSession(id: 1, code: ReturnCode(0)));
      },
    );

    final stream1 = service.burnCaptions(
      videoPath: sampleVideo.path,
      segments: segments,
      style: style,
      outputPath: outputPath1,
      videoDuration: const Duration(seconds: 5),
    );
    final stream2 = service.burnCaptions(
      videoPath: sampleVideo.path,
      segments: segments,
      style: style,
      outputPath: outputPath2,
      videoDuration: const Duration(seconds: 5),
    );

    await Future.wait([stream1.toList(), stream2.toList()]);

    expect(maxConcurrentJobs, 1);
    expect(FfmpegExportService.isHeavyJobRunning, isFalse);
  });
}
