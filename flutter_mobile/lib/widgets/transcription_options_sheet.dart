import 'package:captionary/providers/language_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../data/models/language_pack.dart';
import '../data/services/system_memory_service.dart';
import '../theme/app_colors.dart';
import 'ghost_pill_button.dart';
import 'glass_card.dart';
import 'gradient_pill_button.dart';

class TranscriptionConfig {
  final String languageCode;
  final bool translateToEnglish;
  final String modelQuality; // 'tiny', 'base', 'medium', 'small'

  const TranscriptionConfig({
    required this.languageCode,
    required this.translateToEnglish,
    this.modelQuality = 'base',
  });
}

class TranscriptionOptionsSheet extends ConsumerStatefulWidget {
  final String videoPath;
  final void Function(TranscriptionConfig config) onConfirm;

  const TranscriptionOptionsSheet({
    super.key,
    required this.videoPath,
    required this.onConfirm,
  });

  static Future<TranscriptionConfig?> show(
    BuildContext context, {
    required String videoPath,
  }) {
    return showModalBottomSheet<TranscriptionConfig>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TranscriptionOptionsSheet(
        videoPath: videoPath,
        onConfirm: (config) => Navigator.of(ctx).pop(config),
      ),
    );
  }

  @override
  ConsumerState<TranscriptionOptionsSheet> createState() =>
      _TranscriptionOptionsSheetState();
}

/// Model tier metadata for UI display and RAM-based recommendations.
class _ModelTier {
  final String id;
  final String label;
  final String description;
  final String sizeLabel;
  final int sizeBytes;
  final int recommendedRamGb;

  const _ModelTier({
    required this.id,
    required this.label,
    required this.description,
    required this.sizeLabel,
    required this.sizeBytes,
    required this.recommendedRamGb,
  });
}

class _TranscriptionOptionsSheetState
    extends ConsumerState<TranscriptionOptionsSheet> {
  String _selectedLanguage = 'auto';
  bool _translateToEnglish = false;
  String _modelQuality = 'base';
  bool _isCheckingModel = true;
  bool _isModelInstalled = false;
  int _modelSizeBytes = 147964211;
  int _deviceRamGb = 4;

  static const List<_ModelTier> _modelTiers = [
    _ModelTier(
      id: 'tiny',
      label: 'Tiny Model (Fast & Compact)',
      description: 'Lowest storage & memory, basic accuracy',
      sizeLabel: '77 MB',
      sizeBytes: 77704715,
      recommendedRamGb: 2,
    ),
    _ModelTier(
      id: 'base',
      label: 'Base Model (Recommended)',
      description: 'Good balance of speed and accuracy',
      sizeLabel: '148 MB',
      sizeBytes: 147964211,
      recommendedRamGb: 4,
    ),
    _ModelTier(
      id: 'small',
      label: 'Small Model (High Accuracy)',
      description: 'High accuracy, handles background noise and accents well',
      sizeLabel: '488 MB',
      sizeBytes: 487601967,
      recommendedRamGb: 4,
    ),
    _ModelTier(
      id: 'medium',
      label: 'Medium Model (Maximum Accuracy)',
      description: 'Best accuracy for African languages (Shona, Zulu, etc.) & heavy accents',
      sizeLabel: '1.5 GB',
      sizeBytes: 1533774781,
      recommendedRamGb: 6,
    ),
  ];


  /// Languages where Whisper struggles with small models and benefits from
  /// translate mode or a larger model.
  static const Set<String> _lowResourceLanguages = {
    'sn', 'zu', 'nd', 'st', 'nso', 'tn', 'to', 'xh', 'yo',
  };

  static const List<Map<String, String>> _supportedLanguages = [
    {'code': 'auto', 'name': 'Auto-Detect Language', 'native': 'Auto'},
    {'code': 'en', 'name': 'English', 'native': 'English'},
    {'code': 'sn', 'name': 'Shona', 'native': 'ChiShona'},
    {'code': 'zu', 'name': 'Zulu', 'native': 'isiZulu'},
    {'code': 'sw', 'name': 'Swahili', 'native': 'Kiswahili'},
    {'code': 'af', 'name': 'Afrikaans', 'native': 'Afrikaans'},
    {'code': 'nd', 'name': 'Ndebele', 'native': 'isiNdebele'},
    {'code': 'st', 'name': 'Southern Sotho', 'native': 'Sesotho'},
    {'code': 'xh', 'name': 'Xhosa', 'native': 'isiXhosa'},
    {'code': 'yo', 'name': 'Yoruba', 'native': 'Èdè Yorùbá'},
    {'code': 'es', 'name': 'Spanish', 'native': 'Español'},
    {'code': 'fr', 'name': 'French', 'native': 'Français'},
    {'code': 'de', 'name': 'German', 'native': 'Deutsch'},
    {'code': 'pt', 'name': 'Portuguese', 'native': 'Português'},
    {'code': 'it', 'name': 'Italian', 'native': 'Italiano'},
    {'code': 'ru', 'name': 'Russian', 'native': 'Русский'},
    {'code': 'ar', 'name': 'Arabic', 'native': 'العربية'},
    {'code': 'hi', 'name': 'Hindi', 'native': 'हिन्दी'},
    {'code': 'ja', 'name': 'Japanese', 'native': '日本語'},
    {'code': 'zh', 'name': 'Chinese', 'native': '中文'},
    {'code': 'ko', 'name': 'Korean', 'native': '한국어'},
    {'code': 'tr', 'name': 'Turkish', 'native': 'Türkçe'},
  ];

  @override
  void initState() {
    super.initState();
    _checkModelStatus();
  }

  Future<void> _checkModelStatus() async {
    setState(() => _isCheckingModel = true);
    try {
      final langService = ref.read(languageServiceProvider);
      final langs = await langService.getAvailableLanguages();

      final targetCode = _selectedLanguage == 'auto' ? 'en' : _selectedLanguage;
      LanguagePack pack;
      try {
        pack = langs.firstWhere(
          (p) =>
              p.code == targetCode &&
              p.modelFile.toLowerCase().contains(_modelQuality.toLowerCase()),
        );
      } catch (_) {
        pack = langs.firstWhere(
          (p) =>
              p.modelFile.toLowerCase().contains(_modelQuality.toLowerCase()),
          orElse: () => langs.firstWhere(
            (p) => p.code == targetCode,
            orElse: () => langs.first,
          ),
        );
      }

      final isInstalled =
          pack.status == LanguagePackStatus.installed ||
          pack.status == LanguagePackStatus.bundled;

      // Detect device RAM tier for model recommendations
      int ramGb = 4;
      try {
        const memService = SystemMemoryService();
        final memInfo = await memService.getMemoryInfo();
        ramGb = (memInfo.totalRamBytes / (1024 * 1024 * 1024)).round();
      } catch (_) {}

      if (mounted) {
        setState(() {
          _isModelInstalled = isInstalled;
          _modelSizeBytes = pack.sizeBytes;
          _isCheckingModel = false;
          _deviceRamGb = ramGb;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isModelInstalled = false;
          _isCheckingModel = false;
        });
      }
    }
  }

  String _formatSize(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      final gb = bytes / (1024 * 1024 * 1024);
      return '${gb.toStringAsFixed(1)} GB';
    }
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(0)} MB';
  }

  bool get _isLowResourceSelected =>
      _lowResourceLanguages.contains(_selectedLanguage);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = bottomInset > 0
        ? bottomInset + 8.0
        : MediaQuery.of(context).padding.bottom + 12.0;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceContainerLow : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28.0)),
        border: const Border(
          top: BorderSide(color: AppColors.surfaceContainerHigh, width: 1.0),
        ),
      ),
      padding: EdgeInsets.fromLTRB(20.0, 12.0, 20.0, bottomPadding),
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
          const SizedBox(height: 12),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Symbols.subtitles,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transcription Options',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Choose spoken and subtitle languages',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Scrollable options content
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Spoken Audio Language Selector
                  Text(
                    'SPOKEN AUDIO LANGUAGE',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh.withValues(
                        alpha: 0.6,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedLanguage,
                        isExpanded: true,
                        dropdownColor: AppColors.surfaceContainerHigh,
                        icon: const Icon(
                          Symbols.keyboard_arrow_down,
                          color: AppColors.onSurfaceVariant,
                        ),
                        items: _supportedLanguages.map((lang) {
                          return DropdownMenuItem<String>(
                            value: lang['code'],
                            child: Row(
                              children: [
                                Text(
                                  lang['name']!,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '(${lang['native']})',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedLanguage = val);
                            _checkModelStatus();
                          }
                        },
                      ),
                    ),
                  ),

                  // Low-resource language advisory banner
                  if (_isLowResourceSelected) ...[
                    const SizedBox(height: 8),
                    GlassCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Symbols.lightbulb,
                            color: Colors.amber.shade300,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'For best results with this language, use "Translate into English" mode with the Small or Medium model. '
                              'Smaller models may output "[speaking foreign language]" for low-resource languages.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.amber.shade200,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),

                  // 2. Subtitle Output Language (Original vs Translated English)
                  Text(
                    'SUBTITLES OUTPUT',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Material(
                    color: AppColors.surfaceContainerHigh.withValues(
                      alpha: 0.6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: AppColors.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: RadioGroup<bool>(
                      groupValue: _translateToEnglish,
                      onChanged: (bool? val) {
                        if (val != null) {
                          setState(() => _translateToEnglish = val);
                        }
                      },
                      child: Column(
                        children: [
                          RadioListTile<bool>(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 0,
                            ),
                            value: false,
                            activeColor: AppColors.primary,
                            title: const Text(
                              'Original Spoken Language',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: const Text(
                              'Transcribe words exactly as spoken',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const Divider(height: 1, indent: 12, endIndent: 12),
                          RadioListTile<bool>(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 0,
                            ),
                            value: true,
                            activeColor: AppColors.primary,
                            title: const Text(
                              'Translate into English',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: const Text(
                              'Automatically translate spoken audio to English subtitles',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 3. AI Model Accuracy Selector
                  Text(
                    'AI MODEL ACCURACY',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Material(
                    color: AppColors.surfaceContainerHigh.withValues(
                      alpha: 0.6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: AppColors.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: RadioGroup<String>(
                      groupValue: _modelQuality,
                      onChanged: (String? val) {
                        if (val != null) {
                          setState(() => _modelQuality = val);
                          _checkModelStatus();
                        }
                      },
                      child: Column(
                        children: [
                          for (int i = 0; i < _modelTiers.length; i++) ...[
                            if (i > 0)
                              const Divider(
                                height: 1,
                                indent: 12,
                                endIndent: 12,
                              ),
                            _buildModelTile(_modelTiers[i]),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 4. Model Storage & Readiness Status Box
                  GlassCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isCheckingModel
                              ? Symbols.sync
                              : (_isModelInstalled
                                    ? Symbols.check_circle
                                    : Symbols.cloud_download),
                          color: _isModelInstalled
                              ? Colors.greenAccent
                              : AppColors.primary,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isCheckingModel
                                    ? 'Checking model availability...'
                                    : (_isModelInstalled
                                          ? 'Model Ready in Storage'
                                          : 'Download Required (${_formatSize(_modelSizeBytes)})'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _isModelInstalled
                                    ? 'Saved in persistent storage. Will not be deleted on app uninstall.'
                                    : 'Download once. Preserved across app updates and uninstalls.',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.onSurfaceVariant,
                                ),
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
          ),
          const SizedBox(height: 12),

          // Action Buttons (anchored at the bottom)
          GradientPillButton(
            label: _isModelInstalled
                ? 'Transcribe Video'
                : 'Download & Transcribe (${_formatSize(_modelSizeBytes)})',
            icon: _isModelInstalled ? Symbols.play_arrow : Symbols.download,
            onTap: () {
              widget.onConfirm(
                TranscriptionConfig(
                  languageCode: _selectedLanguage,
                  translateToEnglish: _translateToEnglish,
                  modelQuality: _modelQuality,
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          GhostPillButton(
            label: 'Cancel',
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  /// Builds a single model tier radio tile with RAM recommendation badges.
  Widget _buildModelTile(_ModelTier tier) {
    final bool ramTooLow = _deviceRamGb < tier.recommendedRamGb;

    return RadioListTile<String>(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 0,
      ),
      value: tier.id,
      activeColor: AppColors.primary,
      title: Row(
        children: [
          Expanded(
            child: Text(
              tier.label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (ramTooLow)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${tier.recommendedRamGb}GB+ RAM',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade300,
                ),
              ),
            ),
        ],
      ),
      subtitle: Text(
        '${tier.description} (${tier.sizeLabel})',
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
  }
}
