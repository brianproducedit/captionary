import 'package:flutter/material.dart';

class AppTypography {
  static const String _fontFamily = 'Lexend';

  static const TextStyle displayLg = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 48,
    height: 56 / 48,
    letterSpacing: -0.02 * 48,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation('wght', 700)],
  );

  static const TextStyle displayLgMobile = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 32,
    height: 40 / 32,
    letterSpacing: -0.01 * 32,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation('wght', 700)],
  );

  static const TextStyle headlineXl = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 36,
    height: 44 / 36,
    letterSpacing: -0.01 * 36,
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation('wght', 600)],
  );

  static const TextStyle headlineXlMobile = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 26,
    height: 34 / 26,
    letterSpacing: 0,
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation('wght', 600)],
  );

  static const TextStyle headlineMd = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    height: 32 / 24,
    letterSpacing: 0,
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation('wght', 600)],
  );

  static const TextStyle headlineSm = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    height: 28 / 20,
    letterSpacing: 0,
    fontWeight: FontWeight.w500,
    fontVariations: [FontVariation('wght', 500)],
  );

  static const TextStyle bodyLg = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    height: 24 / 16,
    letterSpacing: 0.01 * 16,
    fontWeight: FontWeight.w400,
    fontVariations: [FontVariation('wght', 400)],
  );

  static const TextStyle bodyMd = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    height: 20 / 14,
    letterSpacing: 0.01 * 14,
    fontWeight: FontWeight.w400,
    fontVariations: [FontVariation('wght', 400)],
  );

  static const TextStyle bodySm = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    height: 16 / 12,
    letterSpacing: 0.02 * 12,
    fontWeight: FontWeight.w300,
    fontVariations: [FontVariation('wght', 300)],
  );

  static const TextStyle labelLg = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    height: 20 / 14,
    letterSpacing: 0.02 * 14,
    fontWeight: FontWeight.w500,
    fontVariations: [FontVariation('wght', 500)],
  );

  static const TextStyle labelMd = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    height: 16 / 12,
    letterSpacing: 0.03 * 12,
    fontWeight: FontWeight.w500,
    fontVariations: [FontVariation('wght', 500)],
  );

  static const TextStyle captionCode = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    height: 14 / 11,
    letterSpacing: 0.04 * 11,
    fontWeight: FontWeight.w400,
    fontVariations: [FontVariation('wght', 400)],
  );
}

extension CustomTextTheme on TextTheme {
  TextStyle get captionCode => AppTypography.captionCode;
}
