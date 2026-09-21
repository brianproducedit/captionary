# Captionary

> **Privacy-first, on-device AI video captioning and subtitling studio for creators worldwide.**
> Built with Flutter (Android mobile app), React 19 (web portal), and Cloudflare R2 (serverless AI model CDN).

[![CI](https://github.com/brianproducedit/captionary/actions/workflows/ci.yml/badge.svg)](https://github.com/brianproducedit/captionary/actions/workflows/ci.yml)
[![Release APK](https://github.com/brianproducedit/captionary/actions/workflows/release.yml/badge.svg)](https://github.com/brianproducedit/captionary/actions/workflows/release.yml)
[![License: AGPL-3.0](https://img.shields.io/badge/License-AGPL--3.0-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)
[![Flutter](https://img.shields.io/badge/Flutter-3.47.1-02569B?logo=flutter)](https://flutter.dev)
[![React](https://img.shields.io/badge/React-19.2-61DAFB?logo=react)](https://react.dev)

---

## 📱 Download the Android Mobile App

Captionary is 100% open source and distributed directly via APK releases on GitHub and our official Web Portal. **No Google Play Store account, fees, or device surveillance required.**

| Download Source | Link | Description |
|---|---|---|
| 🌐 **Web Download Portal** | [captionary.co.zw/download](https://captionary.brianproducedit.workers.dev/) | Live download page with automatic update detection, device tier guide & installation steps |
| 📦 **GitHub Releases** | [github.com/brianproducedit/captionary/releases](https://github.com/brianproducedit/captionary/releases/latest) | Direct APK downloads, checksums, and changelogs |

### Available APK Packages

| Package | Target Architecture | Size | Recommendation |
|---|---|---:|---|
| **`app-release.apk`** | **Universal** (all CPU types) | ~184 MB | **Recommended for all users**. Installs on 100% of Android phones. |
| **`app-arm64-v8a-release.apk`** | ARM 64-bit (`arm64-v8a`) | ~60 MB | Smaller file size, optimized for modern Android smartphones (2017+). |
| **`app-armeabi-v7a-release.apk`** | ARM 32-bit (`armeabi-v7a`) | ~73 MB | For older or entry-level 32-bit Android phones. |
| **`app-x86_64-release.apk`** | Intel/AMD 64-bit (`x86_64`) | ~68 MB | For Android emulators, ChromeOS Chromebooks, and PC tablets. |

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

- 🔒 **100% On-Device AI:** Powered by native Whisper AI (`whisper_flutter_new`). Your video and audio never leave your phone.
- 🎨 **Studio Subtitle Stylization:** Timeline editor, word-level alignments, split/merge, customizable fonts, and preset themes (TikTok Bold, IG Highlight).
- 🎬 **Hardware-Accelerated Burn-in:** Pure ASS and SRT video subtitle embedding using FFmpeg with variable font support (`Lexend`).
- ⚡ **RAM Safety Engine (B11):** 3-tier memory classification (Low `<4GB`, Standard `4-6GB`, High `≥6GB`) with automatic OOM prevention guards.
- 🌐 **Serverless Language Packs:** Resumable, verified HTTP Range downloads from a public Cloudflare R2 bucket.
- 📤 **Subtitle Export & Sharing:** Export styled ASS, SRT, or VTT files and share directly to social apps.

---

## 🏛️ Serverless Architecture Boundary

Captionary is architected with strict zero-maintenance, serverless principles:
- **No Custom Backend Servers:** Zero Node.js, Python, Firebase, Supabase, or custom APIs.
- **On-Device Computation:** Audio extraction, Whisper transcription, subtitle styling, and video rendering happen entirely client-side.
- **Cloudflare R2 Model CDN:** Language model weights and the public `manifest.json` are served via S3-compatible, edge-cached Cloudflare R2 object storage.
- **Client-Side Live Updates:** The static React web portal automatically queries the GitHub Releases REST API with client-side caching to show the latest updates.

---

## 🚀 Automated CI/CD & Releases

New releases are built, signed, and published automatically through GitHub Actions (`.github/workflows/release.yml`).

### Triggering a Release

To release a new version of the app, simply run the included release helper script:

```powershell
# Bumps pubspec.yaml, commits, tags, and pushes to GitHub:
.\scripts\create-release-tag.ps1 -Version 1.0.0 -Push
```

Or manually via git commands:

```bash
# 1. Update version in flutter_mobile/pubspec.yaml (e.g. version: 1.0.0+2)
# 2. Commit and tag:
git commit -am "chore(release): v1.0.0"
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin main
git push origin v1.0.0
```

### What GitHub Actions Produces

When a `v*.*.*` tag is pushed, the release pipeline automatically:
1. Builds the **Universal APK** (`app-release.apk`).
2. Builds **Split-per-ABI APKs** (`arm64-v8a`, `armeabi-v7a`, `x86_64`).
3. Signs with your production keystore (or uses graceful debug signing if secrets are not configured).
4. Generates cryptographic checksums (`SHA256SUMS.txt`).
5. Generates machine-readable release metadata (`latest-release.json`).
6. Publishes a new **GitHub Release** with all assets and auto-generated release notes.

---

## 💻 Developer Quick Start

### 1. Flutter Mobile App

```bash
cd flutter_mobile

# Run in Development Mode (Fast, in-memory mock engine - no Whisper/FFmpeg required)
flutter run --dart-define=BACKEND_MODE=mock

# Run in Production Mode (Real on-device Whisper & FFmpeg on physical device)
flutter run --dart-define=BACKEND_MODE=local

# Run automated tests and analyzer
flutter test
flutter analyze
```

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

---

## 🔐 Environment Configuration

| File | Purpose | Mode |
|---|---|---|
| `.env.development` | Local development and mock testing | `BACKEND_MODE=mock` |
| `.env.production` | Physical devices and release builds | `BACKEND_MODE=local` |
| `.env.example` | Reference template | — |

> [!IMPORTANT]
> **Zero-Secret Client Policy:**
> Client builds only consume public URLs (`R2_BASE_URL`, `MANIFEST_URL`, `DONATE_WEB_URL`). Cloudflare R2 upload keys are used exclusively for developer maintenance scripts (`scripts/upload_models.js`) and are **never** bundled into APKs or web assets.

---

## 📄 License

This project is licensed under the **GNU Affero General Public License v3.0 (AGPL-3.0)**. See [LICENSE](LICENSE) for details.
