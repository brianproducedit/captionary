import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:captionary/core/wav_header_validator.dart';
import 'package:captionary/data/models/download_progress.dart';
import 'package:captionary/data/models/language_pack.dart';
import 'package:captionary/data/models/subtitle_segment.dart';
import 'package:captionary/data/services/audio_extraction_service.dart';
import 'package:captionary/data/services/caption_pipeline.dart';
import 'package:captionary/data/services/language_pack_service.dart';
import 'package:captionary/data/services/system_memory_service.dart';
import 'package:captionary/data/services/transcription_service.dart';
import 'package:captionary/providers/caption_pipeline_provider.dart';
import 'package:captionary/providers/language_provider.dart';
import 'package:captionary/providers/subtitle_provider.dart';
import 'package:captionary/providers/transcription_provider.dart';

/// Test implementation of AudioExtractionService for hermetic testing.
class TestAudioExtractionService implements AudioExtractionService {
  final Directory tempDir;
  final bool shouldFail;
  final Duration delay;
  String? lastCreatedAudioPath;
  bool wasCancelled = false;

  TestAudioExtractionService({
    required this.tempDir,
    this.shouldFail = false,
    this.delay = Duration.zero,
  });

  @override
  Future<String?> extractAudio(String videoPath, {Duration? limit}) async {
    wasCancelled = false;
    if (shouldFail) return null;
    if (delay > Duration.zero) {
      await Future.delayed(delay);
    }
    if (wasCancelled) return null;

    final wavFile = File(
      '${tempDir.path}/test_extracted_${DateTime.now().microsecondsSinceEpoch}.wav',
    );
    final bytes = WavHeaderValidator.createPcm16kMonoWav(
      duration: const Duration(seconds: 2),
    );
    await wavFile.writeAsBytes(bytes);
    lastCreatedAudioPath = wavFile.path;
    return wavFile.path;
  }

  @override
  Future<void> cancel() async {
    wasCancelled = true;
  }
}

/// Test implementation of LanguagePackService for hermetic testing.
class TestLanguagePackService implements LanguagePackService {
  List<LanguagePack> languages;
  final bool downloadShouldFail;
  final Duration downloadDelay;
  bool wasDownloadCancelled = false;

  TestLanguagePackService({
    required this.languages,
    this.downloadShouldFail = false,
    this.downloadDelay = Duration.zero,
  });

  @override
  Future<List<LanguagePack>> getAvailableLanguages() async {
    return languages;
  }

  @override
  Future<LanguagePack> getActiveLanguage() async {
    return languages.first;
  }

  @override
  Stream<DownloadProgress> downloadLanguagePack(String code) async* {
    wasDownloadCancelled = false;
    if (downloadShouldFail) {
      throw StateError('Network download failed for language: $code');
    }

    if (downloadDelay > Duration.zero) {
      await Future.delayed(downloadDelay);
    }

    if (wasDownloadCancelled) return;

    yield DownloadProgress(
      languageCode: code,
      downloadedBytes: 50,
      totalBytes: 100,
      speedBytesPerSec: 1000,
      estimatedTimeRemaining: const Duration(seconds: 1),
      state: DownloadState.downloading,
    );

    yield DownloadProgress(
      languageCode: code,
      downloadedBytes: 100,
      totalBytes: 100,
      speedBytesPerSec: 1000,
      estimatedTimeRemaining: Duration.zero,
      state: DownloadState.complete,
    );

    // Update the pack status to installed and create model file if needed
    final idx = languages.indexWhere((l) => l.code == code);
    if (idx != -1) {
      final old = languages[idx];
      final file = File(old.modelFile);
      if (!file.existsSync()) {
        file.writeAsStringSync('mock model binary');
      }
      languages[idx] = old.copyWith(
        status: LanguagePackStatus.installed,
        downloadProgress: 1.0,
      );
    }
  }

  @override
  Future<void> deleteLanguagePack(String code) async {}

  @override
  Future<String> detectLanguage(String audioPath) async {
    return 'en';
  }

  @override
  double getStorageUsedGB() => 1.0;

  @override
  double getStorageTotalGB() => 10.0;
}

/// Test implementation of TranscriptionService for hermetic testing.
class TestTranscriptionService implements TranscriptionService {
  final bool shouldFail;
  final Duration delay;
  final List<SubtitleSegment> segmentsToReturn;
  bool wasCancelled = false;

  TestTranscriptionService({
    this.shouldFail = false,
    this.delay = Duration.zero,
    List<SubtitleSegment>? segments,
  }) : segmentsToReturn =
           segments ??
           [
             SubtitleSegment(
               index: 0,
               startTime: Duration.zero,
               endTime: const Duration(seconds: 2),
               text: 'Hello from test transcription',
               isSelected: false,
             ),
             SubtitleSegment(
               index: 1,
               startTime: const Duration(seconds: 2),
               endTime: const Duration(seconds: 4),
               text: 'Second subtitle segment',
               isSelected: false,
             ),
           ];

  @override
  Future<List<SubtitleSegment>> transcribeAudio({
    required String audioPath,
    required String languageCode,
    required String modelPath,
  }) async {
    final list = <SubtitleSegment>[];
    await for (final s in transcribeAudioStream(
      audioPath: audioPath,
      languageCode: languageCode,
      modelPath: modelPath,
    )) {
      list.add(s);
    }
    return list;
  }

  @override
  Stream<SubtitleSegment> transcribeAudioStream({
    required String audioPath,
    required String languageCode,
    required String modelPath,
  }) async* {
    wasCancelled = false;
    if (shouldFail) {
      throw StateError('Transcription engine internal error.');
    }

    for (final seg in segmentsToReturn) {
      if (delay > Duration.zero) {
        await Future.delayed(delay);
      }
      if (wasCancelled) return;
      yield seg;
    }
  }

  void cancel() {
    wasCancelled = true;
  }
}

void main() {
  late Directory tempDir;
  late File dummyVideoFile;
  late File dummyModelFile;

  setUp(() async {
    CaptionPipeline.clearActiveMediaIds();
    tempDir = await Directory.systemTemp.createTemp('caption_pipeline_test_');

    dummyVideoFile = File('${tempDir.path}/dummy_video.mp4');
    await dummyVideoFile.writeAsString('mock video binary content');

    dummyModelFile = File('${tempDir.path}/ggml-model.bin');
    await dummyModelFile.writeAsString('mock model file content');
  });

  tearDown(() async {
    CaptionPipeline.clearActiveMediaIds();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('CaptionPipeline Integration Tests', () {
    test('1. Full success flow: transitions through typed states and outputs segments', () async {
      final audioService = TestAudioExtractionService(tempDir: tempDir);
      final langService = TestLanguagePackService(
        languages: [
          LanguagePack(
            code: 'en',
            name: 'English',
            nativeName: 'English',
            region: 'Global',
            modelFile: dummyModelFile.path,
            sizeBytes: 100,
            sha256: 'abc',
            accuracy: '95%',
            engine: 'whisper',
            isBundled: false,
            priority: 1,
            status: LanguagePackStatus.installed,
            downloadProgress: 1.0,
          ),
        ],
      );
      final transService = TestTranscriptionService();

      final statesObserved = <CaptionPipelineStatus>[];

      final pipeline = CaptionPipeline(
        audioExtractionService: audioService,
        languagePackService: langService,
        transcriptionService: transService,
        onStateChange: (st) => statesObserved.add(st.status),
      );

      final segments = await pipeline.run(
        videoPath: dummyVideoFile.path,
        mediaId: 'media_success_1',
      );

      expect(segments.length, 2);
      expect(segments.first.text, 'Hello from test transcription');
      expect(pipeline.state.status, CaptionPipelineStatus.ready);

      // Verify sequence of typed states
      expect(
        statesObserved,
        containsAllInOrder([
          CaptionPipelineStatus.importing,
          CaptionPipelineStatus.extracting,
          CaptionPipelineStatus.detecting,
          CaptionPipelineStatus.checkingModel,
          CaptionPipelineStatus.transcribing,
          CaptionPipelineStatus.merging,
          CaptionPipelineStatus.ready,
        ]),
      );

      // Verify temp audio file was deleted in finally
      expect(audioService.lastCreatedAudioPath, isNotNull);
      expect(File(audioService.lastCreatedAudioPath!).existsSync(), isFalse);
    });

    test('2. Offline cached model skips downloadingModel state', () async {
      final audioService = TestAudioExtractionService(tempDir: tempDir);
      final langService = TestLanguagePackService(
        languages: [
          LanguagePack(
            code: 'en',
            name: 'English',
            nativeName: 'English',
            region: 'Global',
            modelFile: dummyModelFile.path,
            sizeBytes: 100,
            sha256: 'abc',
            accuracy: '95%',
            engine: 'whisper',
            isBundled: true,
            priority: 1,
            status: LanguagePackStatus.installed,
            downloadProgress: 1.0,
          ),
        ],
      );
      final transService = TestTranscriptionService();
      final statesObserved = <CaptionPipelineStatus>[];

      final pipeline = CaptionPipeline(
        audioExtractionService: audioService,
        languagePackService: langService,
        transcriptionService: transService,
        onStateChange: (st) => statesObserved.add(st.status),
      );

      await pipeline.run(
        videoPath: dummyVideoFile.path,
        mediaId: 'media_cached_1',
      );

      expect(
        statesObserved.contains(CaptionPipelineStatus.downloadingModel),
        isFalse,
      );
      expect(
        statesObserved.contains(CaptionPipelineStatus.transcribing),
        isTrue,
      );
      expect(pipeline.state.status, CaptionPipelineStatus.ready);
    });

    test(
      '3. Missing model triggers downloadingModel then completes transcribing',
      () async {
        final missingModelFile = File('${tempDir.path}/downloaded_model.bin');

        final audioService = TestAudioExtractionService(tempDir: tempDir);
        final langService = TestLanguagePackService(
          languages: [
            LanguagePack(
              code: 'en',
              name: 'English',
              nativeName: 'English',
              region: 'Global',
              modelFile: missingModelFile.path,
              sizeBytes: 100,
              sha256: 'abc',
              accuracy: '95%',
              engine: 'whisper',
              isBundled: false,
              priority: 1,
              status: LanguagePackStatus.notDownloaded,
              downloadProgress: 0.0,
            ),
          ],
        );
        final transService = TestTranscriptionService();
        final statesObserved = <CaptionPipelineStatus>[];

        final pipeline = CaptionPipeline(
          audioExtractionService: audioService,
          languagePackService: langService,
          transcriptionService: transService,
          onStateChange: (st) => statesObserved.add(st.status),
        );

        final segments = await pipeline.run(
          videoPath: dummyVideoFile.path,
          mediaId: 'media_download_1',
        );

        expect(
          statesObserved,
          contains(CaptionPipelineStatus.downloadingModel),
        );
        expect(statesObserved, contains(CaptionPipelineStatus.transcribing));
        expect(pipeline.state.status, CaptionPipelineStatus.ready);
        expect(segments.isNotEmpty, isTrue);
      },
    );

    test('4. Network failure during model download transitions to error and cleans up', () async {
      final missingModelFile = File('${tempDir.path}/missing.bin');
      final audioService = TestAudioExtractionService(tempDir: tempDir);
      final langService = TestLanguagePackService(
        languages: [
          LanguagePack(
            code: 'en',
            name: 'English',
            nativeName: 'English',
            region: 'Global',
            modelFile: missingModelFile.path,
            sizeBytes: 100,
            sha256: 'abc',
            accuracy: '95%',
            engine: 'whisper',
            isBundled: false,
            priority: 1,
            status: LanguagePackStatus.notDownloaded,
            downloadProgress: 0.0,
          ),
        ],
        downloadShouldFail: true,
      );
      final transService = TestTranscriptionService();

      final pipeline = CaptionPipeline(
        audioExtractionService: audioService,
        languagePackService: langService,
        transcriptionService: transService,
      );

      await expectLater(
        pipeline.run(
          videoPath: dummyVideoFile.path,
          mediaId: 'media_net_fail_1',
        ),
        throwsA(isA<StateError>()),
      );

      // Verify temp audio was deleted in finally
      expect(audioService.lastCreatedAudioPath, isNotNull);
      expect(File(audioService.lastCreatedAudioPath!).existsSync(), isFalse);
    });

    test(
      '5. Transcription failure transitions to error and cleans up',
      () async {
        final audioService = TestAudioExtractionService(tempDir: tempDir);
        final langService = TestLanguagePackService(
          languages: [
            LanguagePack(
              code: 'en',
              name: 'English',
              nativeName: 'English',
              region: 'Global',
              modelFile: dummyModelFile.path,
              sizeBytes: 100,
              sha256: 'abc',
              accuracy: '95%',
              engine: 'whisper',
              isBundled: false,
              priority: 1,
              status: LanguagePackStatus.installed,
              downloadProgress: 1.0,
            ),
          ],
        );
        final transService = TestTranscriptionService(shouldFail: true);

        final pipeline = CaptionPipeline(
          audioExtractionService: audioService,
          languagePackService: langService,
          transcriptionService: transService,
        );

        await expectLater(
          pipeline.run(
            videoPath: dummyVideoFile.path,
            mediaId: 'media_trans_fail_1',
          ),
          throwsA(isA<StateError>()),
        );

        expect(audioService.lastCreatedAudioPath, isNotNull);
        expect(File(audioService.lastCreatedAudioPath!).existsSync(), isFalse);
      },
    );

    test(
      '6. Cancel during transcription sets cancelled state and cleans up',
      () async {
        final audioService = TestAudioExtractionService(tempDir: tempDir);
        final langService = TestLanguagePackService(
          languages: [
            LanguagePack(
              code: 'en',
              name: 'English',
              nativeName: 'English',
              region: 'Global',
              modelFile: dummyModelFile.path,
              sizeBytes: 100,
              sha256: 'abc',
              accuracy: '95%',
              engine: 'whisper',
              isBundled: false,
              priority: 1,
              status: LanguagePackStatus.installed,
              downloadProgress: 1.0,
            ),
          ],
        );
        // Slow transcription stream
        final transService = TestTranscriptionService(
          delay: const Duration(milliseconds: 50),
        );

        final pipeline = CaptionPipeline(
          audioExtractionService: audioService,
          languagePackService: langService,
          transcriptionService: transService,
        );

        final future = pipeline.run(
          videoPath: dummyVideoFile.path,
          mediaId: 'media_cancel_1',
        );

        // Cancel shortly after starting
        await Future.delayed(const Duration(milliseconds: 15));
        pipeline.cancel();

        final segments = await future;
        expect(segments, isEmpty);
        expect(pipeline.state.status, CaptionPipelineStatus.cancelled);

        // Verify temp audio cleanup
        expect(audioService.lastCreatedAudioPath, isNotNull);
        expect(File(audioService.lastCreatedAudioPath!).existsSync(), isFalse);
      },
    );

    test('7. Cleanup verification across multiple runs', () async {
      final audioService = TestAudioExtractionService(tempDir: tempDir);
      final langService = TestLanguagePackService(
        languages: [
          LanguagePack(
            code: 'en',
            name: 'English',
            nativeName: 'English',
            region: 'Global',
            modelFile: dummyModelFile.path,
            sizeBytes: 100,
            sha256: 'abc',
            accuracy: '95%',
            engine: 'whisper',
            isBundled: false,
            priority: 1,
            status: LanguagePackStatus.installed,
            downloadProgress: 1.0,
          ),
        ],
      );
      final transService = TestTranscriptionService();

      final pipeline = CaptionPipeline(
        audioExtractionService: audioService,
        languagePackService: langService,
        transcriptionService: transService,
      );

      await pipeline.run(
        videoPath: dummyVideoFile.path,
        mediaId: 'cleanup_test_1',
      );

      final path1 = audioService.lastCreatedAudioPath!;
      expect(File(path1).existsSync(), isFalse);

      await pipeline.run(
        videoPath: dummyVideoFile.path,
        mediaId: 'cleanup_test_2',
      );

      final path2 = audioService.lastCreatedAudioPath!;
      expect(File(path2).existsSync(), isFalse);
      expect(path1 != path2, isTrue);
    });

    test('8. One run per media ID guard prevents concurrent runs', () async {
      final audioService = TestAudioExtractionService(
        tempDir: tempDir,
        delay: const Duration(milliseconds: 50),
      );
      final langService = TestLanguagePackService(
        languages: [
          LanguagePack(
            code: 'en',
            name: 'English',
            nativeName: 'English',
            region: 'Global',
            modelFile: dummyModelFile.path,
            sizeBytes: 100,
            sha256: 'abc',
            accuracy: '95%',
            engine: 'whisper',
            isBundled: false,
            priority: 1,
            status: LanguagePackStatus.installed,
            downloadProgress: 1.0,
          ),
        ],
      );
      final transService = TestTranscriptionService();

      final pipeline1 = CaptionPipeline(
        audioExtractionService: audioService,
        languagePackService: langService,
        transcriptionService: transService,
      );
      final pipeline2 = CaptionPipeline(
        audioExtractionService: audioService,
        languagePackService: langService,
        transcriptionService: transService,
      );

      final f1 = pipeline1.run(
        videoPath: dummyVideoFile.path,
        mediaId: 'conflict_media_id',
      );

      // Immediately attempt second run with same mediaId
      expect(
        () => pipeline2.run(
          videoPath: dummyVideoFile.path,
          mediaId: 'conflict_media_id',
        ),
        throwsA(isA<CaptionPipelineConflictException>()),
      );

      await f1;

      // After first finishes, running again with same mediaId is allowed
      final f3 = await pipeline2.run(
        videoPath: dummyVideoFile.path,
        mediaId: 'conflict_media_id',
      );
      expect(f3.isNotEmpty, isTrue);
    });

    test('9. Riverpod integration: CaptionPipelineNotifier updates subtitleProvider', () async {
      final audioService = TestAudioExtractionService(tempDir: tempDir);
      final langService = TestLanguagePackService(
        languages: [
          LanguagePack(
            code: 'en',
            name: 'English',
            nativeName: 'English',
            region: 'Global',
            modelFile: dummyModelFile.path,
            sizeBytes: 100,
            sha256: 'abc',
            accuracy: '95%',
            engine: 'whisper',
            isBundled: false,
            priority: 1,
            status: LanguagePackStatus.installed,
            downloadProgress: 1.0,
          ),
        ],
      );
      final expectedSegments = [
        SubtitleSegment(
          index: 0,
          startTime: const Duration(seconds: 1),
          endTime: const Duration(seconds: 3),
          text: 'Real pipeline subtitle 1',
          isSelected: false,
        ),
        SubtitleSegment(
          index: 1,
          startTime: const Duration(seconds: 3),
          endTime: const Duration(seconds: 5),
          text: 'Real pipeline subtitle 2',
          isSelected: false,
        ),
      ];
      final transService = TestTranscriptionService(segments: expectedSegments);

      final container = ProviderContainer(
        overrides: [
          audioExtractionServiceProvider.overrideWithValue(audioService),
          languageServiceProvider.overrideWithValue(langService),
          transcriptionServiceProvider.overrideWithValue(transService),
        ],
      );
      addTearDown(container.dispose);

      // Verify subtitleProvider starts with seed data
      final initialSubtitles = container.read(subtitleProvider);
      expect(initialSubtitles.first.text, contains('Mhoroi mose'));

      // Run pipeline notifier
      final notifier = container.read(captionPipelineProvider.notifier);
      final results = await notifier.run(
        videoPath: dummyVideoFile.path,
        mediaId: 'provider_test_media',
        updateSubtitlesOnSuccess: true,
      );

      expect(results.length, 2);

      // Done when: import -> transcribe -> segments in subtitleProvider without dummy paths
      final updatedSubtitles = container.read(subtitleProvider);
      expect(updatedSubtitles.length, 2);
      expect(updatedSubtitles[0].text, 'Real pipeline subtitle 1');
      expect(updatedSubtitles[1].text, 'Real pipeline subtitle 2');
    });

    test('10. TranscriptionNotifier delegates to CaptionPipeline and updates subtitleProvider', () async {
      final audioService = TestAudioExtractionService(tempDir: tempDir);
      final langService = TestLanguagePackService(
        languages: [
          LanguagePack(
            code: 'en',
            name: 'English',
            nativeName: 'English',
            region: 'Global',
            modelFile: dummyModelFile.path,
            sizeBytes: 100,
            sha256: 'abc',
            accuracy: '95%',
            engine: 'whisper',
            isBundled: false,
            priority: 1,
            status: LanguagePackStatus.installed,
            downloadProgress: 1.0,
          ),
        ],
      );
      final expectedSegments = [
        SubtitleSegment(
          index: 0,
          startTime: const Duration(seconds: 0),
          endTime: const Duration(seconds: 2),
          text: 'Transcribed from TranscriptionNotifier',
          isSelected: false,
        ),
      ];
      final transService = TestTranscriptionService(segments: expectedSegments);

      final container = ProviderContainer(
        overrides: [
          audioExtractionServiceProvider.overrideWithValue(audioService),
          languageServiceProvider.overrideWithValue(langService),
          transcriptionServiceProvider.overrideWithValue(transService),
        ],
      );
      addTearDown(container.dispose);

      final transcriptionNotifier = container.read(
        transcriptionProvider.notifier,
      );
      await transcriptionNotifier.startTranscription(dummyVideoFile.path);

      final transcriptionState = container.read(transcriptionProvider);
      expect(transcriptionState.status, TranscriptionStatus.success);

      final subtitles = container.read(subtitleProvider);
      expect(subtitles.length, 1);
      expect(subtitles.first.text, 'Transcribed from TranscriptionNotifier');
    });

    test('aborts with error state when available RAM is below required model threshold', () async {
      final audioService = TestAudioExtractionService(tempDir: tempDir);
      final langService = TestLanguagePackService(
        languages: [
          LanguagePack(
            code: 'en',
            name: 'English',
            nativeName: 'English',
            region: 'Global',
            modelFile: dummyModelFile.path,
            sizeBytes: 1000000,
            sha256: 'deadbeef',
            accuracy: 'High',
            engine: 'whisper_flutter_new',
            isBundled: true,
            priority: 1,
            status: LanguagePackStatus.installed,
            downloadProgress: 1.0,
          ),
        ],
      );
      final transService = TestTranscriptionService();

      // System memory service reporting only 50 MB available (too low for any whisper model)
      const lowMemoryService = SystemMemoryService(
        overrideTotalRamBytes: 2 * 1024 * 1024 * 1024,
        overrideAvailableRamBytes: 50 * 1024 * 1024,
      );

      final pipeline = CaptionPipeline(
        audioExtractionService: audioService,
        languagePackService: langService,
        transcriptionService: transService,
        systemMemoryService: lowMemoryService,
      );

      final segments = await pipeline.run(
        videoPath: dummyVideoFile.path,
        mediaId: 'low_mem_test',
      );

      expect(segments, isEmpty);
      expect(pipeline.state.status, CaptionPipelineStatus.error);
      expect(pipeline.state.errorMessage, contains('Device memory too low'));
    });
  });
}
