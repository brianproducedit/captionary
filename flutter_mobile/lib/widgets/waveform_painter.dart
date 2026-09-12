import 'package:flutter/material.dart';

import '../core/waveform_data.dart';
import '../theme/app_colors.dart';

/// Draws [WaveformData] peaks. Empty or fallback states paint nothing;
/// the parent must label that this is not audio.
class WaveformPainter extends CustomPainter {
  final double progress;
  final List<double> peaks;

  WaveformPainter({required this.progress, required this.peaks});

  @override
  void paint(Canvas canvas, Size size) {
    if (peaks.isEmpty || size.width <= 0 || size.height <= 0) return;

    final barCount = peaks.length;
    final barWidth = size.width / (barCount * 1.6);
    final gap = barWidth * 0.6;
    final totalBarWidth = barWidth + gap;
    final playheadX = size.width * progress.clamp(0.0, 1.0);

    for (var i = 0; i < barCount; i++) {
      final x = i * totalBarWidth;
      final amplitude = peaks[i].clamp(0.05, 1.0);
      final barHeight = amplitude * size.height;
      final y = (size.height - barHeight) / 2;
      final isPast = x + barWidth <= playheadX;

      Color barColor;
      if (isPast) {
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

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, barHeight),
          const Radius.circular(1.5),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.peaks != peaks;
  }
}
