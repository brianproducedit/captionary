class AppConstants {
  static const String r2BaseUrl = String.fromEnvironment(
    'R2_BASE_URL',
    defaultValue: 'https://models.captionary.co.zw',
  );
  static const String manifestUrl = String.fromEnvironment(
    'MANIFEST_URL',
    defaultValue: 'https://models.captionary.co.zw/manifest.json',
  );

  /// Canonical donate portal URL. Keep in sync with
  /// `react_frontend/src/config/public.ts` (`publicConfig.donateWebUrl`).
  static const String donateWebUrl = String.fromEnvironment(
    'DONATE_WEB_URL',
    defaultValue: 'https://captionary.co.zw/donate',
  );
  static const String licenseUrl = 'https://captionary.co.zw/terms';
  static const int maxModelSizeBytes = 1024 * 1024 * 1024; // 1GB
  static const int audioSampleDurationSec = 30;
  static const double storageCapacityGB = 10.0;
  static const Duration donateReminderInterval = Duration(hours: 8);
}
