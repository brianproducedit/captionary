import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';

class DonatePill extends StatelessWidget {
  final VoidCallback onTap;

  const DonatePill({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        decoration: BoxDecoration(
          color: AppColors.secondaryContainer,
          borderRadius: BorderRadius.circular(9999),
          boxShadow: const [AppShadows.glowSupport],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Symbols.local_cafe, size: 16, color: AppColors.allWhite),
            const SizedBox(width: 4),
            Text(
              'Donate',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.allWhite,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
