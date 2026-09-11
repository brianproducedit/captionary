import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:captionary/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: CaptionaryApp()));

    // Use pump instead of pumpAndSettle to avoid infinite animation timeouts
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    // Verify that the app launches and no exceptions are thrown.
    expect(find.byType(CaptionaryApp), findsOneWidget);
  });
}
