import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:captionary/data/models/subtitle_segment.dart';
import 'package:captionary/providers/subtitle_provider.dart';
import 'package:captionary/screens/studio_screen.dart';

void main() {
  Widget buildTestWidget({List<SubtitleSegment>? initialSubtitles}) {
    return ProviderScope(
      overrides: [
        if (initialSubtitles != null)
          subtitleProvider.overrideWith(
            (ref) => SubtitleNotifier(initialSubtitles),
          ),
      ],
      child: const MaterialApp(home: StudioScreen()),
    );
  }

  testWidgets('Style button opens the stylization sheet with equal presets', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    await tester.tap(find.text('Style'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('TikTok Bold'), findsWidgets);
    expect(find.text('IG Highlight'), findsOneWidget);
    expect(find.text('Presets'), findsOneWidget);
  });

  testWidgets('Timeline chip is visible on the studio canvas', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final segments = [
      SubtitleSegment(
        index: 1,
        startTime: Duration.zero,
        endTime: const Duration(seconds: 3),
        text: 'Studio test caption',
        isSelected: false,
      ),
    ];

    await tester.pumpWidget(buildTestWidget(initialSubtitles: segments));
    await tester.pump();

    expect(find.text('Studio test caption'), findsWidgets);
  });

  testWidgets('Export captions opens the format sheet', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildTestWidget());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final export = find.text('Export captions');
    expect(export, findsOneWidget);

    await tester.tap(export);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('SRT'), findsOneWidget);
    expect(find.text('VTT'), findsOneWidget);
    expect(find.text('ASS'), findsOneWidget);
  });

  testWidgets('StudioScreen renders without overflow on phone dimensions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('No Video Loaded'), findsOneWidget);
  });
}
