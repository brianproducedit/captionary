import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/services/notification_service.dart';

/// Keys for SharedPreferences
class EngagementKeys {
  static const String exportCount = 'captionary_export_count';
  static const String lastOpenedTimestamp = 'captionary_last_opened';
  static const String donateRemindersEnabled = 'captionary_donate_reminders';
  static const String reminderFrequency = 'captionary_reminder_frequency';
  static const String hasDonated = 'captionary_has_donated';
  static const String notificationsOptedOut =
      'captionary_notifications_opted_out';
  static const String notificationPermissionAsked =
      'captionary_notification_permission_asked';
  static const String hasSeenOnboarding = 'captionary_has_seen_onboarding';
}

/// Manages engagement tracking: export counts, inactivity detection,
/// and scheduling/cancelling of donate reminder notifications.
class EngagementNotifier extends StateNotifier<EngagementState> {
  final SharedPreferences _prefs;

  EngagementNotifier(this._prefs)
    : super(
        EngagementState(
          exportCount: 0,
          donateRemindersEnabled: true,
          reminderFrequency: 'Every 8 hours',
          hasDonated: false,
          notificationsOptedOut: false,
          hasSeenOnboarding: false,
        ),
      ) {
    _loadFromPrefs();
  }

  void _loadFromPrefs() {
    state = EngagementState(
      exportCount: _prefs.getInt(EngagementKeys.exportCount) ?? 0,
      donateRemindersEnabled:
          _prefs.getBool(EngagementKeys.donateRemindersEnabled) ?? true,
      reminderFrequency:
          _prefs.getString(EngagementKeys.reminderFrequency) ?? 'Every 8 hours',
      hasDonated: _prefs.getBool(EngagementKeys.hasDonated) ?? false,
      notificationsOptedOut:
          _prefs.getBool(EngagementKeys.notificationsOptedOut) ?? false,
      hasSeenOnboarding:
          _prefs.getBool(EngagementKeys.hasSeenOnboarding) ?? false,
    );
  }

  Future<void> completeOnboarding() async {
    await _prefs.setBool(EngagementKeys.hasSeenOnboarding, true);
    state = state.copyWith(hasSeenOnboarding: true);
  }

  /// Called each time a video export completes successfully.
  Future<void> onExportCompleted() async {
    final newCount = state.exportCount + 1;
    await _prefs.setInt(EngagementKeys.exportCount, newCount);
    state = state.copyWith(exportCount: newCount);

    // After 2+ exports, schedule a donate reminder (if allowed)
    if (newCount >= 2 && _shouldScheduleReminder()) {
      final delay = _getDelayFromFrequency(state.reminderFrequency);
      await NotificationService.instance.scheduleDonateReminder(delay: delay);
    }
  }

  /// Called on each app launch to record timestamp and schedule inactivity nudge.
  Future<void> onAppOpened() async {
    await _prefs.setString(
      EngagementKeys.lastOpenedTimestamp,
      DateTime.now().toIso8601String(),
    );

    // Cancel any existing inactivity nudge and reschedule for 5 days from now
    if (_shouldScheduleReminder()) {
      await NotificationService.instance.cancel(
        NotificationService.inactivityNudgeId,
      );
      await NotificationService.instance.scheduleInactivityNudge();
    }
  }

  /// Toggle donate reminders on/off.
  Future<void> setDonateRemindersEnabled(bool enabled) async {
    await _prefs.setBool(EngagementKeys.donateRemindersEnabled, enabled);

    String frequency = state.reminderFrequency;
    if (!enabled) {
      frequency = 'Never';
      await NotificationService.instance.cancelAll();
    } else if (frequency == 'Never') {
      frequency = 'Every 8 hours';
    }

    await _prefs.setString(EngagementKeys.reminderFrequency, frequency);
    state = state.copyWith(
      donateRemindersEnabled: enabled,
      reminderFrequency: frequency,
    );
  }

  /// Update reminder frequency.
  Future<void> setReminderFrequency(String frequency) async {
    await _prefs.setString(EngagementKeys.reminderFrequency, frequency);
    state = state.copyWith(reminderFrequency: frequency);
  }

  /// Mark the user as having donated. Cancels all reminders.
  Future<void> markAsDonated() async {
    await _prefs.setBool(EngagementKeys.hasDonated, true);
    await NotificationService.instance.cancelAll();
    state = state.copyWith(hasDonated: true);
  }

  /// Opt out of notifications entirely.
  Future<void> optOutOfNotifications() async {
    await _prefs.setBool(EngagementKeys.notificationsOptedOut, true);
    await NotificationService.instance.cancelAll();
    state = state.copyWith(notificationsOptedOut: true);
  }

  /// Check if notification permission prompt has been shown before.
  bool hasAskedPermission() {
    return _prefs.getBool(EngagementKeys.notificationPermissionAsked) ?? false;
  }

  /// Mark that we've asked for notification permission.
  Future<void> markPermissionAsked() async {
    await _prefs.setBool(EngagementKeys.notificationPermissionAsked, true);
  }

  bool _shouldScheduleReminder() {
    return state.donateRemindersEnabled &&
        !state.hasDonated &&
        !state.notificationsOptedOut;
  }

  Duration _getDelayFromFrequency(String frequency) {
    switch (frequency) {
      case 'Every 8 hours':
        return const Duration(hours: 8);
      case 'Daily':
        return const Duration(days: 1);
      default:
        return const Duration(hours: 8);
    }
  }
}

class EngagementState {
  final int exportCount;
  final bool donateRemindersEnabled;
  final String reminderFrequency;
  final bool hasDonated;
  final bool notificationsOptedOut;
  final bool hasSeenOnboarding;

  const EngagementState({
    required this.exportCount,
    required this.donateRemindersEnabled,
    required this.reminderFrequency,
    required this.hasDonated,
    required this.notificationsOptedOut,
    required this.hasSeenOnboarding,
  });

  EngagementState copyWith({
    int? exportCount,
    bool? donateRemindersEnabled,
    String? reminderFrequency,
    bool? hasDonated,
    bool? notificationsOptedOut,
    bool? hasSeenOnboarding,
  }) {
    return EngagementState(
      exportCount: exportCount ?? this.exportCount,
      donateRemindersEnabled:
          donateRemindersEnabled ?? this.donateRemindersEnabled,
      reminderFrequency: reminderFrequency ?? this.reminderFrequency,
      hasDonated: hasDonated ?? this.hasDonated,
      notificationsOptedOut:
          notificationsOptedOut ?? this.notificationsOptedOut,
      hasSeenOnboarding: hasSeenOnboarding ?? this.hasSeenOnboarding,
    );
  }
}

/// Provider for SharedPreferences — must be overridden in main.dart.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden with a ProviderScope override.',
  );
});

/// Provider for engagement tracking.
final engagementProvider =
    StateNotifierProvider<EngagementNotifier, EngagementState>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return EngagementNotifier(prefs);
    });
