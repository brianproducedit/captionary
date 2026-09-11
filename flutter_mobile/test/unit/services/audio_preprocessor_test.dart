import 'package:flutter_test/flutter_test.dart';

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
  });
}
