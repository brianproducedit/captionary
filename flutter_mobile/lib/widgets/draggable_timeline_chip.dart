import 'package:flutter/material.dart';

import '../data/models/subtitle_segment.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_shadows.dart';

class DraggableTimelineChip extends StatelessWidget {
  final SubtitleSegment segment;
  final bool isSelected;
  final bool isActive;
  final double msPerPx;
  final VoidCallback onTap;
  final Function(Duration) onDragUpdate;

  const DraggableTimelineChip({
    super.key,
    required this.segment,
    required this.isSelected,
    required this.isActive,
    required this.msPerPx,
    required this.onTap,
    required this.onDragUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final int durationMs =
        segment.endTime.inMilliseconds - segment.startTime.inMilliseconds;
    final double width = durationMs / msPerPx;

    return GestureDetector(
      onTap: onTap,
      onHorizontalDragUpdate: (details) {
        final deltaMs = (details.delta.dx * msPerPx).round();
        onDragUpdate(Duration(milliseconds: deltaMs));
      },
      child: Container(
        width: width,
        height: 60,
        margin: const EdgeInsets.only(right: 2),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary
              : (isSelected
                    ? AppColors.secondary
                    : AppColors.surfaceContainerHigh),
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: isSelected ? AppColors.onSurface : Colors.transparent,
            width: isSelected ? 2 : 0,
          ),
          boxShadow: isActive ? [AppShadows.glowPrimary] : [],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
        child: Text(
          segment.text,
          style: AppTypography.bodySm.copyWith(
            color: (isActive || isSelected)
                ? AppColors.onPrimary
                : AppColors.onSurfaceVariant,
          ),
          overflow: TextOverflow.fade,
        ),
      ),
    );
  }
}
