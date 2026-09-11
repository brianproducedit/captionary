import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../theme/app_colors.dart';

class NotificationPreviewCard extends StatelessWidget {
  final VoidCallback? onDonateTap;

  const NotificationPreviewCard({super.key, this.onDonateTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Icon + App Name + Timestamp
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Symbols.closed_caption,
                  size: 14,
                  color: AppColors.onPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Captionary',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '• 8h ago',
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Text(
                  'PREVIEW',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Content
          Text(
            '☕ Your video captioning matters!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Fuel Captionary with a small donation to keep our AI language models updated and accessible to everyone.',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.onSurfaceVariant, height: 1.3),
          ),
          const SizedBox(height: 12),
          // Action button
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onDonateTap,
              style: TextButton.styleFrom(
                backgroundColor: AppColors.primary.withAlpha(25),
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 6.0,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
              ),
              icon: const Icon(Symbols.local_cafe, size: 16),
              label: Text(
                'Donate ☕',
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
