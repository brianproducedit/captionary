import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppGradients {
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [
      AppColors.primaryContainer,
      AppColors.secondaryContainer,
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient extendedGradient = LinearGradient(
    colors: [
      AppColors.primaryContainer,
      AppColors.primary,
      AppColors.secondaryContainer,
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient scrubberProgress = LinearGradient(
    colors: [
      AppColors.primaryContainer,
      AppColors.primary,
      AppColors.secondary,
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const RadialGradient ambientBackgroundGlow = RadialGradient(
    colors: [
      Color(0x332196F3), // primary-container/20
      Color(0x3386039C), // secondary-container/20
      Color(0x00000000), // transparent
    ],
    radius: 0.8,
  );

  static const LinearGradient heroMesh = LinearGradient(
    colors: [AppColors.gradientStart, AppColors.gradientEnd, Color(0xFF0F3460)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warmAccent = LinearGradient(
    colors: [AppColors.warmCoral, AppColors.warmAmber],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient creatorGlow = LinearGradient(
    colors: [AppColors.deepViolet, AppColors.electricCyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
