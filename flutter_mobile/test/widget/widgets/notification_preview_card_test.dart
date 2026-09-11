import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:captionary/widgets/notification_preview_card.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  testWidgets(
    'NotificationPreviewCard renders title, timestamp, body text, and donate button',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestableWidget(const NotificationPreviewCard()),
      );

      expect(find.text('Captionary'), findsOneWidget);
      expect(find.text('• 8h ago'), findsOneWidget);
      expect(find.text('PREVIEW'), findsOneWidget);
      expect(find.text('☕ Your video captioning matters!'), findsOneWidget);
      expect(find.text('Donate ☕'), findsOneWidget);
    },
  );

  testWidgets('Tapping Donate ☕ calls onDonateTap callback', (
    WidgetTester tester,
  ) async {
    bool tapped = false;

    await tester.pumpWidget(
      buildTestableWidget(
        NotificationPreviewCard(
          onDonateTap: () {
            tapped = true;
          },
        ),
      ),
    );

    await tester.tap(find.text('Donate ☕'));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });
}
