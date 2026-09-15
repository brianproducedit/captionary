import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'wav_header_validator.dart';

/// Represents an audio chunk ready for transcription.
class AudioChunk {
  final File file;
  final Duration timeOffset;
  final Duration duration;
  final bool isTemporary;

  AudioChunk({
    required this.file,
    required this.timeOffset,
    required this.duration,
    required this.isTemporary,
  });
}

/// Splits long 16kHz mono 16-bit PCM WAV audio into Whisper-compatible 30s chunks
/// with overlapping windows to prevent lost words at boundaries.
class WhisperChunker {
  static const Uuid _uuid = Uuid();

  /// Default Whisper window duration (30 seconds).
  static const Duration defaultChunkDuration = Duration(seconds: 30);

  /// Default overlap between consecutive chunks (2 seconds).
  static const Duration defaultOverlap = Duration(seconds: 2);

  /// Bytes per millisecond for canonical 16kHz mono 16-bit PCM audio
  /// (16000 samples/sec * 2 bytes/sample / 1000 ms = 32 bytes/ms).
  static const int bytesPerMs = 32;

  /// Chunks a 16kHz mono WAV file into windows of [chunkDuration] with [overlap].
  /// If the audio is shorter than or equal to [chunkDuration], the original file is returned.
  static Future<List<AudioChunk>> chunkAudio(
    File wavFile, {
    Duration chunkDuration = defaultChunkDuration,
    Duration overlap = defaultOverlap,
    Future<Directory> Function()? getTempDirectory,
  }) async {
    final header = await WavHeaderValidator.validateFile(wavFile);
    if (!header.isValid ||
        !header.isWhisperCompatible ||
        header.duration == null ||
        header.dataOffset == null ||
        header.dataSize == null) {
      throw FormatException(
        'Invalid or non-16kHz mono WAV file: ${wavFile.path}',
      );
    }

    final totalDuration = header.duration!;
    if (totalDuration <= chunkDuration) {
      return [
        AudioChunk(
          file: wavFile,
          timeOffset: Duration.zero,
          duration: totalDuration,
          isTemporary: false,
        ),
      ];
    }

    Directory tempDir;
    if (getTempDirectory != null) {
      tempDir = await getTempDirectory();
    } else {
      try {
        tempDir = await getTemporaryDirectory();
      } catch (_) {
        tempDir = Directory.systemTemp;
      }
    }

    final chunksDir = Directory('${tempDir.path}/whisper_chunks');
    if (!await chunksDir.exists()) {
      await chunksDir.create(recursive: true);
    }

    // Read raw PCM bytes from the data subchunk
    final bytes = await wavFile.readAsBytes();
    final dataOffset = header.dataOffset!;
    final dataLength = header.dataSize!;

    final pcmBytes = Uint8List.sublistView(bytes, dataOffset, dataOffset + dataLength);

    final chunkBytesCount = chunkDuration.inMilliseconds * bytesPerMs;
    final stepDuration = chunkDuration - overlap;
    final stepBytesCount = stepDuration.inMilliseconds * bytesPerMs;

    final List<AudioChunk> chunks = [];
    int currentByteOffset = 0;
    Duration currentOffset = Duration.zero;

    while (currentByteOffset < pcmBytes.length) {
      final endByteOffset = (currentByteOffset + chunkBytesCount > pcmBytes.length)
          ? pcmBytes.length
          : currentByteOffset + chunkBytesCount;

      final slice = Uint8List.sublistView(pcmBytes, currentByteOffset, endByteOffset);
      final sliceDuration = Duration(milliseconds: slice.length ~/ bytesPerMs);

      final chunkFile = File('${chunksDir.path}/chunk_${_uuid.v4()}.wav');
      final wavData = WavHeaderValidator.createPcm16kMonoWav(
        duration: sliceDuration,
        pcmData: slice,
      );
      await chunkFile.writeAsBytes(wavData, flush: true);

      chunks.add(
        AudioChunk(
          file: chunkFile,
          timeOffset: currentOffset,
          duration: sliceDuration,
          isTemporary: true,
        ),
      );

      currentByteOffset += stepBytesCount;
      currentOffset += stepDuration;

      // If the remaining duration is less than or equal to the overlap, we're done
      if (pcmBytes.length - currentByteOffset <= overlap.inMilliseconds * bytesPerMs) {
        break;
      }
    }

    return chunks;
  }

  /// Cleans up any temporary chunk files created during [chunkAudio].
  static Future<void> cleanupChunks(List<AudioChunk> chunks) async {
    for (final chunk in chunks) {
      if (chunk.isTemporary && await chunk.file.exists()) {
        try {
          await chunk.file.delete();
        } catch (_) {}
      }
    }
  }
}
