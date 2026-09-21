import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../providers/subscription_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/ad_banner_widget.dart';
import '../widgets/app_header.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/ghost_pill_button.dart';
import '../widgets/gradient_pill_button.dart';
import '../widgets/pro_teaser_sheet.dart';

class UpgradeProScreen extends ConsumerWidget {
  const UpgradeProScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sub = ref.watch(subscriptionProvider);

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: const AppHeader(subtitle: 'Captionary Pro'),
      body: ListView(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 64.0 + 20.0,
          bottom: AppSpacing.bottomNavClearance,
          left: 16.0,
          right: 16.0,
        ),
        children: [
          _buildHeroSpotlight(context, sub),
          const SizedBox(height: 28),

          // Tiers Header
          Text(
            'Choose Your Plan',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.allWhite,
            ),
          ),
          const SizedBox(height: 14),

          // 1. Creator Pro (Featured First for high conversion)
          _buildCreatorProCard(context, sub),
          const SizedBox(height: 16),

          // 2. 24-Hour Pass (Impulse Buy)
          _buildPass24hCard(context, sub),
          const SizedBox(height: 16),

          // 3. Free Beta (Active Baseline)
          _buildFreeCard(context, sub),
          const SizedBox(height: 32),

          // Sync Code & Google Play Architecture Card
          _buildSyncCodeArchitectureCard(context, sub),
          const SizedBox(height: 24),

          // Restore Purchases Button
          _buildRestorePurchasesButton(context),
          const SizedBox(height: 24),

          const AdBannerWidget(),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 3),
    );
  }

  Widget _buildHeroSpotlight(BuildContext context, SubscriptionState sub) {
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
                horizontal: 14.0,
                vertical: 6.0,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(9999),
                border: Border.all(color: AppColors.surfaceContainerHigh),
                boxShadow: const [AppShadows.tertiaryGlow],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: sub.isPro ? AppColors.tertiary : AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    sub.isPro ? 'CREATOR PRO ACTIVE' : 'FREE BETA TIER ACTIVE',
                    style: AppTypography.labelMd.copyWith(
                      color: AppColors.allWhite,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Supercharge Your Videos',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.allWhite,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'On-device Whisper AI engine. Zero recurring subscription traps. '
              'Built for creators in Zimbabwe, Africa, and across the globe.',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.onSurfaceVariant, height: 1.4),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCreatorProCard(BuildContext context, SubscriptionState sub) {
    final isCurrent = sub.tier == SubscriptionTier.creatorPro;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22.0),
        border: Border.all(
          color: const Color(0xFFFFD54F), // Gold accent
          width: 2.0,
        ),
        boxShadow: const [AppShadows.glowSupport],
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 4.0,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
                  ),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  'MOST POPULAR • LIFETIME',
                  style: AppTypography.labelMd.copyWith(
                    color: Colors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Text(
                '\$7.99',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFFFD54F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Creator Pro',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.allWhite,
            ),
          ),
          Text(
            'One-time payment • Lifetime permanent access • No SaaS friction',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.surfaceContainerHigh),
          const SizedBox(height: 12),
          _buildCheckFeature('Permanent watermark removal'),
          _buildCheckFeature('1080p Full HD & 4K Ultra HD video exports'),
          _buildCheckFeature('Batch timeline processing'),
          _buildCheckFeature('Custom font imports (.ttf / .otf)'),
          _buildCheckFeature('EcoCash, Innbucks, OneMoney & card support'),
          const SizedBox(height: 20),
          GradientPillButton(
            label: isCurrent
                ? 'Active Plan'
                : 'Unlock Creator Pro (Coming Soon)',
            icon: Symbols.diamond,
            onTap: () {
              ProTeaserSheet.show(
                context,
                featureTriggered: 'Creator Pro Lifetime Pass',
              );
            },
            isFullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPass24hCard(BuildContext context, SubscriptionState sub) {
    final isCurrent = sub.tier == SubscriptionTier.pass24h && sub.isPro;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: AppColors.primary, width: 1.2),
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 4.0,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withAlpha(60),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  'SINGLE VIRAL EDIT',
                  style: AppTypography.labelMd.copyWith(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '\$0.99',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '24-Hour Pass',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.allWhite,
            ),
          ),
          Text(
            '24 hours of full watermark removal & 1080p exports via mobile money',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.surfaceContainerHigh),
          const SizedBox(height: 12),
          _buildCheckFeature('Watermark & logo removal for 24 hours'),
          _buildCheckFeature('1080p exports for single viral TikToks/Reels'),
          _buildCheckFeature('Instant mobile money activation via Sync Code'),
          const SizedBox(height: 20),
          GhostPillButton(
            label: isCurrent ? 'Pass Active' : 'Get 24-Hour Pass (Coming Soon)',
            icon: Symbols.timer,
            onTap: () {
              ProTeaserSheet.show(
                context,
                featureTriggered: '24-Hour Creator Pass',
              );
            },
            isFullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildFreeCard(BuildContext context, SubscriptionState sub) {
    final isCurrent = sub.tier == SubscriptionTier.free;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: isCurrent
              ? AppColors.secondary
              : AppColors.surfaceContainerHigh,
        ),
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 4.0,
                ),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer.withAlpha(60),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  'CURRENT ACTIVE',
                  style: AppTypography.labelMd.copyWith(
                    color: AppColors.secondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '\$0',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Free Beta',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.allWhite,
            ),
          ),
          Text(
            'Free on-device transcription with organic viral watermark',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.surfaceContainerHigh),
          const SizedBox(height: 12),
          _buildCheckFeature('Unlimited captions with local Whisper AI'),
          _buildCheckFeature('720p HD video export'),
          _buildCheckFeature(
            'Mandatory "Captioned by Captionary" watermark + logo',
          ),
          _buildCheckFeature('99+ offline languages supported'),
        ],
      ),
    );
  }

  Widget _buildSyncCodeArchitectureCard(
    BuildContext context,
    SubscriptionState sub,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Symbols.verified_user,
                color: AppColors.tertiary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Zero-Friction Anonymous Identity',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.allWhite,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'No email or password signup required. Your entitlements are bound to your secure Device ID and unlocked via our Google Play compliant Web Sync Code system.',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.onSurfaceVariant, height: 1.4),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14.0,
              vertical: 10.0,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: AppColors.surfaceContainerHighest),
            ),
            child: Row(
              children: [
                const Icon(
                  Symbols.fingerprint,
                  size: 18,
                  color: AppColors.tertiary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    sub.deviceId.isNotEmpty
                        ? sub.deviceId
                        : 'Generating device id...',
                    style: AppTypography.captionCode.copyWith(
                      color: AppColors.allWhite,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Symbols.content_copy, size: 16),
                  color: AppColors.tertiary,
                  onPressed: sub.deviceId.isNotEmpty
                      ? () {
                          Clipboard.setData(ClipboardData(text: sub.deviceId));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Device ID copied to clipboard'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestorePurchasesButton(BuildContext context) {
    return Center(
      child: TextButton.icon(
        icon: const Icon(
          Symbols.restore,
          size: 16,
          color: AppColors.onSurfaceVariant,
        ),
        label: Text(
          'Restore Mobile Money Purchase',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.onSurfaceVariant,
            decoration: TextDecoration.underline,
          ),
        ),
        onPressed: () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppColors.surfaceContainerLow,
              title: const Text(
                'Restore Purchase',
                style: TextStyle(color: AppColors.allWhite),
              ),
              content: const Text(
                'Once the payment gateway is live, you can enter your mobile money phone number (EcoCash, Innbucks) and transaction reference to re-link entitlement to this device.',
                style: TextStyle(color: AppColors.onSurfaceVariant),
              ),
              actions: [
                TextButton(
                  child: const Text(
                    'Close',
                    style: TextStyle(color: AppColors.primary),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCheckFeature(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Symbols.check_circle, size: 16, color: AppColors.tertiary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.allWhite,
                fontSize: 13,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
