import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_typography.dart';
import '../widgets/gradient_pill_button.dart';
import '../widgets/ghost_pill_button.dart';
import '../widgets/circular_progress_painter.dart';

import 'package:share_plus/share_plus.dart';

import '../widgets/ad_banner_widget.dart';
import '../providers/export_provider.dart';
import '../data/models/export_job.dart';

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _logoAnimationController;
  late Animation<double> _logoScaleAnimation;

  @override
  void initState() {
    super.initState();
    _logoAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    if (Platform.environment['FLUTTER_TEST'] != 'true') {
      _logoAnimationController.repeat(reverse: true);
    }

    _logoScaleAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(
        parent: _logoAnimationController,
        curve: Curves.easeInOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _logoAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeJob = ref.watch(activeExportJobProvider);

    return Scaffold(
      // extendBodyBehindAppBar: true,
      // appBar: const SubScreenHeader(title: 'Export Video'),
      backgroundColor: AppColors.baseCanvas,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.only(
            top: 24.0,
            bottom: MediaQuery.of(context).padding.bottom + 24.0,
            left: 16.0,
            right: 16.0,
          ),
          children: [
            if (activeJob != null) ...[
              if (activeJob.state == ExportState.complete)
                _buildStateBFinished(context, activeJob)
              else if (activeJob.state == ExportState.cancelled)
                _buildStateCCancelled(context, activeJob)
              else if (activeJob.state == ExportState.error)
                _buildStateError(context, activeJob)
              else
                _buildStateAInProgress(context, activeJob),
            ] else ...[
              Center(
                child: Text(
                  "No active export job.",
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: AppColors.allWhite),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStateAInProgress(BuildContext context, ExportJob activeJob) {
    return Column(
      children: [
        // Context bar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.tertiary,
                    shape: BoxShape.circle,
                    boxShadow: [AppShadows.tertiaryGlow],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Engine: Whisper + FFmpeg Core',
                  style: AppTypography.captionCode.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                // Mock abort
                context.pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Abort'),
            ),
          ],
        ),
        const SizedBox(height: 32),
        // Progress Indicator
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 256,
              height: 256,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x332196F3),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 256,
              height: 256,
              child: CustomPaint(
                painter: CircularProgressPainter(progress: activeJob.progress),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: _logoScaleAnimation,
                  child: Image.asset(
                    'assets/images/captionary_logo.png',
                    width: 48,
                    height: 48,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                            return SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.0, -0.5),
                                end: Offset.zero,
                              ).animate(animation),
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            );
                          },
                      child: Text(
                        (activeJob.progress * 100).toInt().toString(),
                        key: ValueKey<int>((activeJob.progress * 100).toInt()),
                        style: Theme.of(context).textTheme.displayLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      '%',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Symbols.sync, color: AppColors.primary, size: 24),
            const SizedBox(width: 8),
            Text(
              'Encoding ${activeJob.resolution} 60fps',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Burned subtitles, High precision audio-sync',
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: AppColors.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: AppColors.tertiaryContainer,
            borderRadius: BorderRadius.circular(9999),
          ),
          child: Text(
            'Est. Time Remaining: ${activeJob.estimatedTimeRemaining.inSeconds}s',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.onTertiaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 32),
        // Hardware Details
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: AppColors.surfaceContainerHigh),
          ),
          child: Row(
            children: [
              const Icon(
                Symbols.memory,
                color: AppColors.onSurfaceVariant,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activeJob.hardwareAcceleration
                          ? 'Hardware Acceleration ON'
                          : 'Software Encoding',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bitrate: ${activeJob.bitrateMbps} Mbps, ${activeJob.codec.toUpperCase()} High',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // AdMob Placeholder
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Row(
            children: [
              const Icon(
                Symbols.campaign,
                color: AppColors.onSurfaceVariant,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Empower Regional AI Speech',
                      style: Theme.of(context).textTheme.labelMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Monetising idle time helps us serve free dialect updates.',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 6.0,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.outlineVariant),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  'Learn',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const AdBannerWidget(),
      ],
    );
  }

  Widget _buildStateBFinished(BuildContext context, ExportJob activeJob) {
    return Column(
      children: [
        // Success Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32.0),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(24.0),
            border: Border.all(
              color: AppColors.tertiary.withValues(alpha: 0.3),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x3378DC77), // AppColors.tertiary with opacity
                blurRadius: 40,
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [AppShadows.tertiaryGlow],
                ),
                child: const Icon(
                  Symbols.check_circle,
                  size: 64,
                  color: AppColors.tertiary,
                  fill: 1.0,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Export Complete!',
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Your subtitled video is ready and has been saved to your device gallery.',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: AppColors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Symbols.movie,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activeJob.outputFileName,
                            style: Theme.of(context).textTheme.labelMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${(activeJob.outputSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB • ${activeJob.codec.toUpperCase()} (${activeJob.resolution}) • Synced 100%',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: GhostPillButton(
                label: 'Preview',
                icon: Symbols.play_arrow,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Opening preview...')),
                  );
                },
                isFullWidth: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              // child: GradientPillButton(
              child: GhostPillButton(
                label: 'Share Video',
                onTap: () {
                  SharePlus.instance.share(
                    ShareParams(
                      files: [XFile(activeJob.outputFileName)],
                      text: 'Check out my new video edited with Captionary!',
                    ),
                  );
                },
                isFullWidth: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        // Community support banner
        GestureDetector(
          onTap: () => context.push('/donate'),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: AppColors.surfaceContainerHigh),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Symbols.favorite,
                      size: 16,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Captionary is community funded',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Join creators from SN, ZW, SA in keeping the open models free.',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryContainer,
                    borderRadius: BorderRadius.circular(9999),
                    boxShadow: const [AppShadows.glowSupport],
                  ),
                  child: Text(
                    'Buy a Coffee ☕',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.onSecondaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        TextButton(
          onPressed: () {
            context.pop();
          },
          style: TextButton.styleFrom(
            foregroundColor: AppColors.onSurfaceVariant,
          ),
          child: Text(
            'Re-encode with other settings',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(decoration: TextDecoration.underline),
          ),
        ),
      ],
    );
  }

  Widget _buildStateCCancelled(BuildContext context, ExportJob activeJob) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32.0),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(24.0),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [AppShadows.glowSupport],
                ),
                child: const Icon(
                  Symbols.cancel,
                  size: 64,
                  color: AppColors.error,
                  fill: 1.0,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Export Cancelled',
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'The export process was aborted. No file was saved.',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: AppColors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        GradientPillButton(
          label: 'Retry Export',
          icon: Symbols.refresh,
          onTap: () {
            // Mock retry
            context.pop(); // Go back to studio to retry
          },
        ),
        const SizedBox(height: 16),
        GhostPillButton(
          label: 'Back to Studio',
          onTap: () {
            context.pop();
          },
          isFullWidth: true,
        ),
      ],
    );
  }

  Widget _buildStateError(BuildContext context, ExportJob job) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.errorContainer,
            shape: BoxShape.circle,
          ),
          child: const Icon(Symbols.error, size: 40, color: AppColors.error),
        ),
        const SizedBox(height: 24),
        Text(
          'Export Failed',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'An error occurred during video processing.',
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: AppColors.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        GradientPillButton(
          label: 'Retry Export',
          icon: Symbols.refresh,
          onTap: () {
            // Need to pass video path and start again
            // For now just pop back to studio
            context.pop();
          },
          isFullWidth: true,
        ),
        const SizedBox(height: 16),
        GhostPillButton(
          label: 'Back to Studio',
          onTap: () {
            ref.read(activeExportJobProvider.notifier).clearJob();
            context.pop();
          },
          isFullWidth: true,
        ),
      ],
    );
  }
}
