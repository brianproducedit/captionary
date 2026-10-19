import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/playback_quality.dart';

final playbackQualityProvider = StateProvider<PlaybackQuality>((ref) {
  return PlaybackQuality.auto;
});
