import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/cached_transcription.dart';
import '../data/services/transcription_cache_service.dart';

/// Global provider for the TranscriptionCacheService.
final transcriptionCacheServiceProvider = Provider<TranscriptionCacheService>((
  ref,
) {
  return TranscriptionCacheService();
});

/// Reactive provider to check whether cached captions exist for a specific video path.
final hasCachedTranscriptionProvider = FutureProvider.family<bool, String>((
  ref,
  videoPath,
) async {
  if (videoPath.trim().isEmpty) return false;
  final service = ref.watch(transcriptionCacheServiceProvider);
  return service.hasCachedTranscription(videoPath: videoPath);
});

/// Reactive provider to retrieve cached transcription metadata for a specific video path.
final cachedTranscriptionProvider =
    FutureProvider.family<CachedTranscription?, String>((ref, videoPath) async {
      if (videoPath.trim().isEmpty) return null;
      final service = ref.watch(transcriptionCacheServiceProvider);
      return service.getCachedTranscription(videoPath: videoPath);
    });
