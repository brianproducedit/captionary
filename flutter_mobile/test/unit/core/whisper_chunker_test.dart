import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:captionary/core/wav_header_validator.dart';
import 'package:captionary/core/whisper_chunker.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('whisper_chunker_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('WhisperChunker', () {
    test(
      'returns single original chunk when audio duration is <= chunk duration',
      () async {
        final wavData = WavHeaderValidator.createPcm16kMonoWav(
          duration: const Duration(seconds: 15),
        );
        final wavFile = File('${tempDir.path}/short_test.wav');
        await wavFile.writeAsBytes(wavData);

        final chunks = await WhisperChunker.chunkAudio(
          wavFile,
          chunkDuration: const Duration(seconds: 30),
          getTempDirectory: () async => tempDir,
        );

        expect(chunks.length, 1);
        expect(chunks[0].file.path, wavFile.path);
        expect(chunks[0].timeOffset, Duration.zero);
        expect(chunks[0].isTemporary, isFalse);

        await WhisperChunker.cleanupChunks(chunks);
        expect(await wavFile.exists(), isTrue); // original file preserved
      },
    );

    test(
      'slices long audio (> 30s) into overlapping 30s chunks and cleans up',
      () async {
        final wavData = WavHeaderValidator.createPcm16kMonoWav(
          duration: const Duration(seconds: 65),
        );
        final wavFile = File('${tempDir.path}/long_test.wav');
        await wavFile.writeAsBytes(wavData);

        final chunks = await WhisperChunker.chunkAudio(
          wavFile,
          chunkDuration: const Duration(seconds: 30),
          overlap: const Duration(seconds: 2),
          getTempDirectory: () async => tempDir,
        );

        // 65s total:
        // Chunk 0: 0s..30s (offset: 0s, step: 28s)
        // Chunk 1: 28s..58s (offset: 28s, step: 28s)
        // Chunk 2: 56s..65s (offset: 56s)
        expect(chunks.length, 3);

        expect(chunks[0].timeOffset, Duration.zero);
        expect(chunks[0].duration, const Duration(seconds: 30));
        expect(chunks[0].isTemporary, isTrue);

        expect(chunks[1].timeOffset, const Duration(seconds: 28));
        expect(chunks[1].duration, const Duration(seconds: 30));
        expect(chunks[1].isTemporary, isTrue);

        expect(chunks[2].timeOffset, const Duration(seconds: 56));
        expect(chunks[2].duration, const Duration(seconds: 9));
        expect(chunks[2].isTemporary, isTrue);

        // Verify generated chunk is valid 16kHz mono WAV
        for (final chunk in chunks) {
          final header = await WavHeaderValidator.validateFile(chunk.file);
          expect(header.isValid, isTrue);
          expect(header.isWhisperCompatible, isTrue);
        }

        // Verify cleanup deletes temporary files
        await WhisperChunker.cleanupChunks(chunks);
        for (final chunk in chunks) {
          expect(await chunk.file.exists(), isFalse);
        }
      },
    );

    test('throws FormatException for invalid audio file', () async {
      final badFile = File('${tempDir.path}/corrupt.wav');
      await badFile.writeAsString('not a wav file');

      expect(
        () => WhisperChunker.chunkAudio(
          badFile,
          getTempDirectory: () async => tempDir,
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
