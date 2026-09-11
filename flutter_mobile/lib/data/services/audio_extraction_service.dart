abstract class AudioExtractionService {
  Future<String?> extractAudio(String videoPath, {Duration? limit});

  Future<void> cancel();
}
