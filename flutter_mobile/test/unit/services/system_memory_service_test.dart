import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:captionary/data/services/system_memory_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SystemMemoryInfo and DeviceRamTier', () {
    test(
      'classifies < 3.8 GB as low tier (accounting for 4GB OS carve-outs)',
      () {
        // 2 GB device
        const info2Gb = SystemMemoryInfo(
          totalRamBytes: 2 * 1024 * 1024 * 1024,
          availableRamBytes: 800 * 1024 * 1024,
          thresholdBytes: 400 * 1024 * 1024,
          isLowMemory: false,
          currentRssBytes: 100 * 1024 * 1024,
          maxRssBytes: 150 * 1024 * 1024,
        );
        expect(info2Gb.tier, DeviceRamTier.low);
        expect(info2Gb.totalRamGb, closeTo(2.0, 0.1));

        // 3.5 GB device (budget phone)
        const info35Gb = SystemMemoryInfo(
          totalRamBytes: 3500 * 1024 * 1024,
          availableRamBytes: 1200 * 1024 * 1024,
          thresholdBytes: 400 * 1024 * 1024,
          isLowMemory: false,
          currentRssBytes: 100 * 1024 * 1024,
          maxRssBytes: 150 * 1024 * 1024,
        );
        expect(info35Gb.tier, DeviceRamTier.low);
      },
    );

    test(
      'classifies 3.8 GB to 5.8 GB as standard tier (physical 4GB & 5GB)',
      () {
        // Physical 4 GB device with kernel carve-outs reporting ~3.8 GB
        const info4Gb = SystemMemoryInfo(
          totalRamBytes: 3850 * 1024 * 1024,
          availableRamBytes: 1800 * 1024 * 1024,
          thresholdBytes: 400 * 1024 * 1024,
          isLowMemory: false,
          currentRssBytes: 100 * 1024 * 1024,
          maxRssBytes: 150 * 1024 * 1024,
        );
        expect(info4Gb.tier, DeviceRamTier.standard);

        // Exact 4 GiB
        const info4GiB = SystemMemoryInfo(
          totalRamBytes: 4 * 1024 * 1024 * 1024,
          availableRamBytes: 2 * 1024 * 1024 * 1024,
          thresholdBytes: 500 * 1024 * 1024,
          isLowMemory: false,
          currentRssBytes: 120 * 1024 * 1024,
          maxRssBytes: 200 * 1024 * 1024,
        );
        expect(info4GiB.tier, DeviceRamTier.standard);
      },
    );

    test('classifies >= 5.8 GB as high tier (6GB, 8GB, 12GB devices)', () {
      // 6 GB physical device with carve-outs reporting ~5.8 GB
      const info6Gb = SystemMemoryInfo(
        totalRamBytes: 5850 * 1024 * 1024,
        availableRamBytes: 3000 * 1024 * 1024,
        thresholdBytes: 500 * 1024 * 1024,
        isLowMemory: false,
        currentRssBytes: 100 * 1024 * 1024,
        maxRssBytes: 150 * 1024 * 1024,
      );
      expect(info6Gb.tier, DeviceRamTier.high);

      // 8 GiB
      const info8Gb = SystemMemoryInfo(
        totalRamBytes: 8 * 1024 * 1024 * 1024,
        availableRamBytes: 5 * 1024 * 1024 * 1024,
        thresholdBytes: 600 * 1024 * 1024,
        isLowMemory: false,
        currentRssBytes: 150 * 1024 * 1024,
        maxRssBytes: 250 * 1024 * 1024,
      );
      expect(info8Gb.tier, DeviceRamTier.high);
    });

    test('canSafelyRunModel rejects when lowMemory flag is active', () {
      const service = SystemMemoryService();
      const lowMemInfo = SystemMemoryInfo(
        totalRamBytes: 4 * 1024 * 1024 * 1024,
        availableRamBytes: 2 * 1024 * 1024 * 1024,
        thresholdBytes: 500 * 1024 * 1024,
        isLowMemory: true, // System flagged low memory
        currentRssBytes: 100 * 1024 * 1024,
        maxRssBytes: 150 * 1024 * 1024,
      );

      expect(
        service.canSafelyRunModel(
          modelNameOrPath: 'ggml-tiny.bin',
          memoryInfo: lowMemInfo,
        ),
        isFalse,
      );
    });

    test('canSafelyRunModel respects model thresholds', () {
      const service = SystemMemoryService();

      // Available 200 MB
      const info200Mb = SystemMemoryInfo(
        totalRamBytes: 4 * 1024 * 1024 * 1024,
        availableRamBytes: 200 * 1024 * 1024,
        thresholdBytes: 500 * 1024 * 1024,
        isLowMemory: false,
        currentRssBytes: 100 * 1024 * 1024,
        maxRssBytes: 150 * 1024 * 1024,
      );
      expect(
        service.canSafelyRunModel(
          modelNameOrPath: 'ggml-tiny.bin',
          memoryInfo: info200Mb,
        ),
        isTrue, // tiny requires 150MB
      );
      expect(
        service.canSafelyRunModel(
          modelNameOrPath: 'ggml-base.bin',
          memoryInfo: info200Mb,
        ),
        isFalse, // base requires 300MB
      );

      // Available 800 MB
      const info800Mb = SystemMemoryInfo(
        totalRamBytes: 4 * 1024 * 1024 * 1024,
        availableRamBytes: 800 * 1024 * 1024,
        thresholdBytes: 500 * 1024 * 1024,
        isLowMemory: false,
        currentRssBytes: 100 * 1024 * 1024,
        maxRssBytes: 150 * 1024 * 1024,
      );
      expect(
        service.canSafelyRunModel(
          modelNameOrPath: 'ggml-small.bin',
          memoryInfo: info800Mb,
        ),
        isTrue, // small requires 750MB
      );
      expect(
        service.canSafelyRunModel(
          modelNameOrPath: 'ggml-medium.bin',
          memoryInfo: info800Mb,
        ),
        isFalse, // medium requires 1.5GB
      );

      // Available 3000 MB
      const info3000Mb = SystemMemoryInfo(
        totalRamBytes: 8 * 1024 * 1024 * 1024,
        availableRamBytes: 3000 * 1024 * 1024,
        thresholdBytes: 500 * 1024 * 1024,
        isLowMemory: false,
        currentRssBytes: 100 * 1024 * 1024,
        maxRssBytes: 150 * 1024 * 1024,
      );
      expect(
        service.canSafelyRunModel(
          modelNameOrPath: 'ggml-large-v2.bin',
          memoryInfo: info3000Mb,
        ),
        isTrue, // large requires 2.5GB
      );
    });

    test('recommendedRamGbForModel returns proper GB requirements', () {
      expect(SystemMemoryService.recommendedRamGbForModel('ggml-tiny.bin'), 2);
      expect(SystemMemoryService.recommendedRamGbForModel('ggml-base.bin'), 4);
      expect(SystemMemoryService.recommendedRamGbForModel('ggml-small.bin'), 4);
      expect(
        SystemMemoryService.recommendedRamGbForModel('ggml-medium.bin'),
        6,
      );
      expect(
        SystemMemoryService.recommendedRamGbForModel('ggml-large-v2.bin'),
        8,
      );
    });
  });

  group('SystemMemoryService Platform Channel', () {
    const channel = MethodChannel('com.captionary.captionary/system_memory');

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('invokes getMemoryInfo on platform channel and parses map', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'getMemoryInfo') {
              return <String, dynamic>{
                'totalMem': 4294967296,
                'availMem': 2147483648,
                'lowMemory': false,
                'threshold': 524288000,
              };
            }
            return null;
          });

      const service = SystemMemoryService(channel: channel);
      final memInfo = await service.getMemoryInfo();

      expect(memInfo.totalRamBytes, 4294967296);
      expect(memInfo.availableRamBytes, 2147483648);
      expect(memInfo.isLowMemory, isFalse);
      expect(memInfo.thresholdBytes, 524288000);
      expect(memInfo.tier, DeviceRamTier.standard);
    });

    test('falls back gracefully when platform channel throws', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            throw PlatformException(code: 'UNAVAILABLE');
          });

      const service = SystemMemoryService(channel: channel);
      final memInfo = await service.getMemoryInfo();

      expect(memInfo.totalRamBytes, greaterThan(0));
      expect(memInfo.availableRamBytes, greaterThan(0));
      expect(memInfo.isLowMemory, isFalse);
    });

    test('supports manual overrides for test mocking', () async {
      const service = SystemMemoryService(
        overrideTotalRamBytes: 2 * 1024 * 1024 * 1024,
        overrideAvailableRamBytes: 500 * 1024 * 1024,
        overrideLowMemory: true,
      );
      final memInfo = await service.getMemoryInfo();

      expect(memInfo.totalRamBytes, 2 * 1024 * 1024 * 1024);
      expect(memInfo.availableRamBytes, 500 * 1024 * 1024);
      expect(memInfo.isLowMemory, isTrue);
      expect(memInfo.tier, DeviceRamTier.low);
    });
  });
}
