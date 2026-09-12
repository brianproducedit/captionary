import 'package:flutter/material.dart';

import '../data/models/caption_style.dart';
import '../theme/app_colors.dart';

/// Live caption sample using only the local [CaptionStyle] (no remote assets).
class CaptionStylePreview extends StatelessWidget {
  final CaptionStyle style;
  final String? text;
  final double? fontSizeOverride;
  final int maxLines;

  const CaptionStylePreview({
    super.key,
    required this.style,
    this.text,
    this.fontSizeOverride,
    this.maxLines = 3,
  });

  @override
  Widget build(BuildContext context) {
    final sample = text ?? style.previewText;
    final fontSize = fontSizeOverride ?? style.fontSize;
    final fill = TextStyle(
      fontFamily: CaptionStyle.fontFamily,
      fontSize: fontSize,
      height: style.lineHeight,
      fontWeight: FontWeight.bold,
      color: style.accentColor,
      shadows: style.shadowBlur > 0
          ? [
              Shadow(
                color: style.shadowColor.withValues(alpha: 0.85),
                blurRadius: style.shadowBlur,
              ),
            ]
          : null,
    );
    final stroke = style.outlineWidth > 0
        ? fill.copyWith(
            color: null,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = style.outlineWidth
              ..color = style.outlineColor,
          )
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: style.localTexture,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.baseCanvas.withValues(alpha: style.boxOpacity),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (stroke != null)
              Text(
                sample,
                textAlign: style.textAlign.asTextAlign,
                style: stroke,
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
              ),
            Text(
              sample,
              textAlign: style.textAlign.asTextAlign,
              style: fill,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
