import 'package:captionary/widgets/app_header.dart';
import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import '../widgets/ad_banner_widget.dart';
import '../widgets/donate_banner.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/ghost_pill_button.dart';
import '../theme/app_typography.dart';
import '../providers/language_provider.dart';
import '../data/models/language_pack.dart';
import '../widgets/download_progress_bar.dart';

class LanguagePacksScreen extends ConsumerStatefulWidget {
  const LanguagePacksScreen({super.key});

  @override
  ConsumerState<LanguagePacksScreen> createState() =>
      _LanguagePacksScreenState();
}

class _LanguagePacksScreenState extends ConsumerState<LanguagePacksScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _activeRegion = 'All';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: const AppHeader(subtitle: 'Manage Languages'),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            top: 24.0,
            bottom: AppSpacing.bottomNavClearance,
          ),
          children: [
            _buildPageHeader(context),
            const SizedBox(height: 24),
            _buildSearchInput(context),
            const SizedBox(height: 16),
            _buildRegionChips(context),
            const SizedBox(height: 24),
            _buildStorageSummary(context, ref),
            const SizedBox(height: 32),
            _buildLanguageCardsList(context, ref),
            const SizedBox(height: 32),
            DonateBanner(
              key: const ValueKey('donate-banner'),
              onTap: () => context.push('/donate'),
            ),
            const SizedBox(height: 16),
            const AdBannerWidget(),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildPageHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Language Packs',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(9999),
          ),
          child: Row(
            children: [
              const Icon(
                Symbols.cloud_sync,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'R2 Sync Active',
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: AppColors.primary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchInput(BuildContext context) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search languages...',
        hintStyle: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: AppColors.onSurfaceVariant),
        prefixIcon: const Icon(
          Symbols.search,
          color: AppColors.onSurfaceVariant,
        ),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                tooltip: 'Clear search',
                icon: const Icon(
                  Symbols.close,
                  color: AppColors.onSurfaceVariant,
                ),
                onPressed: () {
                  _searchController.clear();
                },
              )
            : null,
        filled: true,
        fillColor: AppColors.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(vertical: 14.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9999),
          borderSide: const BorderSide(color: AppColors.surfaceContainerHigh),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9999),
          borderSide: const BorderSide(color: AppColors.surfaceContainerHigh),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9999),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildRegionChips(BuildContext context) {
    final regions = ['All', 'Africa', 'Europe', 'Asia', 'Americas'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: regions.map((region) {
          final isSelected = _activeRegion == region;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _activeRegion = region;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
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
                  region,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: isSelected
                        ? AppColors.onSurface
                        : AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStorageSummary(BuildContext context, WidgetRef ref) {
    final asyncLangs = ref.watch(availableLanguagesProvider);

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      child: asyncLangs.when(
        data: (langs) {
          double usedStorageGB = 2.0; // Base system size
          for (var lang in langs) {
            if (lang.status == LanguagePackStatus.installed ||
                lang.status == LanguagePackStatus.bundled) {
              usedStorageGB += lang.sizeBytes / 1000000000;
            } else if (lang.status == LanguagePackStatus.downloading) {
              usedStorageGB +=
                  (lang.sizeBytes * lang.downloadProgress) / 1000000000;
            }
          }

          return DownloadProgressBar(
            packs: langs,
            totalStorageGB: 10.0,
            usedStorageGB: usedStorageGB,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const SizedBox(),
      ),
    );
  }

  Widget _buildLanguageCardsList(BuildContext context, WidgetRef ref) {
    final asyncLangs = ref.watch(availableLanguagesProvider);

    return asyncLangs.when(
      data: (langs) {
        final filteredLangs = langs.where((lang) {
          return lang.name.toLowerCase().contains(_searchQuery) ||
              lang.nativeName.toLowerCase().contains(_searchQuery);
        }).toList();

        if (filteredLangs.isEmpty) {
          return const Center(child: Text('No language packs found.'));
        }

        return Column(
          children: filteredLangs.map((lang) {
            String statusStr = 'Available';
            Color statusColor = AppColors.onSurfaceVariant;
            Widget actionWidget = GhostPillButton(
              label:
                  'Download (${(lang.sizeBytes / 1000000).toStringAsFixed(0)}MB)',
              icon: Symbols.download,
              onTap: () {
                ref
                    .read(availableLanguagesProvider.notifier)
                    .simulateDownload(lang.code);
              },
            );
            double? progress;
            String? progressText;
            String? etaText;

            if (lang.status == LanguagePackStatus.installed) {
              statusStr = 'Ready';
              statusColor = AppColors.tertiary;
              actionWidget = IconButton(
                icon: const Icon(Symbols.delete, color: AppColors.error),
                onPressed: () {
                  _showDeleteConfirmationDialog(context, lang);
                },
              );
            } else if (lang.status == LanguagePackStatus.bundled) {
              statusStr = 'Active Default';
              statusColor = AppColors.primary;
              actionWidget = const Icon(
                Symbols.lock,
                color: AppColors.onSurfaceVariant,
              );
            } else if (lang.status == LanguagePackStatus.downloading ||
                lang.status == LanguagePackStatus.paused) {
              final isPaused = lang.status == LanguagePackStatus.paused;
              statusStr = isPaused
                  ? 'Paused ${(lang.downloadProgress * 100).toInt()}%'
                  : 'Downloading ${(lang.downloadProgress * 100).toInt()}%';
              statusColor = isPaused
                  ? AppColors.onSurfaceVariant
                  : AppColors.attentionYellow;

              actionWidget = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Symbols.close, color: AppColors.error),
                    onPressed: () {
                      ref
                          .read(availableLanguagesProvider.notifier)
                          .simulateDelete(lang.code);
                    },
                  ),
                  const SizedBox(width: 8),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: CircularProgressIndicator(
                          value: lang.downloadProgress,
                          strokeWidth: 3,
                          backgroundColor: AppColors.surfaceContainerHighest,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.attentionYellow,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isPaused ? Symbols.play_arrow : Symbols.pause,
                          color: AppColors.onSurface,
                        ),
                        onPressed: () {
                          if (isPaused) {
                            ref
                                .read(availableLanguagesProvider.notifier)
                                .simulateDownload(lang.code);
                          } else {
                            ref
                                .read(availableLanguagesProvider.notifier)
                                .pauseDownload(lang.code);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              );

              // We remove the linear progress bar properties
              progress = null;
              progressText = isPaused
                  ? 'Paused'
                  : '${lang.downloadSpeedMbps?.toStringAsFixed(1) ?? 0} MB/s';
              etaText = isPaused ? '' : 'Downloading...';
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: GestureDetector(
                onLongPress: lang.status == LanguagePackStatus.installed
                    ? () => _showDeleteConfirmationDialog(context, lang)
                    : null,
                child: _buildLanguageCard(
                  context: context,
                  language: '${lang.name} (${lang.nativeName})',
                  status: statusStr,
                  statusColor: statusColor,
                  details: '${lang.accuracy} Accuracy • ${lang.engine}',
                  actionWidget: actionWidget,
                  isVerified:
                      lang.status == LanguagePackStatus.installed ||
                      lang.status == LanguagePackStatus.bundled,
                  progress: progress,
                  progressText: progressText,
                  etaText: etaText,
                ),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }

  Future<void> _showDeleteConfirmationDialog(
    BuildContext context,
    LanguagePack lang,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceContainerHigh,
          title: Text(
            'Delete ${lang.name}?',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          content: Text(
            'This will free up ${(lang.sizeBytes / 1000000).toStringAsFixed(0)}MB of storage. You can download it again later.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: AppColors.onSurface),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Delete',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: AppColors.error),
              ),
            ),
          ],
        );
      },
    );

    if (result == true && mounted) {
      ref.read(availableLanguagesProvider.notifier).simulateDelete(lang.code);
    }
  }

  Widget _buildLanguageCard({
    required BuildContext context,
    required String language,
    required String status,
    required Color statusColor,
    required String details,
    required Widget actionWidget,
    bool isVerified = false,
    double? progress,
    String? progressText,
    String? etaText,
    String? description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            language,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Symbols.verified,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      details,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                    if (description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                          boxShadow: statusColor == AppColors.tertiary
                              ? const [AppShadows.tertiaryGlow]
                              : null,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        status,
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(color: statusColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  actionWidget,
                ],
              ),
            ],
          ),
          if (progressText != null || etaText != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  progressText ?? '',
                  style: AppTypography.captionCode.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                Text(
                  etaText ?? '',
                  style: AppTypography.captionCode.copyWith(
                    color: AppColors.attentionYellow,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
