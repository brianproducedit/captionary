import '../services/system_memory_service.dart';

enum PlaybackQuality { auto, p360, p480, p720, original }

extension PlaybackQualityExt on PlaybackQuality {
  String get label {
    switch (this) {
      case PlaybackQuality.auto:
        return 'Auto (RAM Optimized)';
      case PlaybackQuality.p360:
        return '360p (Low RAM)';
      case PlaybackQuality.p480:
        return '480p (Balanced)';
      case PlaybackQuality.p720:
        return '720p (High)';
      case PlaybackQuality.original:
        return 'Original (Full)';
    }
  }

  String get shortLabel {
    switch (this) {
      case PlaybackQuality.auto:
        return 'Auto';
      case PlaybackQuality.p360:
        return '360p';
      case PlaybackQuality.p480:
        return '480p';
      case PlaybackQuality.p720:
        return '720p';
      case PlaybackQuality.original:
        return 'Orig';
    }
  }

  int? get targetHeight {
    switch (this) {
      case PlaybackQuality.auto:
        return null;
      case PlaybackQuality.p360:
        return 360;
      case PlaybackQuality.p480:
        return 480;
      case PlaybackQuality.p720:
        return 720;
      case PlaybackQuality.original:
        return null;
    }
  }

  int? resolveMaxResolution(SystemMemoryInfo? memInfo) {
    if (this != PlaybackQuality.auto) {
      return targetHeight;
    }
    if (memInfo == null) return 480;
    switch (memInfo.tier) {
      case DeviceRamTier.low:
        return 360;
      case DeviceRamTier.standard:
        return 480;
      case DeviceRamTier.high:
        return 720;
    }
  }
}
