import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:captionary/core/ad_placement_policy.dart';
import 'package:captionary/widgets/ad_banner_widget.dart';

void main() {
  testWidgets('AdBannerWidget collapses by default when no ad is loaded', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: AdBannerWidget())),
      ),
    );
    await tester.pump();

    // By default to comply with AdMob policy, collapses to SizedBox.shrink
    expect(find.text(AdBannerWidget.placeholderLabel), findsNothing);
    expect(find.byType(SizedBox), findsWidgets);
  });

  testWidgets(
    'AdBannerWidget renders placeholder fallback when showPlaceholder is true',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: AdBannerWidget(showPlaceholder: true)),
          ),
        ),
      );
      await tester.pump();

      expect(find.text(AdBannerWidget.placeholderLabel), findsOneWidget);
    },
  );

  testWidgets(
    'AdBannerWidget has correct default height when placeholder enabled',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: AdBannerWidget(showPlaceholder: true)),
          ),
        ),
      );
      await tester.pump();

      final renderBox = tester.renderObject<RenderBox>(
        find.byType(AdBannerWidget),
      );
      expect(renderBox.size.height, AdBannerWidget.defaultHeight);
    },
  );

  testWidgets('AdBannerWidget accepts custom height when placeholder enabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: AdBannerWidget(showPlaceholder: true, bannerHeight: 90.0),
          ),
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
