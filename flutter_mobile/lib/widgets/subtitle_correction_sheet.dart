import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/glass_card.dart';
import '../data/models/subtitle_segment.dart';
import '../providers/subtitle_provider.dart';
import '../providers/player_provider.dart';

class SubtitleCorrectionSheet extends ConsumerStatefulWidget {
  const SubtitleCorrectionSheet({super.key});

  @override
  ConsumerState<SubtitleCorrectionSheet> createState() => _SubtitleCorrectionSheetState();
}

class _SubtitleCorrectionSheetState extends ConsumerState<SubtitleCorrectionSheet> {
  final Map<int, TextEditingController> _controllers = {};

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _getController(SubtitleSegment segment) {
    if (!_controllers.containsKey(segment.index)) {
      _controllers[segment.index] = TextEditingController(text: segment.text);
    }
    return _controllers[segment.index]!;
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final ms = (d.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');
    return '$m:$s.$ms';
  }

  @override
  Widget build(BuildContext context) {
    final segments = ref.watch(subtitleProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12.0, bottom: 8.0),
                decoration: BoxDecoration(
                  color: AppColors.onSurfaceVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Subtitle Correction',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${segments.length} segments',
                      style: AppTypography.captionCode.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.surfaceContainerHigh),
              // Segment list
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16.0),
                  itemCount: segments.length,
                  separatorBuilder: (context, i) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final segment = segments[index];
                    final controller = _getController(segment);
                    
                    // Sync controller text if segment text changed externally
                    if (controller.text != segment.text) {
                      controller.text = segment.text;
                    }

                    return GestureDetector(
                      onTap: () {
                        ref.read(subtitleProvider.notifier).selectSegment(segment.index);
                        ref.read(playerProvider.notifier).seekTo(segment.startTime);
                      },
                      child: GlassCard(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Timecodes row
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '#${segment.index + 1}',
                                    style: AppTypography.captionCode.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(Symbols.schedule, size: 14, color: AppColors.onSurfaceVariant),
                                const SizedBox(width: 4),
                                Text(
                                  '${_formatDuration(segment.startTime)} → ${_formatDuration(segment.endTime)}',
                                  style: AppTypography.captionCode.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Editable text field
                            TextField(
                              controller: controller,
                              onChanged: (text) {
                                ref.read(subtitleProvider.notifier).updateSegmentText(segment.index, text);
                              },
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.onSurface,
                              ),
                              maxLines: null,
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                filled: true,
                                fillColor: AppColors.surfaceContainerHigh,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: AppColors.primary, width: 1),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
