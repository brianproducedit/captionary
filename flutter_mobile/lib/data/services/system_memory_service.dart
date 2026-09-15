import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Device RAM tiers based on measured physical RAM (accounting for kernel/GPU carve-outs).
/// - low: < 3.8 GB (e.g., 2 GB - 3 GB devices)
/// - standard: 3.8 GB - 5.8 GB (e.g., 4 GB devices)
/// - high: >= 5.8 GB (e.g., 6 GB, 8 GB, 12 GB devices)
enum DeviceRamTier { low, standard, high }

/// Snapshot of system and process memory metrics.
class SystemMemoryInfo {
  final int totalRamBytes;
  final int availableRamBytes;
  final int thresholdBytes;
  final bool isLowMemory;
  final int currentRssBytes;
  final int maxRssBytes;

  const SystemMemoryInfo({
    required this.totalRamBytes,
    required this.availableRamBytes,
    required this.thresholdBytes,
    required this.isLowMemory,
    required this.currentRssBytes,
    required this.maxRssBytes,
  });

  /// Device RAM tier computed using hardware carve-out thresholds:
  /// - Low: < 3.8 GB (< 4,080,218,931 bytes)
  /// - Standard: 3.8 GB - 5.8 GB
  /// - High: >= 5.8 GB (>= 6,227,702,579 bytes)
  DeviceRamTier get tier {
    const lowTierThresholdBytes = 3800 * 1024 * 1024; // ~3.71 GiB / 3.8 GB
    const highTierThresholdBytes = 5800 * 1024 * 1024; // ~5.66 GiB / 5.8 GB

    if (totalRamBytes < lowTierThresholdBytes) {
      return DeviceRamTier.low;
    } else if (totalRamBytes < highTierThresholdBytes) {
      return DeviceRamTier.standard;
    } else {
      return DeviceRamTier.high;
    }
  }

  double get totalRamGb => totalRamBytes / (1024 * 1024 * 1024);
  double get availableRamGb => availableRamBytes / (1024 * 1024 * 1024);
  double get currentRssMb => currentRssBytes / (1024 * 1024);
  double get maxRssMb => maxRssBytes / (1024 * 1024);

  @override
  String toString() =>
      'SystemMemoryInfo(total: ${totalRamGb.toStringAsFixed(1)}GB, '
      'available: ${availableRamGb.toStringAsFixed(1)}GB, '
      'tier: ${tier.name}, '
      'lowMemory: $isLowMemory, '
      'rss: ${currentRssMb.toStringAsFixed(1)}MB)';
}

/// Service providing platform memory metrics, tier categorization, and
/// safety guards against out-of-memory (OOM) crashes.
class SystemMemoryService {
  static const MethodChannel _defaultChannel = MethodChannel(
    'com.captionary.captionary/system_memory',
  );

  final MethodChannel _channel;
  final int? _overrideTotalRamBytes;
  final int? _overrideAvailableRamBytes;
  final bool? _overrideLowMemory;

  const SystemMemoryService({
    this._channel = _defaultChannel,
    this._overrideTotalRamBytes,
    this._overrideAvailableRamBytes,
    this._overrideLowMemory,
  });

  /// Fetches the latest system memory snapshot.
  Future<SystemMemoryInfo> getMemoryInfo() async {
    int totalMem = _overrideTotalRamBytes ?? (4096 * 1024 * 1024);
    int availMem = _overrideAvailableRamBytes ?? (2048 * 1024 * 1024);
    int threshold = 500 * 1024 * 1024;
    bool isLowMem = _overrideLowMemory ?? false;

    if (_overrideTotalRamBytes == null || _overrideAvailableRamBytes == null) {
      try {
        final result = await _channel.invokeMapMethod<String, dynamic>(
          'getMemoryInfo',
        );
        if (result != null) {
          if (_overrideTotalRamBytes == null && result['totalMem'] != null) {
            totalMem = (result['totalMem'] as num).toInt();
          }
          if (_overrideAvailableRamBytes == null &&
              result['availMem'] != null) {
            availMem = (result['availMem'] as num).toInt();
          }
          if (_overrideLowMemory == null && result['lowMemory'] != null) {
            isLowMem = result['lowMemory'] as bool;
          }
          if (result['threshold'] != null) {
            threshold = (result['threshold'] as num).toInt();
          }
        }
      } catch (e) {
        // Fallback gracefully on desktop / testing environments
        debugPrint('SystemMemoryService: platform query note: $e');
      }
    }

    int currentRss = 0;
    int maxRss = 0;
    try {
      currentRss = ProcessInfo.currentRss;
      maxRss = ProcessInfo.maxRss;
    } catch (_) {}

    return SystemMemoryInfo(
      totalRamBytes: totalMem,
      availableRamBytes: availMem,
      thresholdBytes: threshold,
      isLowMemory: isLowMem,
      currentRssBytes: currentRss,
      maxRssBytes: maxRss,
    );
  }

  /// Evaluates whether the system has sufficient available RAM to safely load and run
  /// a given model without risking an OOM kill.
  bool canSafelyRunModel({
    required String modelNameOrPath,
    required SystemMemoryInfo memoryInfo,
  }) {
    if (memoryInfo.isLowMemory) {
      return false;
    }

    final lower = modelNameOrPath.toLowerCase();
    final int requiredBytes;

    if (lower.contains('tiny')) {
      requiredBytes = 150 * 1024 * 1024; // 150 MB
    } else if (lower.contains('base')) {
      requiredBytes = 300 * 1024 * 1024; // 300 MB
    } else if (lower.contains('small')) {
      requiredBytes = 750 * 1024 * 1024; // 750 MB
    } else if (lower.contains('medium')) {
      requiredBytes = 1500 * 1024 * 1024; // 1.5 GB
    } else if (lower.contains('large')) {
      requiredBytes = 2500 * 1024 * 1024; // 2.5 GB
    } else {
      requiredBytes = 300 * 1024 * 1024; // Standard fallback
    }

    return memoryInfo.availableRamBytes >= requiredBytes;
  }

  /// Minimum recommended RAM in GB for a model name or path.
  static int recommendedRamGbForModel(String modelNameOrPath) {
    final lower = modelNameOrPath.toLowerCase();
    if (lower.contains('tiny')) return 2;
    if (lower.contains('base')) return 4;
    if (lower.contains('small')) return 4;
    if (lower.contains('medium')) return 6;
    if (lower.contains('large')) return 8;
    return 4;
  }
}
