import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:captionary/data/mock/mock_export_service.dart';
import 'package:captionary/data/models/caption_style.dart';
import 'package:captionary/data/models/export_job.dart';
import 'package:captionary/data/models/subtitle_segment.dart';

void main() {
  group('MockExportService Tests', () {
    late MockExportService service;

    setUp(() {
      service = MockExportService();
    });

    test('burnCaptions streams export progress', () async {
      final style = CaptionStyle(
        name: 'Style1',
        previewText: 'Preview',
        fontSize: 24.0,
        boxOpacity: 0.5,
        accentColor: Colors.red,
        animationType: 'bounce',
        targetPlatform: 'generic',
      );
      final stream = service.burnCaptions(
        videoPath: 'test_path.mp4',
        segments: [],
        style: style,
        outputPath: 'out.mp4',
        videoDuration: const Duration(minutes: 1),
      );
      final events = await stream.toList();
      expect(events.isNotEmpty, true);
      expect(events.last.state, ExportState.complete);
      expect(events.last.progress, 1.0);
    });

    test('exportSRT generates SRT string', () async {
      final res = await service.exportSRT([
        SubtitleSegment(
          index: 1,
          startTime: Duration.zero,
          endTime: const Duration(seconds: 3),
          text: 'Mhoroi mose, ndinofara kuva pano',
          isSelected: false,
        ),
      ]);
      expect(res.contains('1'), true);
      expect(res.contains('00:00:00,000'), true);
    });

    test('exportVTT generates VTT string', () async {
      final res = await service.exportVTT([]);
      expect(res.contains('WEBVTT'), true);
    });

    test(
      'exportASS generates ASS string with styles and script info',
      () async {
        final res = await service.exportASS([
          SubtitleSegment(
            index: 1,
            startTime: Duration.zero,
            endTime: const Duration(seconds: 2),
            text: 'ASS subtitle line',
            isSelected: false,
          ),
        ]);
        expect(res.contains('[Script Info]'), true);
        expect(res.contains('[V4+ Styles]'), true);
        expect(res.contains('ASS subtitle line'), true);
      },
    );

    test('cancel sets cancelled state on burnCaptions stream', () async {
      final style = CaptionStyle(
        name: 'Style1',
        previewText: 'Preview',
        fontSize: 24.0,
        boxOpacity: 0.5,
        accentColor: Colors.red,
        animationType: 'bounce',
        targetPlatform: 'generic',
      );
      final stream = service.burnCaptions(
        videoPath: 'test_path.mp4',
        segments: [],
        style: style,
        outputPath: 'out.mp4',
        videoDuration: const Duration(minutes: 1),
      );

      // Cancel after first event
      final events = <ExportJob>[];
      await for (final event in stream) {
        events.add(event);
        if (events.length == 2) {
          await service.cancel();
        }
      }

      expect(events.last.state, ExportState.cancelled);
    });
  });
}
