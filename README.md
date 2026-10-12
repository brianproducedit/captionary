# Captionary

> **Privacy-first, 100% on-device AI video captioning and subtitling studio for creators worldwide.**
> Built with Flutter (Android mobile app), React 19 (web portal), and Cloudflare R2 (serverless AI model CDN).

[![CI](https://github.com/brianproducedit/captionary/actions/workflows/ci.yml/badge.svg)](https://github.com/brianproducedit/captionary/actions/workflows/ci.yml)
[![Release APK](https://github.com/brianproducedit/captionary/actions/workflows/release.yml/badge.svg)](https://github.com/brianproducedit/captionary/actions/workflows/release.yml)
[![Web Portal](https://github.com/brianproducedit/captionary/actions/workflows/react.yml/badge.svg)](https://github.com/brianproducedit/captionary/actions/workflows/react.yml)
[![License: AGPL-3.0](https://img.shields.io/badge/License-AGPL--3.0-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)
[![Flutter](https://img.shields.io/badge/Flutter-3.47.1-02569B?logo=flutter)](https://flutter.dev)
[![React](https://img.shields.io/badge/React-19.2-61DAFB?logo=react)](https://react.dev)

---

## 📱 Download the Android Mobile App

Captionary is 100% open source and distributed directly via APK releases hosted on Cloudflare R2 and mirrored on GitHub Releases. **No Google Play Store account, fees, or device surveillance required.**

| Download Source | Link | Description |
|---|---|---|
| 🌐 **Web Download Portal** | [captionary.co.zw/download](https://captionary.brianproducedit.workers.dev/) | Live download page with automatic update detection, device tier guide & installation steps |
| 📦 **GitHub Releases** | [github.com/brianproducedit/captionary/releases](https://github.com/brianproducedit/captionary/releases/latest) | Direct APK downloads, checksums, and changelogs |

### Available APK Packages

| Package | Target Architecture | Size | Recommendation |
|---|---|---:|---|
| **`app-release.apk`** | **Universal** (all CPU types) | ~194 MB | **Recommended for all users**. Installs on 100% of Android phones. |
| **`app-arm64-v8a-release.apk`** | ARM 64-bit (`arm64-v8a`) | ~64 MB | Smaller file size, optimized for modern Android smartphones (2017+). |
| **`app-armeabi-v7a-release.apk`** | ARM 32-bit (`armeabi-v7a`) | ~78 MB | For older or entry-level 32-bit Android phones. |
| **`app-x86_64-release.apk`** | Intel/AMD 64-bit (`x86_64`) | ~72 MB | For Android emulators, ChromeOS Chromebooks, and PC tablets. |

### How to Install (Sideloading Guide)

1. **Download:** Tap **Download Universal APK** on your Android device. If your browser shows a prompt saying *"File might be harmful"*, tap **Download anyway**.
2. **Open:** Once downloaded, tap the file in your notification bar or find it in your **Files / Downloads** app.
3. **Allow Unknown Apps:** If Android security warns that your browser cannot install unknown apps, tap **Settings** and enable **"Allow from this source"**.
4. **Install:** Return to the installation dialog, tap **Install**, and launch Captionary!

### Verify Cryptographic Integrity

Each release includes a `SHA256SUMS.txt` cryptographic checksum file. Verify your downloaded APK with:

```bash
sha256sum -c SHA256SUMS.txt
```

---

## ✨ Features

### Core AI Engine
- 🔒 **100% On-Device AI Transcription:** Powered by native Whisper AI (`whisper_flutter_new`). Your video and audio **never** leave your phone — zero cloud uploads, zero internet required during transcription.
- 🧠 **Smart Caption Pipeline:** End-to-end orchestration from video import → audio extraction → Whisper transcription → word-level alignment → styled subtitle output, all within a single automated pipeline (`CaptionPipeline`).
- ⚡ **RAM Safety Engine:** 3-tier device memory classification (Low `<4GB`, Standard `4–6GB`, High `≥6GB`) with automatic OOM prevention guards. Whisper chunk sizes, thread counts, and model delegation are tuned per tier.

### Studio & Editing
- 🎨 **Subtitle Stylization Studio:** Full timeline editor with word-level alignments, split/merge segments, customizable font sizes (7pt–48pt), color pickers, and preset themes (TikTok Bold, IG Highlight, Karaoke, Minimal).
- ✏️ **Interactive Subtitle Correction:** Tap any segment to edit text, adjust timing, or correct AI transcription errors before export.
- 🎯 **Drag-to-Position Subtitles:** True bottom, center, top positioning with interactive drag handles in the preview viewport.

### Video Export
- 🎬 **Hardware-Accelerated Burn-in:** ASS and SRT subtitle embedding using FFmpeg with variable font support (Lexend). Two-pass fallback: ASS filter → SRT subtitles if libass is unavailable.
- 🔊 **Universal Audio Compatibility:** Audio is always transcoded to AAC (`-c:a aac -b:a 192k`), ensuring MP4 container compatibility regardless of source codec (PCM, Opus, AC3, Vorbis).
- 📁 **Clean Output Paths:** Export files use `{original_name}_captioned_{timestamp}.mp4` format, placed in the same directory as the source video. No double extensions or hardcoded filenames.
- ✅ **Export Completion Flow:** Full-featured export screen with Preview, Share, Done navigation, Pro upgrade teaser, and re-encode options.

### Language Packs & Model Management
- 🌐 **Serverless Language Packs:** Resumable, SHA-256 verified HTTP Range downloads from a public Cloudflare R2 bucket. Supports partial download resume after network interruption.
- 💾 **Uninstall-Persistent Models:** Downloaded Whisper models are stored in the public Android Downloads directory (`Download/Captionary/models/`), surviving app uninstallation. On reinstall, Captionary auto-detects existing model binaries and regenerates metadata without re-downloading.
- 📤 **Subtitle Export & Sharing:** Export styled ASS, SRT, or VTT files and share directly to social apps via the system share sheet.

### Infrastructure
- 📊 **Accurate Storage Accounting:** Settings screen shows real disk usage across temp audio, media cache, thumbnails, and model files — including models in the persistent public downloads directory.
- 🔔 **Local Notifications:** Scheduled and immediate notifications for download completions, export progress, and pipeline status updates.
- 📱 **AdMob Integration:** Non-intrusive banner ads with graceful fallback when ad SDK is unavailable.

---

## 🏛️ Project Architecture

### Monorepo Structure

```
captionary/
├── flutter_mobile/          # Flutter Android app (Dart)
│   ├── lib/
│   │   ├── core/            # Shared utilities, parsers, performance logger
│   │   ├── data/
│   │   │   ├── models/      # Immutable data models (ExportJob, SubtitleSegment, etc.)
│   │   │   ├── mock/        # In-memory mock services for development
│   │   │   └── services/    # 19 production services (see below)
│   │   ├── providers/       # Riverpod state management
│   │   ├── screens/         # 10 app screens
│   │   ├── theme/           # Colors, gradients, shadows, typography
│   │   └── widgets/         # 36 reusable UI components
│   ├── test/
│   │   ├── unit/            # 16+ unit test files
│   │   └── widget/          # Widget and integration tests
│   └── android/             # Android platform config & signing
├── react_frontend/          # React 19 + Vite web portal
│   └── src/
│       ├── components/      # UI components (Navbar, Hero, Download cards)
│       ├── pages/           # Download, Donate, Terms pages
│       ├── services/        # R2 release API client
│       └── config/          # Public configuration
├── scripts/                 # Release automation & R2 model upload scripts
├── r2/                      # Cloudflare R2 bucket configuration
├── .github/workflows/       # 5 CI/CD pipelines
│   ├── ci.yml               # Flutter test + analyze on every push
│   ├── release.yml          # Build, sign, upload to R2 + GitHub Releases
│   ├── react.yml            # Build & deploy web portal to Cloudflare Pages
│   ├── build-debug.yml      # Debug APK build
│   └── upload-models.yml    # Whisper model upload to R2
└── docs/                    # Documentation
```

### Key Services (Flutter)

| Service | Responsibility |
|---|---|
| `CaptionPipeline` | End-to-end orchestration: import → extract → transcribe → style → export |
| `WhisperTranscriptionService` | Native Whisper AI inference with chunked processing and concurrency lock |
| `FfmpegExportService` | ASS/SRT video burn-in with 2-pass fallback, atomic `.part` file rename |
| `R2LanguagePackService` | Resumable R2 downloads, SHA-256 verification, manifest caching, auto-recovery |
| `SystemMemoryService` | Device RAM classification for safe Whisper configuration |
| `StorageService` | Disk usage calculation across all cache and model directories |
| `AudioPreprocessor` | FFmpeg audio extraction and format normalization |
| `NotificationService` | Local notification scheduling for pipeline and download events |
| `FileImportService` | Video file import with validation and metadata extraction |
| `LocalMediaService` | On-device media library management with thumbnail generation |

### Serverless Architecture Boundary

Captionary is architected with strict zero-maintenance, serverless principles:
- **No Custom Backend Servers:** Zero Node.js, Python, Firebase, Supabase, or custom APIs.
- **On-Device Computation:** Audio extraction, Whisper transcription, subtitle styling, and video rendering happen entirely client-side.
- **Cloudflare R2 Model CDN:** Language model weights and the public `manifest.json` are served via S3-compatible, edge-cached Cloudflare R2 object storage.
- **Cloudflare Pages:** The React web portal is deployed as a static site on Cloudflare Pages with automatic deployments on push to `main`.
- **Dual APK Distribution:** Release APKs are uploaded to both Cloudflare R2 (primary, via `latest-release.json`) and GitHub Releases (backup mirror with `--clobber` support for re-releases).

---

## 🚀 CI/CD Pipeline

### Automated Release Flow

New releases are built, signed, and published automatically through GitHub Actions when a `v*.*.*` tag is pushed.

```
git tag → GitHub Actions → Build APKs → Sign → SHA256 checksums
                         → Upload to Cloudflare R2 (primary CDN)
                         → Publish/Update GitHub Release (backup)
                         → React portal auto-detects via latest-release.json
```

### Triggering a Release

**Option A: Release helper script (recommended):**
```powershell
.\scripts\create-release-tag.ps1 -Version 1.0.2 -Push
```

**Option B: Manual git commands:**
```bash
# 1. Update version in flutter_mobile/pubspec.yaml (e.g. version: 1.0.2+3)
# 2. Commit, tag, and push:
git commit -am "chore(release): v1.0.2"
git tag v1.0.2
git push origin main
git push origin v1.0.2
```

**Option C: Re-release an existing tag (force update):**
```bash
git tag -d v1.0.1          # Delete local tag
git tag v1.0.1             # Re-create on current commit
git push origin v1.0.1 --force
```

### What the Pipeline Produces

When a `v*.*.*` tag is pushed, the release pipeline automatically:
1. Validates the tag matches the `pubspec.yaml` version.
2. Builds the **Universal APK** and **Split-per-ABI APKs** (arm64-v8a, armeabi-v7a, x86_64).
3. Signs with the production keystore (or uses graceful debug signing if secrets are not configured).
4. Generates cryptographic checksums (`SHA256SUMS.txt`) and machine-readable metadata (`latest-release.json`).
5. Uploads all artifacts to **Cloudflare R2** (versioned path + `latest/` pointer).
6. **Creates or updates** the **GitHub Release** — if the release already exists, assets are replaced with `--clobber` instead of silently skipping.

> **Note:** The GitHub Release step was recently fixed to properly handle re-releases. Previously, force-pushing a tag would trigger the workflow but `gh release create` would silently fail if the release already existed, leaving stale 2-week-old APKs on the GitHub Releases page while R2 was correctly updated.

---

## 💻 Developer Quick Start

### Prerequisites

- [Flutter SDK 3.47.1+](https://flutter.dev/docs/get-started/install)
- [Node.js 22+](https://nodejs.org/) (for web portal and release scripts)
- Android SDK with Build Tools (for APK signing verification)
- An Android device or emulator for testing

### 1. Flutter Mobile App

```bash
cd flutter_mobile

# Install dependencies
flutter pub get

# Run in Development Mode (fast, in-memory mock engine — no Whisper/FFmpeg required)
flutter run --dart-define=BACKEND_MODE=mock

# Run in Production Mode (real on-device Whisper & FFmpeg on physical device)
flutter run --dart-define=BACKEND_MODE=local

# Run all tests
flutter test

# Static analysis
flutter analyze
```

#### Backend Modes

| Mode | Purpose | Requirements |
|---|---|---|
| `mock` | Fast development and UI iteration with synthetic data | Desktop or emulator, no native plugins needed |
| `local` | Full production pipeline with real Whisper + FFmpeg | Physical Android device, downloaded language model |
| `real` | Same as `local` (production alias) | Physical Android device |

### 2. React Web Portal

```bash
cd react_frontend

# Install dependencies
npm install

# Start local Vite development server
npm run dev

# Run linter and tests
npm run lint
npm run test

# Build production static bundle
npm run build
```

### 3. Release Scripts

```bash
cd scripts

# Upload Whisper models to Cloudflare R2
node upload_models.js

# Create and push a release tag
.\create-release-tag.ps1 -Version 1.0.2 -Push

# Verify repository secrets are configured
.\check-secrets.ps1
```

---

## 🧪 Test Coverage

The project maintains comprehensive test coverage across unit, service, and widget tests:

| Test Suite | Count | Coverage |
|---|---|---|
| **Unit Tests** | 40+ | Caption export formats, ASS watermarks, subtitle timeline, media queries, style models, duration formatting |
| **Service Tests** | 30+ | FFmpeg export (ASS/SRT fallback, cancellation, concurrency), Whisper transcription (chunking, memory guards), R2 downloads (resume, checksum, manifest), storage, audio preprocessing |
| **Widget Tests** | 15+ | Export screen states, stylization sheet, interaction audit, notification routing |

All tests pass with `flutter analyze` reporting **0 issues**.

---

## 🔐 Environment Configuration

| File | Purpose | Mode |
|---|---|---|
| `.env.development` | Local development and mock testing | `BACKEND_MODE=mock` |
| `.env.production` | Physical devices and release builds | `BACKEND_MODE=local` |
| `.env.example` | Reference template | — |

> [!IMPORTANT]
> **Zero-Secret Client Policy:**
> Client builds only consume public URLs (`R2_BASE_URL`, `MANIFEST_URL`, `DONATE_WEB_URL`). Cloudflare R2 upload keys are used exclusively for developer maintenance scripts (`scripts/upload_models.js`) and CI/CD pipelines and are **never** bundled into APKs or web assets.

### Required GitHub Repository Secrets

| Secret | Purpose |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | Base64-encoded production signing keystore |
| `ANDROID_KEY_ALIAS` | Keystore key alias |
| `ANDROID_KEY_PASSWORD` | Key password |
| `ANDROID_STORE_PASSWORD` | Keystore password |
| `R2_ACCESS_KEY_ID` | Cloudflare R2 access key |
| `R2_SECRET_ACCESS_KEY` | Cloudflare R2 secret key |
| `R2_ACCOUNT_ID` | Cloudflare account ID |
| `ADMOB_APP_ID` | Google AdMob application ID |
| `ADMOB_BANNER_ID` | AdMob banner unit ID |
| `CLOUDFLARE_API_TOKEN` | Cloudflare Pages deploy token |
| `CLOUDFLARE_ACCOUNT_ID` | Cloudflare account ID (for Pages) |

---

## 🗺️ Roadmap

### Achieved (v1.0.1)
- [x] On-device Whisper AI transcription with word-level alignment
- [x] Full subtitle stylization studio with timeline editor
- [x] Hardware-accelerated FFmpeg video burn-in (ASS + SRT fallback)
- [x] Resumable R2 language pack downloads with SHA-256 verification
- [x] RAM safety engine with 3-tier device classification
- [x] Uninstall-persistent model storage with auto-recovery
- [x] Universal AAC audio transcoding for MP4 compatibility
- [x] Clean export output paths (no double `.mp4` extensions)
- [x] Full export completion UX (Preview, Share, Done)
- [x] Automated CI/CD with dual R2 + GitHub Release publishing
- [x] Idempotent release pipeline (`--clobber` for re-releases)
- [x] React web portal with live R2 metadata and Cloudflare Pages deployment
- [x] `android:hasFragileUserData="true"` for user data preservation

### Planned
- [ ] iOS support (Flutter cross-platform)
- [ ] Multi-language simultaneous transcription
- [ ] Custom font upload and embedding
- [ ] Video trimming and cropping before export
- [ ] Batch processing for multiple videos
- [ ] Paynow / EcoCash mobile money integration for Pro plans
- [ ] Web Sync Code for cross-device license activation

---

## 📄 License

This project is licensed under the **GNU Affero General Public License v3.0 (AGPL-3.0)**. See [LICENSE](LICENSE) for details.
