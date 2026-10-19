import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../core/duration_format.dart';
import '../providers/player_provider.dart';
import '../providers/trim_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Interactive Trim Bar widget allowing users to select start & end cut points.
class TrimBar extends ConsumerStatefulWidget {
  const TrimBar({super.key});

  @override
  ConsumerState<TrimBar> createState() => _TrimBarState();
}

class _TrimBarState extends ConsumerState<TrimBar> {
  @override
  Widget build(BuildContext context) {
    final trim = ref.watch(trimProvider);
    final player = ref.watch(playerProvider);
    final totalDuration = player.duration;

    if (totalDuration <= Duration.zero) {
      return const SizedBox.shrink();
    }

    final totalSeconds = totalDuration.inMilliseconds / 1000.0;
    final startSeconds = (trim.start.inMilliseconds / 1000.0).clamp(
      0.0,
      totalSeconds,
    );
    final endSeconds =
        ((trim.end?.inMilliseconds ?? totalDuration.inMilliseconds) / 1000.0)
            .clamp(startSeconds, totalSeconds);

    final effectiveEnd = trim.end ?? totalDuration;
    final trimmedDuration = (effectiveEnd - trim.start).isNegative
        ? Duration.zero
        : (effectiveEnd - trim.start);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: trim.isEnabled
              ? AppColors.primary.withValues(alpha: 0.6)
              : AppColors.surfaceContainerHigh,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                Symbols.content_cut,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Video Trim Range',
                style: AppTypography.labelLg.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              const Spacer(),
              Text(
                '${formatPlayerTime(trim.start)} - ${formatPlayerTime(effectiveEnd)} (${formatPlayerTime(trimmedDuration)})',
                style: AppTypography.captionCode.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 8),
              if (trim.isEnabled)
                IconButton(
                  tooltip: 'Reset Trim',
                  icon: const Icon(
                    Symbols.restart_alt,
                    size: 18,
                    color: AppColors.onSurfaceVariant,
                  ),
                  onPressed: () {
                    ref.read(trimProvider.notifier).reset();
                  },
                ),
            ],
          ),
          const SizedBox(height: 6),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 6.0,
              rangeTrackShape: const RoundedRectRangeSliderTrackShape(),
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.surfaceContainerHighest,
              rangeThumbShape: const RoundRangeSliderThumbShape(
                enabledThumbRadius: 8.0,
                elevation: 4.0,
              ),
              thumbColor: AppColors.allWhite,
              overlayColor: AppColors.primary.withValues(alpha: 0.2),
            ),
            child: RangeSlider(
              values: RangeValues(startSeconds, endSeconds),
              min: 0.0,
              max: totalSeconds > 0 ? totalSeconds : 1.0,
              onChanged: (RangeValues values) {
                final newStart = Duration(
                  milliseconds: (values.start * 1000).round(),
                );
                final newEnd = Duration(
                  milliseconds: (values.end * 1000).round(),
                );
                ref
                    .read(trimProvider.notifier)
                    .setTrim(start: newStart, end: newEnd);
              },
            ),
          ),
        ],
      ),
    );
  }
}
