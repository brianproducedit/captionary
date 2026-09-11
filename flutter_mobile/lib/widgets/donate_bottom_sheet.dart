import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../widgets/gradient_pill_button.dart';
import '../widgets/ghost_pill_button.dart';

class DonateBottomSheet extends StatelessWidget {
  const DonateBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(
        left: 24.0,
        right: 24.0,
        top: 12.0,
        bottom: 32.0,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.0),
          topRight: Radius.circular(24.0),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(9999),
            ),
          ),
          const SizedBox(height: 32),
          // Icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.tertiary),
              boxShadow: const [AppShadows.tertiaryGlow],
            ),
            child: const Icon(Symbols.local_cafe, size: 32, color: AppColors.tertiary),
          ),
          const SizedBox(height: 24),
          // Text
          Text(
            'Fuel Our Mission 🚀',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your donation keeps Captionary free and ad-light for everyone.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 32),
          // Buttons
          SizedBox(
            width: double.infinity,
            child: GradientPillButton(
              label: 'Donate Now',
              icon: Symbols.open_in_new,
              onTap: () {
                // Future integration for URL launcher
                Navigator.of(context).pop();
              },
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: GhostPillButton(
              label: 'Maybe Later',
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}
