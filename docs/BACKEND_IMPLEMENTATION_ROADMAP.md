# Captionary Backend Implementation Roadmap

> **Repository:** `brianproducedit/captionary` (workspace snapshot inspected 2026-09-11)
>
> **Project:** Captionary, an offline-first Android captioning and creator suite for devices with 4 GB RAM.
>
> **Scope:** Replace mock backend behavior with real local media, transcription, model-download, export, notification, payment, and release integrations. GitHub Releases are the only distribution target in this roadmap. Play Store distribution is explicitly out of scope.
>
> **Execution rule:** Work top to bottom. Every checkbox is an independently verifiable task. Preserve the existing service contracts unless a contract-preserving adapter is added. Keep every mock implementation and select real versus mock implementations at Riverpod provider seams.

## Fixed Decisions

- [ ] Use `whisper_flutter_new`; do not evaluate or add another Whisper wrapper.
- [ ] Use GitHub Releases with signed APK artifacts; do not produce an AAB for this roadmap.
- [ ] Register Paynow as an individual merchant. Keep merchant credentials server-side in the Worker environment, not in the mobile APK.
- [ ] Use Firebase Cloud Messaging for server-initiated push. Use `flutter_local_notifications` for foreground display and local reminders.
- [ ] Use Cloudflare R2's S3-compatible API for upload tooling. The Flutter client downloads public model objects with `dio`.
- [ ] Treat all values embedded in a Flutter asset, including `.env`, as extractable public configuration. Never put a Paynow key, R2 secret, FCM server credential, or other server-only secret in a mobile `.env` asset.

## 0. Preconditions and Codebase Snapshot

### 0.1 Workspace facts

The workspace contains two applications:

- Flutter application: `flutter_mobile/`
- React donation portal: `react_frontend/`

The existing Section B in `docs/roadmap.md` is not an accurate implementation snapshot. It names `whisper_cpp_flutter_plus`, the retired/nonexistent generic `ffmpeg_kit_flutter_new` package, older notification versions, and a media_kit migration that has not been implemented. This file supersedes that Section B.

### 0.2 Existing abstract service contracts

Do not rename these files or change these public signatures. Implement adapters around them when a real service needs additional methods.

| Interface | Existing public contract |
|---|---|
| `flutter_mobile/lib/data/services/media_service.dart` | `Future<List<MediaItem>> getRecentMedia()`; `Future<MediaItem?> importVideo()`; `Future<void> deleteMedia(String id)`; `Future<MediaItem> getMediaById(String id)` |
| `flutter_mobile/lib/data/services/language_pack_service.dart` | `Future<List<LanguagePack>> getAvailableLanguages()`; `Future<LanguagePack> getActiveLanguage()`; `Stream<DownloadProgress> downloadLanguagePack(String code)`; `Future<void> deleteLanguagePack(String code)`; `Future<String> detectLanguage(String audioPath)`; `double getStorageUsedGB()`; `double getStorageTotalGB()` |
| `flutter_mobile/lib/data/services/transcription_service.dart` | `Future<List<SubtitleSegment>> transcribeAudio({required String audioPath, required String languageCode, required String modelPath})`; `Stream<SubtitleSegment> transcribeAudioStream({required String audioPath, required String languageCode, required String modelPath})` |
| `flutter_mobile/lib/data/services/export_service.dart` | `Stream<ExportJob> burnCaptions({required String videoPath, required List<SubtitleSegment> segments, required CaptionStyle style, required String outputPath, required Duration videoDuration})`; `Future<String> exportSRT(List<SubtitleSegment> segments)`; `Future<String> exportVTT(List<SubtitleSegment> segments)` |

Additional concrete services already exist and must be accounted for:

| Existing service | Current responsibility |
|---|---|
| `flutter_mobile/lib/data/services/audio_preprocessor.dart` | Calls `ffmpeg_kit_flutter_new_min_gpl` to create mono 16 kHz PCM WAV in the temporary directory. |
| `flutter_mobile/lib/data/services/file_import_service.dart` | Picks a video with `file_picker`, copies it to a temporary media cache, and clears that cache. |
| `flutter_mobile/lib/data/services/local_media_service.dart` | Real `MediaService` implementation using file import and FFprobe metadata. Its in-memory list is not persistent. |
| `flutter_mobile/lib/data/services/ffmpeg_export_service.dart` | Real `ExportService` implementation. It currently creates SRT and burns it with FFmpeg's `subtitles` filter; it does not yet generate ASS styling. |
| `flutter_mobile/lib/data/services/ffmpeg_metadata_service.dart` | Reads duration, resolution, and size through FFprobe. |
| `flutter_mobile/lib/data/services/notification_service.dart` | Real local notification singleton with timezone initialization, Android channels, one-shot inexact scheduling, and payload callback. |

### 0.3 Mock services and current provider wiring

| Mock service | Provider seam | Current state |
|---|---|---|
| `flutter_mobile/lib/data/mock/mock_media_service.dart` | `mediaServiceProvider` in `providers/media_provider.dart` | Provider currently uses `LocalMediaService`, not the mock. |
| `flutter_mobile/lib/data/mock/mock_language_service.dart` | `languageServiceProvider` in `providers/language_provider.dart` | Mock-backed. |
| `flutter_mobile/lib/data/mock/mock_transcription_service.dart` | `transcriptionServiceProvider` in `providers/transcription_provider.dart` | Mock-backed. |
| `flutter_mobile/lib/data/mock/mock_export_service.dart` | No current default provider use | `exportServiceProvider` currently uses real `FfmpegExportService`. |
| `flutter_mobile/lib/data/mock/seed_data.dart` | Used by mock services | Keep for tests and offline/demo mode. |

Other provider facts:

- [ ] Add an explicit `backendModeProvider` or equivalent configuration provider with `mock`, `local`, and `real` modes.
- [ ] Ensure tests can override each service provider with a mock without constructing platform plugins.
- [ ] Dispose subscriptions and platform resources in provider `ref.onDispose` callbacks.
- [ ] Replace the current transcription provider's hard-coded `'en'` and `'dummy_model.bin'` values with selected language/model state.
- [ ] Make notification navigation use the app's router instead of only logging the payload in `main.dart`.

### 0.4 Current pinned dependencies

Flutter package versions read from `flutter_mobile/pubspec.yaml`:

| Package | Pinned constraint | Roadmap use |
|---|---:|---|
| `go_router` | `^18.0.1` | Existing navigation and notification/deep-link routing. |
| `flutter_riverpod` | `^2.6.1` | Existing DI and state. |
| `riverpod_annotation` | `^2.6.1` | Existing code generation dependency. |
| `file_picker` | `^12.2.0` | Existing media import. |
| `ffmpeg_kit_flutter_new_min_gpl` | `^2.6.2` | Existing extraction, metadata, and export. Keep it. |
| `path_provider` | `^2.1.6` | Local model/temp/output paths. |
| `path` | `^1.9.1` | Safe path composition. |
| `video_player` | `^2.14.0` | Currently present and must be evaluated before removal. |
| `share_plus` | `^13.3.0` | Existing export sharing. |
| `flutter_local_notifications` | `^22.3.0` | Existing local notification service. |
| `shared_preferences` | `^2.5.5` | Existing preferences and provider override. |
| `timezone` | `^0.11.1` | Existing notification scheduling. |
| `audio_waveforms` | `^2.0.2` | Existing UI dependency; verify actual use before retaining/removing. |
| `url_launcher` | `^6.3.2` | Existing external donation links. |

### 0.5 Known gaps and inconsistencies

- [ ] Create a root `.gitignore`; none was present at inspection time.
- [ ] Create `.env.example`; no root environment template was present.
- [ ] Create `.github/workflows/`; no workflow directory was present.
- [ ] Add `flutter_dotenv`, `dio`, `crypto`, `permission_handler`, `firebase_core`, `firebase_messaging`, and `google_mobile_ads` only in the phases that require them.
- [ ] Resolve the placeholder `https://pub-xxxx.r2.dev` in `AppConstants`; load the public URL from non-secret configuration.
- [ ] Resolve the difference between `https://captionary.co.zw/donate` in Flutter constants and the React portal's actual deployment URL. Use one canonical `DONATE_WEB_URL`.
- [ ] Replace the comment and user-facing wording that say “support” where the product decision is “donate”.
- [ ] Add persistent media metadata if recent media must survive an app restart; the current local service keeps only an in-memory list.
- [ ] Add cancellation to audio extraction and export. The current `AudioPreprocessor` has no cancellation token.
- [ ] Validate that `FFmpegKit` GPL licensing and the app's own licensing/distribution plan are compatible before release.
- [ ] Verify the Flutter SDK version installed in CI. `pubspec.yaml` declares Dart `^3.13.1` but no exact Flutter SDK version.
- [ ] Do not mark the application “mock mode complete” until the actual current screens and tests have been checked; the roadmap's completion claims are not evidence.

### 0.6 Baseline checks

- [ ] From `flutter_mobile/`, run `flutter pub get`.
- [ ] From `flutter_mobile/`, run `dart format --set-exit-if-changed lib test` and record existing failures before changing code.
- [ ] From `flutter_mobile/`, run `flutter analyze` and save the baseline output.
- [ ] From `flutter_mobile/`, run `flutter test --coverage` and save the baseline output.
- [ ] From `react_frontend/`, run `npm ci`, `npm run build`, and `npm run lint`.
- [ ] Record every baseline failure as an issue before beginning integration work.

## 1. Branching, Git Hygiene, and Repository Setup

- [ ] Initialize or connect the workspace to the intended Git repository before using branch protections.
- [ ] Protect `main`; require pull requests, passing required checks, and no direct pushes.
- [ ] Create `develop` as the integration branch.
- [ ] Use `feature/<short-name>` for features, `fix/<short-name>` for fixes, and `release/<semver>` for release preparation.
- [ ] Use Conventional Commits: `feat`, `fix`, `docs`, `refactor`, `test`, `build`, `ci`, `chore`, and `perf` with optional scopes such as `flutter`, `react`, `r2`, `paynow`, and `fcm`.
- [ ] Add `.github/pull_request_template.md` containing summary, tests, screenshots/device matrix, environment changes, migration notes, and rollback notes.
- [ ] Add `.github/ISSUE_TEMPLATE/bug_report.yml` and `feature_request.yml`.
- [ ] Add a root `.gitignore` covering `.env`, `.env.*` except `.env.example`, Flutter `.dart_tool/`, `build/`, Android local properties/keystores, Node `node_modules/`, React `dist/`, logs, IDE files, and generated Firebase secrets.
- [ ] Add `.env` to `.gitignore` before creating any real environment file.
- [ ] Add `.env.example` with placeholders and comments for every key in Appendix B.
- [ ] Add a CI guard that fails when a staged or changed file is named `.env` or matches a private key/credential pattern.
- [ ] Add a local pre-commit hook or documented `pre-commit` configuration running the same secret guard.
- [ ] Decide and document Git LFS status: never commit Whisper `.bin` models larger than 50 MB; store them in R2.
- [ ] Add labels: `feature`, `bug`, `backend`, `flutter`, `react`, `ci-cd`, `r2`, `transcription`, `video`, `ffmpeg`, `notifications`, `fcm`, `payments`, `security`, `performance`, `documentation`, and `blocked`.

### Environment policy

- [ ] Keep client-safe values such as a public R2 base URL, manifest URL, donation URL, feature flags, and AdMob application/unit IDs in build configuration.
- [ ] Keep Paynow integration keys, R2 access keys, FCM HTTP v1 service-account credentials, and Worker secrets in GitHub/Cloudflare secrets only.
- [ ] Do not add `.env` as a Flutter asset when it contains a secret. If `flutter_dotenv` is used for public configuration, document that it is not a secret store.
- [ ] For local scripts, load `.env` from the repository root with a Node/Python dotenv library and fail if a required upload secret is missing.

## 2. CI/CD on GitHub Actions

Use the Flutter package root `flutter_mobile/` as the working directory and `react_frontend/` as the Node package root.

### 2.1 Pull-request checks: `.github/workflows/ci.yml`

- [ ] Trigger on `pull_request` targeting `main` or `develop` and on manual dispatch.
- [ ] Pin action versions or commit SHAs according to the repository security policy.
- [ ] Check out the repository with `actions/checkout`.
- [ ] Install the Flutter version compatible with the Dart constraint using `subosito/flutter-action@v2`; record the exact version in CI configuration.
- [ ] Enable Flutter/pub caching and Gradle caching.
- [ ] Run `flutter pub get` in `flutter_mobile/`.
- [ ] Run `dart format --set-exit-if-changed lib test`.
- [ ] Run `flutter analyze`.
- [ ] Run `flutter test --coverage`.
- [ ] Upload `flutter_mobile/coverage/lcov.info` as an artifact.
- [ ] Run the `.env` and credential scan.
- [ ] Run `npm ci`, `npm run build`, and `npm run lint` in `react_frontend/`.
- [ ] Do not require live Paynow, R2, Firebase, or AdMob credentials for pull-request checks.

### 2.2 Debug APK: `.github/workflows/build-debug.yml`

- [ ] Trigger on pushes to `develop` and manual dispatch.
- [ ] Run Flutter setup, `flutter pub get`, and `flutter build apk --debug --split-per-abi`.
- [ ] Upload `flutter_mobile/build/app/outputs/flutter-apk/*.apk` as an artifact.
- [ ] Name artifacts with commit SHA and ABI.

### 2.3 GitHub Release APK: `.github/workflows/release.yml`

- [ ] Trigger on tags matching `v*.*.*` and manual dispatch with a tag input.
- [ ] Check that the tag equals `flutter_mobile/pubspec.yaml` version before building.
- [ ] Decode `ANDROID_KEYSTORE_BASE64` into a temporary file on the runner.
- [ ] Write an untracked `key.properties` file from GitHub secrets.
- [ ] Build signed release APKs with `flutter build apk --release --split-per-abi`.
- [ ] Generate SHA256 checksums for each APK.
- [ ] Create a GitHub Release with generated notes from Conventional Commits.
- [ ] Attach APKs and checksum files to the release using a supported release action or GitHub CLI.
- [ ] Delete temporary signing files in a final cleanup step.
- [ ] Do not build or attach an AAB in this roadmap.

### 2.4 Android signing

- [ ] Generate a release keystore outside the repository: `keytool -genkeypair -v -keystore captionary-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias captionary`.
- [ ] Base64 encode the keystore without line wrapping; on PowerShell use `[Convert]::ToBase64String([IO.File]::ReadAllBytes('captionary-release.jks'))`.
- [ ] Store only these secret names in GitHub, never their values in the repository: `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`, `ANDROID_STORE_PASSWORD`.
- [ ] Configure `flutter_mobile/android/key.properties` generation in CI only.
- [ ] Change the release signing configuration from the current debug signing config.
- [ ] Verify the release APK signature with `apksigner verify --verbose <apk>`.

### 2.5 React portal CI and Cloudflare Pages

- [ ] Run `npm ci` and `npm run build` for every React pull request.
- [ ] Add a production workflow on pushes to `main` or manual dispatch.
- [ ] Deploy `react_frontend/dist` to Cloudflare Pages using the chosen Cloudflare Pages/Wrangler action.
- [ ] Store `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID`, and `CLOUDFLARE_PAGES_PROJECT` as GitHub secrets/variables.
- [ ] Configure SPA fallback so `/donate`, `/about`, and `/payment-confirmation` resolve to the app entry point.
- [ ] Run a post-deploy smoke check against the canonical portal URL.

### 2.6 Versioning and release notes

- [ ] Use semantic versions in `flutter_mobile/pubspec.yaml` as `MAJOR.MINOR.PATCH+BUILD`.
- [ ] Require a version bump PR before a release tag.
- [ ] Keep React `package.json` version synchronized with the portal release when portal changes ship with the app.
- [ ] Generate release notes with sections: Added, Changed, Fixed, Security, and Known limitations.
- [ ] Include APK ABI, SHA256, minimum Android SDK, and known offline limitations in each release.

## 3. Cloudflare R2 Setup and Manifest Contract

### 3.1 Bucket and public delivery

- [ ] Create an R2 bucket named `captionary-models`.
- [ ] Use a custom production domain for production model delivery; treat `r2.dev` as development-only because Cloudflare documents rate limiting and non-production intent for public development URLs.
- [ ] Enable public read access only for model objects and `manifest.json`.
- [ ] Do not expose the S3 endpoint or upload credentials to the mobile app.
- [ ] Configure CORS for the actual React/portal origins and local development origins; avoid `AllowedOrigins: ["*"]` for browser uploads.
- [ ] Permit `GET` and `HEAD` for public client downloads and expose `Content-Length`, `ETag`, and checksum headers only if the client needs them.
- [ ] Verify `HEAD`, full `GET`, and byte-range `GET` responses using `curl`.

### 3.2 Object layout

```text
captionary-models/
  manifest.json
  checksums.sha256
  models/
    ggml-tiny.en.bin
    ggml-tiny.bin
    ggml-base.bin
    ggml-small.q5_0.bin
    <language-specific files only after validation>
```

- [ ] Never publish a model until it has a source URL, exact byte size, SHA256, license, engine compatibility, and tested device tier.
- [ ] Keep model files out of Git and out of the Flutter asset bundle except the intentionally bundled tiny model.

### 3.3 Frozen `manifest.json` contract

The manifest is a public, versioned JSON document. Unknown fields may be added only compatibly; existing fields cannot change meaning.

```json
{
  "schema_version": 1,
  "catalog_version": 1,
  "updated_at": "2026-09-11T00:00:00Z",
  "base_url": "https://models.example.com/",
  "default_language": "en",
  "models": [
    {
      "id": "tiny.en",
      "engine": "whisper_flutter_new",
      "file": "models/ggml-tiny.en.bin",
      "language_codes": ["en"],
      "display_name": "English Tiny",
      "size_bytes": 75300000,
      "sha256": "64-lowercase-hex-characters",
      "quantization": "none",
      "bundled": true,
      "min_android_sdk": 21,
      "recommended_ram_gb": 4,
      "license": "MIT",
      "source_url": "https://huggingface.co/ggerganov/whisper.cpp"
    }
  ]
}
```

- [ ] Validate `schema_version` before parsing.
- [ ] Require non-empty `id`, `engine`, `file`, `language_codes`, `size_bytes`, `sha256`, and `source_url`.
- [ ] Require exactly 64 lowercase hexadecimal SHA256 characters.
- [ ] Reject negative or implausibly large `size_bytes` values.
- [ ] Reject path traversal and absolute paths in `file`.
- [ ] Cache the last valid manifest and use it offline when the network fails.
- [ ] Show a stale-catalog state rather than silently treating an unavailable model as installed.

### 3.4 Upload script

- [ ] Create `scripts/upload_models.js` or `scripts/upload_models.py`; prefer Node if the React tooling is the maintained scripting environment.
- [ ] Read `R2_ACCOUNT_ID`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `R2_BUCKET`, and `R2_PUBLIC_BASE_URL` from a local untracked `.env` or CI environment.
- [ ] Use the S3 endpoint `https://<ACCOUNT_ID>.r2.cloudflarestorage.com` and region `auto`.
- [ ] Walk a local `models/` input directory without following unsafe symlinks.
- [ ] Compute SHA256 and byte size before upload.
- [ ] Upload to a temporary key, verify the upload with `HEAD`, then publish/update `manifest.json`.
- [ ] Set `Content-Type: application/octet-stream` for models and `application/json` for the manifest.
- [ ] Generate `checksums.sha256` in stable sorted order.
- [ ] Abort rather than overwrite a model whose checksum differs unless `--replace` is explicitly passed.
- [ ] Add `--dry-run`, `--manifest-only`, and `--verify` modes.
- [ ] Add unit tests for hashing, path mapping, and missing credentials.

### 3.5 Plain public bucket versus Worker

- [ ] Use plain public object delivery for model downloads and the public manifest. This keeps downloads cacheable and avoids putting an unnecessary Worker in the hot path.
- [ ] Use a Cloudflare Worker only for Paynow initiation/webhook handling, FCM sending, optional signed admin operations, or a future controlled model API.
- [ ] Do not use a Worker to hide public model files; public files are intentionally public.

### 3.6 Budget guardrails

- [ ] Record the R2 storage and operation allowance currently applicable to the account; do not hard-code historical free-tier numbers without checking the billing page.
- [ ] Add a monthly script that reports object count, total model bytes, and estimated operation volume.
- [ ] Fail CI if the published catalog exceeds the project storage budget agreed in an issue.
- [ ] Configure Cloudflare billing/usage alerts where available.
- [ ] Keep at least 20 percent storage headroom for replacement models and manifests.

### Sources

- [ ] Review https://developers.cloudflare.com/r2/buckets/public-buckets/ for public access and `r2.dev` limitations.
- [ ] Review https://developers.cloudflare.com/r2/buckets/cors/ for exact CORS rules and origin syntax.
- [ ] Review https://developers.cloudflare.com/r2/api/s3/api/ for S3 compatibility, `auto` region, range reads, and multipart behavior.
- [ ] Review https://developers.cloudflare.com/workers/ for Worker deployment and secret bindings.

## 4. Phase B1: Real Video Player

### Decision: keep `video_player` initially, migrate only if acceptance tests fail

`video_player` 2.14.0 is already present, maintained by Flutter, and uses ExoPlayer on Android. It covers local playback, play/pause, seeking, speed, volume, and a Flutter `Stack` can provide the subtitle overlay. `media_kit` offers broader codecs, hardware acceleration, custom controls, external subtitle tracks, and subtitle styling, but its current package set is version-sensitive and increases native surface area. Therefore:

- [ ] Keep `video_player` for the first real-player implementation to minimize migration risk.
- [ ] Build an acceptance matrix for required containers/codecs, frame-accurate seeking, hardware decoding, subtitle overlay, and 4 GB memory use.
- [ ] Migrate to `media_kit` only if `video_player` fails a required acceptance test on a target device.
- [ ] If migration is approved, use the current compatible versions from pub.dev: `media_kit: ^1.2.6`, `media_kit_video: ^2.0.1`, and the current Android video library package recommended by the media-kit installation page. ⚠️ VERIFY ONLINE the exact Android package/version before editing `pubspec.yaml`; the old roadmap's `media_kit_libs_android_video: ^1.3.8` is not the current video installation snippet.

### Implementation

- [ ] Add a `MediaPlayerService` abstraction separate from `MediaService` so the existing media import contract does not become a player contract.
- [ ] For `video_player`, create and dispose `VideoPlayerController.file` only for the active video.
- [ ] Expose play, pause, seek, playback speed, volume, position, duration, buffering, and error state through a Riverpod notifier.
- [ ] Pause and dispose the controller when the player screen is removed or app lifecycle becomes paused.
- [ ] Use a stable `AspectRatio` and a `Stack` containing the video, subtitle overlay, and controls.
- [ ] Wire `file_picker` selection through the existing `FileImportService`, then persist/copy the selected file before opening it.
- [ ] Reject missing, unreadable, zero-byte, and unsupported files with user-visible retry states.
- [ ] Add a file import test using a small fixture or a fake `MediaPlayerService`; do not require a real platform texture in unit tests.
- [ ] Add a manual device test for local MP4 playback, pause, seek, speed, volume, rotation/lifecycle, and subtitle overlay.
- [ ] Remove `video_player` only after the migration acceptance suite passes on at least one physical target device.

### Sources

- [ ] Review https://pub.dev/packages/video_player for current APIs, Android ExoPlayer behavior, supported SDK, and controller disposal.
- [ ] Review https://pub.dev/packages/media_kit and https://pub.dev/packages/media_kit_video only if the migration gate is triggered.

## 5. Phase B2: FFmpeg Audio Extraction

- [ ] Keep `ffmpeg_kit_flutter_new_min_gpl: ^2.6.2`; do not add the nonexistent generic package name from the old roadmap.
- [ ] Rename or wrap `AudioPreprocessor` as the implementation behind a new `AudioExtractionService` if a clearer abstraction is needed.
- [ ] Use the exact command: `-y -i "<input>" -vn -acodec pcm_s16le -ar 16000 -ac 1 "<output.wav>"`.
- [ ] Quote/escape paths through a dedicated argument builder; do not interpolate untrusted filenames without escaping.
- [ ] Store output below `getTemporaryDirectory()/audio/` with a UUID-based filename.
- [ ] Support a `Duration` limit for the 30-second language-detection sample using `-t 30`.
- [ ] Add cancellation using FFmpeg session cancellation and a cancellation token owned by the pipeline.
- [ ] Run long extraction work asynchronously and never block the UI isolate with file reads or large buffers.
- [ ] Delete temporary audio in `finally`, including failure and cancellation paths.
- [ ] Add a WAV header/sample-rate/channel validation test using a generated fixture.
- [ ] Add a physical-device test for MP4, MOV, no-audio, corrupt-input, and long-video cases.
- [ ] Document that Android media access uses SAF/file picker URIs; do not add obsolete broad storage permissions solely for picker-selected files.

## 6. Phase B3: Whisper On-Device Transcription (`whisper_flutter_new`)

### Fixed package and verified facts

- [ ] Add `whisper_flutter_new: ^1.0.1` unless `flutter pub outdated` identifies a compatible newer stable version at implementation time.
- [ ] Use its documented `Whisper(model: WhisperModel.<model>, downloadHost: ...)` constructor and `transcribe(transcribeRequest: TranscribeRequest(...))` API.
- [ ] Treat exact model enum members, result object fields, and any language-detection API as version-sensitive. ⚠️ VERIFY ONLINE against https://pub.dev/documentation/whisper_flutter_new/latest/ and the package README immediately before implementation.
- [ ] Do not invent a `detect_language()` Dart method. If the package does not expose language detection, use its documented lower-level option if present; otherwise create a tracked limitation and use an explicit user language selection fallback.
- [ ] Note the package license (GPL-3.0) and obtain a release/legal decision before shipping it with the GPL FFmpeg package.

### Models and RAM

Official whisper.cpp memory figures are approximate peak/runtime figures, not APK file sizes: tiny 75 MiB model / approximately 273 MB runtime, base 142 MiB / approximately 388 MB, small 466 MiB / approximately 852 MB, medium 1.5 GiB / approximately 2.1 GB, and large 2.9 GiB / approximately 3.9 GB.

- [ ] Bundle only `ggml-tiny.en.bin` if the product accepts English as the offline first-run model; record its real SHA256 and size in the manifest.
- [ ] Download multilingual models from R2 after manifest verification; do not bundle unvalidated large models.
- [ ] Use tiny/base for 4 GB devices and make small an opt-in recommendation only after device testing.
- [ ] Use Q5_0 for reduced storage/RAM when a compatible model is validated; use Q8_0 when quality is more important and the device budget allows it.
- [ ] Record measured peak RSS/native memory for each model rather than promising a theoretical value.
- [ ] Load one model at a time, process sequentially, and unload it in `finally`.
- [ ] Add a model lock so two transcription requests cannot load two native model instances.

### Service implementation

- [ ] Implement a real `TranscriptionService` adapter without changing the existing interface.
- [ ] Copy bundled assets to an application-support path before passing a filesystem path to the package if the package requires a file path.
- [ ] Use `TranscribeRequest` with timestamps enabled; use word splitting only when the package version supports it and memory tests pass.
- [ ] Convert the package result into `SubtitleSegment` objects with a deterministic index and chunk offset.
- [ ] Implement `transcribeAudioStream` by emitting parsed segments as they become available; if the package only returns a complete string, emit parsed segments after completion and document that streaming is simulated at the adapter boundary.
- [ ] Use a 30-second chunk size with a small overlap to avoid word loss at boundaries.
- [ ] Merge chunks by adding the chunk start offset, sorting by start time, removing exact duplicates, and clamping invalid intervals.
- [ ] Keep language code selection explicit. Whisper language codes must be validated against the manifest and package support.
- [ ] Add tests for model-path errors, empty audio, cancellation, unload-on-error, timestamp parsing, and chunk merge.
- [ ] Add a physical-device transcription test with a short licensed fixture and record model, device RAM, elapsed time, and peak memory.

### Sources

- [ ] Review https://pub.dev/packages/whisper_flutter_new and https://pub.dev/documentation/whisper_flutter_new/latest/.
- [ ] Review https://github.com/ggml-org/whisper.cpp for GGML format, model memory figures, quantization, timestamps, and language behavior.
- [ ] Review https://github.com/ggml-org/whisper.cpp/blob/master/models/README.md for current model names and conversion details.

## 7. Phase B4: R2 Language Pack Downloads

- [ ] Add `dio: ^5.11.1` and `crypto` at the latest compatible stable version after `flutter pub outdated`.
- [ ] Fetch `manifest.json` with `dio.get`, a finite timeout, and a cached-manifest fallback.
- [ ] Build model URLs by resolving the manifest's validated relative `file` against the configured public base URL.
- [ ] Download to `<model>.part`, not the final filename.
- [ ] If a `.part` file exists, send `Range: bytes=<current>-` and verify the server returns `206 Partial Content`; restart from zero if the server returns a full `200` response.
- [ ] Stream bytes to disk rather than holding a model in memory.
- [ ] Report downloaded bytes, total bytes, speed, and state through `DownloadProgress`.
- [ ] Support `CancelToken` cancellation and preserve the partial file for resume.
- [ ] Compute SHA256 from the final file and compare with the manifest; delete the final file on mismatch and preserve diagnostic metadata.
- [ ] Atomically rename `.part` to the final model name only after checksum success.
- [ ] Store install metadata, manifest version, checksum, and last verification time in JSON under the application support directory.
- [ ] Implement delete with metadata cleanup and storage recalculation.
- [ ] Make the language screen show cached data offline and explain when a model cannot be downloaded.
- [ ] Add tests for manifest parsing, range resume, full-response fallback, cancellation, checksum mismatch, atomic rename, and offline cache.

### Sources

- [ ] Review https://pub.dev/packages/dio for `Dio.download`, `Options.headers`, progress callbacks, `CancelToken`, and `DioException`.
- [ ] Review Cloudflare R2 public bucket and S3 API sources listed in Section 3.

## 8. Phase B5: Caption Pipeline Orchestration

Define a typed state machine; do not use arbitrary UI strings as state.

```text
idle -> importing -> extracting -> detecting -> checkingModel -> downloadingModel
     -> transcribing -> merging -> ready -> error/cancelled
```

- [ ] Add `CaptionPipelineState` with state, progress, current file, language, model, error, and cancellation metadata.
- [ ] Add a `CaptionPipeline` service that composes media, extraction, language, model, and transcription services.
- [ ] Ensure every state has a UI hook in the player/studio screen.
- [ ] Delete temporary audio and failed output files in `finally`.
- [ ] Prevent concurrent pipeline runs for the same media item.
- [ ] Persist resumable model downloads, but do not pretend audio transcription is resumable unless the chunk checkpoint is valid.
- [ ] Connect `Re-align AI` to the real pipeline, selected language, and selected model.
- [ ] Add provider overrides for an all-mock pipeline and a fake failure at every state.
- [ ] Add integration tests for success, offline cached model, missing model, network failure, transcription failure, cancellation, and cleanup.

## 9. Phase B6: Burn-In Engine

The existing export service currently burns SRT with the `subtitles` filter. This phase replaces that implementation with a generated ASS file for styled captions.

- [ ] Add a pure `AssFileWriter` with a fixed script header, PlayRes, style line, and dialogue events.
- [ ] Escape ASS special characters and line breaks correctly.
- [ ] Convert Flutter colors/opacity to ASS `&HAABBGGRR` format.
- [ ] Map Lexend to the installed/bundled font strategy and verify the Android FFmpeg build can access the font. If not, render the font file through a documented `fontsdir`/font attachment strategy. ⚠️ VERIFY ONLINE against the exact FFmpegKit package capabilities.
- [ ] Implement style presets for TikTok Bold, IG Highlight, Classic Movie, and Neon Flow without promising unsupported animation semantics.
- [ ] Use a generated ASS command with a safe filter path, for example `-y -i "<video>" -vf "ass=<escaped-ass>" -c:v libx264 -crf 23 -preset fast -c:a copy "<output>"`.
- [ ] Probe available encoders before selecting a hardware encoder; fall back to software `libx264` when unavailable.
- [ ] Parse FFmpeg statistics against real input duration; never hard-code `1080x1920` or progress values.
- [ ] Make output writing atomic and reject output equal to input.
- [ ] Add cancellation and cleanup for ASS, temporary files, and partial output.
- [ ] Add unit tests for ASS syntax, color conversion, escaping, command construction, and progress conversion.
- [ ] Add manual tests on at least one 4 GB Android device for portrait and landscape videos.

## 10. Phase B7: SRT, VTT, and ASS Export

- [ ] Keep `exportSRT` and `exportVTT` signatures unchanged.
- [ ] Ensure SRT uses `HH:MM:SS,mmm`, 1-based sequential indexes, blank-line separation, and normalized line endings.
- [ ] Ensure VTT begins with `WEBVTT`, uses `HH:MM:SS.mmm`, and does not emit negative or reversed intervals.
- [ ] Add an ASS export path as a new adapter method without changing the abstract contract.
- [ ] Save files through a user-selected SAF/file-picker location where platform support permits; do not assume a hard-coded Downloads path exists.
- [ ] Use `share_plus` with a real temporary file URI, MIME type, and filename.
- [ ] Show success only after the write/share preparation succeeds.
- [ ] Add golden tests that open in a strict parser or compare exact expected output.
- [ ] Test empty segments, Unicode text, long durations, overlapping segments, and invalid intervals.

## 11. Phase B8: AdMob Live Ads

- [ ] Add the current compatible `google_mobile_ads` version after checking pub.dev and the Flutter SDK constraint. ⚠️ VERIFY ONLINE before pinning; the old roadmap's `^5.3.0` is not current.
- [ ] Initialize `MobileAds.instance.initialize()` once before the first ad request.
- [ ] Add test and production application/unit IDs in a configuration layer; never use production IDs in tests.
- [ ] Add the Android AdMob application ID metadata only after the real ID is available.
- [ ] Implement adaptive banner sizing from available width.
- [ ] Dispose each `BannerAd` when the widget leaves the tree.
- [ ] Collapse the layout on `onAdFailedToLoad`; do not leave a permanent blank card.
- [ ] Enforce placements with a single `AdPlacement` enum: language-pack manager and export encoding only.
- [ ] Verify no ad widget is created in player, studio, media library, or donate routes.
- [ ] Add tests for mock mode, loading, loaded, failed, disposed, and placement policy.
- [ ] Use test IDs on emulator and physical development devices.

## 12. Phase B9: Local Donate Reminder Scheduler

The existing `NotificationService` is partly implemented. This phase hardens it instead of duplicating it.

- [ ] Keep `flutter_local_notifications: ^22.3.0` and `timezone: ^0.11.1` unless compatibility checks require a coordinated upgrade.
- [ ] Keep timezone database initialization before scheduling and set the device timezone using a verified platform/plugin method.
- [ ] Add Android 13+ notification permission flow through `requestNotificationsPermission()`.
- [ ] Add `RECEIVE_BOOT_COMPLETED` and scheduled-notification receivers only if the plugin's v22 setup requires them for the selected scheduling mode.
- [ ] Use inexact scheduling by default for donation reminders; exact alarms are not necessary for a non-critical reminder.
- [ ] If a product decision requires exact time, request `SCHEDULE_EXACT_ALARM` and explain why; never add `USE_EXACT_ALARM` casually.
- [ ] Replace the current one-shot-only behavior with a preference-driven schedule: daily, configured interval, or disabled. Verify whether `periodicallyShow` supports the desired interval in v22; otherwise schedule the next reminder after each delivery.
- [ ] Persist enabled state and frequency with `shared_preferences`.
- [ ] Respect OEM background restrictions and document that some manufacturers may delay scheduled notifications.
- [ ] Route notification payloads to `/donate` through the actual `GoRouter` instance.
- [ ] Handle notification-launched app state with `getNotificationAppLaunchDetails()`.
- [ ] Add unit tests with a mock notification plugin and physical tests on Android 13+.

### Sources

- [ ] Review https://pub.dev/packages/flutter_local_notifications, especially v22 Android setup, scheduling, exact-alarm, permission, and compatibility sections.
- [ ] Review https://developer.android.com/about/versions/14/changes/schedule-exact-alarms.

## 13. Phase B10: URL Launcher and Donation Portal Deep Link

- [ ] Keep `url_launcher: ^6.3.2`.
- [ ] Move the donation URL from `AppConstants` into one configuration source and make Flutter and React use the same canonical URL.
- [ ] Add Android `<queries>` only for schemes that the app actually checks.
- [ ] Use `launchUrl(uri, mode: LaunchMode.externalApplication)`.
- [ ] Handle `false` return with a user-visible fallback and a copyable URL.
- [ ] Keep the bottom navigation Donate route in-app; only explicit donate actions open the external portal.
- [ ] Add tests around the launcher abstraction, including URL and external launch mode.
- [ ] Add an Android manual test with and without a browser available.

## 14. Phase B11: Paynow and Alternative Payment Gateways

### Architecture

The React browser must not receive Paynow integration keys. The flow is:

```text
React portal -> Cloudflare Worker /initiate -> Paynow
Paynow -> return URL (browser UX)
Paynow -> result URL (server webhook) -> verify signature -> durable status
React portal -> /status?id=... -> confirmed/pending/failed
```

- [ ] Confirm Paynow's current individual merchant onboarding requirements directly with Paynow support/documentation; do not state undocumented requirements as fact.
- [ ] Obtain the individual merchant's Integration ID and Integration Key.
- [ ] Store them as Cloudflare Worker secrets, not in React source, Flutter `.env`, GitHub artifacts, or public Pages variables.
- [ ] Create a Worker with `POST /api/paynow/initiate`, `POST /api/paynow/result`, and `GET /api/paynow/status/:reference`.
- [ ] Generate a server-side unique reference and validate amount/currency bounds server-side.
- [ ] Use Paynow's documented Express Checkout or Redirect API after verifying exact current request/response fields. ⚠️ VERIFY ONLINE against https://developers.paynow.co.zw/docs/paynow/quickstart/ before implementation.
- [ ] Verify result/webhook signatures using the documented algorithm and constant-time comparison where applicable.
- [ ] Make webhook processing idempotent by reference and transaction ID.
- [ ] Return only a public status and reference to the browser.
- [ ] Configure `PAYNOW_RETURN_URL` and `PAYNOW_RESULT_URL` as Worker environment values.
- [ ] Add CORS allowing only the production portal and explicitly configured local development origins.
- [ ] Do not trust a browser “success” query parameter as payment confirmation.
- [ ] Add sandbox/test matrix for accepted, cancelled, failed, duplicate, malformed, delayed, and replayed results.
- [ ] Add React loading, pending, success, failure, retry, and expired-reference states.
- [ ] Keep Ko-fi, Buy Me a Coffee, and crypto links as independent fallback methods with no fake confirmation.
- [ ] Add manual EcoCash instructions only after the merchant has supplied an approved public number.
- [ ] Document privacy, retention, and refund handling before production payments.
- [ ] Deploy the Worker separately from Cloudflare Pages and test from the deployed portal origin.

### React portal corrections

- [ ] Preserve the current Vite/React/TypeScript setup: React `^19.2.8`, React Router `^7.18.3`, Vite `^8.2.2`, TypeScript `~6.0.2`, Tailwind 4, and Oxlint.
- [ ] Keep the current `/`, `/donate`, `/support`, `/about`, and `/payment-confirmation` routes during migration; mark `/support` as a compatibility redirect, then remove it only in a planned breaking change.
- [ ] Do not add the old roadmap's unverified `paynow` npm package without checking whether it is maintained and browser-safe; the Worker should own Paynow protocol calls.
- [ ] Add a typed API client under `react_frontend/src/` for initiate/status calls with runtime response validation.
- [ ] Add `VITE_PAYNOW_API_BASE_URL` as public configuration only; never put Paynow keys in `VITE_*` variables.
- [ ] Add React tests for amount validation, method selection, route states, and API error handling.
- [ ] Add `react_frontend/wrangler.toml` only if the chosen Pages deployment requires it.
- [ ] Add a Pages SPA fallback configuration and verify deep links in production.

### Sources

- [ ] Review https://developers.paynow.co.zw/ and the Paynow quickstart linked there.
- [ ] Review Cloudflare Workers and Pages deployment documentation before writing the Worker workflow.

## 15. Phase B12: Firebase Cloud Messaging

- [ ] Add `firebase_core` and `firebase_messaging` at mutually compatible current versions after checking the FlutterFire compatibility matrix.
- [ ] Create a Firebase project and register Android package `com.captionary.captionary`.
- [ ] Add `google-services.json` locally and ignore it if project policy treats it as generated configuration; never commit service-account private keys.
- [ ] Configure the Google services Gradle plugin according to the current FlutterFire setup.
- [ ] Initialize Firebase before using `FirebaseMessaging`.
- [ ] Request notification permission on Android 13+ through FCM and track whether the request was made.
- [ ] Retrieve the FCM token, store it in `shared_preferences` only if the product has a privacy-approved token policy, and handle `onTokenRefresh`.
- [ ] Register a top-level `@pragma('vm:entry-point')` background handler.
- [ ] Keep background handlers short; do not perform transcription or long processing there.
- [ ] On foreground `FirebaseMessaging.onMessage`, display a local notification through the existing notification service.
- [ ] Create a high-importance Android channel for visible foreground messages if required by the Android behavior.
- [ ] Handle `FirebaseMessaging.onMessageOpenedApp` for background taps.
- [ ] Handle `getInitialMessage()` for terminated-app taps.
- [ ] Route a typed data field such as `route: /donate` through GoRouter after app startup.
- [ ] Define message payload schema with `message_id`, `type`, `route`, and optional safe display fields.
- [ ] Create a Worker/admin sender using FCM HTTP v1 OAuth/service-account credentials stored only in Worker secrets. Do not use the deprecated legacy server key unless current Firebase documentation explicitly requires it.
- [ ] Add token deletion/opt-out behavior and a privacy notice.
- [ ] Test foreground, background, terminated, denied permission, token refresh, malformed route, duplicate message, and force-quit behavior.

### Message flow

```text
Admin/Worker -> FCM HTTP v1 -> Android FCM SDK ->
  foreground: onMessage -> flutter_local_notifications
  background: system notification -> onMessageOpenedApp on tap
  terminated: system notification -> getInitialMessage on launch
-> typed route -> GoRouter -> relevant screen
```

### Sources

- [ ] Review https://pub.dev/packages/firebase_messaging.
- [ ] Review https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages.
- [ ] Review https://firebase.google.com/docs/cloud-messaging/send-message.

## 16. Phase B13: RAM and Performance Hardening

- [ ] Define tiers from total RAM: low `<4 GB`, standard `4-6 GB`, high `>=6 GB`; record this as a recommendation, not a guarantee.
- [ ] Implement Android total/available memory reporting through a small platform channel or a verified package; do not infer RAM from model name.
- [ ] Record Dart heap and native/graphics/process memory at import, playback, extraction, model load, transcription, model unload, and burn-in.
- [ ] Enforce one model and one heavy FFmpeg job at a time.
- [ ] Process audio sequentially in 30-second chunks and delete each intermediate file.
- [ ] Dispose the video controller when leaving the player screen.
- [ ] Do not preload full videos or thumbnails; generate a single thumbnail frame only when needed.
- [ ] Keep the explicit target: peak total app memory below 1.5 GB during burn-in on a 4 GB device.
- [ ] Add a lower-memory fallback: stop before model load if measured available memory is below the tested threshold, show a retry/actionable message, and preserve no corrupt output.
- [ ] Disable large model recommendations on low-memory tiers.
- [ ] Run 10 consecutive transcriptions and 10 consecutive burn-ins while recording peak and post-operation memory.
- [ ] Run Flutter DevTools memory profiling on a physical 4 GB device; emulator results are supplementary.
- [ ] Document observed values and update model recommendations from measurements.

## 17. Phase B14: End-to-End Integration and Release

- [ ] Create a licensed short-video fixture and a known expected subtitle fixture.
- [ ] Test import -> metadata -> playback -> extraction -> language selection/detection -> model verification -> transcription -> timeline -> style -> burn-in -> share.
- [ ] Test offline playback and transcription with an installed model and cached manifest.
- [ ] Test offline failure when no model is installed with a clear download instruction.
- [ ] Test interrupted model download, resume, corrupt checksum, deletion, and storage accounting.
- [ ] Test notification scheduler and FCM tap routing on Android 13+.
- [ ] Test Paynow sandbox or merchant-approved test environment without exposing credentials.
- [ ] Test React portal production build and deployed SPA deep links.
- [ ] Run `flutter analyze`.
- [ ] Run `flutter test --coverage`.
- [ ] Run integration tests with `flutter test integration_test/`.
- [ ] Run `npm ci && npm run build && npm run lint` in `react_frontend/`.
- [ ] Build a signed split APK and verify signature/checksums.
- [ ] Test the release APK on at least one physical 4 GB Android device and one higher-RAM device.
- [ ] Create a GitHub Release with APKs, checksums, changelog, known limitations, and source commit.
- [ ] Confirm Play Store/AAB work is excluded from the release checklist.

## 18. Definition of Done Per Phase

Every phase B1-B14 is complete only when all applicable items below are checked:

- [ ] `flutter analyze` has zero new warnings/errors.
- [ ] `flutter test` passes.
- [ ] Touched modules have at least 80 percent coverage, or a linked issue explains why a platform/manual test is required instead.
- [ ] Mock implementations remain available and provider overrides are tested.
- [ ] Offline behavior is defined and tested.
- [ ] Android 13+ permission behavior is tested where relevant.
- [ ] A manual emulator smoke test passes.
- [ ] A physical-device test passes when native playback, FFmpeg, notifications, FCM, ads, or memory is involved.
- [ ] React `npm run build` and `npm run lint` pass for portal changes.
- [ ] Documentation and source URLs are updated in `docs/`.
- [ ] A Conventional Commit is created and the PR is merged to `develop`.
- [ ] No untracked TODO remains without a linked issue.
- [ ] Rollback instructions and feature-flag behavior are documented.

## 19. Risk Register

| Risk | Likelihood | Impact | Mitigation | Owner |
|---|---:|---:|---|---|
| `whisper_flutter_new` API does not expose the assumed language-detection method | High | High | Verify API before implementation; provide explicit language fallback; never invent methods. | Flutter |
| Native Whisper/FFmpeg licenses conflict with distribution plan | Medium | High | Legal review before release; record package licenses and source obligations. | Release |
| 4 GB device OOM during model load/burn-in | High | High | Tiny model default, sequential pipeline, measured memory gate, unload in `finally`. | Performance |
| R2 public URL/range/CORS behavior differs from local assumptions | Medium | High | Test HEAD/range/CORS in CI or staging; cache validated manifest. | R2 |
| R2 development URL is rate-limited | Medium | Medium | Use custom production domain; reserve `r2.dev` for development. | R2 |
| Android OEM kills scheduled notifications | High | Medium | Inexact scheduling, user guidance, FCM for server messages, physical OEM tests. | Mobile |
| FCM background behavior differs after force-quit | Medium | Medium | Document Android behavior; test reopen/token lifecycle; never promise delivery after force-quit. | Mobile |
| Paynow result is spoofed or replayed | Medium | High | Worker-side signature verification, idempotency, server-side status authority. | Payments |
| Paynow credentials leak through React/Vite or Flutter assets | Medium | Critical | Keep secrets in Worker/GitHub secrets; secret scan; review built artifacts. | Security |
| React route alias conflicts with old `/support` links | Medium | Low | Keep compatibility route during migration and add redirect tests. | React |
| Release signing material is lost | Low | Critical | Secure backup and documented key custody; never store in Git. | Release |
| `media_kit` package versions mismatch | Medium | Medium | Keep video_player initially; verify current media-kit package set before migration. | Flutter |
| FFmpeg ASS/font behavior differs by Android ABI | Medium | High | Test every target ABI/device; provide SRT/export fallback. | Media |

## 20. Rollback Plan

- [ ] Add a `backendModeProvider` that can select mock, local, and real adapters at startup/build configuration.
- [ ] Keep mock language/transcription/export services in the repository permanently for tests and offline UI development.
- [ ] Roll back real R2 downloads by disabling the real language provider and serving cached/seed data.
- [ ] Roll back Whisper by disabling real transcription and preserving imported media/subtitle editing.
- [ ] Roll back ASS burn-in by selecting the current SRT burn-in path or export-only mode if styling fails.
- [ ] Roll back FCM independently from local notifications; local reminders must continue to work without FCM.
- [ ] Roll back AdMob by returning the placeholder widget and production-safe no-ad state.
- [ ] Roll back Paynow by disabling the Paynow method and leaving alternative donation links available; never show success for an unconfirmed payment.
- [ ] Roll back a release by publishing a corrected GitHub Release and marking the affected version as withdrawn; do not rewrite already-published tags.
- [ ] Document the feature flag, affected version, data migration, and user-visible behavior for every rollback.

## 21. Appendices

### Appendix A: GitHub Secrets and Variables

Names only; never commit values.

| Name | Purpose |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | Base64 release keystore. |
| `ANDROID_KEY_ALIAS` | Release key alias. |
| `ANDROID_KEY_PASSWORD` | Key password. |
| `ANDROID_STORE_PASSWORD` | Keystore password. |
| `CLOUDFLARE_API_TOKEN` | Pages/Worker deployment token with least privilege. |
| `CLOUDFLARE_ACCOUNT_ID` | Cloudflare account identifier. |
| `CLOUDFLARE_PAGES_PROJECT` | Pages project name. |
| `R2_ACCOUNT_ID` | Upload script account identifier. |
| `R2_ACCESS_KEY_ID` | R2 S3 upload key. |
| `R2_SECRET_ACCESS_KEY` | R2 S3 upload secret. |
| `PAYNOW_INTEGRATION_ID` | Worker-only Paynow integration ID. |
| `PAYNOW_INTEGRATION_KEY` | Worker-only Paynow integration key. |
| `PAYNOW_RETURN_URL` | Browser return URL. |
| `PAYNOW_RESULT_URL` | Paynow server result/webhook URL. |
| `FCM_SERVICE_ACCOUNT_JSON` | Worker/admin sender credential, if a Worker sends FCM HTTP v1 messages. |
| `FCM_PROJECT_ID` | Firebase project ID for the sender. |
| `FCM_CLIENT_EMAIL` | Service-account client email if stored as split secrets. |
| `FCM_PRIVATE_KEY` | Service-account private key if stored separately. |
| `R2_PUBLIC_BASE_URL` | Public model delivery URL; not a secret. |
| `DONATE_WEB_URL` | Canonical portal URL; not a secret. |

### Appendix B: `.env.example` keys

The root `.env.example` must explain whether each value is public client configuration or server-only. Server-only values must not be loaded into the APK.

```dotenv
# Public configuration safe to expose in a client build.
R2_BASE_URL=https://models.example.com/
MANIFEST_URL=https://models.example.com/manifest.json
DONATE_WEB_URL=https://captionary.example/donate
APP_ENV=development
BACKEND_MODE=mock
ADMOB_APP_ID=ca-app-pub-0000000000000000~0000000000
ADMOB_BANNER_UNIT_ID=ca-app-pub-0000000000000000/0000000000

# Local upload/Worker configuration. Never bundle these into Flutter or React.
R2_ACCOUNT_ID=replace-with-account-id
R2_ACCESS_KEY_ID=replace-with-r2-access-key
R2_SECRET_ACCESS_KEY=replace-with-r2-secret
R2_BUCKET=captionary-models
R2_PUBLIC_BASE_URL=https://models.example.com/
PAYNOW_INTEGRATION_ID=replace-with-paynow-id
PAYNOW_INTEGRATION_KEY=replace-with-paynow-key
PAYNOW_RETURN_URL=https://captionary.example/payment-confirmation
PAYNOW_RESULT_URL=https://captionary-payments.example/api/paynow/result
FCM_PROJECT_ID=replace-with-firebase-project
FCM_CLIENT_EMAIL=replace-with-service-account-email
FCM_PRIVATE_KEY=replace-with-service-account-private-key
FCM_SERVICE_ACCOUNT_JSON=replace-with-server-only-service-account-json

# Optional server-side alternatives; do not place private wallet secrets here.
DONATE_KOFI_URL=https://ko-fi.com/replace
DONATE_BMAC_URL=https://buymeacoffee.com/replace
DONATE_CRYPTO_BTC_ADDRESS=replace-with-public-address
DONATE_CRYPTO_ETH_ADDRESS=replace-with-public-address
DONATE_CRYPTO_USDT_ADDRESS=replace-with-public-address
```

- [ ] Keep `.env.example` committed with placeholders only.
- [ ] Keep `.env` ignored and outside release artifacts.
- [ ] Remove any secret-looking value from Flutter assets before release.

### Appendix C: Android permissions and declarations

| Permission/declaration | Why | Condition |
|---|---|---|
| `INTERNET` | R2, FCM, Paynow portal, remote configuration. | Required for network features. |
| `POST_NOTIFICATIONS` | Android 13+ local/FCM notifications. | Required for notifications. |
| `RECEIVE_BOOT_COMPLETED` | Re-schedule local notifications after reboot. | Required only when using plugin scheduled-notification receiver. |
| `SCHEDULE_EXACT_ALARM` | Exact local alarm delivery. | Avoid unless product requires exact timing; request at runtime. |
| `READ_MEDIA_VIDEO` | Direct media-library reads on Android 13+. | Only if bypassing SAF/file picker. |
| `READ_MEDIA_AUDIO` | Direct audio reads on Android 13+. | Only if needed by the chosen flow. |
| `READ_EXTERNAL_STORAGE` | Legacy Android media access. | Only for supported pre-33 behavior. |
| `WRITE_EXTERNAL_STORAGE` | Legacy writes. | Do not rely on it for Android 10+. |
| AdMob application metadata | AdMob SDK initialization. | Required only when live ads ship. |
| Firebase services/plugin config | FCM registration. | Required only after Firebase setup. |
| `<queries>` for `https` | Browser/package visibility checks. | Add only if the launcher calls `canLaunchUrl`. |

- [ ] Confirm `compileSdk` meets the current notification plugin requirement; the current app delegates to Flutter's compile SDK and must be checked in CI.
- [ ] Use SAF/file picker to minimize broad storage permissions.

### Appendix D: Files to create or modify

| Path | Action |
|---|---|
| `docs/BACKEND_IMPLEMENTATION_ROADMAP.md` | Create this roadmap. |
| `.gitignore` | Create root ignore policy. |
| `.env.example` | Create placeholders/documentation. |
| `.github/workflows/ci.yml` | Create PR checks. |
| `.github/workflows/build-debug.yml` | Create debug APK workflow. |
| `.github/workflows/release.yml` | Create signed APK release workflow. |
| `.github/workflows/react.yml` | Create React build/deploy workflow. |
| `.github/pull_request_template.md` | Create PR checklist. |
| `scripts/upload_models.js` or `.py` | Create R2 uploader/manifest generator. |
| `scripts/check-secrets.*` | Create `.env`/credential guard. |
| `flutter_mobile/pubspec.yaml` | Add only verified dependencies and assets. |
| `flutter_mobile/lib/main.dart` | Firebase/media initialization and lifecycle wiring. |
| `flutter_mobile/lib/app.dart` | Router/tap/deep-link handling. |
| `flutter_mobile/lib/core/constants/app_constants.dart` | Public configuration source. |
| `flutter_mobile/lib/data/services/*.dart` | Add adapters while preserving contracts. |
| `flutter_mobile/lib/data/mock/*.dart` | Preserve and improve test fakes. |
| `flutter_mobile/lib/providers/*.dart` | Add real/mock provider selection and disposal. |
| `flutter_mobile/lib/screens/video_player_screen.dart` | Real player and overlay. |
| `flutter_mobile/lib/widgets/ad_banner_widget.dart` | Live/mock/failure ad states. |
| `flutter_mobile/android/app/build.gradle.kts` | Signing, Firebase/AdMob/plugin configuration as required. |
| `flutter_mobile/android/app/src/main/AndroidManifest.xml` | Conditional permissions, receivers, metadata, queries. |
| `flutter_mobile/android/app/google-services.json` | Local/generated Firebase config; ignore according to policy. |
| `flutter_mobile/test/unit/` | Service, parser, checksum, state-machine tests. |
| `flutter_mobile/integration_test/` | End-to-end device tests. |
| `react_frontend/src/` | Typed payment client and portal states. |
| `react_frontend/package.json` | Only verified dependencies/scripts. |
| `react_frontend/wrangler.toml` | Optional Pages/Worker deployment config. |
| `worker/` or `cloudflare/worker/` | Paynow/FCM serverless endpoints. |

### Appendix E: Model catalog template

Do not invent sizes or checksums. Fill each row only after downloading and hashing the exact file.

| Model file | Language | Quantization | Size bytes | SHA256 | Runtime RAM measured | Source/license |
|---|---|---|---:|---|---:|---|
| `ggml-tiny.en.bin` | `en` | none | `VERIFY` | `VERIFY` | `VERIFY` | whisper.cpp / MIT source terms |
| `ggml-tiny.bin` | multilingual | none | `VERIFY` | `VERIFY` | `VERIFY` | whisper.cpp / MIT source terms |
| `ggml-base.bin` | multilingual | none | `VERIFY` | `VERIFY` | `VERIFY` | whisper.cpp / MIT source terms |
| `ggml-small.q5_0.bin` | multilingual | Q5_0 | `VERIFY` | `VERIFY` | `VERIFY` | whisper.cpp / source terms |
| language-specific model | `VERIFY` | `VERIFY` | `VERIFY` | `VERIFY` | `VERIFY` | `VERIFY` |

- [ ] Record both disk size and measured runtime memory.
- [ ] Do not claim a language is supported by a specialized model until the model is tested with the selected package.

### Appendix F: Glossary

- **APK:** Android application package attached to a GitHub Release.
- **ASS:** Advanced SubStation Alpha subtitle format with styling.
- **CI/CD:** Continuous integration and continuous delivery automation.
- **CORS:** Browser policy controlling permitted cross-origin requests.
- **FCM:** Firebase Cloud Messaging for server-initiated push notifications.
- **FFmpeg:** Media processing toolkit used for audio extraction and video encoding.
- **FFI:** Foreign Function Interface used to call native code.
- **GGML:** Binary model format used by whisper.cpp model files.
- **GitHub Actions:** GitHub-hosted workflow automation.
- **HMAC/signature:** Cryptographic verification that a callback was generated by a trusted sender.
- **Manifest:** Public JSON catalog describing models and checksums.
- **OOM:** Out of memory; the process is killed or fails allocation.
- **R2:** Cloudflare object storage with an S3-compatible API.
- **Riverpod:** Flutter state-management and dependency-injection library used by this project.
- **SAF:** Android Storage Access Framework for user-selected files.
- **S3 API:** Object-storage API compatible with Amazon S3 requests.
- **SRT/VTT:** Common subtitle file formats.
- **Worker:** Cloudflare's serverless JavaScript/TypeScript runtime.
- **Q5_0/Q8_0:** Whisper model quantization formats trading size and precision.

## Sources Index

- [ ] Whisper package: https://pub.dev/packages/whisper_flutter_new
- [ ] Whisper package API: https://pub.dev/documentation/whisper_flutter_new/latest/
- [ ] Whisper.cpp: https://github.com/ggml-org/whisper.cpp
- [ ] Video player: https://pub.dev/packages/video_player
- [ ] Media Kit: https://pub.dev/packages/media_kit
- [ ] Media Kit video: https://pub.dev/packages/media_kit_video
- [ ] Firebase Messaging: https://pub.dev/packages/firebase_messaging
- [ ] Firebase receive messages: https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages
- [ ] Local notifications: https://pub.dev/packages/flutter_local_notifications
- [ ] Dotenv: https://pub.dev/packages/flutter_dotenv
- [ ] Dio: https://pub.dev/packages/dio
- [ ] Permission handler: https://pub.dev/packages/permission_handler
- [ ] R2 public buckets: https://developers.cloudflare.com/r2/buckets/public-buckets/
- [ ] R2 CORS: https://developers.cloudflare.com/r2/buckets/cors/
- [ ] R2 S3 compatibility: https://developers.cloudflare.com/r2/api/s3/api/
- [ ] Cloudflare Workers: https://developers.cloudflare.com/workers/
- [ ] GitHub Actions: https://docs.github.com/en/actions
- [ ] Flutter Action: https://github.com/subosito/flutter-action
- [ ] Paynow Developer Hub: https://developers.paynow.co.zw/

## Final Acceptance Summary

- [ ] All fourteen backend phases B1-B14 are complete.
- [ ] Existing roadmap B1-B13 coverage is preserved as follows: old B1 is expanded with a video-player decision; old B2-B7 remain focused on media processing/export; old B8-B10 remain ads/local notifications/URL launching; old B11 is expanded into React plus Worker Paynow; old B12 becomes B13 performance; old B13 becomes B14 release verification.
- [ ] New standalone phases cover R2/CI setup, FCM as a distinct phase, and explicit preconditions/rollback/documentation.
- [ ] Flutter mock providers remain usable in tests and offline UI mode.
- [ ] React portal builds, lint passes, deep links work, and no payment secret appears in its bundle.
- [ ] The final player decision is `video_player` first, with a measured migration gate to current `media_kit` packages only if acceptance tests show that `video_player` cannot meet codec, seeking, hardware, or subtitle requirements. 
