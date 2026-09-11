import 'package:flutter/material.dart';

import '../widgets/donate_banner.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/empty_state_widget.dart';

import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_shadows.dart';
import '../widgets/app_header.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/status_chip.dart';
import '../widgets/bento_grid.dart';
import '../widgets/storage_usage_bar.dart';
import '../widgets/glass_card.dart';
import '../theme/app_typography.dart';
import '../providers/media_provider.dart';
import '../providers/language_provider.dart';
import '../data/models/media_item.dart';

class MediaLibraryScreen extends ConsumerWidget {
  const MediaLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      extendBody: true, // For bottom nav blur
      extendBodyBehindAppBar: true, // For app bar blur
      appBar: const AppHeader(subtitle: 'Local Media Library'),
      body: ListView(
        padding: EdgeInsets.only(
          top:
              MediaQuery.of(context).padding.top +
              64.0 +
              24.0, // app bar + extra
          bottom: 120.0, // space for bottom nav
          left: 16.0,
          right: 16.0,
        ),
        children: [
          _buildLanguagePackBanner(context, ref),
          const SizedBox(height: 24),
          _buildHeroImportCard(context, ref),
          const SizedBox(height: 24),
          _buildQuickStats(context),
          const SizedBox(height: 16),
          const StorageUsageBar(
            mediaCacheBytes: 251658240,
            modelCacheBytes: 524288000,
            totalSpaceBytes: 10737418240,
          ), // dummy data
          const SizedBox(height: 24),
          DonateBanner(onTap: () {}),
          const SizedBox(height: 32),
          _buildSectionHeader(context, ref),
          const SizedBox(height: 16),
          _buildRecentMediaList(context, ref),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildLanguagePackBanner(BuildContext context, WidgetRef ref) {
    final activeLanguageAsync = ref.watch(activeLanguageProvider);

    return GestureDetector(
      onTap: () => context.go('/languages'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(color: AppColors.surfaceContainerHigh),
        ),
        child: Row(
          children: [
            // Pulsing dot
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.tertiary,
                shape: BoxShape.circle,
                boxShadow: [AppShadows.tertiaryGlow],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: activeLanguageAsync.when(
                data: (lang) => Text(
                  'Language Pack: ${lang.name}',
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                loading: () => const Text('Loading language...'),
                error: (error, stack) => const Text('Error loading language'),
              ),
            ),
            const StatusChip(label: 'Ready', variant: StatusChipVariant.ready),
            const SizedBox(width: 8),
            const Icon(
              Symbols.chevron_right,
              size: 20,
              color: AppColors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroImportCard(BuildContext context, WidgetRef ref) {
    return GlassCard(
      padding: const EdgeInsets.all(24.0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ambient glow behind
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppGradients.ambientBackgroundGlow,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              EmptyStateWidget(
                icon: Symbols.video_file,
                title: 'Import Video Storage',
                message: 'Supports MP4, MOV, MKV up to 4K 60fps.\nAudio tracks are extracted locally.',
                actionLabel: 'Browse Media',
                actionIcon: Symbols.browse_sharp,
                onAction: () async {
                  final service = ref.read(mediaServiceProvider);
                  final item = await service.importVideo();
                  if (item != null) {
                    ref.invalidate(recentMediaProvider);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          _buildStatPill(
            context,
            '2.4 GB Cached',
            Symbols.data_usage,
            AppColors.primary,
          ),
          const SizedBox(width: 12),
          _buildStatPill(
            context,
            '5 Models Installed',
            Symbols.model_training,
            AppColors.secondary,
          ),
          const SizedBox(width: 12),
          _buildStatPill(
            context,
            'Offline Ready',
            Symbols.wifi_off,
            AppColors.tertiary,
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(
    BuildContext context,
    String text,
    IconData icon,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 8),
          Text(
            text,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, WidgetRef ref) {
    final recentMediaAsync = ref.watch(recentMediaProvider);
    final count = recentMediaAsync.when(
      data: (media) => media.length.toString(),
      loading: () => '...',
      error: (_, _) => '0',
    );

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Media Library',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 2.0,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    count,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: 'Recent',
                    icon: const Icon(
                      Symbols.arrow_drop_down,
                      color: AppColors.onSurfaceVariant,
                    ),
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: AppColors.onSurfaceVariant),
                    dropdownColor: AppColors.surfaceContainerHigh,
                    items: <String>['Recent', 'Name', 'Duration'].map((
                      String value,
                    ) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (_) {},
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Symbols.grid_view),
                  color: AppColors.onSurfaceVariant,
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip(context, 'All', true),
              const SizedBox(width: 8),
              _buildFilterChip(context, 'Video', false),
              const SizedBox(width: 8),
              _buildFilterChip(context, 'Audio', false),
              const SizedBox(width: 8),
              _buildFilterChip(context, 'Exported', false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(BuildContext context, String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.surfaceContainerHighest
            : Colors.transparent,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(
          color: isSelected
              ? Colors.transparent
              : AppColors.surfaceContainerHigh,
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: isSelected ? AppColors.onSurface : AppColors.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildRecentMediaList(BuildContext context, WidgetRef ref) {
    final recentMediaAsync = ref.watch(recentMediaProvider);

    return recentMediaAsync.when(
      data: (mediaItems) {
        if (mediaItems.isEmpty) {
          return const Center(child: Text('No media found.'));
        }
        return BentoGrid(
          itemCount: mediaItems.length,
          itemBuilder: (context, index) {
            final item = mediaItems[index];
            String durationStr =
                '${item.duration.inMinutes.toString().padLeft(2, '0')}:${(item.duration.inSeconds % 60).toString().padLeft(2, '0')}';
            String detailsStr =
                '${(item.fileSizeBytes / (1024 * 1024)).toStringAsFixed(0)} MB • ${item.resolution}';

            StatusChipVariant variant = StatusChipVariant.ready;
            String statusLabel = 'Ready';
            switch (item.status) {
              case MediaStatus.newItem:
                variant = StatusChipVariant.newVariant;
                statusLabel = 'New';
                break;
              case MediaStatus.pendingAudioSync:
                variant = StatusChipVariant.processing;
                statusLabel = 'Syncing...';
                break;
              case MediaStatus.readyToEdit:
                variant = StatusChipVariant.ready;
                statusLabel = 'Ready';
                break;
              case MediaStatus.transcribed:
                variant = StatusChipVariant.ready;
                statusLabel = 'Transcribed';
                break;
            }

            return _buildMediaCard(
              context: context,
              title: item.fileName,
              details: detailsStr,
              duration: durationStr,
              status: statusLabel,
              variant: variant,
              onTap: () {
                if (item.status == MediaStatus.newItem) {
                  context.push('/transcription', extra: item.filePath);
                } else if (item.status == MediaStatus.transcribed) {
                  context.push('/player', extra: item.filePath);
                } else {
                  context.push('/studio', extra: item.filePath);
                }
              },
              gradient: const LinearGradient(
                colors: [
                  AppColors.surfaceContainerHigh,
                  AppColors.surfaceVariant,
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildMediaCard({
    required BuildContext context,
    required String title,
    required String details,
    required String duration,
    required String status,
    required StatusChipVariant variant,
    required LinearGradient gradient,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.0),
                gradient: gradient,
              ),
              alignment: Alignment.bottomRight,
              child: Container(
                margin: const EdgeInsets.all(6.0),
                padding: const EdgeInsets.symmetric(
                  horizontal: 4.0,
                  vertical: 2.0,
                ),
                decoration: BoxDecoration(
                  color: AppColors.baseCanvas.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Text(duration, style: AppTypography.captionCode),
              ),
            ),
            const SizedBox(height: 12),
            // Details
            Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              details,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            StatusChip(label: status, variant: variant),
          ],
        ),
      ),
    );
  }
}
