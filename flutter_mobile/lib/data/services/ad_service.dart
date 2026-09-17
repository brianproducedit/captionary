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
    if (_configuredBannerId.isNotEmpty) {
      return _configuredBannerId;
    }
    if (Platform.isIOS) {
      return defaultIosTestBannerId;
    }
    return defaultAndroidTestBannerId;
  }

  /// Initialize the Google Mobile Ads SDK safely.
  Future<void> initialize() async {
    if (!isSupportedPlatform || _initialized) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      debugPrint('[AdService] Google Mobile Ads SDK initialized successfully.');
    } catch (e) {
      debugPrint('[AdService] MobileAds initialize failed: $e');
    }
  }

  /// Creates and loads a BannerAd.
  /// Callers should dispose the returned [BannerAd] when unmounted.
  BannerAd? createBannerAd({
    required void Function(BannerAd ad) onAdLoaded,
    required void Function(BannerAd ad, LoadAdError error) onAdFailedToLoad,
  }) {
    if (!isSupportedPlatform) return null;

    final bannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('[AdService] BannerAd loaded.');
          onAdLoaded(ad as BannerAd);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('[AdService] BannerAd failed to load: ${error.message} (code ${error.code})');
          ad.dispose();
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
