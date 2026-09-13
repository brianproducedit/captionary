import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:captionary/app.dart';
import 'package:captionary/providers/engagement_provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const CaptionaryApp(),
      ),
    );

    // Use pump instead of pumpAndSettle to avoid infinite animation timeouts
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    // Verify that the app launches and no exceptions are thrown.
    expect(find.byType(CaptionaryApp), findsOneWidget);
  });
}
