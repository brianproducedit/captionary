import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:captionary/core/subtitle_file_store.dart';
import 'package:captionary/data/models/subtitle_segment.dart';
import 'package:captionary/providers/export_provider.dart';
import 'package:captionary/providers/subtitle_provider.dart';
import 'package:captionary/theme/app_theme.dart';
import 'package:captionary/widgets/caption_export_sheet.dart';

void main() {
  Future<void> pumpSheet(
    WidgetTester tester, {
    List<Override> overrides = const [],
  }) async {
    tester.view.physicalSize = const Size(1080, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: SizedBox.expand(child: CaptionExportSheet()),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('format picker includes SRT, VTT, and enabled ASS', (
    tester,
  ) async {
    await pumpSheet(tester);
    expect(find.text('SRT'), findsOneWidget);
    expect(find.text('VTT'), findsOneWidget);
    expect(find.text('ASS'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('format-vtt')));
    await tester.pump();
    expect(find.text('Export VTT'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('format-ass')));
    await tester.pump();
    expect(find.text('Export ASS'), findsOneWidget);
  });

  testWidgets('empty captions show why export is disabled', (tester) async {
    await pumpSheet(
      tester,
      overrides: [
        subtitleProvider.overrideWith((ref) => SubtitleNotifier(const [])),
      ],
    );
    expect(find.textContaining('Add at least one caption'), findsOneWidget);
    expect(find.text('Fix captions to enable export'), findsOneWidget);
  });

  testWidgets('exporting VTT writes a file and shares it', (tester) async {
    final dir = Directory.systemTemp.createTempSync('captionary_sheet');
    addTearDown(() {
      try {
        dir.deleteSync(recursive: true);
      } catch (e) {
        // Ignore file lock errors on Windows during test teardown
      }
    });
    CaptionShareRequest? shared;

    await pumpSheet(
      tester,
      overrides: [
        subtitleFileStoreProvider.overrideWith(
          (ref) => SubtitleFileStore(directory: dir),
        ),
        captionShareHandlerProvider.overrideWith((ref) {
          return (request) async {
            shared = request;
          };
        }),
        subtitleProvider.overrideWith(
          (ref) => SubtitleNotifier([
            SubtitleSegment(
              index: 1,
              startTime: Duration.zero,
              endTime: const Duration(seconds: 1),
              text: 'Hi',
              isSelected: false,
            ),
          ]),
        ),
      ],
    );

    await tester.tap(find.byKey(const ValueKey('format-vtt')));
    await tester.pumpAndSettle();

    // Ensure the sheet is scrolled if necessary
    await tester.ensureVisible(find.text('Export VTT'));
    await tester.tap(find.text('Export VTT'));
    await tester.pumpAndSettle();

    expect(shared, isNotNull);
    expect(shared!.fileName.endsWith('.vtt'), isTrue);
    expect(shared!.mimeType, 'text/vtt');
    final file = File(shared!.path);
    expect(file.existsSync(), isTrue);
    expect(file.readAsStringSync(), contains('WEBVTT'));
  });

  testWidgets('exporting ASS writes a styled ASS file and shares it', (
    tester,
  ) async {
    final dir = Directory.systemTemp.createTempSync('captionary_sheet_ass');
    addTearDown(() {
      try {
        dir.deleteSync(recursive: true);
      } catch (e) {
        // Ignore file lock errors on Windows during test teardown
      }
    });
    CaptionShareRequest? shared;

    await pumpSheet(
      tester,
      overrides: [
        subtitleFileStoreProvider.overrideWith(
          (ref) => SubtitleFileStore(directory: dir),
        ),
        captionShareHandlerProvider.overrideWith((ref) {
          return (request) async {
            shared = request;
          };
        }),
        subtitleProvider.overrideWith(
          (ref) => SubtitleNotifier([
            SubtitleSegment(
              index: 1,
              startTime: Duration.zero,
              endTime: const Duration(seconds: 2),
              text: 'Styled caption',
              isSelected: false,
            ),
          ]),
        ),
      ],
    );

    await tester.tap(find.byKey(const ValueKey('format-ass')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Export ASS'));
    await tester.tap(find.text('Export ASS'));
    await tester.pumpAndSettle();

    expect(shared, isNotNull);
    expect(shared!.fileName.endsWith('.ass'), isTrue);
    expect(shared!.mimeType, 'text/x-ssa');
    final file = File(shared!.path);
    expect(file.existsSync(), isTrue);
    final content = file.readAsStringSync();
    expect(content, contains('[Script Info]'));
    expect(content, contains('[V4+ Styles]'));
    expect(content, contains('Styled caption'));
  });
}
