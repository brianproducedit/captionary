# Captionary — UI Migration Roadmap

> **Project Name:** Captionary
> **Logo File:** `captionary_logo.png` (located in `prototypes/html_mobile_version/captionary_logo.png`)
> **Created:** 2026-09-05
> **Purpose:** Migrate HTML prototype UI designs to Flutter (mobile) and React-TypeScript (web) with pixel-perfect accuracy, using only local/offline assets.

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Source Prototype Inventory](#2-source-prototype-inventory)
3. [Design System Reference](#3-design-system-reference)
4. [Phase 1 — Pre-Migration Setup](#phase-1--pre-migration-setup)
5. [Phase 2 — Flutter Mobile Migration](#phase-2--flutter-mobile-migration)
6. [Phase 3 — React-TypeScript Web Migration](#phase-3--react-typescript-web-migration)
7. [Phase 4 — Navigation & Routing](#phase-4--navigation--routing)
8. [Phase 5 — Verification & Polish](#phase-5--verification--polish)
9. [Asset Dependency Matrix](#asset-dependency-matrix)
10. [File Structure Maps](#file-structure-maps)

---

## 1. Project Overview

### What We Are Doing

We are migrating **static HTML/CSS/JS prototype screens** into **production-ready framework code** in two parallel tracks:

| Track | Source Directory | Target Directory | Framework | Language |
|-------|-----------------|------------------|-----------|----------|
| **Mobile App** | `prototypes/html_mobile_version/` | `flutter_mobile/` | Flutter (Dart) | Dart |
| **Web App** | `prototypes/html_web_version/` | `react_frontend/` | Vite + React | TypeScript |

### Critical Rules

1. **UI designs MUST be migrated exactly as they appear in the HTML prototypes** — same colors, spacing, typography, layouts, shadows, gradients, and component shapes.
2. **ALL resources (fonts, icons, images, logo) MUST be local/offline** — no CDN links, no Google Fonts API calls, no online image URLs. Everything must be downloaded into the project's `assets/` directory.
3. **In-app navigation must be configured** so all screens are reachable for preview purposes.
4. **The Captionary logo** (`captionary_logo.png`) must be copied from `prototypes/html_mobile_version/` into both `flutter_mobile/assets/images/` and `react_frontend/src/assets/images/`.

---

## 2. Source Prototype Inventory

### Mobile Screens (6 screens → Flutter)

| # | Directory Name | Screen Title | Key UI Elements | Source File |
|---|---------------|-------------|-----------------|-------------|
| 1 | `home_local_media_library` | Home / Media Library | Hero import card, quick stats pills, recent media list (4 items with thumbnails), bottom nav bar | `code.html` |
| 2 | `language_pack_manager` | Language Packs | Search input, storage progress bar (multi-segment), language cards (5 cards: Shona ready, isiZulu downloading, Sepedi/French not downloaded, English built-in), AdMob placeholder, bottom nav bar | `code.html` |
| 3 | `subtitle_creator_studio_styling_editor` | Studio / Subtitle Editor | Video preview with subtitle overlay, audio waveform SVG, timeline blocks (editable), style presets carousel, sliders (font size, opacity), color picker chips, action buttons, bottom nav bar | `code.html` |
| 4 | `custom_video_player_auto_detection` | Timeline Editor / Video Player | Video canvas (16:9), caption overlay, audio waveform scrubber, transport controls (play/pause/skip), auto-detect language modal, NO bottom nav bar (sub-screen) | `code.html` |
| 5 | `support_community_mobile_app` | Support & Community | Hero spotlight with logo, mission stats grid, web contribution gateway card, impact cards (3 items), community links, bottom nav bar | `code.html` |
| 6 | `video_encoding_export_progress` | Export Details | State switcher tabs, circular SVG progress indicator, encoding telemetry card, AdMob banner, export complete celebration, share/preview buttons, NO bottom nav bar (sub-screen) | `code.html` |

### Web Screens (6 screens → React-TS)

| # | Directory Name | Screen Title | Key UI Elements | Source File |
|---|---------------|-------------|-----------------|-------------|
| 1 | `about_project_desktop` | About Project | Desktop nav bar, hero section with gradient text, 4-stat grid, 3-pillar cards, team section, CTA section | `code.html` |
| 2 | `documentation_desktop` | Documentation | Desktop nav bar, sidebar navigation, documentation content area, code blocks, search | `code.html` |
| 3 | `github_ecosystem_desktop` | GitHub Ecosystem | Desktop nav bar, repo cards, contribution stats, ecosystem overview | `code.html` |
| 4 | `payment_confirmation_gratitude_desktop` | Payment Confirmation | Desktop nav bar, confirmation card, thank you message, receipt details | `code.html` |
| 5 | `support_donation_portal_desktop` | Support / Donation Portal | Desktop nav bar, donation tiers, payment method selector, progress tracker | `code.html` |
| 6 | `transparency_ledger_desktop` | Transparency Ledger | Desktop nav bar, financial tables, allocation breakdowns, timeline charts | `code.html` |

### Design System Files (shared)

| File | Location | Purpose |
|------|----------|---------|
| `DESIGN.md` | `prototypes/html_mobile_version/deep_neon_dark_ui/` | Full design system specification (colors, typography, spacing, elevation, shapes, components) |
| `DESIGN.md` | `prototypes/html_web_version/deep_neon_dark_ui/` | Same design system (identical content — shared between mobile and web) |

---

## 3. Design System Reference

> **CRITICAL:** This section contains the EXACT design tokens extracted from the HTML prototypes and `DESIGN.md`. Every color, font size, spacing value, and component style below MUST be reproduced pixel-perfectly in both Flutter and React.

### 3.1 Color Palette (Dark Mode Only)

```
SURFACE COLORS:
  surface:                    #131313
  surface-dim:                #131313
  surface-bright:             #3a3939
  surface-container-lowest:   #0e0e0e
  surface-container-low:      #1c1b1b
  surface-container:          #201f1f
  surface-container-high:     #2a2a2a
  surface-container-highest:  #353534
  surface-variant:            #353534

ON-SURFACE COLORS:
  on-surface:                 #e5e2e1
  on-surface-variant:         #bfc7d4
  inverse-surface:            #e5e2e1
  inverse-on-surface:         #313030
  
OUTLINE COLORS:
  outline:                    #89919d
  outline-variant:            #404752

PRIMARY (Electric Blue):
  primary:                    #9ecaff
  on-primary:                 #003258
  primary-container:          #2196f3
  on-primary-container:       #002c4f
  inverse-primary:            #0061a4
  primary-fixed:              #d1e4ff
  primary-fixed-dim:          #9ecaff
  on-primary-fixed:           #001d36
  on-primary-fixed-variant:   #00497d
  surface-tint:               #9ecaff

SECONDARY (Deep Purple / Magenta):
  secondary:                  #f9abff
  on-secondary:               #570066
  secondary-container:        #86039c
  on-secondary-container:     #f7a0ff
  secondary-fixed:            #ffd6fe
  secondary-fixed-dim:        #f9abff
  on-secondary-fixed:         #35003f
  on-secondary-fixed-variant: #7b008f

TERTIARY (Neon Green):
  tertiary:                   #78dc77
  on-tertiary:                #00390a
  tertiary-container:         #42a547
  on-tertiary-container:      #003308
  tertiary-fixed:             #94f990
  tertiary-fixed-dim:         #78dc77
  on-tertiary-fixed:          #002204
  on-tertiary-fixed-variant:  #005313

ERROR:
  error:                      #ffb4ab
  on-error:                   #690005
  error-container:            #93000a
  on-error-container:         #ffdad6

EXTRA HARDCODED COLORS (used in HTML but not in design tokens):
  base-canvas:                #0A0A0A  (html body background)
  attention-yellow:           #FFC107  (download progress, processing states)
  surface-border:             #222222  (subtle structural borders)
```

### 3.2 Typography (Lexend Font Family — All Weights)

**Font:** Lexend (Google Font — must be downloaded as `.ttf` variable font for local use)
**Weights needed:** 300 (Light), 400 (Regular), 500 (Medium), 600 (SemiBold), 700 (Bold)

| Token Name | Font Size | Line Height | Letter Spacing | Font Weight | Usage |
|-----------|-----------|------------|----------------|-------------|-------|
| `display-lg` | 48px | 56px | -0.02em | 700 (Bold) | Desktop hero headlines |
| `display-lg-mobile` | 32px | 40px | -0.01em | 700 (Bold) | Mobile hero headlines, large percentages |
| `headline-xl` | 36px | 44px | -0.01em | 600 (SemiBold) | Desktop section headers |
| `headline-xl-mobile` | 26px | 34px | 0em | 600 (SemiBold) | Mobile section headers (e.g., "Language Packs") |
| `headline-md` | 24px | 32px | 0em | 600 (SemiBold) | Desktop sub-section headers |
| `headline-sm` | 20px | 28px | 0em | 500 (Medium) | Screen titles, card headers |
| `body-lg` | 16px | 24px | 0.01em | 400 (Regular) | Desktop body text |
| `body-md` | 14px | 20px | 0.01em | 400 (Regular) | Default body text |
| `body-sm` | 12px | 16px | 0.02em | 300 (Light) | Secondary descriptions |
| `label-lg` | 14px | 20px | 0.02em | 500 (Medium) | Button labels, file names |
| `label-md` | 12px | 16px | 0.03em | 500 (Medium) | Chips, badges, small labels |
| `caption-code` | 11px | 14px | 0.04em | 400 (Regular) | Timestamps, metadata, technical data |

### 3.3 Spacing System

```
space-xxs:       0.25rem (4px)
space-xs:        0.5rem  (8px)
space-sm:        0.75rem (12px)
space-md:        1rem    (16px)
space-lg:        1.5rem  (24px)
space-xl:        2rem    (32px)
space-2xl:       3rem    (48px)
space-3xl:       4rem    (64px)
gutter-mobile:   1rem    (16px)
gutter-desktop:  1.5rem  (24px)
margin-mobile:   1rem    (16px)
margin-tablet:   1.5rem  (24px)
margin-desktop:  2.5rem  (40px)
```

### 3.4 Border Radius

```
sm:       0.5rem  (8px)
DEFAULT:  1rem    (16px)
md:       1.5rem  (24px)
lg:       2rem    (32px)
xl:       3rem    (48px)
full:     9999px  (pill shape)
```

### 3.5 Elevation & Shadows

```
Level 0 (Base):     No shadow, flat #0A0A0A background
Level 1 (Cards):    #141414 background, 1px solid #222222 border
Level 2 (Modals):   #141414 semi-transparent, 16px backdrop blur, #2A2A2A edge
Level 3 (Float):    0px 4px 20px rgba(33, 150, 243, 0.35) — neon blue glow

Specific shadows used in HTML:
  - Primary button glow:      0 4px 20px rgba(33,150,243,0.35)
  - Support button glow:      0 0 12px rgba(156,39,176,0.35)
  - Bottom nav shadow:        0 -4px 24px rgba(0,0,0,0.6)
  - Card shadows:             shadow-sm, shadow-md, shadow-lg, shadow-xl, shadow-2xl (Tailwind defaults)
  - Modal bottom sheet:       0 -8px 30px rgba(0,0,0,0.6)
  - Tertiary dot glow:        0 0 8px rgba(120,220,119,0.9)
```

### 3.6 Gradient Definitions

```
Primary Gradient (buttons):    linear-gradient(to right, #2196F3, #86039C)
                               from-primary-container to-secondary-container
                               
Extended gradient:             linear-gradient(to right, #2196F3, #9ecaff, #86039C)
                               from-primary-container via-primary to-secondary-container

Scrubber progress gradient:    linear-gradient(to right, #2196F3, #9ecaff, #f9abff)
                               from-primary-container via-primary to-secondary

Circular progress SVG gradient: #2196F3 → #7B1FA2 → #F9ABFF (3-stop)

Toggle enabled gradient:       #2196F3 → #9C27B0

Ambient background glow:       radial-gradient from primary-container/20 + secondary-container/20
```

### 3.7 Key Component Patterns

#### Bottom Navigation Bar (Mobile — 4 tabs)
```
Tabs:          Media | Languages | Studio | Support
Icons:         video_library | language | graphic_eq | favorite
Active state:  bg-gradient-to-r from-primary-container to-secondary-container
               text-on-primary
               shadow-[0_4px_20px_rgba(33,150,243,0.35)]
               rounded-full pill shape
Inactive:      text-on-surface-variant
Container:     fixed bottom-0, bg-surface/90, backdrop-blur-xl
               shadow-[0_-4px_24px_rgba(0,0,0,0.6)]
Home indicator: w-32 h-1 bg-surface-variant rounded-full mx-auto mb-1.5 opacity-60
```

#### Top Header Bar (Mobile)
```
Container:     fixed top-0, h-16, bg-surface/85, backdrop-blur-xl
Left:          Profile image (w-8 h-8 rounded-full) + App name "Captionary" + section label
Right:         Support pill button with coffee icon + purple glow
```

#### Desktop Navigation Bar (Web)
```
Container:     fixed top-0, h-20, max-w-7xl centered, bg-surface/85, backdrop-blur-xl
               border-b border-outline-variant/30
Left:          Logo (w-9 h-9) + "Captionary" + version badge
Center:        Nav pills (About Project | GitHub | Transparency Ledger | Docs)
               Active: bg-surface-container-highest rounded-full shadow-inner
Right:         "Support Us" gradient pill + "Launch Studio App" ghost pill
```

#### Primary Button (Gradient Pill)
```
Shape:         rounded-full (9999px)
Background:    bg-gradient-to-r from-primary-container to-secondary-container
Text:          text-on-primary (white against blue/purple gradient)
Font:          font-label-lg text-label-lg font-medium
Shadow:        shadow-[0_4px_20px_rgba(33,150,243,0.35)]
Active:        active:scale-95 transition-all
Padding:       px-space-xl py-space-sm (or px-space-md py-space-xs for smaller)
```

#### Secondary Button (Ghost Pill)
```
Shape:         rounded-full (9999px)
Background:    bg-surface-container (or bg-surface-container-high)
Text:          text-on-surface (or text-on-surface-variant)
Font:          font-label-lg text-label-lg font-medium
Hover:         hover:bg-surface-bright
Active:        active:scale-98 transition-all
```

#### Status Chips
```
Ready/Verified: bg-tertiary-container/20 text-tertiary + check_circle icon filled
Processing:     bg-[#FFC107]/15 text-[#FFC107] + sync icon (animated spin)
New:            bg-surface-bright text-on-surface + fiber_new icon (secondary color)
Pending:        bg-secondary-container/30 text-secondary + sync icon (animated spin)
Ready to Edit:  bg-primary-container/20 text-primary + edit_note icon
```

### 3.8 Icon Reference (Material Symbols Outlined)

Below is the complete list of every Material Symbols icon used across all HTML prototypes. These must all be available locally.

**Mobile screens icons:**
```
arrow_back_ios_new, movie, tune, more_vert, fullscreen, closed_caption,
replay_10, pause, play_arrow, forward_10, volume_up, aspect_ratio,
graphic_eq, translate, check_circle, done_all, language, video_library,
favorite, local_cafe, video_file, auto_awesome, data_usage, model_training,
wifi_off, arrow_forward, fiber_new, edit_note, sync, check, search,
pie_chart, cloud_sync, record_voice_over, download, delete, verified,
ad_units, arrow_back, undo, redo, zoom_in, content_cut, splitscreen,
edit, format_size, opacity, palette, subtitles, local_fire_department,
close, motion_photos_on, timer, memory, campaign, share, replay,
open_in_new, bolt, lock, account_balance, forum, lock_open_right,
coffee, chevron_right
```

**Web screens icons:**
```
lock, record_voice_over, cloud, check_circle, open_in_new, code,
terminal, arrow_outward, groups, star, favorite, diamond, bolt,
local_cafe, article, search, menu_book, settings, auto_awesome,
play_circle, new_releases, arrow_forward, expand_more, check, close,
rocket_launch, info, timeline, schedule, account_balance_wallet,
visibility, receipt_long, savings, trending_up, dns, cloud_sync,
tune, currency_exchange, volunteer_activism, verified, download,
share, celebration, auto_fix_high, link
```

---

## Phase 1 — Pre-Migration Setup

### Phase 1.1 — Flutter Project Initialization
- [x] **1.1.1** Create Flutter project inside `flutter_mobile/` directory:
  ```bash
  cd flutter_mobile
  flutter create --org com.captionary --project-name captionary .
  ```
- [x] **1.1.2** Verify Flutter project compiles and runs:
  ```bash
  cd flutter_mobile
  flutter run
  ```
- [x] **1.1.3** Clean out default counter app code from `lib/main.dart`

### Phase 1.2 — React-TS Project Initialization
- [x] **1.2.1** Create Vite + React-TS project inside `react_frontend/` directory:
  ```bash
  cd react_frontend
  npm create vite@latest ./ -- --template react-ts
  ```
- [x] **1.2.2** Install dependencies:
  ```bash
  cd react_frontend
  npm install
  npm install react-router-dom
  ```
- [x] **1.2.3** Verify React project compiles and runs:
  ```bash
  cd react_frontend
  npm run dev
  ```
- [x] **1.2.4** Clean out default Vite boilerplate (remove `App.css` content, counter code, etc.)

### Phase 1.3 — Asset Collection & Local Setup

#### Phase 1.3.1 — Lexend Font (for both projects)
- [x] **1.3.1a** Download Lexend variable font `.ttf` file from Google Fonts GitHub repo: https://github.com/googlefonts/lexend
  - File needed: `Lexend-VariableFont_wght.ttf` (supports weights 100-900 in one file)
  - OR download individual weight `.ttf` files: Lexend-Light.ttf (300), Lexend-Regular.ttf (400), Lexend-Medium.ttf (500), Lexend-SemiBold.ttf (600), Lexend-Bold.ttf (700)
- [x] **1.3.1b** Place font files in Flutter:
  ```
  flutter_mobile/assets/fonts/Lexend-VariableFont_wght.ttf
  ```
- [x] **1.3.1c** Register font in `flutter_mobile/pubspec.yaml`:
  ```yaml
  flutter:
    fonts:
      - family: Lexend
        fonts:
          - asset: assets/fonts/Lexend-VariableFont_wght.ttf
  ```
- [x] **1.3.1d** For React: Install `@fontsource/lexend` npm package:
  ```bash
  cd react_frontend
  npm install @fontsource/lexend
  ```
  Then import in `src/main.tsx`:
  ```typescript
  import '@fontsource/lexend/300.css';
  import '@fontsource/lexend/400.css';
  import '@fontsource/lexend/500.css';
  import '@fontsource/lexend/600.css';
  import '@fontsource/lexend/700.css';
  ```

#### Phase 1.3.2 — Material Symbols Icons (for both projects)
- [x] **1.3.2a** Flutter: Add `material_symbols_icons` package to `pubspec.yaml`:
  ```yaml
  dependencies:
    material_symbols_icons: ^4.2801.0  # or latest
  ```
  Then run:
  ```bash
  flutter pub get
  ```
- [x] **1.3.2b** React: Install `@fontsource/material-symbols-outlined` package:
  ```bash
  cd react_frontend
  npm install @fontsource/material-symbols-outlined
  ```
  Then import in `src/main.tsx`:
  ```typescript
  import '@fontsource/material-symbols-outlined';
  ```

#### Phase 1.3.3 — Logo & Image Assets
- [x] **1.3.3a** Copy `captionary_logo.png` from `prototypes/html_mobile_version/captionary_logo.png` to:
  - `flutter_mobile/assets/images/captionary_logo.png`
  - `react_frontend/src/assets/images/captionary_logo.png`
- [x] **1.3.3b** Register image assets in Flutter `pubspec.yaml`:
  ```yaml
  flutter:
    assets:
      - assets/images/
  ```
- [x] **1.3.3c** Generate placeholder images for thumbnail previews that appear in the HTML prototypes. The HTML prototypes use Google-hosted images (lh3.googleusercontent.com) for:
  - Video thumbnail: Podcast microphone scene (home_local_media_library item 1)
  - Video thumbnail: Victoria Falls scene (home_local_media_library item 2)
  - Video thumbnail: Futuristic stage scene (home_local_media_library item 3)
  - Video thumbnail: Dance performance scene (home_local_media_library item 4)
  - Video canvas: Street interview Harare scene (custom_video_player)
  - Video canvas: Content creator in studio (subtitle_creator_studio)
  - Profile avatar placeholder
  - Captionary speech ribbon logo variant (encoding progress)
  - About page hero logo variant (web)

  **Strategy:** Generate solid-color gradient placeholder images (using the design system's primary-container to secondary-container gradient) sized appropriately, OR use Flutter's built-in `Container` with gradient decorations as placeholders. For React, create CSS gradient placeholders. These must be stored locally:
  ```
  flutter_mobile/assets/images/placeholder_thumbnail_1.png
  flutter_mobile/assets/images/placeholder_thumbnail_2.png
  flutter_mobile/assets/images/placeholder_thumbnail_3.png
  flutter_mobile/assets/images/placeholder_thumbnail_4.png
  flutter_mobile/assets/images/placeholder_video_canvas.png
  flutter_mobile/assets/images/placeholder_studio_canvas.png
  flutter_mobile/assets/images/placeholder_avatar.png

  react_frontend/src/assets/images/placeholder_hero.png
  react_frontend/src/assets/images/placeholder_avatar.png
  ```

  **Alternative (Recommended for speed):** Use colored Container/div boxes with gradient backgrounds as placeholders instead of image files. This avoids needing to generate image files.

### Phase 1.4 — Design System Implementation

#### Phase 1.4.1 — Flutter Theme Setup
- [x] **1.4.1a** Create `lib/theme/app_colors.dart` — define ALL color constants from Section 3.1 above as `static const Color` values
- [x] **1.4.1b** Create `lib/theme/app_typography.dart` — define ALL text styles from Section 3.2 as `static const TextStyle` values using the Lexend font family
- [x] **1.4.1c** Create `lib/theme/app_spacing.dart` — define ALL spacing constants from Section 3.3 as `static const double` values
- [x] **1.4.1d** Create `lib/theme/app_radius.dart` — define ALL border radius values from Section 3.4
- [x] **1.4.1e** Create `lib/theme/app_shadows.dart` — define ALL box shadow values from Section 3.5
- [x] **1.4.1f** Create `lib/theme/app_theme.dart` — compose a `ThemeData` with custom `ColorScheme`, text theme, and component themes. Set `useMaterial3: true`, `brightness: Brightness.dark`, and map ALL design tokens to the `ColorScheme` properties
- [x] **1.4.1g** Create `lib/theme/app_gradients.dart` — define all gradient `LinearGradient` constants from Section 3.6

#### Phase 1.4.2 — React CSS Design System Setup
- [x] **1.4.2a** Create `src/styles/variables.css` — define ALL colors as CSS custom properties (`--color-surface: #131313;` etc.)
- [x] **1.4.2b** Create `src/styles/typography.css` — define ALL text style classes (`.text-display-lg`, `.text-headline-xl`, etc.) with exact font-size, line-height, letter-spacing, and font-weight values
- [x] **1.4.2c** Create `src/styles/spacing.css` — define ALL spacing values as CSS custom properties
- [x] **1.4.2d** Create `src/styles/components.css` — define reusable component classes for buttons, chips, cards, etc.
- [x] **1.4.2e** Update `src/index.css` — import all CSS modules, set dark body background (#0A0A0A), set default font-family to Lexend, hide scrollbars, set `overscroll-behavior: none`
- [x] **1.4.2f** Alternatively (Recommended): Create a single comprehensive `src/styles/design-system.css` file that contains all the above, since the HTML prototypes use Tailwind utility classes which can be translated to a utility-class approach or component-specific CSS

---

## Phase 2 — Flutter Mobile Migration

> **Goal:** Recreate all 6 mobile HTML screens as Flutter widgets with exact visual fidelity.

### Phase 2.1 — Shared Widgets

- [x] **2.1.1** Create `lib/widgets/bottom_nav_bar.dart` — the shared bottom navigation bar with 4 tabs (Media, Languages, Studio, Support) that:
  - Uses Material Symbols icons: `video_library`, `language`, `graphic_eq`, `favorite`
  - Active tab has gradient pill background with glow shadow
  - Inactive tabs have `on-surface-variant` color
  - Container has frosted glass effect (semi-transparent surface + backdrop blur)
  - Includes home indicator bar at bottom (w-32 h-1 rounded-full)
  - Uses `Theme.of(context)` for all colors

- [x] **2.1.2** Create `lib/widgets/app_header.dart` — the shared top app bar that:
  - Shows profile avatar (circular, 32x32) on the left
  - Shows "Captionary" title + section label below it
  - Shows "Support" pill button with coffee icon + purple glow on the right
  - Has frosted glass background (surface/85 + backdrop blur)
  - Fixed at top, height 64px

- [x] **2.1.3** Create `lib/widgets/sub_screen_header.dart` — alternative header for sub-screens (Video Player, Export) that:
  - Shows back arrow button (circular) on the left
  - Shows screen title next to it
  - Shows Support pill + profile avatar on the right

- [x] **2.1.4** Create `lib/widgets/gradient_pill_button.dart` — reusable primary gradient pill button
- [x] **2.1.5** Create `lib/widgets/ghost_pill_button.dart` — reusable secondary ghost pill button
- [x] **2.1.6** Create `lib/widgets/status_chip.dart` — reusable status chip widget (ready/processing/new/pending variants)
- [x] **2.1.7** Create `lib/widgets/support_pill.dart` — the "Support" button with coffee icon and purple glow

### Phase 2.2 — Screen: Home / Media Library

**Source:** `prototypes/html_mobile_version/home_local_media_library/code.html`
**Target:** `lib/screens/media_library_screen.dart`

- [x] **2.2.1** Create `lib/screens/media_library_screen.dart`
- [x] **2.2.2** Implement the **Language Pack Status Banner** — a pill-shaped banner showing:
  - Green pulsing dot (tertiary color)
  - "Language Pack: English (Default)" text
  - "Ready" badge chip
  - Chevron right icon
  - Taps navigate to Language Pack screen
  
- [x] **2.2.3** Implement the **Hero Import Card** — centered card with:
  - Ambient gradient glow blobs (positioned absolute, blurred)
  - Circular upload badge icon with gradient ring and `video_file` icon
  - "Import Video Storage" headline
  - "Supports MP4, MOV, MKV up to 4K 60fps..." description
  - "Browse Media" gradient pill button with `auto_awesome` icon

- [x] **2.2.4** Implement the **Quick Stats Pill Row** — horizontal scrollable row of 3 stat pills:
  - "2.4 GB Cached" with `data_usage` icon (primary)
  - "5 Models Installed" with `model_training` icon (secondary)
  - "Offline Ready" with `wifi_off` icon (tertiary)

- [x] **2.2.5** Implement the **Section Header** — "Recent Media" with count badge "4" and "View All" link

- [x] **2.2.6** Implement the **Recent Media List** — 4 media item cards, each with:
  - Thumbnail image (80x80, rounded-xl) with gradient overlay and duration badge
  - File name (truncated), file size, resolution
  - Status chip (Transcribed, Pending Audio Sync, Ready to Edit, New)
  - More options (vertical dots) button
  - Hover/tap scale effect on thumbnail
  
  **Media items data:**
  1. `Podcast_Ep14_Raw.mp4` — 142 MB, 1080p, 04:12 — "Transcribed (Shona)" ready
  2. `Victoria_Falls_Trip.mp4` — 58 MB, 4K 60fps, 01:45 — "Pending Audio Sync" processing
  3. `AI_Keynote_2025.mov` — 410 MB, 1080p, 12:30 — "Ready to Edit"
  4. `Afrobeats_Snippet.mp4` — 34 MB, Vertical 9:16, 00:58 — "New"

### Phase 2.3 — Screen: Language Pack Manager

**Source:** `prototypes/html_mobile_version/language_pack_manager/code.html`
**Target:** `lib/screens/language_packs_screen.dart`

- [x] **2.3.1** Create `lib/screens/language_packs_screen.dart`
- [x] **2.3.2** Implement **Page Header** with "Language Packs" headline + "R2 Sync Active" badge
- [x] **2.3.3** Implement **Search Input** — pill-shaped, with search icon prefix and tune icon suffix
- [x] **2.3.4** Implement **Storage Summary Card** — showing:
  - "Model Storage" label with pie_chart icon
  - "1.4 GB / 10 GB" counter
  - Multi-segment progress bar (green for installed, blue for primary, yellow animated for downloading, gray for available)
  - Legend: "Installed" (green) + "Downloading" (yellow) + "8.6 GB Available"
  
- [x] **2.3.5** Implement **Language Cards List** (5 cards):
  1. **Shona (chiShona)** — Ready/Verified, Small 470MB High Accuracy (v2.1), Delete button
  2. **isiZulu (Zulu)** — Downloading 68%, Medium 820MB Neural Whisper Engine, linear progress bar (yellow, 68%), "4.8 MB/s 558 MB / 820 MB", "ETA: 54s", Abort button
  3. **Sepedi (Northern Sotho)** — Not downloaded, Small 460MB Fast Inference, "Download (460MB)" button
  4. **French (Francais)** — Not downloaded, Standard 510MB Multilingual, "Download (510MB)" button
  5. **English (US/UK Built-in)** — Active Default (verified icon filled), Bundled 280MB Core Model, "Locked" label, "System fallback and real-time punctuation enhancer" description

- [x] **2.3.6** Implement **AdMob Placeholder** — card with ad_units icon, "[Ad Space] Google AdMob Adaptive Banner", support text

### Phase 2.4 — Screen: Subtitle Creator Studio

**Source:** `prototypes/html_mobile_version/subtitle_creator_studio_styling_editor/code.html`
**Target:** `lib/screens/studio_screen.dart`

- [x] **2.4.1** Create `lib/screens/studio_screen.dart`
- [x] **2.4.2** Implement **Top Utility Toolbar** — rounded pill bar with:
  - Back button + red pulsing recording dot + "00:02:14" timecode
  - Undo, Redo, Settings (tune) icon buttons on right

- [x] **2.4.3** Implement **Video Preview Canvas** (16:9 aspect ratio):
  - Placeholder image/gradient with slight opacity
  - Scrim gradient overlay (bottom to top)
  - Active subtitle text overlay with highlight word styling ("instant" in green box)
  - "Live 4K Style" floating badge (top-left)
  - Play/Pause floating button (bottom-right)

- [x] **2.4.4** Implement **Timeline and Waveform Studio** — card containing:
  - Track header ("Audio Waveform Track") with zoom/cut buttons
  - Time ruler marks (00:01 through 00:05)
  - Waveform visualization using CustomPaint or Container with gradient bars
  - Playhead indicator (vertical line with dot, secondary color with glow)
  - Subtitle blocks: preceding chunk (dimmed) + active selected chunk (with glow frame, gradient left bar, editable text input, trim handles)

- [x] **2.4.5** Implement **Style Toolbar** with 4 tabs (Presets | Text and Font | Animation | Colors):
  - Tab bar: active tab has gradient background, others plain
  - **Presets carousel** (horizontal scroll):
    1. "TikTok Bold" — selected (check badge), "BOUNCE" preview text in green
    2. "IG Highlight" — "Reels Pill" preview
    3. "Classic Movie" — "Minimal Cinema" preview
    4. "Neon Flow" — "KARAOKE" preview with blue glow
  - **Font Scale slider** (14-48, current: 24px)
  - **Box Opacity slider** (0-100, current: 80%)
  - **Active Word Accent** color picker (green selected with check, blue, purple, yellow, custom palette button)

- [x] **2.4.6** Implement **Action Buttons**:
  - 2-column grid: "Export .SRT" + "Re-align AI"
  - Full-width: "Burn Captions to Video" (gradient pill with fire icon)

### Phase 2.5 — Screen: Video Player / Auto-Detection

**Source:** `prototypes/html_mobile_version/custom_video_player_auto_detection/code.html`
**Target:** `lib/screens/video_player_screen.dart`

- [x] **2.5.1** Create `lib/screens/video_player_screen.dart`
- [x] **2.5.2** Implement **Sub-Screen Header** with back button + "Timeline Editor" title + Support pill + avatar
- [x] **2.5.3** Implement **File Details Bar** — movie icon + "Street_Interview_Harare.mp4" + "1080p 1.0x Audio 48kHz 24fps" + tune/more buttons
- [x] **2.5.4** Implement **Video Canvas** (16:9) with:
  - Placeholder image/gradient
  - Top overlay: "REC SYNC" badge (red) + "Stereo (L/R)" badge + fullscreen button
  - Bottom overlay: Active caption text with word-by-word coloring (primary/secondary/on-surface/variant)
  
- [x] **2.5.5** Implement **Transport and Scrubber Bar**:
  - Audio waveform bars (varying heights, colored by position)
  - Progress bar with gradient fill (26%)
  - Glowing playhead thumb with inner dot
  - Timecodes: "00:01:23" (primary) and "00:05:40" (variant)
  - Playback controls: speed (1.0x), closed captions, skip back 10s, play/pause (gradient pill), skip forward 10s, volume, aspect ratio

- [x] **2.5.6** Implement **Auto-Detect Language Modal**:
  - Drag handle pill at top
  - Pulsing graphic_eq icon with green dot indicator
  - "Speech Engine Active" headline + "Neural v4" badge
  - "Analyzing audio track with on-device acoustic model..." description
  - Detected language card: "Shona (chiShona)" with "98% Match" badge
  - "98% confidence score, 14 words sampled in Harare dialect"
  - "Shona Language Pack installed and ready" with green check
  - "Use Shona Pack" gradient pill button
  - "Select Different Pack" ghost pill button

### Phase 2.6 — Screen: Support & Community

**Source:** `prototypes/html_mobile_version/support_community_mobile_app/code.html`
**Target:** `lib/screens/support_screen.dart`

- [x] **2.6.1** Create `lib/screens/support_screen.dart`
- [x] **2.6.2** Implement **Hero Spotlight** with:
  - Ambient radial gradient glow behind logo
  - "Open-Source and Independent" status pill with pulsing green dot
  - Captionary logo with gradient halo ring (use local `captionary_logo.png`)
  - "Support Independent AI Speech" headline
  - Mission description text mentioning Shona, isiZulu, Sepedi
  - Stats grid (3 columns): "1,420+ Global Backers" (primary) | "18.5k+ Models Funded" (secondary) | "4 Dialects Preserved" (tertiary)

- [x] **2.6.3** Implement **Web Contribution Gateway Card** with:
  - Gradient bleed-over decoration
  - Bolt icon + "Web Contribution Gateway" label
  - "Fuel Our Infrastructure" headline
  - Description about EcoCash, Paynow, international cards, crypto
  - "Open Web Donation Portal" gradient pill button with open_in_new icon
  - Lock icon + "captionary.ai/support Opens safely in default browser" helper text

- [x] **2.6.4** Implement **Direct Impact Grid** (3 impact cards):
  1. cloud_sync icon (primary) — "Cloudflare R2 Bandwidth" + description
  2. tune icon (secondary) — "Dialect Fine-Tuning Compute" + description
  3. lock_open_right icon (tertiary) — "100% Free and AGPL-3.0 Licensed" + description

- [x] **2.6.5** Implement **Community and Accountability Links** (3 action rows):
  1. account_balance icon then "Public Financial and Cost Ledger" then "GitHub" (primary, external)
  2. forum icon then "Join Creator Community and Council" then "Discord" (secondary, external)
  3. record_voice_over icon then "Request New African Dialect Pack" then "Submit" (tertiary, external)

- [x] **2.6.6** Implement **Sign-off Badge** with heart icon and "Crafted for mobile creators..." text

### Phase 2.7 — Screen: Video Encoding / Export Progress

**Source:** `prototypes/html_mobile_version/video_encoding_export_progress/code.html`
**Target:** `lib/screens/export_screen.dart`

- [x] **2.7.1** Create `lib/screens/export_screen.dart`
- [x] **2.7.2** Implement **View Switcher** — 2 toggle tabs:
  - "State A: In Progress" (active: primary-container fill)
  - "State B: Finished" (inactive: text variant)

- [x] **2.7.3** Implement **State A: Encoding In Progress**:
  - Context bar: pulsing green dot + "Engine: Whisper + FFmpeg Core" + "Abort" button (red)
  - **Circular Progress Indicator** (custom SVG/Canvas):
    - 256x256 container with glow underlay
    - Background circle track (#201f1f)
    - Progress arc with 3-stop gradient (#2196F3, #7B1FA2, #F9ABFF) at 45%
    - Center: Captionary logo (bouncing animation) + "45" percentage text + "%" suffix
  - "Encoding 1080p 60fps" headline with spinning icon
  - "Burned subtitles, High precision audio-sync" description
  - "Est. Time Remaining: 32s" badge pill (tertiary)
  - Hardware details card: "Hardware Acceleration ON (Mali GPU)" + "Bitrate: 14 Mbps, H.264 High"
  - AdMob banner: campaign icon, "Empower Regional AI Speech", "Monetising idle time..." description, "Learn" button

- [x] **2.7.4** Implement **State B: Export Complete**:
  - Success card with glow burst decoration
  - Glowing green check_circle icon (44px, filled)
  - "Export Complete!" headline
  - "Your subtitled video is ready..." description
  - File metadata card: movie icon + "Street_Interview_Harare_Subtitled.mp4" + "48.2 MB, MP4 (1080p 60fps), Synced 100%"
  - 2-column action buttons: "Preview" (ghost) + "Share Video" (gradient)
  - Community support banner with heart icon, description, avatar stack (SN/ZW/SA initials), "Buy a Coffee" button
  - "Re-encode with other settings" link

---

## Phase 3 — React-TypeScript Web Migration

> **Goal:** Recreate all 6 web HTML screens as React-TS components with exact visual fidelity.

### Phase 3.1 — Shared Components

- [x] **3.1.1** Create `src/components/DesktopNavbar.tsx` — the shared desktop navigation bar matching the HTML exactly:
  - Logo (w-9 h-9, rounded) + "Captionary" + "V2.4 CORE" version badge
  - Nav pills: About Project | GitHub | Transparency Ledger | Docs
  - Active state: `bg-surface-container-highest` with shadow-inner
  - "Support Us" gradient pill + "Launch Studio App" ghost pill
  - Fixed top, frosted glass background, border-bottom

- [x] **3.1.2** Create `src/components/Footer.tsx` — if any common footer exists across pages
- [x] **3.1.3** Create `src/components/GradientPillButton.tsx` — reusable primary button
- [x] **3.1.4** Create `src/components/GhostPillButton.tsx` — reusable secondary button
- [x] **3.1.5** Create `src/components/MaterialIcon.tsx` — wrapper component for Material Symbols Outlined icons
- [x] **3.1.6** Create `src/layouts/MainLayout.tsx` — layout wrapper with navbar + content area + max-width container

### Phase 3.2 — Page: About Project

**Source:** `prototypes/html_web_version/about_project_desktop/code.html`
**Target:** `src/pages/AboutProject.tsx`

- [x] **3.2.1** Create `src/pages/AboutProject.tsx`
- [x] **3.2.2** Implement **Hero Section** with ambient glow, mission pill badge, logo with spectral ring, gradient headline text, subheadline, 4-stat grid
- [x] **3.2.3** Implement **Three Pillars Section** with "Core Philosophy" header, 3 pillar cards (Privacy-First, Indigenous Dialect Preservation, third pillar), each with icon, label, headline, description, and footer badge
- [x] **3.2.4** Implement remaining sections from the HTML (read the full file to identify all sections — the file is 359 lines with team section, CTA, etc.)

### Phase 3.3 — Page: Documentation

**Source:** `prototypes/html_web_version/documentation_desktop/code.html`
**Target:** `src/pages/Documentation.tsx`

- [x] **3.3.1** Create `src/pages/Documentation.tsx`
- [x] **3.3.2** Implement all sections from the HTML prototype exactly as designed

### Phase 3.4 — Page: GitHub Ecosystem

**Source:** `prototypes/html_web_version/github_ecosystem_desktop/code.html`
**Target:** `src/pages/GitHubEcosystem.tsx`

- [x] **3.4.1** Create `src/pages/GitHubEcosystem.tsx`
- [x] **3.4.2** Implement all sections from the HTML prototype exactly as designed

### Phase 3.5 — Page: Payment Confirmation

**Source:** `prototypes/html_web_version/payment_confirmation_gratitude_desktop/code.html`
**Target:** `src/pages/PaymentConfirmation.tsx`

- [x] **3.5.1** Create `src/pages/PaymentConfirmation.tsx`
- [x] **3.5.2** Implement all sections from the HTML prototype exactly as designed

### Phase 3.6 — Page: Support / Donation Portal

**Source:** `prototypes/html_web_version/support_donation_portal_desktop/code.html`
**Target:** `src/pages/SupportDonation.tsx`

- [x] **3.6.1** Create `src/pages/SupportDonation.tsx`
- [x] **3.6.2** Implement all sections from the HTML prototype exactly as designed

### Phase 3.7 — Page: Transparency Ledger

**Source:** `prototypes/html_web_version/transparency_ledger_desktop/code.html`
**Target:** `src/pages/TransparencyLedger.tsx`

- [x] **3.7.1** Create `src/pages/TransparencyLedger.tsx`
- [x] **3.7.2** Implement all sections from the HTML prototype exactly as designed

---

## Phase 4 — Navigation & Routing

### Phase 4.1 — Flutter Navigation

- [x] **4.1.1** Create `lib/navigation/app_router.dart` — define all routes:
  ```
  /              -> MediaLibraryScreen (home, with bottom nav)
  /languages     -> LanguagePacksScreen (with bottom nav)
  /studio        -> StudioScreen (with bottom nav)
  /support       -> SupportScreen (with bottom nav)
  /player        -> VideoPlayerScreen (no bottom nav, sub-screen)
  /export        -> ExportScreen (no bottom nav, sub-screen)
  ```
- [x] **4.1.2** Create `lib/screens/main_shell.dart` — scaffold with IndexedStack or PageView for bottom nav tab switching
- [x] **4.1.3** Wire bottom nav bar tabs to switch between the 4 main screens
- [x] **4.1.4** Add navigation triggers:
  - From Media Library: tap media item navigates to Video Player screen
  - From Language Pack Status Banner: navigates to Language Packs screen
  - From Studio "Burn Captions to Video": navigates to Export screen
  - Back buttons on sub-screens navigate back
- [x] **4.1.5** Add `go_router` dependency to `pubspec.yaml`:
  ```yaml
  dependencies:
    go_router: ^14.0.0  # or latest
  ```

### Phase 4.2 — React Router Setup

- [x] **4.2.1** Create `src/router/AppRouter.tsx` — define all routes:
  ```
  /                -> AboutProject (default landing page)
  /github          -> GitHubEcosystem
  /transparency    -> TransparencyLedger
  /docs            -> Documentation
  /support         -> SupportDonation
  /payment-success -> PaymentConfirmation
  ```
- [x] **4.2.2** Update `src/App.tsx` to use `Routes` and `Route` from react-router-dom
- [x] **4.2.3** Update `src/main.tsx` to wrap App in `BrowserRouter`
- [x] **4.2.4** Wire desktop navbar links to route correctly using `Link` or `NavLink`
- [x] **4.2.5** Add active state styling to navbar based on current route (useLocation)
- [x] **4.2.6** Add "Support Us" button navigation to `/support`
- [x] **4.2.7** Ensure all internal links use client-side routing (no full page reloads)

---

## Phase 5 — Verification & Polish

### Phase 5.1 — Flutter Verification

- [x] **5.1.1** Run `flutter analyze` — fix all lint warnings
- [x] **5.1.2** Run `flutter build apk --debug` — ensure successful build
- [x] **5.1.3** Test on Android emulator (or physical device):
  - [x] All 4 bottom nav tabs switch correctly
  - [x] All 6 screens render without overflow errors
  - [x] Scrolling works on screens with long content
  - [x] Gradient buttons render correctly
  - [x] All icons display correctly (Material Symbols)
  - [x] Lexend font renders at all weight levels
  - [x] All colors match the design tokens
  - [x] Back navigation works on sub-screens
- [x] **5.1.4** Screenshot each screen and compare side-by-side with HTML prototype rendered in a browser
- [x] **5.1.5** Fix any visual discrepancies

### Phase 5.2 — React Verification

- [x] **5.2.1** Run `npm run build` — ensure successful production build with no TypeScript errors
- [x] **5.2.2** Run `npm run dev` and test in browser:
  - [x] All 6 pages render correctly
  - [x] Desktop navbar active state highlights correctly per route
  - [x] Client-side routing works (no page reloads)
  - [x] All icons display correctly (Material Symbols Outlined)
  - [x] Lexend font renders at all weight levels
  - [x] All colors match the design tokens
  - [x] Responsive layouts work (if applicable)
  - [x] Gradient buttons and glow shadows render correctly
- [x] **5.2.3** Screenshot each page and compare side-by-side with HTML prototype
- [x] **5.2.4** Fix any visual discrepancies

### Phase 5.3 — Final Asset Audit

- [x] **5.3.1** Verify NO external CDN calls exist in Flutter code (grep for http or https in lib/)
- [x] **5.3.2** Verify NO external CDN calls exist in React code (grep for googleapis.com, cdn. in src/)
- [x] **5.3.3** Verify Captionary logo renders correctly on both platforms
- [x] **5.3.4** Verify all placeholder images are local assets or CSS gradients (no broken images)

---

## Asset Dependency Matrix

### Flutter Dependencies (pubspec.yaml)

| Package | Purpose | Version |
|---------|---------|---------|
| `flutter` | Core SDK | SDK default |
| `material_symbols_icons` | Material Symbols icon font (offline) | Latest |
| `go_router` | Declarative routing | Latest |
| `google_fonts` | NOT NEEDED — Lexend font is bundled locally via assets/fonts | Do not use |

### React Dependencies (package.json)

| Package | Purpose |
|---------|---------|
| `react` | Core library |
| `react-dom` | DOM rendering |
| `react-router-dom` | Client-side routing |
| `@fontsource/lexend` | Lexend font files (offline, bundled at build time) |
| `@fontsource/material-symbols-outlined` | Material Symbols icon font (offline, bundled at build time) |
| `typescript` | Type checking |
| `vite` | Build tool |
| `@vitejs/plugin-react` | Vite React plugin |

---

## File Structure Maps

### Flutter Project Structure

```
flutter_mobile/
  assets/
    fonts/
      Lexend-VariableFont_wght.ttf
    images/
      captionary_logo.png
      # Note: Placeholders for thumbnails and avatars were implemented 
      # using native Flutter code-generated gradients and containers.
  lib/
    main.dart
    theme/
      app_colors.dart
      app_typography.dart
      app_spacing.dart
      app_radius.dart
      app_shadows.dart
      app_gradients.dart
      app_theme.dart
    navigation/
      app_router.dart
    widgets/
      bottom_nav_bar.dart
      app_header.dart
      sub_screen_header.dart
      gradient_pill_button.dart
      ghost_pill_button.dart
      status_chip.dart
      support_pill.dart
    screens/
      main_shell.dart
      media_library_screen.dart
      language_packs_screen.dart
      studio_screen.dart
      support_screen.dart
      video_player_screen.dart
      export_screen.dart
  pubspec.yaml
```

### React Project Structure

```
react_frontend/
  src/
    main.tsx
    App.tsx
    index.css
    assets/
      images/
        captionary_logo.png
    styles/
      variables.css
      typography.css
      components.css
      design-system.css
    components/
      DesktopNavbar.tsx
      GradientPillButton.tsx
      GhostPillButton.tsx
      MaterialIcon.tsx
    layouts/
      MainLayout.tsx
    pages/
      AboutProject.tsx
      Documentation.tsx
      GitHubEcosystem.tsx
      PaymentConfirmation.tsx
      SupportDonation.tsx
      TransparencyLedger.tsx
    router/
      AppRouter.tsx
  package.json
  tsconfig.json
  vite.config.ts
  index.html
```

---

## Execution Order Summary

```
Phase 1 (Setup)
  1.1 Flutter init
  1.2 React init  
  1.3 Asset collection (fonts, icons, logo, placeholders)
  1.4 Design system implementation (both platforms)

Phase 2 (Flutter Screens) — depends on Phase 1
  2.1 Shared widgets (bottom nav, headers, buttons)
  2.2 Media Library screen
  2.3 Language Packs screen
  2.4 Studio screen
  2.5 Video Player screen
  2.6 Support screen
  2.7 Export screen

Phase 3 (React Pages) — depends on Phase 1, can run parallel to Phase 2
  3.1 Shared components (navbar, buttons)
  3.2 About Project page
  3.3 Documentation page
  3.4 GitHub Ecosystem page
  3.5 Payment Confirmation page
  3.6 Support Donation page
  3.7 Transparency Ledger page

Phase 4 (Navigation) — depends on Phases 2 and 3
  4.1 Flutter navigation
  4.2 React routing

Phase 5 (Verification) — depends on Phase 4
  5.1 Flutter testing
  5.2 React testing
  5.3 Asset audit
```

---

> **Note for AI Executors:** When implementing each screen, you MUST read the corresponding `code.html` file from the `prototypes/` directory to extract EVERY detail — every class, every color, every icon name, every text string, every shadow, every spacing value. The HTML files are the single source of truth. The design tokens in Section 3 provide the systematic mapping, but the HTML files contain the exact layout structure and component hierarchy you must replicate.

