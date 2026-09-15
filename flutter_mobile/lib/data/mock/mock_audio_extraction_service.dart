import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/wav_header_validator.dart';
import '../services/audio_extraction_service.dart';

class MockAudioExtractionService implements AudioExtractionService {
  static const _uuid = Uuid();
  final bool shouldFail;
  final Duration delay;
  final Future<Directory> Function()? getTempDirectory;
  bool _isCancelled = false;

  MockAudioExtractionService({
    this.shouldFail = false,
    this.delay = const Duration(milliseconds: 50),
    this.getTempDirectory,
  });

  @override
  Future<String?> extractAudio(String videoPath, {Duration? limit}) async {
    _isCancelled = false;
    if (videoPath.trim().isEmpty || shouldFail) {
      return null;
    }

    if (delay > Duration.zero) {
      await Future.delayed(delay);
    }

    if (_isCancelled) {
      return null;
    }

    Directory tempDir;
    if (getTempDirectory != null) {
      tempDir = await getTempDirectory!();
    } else {
      try {
        tempDir = await getTemporaryDirectory();
      } catch (_) {
        tempDir = Directory.systemTemp;
      }
    }

    final audioDir = Directory('${tempDir.path}/audio');
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }

    final wavFile = File('${audioDir.path}/mock_extracted_${_uuid.v4()}.wav');
    final pcmBytes = WavHeaderValidator.createPcm16kMonoWav(
      duration: limit ?? const Duration(seconds: 2),
    );
    await wavFile.writeAsBytes(pcmBytes);

    return wavFile.path;
  }

  @override
  Future<void> cancel() async {
    _isCancelled = true;
  }
}
