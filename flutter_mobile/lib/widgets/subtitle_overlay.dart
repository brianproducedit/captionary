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

  const SubtitleOverlay({
    super.key,
    required this.segment,
    required this.style,
    this.activeWordIndex,
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
          return Alignment.bottomCenter;
        case SubtitlePosition.custom:
          return Alignment(0, style.customY);
      }
    }

    return AnimatedOpacity(
      opacity: segment != null ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: segment != null
          ? Align(
              alignment: getAlignment(),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 24.0,
                  horizontal: 16.0,
                ),
                child: _buildOverlay(context),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildOverlay(BuildContext context) {
    final words = segment!.text.split(' ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: AppColors.baseCanvas.withValues(alpha: style.boxOpacity),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: style.fontSize,
            fontWeight: FontWeight.bold,
            shadows: [const Shadow(color: AppColors.baseCanvas, blurRadius: 4)],
          ),
          children: words.asMap().entries.map((entry) {
            final isActive = entry.key == activeWordIndex;
            final isLastWord = entry.key == words.length - 1;
            return TextSpan(
              text: isLastWord ? entry.value : '${entry.value} ',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isActive ? style.accentColor : AppColors.allWhite,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
