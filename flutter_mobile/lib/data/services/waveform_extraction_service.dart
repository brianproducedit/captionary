import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../core/waveform_data.dart';
import '../../core/wav_header_validator.dart';
import 'audio_extraction_service.dart';

/// Service responsible for extracting audio from video and computing PCM peak amplitudes.
class WaveformExtractionService {
  final AudioExtractionService audioExtractionService;
  final Map<String, WaveformData> _cache = {};

  WaveformExtractionService({required this.audioExtractionService});

  /// Extracts or computes peaks for [videoPath].
  Future<WaveformData> extractWaveform(String videoPath) async {
    if (videoPath.trim().isEmpty) {
      return WaveformData.noAudio('No video path provided.');
    }

    if (_cache.containsKey(videoPath)) {
      return _cache[videoPath]!;
    }

    try {
      // 1. Extract audio if needed
      final audioPath = await audioExtractionService.extractAudio(videoPath);
      if (audioPath == null || !File(audioPath).existsSync()) {
        return WaveformData.noAudio('Audio could not be extracted.');
      }

      final wavFile = File(audioPath);
      final validation = await WavHeaderValidator.validateFile(wavFile);
      if (!validation.isValid ||
          validation.dataOffset == null ||
          validation.dataSize == null) {
        return WaveformData.error('Invalid WAV audio data.');
      }

      final bytes = await wavFile.readAsBytes();
      final dataOffset = validation.dataOffset!;
      final dataSize = validation.dataSize!;

      if (bytes.length < dataOffset + dataSize) {
        return WaveformData.error('Truncated WAV audio data.');
      }

      final byteData = ByteData.sublistView(
        bytes,
        dataOffset,
        dataOffset + dataSize,
      );
      final sampleCount = dataSize ~/ 2; // 16-bit mono = 2 bytes per sample
      if (sampleCount <= 0) {
        return WaveformData.noAudio('Audio contains no samples.');
      }

      // 2. Downsample to target peaks (up to WaveformData.maxDisplayPeaks)
      final targetPeaks = math.min(1000, math.max(100, sampleCount ~/ 160));
      final bucketSize = sampleCount / targetPeaks;
      final peaks = <double>[];
      var maxPeak = 0.0;

      for (var i = 0; i < targetPeaks; i++) {
        final start = (i * bucketSize).floor();
        final end = math.min(sampleCount, ((i + 1) * bucketSize).ceil());
        var peak = 0.0;
        for (var s = start; s < end; s++) {
          final sampleVal = byteData.getInt16(s * 2, Endian.little).abs();
          if (sampleVal > peak) {
            peak = sampleVal.toDouble();
          }
        }
        final normalized = peak / 32768.0;
        peaks.add(normalized);
        if (normalized > maxPeak) {
          maxPeak = normalized;
        }
      }

      // 3. Normalize peaks dynamically so quiet recordings are visible
      if (maxPeak > 0.05) {
        final scale = 0.95 / maxPeak;
        for (var i = 0; i < peaks.length; i++) {
          peaks[i] = (peaks[i] * scale).clamp(0.05, 1.0);
        }
      }

      final data = WaveformData(state: WaveformLoadState.ready, peaks: peaks);
      _cache[videoPath] = data;
      return data;
    } catch (e) {
      debugPrint('WaveformExtractionService error: $e');
      return WaveformData.error('Error extracting waveform: $e');
    }
  }

  void clearCache() {
    _cache.clear();
  }
}
