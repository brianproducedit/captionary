import 'dart:collection';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Single recorded memory and performance checkpoint.
class PerformanceCheckpoint {
  final String phase;
  final DateTime timestamp;
  final int rssBytes;
  final int maxRssBytes;
  final Map<String, dynamic>? metadata;

  PerformanceCheckpoint({
    required this.phase,
    required this.timestamp,
    required this.rssBytes,
    required this.maxRssBytes,
    this.metadata,
  });

  double get rssMb => rssBytes / (1024 * 1024);
  double get maxRssMb => maxRssBytes / (1024 * 1024);

  @override
  String toString() {
    final meta = (metadata != null && metadata!.isNotEmpty)
        ? ' | $metadata'
        : '';
    return '[PERF][$phase] RSS: ${rssMb.toStringAsFixed(1)}MB (peak: ${maxRssMb.toStringAsFixed(1)}MB)$meta';
  }
}

/// Tracks and logs heap/process RSS metrics across core media and pipeline phases:
/// `import`, `play`, `extract`, `model load`, `transcribe`, `unload`, and `burn-in`.
class PerformanceLogger {
  static const int maxHistorySize = 50;
  static final Queue<PerformanceCheckpoint> _history =
      Queue<PerformanceCheckpoint>();
  static void Function(String message)? onLog;

  /// Records a checkpoint for the given lifecycle [phase].
  /// Logs to `debugPrint` (and optional [onLog] handler) and retains in history.
  static PerformanceCheckpoint recordCheckpoint(
    String phase, {
    Map<String, dynamic>? metadata,
    int? rssOverride,
    int? maxRssOverride,
  }) {
    int rss = rssOverride ?? 0;
    int maxRss = maxRssOverride ?? 0;

    if (rssOverride == null || maxRssOverride == null) {
      try {
        rss = rssOverride ?? ProcessInfo.currentRss;
        maxRss = maxRssOverride ?? ProcessInfo.maxRss;
      } catch (_) {}
    }

    final checkpoint = PerformanceCheckpoint(
      phase: phase,
      timestamp: DateTime.now(),
      rssBytes: rss,
      maxRssBytes: maxRss,
      metadata: metadata,
    );

    _history.addLast(checkpoint);
    while (_history.length > maxHistorySize) {
      _history.removeFirst();
    }

    final msg = checkpoint.toString();
    debugPrint(msg);
    onLog?.call(msg);

    return checkpoint;
  }

  /// Returns an unmodifiable list of recently recorded checkpoints.
  static List<PerformanceCheckpoint> get history => List.unmodifiable(_history);

  /// Clears the checkpoint history (useful for test isolation).
  static void clearHistory() {
    _history.clear();
  }
}
