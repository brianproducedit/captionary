import 'package:flutter/material.dart';

import '../data/models/caption_style.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';

class CaptionStyleCard extends StatelessWidget {
  final CaptionStyle style;
  final bool isSelected;
  final VoidCallback onTap;

  const CaptionStyleCard({
    super.key,
    required this.style,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : AppColors.surfaceContainerHigh,
            width: 2,
          ),
          gradient: isSelected ? AppGradients.primaryGradient : null,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: style.boxOpacity),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  style.previewText,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 14, // Scale down for preview
                    fontWeight: FontWeight.bold,
                    color: style.accentColor,
                    // Mock font families based on name if desired, keeping simple for now
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                style.name,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isSelected
                      ? AppColors.onSurface
                      : AppColors.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (isSelected)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Icon(
                    Icons.check_circle,
                    color: AppColors.primary,
                    size: 16,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
