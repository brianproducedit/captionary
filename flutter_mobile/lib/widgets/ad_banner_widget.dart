import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../theme/app_colors.dart';

/// A mock AdMob banner placeholder widget.
///
/// In mock mode (default), renders a styled placeholder card matching the
/// design system. In production mode, this would render an actual [AdWidget].
class AdBannerWidget extends StatelessWidget {
  final String adUnitId;
  final double bannerHeight;

  const AdBannerWidget({
    super.key,
    this.adUnitId = 'ca-app-pub-mock/placeholder',
    this.bannerHeight = 60.0,
  });

  @override
  Widget build(BuildContext context) {
    // Mock mode: show styled placeholder
    return Container(
      width: double.infinity,
      height: bannerHeight,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Symbols.ad_units,
            color: AppColors.onSurfaceVariant,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Ad Space',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(width: 8),
          Text(
            '• Google AdMob Adaptive Banner',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                ),
          ),
        ],
      ),
    );
  }
}
