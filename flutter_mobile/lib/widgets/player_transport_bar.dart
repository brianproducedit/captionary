import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../core/duration_format.dart';
import '../theme/app_colors.dart';

class PlayerTransportBar extends StatelessWidget {
  static const double minTapSize = 48;

  final bool isPlaying;
  final bool isMuted;
  final bool isFullscreen;
  final Duration position;
  final Duration duration;
  final double playbackSpeed;
  final VoidCallback onPlayPause;
  final VoidCallback onSkipBack;
  final VoidCallback onSkipForward;
  final VoidCallback onToggleMute;
  final VoidCallback onCycleSpeed;
  final VoidCallback onToggleFullscreen;

  const PlayerTransportBar({
    super.key,
    required this.isPlaying,
    required this.isMuted,
    required this.isFullscreen,
    required this.position,
    required this.duration,
    required this.playbackSpeed,
    required this.onPlayPause,
    required this.onSkipBack,
    required this.onSkipForward,
    required this.onToggleMute,
    required this.onCycleSpeed,
    required this.onToggleFullscreen,
  });

  @override
  Widget build(BuildContext context) {
    final speedLabel =
        '${playbackSpeed % 1 == 0 ? playbackSpeed.toStringAsFixed(0) : playbackSpeed}x';

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Text(
                  formatPlayerTime(position),
                  key: const ValueKey('player-time-position'),
                  style: Theme.of(context).textTheme.labelMedium
                      ?.copyWith(color: AppColors.onSurface),
                ),
                const Spacer(),
                Text(
                  formatPlayerTime(duration),
                  key: const ValueKey('player-time-duration'),
                  style: Theme.of(context).textTheme.labelMedium
                      ?.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 4,
            children: [
              _TransportButton(
                key: const ValueKey('player-skip-back'),
                tooltip: 'Skip back 10 seconds',
                icon: Symbols.replay_10,
                onPressed: onSkipBack,
              ),
              _TransportButton(
                key: const ValueKey('player-play-pause'),
                tooltip: isPlaying ? 'Pause' : 'Play',
                icon: isPlaying ? Symbols.pause : Symbols.play_arrow,
                onPressed: onPlayPause,
              ),
              _TransportButton(
                key: const ValueKey('player-skip-forward'),
                tooltip: 'Skip forward 10 seconds',
                icon: Symbols.forward_10,
                onPressed: onSkipForward,
              ),
              _TransportButton(
                key: const ValueKey('player-mute'),
                tooltip: isMuted ? 'Unmute' : 'Mute',
                icon: isMuted ? Symbols.volume_off : Symbols.volume_up,
                onPressed: onToggleMute,
              ),
              Semantics(
                button: true,
                label: 'Playback speed $speedLabel',
                child: TextButton(
                  key: const ValueKey('player-speed'),
                  onPressed: onCycleSpeed,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(minTapSize, minTapSize),
                    foregroundColor: AppColors.onSurface,
                  ),
                  child: Text(speedLabel),
                ),
              ),
              _TransportButton(
                key: const ValueKey('player-fullscreen'),
                tooltip: isFullscreen ? 'Exit fullscreen' : 'Enter fullscreen',
                icon: isFullscreen
                    ? Symbols.fullscreen_exit
                    : Symbols.fullscreen,
                onPressed: onToggleFullscreen,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TransportButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  const _TransportButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon),
      color: AppColors.onSurface,
      style: IconButton.styleFrom(
        minimumSize: const Size(
          PlayerTransportBar.minTapSize,
          PlayerTransportBar.minTapSize,
        ),
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
    );
  }
}
