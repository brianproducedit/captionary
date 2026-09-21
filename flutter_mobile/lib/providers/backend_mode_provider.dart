import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Backend mode determines which service implementations are wired.
///
/// - [real]: Real production services with Cloudflare R2 catalog and downloads,
///   on-device Whisper transcription, FFmpeg export, and native media import. Default.
/// - [local]: Same as real.
/// - [mock]: In-memory fake/seed data for testing.
///
/// Set via `--dart-define=BACKEND_MODE=real|local|mock`.
enum BackendMode { mock, local, real }

/// Parses the compile-time `BACKEND_MODE` dart-define.
/// Falls back to [BackendMode.real] when unset or unrecognised.
BackendMode _parseMode() {
  const raw = String.fromEnvironment('BACKEND_MODE', defaultValue: 'real');
  switch (raw) {
    case 'mock':
      return BackendMode.mock;
    case 'local':
      return BackendMode.local;
    case 'real':
    default:
      return BackendMode.real;
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
