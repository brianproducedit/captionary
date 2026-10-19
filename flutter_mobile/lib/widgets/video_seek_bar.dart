import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/duration_format.dart';
import '../providers/player_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Draggable video seekbar with timestamps, glassmorphic styling, and auto-hide.
class VideoSeekBar extends ConsumerStatefulWidget {
  final Duration autoHideDuration;
  final VoidCallback? onUserInteraction;

  const VideoSeekBar({
    super.key,
    this.autoHideDuration = const Duration(seconds: 3),
    this.onUserInteraction,
  });

  @override
  ConsumerState<VideoSeekBar> createState() => VideoSeekBarState();
}

class VideoSeekBarState extends ConsumerState<VideoSeekBar> {
  Timer? _hideTimer;
  bool _isVisible = true;
  bool _isDragging = false;
  double _dragValueSeconds = 0.0;

  bool get isVisible => _isVisible;

  @override
  void initState() {
    super.initState();
    _startHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void showControls() {
    if (!mounted) return;
    setState(() {
      _isVisible = true;
    });
    _startHideTimer();
  }

  void toggleControls() {
    if (!mounted) return;
    if (_isVisible) {
      _hideTimer?.cancel();
      setState(() {
        _isVisible = false;
      });
    } else {
      showControls();
    }
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    if (_isDragging) return; // Keep visible while dragging
    _hideTimer = Timer(widget.autoHideDuration, () {
      if (mounted && !_isDragging) {
        setState(() {
          _isVisible = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerProvider);
    final totalDuration = playerState.duration;
    final currentPosition = playerState.position;

    final totalSeconds = totalDuration.inMilliseconds / 1000.0;
    final currentSeconds = currentPosition.inMilliseconds / 1000.0;

    final double displaySeconds = _isDragging
        ? _dragValueSeconds
        : currentSeconds.clamp(0.0, totalSeconds > 0 ? totalSeconds : 0.0);

    final displayDuration = Duration(
      milliseconds: (displaySeconds * 1000).round(),
    );

    return AnimatedOpacity(
      opacity: _isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: IgnorePointer(
        ignoring: !_isVisible,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.surfaceContainerHigh.withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              // Current timestamp
              Text(
                formatPlayerTime(displayDuration),
                key: const ValueKey('video-seekbar-current-time'),
                style: AppTypography.captionCode.copyWith(
                  color: AppColors.onSurface,
                  fontSize: 12,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 8),

              // Slider
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3.5,
                    trackShape: const RoundedRectSliderTrackShape(),
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor: AppColors.surfaceContainerHighest
                        .withValues(alpha: 0.6),
                    thumbShape: RoundSliderThumbShape(
                      enabledThumbRadius: _isDragging ? 7.0 : 5.0,
                      pressedElevation: 6.0,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 12.0,
                    ),
                    thumbColor: AppColors.allWhite,
                    overlayColor: AppColors.primary.withValues(alpha: 0.25),
                  ),
                  child: Slider(
                    key: const ValueKey('video-seekbar-slider'),
                    value: totalSeconds > 0
                        ? displaySeconds.clamp(0.0, totalSeconds)
                        : 0.0,
                    min: 0.0,
                    max: totalSeconds > 0 ? totalSeconds : 1.0,
                    onChangeStart: (val) {
                      _hideTimer?.cancel();
                      setState(() {
                        _isDragging = true;
                        _dragValueSeconds = val;
                      });
                      widget.onUserInteraction?.call();
                    },
                    onChanged: (val) {
                      setState(() {
                        _dragValueSeconds = val;
                      });
                      widget.onUserInteraction?.call();
                    },
                    onChangeEnd: (val) {
                      setState(() {
                        _isDragging = false;
                        _dragValueSeconds = val;
                      });
                      final targetDuration = Duration(
                        milliseconds: (val * 1000).round(),
                      );
                      ref.read(playerProvider.notifier).seekTo(targetDuration);
                      _startHideTimer();
                      widget.onUserInteraction?.call();
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Total duration
              Text(
                formatPlayerTime(totalDuration),
                key: const ValueKey('video-seekbar-total-duration'),
                style: AppTypography.captionCode.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 12,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
