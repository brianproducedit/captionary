import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:captionary/providers/subscription_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SubscriptionProvider Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test(
      'Initializes with Free Beta and generates a valid UUID deviceId',
      () async {
        final prefs = await SharedPreferences.getInstance();
        final notifier = SubscriptionNotifier(prefs);

        // Await any microtasks/futures in notifier
        await Future.delayed(const Duration(milliseconds: 10));

        expect(notifier.state.tier, SubscriptionTier.free);
        expect(notifier.state.isPro, isFalse);
        expect(notifier.state.isWatermarkMandatory, isTrue);
        expect(notifier.state.maxExportResolution, 720);
        expect(notifier.state.deviceId, isNotEmpty);
        expect(notifier.state.deviceId.length, 36); // UUID format 8-4-4-4-12
      },
    );

    test(
      'unlockTier(creatorPro) sets permanent Pro status and lifts restrictions',
      () async {
        final prefs = await SharedPreferences.getInstance();
        final notifier = SubscriptionNotifier(prefs);
        await Future.delayed(const Duration(milliseconds: 10));

        await notifier.unlockTier(SubscriptionTier.creatorPro);

        expect(notifier.state.tier, SubscriptionTier.creatorPro);
        expect(notifier.state.isPro, isTrue);
        expect(notifier.state.isWatermarkMandatory, isFalse);
        expect(notifier.state.maxExportResolution, 2160);
      },
    );

    test('unlockTier(pass24h) sets 24-hour expiry', () async {
      final prefs = await SharedPreferences.getInstance();
      final notifier = SubscriptionNotifier(prefs);
      await Future.delayed(const Duration(milliseconds: 10));

      await notifier.unlockTier(SubscriptionTier.pass24h);

      expect(notifier.state.tier, SubscriptionTier.pass24h);
      expect(notifier.state.isPro, isTrue);
      expect(notifier.state.passExpiresAt, isNotNull);
      expect(notifier.state.passExpiresAt!.isAfter(DateTime.now()), isTrue);
    });

    test('resetToFree restores Free Beta restrictions', () async {
      final prefs = await SharedPreferences.getInstance();
      final notifier = SubscriptionNotifier(prefs);
      await Future.delayed(const Duration(milliseconds: 10));

      await notifier.unlockTier(SubscriptionTier.creatorPro);
      expect(notifier.state.isPro, isTrue);

      await notifier.resetToFree();
      expect(notifier.state.tier, SubscriptionTier.free);
      expect(notifier.state.isPro, isFalse);
      expect(notifier.state.isWatermarkMandatory, isTrue);
      expect(notifier.state.maxExportResolution, 720);
    });
  });
}
