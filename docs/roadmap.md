# Captionary — Full Development Roadmap

> **Project:** Captionary — Serverless, Offline-First AI Caption & Creator Suite
> **Created:** 2026-09-06
> **Strategy:** UI-First with Mock Data → Backend Wiring → Integration Testing
> **Target Devices:** Android 4GB+ RAM (primary), <4GB (best-effort)
> **Theme:** Dark-only (deep matte black `#0A0A0A`)

---

## Table of Contents

1. [Current State Assessment](#1-current-state-assessment)
2. [Requirements Feasibility Analysis](#2-requirements-feasibility-analysis)
3. [Technology Stack & Dependencies](#3-technology-stack--dependencies)
4. [Architecture Overview](#4-architecture-overview)
5. [SECTION A — UI-First with Mock Data](#section-a--ui-first-with-mock-data)
   - [Phase A1 — Project Restructuring & State Management](#phase-a1--project-restructuring--state-management)
   - [Phase A2 — Mock Services & Seeded Data Layer](#phase-a2--mock-services--seeded-data-layer)
   - [Phase A3 — "Support" → "Donate" Rename & Donate UX Spread](#phase-a3--support--donate-rename--donate-ux-spread)
   - [Phase A4 — Custom Video Player UI](#phase-a4--custom-video-player-ui)
   - [Phase A5 — Language Pack Manager UI Enhancements](#phase-a5--language-pack-manager-ui-enhancements)
   - [Phase A6 — Subtitle Creator Studio UI](#phase-a6--subtitle-creator-studio-ui)
   - [Phase A7 — Export & Encoding Progress UI](#phase-a7--export--encoding-progress-ui)
   - [Phase A8 — Settings & Preferences UI](#phase-a8--settings--preferences-ui)
   - [Phase A9 — AdMob Placeholder UI](#phase-a9--admob-placeholder-ui)
   - [Phase A10 — Notification Permission & Donate Reminder UI](#phase-a10--notification-permission--donate-reminder-ui)
   - [Phase A11 — React Donation Portal Enhancements](#phase-a11--react-donation-portal-enhancements)
   - [Phase A12 — UI Testing & UX Verification](#phase-a12--ui-testing--ux-verification)
6. [SECTION B — Backend Wiring & Integration](#section-b--backend-wiring--integration)
   - [Phase B1 — media_kit Video Player Integration](#phase-b1--media_kit-video-player-integration)
   - [Phase B2 — FFmpeg Audio Extraction Pipeline](#phase-b2--ffmpeg-audio-extraction-pipeline)
   - [Phase B3 — Whisper CPP On-Device Transcription](#phase-b3--whisper-cpp-on-device-transcription)
   - [Phase B4 — Cloudflare R2 Language Pack Downloads](#phase-b4--cloudflare-r2-language-pack-downloads)
   - [Phase B5 — Subtitle Generation & Timeline Sync](#phase-b5--subtitle-generation--timeline-sync)
   - [Phase B6 — Caption Styling & Burn-In Engine](#phase-b6--caption-styling--burn-in-engine)
   - [Phase B7 — SRT/VTT Export Pipeline](#phase-b7--srtvtt-export-pipeline)
   - [Phase B8 — Google AdMob Live Integration](#phase-b8--google-admob-live-integration)
   - [Phase B9 — Donate Notification Scheduler](#phase-b9--donate-notification-scheduler)
   - [Phase B10 — URL Launcher & External Donate Portal](#phase-b10--url-launcher--external-donate-portal)
   - [Phase B11 — React Donation Portal — Payment Gateway Wiring](#phase-b11--react-donation-portal--payment-gateway-wiring)
   - [Phase B12 — RAM Optimization & Performance Profiling](#phase-b12--ram-optimization--performance-profiling)
   - [Phase B13 — Integration Testing & Final Verification](#phase-b13--integration-testing--final-verification)

---

## 1. Current State Assessment

### What Has Been Completed (from `migration_roadmap.md`)

| Component | Status | Details |
|-----------|--------|---------|
| Flutter project initialization | ✅ Done | `flutter_mobile/` with Dart SDK ^3.13.1 |
| Dark theme enforcement | ✅ Done | `ThemeMode.dark` in `main.dart`, full `ColorScheme` mapping |
| Design system tokens | ✅ Done | `app_colors.dart`, `app_typography.dart`, `app_spacing.dart`, `app_radius.dart`, `app_shadows.dart`, `app_gradients.dart`, `app_theme.dart` |
| Lexend font bundled locally | ✅ Done | Variable font `.ttf` in `assets/fonts/` |
| Material Symbols Icons | ✅ Done | `material_symbols_icons: ^4.2960.0` |
| GoRouter navigation | ✅ Done | 6 routes: `/`, `/languages`, `/studio`, `/player`, `/support`, `/export` |
| All 6 mobile screens (UI shells) | ✅ Done | `media_library_screen.dart`, `language_packs_screen.dart`, `studio_screen.dart`, `video_player_screen.dart`, `support_screen.dart`, `export_screen.dart` |
| All 7 reusable widgets | ✅ Done | `bottom_nav_bar.dart`, `app_header.dart`, `sub_screen_header.dart`, `gradient_pill_button.dart`, `ghost_pill_button.dart`, `status_chip.dart`, `support_pill.dart` |
| React frontend (Vite + React-TS) | ✅ Done | 6 pages, navbar, components, Tailwind CSS v4, all routes configured |
| React donation portal pages | ✅ Done | `SupportDonation.tsx`, `PaymentConfirmation.tsx`, `TransparencyLedger.tsx`, etc. |

### What Remains To Be Done

| Feature Area | Status | Priority |
|-------------|--------|----------|
| State management (Riverpod) | ❌ Not started | Critical |
| Mock data services layer | ❌ Not started | Critical |
| "Support" → "Donate" rename | ❌ Not started | High |
| Donate prompts spread across app | ❌ Not started | High |
| Custom video player (media_kit) | ❌ Not started | Critical |
| Whisper CPP transcription engine | ❌ Not started | Critical |
| FFmpeg audio extraction | ❌ Not started | Critical |
| Cloudflare R2 language pack downloads | ❌ Not started | Critical |
| Language auto-detection / recommendation | ❌ Not started | High |
| Subtitle timeline editor with styling | ❌ Not started | Critical |
| Caption burn-in (FFmpeg hardcoded subs) | ❌ Not started | Critical |
| SRT/VTT file export | ❌ Not started | High |
| Google AdMob adaptive banners | ❌ Not started | Medium |
| Periodic donate notifications | ❌ Not started | Medium |
| React payment gateway (Paynow) | ❌ Not started | High |
| RAM optimization for 4GB devices | ❌ Not started | Critical |
| Flutter tests | ❌ Not started | Critical |

---

## 2. Requirements Feasibility Analysis

### Requirement-by-Requirement Assessment

| # | Requirement | Feasible? | Notes |
|---|------------|-----------|-------|
| 1 | Dark theme only | ✅ Yes | Already implemented. `ThemeMode.dark` enforced. |
| 2 | Background captioning from other players | ⚠️ **Not feasible** | Android restricts system-wide audio capture. Samsung Live Caption uses a privileged system API not available to third-party apps. **Mitigation:** Build a custom in-app video player using `media_kit` that auto-captions. Users import/play videos inside Captionary. |
| 3 | Caption editor for creators (TikTok/IG/YT) | ✅ Yes | Subtitle styling presets, font/color/opacity controls, preview canvas overlay. Fully achievable with Flutter Canvas + ffmpeg burn-in. |
| 4 | Video processing & subtitle embedding | ✅ Yes | `ffmpeg_kit_flutter_new` for burn-in. SRT/VTT export via string generation. |
| 5 | Serverless, Cloudflare R2 only | ✅ Yes | R2 free tier: 10GB storage, unlimited egress, 10M reads/month. Language pack `.bin` files served via public R2 URL + `manifest.json`. |
| 6 | Language recommendation under serverless | ✅ Yes | Whisper `tiny` model (bundled, ~75MB) does a 30-second audio sample analysis. The detected language code maps to R2 `manifest.json` entry. No server needed — logic runs 100% on-device. |
| 7 | Free app with non-intrusive ads | ✅ Yes | AdMob adaptive banners ONLY on Language Pack Manager and Export/Encoding screens. No ads during video playback or subtitle editing. |
| 8 | Donate feature widespread + separate React portal | ✅ Yes | "Donate ☕" pill in header, periodic device notifications, bottom-sheet prompts, and `url_launcher` to open React web portal. |
| 9 | React web app strictly for donations | ✅ Yes | React portal with Paynow (EcoCash, InnBucks), international cards, crypto. No backend — Paynow handles payment processing. |
| 10 | "Support" → "Donate" rename | ✅ Yes | String replacement across all Flutter widgets and React components. |
| 11 | Free serverless development | ✅ Yes | Cloudflare R2 free tier (10GB storage, unlimited bandwidth), Cloudflare Pages free (unlimited sites), Paynow free merchant tier. |
| 12 | All languages, African priority | ✅ Yes | Whisper supports Shona, Zulu, Swahili, Yoruba, Afrikaans natively. Specialized "Whisper Large for 51 African Languages" model exists on HuggingFace for Tswana, Sepedi, Sotho, Tonga, etc. Models can be quantized to GGML format. |
| 13 | No company needed for payments | ✅ Yes | Paynow allows individual registration (no ZIMRA BP number needed for local payments). For international cards/crypto, use Ko-fi, Buy Me a Coffee, or direct crypto wallet addresses. |
| 14 | 4GB RAM benchmark | ✅ Yes | Whisper `tiny` model uses ~125MB RAM. `small` model uses ~500MB. Strategy: use quantized Q5_0 models, process audio in 30-sec chunks, release model after transcription. |
| 15 | RAM conservation | ✅ Yes | Implement model loading/unloading lifecycle, chunk-based processing, isolate-based FFmpeg execution, aggressive memory pool management. |
| 16 | Frequent donate notifications | ✅ Yes | `flutter_local_notifications` with `periodicallyShow` (daily or every 8 hours). Must respect Android 13+ POST_NOTIFICATIONS permission. |

### Cloudflare R2 Free Tier Budget

| Resource | Free Allowance | Our Estimated Usage | Headroom |
|----------|---------------|-------------------|----------|
| Storage | 10 GB/month | ~8 GB (15-20 language models, quantized) | 2 GB |
| Class A ops (writes) | 1M/month | ~100 (manifest updates) | 999,900 |
| Class B ops (reads) | 10M/month | ~50,000 (model downloads) | 9,950,000 |
| Egress bandwidth | **Unlimited ($0)** | Unlimited | ∞ |

---

## 3. Technology Stack & Dependencies

### Flutter Mobile (`pubspec.yaml` additions)

```yaml
dependencies:
  # --- EXISTING ---
  flutter: { sdk: flutter }
  cupertino_icons: ^1.0.8
  material_symbols_icons: ^4.2960.0
  go_router: ^18.0.1

  # --- NEW: State Management ---
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.6.1

  # --- NEW: Video Player ---
  media_kit: ^1.2.6
  media_kit_video: ^1.3.1
  media_kit_libs_android_video: ^1.3.8

  # --- NEW: Audio/Video Processing ---
  ffmpeg_kit_flutter_new: ^6.0.3    # Community fork (original retired 2025)

  # --- NEW: AI Speech Recognition ---
  whisper_cpp_flutter_plus: ^0.4.1

  # --- NEW: File & Storage ---
  path_provider: ^2.1.4
  file_picker: ^8.1.6
  permission_handler: ^11.3.1
  share_plus: ^10.1.4

  # --- NEW: Networking (R2 Downloads) ---
  dio: ^5.7.0                       # Chunked downloads with progress
  crypto: ^3.0.5                    # SHA256 checksum validation

  # --- NEW: Ads ---
  google_mobile_ads: ^5.3.0

  # --- NEW: Notifications ---
  flutter_local_notifications: ^19.5.0
  timezone: ^0.10.0
  flutter_timezone: ^2.0.0

  # --- NEW: External Links ---
  url_launcher: ^6.3.0

dev_dependencies:
  flutter_test: { sdk: flutter }
  flutter_lints: ^6.0.0
  riverpod_generator: ^2.6.3
  build_runner: ^2.4.13
  mockito: ^5.4.4
  integration_test: { sdk: flutter }
```

### React Donation Portal (`package.json` additions)

```json
{
  "dependencies": {
    "paynow": "^1.0.0",
    "react-icons": "^5.4.0",
    "framer-motion": "^11.0.0"
  }
}
```

### Cloudflare R2 Bucket Structure

```
captionary-models/
├── manifest.json                     # Language catalog + SHA256 checksums
├── models/
│   ├── ggml-tiny.en.bin              # Bundled in APK (English tiny, ~75MB)
│   ├── ggml-small-shona.q5_0.bin    # Shona optimized (~470MB)
│   ├── ggml-small-zulu.q5_0.bin     # isiZulu optimized (~460MB)
│   ├── ggml-small-sepedi.q5_0.bin   # Sepedi optimized (~460MB)
│   ├── ggml-small-tswana.q5_0.bin   # Setswana optimized (~450MB)
│   ├── ggml-small-tonga.q5_0.bin    # Tonga optimized (~450MB)
│   ├── ggml-medium-french.q5_0.bin  # French multilingual (~510MB)
│   ├── ggml-medium-swahili.q5_0.bin # Swahili (~480MB)
│   ├── ggml-medium-yoruba.q5_0.bin  # Yoruba (~470MB)
│   └── ...                           # Additional languages
└── checksums.sha256                   # Integrity verification file
```

### `manifest.json` Schema

```json
{
  "version": 2,
  "updated_at": "2026-09-06T00:00:00Z",
  "base_url": "https://pub-xxxx.r2.dev/models/",
  "default_language": "en",
  "languages": [
    {
      "code": "sn",
      "name": "Shona",
      "native_name": "chiShona",
      "region": "Africa",
      "model_file": "ggml-small-shona.q5_0.bin",
      "size_bytes": 492830720,
      "sha256": "abc123...",
      "accuracy": "high",
      "engine": "whisper-v3-african",
      "is_bundled": false,
      "priority": 1
    }
  ]
}
```

---

## 4. Architecture Overview

### Flutter App Architecture

```
lib/
├── main.dart                          # Entry point, Riverpod scope, MediaKit init
├── app.dart                           # MaterialApp.router, theme, GoRouter
│
├── core/
│   ├── constants/
│   │   ├── app_constants.dart         # R2 URLs, model sizes, timing constants
│   │   └── ad_unit_ids.dart           # AdMob unit IDs (test + production)
│   ├── utils/
│   │   ├── ram_monitor.dart           # Device RAM detection + tier classification
│   │   ├── file_utils.dart            # Path helpers, temp file management
│   │   └── duration_formatter.dart    # Time formatting utilities
│   └── errors/
│       └── app_exceptions.dart        # Custom exception classes
│
├── theme/                             # ✅ EXISTING — no changes needed
│   ├── app_colors.dart
│   ├── app_typography.dart
│   ├── app_spacing.dart
│   ├── app_radius.dart
│   ├── app_shadows.dart
│   ├── app_gradients.dart
│   └── app_theme.dart
│
├── data/
│   ├── models/                        # Data classes
│   │   ├── media_item.dart            # Video file metadata
│   │   ├── language_pack.dart         # Language model info
│   │   ├── subtitle_segment.dart      # Timestamped text segment
│   │   ├── caption_style.dart         # Font, color, animation preset
│   │   ├── export_job.dart            # Encoding job state
│   │   └── download_progress.dart     # R2 download state
│   │
│   ├── mock/                          # Mock data services (SECTION A)
│   │   ├── mock_media_service.dart
│   │   ├── mock_language_service.dart
│   │   ├── mock_transcription_service.dart
│   │   ├── mock_export_service.dart
│   │   └── seed_data.dart             # Hardcoded realistic test data
│   │
│   └── services/                      # Real backend services (SECTION B)
│       ├── media_service.dart         # File picker, media metadata
│       ├── language_pack_service.dart  # R2 manifest fetch, model download
│       ├── transcription_service.dart  # Whisper CPP engine wrapper
│       ├── ffmpeg_service.dart         # Audio extraction, caption burn-in
│       ├── export_service.dart         # Video encoding orchestrator
│       ├── notification_service.dart   # Donate reminder scheduler
│       └── ad_service.dart            # AdMob lifecycle manager
│
├── providers/                         # Riverpod providers
│   ├── media_provider.dart
│   ├── language_provider.dart
│   ├── transcription_provider.dart
│   ├── player_provider.dart
│   ├── subtitle_provider.dart
│   ├── export_provider.dart
│   ├── caption_style_provider.dart
│   └── notification_provider.dart
│
├── widgets/                           # ✅ EXISTING + NEW shared widgets
│   ├── bottom_nav_bar.dart            # ✅ EXISTING (rename Support→Donate)
│   ├── app_header.dart                # ✅ EXISTING (rename Support→Donate)
│   ├── sub_screen_header.dart         # ✅ EXISTING
│   ├── gradient_pill_button.dart      # ✅ EXISTING
│   ├── ghost_pill_button.dart         # ✅ EXISTING
│   ├── status_chip.dart               # ✅ EXISTING
│   ├── support_pill.dart              # ✅ EXISTING → rename to donate_pill.dart
│   ├── donate_bottom_sheet.dart       # NEW — periodic donation prompt
│   ├── donate_banner.dart             # NEW — inline donation banner
│   ├── ad_banner_widget.dart          # NEW — AdMob adaptive banner wrapper
│   ├── download_progress_bar.dart     # NEW — chunked download progress
│   ├── waveform_painter.dart          # NEW — audio waveform CustomPainter
│   ├── subtitle_overlay.dart          # NEW — caption text on video canvas
│   ├── circular_progress_painter.dart # NEW — gradient circular progress
│   └── caption_style_card.dart        # NEW — style preset preview card
│
├── screens/                           # ✅ EXISTING (enhanced in this roadmap)
│   ├── media_library_screen.dart
│   ├── language_packs_screen.dart
│   ├── studio_screen.dart
│   ├── video_player_screen.dart
│   ├── support_screen.dart            # → rename to donate_screen.dart
│   ├── export_screen.dart
│   └── settings_screen.dart           # NEW
│
└── test/
    ├── unit/
    │   ├── models/
    │   ├── services/
    │   └── providers/
    ├── widget/
    │   ├── widgets/
    │   └── screens/
    └── integration/
        └── app_flow_test.dart
```

### RAM Management Strategy

```
Device RAM Tiers:
┌─────────────────────────────────────────────────────────────────┐
│ Tier 1: ≥6GB RAM  → Use "small" models (~500MB), parallel ops  │
│ Tier 2: 4-6GB RAM → Use "tiny" models (~75MB), sequential ops  │
│ Tier 3: <4GB RAM  → Use "tiny" Q8 models, aggressive cleanup   │
└─────────────────────────────────────────────────────────────────┘

Processing Pipeline (Sequential to conserve RAM):
1. Load model → 2. Extract 30s audio chunk → 3. Transcribe chunk →
4. Release audio buffer → 5. Repeat 2-4 → 6. Unload model →
7. Load FFmpeg → 8. Burn subtitles → 9. Release FFmpeg
```

---

## SECTION A — UI-First with Mock Data

> **Goal:** Build the complete user experience with realistic fake data so the app feels fully functional. All screens, interactions, animations, and flows are testable without any real backend.
>
> **Rule:** NO real API calls, no real file processing, no real model loading. Everything uses mock services with `Future.delayed()` to simulate latency.

---

### Phase A1 — Project Restructuring & State Management

> **Goal:** Introduce Riverpod for state management, reorganize the project into the architecture defined above, and set up the mock/real service abstraction.

- [x] **A1.1** Add Riverpod dependencies to `pubspec.yaml`:
  ```yaml
  dependencies:
    flutter_riverpod: ^2.6.1
    riverpod_annotation: ^2.6.1
  dev_dependencies:
    riverpod_generator: ^2.6.3
    build_runner: ^2.4.13
  ```
  Run `flutter pub get`.

- [x] **A1.2** Create directory structure under `lib/`:
  ```
  lib/core/constants/
  lib/core/utils/
  lib/core/errors/
  lib/data/models/
  lib/data/mock/
  lib/data/services/
  lib/providers/
  ```

- [x] **A1.3** Create `lib/app.dart` — extract `CaptionaryApp` widget and `GoRouter` from `main.dart`. The `MaterialApp.router` should remain identical in behavior.

- [x] **A1.4** Update `lib/main.dart` to wrap `CaptionaryApp` in `ProviderScope`:
  ```dart
  void main() {
    WidgetsFlutterBinding.ensureInitialized();
    runApp(const ProviderScope(child: CaptionaryApp()));
  }
  ```

- [x] **A1.5** Create data model classes:
  - `lib/data/models/media_item.dart`:
    ```dart
    class MediaItem {
      final String id;
      final String fileName;
      final String filePath;
      final int fileSizeBytes;
      final String resolution;
      final Duration duration;
      final String? thumbnailPath;
      final MediaStatus status;
      final String? detectedLanguage;
      final DateTime importedAt;
    }

    enum MediaStatus { newItem, pendingAudioSync, readyToEdit, transcribed }
    ```

  - `lib/data/models/language_pack.dart`:
    ```dart
    class LanguagePack {
      final String code;
      final String name;
      final String nativeName;
      final String region;
      final String modelFile;
      final int sizeBytes;
      final String sha256;
      final String accuracy;
      final String engine;
      final bool isBundled;
      final int priority;
      final LanguagePackStatus status;
      final double downloadProgress; // 0.0 to 1.0
      final double? downloadSpeedMbps;
    }

    enum LanguagePackStatus { notDownloaded, downloading, installed, bundled, error }
    ```

  - `lib/data/models/subtitle_segment.dart`:
    ```dart
    class SubtitleSegment {
      final int index;
      final Duration startTime;
      final Duration endTime;
      final String text;
      final String? activeWord;
      final bool isSelected;
    }
    ```

  - `lib/data/models/caption_style.dart`:
    ```dart
    class CaptionStyle {
      final String name;
      final String previewText;
      final double fontSize;
      final double boxOpacity;
      final Color accentColor;
      final String animationType; // bounce, highlight, karaoke, minimal
      final String targetPlatform; // tiktok, instagram, youtube, generic
    }
    ```

  - `lib/data/models/export_job.dart`:
    ```dart
    class ExportJob {
      final String id;
      final String sourceFileName;
      final String outputFileName;
      final ExportState state;
      final double progress; // 0.0 to 1.0
      final String resolution;
      final String codec;
      final int bitrateMbps;
      final Duration estimatedTimeRemaining;
      final int outputSizeBytes;
      final bool hardwareAcceleration;
    }

    enum ExportState { idle, encoding, complete, error }
    ```

  - `lib/data/models/download_progress.dart`:
    ```dart
    class DownloadProgress {
      final String languageCode;
      final int downloadedBytes;
      final int totalBytes;
      final double speedBytesPerSec;
      final Duration estimatedTimeRemaining;
      final DownloadState state;
    }

    enum DownloadState { idle, downloading, verifying, complete, error }
    ```

- [x] **A1.6** Create abstract service interfaces in `lib/data/services/`:
  - `media_service.dart`:
    ```dart
    abstract class MediaService {
      Future<List<MediaItem>> getRecentMedia();
      Future<MediaItem?> importVideo();
      Future<void> deleteMedia(String id);
      Future<MediaItem> getMediaById(String id);
    }
    ```
  - `language_pack_service.dart`:
    ```dart
    abstract class LanguagePackService {
      Future<List<LanguagePack>> getAvailableLanguages();
      Future<LanguagePack> getActiveLanguage();
      Stream<DownloadProgress> downloadLanguagePack(String code);
      Future<void> deleteLanguagePack(String code);
      Future<String> detectLanguage(String audioPath);
      double getStorageUsedGB();
      double getStorageTotalGB();
    }
    ```
  - `transcription_service.dart`:
    ```dart
    abstract class TranscriptionService {
      Future<List<SubtitleSegment>> transcribeAudio({
        required String audioPath,
        required String languageCode,
        required String modelPath,
      });
      Stream<SubtitleSegment> transcribeAudioStream({
        required String audioPath,
        required String languageCode,
        required String modelPath,
      });
    }
    ```
  - `export_service.dart`:
    ```dart
    abstract class ExportService {
      Stream<ExportJob> burnCaptions({
        required String videoPath,
        required List<SubtitleSegment> segments,
        required CaptionStyle style,
        required String outputPath,
      });
      Future<String> exportSRT(List<SubtitleSegment> segments);
      Future<String> exportVTT(List<SubtitleSegment> segments);
    }
    ```

- [x] **A1.7** Create `lib/core/constants/app_constants.dart`:
  ```dart
  class AppConstants {
    static const String r2BaseUrl = 'https://pub-xxxx.r2.dev';
    static const String manifestUrl = '$r2BaseUrl/manifest.json';
    static const String donateWebUrl = 'https://captionary.pages.dev/donate';
    static const int maxModelSizeBytes = 1024 * 1024 * 1024; // 1GB
    static const int audioSampleDurationSec = 30;
    static const double storageCapacityGB = 10.0;
    static const Duration donateReminderInterval = Duration(hours: 8);
  }
  ```

- [x] **A1.8** Run `flutter pub get` and verify project compiles with `flutter analyze`.

- [x] **A1.9** Run `flutter test` to verify existing tests still pass.

**Verification:**
- `flutter analyze` reports no errors.
- `flutter test` passes.
- App launches and existing UI screens are unaffected.

---

### Phase A2 — Mock Services & Seeded Data Layer

> **Goal:** Create mock implementations of all services with realistic hardcoded data that exercises every UI state.

- [x] **A2.1** Create `lib/data/mock/seed_data.dart` — centralized realistic test data with all the hardcoded media items, language packs, subtitle segments, caption styles, and export jobs that match the data previously hardcoded in the HTML prototypes and current screen files. Include:
  - 4 media items (Podcast_Ep14_Raw.mp4, Victoria_Falls_Trip.mp4, AI_Keynote_2025.mov, Afrobeats_Snippet.mp4) with realistic sizes, resolutions, durations, statuses
  - 8+ language packs (Shona installed, isiZulu downloading at 68%, Sepedi/French/Setswana/Tonga/Swahili not downloaded, English bundled)
  - 4 sample subtitle segments in Shona with timestamps
  - 4 caption style presets (TikTok Bold, IG Highlight, Classic Movie, Neon Flow)
  - Sample encoding job at 45% progress and completed variant

- [x] **A2.2** Create `lib/data/mock/mock_media_service.dart`:
  - Implements `MediaService` interface
  - Returns `SeedData.recentMedia` with `Future.delayed(400ms)` simulated latency
  - `importVideo()` returns first media item after 1 second delay
  - `deleteMedia()` completes after 300ms delay

- [x] **A2.3** Create `lib/data/mock/mock_language_service.dart`:
  - Implements `LanguagePackService` interface
  - Returns `SeedData.languagePacks` with 500ms delay
  - `downloadLanguagePack()` yields progress stream 0-100% in 5% increments every 200ms
  - `detectLanguage()` returns 'sn' (Shona) after 2 second delay

- [x] **A2.4** Create `lib/data/mock/mock_transcription_service.dart`:
  - Implements `TranscriptionService` interface
  - Returns `SeedData.sampleSubtitles` after 3 second delay
  - Stream variant yields one segment per second

- [x] **A2.5** Create `lib/data/mock/mock_export_service.dart`:
  - Implements `ExportService` interface
  - `burnCaptions()` streams progress 0-100% in 2% increments every 300ms
  - `exportSRT()` generates valid SRT format string from segments
  - `exportVTT()` generates valid VTT format string from segments

- [x] **A2.6** Create Riverpod providers in `lib/providers/`:
  - `media_provider.dart` — wraps `MockMediaService`, exposes `AsyncValue<List<MediaItem>>`
  - `language_provider.dart` — wraps `MockLanguageService`, exposes language list + active language + download streams
  - `transcription_provider.dart` — wraps `MockTranscriptionService`
  - `player_provider.dart` — manages playback state (position, playing, volume, speed)
  - `subtitle_provider.dart` — manages subtitle segments list, selected segment, edit state
  - `export_provider.dart` — wraps `MockExportService`, exposes encoding progress stream
  - `caption_style_provider.dart` — manages selected style preset, font size, opacity, accent color

- [x] **A2.7** Wire all 6 existing screens to consume data from Riverpod providers instead of inline hardcoded data. Each screen should use `ConsumerWidget` or `ConsumerStatefulWidget` and call `ref.watch()` on the appropriate provider.

- [x] **A2.8** Verify all screens still render correctly with mock data.

**Verification:**
- `flutter analyze` clean.
- `flutter test` passes.
- App runs with all screens showing mock data identical to current hardcoded data.

---

### Phase A3 — "Support" → "Donate" Rename & Donate UX Spread

> **Goal:** Rename all instances of "Support" to "Donate" across the Flutter app and React web portal. Add donate prompts in strategic locations throughout the app.

- [x] **A3.1** Rename `lib/widgets/support_pill.dart` → `lib/widgets/donate_pill.dart`:
  - Class name: `SupportPill` → `DonatePill`
  - Icon: Keep `local_cafe` (coffee icon)
  - Label: `"Support"` → `"Donate ☕"`
  - Glow color: Keep purple glow

- [x] **A3.2** Rename `lib/screens/support_screen.dart` → `lib/screens/donate_screen.dart`:
  - Class name: `SupportScreen` → `DonateScreen`
  - App bar subtitle: `"Support & Community"` → `"Donate & Community"`
  - Hero headline: `"Support Independent AI Speech"` → `"Donate to Independent AI Speech"`
  - Section: `"Web Contribution Gateway"` → `"Web Donation Gateway"`
  - Button: `"Open Web Donation Portal"` (keep as-is, already says "Donation")
  - All body copy: Replace "support" with "donate" where contextually appropriate

- [x] **A3.3** Update `lib/widgets/bottom_nav_bar.dart`:
  - Tab 4 label: `"Support"` → `"Donate"`
  - Icon: `favorite` → `local_cafe` (coffee icon, more donation-themed)

- [x] **A3.4** Update `lib/widgets/app_header.dart`:
  - Right-side pill: Replace `SupportPill` reference with `DonatePill`

- [x] **A3.5** Update `lib/main.dart` (or `app.dart`):
  - Route `/support` → `/donate`
  - Import `donate_screen.dart` instead of `support_screen.dart`

- [x] **A3.6** Create `lib/widgets/donate_bottom_sheet.dart` — a modal bottom sheet with:
  - Drag handle pill at top
  - Coffee cup icon with gradient ring glow
  - "Fuel Our Mission ☕" headline
  - "Your donation keeps Captionary free and ad-light for everyone." body text
  - "Donate Now" gradient pill button → opens external donate URL
  - "Maybe Later" ghost pill button → dismisses
  - Appears after every 3rd video import or every 5th transcription (tracked via counter)

- [x] **A3.7** Create `lib/widgets/donate_banner.dart` — a compact inline banner card:
  - Coffee icon + "Help keep Captionary free" text + "Donate" mini gradient pill
  - Used in: Export complete screen, Settings screen, Language Pack Manager (above AdMob)
  - 1px border with `secondaryContainer` color, subtle purple gradient left edge

- [x] **A3.8** Add donate prompts to screens:
  - **Media Library Screen:** Add `DonateBanner` below the Quick Stats row
  - **Export Screen (State B: Complete):** Keep existing community support banner, ensure it says "Donate" not "Support"
  - **Language Pack Manager:** Add `DonateBanner` above the AdMob placeholder

- [x] **A3.9** Update React web portal:
  - `DesktopNavbar.tsx`: "Support Us" button → "Donate ☕"
  - `SupportDonation.tsx`: Update all "Support" text to "Donate"
  - All pages: Update any "support" references in navigation links
  - Route: `/support` → `/donate` (update `App.tsx` router)

- [x] **A3.10** Write widget tests:
  - `test/widget/widgets/donate_pill_test.dart` — renders correctly, shows "Donate ☕"
  - `test/widget/widgets/donate_bottom_sheet_test.dart` — opens, buttons work
  - `test/widget/widgets/donate_banner_test.dart` — renders correctly

**Verification:**
- No remaining instances of "Support" in user-facing text (grep `lib/` and `src/` for "Support" — only code identifiers should remain).
- All donate touchpoints visible on at least 4 of 6 screens.
- `flutter test` passes.

---

### Phase A4 — Custom Video Player UI

> **Goal:** Redesign the video player screen to be a fully functional custom player UI with mock playback controls, waveform scrubber, transport bar, caption overlay, and auto-detect language modal.

- [ ] **A4.1** Create `lib/widgets/waveform_painter.dart` — CustomPainter that draws:
  - Array of vertical bars with varying heights (randomized from seed for mock)
  - Color gradient from `primaryContainer` through `primary` to `secondary` based on position
  - Dimmed bars after the playhead position
  - Accepts `progress` (0.0 to 1.0) to split colored vs dimmed regions

- [ ] **A4.2** Create `lib/widgets/subtitle_overlay.dart` — widget that renders:
  - Semi-transparent black box background with configurable opacity
  - Subtitle text with word-by-word coloring (active word highlighted in accent color)
  - Smooth fade-in/fade-out transitions between subtitle segments
  - Accepts `SubtitleSegment`, `CaptionStyle`, and `activeWordIndex`

- [ ] **A4.3** Refactor `lib/screens/video_player_screen.dart` to use Riverpod providers:
  - `ConsumerStatefulWidget` with `ref.watch(playerProvider)` for playback state
  - `ref.watch(subtitleProvider)` for current caption text
  - `ref.watch(languageProvider)` for detected language modal
  - Mock video canvas: Gradient placeholder container (16:9 aspect ratio) with overlay badges
  - Functional transport controls (play/pause toggles icon, scrubber updates position, skip ±10s)
  - Waveform scrubber using `WaveformPainter`
  - Subtitle overlay using `SubtitleOverlay`
  - All controls update mock state via Riverpod notifiers

- [ ] **A4.4** Implement Auto-Detect Language Modal as a `showModalBottomSheet`:
  - Uses mock data: "Shona (chiShona)" detected with "98% Match"
  - Pulsing `graphic_eq` icon animation (use `AnimationController`)
  - "Use Shona Pack" button triggers navigation to language pack screen if not installed
  - "Select Different Pack" opens language picker

- [ ] **A4.5** Add smooth animations:
  - Play/Pause icon transition: `AnimatedSwitcher` between `play_arrow` and `pause`
  - Scrubber thumb: Glowing dot with `BoxShadow` animation on drag
  - Caption overlay: `AnimatedOpacity` fade between segments
  - Modal entrance: `showModalBottomSheet` with spring curve

- [ ] **A4.6** Write widget tests:
  - `test/widget/screens/video_player_screen_test.dart`
  - Test: Transport controls toggle play/pause state
  - Test: Scrubber position updates on drag
  - Test: Auto-detect modal renders with language data
  - Test: Subtitle overlay shows current segment text

**Verification:**
- Video player screen fully interactive with mock data
- All transport controls respond to taps
- Scrubber is draggable and updates position
- Caption text changes with scrubber position
- Language detection modal opens and displays results

---

### Phase A5 — Language Pack Manager UI Enhancements

> **Goal:** Make the language pack manager fully interactive with mock download flows, search, storage tracking, and expanded African language support.

- [x] **A5.1** Create `lib/widgets/download_progress_bar.dart` — reusable widget:
  - Multi-segment horizontal bar (installed=green, downloading=yellow animated shimmer, available=gray)
  - Accepts `List<LanguagePack>` to calculate segment widths proportionally
  - Yellow downloading segment has `AnimatedContainer` shimmer effect

- [x] **A5.2** Refactor `lib/screens/language_packs_screen.dart`:
  - Convert to `ConsumerStatefulWidget`
  - Wire to `ref.watch(languageProvider)` for language list
  - Search input filters the displayed language cards in real-time (local filter, no API)
  - Storage summary card reads from `languageProvider` computed values
  - Each language card shows correct status chip based on `LanguagePackStatus`

- [x] **A5.3** Implement mock download flow:
  - Tap "Download (460MB)" button on a language card
  - Card transitions: `notDownloaded` → `downloading` (shows progress bar, speed, ETA) → `installed`
  - Progress bar animates from 0% to 100% using `Stream<DownloadProgress>` from mock service
  - Speed shows as "4.8 MB/s", ETA counts down
  - On completion: card shows green "Ready" chip with `check_circle` icon

- [x] **A5.4** Implement mock delete flow:
  - Long-press installed language card → confirmation dialog
  - On confirm: card transitions back to `notDownloaded` state
  - Storage summary updates (recalculates used/total)

- [x] **A5.5** Add African language cards for: Setswana, Tonga, Swahili, Yoruba, Afrikaans, Ndebele, Sotho
  - Each with realistic size, native name, region, accuracy, engine labels
  - All default to `notDownloaded` status in seed data

- [x] **A5.6** Write widget tests:
  - `test/widget/screens/language_packs_screen_test.dart`
  - Test: Search filters languages correctly
  - Test: Download button triggers progress stream
  - Test: Storage bar reflects installed models
  - Test: Delete flow removes language card from installed list

**Verification:**
- 10+ language cards visible (scrollable list)
- Search filters in real-time
- Mock download completes with animated progress
- Storage bar updates after install/delete

---

### Phase A6 — Subtitle Creator Studio UI

> **Goal:** Make the studio screen fully interactive with mock subtitle editing, style presets, timeline scrubbing, and preview canvas.

- [x] **A6.1** Create `lib/widgets/caption_style_card.dart` — preset preview card:
  - Preview text styled with the preset's font, color, and animation type
  - Selected state: gradient border glow + check badge
  - Tap to select: updates `captionStyleProvider`

- [x] **A6.2** Refactor `lib/screens/studio_screen.dart`:
  - Convert to `ConsumerStatefulWidget`
  - Wire to `subtitleProvider` for timeline segments
  - Wire to `captionStyleProvider` for active style preset
  - Video preview canvas shows subtitle overlay with selected style
  - Timeline blocks are tappable (selects segment for editing)
  - Font size slider (14-48) updates preview in real-time
  - Box opacity slider (0-100) updates preview in real-time
  - Color picker chips update accent color in real-time

- [x] **A6.3** Implement subtitle segment editing:
  - Tap a timeline block → block gets gradient border glow (selected state)
  - Selected block shows editable `TextField` with current text
  - Trim handles (left/right drag icons) on selected block (mock — adjust start/end time by ±500ms per drag)
  - Edit text and press done → updates `subtitleProvider`

- [x] **A6.4** Implement style presets carousel:
  - Horizontal `ListView` of 4 `CaptionStyleCard` widgets
  - Selecting a preset updates the video preview canvas in real-time
  - Preview text: "TikTok Bold" → bouncing green text, "IG Highlight" → highlighted pill, etc.

- [x] **A6.5** Implement action buttons:
  - "Export .SRT" → shows `SnackBar` with "SRT file saved to Downloads" (mock)
  - "Re-align AI" → shows 2-second loading spinner then "Re-aligned 4 segments" snackbar
  - "Burn Captions to Video" → navigates to Export screen with `ExportJob` in progress state

- [x] **A6.6** Write widget tests:
  - `test/widget/screens/studio_screen_test.dart`
  - Test: Style presets update preview text styling
  - Test: Sliders update font size and opacity values
  - Test: Timeline block tap selects segment
  - Test: Action buttons trigger correct navigation/snackbar

**Verification:**
- Studio screen is fully interactive
- Style changes reflect in real-time on video preview canvas
- Timeline blocks are selectable and editable
- All action buttons work with mock feedback

---

### Phase A7 — Export & Encoding Progress UI

> **Goal:** Make the export screen fully animated with mock encoding progress simulation and export complete celebration.

- [x] **A7.1** Create `lib/widgets/circular_progress_painter.dart` — CustomPainter:
  - Background circle track (`surfaceContainer` color)
  - Progress arc with 3-stop gradient (primary → `#7B1FA2` → secondary)
  - Accepts `progress` (0.0 to 1.0) for arc sweep angle
  - Accepts `size` for diameter (256px default)
  - Uses `SweepGradient` clipped by arc

- [x] **A7.2** Refactor `lib/screens/export_screen.dart`:
  - Convert to `ConsumerStatefulWidget`
  - Wire to `ref.watch(exportProvider)` for `ExportJob` state
  - State A (Encoding): Shows animated circular progress with gradient arc, bouncing logo, percentage counter, telemetry card
  - State B (Complete): Shows success card with green glow burst, file details, action buttons
  - Toggle between State A and State B uses `TabBar` or custom switcher

- [x] **A7.3** Implement mock encoding simulation:
  - On entering Export screen from Studio's "Burn Captions" button:
  - Progress animates from 0% to 100% over ~15 seconds (mock stream)
  - Percentage text updates with `AnimatedSwitcher` (number tick animation)
  - "Est. Time Remaining" counts down from 32s
  - Logo in center uses `AnimationController` with `Curves.elasticInOut` for bounce
  - On reaching 100%: auto-switch to State B with confetti-like particle animation

- [x] **A7.4** Implement State B actions:
  - "Preview" button → shows `SnackBar` "Opening preview..." (mock)
  - "Share Video" button → shows share dialog (mock `SharePlus` intent)
  - "Re-encode with other settings" link → navigates back to Studio
  - "Buy a Coffee ☕" button → triggers `DonateBanner` expand or `url_launcher` (mock)

- [x] **A7.5** Write widget tests:
  - `test/widget/screens/export_screen_test.dart`
  - Test: Circular progress renders at 45%
  - Test: State switcher toggles between encoding and complete views
  - Test: Percentage text matches export job progress

**Verification:**
- Encoding animation runs smoothly from 0% to 100%
- Auto-transition to complete state
- All action buttons respond
- Circular gradient arc renders correctly

---

### Phase A8 — Settings & Preferences UI

> **Goal:** Add a simple settings screen for user preferences (RAM tier selection, notification preferences, general app info).

- [x] **A8.1** Create `lib/screens/settings_screen.dart`:
  - Uses `SubScreenHeader` (back arrow + "Settings" title)
  - No bottom nav bar (sub-screen)
  - Sections:
    1. **Performance** — RAM tier selector (dropdown: "Auto", "High (6GB+)", "Standard (4GB)", "Low (<4GB)")
    2. **Notifications** — "Donate reminders" toggle switch (with frequency: "Every 8 hours" / "Daily" / "Never")
    3. **Storage** — Shows model cache size, "Clear cache" button
    4. **About** — App version, "Open Source (AGPL-3.0)", GitHub link, "Rate on Play Store"
    5. **Donate** — `DonateBanner` widget at bottom

- [x] **A8.2** Add settings route to `GoRouter`:
  ```dart
  GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen())
  ```

- [x] **A8.3** Add settings icon button to `AppHeader` (gear icon) or accessible from a profile menu.

- [x] **A8.4** Write widget tests:
  - `test/widget/screens/settings_screen_test.dart`
  - Test: RAM tier dropdown shows options
  - Test: Notification toggle switches state
  - Test: About section shows version

**Verification:**
- Settings screen accessible from header
- All toggles and dropdowns functional (state changes)
- DonateBanner visible at bottom

---

### Phase A9 — AdMob Placeholder UI

> **Goal:** Design and place non-intrusive AdMob placeholder widgets on ONLY the permitted screens.

- [x] **A9.1** Create `lib/widgets/ad_banner_widget.dart`:
  - Accepts `adUnitId` and `adSize` (adaptive banner width)
  - In mock mode: Shows a styled placeholder card matching the design system:
    - `surfaceContainerHigh` background
    - `ad_units` icon + "Ad Space" label + "Google AdMob Adaptive Banner" subtext
    - Bordered with `surfaceBorder` color
    - Exact same height as a real adaptive banner would be
  - In production mode: Renders actual `AdWidget` (wired in Section B)

- [x] **A9.2** Place `AdBannerWidget` on permitted screens ONLY:
  - **Language Pack Manager** (`language_packs_screen.dart`): Below the language cards list, above the bottom nav padding
  - **Export Screen — State A: Encoding** (`export_screen.dart`): Below the telemetry card, above bottom padding
  - **NEVER on:** Video Player, Studio, Media Library, Donate screen

- [x] **A9.3** Ensure ad placeholders do NOT overlap or interfere with:
  - Video playback canvas
  - Subtitle editing canvas
  - Transport controls
  - Any interactive buttons or sliders

- [x] **A9.4** Write widget tests:
  - `test/widget/widgets/ad_banner_widget_test.dart`
  - Test: Renders placeholder in mock mode
  - Test: Shows correct "Ad Space" text and icon
  - Test: Has correct height

**Verification:**
- Ad placeholders visible ONLY on Language Pack Manager and Export (encoding) screens
- No ad placeholders on other screens
- Placeholders match design system styling

---

### Phase A10 — Notification Permission & Donate Reminder UI

> **Goal:** Build the UI flow for requesting notification permission and showing a preview of what donate reminder notifications will look like.

- [x] **A10.1** Create notification permission request flow:
  - On first app launch: Show a one-time bottom sheet explaining notifications
  - "Captionary would like to send you occasional reminders to support the project"
  - "Allow Notifications" gradient pill + "Not Now" ghost pill
  - If "Allow": Store preference, schedule reminders (mock — just saves flag)
  - If "Not Now": Store preference, don't ask again for 7 days

- [x] **A10.2** Create notification preview in Settings:
  - Under "Notifications" section, show a mock notification card:
  - App icon + "Captionary" + "☕ Your code captioning matters! Fuel Captionary with a small donation."
  - Time stamp: "8h ago"
  - Styled to look like an Android notification

- [x] **A10.3** Write widget tests:
  - Test: Permission flow shows on first launch
  - Test: "Allow" saves notification preference
  - Test: "Not Now" dismisses and stores cooldown

**Verification:**
- Notification permission flow triggers on first launch
- Settings shows notification preview
- Preferences persist correctly (mock)

---

### Phase A11 — React Donation Portal Enhancements

> **Goal:** Enhance the React donation portal to better integrate with the "Donate" branding and prepare for Paynow payment gateway wiring.

- [x] **A11.1** Update all React components:
  - Replace all "Support" text with "Donate" in visible UI
  - Update page titles and meta descriptions
  - Update navbar button text

- [x] **A11.2** Create payment method selector component with mock data:
  - "EcoCash" card with green accent
  - "InnBucks" card with blue accent
  - "International Card (Visa/Mastercard)" card (note: requires merchant verification)
  - "Cryptocurrency" card with Bitcoin/ETH icons
  - "Ko-fi / Buy Me a Coffee" card (alternative for international)
  - Each card is selectable, shows mock processing state on click

- [x] **A11.3** Create donation amount selector:
  - Quick amounts: $1, $3, $5, $10, $25
  - Custom amount input
  - Currency selector: USD, ZWL, ZAR

- [x] **A11.4** Create mock payment flow:
  - Select method → Select amount → "Processing..." state (2 second delay) → "Thank You!" confirmation
  - Confirmation page shows receipt-like card with donation details

- [x] **A11.5** Verify React app builds and runs:
  ```bash
  cd react_frontend && npm run build && npm run preview
  ```

**Verification:**
- React donation portal fully functional with mock payment flow
- All "Support" text replaced with "Donate"
- Payment method selector and amount picker work
- Build produces no TypeScript errors

---

### Phase A12 — UI Testing & UX Verification

> **Goal:** Comprehensive testing of all UI screens, interactions, and flows.

- [x] **A12.1** Write unit tests for all data models:
  - `test/unit/models/media_item_test.dart`
  - `test/unit/models/language_pack_test.dart`
  - `test/unit/models/subtitle_segment_test.dart`
  - `test/unit/models/caption_style_test.dart`
  - `test/unit/models/export_job_test.dart`
  - Test equality, copyWith, serialization

- [x] **A12.2** Write unit tests for mock services:
  - `test/unit/services/mock_media_service_test.dart`
  - `test/unit/services/mock_language_service_test.dart`
  - `test/unit/services/mock_transcription_service_test.dart`
  - `test/unit/services/mock_export_service_test.dart`
  - Test return values, stream emissions, edge cases

- [x] **A12.3** Write widget tests for all screens:
  - Each screen gets a test file verifying:
    - Renders without overflow errors
    - Key widgets are findable by text/key
    - Interactive elements respond to taps
    - Navigation triggers work
    - Loading states display correctly
    - Error states display correctly (show "No data" or retry)

- [x] **A12.4** Run full test suite:
  ```bash
  flutter test --coverage
  ```
  Target: 80%+ code coverage on models, services, and providers.

- [x] **A12.5** Run `flutter analyze` — zero warnings.

- [x] **A12.6** Build debug APK and test on Android emulator:
  ```bash
  flutter build apk --debug
  ```
  - Test all navigation flows
  - Test all interactive elements
  - Test scrolling on long screens
  - Test landscape orientation (should remain portrait-locked or adapt gracefully)
  - Test on different screen sizes (phone vs tablet)

- [x] **A12.7** Visual comparison:
  - Screenshot each screen in emulator
  - Compare with original HTML prototypes
  - Document any visual discrepancies for fix

**Verification:**
- `flutter test --coverage` passes with 80%+ coverage
- `flutter analyze` reports zero warnings
- Debug APK installs and runs on emulator
- All 7+ screens (6 original + settings) render without overflow
- All navigation routes work
- All interactive mock flows complete successfully

---

## SECTION B — Backend Wiring & Integration

> **Goal:** Replace all mock services with real implementations. Wire actual video playback, audio processing, AI transcription, network downloads, and payment processing.
>
> **Rule:** Mock services remain available for testing. Use dependency injection via Riverpod to swap mock ↔ real at the provider level.

---

### Phase B1 — media_kit Video Player Integration

> **Goal:** Replace the mock video canvas with a real `media_kit` video player.

- [ ] **B1.1** Add `media_kit` dependencies to `pubspec.yaml`:
  ```yaml
  media_kit: ^1.2.6
  media_kit_video: ^1.3.1
  media_kit_libs_android_video: ^1.3.8
  ```

- [ ] **B1.2** Initialize `MediaKit` in `main.dart`:
  ```dart
  void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    MediaKit.ensureInitialized();
    runApp(const ProviderScope(child: CaptionaryApp()));
  }
  ```

- [ ] **B1.3** Create `lib/data/services/media_player_service.dart`:
  - Wraps `Player` instance with lifecycle management
  - `open(String filePath)` — opens local video file
  - `play()`, `pause()`, `seek(Duration)`, `setSpeed(double)`, `setVolume(double)`
  - Exposes streams: `positionStream`, `durationStream`, `playingStream`, `bufferingStream`
  - Implements `dispose()` for cleanup

- [ ] **B1.4** Create `lib/providers/player_provider.dart` (real implementation):
  - Manages `Player` and `VideoController` instances
  - Exposes `Video(controller: controller)` widget to the screen
  - Handles hardware acceleration: `await nativePlayer.setProperty('hwdec', 'mediacodec')`

- [ ] **B1.5** Update `lib/screens/video_player_screen.dart`:
  - Replace gradient placeholder with `Video(controller: ref.watch(playerProvider).controller)`
  - Wire transport controls to real `player.play()`, `player.pause()`, `player.seek()`
  - Wire scrubber to real position stream
  - Overlay subtitle text on top of `Video` widget using `Stack`

- [ ] **B1.6** Implement file import flow:
  - `file_picker` integration: `FilePicker.platform.pickFiles(type: FileType.video)`
  - On file selected: Create `MediaItem` from file metadata, open in player

- [ ] **B1.7** Write integration test:
  - Test: Player opens a local video file
  - Test: Play/Pause toggles correctly
  - Test: Seek updates position

**Verification:**
- Real video files play in the custom player
- Transport controls work with real playback
- Subtitle overlay renders on top of video

---

### Phase B2 — FFmpeg Audio Extraction Pipeline

> **Goal:** Extract audio from video files for Whisper transcription, using ffmpeg_kit_flutter_new.

- [ ] **B2.1** Add `ffmpeg_kit_flutter_new` dependency:
  ```yaml
  ffmpeg_kit_flutter_new: ^6.0.3  # Use _full or _gpl variant for libass subtitle support
  ```

- [ ] **B2.2** Create `lib/data/services/ffmpeg_service.dart`:
  - `extractAudioSample()` — extracts audio from video file as 16kHz mono WAV (Whisper input format)
    - FFmpeg command: `-i "$videoPath" -t $durationSeconds -ar 16000 -ac 1 -f wav "$outputPath"`
  - `burnSubtitles()` — burns subtitles into video using ASS/SRT filter (implemented in Phase B6)

- [ ] **B2.3** Add Android permissions for file access:
  - `AndroidManifest.xml`: `READ_EXTERNAL_STORAGE`, `WRITE_EXTERNAL_STORAGE` (legacy), SAF support
  - `permission_handler` setup for runtime permission requests

- [ ] **B2.4** Wire audio extraction into the transcription flow:
  - On "Auto-Detect Language" trigger → extract 30s audio → pass to Whisper

- [ ] **B2.5** Write unit tests:
  - Test: Audio extraction command string is correctly formed
  - Test: Output path is correctly generated
  - Test: Error handling on FFmpeg failure

**Verification:**
- Audio extraction produces valid WAV file from test video
- 16kHz mono format confirmed
- Proper error handling on invalid input

---

### Phase B3 — Whisper CPP On-Device Transcription

> **Goal:** Integrate whisper_cpp_flutter_plus for offline speech-to-text with language detection.

- [ ] **B3.1** Add Whisper dependency:
  ```yaml
  whisper_cpp_flutter_plus: ^0.4.1
  ```

- [ ] **B3.2** Bundle `ggml-tiny.en.bin` model in APK assets:
  - Download from Whisper.cpp releases or HuggingFace
  - Place in `flutter_mobile/assets/models/ggml-tiny.en.bin`
  - Register in `pubspec.yaml`:
    ```yaml
    assets:
      - assets/models/
    ```
  - **Note:** This adds ~75MB to APK size. Consider using Android App Bundle (AAB) with asset packs for Play Store.

- [ ] **B3.3** Create `lib/data/services/transcription_service.dart` (real implementation):
  - `_loadModel(modelPath)` — loads Whisper engine from model file
  - `_unloadModel()` — disposes engine and releases RAM
  - `transcribeAudio()` — loads model, transcribes, unloads model (always release RAM in `finally` block)
  - `transcribeAudioStream()` — chunk-based streaming transcription for real-time updates
  - `_parseTranscription()` — converts Whisper output to `SubtitleSegment` list with timestamps

- [ ] **B3.4** Implement language detection:
  - Extract 30s audio sample (Phase B2)
  - Run Whisper `detect_language()` on audio
  - Return detected language code + confidence score
  - Map to available language packs from manifest

- [ ] **B3.5** Implement RAM-aware model selection:
  - Detect device RAM using platform channel or SysInfo
  - ≥6GB RAM → recommend `small` models (~500MB)
  - 4-6GB RAM → recommend `tiny` models (~75MB)
  - <4GB RAM → recommend `tiny` Q8 quantized models

- [ ] **B3.6** Write tests:
  - Test: Model loads and unloads without memory leak
  - Test: Language detection returns valid language code
  - Test: Transcription produces non-empty segments
  - Test: RAM tier classification returns correct tier

**Verification:**
- Bundled English tiny model transcribes audio correctly
- Language detection identifies spoken language
- Model unloads after transcription (RAM recovers)
- Works on 4GB RAM devices without OOM crash

---

### Phase B4 — Cloudflare R2 Language Pack Downloads

> **Goal:** Implement chunked downloads of language model files from Cloudflare R2 with progress tracking and SHA256 integrity verification.

- [ ] **B4.1** Add `dio` and `crypto` dependencies:
  ```yaml
  dio: ^5.7.0
  crypto: ^3.0.5
  ```

- [ ] **B4.2** Create `lib/data/services/language_pack_service.dart` (real implementation):
  - `getAvailableLanguages()` — fetches and parses `manifest.json` from R2
  - `downloadLanguagePack()` — chunked download via Dio with progress callback, yields `DownloadProgress` stream
  - SHA256 verification after download: compute hash of downloaded file, compare with manifest entry, delete if mismatch
  - Models saved to `getApplicationDocumentsDirectory()/models/`

- [ ] **B4.3** Implement download resume:
  - Check if partial file exists at save path
  - If yes, use `Range` header to resume from last byte
  - Verify total downloaded matches expected size

- [ ] **B4.4** Implement storage management:
  - Track installed models in local JSON metadata file
  - Calculate total storage used by summing model file sizes
  - Expose `getStorageUsedGB()` and `getStorageTotalGB()`

- [ ] **B4.5** Set up Cloudflare R2 bucket:
  - Create bucket `captionary-models`
  - Enable public access or use R2.dev subdomain
  - Configure CORS:
    ```json
    [{ "AllowedOrigins": ["*"], "AllowedMethods": ["GET", "HEAD"], "AllowedHeaders": ["*"] }]
    ```
  - Upload `manifest.json` with language catalog
  - Upload initial model files (start with English tiny + Shona small)

- [ ] **B4.6** Write tests:
  - Test: Manifest JSON parses correctly
  - Test: SHA256 verification catches corrupted file
  - Test: Download progress stream emits correct values
  - Test: Resume works with partial file

**Verification:**
- Manifest fetches from R2 and displays languages
- Download progresses with real progress bar
- SHA256 verification passes for valid files
- Download resume works after interruption

---

### Phase B5 — Subtitle Generation & Timeline Sync

> **Goal:** Wire the complete pipeline: import video → extract audio → detect language → transcribe → display subtitles on timeline.

- [ ] **B5.1** Create `lib/data/services/caption_pipeline.dart` — orchestrator:
  - `processVideo()` yields pipeline state stream: extractingAudio → detectingLanguage → checkingModel → transcribing → complete
  - Cleans up temp audio files after processing

- [ ] **B5.2** Implement chunk-based transcription for long videos:
  - Split video audio into 30-second chunks
  - Transcribe each chunk sequentially (RAM conservation)
  - Merge chunk timestamps into continuous timeline
  - Yield `SubtitleSegment` stream for real-time UI updates

- [ ] **B5.3** Wire pipeline to Studio screen:
  - "Re-align AI" button triggers full pipeline
  - Progress states show in UI (extracting → detecting → transcribing → done)
  - Timeline populates with real subtitle segments

- [ ] **B5.4** Write integration tests:
  - Test: Full pipeline from video file to subtitle segments
  - Test: Chunk-based transcription produces continuous timeline
  - Test: Temp files are cleaned up after processing

**Verification:**
- Import a real video → auto-transcription produces subtitle segments
- Segments have accurate timestamps
- RAM stays within budget during processing

---

### Phase B6 — Caption Styling & Burn-In Engine

> **Goal:** Implement real caption burn-in using FFmpeg subtitle filters with custom styling.

- [ ] **B6.1** Create SRT/ASS file generator from `SubtitleSegment` list:
  - Generate `.srt` file for simple burn-in
  - Generate `.ass` (Advanced SubStation Alpha) file for styled burn-in with: font name (Lexend), font size, primary color, background box opacity, alignment, border/outline style

- [ ] **B6.2** Implement burn-in via FFmpeg:
  - FFmpeg command: `-i "$videoPath" -vf "ass=$assPath" -c:v libx264 -crf 23 -preset fast -c:a copy "$outputPath"`
  - Parse FFmpeg statistics callback for progress tracking

- [ ] **B6.3** Implement platform-specific caption style presets:
  - "TikTok Bold": Large font, green word highlight, bounce animation via ASS fade tags
  - "IG Highlight": Pill-shaped background, moderate font, blue accent
  - "Classic Movie": White text, thin outline, bottom-center, no box
  - "Neon Flow": Blue glow effect, karaoke-style word progression

- [ ] **B6.4** Write tests:
  - Test: ASS file generates valid syntax
  - Test: SRT file generates valid format
  - Test: FFmpeg burn-in command is correctly formed

**Verification:**
- Burn-in produces valid MP4 with embedded subtitles
- Styling presets render correctly in output video
- Progress tracking works during encoding

---

### Phase B7 — SRT/VTT Export Pipeline

> **Goal:** Implement subtitle file export to device storage.

- [ ] **B7.1** Implement real `exportSRT()` and `exportVTT()`:
  - Generate correctly formatted subtitle file content
  - Save to user-accessible directory (Downloads folder or file picker save dialog)
  - Use `share_plus` to share files via Android share sheet

- [ ] **B7.2** Implement "Export .SRT" button flow:
  - Generate SRT content → save to Downloads → show `SnackBar` confirmation

- [ ] **B7.3** Implement "Export .VTT" option:
  - Same flow as SRT but with VTT format

- [ ] **B7.4** Write tests:
  - Test: SRT format has correct timing syntax
  - Test: VTT format has correct header and timing syntax
  - Test: File saves to accessible location

**Verification:**
- SRT file opens correctly in VLC or any video player
- VTT file works when loaded as web subtitle track

---

### Phase B8 — Google AdMob Live Integration

> **Goal:** Replace ad placeholders with real AdMob adaptive banner ads.

- [ ] **B8.1** Add `google_mobile_ads: ^5.3.0` dependency.

- [ ] **B8.2** Initialize MobileAds in `main.dart` before `runApp()`.

- [ ] **B8.3** Create `lib/core/constants/ad_unit_ids.dart` with test and production ad unit IDs.

- [ ] **B8.4** Create `lib/data/services/ad_service.dart`:
  - Manages `BannerAd` lifecycle (load, show, dispose)
  - Handles `onAdFailedToLoad` gracefully (hide ad space)
  - Pre-calculates adaptive banner size using `MediaQuery`

- [ ] **B8.5** Update `lib/widgets/ad_banner_widget.dart`:
  - In real mode: Load and display actual `BannerAd` via `AdWidget`
  - Handle loading state (show placeholder until ad loads)
  - Handle failure state (collapse space if ad fails)

- [ ] **B8.6** Configure Android `AndroidManifest.xml` with AdMob App ID.

- [ ] **B8.7** Placement rules enforcement:
  - **ALLOWED:** Language Pack Manager, Export screen (encoding state)
  - **NEVER:** Video Player, Studio/Editor, Media Library, Donate screen

- [ ] **B8.8** Write tests:
  - Test: Ad widget renders placeholder when ad not loaded
  - Test: No ad widget exists on video player or studio screens

**Verification:**
- Test ads display correctly on permitted screens
- No ads appear during video playback or editing
- Ad loading/failure doesn't break UI layout

---

### Phase B9 — Donate Notification Scheduler

> **Goal:** Implement periodic device notifications reminding users to donate.

- [ ] **B9.1** Add notification dependencies: `flutter_local_notifications`, `timezone`, `flutter_timezone`.

- [ ] **B9.2** Create `lib/data/services/notification_service.dart`:
  - Initialize timezone database in `initialize()`
  - `requestPermission()` — Android 13+ POST_NOTIFICATIONS permission request
  - `scheduleDonateReminder()` — schedule periodic notifications (daily or every 8 hours)
  - `cancelDonateReminder()` — cancel scheduled notifications

- [ ] **B9.3** Wire notification tap action:
  - Tap notification → open app → navigate to Donate screen or open external donate URL

- [ ] **B9.4** Respect user preferences from Settings (toggle on/off, frequency selection).

- [ ] **B9.5** Configure Android `AndroidManifest.xml` with `POST_NOTIFICATIONS` permission and notification channel.

- [ ] **B9.6** Write tests:
  - Test: Permission request triggers on Android 13+
  - Test: Notification schedules correctly based on user preference
  - Test: Cancel removes scheduled notifications

**Verification:**
- Notifications appear at configured intervals
- Tapping notification opens Donate screen
- Settings toggle enables/disables correctly

---

### Phase B10 — URL Launcher & External Donate Portal

> **Goal:** Wire the "Donate ☕" buttons throughout the app to open the React donation portal in the device's external browser.

- [ ] **B10.1** Add `url_launcher: ^6.3.0` dependency.

- [ ] **B10.2** Configure Android `AndroidManifest.xml` with `<queries>` for URL scheme.

- [ ] **B10.3** Create `lib/core/utils/donate_launcher.dart`:
  - `openDonatePortal()` — opens `AppConstants.donateWebUrl` in external browser using `LaunchMode.externalApplication`

- [ ] **B10.4** Wire all donate buttons:
  - `DonatePill` (header) → `DonateLauncher.openDonatePortal()`
  - `DonateBottomSheet` "Donate Now" button → `DonateLauncher.openDonatePortal()`
  - `DonateBanner` "Donate" mini button → `DonateLauncher.openDonatePortal()`
  - `DonateScreen` "Open Web Donation Portal" button → `DonateLauncher.openDonatePortal()`
  - Export Complete "Buy a Coffee" button → `DonateLauncher.openDonatePortal()`
  - Notification tap action → `DonateLauncher.openDonatePortal()`
  - Bottom nav "Donate" tab → navigates to in-app Donate screen (NOT external URL)

- [ ] **B10.5** Write tests:
  - Test: URL launcher is called with correct URL
  - Test: LaunchMode.externalApplication is used

**Verification:**
- All donate buttons open the React portal in Chrome/default browser
- Bottom nav Donate tab opens in-app Donate screen (not external)

---

### Phase B11 — React Donation Portal — Payment Gateway Wiring

> **Goal:** Integrate real Paynow payment processing into the React donation portal.

- [ ] **B11.1** Register on Paynow as an individual:
  - Sign up at paynow.co.zw (select "Individual" entity type)
  - Obtain Integration ID and Integration Key
  - Configure webhook URL (Cloudflare Workers endpoint)

- [ ] **B11.2** Implement Paynow integration:
  - Create Cloudflare Worker (serverless function) to initiate Paynow transactions
  - React frontend redirects user to Paynow payment page
  - On return: Show confirmation page

- [ ] **B11.3** Implement alternative payment methods:
  - **Ko-fi:** Embed Ko-fi button/link (no API needed, just redirect)
  - **Buy Me a Coffee:** Embed BMAC link (no API needed)
  - **Cryptocurrency:** Display wallet addresses (BTC, ETH, USDT) with QR codes
  - **Direct EcoCash:** Show EcoCash merchant number for manual USSD payment

- [ ] **B11.4** Create thank-you/confirmation flow:
  - Paynow webhook confirms payment → update confirmation page
  - For manual methods: Show "Your donation may take a few minutes to confirm" message

- [ ] **B11.5** Deploy to Cloudflare Pages:
  ```bash
  cd react_frontend && npm run build
  # Deploy via Cloudflare Pages dashboard or Wrangler CLI
  ```

- [ ] **B11.6** Write tests:
  - Test: Payment method selection works
  - Test: Amount validation (min $1, max $1000)
  - Test: Confirmation page displays correctly

**Verification:**
- Paynow test transaction succeeds for EcoCash
- Ko-fi/BMAC links redirect correctly
- Crypto wallet addresses display with QR codes

---

### Phase B12 — RAM Optimization & Performance Profiling

> **Goal:** Ensure the app runs smoothly on 4GB RAM devices without crashes or excessive memory usage.

- [ ] **B12.1** Implement RAM monitoring:
  - Platform channel to get device total RAM and available RAM
  - Log current Dart heap + native memory at key pipeline points

- [ ] **B12.2** Implement model lifecycle management:
  - Load model ONLY when transcription starts
  - Unload model IMMEDIATELY after transcription completes
  - Never keep more than 1 model loaded simultaneously
  - Show "Preparing AI engine..." loading state during model load

- [ ] **B12.3** Implement chunk-based audio processing:
  - Maximum chunk size: 30 seconds of audio
  - Process sequentially (not parallel) to conserve RAM
  - Delete intermediate WAV files after each chunk is transcribed
  - Yield partial results to UI as each chunk completes

- [ ] **B12.4** Implement video player memory management:
  - Dispose player when leaving video player screen
  - Don't pre-load videos on Media Library screen
  - Thumbnail generation: Use FFmpeg to extract single frame, not load entire video

- [ ] **B12.5** Profile on 4GB device (or emulator configured with 4GB):
  - Run Flutter DevTools memory profiler
  - Target: Peak memory < 1.5GB total app usage during:
    - Video playback
    - Audio extraction
    - Model loading + transcription
    - FFmpeg burn-in encoding

- [ ] **B12.6** Implement low-memory fallbacks:
  - If available RAM < 500MB during transcription: Abort and show user-friendly error
  - If available RAM < 200MB: Show warning notification
  - If device RAM < 3GB: Disable large model downloads, only allow tiny/base models

- [ ] **B12.7** Write performance tests:
  - Test: Peak memory during transcription < 600MB
  - Test: Model unload recovers > 90% of model memory
  - Test: No memory leak after 10 consecutive transcriptions

**Verification:**
- App doesn't crash on 4GB RAM devices during full pipeline
- Memory profiler shows peak < 1.5GB
- Model memory is fully recovered after unloading

---

### Phase B13 — Integration Testing & Final Verification

> **Goal:** End-to-end testing of all features working together.

- [ ] **B13.1** Write end-to-end integration tests:
  - Full captioning flow: Launch → Import video → Detect language → Transcribe → Edit subtitles → Select style → Burn captions → Share
  - Language pack download flow: Navigate → Search → Download → Verify SHA256 → Install → Storage update

- [ ] **B13.2** Run full test suite:
  ```bash
  flutter test --coverage
  flutter test integration_test/
  ```

- [ ] **B13.3** Run `flutter analyze` — zero warnings.

- [ ] **B13.4** Build release APK:
  ```bash
  flutter build apk --release
  ```
  - Test on physical Android device (4GB+ RAM)
  - Test complete captioning flow with real video
  - Test language pack download from R2
  - Test donate flow (opens React portal in browser)
  - Test notification delivery

- [ ] **B13.5** Build React production bundle:
  ```bash
  cd react_frontend && npm run build
  ```
  - Deploy to Cloudflare Pages
  - Test donation flow in mobile browser
  - Test Paynow payment (sandbox mode)

- [ ] **B13.6** Final checklist:
  - [ ] All 16 requirements from user verified
  - [ ] No "Support" text remaining (all replaced with "Donate")
  - [ ] Ads ONLY on Language Pack Manager and Export (encoding) screens
  - [ ] Donate buttons open external React portal
  - [ ] Notifications deliver at configured interval
  - [ ] Video playback works smoothly
  - [ ] Transcription produces accurate results
  - [ ] Caption burn-in produces valid MP4
  - [ ] SRT/VTT export creates valid files
  - [ ] R2 downloads work with progress tracking
  - [ ] SHA256 verification catches corrupted files
  - [ ] App works on 4GB RAM device without crashes
  - [ ] React donation portal processes test payments
  - [ ] Dark theme enforced everywhere (no light theme leaks)
  - [ ] Lexend font renders across all screens

**Verification:**
- All integration tests pass
- Release APK installs and runs correctly on physical device
- Full end-to-end flow works: Import → Detect → Transcribe → Style → Burn-In → Share
- React portal deployed and processing donations
- 100% of user requirements met

---

## Appendix A — Whisper Language Codes Reference

| Language | Code | Region | Whisper Native? | Specialized Model? |
|----------|------|--------|----------------|-------------------|
| Shona | `sn` | Zimbabwe | ✅ Yes | ✅ African-51 fine-tune |
| isiZulu | `zu` | South Africa | ✅ Yes | ✅ African-51 fine-tune |
| Sepedi | `nso` | South Africa | ⚠️ Limited | ✅ African-51 fine-tune |
| Setswana | `tn` | Botswana/SA | ⚠️ Limited | ✅ African-51 fine-tune |
| Tonga | `toi` | Zambia/Zimbabwe | ⚠️ Limited | ⚠️ Community fine-tune |
| Swahili | `sw` | East Africa | ✅ Yes | ✅ African-51 fine-tune |
| Yoruba | `yo` | Nigeria | ✅ Yes | ✅ African-51 fine-tune |
| Afrikaans | `af` | South Africa | ✅ Yes | ✅ Native support |
| English | `en` | Global | ✅ Yes | ✅ Bundled tiny model |
| French | `fr` | Global | ✅ Yes | ✅ Multilingual model |
| Ndebele | `nr` | Zimbabwe/SA | ⚠️ Limited | ⚠️ Community fine-tune |
| Sotho | `st` | Lesotho/SA | ⚠️ Limited | ✅ African-51 fine-tune |

---

## Appendix B — File Size Budget

| Component | Size | Notes |
|-----------|------|-------|
| Base APK (Flutter + UI) | ~25 MB | Without models |
| Bundled tiny.en model | ~75 MB | English-only, shipped with APK |
| Total APK size | ~100 MB | Play Store limit is 150 MB (AAB) |
| Downloaded language model (small, Q5) | ~450-500 MB each | Stored in app data directory |
| Max recommended installed models | 3-4 | ~2 GB total on device |
| React web portal (built) | ~2 MB | Cloudflare Pages deployment |
| R2 storage (all models) | ~8 GB | Within 10 GB free tier |

---

## Appendix C — Execution Order Summary

```
SECTION A — UI First (Mock Data)
═══════════════════════════════════
A1  → Project restructuring, Riverpod, data models
A2  → Mock services with seed data
A3  → "Support" → "Donate" rename, donate UX spread
A4  → Custom video player UI
A5  → Language pack manager UI enhancements
A6  → Subtitle creator studio UI
A7  → Export & encoding progress UI
A8  → Settings screen UI
A9  → AdMob placeholder UI
A10 → Notification permission UI
A11 → React donation portal enhancements
A12 → UI testing & UX verification checkpoint
      ↓↓↓ USER APPROVAL GATE ↓↓↓

SECTION B — Backend Wiring
═══════════════════════════════════
B1  → media_kit video player
B2  → FFmpeg audio extraction
B3  → Whisper CPP transcription
B4  → Cloudflare R2 downloads
B5  → Subtitle generation pipeline
B6  → Caption styling & burn-in
B7  → SRT/VTT file export
B8  → Google AdMob live ads
B9  → Donate notification scheduler
B10 → URL launcher integration
B11 → React Paynow payment wiring
B12 → RAM optimization & profiling
B13 → Integration testing & final verification
```

---

> **Note for AI Executors:** This roadmap is designed to be executed sequentially within each section. Each phase has clear inputs, outputs, and verification criteria. When implementing a phase:
> 1. Read the phase description completely before writing any code.
> 2. Check off each sub-task as you complete it by changing `[ ]` to `[x]`.
> 3. Run the verification steps at the end of each phase before proceeding.
> 4. If a verification step fails, fix the issue before moving to the next phase.
> 5. Use the mock services (Section A) for all UI development. NEVER call real APIs during Section A.
> 6. When wiring backends (Section B), keep mock services available for testing — use Riverpod provider overrides to swap implementations.
> 7. Always run `flutter analyze` and `flutter test` after completing a phase.
> 8. The data model classes in Phase A1 define the contract between UI and backend — do not change their interface in Section B, only implement the abstract service methods.
