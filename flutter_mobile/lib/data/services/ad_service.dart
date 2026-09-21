import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  /// Default official Google test banner ID for Android.
  /// Replace via --dart-define=ADMOB_BANNER_ID=ca-app-pub-XXXXXXXXXXXXXXXX/ZZZZZZZZZZ for production.
  static const String defaultAndroidTestBannerId =
      'ca-app-pub-3940256099942544/6300978111';

  /// Default official Google test banner ID for iOS.
  static const String defaultIosTestBannerId =
      'ca-app-pub-3940256099942544/2934735716';

  static const String _configuredBannerId = String.fromEnvironment(
    'ADMOB_BANNER_ID',
    defaultValue: '',
  );

  bool _initialized = false;
  bool get isInitialized => _initialized;

  /// Returns whether the current runtime environment supports native AdMob SDK.
  bool get isSupportedPlatform {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  /// The active Banner Ad Unit ID.
  String get bannerAdUnitId {
    // In debug mode, Google AdMob strictly requires using sample/test ad units.
    // Serving live ads on test devices can trigger Error 2 (Network/Inventory) or account suspension.
    if (kDebugMode || _configuredBannerId.isEmpty) {
      if (Platform.isIOS) {
        return defaultIosTestBannerId;
      }
      return defaultAndroidTestBannerId;
    }
    return _configuredBannerId;
  }

  /// Initialize the Google Mobile Ads SDK safely.
  Future<void> initialize({List<String>? testDeviceIds}) async {
    if (!isSupportedPlatform || _initialized) return;
    try {
      await MobileAds.instance.initialize();
      final devices = [
        '1E36DB6BB99F0D49096AB3D3150BBB24',
        ...?testDeviceIds,
      ];
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(testDeviceIds: devices),
      );
      _initialized = true;
      debugPrint(
        '[AdService] Google Mobile Ads SDK initialized successfully with test devices: $devices',
      );
    } catch (e) {
      debugPrint('[AdService] MobileAds initialize failed: $e');
    }
  }

  /// Creates and loads a BannerAd.
  /// Callers should dispose the returned [BannerAd] when unmounted.
  BannerAd? createBannerAd({
    required void Function(BannerAd ad) onAdLoaded,
    required void Function(BannerAd ad, LoadAdError error) onAdFailedToLoad,
    String? customAdUnitId,
  }) {
    if (!isSupportedPlatform) return null;

    final unitId = customAdUnitId ?? bannerAdUnitId;
    final testFallbackUnitId =
        Platform.isIOS ? defaultIosTestBannerId : defaultAndroidTestBannerId;

    BannerAd? bannerAd;
    bannerAd = BannerAd(
      adUnitId: unitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('[AdService] BannerAd loaded successfully for unit $unitId.');
          onAdLoaded(ad as BannerAd);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint(
            '[AdService] BannerAd ($unitId) failed to load: ${error.message} (code ${error.code})',
          );
          ad.dispose();
          // If custom live banner failed and we aren't already trying the test banner, fallback to test banner
          if (unitId != testFallbackUnitId) {
            debugPrint(
              '[AdService] Retrying with Google Test Banner unit: $testFallbackUnitId',
            );
            createBannerAd(
              onAdLoaded: onAdLoaded,
              onAdFailedToLoad: onAdFailedToLoad,
              customAdUnitId: testFallbackUnitId,
            );
            return;
          }
          onAdFailedToLoad(ad as BannerAd, error);
        },
      ),
    );

    bannerAd.load();
    return bannerAd;
  }
}

final adServiceProvider = Provider<AdService>((ref) {
  return AdService();
});
