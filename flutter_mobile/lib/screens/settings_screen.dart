import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../core/constants/app_constants.dart';
import '../core/user_preferences.dart';
import '../providers/engagement_provider.dart';
import '../providers/preferences_provider.dart';
import '../providers/url_open_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/donate_banner.dart';
import '../widgets/ghost_pill_button.dart';
import '../widgets/sub_screen_header.dart';
import '../widgets/app_toast.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _frequencies = ['Every 8 hours', 'Daily'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(preferencesProvider);
    final engagement = ref.watch(engagementProvider);
    final packageInfo = ref.watch(appPackageInfoProvider);

    return Scaffold(
      appBar: const SubScreenHeader(title: 'Settings'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionHeader(context, 'General'),
            _card(
              child: Column(
                children: [
                  _tile(
                    context,
                    title: 'Donate Reminders',
                    subtitle:
                        'Help donate to the project by keeping reminders on',
                    icon: Symbols.favorite,
                    trailing: _switch(
                      value: engagement.donateRemindersEnabled,
                      onChanged: (value) {
                        ref
                            .read(engagementProvider.notifier)
                            .setDonateRemindersEnabled(value);
                      },
                    ),
                  ),
                  if (engagement.donateRemindersEnabled) ...[
                    const Divider(color: AppColors.surfaceContainerHigh),
                    _tile(
                      context,
                      title: 'Frequency',
                      icon: Symbols.schedule,
                      trailing: _dropdown<String>(
                        context,
                        value: engagement.reminderFrequency == 'Never'
                            ? 'Every 8 hours'
                            : engagement.reminderFrequency,
                        items: _frequencies,
                        onChanged: (value) {
                          if (value != null) {
                            ref
                                .read(engagementProvider.notifier)
                                .setReminderFrequency(value);
                          }
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            _sectionHeader(context, 'Playback & Export'),
            _card(
              child: Column(
                children: [
                  _tile(
                    context,
                    title: 'Auto-Play Previews',
                    subtitle: 'Start playback when a video opens',
                    icon: Symbols.play_circle,
                    trailing: _switch(
                      key: const ValueKey('settings-autoplay'),
                      value: prefs.autoPlay,
                      onChanged: (value) {
                        ref.read(preferencesProvider.notifier).setAutoPlay(value);
                      },
                    ),
                  ),
                  const Divider(color: AppColors.surfaceContainerHigh),
                  _tile(
                    context,
                    title: 'Default speed',
                    icon: Symbols.speed,
                    trailing: _dropdown<double>(
                      context,
                      value: prefs.playbackSpeed,
                      items: UserPreferences.playbackSpeeds,
                      label: (speed) => '${speed}x',
                      onChanged: (value) {
                        if (value != null) {
                          ref
                              .read(preferencesProvider.notifier)
                              .setPlaybackSpeed(value);
                        }
                      },
                    ),
                  ),
                  const Divider(color: AppColors.surfaceContainerHigh),
                  _tile(
                    context,
                    title: 'Default volume',
                    subtitle: '${(prefs.volume * 100).round()}%',
                    icon: Symbols.volume_up,
                    trailing: SizedBox(
                      width: 140,
                      child: Slider(
                        key: const ValueKey('settings-volume'),
                        value: prefs.volume,
                        onChanged: (value) {
                          ref.read(preferencesProvider.notifier).setVolume(value);
                        },
                      ),
                    ),
                  ),
                  const Divider(color: AppColors.surfaceContainerHigh),
                  _tile(
                    context,
                    title: 'Default caption format',
                    icon: Symbols.subtitles,
                    trailing: _dropdown<String>(
                      context,
                      value: prefs.exportFormat,
                      items: UserPreferences.exportFormats,
                      label: (value) => value.toUpperCase(),
                      onChanged: (value) {
                        if (value != null) {
                          ref
                              .read(preferencesProvider.notifier)
                              .setExportFormat(value);
                        }
                      },
                    ),
                  ),
                  const Divider(color: AppColors.surfaceContainerHigh),
                  _tile(
                    context,
                    title: 'Default Export Quality',
                    icon: Symbols.hd,
                    trailing: _dropdown<String>(
                      context,
                      value: prefs.exportQuality,
                      items: UserPreferences.exportQualities,
                      onChanged: (value) {
                        if (value != null) {
                          ref
                              .read(preferencesProvider.notifier)
                              .setExportQuality(value);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _sectionHeader(context, 'System'),
            _card(
              child: Column(
                children: [
                  _tile(
                    context,
                    title: 'RAM Allocation Tier',
                    subtitle:
                        'Saved locally. Memory probes are not wired yet.',
                    icon: Symbols.memory,
                    trailing: _dropdown<String>(
                      context,
                      value: prefs.ramTier,
                      items: UserPreferences.ramTiers,
                      onChanged: (value) {
                        if (value != null) {
                          ref.read(preferencesProvider.notifier).setRamTier(value);
                        }
                      },
                    ),
                  ),
                  const Divider(color: AppColors.surfaceContainerHigh),
                  _tile(
                    context,
                    title: 'Model Cache',
                    subtitle: 'Clearing downloaded packs is not implemented yet.',
                    icon: Symbols.storage,
                    trailing: OutlinedButton(
                      onPressed: null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.onSurfaceVariant,
                        side: const BorderSide(
                          color: AppColors.surfaceContainerHigh,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Clear'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _sectionHeader(context, 'About'),
            _card(
              child: Column(
                children: [
                  _tile(
                    context,
                    title: 'App Version',
                    subtitle: packageInfo.label,
                    icon: Symbols.info,
                  ),
                  const Divider(color: AppColors.surfaceContainerHigh),
                  _tile(
                    context,
                    key: const ValueKey('settings-license'),
                    title: 'Open Source License',
                    subtitle: 'AGPL-3.0',
                    icon: Symbols.gavel,
                    onTap: () async {
                      final uri = Uri.parse(AppConstants.licenseUrl);
                      final opened = await ref.read(urlOpenHandlerProvider)(uri);
                      if (!opened && context.mounted) {
                        AppToast.show(
                          context,
                          message: 'Could not open the license page',
                          variant: AppToastVariant.warning,
                        );
                      }
                    },
                  ),
                  const Divider(color: AppColors.surfaceContainerHigh),
                  _tile(
                    context,
                    title: 'Rate on Play Store',
                    subtitle: 'Not listed yet',
                    icon: Symbols.star,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            GhostPillButton(
              key: const ValueKey('settings-reset'),
              label: 'Reset playback defaults',
              onTap: () async {
                await ref.read(preferencesProvider.notifier).resetToDefaults();
                if (context.mounted) {
                  AppToast.show(
                    context,
                    message: 'Playback and export defaults restored',
                    variant: AppToastVariant.info,
                  );
                }
              },
              isFullWidth: true,
            ),
            const SizedBox(height: 32),
            DonateBanner(onTap: () => context.push('/donate')),
            const SizedBox(height: 64),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.onSurfaceVariant,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Material(
      color: AppColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceContainerHigh),
        ),
        child: child,
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    Key? key,
    required String title,
    String? subtitle,
    required IconData icon,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      key: key,
      leading: Icon(icon, color: AppColors.onSurfaceVariant),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.onSurfaceVariant),
            )
          : null,
      trailing: trailing,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _switch({
    Key? key,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      key: key,
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48,
        height: 24,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: value ? AppColors.primary : AppColors.surfaceContainerHigh,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.allWhite,
            ),
          ),
        ),
      ),
    );
  }

  Widget _dropdown<T>(
    BuildContext context, {
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    String Function(T value)? label,
  }) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        value: value,
        dropdownColor: AppColors.surfaceContainerHigh,
        items: [
          for (final item in items)
            DropdownMenuItem<T>(
              value: item,
              child: Text(
                label?.call(item) ?? item.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}
