import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:captionary/core/ass_file_writer.dart';
import 'package:captionary/data/models/caption_style.dart';
import 'package:captionary/data/models/subtitle_segment.dart';

void main() {
  group('AssFileWriter Watermark Tests', () {
    final style = CaptionStyle(
      name: 'Default',
      previewText: 'Preview',
      fontSize: 24,
      boxOpacity: 0.0,
      accentColor: const Color(0xFFFFFFFF),
      animationType: CaptionStyle.animationNone,
      targetPlatform: 'tiktok',
    );
    final segments = [
      SubtitleSegment(
        index: 1,
        text: 'Welcome to Captionary',
        startTime: const Duration(seconds: 1),
        endTime: const Duration(seconds: 3),
        isSelected: false,
      ),
    ];

    test('Omits watermark when showWatermark is false', () {
      final ass = AssFileWriter.generate(
        segments: segments,
        style: style,
        showWatermark: false,
      );

      expect(ass.contains('Style: Watermark'), isFalse);
      expect(ass.contains('Captioned by Captionary'), isFalse);
    });

    test('Includes watermark style and dialogue when showWatermark is true', () {
      final ass = AssFileWriter.generate(
        segments: segments,
        style: style,
        showWatermark: true,
        watermarkText: 'Captioned by Captionary',
        videoDuration: const Duration(seconds: 10),
      );

      expect(ass.contains('Style: Watermark'), isTrue);
      expect(ass.contains('Captioned by Captionary'), isTrue);
      expect(
        ass.contains(
          'Dialogue: 1,0:00:00.00,0:00:10.00,Watermark,,0,0,0,,Captioned by Captionary',
        ),
        isTrue,
      );
    });
  });
}
