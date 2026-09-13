import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:captionary/core/waveform_data.dart';
import 'package:captionary/providers/player_provider.dart';
import 'package:captionary/providers/subtitle_provider.dart';
import 'package:captionary/theme/app_theme.dart';
import 'package:captionary/widgets/caption_timeline.dart';
import 'package:captionary/widgets/draggable_timeline_chip.dart';

void main() {
  Future<void> pumpTimeline(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: SingleChildScrollView(
              child: CaptionTimeline(
                waveform: WaveformData(
                  state: WaveformLoadState.noAudio,
                  message: 'No audio waveform yet. Playhead and captions still follow time.',
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('moving a chip updates subtitle times', (tester) async {
    await pumpTimeline(tester);
    expect(find.byType(DraggableTimelineChip), findsNWidgets(4));

    final element = tester.element(find.byType(CaptionTimeline));
    final container = ProviderScope.containerOf(element);
    final before = container.read(subtitleProvider).first.startTime;

    await tester.drag(
      find.byKey(const ValueKey('chip-1')),
      const Offset(40, 0),
    );
    await tester.pump();

    final after = container.read(subtitleProvider).first.startTime;
    expect(after, greaterThan(before));
    expect(after, lessThanOrEqualTo(const Duration(milliseconds: 500)));
  });

  testWidgets('split at playhead adds a caption', (tester) async {
    await pumpTimeline(tester);
    final element = tester.element(find.byType(CaptionTimeline));
    final container = ProviderScope.containerOf(element);
    await container
        .read(playerProvider.notifier)
        .seekTo(const Duration(milliseconds: 1500));
    await tester.pump();

    await tester.tap(find.byTooltip('Split at playhead'));
    await tester.pump();

    expect(find.byType(DraggableTimelineChip), findsNWidgets(5));
  });
}
