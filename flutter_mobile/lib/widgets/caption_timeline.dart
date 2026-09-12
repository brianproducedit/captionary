import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../core/duration_format.dart';
import '../core/timeline_mapping.dart';
import '../core/waveform_data.dart';
import '../data/models/subtitle_segment.dart';
import '../providers/player_provider.dart';
import '../providers/subtitle_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import 'draggable_timeline_chip.dart';
import 'glass_card.dart';
import 'waveform_painter.dart';

class CaptionTimeline extends ConsumerStatefulWidget {
  final WaveformData waveform;
  final VoidCallback? onOpenCaptionList;

  const CaptionTimeline({
    super.key,
    required this.waveform,
    this.onOpenCaptionList,
  });

  @override
  ConsumerState<CaptionTimeline> createState() => _CaptionTimelineState();
}

class _CaptionTimelineState extends ConsumerState<CaptionTimeline> {
  double _pixelsPerSecond = TimelineMapping.defaultPixelsPerSecond;
  bool _snap = false;
  final _scroll = ScrollController();
  final _textController = TextEditingController();
  final _textFocus = FocusNode();
  int? _boundIndex;

  @override
  void dispose() {
    _scroll.dispose();
    _textController.dispose();
    _textFocus.dispose();
    super.dispose();
  }

  void _syncEditor(List<SubtitleSegment> segments) {
    SubtitleSegment? selected;
    for (final segment in segments) {
      if (segment.isSelected) {
        selected = segment;
        break;
      }
    }
    if (selected == null) {
      if (_boundIndex != null) {
        _boundIndex = null;
        _textController.clear();
      }
      return;
    }
    if (_boundIndex != selected.index ||
        (!_textFocus.hasFocus && _textController.text != selected.text)) {
      _boundIndex = selected.index;
      _textController.text = selected.text;
    }
  }

  TimelineMapping _mapping(Duration duration) {
    return TimelineMapping(
      pixelsPerSecond: _pixelsPerSecond,
      duration: duration,
      snapEnabled: _snap,
    );
  }

  Duration _deltaFromDx(TimelineMapping mapping, double dx) {
    return mapping.xToTime(dx) - mapping.xToTime(0);
  }

  @override
  Widget build(BuildContext context) {
    final segments = ref.watch(subtitleProvider);
    final player = ref.watch(playerProvider);
    final duration = TimelineMapping.mediaDuration(
      playerDuration: player.duration,
      segments: segments,
    );
    final mapping = _mapping(duration);
    _syncEditor(segments);

    final progress = duration.inMilliseconds == 0
        ? 0.0
        : (player.position.inMilliseconds / duration.inMilliseconds).clamp(
            0.0,
            1.0,
          );

    return GlassCard(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _toolbar(context, mapping, duration),
            const SizedBox(height: 8),
            _statusBanner(),
            const SizedBox(height: 8),
            SizedBox(
              height: 132,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = mapping.totalWidth < constraints.maxWidth
                      ? constraints.maxWidth
                      : mapping.totalWidth;
                  return SingleChildScrollView(
                    controller: _scroll,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: width,
                      child: Stack(
                        clipBehavior: Clip.hardEdge,
                        children: [
                          Positioned(
                            left: 0,
                            right: 0,
                            top: 0,
                            height: 18,
                            child: CustomPaint(
                              painter: _TimeRulerPainter(mapping: mapping),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            top: 20,
                            height: 44,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTapDown: (details) => _seekToX(
                                mapping,
                                details.localPosition.dx,
                              ),
                              child: widget.waveform.displayPeaks.isEmpty
                                  ? const ColoredBox(
                                      color: AppColors.surfaceContainerHighest,
                                    )
                                  : CustomPaint(
                                      painter: WaveformPainter(
                                        progress: progress,
                                        peaks: widget.waveform.displayPeaks,
                                      ),
                                    ),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            top: 68,
                            height: 56,
                            child: Stack(
                              children: [
                                for (final segment in segments)
                                  Positioned(
                                    left: mapping.timeToX(segment.startTime),
                                    child: DraggableTimelineChip(
                                      key: ValueKey('chip-${segment.index}'),
                                      segment: segment,
                                      isSelected: segment.isSelected,
                                      isActive:
                                          player.position >= segment.startTime &&
                                          player.position <= segment.endTime,
                                      width:
                                          mapping.timeToX(segment.endTime) -
                                          mapping.timeToX(segment.startTime),
                                      onTap: () {
                                        ref
                                            .read(subtitleProvider.notifier)
                                            .selectSegment(segment.index);
                                        ref
                                            .read(playerProvider.notifier)
                                            .seekTo(
                                              mapping.snap(segment.startTime),
                                            );
                                      },
                                      onDragStart: () {
                                        ref
                                            .read(subtitleProvider.notifier)
                                            .checkpoint();
                                      },
                                      onMoveDx: (dx) {
                                        ref
                                            .read(subtitleProvider.notifier)
                                            .moveSegment(
                                              segment.index,
                                              _deltaFromDx(mapping, dx),
                                              mediaDuration: duration,
                                              recordHistory: false,
                                            );
                                      },
                                      onTrimStartDx: (dx) {
                                        final next = mapping.snap(
                                          segment.startTime +
                                              _deltaFromDx(mapping, dx),
                                        );
                                        ref
                                            .read(subtitleProvider.notifier)
                                            .trimStart(
                                              segment.index,
                                              next,
                                              recordHistory: false,
                                            );
                                      },
                                      onTrimEndDx: (dx) {
                                        final next = mapping.snap(
                                          segment.endTime +
                                              _deltaFromDx(mapping, dx),
                                        );
                                        ref
                                            .read(subtitleProvider.notifier)
                                            .trimEnd(
                                              segment.index,
                                              next,
                                              mediaDuration: duration,
                                              recordHistory: false,
                                            );
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Positioned(
                            left: mapping.timeToX(player.position) - 6,
                            top: 0,
                            bottom: 0,
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onHorizontalDragUpdate: (details) {
                                final x =
                                    mapping.timeToX(player.position) +
                                    details.delta.dx;
                                _seekToX(mapping, x);
                              },
                              child: SizedBox(
                                width: 12,
                                child: Center(
                                  child: Container(
                                    width: 2,
                                    color: AppColors.secondary,
                                    child: Align(
                                      alignment: Alignment.topCenter,
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        margin: const EdgeInsets.only(top: 2),
                                        decoration: const BoxDecoration(
                                          color: AppColors.secondary,
                                          shape: BoxShape.circle,
                                          boxShadow: [AppShadows.glowSupport],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
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
            const SizedBox(height: 8),
            TextField(
              key: const Key('caption-text-field'),
              controller: _textController,
              focusNode: _textFocus,
              enabled: _boundIndex != null,
              minLines: 1,
              maxLines: 3,
              textInputAction: TextInputAction.done,
              onSubmitted: _commitText,
              decoration: InputDecoration(
                labelText: 'Caption text',
                hintText: 'Select a caption to edit',
                filled: true,
                fillColor: AppColors.surfaceContainerHigh,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _seekToX(TimelineMapping mapping, double x) {
    ref.read(playerProvider.notifier).seekTo(mapping.snap(mapping.xToTime(x)));
  }

  void _commitText(String value) {
    final index = _boundIndex;
    if (index == null) return;
    ref.read(subtitleProvider.notifier).updateSegmentText(index, value);
    _textFocus.unfocus();
  }

  Widget _statusBanner() {
    final data = widget.waveform;
    final color = switch (data.state) {
      WaveformLoadState.loading => AppColors.primary,
      WaveformLoadState.ready => AppColors.tertiary,
      WaveformLoadState.lowMemory => AppColors.attentionYellow,
      WaveformLoadState.error => AppColors.error,
      WaveformLoadState.noAudio => AppColors.onSurfaceVariant,
    };
    return Row(
      children: [
        Icon(Symbols.graphic_eq, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            data.message.isEmpty ? 'Waveform' : data.message,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }

  Widget _toolbar(
    BuildContext context,
    TimelineMapping mapping,
    Duration duration,
  ) {
    final notifier = ref.read(subtitleProvider.notifier);
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          formatClockHms(ref.watch(playerProvider).position),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        _tool(Symbols.zoom_out, 'Zoom out', () {
          setState(() {
            _pixelsPerSecond = TimelineMapping.clampZoom(_pixelsPerSecond / 1.25);
          });
        }),
        _tool(Symbols.zoom_in, 'Zoom in', () {
          setState(() {
            _pixelsPerSecond = TimelineMapping.clampZoom(_pixelsPerSecond * 1.25);
          });
        }),
        _tool(
          _snap ? Symbols.grid_on : Symbols.grid_off,
          _snap ? 'Snap on' : 'Snap off',
          () => setState(() => _snap = !_snap),
        ),
        _tool(Symbols.restart_alt, 'Reset zoom', () {
          setState(() {
            _pixelsPerSecond = TimelineMapping.defaultPixelsPerSecond;
            _snap = false;
          });
          if (_scroll.hasClients) {
            _scroll.jumpTo(0);
          }
        }),
        _tool(Symbols.content_cut, 'Split at playhead', () {
          notifier.splitSelected(ref.read(playerProvider).position);
        }),
        _tool(Symbols.merge_type, 'Merge with next', notifier.mergeSelected),
        _tool(Symbols.content_copy, 'Duplicate', () {
          notifier.duplicateSelected(mediaDuration: duration);
        }),
        _tool(Symbols.delete, 'Delete caption', notifier.deleteSelected),
        if (widget.onOpenCaptionList != null)
          _tool(Symbols.edit_note, 'All captions', widget.onOpenCaptionList!),
      ],
    );
  }

  Widget _tool(IconData icon, String tooltip, VoidCallback onTap) {
    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      onPressed: onTap,
      icon: Icon(icon, size: 20),
    );
  }
}

class _TimeRulerPainter extends CustomPainter {
  final TimelineMapping mapping;

  _TimeRulerPainter({required this.mapping});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.outlineVariant
      ..strokeWidth = 1;
    final seconds = mapping.duration.inSeconds;
    final step = mapping.pixelsPerSecond >= 80 ? 1 : 2;
    for (var s = 0; s <= seconds; s += step) {
      final x = mapping.timeToX(Duration(seconds: s));
      canvas.drawLine(Offset(x, 10), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TimeRulerPainter oldDelegate) {
    return oldDelegate.mapping.pixelsPerSecond != mapping.pixelsPerSecond ||
        oldDelegate.mapping.duration != mapping.duration;
  }
}
