class PreferenceKeys {
  static const autoPlay = 'captionary_auto_play';
  static const playbackSpeed = 'captionary_playback_speed';
  static const volume = 'captionary_volume';
  static const exportQuality = 'captionary_export_quality';
  static const exportFormat = 'captionary_export_format';
  static const ramTier = 'captionary_ram_tier';
}

class UserPreferences {
  static const ramTiers = [
    'Auto',
    'High (6GB+)',
    'Standard (4GB)',
    'Low (<4GB)',
  ];
  static const exportQualities = ['720p', '1080p', '1440p'];
  static const exportFormats = ['srt', 'vtt'];
  static const playbackSpeeds = [0.5, 1.0, 1.25, 1.5, 2.0];

  static const defaults = UserPreferences(
    autoPlay: false,
    playbackSpeed: 1.0,
    volume: 1.0,
    exportQuality: '1080p',
    exportFormat: 'srt',
    ramTier: 'Auto',
  );

  final bool autoPlay;
  final double playbackSpeed;
  final double volume;
  final String exportQuality;
  final String exportFormat;
  final String ramTier;

  const UserPreferences({
    required this.autoPlay,
    required this.playbackSpeed,
    required this.volume,
    required this.exportQuality,
    required this.exportFormat,
    required this.ramTier,
  });

  UserPreferences copyWith({
    bool? autoPlay,
    double? playbackSpeed,
    double? volume,
    String? exportQuality,
    String? exportFormat,
    String? ramTier,
  }) {
    return UserPreferences(
      autoPlay: autoPlay ?? this.autoPlay,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      volume: volume ?? this.volume,
      exportQuality: exportQuality ?? this.exportQuality,
      exportFormat: exportFormat ?? this.exportFormat,
      ramTier: ramTier ?? this.ramTier,
    );
  }
}

class AppPackageInfo {
  static const fallback = AppPackageInfo(version: '1.0.0', buildNumber: '1');

  final String version;
  final String buildNumber;

  const AppPackageInfo({required this.version, required this.buildNumber});

  String get label => '$version+$buildNumber';
}
