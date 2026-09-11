class AppConstants {
  static const String r2BaseUrl = 'https://pub-xxxx.r2.dev';
  static const String manifestUrl = '$r2BaseUrl/manifest.json';
  static const String donateWebUrl = 'https://captionary.co.zw/donate';
  static const int maxModelSizeBytes = 1024 * 1024 * 1024; // 1GB
  static const int audioSampleDurationSec = 30;
  static const double storageCapacityGB = 10.0;
  static const Duration donateReminderInterval = Duration(hours: 8);
}
