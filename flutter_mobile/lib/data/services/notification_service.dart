import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// Singleton service for managing local notifications.
///
/// Handles:
/// - Donate reminders (action-based, after N exports)
/// - Inactivity nudges (scheduled after 5 days of no app open)
/// - Export progress foreground notification channel
/// - Deep-link to /donate on notification tap
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // Notification channel IDs
  static const String _donateChannelId = 'captionary_donate';
  static const String _donateChannelName = 'Donation Reminders';
  static const String _donateChannelDesc =
      'Occasional reminders to donate to the Captionary project.';

  static const String _exportChannelId = 'captionary_export';
  static const String _exportChannelName = 'Export Progress';
  static const String _exportChannelDesc =
      'Shows progress during video export.';

  // Notification IDs
  static const int donateReminderId = 1001;
  static const int inactivityNudgeId = 1002;
  static const int exportProgressId = 1003;

  /// Callback for when a notification is tapped.
  /// Set this from the app layer to handle navigation (e.g., to /donate).
  void Function(String? payload)? onNotificationTap;

  /// Retrieves details if the app was launched by tapping a notification.
  Future<NotificationAppLaunchDetails?> getNotificationAppLaunchDetails() =>
      _plugin.getNotificationAppLaunchDetails();

  /// Initialize the notification plugin.
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone database
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/launcher_icon',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        onNotificationTap?.call(response.payload);
      },
    );

    // Create Android notification channels
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _donateChannelId,
          _donateChannelName,
          description: _donateChannelDesc,
          importance: Importance.defaultImportance,
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _exportChannelId,
          _exportChannelName,
          description: _exportChannelDesc,
          importance: Importance.low,
          showBadge: false,
        ),
      );
    }

    _isInitialized = true;
    debugPrint('[NotificationService] Initialized.');
  }

  /// Request notification permission (Android 13+ / iOS).
  Future<bool> requestPermission() async {
    // Android 13+
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    }

    // iOS
    final iosPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (iosPlugin != null) {
      final granted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return false;
  }

  /// Schedule a donate reminder notification after a delay.
  Future<void> scheduleDonateReminder({
    Duration delay = const Duration(hours: 8),
  }) async {
    try {
      final scheduledDate = tz.TZDateTime.now(tz.local).add(delay);

      await _plugin.zonedSchedule(
        id: donateReminderId,
        title: '☕ Your video captioning matters!',
        body: 'Fuel Captionary with a small donation to keep our AI language models updated and accessible to everyone.',
        scheduledDate: scheduledDate,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _donateChannelId,
            _donateChannelName,
            channelDescription: _donateChannelDesc,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            icon: '@mipmap/launcher_icon',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: '/donate?from=notification',
      );

      debugPrint(
        '[NotificationService] Donate reminder scheduled for $scheduledDate.',
      );
    } catch (e) {
      debugPrint(
        '[NotificationService] Failed to schedule donate reminder: $e',
      );
    }
  }

  /// Schedule an inactivity nudge (5-day idle).
  Future<void> scheduleInactivityNudge({
    Duration delay = const Duration(days: 5),
  }) async {
    try {
      final scheduledDate = tz.TZDateTime.now(tz.local).add(delay);

      await _plugin.zonedSchedule(
        id: inactivityNudgeId,
        title: '👋 We miss you!',
        body: 'Your videos are waiting for captions. Come back and add some magic!',
        scheduledDate: scheduledDate,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _donateChannelId,
            _donateChannelName,
            channelDescription: _donateChannelDesc,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            icon: '@mipmap/launcher_icon',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: '/library',
      );

      debugPrint(
        '[NotificationService] Inactivity nudge scheduled for $scheduledDate.',
      );
    } catch (e) {
      debugPrint(
        '[NotificationService] Failed to schedule inactivity nudge: $e',
      );
    }
  }

  /// Cancel all scheduled notifications.
  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
      debugPrint('[NotificationService] All notifications cancelled.');
    } catch (e) {
      debugPrint(
        '[NotificationService] Failed to cancel all notifications: $e',
      );
    }
  }

  /// Cancel a specific notification by ID.
  Future<void> cancel(int id) async {
    try {
      await _plugin.cancel(id: id);
    } catch (e) {
      debugPrint('[NotificationService] Failed to cancel notification: $e');
    }
  }

  /// Show an immediate notification (e.g., for export progress).
  Future<void> showExportProgress({
    required double progress,
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      id: exportProgressId,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _exportChannelId,
          _exportChannelName,
          channelDescription: _exportChannelDesc,
          importance: Importance.low,
          priority: Priority.low,
          ongoing: true,
          autoCancel: false,
          showProgress: true,
          maxProgress: 100,
          progress: (progress * 100).toInt(),
          icon: '@mipmap/launcher_icon',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  /// Dismiss the export progress notification.
  Future<void> dismissExportProgress() async {
    await cancel(exportProgressId);
  }
}
