import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_colors.dart';

class ShimmerPlaceholder extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final Color baseColor;
  final Color highlightColor;

  const ShimmerPlaceholder({
    super.key,
    this.width = double.infinity,
    this.height = 100.0,
    this.borderRadius = 12.0,
    this.baseColor = AppColors.surfaceContainerHigh,
    this.highlightColor = AppColors.surfaceContainerHighest,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .shimmer(
          duration: const Duration(milliseconds: 1500),
          color: highlightColor,
        );
  }
}
