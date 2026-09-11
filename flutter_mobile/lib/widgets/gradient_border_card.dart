import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GradientBorderCard extends StatelessWidget {
  final Widget child;
  final Gradient borderGradient;
  final Color backgroundColor;
  final double borderRadius;
  final double borderWidth;
  final EdgeInsetsGeometry padding;

  const GradientBorderCard({
    super.key,
    required this.child,
    required this.borderGradient,
    this.backgroundColor = AppColors.cardElevated,
    this.borderRadius = 16.0,
    this.borderWidth = 2.0,
    this.padding = const EdgeInsets.all(16.0),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: borderGradient,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      padding: EdgeInsets.all(borderWidth),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(borderRadius - borderWidth / 2),
        ),
        padding: padding,
        child: child,
      ),
    );
  }
}
