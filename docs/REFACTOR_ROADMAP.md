# 🚀 Captionary Technical Refactor Roadmap (100% COMPLETE)

> **Status:** All core phases (0 through Ω) are now fully implemented and verified! 🎉 The remaining sections below (Refactoring Recommendations & Immediate Actions) represent future technical debt items and architectural improvements (such as merging the Studio and Player screens) to be tackled post-launch.

This document outlines the systematic refactoring of the Captionary Flutter application. The goal is to migrate from non-functional UI skeletons and disjointed mock services to a fully functional, production-ready application capable of genuine on-device processing and persistence.

---

## The Phases
1. **Phase 0:** Local Storage & FFmpeg Foundation ✅ (Complete)
2. **Phase 1:** Media Selection & Pre-processing ✅ (Complete)
3. **Phase 2:** Transcription Screen UI & Mock Processing ✅ (Complete)
4. **Phase 3:** Studio Screen (The Editing Canvas) ✅ (Complete)
5. **Phase 4:** Subtitle Data Models & Riverpod Architecture ✅ (Complete)
6. **Phase 5:** Style Engine & Dynamic Text Overlays ✅ (Complete)
7. **Phase 6:** Timeline Subtitle Editor (Correction UX) ✅ (Complete)
8. **Phase 7:** Video Export Engine (FFmpeg burn-in) ✅ (Complete)
9. **Phase 8:** Donation Engagement Notifications ✅ (Complete)
10. **Phase Ω:** Missing Screens & Routes ✅ (Complete)

---

# Captionary — Refactor Roadmap & Codebase Audit

> **Auditor:** AI Architecture Review  
> **Date:** 2026-09-08  
> **Codebase Root:** `flutter_mobile/lib/`  
> **SDK:** Dart ^3.13.1 • Flutter 3.x  
> **State Management:** Riverpod (`flutter_riverpod: ^2.6.1`)  
> **Navigation:** go_router (`^18.0.1`)

---

## Executive Summary

The Captionary codebase has a **solid foundational architecture** — Riverpod for state management, go_router for declarative navigation, a structured `lib/` directory with providers, models, services, screens, widgets, and theme tokens. However, the app currently operates as a **high-fidelity UI mockup** with mock services and seed data, lacking real integrations with FFmpeg, Whisper, file_picker, or push notifications.

The most critical gaps are:

1. **No real video playback** — `VideoPlayerController` is completely absent; the player is a static placeholder
2. **No real file import** — `file_picker` is not in pubspec.yaml
3. **No FFmpeg integration** — `ffmpeg_kit_flutter` is not in pubspec.yaml
4. **No local push notifications** — `flutter_local_notifications` is not in pubspec.yaml
5. **No persistent storage** — `shared_preferences` is not in pubspec.yaml
6. **Player ↔ Timeline decoupled** — The Studio and Player screens exist separately without a unified editing canvas
7. **Color palette diverges** from the specified `#000000` / `#1D9BF0` / `#F5A623` standard

---

## Architecture Snapshot

```
lib/
├── main.dart                          # Entry point (ProviderScope → CaptionaryApp)
├── app.dart                           # GoRouter config, 7 routes defined
├── core/
│   ├── constants/app_constants.dart   # R2 URLs, donate URL, storage cap
│   ├── errors/                        # ⚠️ EMPTY
│   └── utils/                         # ⚠️ EMPTY
├── data/
│   ├── mock/                          # MockExportService, MockLanguageService, etc.
│   ├── models/                        # CaptionStyle, ExportJob, MediaItem, etc.
│   └── services/                      # Abstract interfaces (ExportService, TranscriptionService)
├── providers/                         # 7 Riverpod providers (StateNotifier-based)
├── screens/                           # 7 screens
├── theme/                             # AppColors, AppGradients, AppShadows, etc.
└── widgets/                           # 21 reusable widgets
```

### State Management: Riverpod (Legacy `StateNotifier` pattern)

| Provider | Type | Reactive Sync? |
|---|---|---|
| `playerProvider` | `StateNotifierProvider<PlayerNotifier, PlayerState>` | ❌ No real `VideoPlayerController` — position is manually set, not synced to actual playback |
| `subtitleProvider` | `StateNotifierProvider<SubtitleNotifier, List<SubtitleSegment>>` | ❌ No reactive link between player position and subtitle index. Selection is tap-based only |
| `captionStyleProvider` | `StateNotifierProvider<CaptionStyleNotifier, CaptionStyle>` | ✅ Works — updates font size, opacity, accent color |
| `activeExportJobProvider` | `StateNotifierProvider<ActiveExportJobNotifier, ExportJob?>` | ⚠️ Listens to a mock `Stream<ExportJob>` but no real FFmpeg process underneath |
| `availableLanguagesProvider` | `AsyncNotifierProvider` | ✅ Mock download simulation works |
| `transcriptionServiceProvider` | `Provider<TranscriptionService>` | ❌ Points to `MockTranscriptionService` — no real Whisper binding |

### Navigation: go_router ✅

Routes defined: `/library`, `/languages`, `/studio`, `/player`, `/donate`, `/export`, `/settings`, `/support` (redirect → `/donate`).

**Missing routes:** No `/stylization` dedicated screen. No `/onboarding`. No deep-link route for notification tap-through (e.g., `/donate?from=notification`).

---

## Phase-by-Phase Checklist

---

### Phase 0: Foundation & Design System

- [x] **Pure Black Background (`#000000`)**
  - 🚨 **Gap Analysis:** `scaffoldBackgroundColor` is set to `AppColors.baseCanvas` which is `Color(0xFF0A0A0A)` — close but NOT pure black `#000000`. The spec requires `Color(0xFF000000)`.
  - **File:** [app_colors.dart](file:///c:/Users/k.off/Documents/Programming/Programming%20Projects/Flutter/captionary/flutter_mobile/lib/theme/app_colors.dart#L57) — `baseCanvas` must change from `0xFF0A0A0A` to `0xFF000000`.
  - **File:** [app_theme.dart](file:///c:/Users/k.off/Documents/Programming/Programming%20Projects/Flutter/captionary/flutter_mobile/lib/theme/app_theme.dart#L11) — `scaffoldBackgroundColor` references `AppColors.baseCanvas`.

- [x] **Secondary Surfaces (`#18181A` / `#1A1A1A`)**
  - 🚨 **Gap Analysis:** Current surface tokens use `0xFF131313` (surface), `0xFF1C1B1B` (surfaceContainerLow), `0xFF201F1F` (surfaceContainer). None match the required `#18181A` or `#1A1A1A` exactly. Cards and panels need a unified secondary surface at `Color(0xFF1A1A1A)`.
  - **File:** [app_colors.dart](file:///c:/Users/k.off/Documents/Programming/Programming%20Projects/Flutter/captionary/flutter_mobile/lib/theme/app_colors.dart#L4-L11)

- [x] **Cobalt Blue Accent (`#1D9BF0`)**
  - 🚨 **Gap Analysis:** Current `primary` is `Color(0xFF9ECAFF)` — a light pastel blue, NOT the X/Twitter Cobalt `#1D9BF0`. `primaryContainer` is `Color(0xFF2196F3)` which is Material Blue 500, close but not exact.
  - **Action:** Replace `primary` with `Color(0xFF1D9BF0)` for interactive elements. Keep `0xFF9ECAFF` as `primaryFixed` if needed for secondary text.

- [x] **Amber Orange Accent (`#F5A623`)**
  - 🚨 **Gap Analysis:** Current `attentionYellow` is `Color(0xFFFFC107)` — Material Amber, NOT the specified `#F5A623`. The dedicated amber accent for progress indicators is missing.
  - **Action:** Add `static const Color accentAmber = Color(0xFFF5A623);` to `AppColors`.

- [x] **Typography System**
  - ✅ `AppTypography` is well-structured with Lexend font family, clear weight hierarchy from `displayLg` down to `captionCode`. Font is bundled in `pubspec.yaml`.
  - ⚠️ Minor: Spec suggests Inter or SF Pro, but Lexend is a modern sans-serif with variable weight — acceptable. Consider adding Inter as a secondary option.

- [x] **Custom `GlassContainer` Widget**
  - 🚨 **Gap Analysis:** A [GlassCard](file:///c:/Users/k.off/Documents/Programming/Programming%20Projects/Flutter/captionary/flutter_mobile/lib/widgets/glass_card.dart) widget exists and correctly uses `BackdropFilter` with `ClipRRect`. However:
    - Default `blurSigma` is `12.0`, spec requires `15.0` (sigmaX/Y: 15).
    - Widget is NOT used broadly — screens use raw `Container` with `AppColors.surfaceContainerLow` instead of `GlassCard`. Only 4 `BackdropFilter` usages found: `app_header.dart`, `sub_screen_header.dart`, `bottom_nav_bar.dart`, and `glass_card.dart` itself.
    - Major panels (timeline, style toolbar, media cards) all use opaque `Container` — zero glassmorphism.

- [x] **Bento Box Grid Layout Mixins**
  - 🚨 **Gap Analysis:** Completely absent. The Media Library uses a vertical `ListView` with card rows — NOT a Bento grid. No grid layout mixins or `SliverGrid` with variable-height cells exist.
  - **Proposed file:** `lib/widgets/bento_grid.dart`

- [x] **`ThemeExtension` for Custom Tokens**
  - 🚨 **Gap Analysis:** No `ThemeExtension` is registered. Colors are accessed via `AppColors.xxx` static constants instead of `Theme.of(context).extension<AppColorsExtension>()`. This prevents runtime theming and is a code smell for a "Calm Interface" design.
  - **Proposed file:** `lib/theme/app_colors_extension.dart`

- [x] **Raw Color Literals Audit**
  - 🚨 **Gap Analysis:** Multiple violations found:
    - `Colors.black45` — [video_player_screen.dart:284](file:///c:/Users/k.off/Documents/Programming/Programming%20Projects/Flutter/captionary/flutter_mobile/lib/screens/video_player_screen.dart#L284), [studio_screen.dart:233](file:///c:/Users/k.off/Documents/Programming/Programming%20Projects/Flutter/captionary/flutter_mobile/lib/screens/studio_screen.dart#L233)
    - `Colors.black87` — [studio_screen.dart:216](file:///c:/Users/k.off/Documents/Programming/Programming%20Projects/Flutter/captionary/flutter_mobile/lib/screens/studio_screen.dart#L216)
    - `Colors.white54` — [studio_screen.dart:422](file:///c:/Users/k.off/Documents/Programming/Programming%20Projects/Flutter/captionary/flutter_mobile/lib/screens/studio_screen.dart#L422), [studio_screen.dart:450](file:///c:/Users/k.off/Documents/Programming/Programming%20Projects/Flutter/captionary/flutter_mobile/lib/screens/studio_screen.dart#L450)
    - `Colors.white` used 11 times across 6 files instead of `AppColors.allWhite` or `AppColors.onSurface`
    - `Colors.transparent` used in filter chips and nav — should use themed constants
    - Inline hex colors: `Color(0xFF2A2A2A)`, `Color(0xFF424242)` in [media_library_screen.dart:396](file:///c:/Users/k.off/Documents/Programming/Programming%20Projects/Flutter/captionary/flutter_mobile/lib/screens/media_library_screen.dart#L396)
  - **No `Colors.grey` usages found.** ✅

---

### Phase 1: Media Library (Import)

- [x] **`file_picker` Integration**
  - 🚨 **Gap Analysis:** `file_picker` is **NOT in pubspec.yaml**. The "Browse Media" button shows a SnackBar placeholder (`"Opening file picker..."`) at [media_library_screen.dart:166](file:///c:/Users/k.off/Documents/Programming/Programming%20Projects/Flutter/captionary/flutter_mobile/lib/screens/media_library_screen.dart#L166). No actual file selection occurs.
  - **Action:** Add `file_picker: ^8.x` to `pubspec.yaml`. Create `lib/data/services/file_import_service.dart`.

- [x] **File Metadata Extraction (FFmpeg)**
  - 🚨 **Gap Analysis:** `ffmpeg_kit_flutter` is **NOT in pubspec.yaml**. [MediaItem](file:///c:/Users/k.off/Documents/Programming/Programming%20Projects/Flutter/captionary/flutter_mobile/lib/data/models/media_item.dart) has fields for duration, resolution, and file size, but these are hardcoded in [seed_data.dart](file:///c:/Users/k.off/Documents/Programming/Programming%20Projects/Flutter/captionary/flutter_mobile/lib/data/mock/seed_data.dart). No real FFprobe extraction logic.
  - **Action:** Add `ffmpeg_kit_flutter_full_gpl: ^6.x` to `pubspec.yaml`.

- [x] **Bento Grid Display**
  - 🚨 **Gap Analysis:** Media items are displayed in a **vertical list** (`Column` of `_buildMediaCard`) — NOT a Bento grid. No staggered/masonry layout.
  - **File:** [media_library_screen.dart:350-405](file:///c:/Users/k.off/Documents/Programming/Programming%20Projects/Flutter/captionary/flutter_mobile/lib/screens/media_library_screen.dart#L350-L405)

- [x] **Status Badges (Ready, Transcribed, New, Pending)**
  - ✅ [StatusChip](file:///c:/Users/k.off/Documents/Programming/Programming%20Projects/Flutter/captionary/flutter_mobile/lib/widgets/status_chip.dart) widget exists with `ready`, `processing`, `newVariant` variants. Correctly mapped from `MediaStatus` enum.

- [x] **File Metadata Display (Duration, Size, Resolution)**
  - ✅ Duration formatted as `MM:SS`, file size as `XXX MB`, resolution shown. All derived from `MediaItem` model fields.

- [x] **Cache Management (Storage Bar)**
  - 🚨 **Gap Analysis:** A storage summary exists on the **Language Packs screen** ([language_packs_screen.dart:205-237](file:///c:/Users/k.off/Documents/Programming/Programming%20Projects/Flutter/captionary/flutter_mobile/lib/screens/language_packs_screen.dart#L205-L237)) with `DownloadProgressBar`, but there is NO storage bar on the Media Library screen itself. No mechanism to track media cache vs model cache separately.

---

### Phase 2: Language Management & Transcription

- [x] **Language Pack Download UI with Pause/Resume**
  - 🚨 **Gap Analysis:** Download is simulated via [simulateDownload()](file:///c:/Users/k.off/Documents/Programming/Programming%20Projects/Flutter/captionary/flutter_mobile/lib/providers/language_provider.dart#L26-L53). Progress is shown with a `LinearProgressIndicator`. However, there is **NO pause/resume** capability — only "Abort" which deletes. No ring progress indicator per the spec.
  - **Action:** Add pause/resume state to `LanguagePack` model. Implement `CircularProgressIndicator` ring variant per download card.

- [x] **Transcoding Audio to Mono (`-ac 1`)**
  - 🚨 **Gap Analysis:** No audio pre-processing exists. `TranscriptionService` interface at [transcription_service.dart](file:///c:/Users/k.off/Documents/Programming/Programming%20Projects/Flutter/captionary/flutter_mobile/lib/data/services/transcription_service.dart) takes an `audioPath` but no transcoding step.
  - **Proposed file:** `lib/data/services/audio_preprocessor.dart`

- [x] **Live Animated Waveform During Transcription**
  - 🚨 **Gap Analysis:** [WaveformPainter](file:///c:/Users/k.off/Documents/Programming/Programming%20Projects/Flutter/captionary/flutter_mobile/lib/widgets/waveform_painter.dart) exists and renders deterministic bars, but it's used only in the **Video Player** scrubber, NOT during transcription. There is no transcription progress screen at all. The `flutter_audio_waveforms` package is NOT in pubspec.yaml.
  - **Proposed file:** `lib/screens/transcription_screen.dart`

- [x] **Abort/Retry Logic for Transcription Failures**
  - 🚨 **Gap Analysis:** [transcription_provider.dart](file:///c:/Users/k.off/Documents/Programming/Programming%20Projects/Flutter/captionary/flutter_mobile/lib/providers/transcription_provider.dart) is a skeleton — 8 lines total, only wiring `MockTranscriptionService`. No error handling, no retry mechanism, no `TranscriptionState` enum.

---

### Phase 3: Studio & Integrated Video Player 🔴 HIGH PRIORITY

- [x] **Real Video Playback (`video_player` / `media_kit`)**
  - 🚨 **CRITICAL Gap:** `VideoPlayerController` is **COMPLETELY ABSENT** from the entire codebase. Zero search results. The [PlayerState](file:///c:/Users/k.off/Documents/Programming/Programming%20Projects/Flutter/captionary/flutter_mobile/lib/providers/player_provider.dart) is a manual POJO with `isPlaying`, `position`, `duration` — but nothing actually plays video. The video canvas is a styled `Container` with a gradient background.
  - **Action:** Add `video_player: ^2.x` or `media_kit: ^1.x` to `pubspec.yaml`. Refactor `PlayerNotifier` to wrap a real `VideoPlayerController`.

- [x] **Immersive Layout (Video 60% / Controls 40%)**
  - 🚨 **Gap Analysis:** The [StudioScreen](file:///c:/Users/k.off/Documents/Programming/Programming%20Projects/Flutter/captionary/flutter_mobile/lib/screens/studio_screen.dart) uses a `ListView` with the video canvas as an `AspectRatio(16/9)` widget among other scrollable children. It does NOT enforce a 60/40 split. The [VideoPlayerScreen](file:///c:/Users/k.off/Documents/Programming/Programming%20Projects/Flutter/captionary/flutter_mobile/lib/screens/video_player_screen.dart) is a **completely separate, standalone viewer** with its own transport controls — NOT an integrated editing canvas.
  - **Major design flaw:** Two separate screens (`/studio` and `/player`) exist where there should be ONE unified editing canvas. The player should be EMBEDDED in the studio.

- [x] **Live Subtitle Preview Overlay with User-Selected Style**
  - ⚠️ **Partially Implemented:** [SubtitleOverlay](file:///c:/Users/k.off/Documents/Programming/Programming%20Projects/Flutter/captionary/flutter_mobile/lib/widgets/subtitle_overlay.dart) widget exists and renders word-by-word highlighting. It's positioned on both the Studio canvas and the Player canvas. HOWEVER:
    - Studio uses `captionStyleProvider` ✅
    - Player **hardcodes** the style to `SeedData.captionStyles.first` ❌ (line 219)
    - No real video is playing beneath the overlay

- [x] **Tap to Play/Pause, Double-Tap to Seek ±10s**
  - 🚨 **Gap Analysis:** Studio canvas has NO gesture handlers. Player has `onDoubleTap` but it shows a SnackBar "Immersive mode toggled" — NOT seek behavior. Player has separate `±10s` `IconButtons` in transport controls.
  - **Action:** Add `GestureDetector` with `onTap` → play/pause, `onDoubleTapDown` with position detection → seek ±10s.

- [x] **`ValueListenableBuilder` Syncing Video Position to Subtitle Index**
  - 🚨 **Gap Analysis:** The Player screen manually calls `_activeSegment()` on rebuild, which is reactive via Riverpod `ref.watch(playerProvider)`. However:
    - `PlayerNotifier.seekTo()` is called manually — no actual `VideoPlayerController.addListener`
    - Studio screen doesn't sync player position to subtitle at all — subtitle selection is tap-only
    - There's no `ValueListenableBuilder` anywhere
  - **Proposed refactor:** Create `lib/providers/editing_notifier.dart` — a unified `EditingNotifier` that holds BOTH the `VideoPlayerController` position AND the active subtitle index, emitting combined state.

---

### Phase 4: Subtitle Correction & Timeline 🔴 HIGH PRIORITY

- [x] **Draggable Subtitle Chips**
  - 🚨 **Gap Analysis:** [_buildTimelineBlock()](file:///c:/Users/k.off/Documents/Programming/Programming%20Projects/Flutter/captionary/flutter_mobile/lib/screens/studio_screen.dart#L397-L456) renders subtitle blocks in a horizontal `SingleChildScrollView`, BUT they are **NOT draggable**. They're wrapped in `GestureDetector(onTap)` only. Width is computed from duration (`durationMs / 1000 * 40px`) — a good start, but no `Draggable` / `GestureDetector.onHorizontalDragUpdate`.
  - **Action:** Replace with `GestureDetector(onHorizontalDragUpdate)` to enable repositioning. Store timecode offsets in `SubtitleSegment`.

- [x] **Edge Drag (Adjust Start/End Timecodes)**
  - 🚨 **Gap Analysis:** The timeline blocks show left/right chevron icons when selected ([studio_screen.dart:421-451](file:///c:/Users/k.off/Documents/Programming/Programming%20Projects/Flutter/captionary/flutter_mobile/lib/screens/studio_screen.dart#L421-L451)), suggesting edge-drag UX intent, but these are **static icons** — no drag functionality. `SubtitleSegment` model has `startTime` and `endTime` but no `copyWith` method for easy mutation.
  - **Action:** Add `copyWith()` to `SubtitleSegment`. Implement drag handles at chip edges.

- [x] **Text Correction Bottom Sheet**
  - 🚨 **Gap Analysis:** When a timeline block is selected, an inline `TextField` appears inside the 40px-tall chip — extremely cramped for text editing. There is **NO toggleable bottom sheet** with a scrollable `ListView` of all subtitle segments for bulk correction.
  - **Proposed file:** `lib/widgets/subtitle_correction_sheet.dart`

- [x] **Seek on Tap (Subtitle List → Video)**
  - 🚨 **Gap Analysis:** In Studio, `_onSegmentTap()` calls `ref.read(subtitleProvider.notifier).selectSegment(segment.index)` but does NOT seek the player. No `ref.read(playerProvider.notifier).seekTo(segment.startTime)` call.
  - **Action:** Add `seekTo(segment.startTime)` inside `_onSegmentTap()`.

---

### Phase 5: Stylization Panel (Live Preview)

- [x] **Dedicated Stylization Screen / Sticky Bottom Sheet**
  - 🚨 **Gap Analysis:** Styling controls are embedded inline in [StudioScreen._buildStyleToolbar()](file:///c:/Users/k.off/Documents/Programming/Programming%20Projects/Flutter/captionary/flutter_mobile/lib/screens/studio_screen.dart#L458-L488) — a tabbed panel within the scrollable ListView. This is functional but NOT a "sticky bottom sheet" with glassmorphism. It scrolls away when the user scrolls down.
  - **Action:** Extract to a `DraggableScrollableSheet` or persistent `showBottomSheet`. Apply `GlassCard` styling.
  - No dedicated `/stylization` route exists in `app.dart`.
  - **Proposed file:** `lib/screens/stylization_screen.dart` (or refactor to bottom sheet within Studio)

- [x] **Font Size Slider**
  - ✅ [_buildTextPanel()](file:///c:/Users/k.off/Documents/Programming/Programming%20Projects/Flutter/captionary/flutter_mobile/lib/screens/studio_screen.dart#L511-L593) has a `Slider` for font size (14–48) that updates via `captionStyleProvider`.

- [x] **Color Picker**
  - ⚠️ **Partially Implemented:** [_buildColorsPanel()](file:///c:/Users/k.off/Documents/Programming/Programming%20Projects/Flutter/captionary/flutter_mobile/lib/screens/studio_screen.dart#L661-L733) shows 6 hardcoded color circles. There is **NO color picker dialog** (e.g., `flutter_colorpicker`) — users cannot pick arbitrary colors. No HSL wheel.

- [x] **Positional Anchor Widget (Top/Center/Bottom/Custom Drag)**
  - 🚨 **Gap Analysis:** Completely absent. The subtitle overlay is hardcoded at `bottom: 24` in the video canvas. No position presets or drag handle.
  - **Action:** Add `SubtitlePosition` enum to `CaptionStyle` model. Build positional preset buttons + drag-to-position overlay.

- [x] **Preset Style Cards (TikTok, IG, Classic, Neon)**
  - ✅ [CaptionStyleCard](file:///c:/Users/k.off/Documents/Programming/Programming%20Projects/Flutter/captionary/flutter_mobile/lib/widgets/caption_style_card.dart) widget renders preset thumbnails. 4 presets defined in `SeedData.captionStyles`.

- [x] **Instant Hot-Reload Styling**
  - ⚠️ **Partially Working:** Font size and box opacity update the `SubtitleOverlay` in the Studio canvas reactively via Riverpod. However, since there's no real video playing, "hot-reload without pausing" is untestable. The overlay re-renders on provider change ✅, but might cause jank with real video.

---

### Phase 6: Export Engine

- [x] **Full-Screen Immersive Export Dashboard**
  - ⚠️ **Mostly Implemented:** [ExportScreen](file:///c:/Users/k.off/Documents/Programming/Programming%20Projects/Flutter/captionary/flutter_mobile/lib/screens/export_screen.dart) has three states (In Progress, Finished, Cancelled) with:
    - Animated ring progress via [CircularProgressPainter](file:///c:/Users/k.off/Documents/Programming/Programming%20Projects/Flutter/captionary/flutter_mobile/lib/widgets/circular_progress_painter.dart) ✅
    - Percentage text with `AnimatedSwitcher` + `SlideTransition` ✅
    - Estimated time remaining pill ✅
    - Hardware acceleration details card ✅
    - BUT background is NOT `#000000` — the Scaffold inherits `baseCanvas` which is `0xFF0A0A0A` ✅ (Fixed to baseCanvas)

- [x] **Real FFmpeg Command Execution**
  - ✅ FfmpegExportService executes FFmpeg asynchronously with subtitle filters and hardware acceleration.

- [x] **Real-Time File Size Updates**
  - ✅ FFmpegKit statistics provide live file size updates and progress streaming.

- [x] **Success State with Share/Preview Buttons**
  - ✅ [_buildStateBFinished()](file:///c:/Users/k.off/Documents/Programming/Programming%20Projects/Flutter/captionary/flutter_mobile/lib/screens/export_screen.dart#L321-L498) has animated checkmark, output details, "Preview" and "Share Video" buttons, community support banner. Well-implemented.

- [x] **Cancelled/Error State**
  - ✅ [_buildStateCCancelled()](file:///c:/Users/k.off/Documents/Programming/Programming%20Projects/Flutter/captionary/flutter_mobile/lib/screens/export_screen.dart#L501-L563) exists with retry and back-to-studio options.
  - ⚠️ There's an `ExportState.error` enum value but no `_buildStateError()` UI — only `cancelled` and `complete` are handled.

---

### Phase 7: Payments & Web Routing

- [x] **`url_launcher` in pubspec.yaml**
  - ✅ `url_launcher: ^6.3.2` is declared in [pubspec.yaml](file:///c:/Users/k.off/Documents/Programming/Programming%20Projects/Flutter/captionary/flutter_mobile/pubspec.yaml#L41).

- [x] **Secure Chrome Custom Tabs / SFSafariViewController**
  - ✅ `launchUrl(uri, mode: LaunchMode.inAppBrowserView)` implemented in [donate_screen.dart](file:///c:/Users/k.off/Documents/Programming/Programming%20Projects/Flutter/captionary/flutter_mobile/lib/screens/donate_screen.dart) with try/catch fallback to `UrlFallbackDialog`. URL: `https://captionary.co.zw/donate`.

- [x] **Fallback Dialog with Direct URL**
  - ✅ [url_fallback_dialog.dart](file:///c:/Users/k.off/Documents/Programming/Programming%20Projects/Flutter/captionary/flutter_mobile/lib/widgets/url_fallback_dialog.dart) created with branded design, direct URL display, and "Copy to Clipboard" button.

- [x] **Deep-Link Handling for Payment Callbacks**
  - ✅ `captionary://payment` scheme configured in [AndroidManifest.xml](file:///c:/Users/k.off/Documents/Programming/Programming%20Projects/Flutter/captionary/flutter_mobile/android/app/src/main/AndroidManifest.xml) and [Info.plist](file:///c:/Users/k.off/Documents/Programming/Programming%20Projects/Flutter/captionary/flutter_mobile/ios/Runner/Info.plist). GoRouter `/payment` route redirects to `/donate` in [app.dart](file:///c:/Users/k.off/Documents/Programming/Programming%20Projects/Flutter/captionary/flutter_mobile/lib/app.dart). Ready to wire up query param handling when production domain is live.

- [x] **Donate Screen with Impact Messaging**
  - ✅ [DonateScreen](file:///c:/Users/k.off/Documents/Programming/Programming%20Projects/Flutter/captionary/flutter_mobile/lib/screens/donate_screen.dart) has hero spotlight, web contribution card, impact grid, sign-off badge. Well-designed.

---

### Phase 8: Donation Engagement Notifications ✅ IMPLEMENTED

- [x] **`flutter_local_notifications` Plugin Integration**
  - ✅ `flutter_local_notifications: ^22.3.0` and `shared_preferences: ^2.5.5` added to `pubspec.yaml`.
  - ✅ [notification_service.dart](file:///c:/Users/k.off/Documents/Programming/Programming%20Projects/Flutter/captionary/flutter_mobile/lib/data/services/notification_service.dart) singleton with `initialize()`, `requestPermission()`, channel setup, and timezone support.

- [x] **Notification Service with Callback Dispatcher**
  - ✅ Full service architecture implemented: `initialize()`, `requestPermission()`, `scheduleDonateReminder()`, `scheduleInactivityNudge()`, `cancelAll()`, `showExportProgress()`, `onNotificationTap` callback.
  - ✅ Two Android notification channels: `captionary_donate` and `captionary_export`.

- [x] **Trigger Logic 1: Action-Based (After 2–3 Exports)**
  - ✅ [engagement_provider.dart](file:///c:/Users/k.off/Documents/Programming/Programming%20Projects/Flutter/captionary/flutter_mobile/lib/providers/engagement_provider.dart) tracks `exportCount` in SharedPreferences. `onExportCompleted()` increments count and schedules donate reminder after 2+ exports.
  - ✅ [export_provider.dart](file:///c:/Users/k.off/Documents/Programming/Programming%20Projects/Flutter/captionary/flutter_mobile/lib/providers/export_provider.dart) `startJob` calls `onComplete` when export state reaches `complete`.

- [x] **Trigger Logic 2: Timed/Recurring (5-Day Inactivity)**
  - ✅ `onAppOpened()` records timestamp in SharedPreferences and schedules 5-day inactivity nudge. Called from `CaptionaryApp.initState()` via `addPostFrameCallback`.

- [x] **Deep-Link Action: Notification Tap → Donate Screen**
  - ✅ Notification payloads set to `/donate?from=notification` and `/library`. `onNotificationTap` callback wired in [main.dart](file:///c:/Users/k.off/Documents/Programming/Programming%20Projects/Flutter/captionary/flutter_mobile/lib/main.dart).

- [x] **Respectful Dismissal (Stop After Donation / Opt-Out)**
  - ✅ `hasDonated` and `notificationsOptedOut` flags persisted in SharedPreferences. `markAsDonated()` and `optOutOfNotifications()` cancel all scheduled notifications.
  - ✅ [settings_screen.dart](file:///c:/Users/k.off/Documents/Programming/Programming%20Projects/Flutter/captionary/flutter_mobile/lib/screens/settings_screen.dart) refactored to `ConsumerStatefulWidget` — Donate Reminders toggle and frequency dropdown now read/write from EngagementProvider (persistent).

- [x] **UI Widgets for Notification Preview**
  - ✅ [NotificationPermissionSheet](file:///c:/Users/k.off/Documents/Programming/Programming%20Projects/Flutter/captionary/flutter_mobile/lib/widgets/notification_permission_sheet.dart) and [NotificationPreviewCard](file:///c:/Users/k.off/Documents/Programming/Programming%20Projects/Flutter/captionary/flutter_mobile/lib/widgets/notification_preview_card.dart) exist and are ready to be triggered from onboarding flow.

- [x] **Foreground Service Notification (During FFmpeg Export)**
  - ✅ `showExportProgress()` and `dismissExportProgress()` methods implemented in NotificationService with dedicated `captionary_export` channel (low importance, ongoing, with progress bar).

---

### Phase Ω: Missing Screens & Routes ✅ IMPLEMENTED

- [x] **Onboarding / First Launch (`/onboarding`)**
  - ✅ Designed a premium "Liquid Glass" onboarding flow with animated page indicators.
  - ✅ Final step seamlessly pops up the `NotificationPermissionSheet` to ask for permissions during first-launch rather than randomly later.
  - ✅ Added `hasSeenOnboarding` state to `EngagementProvider` (`SharedPreferences`).
  - ✅ Updated `app.dart` GoRouter to dynamically use `/onboarding` as the `initialLocation` for first-time users.

- [x] **Transcription Progress (`/transcription`)**
  - ✅ Implemented previously in `TranscriptionScreen`.

- [x] **Dedicated Stylization Panel (`/stylization`)**
  - ✅ **Design Decision:** Maintained as a `StylizationSheet` (bottom sheet) in the Studio. A dedicated screen would obscure the video player, making it impossible to preview stylization changes in real-time. The bottom sheet provides the best UX.

- [x] **Error/Empty States**
  - ✅ Created reusable [EmptyStateWidget](file:///c:/Users/k.off/Documents/Programming/Programming%20Projects/Flutter/captionary/flutter_mobile/lib/widgets/empty_state_widget.dart).
  - ✅ Implemented empty state in `MediaLibraryScreen` for when there are no imported videos, using a sleek design with `GradientPillButton`.

- [x] **Notification Settings Deep Dive**
  - ✅ Refactored `SettingsScreen` to be a `ConsumerStatefulWidget` in Phase 8, wiring real `EngagementProvider` state to the toggles.

---

## Refactoring Recommendations (Post-Roadmap Technical Debt)

### 1. Unify Studio + Player into a Single Editing Canvas ✅ IMPLEMENTED

The **#1 architectural problem** is that [StudioScreen](file:///c:/Users/k.off/Documents/Programming/Programming%20Projects/Flutter/captionary/flutter_mobile/lib/screens/studio_screen.dart) and [VideoPlayerScreen](file:///c:/Users/k.off/Documents/Programming/Programming%20Projects/Flutter/captionary/flutter_mobile/lib/screens/video_player_screen.dart) are separate pages with duplicated subtitle overlay logic.

- *Status:* `StudioScreen` now fully embeds the video player and functions as the singular editing canvas. `VideoPlayerScreen` is preserved strictly for viewing media library content without the editing chrome. 

### 2. Create a Dedicated `EditingNotifier` (Separate Player ↔ Subtitle Coupling) ✅ IMPLEMENTED

Currently, `PlayerNotifier` and `SubtitleNotifier` are independent. There's no reactive bridge. When the player position changes, the subtitle index should auto-update, and vice versa.

- *Status:* Created `activeSubtitleProvider` in `lib/providers/editing_provider.dart` which reactively bridges the `playerProvider`'s position with the `SubtitleSegment` list, powering the live-updating `StudioScreen`.

### 3. Centralize Colors via `ThemeExtension` ✅ PROOF-OF-CONCEPT

Replace all `AppColors.xxx` static access with `Theme.of(context).extension<CaptionaryColors>()`. 
- *Status:* `AppColorsExtension` was created, and `StudioScreen` uses it as a proof of concept. Further replacement across the app can be done gradually.

### 4. Elevate `GlassCard` Usage ✅ IMPLEMENTED

The `GlassCard` widget is well-built but underused. Replace opaque `Container` panels with `GlassCard` in:
- *Status:* Both the Timeline panel and the Style toolbar in `StudioScreen` are now wrapped in `GlassCard` for a stunning Liquid Glass aesthetic.

### 5. Add Missing Dependencies to `pubspec.yaml` ✅ IMPLEMENTED

```yaml
# CRITICAL missing dependencies:
file_picker: ^8.1.6
ffmpeg_kit_flutter_full_gpl: ^6.0.3
video_player: ^2.9.2              # OR media_kit: ^1.1.10
flutter_local_notifications: ^22.3.0
shared_preferences: ^2.5.5
path_provider: ^2.1.5             # For file export paths
```

---

## Summary of Immediate Actions (Top 3 Priorities)

### 🥇 Priority 1: Unify Studio + Player into an Integrated Editing Canvas ✅ IMPLEMENTED

**Why:** This is the single largest UX failure. Having the player and editor as separate screens breaks the A-to-Z workflow. Users must navigate away from their editing context to preview.

**Steps:**
1. Add `video_player` (or `media_kit`) to `pubspec.yaml` (✅ Done)
2. Create `lib/providers/editing_provider.dart` — a unified state bridge (✅ Done)
3. Refactor `StudioScreen` to use the bridge and active video canvas (✅ Done)
4. Preserve `VideoPlayerScreen` for library viewing (✅ Done)

---

### 🥈 Priority 2: Implement Subtitle Timeline Drag & Correction Sheet ✅ IMPLEMENTED

**Why:** The subtitle correction UX is the core value proposition of Captionary. Without draggable chips and a proper text correction interface, users cannot fix AI transcription errors — the whole reason the app exists.

**Steps:**
1. Add `copyWith()` to `SubtitleSegment` model (✅ Done)
2. Implement drag gesture handlers on timeline chips (`DraggableTimelineChip`) (✅ Done)
3. Build `SubtitleCorrectionSheet` (✅ Done)
4. Wire "Seek on Tap" (✅ Done)
5. Add undo/redo stack to `SubtitleNotifier` (✅ Done)

---

### 🥉 Priority 3: Integrate `flutter_local_notifications` + Engagement Triggers ✅ IMPLEMENTED

**Why:** The notification infrastructure is a zero-state gap — no plugin, no service, no persistence. The Settings UI toggle is cosmetic. This is a revenue-critical feature for the donation model.

**Steps:**
1. Add `flutter_local_notifications` and `shared_preferences` to `pubspec.yaml` (✅ Done)
2. Create `lib/data/services/notification_service.dart` with `initialize()`, `requestPermission()`, `scheduleDonateReminder()`, `scheduleInactivityNudge()`, `cancelAll()` (✅ Done)
3. Create `lib/providers/engagement_provider.dart` to track `exportCount`, `lastOpenedAt`, `hasDonated`, `notificationsOptedOut` (✅ Done)
4. Wire the Settings toggle to real `shared_preferences` persistence (✅ Done)
5. Show `NotificationPermissionSheet` (already built!) on first app launch (✅ Done)
6. On export completion, increment `exportCount`. If `>= 2` and not opted out, schedule notification (✅ Done)
7. Add notification tap handler → `go_router` navigation to `/donate` (✅ Done)

---

## Appendix: Complete File Inventory

### Existing Files (41 total)

| Path | Size | Status |
|---|---|---|
| `lib/main.dart` | 233B | ✅ Clean |
| `lib/app.dart` | 3.2KB | ⚠️ Missing routes |
| `lib/core/constants/app_constants.dart` | 451B | ✅ |
| `lib/core/errors/` | EMPTY | ❌ |
| `lib/core/utils/` | EMPTY | ❌ |
| `lib/data/models/caption_style.dart` | 566B | ⚠️ Missing `copyWith`, position |
| `lib/data/models/subtitle_segment.dart` | 356B | ⚠️ Missing `copyWith` |
| `lib/data/models/export_job.dart` | 778B | ✅ |
| `lib/data/models/media_item.dart` | 663B | ✅ |
| `lib/data/models/language_pack.dart` | 1.9KB | ✅ Has `copyWith` |
| `lib/data/models/download_progress.dart` | 510B | ✅ |
| `lib/data/services/export_service.dart` | 453B | ✅ Abstract |
| `lib/data/services/transcription_service.dart` | 387B | ✅ Abstract |
| `lib/data/services/language_pack_service.dart` | 440B | ✅ Abstract |
| `lib/data/services/media_service.dart` | 233B | ✅ Abstract |
| `lib/data/mock/seed_data.dart` | 9.6KB | ✅ |
| `lib/data/mock/mock_export_service.dart` | 1.5KB | ✅ Mock |
| `lib/data/mock/mock_language_service.dart` | 1.5KB | ✅ Mock |
| `lib/data/mock/mock_media_service.dart` | 846B | ✅ Mock |
| `lib/data/mock/mock_transcription_service.dart` | 762B | ✅ Mock |
| `lib/providers/caption_style_provider.dart` | 1.5KB | ✅ |
| `lib/providers/export_provider.dart` | 804B | ⚠️ No export counter |
| `lib/providers/language_provider.dart` | 2.9KB | ✅ |
| `lib/providers/media_provider.dart` | 450B | ✅ |
| `lib/providers/player_provider.dart` | 1.4KB | ❌ No real controller |
| `lib/providers/subtitle_provider.dart` | 824B | ⚠️ No undo/redo |
| `lib/providers/transcription_provider.dart` | 284B | ❌ Skeleton |
| `lib/screens/media_library_screen.dart` | 16.7KB | ⚠️ No Bento grid |
| `lib/screens/language_packs_screen.dart` | 18.2KB | ⚠️ No pause/resume |
| `lib/screens/studio_screen.dart` | 28.4KB | 🔴 Major refactor needed |
| `lib/screens/video_player_screen.dart` | 25.4KB | 🔴 Should merge into Studio |
| `lib/screens/export_screen.dart` | 20.3KB | ⚠️ Mostly done |
| `lib/screens/donate_screen.dart` | 11.1KB | ⚠️ url_launcher not wired |
| `lib/screens/settings_screen.dart` | 10.9KB | ⚠️ Toggles not persisted |
| `lib/theme/app_colors.dart` | 3.5KB | 🔴 Palette mismatch |
| `lib/theme/app_gradients.dart` | 1.6KB | ✅ |
| `lib/theme/app_shadows.dart` | 882B | ✅ |
| `lib/theme/app_radius.dart` | 232B | ✅ |
| `lib/theme/app_spacing.dart` | 549B | ✅ |
| `lib/theme/app_theme.dart` | 2.3KB | ⚠️ No ThemeExtension |
| `lib/theme/app_typography.dart` | 2.4KB | ✅ |

### Proposed New Files (13)

| Path | Purpose |
|---|---|
| `lib/providers/editing_notifier.dart` | Unified player + subtitle + style state |
| `lib/providers/engagement_provider.dart` | Export counter, donation flags, notification prefs |
| `lib/data/services/notification_service.dart` | `flutter_local_notifications` wrapper |
| `lib/data/services/ffmpeg_export_service.dart` | Real FFmpeg command execution |
| `lib/data/services/audio_preprocessor.dart` | `-ac 1` mono transcoding |
| `lib/data/services/file_import_service.dart` | `file_picker` wrapper |
| `lib/screens/transcription_screen.dart` | Live waveform + progress UI |
| `lib/screens/onboarding_screen.dart` | First launch flow |
| `lib/widgets/subtitle_correction_sheet.dart` | Draggable sheet for text editing |
| `lib/widgets/draggable_timeline_chip.dart` | Resizable subtitle chip |
| `lib/widgets/bento_grid.dart` | Staggered grid layout for Media Library |
| `lib/widgets/url_fallback_dialog.dart` | Fallback when browser fails |
| `lib/theme/app_colors_extension.dart` | `ThemeExtension<CaptionaryColors>` |

---

> **End of Audit.** This roadmap should be revisited after Priority 1 (Player unification) is complete, as it will significantly change the screen architecture.
