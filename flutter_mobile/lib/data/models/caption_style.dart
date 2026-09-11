import 'package:flutter/material.dart';

enum SubtitlePosition { top, center, bottom, custom }

class CaptionStyle {
  final String name;
  final String previewText;
  final double fontSize;
  final double boxOpacity;
  final Color accentColor;
  final String animationType; // bounce, highlight, karaoke, minimal
  final String targetPlatform; // tiktok, instagram, youtube, generic
  final SubtitlePosition position;
  final double customY; // For custom drag positions

  CaptionStyle({
    required this.name,
    required this.previewText,
    required this.fontSize,
    required this.boxOpacity,
    required this.accentColor,
    required this.animationType,
    required this.targetPlatform,
    this.position = SubtitlePosition.bottom,
    this.customY = 0.0,
  });

  CaptionStyle copyWith({
    String? name,
    String? previewText,
    double? fontSize,
    double? boxOpacity,
    Color? accentColor,
    String? animationType,
    String? targetPlatform,
    SubtitlePosition? position,
    double? customY,
  }) {
    return CaptionStyle(
      name: name ?? this.name,
      previewText: previewText ?? this.previewText,
      fontSize: fontSize ?? this.fontSize,
      boxOpacity: boxOpacity ?? this.boxOpacity,
      accentColor: accentColor ?? this.accentColor,
      animationType: animationType ?? this.animationType,
      targetPlatform: targetPlatform ?? this.targetPlatform,
      position: position ?? this.position,
      customY: customY ?? this.customY,
    );
  }
}
