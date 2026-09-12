import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:captionary/core/caption_export.dart';
import 'package:captionary/core/subtitle_file_store.dart';
import 'package:captionary/data/models/subtitle_segment.dart';

void main() {
  final segments = [
    SubtitleSegment(
      index: 1,
      startTime: Duration.zero,
      endTime: const Duration(seconds: 1, milliseconds: 500),
      text: 'Hello there',
      isSelected: false,
    ),
  ];

  test('blockReason covers empty and inverted times', () {
    expect(CaptionExport.blockReason([]), contains('at least one caption'));
    expect(
      CaptionExport.blockReason([
        SubtitleSegment(
          index: 3,
          startTime: const Duration(seconds: 2),
          endTime: const Duration(seconds: 1),
          text: 'x',
          isSelected: false,
        ),
      ]),
      contains('inverted times'),
    );
    expect(CaptionExport.blockReason(segments), isNull);
  });

  test('srt and vtt encode cue times', () {
    final srt = CaptionExport.srt(segments);
    expect(srt, contains('1\n00:00:00,000 --> 00:00:01,500\nHello there'));
    final vtt = CaptionExport.vtt(segments);
    expect(vtt, startsWith('WEBVTT'));
    expect(vtt, contains('00:00:00.000 --> 00:00:01.500'));
  });

  test('ASS is not available', () {
    expect(CaptionExportFormat.ass.isAvailable, isFalse);
    expect(
      () => CaptionExport.encode(segments, CaptionExportFormat.ass),
      throwsUnsupportedError,
    );
  });

  test('SubtitleFileStore writes named content', () async {
    final dir = Directory.systemTemp.createTempSync('captionary_export');
    addTearDown(() => dir.deleteSync(recursive: true));
    final store = SubtitleFileStore(directory: dir);
    final file = await store.write(fileName: 'captions.vtt', content: 'WEBVTT\n');
    expect(file.existsSync(), isTrue);
    expect(file.readAsStringSync(), 'WEBVTT\n');
  });
}
