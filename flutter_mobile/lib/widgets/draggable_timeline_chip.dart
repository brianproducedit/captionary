import 'package:flutter/material.dart';

import '../data/models/subtitle_segment.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_typography.dart';

class DraggableTimelineChip extends StatelessWidget {
  final SubtitleSegment segment;
  final bool isSelected;
  final bool isActive;
  final double width;
  final VoidCallback onTap;
  final VoidCallback? onDragStart;
  final ValueChanged<double> onMoveDx;
  final ValueChanged<double>? onTrimStartDx;
  final ValueChanged<double>? onTrimEndDx;

  const DraggableTimelineChip({
    super.key,
    required this.segment,
    required this.isSelected,
    required this.isActive,
    required this.width,
    required this.onTap,
    required this.onMoveDx,
    this.onDragStart,
    this.onTrimStartDx,
    this.onTrimEndDx,
  });

  @override
  Widget build(BuildContext context) {
    final minWidth = isSelected ? 40.0 : 28.0;
    final effectiveWidth = width < minWidth ? minWidth : width;

    return GestureDetector(
      onTap: onTap,
      onHorizontalDragStart: (_) => onDragStart?.call(),
      onHorizontalDragUpdate: (details) => onMoveDx(details.delta.dx),
      child: Container(
        width: effectiveWidth,
        height: 48,
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary
              : (isSelected
                    ? AppColors.secondary
                    : AppColors.surfaceContainerHigh),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.onSurface : Colors.transparent,
            width: isSelected ? 2 : 0,
          ),
          boxShadow: isActive ? [AppShadows.glowPrimary] : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Row(
            children: [
              if (isSelected && onTrimStartDx != null)
                _TrimHandle(
                  semanticLabel: 'Trim start',
                  onDragStart: onDragStart,
                  onDragDx: onTrimStartDx!,
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    segment.text,
                    style: AppTypography.bodySm.copyWith(
                      color: (isActive || isSelected)
                          ? AppColors.onPrimary
                          : AppColors.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.fade,
                    softWrap: false,
                  ),
                ),
              ),
              if (isSelected && onTrimEndDx != null)
                _TrimHandle(
                  semanticLabel: 'Trim end',
                  onDragStart: onDragStart,
                  onDragDx: onTrimEndDx!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrimHandle extends StatelessWidget {
  final String semanticLabel;
  final VoidCallback? onDragStart;
  final ValueChanged<double> onDragDx;

  const _TrimHandle({
    required this.semanticLabel,
    required this.onDragDx,
    this.onDragStart,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: (_) => onDragStart?.call(),
      onHorizontalDragUpdate: (details) => onDragDx(details.delta.dx),
      child: Semantics(
        label: semanticLabel,
        button: true,
        child: Container(
          width: 12,
          color: AppColors.baseCanvas.withValues(alpha: 0.25),
          child: const Center(
            child: Icon(Icons.drag_handle, size: 12, color: AppColors.allWhite),
          ),
        ),
      ),
    );
  }
}
