import 'package:flutter/material.dart';

import '../../data/models/caption_style.dart';
import '../../theme/app_colors.dart';

/// Standard preset caption styles available in Captionary.
class CaptionPresets {
  static final List<CaptionStyle> defaultStyles = [
    CaptionStyle(
      name: 'TikTok Bold',
      previewText: 'BOLD & LOUD',
      fontSize: 28.0,
      lineHeight: 1.1,
      boxOpacity: 0.8,
      accentColor: const Color(0xFF4CAF50),
      outlineWidth: 2.0,
      shadowBlur: 0,
      animationType: CaptionStyle.animationHighlight,
      targetPlatform: 'tiktok',
    ),
    CaptionStyle(
      name: 'IG Highlight',
      previewText: 'Clean Highlight',
      fontSize: 24.0,
      lineHeight: 1.3,
      boxOpacity: 0.5,
      accentColor: const Color(0xFFFFC107),
      outlineWidth: 0,
      shadowBlur: 6,
      animationType: CaptionStyle.animationBounce,
      targetPlatform: 'instagram',
    ),
    CaptionStyle(
      name: 'Classic Movie',
      previewText: 'Cinematic Subtitles',
      fontSize: 20.0,
      lineHeight: 1.35,
      boxOpacity: 0.0,
      accentColor: AppColors.allWhite,
      outlineWidth: 1.5,
      outlineColor: const Color(0xFF000000),
      shadowBlur: 8,
      animationType: CaptionStyle.animationMinimal,
      targetPlatform: 'generic',
    ),
    CaptionStyle(
      name: 'Neon Flow',
      previewText: 'Electric Flow',
      fontSize: 26.0,
      lineHeight: 1.2,
      boxOpacity: 0.7,
      accentColor: const Color(0xFF2196F3),
      outlineWidth: 0,
      shadowBlur: 10,
      animationType: CaptionStyle.animationKaraoke,
      animationIntensity: 0.8,
      targetPlatform: 'youtube',
    ),
  ];
}
