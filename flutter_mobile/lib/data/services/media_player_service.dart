import 'dart:io';

import 'package:video_player/video_player.dart';

abstract class MediaPlayerService {
  Future<VideoPlayerController> open(String videoPath);
  Future<void> dispose(VideoPlayerController controller);
}

class VideoPlayerMediaService implements MediaPlayerService {
  @override
  Future<VideoPlayerController> open(String videoPath) async {
    if (videoPath.contains('?') || videoPath.contains('#')) {
      throw const FormatException(
        'This file name cannot be played. Rename it to remove ? or #.',
      );
    }
    final file = File(videoPath);
    if (!file.existsSync()) {
      throw FileSystemException('The video file is missing.', videoPath);
    }
    final controller = VideoPlayerController.file(file);
    await controller.initialize();
    return controller;
  }

  @override
  Future<void> dispose(VideoPlayerController controller) {
    return controller.dispose();
  }
}
