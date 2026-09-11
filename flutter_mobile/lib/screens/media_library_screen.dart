import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../core/media_library_query.dart';
import '../data/models/media_item.dart';
import '../providers/language_provider.dart';
import '../providers/media_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/app_header.dart';
import '../widgets/bento_grid.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/donate_banner.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/glass_card.dart';
import '../widgets/status_chip.dart';

class MediaLibraryScreen extends ConsumerStatefulWidget {
  const MediaLibraryScreen({super.key});

  @override
  ConsumerState<MediaLibraryScreen> createState() => _MediaLibraryScreenState();
}

class _MediaLibraryScreenState extends ConsumerState<MediaLibraryScreen> {
  MediaLibrarySort _sort = MediaLibrarySort.recent;
  MediaLibraryFilter _filter = MediaLibraryFilter.all;
  bool _isGrid = true;

  Future<void> _importMedia() async {
    final item = await ref.read(mediaServiceProvider).importVideo();
    if (item != null) {
      ref.invalidate(recentMediaProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final recentMediaAsync = ref.watch(recentMediaProvider);

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: const AppHeader(subtitle: 'Local Media Library'),
      body: ListView(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 64.0 + 24.0,
          bottom: AppSpacing.bottomNavClearance,
          left: 16.0,
          right: 16.0,
        ),
        children: [
          _buildLanguagePackBanner(context),
          const SizedBox(height: AppSpacing.spaceLg),
          _buildHeroImportCard(context),
          const SizedBox(height: AppSpacing.spaceMd),
          recentMediaAsync.maybeWhen(
            data: (items) => _buildQuickStats(context, items.length),
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(height: AppSpacing.spaceMd),
          DonateBanner(onTap: () => context.go('/donate')),
          const SizedBox(height: AppSpacing.spaceLg),
          _buildSectionHeader(context, recentMediaAsync),
          const SizedBox(height: AppSpacing.spaceSm),
          _buildMediaResults(context, recentMediaAsync),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildLanguagePackBanner(BuildContext context) {
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

  Widget _buildHeroImportCard(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: AppGradients.ambientBackgroundGlow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Symbols.video_file, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Import MP4, MOV, or MKV. Audio is extracted on device.',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ),
          TextButton.icon(
            key: const ValueKey('library-import'),
            onPressed: _importMedia,
            icon: const Icon(Symbols.browse_sharp, size: 18),
            label: const Text('Browse'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, int itemCount) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _buildStatPill(
          context,
          '$itemCount in library',
          Symbols.video_library,
          AppColors.primary,
        ),
        _buildStatPill(
          context,
          'Offline ready',
          Symbols.wifi_off,
          AppColors.tertiary,
        ),
      ],
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

  Widget _buildSectionHeader(
    BuildContext context,
    AsyncValue<List<MediaItem>> recentMediaAsync,
  ) {
    final visibleCount = recentMediaAsync.maybeWhen(
      data: (media) => MediaLibraryQuery.apply(
        items: media,
        filter: _filter,
        sort: _sort,
      ).length,
      orElse: () => null,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                visibleCount?.toString() ?? '…',
                key: const ValueKey('library-count'),
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
            const Spacer(),
            DropdownButtonHideUnderline(
              child: DropdownButton<MediaLibrarySort>(
                key: const ValueKey('library-sort'),
                value: _sort,
                icon: const Icon(
                  Symbols.arrow_drop_down,
                  color: AppColors.onSurfaceVariant,
                ),
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: AppColors.onSurfaceVariant),
                dropdownColor: AppColors.surfaceContainerHigh,
                items: const [
                  DropdownMenuItem(
                    value: MediaLibrarySort.recent,
                    child: Text('Recent'),
                  ),
                  DropdownMenuItem(
                    value: MediaLibrarySort.name,
                    child: Text('Name'),
                  ),
                  DropdownMenuItem(
                    value: MediaLibrarySort.duration,
                    child: Text('Duration'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _sort = value);
                },
              ),
            ),
            IconButton(
              key: const ValueKey('library-view-toggle'),
              tooltip: _isGrid ? 'Switch to list view' : 'Switch to grid view',
              icon: Icon(_isGrid ? Symbols.view_list : Symbols.grid_view),
              color: AppColors.onSurfaceVariant,
              onPressed: () => setState(() => _isGrid = !_isGrid),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final filter in MediaLibraryFilter.values) ...[
                if (filter != MediaLibraryFilter.values.first)
                  const SizedBox(width: 8),
                _buildFilterChip(filter),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(MediaLibraryFilter filter) {
    final label = switch (filter) {
      MediaLibraryFilter.all => 'All',
      MediaLibraryFilter.video => 'Video',
      MediaLibraryFilter.audio => 'Audio',
      MediaLibraryFilter.exported => 'Exported',
    };
    final isSelected = _filter == filter;

    return FilterChip(
      key: ValueKey('library-filter-$label'),
      label: Text(label),
      selected: isSelected,
      showCheckmark: false,
      selectedColor: AppColors.surfaceContainerHighest,
      backgroundColor: Colors.transparent,
      side: BorderSide(
        color: isSelected ? Colors.transparent : AppColors.surfaceContainerHigh,
      ),
      labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: isSelected ? AppColors.onSurface : AppColors.onSurfaceVariant,
      ),
      onSelected: (_) => setState(() => _filter = filter),
    );
  }

  Widget _buildMediaResults(
    BuildContext context,
    AsyncValue<List<MediaItem>> recentMediaAsync,
  ) {
    return recentMediaAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => EmptyStateWidget(
        icon: Symbols.error,
        title: 'Could not load media',
        message: error.toString(),
        actionLabel: 'Retry',
        actionIcon: Symbols.refresh,
        onAction: () => ref.invalidate(recentMediaProvider),
      ),
      data: (mediaItems) {
        if (mediaItems.isEmpty) {
          return EmptyStateWidget(
            icon: Symbols.video_file,
            title: 'No media yet',
            message: 'Import a video to start captioning on this device.',
            actionLabel: 'Browse Media',
            actionIcon: Symbols.browse_sharp,
            onAction: _importMedia,
          );
        }

        final visible = MediaLibraryQuery.apply(
          items: mediaItems,
          filter: _filter,
          sort: _sort,
        );

        if (visible.isEmpty) {
          return EmptyStateWidget(
            icon: Symbols.filter_alt_off,
            title: 'No matching media',
            message: 'Nothing matches the current filter.',
            actionLabel: 'Clear filters',
            actionIcon: Symbols.filter_alt,
            onAction: () => setState(() {
              _filter = MediaLibraryFilter.all;
              _sort = MediaLibrarySort.recent;
            }),
          );
        }

        if (_isGrid) {
          return BentoGrid(
            key: const ValueKey('library-grid'),
            animate: false,
            itemCount: visible.length,
            itemBuilder: (context, index) =>
                _buildMediaCard(context, visible[index], isGrid: true),
          );
        }

        return Column(
          key: const ValueKey('library-list'),
          children: [
            for (final item in visible) ...[
              _buildMediaCard(context, item, isGrid: false),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }

  Widget _buildMediaCard(
    BuildContext context,
    MediaItem item, {
    required bool isGrid,
  }) {
    final durationStr =
        '${item.duration.inMinutes.toString().padLeft(2, '0')}:${(item.duration.inSeconds % 60).toString().padLeft(2, '0')}';
    final detailsStr =
        '${(item.fileSizeBytes / (1024 * 1024)).toStringAsFixed(0)} MB • ${item.resolution}';

    var variant = StatusChipVariant.ready;
    var statusLabel = 'Ready';
    switch (item.status) {
      case MediaStatus.newItem:
        variant = StatusChipVariant.newVariant;
        statusLabel = 'New';
      case MediaStatus.pendingAudioSync:
        variant = StatusChipVariant.processing;
        statusLabel = 'Syncing...';
      case MediaStatus.readyToEdit:
        variant = StatusChipVariant.ready;
        statusLabel = 'Ready';
      case MediaStatus.transcribed:
        variant = StatusChipVariant.ready;
        statusLabel = 'Transcribed';
    }

    void onTap() {
      if (item.status == MediaStatus.newItem) {
        context.push('/transcription', extra: item.filePath);
      } else if (item.status == MediaStatus.transcribed) {
        context.push('/player', extra: item.filePath);
      } else {
        context.push('/studio', extra: item.filePath);
      }
    }

    final thumbnail = _MediaThumbnail(
      item: item,
      durationLabel: durationStr,
      height: isGrid ? 120 : 72,
    );

    return GestureDetector(
      key: ValueKey('media-card-${item.id}'),
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(12.0),
        child: isGrid
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  thumbnail,
                  const SizedBox(height: 12),
                  Text(
                    item.fileName,
                    style: Theme.of(context).textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    detailsStr,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppColors.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  StatusChip(label: statusLabel, variant: variant),
                ],
              )
            : Row(
                children: [
                  SizedBox(width: 96, child: thumbnail),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.fileName,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          detailsStr,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        StatusChip(label: statusLabel, variant: variant),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _MediaThumbnail extends StatelessWidget {
  final MediaItem item;
  final String durationLabel;
  final double height;

  const _MediaThumbnail({
    required this.item,
    required this.durationLabel,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final path = item.thumbnailPath;
    final fallback = _fallback(item);

    Widget image;
    if (path == null || path.isEmpty) {
      image = fallback;
    } else {
      image = Image.file(
        File(path),
        fit: BoxFit.cover,
        width: double.infinity,
        height: height,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) return child;
          return const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (_, _, _) => fallback,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12.0),
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            image,
            Positioned(
              right: 6,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4.0,
                  vertical: 2.0,
                ),
                decoration: BoxDecoration(
                  color: AppColors.baseCanvas.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Text(durationLabel, style: AppTypography.captionCode),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallback(MediaItem item) {
    return ColoredBox(
      color: AppColors.surfaceContainerHigh,
      child: Center(
        child: Icon(
          item.isAudio ? Symbols.audio_file : Symbols.movie,
          color: AppColors.onSurfaceVariant,
          size: 32,
        ),
      ),
    );
  }
}
