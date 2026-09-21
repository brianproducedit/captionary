import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Service for managing local notifications and scheduling inexact reminders.
///
/// Handles:
/// - Donate reminders (action-based, after N exports)
/// - Inactivity nudges (scheduled after 5 days of no app open)
/// - Export progress foreground notification channel
/// - Deep-link to /donate or /library on notification tap
///
/// NOTE on OEM Delays & Battery Optimization:
/// Inexact alarms ([AndroidScheduleMode.inexactAllowWhileIdle]) are used by default
/// to preserve device battery life without requiring intrusive exact alarm permissions
/// (SCHEDULE_EXACT_ALARM).
/// Modern Android OEM battery managers (e.g. Samsung OneUI, Xiaomi MIUI, Huawei EMUI)
/// batch and throttle inexact background alarms when the device enters Doze mode.
/// Consequently, reminder delivery may experience delays of minutes or hours depending
/// on device idle state. No strict delivery SLA is guaranteed for inexact reminders.
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin;

  NotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static NotificationService? _instance;

  /// Singleton instance.
  static NotificationService get instance =>
      _instance ??= NotificationService();

  @visibleForTesting
  static set instance(NotificationService service) => _instance = service;

  bool _isInitialized = false;
  static bool _timeZonesInitialized = false;

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

  static void _ensureTimeZonesInitialized() {
    if (!_timeZonesInitialized) {
      try {
        tz_data.initializeTimeZones();
        _timeZonesInitialized = true;
      } catch (e) {
        debugPrint('[NotificationService] Timezone init exception: $e');
      }
    }
  }

  static tz.Location _safeLocation() {
    _ensureTimeZonesInitialized();
    try {
      return tz.local;
    } catch (_) {
      try {
        return tz.getLocation('UTC');
      } catch (_) {
        tz_data.initializeTimeZones();
        return tz.getLocation('UTC');
      }
    }
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _ensureTimeZonesInitialized();

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
      debugPrint('[NotificationService] Initialized successfully.');
    } catch (e, stack) {
      debugPrint('[NotificationService] Initialization error: $e\n$stack');
    }
  }

  /// Request notification permission (Android 13+ / iOS).
  Future<bool> requestPermission() async {
    try {
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
    } catch (e) {
      debugPrint('[NotificationService] requestPermission error: $e');
    }

    return false;
  }

  /// Schedule a donate reminder notification after a delay.
  ///
  /// Uses [AndroidScheduleMode.inexactAllowWhileIdle] to minimize battery drain.
  Future<void> scheduleDonateReminder({
    Duration delay = const Duration(hours: 8),
  }) async {
    try {
      final location = _safeLocation();
      final scheduledDate = tz.TZDateTime.now(location).add(delay);

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

  /// Schedule a short test reminder for on-device or integration verification.
  Future<void> scheduleTestReminder({
    Duration delay = const Duration(seconds: 5),
  }) async {
    try {
      final location = _safeLocation();
      final scheduledDate = tz.TZDateTime.now(location).add(delay);

      await _plugin.zonedSchedule(
        id: donateReminderId,
        title: '☕ Captionary Test Reminder',
        body: 'Testing inexact local notification delivery. Tap to visit the donation page.',
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
        '[NotificationService] Test reminder scheduled for $scheduledDate (delay: ${delay.inSeconds}s).',
      );
    } catch (e) {
      debugPrint('[NotificationService] Failed to schedule test reminder: $e');
    }
  }

  /// Schedule an inactivity nudge (5-day idle).
  Future<void> scheduleInactivityNudge({
    Duration delay = const Duration(days: 5),
  }) async {
    try {
      final location = _safeLocation();
      final scheduledDate = tz.TZDateTime.now(location).add(delay);

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
    try {
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
    } catch (e) {
      debugPrint('[NotificationService] Failed to show export progress: $e');
    }
  }

  /// Dismiss the export progress notification.
  Future<void> dismissExportProgress() async {
    await cancel(exportProgressId);
  }
}
