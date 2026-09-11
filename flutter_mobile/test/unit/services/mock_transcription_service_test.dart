import 'package:flutter_test/flutter_test.dart';
import 'package:captionary/data/mock/mock_transcription_service.dart';

void main() {
  group('MockTranscriptionService Tests', () {
    late MockTranscriptionService service;

    setUp(() {
      service = MockTranscriptionService();
    });

    test('transcribeAudio returns segments', () async {
      final segments = await service.transcribeAudio(
        audioPath: 'path',
        languageCode: 'sn',
        modelPath: 'model',
      );
      expect(segments.isNotEmpty, true);
    });

    test('transcribeAudioStream emits segments', () async {
      final stream = service.transcribeAudioStream(
        audioPath: 'path',
        languageCode: 'sn',
        modelPath: 'model',
      );
      final events = await stream.toList();
      expect(events.isNotEmpty, true);
    });
  });
}
