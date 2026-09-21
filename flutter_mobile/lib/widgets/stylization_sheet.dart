import 'package:captionary/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../core/constants/caption_presets.dart';
import '../data/models/caption_style.dart';
import '../providers/caption_style_provider.dart';
import 'caption_style_card.dart';
import 'caption_style_preview.dart';

class StylizationSheet extends ConsumerStatefulWidget {
  const StylizationSheet({super.key});

  @override
  ConsumerState<StylizationSheet> createState() => _StylizationSheetState();
}

class _StylizationSheetState extends ConsumerState<StylizationSheet> {
  static const _swatches = <Color>[
    Color(0xFF4CAF50),
    Color(0xFFFFC107),
    Color(0xFFFFFFFF),
    Color(0xFF2196F3),
    AppColors.warmCoral,
    AppColors.electricCyan,
    AppColors.deepViolet,
    AppColors.secondary,
  ];

  int _activeTabIndex = 0;

  void _update(CaptionStyle style) {
    ref.read(captionStyleProvider.notifier).updateStyle(style);
  }

  Widget _buildTab(String title, int index) {
    final isActive = _activeTabIndex == index;
    return Expanded(
      child: Semantics(
        button: true,
        selected: isActive,
        label: '$title tab',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _activeTabIndex = index),
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? AppColors.surfaceVariant : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: isActive
                      ? AppColors.onSurface
                      : AppColors.onSurfaceVariant,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
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
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.onSurfaceVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CaptionStylePreview(style: currentStyle),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.only(bottom: AppSpacing.spaceXl),
                  child: Column(
                    children: [
                      if (_activeTabIndex == 0)
                        _buildPresetsPanel(currentStyle),
                      if (_activeTabIndex == 1) _buildTextPanel(currentStyle),
                      if (_activeTabIndex == 2)
                        _buildAnimationPanel(currentStyle),
                      if (_activeTabIndex == 3)
                        _buildColorsPanel(context, currentStyle),
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
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        alignment: WrapAlignment.center,
        children: CaptionPresets.defaultStyles.map((style) {
          return CaptionStyleCard(
            key: ValueKey('preset-${style.name}'),
            style: style,
            isSelected: currentStyle.name == style.name,
            onTap: () {
              ref.read(captionStyleProvider.notifier).setStyle(style);
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTextPanel(CaptionStyle currentStyle) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Font',
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(color: AppColors.onSurface),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${CaptionStyle.fontFamily} — ${currentStyle.previewText}',
              style: TextStyle(
                fontFamily: CaptionStyle.fontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                height: currentStyle.lineHeight,
                color: AppColors.onSurface,
              ),
              textAlign: currentStyle.textAlign.asTextAlign,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Size',
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(color: AppColors.onSurface),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                tooltip: 'Decrease font size',
                onPressed: currentStyle.fontSize <= 7
                    ? null
                    : () => _update(
                        currentStyle.copyWith(
                          fontSize: (currentStyle.fontSize - 2).clamp(7, 48),
                        ),
                      ),
                icon: const Icon(Symbols.remove),
              ),
              Expanded(
                child: Slider(
                  value: currentStyle.fontSize.clamp(7, 48),
                  min: 7,
                  max: 48,
                  label: '${currentStyle.fontSize.round()} pt',
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.surfaceContainerHigh,
                  onChanged: (val) {
                    _update(currentStyle.copyWith(fontSize: val));
                  },
                ),
              ),
              IconButton(
                tooltip: 'Increase font size',
                onPressed: currentStyle.fontSize >= 48
                    ? null
                    : () => _update(
                        currentStyle.copyWith(
                          fontSize: (currentStyle.fontSize + 2).clamp(7, 48),
                        ),
                      ),
                icon: const Icon(Symbols.add),
              ),
              SizedBox(
                width: 48,
                child: Text(
                  '${currentStyle.fontSize.round()}pt',
                  style: AppTypography.captionCode.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Line spacing',
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(color: AppColors.onSurface),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Slider(
                  key: const Key('line-spacing-slider'),
                  value: currentStyle.lineHeight.clamp(1.0, 2.0),
                  min: 1.0,
                  max: 2.0,
                  divisions: 10,
                  label: currentStyle.lineHeight.toStringAsFixed(1),
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.surfaceContainerHigh,
                  onChanged: (val) {
                    _update(currentStyle.copyWith(lineHeight: val));
                  },
                ),
              ),
              Text(
                currentStyle.lineHeight.toStringAsFixed(1),
                style: AppTypography.captionCode.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Alignment',
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(color: AppColors.onSurface),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _alignButton(
                currentStyle,
                CaptionTextAlign.left,
                Symbols.format_align_left,
                'Align left',
              ),
              const SizedBox(width: 8),
              _alignButton(
                currentStyle,
                CaptionTextAlign.center,
                Symbols.format_align_center,
                'Align center',
              ),
              const SizedBox(width: 8),
              _alignButton(
                currentStyle,
                CaptionTextAlign.right,
                Symbols.format_align_right,
                'Align right',
              ),
            ],
          ),

          //Position
          const SizedBox(height: 24),
          Text(
            'Position',
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(color: AppColors.onSurface),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildPositionButton(
                currentStyle,
                SubtitlePosition.top,
                Symbols.vertical_align_top,
                'Top',
              ),
              const SizedBox(width: 8),
              _buildPositionButton(
                currentStyle,
                SubtitlePosition.center,
                Symbols.vertical_align_center,
                'Center',
              ),
              const SizedBox(width: 8),
              _buildPositionButton(
                currentStyle,
                SubtitlePosition.bottom,
                Symbols.vertical_align_bottom,
                'Bottom',
              ),
              const SizedBox(width: 8),
              _buildPositionButton(
                currentStyle,
                SubtitlePosition.custom,
                Symbols.pan_tool_alt,
                'Custom',
              ),
            ],
          ),
          if (currentStyle.position == SubtitlePosition.custom) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Symbols.vertical_distribute,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Slider(
                    value: currentStyle.customY.clamp(-0.9, 0.95),
                    min: -0.9,
                    max: 0.95,
                    divisions: 37,
                    label: '${((currentStyle.customY + 1.0) * 50).round()}%',
                    activeColor: AppColors.primary,
                    inactiveColor: AppColors.surfaceContainerHigh,
                    onChanged: (val) {
                      _update(currentStyle.copyWith(customY: val));
                    },
                  ),
                ),
                Text(
                  '${((currentStyle.customY + 1.0) * 50).round()}%',
                  style: AppTypography.captionCode.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            Text(
              'Tip: You can also drag the caption directly on the video screen.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _alignButton(
    CaptionStyle currentStyle,
    CaptionTextAlign align,
    IconData icon,
    String tooltip,
  ) {
    final isSelected = currentStyle.textAlign == align;
    return Expanded(
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.2)
              : AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => _update(currentStyle.copyWith(textAlign: align)),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Icon(
                icon,
                semanticLabel: tooltip,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPositionButton(
    CaptionStyle currentStyle,
    SubtitlePosition position,
    IconData icon,
    String label,
  ) {
    final isSelected = currentStyle.position == position;
    return Expanded(
      child: Material(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.2)
            : AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _update(currentStyle.copyWith(position: position)),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.onSurfaceVariant,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimationPanel(CaptionStyle currentStyle) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.attentionYellow.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.attentionYellow.withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              'Not applied at burn-in yet. These motion styles are a studio '
              'preview only. Export still burns static styled text until the '
              'ASS engine supports bounce, karaoke, and highlight.',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.onSurface, height: 1.4),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Motion',
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(color: AppColors.onSurface),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: CaptionStyle.animationTypes.map((type) {
              final isSelected = currentStyle.animationType == type;
              final label = type == CaptionStyle.animationNone
                  ? 'None'
                  : type[0].toUpperCase() + type.substring(1);
              return ChoiceChip(
                key: ValueKey('anim-$type'),
                label: Text(label),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    _update(currentStyle.copyWith(animationType: type));
                  }
                },
                selectedColor: AppColors.primaryContainer,
                backgroundColor: AppColors.surfaceContainerHigh,
                labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isSelected
                      ? AppColors.onPrimaryContainer
                      : AppColors.onSurfaceVariant,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text(
            'Preview intensity',
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(color: AppColors.onSurface),
          ),
          const SizedBox(height: 8),
          Slider(
            key: const Key('animation-intensity-slider'),
            value: currentStyle.animationIntensity.clamp(0, 1),
            min: 0,
            max: 1,
            activeColor: AppColors.primary,
            inactiveColor: AppColors.surfaceContainerHigh,
            onChanged: currentStyle.animationType == CaptionStyle.animationNone
                ? null
                : (val) {
                    _update(currentStyle.copyWith(animationIntensity: val));
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildColorsPanel(BuildContext context, CaptionStyle currentStyle) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Live preview',
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(color: AppColors.onSurface),
          ),
          const SizedBox(height: 8),
          CaptionStylePreview(style: currentStyle),
          const SizedBox(height: 24),
          Text(
            'Accent swatches',
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(color: AppColors.onSurface),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _swatches.map((color) {
              final selected =
                  color.toARGB32() == currentStyle.accentColor.toARGB32();
              return Semantics(
                button: true,
                label: 'Accent swatch ${color.toARGB32().toRadixString(16)}',
                child: InkWell(
                  key: ValueKey('swatch-${color.toARGB32()}'),
                  onTap: () =>
                      _update(currentStyle.copyWith(accentColor: color)),
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : AppColors.allWhite,
                        width: selected ? 3 : 2,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Text(
            'Box opacity',
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(color: AppColors.onSurface),
          ),
          Slider(
            key: const Key('box-opacity-slider'),
            value: currentStyle.boxOpacity.clamp(0, 1),
            min: 0,
            max: 1,
            activeColor: AppColors.primary,
            inactiveColor: AppColors.surfaceContainerHigh,
            onChanged: (val) {
              _update(currentStyle.copyWith(boxOpacity: val));
            },
          ),
          Text(
            'Outline',
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(color: AppColors.onSurface),
          ),
          Slider(
            key: const Key('outline-slider'),
            value: currentStyle.outlineWidth.clamp(0, 6),
            min: 0,
            max: 6,
            activeColor: AppColors.primary,
            inactiveColor: AppColors.surfaceContainerHigh,
            onChanged: (val) {
              _update(currentStyle.copyWith(outlineWidth: val));
            },
          ),
          Text(
            'Shadow',
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(color: AppColors.onSurface),
          ),
          Slider(
            key: const Key('shadow-slider'),
            value: currentStyle.shadowBlur.clamp(0, 16),
            min: 0,
            max: 16,
            activeColor: AppColors.primary,
            inactiveColor: AppColors.surfaceContainerHigh,
            onChanged: (val) {
              _update(currentStyle.copyWith(shadowBlur: val));
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Custom accent',
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(color: AppColors.onSurface),
          ),
          const SizedBox(height: 8),
          ColorPicker(
            pickerColor: currentStyle.accentColor,
            onColorChanged: (color) {
              _update(currentStyle.copyWith(accentColor: color));
            },
            colorPickerWidth: 300,
            pickerAreaHeightPercent: 0.55,
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
