import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'gradient_pill_button.dart';

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surfaceContainerHigh),
              ),
              child: Icon(
                icon,
                size: 64,
                color: AppColors.primary.withAlpha(200),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    height: 1.5,
                  ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 32),
              GradientPillButton(
                label: actionLabel!,
                icon: actionIcon,
                onTap: onAction!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
