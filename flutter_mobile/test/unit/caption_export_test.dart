import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:captionary/core/ass_file_writer.dart';
import 'package:captionary/core/caption_export.dart';
import 'package:captionary/core/subtitle_file_store.dart';
import 'package:captionary/data/models/caption_style.dart';
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

  final unicodeSegments = [
    SubtitleSegment(
      index: 1,
      startTime: const Duration(seconds: 1),
      endTime: const Duration(seconds: 3, milliseconds: 250),
      text: 'Mhoroi mose, ndinofara kuva pano 🇿🇼',
      isSelected: false,
    ),
    SubtitleSegment(
      index: 2,
      startTime: const Duration(seconds: 3),
      endTime: const Duration(seconds: 5),
      text: 'Èdè Yorùbá pẹ̀lú àmì ohùn: {bold} & \\backslash\\',
      isSelected: false,
    ),
  ];

  test('blockReason covers empty, whitespace, and inverted times', () {
    expect(CaptionExport.blockReason([]), contains('at least one caption'));
    expect(
      CaptionExport.blockReason([
        SubtitleSegment(
          index: 1,
          startTime: const Duration(seconds: 5),
          endTime: const Duration(seconds: 2),
          text: 'Valid',
          isSelected: false,
        ),
      ]),
      contains('inverted times'),
    );
    expect(
      CaptionExport.blockReason([
        SubtitleSegment(
          index: 2,
          startTime: const Duration(seconds: 1),
          endTime: const Duration(seconds: 3),
          text: '   ',
          isSelected: false,
        ),
      ]),
      contains('empty text'),
    );
    expect(CaptionExport.blockReason(segments), isNull);
  });

  test('srt and vtt encode cue times with Unicode text', () {
    final srt = CaptionExport.srt(unicodeSegments);
    expect(srt, contains('1\n00:00:01,000 --> 00:00:03,250\nMhoroi mose, ndinofara kuva pano 🇿🇼'));
    expect(srt, contains('2\n00:00:03,000 --> 00:00:05,000\nÈdè Yorùbá'));

    final vtt = CaptionExport.vtt(unicodeSegments);
    expect(vtt, startsWith('WEBVTT'));
    expect(vtt, contains('00:00:01.000 --> 00:00:03.250'));
    expect(vtt, contains('Mhoroi mose, ndinofara kuva pano 🇿🇼'));
  });

  test('ASS export is available and encodes valid ASS v4.00+ content', () {
    expect(CaptionExportFormat.ass.isAvailable, isTrue);

    final style = CaptionStyle(
      name: 'TestStyle',
      previewText: 'Preview',
      fontSize: 28.0,
      boxOpacity: 0.8,
      accentColor: const Color(0xFF00FF00), // Pure green
      outlineWidth: 2.0,
      outlineColor: const Color(0xFF000000), // Black
      shadowBlur: 4.0,
      shadowColor: const Color(0xFF333333),
      animationType: CaptionStyle.animationNone,
      targetPlatform: 'tiktok',
      position: SubtitlePosition.bottom,
      textAlign: CaptionTextAlign.center,
    );

    final assContent = CaptionExport.ass(
      unicodeSegments,
      style: style,
      playResX: 1080,
      playResY: 1920,
    );

    // Verify sections
    expect(assContent, contains('[Script Info]'));
    expect(assContent, contains('PlayResX: 1080'));
    expect(assContent, contains('PlayResY: 1920'));
    expect(assContent, contains('[V4+ Styles]'));
    expect(assContent, contains('Style: Default,Lexend,28,'));
    expect(assContent, contains('[Events]'));

    // Verify ASS color formatting &HAABBGGRR:
    // Green (0xFF00FF00): alpha 00 (opaque), blue 00, green FF, red 00 -> &H0000FF00
    expect(assContent, contains('&H0000FF00'));

    // Verify timestamps in centiseconds H:MM:SS.cc
    expect(assContent, contains('0:00:01.00,0:00:03.25,Default,,0,0,0,,'));
    expect(assContent, contains('0:00:03.00,0:00:05.00,Default,,0,0,0,,'));

    // Verify special character escaping: { -> ｛ and } -> ｝, \ -> ＼
    expect(assContent, contains('｛bold｝'));
    expect(assContent, contains('＼backslash＼'));
    expect(assContent, isNot(contains('{bold}')));

    // Verify Unicode preserves Shona & Yoruba with accents and flags
    expect(assContent, contains('Mhoroi mose, ndinofara kuva pano 🇿🇼'));
    expect(assContent, contains('Èdè Yorùbá pẹ̀lú àmì ohùn'));
  });

  test('ASS color conversion correctly inverts alpha and orders BGR', () {
    // Fully opaque white -> &H00FFFFFF
    expect(AssFileWriter.colorToAss(const Color(0xFFFFFFFF)), '&H00FFFFFF');
    // Fully opaque black -> &H00000000
    expect(AssFileWriter.colorToAss(const Color(0xFF000000)), '&H00000000');
    // Fully opaque red -> &H000000FF (Blue=00, Green=00, Red=FF)
    expect(AssFileWriter.colorToAss(const Color(0xFFFF0000)), '&H000000FF');
    // Fully opaque blue -> &H00FF0000 (Blue=FF, Green=00, Red=00)
    expect(AssFileWriter.colorToAss(const Color(0xFF0000FF)), '&H00FF0000');
    // 50% opacity green
    final halfGreen = AssFileWriter.colorToAss(const Color(0x8000FF00));
    expect(halfGreen.startsWith('&H7F') || halfGreen.startsWith('&H80'), isTrue);
    expect(halfGreen.endsWith('00FF00'), isTrue);
  });

  test('ASS alignment maps correctly for all positions and text alignments', () {
    expect(
      AssFileWriter.assAlignment(SubtitlePosition.top, CaptionTextAlign.left),
      7,
    );
    expect(
      AssFileWriter.assAlignment(SubtitlePosition.top, CaptionTextAlign.center),
      8,
    );
    expect(
      AssFileWriter.assAlignment(SubtitlePosition.top, CaptionTextAlign.right),
      9,
    );

    expect(
      AssFileWriter.assAlignment(SubtitlePosition.center, CaptionTextAlign.left),
      4,
    );
    expect(
      AssFileWriter.assAlignment(SubtitlePosition.center, CaptionTextAlign.center),
      5,
    );
    expect(
      AssFileWriter.assAlignment(SubtitlePosition.center, CaptionTextAlign.right),
      6,
    );

    expect(
      AssFileWriter.assAlignment(SubtitlePosition.bottom, CaptionTextAlign.left),
      1,
    );
    expect(
      AssFileWriter.assAlignment(SubtitlePosition.bottom, CaptionTextAlign.center),
      2,
    );
    expect(
      AssFileWriter.assAlignment(SubtitlePosition.bottom, CaptionTextAlign.right),
      3,
    );
  });

  test('CaptionExport.encode routes to srt, vtt, and ass properly', () {
    final srt = CaptionExport.encode(segments, CaptionExportFormat.srt);
    expect(srt, contains('-->'));
    final vtt = CaptionExport.encode(segments, CaptionExportFormat.vtt);
    expect(vtt, startsWith('WEBVTT'));
    final ass = CaptionExport.encode(segments, CaptionExportFormat.ass);
    expect(ass, contains('[Script Info]'));
  });

  test('ASS handles overlapping intervals and newlines properly', () {
    final overlapping = [
      SubtitleSegment(
        index: 1,
        startTime: const Duration(seconds: 1),
        endTime: const Duration(seconds: 4),
        text: 'First line\nSecond line',
        isSelected: false,
      ),
      SubtitleSegment(
        index: 2,
        startTime: const Duration(seconds: 2),
        endTime: const Duration(seconds: 5),
        text: 'Overlapping speaker',
        isSelected: false,
      ),
    ];

    final ass = CaptionExport.ass(overlapping);
    expect(ass, contains(r'First line\NSecond line'));
    expect(ass, contains('0:00:01.00,0:00:04.00,Default,,0,0,0,,First line\\NSecond line'));
    expect(ass, contains('0:00:02.00,0:00:05.00,Default,,0,0,0,,Overlapping speaker'));
  });

  test('SubtitleFileStore writes named content', () async {
    final dir = Directory.systemTemp.createTempSync('captionary_export');
    addTearDown(() => dir.deleteSync(recursive: true));
    final store = SubtitleFileStore(directory: dir);
    final file = await store.write(
      fileName: 'captions.ass',
      content: '[Script Info]\n',
    );
    expect(file.existsSync(), isTrue);
    expect(file.readAsStringSync(), '[Script Info]\n');
  });
}
