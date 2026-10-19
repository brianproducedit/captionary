import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:captionary/core/waveform_data.dart';
import 'package:captionary/data/mock/mock_audio_extraction_service.dart';
import 'package:captionary/data/services/waveform_extraction_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('waveform_test_');
  });

  tearDown(() {
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  test('extractWaveform extracts peaks from valid PCM WAV', () async {
    final mockAudio = MockAudioExtractionService(
      getTempDirectory: () async => tempDir,
      delay: Duration.zero,
    );
    final service = WaveformExtractionService(
      audioExtractionService: mockAudio,
    );

    final waveform = await service.extractWaveform('dummy_video.mp4');

    expect(waveform.state, WaveformLoadState.ready);
    expect(waveform.peaks, isNotEmpty);
    expect(waveform.displayPeaks, isNotEmpty);
    for (final peak in waveform.peaks) {
      expect(peak, greaterThanOrEqualTo(0.0));
      expect(peak, lessThanOrEqualTo(1.0));
    }

    // Verify caching
    final cached = await service.extractWaveform('dummy_video.mp4');
    expect(identical(waveform, cached), isTrue);
  });

  test('extractWaveform returns noAudio when video path is empty', () async {
    final mockAudio = MockAudioExtractionService();
    final service = WaveformExtractionService(
      audioExtractionService: mockAudio,
    );

    final waveform = await service.extractWaveform('');
    expect(waveform.state, WaveformLoadState.noAudio);
  });

  test('extractWaveform handles audio extraction failure gracefully', () async {
    final mockAudio = MockAudioExtractionService(shouldFail: true);
    final service = WaveformExtractionService(
      audioExtractionService: mockAudio,
    );

    final waveform = await service.extractWaveform('failing_video.mp4');
    expect(waveform.state, WaveformLoadState.noAudio);
  });
}
