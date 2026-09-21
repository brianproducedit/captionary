import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/media_library_query.dart';
import '../data/models/media_item.dart';
import '../data/services/file_import_service.dart';
import '../providers/media_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/ad_banner_widget.dart';
import '../widgets/app_header.dart';
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
  final Set<String> _selectedIds = {};

  bool get _isSelecting => _selectedIds.isNotEmpty;

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _importMedia() async {
    try {
      final item = await ref.read(mediaServiceProvider).importVideo();
      if (item != null) {
        ref.invalidate(recentMediaProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Imported "${item.fileName}" successfully')),
          );
        }
      }
    } on MediaPermissionException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            duration: const Duration(seconds: 5),
            action: e.isPermanentlyDenied
                ? SnackBarAction(
                    label: 'Settings',
                    onPressed: () => openAppSettings(),
                  )
                : null,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to import media: $e')));
      }
    }
  }

  Future<void> _deleteSelectedMedia() async {
    final count = _selectedIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete $count ${count == 1 ? 'item' : 'items'}?'),
        content: const Text(
          'Are you sure you want to remove the selected media files from your library?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final ids = List<String>.from(_selectedIds);
      for (final id in ids) {
        await ref.read(mediaServiceProvider).deleteMedia(id);
      }
      setState(() => _selectedIds.clear());
      ref.invalidate(recentMediaProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed $count ${count == 1 ? 'item' : 'items'}'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final recentMediaAsync = ref.watch(recentMediaProvider);

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: !_isSelecting,
      appBar: _isSelecting
          ? AppBar(
              backgroundColor: AppColors.surfaceContainerHigh,
              leading: IconButton(
                icon: const Icon(Symbols.close),
                onPressed: () => setState(() => _selectedIds.clear()),
              ),
              title: Text('${_selectedIds.length} Selected'),
              actions: [
                IconButton(
                  icon: const Icon(Symbols.select_all),
                  tooltip: 'Select all',
                  onPressed: () {
                    final allItems = recentMediaAsync.value ?? [];
                    setState(() {
                      if (_selectedIds.length == allItems.length) {
                        _selectedIds.clear();
                      } else {
                        _selectedIds.addAll(allItems.map((e) => e.id));
                      }
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Symbols.delete, color: AppColors.error),
                  tooltip: 'Delete selected',
                  onPressed: _deleteSelectedMedia,
                ),
              ],
            )
          : const AppHeader(subtitle: 'Local Media Library'),
      body: ListView(
        padding: EdgeInsets.only(
          top: _isSelecting
              ? 16.0
              : MediaQuery.of(context).padding.top + 64.0 + 16.0,
          bottom: AppSpacing.bottomNavClearance,
          left: 16.0,
          right: 16.0,
        ),
        children: [
          _buildHeroImportCard(context),
          const SizedBox(height: AppSpacing.spaceMd),
          recentMediaAsync.maybeWhen(
            data: (items) => _buildQuickStats(context, items.length),
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(height: AppSpacing.spaceMd),
          DonateBanner(onTap: () => context.go('/donate')),
          const SizedBox(height: AppSpacing.spaceMd),
          _buildSectionHeader(context, recentMediaAsync),
          const SizedBox(height: AppSpacing.spaceSm),
          _buildMediaResults(context, recentMediaAsync),
          const SizedBox(height: 16),
          const AdBannerWidget(),
        ],
      ),
      floatingActionButton: recentMediaAsync.maybeWhen(
        data: (items) => items.isNotEmpty && !_isSelecting
            ? FloatingActionButton.extended(
                onPressed: _importMedia,
                backgroundColor: AppColors.primary,
                icon: const Icon(Symbols.add, color: AppColors.allWhite),
                label: const Text(
                  'Add Media',
                  style: TextStyle(color: AppColors.allWhite),
                ),
              )
            : null,
        orElse: () => null,
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
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
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      'Media Library',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
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
                ],
              ),
            ),
            const SizedBox(width: 8),
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
          return GridView.builder(
            key: const ValueKey('library-grid'),
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: visible.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.63,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
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
    final isSelected = _selectedIds.contains(item.id);
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
      case MediaStatus.error:
        variant = StatusChipVariant.error;
        statusLabel = 'Missing File';
    }

    void onTap() {
      if (_isSelecting) {
        _toggleSelection(item.id);
        return;
      }

      if (item.status == MediaStatus.error) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Missing Media File'),
            content: Text(
              'The file "${item.fileName}" could not be found in cache. It may have been moved or deleted.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Close'),
              ),
              FilledButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  await ref.read(mediaServiceProvider).deleteMedia(item.id);
                  ref.invalidate(recentMediaProvider);
                },
                child: const Text('Remove from Library'),
              ),
            ],
          ),
        );
        return;
      }

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
      height: isGrid ? 104 : 72,
    );

    Widget buildCardActions() {
      return PopupMenuButton<String>(
        key: ValueKey('card-menu-${item.id}'),
        icon: const Icon(
          Symbols.more_vert,
          size: 20,
          color: AppColors.onSurfaceVariant,
        ),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        onSelected: (action) async {
          if (action == 'studio') {
            context.push('/studio', extra: item.filePath);
          } else if (action == 'preview') {
            context.push('/player', extra: item.filePath);
          } else if (action == 'delete') {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Delete Video?'),
                content: Text(
                  'Are you sure you want to remove "${item.fileName}" from your library?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.error,
                    ),
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );
            if (confirmed == true) {
              await ref.read(mediaServiceProvider).deleteMedia(item.id);
              ref.invalidate(recentMediaProvider);
            }
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'studio',
            child: Row(
              children: [
                Icon(Symbols.edit, size: 18),
                SizedBox(width: 8),
                Text('Edit in Studio'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'preview',
            child: Row(
              children: [
                Icon(Symbols.play_arrow, size: 18),
                SizedBox(width: 8),
                Text('Preview Video'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Symbols.delete, size: 18, color: AppColors.error),
                SizedBox(width: 8),
                Text('Remove', style: TextStyle(color: AppColors.error)),
              ],
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      key: ValueKey('media-card-${item.id}'),
      onTap: onTap,
      onLongPress: () => _toggleSelection(item.id),
      child: GlassCard(
        padding: const EdgeInsets.all(12.0),
        border: isSelected
            ? Border.all(color: AppColors.primary, width: 2)
            : null,
        child: isGrid
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      thumbnail,
                      if (_isSelecting)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.surfaceContainerHigh.withValues(
                                      alpha: 0.8,
                                    ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              isSelected ? Symbols.check : null,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item.fileName,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detailsStr,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppColors.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      StatusChip(label: statusLabel, variant: variant),
                      buildCardActions(),
                    ],
                  ),
                ],
              )
            : Row(
                children: [
                  Stack(
                    children: [
                      SizedBox(width: 96, child: thumbnail),
                      if (_isSelecting)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.surfaceContainerHigh.withValues(
                                      alpha: 0.8,
                                    ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                            padding: const EdgeInsets.all(3),
                            child: Icon(
                              isSelected ? Symbols.check : null,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            StatusChip(label: statusLabel, variant: variant),
                            buildCardActions(),
                          ],
                        ),
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
    final isError = item.status == MediaStatus.error;
    return ColoredBox(
      color: isError
          ? AppColors.errorContainer.withValues(alpha: 0.3)
          : AppColors.surfaceContainerHigh,
      child: Center(
        child: Icon(
          isError
              ? Symbols.broken_image_rounded
              : (item.isAudio ? Symbols.audio_file : Symbols.movie),
          color: isError ? AppColors.error : AppColors.onSurfaceVariant,
          size: 32,
        ),
      ),
    );
  }
}
