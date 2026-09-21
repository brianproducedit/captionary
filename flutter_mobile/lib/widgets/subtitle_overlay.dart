import 'package:flutter/material.dart';

import '../data/models/subtitle_segment.dart';
import '../data/models/caption_style.dart';
import '../theme/app_colors.dart';

/// Renders a styled subtitle overlay on top of a video canvas.
///
/// Displays the subtitle text with word-by-word highlighting
/// (the active word is rendered in the accent color) over a
/// semi-transparent background box. Uses [AnimatedOpacity] for
/// smooth fade transitions between segments.
class SubtitleOverlay extends StatelessWidget {
  /// The subtitle segment to display. If null, the overlay is hidden.
  final SubtitleSegment? segment;

  /// The caption style preset controlling font size, opacity, and accent.
  final CaptionStyle style;

  /// Index of the word currently being spoken (0-based). If null, no word
  /// is highlighted.
  final int? activeWordIndex;

  /// Optional callback invoked when dragging vertically on the subtitle box.
  final ValueChanged<double>? onPositionDelta;

  const SubtitleOverlay({
    super.key,
    required this.segment,
    required this.style,
    this.activeWordIndex,
    this.onPositionDelta,
  });

  @override
  Widget build(BuildContext context) {
    AlignmentGeometry getAlignment() {
      switch (style.position) {
        case SubtitlePosition.top:
          return Alignment.topCenter;
        case SubtitlePosition.center:
          return Alignment.center;
        case SubtitlePosition.bottom:
          return const Alignment(0, 0.90);
        case SubtitlePosition.custom:
          return Alignment(0, style.customY);
      }
    }

    final double topPad = style.position == SubtitlePosition.top ? 16.0 : 6.0;
    final double bottomPad = style.position == SubtitlePosition.bottom
        ? 10.0
        : 6.0;

    return AnimatedOpacity(
      opacity: segment != null ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: segment != null
          ? Align(
              alignment: getAlignment(),
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  top: topPad,
                  bottom: bottomPad,
                ),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragUpdate: onPositionDelta != null
                      ? (details) =>
                            onPositionDelta!(details.primaryDelta ?? 0.0)
                      : null,
                  child: _buildOverlay(context),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  TextStyle _baseStyle(
    BuildContext context, {
    Color? color,
    Paint? foreground,
  }) {
    return Theme.of(context).textTheme.bodyMedium!.copyWith(
      fontFamily: CaptionStyle.fontFamily,
      fontSize: style.fontSize,
      height: style.lineHeight,
      fontWeight: FontWeight.bold,
      color: foreground == null ? color : null,
      foreground: foreground,
      shadows: style.shadowBlur > 0
          ? [
              Shadow(
                color: style.shadowColor.withValues(alpha: 0.85),
                blurRadius: style.shadowBlur,
              ),
            ]
          : null,
    );
  }

  Widget _buildOverlay(BuildContext context) {
    final words = segment!.text.split(' ');

    List<InlineSpan> spans({Paint? foreground}) {
      return words.asMap().entries.map((entry) {
        final isActive = entry.key == activeWordIndex;
        final isLastWord = entry.key == words.length - 1;
        return TextSpan(
          text: isLastWord ? entry.value : '${entry.value} ',
          style: _baseStyle(
            context,
            color: isActive ? style.accentColor : AppColors.allWhite,
            foreground: foreground,
          ),
        );
      }).toList();
    }

    final fill = RichText(
      textAlign: style.textAlign.asTextAlign,
      text: TextSpan(children: spans()),
    );

    Widget body = fill;
    if (style.outlineWidth > 0) {
      final strokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = style.outlineWidth
        ..color = style.outlineColor;
      body = Stack(
        alignment: Alignment.center,
        children: [
          RichText(
            textAlign: style.textAlign.asTextAlign,
            text: TextSpan(children: spans(foreground: strokePaint)),
          ),
          fill,
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: AppColors.baseCanvas.withValues(alpha: style.boxOpacity),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: body,
    );
  }
}
