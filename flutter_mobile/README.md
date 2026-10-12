# Captionary — Flutter Mobile App

> **100% on-device AI video captioning studio for Android.**
> Whisper AI transcription, subtitle stylization, and FFmpeg video burn-in — all running natively on your phone with zero cloud dependencies.

**Current Version:** `1.0.1+2` · **Min Android:** 8.0+ (API 26) · **Flutter:** 3.47.1 · **Dart SDK:** ^3.13.1

---

## 🚀 Quick Start

### Development (Mock Mode — No Physical Device Required)

```bash
cd flutter_mobile
flutter pub get
flutter run --dart-define=BACKEND_MODE=mock
```

Mock mode provides synthetic transcription data, in-memory media library, and simulated export progress — ideal for UI development and testing without Whisper or FFmpeg native plugins.

### Production (Real AI — Physical Android Device Required)

```bash
cd flutter_mobile
flutter pub get
flutter run --dart-define=BACKEND_MODE=local
```

Production mode runs real Whisper inference on-device. Requires a physical Android device with a downloaded language model (minimum ~40MB for Whisper Tiny).

### Build Release APK

```bash
cd flutter_mobile

flutter build apk --release --dart-define-from-file=.env

git tag -d v1.0.1
git tag v1.0.1 
git push origin v1.0.1 --force

flutter build apk --release --dart-define=ADMOB_BANNER_ID=<your_banner_id>
```

### Run Tests & Analysis

```bash
flutter test          # 85+ tests across unit, service, and widget suites
flutter analyze       # Static analysis — currently 0 issues
```

---

## 🏗️ Architecture

### Directory Structure

```
flutter_mobile/
├── lib/
│   ├── main.dart                    # App entry point & backend mode injection
│   ├── app.dart                     # GoRouter configuration & theme setup
│   ├── core/                        # Shared utilities
│   │   ├── performance_logger.dart  # RSS memory & timing instrumentation
│   │   ├── whisper_output_parser.dart
│   │   ├── subtitle_file_store.dart
│   │   └── ...
│   ├── data/
│   │   ├── models/                  # Immutable data classes
│   │   │   ├── subtitle_segment.dart
│   │   │   ├── export_job.dart
│   │   │   ├── caption_style.dart
│   │   │   ├── download_progress.dart
│   │   │   ├── language_pack.dart
│   │   │   └── ...
│   │   ├── mock/                    # Mock service implementations
│   │   │   ├── mock_export_service.dart
│   │   │   ├── mock_media_service.dart
│   │   │   └── ...
│   │   └── services/               # 19 production services
│   │       ├── caption_pipeline.dart         # End-to-end orchestration engine
│   │       ├── whisper_transcription_service.dart  # Native Whisper AI inference
│   │       ├── ffmpeg_export_service.dart    # Video burn-in with ASS/SRT fallback
│   │       ├── r2_language_pack_service.dart # R2 model downloads & recovery
│   │       ├── system_memory_service.dart    # RAM tier classification
│   │       ├── audio_preprocessor.dart       # FFmpeg audio extraction
│   │       ├── storage_service.dart          # Disk usage accounting
│   │       ├── notification_service.dart     # Local push notifications
│   │       ├── file_import_service.dart      # Video import & validation
│   │       ├── local_media_service.dart      # On-device media library
│   │       ├── ffmpeg_metadata_service.dart  # Video metadata extraction
│   │       ├── ffmpeg_thumbnail_service.dart # Thumbnail generation
│   │       ├── media_player_service.dart     # Video playback control
│   │       ├── ad_service.dart               # AdMob integration
│   │       └── ...
│   ├── providers/                   # Riverpod state management
│   │   ├── export_provider.dart
│   │   ├── backend_mode_provider.dart
│   │   ├── caption_pipeline_provider.dart
│   │   └── ...
│   ├── screens/                     # 10 app screens
│   │   ├── media_library_screen.dart         # Video library with grid view
│   │   ├── studio_screen.dart                # Caption editing studio
│   │   ├── transcription_screen.dart         # Live transcription progress
│   │   ├── export_screen.dart                # Export progress & completion
│   │   ├── video_player_screen.dart          # Full video player
│   │   ├── language_packs_screen.dart        # Model download manager
│   │   ├── settings_screen.dart              # Storage, cache, preferences
│   │   ├── onboarding_screen.dart            # First launch setup
│   │   ├── upgrade_pro_screen.dart           # Pro plans & features
│   │   └── donate_screen.dart                # Support the project
│   ├── theme/                       # Design system
│   │   ├── app_colors.dart
│   │   ├── app_gradients.dart
│   │   ├── app_shadows.dart
│   │   └── app_typography.dart
│   └── widgets/                     # 36 reusable UI components
│       ├── caption_timeline.dart             # Interactive subtitle timeline
│       ├── stylization_sheet.dart            # Style customization panel
│       ├── transcription_options_sheet.dart   # Transcription settings
│       ├── export_options_sheet.dart          # Export quality settings
│       ├── subtitle_overlay.dart             # Live preview overlay
│       ├── subtitle_correction_sheet.dart    # Text editing sheet
│       ├── download_progress_bar.dart        # Model download progress
│       ├── gradient_pill_button.dart          # Primary action button
│       ├── ghost_pill_button.dart             # Secondary action button
│       └── ... (27 more widgets)
├── test/
│   ├── unit/                        # 16+ unit test files
│   │   ├── services/                # Service-level tests
│   │   │   ├── ffmpeg_export_service_test.dart
│   │   │   ├── whisper_transcription_service_test.dart
│   │   │   ├── storage_service_test.dart
│   │   │   ├── caption_pipeline_test.dart
│   │   │   └── ...
│   │   ├── r2_language_pack_service_test.dart
│   │   ├── caption_export_test.dart
│   │   ├── backend_mode_switch_test.dart
│   │   └── ...
│   └── widget/                      # Widget & integration tests
│       ├── screens/
│       │   └── export_screen_test.dart
│       └── widgets/
│           └── stylization_sheet_test.dart
└── android/
    └── app/src/main/
        └── AndroidManifest.xml      # hasFragileUserData, permissions
```

### State Management

The app uses **Riverpod** with the `StateNotifier` pattern. The `BackendMode` enum (`mock` / `local` / `real`) is injected at startup and drives which service implementations are provided:

| Provider | Mock Mode | Production Mode |
|---|---|---|
| `exportServiceProvider` | `MockExportService` | `FfmpegExportService` |
| `mediaServiceProvider` | `MockMediaService` | `LocalMediaService` |
| `languagePackServiceProvider` | `MockLanguagePackService` | `R2LanguagePackService` |
| `transcriptionServiceProvider` | `MockTranscriptionService` | `WhisperTranscriptionService` |

### Navigation

GoRouter with 10 routes and fade transitions:
`/onboarding` → `/library` → `/studio` → `/player` → `/languages` → `/settings` → `/pro` → `/donate` → `/export`

---

## 🔧 Key Technical Details

### Caption Pipeline

The `CaptionPipeline` is the central orchestration engine. It manages the full flow:

```
Import Video → Extract Audio (FFmpeg) → Detect Language → Check/Download Model
    → Transcribe (Whisper, chunked) → Merge Segments → Ready for Styling
```

Each stage emits `CaptionPipelineState` updates with typed status enums, progress percentages, and human-readable action descriptions. The pipeline supports cancellation at any stage and enforces a concurrency lock (one pipeline per media ID).

### FFmpeg Export Service

Video export uses a **two-pass fallback strategy:**

1. **Attempt 1 (ASS):** Burns styled ASS subtitles with custom font directory. Supports variable weight Lexend font, precise positioning, and logo overlay watermark.
2. **Attempt 2 (SRT):** If ASS filter fails (e.g., libass not compiled), falls back to SRT subtitles with `force_style` parameters.

Both passes use:
- Atomic `.part` file rename (no partial output on crash)
- AAC audio transcoding (`-c:a aac -b:a 192k`) for universal MP4 compatibility
- Configurable resolution scaling (720p cap for free tier, 1080p for Pro)
- Real-time progress tracking via FFmpeg statistics callback

### Model Persistence

Downloaded Whisper models are stored in a **public Android Downloads directory** that survives app uninstallation:

```
/storage/emulated/0/Download/Captionary/models/
```

On reinstall:
1. The service scans candidate directories (Downloads, app support, app documents).
2. If a model binary exists but its `.meta.json` metadata file is missing (deleted during uninstall), metadata is regenerated from the R2 catalog manifest.
3. The model appears as "installed" immediately without re-downloading.

The `android:hasFragileUserData="true"` manifest flag prompts the user during uninstallation (Android 10+) to optionally preserve app data.

### RAM Safety Engine

`SystemMemoryService` classifies devices into three tiers:

| Tier | Available RAM | Whisper Config |
|---|---|---|
| **Low** | < 4 GB | Tiny model, 15s chunks, 2 threads |
| **Standard** | 4–6 GB | Small model, 30s chunks, 4 threads |
| **High** | ≥ 6 GB | Medium model, 60s chunks, 6 threads |

If available RAM drops below the safety threshold during transcription, a `LowMemoryException` is thrown and the pipeline gracefully cancels.

---

## 📦 Dependencies

### Production

| Package | Purpose |
|---|---|
| `whisper_flutter_new` | Native Whisper AI speech recognition |
| `ffmpeg_kit_flutter_new_min_gpl` | FFmpeg video processing & audio extraction |
| `flutter_riverpod` | Reactive state management |
| `go_router` | Declarative routing with deep links |
| `media_kit` + `media_kit_video` | High-performance video playback |
| `dio` | HTTP client for R2 downloads with Range support |
| `crypto` | SHA-256 checksum verification |
| `share_plus` | Native share sheet integration |
| `path_provider` | Platform-aware directory resolution |
| `google_mobile_ads` | AdMob banner integration |
| `flutter_local_notifications` | Scheduled & immediate local notifications |
| `permission_handler` | Runtime permission management |
| `flutter_colorpicker` | Color selection for subtitle styling |
| `material_symbols_icons` | Material Symbols icon set |

### Dev

| Package | Purpose |
|---|---|
| `flutter_test` | Widget and unit testing framework |
| `flutter_lints` | Recommended lint rules |
| `flutter_launcher_icons` | Adaptive icon generation |
| `flutter_native_splash` | Splash screen generation |

---

## 🧪 Testing

### Running Tests

```bash
# Run all tests
flutter test

# Run a specific test file
flutter test test/unit/services/ffmpeg_export_service_test.dart

# Run with verbose output
flutter test --reporter expanded
```

### Test Highlights

| Test File | What It Verifies |
|---|---|
| `ffmpeg_export_service_test.dart` | ASS burn-in, SRT fallback, cancellation cleanup, concurrency lock, path escaping |
| `whisper_transcription_service_test.dart` | Audio validation, chunked transcription, cancellation, concurrency, low-memory guard |
| `r2_language_pack_service_test.dart` | Manifest parsing, schema validation, path traversal rejection, resumable downloads, checksum mismatch, deletion |
| `caption_pipeline_test.dart` | Full pipeline orchestration, stage transitions, error propagation, cancellation |
| `export_screen_test.dart` | Progress state UI, complete state with/without output file, Done button presence |
| `storage_service_test.dart` | Disk usage calculation, cache clearing |
| `export_service_watermark_test.dart` | Logo overlay, 720p scaling enforcement |

---

## 📄 License

This project is licensed under the **GNU Affero General Public License v3.0 (AGPL-3.0)**.
