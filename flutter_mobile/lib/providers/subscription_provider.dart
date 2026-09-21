import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'engagement_provider.dart';

enum SubscriptionTier { free, pass24h, creatorPro }

extension SubscriptionTierX on SubscriptionTier {
  String get displayName {
    switch (this) {
      case SubscriptionTier.free:
        return 'Free Beta';
      case SubscriptionTier.pass24h:
        return '24-Hour Pass';
      case SubscriptionTier.creatorPro:
        return 'Creator Pro';
    }
  }

  String get priceDisplay {
    switch (this) {
      case SubscriptionTier.free:
        return '\$0';
      case SubscriptionTier.pass24h:
        return '\$0.99';
      case SubscriptionTier.creatorPro:
        return '\$7.99';
    }
  }

  String get billingPeriod {
    switch (this) {
      case SubscriptionTier.free:
        return 'Free Forever';
      case SubscriptionTier.pass24h:
        return '24-Hour Access';
      case SubscriptionTier.creatorPro:
        return 'One-time • Lifetime Access';
    }
  }
}

class SubscriptionState {
  final SubscriptionTier tier;
  final String deviceId;
  final DateTime? passExpiresAt;

  const SubscriptionState({
    this.tier = SubscriptionTier.free,
    this.deviceId = '',
    this.passExpiresAt,
  });

  bool get isPro {
    if (tier == SubscriptionTier.creatorPro) return true;
    if (tier == SubscriptionTier.pass24h && passExpiresAt != null) {
      return passExpiresAt!.isAfter(DateTime.now());
    }
    return false;
  }

  bool get isWatermarkMandatory => !isPro;

  int get maxExportResolution => isPro ? 2160 : 720;

  SubscriptionState copyWith({
    SubscriptionTier? tier,
    String? deviceId,
    DateTime? passExpiresAt,
  }) {
    return SubscriptionState(
      tier: tier ?? this.tier,
      deviceId: deviceId ?? this.deviceId,
      passExpiresAt: passExpiresAt ?? this.passExpiresAt,
    );
  }
}

class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  static const String _prefsKeyDeviceId = 'captionary_anonymous_device_id';
  static const String _prefsKeyTier = 'captionary_subscription_tier';
  static const String _prefsKeyPassExpiry = 'captionary_pass_expiry_ms';

  final SharedPreferences? _prefs;

  SubscriptionNotifier([this._prefs]) : super(const SubscriptionState()) {
    if (_prefs != null) {
      _loadFromPrefs(_prefs);
    } else {
      _init();
    }
  }

  void _loadFromPrefs(SharedPreferences prefs) {
    var id = prefs.getString(_prefsKeyDeviceId);
    if (id == null || id.isEmpty) {
      id = _generateDeviceId();
      prefs.setString(_prefsKeyDeviceId, id);
    }

    final tierStr = prefs.getString(_prefsKeyTier);
    final expiryMs = prefs.getInt(_prefsKeyPassExpiry);

    SubscriptionTier initialTier = SubscriptionTier.free;
    DateTime? expiry;

    if (tierStr == SubscriptionTier.creatorPro.name) {
      initialTier = SubscriptionTier.creatorPro;
    } else if (tierStr == SubscriptionTier.pass24h.name && expiryMs != null) {
      expiry = DateTime.fromMillisecondsSinceEpoch(expiryMs);
      if (expiry.isAfter(DateTime.now())) {
        initialTier = SubscriptionTier.pass24h;
      }
    }

    state = SubscriptionState(
      deviceId: id,
      tier: initialTier,
      passExpiresAt: expiry,
    );
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _loadFromPrefs(prefs);
  }

  static String _generateDeviceId() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    // Set UUID version 4 and variant
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  Future<void> unlockTier(SubscriptionTier tier, {Duration? duration}) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    DateTime? expiry;
    if (tier == SubscriptionTier.pass24h) {
      expiry = DateTime.now().add(duration ?? const Duration(hours: 24));
      await prefs.setInt(_prefsKeyPassExpiry, expiry.millisecondsSinceEpoch);
    } else {
      await prefs.remove(_prefsKeyPassExpiry);
    }

    await prefs.setString(_prefsKeyTier, tier.name);
    state = state.copyWith(tier: tier, passExpiresAt: expiry);
  }

  Future<void> resetToFree() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setString(_prefsKeyTier, SubscriptionTier.free.name);
    await prefs.remove(_prefsKeyPassExpiry);
    state = state.copyWith(tier: SubscriptionTier.free, passExpiresAt: null);
  }
}

final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
      try {
        final prefs = ref.watch(sharedPreferencesProvider);
        return SubscriptionNotifier(prefs);
      } catch (_) {
        return SubscriptionNotifier();
      }
    });
