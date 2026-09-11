import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GhostPillButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool isFullWidth;

  const GhostPillButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: 20,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );

    Widget button = GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(
            color: AppColors.outlineVariant,
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: content,
      ),
    );

    if (isFullWidth) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    }
    return button;
  }
}
