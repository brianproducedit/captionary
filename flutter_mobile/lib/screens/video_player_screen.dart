import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:video_player/video_player.dart';

import '../data/models/subtitle_segment.dart';
import '../providers/caption_style_provider.dart';
import '../providers/player_provider.dart';
import '../providers/subtitle_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_header.dart';
import '../widgets/player_transport_bar.dart';
import '../widgets/subtitle_overlay.dart';

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
    final controller = playerState.controller;
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
    } else if (controller != null && playerState.isInitialized) {
      playerWidget = AspectRatio(
        aspectRatio: controller.value.aspectRatio > 0
            ? controller.value.aspectRatio
            : 16 / 9,
        child: VideoPlayer(controller),
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

    final scaffold = _isFullscreen
        ? Scaffold(
            backgroundColor: Colors.black,
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(child: videoStack),
                  if (controller != null && playerState.isInitialized)
                    VideoProgressIndicator(
                      controller,
                      allowScrubbing: true,
                      colors: const VideoProgressColors(
                        playedColor: AppColors.primary,
                        backgroundColor: AppColors.surfaceContainerHigh,
                      ),
                    ),
                  transport,
                ],
              ),
            ),
          )
        : Scaffold(
            appBar: const AppHeader(subtitle: 'Player'),
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(child: videoStack),
                  if (controller != null && playerState.isInitialized)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: VideoProgressIndicator(
                        controller,
                        allowScrubbing: true,
                        colors: const VideoProgressColors(
                          playedColor: AppColors.primary,
                          backgroundColor: AppColors.surfaceContainerHigh,
                        ),
                      ),
                    ),
                  transport,
                ],
              ),
            ),
          );

    return PopScope(
      canPop: !_isFullscreen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _isFullscreen) {
          _toggleFullscreen();
        }
      },
      child: scaffold,
    );
  }
}
