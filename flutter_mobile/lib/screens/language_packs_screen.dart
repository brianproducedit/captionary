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
import '../providers/system_memory_provider.dart';
import '../data/models/language_pack.dart';
import '../data/services/system_memory_service.dart';
import '../widgets/download_progress_bar.dart';

class LanguagePacksScreen extends ConsumerStatefulWidget {
  const LanguagePacksScreen({super.key});

  @override
  ConsumerState<LanguagePacksScreen> createState() =>
      _LanguagePacksScreenState();
}

class _LanguagePacksScreenState extends ConsumerState<LanguagePacksScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _activeRegion = 'All';

  /// Tracks which model tiers are expanded in the UI.
  final Set<String> _expandedTiers = {'base'};

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
      appBar: const AppHeader(subtitle: 'Manage AI Models'),
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
            _buildPageHeader(context, ref),
            if (ref.watch(isCatalogStaleProvider)) ...[
              const SizedBox(height: 12),
              _buildOfflineBanner(context),
            ],
            const SizedBox(height: 20),
            _buildDeviceCapabilityCard(context, ref),
            const SizedBox(height: 24),
            _buildSearchInput(context),
            const SizedBox(height: 16),
            _buildRegionChips(context),
            const SizedBox(height: 24),
            _buildStorageSummary(context, ref),
            const SizedBox(height: 32),
            _buildModelTiersList(context, ref),
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

  Widget _buildPageHeader(BuildContext context, WidgetRef ref) {
    final isStale = ref.watch(isCatalogStaleProvider);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI Models',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 2),
            Text(
              'Download Whisper models from R2',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(9999),
          ),
          child: Row(
            children: [
              Icon(
                isStale ? Symbols.cloud_off : Symbols.cloud_sync,
                size: 16,
                color: isStale ? AppColors.attentionYellow : AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                isStale ? 'Offline' : 'R2 Sync',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: isStale
                      ? AppColors.attentionYellow
                      : AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOfflineBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.attentionYellow.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.attentionYellow.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Symbols.cloud_off,
            size: 18,
            color: AppColors.attentionYellow,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Showing cached catalog. Connect to the internet to download new models.',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Device Capability Card
  // ---------------------------------------------------------------------------

  Widget _buildDeviceCapabilityCard(BuildContext context, WidgetRef ref) {
    final memInfo = ref.watch(systemMemoryInfoProvider).asData?.value;

    if (memInfo == null) {
      return const SizedBox.shrink();
    }

    final Color tierColor;
    final IconData tierIcon;
    final String tierLabel;
    final String tierDescription;
    final String recommendedModel;

    switch (memInfo.tier) {
      case DeviceRamTier.low:
        tierColor = AppColors.warmCoral;
        tierIcon = Symbols.warning;
        tierLabel = 'Low Memory Device';
        tierDescription =
            '${memInfo.totalRamGb.toStringAsFixed(1)}GB RAM · Use Tiny models for best stability';
        recommendedModel = 'Tiny';
      case DeviceRamTier.standard:
        tierColor = AppColors.attentionYellow;
        tierIcon = Symbols.memory;
        tierLabel = 'Standard Device';
        tierDescription =
            '${memInfo.totalRamGb.toStringAsFixed(1)}GB RAM · Base & Small models work well';
        recommendedModel = 'Base / Small';
      case DeviceRamTier.high:
        tierColor = AppColors.tertiary;
        tierIcon = Symbols.rocket_launch;
        tierLabel = 'High Performance Device';
        tierDescription =
            '${memInfo.totalRamGb.toStringAsFixed(1)}GB RAM · All models supported';
        recommendedModel = 'Small / Medium';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tierColor.withValues(alpha: 0.12),
            AppColors.surfaceContainerLow,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tierColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: tierColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(tierIcon, color: tierColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      tierLabel,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: tierColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: tierColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${memInfo.availableRamGb.toStringAsFixed(1)}GB free',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: tierColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  tierDescription,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 4),
                Text(
                  'Recommended: $recommendedModel',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Search & Filter
  // ---------------------------------------------------------------------------

  Widget _buildSearchInput(BuildContext context) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search languages or models...',
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

  // ---------------------------------------------------------------------------
  // Storage Summary
  // ---------------------------------------------------------------------------

  Widget _buildStorageSummary(BuildContext context, WidgetRef ref) {
    final asyncLangs = ref.watch(availableLanguagesProvider);
    final memInfo = ref.watch(systemMemoryInfoProvider).asData?.value;

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (memInfo != null) ...[
            Row(
              children: [
                Icon(
                  memInfo.tier == DeviceRamTier.low
                      ? Symbols.warning
                      : Symbols.memory,
                  size: 18,
                  color: memInfo.tier == DeviceRamTier.low
                      ? AppColors.attentionYellow
                      : AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  switch (memInfo.tier) {
                    DeviceRamTier.low => 'Low RAM Tier (<4GB)',
                    DeviceRamTier.standard => 'Standard RAM Tier (4–6GB)',
                    DeviceRamTier.high => 'High RAM Tier (≥6GB)',
                  },
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: memInfo.tier == DeviceRamTier.low
                        ? AppColors.attentionYellow
                        : AppColors.onSurface,
                  ),
                ),
                const Spacer(),
                Text(
                  '${memInfo.totalRamGb.toStringAsFixed(1)}GB Total • ${memInfo.availableRamGb.toStringAsFixed(1)}GB Free',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          asyncLangs.when(
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
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Model Tiers List (core of the redesign)
  // ---------------------------------------------------------------------------

  /// Groups language packs by their model file (= model tier) and renders
  /// each tier as an expandable card.
  Widget _buildModelTiersList(BuildContext context, WidgetRef ref) {
    final asyncLangs = ref.watch(availableLanguagesProvider);
    final memInfo = ref.watch(systemMemoryInfoProvider).asData?.value;
    final deviceTier = memInfo?.tier ?? DeviceRamTier.standard;

    return asyncLangs.when(
      data: (langs) {
        // Group packs by model file (e.g. ggml-base.bin, ggml-small.bin)
        final Map<String, List<LanguagePack>> tierMap = {};
        for (final pack in langs) {
          tierMap.putIfAbsent(pack.modelFile, () => []).add(pack);
        }

        // Filter tiers by search and region
        final filteredTierMap = <String, List<LanguagePack>>{};
        for (final entry in tierMap.entries) {
          final filtered = entry.value.where((lang) {
            final matchesSearch =
                _searchQuery.isEmpty ||
                lang.name.toLowerCase().contains(_searchQuery) ||
                lang.nativeName.toLowerCase().contains(_searchQuery) ||
                lang.code.toLowerCase().contains(_searchQuery) ||
                lang.modelFile.toLowerCase().contains(_searchQuery) ||
                lang.accuracy.toLowerCase().contains(_searchQuery);

            final matchesRegion =
                _activeRegion == 'All' ||
                lang.region.toLowerCase().contains(
                  _activeRegion.toLowerCase(),
                ) ||
                (_activeRegion == 'Americas' &&
                    (lang.code == 'es' ||
                        lang.code == 'pt' ||
                        lang.code == 'en')) ||
                (_activeRegion == 'Europe' &&
                    (lang.code == 'en' ||
                        lang.code == 'fr' ||
                        lang.code == 'es' ||
                        lang.code == 'pt' ||
                        lang.code == 'de' ||
                        lang.code == 'it' ||
                        lang.code == 'ru' ||
                        lang.code == 'nl')) ||
                (_activeRegion == 'Asia' &&
                    (lang.code == 'ar' ||
                        lang.code == 'hi' ||
                        lang.code == 'ja' ||
                        lang.code == 'zh' ||
                        lang.code == 'ko' ||
                        lang.code == 'tr'));

            return matchesSearch && matchesRegion;
          }).toList();

          if (filtered.isNotEmpty) {
            filteredTierMap[entry.key] = filtered;
          }
        }

        if (filteredTierMap.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(
                    Symbols.search_off,
                    size: 48,
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No models found',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Try adjusting your search or region filter',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          );
        }

        // Sort tiers by recommended RAM (ascending: Tiny → Base → Small → Medium)
        final sortedKeys = filteredTierMap.keys.toList()
          ..sort((a, b) {
            final aRam = filteredTierMap[a]!.first.recommendedRamGb;
            final bRam = filteredTierMap[b]!.first.recommendedRamGb;
            return aRam.compareTo(bRam);
          });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Available Models',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            ...sortedKeys.map((modelFile) {
              final packs = filteredTierMap[modelFile]!;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildModelTierCard(
                  context: context,
                  ref: ref,
                  modelFile: modelFile,
                  packs: packs,
                  deviceTier: deviceTier,
                  memInfo: memInfo,
                ),
              );
            }),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }

  // ---------------------------------------------------------------------------
  // Single Model Tier Card
  // ---------------------------------------------------------------------------

  Widget _buildModelTierCard({
    required BuildContext context,
    required WidgetRef ref,
    required String modelFile,
    required List<LanguagePack> packs,
    required DeviceRamTier deviceTier,
    required SystemMemoryInfo? memInfo,
  }) {
    final representative = packs.first;
    final isExpanded =
        _searchQuery.isNotEmpty || _expandedTiers.contains(_tierKey(modelFile));
    final isEnglishOnly = modelFile.contains('.en');

    // Determine model tier info
    final tierInfo = _getTierInfo(modelFile, representative);

    // Determine RAM compatibility
    final compatibility = _getCompatibility(
      representative.recommendedRamGb,
      deviceTier,
    );

    // Check install status - since all packs share the same model file,
    // they all share the same status
    final modelStatus = representative.status;
    final isInstalled =
        modelStatus == LanguagePackStatus.installed ||
        modelStatus == LanguagePackStatus.bundled;
    final isDownloading = modelStatus == LanguagePackStatus.downloading;
    final isPaused = modelStatus == LanguagePackStatus.paused;
    final isError = modelStatus == LanguagePackStatus.error;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isInstalled
              ? AppColors.tertiary.withValues(alpha: 0.4)
              : isDownloading || isPaused
              ? AppColors.attentionYellow.withValues(alpha: 0.4)
              : AppColors.surfaceContainerHigh,
        ),
        boxShadow: isInstalled ? const [AppShadows.tertiaryGlow] : null,
      ),
      child: Column(
        children: [
          // Header row
          InkWell(
            onLongPress: isInstalled
                ? () => _showDeleteConfirmationDialog(context, representative)
                : null,
            onTap: () {
              setState(() {
                final key = _tierKey(modelFile);
                if (_expandedTiers.contains(key)) {
                  _expandedTiers.remove(key);
                } else {
                  _expandedTiers.add(key);
                }
              });
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Tier icon
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: tierInfo.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          tierInfo.icon,
                          size: 22,
                          color: tierInfo.color,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Model name + subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    tierInfo.displayName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                if (isInstalled) ...[
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Symbols.verified,
                                    size: 16,
                                    color: AppColors.tertiary,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              tierInfo.subtitle,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      // Status + expand arrow
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildStatusBadge(
                            context,
                            modelStatus,
                            representative,
                          ),
                          const SizedBox(height: 4),
                          AnimatedRotation(
                            turns: isExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: const Icon(
                              Symbols.expand_more,
                              size: 20,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Specs row: Size | RAM | Accuracy | Compatibility
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _buildSpecChip(
                        context,
                        Symbols.storage,
                        '${(representative.sizeBytes / 1000000).toStringAsFixed(0)}MB',
                      ),
                      _buildSpecChip(
                        context,
                        Symbols.memory,
                        '${representative.recommendedRamGb}GB RAM',
                      ),
                      _buildSpecChip(
                        context,
                        Symbols.speed,
                        representative.accuracy,
                      ),
                      _buildCompatibilityChip(context, compatibility),
                      if (isEnglishOnly)
                        _buildSpecChip(
                          context,
                          Symbols.language,
                          'English Only',
                          color: AppColors.primary,
                        ),
                    ],
                  ),

                  // Download progress for active downloads
                  if (isDownloading || isPaused) ...[
                    const SizedBox(height: 12),
                    _buildDownloadProgressSection(
                      context,
                      ref,
                      representative,
                      isPaused,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Expanded content: languages + action button
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildExpandedContent(
              context: context,
              ref: ref,
              packs: packs,
              representative: representative,
              modelFile: modelFile,
              isInstalled: isInstalled,
              isDownloading: isDownloading,
              isPaused: isPaused,
              isError: isError,
              compatibility: compatibility,
              memInfo: memInfo,
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
            sizeCurve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Expanded Content (languages + action)
  // ---------------------------------------------------------------------------

  Widget _buildExpandedContent({
    required BuildContext context,
    required WidgetRef ref,
    required List<LanguagePack> packs,
    required LanguagePack representative,
    required String modelFile,
    required bool isInstalled,
    required bool isDownloading,
    required bool isPaused,
    required bool isError,
    required _Compatibility compatibility,
    required SystemMemoryInfo? memInfo,
  }) {
    final sortedPacks = List<LanguagePack>.from(packs)
      ..sort((a, b) => a.name.compareTo(b.name));

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow.withValues(alpha: 0.5),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(color: AppColors.surfaceContainerHigh),
            const SizedBox(height: 8),

            // Languages label
            Text(
              'Supported Languages (${sortedPacks.length})',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),

            // Language chips
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: sortedPacks.map((pack) {
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onLongPress: isInstalled
                        ? () => _showDeleteConfirmationDialog(context, pack)
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isInstalled
                            ? AppColors.tertiary.withValues(alpha: 0.12)
                            : AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isInstalled
                              ? AppColors.tertiary.withValues(alpha: 0.3)
                              : AppColors.surfaceContainerHighest,
                        ),
                      ),
                      child: Text(
                        '${pack.name} (${pack.nativeName})',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isInstalled
                              ? AppColors.tertiary
                              : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Info / warnings
            if (compatibility == _Compatibility.incompatible) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warmCoral.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.warmCoral.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Symbols.warning,
                      size: 18,
                      color: AppColors.warmCoral,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This model requires ${representative.recommendedRamGb}GB+ RAM. '
                        'Your device (${memInfo?.totalRamGb.toStringAsFixed(1) ?? "<4"}GB) may crash. '
                        'RAM delegation will attempt to offload processing, but stability is not guaranteed.',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: AppColors.warmCoral),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ] else if (compatibility == _Compatibility.marginal) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.attentionYellow.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.attentionYellow.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Symbols.info,
                      size: 18,
                      color: AppColors.attentionYellow,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This model may run slowly on your device. Close background apps for best results. '
                        'RAM delegation is enabled to prevent crashes.',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: AppColors.attentionYellow),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Engine info
            Row(
              children: [
                Icon(
                  Symbols.settings,
                  size: 14,
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 6),
                Text(
                  'Engine: ${representative.engine}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
                const Spacer(),
                Text(
                  'Model: $modelFile',
                  style: AppTypography.captionCode.copyWith(
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                    fontSize: 10,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Action button
            _buildModelActionButton(
              context: context,
              ref: ref,
              representative: representative,
              modelFile: modelFile,
              isInstalled: isInstalled,
              isDownloading: isDownloading,
              isPaused: isPaused,
              isError: isError,
              compatibility: compatibility,
              memInfo: memInfo,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Action Button
  // ---------------------------------------------------------------------------

  Widget _buildModelActionButton({
    required BuildContext context,
    required WidgetRef ref,
    required LanguagePack representative,
    required String modelFile,
    required bool isInstalled,
    required bool isDownloading,
    required bool isPaused,
    required bool isError,
    required _Compatibility compatibility,
    required SystemMemoryInfo? memInfo,
  }) {
    if (isInstalled) {
      // Installed: show "Ready" with delete option
      return Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.tertiary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.tertiary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Symbols.check_circle,
                    size: 20,
                    color: AppColors.tertiary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Installed & Ready',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.tertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
            ),
            child: IconButton(
              icon: const Icon(Symbols.delete, color: AppColors.error),
              onPressed: () {
                _showDeleteConfirmationDialog(context, representative);
              },
              tooltip: 'Delete model',
            ),
          ),
        ],
      );
    }

    if (isDownloading || isPaused) {
      // Downloading/Paused: show pause/resume + cancel
      return Row(
        children: [
          Expanded(
            child: GhostPillButton(
              label: isPaused ? 'Resume Download' : 'Pause',
              icon: isPaused ? Symbols.play_arrow : Symbols.pause,
              isFullWidth: true,
              onTap: () {
                if (isPaused) {
                  ref
                      .read(availableLanguagesProvider.notifier)
                      .startDownload(representative.code);
                } else {
                  ref
                      .read(availableLanguagesProvider.notifier)
                      .pauseDownload(representative.code);
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
            ),
            child: IconButton(
              icon: const Icon(Symbols.close, color: AppColors.error),
              onPressed: () {
                ref
                    .read(availableLanguagesProvider.notifier)
                    .deleteLanguagePack(representative.code);
              },
              tooltip: 'Cancel download',
            ),
          ),
        ],
      );
    }

    if (isError) {
      return GhostPillButton(
        label: 'Retry Download',
        icon: Symbols.refresh,
        isFullWidth: true,
        onTap: () {
          ref
              .read(availableLanguagesProvider.notifier)
              .startDownload(representative.code);
        },
      );
    }

    // Not downloaded
    if (compatibility == _Compatibility.incompatible) {
      return Row(
        children: [
          Expanded(
            child: GhostPillButton(
              label:
                  'Download Anyway (${(representative.sizeBytes / 1000000).toStringAsFixed(0)}MB)',
              icon: Symbols.download,
              isFullWidth: true,
              onTap: () {
                _showLowRamWarningDialog(
                  context,
                  representative,
                  memInfo,
                  onConfirm: () {
                    ref
                        .read(availableLanguagesProvider.notifier)
                        .startDownload(representative.code);
                  },
                );
              },
            ),
          ),
        ],
      );
    }

    return GhostPillButton(
      label:
          'Download Model (${(representative.sizeBytes / 1000000).toStringAsFixed(0)}MB)',
      icon: Symbols.download,
      isFullWidth: true,
      onTap: () {
        ref
            .read(availableLanguagesProvider.notifier)
            .startDownload(representative.code);
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Download Progress Section
  // ---------------------------------------------------------------------------

  Widget _buildDownloadProgressSection(
    BuildContext context,
    WidgetRef ref,
    LanguagePack pack,
    bool isPaused,
  ) {
    final pct = (pack.downloadProgress * 100).toInt();
    return Column(
      children: [
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pack.downloadProgress,
            backgroundColor: AppColors.surfaceContainerHigh,
            valueColor: AlwaysStoppedAnimation<Color>(
              isPaused ? AppColors.onSurfaceVariant : AppColors.attentionYellow,
            ),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isPaused
                  ? 'Paused · $pct%'
                  : '${pack.downloadSpeedMbps?.toStringAsFixed(1) ?? "0"} MB/s',
              style: AppTypography.captionCode.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            Text(
              '$pct%',
              style: AppTypography.captionCode.copyWith(
                color: isPaused
                    ? AppColors.onSurfaceVariant
                    : AppColors.attentionYellow,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Helper Widgets
  // ---------------------------------------------------------------------------

  Widget _buildStatusBadge(
    BuildContext context,
    LanguagePackStatus status,
    LanguagePack pack,
  ) {
    final String label;
    final Color color;

    switch (status) {
      case LanguagePackStatus.installed:
        label = 'Ready';
        color = AppColors.tertiary;
      case LanguagePackStatus.bundled:
        label = 'Built-in';
        color = AppColors.primary;
      case LanguagePackStatus.downloading:
        label = '${(pack.downloadProgress * 100).toInt()}%';
        color = AppColors.attentionYellow;
      case LanguagePackStatus.paused:
        label = 'Paused';
        color = AppColors.onSurfaceVariant;
      case LanguagePackStatus.error:
        label = 'Failed';
        color = AppColors.error;
      case LanguagePackStatus.notDownloaded:
        label = 'Available';
        color = AppColors.onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: color == AppColors.tertiary
                  ? const [AppShadows.tertiaryGlow]
                  : null,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecChip(
    BuildContext context,
    IconData icon,
    String label, {
    Color? color,
  }) {
    final c = color ?? AppColors.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: c),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: c, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildCompatibilityChip(BuildContext context, _Compatibility compat) {
    final String label;
    final Color color;
    final IconData icon;

    switch (compat) {
      case _Compatibility.full:
        label = 'Compatible';
        color = AppColors.tertiary;
        icon = Symbols.check;
      case _Compatibility.marginal:
        label = 'Marginal';
        color = AppColors.attentionYellow;
        icon = Symbols.info;
      case _Compatibility.incompatible:
        label = 'High RAM';
        color = AppColors.warmCoral;
        icon = Symbols.warning;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Dialogs
  // ---------------------------------------------------------------------------

  Future<void> _showLowRamWarningDialog(
    BuildContext context,
    LanguagePack pack,
    SystemMemoryInfo? memInfo, {
    VoidCallback? onConfirm,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceContainerHigh,
          title: const Row(
            children: [
              Icon(Symbols.warning, color: AppColors.warmCoral),
              SizedBox(width: 8),
              Text('High RAM Model'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This model requires at least ${pack.recommendedRamGb}GB RAM, '
                'but your device has ${memInfo?.totalRamGb.toStringAsFixed(1) ?? "<4"}GB.\n',
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.attentionYellow.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🧠 RAM Delegation Active',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'The app will attempt to manage memory by:\n'
                      '• Processing audio in smaller chunks\n'
                      '• Releasing unused resources aggressively\n'
                      '• Using system memory pressure callbacks\n\n'
                      'However, crashes may still occur on very '
                      'low-memory devices.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
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
                'Download Anyway',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: AppColors.attentionYellow),
              ),
            ),
          ],
        );
      },
    );

    if (result == true && onConfirm != null) {
      onConfirm();
    }
  }

  Future<void> _showDeleteConfirmationDialog(
    BuildContext context,
    LanguagePack pack,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceContainerHigh,
          title: Text(
            'Delete ${pack.name}?',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          content: Text(
            'This will delete ${pack.modelFile} and free up ${(pack.sizeBytes / 1000000).toStringAsFixed(0)}MB of storage. '
            'All languages supported by this model will become unavailable until re-downloaded.',
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
      ref
          .read(availableLanguagesProvider.notifier)
          .deleteLanguagePack(pack.code);
    }
  }

  // ---------------------------------------------------------------------------
  // Tier info helpers
  // ---------------------------------------------------------------------------

  String _tierKey(String modelFile) {
    final lower = modelFile.toLowerCase();
    if (lower.contains('tiny.en')) return 'tiny.en';
    if (lower.contains('tiny')) return 'tiny';
    if (lower.contains('base')) return 'base';
    if (lower.contains('small')) return 'small';
    if (lower.contains('medium')) return 'medium';
    if (lower.contains('large')) return 'large';
    return modelFile;
  }

  _TierInfo _getTierInfo(String modelFile, LanguagePack representative) {
    final lower = modelFile.toLowerCase();

    if (lower.contains('medium')) {
      return _TierInfo(
        displayName: 'Medium Model',
        subtitle: 'Maximum accuracy · Best for low-resource languages',
        icon: Symbols.diamond,
        color: AppColors.deepViolet,
      );
    }
    if (lower.contains('small')) {
      return _TierInfo(
        displayName: 'Small Model',
        subtitle: 'High accuracy · Great balance of speed & quality',
        icon: Symbols.auto_awesome,
        color: AppColors.primary,
      );
    }
    if (lower.contains('base')) {
      return _TierInfo(
        displayName: 'Base Model',
        subtitle: 'Standard accuracy · Recommended for most devices',
        icon: Symbols.star,
        color: AppColors.tertiary,
      );
    }
    if (lower.contains('tiny.en')) {
      return _TierInfo(
        displayName: 'Tiny English',
        subtitle: 'Fastest · English only, optimized for speed',
        icon: Symbols.bolt,
        color: AppColors.electricCyan,
      );
    }
    if (lower.contains('tiny')) {
      return _TierInfo(
        displayName: 'Tiny Model',
        subtitle: 'Fastest · Low accuracy, good for quick previews',
        icon: Symbols.bolt,
        color: AppColors.neonMint,
      );
    }

    return _TierInfo(
      displayName: representative.name,
      subtitle: '${representative.accuracy} accuracy',
      icon: Symbols.model_training,
      color: AppColors.onSurfaceVariant,
    );
  }

  _Compatibility _getCompatibility(int requiredRamGb, DeviceRamTier tier) {
    switch (tier) {
      case DeviceRamTier.high:
        return _Compatibility.full;
      case DeviceRamTier.standard:
        if (requiredRamGb <= 4) return _Compatibility.full;
        if (requiredRamGb <= 6) return _Compatibility.marginal;
        return _Compatibility.incompatible;
      case DeviceRamTier.low:
        if (requiredRamGb <= 2) return _Compatibility.full;
        if (requiredRamGb <= 4) return _Compatibility.marginal;
        return _Compatibility.incompatible;
    }
  }
}

// Private data classes
class _TierInfo {
  final String displayName;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _TierInfo({
    required this.displayName,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

enum _Compatibility { full, marginal, incompatible }
