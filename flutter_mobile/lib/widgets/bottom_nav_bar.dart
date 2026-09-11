import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_shadows.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;

  const BottomNavBar({super.key, required this.currentIndex});

  void _onItemTapped(BuildContext context, int index) {
    if (index == currentIndex) return;

    switch (index) {
      case 0:
        context.go('/library');
        break;
      case 1:
        context.go('/languages');
        break;
      case 2:
        context.go('/studio');
        break;
      case 3:
        context.go('/donate');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xE6131313), // AppColors.surface with 90% opacity
        boxShadow: [AppShadows.bottomNav],
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 16.0,
            sigmaY: 16.0,
          ), // backdrop-blur-xl
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 10.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _NavBarItem(
                        icon: Symbols.video_library,
                        label: 'Library',
                        isSelected: currentIndex == 0,
                        onTap: () => _onItemTapped(context, 0),
                      ),
                      _NavBarItem(
                        icon: Symbols.language,
                        label: 'Languages',
                        isSelected: currentIndex == 1,
                        onTap: () => _onItemTapped(context, 1),
                      ),
                      _NavBarItem(
                        icon: Symbols.graphic_eq,
                        label: 'Studio',
                        isSelected: currentIndex == 2,
                        onTap: () => _onItemTapped(context, 2),
                      ),
                      _NavBarItem(
                        icon: Symbols.local_cafe,
                        label: 'Donate',
                        isSelected: currentIndex == 3,
                        onTap: () => _onItemTapped(context, 3),
                      ),
                    ],
                  ),
                ),
                // Home indicator (iOS style)
                Container(
                  width: 128,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 6),
                  // decoration: BoxDecoration(
                  //   color: AppColors.surfaceVariant.withValues(alpha: 0.6),
                  //   borderRadius: BorderRadius.circular(9999),
                  // ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 12.0 : 8.0,
          vertical: 8.0,
        ),
        decoration: isSelected
            ? BoxDecoration(
                gradient: AppGradients.primaryGradient,
                borderRadius: BorderRadius.circular(9999),
                boxShadow: const [AppShadows.glowPrimary],
              )
            : BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(9999),
              ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected
                  ? AppColors.onPrimary
                  : AppColors.onSurfaceVariant,
              fill: isSelected ? 1.0 : 0.0,
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
