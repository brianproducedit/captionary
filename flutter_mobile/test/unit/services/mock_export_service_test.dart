import 'package:flutter_test/flutter_test.dart';
import 'package:captionary/data/mock/mock_export_service.dart';
import 'package:captionary/data/models/caption_style.dart';
import 'package:captionary/data/models/export_job.dart';
import 'package:flutter/material.dart';

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
      final res = await service.exportSRT([]);
      expect(res.contains('1'), true);
      expect(res.contains('00:00:00,000'), true);
    });

    test('exportVTT generates VTT string', () async {
      final res = await service.exportVTT([]);
      expect(res.contains('WEBVTT'), true);
    });
  });
}
