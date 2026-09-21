import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../data/services/ad_service.dart';
import '../theme/app_colors.dart';

/// Renders a real payable Google AdMob banner on mobile devices
/// with a graceful fallback for offline, desktop, and test environments.
class AdBannerWidget extends ConsumerStatefulWidget {
  static const double defaultHeight = 60.0;
  static const String placeholderLabel = 'Ad Space';

  final double bannerHeight;

  const AdBannerWidget({super.key, this.bannerHeight = defaultHeight});

  @override
  ConsumerState<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends ConsumerState<AdBannerWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _initAndLoadAd();
  }

  Future<void> _initAndLoadAd() async {
    final adService = ref.read(adServiceProvider);
    await adService.initialize();
    if (!mounted || _isDisposed) return;

    final ad = adService.createBannerAd(
      onAdLoaded: (loadedAd) {
        if (mounted && !_isDisposed) {
          setState(() {
            _bannerAd = loadedAd;
            _isAdLoaded = true;
          });
        } else {
          loadedAd.dispose();
        }
      },
      onAdFailedToLoad: (failedAd, error) {
        if (mounted && !_isDisposed) {
          setState(() {
            _bannerAd = null;
            _isAdLoaded = false;
          });
        }
      },
    );

    if (mounted && !_isDisposed) {
      _bannerAd = ad;
    } else {
      ad?.dispose();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _bannerAd?.dispose();
    _bannerAd = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isAdLoaded && _bannerAd != null) {
      return Container(
        width: double.infinity,
        height: _bannerAd!.size.height.toDouble(),
        alignment: Alignment.center,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: AdWidget(ad: _bannerAd!),
      );
    }

    // Elegant fallback / placeholder when ad is loading, offline, or running in test/desktop
    return Semantics(
      label: AdBannerWidget.placeholderLabel,
      child: Container(
        width: double.infinity,
        height: widget.bannerHeight,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Symbols.ad_units,
              color: AppColors.onSurfaceVariant,
              size: 18,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                AdBannerWidget.placeholderLabel,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
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
