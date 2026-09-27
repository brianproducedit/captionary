import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:captionary/widgets/transcription_options_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'TranscriptionOptionsSheet displays languages, options, and returns config on confirm',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      TranscriptionConfig? receivedConfig;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    receivedConfig = await TranscriptionOptionsSheet.show(
                      context,
                      videoPath: '/path/to/test_video.mp4',
                    );
                  },
                  child: const Text('Open Options'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open sheet
      await tester.tap(find.text('Open Options'));
      await tester.pumpAndSettle();

      // Verify UI elements are present
      expect(find.text('Transcription Options'), findsOneWidget);
      expect(find.text('SPOKEN AUDIO LANGUAGE'), findsOneWidget);
      expect(find.text('SUBTITLES OUTPUT'), findsOneWidget);
      expect(find.text('Original Spoken Language'), findsOneWidget);
      expect(find.text('Translate into English'), findsOneWidget);

      // Tap translate to English
      await tester.tap(find.text('Translate into English'));
      await tester.pumpAndSettle();

      // Tap Confirm (either "Transcribe Video" or "Download & Transcribe...")
      final confirmBtn = find.textContaining('Transcribe');
      expect(confirmBtn, findsWidgets);
      await tester.tap(confirmBtn.last);
      await tester.pumpAndSettle();

      // Sheet should be dismissed and config returned
      expect(receivedConfig, isNotNull);
      expect(receivedConfig!.translateToEnglish, isTrue);
      expect(receivedConfig!.languageCode, 'auto');
    },
  );
}
