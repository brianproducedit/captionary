import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:captionary/providers/trim_provider.dart';
import 'package:captionary/providers/crop_provider.dart';

void main() {
  group('TrimProvider', () {
    test('initial state defaults to disabled and zero start', () {
      final notifier = TrimNotifier();
      expect(notifier.state.isEnabled, isFalse);
      expect(notifier.state.start, Duration.zero);
      expect(notifier.state.end, isNull);
    });

    test('duration computes effective range based on totalVideoDuration', () {
      final state = const TrimState(
        start: Duration(seconds: 2),
        end: Duration(seconds: 8),
        isEnabled: true,
      );
      expect(
        state.duration(const Duration(seconds: 10)),
        const Duration(seconds: 6),
      );

      // When end is greater than total duration, clamps to total duration
      final state2 = const TrimState(
        start: Duration(seconds: 2),
        end: Duration(seconds: 20),
        isEnabled: true,
      );
      expect(
        state2.duration(const Duration(seconds: 10)),
        const Duration(seconds: 8),
      );

      // When start >= total duration, returns Duration.zero
      final state3 = const TrimState(
        start: Duration(seconds: 15),
        end: Duration(seconds: 20),
        isEnabled: true,
      );
      expect(state3.duration(const Duration(seconds: 10)), Duration.zero);
    });

    test('updateStart, updateEnd, and reset work properly', () {
      final notifier = TrimNotifier();
      notifier.updateStart(const Duration(seconds: 3));
      expect(notifier.state.start, const Duration(seconds: 3));
      expect(notifier.state.isEnabled, isTrue);

      notifier.updateEnd(const Duration(seconds: 12));
      expect(notifier.state.end, const Duration(seconds: 12));

      notifier.reset();
      expect(notifier.state.start, Duration.zero);
      expect(notifier.state.end, isNull);
      expect(notifier.state.isEnabled, isFalse);
    });
  });

  group('CropProvider', () {
    test('initial state defaults to original ratio and disabled', () {
      final notifier = CropNotifier();
      expect(notifier.state.ratio, CropAspectRatio.original);
      expect(notifier.state.isEnabled, isFalse);
      expect(notifier.state.targetRatio, isNull);
    });

    test('targetRatio and label match preset ratios', () {
      expect(CropAspectRatio.portrait916.name, 'portrait916');
      final p916 = const CropState(ratio: CropAspectRatio.portrait916);
      expect(p916.targetRatio, closeTo(9 / 16, 0.001));

      final sq = const CropState(ratio: CropAspectRatio.square11);
      expect(sq.targetRatio, 1.0);

      final l169 = const CropState(ratio: CropAspectRatio.landscape169);
      expect(l169.targetRatio, closeTo(16 / 9, 0.001));
    });

    test('setAspectRatio and setCropRect update state correctly', () {
      final notifier = CropNotifier();
      notifier.setAspectRatio(CropAspectRatio.portrait916);
      expect(notifier.state.isEnabled, isTrue);
      expect(notifier.state.ratio, CropAspectRatio.portrait916);

      const testRect = Rect.fromLTWH(0.1, 0.1, 0.8, 0.8);
      notifier.setCropRect(testRect);
      expect(notifier.state.cropRect, testRect);

      notifier.reset();
      expect(notifier.state.isEnabled, isFalse);
      expect(notifier.state.ratio, CropAspectRatio.original);
      expect(notifier.state.cropRect, isNull);
    });
  });
}
