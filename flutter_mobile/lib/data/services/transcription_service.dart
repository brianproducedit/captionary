import '../models/subtitle_segment.dart';

abstract class TranscriptionService {
  Future<List<SubtitleSegment>> transcribeAudio({
    required String audioPath,
    required String languageCode,
    required String modelPath,
  });
  Stream<SubtitleSegment> transcribeAudioStream({
    required String audioPath,
    required String languageCode,
    required String modelPath,
  });
}
