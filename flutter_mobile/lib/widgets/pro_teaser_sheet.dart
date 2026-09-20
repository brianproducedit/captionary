import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_shadows.dart';
import '../theme/app_typography.dart';
import 'ghost_pill_button.dart';
import 'gradient_pill_button.dart';

class ProTeaserSheet extends StatelessWidget {
  final String featureTriggered;

  const ProTeaserSheet({
    super.key,
    this.featureTriggered = 'Premium Feature',
  });

  static Future<void> show(
    BuildContext context, {
    String featureTriggered = 'Premium Feature',
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProTeaserSheet(featureTriggered: featureTriggered),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.0)),
        border: Border(
          top: BorderSide(color: AppColors.surfaceContainerHigh, width: 1.0),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        20.0,
        12.0,
        20.0,
        MediaQuery.of(context).padding.bottom + 24.0,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header badge
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
              decoration: BoxDecoration(
                gradient: AppGradients.primaryGradient,
                borderRadius: BorderRadius.circular(9999),
                boxShadow: const [AppShadows.tertiaryGlow],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Symbols.workspace_premium, size: 16, color: AppColors.baseCanvas),
                  const SizedBox(width: 6),
                  Text(
                    'PREMIUM UNLOCKS COMING SOON',
                    style: AppTypography.labelMd.copyWith(
                      color: AppColors.baseCanvas,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            '$featureTriggered is a Pro Feature',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.allWhite,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          Text(
            'Captionary is currently in Free Beta with unlimited on-device Whisper AI. '
            'Upcoming paid passes will unlock watermark removal and 1080p/4K exports via mobile money (EcoCash, Innbucks).',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Upcoming tiers comparison preview
          _buildTierFeatureRow(
            context,
            icon: Symbols.timer,
            title: '24-Hour Pass (\$0.99)',
            subtitle: '24 hours of watermark removal & 1080p exports for single viral video edits.',
          ),
          const SizedBox(height: 12),
          _buildTierFeatureRow(
            context,
            icon: Symbols.diamond,
            title: 'Creator Pro (\$7.99 Lifetime)',
            subtitle: 'Permanent watermark removal, 1080p/4K exports, batch tools & custom font imports.',
            highlight: true,
          ),
          const SizedBox(height: 12),
          _buildTierFeatureRow(
            context,
            icon: Symbols.smartphone,
            title: 'Google Play & Sync Code Compliant',
            subtitle: 'No account signup needed. Activate seamlessly on the web portal with EcoCash & Innbucks.',
          ),
          const SizedBox(height: 28),

          // Action buttons
          GradientPillButton(
            label: 'View All Pricing & Tiers',
            icon: Symbols.visibility,
            onTap: () {
              Navigator.of(context).pop();
              context.push('/pro');
            },
            isFullWidth: true,
          ),
          const SizedBox(height: 10),
          GhostPillButton(
            label: 'Got it, stay on Free Beta',
            onTap: () => Navigator.of(context).pop(),
            isFullWidth: true,
          ),
        ],
      ),
    ),
  );
}

  Widget _buildTierFeatureRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.primaryContainer.withAlpha(40)
            : AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(
          color: highlight ? AppColors.primary : AppColors.surfaceContainerHigh,
          width: highlight ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: highlight
                  ? AppColors.primary.withAlpha(50)
                  : AppColors.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 18,
              color: highlight ? AppColors.primary : AppColors.onSurface,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: highlight ? AppColors.primary : AppColors.allWhite,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
