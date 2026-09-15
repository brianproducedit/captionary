import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock/mock_media_service.dart';
import '../data/models/media_item.dart';
import '../data/services/local_media_service.dart';
import '../data/services/media_service.dart';
import 'backend_mode_provider.dart';

final mediaServiceProvider = Provider<MediaService>((ref) {
  final mode = ref.watch(backendModeProvider);
  switch (mode) {
    case BackendMode.mock:
      return MockMediaService();
    case BackendMode.local:
    case BackendMode.real:
      return LocalMediaService();
  }
});

final recentMediaProvider = FutureProvider<List<MediaItem>>((ref) async {
  final service = ref.watch(mediaServiceProvider);
  return service.getRecentMedia();
});
