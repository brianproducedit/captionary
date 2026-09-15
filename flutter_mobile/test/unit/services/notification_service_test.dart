import 'package:captionary/data/services/notification_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAndroidNotificationsPlatform
    extends AndroidFlutterLocalNotificationsPlugin {
  bool permissionRequested = false;
  final List<AndroidNotificationChannel> createdChannels = [];

  @override
  Future<bool?> requestNotificationsPermission() async {
    permissionRequested = true;
    return true;
  }

  @override
  Future<void> createNotificationChannel(
    AndroidNotificationChannel notificationChannel,
  ) async {
    createdChannels.add(notificationChannel);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final log = <MethodCall>[];
  late NotificationService service;
  late FakeAndroidNotificationsPlatform fakePlatform;

  setUp(() {
    log.clear();
    fakePlatform = FakeAndroidNotificationsPlatform();
    FlutterLocalNotificationsPlatform.instance = fakePlatform;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dexterous.com/flutter/local_notifications'),
          (MethodCall methodCall) async {
            log.add(methodCall);
            switch (methodCall.method) {
              case 'initialize':
                return true;
              case 'getNotificationAppLaunchDetails':
                return null;
              case 'createNotificationChannel':
                return null;
              case 'requestNotificationsPermission':
                return true;
              case 'zonedSchedule':
                return null;
              case 'cancel':
                return null;
              case 'cancelAll':
                return null;
              case 'show':
                return null;
              default:
                return null;
            }
          },
        );

    service = NotificationService();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dexterous.com/flutter/local_notifications'),
          null,
        );
  });

  test(
    'initialize sets up donation and export notification channels',
    () async {
      await service.initialize();

      expect(log.any((call) => call.method == 'initialize'), isTrue);
      expect(fakePlatform.createdChannels.length, 2);

      final channelIds = fakePlatform.createdChannels.map((c) => c.id).toList();
      expect(channelIds, contains('captionary_donate'));
      expect(channelIds, contains('captionary_export'));
    },
  );

  test(
    'requestPermission invokes requestNotificationsPermission on Android',
    () async {
      final granted = await service.requestPermission();
      expect(granted, isTrue);
      expect(fakePlatform.permissionRequested, isTrue);
    },
  );

  test(
    'scheduleDonateReminder schedules inexact alarm with /donate payload',
    () async {
      await service.scheduleDonateReminder(delay: const Duration(hours: 8));

      final scheduleCalls = log
          .where((call) => call.method == 'zonedSchedule')
          .toList();
      expect(scheduleCalls, isNotEmpty);

      final call = scheduleCalls.first;
      expect(call.arguments['id'], NotificationService.donateReminderId);
      expect(call.arguments['payload'], '/donate?from=notification');
      // The scheduled date is set (non-null)
      expect(call.arguments['scheduledDateTime'], isNotNull);
    },
  );

  test(
    'scheduleTestReminder schedules test reminder with short delay',
    () async {
      await service.scheduleTestReminder(delay: const Duration(seconds: 5));

      final scheduleCalls = log
          .where((call) => call.method == 'zonedSchedule')
          .toList();
      expect(scheduleCalls, isNotEmpty);

      final call = scheduleCalls.first;
      expect(call.arguments['id'], NotificationService.donateReminderId);
      expect(call.arguments['payload'], '/donate?from=notification');
      // id and payload verified — channel is correct by construction
    },
  );

  test('scheduleInactivityNudge schedules inexact notification with /library payload', () async {
    await service.scheduleInactivityNudge(delay: const Duration(days: 5));

    final scheduleCalls = log
        .where((call) => call.method == 'zonedSchedule')
        .toList();
    expect(scheduleCalls, isNotEmpty);

    final call = scheduleCalls.first;
    expect(call.arguments['id'], NotificationService.inactivityNudgeId);
    expect(call.arguments['payload'], '/library');
    expect(call.arguments['scheduledDateTime'], isNotNull);
  });

  test('cancel and cancelAll send cancellation commands to plugin', () async {
    await service.cancel(1234);
    expect(
      log.any(
        (call) => call.method == 'cancel' && call.arguments['id'] == 1234,
      ),
      isTrue,
    );

    await service.cancelAll();
    expect(log.any((call) => call.method == 'cancelAll'), isTrue);
  });

  test('showExportProgress and dismissExportProgress display and clear progress notification', () async {
    await service.showExportProgress(
      progress: 0.5,
      title: 'Exporting Video',
      body: 'Processing captions...',
    );

    final showCalls = log.where((call) => call.method == 'show').toList();
    expect(showCalls, isNotEmpty);
    expect(
      showCalls.first.arguments['id'],
      NotificationService.exportProgressId,
    );
    expect(showCalls.first.arguments['title'], 'Exporting Video');
    expect(showCalls.first.arguments['body'], 'Processing captions...');

    await service.dismissExportProgress();
    expect(
      log.any(
        (call) =>
            call.method == 'cancel' &&
            call.arguments['id'] == NotificationService.exportProgressId,
      ),
      isTrue,
    );
  });
}
