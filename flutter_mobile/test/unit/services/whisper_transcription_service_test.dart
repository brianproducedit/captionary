import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:whisper_flutter_new/whisper_flutter_new.dart';
import 'package:captionary/core/wav_header_validator.dart';
import 'package:captionary/data/services/whisper_transcription_service.dart';

void main() {
  late Directory tempDir;
  late File testWavFile;
  late File testModelFile;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('whisper_service_test_');

    final wavData = WavHeaderValidator.createPcm16kMonoWav(
      duration: const Duration(seconds: 4),
    );
    testWavFile = File('${tempDir.path}/test.wav');
    await testWavFile.writeAsBytes(wavData);

    testModelFile = File('${tempDir.path}/ggml-tiny.bin');
    await testModelFile.writeAsString('mock model content');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('WhisperTranscriptionService', () {
    test('validates empty audio path and non-existent audio file', () async {
      final service = WhisperTranscriptionService(
        getTempDirectory: () async => tempDir,
      );

      expect(
        () => service.transcribeAudio(
          audioPath: '',
          languageCode: 'en',
          modelPath: testModelFile.path,
        ),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => service.transcribeAudio(
          audioPath: '${tempDir.path}/missing.wav',
          languageCode: 'en',
          modelPath: testModelFile.path,
        ),
        throwsA(isA<FileSystemException>()),
      );
    });

    test('validates empty model path', () async {
      final service = WhisperTranscriptionService(
        getTempDirectory: () async => tempDir,
      );

      expect(
        () => service.transcribeAudio(
          audioPath: testWavFile.path,
          languageCode: 'en',
          modelPath: '   ',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test(
      'transcribes audio using injected runner and returns parsed segments',
      () async {
        final service = WhisperTranscriptionService(
          getTempDirectory: () async => tempDir,
          runner:
              ({
                required String audioPath,
                required String modelPath,
                required String languageCode,
              }) async {
                return WhisperTranscribeResponse(
                  type: 'text',
                  text: 'Hello from mock whisper',
                  segments: [
                    WhisperTranscribeSegment(
                      fromTs: const Duration(seconds: 0),
                      toTs: const Duration(seconds: 2),
                      text: 'Hello from',
                    ),
                    WhisperTranscribeSegment(
                      fromTs: const Duration(seconds: 2),
                      toTs: const Duration(seconds: 4),
                      text: 'mock whisper',
                    ),
                  ],
                );
              },
        );

        final segments = await service.transcribeAudio(
          audioPath: testWavFile.path,
          languageCode: 'en',
          modelPath: testModelFile.path,
        );

        expect(segments.length, 2);
        expect(segments[0].text, 'Hello from');
        expect(segments[0].startTime, Duration.zero);
        expect(segments[0].endTime, const Duration(seconds: 2));

        expect(segments[1].text, 'mock whisper');
        expect(segments[1].startTime, const Duration(seconds: 2));
        expect(segments[1].endTime, const Duration(seconds: 4));
      },
    );

    test('cancellation terminates stream early', () async {
      final service = WhisperTranscriptionService(
        getTempDirectory: () async => tempDir,
        runner:
            ({
              required String audioPath,
              required String modelPath,
              required String languageCode,
            }) async {
              await Future.delayed(const Duration(milliseconds: 80));
              return WhisperTranscribeResponse(
                type: 'text',
                text: 'Result',
                segments: [
                  WhisperTranscribeSegment(
                    fromTs: Duration.zero,
                    toTs: const Duration(seconds: 2),
                    text: 'Should not arrive',
                  ),
                ],
              );
            },
      );

      final future = service.transcribeAudio(
        audioPath: testWavFile.path,
        languageCode: 'en',
        modelPath: testModelFile.path,
      );

      // Cancel while in-flight
      await Future.delayed(const Duration(milliseconds: 15));
      service.cancel();

      final segments = await future;
      expect(segments, isEmpty);
    });

    test('concurrency lock serializes multiple transcription calls', () async {
      int activeRunners = 0;
      int maxConcurrent = 0;

      final service = WhisperTranscriptionService(
        getTempDirectory: () async => tempDir,
        runner:
            ({
              required String audioPath,
              required String modelPath,
              required String languageCode,
            }) async {
              activeRunners++;
              if (activeRunners > maxConcurrent) {
                maxConcurrent = activeRunners;
              }
              await Future.delayed(const Duration(milliseconds: 40));
              activeRunners--;
              return WhisperTranscribeResponse(
                type: 'text',
                text: 'Done',
                segments: [],
              );
            },
      );

      // Launch 2 parallel transcription tasks
      final f1 = service.transcribeAudio(
        audioPath: testWavFile.path,
        languageCode: 'en',
        modelPath: testModelFile.path,
      );
      final f2 = service.transcribeAudio(
        audioPath: testWavFile.path,
        languageCode: 'en',
        modelPath: testModelFile.path,
      );

      await Future.wait([f1, f2]);

      // Assert that at most 1 runner was executing concurrently
      expect(maxConcurrent, 1);
    });
  });
}
