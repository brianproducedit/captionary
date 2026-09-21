import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:captionary/core/constants/app_constants.dart';
import 'package:captionary/providers/backend_mode_provider.dart';
import 'package:captionary/providers/export_provider.dart';
import 'package:captionary/providers/language_provider.dart';
import 'package:captionary/providers/media_provider.dart';
import 'package:captionary/providers/player_provider.dart';
import 'package:captionary/providers/transcription_provider.dart';
import 'package:captionary/data/mock/mock_audio_extraction_service.dart';
import 'package:captionary/data/mock/mock_export_service.dart';
import 'package:captionary/data/mock/mock_language_service.dart';
import 'package:captionary/data/mock/mock_media_player_service.dart';
import 'package:captionary/data/mock/mock_media_service.dart';
import 'package:captionary/data/mock/mock_transcription_service.dart';
import 'package:captionary/data/services/audio_preprocessor.dart';
import 'package:captionary/data/services/ffmpeg_export_service.dart';
import 'package:captionary/data/services/local_media_service.dart';
import 'package:captionary/data/services/media_player_service.dart';
import 'package:captionary/data/services/r2_language_pack_service.dart';
import 'package:captionary/data/services/whisper_transcription_service.dart';

void main() {
  group('BackendMode & Provider Switching', () {
    test('default backendModeProvider is real', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(backendModeProvider), BackendMode.real);
    });

    test('mock mode resolves mock services', () {
      final container = ProviderContainer(
        overrides: [backendModeProvider.overrideWithValue(BackendMode.mock)],
      );
      addTearDown(container.dispose);

      expect(container.read(exportServiceProvider), isA<MockExportService>());
      expect(container.read(mediaServiceProvider), isA<MockMediaService>());
      expect(
        container.read(languageServiceProvider),
        isA<MockLanguageService>(),
      );
      expect(
        container.read(transcriptionServiceProvider),
        isA<MockTranscriptionService>(),
      );
      expect(
        container.read(audioExtractionServiceProvider),
        isA<MockAudioExtractionService>(),
      );
      expect(
        container.read(mediaPlayerServiceProvider),
        isA<MockMediaPlayerService>(),
      );
    });

    test('local mode switches export, media, audio extraction, transcription, language, and player', () {
      final container = ProviderContainer(
        overrides: [backendModeProvider.overrideWithValue(BackendMode.local)],
      );
      addTearDown(container.dispose);

      expect(container.read(exportServiceProvider), isA<FfmpegExportService>());
      expect(container.read(mediaServiceProvider), isA<LocalMediaService>());
      expect(
        container.read(languageServiceProvider),
        isA<R2LanguagePackService>(),
      );
      expect(
        container.read(audioExtractionServiceProvider),
        isA<AudioPreprocessor>(),
      );
      expect(
        container.read(transcriptionServiceProvider),
        isA<WhisperTranscriptionService>(),
      );
      expect(
        container.read(mediaPlayerServiceProvider),
        isA<MediaKitMediaService>(),
      );
    });

    test('real mode switches export, media, audio extraction, transcription, language, and player', () {
      final container = ProviderContainer(
        overrides: [backendModeProvider.overrideWithValue(BackendMode.real)],
      );
      addTearDown(container.dispose);

      expect(container.read(exportServiceProvider), isA<FfmpegExportService>());
      expect(container.read(mediaServiceProvider), isA<LocalMediaService>());
      expect(
        container.read(languageServiceProvider),
        isA<R2LanguagePackService>(),
      );
      expect(
        container.read(audioExtractionServiceProvider),
        isA<AudioPreprocessor>(),
      );
      expect(
        container.read(transcriptionServiceProvider),
        isA<WhisperTranscriptionService>(),
      );
      expect(
        container.read(mediaPlayerServiceProvider),
        isA<MediaKitMediaService>(),
      );
    });
  });

  group('AppConstants Configuration', () {
    test('r2BaseUrl has valid default without pub-xxxx placeholder', () {
      expect(AppConstants.r2BaseUrl, isNot(contains('pub-xxxx')));
      expect(AppConstants.r2BaseUrl.startsWith('https://'), isTrue);
    });

    test('manifestUrl points to manifest.json', () {
      expect(AppConstants.manifestUrl, isNot(contains('pub-xxxx')));
      expect(AppConstants.manifestUrl.endsWith('/manifest.json'), isTrue);
    });

    test('donateWebUrl is valid https url', () {
      expect(AppConstants.donateWebUrl.startsWith('https://'), isTrue);
    });
  });
}
