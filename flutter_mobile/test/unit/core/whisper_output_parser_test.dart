import 'package:flutter_test/flutter_test.dart';
import 'package:whisper_flutter_new/whisper_flutter_new.dart';
import 'package:captionary/core/whisper_output_parser.dart';
import 'package:captionary/data/models/subtitle_segment.dart';

void main() {
  group('WhisperOutputParser', () {
    test('parseSegments converts WhisperTranscribeSegments with offset and clamping', () {
      final rawSegments = [
        WhisperTranscribeSegment(
          fromTs: const Duration(seconds: 1),
          toTs: const Duration(seconds: 4),
          text: 'Hello world',
        ),
        WhisperTranscribeSegment(
          fromTs: const Duration(seconds: 5),
          toTs: const Duration(seconds: 8),
          text: 'This is Whisper',
        ),
      ];

      final results = WhisperOutputParser.parseSegments(
        rawSegments,
        timeOffset: const Duration(seconds: 28),
        startIndex: 5,
      );

      expect(results.length, 2);
      expect(results[0].index, 5);
      expect(results[0].startTime, const Duration(seconds: 29));
      expect(results[0].endTime, const Duration(seconds: 32));
      expect(results[0].text, 'Hello world');

      expect(results[1].index, 6);
      expect(results[1].startTime, const Duration(seconds: 33));
      expect(results[1].endTime, const Duration(seconds: 36));
      expect(results[1].text, 'This is Whisper');
    });

    test('parseSegments handles zero and negative duration by clamping', () {
      final rawSegments = [
        WhisperTranscribeSegment(
          fromTs: const Duration(seconds: 5),
          toTs: const Duration(seconds: 3), // invalid: toTs < fromTs
          text: 'Clamped segment',
        ),
      ];

      final results = WhisperOutputParser.parseSegments(rawSegments);
      expect(results.length, 1);
      expect(results[0].startTime, const Duration(seconds: 5));
      expect(results[0].endTime, const Duration(milliseconds: 5500)); // +500ms
    });

    test(
      'parseRawText parses standard MM:SS.mmm and HH:MM:SS.mmm timestamps',
      () {
        const raw = '''
[00:01.000 --> 00:04.500] First segment here
[00:05.200 --> 00:09.100] Second segment here
[01:00:02.000 --> 01:00:05.000] One hour later segment
''';

        final results = WhisperOutputParser.parseRawText(raw);

        expect(results.length, 3);
        expect(results[0].startTime, const Duration(seconds: 1));
        expect(results[0].endTime, const Duration(milliseconds: 4500));
        expect(results[0].text, 'First segment here');

        expect(results[1].startTime, const Duration(milliseconds: 5200));
        expect(results[1].endTime, const Duration(milliseconds: 9100));
        expect(results[1].text, 'Second segment here');

        expect(results[2].startTime, const Duration(hours: 1, seconds: 2));
        expect(results[2].endTime, const Duration(hours: 1, seconds: 5));
        expect(results[2].text, 'One hour later segment');
      },
    );

    test(
      'parseRawText falls back to single segment when text has no timestamps',
      () {
        const raw = 'Just raw transcribed words without any timestamps';

        final results = WhisperOutputParser.parseRawText(
          raw,
          timeOffset: const Duration(seconds: 10),
          fallbackDuration: const Duration(seconds: 5),
        );

        expect(results.length, 1);
        expect(results[0].startTime, const Duration(seconds: 10));
        expect(results[0].endTime, const Duration(seconds: 15));
        expect(results[0].text, raw);
      },
    );

    test(
      'mergeSegments deduplicates identical words at chunk overlap boundary',
      () {
        final segments = [
          SubtitleSegment(
            index: 0,
            startTime: const Duration(seconds: 25),
            endTime: const Duration(seconds: 29),
            text: 'Overlapping phrase',
            isSelected: false,
          ),
          // Overlap from next chunk:
          SubtitleSegment(
            index: 1,
            startTime: const Duration(seconds: 26),
            endTime: const Duration(seconds: 30),
            text: 'overlapping phrase',
            isSelected: false,
          ),
          SubtitleSegment(
            index: 2,
            startTime: const Duration(seconds: 31),
            endTime: const Duration(seconds: 35),
            text: 'Next distinct segment',
            isSelected: false,
          ),
        ];

        final merged = WhisperOutputParser.mergeSegments(segments);

        expect(merged.length, 2);
        expect(merged[0].index, 0);
        expect(merged[0].text, 'Overlapping phrase');
        expect(merged[0].endTime, const Duration(seconds: 30)); // expanded

        expect(merged[1].index, 1);
        expect(merged[1].text, 'Next distinct segment');
      },
    );

    test('mergeSegments clamps overlapping timestamps monotonically', () {
      final segments = [
        SubtitleSegment(
          index: 0,
          startTime: const Duration(seconds: 0),
          endTime: const Duration(seconds: 5),
          text: 'First',
          isSelected: false,
        ),
        SubtitleSegment(
          index: 1,
          startTime: const Duration(seconds: 4), // starts before prev ends
          endTime: const Duration(seconds: 8),
          text: 'Second',
          isSelected: false,
        ),
      ];

      final merged = WhisperOutputParser.mergeSegments(segments);

      expect(merged.length, 2);
      expect(
        merged[0].endTime,
        const Duration(seconds: 4),
      ); // clamped to current.startTime
      expect(merged[1].startTime, const Duration(seconds: 4));
      expect(merged[1].endTime, const Duration(seconds: 8));
    });
  });
}
