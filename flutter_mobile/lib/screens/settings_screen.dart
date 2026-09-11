import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../theme/app_colors.dart';
import '../widgets/sub_screen_header.dart';
import '../widgets/donate_banner.dart';
import '../providers/engagement_provider.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _selectedRamTier = 'Auto';

  final List<String> _ramTiers = [
    'Auto',
    'High (6GB+)',
    'Standard (4GB)',
    'Low (<4GB)',
  ];
  final List<String> _frequencies = ['Every 8 hours', 'Daily', 'Never'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SubScreenHeader(title: 'Settings'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionHeader('General'),
            _buildCard(
              child: Column(
                children: [
                  _buildListTile(
                    title: 'Donate Reminders',
                    subtitle:
                        'Help support the project by keeping reminders on',
                    icon: Symbols.favorite,
                    trailing: _buildCustomSwitch(
                      value: ref.watch(engagementProvider).donateRemindersEnabled,
                      onChanged: (value) {
                        ref.read(engagementProvider.notifier).setDonateRemindersEnabled(value);
                      },
                    ),
                  ),
                  if (ref.watch(engagementProvider).donateRemindersEnabled)
                    const Divider(color: AppColors.surfaceContainerHigh),
                  if (ref.watch(engagementProvider).donateRemindersEnabled)
                    _buildListTile(
                      title: 'Frequency',
                      icon: Symbols.schedule,
                      trailing: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: ref.watch(engagementProvider).reminderFrequency,
                          dropdownColor: AppColors.surfaceContainerHigh,
                          items: _frequencies.where((f) => f != 'Never').map((
                            String value,
                          ) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            if (newValue != null) {
                              ref.read(engagementProvider.notifier).setReminderFrequency(newValue);
                            }
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('Playback & Export'),
            _buildCard(
              child: Column(
                children: [
                  _buildListTile(
                    title: 'Auto-Play Previews',
                    subtitle: 'Play videos automatically in the video player',
                    icon: Symbols.play_circle,
                    trailing: _buildCustomSwitch(
                      value: true,
                      onChanged: (val) {},
                    ),
                  ),
                  const Divider(color: AppColors.surfaceContainerHigh),
                  _buildListTile(
                    title: 'Default Export Quality',
                    icon: Symbols.hd,
                    trailing: Text(
                      '1080p',
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('System'),
            _buildCard(
              child: Column(
                children: [
                  _buildListTile(
                    title: 'RAM Allocation Tier',
                    subtitle: 'Controls how much memory the AI models can use',
                    icon: Symbols.memory,
                    trailing: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedRamTier,
                        dropdownColor: AppColors.surfaceContainerHigh,
                        items: _ramTiers.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedRamTier = newValue;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const Divider(color: AppColors.surfaceContainerHigh),
                  _buildListTile(
                    title: 'Model Cache',
                    subtitle: '1.2 GB used by downloaded language packs',
                    icon: Symbols.storage,
                    trailing: OutlinedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Cache cleared (Mock)')),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.onSurface,
                        side: const BorderSide(
                          color: AppColors.surfaceContainerHigh,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 4.0,
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
            _buildSectionHeader('About'),
            _buildCard(
              child: Column(
                children: [
                  _buildListTile(
                    title: 'App Version',
                    subtitle: '1.0.0 (Build 42)',
                    icon: Symbols.info,
                  ),
                  const Divider(color: AppColors.surfaceContainerHigh),
                  _buildListTile(
                    title: 'Open Source License',
                    subtitle: 'AGPL-3.0',
                    icon: Symbols.gavel,
                    onTap: () {},
                  ),
                  const Divider(color: AppColors.surfaceContainerHigh),
                  _buildListTile(
                    title: 'Rate on Play Store',
                    icon: Symbols.star,
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            DonateBanner(onTap: () => context.push('/donate')),
            const SizedBox(height: 32),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
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

  Widget _buildCard({required Widget child}) {
    return Material(
      color: AppColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: AppColors.surfaceContainerHigh),
        ),
        child: child,
      ),
    );
  }

  Widget _buildListTile({
    required String title,
    String? subtitle,
    required IconData icon,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
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
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 4.0,
      ),
    );
  }

  Widget _buildCustomSwitch({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
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
}
