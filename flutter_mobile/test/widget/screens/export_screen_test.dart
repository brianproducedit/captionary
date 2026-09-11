import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:captionary/screens/export_screen.dart';
import 'package:captionary/providers/export_provider.dart';
import 'package:captionary/data/models/export_job.dart';

void main() {
  testWidgets('Export Screen shows progress state correctly', (tester) async {
    final activeJob = ExportJob(
      id: 'mock_1',
      sourceFileName: 'source.mp4',
      outputFileName: 'output.mp4',
      state: ExportState.encoding,
      progress: 0.45,
      resolution: '1080x1920',
      codec: 'h264',
      bitrateMbps: 8,
      estimatedTimeRemaining: const Duration(seconds: 32),
      outputSizeBytes: 0,
      hardwareAcceleration: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeExportJobProvider.overrideWith((ref) => _MockExportJobNotifier(activeJob)),
        ],
        child: const MaterialApp(
          home: ExportScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Should show 45% text
    expect(find.text('45'), findsOneWidget);
    // Should show encoding text
    expect(find.textContaining('Encoding 1080x1920'), findsOneWidget);
    // Should have Abort button
    expect(find.text('Abort'), findsOneWidget);
  });

  testWidgets('Export Screen shows complete state correctly', (tester) async {
    final completeJob = ExportJob(
      id: 'mock_1',
      sourceFileName: 'source.mp4',
      outputFileName: 'output.mp4',
      state: ExportState.complete,
      progress: 1.0,
      resolution: '1080x1920',
      codec: 'h264',
      bitrateMbps: 8,
      estimatedTimeRemaining: Duration.zero,
      outputSizeBytes: 1024 * 1024 * 48, // ~48MB
      hardwareAcceleration: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeExportJobProvider.overrideWith((ref) => _MockExportJobNotifier(completeJob)),
        ],
        child: const MaterialApp(
          home: ExportScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Should show completion text
    expect(find.text('Export Complete!'), findsOneWidget);
    // Should show file details
    expect(find.textContaining('48.0 MB', findRichText: true), findsOneWidget);
    // Should show Preview button
    expect(find.text('Preview'), findsOneWidget);
  });
}

class _MockExportJobNotifier extends ActiveExportJobNotifier {
  final ExportJob mockJob;
  
  _MockExportJobNotifier(this.mockJob) : super() {
    state = mockJob;
  }
}
