import 'dart:math' as math;

import 'package:whisper_flutter_new/whisper_flutter_new.dart';

import '../data/models/subtitle_segment.dart';

/// Parses raw Whisper output or WhisperTranscribeSegments into normalized
/// SubtitleSegments with offset adjustments, interval clamping, and overlap merging.
class WhisperOutputParser {
  /// Regular expression to match timestamps in standard Whisper / VTT / SRT formats:
  /// Examples:
  ///   [00:00.000 --> 00:05.000] Subtitle text
  ///   [00:00:01.500 --> 00:00:06.200] Subtitle text
  ///   00:01.000 --> 00:04.500 Subtitle text
  static final RegExp timestampRegex = RegExp(
    r'(?:\[)?(?:(\d{1,2}):)?(\d{2}):(\d{2})[\.,](\d{3})\s*-->\s*(?:(\d{1,2}):)?(\d{2}):(\d{2})[\.,](\d{3})(?:\])?\s*(.*)',
  );

  /// Convert a list of native [WhisperTranscribeSegment]s to [SubtitleSegment]s,
  /// applying a [timeOffset] (for chunked audio) and ensuring valid durations.
  static List<SubtitleSegment> parseSegments(
    List<WhisperTranscribeSegment> rawSegments, {
    Duration timeOffset = Duration.zero,
    int startIndex = 0,
  }) {
    final List<SubtitleSegment> result = [];

    for (int i = 0; i < rawSegments.length; i++) {
      final seg = rawSegments[i];
      final text = seg.text.trim();
      if (text.isEmpty) continue;

      var start = seg.fromTs + timeOffset;
      var end = seg.toTs + timeOffset;

      if (start < Duration.zero) start = Duration.zero;
      if (end <= start) {
        end = start + const Duration(milliseconds: 500);
      }

      result.add(
        SubtitleSegment(
          index: startIndex + result.length,
          startTime: start,
          endTime: end,
          text: text,
          isSelected: false,
        ),
      );
    }

    return result;
  }

  /// Parse a raw timestamped string into [SubtitleSegment]s.
  /// If no timestamp patterns are found in the string, fallback to creating a single
  /// segment spanning [timeOffset] to [timeOffset + fallbackDuration].
  static List<SubtitleSegment> parseRawText(
    String rawText, {
    Duration timeOffset = Duration.zero,
    int startIndex = 0,
    Duration fallbackDuration = const Duration(seconds: 3),
  }) {
    final trimmed = rawText.trim();
    if (trimmed.isEmpty) return [];

    final List<SubtitleSegment> parsed = [];
    final lines = trimmed.split('\n');

    for (final line in lines) {
      final lineTrimmed = line.trim();
      if (lineTrimmed.isEmpty) continue;

      final match = timestampRegex.firstMatch(lineTrimmed);
      if (match != null) {
        final startH = int.tryParse(match.group(1) ?? '0') ?? 0;
        final startM = int.tryParse(match.group(2) ?? '0') ?? 0;
        final startS = int.tryParse(match.group(3) ?? '0') ?? 0;
        final startMs = int.tryParse(match.group(4) ?? '0') ?? 0;

        final endH = int.tryParse(match.group(5) ?? '0') ?? 0;
        final endM = int.tryParse(match.group(6) ?? '0') ?? 0;
        final endS = int.tryParse(match.group(7) ?? '0') ?? 0;
        final endMs = int.tryParse(match.group(8) ?? '0') ?? 0;

        final text = (match.group(9) ?? '').trim();
        if (text.isEmpty) continue;

        var start =
            Duration(
              hours: startH,
              minutes: startM,
              seconds: startS,
              milliseconds: startMs,
            ) +
            timeOffset;

        var end =
            Duration(
              hours: endH,
              minutes: endM,
              seconds: endS,
              milliseconds: endMs,
            ) +
            timeOffset;

        if (start < Duration.zero) start = Duration.zero;
        if (end <= start) {
          end = start + const Duration(milliseconds: 500);
        }

        parsed.add(
          SubtitleSegment(
            index: startIndex + parsed.length,
            startTime: start,
            endTime: end,
            text: text,
            isSelected: false,
          ),
        );
      }
    }

    if (parsed.isNotEmpty) {
      return parsed;
    }

    // Fallback if no timestamps were present: treat as single block
    final cleanText = trimmed.replaceAll(RegExp(r'\s+'), ' ');
    return [
      SubtitleSegment(
        index: startIndex,
        startTime: timeOffset,
        endTime: timeOffset + fallbackDuration,
        text: cleanText,
        isSelected: false,
      ),
    ];
  }

  /// Merges segments from sequential / overlapping chunks into a single, clean list:
  /// - Sorts by startTime.
  /// - Removes exact duplicates occurring at chunk overlap boundaries.
  /// - Clamps overlapping durations monotonically (`prev.endTime <= current.startTime`).
  /// - Re-indexes sequentially from 0.
  static List<SubtitleSegment> mergeSegments(List<SubtitleSegment> segments) {
    if (segments.isEmpty) return [];

    final sorted = List<SubtitleSegment>.from(segments)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final List<SubtitleSegment> merged = [];

    for (final current in sorted) {
      if (merged.isEmpty) {
        merged.add(current);
        continue;
      }

      final prev = merged.last;

      // 1. Deduplication: exact or near-identical text within overlap window (<= 3s apart)
      final sameText =
          prev.text.toLowerCase().trim() == current.text.toLowerCase().trim();
      final closeInTime =
          (current.startTime - prev.startTime).abs() <
          const Duration(seconds: 3);

      if (sameText && closeInTime) {
        if (current.endTime > prev.endTime) {
          merged[merged.length - 1] = prev.copyWith(endTime: current.endTime);
        }
        continue;
      }

      // 2. Overlap clamp: if current starts before previous ends, clamp previous endTime
      if (current.startTime < prev.endTime) {
        if (current.startTime > prev.startTime) {
          merged[merged.length - 1] = prev.copyWith(endTime: current.startTime);
        } else {
          final adjustedMs = math.max(
            (current.endTime).inMilliseconds,
            (prev.startTime + const Duration(milliseconds: 500)).inMilliseconds,
          );
          merged.add(
            current.copyWith(
              startTime: prev.startTime + const Duration(milliseconds: 10),
              endTime: Duration(milliseconds: adjustedMs),
            ),
          );
          continue;
        }
      }

      merged.add(current);
    }

    // Re-index cleanly 0..N-1
    return [
      for (int i = 0; i < merged.length; i++) merged[i].copyWith(index: i),
    ];
  }

  /// Consolidates short or fragmented subtitle segments into natural, readable
  /// 1-2 sentence subtitle blocks (typically 2-6.5 seconds, <= 100 characters).
  static List<SubtitleSegment> consolidateSegments(
    List<SubtitleSegment> segments, {
    Duration minDuration = const Duration(milliseconds: 1800),
    Duration maxDuration = const Duration(milliseconds: 6500),
    int maxChars = 100,
    Duration maxGap = const Duration(milliseconds: 1200),
    int maxSentences = 2,
  }) {
    if (segments.isEmpty) return [];

    final sentenceEndRegex = RegExp(r'[.!?。！？](\s*$)');
    final List<SubtitleSegment> consolidated = [];

    SubtitleSegment? currentBlock;
    int sentencesInBlock = 0;

    for (final seg in segments) {
      final text = seg.text.trim();
      if (text.isEmpty) continue;

      if (currentBlock == null) {
        currentBlock = seg.copyWith(text: text);
        sentencesInBlock = sentenceEndRegex.hasMatch(text) ? 1 : 0;
        continue;
      }

      final gap = seg.startTime - currentBlock.endTime;
      final currentDuration = currentBlock.endTime - currentBlock.startTime;
      final combinedDuration = seg.endTime - currentBlock.startTime;
      final combinedText = '${currentBlock.text} $text';

      final bool isSilenceGap =
          gap > maxGap || gap < const Duration(milliseconds: -300);
      final bool exceedsMaxDuration = combinedDuration > maxDuration;
      final bool exceedsMaxChars = combinedText.length > maxChars;
      final bool currentBlockCompletedSentence =
          sentenceEndRegex.hasMatch(currentBlock.text) &&
          currentDuration >= minDuration;
      final bool reachedMaxSentences = sentencesInBlock >= maxSentences;

      if (isSilenceGap ||
          exceedsMaxDuration ||
          exceedsMaxChars ||
          currentBlockCompletedSentence ||
          reachedMaxSentences) {
        consolidated.add(currentBlock);
        currentBlock = seg.copyWith(text: text);
        sentencesInBlock = sentenceEndRegex.hasMatch(text) ? 1 : 0;
      } else {
        final newEnd = seg.endTime > currentBlock.endTime
            ? seg.endTime
            : currentBlock.endTime;
        currentBlock = currentBlock.copyWith(
          endTime: newEnd,
          text: combinedText,
        );
        if (sentenceEndRegex.hasMatch(text)) {
          sentencesInBlock++;
        }
      }
    }

    if (currentBlock != null) {
      consolidated.add(currentBlock);
    }

    return [
      for (int i = 0; i < consolidated.length; i++)
        consolidated[i].copyWith(index: i),
    ];
  }
}
