import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CropAspectRatio { original, portrait916, square11, social45, landscape169 }

class CropState {
  final CropAspectRatio ratio;
  final Rect? cropRect; // normalized 0.0 - 1.0 rect
  final bool isEnabled;

  const CropState({
    this.ratio = CropAspectRatio.original,
    this.cropRect,
    this.isEnabled = false,
  });

  double? get targetRatio {
    switch (ratio) {
      case CropAspectRatio.original:
        return null;
      case CropAspectRatio.portrait916:
        return 9 / 16;
      case CropAspectRatio.square11:
        return 1 / 1;
      case CropAspectRatio.social45:
        return 4 / 5;
      case CropAspectRatio.landscape169:
        return 16 / 9;
    }
  }

  String get label {
    switch (ratio) {
      case CropAspectRatio.original:
        return 'Original';
      case CropAspectRatio.portrait916:
        return '9:16 (TikTok/Reels)';
      case CropAspectRatio.square11:
        return '1:1 (Square)';
      case CropAspectRatio.social45:
        return '4:5 (Portrait)';
      case CropAspectRatio.landscape169:
        return '16:9 (Landscape)';
    }
  }

  CropState copyWith({
    CropAspectRatio? ratio,
    Rect? cropRect,
    bool? isEnabled,
  }) {
    return CropState(
      ratio: ratio ?? this.ratio,
      cropRect: cropRect ?? this.cropRect,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}

class CropNotifier extends StateNotifier<CropState> {
  CropNotifier() : super(const CropState());

  void setAspectRatio(CropAspectRatio ratio) {
    state = state.copyWith(
      ratio: ratio,
      isEnabled: ratio != CropAspectRatio.original,
    );
  }

  void setCropRect(Rect rect) {
    state = state.copyWith(cropRect: rect, isEnabled: true);
  }

  void reset() {
    state = const CropState();
  }

  void toggleEnabled() {
    state = state.copyWith(isEnabled: !state.isEnabled);
  }
}

final cropProvider = StateNotifierProvider<CropNotifier, CropState>((ref) {
  return CropNotifier();
});
