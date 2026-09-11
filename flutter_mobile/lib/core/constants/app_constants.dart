class AppConstants {
  static const String r2BaseUrl = 'https://pub-xxxx.r2.dev';
  static const String manifestUrl = '$r2BaseUrl/manifest.json';

  /// Canonical donate portal URL. Keep in sync with
  /// `react_frontend/src/config/public.ts` (`publicConfig.donateWebUrl`).
  static const String donateWebUrl = 'https://captionary.co.zw/donate';
  static const int maxModelSizeBytes = 1024 * 1024 * 1024; // 1GB
  static const int audioSampleDurationSec = 30;
  static const double storageCapacityGB = 10.0;
  static const Duration donateReminderInterval = Duration(hours: 8);
}
