import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class FFmpegThumbnailService {
  final Future<Directory> Function()? getTempDirectory;

  FFmpegThumbnailService({this.getTempDirectory});

  /// Extracts a single-frame thumbnail JPG from [videoPath].
  /// Returns the absolute path to the generated thumbnail, or null if failed.
  Future<String?> generateThumbnail(
    String videoPath, {
    String? customThumbnailDir,
  }) async {
    try {
      final Directory thumbDir;
      if (customThumbnailDir != null) {
        thumbDir = Directory(customThumbnailDir);
      } else if (getTempDirectory != null) {
        final dir = await getTempDirectory!();
        thumbDir = Directory('${dir.path}/thumbnails');
      } else {
        final cacheDir = await getTemporaryDirectory();
        thumbDir = Directory('${cacheDir.path}/thumbnails');
      }

      if (!await thumbDir.exists()) {
        await thumbDir.create(recursive: true);
      }

      final fileName = '${const Uuid().v4()}_thumb.jpg';
      final outputPath = '${thumbDir.path}/$fileName';

      // Seek to 1s to capture a meaningful frame; if video is very short, seek to 0s
      final command = buildCommand(
        videoPath: videoPath,
        outputPath: outputPath,
        seekTime: '00:00:01',
      );

      var session = await FFmpegKit.execute(command);
      var returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode) && await File(outputPath).exists()) {
        return outputPath;
      }

      // Fallback seek to 00:00:00 for short clips
      final fallbackCommand = buildCommand(
        videoPath: videoPath,
        outputPath: outputPath,
        seekTime: '00:00:00',
      );

      session = await FFmpegKit.execute(fallbackCommand);
      returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode) && await File(outputPath).exists()) {
        return outputPath;
      }

      // Clean up failed output if left behind
      if (await File(outputPath).exists()) {
        await File(outputPath).delete();
      }
      return null;
    } catch (e) {
      debugPrint('[FFmpegThumbnailService] Failed to generate thumbnail: $e');
      return null;
    }
  }

  /// Deletes a thumbnail file from disk if it exists.
  Future<void> deleteThumbnail(String? thumbnailPath) async {
    if (thumbnailPath == null || thumbnailPath.isEmpty) return;
    try {
      final file = File(thumbnailPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('[FFmpegThumbnailService] Failed to delete thumbnail: $e');
    }
  }

  static String buildCommand({
    required String videoPath,
    required String outputPath,
    String seekTime = '00:00:01',
  }) {
    return '-y -ss $seekTime -i "${_escape(videoPath)}" -vframes 1 -q:v 2 "${_escape(outputPath)}"';
  }

  static String _escape(String path) => path.replaceAll('"', '\\"');
}
