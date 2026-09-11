import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../theme/app_colors.dart';
// import '../theme/app_gradients.dart';
import 'donate_pill.dart';

class SubScreenHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const SubScreenHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
        child: Container(
          height: preferredSize.height,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top,
            left: 8.0,
            right: 16.0,
          ),
          decoration: const BoxDecoration(
            color: Color(0xD9131313),
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
              // Back Button
              IconButton(
                icon: const Icon(Symbols.arrow_back_ios_new, size: 20),
                color: AppColors.onSurface,
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/');
                  }
                },
              ),
              const SizedBox(width: 4),
              // Title
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Donate Pill
              DonatePill(onTap: () => context.push('/donate')),
              const SizedBox(width: 12),

              // Avatar Placeholder
              GestureDetector(
                onTap: () => context.push('/settings'),
                child: Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  child: Icon(
                    Symbols.settings,
                    size: 30,
                    color: AppColors.allWhite,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(64.0 + 40.0);
}
