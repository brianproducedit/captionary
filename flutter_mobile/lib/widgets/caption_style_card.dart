import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../data/models/caption_style.dart';
import '../theme/app_colors.dart';
import 'caption_style_preview.dart';

class CaptionStyleCard extends StatelessWidget {
  static const Size cardSize = Size(148, 176);

  final CaptionStyle style;
  final bool isSelected;
  final bool enabled;
  final VoidCallback? onTap;

  const CaptionStyleCard({
    super.key,
    required this.style,
    required this.isSelected,
    this.enabled = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: cardSize.width,
      height: cardSize.height,
      child: Material(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          focusColor: AppColors.primary.withValues(alpha: 0.18),
          hoverColor: AppColors.primary.withValues(alpha: 0.08),
          splashColor: AppColors.primary.withValues(alpha: 0.22),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: enabled ? 1 : 0.45,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.surfaceContainerHigh,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                    child: Column(
                      children: [
                        Expanded(
                          child: CaptionStylePreview(
                            style: style,
                            fontSizeOverride: 13,
                            maxLines: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          style.name,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: isSelected
                                ? AppColors.onSurface
                                : AppColors.onSurfaceVariant,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Icon(
                      Symbols.check_circle,
                      size: 18,
                      color: isSelected ? AppColors.primary : Colors.transparent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
