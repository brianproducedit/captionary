import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/user_preferences.dart';
import 'engagement_provider.dart';

class PreferencesNotifier extends StateNotifier<UserPreferences> {
  final SharedPreferences _prefs;

  PreferencesNotifier(this._prefs) : super(_read(_prefs));

  static UserPreferences _read(SharedPreferences prefs) {
    final speed =
        prefs.getDouble(PreferenceKeys.playbackSpeed) ??
        UserPreferences.defaults.playbackSpeed;
    final nearest = UserPreferences.playbackSpeeds.reduce(
      (a, b) => (a - speed).abs() < (b - speed).abs() ? a : b,
    );
    return UserPreferences(
      autoPlay:
          prefs.getBool(PreferenceKeys.autoPlay) ??
          UserPreferences.defaults.autoPlay,
      playbackSpeed: nearest,
      volume:
          (prefs.getDouble(PreferenceKeys.volume) ??
                  UserPreferences.defaults.volume)
              .clamp(0.0, 1.0),
      exportQuality:
          prefs.getString(PreferenceKeys.exportQuality) ??
          UserPreferences.defaults.exportQuality,
      exportFormat:
          prefs.getString(PreferenceKeys.exportFormat) ??
          UserPreferences.defaults.exportFormat,
      ramTier:
          prefs.getString(PreferenceKeys.ramTier) ??
          UserPreferences.defaults.ramTier,
    );
  }

  Future<void> setAutoPlay(bool value) async {
    await _prefs.setBool(PreferenceKeys.autoPlay, value);
    state = state.copyWith(autoPlay: value);
  }

  Future<void> setPlaybackSpeed(double value) async {
    await _prefs.setDouble(PreferenceKeys.playbackSpeed, value);
    state = state.copyWith(playbackSpeed: value);
  }

  Future<void> setVolume(double value) async {
    await _prefs.setDouble(PreferenceKeys.volume, value);
    state = state.copyWith(volume: value);
  }

  Future<void> setExportQuality(String value) async {
    await _prefs.setString(PreferenceKeys.exportQuality, value);
    state = state.copyWith(exportQuality: value);
  }

  Future<void> setExportFormat(String value) async {
    await _prefs.setString(PreferenceKeys.exportFormat, value);
    state = state.copyWith(exportFormat: value);
  }

  Future<void> setRamTier(String value) async {
    await _prefs.setString(PreferenceKeys.ramTier, value);
    state = state.copyWith(ramTier: value);
  }

  Future<void> resetToDefaults() async {
    await _prefs.setBool(
      PreferenceKeys.autoPlay,
      UserPreferences.defaults.autoPlay,
    );
    await _prefs.setDouble(
      PreferenceKeys.playbackSpeed,
      UserPreferences.defaults.playbackSpeed,
    );
    await _prefs.setDouble(
      PreferenceKeys.volume,
      UserPreferences.defaults.volume,
    );
    await _prefs.setString(
      PreferenceKeys.exportQuality,
      UserPreferences.defaults.exportQuality,
    );
    await _prefs.setString(
      PreferenceKeys.exportFormat,
      UserPreferences.defaults.exportFormat,
    );
    await _prefs.setString(
      PreferenceKeys.ramTier,
      UserPreferences.defaults.ramTier,
    );
    state = UserPreferences.defaults;
  }
}

final preferencesProvider =
    StateNotifierProvider<PreferencesNotifier, UserPreferences>((ref) {
      return PreferencesNotifier(ref.watch(sharedPreferencesProvider));
    });

final appPackageInfoProvider = Provider<AppPackageInfo>((ref) {
  return AppPackageInfo.fallback;
});
