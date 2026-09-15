import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

enum StatusChipVariant { ready, processing, pending, newVariant, error }

class StatusChip extends StatelessWidget {
  final String label;
  final StatusChipVariant variant;
  final IconData? icon;

  const StatusChip({
    super.key,
    required this.label,
    required this.variant,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;

    switch (variant) {
      case StatusChipVariant.ready:
        bgColor = AppColors.tertiaryContainer;
        textColor = AppColors.onTertiaryContainer;
        break;
      case StatusChipVariant.processing:
        bgColor = AppColors.secondaryContainer;
        textColor = AppColors.onSecondaryContainer;
        break;
      case StatusChipVariant.pending:
        bgColor = AppColors.surfaceContainerHigh;
        textColor = AppColors.onSurfaceVariant;
        break;
      case StatusChipVariant.newVariant:
        bgColor = AppColors.primaryContainer;
        textColor = AppColors.onPrimaryContainer;
        break;
      case StatusChipVariant.error:
        bgColor = AppColors.errorContainer;
        textColor = AppColors.onErrorContainer;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4.0), // small radius for chips
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTypography.captionCode.copyWith(
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
