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

import 'package:video_player/video_player.dart';

import '../theme/app_spacing.dart';
import '../widgets/app_toast.dart';
import '../widgets/glass_card.dart';
import '../widgets/caption_timeline.dart';
import '../widgets/caption_export_sheet.dart';
import '../theme/app_colors_extension.dart';
import '../core/duration_format.dart';
import '../providers/waveform_provider.dart';

class StudioScreen extends ConsumerStatefulWidget {
  final String videoPath;
  const StudioScreen({super.key, this.videoPath = ''});

  @override
  ConsumerState<StudioScreen> createState() => _StudioScreenState();
}

class _StudioScreenState extends ConsumerState<StudioScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.videoPath.isNotEmpty) {
        ref.read(playerProvider.notifier).initPlayer(widget.videoPath);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final style = ref.watch(captionStyleProvider);
    final segments = ref.watch(subtitleProvider);

    return Scaffold(
      extendBody: true,
      appBar: const AppHeader(subtitle: 'Studio'),
      body: SafeArea(
        bottom: false,
        child: OrientationBuilder(
          builder: (context, orientation) {
            if (orientation == Orientation.landscape) {
              return Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            16.0,
                            16.0,
                            16.0,
                            0,
                          ),
                          child: _buildTopToolbar(context),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              16.0,
                              0,
                              8.0,
                              16.0,
                            ),
                            child: _buildVideoCanvas(context, style, segments),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: ListView(
                      padding: const EdgeInsets.only(
                        left: 8.0,
                        right: 16.0,
                        bottom: AppSpacing.bottomNavClearance,
                      ),
                      children: [
                        _buildTimelineStudio(context),
                        const SizedBox(height: 16),
                        _buildActionButtons(context),
                        const SizedBox(height: 42),
                        const AdBannerWidget(),
                      ],
                    ),
                  ),
                ],
              );
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
                  child: _buildTopToolbar(context),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildVideoCanvas(context, style, segments),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(
                      left: 16.0,
                      right: 16.0,
                      bottom: AppSpacing.bottomNavClearance,
                    ),
                    children: [
                      _buildTimelineStudio(context),
                      const SizedBox(height: 16),
                      _buildActionButtons(context),
                      const SizedBox(height: 42),
                      const AdBannerWidget(),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),

      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     // Mock add segment
      //     ScaffoldMessenger.of(context)
      //         .showSnackBar(const SnackBar(content: Text('Added new segment')));
      //   },
      //   backgroundColor: AppColors.primaryContainer,
      //   child: const Icon(Symbols.add, color: AppColors.onPrimaryContainer),
      // ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildTopToolbar(BuildContext context) {
    final colors =
        Theme.of(context).extension<AppColorsExtension>() ??
        AppColorsExtension.defaultTheme;
    final subtitleNotifier = ref.watch(subtitleProvider.notifier);

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      borderRadius: 9999.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Symbols.arrow_back_ios_new, size: 20),
                color: colors.onSurface,
                onPressed: () => context.pop(),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(width: 16),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Color(0x66FFB4AB), blurRadius: 8),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatClockHms(ref.watch(playerProvider).position),
                style: AppTypography.captionCode.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Row(
            children: [
              _buildIconButton(
                Symbols.undo,
                tooltip: 'Undo',
                onTap: subtitleNotifier.canUndo
                    ? () => subtitleNotifier.undo()
                    : null,
              ),
              const SizedBox(width: 8),
              _buildIconButton(
                Symbols.redo,
                tooltip: 'Redo',
                onTap: subtitleNotifier.canRedo
                    ? () => subtitleNotifier.redo()
                    : null,
              ),
              const SizedBox(width: 8),
              _buildIconButton(
                Symbols.visibility,
                tooltip: 'Preview in Player',
                onTap: () {
                  context.pushReplacement('/player', extra: widget.videoPath);
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
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

  Widget _buildVideoCanvas(
    BuildContext context,
    CaptionStyle style,
    List<SubtitleSegment> segments,
  ) {
    final playerState = ref.watch(playerProvider);
    final controller = playerState.controller;

    Widget playerWidget;
    if (controller != null && playerState.isInitialized) {
      playerWidget = AspectRatio(
        aspectRatio: controller.value.aspectRatio > 0
            ? controller.value.aspectRatio
            : 16 / 9,
        child: VideoPlayer(controller),
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
                onTap: () async {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) =>
                        const Center(child: CircularProgressIndicator()),
                  );
                  await Future.delayed(const Duration(seconds: 2));
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    AppToast.show(
                      context,
                      message: 'Re-align is not available until the caption pipeline is connected',
                      variant: AppToastVariant.warning,
                    );
                  }
                },
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
                );
            context.push('/export');
          },
          isFullWidth: true,
        ),
      ],
    );
  }
}
