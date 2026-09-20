import 'package:captionary/widgets/app_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/ad_banner_widget.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/gradient_pill_button.dart';
import '../widgets/ghost_pill_button.dart';
import '../widgets/subtitle_overlay.dart';
import '../widgets/subtitle_correction_sheet.dart';
import '../widgets/stylization_sheet.dart';
import '../providers/caption_style_provider.dart';
import '../providers/subtitle_provider.dart';
import '../providers/export_provider.dart';
import '../providers/editing_provider.dart';
import '../data/models/export_job.dart';
import '../data/models/subtitle_segment.dart';
import '../data/models/caption_style.dart';
import '../providers/player_provider.dart';
import '../providers/engagement_provider.dart';
import '../providers/media_provider.dart';

import '../theme/app_spacing.dart';
import '../widgets/app_toast.dart';
import '../widgets/glass_card.dart';
import '../widgets/caption_timeline.dart';
import '../widgets/caption_export_sheet.dart';
import '../widgets/export_options_sheet.dart';
import '../theme/app_colors_extension.dart';
import '../core/duration_format.dart';
import '../providers/waveform_provider.dart';
import '../providers/caption_pipeline_provider.dart';

import 'package:path/path.dart' as p;

import '../core/performance_logger.dart';
import '../data/services/caption_pipeline.dart';

class StudioScreen extends ConsumerStatefulWidget {
  final String videoPath;
  const StudioScreen({super.key, this.videoPath = ''});

  @override
  ConsumerState<StudioScreen> createState() => _StudioScreenState();
}

class _StudioScreenState extends ConsumerState<StudioScreen> {
  bool _isEditMode = true;

  @override
  void initState() {
    super.initState();
    if (widget.videoPath.isNotEmpty) {
      PerformanceLogger.recordCheckpoint(
        'import',
        metadata: {'video': p.basename(widget.videoPath)},
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.videoPath.isNotEmpty) {
        ref.read(playerProvider.notifier).initPlayer(widget.videoPath);
      }
    });
  }

  @override
  void deactivate() {
    ref.read(playerProvider.notifier).releasePlayer();
    super.deactivate();
  }

  Future<void> _importAndOpenVideo() async {
    try {
      final mediaService = ref.read(mediaServiceProvider);
      final item = await mediaService.importVideo();
      if (item != null && mounted) {
        context.pushReplacement('/studio', extra: item.filePath);
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          message: 'Failed to import video: $e',
          variant: AppToastVariant.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = ref.watch(captionStyleProvider);
    final segments = ref.watch(subtitleProvider);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      extendBody: true,
      appBar: isLandscape ? null : const AppHeader(subtitle: 'Studio'),
      bottomNavigationBar: isLandscape
          ? null
          : const BottomNavBar(currentIndex: 2),
      body: SafeArea(
        bottom: false,
        child: isLandscape
            ? _buildLandscapeLayout(context, style, segments)
            : _buildPortraitLayout(context, style, segments),
      ),
    );
  }

  Widget _buildLandscapeLayout(
    BuildContext context,
    CaptionStyle style,
    List<SubtitleSegment> segments,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 8.0, 8.0),
            child: Column(
              children: [
                _buildTopToolbar(context),
                const SizedBox(height: 8),
                Expanded(child: _buildVideoCanvas(context, style, segments)),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(8.0, 8.0, 16.0, 16.0),
            children: [
              if (_isEditMode) ...[
                _buildTimelineStudio(context),
                const SizedBox(height: 12),
                _buildActionButtons(context),
              ] else ...[
                _buildPreviewModeCard(context),
              ],
              const SizedBox(height: 16),
              const AdBannerWidget(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPortraitLayout(
    BuildContext context,
    CaptionStyle style,
    List<SubtitleSegment> segments,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
          child: _buildTopToolbar(context),
        ),
        const SizedBox(height: 12),
        Flexible(
          flex: _isEditMode ? 4 : 7,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildVideoCanvas(context, style, segments),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          flex: _isEditMode ? 6 : 3,
          child: ListView(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              bottom: AppSpacing.bottomNavClearance,
            ),
            children: [
              if (_isEditMode) ...[
                _buildTimelineStudio(context),
                const SizedBox(height: 16),
                _buildActionButtons(context),
              ] else ...[
                _buildPreviewModeCard(context),
              ],
              const SizedBox(height: 24),
              const AdBannerWidget(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewModeCard(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Symbols.visibility,
                color: AppColors.tertiary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Preview Mode',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _isEditMode = true;
                  });
                },
                icon: const Icon(Symbols.edit, size: 16),
                label: const Text('Edit Studio'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Clean viewing mode for subtitle playback. Tap video to Play/Pause, double tap sides to seek +/-10s.',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GhostPillButton(
                  label: 'Export Captions',
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const CaptionExportSheet(),
                    );
                  },
                  isFullWidth: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GradientPillButton(
                  label: 'Burn to Video',
                  icon: Symbols.local_fire_department,
                  onTap: () {
                    ExportOptionsSheet.show(
                      context,
                      onConfirmExport: ({
                        required bool includeWatermark,
                        required int targetMaxResolution,
                      }) {
                        final exportService = ref.read(exportServiceProvider);
                        final segments = ref.read(subtitleProvider);
                        final style = ref.read(captionStyleProvider);
                        final duration = ref.read(playerProvider).duration;

                        final timestamp = DateTime.now().millisecondsSinceEpoch;
                        final outputPath =
                            '${widget.videoPath}_captionary_$timestamp.mp4';

                        final stream = exportService.burnCaptions(
                          videoPath: widget.videoPath,
                          segments: segments,
                          style: style,
                          outputPath: outputPath,
                          videoDuration: duration,
                          includeWatermark: includeWatermark,
                          targetMaxResolution: targetMaxResolution,
                        );

                        final job = ExportJob(
                          id: 'export_$timestamp',
                          sourceFileName: 'Source_Video.mp4',
                          outputFileName: outputPath,
                          state: ExportState.encoding,
                          progress: 0.0,
                          resolution: '${targetMaxResolution}p',
                          codec: 'h264',
                          bitrateMbps: 8,
                          estimatedTimeRemaining: const Duration(seconds: 50),
                          outputSizeBytes: 0,
                          hardwareAcceleration: true,
                        );

                        ref
                            .read(activeExportJobProvider.notifier)
                            .startJob(
                              job,
                              stream,
                              onComplete: () {
                                ref
                                    .read(engagementProvider.notifier)
                                    .onExportCompleted();
                              },
                              onCancel: () => exportService.cancel(),
                            );
                        context.push('/export');
                      },
                    );
                  },
                  isFullWidth: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopToolbar(BuildContext context) {
    final colors =
        Theme.of(context).extension<AppColorsExtension>() ??
        AppColorsExtension.defaultTheme;
    final subtitleNotifier = ref.watch(subtitleProvider.notifier);
    final playerState = ref.watch(playerProvider);
    final playerNotifier = ref.read(playerProvider.notifier);

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      borderRadius: 9999.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Symbols.arrow_back_ios_new, size: 18),
                color: colors.onSurface,
                onPressed: () => context.pop(),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: playerState.isPlaying
                      ? AppColors.tertiary
                      : AppColors.error,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: playerState.isPlaying
                          ? const Color(0x6642A547)
                          : const Color(0x66FFB4AB),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                formatClockHms(playerState.position),
                style: AppTypography.captionCode.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 6),
              // Return to Beginning
              _buildIconButton(
                Symbols.first_page,
                tooltip: 'Return to 00:00:00',
                onTap: () => playerNotifier.seekTo(Duration.zero),
              ),
            ],
          ),
          Row(
            children: [
              // Speed control
              _buildSpeedSelector(context, playerState, playerNotifier),
              const SizedBox(width: 6),
              _buildIconButton(
                Symbols.undo,
                tooltip: 'Undo',
                onTap: subtitleNotifier.canUndo
                    ? () => subtitleNotifier.undo()
                    : null,
              ),
              const SizedBox(width: 6),
              _buildIconButton(
                Symbols.redo,
                tooltip: 'Redo',
                onTap: subtitleNotifier.canRedo
                    ? () => subtitleNotifier.redo()
                    : null,
              ),
              const SizedBox(width: 6),
              // Demarcation: View Mode vs Edit Mode
              _buildIconButton(
                _isEditMode ? Symbols.visibility : Symbols.edit,
                tooltip: _isEditMode
                    ? 'Switch to View Mode'
                    : 'Switch to Edit Studio',
                onTap: () {
                  setState(() {
                    _isEditMode = !_isEditMode;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedSelector(
    BuildContext context,
    PlayerState playerState,
    PlayerNotifier playerNotifier,
  ) {
    return PopupMenuButton<double>(
      tooltip: 'Playback Speed',
      initialValue: playerState.playbackSpeed,
      onSelected: (speed) {
        playerNotifier.setPlaybackSpeed(speed);
      },
      itemBuilder: (context) => [
        for (final s in [0.5, 0.75, 1.0, 1.25, 1.5, 2.0])
          PopupMenuItem(
            value: s,
            child: Text(
              '${s}x',
              style: TextStyle(
                fontWeight: s == playerState.playbackSpeed
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: s == playerState.playbackSpeed
                    ? AppColors.primary
                    : AppColors.onSurface,
              ),
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '${playerState.playbackSpeed}x',
          style: AppTypography.captionCode.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(
    IconData icon, {
    String? tooltip,
    VoidCallback? onTap,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: onTap != null
                ? AppColors.surfaceContainerHigh
                : AppColors.surfaceContainerLow,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 18,
            color: onTap != null
                ? AppColors.onSurface
                : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyVideoState(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Symbols.movie_edit,
                size: 28,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No Video Loaded',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Select a video from your library or import one to begin editing.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: () => context.go('/library'),
                  icon: const Icon(Symbols.video_library, size: 16),
                  label: const Text('Media Library'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _importAndOpenVideo,
                  icon: const Icon(Symbols.add, size: 16),
                  label: const Text('Import Video'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.onSurface,
                    side: const BorderSide(color: AppColors.outlineVariant),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoCanvas(
    BuildContext context,
    CaptionStyle style,
    List<SubtitleSegment> segments,
  ) {
    if (widget.videoPath.trim().isEmpty) {
      return _buildEmptyVideoState(context);
    }

    final playerState = ref.watch(playerProvider);

    Widget playerWidget;
    if (playerState.error != null) {
      playerWidget = AspectRatio(
        aspectRatio: 16 / 9,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Symbols.error, color: AppColors.error, size: 32),
                const SizedBox(height: 8),
                Text(
                  playerState.error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.onSurface),
                ),
              ],
            ),
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
      playerWidget = const AspectRatio(
        aspectRatio: 16 / 9,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        ref.read(playerProvider.notifier).togglePlay();
      },
      onDoubleTapDown: (details) {
        final screenWidth = MediaQuery.of(context).size.width;
        if (details.globalPosition.dx < screenWidth / 2) {
          ref
              .read(playerProvider.notifier)
              .seekRelative(const Duration(seconds: -10));
        } else {
          ref
              .read(playerProvider.notifier)
              .seekRelative(const Duration(seconds: 10));
        }
      },
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: AppColors.surfaceContainerHigh),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            playerWidget,
            // Scrim
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 100,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppColors.baseCanvas.withValues(alpha: 0.87),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            // Floating badge
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                decoration: BoxDecoration(
                  color: AppColors.baseCanvas.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                // child: Text(
                //   'Live 4K Style',
                //   style: AppTypography.captionCode.copyWith(
                //     color: AppColors.tertiary,
                //   ),
                // ),
              ),
            ),
            // Subtitles preview
            Positioned.fill(
              child: SubtitleOverlay(
                segment: ref.watch(activeSubtitleProvider),
                style: style,
              ),
            ),
            // Play button overlay
            if (!playerState.isPlaying)
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
    );
  }

  Widget _buildTimelineStudio(BuildContext context) {
    final waveform = ref.watch(waveformProvider(widget.videoPath));
    return CaptionTimeline(
      waveform: waveform,
      onOpenCaptionList: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const SubtitleCorrectionSheet(),
        );
      },
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const StylizationSheet(),
                  );
                },
                icon: const Icon(Symbols.palette, size: 18),
                label: const Text('Style'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.onSurface,
                  side: const BorderSide(color: AppColors.surfaceContainerHigh),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GhostPillButton(
                label: 'Export captions',
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const CaptionExportSheet(),
                  );
                },
                isFullWidth: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: GhostPillButton(
                label: 'Re-align AI',
                onTap: _handleRealignCaptions,
                isFullWidth: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GradientPillButton(
          label: 'Burn Captions to Video',
          icon: Symbols.local_fire_department,
          onTap: () {
            // Trigger export mock job
            final exportService = ref.read(exportServiceProvider);
            final segments = ref.read(subtitleProvider);
            final style = ref.read(captionStyleProvider);
            final duration = ref.read(playerProvider).duration;

            final timestamp = DateTime.now().millisecondsSinceEpoch;
            final outputPath = '${widget.videoPath}_captionary_$timestamp.mp4';

            final stream = exportService.burnCaptions(
              videoPath: widget.videoPath,
              segments: segments,
              style: style,
              outputPath: outputPath,
              videoDuration: duration,
            );

            final job = ExportJob(
              id: 'mock_export_1',
              sourceFileName: 'Source_Video.mp4',
              outputFileName: 'Output_Video.mp4',
              state: ExportState.encoding,
              progress: 0.0,
              resolution: '1080x1920',
              codec: 'h264',
              bitrateMbps: 8,
              estimatedTimeRemaining: const Duration(seconds: 50),
              outputSizeBytes: 0,
              hardwareAcceleration: true,
            );

            ref
                .read(activeExportJobProvider.notifier)
                .startJob(
                  job,
                  stream,
                  onComplete: () {
                    ref.read(engagementProvider.notifier).onExportCompleted();
                  },
                  onCancel: () => exportService.cancel(),
                );
            context.push('/export');
          },
          isFullWidth: true,
        ),
      ],
    );
  }

  Future<void> _handleRealignCaptions() async {
    if (widget.videoPath.trim().isEmpty) {
      AppToast.show(
        context,
        message: 'No video source loaded to re-align',
        variant: AppToastVariant.warning,
      );
      return;
    }

    final pipelineNotifier = ref.read(captionPipelineProvider.notifier);
    bool isDismissed = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Consumer(
          builder: (context, ref, child) {
            final pipelineState = ref.watch(captionPipelineProvider);

            return AlertDialog(
              backgroundColor: AppColors.surfaceContainerHigh,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  const Icon(Symbols.auto_fix_high, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Re-aligning Captions',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    pipelineState.currentAction ?? 'Processing...',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: pipelineState.progress > 0
                        ? pipelineState.progress
                        : null,
                    backgroundColor: AppColors.surfaceContainerHighest,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  if (pipelineState.status == CaptionPipelineStatus.error) ...[
                    const SizedBox(height: 12),
                    Text(
                      pipelineState.errorMessage ?? 'An error occurred',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppColors.error),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    pipelineNotifier.cancel();
                    if (!isDismissed) {
                      isDismissed = true;
                      Navigator.of(dialogContext).pop();
                    }
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.onSurfaceVariant),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    try {
      final segments = await pipelineNotifier.run(
        videoPath: widget.videoPath,
        mediaId: 'realign_${DateTime.now().millisecondsSinceEpoch}',
        updateSubtitlesOnSuccess: true,
      );

      if (!isDismissed && mounted) {
        isDismissed = true;
        Navigator.of(context).pop();
      }

      if (mounted) {
        if (segments.isNotEmpty) {
          AppToast.show(
            context,
            message:
                'Captions re-aligned successfully (${segments.length} segments)',
            variant: AppToastVariant.success,
          );
        } else {
          AppToast.show(
            context,
            message: 'Re-align complete (no speech detected)',
            variant: AppToastVariant.info,
          );
        }
      }
    } catch (e) {
      if (!isDismissed && mounted) {
        isDismissed = true;
        Navigator.of(context).pop();
      }
      if (mounted) {
        AppToast.show(
          context,
          message: 'Re-alignment failed: $e',
          variant: AppToastVariant.error,
        );
      }
    }
  }
}
