import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:captionary/core/ad_placement_policy.dart';
import 'package:captionary/widgets/ad_banner_widget.dart';

void main() {
  testWidgets(
    'AdBannerWidget renders placeholder fallback in test environment',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: AdBannerWidget())),
        ),
      );
      await tester.pump();

      // In test environment (non-mobile), the fallback placeholder is shown
      expect(find.text(AdBannerWidget.placeholderLabel), findsOneWidget);
    },
  );

  testWidgets('AdBannerWidget has correct default height', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: AdBannerWidget())),
      ),
    );
    await tester.pump();

    final renderBox = tester.renderObject<RenderBox>(
      find.byType(AdBannerWidget),
    );
    expect(renderBox.size.height, AdBannerWidget.defaultHeight);
  });

  testWidgets('AdBannerWidget accepts custom height', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: AdBannerWidget(bannerHeight: 90.0)),
        ),
      ),
    );
    await tester.pump();

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
