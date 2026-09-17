import 'package:flutter_test/flutter_test.dart';
import 'package:captionary/core/performance_logger.dart';

void main() {
  setUp(() {
    PerformanceLogger.clearHistory();
    PerformanceLogger.onLog = null;
  });

  tearDown(() {
    PerformanceLogger.clearHistory();
    PerformanceLogger.onLog = null;
  });

  group('PerformanceLogger', () {
    test('records and formats checkpoints across all 7 lifecycle phases', () {
      const phases = [
        'import',
        'play',
        'extract',
        'model load',
        'transcribe',
        'unload',
        'burn-in',
      ];

      for (final phase in phases) {
        final cp = PerformanceLogger.recordCheckpoint(
          phase,
          metadata: {'test': true},
          rssOverride: 100 * 1024 * 1024,
          maxRssOverride: 150 * 1024 * 1024,
        );

        expect(cp.phase, phase);
        expect(cp.rssMb, closeTo(100.0, 0.1));
        expect(cp.maxRssMb, closeTo(150.0, 0.1));
        expect(cp.toString(), contains('[PERF][$phase]'));
        expect(cp.toString(), contains('RSS: 100.0MB'));
        expect(cp.toString(), contains('peak: 150.0MB'));
        expect(cp.toString(), contains('{test: true}'));
      }

      expect(PerformanceLogger.history.length, 7);
    });

    test('invokes onLog callback when provided', () {
      final logs = <String>[];
      PerformanceLogger.onLog = (msg) => logs.add(msg);

      PerformanceLogger.recordCheckpoint(
        'model load',
        rssOverride: 50 * 1024 * 1024,
        maxRssOverride: 80 * 1024 * 1024,
      );

      expect(logs.length, 1);
      expect(logs.first, contains('[PERF][model load]'));
    });

    test('caps history at maxHistorySize (50)', () {
      for (int i = 0; i < 60; i++) {
        PerformanceLogger.recordCheckpoint(
          'transcribe',
          metadata: {'iteration': i},
          rssOverride: 10 * 1024 * 1024,
          maxRssOverride: 20 * 1024 * 1024,
        );
      }

      expect(PerformanceLogger.history.length, PerformanceLogger.maxHistorySize);
      // The oldest 10 items should have been discarded (first remaining iteration is 10)
      expect(PerformanceLogger.history.first.metadata?['iteration'], 10);
      expect(PerformanceLogger.history.last.metadata?['iteration'], 59);
    });

    test('clearHistory removes all recorded checkpoints', () {
      PerformanceLogger.recordCheckpoint(
        'import',
        rssOverride: 10 * 1024 * 1024,
        maxRssOverride: 20 * 1024 * 1024,
      );
      expect(PerformanceLogger.history, isNotEmpty);

      PerformanceLogger.clearHistory();
      expect(PerformanceLogger.history, isEmpty);
    });
  });
}
