import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:captionary/core/async_lock.dart';

void main() {
  group('AsyncLock', () {
    test('enforces mutual exclusion for concurrent tasks', () async {
      final lock = AsyncLock();
      final executionOrder = <int>[];

      expect(lock.isLocked, isFalse);

      // Task 1 acquires lock
      await lock.acquire();
      expect(lock.isLocked, isTrue);

      // Task 2 attempts to acquire lock in background
      final completer2 = Completer<void>();
      unawaited(() async {
        await lock.acquire();
        executionOrder.add(2);
        completer2.complete();
        lock.release();
      }());

      // Yield event loop
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(executionOrder, isEmpty); // Task 2 is waiting

      executionOrder.add(1);
      lock.release(); // Task 1 releases lock

      await completer2.future;
      expect(executionOrder, [1, 2]);
      expect(lock.isLocked, isFalse);
    });

    test('supports sequential acquire and release', () async {
      final lock = AsyncLock();

      await lock.acquire();
      expect(lock.isLocked, isTrue);
      lock.release();
      expect(lock.isLocked, isFalse);

      await lock.acquire();
      expect(lock.isLocked, isTrue);
      lock.release();
      expect(lock.isLocked, isFalse);
    });
  });
}
