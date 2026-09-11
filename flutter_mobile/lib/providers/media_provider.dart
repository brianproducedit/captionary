import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/media_item.dart';
import '../data/services/local_media_service.dart';
import '../data/services/media_service.dart';

final mediaServiceProvider = Provider<MediaService>((ref) {
  return LocalMediaService();
});

final recentMediaProvider = FutureProvider<List<MediaItem>>((ref) async {
  final service = ref.watch(mediaServiceProvider);
  return service.getRecentMedia();
});
