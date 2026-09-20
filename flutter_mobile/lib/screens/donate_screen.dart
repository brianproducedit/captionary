import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'upgrade_pro_screen.dart';

/// Legacy alias for [UpgradeProScreen], preserving backwards compatibility for
/// notifications, tests, and deep links.
class DonateScreen extends ConsumerWidget {
  const DonateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const UpgradeProScreen();
  }
}
