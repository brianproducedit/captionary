import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:captionary/data/models/caption_style.dart';

void main() {
  group('CaptionStyle Tests', () {
    test('should create a valid CaptionStyle', () {
      final style = CaptionStyle(
        name: 'Style1',
        previewText: 'Preview',
        fontSize: 24.0,
        boxOpacity: 0.5,
        accentColor: Colors.red,
        animationType: 'bounce',
        targetPlatform: 'generic',
      );

      expect(style.name, 'Style1');
      expect(style.fontSize, 24.0);
      expect(style.accentColor, Colors.red);
    });
  });
}
