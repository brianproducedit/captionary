import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:captionary/core/wav_header_validator.dart';
import 'package:captionary/data/mock/mock_audio_extraction_service.dart';
import 'package:captionary/data/services/audio_preprocessor.dart';

void main() {
  group('AudioPreprocessor.buildCommand', () {
    test('builds a 16kHz mono PCM WAV extraction command', () {
      final command = AudioPreprocessor.buildCommand(
        videoPath: '/tmp/input video.mp4',
        outputPath: '/tmp/output.wav',
      );

      expect(
        command,
        '-y -i "/tmp/input video.mp4" -vn '
        '-acodec pcm_s16le -ar 16000 -ac 1 "/tmp/output.wav"',
      );
    });

    test('limits extraction when a sample duration is provided', () {
      final command = AudioPreprocessor.buildCommand(
        videoPath: '/tmp/input.mp4',
        outputPath: '/tmp/sample.wav',
        limit: const Duration(seconds: 30),
      );

      expect(command, contains('-t 30'));
      expect(command, contains('-ar 16000 -ac 1'));
    });

    test('escapes double quotes in file paths', () {
      final command = AudioPreprocessor.buildCommand(
        videoPath: '/tmp/creator"s video.mp4',
        outputPath: '/tmp/output.wav',
      );

      expect(command, contains('/tmp/creator\\"s video.mp4'));
    });

    test('returns null for empty video path without starting FFmpeg', () async {
      final preprocessor = AudioPreprocessor();
      final result = await preprocessor.extractAudio('   ');
      expect(result, isNull);
    });
  });

  group('MockAudioExtractionService', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('mock_audio_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('extracts valid 16kHz mono WAV file compliant with Whisper', () async {
      final service = MockAudioExtractionService(
        getTempDirectory: () async => tempDir,
        delay: Duration.zero,
      );

      final path = await service.extractAudio('/path/to/test_video.mp4');
      expect(path, isNotNull);
      expect(File(path!).existsSync(), isTrue);

      final validation = await WavHeaderValidator.validateFile(File(path));
      expect(validation.isValid, isTrue);
      expect(validation.isWhisperCompatible, isTrue);
      expect(validation.sampleRate, 16000);
      expect(validation.channels, 1);
      expect(validation.bitsPerSample, 16);
      expect(validation.duration?.inSeconds, 2);
    });

    test('honors duration limit when provided', () async {
      final service = MockAudioExtractionService(
        getTempDirectory: () async => tempDir,
        delay: Duration.zero,
      );

      final path = await service.extractAudio(
        '/path/to/test_video.mp4',
        limit: const Duration(seconds: 5),
      );
      expect(path, isNotNull);

      final validation = await WavHeaderValidator.validateFile(File(path!));
      expect(validation.isValid, isTrue);
      expect(validation.duration?.inSeconds, 5);
    });

    test('returns null when shouldFail is true', () async {
      final service = MockAudioExtractionService(
        shouldFail: true,
        getTempDirectory: () async => tempDir,
        delay: Duration.zero,
      );

      final path = await service.extractAudio('/path/to/video.mp4');
      expect(path, isNull);
    });

    test('returns null when empty video path is provided', () async {
      final service = MockAudioExtractionService(
        getTempDirectory: () async => tempDir,
        delay: Duration.zero,
      );

      final path = await service.extractAudio('  ');
      expect(path, isNull);
    });

    test('returns null when cancelled before completion', () async {
      final service = MockAudioExtractionService(
        getTempDirectory: () async => tempDir,
        delay: const Duration(milliseconds: 100),
      );

      final future = service.extractAudio('/path/to/video.mp4');
      await service.cancel();
      final path = await future;
      expect(path, isNull);
    });
  });
}
