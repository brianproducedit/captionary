import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:captionary/screens/export_screen.dart';
import 'package:captionary/providers/export_provider.dart';
import 'package:captionary/data/models/export_job.dart';

ExportJob _job({
  required ExportState state,
  String outputFileName = 'output.mp4',
  double progress = 0.45,
}) {
  return ExportJob(
    id: 'mock_1',
    sourceFileName: 'source.mp4',
    outputFileName: outputFileName,
    state: state,
    progress: progress,
    resolution: '1080x1920',
    codec: 'h264',
    bitrateMbps: 8,
    estimatedTimeRemaining: const Duration(seconds: 32),
    outputSizeBytes: 1024 * 1024 * 48,
    hardwareAcceleration: true,
  );
}

void main() {
  testWidgets('Export Screen shows progress state correctly', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeExportJobProvider.overrideWith(
            (ref) => _MockExportJobNotifier(_job(state: ExportState.encoding)),
          ),
        ],
        child: const MaterialApp(home: ExportScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('45'), findsOneWidget);
    expect(find.textContaining('Encoding 1080x1920'), findsOneWidget);
    expect(find.text('Abort'), findsOneWidget);
  });

  testWidgets('complete state hides Preview when the file is missing', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeExportJobProvider.overrideWith(
            (ref) => _MockExportJobNotifier(
              _job(state: ExportState.complete, progress: 1),
            ),
          ),
        ],
        child: const MaterialApp(home: ExportScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('Export Complete!'), findsOneWidget);
    expect(find.textContaining('48.0 MB', findRichText: true), findsOneWidget);
    expect(find.text('Preview'), findsNothing);
  });

  testWidgets('complete state shows Preview when the output file exists', (
    tester,
  ) async {
    final file = File(
      '${Directory.systemTemp.path}/captionary_preview_test.mp4',
    );
    await file.writeAsBytes(const [0, 1, 2]);
    addTearDown(() {
      if (file.existsSync()) file.deleteSync();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeExportJobProvider.overrideWith(
            (ref) => _MockExportJobNotifier(
              _job(
                state: ExportState.complete,
                progress: 1,
                outputFileName: file.path,
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: ExportScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('Preview'), findsOneWidget);
    expect(find.text('Share Video'), findsOneWidget);
  });
}

class _MockExportJobNotifier extends ActiveExportJobNotifier {
  _MockExportJobNotifier(ExportJob mockJob) : super() {
    state = mockJob;
  }
}
