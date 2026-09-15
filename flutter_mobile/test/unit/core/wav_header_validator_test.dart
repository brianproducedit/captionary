import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:captionary/core/wav_header_validator.dart';

void main() {
  group('WavHeaderValidator', () {
    test('synthesizes and validates a canonical 16kHz mono 16-bit PCM WAV', () {
      final wavBytes = WavHeaderValidator.createPcm16kMonoWav(
        duration: const Duration(seconds: 3),
        frequencyHz: 440.0,
      );

      final result = WavHeaderValidator.validate(wavBytes);

      expect(result.isValid, isTrue);
      expect(result.isWhisperCompatible, isTrue);
      expect(result.sampleRate, 16000);
      expect(result.channels, 1);
      expect(result.bitsPerSample, 16);
      expect(result.audioFormat, 1);
      expect(result.duration?.inSeconds, 3);
    });

    test('validates WAV from a temporary file on disk', () async {
      final tempDir = await Directory.systemTemp.createTemp('wav_test_');
      final file = File('${tempDir.path}/test_16k_mono.wav');

      final bytes = WavHeaderValidator.createPcm16kMonoWav(
        duration: const Duration(milliseconds: 1500),
      );
      await file.writeAsBytes(bytes);

      final result = await WavHeaderValidator.validateFile(file);

      expect(result.isValid, isTrue);
      expect(result.isWhisperCompatible, isTrue);
      expect(result.duration?.inMilliseconds, closeTo(1500, 10));

      await tempDir.delete(recursive: true);
    });

    test('fails for non-existent file', () async {
      final missingFile = File('/tmp/non_existent_file_xyz_123.wav');
      final result = await WavHeaderValidator.validateFile(missingFile);

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('does not exist'));
    });

    test('fails for buffer smaller than 44 bytes', () {
      final shortBytes = Uint8List(20);
      final result = WavHeaderValidator.validate(shortBytes);

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('less than 44 bytes'));
    });

    test('fails for invalid RIFF header', () {
      final bytes = WavHeaderValidator.createPcm16kMonoWav(
        duration: const Duration(seconds: 1),
      );
      // Corrupt RIFF
      bytes[0] = 'F'.codeUnitAt(0);
      bytes[1] = 'A'.codeUnitAt(0);
      bytes[2] = 'K'.codeUnitAt(0);
      bytes[3] = 'E'.codeUnitAt(0);

      final result = WavHeaderValidator.validate(bytes);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('expected "RIFF"'));
    });

    test('fails for invalid WAVE format tag', () {
      final bytes = WavHeaderValidator.createPcm16kMonoWav(
        duration: const Duration(seconds: 1),
      );
      // Corrupt WAVE
      bytes[8] = 'A'.codeUnitAt(0);
      bytes[9] = 'V'.codeUnitAt(0);
      bytes[10] = 'I'.codeUnitAt(0);
      bytes[11] = ' '.codeUnitAt(0);

      final result = WavHeaderValidator.validate(bytes);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('expected "WAVE"'));
    });

    test('flags stereo (channels != 1) as not Whisper-compatible', () {
      final bytes = WavHeaderValidator.createPcm16kMonoWav(
        duration: const Duration(seconds: 1),
      );
      final bd = ByteData.sublistView(bytes);
      // Set channels = 2, update blockAlign and byteRate accordingly
      bd.setUint16(22, 2, Endian.little);
      bd.setUint16(32, 4, Endian.little); // blockAlign = 2 * 2 = 4
      bd.setUint32(28, 16000 * 4, Endian.little); // byteRate = 16000 * 4

      final result = WavHeaderValidator.validate(bytes);
      expect(result.isValid, isTrue);
      expect(result.channels, 2);
      expect(result.isWhisperCompatible, isFalse);
    });

    test('flags 44.1kHz (sampleRate != 16000) as not Whisper-compatible', () {
      final bytes = WavHeaderValidator.createPcm16kMonoWav(
        duration: const Duration(seconds: 1),
      );
      final bd = ByteData.sublistView(bytes);
      bd.setUint32(24, 44100, Endian.little);
      bd.setUint32(28, 44100 * 2, Endian.little);

      final result = WavHeaderValidator.validate(bytes);
      expect(result.isValid, isTrue);
      expect(result.sampleRate, 44100);
      expect(result.isWhisperCompatible, isFalse);
    });

    test('fails for byteRate or blockAlign mismatch (corrupt header)', () {
      final bytes = WavHeaderValidator.createPcm16kMonoWav(
        duration: const Duration(seconds: 1),
      );
      final bd = ByteData.sublistView(bytes);
      // Corrupt byteRate
      bd.setUint32(28, 99999, Endian.little);

      final result = WavHeaderValidator.validate(bytes);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('mismatch'));
    });
  });
}
