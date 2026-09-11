import 'dart:io';

import 'package:ffmpeg_kit_flutter_new_min_gpl/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/media_information_session.dart';

class FFmpegMetadataService {
  Future<Map<String, dynamic>?> extractMetadata(String filePath) async {
    final MediaInformationSession session =
        await FFprobeKit.getMediaInformation(filePath);
    final information = session.getMediaInformation();

    if (information == null) {
      return null;
    }

    final streams = information.getStreams();
    String resolution = 'Unknown';
    if (streams.isNotEmpty) {
      for (final stream in streams) {
        if (stream.getType() == 'video') {
          final width = stream.getWidth();
          final height = stream.getHeight();
          if (width != null && height != null) {
            resolution = '${width}x$height';
          }
          break;
        }
      }
    }

    final durationStr = information.getDuration();
    Duration duration = Duration.zero;
    if (durationStr != null) {
      try {
        final seconds = double.parse(durationStr);
        duration = Duration(milliseconds: (seconds * 1000).round());
      } catch (_) {}
    }

    int fileSizeBytes = 0;
    try {
      final sizeStr = information.getSize();
      if (sizeStr != null) {
        fileSizeBytes = int.parse(sizeStr);
      } else {
        fileSizeBytes = await File(filePath).length();
      }
    } catch (_) {}

    return {
      'duration': duration,
      'resolution': resolution,
      'sizeBytes': fileSizeBytes,
    };
  }
}
