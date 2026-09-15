import 'dart:ui';

import 'ass_file_writer.dart';
import '../data/models/caption_style.dart';
import '../data/models/subtitle_segment.dart';

enum CaptionExportFormat { srt, vtt, ass }

extension CaptionExportFormatX on CaptionExportFormat {
  bool get isAvailable => true;

  String get label {
    switch (this) {
      case CaptionExportFormat.srt:
        return 'SRT';
      case CaptionExportFormat.vtt:
        return 'VTT';
      case CaptionExportFormat.ass:
        return 'ASS';
    }
  }

  String get fileExtension {
    switch (this) {
      case CaptionExportFormat.srt:
        return 'srt';
      case CaptionExportFormat.vtt:
        return 'vtt';
      case CaptionExportFormat.ass:
        return 'ass';
    }
  }

  String get mimeType {
    switch (this) {
      case CaptionExportFormat.srt:
        return 'application/x-subrip';
      case CaptionExportFormat.vtt:
        return 'text/vtt';
      case CaptionExportFormat.ass:
        return 'text/x-ssa';
    }
  }
}

/// Caption file contents and export pre-flight checks.
class CaptionExport {
  static String? blockReason(List<SubtitleSegment> segments) {
    if (segments.isEmpty) {
      return 'Add at least one caption before exporting.';
    }
    for (final segment in segments) {
      if (segment.startTime >= segment.endTime) {
        return 'Segment ${segment.index} has inverted times.';
      }
      if (segment.text.trim().isEmpty) {
        return 'Segment ${segment.index} has empty text.';
      }
    }
    return null;
  }

  static String srt(List<SubtitleSegment> segments) {
    final buffer = StringBuffer();
    for (var i = 0; i < segments.length; i++) {
      final seg = segments[i];
      buffer.writeln('${i + 1}');
      buffer.writeln(
        '${_formatSrt(seg.startTime)} --> ${_formatSrt(seg.endTime)}',
      );
      buffer.writeln(seg.text);
      buffer.writeln();
    }
    return buffer.toString();
  }

  static String vtt(List<SubtitleSegment> segments) {
    final buffer = StringBuffer();
    buffer.writeln('WEBVTT');
    buffer.writeln();
    for (final seg in segments) {
      buffer.writeln(
        '${_formatVtt(seg.startTime)} --> ${_formatVtt(seg.endTime)}',
      );
      buffer.writeln(seg.text);
      buffer.writeln();
    }
    return buffer.toString();
  }

  static String ass(
    List<SubtitleSegment> segments, {
    CaptionStyle? style,
    int playResX = 1080,
    int playResY = 1920,
  }) {
    final fallbackStyle =
        style ??
        CaptionStyle(
          name: 'Default',
          previewText: 'Default',
          fontSize: 24.0,
          boxOpacity: 0.0,
          accentColor: const Color(0xFFFFFFFF),
          animationType: CaptionStyle.animationNone,
          targetPlatform: 'generic',
        );

    return AssFileWriter.generate(
      segments: segments,
      style: fallbackStyle,
      playResX: playResX,
      playResY: playResY,
    );
  }

  static String encode(
    List<SubtitleSegment> segments,
    CaptionExportFormat format, {
    CaptionStyle? style,
  }) {
    switch (format) {
      case CaptionExportFormat.srt:
        return srt(segments);
      case CaptionExportFormat.vtt:
        return vtt(segments);
      case CaptionExportFormat.ass:
        return ass(segments, style: style);
    }
  }

  static String _formatSrt(Duration duration) {
    return '${_hms(duration)},${_millis(duration)}';
  }

  static String _formatVtt(Duration duration) {
    return '${_hms(duration)}.${_millis(duration)}';
  }

  static String _hms(Duration duration) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(duration.inHours)}:${two(duration.inMinutes.remainder(60))}:${two(duration.inSeconds.remainder(60))}';
  }

  static String _millis(Duration duration) {
    return duration.inMilliseconds.remainder(1000).toString().padLeft(3, '0');
  }
}
