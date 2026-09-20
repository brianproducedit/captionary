import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:captionary/widgets/export_options_sheet.dart';
import 'package:captionary/widgets/pro_teaser_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('ExportOptionsSheet defaults to 720p with watermark and triggers teaser on 1080p', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    bool confirmed = false;
    int selectedRes = 0;
    bool withWatermark = false;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  ExportOptionsSheet.show(
                    context,
                    onConfirmExport: ({
                      required bool includeWatermark,
                      required int targetMaxResolution,
                    }) {
                      confirmed = true;
                      selectedRes = targetMaxResolution;
                      withWatermark = includeWatermark;
                    },
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    // Open sheet
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // Verify title and options
    expect(find.text('Video Export Options'), findsOneWidget);
    expect(find.text('720p HD'), findsOneWidget);
    expect(find.text('1080p FHD'), findsOneWidget);
    expect(find.text('4K UHD'), findsOneWidget);
    expect(find.text('"Captioned by Captionary"'), findsOneWidget);

    // Tapping 1080p triggers ProTeaserSheet
    await tester.tap(find.text('1080p FHD'));
    await tester.pumpAndSettle();

    expect(find.byType(ProTeaserSheet), findsOneWidget);
    expect(find.text('1080p Full HD Export is a Pro Feature'), findsOneWidget);

    // Close teaser
    await tester.tap(find.text('Got it, stay on Free Beta'));
    await tester.pumpAndSettle();

    // Export in 720p
    final exportButton = find.text('Export in 720p (Free Beta)');
    expect(exportButton, findsOneWidget);

    await tester.tap(exportButton);
    await tester.pumpAndSettle();

    expect(confirmed, isTrue);
    expect(selectedRes, 720);
    expect(withWatermark, isTrue);
  });
}
