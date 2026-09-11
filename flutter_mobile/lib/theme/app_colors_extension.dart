import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color surface;
  final Color surfaceContainerLow;
  final Color primary;
  final Color accentAmber;
  final Color baseCanvas;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color surfaceContainerHigh;
  final Color outline;

  const AppColorsExtension({
    required this.surface,
    required this.surfaceContainerLow,
    required this.primary,
    required this.accentAmber,
    required this.baseCanvas,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.surfaceContainerHigh,
    required this.outline,
  });

  @override
  ThemeExtension<AppColorsExtension> copyWith({
    Color? surface,
    Color? surfaceContainerLow,
    Color? primary,
    Color? accentAmber,
    Color? baseCanvas,
    Color? onSurface,
    Color? onSurfaceVariant,
    Color? surfaceContainerHigh,
    Color? outline,
  }) {
    return AppColorsExtension(
      surface: surface ?? this.surface,
      surfaceContainerLow: surfaceContainerLow ?? this.surfaceContainerLow,
      primary: primary ?? this.primary,
      accentAmber: accentAmber ?? this.accentAmber,
      baseCanvas: baseCanvas ?? this.baseCanvas,
      onSurface: onSurface ?? this.onSurface,
      onSurfaceVariant: onSurfaceVariant ?? this.onSurfaceVariant,
      surfaceContainerHigh: surfaceContainerHigh ?? this.surfaceContainerHigh,
      outline: outline ?? this.outline,
    );
  }

  @override
  ThemeExtension<AppColorsExtension> lerp(ThemeExtension<AppColorsExtension>? other, double t) {
    if (other is! AppColorsExtension) {
      return this;
    }
    return AppColorsExtension(
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceContainerLow: Color.lerp(surfaceContainerLow, other.surfaceContainerLow, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      accentAmber: Color.lerp(accentAmber, other.accentAmber, t)!,
      baseCanvas: Color.lerp(baseCanvas, other.baseCanvas, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      onSurfaceVariant: Color.lerp(onSurfaceVariant, other.onSurfaceVariant, t)!,
      surfaceContainerHigh: Color.lerp(surfaceContainerHigh, other.surfaceContainerHigh, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
    );
  }

  static const AppColorsExtension defaultTheme = AppColorsExtension(
    surface: AppColors.surface,
    surfaceContainerLow: AppColors.surfaceContainerLow,
    primary: AppColors.primary,
    accentAmber: AppColors.accentAmber,
    baseCanvas: AppColors.baseCanvas,
    onSurface: AppColors.onSurface,
    onSurfaceVariant: AppColors.onSurfaceVariant,
    surfaceContainerHigh: AppColors.surfaceContainerHigh,
    outline: AppColors.outline,
  );
}
