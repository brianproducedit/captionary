import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

class WavValidationResult {
  final bool isValid;
  final int? sampleRate;
  final int? channels;
  final int? bitsPerSample;
  final int? audioFormat;
  final int? dataSize;
  final int? dataOffset;
  final Duration? duration;
  final String? errorMessage;

  const WavValidationResult({
    required this.isValid,
    this.sampleRate,
    this.channels,
    this.bitsPerSample,
    this.audioFormat,
    this.dataSize,
    this.dataOffset,
    this.duration,
    this.errorMessage,
  });

  bool get isWhisperCompatible =>
      isValid &&
      sampleRate == 16000 &&
      channels == 1 &&
      bitsPerSample == 16 &&
      audioFormat == 1;

  @override
  String toString() {
    if (!isValid) return 'WavValidationResult(Invalid: $errorMessage)';
    return 'WavValidationResult(Valid, rate: ${sampleRate}Hz, ch: $channels, bits: $bitsPerSample, duration: $duration)';
  }
}

class WavHeaderValidator {
  static const int minHeaderSize = 44;
  static const int expectedSampleRate = 16000;
  static const int expectedChannels = 1;
  static const int expectedBitsPerSample = 16;
  static const int pcmAudioFormat = 1;

  /// Validates a WAV file from the filesystem.
  static Future<WavValidationResult> validateFile(File file) async {
    if (!await file.exists()) {
      return const WavValidationResult(
        isValid: false,
        errorMessage: 'File does not exist.',
      );
    }

    final length = await file.length();
    if (length < minHeaderSize) {
      return WavValidationResult(
        isValid: false,
        errorMessage:
            'File size ($length bytes) is smaller than canonical WAV header ($minHeaderSize bytes).',
      );
    }

    // Read first 4096 bytes or total length to parse chunks
    final readBytes = math.min(length, 4096);
    final raf = await file.open(mode: FileMode.read);
    try {
      final headerBytes = await raf.read(readBytes);
      return validate(headerBytes, totalFileLength: length);
    } finally {
      await raf.close();
    }
  }

  /// Validates WAV bytes in memory.
  static WavValidationResult validate(
    Uint8List bytes, {
    int? totalFileLength,
  }) {
    if (bytes.length < minHeaderSize) {
      return WavValidationResult(
        isValid: false,
        errorMessage:
            'Buffer size (${bytes.length} bytes) is less than 44 bytes.',
      );
    }

    final byteData = ByteData.sublistView(bytes);

    // 1. RIFF chunk ID
    final riff = String.fromCharCodes(bytes.sublist(0, 4));
    if (riff != 'RIFF') {
      return WavValidationResult(
        isValid: false,
        errorMessage: 'Invalid RIFF header: expected "RIFF", found "$riff".',
      );
    }

    // 2. Format
    final wave = String.fromCharCodes(bytes.sublist(8, 12));
    if (wave != 'WAVE') {
      return WavValidationResult(
        isValid: false,
        errorMessage: 'Invalid format: expected "WAVE", found "$wave".',
      );
    }

    int offset = 12;
    int? audioFormat;
    int? channels;
    int? sampleRate;
    int? byteRate;
    int? blockAlign;
    int? bitsPerSample;
    int? dataSize;
    int? dataOffset;

    // Scan chunks (fmt, data, etc.)
    while (offset + 8 <= bytes.length) {
      final chunkId = String.fromCharCodes(bytes.sublist(offset, offset + 4));
      final chunkSize = byteData.getUint32(offset + 4, Endian.little);
      final chunkDataOffset = offset + 8;

      if (chunkId == 'fmt ') {
        if (chunkSize < 16 || chunkDataOffset + 16 > bytes.length) {
          return const WavValidationResult(
            isValid: false,
            errorMessage: 'Malformed "fmt " chunk.',
          );
        }
        audioFormat = byteData.getUint16(chunkDataOffset, Endian.little);
        channels = byteData.getUint16(chunkDataOffset + 2, Endian.little);
        sampleRate = byteData.getUint32(chunkDataOffset + 4, Endian.little);
        byteRate = byteData.getUint32(chunkDataOffset + 8, Endian.little);
        blockAlign = byteData.getUint16(chunkDataOffset + 12, Endian.little);
        bitsPerSample = byteData.getUint16(chunkDataOffset + 14, Endian.little);
      } else if (chunkId == 'data') {
        dataSize = chunkSize;
        dataOffset = chunkDataOffset;
        break;
      }

      offset = chunkDataOffset + chunkSize;
      // Chunks are word-aligned (2-byte padding if odd)
      if (chunkSize.isOdd) offset += 1;
    }

    if (audioFormat == null || sampleRate == null || channels == null) {
      return const WavValidationResult(
        isValid: false,
        errorMessage: 'Missing "fmt " chunk in WAV file.',
      );
    }

    if (dataSize == null || dataOffset == null) {
      return const WavValidationResult(
        isValid: false,
        errorMessage: 'Missing "data" chunk in WAV file.',
      );
    }

    if (audioFormat != pcmAudioFormat) {
      return WavValidationResult(
        isValid: false,
        audioFormat: audioFormat,
        channels: channels,
        sampleRate: sampleRate,
        bitsPerSample: bitsPerSample,
        errorMessage:
            'Unsupported audio format $audioFormat (expected PCM = 1).',
      );
    }

    // Verify expected byteRate and blockAlign calculations
    if (bitsPerSample != null) {
      final expectedBlockAlign = (channels * bitsPerSample) ~/ 8;
      final expectedByteRate = sampleRate * expectedBlockAlign;
      if (blockAlign != expectedBlockAlign || byteRate != expectedByteRate) {
        return WavValidationResult(
          isValid: false,
          audioFormat: audioFormat,
          channels: channels,
          sampleRate: sampleRate,
          bitsPerSample: bitsPerSample,
          errorMessage:
              'Corrupt WAV header: blockAlign ($blockAlign vs $expectedBlockAlign) or byteRate ($byteRate vs $expectedByteRate) mismatch.',
        );
      }
    }

    Duration? duration;
    if (byteRate != null && byteRate > 0) {
      final actualDataSize = totalFileLength != null
          ? math.min(dataSize, totalFileLength - dataOffset)
          : dataSize;
      final seconds = actualDataSize / byteRate;
      duration = Duration(milliseconds: (seconds * 1000).round());
    }

    return WavValidationResult(
      isValid: true,
      audioFormat: audioFormat,
      channels: channels,
      sampleRate: sampleRate,
      bitsPerSample: bitsPerSample,
      dataSize: dataSize,
      dataOffset: dataOffset,
      duration: duration,
    );
  }

  /// Synthesizes a valid 16kHz mono 16-bit PCM WAV file in memory.
  static Uint8List createPcm16kMonoWav({
    required Duration duration,
    Uint8List? pcmData,
    double frequencyHz = 440.0,
    double amplitude = 0.5,
  }) {
    const sampleRate = expectedSampleRate;
    const channels = expectedChannels;
    const bitsPerSample = expectedBitsPerSample;
    final totalSamples = (duration.inMilliseconds * sampleRate) ~/ 1000;
    final dataSize = pcmData != null
        ? pcmData.length
        : totalSamples * channels * (bitsPerSample ~/ 8);
    final fileSize = 36 + dataSize;

    final bytes = Uint8List(44 + dataSize);
    final bd = ByteData.sublistView(bytes);

    // RIFF chunk
    bytes.setRange(0, 4, 'RIFF'.codeUnits);
    bd.setUint32(4, fileSize, Endian.little);
    bytes.setRange(8, 12, 'WAVE'.codeUnits);

    // fmt subchunk
    bytes.setRange(12, 16, 'fmt '.codeUnits);
    bd.setUint32(16, 16, Endian.little); // Subchunk1Size
    bd.setUint16(20, pcmAudioFormat, Endian.little); // AudioFormat = 1 (PCM)
    bd.setUint16(22, channels, Endian.little); // Mono
    bd.setUint32(24, sampleRate, Endian.little); // 16000
    bd.setUint32(28, sampleRate * channels * 2, Endian.little); // ByteRate = 32000
    bd.setUint16(32, channels * 2, Endian.little); // BlockAlign = 2
    bd.setUint16(34, bitsPerSample, Endian.little); // 16 bits

    // data subchunk
    bytes.setRange(36, 40, 'data'.codeUnits);
    bd.setUint32(40, dataSize, Endian.little);

    if (pcmData != null) {
      bytes.setRange(44, 44 + pcmData.length, pcmData);
    } else {
      // Write samples (sine wave or silence)
      int sampleOffset = 44;
      for (int i = 0; i < totalSamples; i++) {
        final t = i / sampleRate;
        final value =
            (math.sin(2 * math.pi * frequencyHz * t) * amplitude * 32767)
                .round()
                .clamp(-32768, 32767);
        bd.setInt16(sampleOffset, value, Endian.little);
        sampleOffset += 2;
      }
    }

    return bytes;
  }
}
