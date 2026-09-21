import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../core/constants/app_constants.dart';
import '../providers/url_open_provider.dart';
import '../widgets/ad_banner_widget.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/gradient_pill_button.dart';
import '../widgets/app_header.dart';
import '../widgets/url_fallback_dialog.dart';

class DonateScreen extends ConsumerWidget {
  const DonateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: const AppHeader(
        subtitle: 'Donate to Captionary',
        showBackButton: true,
        showDonatePill: false,
      ),
      body: ListView(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 64.0 + 24.0,
          bottom: AppSpacing.bottomNavClearance,
          left: 16.0,
          right: 16.0,
        ),
        children: [
          _buildHeroSpotlight(context),
          const SizedBox(height: 32),
          _buildWebContributionCard(context, ref),
          const SizedBox(height: 32),
          Text(
            'Your Impact',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildDirectImpactGrid(context),
          const SizedBox(height: 32),
          _buildSignOffBadge(context),
          const SizedBox(height: 16),
          const AdBannerWidget(),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: -1),
    );
  }

  Widget _buildHeroSpotlight(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: AppGradients.ambientBackgroundGlow,
            ),
          ),
        ),
        Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 6.0,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(9999),
                border: Border.all(color: AppColors.surfaceContainerHigh),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.tertiary,
                      shape: BoxShape.circle,
                      boxShadow: [AppShadows.tertiaryGlow],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Open-Source & Independent',
                      style: Theme.of(context).textTheme.labelMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/captionary_logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(
                        Symbols.closed_caption,
                        size: 48,
                        color: AppColors.onPrimary,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Donate to Independent AI Speech',
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Help us preserve and digitize native dialects like Shona, isiZulu, and Sepedi for creators everywhere, free from corporate paywalls.',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ],
    );
  }

  Widget _buildWebContributionCard(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(color: AppColors.surfaceContainerHigh),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceContainerLow,
            AppColors.primaryContainer.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Symbols.gate, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Web Donation Gateway',
                  style: Theme.of(context).textTheme.labelMedium
                      ?.copyWith(color: AppColors.primary, letterSpacing: 1.2),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Fuel Our Infrastructure',
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Donate using EcoCash, Paynow, international cards, or crypto through our web portal.',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          GradientPillButton(
            label: 'Open Web Donation Portal',
            icon: Symbols.open_in_new,
            onTap: () async {
              final url = AppConstants.donateWebUrl;
              final uri = Uri.parse(url);
              try {
                final opened = await ref.read(urlOpenHandlerProvider)(uri);
                if (!opened && context.mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => UrlFallbackDialog(url: url),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => UrlFallbackDialog(url: url),
                  );
                }
              }
            },
            isFullWidth: true,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Symbols.lock,
                size: 14,
                color: AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  'captionary.ai/donate • Opens in browser',
                  style: AppTypography.captionCode.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDirectImpactGrid(BuildContext context) {
    return Column(
      children: [
        _buildImpactCard(
          context: context,
          icon: Symbols.cloud_sync,
          iconColor: AppColors.primary,
          title: 'Cloudflare R2 Bandwidth',
          description: 'Pays for global edge-distribution of heavy acoustic models to local devices.',
        ),
        const SizedBox(height: 12),
        _buildImpactCard(
          context: context,
          icon: Symbols.tune,
          iconColor: AppColors.secondary,
          title: 'Dialect Fine-Tuning Compute',
          description: 'Renting H100 GPU clusters to train new phonetic variations and low-resource accents.',
        ),
        const SizedBox(height: 12),
        _buildImpactCard(
          context: context,
          icon: Symbols.lock_open_right,
          iconColor: AppColors.tertiary,
          title: '100% Free and AGPL-3.0 Licensed',
          description: 'Guarantees the core app and models will never be locked behind a subscription.',
        ),
      ],
    );
  }

  Widget _buildImpactCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignOffBadge(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Symbols.favorite, size: 16, color: AppColors.secondary),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            'Crafted for mobile creators everywhere',
            style: AppTypography.captionCode.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
