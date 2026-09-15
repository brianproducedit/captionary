import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../data/models/subtitle_segment.dart';
import '../providers/caption_style_provider.dart';
import '../providers/player_provider.dart';
import '../providers/subtitle_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_header.dart';
import '../widgets/player_transport_bar.dart';
import '../widgets/subtitle_overlay.dart';
import '../widgets/ghost_pill_button.dart';

class VideoPlayerScreen extends ConsumerStatefulWidget {
  final String videoPath;
  const VideoPlayerScreen({super.key, required this.videoPath});

  @override
  ConsumerState<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends ConsumerState<VideoPlayerScreen>
    with WidgetsBindingObserver {
  bool _isFullscreen = false;
  PlayerNotifier? _player;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _player = ref.read(playerProvider.notifier);
      _player?.initPlayer(widget.videoPath);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _restoreSystemUi();
    _player?.disposePlayer();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      ref.read(playerProvider.notifier).pause();
    }
  }

  Future<void> _toggleFullscreen() async {
    if (_isFullscreen) {
      await _restoreSystemUi();
      setState(() => _isFullscreen = false);
      return;
    }
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    setState(() => _isFullscreen = true);
  }

  Future<void> _restoreSystemUi() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerProvider);
    final notifier = ref.read(playerProvider.notifier);
    final segments = ref.watch(subtitleProvider);
    final currentStyle = ref.watch(captionStyleProvider);

    SubtitleSegment? currentSubtitle;
    if (playerState.isInitialized) {
      final currentPosition = playerState.position;
      try {
        currentSubtitle = segments.firstWhere(
          (s) => s.startTime <= currentPosition && s.endTime >= currentPosition,
        );
      } catch (_) {
        currentSubtitle = null;
      }
    }

    Widget playerWidget;
    if (playerState.error != null) {
      playerWidget = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            playerState.error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.onSurface),
          ),
        ),
      );
    } else if (playerState.handle != null && playerState.isInitialized) {
      playerWidget = AspectRatio(
        aspectRatio: playerState.aspectRatio > 0
            ? playerState.aspectRatio
            : 16 / 9,
        child: playerState.buildVideoView(context),
      );
    } else {
      playerWidget = const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final videoStack = GestureDetector(
      onTap: playerState.isInitialized ? notifier.togglePlay : null,
      child: ColoredBox(
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(child: Center(child: playerWidget)),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 48),
                child: SubtitleOverlay(
                  segment: currentSubtitle,
                  style: currentStyle,
                ),
              ),
            ),
            if (playerState.isBuffering)
              const CircularProgressIndicator(color: AppColors.primary),
            if (!playerState.isPlaying &&
                playerState.isInitialized &&
                !playerState.isBuffering)
              IgnorePointer(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.baseCanvas.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Symbols.play_arrow,
                    size: 40,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    final transport = PlayerTransportBar(
      isPlaying: playerState.isPlaying,
      isMuted: playerState.isMuted,
      isFullscreen: _isFullscreen,
      position: playerState.position,
      duration: playerState.duration,
      playbackSpeed: playerState.playbackSpeed,
      onPlayPause: notifier.togglePlay,
      onSkipBack: notifier.skipBack,
      onSkipForward: notifier.skipForward,
      onToggleMute: notifier.toggleMute,
      onCycleSpeed: notifier.cyclePlaybackSpeed,
      onToggleFullscreen: _toggleFullscreen,
    );

    return OrientationBuilder(
      builder: (context, orientation) {
        final isLandscape = orientation == Orientation.landscape;
        final showFullscreen = _isFullscreen || isLandscape;

        // Automatically manage system UI for physical rotation
        if (isLandscape && !_isFullscreen) {
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        } else if (!isLandscape && !_isFullscreen) {
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        }

        final scaffold = showFullscreen
            ? Scaffold(
                backgroundColor: Colors.black,
                body: SafeArea(
                  child: Column(
                    children: [
                      Expanded(child: videoStack),
                      if (playerState.isInitialized)
                        _VideoScrubber(
                          position: playerState.position,
                          duration: playerState.duration,
                          onSeek: notifier.seekTo,
                        ),
                      transport,
                    ],
                  ),
                ),
              )
            : Scaffold(
                appBar: AppHeader(
                  subtitle: 'Player',
                  actions: [
                    if (segments.isNotEmpty)
                      GhostPillButton(
                        label: 'Edit Captions',
                        icon: Symbols.edit,
                        onTap: () {
                          // Allow editing by popping and pushing to studio
                          // if coming from library, or just pushing
                          context.pushReplacement(
                            '/studio',
                            extra: widget.videoPath,
                          );
                        },
                      ),
                  ],
                ),
                body: SafeArea(
                  child: Column(
                    children: [
                      Expanded(child: videoStack),
                      if (playerState.isInitialized)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _VideoScrubber(
                            position: playerState.position,
                            duration: playerState.duration,
                            onSeek: notifier.seekTo,
                          ),
                        ),
                      transport,
                    ],
                  ),
                ),
              );

        return PopScope(
          canPop: !showFullscreen,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && showFullscreen) {
              if (_isFullscreen) {
                _toggleFullscreen();
              } else {
                // Force portrait if it was physically rotated
                SystemChrome.setPreferredOrientations([
                  DeviceOrientation.portraitUp,
                  DeviceOrientation.portraitDown,
                ]);
                Future.delayed(const Duration(milliseconds: 500), () {
                  SystemChrome.setPreferredOrientations(
                    DeviceOrientation.values,
                  );
                });
              }
            }
          },
          child: scaffold,
        );
      },
    );
  }
}

class _VideoScrubber extends StatelessWidget {
  final Duration position;
  final Duration duration;
  final ValueChanged<Duration> onSeek;

  const _VideoScrubber({
    required this.position,
    required this.duration,
    required this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    final maxMs = duration.inMilliseconds.toDouble();
    final currentMs = position.inMilliseconds.toDouble().clamp(
      0.0,
      maxMs > 0 ? maxMs : 1.0,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: (details) {
            final box = context.findRenderObject() as RenderBox?;
            if (box == null || box.size.width <= 0 || maxMs <= 0) return;
            final local = box.globalToLocal(details.globalPosition);
            final ratio = (local.dx / box.size.width).clamp(0.0, 1.0);
            onSeek(Duration(milliseconds: (ratio * maxMs).round()));
          },
          onTapDown: (details) {
            final box = context.findRenderObject() as RenderBox?;
            if (box == null || box.size.width <= 0 || maxMs <= 0) return;
            final local = box.globalToLocal(details.globalPosition);
            final ratio = (local.dx / box.size.width).clamp(0.0, 1.0);
            onSeek(Duration(milliseconds: (ratio * maxMs).round()));
          },
          child: Container(
            height: 20,
            alignment: Alignment.center,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: SizedBox(
                height: 4,
                width: double.infinity,
                child: LinearProgressIndicator(
                  value: maxMs > 0 ? (currentMs / maxMs).clamp(0.0, 1.0) : 0.0,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                  backgroundColor: AppColors.surfaceContainerHigh,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
