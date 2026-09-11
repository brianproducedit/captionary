import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:captionary/core/ad_placement_policy.dart';
import 'package:captionary/widgets/ad_banner_widget.dart';

void main() {
  testWidgets('AdBannerWidget renders local placeholder label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AdBannerWidget())),
    );

    expect(find.text(AdBannerWidget.placeholderLabel), findsOneWidget);
    expect(find.textContaining('Google AdMob'), findsNothing);
    expect(find.textContaining('Ad Space'), findsNothing);
  });

  testWidgets('AdBannerWidget has correct default height', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AdBannerWidget())),
    );

    final renderBox = tester.renderObject<RenderBox>(
      find.byType(AdBannerWidget),
    );
    expect(renderBox.size.height, AdBannerWidget.defaultHeight);
  });

  testWidgets('AdBannerWidget accepts custom height', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AdBannerWidget(bannerHeight: 90.0)),
      ),
    );

    final renderBox = tester.renderObject<RenderBox>(
      find.byType(AdBannerWidget),
    );
    expect(renderBox.size.height, 90.0);
  });

  test('AdPlacementPolicy allows only language packs and export', () {
    expect(AdPlacementPolicy.allows('/languages'), isTrue);
    expect(AdPlacementPolicy.allows('/export'), isTrue);
    expect(AdPlacementPolicy.allows('/library'), isFalse);
    expect(AdPlacementPolicy.allows('/player'), isFalse);
    expect(AdPlacementPolicy.allows('/studio'), isFalse);
    expect(AdPlacementPolicy.allows('/donate'), isFalse);
  });
}
