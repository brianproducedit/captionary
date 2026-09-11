import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../data/models/caption_style.dart';
import '../data/mock/seed_data.dart';
import '../providers/caption_style_provider.dart';
import 'caption_style_card.dart';

class StylizationSheet extends ConsumerStatefulWidget {
  const StylizationSheet({super.key});

  @override
  ConsumerState<StylizationSheet> createState() => _StylizationSheetState();
}

class _StylizationSheetState extends ConsumerState<StylizationSheet> {
  int _activeTabIndex = 0;

  Widget _buildTab(String title, int index) {
    final isActive = _activeTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activeTabIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          decoration: BoxDecoration(
            color: isActive ? AppColors.surfaceVariant : Colors.transparent,
            borderRadius: BorderRadius.circular(16.0),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: isActive ? AppColors.onSurface : AppColors.onSurfaceVariant,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentStyle = ref.watch(captionStyleProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12.0, bottom: 8.0),
                decoration: BoxDecoration(
                  color: AppColors.onSurfaceVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Tabs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    _buildTab('Presets', 0),
                    _buildTab('Text', 1),
                    _buildTab('Animation', 2),
                    _buildTab('Colors', 3),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.surfaceContainerHigh),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    children: [
                      if (_activeTabIndex == 0) _buildPresetsPanel(currentStyle),
                      if (_activeTabIndex == 1) _buildTextPanel(currentStyle),
                      if (_activeTabIndex == 2) _buildAnimationPanel(currentStyle),
                      if (_activeTabIndex == 3) _buildColorsPanel(context, currentStyle),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPresetsPanel(CaptionStyle currentStyle) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Wrap(
        spacing: 16.0,
        runSpacing: 16.0,
        alignment: WrapAlignment.center,
        children: SeedData.captionStyles.map((style) {
          return SizedBox(
            width: 140, // Fixed width for wrap layout
            child: CaptionStyleCard(
              style: style,
              isSelected: currentStyle.name == style.name,
              onTap: () {
                ref.read(captionStyleProvider.notifier).setStyle(style);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTextPanel(CaptionStyle currentStyle) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Font Size',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.onSurface),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Symbols.format_size, size: 16, color: AppColors.onSurfaceVariant),
              Expanded(
                child: Slider(
                  value: currentStyle.fontSize,
                  min: 14.0,
                  max: 48.0,
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.surfaceContainerHigh,
                  onChanged: (val) {
                    ref.read(captionStyleProvider.notifier).updateStyle(currentStyle.copyWith(fontSize: val));
                  },
                ),
              ),
              Text(
                '${currentStyle.fontSize.toInt()}pt',
                style: AppTypography.captionCode.copyWith(color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Position',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.onSurface),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildPositionButton(currentStyle, SubtitlePosition.top, Symbols.vertical_align_top, 'Top'),
              const SizedBox(width: 8),
              _buildPositionButton(currentStyle, SubtitlePosition.center, Symbols.vertical_align_center, 'Center'),
              const SizedBox(width: 8),
              _buildPositionButton(currentStyle, SubtitlePosition.bottom, Symbols.vertical_align_bottom, 'Bottom'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPositionButton(CaptionStyle currentStyle, SubtitlePosition position, IconData icon, String label) {
    final isSelected = currentStyle.position == position;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          ref.read(captionStyleProvider.notifier).updateStyle(currentStyle.copyWith(position: position));
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : AppColors.surfaceContainerHigh,
            border: Border.all(color: isSelected ? AppColors.primary : Colors.transparent),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Column(
            children: [
              Icon(icon, size: 24, color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimationPanel(CaptionStyle currentStyle) {
    final types = ['bounce', 'highlight', 'karaoke', 'minimal'];
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: types.map((type) {
          final isSelected = currentStyle.animationType == type;
          return ChoiceChip(
            label: Text(type.toUpperCase()),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                ref.read(captionStyleProvider.notifier).updateStyle(currentStyle.copyWith(animationType: type));
              }
            },
            selectedColor: AppColors.primaryContainer,
            backgroundColor: AppColors.surfaceContainerHigh,
            labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isSelected ? AppColors.onPrimaryContainer : AppColors.onSurfaceVariant,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildColorsPanel(BuildContext context, CaptionStyle currentStyle) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Accent Color',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.onSurface),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: currentStyle.accentColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.allWhite, width: 2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ColorPicker(
            pickerColor: currentStyle.accentColor,
            onColorChanged: (color) {
              ref.read(captionStyleProvider.notifier).updateStyle(currentStyle.copyWith(accentColor: color));
            },
            colorPickerWidth: 300,
            pickerAreaHeightPercent: 0.7,
            enableAlpha: false,
            displayThumbColor: true,
            paletteType: PaletteType.hsvWithHue,
            pickerAreaBorderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
    );
  }
}
