import 'package:captionary/providers/language_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../data/models/language_pack.dart';
import '../theme/app_colors.dart';
import 'ghost_pill_button.dart';
import 'glass_card.dart';
import 'gradient_pill_button.dart';

class TranscriptionConfig {
  final String languageCode;
  final bool translateToEnglish;
  final String modelQuality; // 'tiny' or 'base'

  const TranscriptionConfig({
    required this.languageCode,
    required this.translateToEnglish,
    this.modelQuality = 'tiny',
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

class _TranscriptionOptionsSheetState
    extends ConsumerState<TranscriptionOptionsSheet> {
  String _selectedLanguage = 'auto';
  bool _translateToEnglish = false;
  final String _modelQuality = 'tiny'; // 'tiny' (77MB) or 'base' (147MB)
  bool _isCheckingModel = true;
  bool _isModelInstalled = false;
  int _modelSizeBytes = 77704715;

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
      final pack = langs.firstWhere(
        (p) => p.code == targetCode,
        orElse: () => langs.first,
      );

      final isInstalled =
          pack.status == LanguagePackStatus.installed ||
          pack.status == LanguagePackStatus.bundled;

      if (mounted) {
        setState(() {
          _isModelInstalled = isInstalled;
          _modelSizeBytes = pack.sizeBytes;
          _isCheckingModel = false;
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
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(0)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceContainerLow : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28.0)),
        border: const Border(
          top: BorderSide(color: AppColors.surfaceContainerHigh, width: 1.0),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        24.0,
        16.0,
        24.0,
        MediaQuery.of(context).padding.bottom + 24.0,
      ),
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

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Symbols.subtitles,
                  color: AppColors.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transcription Options',
                      style: Theme.of(context).textTheme.titleLarge
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
          const SizedBox(height: 24),

          // 1. Spoken Audio Language Selector
          Text(
            'SPOKEN AUDIO LANGUAGE',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14),
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
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${lang['native']})',
                          style: const TextStyle(
                            fontSize: 12,
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
          const SizedBox(height: 20),

          // 2. Subtitle Output Language (Original vs Translated English)
          Text(
            'SUBTITLES OUTPUT',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Material(
            color: AppColors.surfaceContainerHigh.withValues(alpha: 0.6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: AppColors.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                RadioListTile<bool>(
                  value: false,
                  groupValue: _translateToEnglish,
                  activeColor: AppColors.primary,
                  title: const Text('Original Spoken Language'),
                  subtitle: Text(
                    'Transcribe words exactly as spoken',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  onChanged: (val) {
                    if (val != null) setState(() => _translateToEnglish = val);
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                RadioListTile<bool>(
                  value: true,
                  groupValue: _translateToEnglish,
                  activeColor: AppColors.primary,
                  title: const Text('Translate into English'),
                  subtitle: Text(
                    'Automatically translate spoken audio to English subtitles',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  onChanged: (val) {
                    if (val != null) setState(() => _translateToEnglish = val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. Model Storage & Readiness Status Box
          GlassCard(
            padding: const EdgeInsets.all(14),
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
                  size: 24,
                ),
                const SizedBox(width: 12),
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
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isModelInstalled
                            ? 'Saved in persistent storage. Will not be deleted on app uninstall.'
                            : 'Download once. Preserved across app updates and uninstalls.',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons
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
          const SizedBox(height: 10),
          GhostPillButton(
            label: 'Cancel',
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
