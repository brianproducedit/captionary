import 'package:flutter_test/flutter_test.dart';
import 'package:captionary/data/models/subtitle_segment.dart';

void main() {
  group('SubtitleSegment Tests', () {
    test('should create a valid SubtitleSegment', () {
      final segment = SubtitleSegment(
        index: 1,
        startTime: const Duration(seconds: 0),
        endTime: const Duration(seconds: 2),
        text: 'Hello world',
        isSelected: false,
      );

      expect(segment.index, 1);
      expect(segment.text, 'Hello world');
      expect(segment.isSelected, false);
    });
  });
}
