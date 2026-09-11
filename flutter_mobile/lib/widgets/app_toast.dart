import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../theme/app_colors.dart';

enum AppToastVariant { success, info, warning, error }

/// Themed SnackBar helper for dark-theme contrast and consistent feedback.
class AppToast {
  AppToast._();

  static void show(
    BuildContext context, {
    required String message,
    AppToastVariant variant = AppToastVariant.info,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      snackBar(
        message: message,
        variant: variant,
        actionLabel: actionLabel,
        onAction: onAction,
        duration: duration,
      ),
    );
  }

  static SnackBar snackBar({
    required String message,
    AppToastVariant variant = AppToastVariant.info,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    final colors = _colorsFor(variant);
    return SnackBar(
      backgroundColor: colors.background,
      behavior: SnackBarBehavior.floating,
      duration: duration,
      content: Row(
        children: [
          Icon(colors.icon, color: colors.foreground, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: 'Lexend',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colors.foreground,
              ),
            ),
          ),
        ],
      ),
      action: actionLabel != null
          ? SnackBarAction(
              label: actionLabel,
              textColor: colors.action,
              onPressed: onAction ?? () {},
            )
          : null,
    );
  }

  static _ToastColors _colorsFor(AppToastVariant variant) {
    switch (variant) {
      case AppToastVariant.success:
        return const _ToastColors(
          background: AppColors.tertiaryContainer,
          foreground: AppColors.allWhite,
          action: AppColors.tertiaryFixed,
          icon: Symbols.check_circle,
        );
      case AppToastVariant.info:
        return const _ToastColors(
          background: AppColors.surfaceContainerHighest,
          foreground: AppColors.onSurface,
          action: AppColors.primaryFixed,
          icon: Symbols.info,
        );
      case AppToastVariant.warning:
        return const _ToastColors(
          background: Color(0xFF4A3800),
          foreground: AppColors.onSurface,
          action: AppColors.attentionYellow,
          icon: Symbols.warning,
        );
      case AppToastVariant.error:
        return const _ToastColors(
          background: AppColors.errorContainer,
          foreground: AppColors.onErrorContainer,
          action: AppColors.error,
          icon: Symbols.error,
        );
    }
  }
}

class _ToastColors {
  final Color background;
  final Color foreground;
  final Color action;
  final IconData icon;

  const _ToastColors({
    required this.background,
    required this.foreground,
    required this.action,
    required this.icon,
  });
}
