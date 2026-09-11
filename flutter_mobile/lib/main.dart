import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'data/services/notification_service.dart';
import 'providers/engagement_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Initialize NotificationService
  await NotificationService.instance.initialize();

  // Wire notification tap → GoRouter navigation
  NotificationService.instance.onNotificationTap = (payload) {
    // Payload contains a route like '/donate?from=notification'
    // Navigation will be handled by the GoRouter deep link system
    debugPrint('[NotificationService] Tapped with payload: $payload');
  };

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const CaptionaryApp(),
    ),
  );
}
