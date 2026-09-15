# Captionary

> **On-device AI video captioning and subtitling app with a modern aesthetic.**
> Built with Flutter (Android mobile app) and React (web donation portal).

---

## ⚡ Quick Start: Testing & Running the App

### 1. Development Mode (Mock Data & Fast Reload)

In development mode, the app uses **`BACKEND_MODE=mock`**. All services (transcription, audio processing, language downloads, media library) use fast, in-memory mock implementations and sample seed data. **No native FFmpeg or Whisper models required.**

```bash
cd flutter_mobile

# Option A: Run directly (defaults to mock mode)
flutter run

# Option B: Run explicitly with mock flag
flutter run --dart-define=BACKEND_MODE=mock

# Option C: Run using the development env file
flutter run --dart-define-from-file=../.env.development
```

### 2. Production Mode (Real On-Device Engines)

In production mode, the app uses **`BACKEND_MODE=local`**. Real FFmpeg audio extraction/export, local storage caching, and on-device Whisper models are engaged.

```bash
cd flutter_mobile

# Run on a physical Android device:
flutter run --dart-define=BACKEND_MODE=local

# Run using the production env file:
flutter run --dart-define-from-file=../.env.production

# Build release APK:
flutter build apk --release --dart-define-from-file=../.env.production
```

The release APK will be generated at:
`flutter_mobile/build/app/outputs/flutter-apk/app-release.apk`

---

## 🧪 Testing

Run the automated test suite hermetically without platform dependencies:

```bash
cd flutter_mobile

# Run all unit and widget tests
flutter test

# Run code analysis
flutter analyze
```

---

## 🔐 Environment Configuration

Environment files are located at the repository root:
- `.env.development` — Default configuration for local development and testing (`BACKEND_MODE=mock`).
- `.env.production` — Production configuration for physical devices and release builds (`BACKEND_MODE=local`).
- `.env.example` — Reference template explaining each variable.

> [!IMPORTANT]
> **Zero-Secret Client Policy:**
> - The Flutter app only consumes public configuration variables: `BACKEND_MODE`, `R2_BASE_URL`, `MANIFEST_URL`, `DONATE_WEB_URL`.
> - R2 upload credentials (`R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`) are exclusively for developer maintenance scripts (`scripts/upload_models.js`) and must **never** be passed to `flutter build` or bundled in the client APK.

For detailed developer notes and architecture details, see [docs/DEVELOPMENT_GUIDE.md](file:///c:/Users/k.off/Documents/Programming/Programming%20Projects/Flutter/captionary/docs/DEVELOPMENT_GUIDE.md).

---

## 🌐 React Web Portal (Donations)

```bash
cd react_frontend

# Install dependencies
npm install

# Start development server
npm run dev

# Build production bundle
npm run build
```

---

## 📄 License

AGPL-3.0 License.
