import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:captionary/data/models/subtitle_segment.dart';
import 'package:captionary/core/waveform_data.dart';
import 'package:captionary/providers/player_provider.dart';
import 'package:captionary/providers/subtitle_provider.dart';
import 'package:captionary/theme/app_theme.dart';
import 'package:captionary/widgets/caption_timeline.dart';
import 'package:captionary/widgets/draggable_timeline_chip.dart';

void main() {
  final testSegments = [
    SubtitleSegment(
      index: 1,
      startTime: Duration.zero,
      endTime: const Duration(seconds: 2),
      text: 'Chip 1 text',
      isSelected: false,
    ),
    SubtitleSegment(
      index: 2,
      startTime: const Duration(seconds: 2, milliseconds: 100),
      endTime: const Duration(seconds: 4),
      text: 'Chip 2 text',
      isSelected: false,
    ),
    SubtitleSegment(
      index: 3,
      startTime: const Duration(seconds: 4, milliseconds: 100),
      endTime: const Duration(seconds: 6),
      text: 'Chip 3 text',
      isSelected: false,
    ),
    SubtitleSegment(
      index: 4,
      startTime: const Duration(seconds: 6, milliseconds: 100),
      endTime: const Duration(seconds: 8),
      text: 'Chip 4 text',
      isSelected: false,
    ),
  ];

  Future<void> pumpTimeline(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          subtitleProvider.overrideWith(
            (ref) => SubtitleNotifier(testSegments),
          ),
        ],
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

  testWidgets('playhead handles 4-minute position and jumps to view', (tester) async {
    await pumpTimeline(tester);
    final element = tester.element(find.byType(CaptionTimeline));
    final container = ProviderScope.containerOf(element);

    // Seek to 4 minutes (240 seconds)
    await container
        .read(playerProvider.notifier)
        .seekTo(const Duration(minutes: 4));
    await tester.pumpAndSettle();

    // Verify clock display shows 4 minutes
    expect(find.textContaining('04:00'), findsOneWidget);
  });

  testWidgets('typing in text field updates caption text in real time', (tester) async {
    await pumpTimeline(tester);
    final element = tester.element(find.byType(CaptionTimeline));
    final container = ProviderScope.containerOf(element);

    // Select the first chip
    await tester.tap(find.byKey(const ValueKey('chip-1')));
    await tester.pump();

    // Type into the caption text field
    final textFieldFinder = find.byKey(const Key('caption-text-field'));
    await tester.enterText(textFieldFinder, 'So Lil Durk');
    await tester.pump();

    // Verify subtitleProvider updated in real time
    final updatedText = container.read(subtitleProvider).first.text;
    expect(updatedText, equals('So Lil Durk'));
  });
}
