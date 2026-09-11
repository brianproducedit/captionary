import 'dart:io';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import 'audio_extraction_service.dart';

class AudioPreprocessor implements AudioExtractionService {
  static const _uuid = Uuid();
  FFmpegSession? _activeSession;
  bool _cancelRequested = false;

  /// Extracts audio from [videoPath] and transcodes it to a mono 16kHz WAV file.
  /// Returns the path to the newly created audio file, or null on failure.
  @override
  Future<String?> extractAudio(String videoPath, {Duration? limit}) async {
    final cacheDir = await getTemporaryDirectory();
    final audioDir = Directory('${cacheDir.path}/audio');

    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }

    final baseName = p.basenameWithoutExtension(videoPath);
    final outputPath = '${audioDir.path}/${baseName}_${_uuid.v4()}_mono.wav';
    final command = buildCommand(
      videoPath: videoPath,
      outputPath: outputPath,
      limit: limit,
    );
    final completer = Completer<String?>();
    _cancelRequested = false;

    try {
      final session = await FFmpegKit.executeAsync(command, (
        completedSession,
      ) async {
        _activeSession = null;
        final returnCode = await completedSession.getReturnCode();
        final isSuccess = ReturnCode.isSuccess(returnCode);
        final wasCancelled =
            _cancelRequested || ReturnCode.isCancel(returnCode);

        if (isSuccess && !wasCancelled) {
          completer.complete(outputPath);
        } else {
          if (await File(outputPath).exists()) {
            await File(outputPath).delete();
          }
          if (!wasCancelled) {
            final logs = await completedSession.getLogsAsString();
            debugPrint('AudioPreprocessor FFmpeg Error: $logs');
          }
          completer.complete(null);
        }
      });
      _activeSession = session;

      if (_cancelRequested) {
        await session.cancel();
      }
    } catch (error) {
      debugPrint('AudioPreprocessor FFmpeg start error: $error');
      if (await File(outputPath).exists()) {
        await File(outputPath).delete();
      }
      completer.complete(null);
    }

    return completer.future;
  }

  /// Keeps the existing transcription-provider API while using the real extractor.
  Future<String?> transcodeToMono(String videoPath) async {
    return extractAudio(videoPath);
  }

  @override
  Future<void> cancel() async {
    _cancelRequested = true;
    final session = _activeSession;
    if (session != null) {
      await session.cancel();
    }
  }

  static String buildCommand({
    required String videoPath,
    required String outputPath,
    Duration? limit,
  }) {
    final limitArgument = limit == null ? '' : ' -t ${limit.inSeconds}';
    return '-y -i "${_escape(videoPath)}" -vn$limitArgument '
        '-acodec pcm_s16le -ar 16000 -ac 1 "${_escape(outputPath)}"';
  }

  static String _escape(String path) => path.replaceAll('"', '\\"');
}
