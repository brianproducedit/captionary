import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:captionary/widgets/ad_banner_widget.dart';

void main() {
  testWidgets('AdBannerWidget renders placeholder with correct text', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AdBannerWidget())),
    );

    expect(find.text('Ad Space'), findsOneWidget);
    expect(find.textContaining('Google AdMob Adaptive Banner'), findsOneWidget);
  });

  testWidgets('AdBannerWidget has correct default height', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AdBannerWidget())),
    );

    final container = tester.widget<Container>(find.byType(Container).first);
    final constraints = container.constraints;
    expect(constraints?.maxHeight, 60.0);
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
}
