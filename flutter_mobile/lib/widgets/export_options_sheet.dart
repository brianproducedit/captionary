import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../core/duration_format.dart';
import '../providers/crop_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/trim_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_shadows.dart';
import '../theme/app_typography.dart';
import 'gradient_pill_button.dart';
import 'pro_teaser_sheet.dart';

class ExportOptionsSheet extends ConsumerStatefulWidget {
  final String? defaultFileName;
  final Duration? videoDuration;
  final void Function({
    required bool includeWatermark,
    required int targetMaxResolution,
    int? videoBitrateKbps,
    String? customFileName,
  })
  onConfirmExport;

  const ExportOptionsSheet({
    super.key,
    required this.onConfirmExport,
    this.defaultFileName,
    this.videoDuration,
  });

  static Future<void> show(
    BuildContext context, {
    String? defaultFileName,
    Duration? videoDuration,
    required void Function({
      required bool includeWatermark,
      required int targetMaxResolution,
      int? videoBitrateKbps,
      String? customFileName,
    })
    onConfirmExport,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExportOptionsSheet(
        onConfirmExport: onConfirmExport,
        defaultFileName: defaultFileName,
        videoDuration: videoDuration,
      ),
    );
  }

  @override
  ConsumerState<ExportOptionsSheet> createState() => _ExportOptionsSheetState();
}

class _ExportOptionsSheetState extends ConsumerState<ExportOptionsSheet> {
  int _selectedResolution = 720;
  bool _removeWatermark = false;
  int _selectedBitrateKbps = 8000; // Balanced default
  late final TextEditingController _fileNameController;

  String get _bitrateLabel {
    switch (_selectedBitrateKbps) {
      case 4000:
        return 'Small file';
      case 8000:
        return 'Balanced';
      case 12000:
        return 'Best quality';
      default:
        return '${_selectedBitrateKbps ~/ 1000} Mbps';
    }
  }

  String _estimatedSize() {
    final duration = widget.videoDuration;
    if (duration == null || duration.inSeconds <= 0) return '';
    final seconds = duration.inSeconds;
    final bytesEstimate = (seconds * _selectedBitrateKbps * 1000) ~/ 8;
    if (bytesEstimate > 1024 * 1024 * 1024) {
      return '~${(bytesEstimate / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
    return '~${(bytesEstimate / (1024 * 1024)).toStringAsFixed(0)} MB';
  }

  @override
  void initState() {
    super.initState();
    _fileNameController = TextEditingController(
      text: widget.defaultFileName?.trim().isNotEmpty == true
          ? widget.defaultFileName!.trim()
          : 'captioned_video',
    );
  }

  @override
  void dispose() {
    _fileNameController.dispose();
    super.dispose();
  }

  String _sanitizeFileName(String name) {
    final sanitized = name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    return sanitized.isEmpty ? 'captioned_video' : sanitized;
  }

  @override
  Widget build(BuildContext context) {
    final sub = ref.watch(subscriptionProvider);
    final isPro = sub.isPro;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.0)),
        border: Border(
          top: BorderSide(color: AppColors.surfaceContainerHigh, width: 1.0),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        20.0,
        12.0,
        20.0,
        MediaQuery.of(context).padding.bottom + 24.0,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Symbols.video_settings,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Video Export Options',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.allWhite,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Export File Name
            Text(
              'EXPORT FILE NAME',
              style: AppTypography.captionCode.copyWith(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: AppColors.surfaceContainerHigh),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 14.0,
                vertical: 4.0,
              ),
              child: Row(
                children: [
                  const Icon(
                    Symbols.drive_file_rename_outline,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _fileNameController,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.allWhite,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Enter file name',
                        hintStyle: TextStyle(color: AppColors.onSurfaceVariant),
                        isDense: true,
                      ),
                    ),
                  ),
                  Text(
                    '.mp4',
                    style: AppTypography.captionCode.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Resolution Selection
            Text(
              'OUTPUT RESOLUTION',
              style: AppTypography.captionCode.copyWith(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildResolutionChip(
                    context,
                    title: '720p HD',
                    subtitle: 'Free Beta',
                    resolution: 720,
                    isSelected: _selectedResolution == 720,
                    isLocked: false,
                    onTap: () => setState(() => _selectedResolution = 720),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildResolutionChip(
                    context,
                    title: '1080p FHD',
                    subtitle: 'Creator Pro',
                    resolution: 1080,
                    isSelected: _selectedResolution == 1080,
                    isLocked: !isPro,
                    onTap: () {
                      if (!isPro) {
                        ProTeaserSheet.show(
                          context,
                          featureTriggered: '1080p Full HD Export',
                        );
                      } else {
                        setState(() => _selectedResolution = 1080);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildResolutionChip(
                    context,
                    title: '4K UHD',
                    subtitle: 'Creator Pro',
                    resolution: 2160,
                    isSelected: _selectedResolution == 2160,
                    isLocked: !isPro,
                    onTap: () {
                      if (!isPro) {
                        ProTeaserSheet.show(
                          context,
                          featureTriggered: '4K Ultra HD Export',
                        );
                      } else {
                        setState(() => _selectedResolution = 2160);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Watermark Setting
            Text(
              'BRANDING & WATERMARK',
              style: AppTypography.captionCode.copyWith(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14.0),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: AppColors.surfaceContainerHigh),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: Image.asset(
                        'assets/images/captionary_logo.png',
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Symbols.branding_watermark,
                              size: 20,
                              color: AppColors.primary,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '"Captioned by Captionary"',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.allWhite,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isPro ? 'Pro active: toggle to remove watermark' : 'Mandatory on Free Beta to support organic growth',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  if (!isPro) ...[
                    GestureDetector(
                      onTap: () {
                        ProTeaserSheet.show(
                          context,
                          featureTriggered: 'Watermark Removal',
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10.0,
                          vertical: 6.0,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppGradients.primaryGradient,
                          borderRadius: BorderRadius.circular(9999),
                          boxShadow: const [AppShadows.tertiaryGlow],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Symbols.lock,
                              size: 13,
                              color: AppColors.baseCanvas,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'PRO',
                              style: AppTypography.labelMd.copyWith(
                                color: AppColors.baseCanvas,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    Switch(
                      value: !_removeWatermark,
                      activeThumbColor: AppColors.primary,
                      onChanged: (val) {
                        setState(() => _removeWatermark = !val);
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Bitrate / Quality
            Text(
              'EXPORT QUALITY',
              style: AppTypography.captionCode.copyWith(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildBitrateChip(
                  context,
                  label: 'Small',
                  kbps: 4000,
                  icon: Symbols.compress,
                ),
                const SizedBox(width: 8),
                _buildBitrateChip(
                  context,
                  label: 'Balanced',
                  kbps: 8000,
                  icon: Symbols.balance,
                ),
                const SizedBox(width: 8),
                _buildBitrateChip(
                  context,
                  label: 'Best',
                  kbps: 12000,
                  icon: Symbols.high_quality,
                ),
              ],
            ),
            if (_estimatedSize().isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Symbols.storage,
                    size: 14,
                    color: AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Estimated size: ${_estimatedSize()} ($_bitrateLabel)',
                    style: AppTypography.captionCode.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],

            // Trim/Crop summary
            Builder(
              builder: (context) {
                final trim = ref.watch(trimProvider);
                final crop = ref.watch(cropProvider);
                final hasTrim = trim.isEnabled;
                final hasCrop = crop.isEnabled;
                if (!hasTrim && !hasCrop) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hasTrim)
                          Row(
                            children: [
                              const Icon(
                                Symbols.content_cut,
                                size: 14,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Trim: ${formatPlayerTime(trim.start)} — ${formatPlayerTime(trim.end ?? widget.videoDuration ?? Duration.zero)}',
                                style: AppTypography.labelMd.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        if (hasCrop) ...[
                          if (hasTrim) const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Symbols.crop,
                                size: 14,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Crop: ${crop.label}',
                                style: AppTypography.labelMd.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 28),

            // Export Button
            GradientPillButton(
              label: isPro
                  ? 'Export Video (${_selectedResolution}p)'
                  : 'Export in 720p (Free Beta)',
              icon: Symbols.local_fire_department,
              onTap: () {
                Navigator.of(context).pop();
                final includeWatermark = isPro ? !_removeWatermark : true;
                final resolution = isPro ? _selectedResolution : 720;
                widget.onConfirmExport(
                  includeWatermark: includeWatermark,
                  targetMaxResolution: resolution,
                  videoBitrateKbps: _selectedBitrateKbps,
                  customFileName: _sanitizeFileName(_fileNameController.text),
                );
              },
              isFullWidth: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResolutionChip(
    BuildContext context, {
    required String title,
    required String subtitle,
    required int resolution,
    required bool isSelected,
    required bool isLocked,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withAlpha(35)
              : AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.surfaceContainerHigh,
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.allWhite,
                    ),
                  ),
                ),
                if (isLocked) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Symbols.lock,
                    size: 13,
                    color: AppColors.onSurfaceVariant,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBitrateChip(
    BuildContext context, {
    required String label,
    required int kbps,
    required IconData icon,
  }) {
    final isSelected = _selectedBitrateKbps == kbps;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedBitrateKbps = kbps),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withAlpha(35)
                : AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.surfaceContainerHigh,
              width: isSelected ? 1.8 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.onSurfaceVariant,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTypography.labelMd.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppColors.primary : AppColors.allWhite,
                ),
              ),
              Text(
                '${kbps ~/ 1000} Mbps',
                style: AppTypography.captionCode.copyWith(
                  fontSize: 10,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
