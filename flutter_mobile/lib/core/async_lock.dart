import 'dart:async';

/// Simple asynchronous Mutex lock to enforce single-task or single-job concurrency.
class AsyncLock {
  Completer<void>? _lock;

  /// Acquires the lock, waiting asynchronously if already held.
  Future<void> acquire() async {
    while (_lock != null) {
      await _lock!.future;
    }
    _lock = Completer<void>();
  }

  /// Releases the lock, waking the next waiting caller.
  void release() {
    if (_lock != null && !_lock!.isCompleted) {
      final lockToRelease = _lock!;
      _lock = null;
      lockToRelease.complete();
    }
  }

  /// Indicates whether the lock is currently held.
  bool get isLocked => _lock != null;
}
