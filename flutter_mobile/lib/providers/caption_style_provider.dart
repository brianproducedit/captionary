import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import '../core/constants/caption_presets.dart';
import '../data/models/caption_style.dart';

class CaptionStyleNotifier extends StateNotifier<CaptionStyle> {
  CaptionStyleNotifier() : super(CaptionPresets.defaultStyles.first);

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

final captionStyleProvider =
    StateNotifierProvider<CaptionStyleNotifier, CaptionStyle>((ref) {
      return CaptionStyleNotifier();
    });
