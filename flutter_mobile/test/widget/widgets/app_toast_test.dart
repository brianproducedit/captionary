import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:captionary/theme/app_theme.dart';
import 'package:captionary/widgets/app_toast.dart';

void main() {
  Future<void> pumpToast(
    WidgetTester tester, {
    required String message,
    AppToastVariant variant = AppToastVariant.info,
    String? actionLabel,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () {
                  AppToast.show(
                    context,
                    message: message,
                    variant: variant,
                    actionLabel: actionLabel,
                    onAction: actionLabel == null ? null : () {},
                  );
                },
                child: const Text('Show'),
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('Show'));
    await tester.pump();
  }

  testWidgets('shows info toast with dark on-surface text', (tester) async {
    await pumpToast(tester, message: 'Copied');

    final text = tester.widget<Text>(find.text('Copied'));
    expect(text.style?.color, isNotNull);
    expect(find.byIcon(Symbols.info), findsOneWidget);
  });

  testWidgets('shows success, warning, and error variants', (tester) async {
    await pumpToast(tester, message: 'Saved', variant: AppToastVariant.success);
    expect(find.byIcon(Symbols.check_circle), findsOneWidget);
    expect(find.text('Saved'), findsOneWidget);

    await pumpToast(
      tester,
      message: 'Not ready',
      variant: AppToastVariant.warning,
    );
    expect(find.byIcon(Symbols.warning), findsOneWidget);

    await pumpToast(tester, message: 'Failed', variant: AppToastVariant.error);
    expect(find.byIcon(Symbols.error), findsOneWidget);
  });

  testWidgets('optional action button is shown', (tester) async {
    await pumpToast(
      tester,
      message: 'Long message that should remain readable on a dark snackbar',
      actionLabel: 'Retry',
    );

    expect(find.text('Retry'), findsOneWidget);
  });
}
