import 'dart:io';

import 'package:video_player/video_player.dart';

abstract class MediaPlayerService {
  Future<VideoPlayerController> open(String videoPath);
  Future<void> dispose(VideoPlayerController controller);
}

class VideoPlayerMediaService implements MediaPlayerService {
  @override
  Future<VideoPlayerController> open(String videoPath) async {
    final controller = VideoPlayerController.file(File(videoPath));
    await controller.initialize();
    return controller;
  }

  @override
  Future<void> dispose(VideoPlayerController controller) {
    return controller.dispose();
  }
}
