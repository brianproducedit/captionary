import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/user_preferences.dart';
import 'data/services/notification_service.dart';
import 'providers/engagement_provider.dart';
import 'providers/preferences_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  await NotificationService.instance.initialize();

  NotificationService.instance.onNotificationTap = (payload) {
    debugPrint('[NotificationService] Tapped with payload: $payload');
  };

  var packageInfo = AppPackageInfo.fallback;
  try {
    final info = await PackageInfo.fromPlatform();
    packageInfo = AppPackageInfo(
      version: info.version,
      buildNumber: info.buildNumber,
    );
  } catch (_) {
    packageInfo = AppPackageInfo.fallback;
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appPackageInfoProvider.overrideWithValue(packageInfo),
      ],
      child: const CaptionaryApp(),
    ),
  );
}
