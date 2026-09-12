import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:captionary/data/models/caption_style.dart';
import 'package:captionary/providers/caption_style_provider.dart';
import 'package:captionary/theme/app_theme.dart';
import 'package:captionary/widgets/caption_style_card.dart';
import 'package:captionary/widgets/stylization_sheet.dart';

void main() {
  Future<void> pumpDarkSheet(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: SizedBox.expand(child: StylizationSheet()),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  CaptionStyle readStyle(WidgetTester tester) {
    final element = tester.element(find.byType(StylizationSheet));
    return ProviderScope.containerOf(element).read(captionStyleProvider);
  }

  testWidgets('preset cards are equal size and use local textures', (
    tester,
  ) async {
    await pumpDarkSheet(tester);

    final cards = find.byType(CaptionStyleCard);
    expect(cards, findsNWidgets(4));

    final firstSize = tester.getSize(cards.at(0));
    expect(firstSize, CaptionStyleCard.cardSize);
    for (var i = 1; i < 4; i++) {
      expect(tester.getSize(cards.at(i)), firstSize);
    }
  });

  testWidgets('Presets tab mutates CaptionStyle', (tester) async {
    await pumpDarkSheet(tester);
    expect(readStyle(tester).name, 'TikTok Bold');

    await tester.tap(find.text('IG Highlight'));
    await tester.pump();

    expect(readStyle(tester).name, 'IG Highlight');
    expect(readStyle(tester).fontSize, 24.0);
  });

  testWidgets('Text tab mutates size, spacing, alignment, and position', (
    tester,
  ) async {
    await pumpDarkSheet(tester);

    await tester.tap(find.text('Text'));
    await tester.pump();

    expect(find.textContaining('Lexend'), findsOneWidget);

    final before = readStyle(tester).fontSize;
    await tester.tap(find.byTooltip('Increase font size'));
    await tester.pump();
    expect(readStyle(tester).fontSize, before + 2);

    await tester.drag(
      find.byKey(const Key('line-spacing-slider')),
      const Offset(80, 0),
    );
    await tester.pump();
    expect(readStyle(tester).lineHeight, greaterThan(1.1));

    await tester.tap(find.byTooltip('Align left'));
    await tester.pump();
    expect(readStyle(tester).textAlign, CaptionTextAlign.left);

    await tester.tap(find.text('Top'));
    await tester.pump();
    expect(readStyle(tester).position, SubtitlePosition.top);
  });

  testWidgets('Animation tab sets None and records intensity as preview-only', (
    tester,
  ) async {
    await pumpDarkSheet(tester);

    await tester.tap(find.text('Animation'));
    await tester.pump();

    expect(find.textContaining('Not applied at burn-in yet'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('anim-none')));
    await tester.pump();
    expect(readStyle(tester).animationType, CaptionStyle.animationNone);
    expect(readStyle(tester).animationAppliesAtBurnIn, isFalse);

    await tester.tap(find.byKey(const ValueKey('anim-karaoke')));
    await tester.pump();
    await tester.drag(
      find.byKey(const Key('animation-intensity-slider')),
      const Offset(40, 0),
    );
    await tester.pump();
    expect(readStyle(tester).animationType, CaptionStyle.animationKaraoke);
  });

  testWidgets('Colors tab mutates swatch, opacity, outline, and shadow', (
    tester,
  ) async {
    await pumpDarkSheet(tester);

    await tester.tap(find.text('Colors'));
    await tester.pump();

    const mustard = Color(0xFFFFC107);
    await tester.tap(find.byKey(ValueKey('swatch-${mustard.toARGB32()}')));
    await tester.pump();
    expect(readStyle(tester).accentColor.toARGB32(), mustard.toARGB32());

    await tester.drag(
      find.byKey(const Key('box-opacity-slider')),
      const Offset(-60, 0),
    );
    await tester.pump();
    expect(readStyle(tester).boxOpacity, lessThan(0.8));

    await tester.drag(
      find.byKey(const Key('outline-slider')),
      const Offset(40, 0),
    );
    await tester.pump();
    expect(readStyle(tester).outlineWidth, greaterThan(2.0));

    await tester.drag(
      find.byKey(const Key('shadow-slider')),
      const Offset(50, 0),
    );
    await tester.pump();
    expect(readStyle(tester).shadowBlur, greaterThan(0));
  });
}
