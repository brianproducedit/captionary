import '../services/transcription_service.dart';
import '../models/subtitle_segment.dart';
import 'seed_data.dart';

class MockTranscriptionService implements TranscriptionService {
  @override
  Future<List<SubtitleSegment>> transcribeAudio({
    required String audioPath,
    required String languageCode,
    required String modelPath,
  }) async {
    await Future.delayed(const Duration(seconds: 3));
    return SeedData.sampleSubtitles;
  }

  @override
  Stream<SubtitleSegment> transcribeAudioStream({
    required String audioPath,
    required String languageCode,
    required String modelPath,
  }) async* {
    for (var segment in SeedData.sampleSubtitles) {
      await Future.delayed(const Duration(seconds: 1));
      yield segment;
    }
  }
}
