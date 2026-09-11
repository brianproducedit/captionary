import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// CustomPainter that draws an audio waveform visualization.
///
/// Renders vertical bars with varying heights based on a deterministic
/// seed-based pattern. Bars before the playhead are colored with a
/// gradient from primaryContainer → primary → secondary. Bars after
/// the playhead are dimmed.
class WaveformPainter extends CustomPainter {
  /// The playback progress from 0.0 to 1.0.
  final double progress;

  /// The number of bars to render.
  final int barCount;

  /// Optional seed for deterministic waveform shape.
  final int seed;

  WaveformPainter({
    required this.progress,
    this.barCount = 60,
    this.seed = 42,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(seed);
    final barWidth = size.width / (barCount * 1.6);
    final gap = barWidth * 0.6;
    final totalBarWidth = barWidth + gap;
    final playheadX = size.width * progress;

    // Pre-generate heights so they're deterministic.
    final heights = List.generate(barCount, (_) => 0.15 + random.nextDouble() * 0.85);

    for (int i = 0; i < barCount; i++) {
      final x = i * totalBarWidth;
      final barHeight = heights[i] * size.height;
      final y = (size.height - barHeight) / 2;
      final isPast = x + barWidth <= playheadX;
      final isPlayhead = x <= playheadX && x + barWidth > playheadX;

      Color barColor;
      if (isPast || isPlayhead) {
        // Gradient based on position: primaryContainer → primary → secondary
        final t = i / barCount;
        if (t < 0.5) {
          barColor = Color.lerp(
            AppColors.primaryContainer,
            AppColors.primary,
            t * 2,
          )!;
        } else {
          barColor = Color.lerp(
            AppColors.primary,
            AppColors.secondary,
            (t - 0.5) * 2,
          )!;
        }
      } else {
        barColor = AppColors.surfaceContainerHigh;
      }

      final paint = Paint()
        ..color = barColor
        ..style = PaintingStyle.fill;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        const Radius.circular(1.5),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.barCount != barCount ||
        oldDelegate.seed != seed;
  }
}
