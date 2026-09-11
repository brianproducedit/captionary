import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:video_player/video_player.dart';

import '../providers/player_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_header.dart';
import '../widgets/subtitle_overlay.dart';
import '../providers/subtitle_provider.dart';
import '../providers/caption_style_provider.dart';
import '../data/models/subtitle_segment.dart';

class VideoPlayerScreen extends ConsumerStatefulWidget {
  final String videoPath;
  const VideoPlayerScreen({super.key, required this.videoPath});

  @override
  ConsumerState<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends ConsumerState<VideoPlayerScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.videoPath.isNotEmpty) {
        ref.read(playerProvider.notifier).initPlayer(widget.videoPath);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ref.read(playerProvider.notifier).disposePlayer();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      ref.read(playerProvider.notifier).pause();
    }
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerProvider);
    final controller = playerState.controller;
    final segments = ref.watch(subtitleProvider);
    final currentStyle = ref.watch(captionStyleProvider);

    SubtitleSegment? currentSubtitle;
    if (controller != null && playerState.isInitialized) {
      final currentPosition = controller.value.position;
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
            'Unable to open video.\n${playerState.error}',
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

    return Scaffold(
      appBar: const AppHeader(subtitle: 'Player'),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  ref.read(playerProvider.notifier).togglePlay();
                },
                child: Container(
                  color: Colors.black,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      playerWidget,
                      // Subtitles preview
                      Positioned.fill(
                        child: SubtitleOverlay(
                          segment: currentSubtitle,
                          style: currentStyle,
                        ),
                      ),
                      if (!playerState.isPlaying && playerState.isInitialized)
                        Container(
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
                    ],
                  ),
                ),
              ),
            ),
            // Progress bar
            if (controller != null && playerState.isInitialized)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: VideoProgressIndicator(
                  controller,
                  allowScrubbing: true,
                  colors: const VideoProgressColors(
                    playedColor: AppColors.primary,
                    backgroundColor: AppColors.surfaceContainerHigh,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
