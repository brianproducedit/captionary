import 'package:flutter/material.dart';

enum SubtitlePosition { top, center, bottom, custom }

enum CaptionTextAlign { left, center, right }

extension CaptionTextAlignX on CaptionTextAlign {
  TextAlign get asTextAlign {
    switch (this) {
      case CaptionTextAlign.left:
        return TextAlign.left;
      case CaptionTextAlign.center:
        return TextAlign.center;
      case CaptionTextAlign.right:
        return TextAlign.right;
    }
  }
}

class CaptionStyle {
  static const String fontFamily = 'Lexend';

  static const String animationNone = 'none';
  static const String animationBounce = 'bounce';
  static const String animationHighlight = 'highlight';
  static const String animationKaraoke = 'karaoke';
  static const String animationMinimal = 'minimal';

  static const List<String> animationTypes = [
    animationNone,
    animationBounce,
    animationHighlight,
    animationKaraoke,
    animationMinimal,
  ];

  final String name;
  final String previewText;
  final double fontSize;
  final double lineHeight;
  final CaptionTextAlign textAlign;
  final double boxOpacity;
  final Color accentColor;
  final double outlineWidth;
  final Color outlineColor;
  final double shadowBlur;
  final Color shadowColor;
  final String animationType;
  final double animationIntensity;
  final String targetPlatform;
  final SubtitlePosition position;
  final double customY;

  CaptionStyle({
    required this.name,
    required this.previewText,
    required this.fontSize,
    required this.boxOpacity,
    required this.accentColor,
    required this.animationType,
    required this.targetPlatform,
    this.lineHeight = 1.2,
    this.textAlign = CaptionTextAlign.center,
    this.outlineWidth = 0,
    this.outlineColor = const Color(0xFF000000),
    this.shadowBlur = 4,
    this.shadowColor = const Color(0xFF000000),
    this.animationIntensity = 0.5,
    this.position = SubtitlePosition.bottom,
    this.customY = 0.0,
  });

  bool get animationAppliesAtBurnIn => false;

  LinearGradient get localTexture {
    switch (targetPlatform) {
      case 'tiktok':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D1F12), Color(0xFF1B5E20)],
        );
      case 'instagram':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3D1A00), Color(0xFF6A1B9A)],
        );
      case 'generic':
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF141414), Color(0xFF3A3A3A)],
        );
      default:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF061428), Color(0xFF1565C0)],
        );
    }
  }

  CaptionStyle copyWith({
    String? name,
    String? previewText,
    double? fontSize,
    double? lineHeight,
    CaptionTextAlign? textAlign,
    double? boxOpacity,
    Color? accentColor,
    double? outlineWidth,
    Color? outlineColor,
    double? shadowBlur,
    Color? shadowColor,
    String? animationType,
    double? animationIntensity,
    String? targetPlatform,
    SubtitlePosition? position,
    double? customY,
  }) {
    return CaptionStyle(
      name: name ?? this.name,
      previewText: previewText ?? this.previewText,
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      textAlign: textAlign ?? this.textAlign,
      boxOpacity: boxOpacity ?? this.boxOpacity,
      accentColor: accentColor ?? this.accentColor,
      outlineWidth: outlineWidth ?? this.outlineWidth,
      outlineColor: outlineColor ?? this.outlineColor,
      shadowBlur: shadowBlur ?? this.shadowBlur,
      shadowColor: shadowColor ?? this.shadowColor,
      animationType: animationType ?? this.animationType,
      animationIntensity: animationIntensity ?? this.animationIntensity,
      targetPlatform: targetPlatform ?? this.targetPlatform,
      position: position ?? this.position,
      customY: customY ?? this.customY,
    );
  }
}
