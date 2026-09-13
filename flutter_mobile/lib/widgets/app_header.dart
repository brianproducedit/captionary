import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../theme/app_colors.dart';
// import '../theme/app_gradients.dart';
import 'donate_pill.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String subtitle;
  final List<Widget>? actions;

  const AppHeader({
    super.key,
    this.title = 'Captionary',
    required this.subtitle,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
        child: Container(
          height: preferredSize.height,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top,
            left: 16.0,
            right: 16.0,
          ),
          decoration: const BoxDecoration(
            color: Color(0xD9131313), // AppColors.surface at ~85% opacity
            border: Border(
              bottom: BorderSide(
                color: AppColors.surfaceContainerHigh,
                width: 1,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar Placeholder
              GestureDetector(
                onTap: () => context.push('/settings'),
                child: Container(
                  width: 32,
                  height: 32,
                  // decoration: const BoxDecoration(
                  //   shape: BoxShape.circle,
                  //   gradient: AppGradients.primaryGradient,
                  // ),
                  alignment: Alignment.center,
                  child: Icon(
                    Symbols.settings,
                    size: 30,
                    color: AppColors.allWhite,
                  ),
                  // child: Text(
                  //   'KO',
                  //   style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  //         color: AppColors.onPrimaryContainer,
                  //         fontWeight: FontWeight.bold,
                  //       ),
                  // ),
                ),
              ),
              const SizedBox(width: 12),
              // Title and Subtitle
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.labelLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppColors.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Custom Actions
              if (actions != null) ...?actions,
              if (actions != null) const SizedBox(width: 12),
              // Donate Pill
              DonatePill(onTap: () => context.push('/donate')),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(64.0 + 40.0); // 64 + top padding approx
}
