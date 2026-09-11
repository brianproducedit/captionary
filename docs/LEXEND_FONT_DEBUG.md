# Lexend Font Loading — Debug Report

## 1. Executive Summary

**The issue is identified. There are TWO root causes:**

| # | Cause | Severity |
|---|-------|----------|
| 1 | **The font file was 0 bytes** — an empty placeholder was committed instead of the real Lexend variable font. The user has since replaced it with a valid 174 KB `.ttf` file. | 🔴 Critical (now resolved by user) |
| 2 | **No `flutter clean` + full restart was performed** after replacing the font file. Flutter caches the asset bundle aggressively; a hot reload or even hot restart will NOT pick up new/changed font assets. | 🟡 High |

**Secondary issues found (preventative):**

| # | Issue | Severity |
|---|-------|----------|
| 3 | `fontVariations` is not used — variable font weight axis (`wght`) may not respond to `FontWeight.wXXX` on older Flutter engine versions without explicit `FontVariation('wght', value)` | 🟡 Medium |
| 4 | `ThemeData.fontFamily` does **not** propagate to `AppBarTheme`, `ElevatedButtonThemeData`, `ChipTheme`, etc. Widgets using those component themes will silently fall back to Roboto. | 🟡 Medium |
| 5 | `AndroidManifest.xml` is missing `<uses-permission android:name="android.permission.INTERNET"/>` — not relevant for bundled fonts, but will break any future `google_fonts` runtime fetching or network features in release builds. | 🟢 Low (for fonts) |

---

## 2. Codebase Findings

### 2.1 `pubspec.yaml` — Font Declaration

```yaml
# Lines 117-120 of pubspec.yaml
flutter:
  fonts:
    - family: Lexend
      fonts:
        - asset: assets/fonts/Lexend-VariableFont_wght.ttf
```

**Verdict:** ✅ Correct YAML indentation. ✅ Family name `Lexend` matches code. ✅ Single variable font file is the correct approach.

**Problem found:** The referenced file `assets/fonts/Lexend-VariableFont_wght.ttf` was **0 bytes** (empty file created on 2026-09-05). A 0-byte font file will be bundled silently without errors, but Flutter will fail to render any glyphs from it and fall back to the platform default (Roboto on Android, SF Pro on iOS).

**Current status:** User replaced the file — it is now **174,528 bytes** (valid).

### 2.2 `app_theme.dart` — ThemeData Configuration

```dart
// Lines 8-61 of app_theme.dart
static ThemeData get darkTheme {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'Lexend',                    // ← Global fallback
    textTheme: const TextTheme(
      displayLarge: AppTypography.displayLg,  // ← Each has fontFamily: 'Lexend'
      headlineLarge: AppTypography.headlineXl,
      // ... all styles set fontFamily explicitly
    ),
  );
}
```

**Verdict:** ✅ `fontFamily: 'Lexend'` is set at ThemeData level. ✅ Every `AppTypography` style also has `fontFamily: 'Lexend'` hardcoded — this is **double-safe** and correct.

**Note:** No `appBarTheme.titleTextStyle`, `elevatedButtonTheme`, or `chipTheme` overrides with explicit font family. This means component themes that define their own styles will NOT inherit `fontFamily: 'Lexend'`.

### 2.3 `app_typography.dart` — TextStyle Definitions

```dart
static const String _fontFamily = 'Lexend';

static const TextStyle displayLg = TextStyle(
  fontFamily: _fontFamily,
  fontSize: 48,
  fontWeight: FontWeight.w700,
  // ...
);
// ... all 10 styles follow the same pattern
```

**Verdict:** ✅ Every style explicitly references `fontFamily: 'Lexend'`. No style accidentally omits it.

### 2.4 `main.dart` — No `google_fonts` Usage

The app does **not** use the `google_fonts` package at all. It relies entirely on the bundled `.ttf` file declared in `pubspec.yaml`. This is the correct approach for production apps — no network dependency, no runtime fetching.

### 2.5 `AndroidManifest.xml`

Missing `<uses-permission android:name="android.permission.INTERNET"/>`. Not critical for bundled fonts, but would break `google_fonts` runtime fetching if ever added.

### 2.6 Asset Folder Structure

```
assets/
  fonts/
    Lexend-VariableFont_wght.ttf   ← 174,528 bytes (was 0 bytes, now replaced)
  images/
    ...
```

---

## 3. Research Findings

### 3.1 Flutter 3.38+ AssetManifest.json Breaking Change

**Finding:** Flutter removed `AssetManifest.json` generation in favor of a binary manifest. The `google_fonts` package prior to v4.0.1 read this file directly and would crash.

**Impact on Captionary:** ⚠️ **None.** The app does not use `google_fonts`. Fonts are bundled via `pubspec.yaml` and loaded through the standard asset pipeline, which uses the new binary manifest automatically.

**Source:** [Flutter Breaking Changes — AssetManifest](https://docs.flutter.dev/release/breaking-changes), [google_fonts changelog](https://pub.dev/packages/google_fonts/changelog)

### 3.2 `google_fonts` Latest Version

**Finding:** As of September 2026, the latest stable version is `^7.0.2`. Earlier versions had the `AssetManifest.json` conflict.

**Impact on Captionary:** ⚠️ **None.** Not used. If ever added, use `^7.0.2` or later.

### 3.3 Runtime Fetching vs. Bundling

**Finding:** `GoogleFonts.config.allowRuntimeFetching = false` disables network font downloads. When disabled, the package only uses fonts found in the asset bundle. Bundling is recommended for production to avoid:
- Network dependency on first launch
- INTERNET permission requirement on Android
- Potential CORS/firewall issues

**Impact on Captionary:** ✅ The app already bundles fonts. This is the **correct production approach**.

### 3.4 `ThemeData.fontFamily` Inheritance Bug

**Finding:** This is **not a bug but documented behavior**. `ThemeData.fontFamily` only applies to text rendered via the `textTheme`. Component themes like `AppBarTheme`, `ElevatedButtonThemeData`, `ChipThemeData`, `NavigationBarThemeData`, and `DialogTheme` define their own `TextStyle` objects. When a component theme specifies a style, it does NOT fall back to `ThemeData.fontFamily`.

**Workaround:** Explicitly set `fontFamily` in each component theme, or use `textTheme.apply(fontFamily: 'Lexend')` to ensure full propagation.

**Source:** [Flutter GitHub Issue #92726](https://github.com/flutter/flutter/issues/92726), [StackOverflow — fontFamily not applying](https://stackoverflow.com/questions/67568394)

### 3.5 Lexend Font Family Name

**Finding:** The font family name embedded in the Lexend variable font file metadata is `"Lexend"`. This matches the `family: Lexend` declaration in `pubspec.yaml` and the `fontFamily: 'Lexend'` references in code. **No mismatch.**

If using `google_fonts`, the correct method is `GoogleFonts.lexend()` or `GoogleFonts.lexendTextTheme()`.

### 3.6 Hot Reload vs. Full Restart

**Finding:** Changes to `pubspec.yaml` (adding/removing/modifying font declarations or assets) **require a full app stop + restart**. Neither hot reload nor hot restart is sufficient because:
1. `pubspec.yaml` is parsed at build time, not runtime
2. The asset bundle is compiled into the APK/IPA
3. Font assets are loaded into the Skia/Impeller font cache at app startup

**Recommendation:** After replacing the font file, run:
```bash
flutter clean
flutter pub get
# Then fully stop and restart the app
```

### 3.7 Android/iOS Permissions for Fonts

**Finding:** The `INTERNET` permission in `AndroidManifest.xml` is only required for `google_fonts` runtime fetching. Bundled fonts (declared in `pubspec.yaml`) do not require any permissions.

**Impact on Captionary:** ✅ No permission needed for the current bundled approach. However, the manifest should add INTERNET permission for general app functionality (URL launcher, etc.).

---

## 4. Recommended Fix (Step-by-Step)

### Step 1: Verify the Font File is Valid ✅ (Done)

The user has replaced the 0-byte placeholder with a valid 174,528-byte Lexend variable font file.

### Step 2: Run `flutter clean` and Full Restart 🔴 (Required)

```bash
cd flutter_mobile
flutter clean
flutter pub get
# Stop the running app completely, then:
flutter run
```

> [!CAUTION]
> This is the **most likely remaining fix**. If the app was running when the font file was replaced, the old (empty) font is still cached in the build directory.

### Step 3: Add `fontVariations` for Variable Font Weight Control (Recommended)

Flutter's variable font support has improved, but for maximum compatibility, add `fontVariations` to `AppTypography` styles that use non-400 weights:

```dart
// lib/theme/app_typography.dart
import 'dart:ui';
import 'package:flutter/material.dart';

class AppTypography {
  static const String _fontFamily = 'Lexend';

  static const TextStyle displayLg = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 48,
    height: 56 / 48,
    letterSpacing: -0.02 * 48,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation('wght', 700)],  // ← ADD THIS
  );

  static const TextStyle displayLgMobile = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 32,
    height: 40 / 32,
    letterSpacing: -0.01 * 32,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation('wght', 700)],  // ← ADD THIS
  );

  static const TextStyle headlineXl = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 36,
    height: 44 / 36,
    letterSpacing: -0.01 * 36,
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation('wght', 600)],  // ← ADD THIS
  );

  static const TextStyle headlineXlMobile = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 26,
    height: 34 / 26,
    letterSpacing: 0,
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation('wght', 600)],  // ← ADD THIS
  );

  static const TextStyle headlineMd = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    height: 32 / 24,
    letterSpacing: 0,
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation('wght', 600)],  // ← ADD THIS
  );

  static const TextStyle headlineSm = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    height: 28 / 20,
    letterSpacing: 0,
    fontWeight: FontWeight.w500,
    fontVariations: [FontVariation('wght', 500)],  // ← ADD THIS
  );

  static const TextStyle bodyLg = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    height: 24 / 16,
    letterSpacing: 0.01 * 16,
    fontWeight: FontWeight.w400,
    fontVariations: [FontVariation('wght', 400)],  // ← ADD THIS
  );

  static const TextStyle bodyMd = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    height: 20 / 14,
    letterSpacing: 0.01 * 14,
    fontWeight: FontWeight.w400,
    fontVariations: [FontVariation('wght', 400)],  // ← ADD THIS
  );

  static const TextStyle bodySm = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    height: 16 / 12,
    letterSpacing: 0.02 * 12,
    fontWeight: FontWeight.w300,
    fontVariations: [FontVariation('wght', 300)],  // ← ADD THIS
  );

  static const TextStyle labelLg = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    height: 20 / 14,
    letterSpacing: 0.02 * 14,
    fontWeight: FontWeight.w500,
    fontVariations: [FontVariation('wght', 500)],  // ← ADD THIS
  );

  static const TextStyle labelMd = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    height: 16 / 12,
    letterSpacing: 0.03 * 12,
    fontWeight: FontWeight.w500,
    fontVariations: [FontVariation('wght', 500)],  // ← ADD THIS
  );

  static const TextStyle captionCode = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    height: 14 / 11,
    letterSpacing: 0.04 * 11,
    fontWeight: FontWeight.w400,
    fontVariations: [FontVariation('wght', 400)],  // ← ADD THIS
  );
}

extension CustomTextTheme on TextTheme {
  TextStyle get captionCode => AppTypography.captionCode;
}
```

### Step 4: Harden ThemeData with Component Theme Overrides (Recommended)

Add explicit font family to component themes in `app_theme.dart`:

```dart
// In AppTheme.darkTheme, after the textTheme:
appBarTheme: const AppBarTheme(
  backgroundColor: AppColors.baseCanvas,
  titleTextStyle: TextStyle(
    fontFamily: 'Lexend',
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
  ),
),
elevatedButtonTheme: ElevatedButtonThemeData(
  style: ElevatedButton.styleFrom(
    textStyle: const TextStyle(
      fontFamily: 'Lexend',
      fontWeight: FontWeight.w500,
    ),
  ),
),
outlinedButtonTheme: OutlinedButtonThemeData(
  style: OutlinedButton.styleFrom(
    textStyle: const TextStyle(
      fontFamily: 'Lexend',
      fontWeight: FontWeight.w500,
    ),
  ),
),
textButtonTheme: TextButtonThemeData(
  style: TextButton.styleFrom(
    textStyle: const TextStyle(
      fontFamily: 'Lexend',
      fontWeight: FontWeight.w500,
    ),
  ),
),
chipTheme: const ChipThemeData(
  labelStyle: TextStyle(fontFamily: 'Lexend'),
),
dialogTheme: const DialogThemeData(
  titleTextStyle: TextStyle(
    fontFamily: 'Lexend',
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
  ),
  contentTextStyle: TextStyle(
    fontFamily: 'Lexend',
    fontSize: 14,
    color: AppColors.onSurfaceVariant,
  ),
),
```

### Step 5: Add `fontFamilyFallback` as Safety Net (Optional)

Add a fallback chain to the base theme:

```dart
// In ThemeData
textTheme: ThemeData.dark().textTheme.apply(
  fontFamily: 'Lexend',
  fontFamilyFallback: ['Roboto', 'sans-serif'],
),
```

> [!NOTE]
> Since `AppTypography` already hardcodes `fontFamily: 'Lexend'` in every style, this fallback only matters for widgets that bypass the textTheme entirely.

---

## 5. Testing Checklist

After applying fixes and performing a full restart:

- [ ] **Body text** — Navigate to Media Library. Verify body text is Lexend (look for the distinctive rounded letterforms, especially lowercase `a`, `g`, and `e`).
- [ ] **AppBar titles** — Check that screen titles use Lexend, not Roboto.
- [ ] **Buttons** — Tap through screens. Verify button labels (ElevatedButton, OutlinedButton, GhostPillButton) use Lexend.
- [ ] **Font weights** — Compare `w300` (bodySm) vs `w700` (displayLg). The weight variation should be visibly different. If all weights look the same, the `fontVariations` fix in Step 3 is needed.
- [ ] **Subtitle overlay** — Open Studio screen. The subtitle overlay text should render in Lexend.
- [ ] **Bottom sheet text** — Open StylizationSheet or SubtitleCorrectionSheet. Verify Lexend.

---

## 6. Verdict

> **The primary issue was a 0-byte (empty) font file** at `assets/fonts/Lexend-VariableFont_wght.ttf`. Flutter bundled this empty file silently and fell back to Roboto for all text rendering. The user has replaced it with a valid file (174 KB).
>
> **The required action is: run `flutter clean && flutter pub get`, then fully restart the app.** This will rebuild the asset bundle with the real font file.
>
> **Secondary recommended actions:** Add `fontVariations` to `AppTypography` for robust variable font weight control, and add component theme overrides to `AppTheme.darkTheme` to ensure Lexend propagates to AppBar, Buttons, Chips, and Dialogs.
