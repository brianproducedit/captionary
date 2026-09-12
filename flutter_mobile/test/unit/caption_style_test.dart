import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:captionary/data/models/caption_style.dart';

void main() {
  test('copyWith updates text and color fields without dropping presets', () {
    final style = CaptionStyle(
      name: 'TikTok Bold',
      previewText: 'BOLD',
      fontSize: 28,
      boxOpacity: 0.8,
      accentColor: const Color(0xFF4CAF50),
      animationType: CaptionStyle.animationHighlight,
      targetPlatform: 'tiktok',
    );

    final next = style.copyWith(
      fontSize: 30,
      lineHeight: 1.5,
      textAlign: CaptionTextAlign.left,
      outlineWidth: 3,
      shadowBlur: 8,
      animationType: CaptionStyle.animationNone,
    );

    expect(next.name, 'TikTok Bold');
    expect(next.fontSize, 30);
    expect(next.lineHeight, 1.5);
    expect(next.textAlign, CaptionTextAlign.left);
    expect(next.outlineWidth, 3);
    expect(next.shadowBlur, 8);
    expect(next.animationType, CaptionStyle.animationNone);
    expect(next.animationAppliesAtBurnIn, isFalse);
    expect(next.localTexture.colors, isNotEmpty);
  });
}
