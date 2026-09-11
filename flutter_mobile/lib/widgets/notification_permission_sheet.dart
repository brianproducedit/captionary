import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import 'gradient_pill_button.dart';
import 'ghost_pill_button.dart';

class NotificationPermissionSheet extends StatelessWidget {
  final VoidCallback? onAllowed;
  final VoidCallback? onDismissed;

  const NotificationPermissionSheet({
    super.key,
    this.onAllowed,
    this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(
        left: 24.0,
        right: 24.0,
        top: 12.0,
        bottom: 32.0,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.0),
          topRight: Radius.circular(24.0),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(9999),
            ),
          ),
          const SizedBox(height: 32),
          // Icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary),
              boxShadow: const [AppShadows.glowPrimary],
            ),
            child: const Icon(
              Symbols.notifications_active,
              size: 32,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          // Text
          Text(
            'Stay Updated & Donate to Captionary',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Captionary would like to send you occasional reminders to donate to the project and notify you of background transcription status.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 32),
          // Buttons
          SizedBox(
            width: double.infinity,
            child: GradientPillButton(
              label: 'Allow Notifications',
              icon: Symbols.check,
              onTap: () {
                onAllowed?.call();
                Navigator.of(context).pop(true);
              },
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: GhostPillButton(
              label: 'Not Now',
              onTap: () {
                onDismissed?.call();
                Navigator.of(context).pop(false);
              },
            ),
          ),
        ],
      ),
    );
  }
}

Future<bool?> showNotificationPermissionSheet(
  BuildContext context, {
  VoidCallback? onAllowed,
  VoidCallback? onDismissed,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => NotificationPermissionSheet(
      onAllowed: onAllowed,
      onDismissed: onDismissed,
    ),
  );
}
