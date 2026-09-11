import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_radius.dart';
import 'app_colors_extension.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.baseCanvas,
      extensions: const <ThemeExtension<dynamic>>[
        AppColorsExtension.defaultTheme,
      ],
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.onSecondaryContainer,
        tertiary: AppColors.tertiary,
        onTertiary: AppColors.onTertiary,
        tertiaryContainer: AppColors.tertiaryContainer,
        onTertiaryContainer: AppColors.onTertiaryContainer,
        error: AppColors.error,
        onError: AppColors.onError,
        errorContainer: AppColors.errorContainer,
        onErrorContainer: AppColors.onErrorContainer,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        surfaceContainerHighest: AppColors.surfaceVariant,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
      ),
      fontFamily: 'Lexend',
      textTheme: const TextTheme(
        displayLarge: AppTypography.displayLg,
        headlineLarge: AppTypography.headlineXl,
        headlineMedium: AppTypography.headlineMd,
        headlineSmall: AppTypography.headlineSm,
        bodyLarge: AppTypography.bodyLg,
        bodyMedium: AppTypography.bodyMd,
        bodySmall: AppTypography.bodySm,
        labelLarge: AppTypography.labelLg,
        labelMedium: AppTypography.labelMd,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainerLow,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.defaultRadius),
          side: const BorderSide(color: AppColors.surfaceBorder, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.baseCanvas,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: 'Lexend',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontVariations: [FontVariation('wght', 600)],
          color: AppColors.onSurface,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          textStyle: const TextStyle(
            fontFamily: 'Lexend',
            fontWeight: FontWeight.w500,
            fontVariations: [FontVariation('wght', 500)],
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          textStyle: const TextStyle(
            fontFamily: 'Lexend',
            fontWeight: FontWeight.w500,
            fontVariations: [FontVariation('wght', 500)],
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: const TextStyle(
            fontFamily: 'Lexend',
            fontWeight: FontWeight.w500,
            fontVariations: [FontVariation('wght', 500)],
          ),
        ),
      ),
      chipTheme: const ChipThemeData(
        labelStyle: TextStyle(
          fontFamily: 'Lexend',
          fontVariations: [FontVariation('wght', 400)],
        ),
      ),
      dialogTheme: const DialogThemeData(
        titleTextStyle: TextStyle(
          fontFamily: 'Lexend',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontVariations: [FontVariation('wght', 600)],
          color: AppColors.onSurface,
        ),
        contentTextStyle: TextStyle(
          fontFamily: 'Lexend',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          fontVariations: [FontVariation('wght', 400)],
          color: AppColors.onSurfaceVariant,
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        contentTextStyle: TextStyle(
          fontFamily: 'Lexend',
          fontVariations: [FontVariation('wght', 400)],
        ),
      ),
    );
  }
}
