import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../data/models/caption_style.dart';
import '../data/mock/seed_data.dart';

class CaptionStyleNotifier extends StateNotifier<CaptionStyle> {
  CaptionStyleNotifier() : super(SeedData.captionStyles.first);

  void setStyle(CaptionStyle style) {
    state = style;
  }
  
  void updateStyle(CaptionStyle style) {
    state = style;
  }

  void updateFontSize(double size) {
    state = state.copyWith(fontSize: size);
  }

  void updateBoxOpacity(double opacity) {
    state = state.copyWith(boxOpacity: opacity);
  }

  void updateAccentColor(Color color) {
    state = state.copyWith(accentColor: color);
  }
}

final captionStyleProvider = StateNotifierProvider<CaptionStyleNotifier, CaptionStyle>((ref) {
  return CaptionStyleNotifier();
});
