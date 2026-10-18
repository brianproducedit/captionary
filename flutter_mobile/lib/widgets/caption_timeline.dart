import 'dart:async';

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

  /// Timer and flag to group live keystrokes into a single undo checkpoint.
  Timer? _debounceTypingTimer;
  bool _isTypingSession = false;

  /// Whether the user is actively touching/dragging the timeline or an element.
  bool _userScrolling = false;

  /// Whether a programmatic animateTo scroll is currently running.
  bool _isAutoScrolling = false;

  /// Whether the timeline should follow the playhead during playback.
  bool _autoFollow = true;

  /// Ensures initial viewport jumps directly to playhead (e.g. video at 4 minutes).
  bool _initialScrollDone = false;

  /// Smooth playhead dragging state
  bool _draggingPlayhead = false;
  double _dragPlayheadX = 0;

  /// Tracks last observed player position to detect manual seeks while paused.
  Duration _lastObservedPosition = Duration.zero;

  @override
  void initState() {
    super.initState();
    _textFocus.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _debounceTypingTimer?.cancel();
    _textFocus.removeListener(_onFocusChange);
    _scroll.dispose();
    _textController.dispose();
    _textFocus.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_textFocus.hasFocus) {
      final index = _boundIndex;
      if (index != null) {
        _debounceTypingTimer?.cancel();
        _isTypingSession = false;
        ref.read(subtitleProvider.notifier).updateSegmentText(
          index,
          _textController.text,
          recordHistory: false,
        );
      }
    }
  }

  void _onTextChanged(String value) {
    final index = _boundIndex;
    if (index == null) return;

    // Checkpoint undo history once at the start of a typing sequence
    if (!_isTypingSession) {
      _isTypingSession = true;
      ref.read(subtitleProvider.notifier).checkpoint();
    }

    // Immediately update the segment in real-time so overlay & chip reflect text
    ref.read(subtitleProvider.notifier).updateSegmentText(
      index,
      value,
      recordHistory: false,
    );

    _debounceTypingTimer?.cancel();
    _debounceTypingTimer = Timer(const Duration(milliseconds: 800), () {
      _isTypingSession = false;
    });
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

  /// Centers or scrolls the timeline so the playhead sits comfortably in view.
  void _scrollToPlayhead(
    double playheadX,
    double viewportWidth, {
    bool instant = false,
  }) {
    if (!_scroll.hasClients) return;

    final maxOffset = _scroll.position.maxScrollExtent;
    final targetOffset = (playheadX - viewportWidth * 0.35).clamp(
      0.0,
      maxOffset,
    );

    // If target is far away (> 1 screen), jump directly to avoid long scrolling lag
    if (instant || (playheadX - _scroll.offset).abs() > viewportWidth * 1.5) {
      _scroll.jumpTo(targetOffset);
      return;
    }

    if (_isAutoScrolling) return;

    final currentOffset = _scroll.offset;
    final visibleLeft = currentOffset;
    final visibleRight = currentOffset + viewportWidth;
    const edgeMargin = 40.0;

    // Already comfortably in view
    if (playheadX >= visibleLeft + edgeMargin &&
        playheadX <= visibleRight - edgeMargin) {
      return;
    }

    _isAutoScrolling = true;
    _scroll
        .animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        )
        .whenComplete(() {
          _isAutoScrolling = false;
        });
  }

  /// Called on playback ticks to advance viewport smoothly when playhead nears right edge.
  void _autoScrollToPlayhead(double playheadX, double viewportWidth) {
    if (_userScrolling ||
        !_autoFollow ||
        !_scroll.hasClients ||
        _isAutoScrolling) {
      return;
    }

    final currentOffset = _scroll.offset;
    final visibleRight = currentOffset + viewportWidth;
    final visibleLeft = currentOffset;

    // If playhead jumped outside visible region (e.g. video resumed or seeked)
    if (playheadX < visibleLeft || playheadX > visibleRight) {
      _scrollToPlayhead(
        playheadX,
        viewportWidth,
        instant: (playheadX - currentOffset).abs() > viewportWidth,
      );
      return;
    }

    // When playhead reaches near the right edge (within 60px), glide viewport forward
    if (playheadX >= visibleRight - 60.0) {
      final maxOffset = _scroll.position.maxScrollExtent;
      final targetOffset = (playheadX - viewportWidth * 0.35).clamp(
        0.0,
        maxOffset,
      );

      _isAutoScrolling = true;
      _scroll
          .animateTo(
            targetOffset,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
          )
          .whenComplete(() {
            _isAutoScrolling = false;
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    final segments = ref.watch(subtitleProvider);
    final player = ref.watch(playerProvider);
    final duration = TimelineMapping.mediaDuration(
      playerDuration: player.duration,
      segments: segments,
      position: player.position,
    );
    final mapping = _mapping(duration);
    _syncEditor(segments);

    final progress = duration.inMilliseconds == 0
        ? 0.0
        : (player.position.inMilliseconds / duration.inMilliseconds).clamp(
            0.0,
            1.0,
          );

    // Detect manual seek while paused or external position skip
    final posDelta = (player.position - _lastObservedPosition).abs();
    final didSeek = posDelta > const Duration(seconds: 1);
    _lastObservedPosition = player.position;

    return GlassCard(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _toolbar(context, mapping, duration, player),
            const SizedBox(height: 8),
            _statusBanner(),
            const SizedBox(height: 8),
            SizedBox(
              height: 136,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final viewportWidth = constraints.maxWidth;
                  final width = mapping.totalWidth < viewportWidth
                      ? viewportWidth
                      : mapping.totalWidth;

                  final normalPlayheadX = mapping.timeToX(player.position);
                  final playheadX = _draggingPlayhead
                      ? _dragPlayheadX
                      : normalPlayheadX;

                  // Schedule auto-scroll or initial jump
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted || !_scroll.hasClients) return;

                    if (!_initialScrollDone) {
                      _initialScrollDone = true;
                      _scrollToPlayhead(
                        playheadX,
                        viewportWidth,
                        instant: true,
                      );
                      return;
                    }

                    if (didSeek && _autoFollow) {
                      _scrollToPlayhead(
                        playheadX,
                        viewportWidth,
                        instant:
                            (playheadX - _scroll.offset).abs() > viewportWidth,
                      );
                      return;
                    }

                    if (player.isPlaying && _autoFollow && !_userScrolling) {
                      _autoScrollToPlayhead(playheadX, viewportWidth);
                    }
                  });

                  final hasScroll = _scroll.hasClients;
                  final currentScrollOffset = hasScroll ? _scroll.offset : 0.0;
                  final isPlayheadLeft =
                      hasScroll && playheadX < currentScrollOffset - 20;
                  final isPlayheadRight =
                      hasScroll &&
                      playheadX > currentScrollOffset + viewportWidth + 20;

                  return Stack(
                    children: [
                      NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          if (notification is ScrollStartNotification &&
                              notification.dragDetails != null) {
                            // User manually dragged the scroll view
                            _userScrolling = true;
                            _autoFollow = false;
                          } else if (notification is ScrollEndNotification) {
                            _userScrolling = false;
                            setState(() {});
                          } else if (notification is ScrollUpdateNotification) {
                            // Trigger repaint for off-screen indicator visibility
                            if (!_isAutoScrolling) {
                              setState(() {});
                            }
                          }
                          return false;
                        },
                        child: SingleChildScrollView(
                          controller: _scroll,
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: SizedBox(
                            width: width,
                            child: Stack(
                              clipBehavior: Clip.hardEdge,
                              children: [
                                // --- Interactive Time ruler with labels ---
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  top: 0,
                                  height: 20,
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTapDown: (details) => _seekToX(
                                      mapping,
                                      details.localPosition.dx,
                                    ),
                                    child: CustomPaint(
                                      painter: _TimeRulerPainter(
                                        mapping: mapping,
                                      ),
                                    ),
                                  ),
                                ),
                                // --- Waveform / empty track ---
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  top: 22,
                                  height: 44,
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTapDown: (details) => _seekToX(
                                      mapping,
                                      details.localPosition.dx,
                                    ),
                                    child: widget.waveform.displayPeaks.isEmpty
                                        ? const ColoredBox(
                                            color: AppColors
                                                .surfaceContainerHighest,
                                          )
                                        : CustomPaint(
                                            painter: WaveformPainter(
                                              progress: progress,
                                              peaks:
                                                  widget.waveform.displayPeaks,
                                            ),
                                          ),
                                  ),
                                ),
                                // --- Caption chips ---
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  top: 70,
                                  height: 56,
                                  child: Stack(
                                    children: [
                                      for (final segment in segments)
                                        Positioned(
                                          left: mapping.timeToX(
                                            segment.startTime,
                                          ),
                                          child: DraggableTimelineChip(
                                            key: ValueKey(
                                              'chip-${segment.index}',
                                            ),
                                            segment: segment,
                                            isSelected: segment.isSelected,
                                            isActive:
                                                player.position >=
                                                    segment.startTime &&
                                                player.position <=
                                                    segment.endTime,
                                            width:
                                                mapping.timeToX(
                                                  segment.endTime,
                                                ) -
                                                mapping.timeToX(
                                                  segment.startTime,
                                                ),
                                            onTap: () {
                                              ref
                                                  .read(
                                                    subtitleProvider.notifier,
                                                  )
                                                  .selectSegment(segment.index);
                                              ref
                                                  .read(playerProvider.notifier)
                                                  .seekTo(
                                                    mapping.snap(
                                                      segment.startTime,
                                                    ),
                                                  );
                                              setState(
                                                () => _autoFollow = true,
                                              );
                                              _scrollToPlayhead(
                                                mapping.timeToX(
                                                  segment.startTime,
                                                ),
                                                viewportWidth,
                                              );
                                            },
                                            onDragStart: () {
                                              _userScrolling = true;
                                              ref
                                                  .read(
                                                    subtitleProvider.notifier,
                                                  )
                                                  .checkpoint();
                                            },
                                            onDragEnd: () {
                                              _userScrolling = false;
                                            },
                                            onMoveDx: (dx) {
                                              ref
                                                  .read(
                                                    subtitleProvider.notifier,
                                                  )
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
                                                  .read(
                                                    subtitleProvider.notifier,
                                                  )
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
                                                  .read(
                                                    subtitleProvider.notifier,
                                                  )
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
                                // --- Playhead Marker ---
                                Positioned(
                                  left: playheadX - 16,
                                  top: 0,
                                  bottom: 0,
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.translucent,
                                    onHorizontalDragStart: (_) {
                                      setState(() {
                                        _userScrolling = true;
                                        _draggingPlayhead = true;
                                        _dragPlayheadX = playheadX;
                                      });
                                    },
                                    onHorizontalDragUpdate: (details) {
                                      final newX =
                                          (_dragPlayheadX + details.delta.dx)
                                              .clamp(0.0, width);
                                      setState(() {
                                        _dragPlayheadX = newX;
                                      });
                                      _seekToX(mapping, newX);
                                    },
                                    onHorizontalDragEnd: (_) {
                                      setState(() {
                                        _draggingPlayhead = false;
                                        _userScrolling = false;
                                      });
                                    },
                                    onHorizontalDragCancel: () {
                                      setState(() {
                                        _draggingPlayhead = false;
                                        _userScrolling = false;
                                      });
                                    },
                                    child: SizedBox(
                                      width: 32,
                                      child: Stack(
                                        alignment: Alignment.topCenter,
                                        children: [
                                          // Full vertical marker line
                                          Positioned(
                                            top: 16,
                                            bottom: 0,
                                            child: Container(
                                              width: 2.5,
                                              decoration: BoxDecoration(
                                                color: AppColors.secondary,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: AppColors.secondary
                                                        .withValues(alpha: 0.6),
                                                    blurRadius: 6,
                                                    spreadRadius: 1,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          // Top Playhead Handle
                                          Positioned(
                                            top: 0,
                                            child: Container(
                                              width: 28,
                                              height: 18,
                                              decoration: BoxDecoration(
                                                color: AppColors.secondary,
                                                borderRadius:
                                                    const BorderRadius.only(
                                                      topLeft: Radius.circular(
                                                        6,
                                                      ),
                                                      topRight: Radius.circular(
                                                        6,
                                                      ),
                                                      bottomLeft:
                                                          Radius.circular(2),
                                                      bottomRight:
                                                          Radius.circular(2),
                                                    ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: AppColors.secondary
                                                        .withValues(
                                                          alpha: 0.45,
                                                        ),
                                                    blurRadius: 8,
                                                    spreadRadius: 1,
                                                  ),
                                                  const BoxShadow(
                                                    color: Color(0x80000000),
                                                    blurRadius: 4,
                                                    offset: Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: const Center(
                                                child: Icon(
                                                  Symbols.arrow_drop_down,
                                                  size: 18,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // --- Floating "Jump to Playhead" indicator when scrolled away ---
                      if (!_autoFollow && (isPlayheadLeft || isPlayheadRight))
                        Positioned(
                          bottom: 6,
                          left: isPlayheadLeft ? 10 : null,
                          right: isPlayheadRight ? 10 : null,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                setState(() => _autoFollow = true);
                                _scrollToPlayhead(
                                  playheadX,
                                  viewportWidth,
                                  instant: false,
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x80000000),
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isPlayheadLeft) ...[
                                      const Icon(
                                        Symbols.arrow_left,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                    const Icon(
                                      Symbols.my_location,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      formatClockHms(player.position),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    if (isPlayheadRight) ...[
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Symbols.arrow_right,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
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
              onChanged: _onTextChanged,
              onSubmitted: _commitText,
              decoration: InputDecoration(
                labelText: 'Caption text',
                hintText: 'Select a caption to edit',
                filled: true,
                fillColor: AppColors.surfaceContainerHigh,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _boundIndex != null &&
                        _textController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Symbols.check_circle,
                          size: 20,
                          color: AppColors.secondary,
                        ),
                        tooltip: 'Done editing',
                        onPressed: () => _commitText(_textController.text),
                      )
                    : null,
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
    _debounceTypingTimer?.cancel();
    _isTypingSession = false;
    ref.read(subtitleProvider.notifier).updateSegmentText(
      index,
      value,
      recordHistory: false,
    );
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
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: color),
          ),
        ),
      ],
    );
  }

  Widget _toolbar(
    BuildContext context,
    TimelineMapping mapping,
    Duration duration,
    PlayerState player,
  ) {
    final notifier = ref.read(subtitleProvider.notifier);
    final playerNotifier = ref.read(playerProvider.notifier);

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Play / Pause toggle
        IconButton(
          tooltip: player.isPlaying ? 'Pause' : 'Play',
          visualDensity: VisualDensity.compact,
          onPressed: () {
            if (player.isPlaying) {
              playerNotifier.pause();
            } else {
              setState(() => _autoFollow = true);
              playerNotifier.play();
            }
          },
          icon: Icon(
            player.isPlaying ? Symbols.pause : Symbols.play_arrow,
            size: 20,
            color: player.isPlaying ? AppColors.secondary : null,
          ),
        ),
        // Re-center on playhead toggle
        IconButton(
          tooltip: _autoFollow ? 'Tracking playhead' : 'Center on playhead',
          visualDensity: VisualDensity.compact,
          onPressed: () {
            setState(() => _autoFollow = true);
            if (_scroll.hasClients) {
              _scrollToPlayhead(
                mapping.timeToX(player.position),
                _scroll.position.viewportDimension,
                instant: false,
              );
            }
          },
          icon: Icon(
            Symbols.my_location,
            size: 18,
            color: _autoFollow
                ? AppColors.secondary
                : AppColors.onSurfaceVariant,
          ),
        ),
        // Clock: current position / total duration
        Text(
          '${formatClockHms(player.position)} / ${formatClockHms(duration)}',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        _tool(Symbols.add_circle, 'Add Caption at Playhead', () {
          final pos = ref.read(playerProvider).position;
          notifier.addSegmentAt(pos, mediaDuration: duration);
        }),
        _tool(Symbols.zoom_out, 'Zoom out', () {
          setState(() {
            _pixelsPerSecond = TimelineMapping.clampZoom(
              _pixelsPerSecond / 1.25,
            );
          });
        }),
        _tool(Symbols.zoom_in, 'Zoom in', () {
          setState(() {
            _pixelsPerSecond = TimelineMapping.clampZoom(
              _pixelsPerSecond * 1.25,
            );
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
            _scrollToPlayhead(
              mapping.timeToX(player.position),
              _scroll.position.viewportDimension,
              instant: true,
            );
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
    final tickPaint = Paint()
      ..color = AppColors.outlineVariant
      ..strokeWidth = 1;
    final seconds = mapping.duration.inSeconds;

    // Determine label interval based on zoom level
    final int labelInterval;
    if (mapping.pixelsPerSecond >= 80) {
      labelInterval = 5;
    } else if (mapping.pixelsPerSecond >= 40) {
      labelInterval = 10;
    } else {
      labelInterval = 30;
    }

    final step = mapping.pixelsPerSecond >= 80 ? 1 : 2;
    final textStyle = TextStyle(
      color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
      fontSize: 8,
      fontWeight: FontWeight.w500,
    );

    for (var s = 0; s <= seconds; s += step) {
      final x = mapping.timeToX(Duration(seconds: s));
      final isLabelTick = s % labelInterval == 0;
      final tickHeight = isLabelTick ? 0.0 : 10.0;

      // Draw tick mark
      canvas.drawLine(
        Offset(x, tickHeight),
        Offset(x, size.height),
        tickPaint
          ..strokeWidth = isLabelTick ? 1.5 : 0.5
          ..color = isLabelTick
              ? AppColors.outlineVariant
              : AppColors.outlineVariant.withValues(alpha: 0.4),
      );

      // Draw time label at major ticks
      if (isLabelTick) {
        final minutes = s ~/ 60;
        final secs = s % 60;
        final label = minutes > 0
            ? '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}'
            : '${secs}s';

        final textSpan = TextSpan(text: label, style: textStyle);
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(canvas, Offset(x - textPainter.width / 2, 0));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TimeRulerPainter oldDelegate) {
    return oldDelegate.mapping.pixelsPerSecond != mapping.pixelsPerSecond ||
        oldDelegate.mapping.duration != mapping.duration;
  }
}
