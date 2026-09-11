import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class AudioPreprocessor {
  /// Extracts audio from [videoPath] and transcodes it to a mono 16kHz WAV file.
  /// Returns the path to the newly created audio file, or null on failure.
  Future<String?> transcodeToMono(String videoPath) async {
    final cacheDir = await getTemporaryDirectory();
    final audioDir = Directory('${cacheDir.path}/audio');

    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }

    final baseName = p.basenameWithoutExtension(videoPath);
    final outputPath = '${audioDir.path}/${baseName}_mono.wav';

    // -y: overwrite
    // -vn: no video
    // -acodec pcm_s16le: 16-bit PCM (standard for Whisper)
    // -ar 16000: 16 kHz sample rate
    // -ac 1: 1 channel (mono)
    final command =
        '-y -i "$videoPath" -vn -acodec pcm_s16le -ar 16000 -ac 1 "$outputPath"';

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (ReturnCode.isSuccess(returnCode)) {
      return outputPath;
    } else {
      final logs = await session.getLogsAsString();
      debugPrint('AudioPreprocessor FFmpeg Error: $logs');
      return null;
    }
  }
}
