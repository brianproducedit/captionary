import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Backend mode determines which service implementations are wired.
///
/// - [mock]: All services return fake/seed data. Default for `flutter run`.
/// - [local]: Real on-device services (FFmpeg, Whisper, filesystem).
///   Used for production APK builds.
/// - [real]: Reserved for future remote-API integrations (R2 catalog refresh,
///   cloud transcription, etc.). Currently behaves like [local].
///
/// Set via `--dart-define=BACKEND_MODE=mock|local|real`.
enum BackendMode { mock, local, real }

/// Parses the compile-time `BACKEND_MODE` dart-define.
/// Falls back to [BackendMode.mock] when unset or unrecognised.
BackendMode _parseMode() {
  const raw = String.fromEnvironment('BACKEND_MODE', defaultValue: 'mock');
  switch (raw) {
    case 'local':
      return BackendMode.local;
    case 'real':
      return BackendMode.real;
    default:
      return BackendMode.mock;
  }
}

/// Global provider exposing the current backend mode.
///
/// Override in tests to force a specific mode:
/// ```dart
/// ProviderScope(
///   overrides: [backendModeProvider.overrideWithValue(BackendMode.mock)],
///   child: ...,
/// );
/// ```
final backendModeProvider = Provider<BackendMode>((ref) => _parseMode());
