import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../theme/app_colors.dart';

/// Deterministic local placeholder for reserved bottom ad space.
///
/// Do not add a live ad SDK. Allowed only on language packs and export.
class AdBannerWidget extends StatelessWidget {
  static const double defaultHeight = 60.0;
  static const String placeholderLabel = 'Local placeholder space';

  final double bannerHeight;

  const AdBannerWidget({super.key, this.bannerHeight = defaultHeight});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: placeholderLabel,
      child: Container(
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
            Flexible(
              child: Text(
                placeholderLabel,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
