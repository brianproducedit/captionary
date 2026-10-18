import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:captionary/data/models/cached_transcription.dart';
import 'package:captionary/data/models/subtitle_segment.dart';
import 'package:captionary/data/services/transcription_cache_service.dart';

void main() {
  late Directory tempDir;
  late TranscriptionCacheService cacheService;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('transcription_cache_test_');
    cacheService = TranscriptionCacheService(
      customDirProvider: () async => tempDir,
    );
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('saves and retrieves cached transcription by videoPath', () async {
    final segments = [
      SubtitleSegment(
        index: 1,
        startTime: const Duration(seconds: 1),
        endTime: const Duration(seconds: 3),
        text: 'So Lil Durk',
        isSelected: false,
      ),
    ];

    final item = CachedTranscription(
      videoPath: '/path/to/my_video.mp4',
      mediaId: 'my_video',
      segments: segments,
      detectedLanguage: 'en',
      modelQuality: 'base',
    );

    await cacheService.saveTranscription(item);

    final retrieved = await cacheService.getCachedTranscription(
      videoPath: '/path/to/my_video.mp4',
    );

    expect(retrieved, isNotNull);
    expect(retrieved!.videoPath, '/path/to/my_video.mp4');
    expect(retrieved.mediaId, 'my_video');
    expect(retrieved.segments.length, 1);
    expect(retrieved.segments.first.text, 'So Lil Durk');
    expect(retrieved.detectedLanguage, 'en');
  });

  test('retrieves cached transcription by mediaId fallback', () async {
    final segments = [
      SubtitleSegment(
        index: 1,
        startTime: Duration.zero,
        endTime: const Duration(seconds: 2),
        text: 'Cached content',
        isSelected: false,
      ),
    ];

    final item = CachedTranscription(
      videoPath: '/old/path/video_abc.mp4',
      mediaId: 'video_abc',
      segments: segments,
    );

    await cacheService.saveTranscription(item);

    final retrieved = await cacheService.getCachedTranscription(
      videoPath: '/new/path/video_abc.mp4',
      mediaId: 'video_abc',
    );

    expect(retrieved, isNotNull);
    expect(retrieved!.segments.first.text, 'Cached content');
  });

  test('hasCachedTranscription returns correct boolean', () async {
    expect(
      await cacheService.hasCachedTranscription(videoPath: '/non/existent.mp4'),
      isFalse,
    );

    await cacheService.saveTranscription(
      CachedTranscription(
        videoPath: '/test/video.mp4',
        mediaId: 'video',
        segments: [
          SubtitleSegment(
            index: 1,
            startTime: Duration.zero,
            endTime: const Duration(seconds: 1),
            text: 'Hello',
            isSelected: false,
          ),
        ],
      ),
    );

    expect(
      await cacheService.hasCachedTranscription(videoPath: '/test/video.mp4'),
      isTrue,
    );
  });

  test('deleteCachedTranscription removes entry from memory and disk', () async {
    final item = CachedTranscription(
      videoPath: '/delete/me.mp4',
      mediaId: 'me',
      segments: [
        SubtitleSegment(
          index: 1,
          startTime: Duration.zero,
          endTime: const Duration(seconds: 1),
          text: 'Delete me',
          isSelected: false,
        ),
      ],
    );

    await cacheService.saveTranscription(item);
    expect(await cacheService.hasCachedTranscription(videoPath: '/delete/me.mp4'), isTrue);

    await cacheService.deleteCachedTranscription(
      videoPath: '/delete/me.mp4',
      mediaId: 'me',
    );

    expect(await cacheService.hasCachedTranscription(videoPath: '/delete/me.mp4'), isFalse);
  });

  test('clearAll removes all cached transcriptions', () async {
    await cacheService.saveTranscription(
      CachedTranscription(
        videoPath: '/video1.mp4',
        mediaId: 'v1',
        segments: [
          SubtitleSegment(
            index: 1,
            startTime: Duration.zero,
            endTime: const Duration(seconds: 1),
            text: 'One',
            isSelected: false,
          ),
        ],
      ),
    );
    await cacheService.saveTranscription(
      CachedTranscription(
        videoPath: '/video2.mp4',
        mediaId: 'v2',
        segments: [
          SubtitleSegment(
            index: 1,
            startTime: Duration.zero,
            endTime: const Duration(seconds: 1),
            text: 'Two',
            isSelected: false,
          ),
        ],
      ),
    );

    expect((await cacheService.getAllCached()).length, 2);

    await cacheService.clearAll();

    expect((await cacheService.getAllCached()).length, 0);
  });
}
