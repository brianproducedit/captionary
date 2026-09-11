import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:captionary/widgets/notification_permission_sheet.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: child,
      ),
    );
  }

  testWidgets('NotificationPermissionSheet renders title, body, and action buttons', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestableWidget(const NotificationPermissionSheet()));

    expect(find.text('Stay Updated & Support Captionary'), findsOneWidget);
    expect(find.textContaining('Captionary would like to send you occasional reminders'), findsOneWidget);
    expect(find.text('Allow Notifications'), findsOneWidget);
    expect(find.text('Not Now'), findsOneWidget);
  });

  testWidgets('Tapping Allow Notifications triggers onAllowed callback', (WidgetTester tester) async {
    bool allowedCalled = false;

    await tester.pumpWidget(buildTestableWidget(
      NotificationPermissionSheet(
        onAllowed: () {
          allowedCalled = true;
        },
      ),
    ));

    await tester.tap(find.text('Allow Notifications'));
    await tester.pumpAndSettle();

    expect(allowedCalled, isTrue);
  });

  testWidgets('Tapping Not Now triggers onDismissed callback', (WidgetTester tester) async {
    bool dismissedCalled = false;

    await tester.pumpWidget(buildTestableWidget(
      NotificationPermissionSheet(
        onDismissed: () {
          dismissedCalled = true;
        },
      ),
    ));

    await tester.tap(find.text('Not Now'));
    await tester.pumpAndSettle();

    expect(dismissedCalled, isTrue);
  });
}
