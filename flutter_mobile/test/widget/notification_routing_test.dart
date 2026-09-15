import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:captionary/app.dart';
import 'package:captionary/screens/donate_screen.dart';
import 'package:captionary/data/services/notification_service.dart';
import 'package:captionary/providers/engagement_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Cold start with notification payload opens DonateScreen', (tester) async {
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const CaptionaryApp(initialRoute: '/donate'),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(DonateScreen), findsOneWidget);
  });

  testWidgets('Notification tap while running navigates to DonateScreen', (tester) async {
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const CaptionaryApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(DonateScreen), findsNothing);

    // Trigger notification tap callback wired to GoRouter
    NotificationService.instance.onNotificationTap?.call('/donate');

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(DonateScreen), findsOneWidget);
  });
}
