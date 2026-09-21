import 'dart:ui';

import '../data/models/caption_style.dart';
import '../data/models/subtitle_segment.dart';

/// Pure generator for Advanced SubStation Alpha (.ass v4.00+) subtitles.
class AssFileWriter {
  /// Converts a Flutter [Color] to ASS `&HAABBGGRR` format.
  ///
  /// In ASS v4+, alpha is inverted: `00` represents fully opaque and `FF` represents
  /// fully transparent. The color channels are ordered Blue, Green, Red.
  static String colorToAss(Color color, {double? opacityOverride}) {
    final double effectiveOpacity = (opacityOverride != null)
        ? (color.a * opacityOverride).clamp(0.0, 1.0)
        : color.a;
    final int alphaAss = ((1.0 - effectiveOpacity) * 255.0).round().clamp(
      0,
      255,
    );
    final int red = (color.r * 255.0).round().clamp(0, 255);
    final int green = (color.g * 255.0).round().clamp(0, 255);
    final int blue = (color.b * 255.0).round().clamp(0, 255);

    final String aa = alphaAss.toRadixString(16).padLeft(2, '0').toUpperCase();
    final String bb = blue.toRadixString(16).padLeft(2, '0').toUpperCase();
    final String gg = green.toRadixString(16).padLeft(2, '0').toUpperCase();
    final String rr = red.toRadixString(16).padLeft(2, '0').toUpperCase();

    return '&H$aa$bb$gg$rr';
  }

  /// Calculates ASS alignment number (1 to 9) based on position and text alignment.
  ///
  /// Numpad coordinates:
  /// 7: Top Left,    8: Top Center,    9: Top Right
  /// 4: Mid Left,    5: Mid Center,    6: Mid Right
  /// 1: Bottom Left, 2: Bottom Center, 3: Bottom Right
  static int assAlignment(
    SubtitlePosition position,
    CaptionTextAlign textAlign,
  ) {
    switch (position) {
      case SubtitlePosition.top:
        switch (textAlign) {
          case CaptionTextAlign.left:
            return 7;
          case CaptionTextAlign.center:
            return 8;
          case CaptionTextAlign.right:
            return 9;
        }
      case SubtitlePosition.center:
        switch (textAlign) {
          case CaptionTextAlign.left:
            return 4;
          case CaptionTextAlign.center:
            return 5;
          case CaptionTextAlign.right:
            return 6;
        }
      case SubtitlePosition.bottom:
      case SubtitlePosition.custom:
        switch (textAlign) {
          case CaptionTextAlign.left:
            return 1;
          case CaptionTextAlign.center:
            return 2;
          case CaptionTextAlign.right:
            return 3;
        }
    }
  }

  /// Formats a [Duration] into ASS timestamp format: `H:MM:SS.cc` (centiseconds).
  static String formatAssTime(Duration duration) {
    final int hours = duration.inHours;
    final String minutes = duration.inMinutes
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    final String seconds = duration.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    final String centis = (duration.inMilliseconds.remainder(1000) ~/ 10)
        .toString()
        .padLeft(2, '0');
    return '$hours:$minutes:$seconds.$centis';
  }

  /// Escapes ASS special characters in dialogue text to prevent style tag injection
  /// and ensure proper line wrapping.
  static String escapeText(String text) {
    var escaped = text
        .replaceAll('{', '｛')
        .replaceAll('}', '｝')
        .replaceAll(r'\', '＼');
    // Convert newlines to ASS line break
    escaped = escaped
        .replaceAll('\r\n', r'\N')
        .replaceAll('\n', r'\N')
        .replaceAll('\r', r'\N');
    return escaped;
  }

  /// Generates the complete ASS file content.
  static String generate({
    required List<SubtitleSegment> segments,
    required CaptionStyle style,
    int playResX = 1080,
    int playResY = 1920,
    String scriptTitle = 'Captionary Subtitles',
    bool showWatermark = false,
    String watermarkText = 'Captioned by Captionary',
    Duration? videoDuration,
  }) {
    final buffer = StringBuffer();

    // 1. Script Info
    buffer.writeln('[Script Info]');
    buffer.writeln('Title: $scriptTitle');
    buffer.writeln('ScriptType: v4.00+');
    buffer.writeln('WrapStyle: 0');
    buffer.writeln('ScaledBorderAndShadow: yes');
    buffer.writeln('PlayResX: $playResX');
    buffer.writeln('PlayResY: $playResY');
    buffer.writeln();

    // 2. V4+ Styles
    buffer.writeln('[V4+ Styles]');
    buffer.writeln(
      'Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, '
      'OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, '
      'ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, '
      'Alignment, MarginL, MarginR, MarginV, Encoding',
    );

    // Compute style attributes
    final String primaryColour = colorToAss(style.accentColor);
    final String secondaryColour = '&H000000FF'; // default red placeholder
    final String outlineColour = colorToAss(style.outlineColor);

    // BackColour: shadow color or background box color
    final String backColour = style.boxOpacity > 0
        ? colorToAss(style.shadowColor, opacityOverride: style.boxOpacity)
        : colorToAss(style.shadowColor);

    // BorderStyle: 1 = outline + drop shadow; 3 = opaque bounding box
    final int borderStyle = style.boxOpacity >= 0.4 ? 3 : 1;
    final double outline = style.outlineWidth > 0
        ? style.outlineWidth
        : (borderStyle == 3 ? 2.0 : 1.0);
    final double shadow = style.shadowBlur > 0 ? (style.shadowBlur / 2.0) : 0.0;
    final int alignment = assAlignment(style.position, style.textAlign);

    final int marginL = (playResX * 0.05).round().clamp(20, 100);
    final int marginR = marginL;
    final int marginV = style.position == SubtitlePosition.bottom
        ? (playResY * 0.035).round().clamp(20, 80)
        : (playResY * 0.05).round().clamp(30, 150);

    // Style line
    buffer.writeln(
      'Style: Default,Lexend,${style.fontSize.toInt()},'
      '$primaryColour,$secondaryColour,$outlineColour,$backColour,'
      '1,0,0,0,100,100,0,0,$borderStyle,$outline,$shadow,'
      '$alignment,$marginL,$marginR,$marginV,1',
    );

    if (showWatermark) {
      final int wmFontSize = (playResY * 0.022).round().clamp(16, 28);
      final int wmMarginR = (playResX * 0.035).round().clamp(24, 76);
      final int wmMarginV = (playResY * 0.025).round().clamp(24, 48);
      buffer.writeln(
        'Style: Watermark,Lexend,$wmFontSize,'
        '&H40FFFFFF,&H000000FF,&H40000000,&H80000000,'
        '1,0,0,0,100,100,0,0,1,1.5,0.8,'
        '9,24,$wmMarginR,$wmMarginV,1',
      );
    }
    buffer.writeln();

    // 3. Events
    buffer.writeln('[Events]');
    buffer.writeln(
      'Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text',
    );

    // Sort segments monotonically by startTime
    final sorted = List<SubtitleSegment>.from(segments)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    if (showWatermark) {
      final Duration watermarkEnd =
          videoDuration ??
          (sorted.isNotEmpty
              ? sorted.last.endTime + const Duration(seconds: 5)
              : const Duration(hours: 1));
      final String endStr = formatAssTime(watermarkEnd);
      final String safeWatermark = escapeText(watermarkText);
      buffer.writeln(
        'Dialogue: 1,0:00:00.00,$endStr,Watermark,,0,0,0,,$safeWatermark',
      );
    }

    for (final seg in sorted) {
      if (seg.startTime >= seg.endTime) continue;
      final startStr = formatAssTime(seg.startTime);
      final endStr = formatAssTime(seg.endTime);
      final text = escapeText(seg.text.trim());
      if (text.isEmpty) continue;

      if (style.position == SubtitlePosition.custom) {
        final posX = (playResX / 2.0).round();
        final posY = ((playResY * (style.customY + 1.0)) / 2.0)
            .round()
            .clamp(40, playResY - 40);
        buffer.writeln(
          'Dialogue: 0,$startStr,$endStr,Default,,0,0,0,,{\\pos($posX,$posY)}$text',
        );
      } else {
        buffer.writeln('Dialogue: 0,$startStr,$endStr,Default,,0,0,0,,$text');
      }
    }

    return buffer.toString();
  }
}
