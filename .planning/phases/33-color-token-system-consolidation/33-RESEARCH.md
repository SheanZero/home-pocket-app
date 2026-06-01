# Phase 33: Color Token System & Consolidation — Research

**Researched:** 2026-06-01
**Domain:** Flutter ThemeExtension migration, semantic design-token system, full app-wide dark-mode rollout
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Full migration to Flutter `ThemeExtension<AppPalette>`. ALL color references — existing `AppColors.*` static refs, `context.wm*` extension getters, AND ADR-018's new roles — resolve via `Theme.of(context).extension<AppPalette>()`. Light + dark instances carry the full ADR-018 hex tables.
- **D-02:** Full migration boundary — every call site changes. Not partial. Every `AppColors.daily`/`context.wmCard` style reference is rewritten to read from the ThemeExtension.
- **D-03:** All decorative literals fold INTO the token system as named roles. No separate non-semantic constants file. Avatar color-wheel presets + neutral overlays become named tokens. `soft_toast.dart`'s red group = `error` semantic family, NOT decorative.
- **D-04:** Re-hue decorative colors to the Teal/neutral family. Avatar presets and tinted overlays get new hex consistent with Teal Clarity. Pure hue-neutral alpha-only overlays stay as-is.
- **D-05:** Hero gradient → `daily #1C7A86` → `joy #F0A81E`. Remove `_joyTargetStartColor`/`_joyTargetEndColor` duplicate constants; source from ledger tokens directly.
- **D-06:** olive (trends) merged — no longer a distinct token. Target (success vs daily) is planner's/Claude's call.
- **D-07:** Full dark-mode rollout — every screen responds to dark mode. Pulls THEME-V2-02 forward into Phase 33.
- **New roles:** `dailyText`/`joyText`/`sharedText` amount-text variants + explicit `success`/`warning`/`error`/`info` family via the same ThemeExtension.
- **Residual cleanup:** `wmSurvivalTagBg`/`wmSoulTagBg` stale getter names renamed to `daily`/`joy` semantics as part of D-01/D-02.
- **Hex authority:** ADR-018 is the ONLY source of truth for every hex value. No hex may be introduced that is not present in ADR-018's role table.

### Claude's Discretion

- olive merge target (D-06): success vs daily — planner decides from chart co-occurrence context (research below provides the evidence).
- Whether `AppColors`/`AppColorsDark` static classes survive as internal raw-hex sources for the two ThemeExtension instances, or are deleted entirely.
- Exact new hex for re-hued decorative tokens (D-04) — avatar presets, tinted overlays — within the Teal/neutral family; not in ADR-018.
- Derived values (`*Border`, `*Chevron`, `fabGradient*`, shadows) — may be fine-tuned from anchor hex during Phase 33.
- Migration sequencing / verification strategy.

### Deferred Ideas (OUT OF SCOPE)

- Runtime theming / user-selectable accent palettes (THEME-V2-01).
- Typography / spacing / component redesign.
- Any changes other than color token migration and dark-mode adaptation.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| COLOR-01 | Zero `Color(0x…)` literals in `lib/features/`, `lib/application/`, `lib/shared/` | Literal inventory (§Literal Inventory) identifies all 61 literals by file and classification; ThemeExtension pattern (§Architecture Patterns) enables the routing strategy |
| COLOR-02 | Selected ADR-018 palette applied consistently across all surfaces | ADR-018 hex table verified; ledger accent usage map and dark adaptation strategy (§Dark Mode Rollout) covers every surface |
| COLOR-03 | Single semantic token system; duplicate constants like `_joyTargetStartColor` removed | ThemeExtension structure (§Standard Stack); duplicate inventory confirmed (§Literal Inventory); D-05 removal strategy in §Pitfalls |
</phase_requirements>

---

## Summary

Phase 33 has two parallel workstreams of roughly equal effort: **(1) the token system migration** — replacing the existing `AppColors`/`AppColorsDark` static-const pattern and `context.wm*` extension with a single `ThemeExtension<AppPalette>` carrying ADR-018 hex for both light and dark, and replacing all 61 hardcoded `Color(0x…)` literals in `lib/features/` with named palette tokens; and **(2) the full dark-mode rollout** — adding dark adaptation to the 15 screens and 8 widgets that currently have none (which is the bulk of the scope expansion from D-07).

The ThemeExtension migration is idiomatic Flutter 3.x: define one class with all semantic roles as `final Color` fields, implement `copyWith`/`lerp`, instantiate a light and a dark instance from ADR-018's hex table, register both in `app_theme.dart`'s `ThemeData(extensions: [...])`, and replace every call site. The 61 feature literals fall into five classification buckets; the largest single bucket is coral-gradient FAB/CTA copies (8 occurrences in 4 `family_sync` screens) that map directly to `accentPrimary`/`fabGradient*` tokens.

For D-06 (olive merge), analysis confirms that `AppColors.olive` co-appears with `AppColors.daily` on the same rendering surface in two places: the `HomeHeroCard._trendChip` (trend %, next to the daily/joy split bar in the same card) and the `FamilyInsightCard` (analytics screen, rendered in the same scroll view as `DailyVsJoyCard`). **Merging olive into `daily` would cause a same-color collision in both surfaces.** Merging into `success` (`#2FA37A`, emerald green) avoids collision with `daily` (`#1C7A86`, teal-navy) and `joy` (`#F0A81E`, gold) simultaneously. The `MonthlySpendTrendBarChart` uses `AppColors.daily` for its bar fill — this is an existing misuse (trends shown as daily blue) that the migration should correct by re-pointing it to the success/olive successor token.

**Primary recommendation:** Migrate in 4 ordered waves: (W0) new `AppPalette` ThemeExtension class + light/dark instances + `app_theme.dart` registration; (W1) migrate `app_theme_colors.dart` call sites + delete stale extension; (W2) migrate all 61 feature literals; (W3) dark-mode adaptation for the 15 no-dark screens + 8 no-dark widgets. Maintain `flutter analyze 0` throughout by keeping `AppColors`/`AppColorsDark` as a transitional shim until W2 is complete, then delete.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Token definition (hex values, semantic roles) | Theme Layer (`lib/core/theme/`) | — | Single source of truth; owned by `AppPalette` ThemeExtension + `app_theme.dart` |
| ThemeData registration (light + dark) | Theme Layer (`lib/core/theme/app_theme.dart`) | — | `ThemeData(extensions: [AppPalette.light])` / `AppPalette.dark` |
| Call-site access in widgets | Feature Presentation Layer | — | `Theme.of(context).extension<AppPalette>()!` or BuildContext extension |
| Dark-mode toggle (system / user) | App shell (`MaterialApp.themeMode`) | Already wired in `main.dart` via Riverpod `themeModeProvider` | No new infrastructure; screens just need to read from the ThemeExtension |
| Amount text color (WCAG) | Theme Layer (AppPalette `*Text` roles) | Feature Presentation (via `AppTextStyles.*` that accept color param) | `AppTextStyles.amountLarge.copyWith(color: palette.dailyText)` pattern |

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Flutter `ThemeExtension` | built-in (Flutter 3.44 used) | Custom semantic palette attached to `ThemeData` | Official Flutter API since 3.0; idiomatic for Design Token systems; no extra dependency [VERIFIED: api.flutter.dev/flutter/material/ThemeExtension-class.html] |
| `flutter_riverpod` | ^3.1.0 (already in pubspec) | `themeModeProvider` drives `MaterialApp.themeMode` | Already wired; no change needed [VERIFIED: pubspec.yaml in codebase] |

### Supporting

No new packages are required for this phase. All tooling (`flutter analyze`, `build_runner`, `flutter test --update-goldens`) is already present.

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Manual `ThemeExtension` class | `theme_tailor` code generator | Generator reduces boilerplate but adds a dev dependency + build_runner annotation; for a one-time migration of ~50 fields, manual is leaner. CONTEXT.md does not mention code generators. [ASSUMED] |
| `ThemeExtension` single class | Two separate extensions (palette + decorative) | Single class is simpler to access; one `palette!` null-assert at the extension getter level rather than two. No ADR constraint forces split. |

**Installation:** No new packages.

---

## Package Legitimacy Audit

> No new external packages are introduced in this phase. The audit is not applicable.

---

## Architecture Patterns

### System Architecture Diagram

```
ADR-018 hex table
        │
        ▼
┌─────────────────────────────────────────────────────┐
│  lib/core/theme/                                     │
│  ┌──────────────────────┐  ┌───────────────────────┐│
│  │ app_colors.dart       │  │ app_palette.dart (NEW)││
│  │ (raw hex constants    │  │ ThemeExtension<       ││
│  │  — kept as internal   │  │   AppPalette>         ││
│  │  shim, deleted W2     │  │ .light / .dark static ││
│  │  end)                 │  │ instances             ││
│  └──────────────────────┘  └──────────┬────────────┘│
│  ┌──────────────────────┐             │              │
│  │ app_theme.dart        │◄────────── │              │
│  │ ThemeData(            │            │              │
│  │  extensions:[         │            │              │
│  │   AppPalette.light])  │            │              │
│  │ ThemeData.dark(       │            │              │
│  │  extensions:[         │            │              │
│  │   AppPalette.dark])   │            │              │
│  └──────────────────────┘             │              │
│  ┌──────────────────────┐             │              │
│  │ app_theme_colors.dart │  DELETED   │              │
│  │ (context.wm* getters) │◄── W1 ────┘              │
│  └──────────────────────┘                            │
└─────────────────────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────────────────────┐
│  Feature widgets / screens                           │
│  Theme.of(context).extension<AppPalette>()!          │
│  or BuildContext extension: context.palette.*        │
│                                                      │
│  Color(0x…) literals ──W2──► palette.<role>          │
│  AppColors.* refs     ──W2──► palette.<role>          │
│  context.wm* refs     ──W1──► palette.<role>          │
│  No-dark screens      ──W3──► palette.background etc.│
└─────────────────────────────────────────────────────┘
        │
        ▼
  flutter analyze 0 + build_runner clean-diff
  COLOR-01/02/03 grep gate green
```

### Recommended Project Structure

```
lib/core/theme/
├── app_palette.dart        # NEW — ThemeExtension<AppPalette> class + .light + .dark
├── app_theme.dart          # MODIFIED — registers AppPalette.light / AppPalette.dark
├── app_text_styles.dart    # MODIFIED — amount styles reference palette (via copyWith at call site)
├── app_colors.dart         # TRANSITIONAL — kept as internal shim during W0-W2; deleted at W2 end
└── app_theme_colors.dart   # DELETED at W1 end
```

### Pattern 1: ThemeExtension Class Definition

**What:** Define `AppPalette extends ThemeExtension<AppPalette>` with all ADR-018 roles as `final Color` fields, plus two `static const` factory instances (`light`, `dark`).

**When to use:** Single definition in `lib/core/theme/app_palette.dart`.

```dart
// Source: https://api.flutter.dev/flutter/material/ThemeExtension-class.html [VERIFIED]
import 'package:flutter/material.dart';

final class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    // Backgrounds
    required this.background,
    required this.card,
    required this.backgroundMuted,
    required this.backgroundSubtle,
    required this.backgroundDivider,
    // Text
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    // Borders
    required this.borderDefault,
    required this.borderDivider,
    required this.borderList,
    required this.borderInputActive,
    // Accent — Primary (Teal)
    required this.accentPrimary,
    required this.accentPrimaryLight,
    required this.accentPrimaryBorder,
    required this.fabGradientStart,
    required this.fabGradientEnd,
    // Ledger — Daily
    required this.daily,
    required this.dailyText,      // WCAG ≥4.5:1 amount text
    required this.dailyLight,
    // Ledger — Joy
    required this.joy,
    required this.joyText,        // WCAG ≥4.5:1 amount text
    required this.joyLight,
    // Ledger — Shared
    required this.shared,
    required this.sharedText,     // WCAG ≥4.5:1 amount text
    required this.sharedLight,
    required this.sharedBorder,
    required this.sharedChevron,
    // Semantic
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    // Joy card (satisfaction / ROI) — previously profile-scoped dark only
    required this.joyFullnessBg,
    required this.joyFullnessBorder,
    required this.joyRoiBg,
    required this.joyRoiBorder,
    required this.familyBadgeBg,
    // Decorative — avatar presets (D-04 re-hued)
    required this.avatarGradientStart,  // new teal-family hex (D-04)
    required this.avatarGradientMid,
    required this.avatarGradientEnd,
    // Decorative — member tile presets (D-04 re-hued)
    required this.memberGradientA,
    required this.memberGradientB,
    required this.memberGradientC,
    // Best Joy strip — satisfaction pill (re-mapped to joy family)
    required this.satisfactionPillBg,
    required this.satisfactionPillRose,
    // Misc retained tokens
    required this.surfaceCream,
    required this.surfaceCreamBorder,
    required this.textMutedGold,
    required this.navShadow,
    required this.actionShadow,
    required this.fabShadow,
    required this.recordingGradientStart,
    required this.recordingGradientEnd,
  });

  // ── Backgrounds ──
  final Color background;
  final Color card;
  final Color backgroundMuted;
  final Color backgroundSubtle;
  final Color backgroundDivider;
  // … (all fields as above)

  static const light = AppPalette(
    background: Color(0xFFF8FCFD),      // ADR-018
    card: Color(0xFFFFFFFF),
    // … all ADR-018 light values
    // Decorative (D-04 planner picks teal-family hex):
    avatarGradientStart: Color(0xFFE0F4F5), // e.g. accentPrimaryLight tint
    // ...
  );

  static const dark = AppPalette(
    background: Color(0xFF0C1719),      // ADR-018
    card: Color(0xFF162527),
    // … all ADR-018 dark values
  );

  @override
  AppPalette copyWith({
    Color? background,
    // … all nullable params
  }) {
    return AppPalette(
      background: background ?? this.background,
      // …
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      // … Color.lerp all Color fields
    );
  }
}
```

### Pattern 2: ThemeData Registration

**What:** Register both instances in `app_theme.dart`.

```dart
// Modified app_theme.dart — Source: codebase + Flutter docs [VERIFIED]
import 'app_palette.dart';

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorSchemeSeed: const Color(0xFF0E9AA7), // accentPrimary teal
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF8FCFD),
    fontFamily: 'Outfit',
    extensions: const [AppPalette.light],     // ← registration
    // ... other ThemeData params
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    colorSchemeSeed: const Color(0xFF0E9AA7),
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0C1719),
    fontFamily: 'Outfit',
    extensions: const [AppPalette.dark],      // ← registration
    // ...
  );
}
```

### Pattern 3: BuildContext Access Ergonomics

**What:** Replace `context.wmCard` style with `context.palette.card`. Keep the extension-getter pattern — just point to the ThemeExtension instead of the brightness ternary.

```dart
// New lib/core/theme/app_palette.dart (bottom of file, or separate extension file)
extension AppPaletteContext on BuildContext {
  AppPalette get palette =>
    Theme.of(this).extension<AppPalette>()!;
}

// Usage in widgets (replaces context.wmCard, context.wmTextPrimary, etc.):
color: context.palette.card
color: context.palette.textPrimary
color: context.palette.daily
```

This replaces all 107 existing `context.wm*` call sites (36×`wmTextPrimary`, 34×`wmTextSecondary`, 10×`wmCard`, etc. — see §Literal Inventory) with `context.palette.*` equivalents.

### Pattern 4: Amount Text Color (CLAUDE.md constraint)

**What:** `AppTextStyles.amount*` are `static const` so they cannot hardcode palette colors. Amount-text-with-ledger-color must be applied via `copyWith` at the call site.

```dart
// Source: CLAUDE.md "Amount Display Style" + ADR-018 *Text roles [VERIFIED]
// For daily ledger amount text (WCAG ≥4.5:1):
Text(
  amount,
  style: AppTextStyles.amountLarge.copyWith(
    color: context.palette.dailyText,  // #145E68 light / #4FB0BC dark
  ),
)
// For joy ledger amount text:
Text(
  amount,
  style: AppTextStyles.amountMedium.copyWith(
    color: context.palette.joyText,    // #9A6500 light / #F0C13A dark
  ),
)
// NOTE: joy #F0A81E is tag/affordance ONLY — never use for amount text (ADR-018)
```

### Pattern 5: Dark-Mode Adaptation for Screens

**What:** Screens currently using `isDark ? AppColorsDark.X : AppColors.X` patterns (e.g. `transaction_edit_screen.dart`) must be migrated to `context.palette.X`. Screens with NO dark adaptation must be updated to read all colors from `context.palette` which automatically resolves light/dark.

```dart
// BEFORE (profile screens pattern — brittle, duplicated):
final isDark = Theme.of(context).brightness == Brightness.dark;
backgroundColor: isDark ? _editDarkBackground : AppColors.background,

// AFTER (ThemeExtension pattern):
backgroundColor: context.palette.background,
// No isDark check needed — extension resolves from ThemeData.brightness
```

### Anti-Patterns to Avoid

- **Hardcoded `Color(0x…)` in feature files after migration:** COLOR-01 grep gate will catch these.
- **`AppColors.daily` for both split-bar color AND trend chip (olive):** after olive merge, trend chip must use `palette.success`, not `palette.daily` — they co-appear on the same card surface.
- **`joy #F0A81E` for amount text:** it fails WCAG on white card. ALWAYS use `joyText #9A6500` (light) / `#F0C13A` (dark) for numeric amounts (ADR-018 constraint, CLAUDE.md Amount Display Style).
- **Parallel `survival*`/`soul*` naming:** Phase 31 already renamed these. Use only `daily`/`joy` identifier names (ADR-017, Pitfall 4 in CONTEXT.md).
- **Inventing new hex values not in ADR-018:** All semantic role hex must come from ADR-018. Only D-04 decorative re-hue values are Claude's discretion (within the Teal/neutral family), and they should be derived from existing ADR-018 anchor colors.
- **Removing the `-lsqlite3` Podfile strip:** CLAUDE.md iOS Build section — do NOT touch Podfile during this phase.
- **Modifying generated files** (`.g.dart`, `.freezed.dart`): color migration does not touch generated Dart.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Theme-aware color resolution | Manual `isDark ? dark : light` ternaries | `ThemeExtension<AppPalette>` + `context.palette.*` | ThemeExtension is the idiomatic Flutter 3.x pattern; ternaries scattered across 60+ files are the problem we're solving |
| Color lerp | Custom lerp math | `Color.lerp(a, b, t)!` | Flutter built-in; handles null safety + alpha correctly |
| WCAG amount text | Derive colors manually | Use ADR-018 `*Text` variants directly (`dailyText #145E68`, `joyText #9A6500`, `sharedText #3A6396`) | Already WCAG-verified by ADR-018 |

---

## Literal Inventory & Classification

### Confirmed Count

**61 `Color(0x…)` literals in `lib/features/`** (verified by grep). Zero in `lib/application/` or `lib/shared/`. [VERIFIED: grep in codebase]

### Classification by Bucket

**Bucket A — Profile Dark Constants (duplicated 4×) — 16 literals**

Four profile screens each define the same 4 dark-mode constants inline (not in `AppColorsDark`):
- `avatar_picker_screen.dart`: `_profileDark{Background|Surface|TextPrimary|TextSecondary}`
- `profile_edit_screen.dart`: `_editDark{Background|Surface|TextPrimary|TextSecondary}`
- `profile_onboarding_screen.dart`: `_onboardingDark{Background|Surface|TextPrimary|TextSecondary}`
- `ocr_scanner_screen.dart`: 1 literal `Color(0xFF1A2530)` (dark background variant)

All map to `AppColorsDark` background/surface/text roles, which become `AppPalette.dark.*`. D-01 migration eliminates all duplicates.

Hex values: `0xFF141418`, `0xFF2A2A32`, `0xFFF0F0F5`, `0xFF6B6B78` (repeated 3-4×). Note: these profile-screen dark values differ from ADR-018's background (`#0C1719`)/card (`#162527`). The ADR-018 values are authoritative; planners should verify whether profile screens should align to the new ADR-018 dark background or keep a distinct darker surface. **[ASSUMED — needs planner judgment]**

**Bucket B — Coral/CTA Gradient Copies — 12 literals in 4 family_sync screens**

`create_group_screen.dart`, `member_approval_screen.dart`, `confirm_join_screen.dart`, `join_group_screen.dart` each repeat:
```
Color(0xFFE85A4F), Color(0xFFF08070)  → fabGradientEnd / fabGradientStart  (Teal: #0E9AA7 / #2BB6C2)
Color(0x28E85A4F)                     → actionShadow (alpha-only → keep alpha, change RGB to teal)
Color(0x0A000000)                     → surface overlay (pure black alpha → stays as-is, D-04)
```

**Bucket C — Avatar / Member Color-Wheel Presets — 9 literals**

`avatar_display.dart`: light gradient `[0xFFFFD4CC, 0xFFFEEAE6, 0xFFFEF5F4]`, dark gradient `[0xFF3D2020, 0xFF2D1818, 0xFF251518]`.
`member_list_tile.dart`, `member_approval_screen.dart`, `group_choice_screen.dart`, `join_group_screen.dart`: purple presets `[0xFFE8D5F5, 0xFFF3EAF9, 0xFFFAF5FD]`.

These are decorative (D-03): become named tokens `avatarGradient*` and `memberGradient{A|B|C}`. D-04 re-hues them to Teal/neutral family — planner derives teal-tinted versions (e.g., from `accentPrimaryLight #E0F4F5` family for light; from `backgroundMuted #213537` family for dark).

**Bucket D — Alpha-Only Overlays — 4 literals**

`0x26FFFFFF`, `0x80FFFFFF` (avatar border), `0x14000000`, `0x0A000000` (scrim overlays). Pure alpha, no hue — D-04 keeps these unchanged but names them: `avatarBorderAlpha`, `surfaceScrimLight`, `surfaceScrimMedium`. They become tokens for COLOR-01 compliance.

**Bucket E — Soft Toast Error Family — 7 literals**

`soft_toast.dart`: `0xFFFEF2F2` (bg), `0xFFFECACA` (border), `0x15E53E3E` (shadow), `0xFFDC2626` (icon/text, ×4). Per D-03, these are the `error` semantic family: `errorSurface`, `errorBorder`, `errorShadow`, `error`. Maps to ADR-018 `error #E5484D` + derived tints. Planner should derive `errorSurface` and `errorBorder` from ADR-018's `error #E5484D` in a consistent way (e.g., 10%/20% opacity on white for light, analogous for dark).

**Bucket F — Other Feature-Specific — 13 literals**

- `list_calendar_header.dart`: `_weekendColor 0xFF1565C0` (Material Blue 800), `_todayColor 0xFFD32F2F` (Material Red 700). Weekend = could map to `info #2A8FB8`; today = `error #E5484D`. [ASSUMED — planner judgment]
- `category_selection_screen.dart`: `0xFFABABAB` (default category color fallback) → maps to `textSecondary`.
- `scattered_emoji_background.dart`: `0xFFF0F0F5` (dark emoji color) → maps to `textPrimary` (dark value `#E8F2F3`).
- `group_choice_screen.dart`: `_greenGradient [0xFFD4E8CC, 0xFFF0F8EC]` (green gradient, cosmetic) → D-04 re-hue to teal-tinted; `iconBackgroundColor 0xFFFEF5F4` → `accentPrimaryLight #E0F4F5`.
- `home_hero_card.dart`: `_joyTargetStartColor 0xFF47B88A`, `_joyTargetEndColor 0xFFD9A441` → D-05 REMOVES, replaces with `palette.daily`/`palette.joy` in `joyTargetProgressColor()`.

### AppColors Non-Literal Call Sites (not counted in 61 but must migrate per D-02)

All `AppColors.*` static refs in `lib/features/` must be replaced by `context.palette.*` (or passed as parameter). From grep: ~130 usages across ~50 files. The migration approach: global find-replace `AppColors.X` → `palette.X` within widget `build()` methods.

### Stale context.wm* Getters to Replace

107 usages across features:

| Getter | Count | Maps to |
|--------|-------|---------|
| `wmTextPrimary` | 36 | `palette.textPrimary` |
| `wmTextSecondary` | 34 | `palette.textSecondary` |
| `wmCard` | 10 | `palette.card` |
| `wmBorderDefault` | 7 | `palette.borderDefault` |
| `wmBorderDivider` | 5 | `palette.borderDivider` |
| `wmSurvivalTagBg` | 4 | `palette.dailyLight` (rename D-01) |
| `wmSoulTagBg` | 3 | `palette.joyLight` (rename D-01) |
| `wmBackgroundDivider` | 3 | `palette.backgroundDivider` |
| `wmTextTertiary` | 2 | `palette.textTertiary` |
| Others (NavShadow, FamilyBadgeBg, BorderList) | 3 | `palette.navShadow`, `.familyBadgeBg`, `.borderList` |

---

## D-06 Olive Merge: Evidence and Recommendation

**Question:** Should `olive` (trends) merge into `success #2FA37A` or `daily #1C7A86`?

**Evidence from codebase:** [VERIFIED: grep of lib/features/]

1. **HomeHeroCard** (`home_hero_card.dart`): The `_trendChip` widget uses `AppColors.olive`/`AppColors.oliveLight` for the month-over-month trend percentage chip. This chip renders inline in `_hero()` which is region 1 of the card. Region 2 of the SAME card is `_splitBar()` which shows `AppColors.daily` and `AppColors.joy` as the two ledger labels + bars. **If olive → daily, the trend chip color equals the daily ledger label in the card directly above.**

2. **HappinessRingsPainter** (`home_hero_card.dart`, `_painter()`): In solo mode, the middle ring uses `AppColors.olive` (solid) as one of the three ring colors, alongside `AppColors.accentPrimary` (outer) and a lerp-from-daily-to-joy (inner). If olive → daily, the middle ring and inner ring start from the same hue.

3. **FamilyInsightCard** (`analytics_screen.dart`): Card background + border + title text use `AppColors.olive`. This card renders on the analytics screen. The analytics screen also renders `DailyVsJoyCard` which uses `AppColors.daily` and `AppColors.joy`. They are in the same scroll view. If olive → daily, FamilyInsightCard adopts the same teal hue as the daily ledger accent in the adjacent card — no distinct identity.

4. **MonthlySpendTrendBarChart**: Currently uses `AppColors.daily` for bar fills (this is an existing misuse — total spending trend is not "daily" data). Post-migration, this bar should use the `olive`→`success` successor token to correctly distinguish "total spend trend" from the daily ledger accent.

**Recommendation: olive → `success #2FA37A`.**

`success` is emerald green (`#2FA37A`), clearly distinct from `daily` teal-navy (`#1C7A86`) and `joy` gold (`#F0A81E`). The "trend" and "family insight" use-cases carry a "positive/neutral performance" reading that aligns with `success` semantics. Collisions are avoided on all three surfaces above. As a secondary benefit, `MonthlySpendTrendBarChart` corrects its existing color misuse by using a semantically distinct token.

Dark value: `success #3FC78E` (ADR-018, emerald brightened for dark backgrounds).

---

## Dark-Mode Rollout: Screen-by-Screen Inventory

D-07 is the bulk of the scope expansion. Here is the full audit. [VERIFIED: grep of lib/features/ for isDark/brightness/AppColorsDark/context.wm]

### Screens with NO dark adaptation (15 screens)

| Screen | Feature | Action Needed |
|--------|---------|---------------|
| `list_screen.dart` | list | Add `context.palette.*` for all color refs |
| `analytics_screen.dart` | analytics | Add `context.palette.*` (uses `AppColors.*` static refs) |
| `group_choice_screen.dart` | family_sync | Add `context.palette.*` + resolve Bucket B/C literals |
| `member_approval_screen.dart` | family_sync | Add `context.palette.*` + resolve Bucket B/C literals |
| `group_management_screen.dart` | family_sync | Add `context.palette.*` |
| `join_group_screen.dart` | family_sync | Add `context.palette.*` + resolve Bucket B/C literals |
| `create_group_screen.dart` | family_sync | Add `context.palette.*` + resolve Bucket B/C literals |
| `confirm_join_screen.dart` | family_sync | Add `context.palette.*` + resolve Bucket B/C literals |
| `waiting_approval_screen.dart` | family_sync | Add `context.palette.*` |
| `settings_screen.dart` | settings | Add `context.palette.*` |
| `main_shell_screen.dart` | home | Add `context.palette.*` |
| `ocr_scanner_screen.dart` | accounting | Resolve Bucket A literal + `context.palette.*` |
| `voice_input_screen.dart` (helpers) | accounting | Check for any hard color refs |
| `voice_locale_readiness_mixin.dart` | accounting | Check for any hard color refs |
| `voice_recognition_event_handler_mixin.dart` | accounting | Check for any hard color refs |

### Screens with PARTIAL dark adaptation (using `AppColorsDark.*` directly)

| Screen | Pattern | Migration |
|--------|---------|-----------|
| `transaction_edit_screen.dart` | `isDark ? AppColorsDark.X : AppColors.X` × 3 | Replace with `context.palette.X` |
| `ocr_review_screen.dart` | `isDark ? AppColorsDark.X : AppColors.X` × 3 | Replace with `context.palette.X` |
| `category_selection_screen.dart` | `isDark ? AppColorsDark.X : AppColors.X` × 8 | Replace with `context.palette.X` |

### Screens with FULL `context.wm*` dark adaptation (working, needs getter name update only)

Most widgets using `context.wmCard`, `context.wmTextPrimary` etc. — these just need getter names updated to `context.palette.*` (W1).

### Widgets with AppColors but NO dark adaptation (8 widgets)

| Widget | Colors to Adapt |
|--------|----------------|
| `list_empty_state.dart` | `AppColors.*` refs → `context.palette.*` |
| `list_calendar_header.dart` | `_weekendColor`, `_todayColor` → Bucket F tokens |
| `list_sort_filter_bar.dart` | `AppColors.*` refs |
| `list_transaction_tile.dart` | `AppColors.*` refs |
| `list_category_filter_sheet.dart` | `AppColors.*` refs |
| `list_day_group_header.dart` | `AppColors.*` refs |
| `member_list_tile.dart` | `AppColors.*` refs + Bucket C literals |
| `voice_waveform.dart` | `AppColors.*` refs |

---

## Runtime State Inventory

> Not applicable — this is a purely cosmetic refactor (color constant migration). No data migration, stored data, or OS-registered state is involved.

| Category | Items Found | Action Required |
|----------|-------------|-----------------|
| Stored data | None — color tokens are compile-time constants, not persisted | None |
| Live service config | None | None |
| OS-registered state | None | None |
| Secrets/env vars | None | None |
| Build artifacts | Golden PNG baselines in `test/golden/goldens/` (44 files) will differ after palette change | Phase 34 re-baselines all goldens; Phase 33 must NOT update golden baselines (leave for Phase 34) |

---

## Common Pitfalls

### Pitfall 1: `flutter analyze` Breaks Mid-Wave

**What goes wrong:** Removing `AppColors`/`AppColorsDark` before all call sites are migrated causes analyzer errors on every referencing file simultaneously.

**Why it happens:** The existing 130+ `AppColors.*` call sites in features are not wave-gated.

**How to avoid:** Keep `AppColors`/`AppColorsDark` as a **transitional shim** throughout W0–W2. Delete only after `grep -rn 'AppColors\.\|AppColorsDark\.' lib/features/ lib/application/ lib/shared/` returns zero hits. Maintain `flutter analyze 0` at every task boundary.

**Warning signs:** Any task that touches feature files should run `flutter analyze` before committing.

### Pitfall 2: joy Affordance Color Used for Amount Text

**What goes wrong:** Using `joy #F0A81E` for a monetary amount value fails WCAG AA contrast on white card (`card #FFFFFF`). `#F0A81E` is a light yellow-gold with ~2.8:1 contrast ratio — below the 4.5:1 threshold.

**Why it happens:** `AppColors.joy` is used in `home_hero_card.dart` split bar labels and color dots (affordance context) — these are fine. But if anyone copies that pattern for an amount number, it fails.

**How to avoid:** Amount text in ledger colors MUST use `palette.joyText #9A6500` (light) or `palette.joyText ≈ #F0C13A` (dark). The `AppTextStyles.amountLarge/Medium/Small` should document this. CLAUDE.md "Amount Display Style" enforces `tabularFigures` — add a comment noting the `*Text` color requirement.

**Warning signs:** Any `AppTextStyles.amount*` whose color comes from `palette.joy` directly (not `joyText`).

### Pitfall 3: Same-Color Collision if olive → daily

**What goes wrong:** If olive is mapped to `daily` (not `success`), the trend chip in `HomeHeroCard._trendChip` becomes the same teal as the daily ledger label in `_splitBar` on the same card. Users lose the "trend is neutral performance indicator" vs "daily is a ledger type" distinction.

**Why it happens:** D-06 leaves target as Claude's discretion; a planner without the collision evidence might choose `daily` for aesthetic reasons.

**How to avoid:** Map `olive` → `success`. All trend/analytics uses of `AppColors.olive` map to `palette.success #2FA37A` (light) / `palette.success #3FC78E` (dark).

### Pitfall 4: Inventing survival*/soul* Naming

**What goes wrong:** Creating `palette.survivalTag`/`palette.soulTag` symbols during migration.

**Why it happens:** The stale `wmSurvivalTagBg`/`wmSoulTagBg` getters in `app_theme_colors.dart` are seen and copied.

**How to avoid:** Phase 31 already renamed all identifiers. New names are `palette.dailyLight` (tag bg for daily) and `palette.joyLight` (tag bg for joy). Delete `wmSurvivalTagBg`/`wmSoulTagBg` at W1; do not port them.

### Pitfall 5: Profile-Screen Dark Values vs ADR-018 Dark Background

**What goes wrong:** The profile screens' hard-coded dark bg is `#141418` (nearly black). ADR-018's dark background is `#0C1719` (deep teal-black). They are different hues. Blindly migrating to `palette.background` changes the profile screen's dark appearance noticeably.

**Why it happens:** Profile screens were designed with their own dark palette before `AppColorsDark` existed.

**How to avoid:** During dark-mode adaptation (W3), confirm whether `palette.background #0C1719` is intentionally replacing `#141418` for profile screens (likely yes — single palette is the goal of D-07). Document this as an intentional visual change for Phase 34 golden re-baseline.

### Pitfall 6: Golden Tests Fail During Phase 33

**What goes wrong:** Palette change causes golden pixel mismatches in all 44 existing golden files, making `flutter test` red during the migration.

**Why it happens:** Golden tests compare against old coral-palette baseline snapshots.

**How to avoid:** Do NOT run `--update-goldens` during Phase 33. Golden tests WILL fail (expected) — they are Phase 34's responsibility. Use `flutter test --exclude-tags golden` or skip golden tests in CI during Phase 33. Planner should add a note: "Golden failures are expected until Phase 34."

---

## Code Examples

### Accessing palette in a widget

```dart
// Source: codebase pattern + Flutter official ThemeExtension docs [CITED: api.flutter.dev/flutter/material/ThemeExtension-class.html]
@override
Widget build(BuildContext context) {
  final palette = Theme.of(context).extension<AppPalette>()!;
  // Or via BuildContext extension:
  // final palette = context.palette;
  return Container(
    color: palette.card,
    child: Text(
      amount,
      style: AppTextStyles.amountMedium.copyWith(
        color: palette.dailyText,   // NOT palette.daily for amounts
      ),
    ),
  );
}
```

### Hero gradient (D-05)

```dart
// Source: CONTEXT.md D-05 + home_hero_card.dart current pattern [VERIFIED]
// BEFORE:
Color joyTargetProgressColor(double ratio) {
  return Color.lerp(_joyTargetStartColor, _joyTargetEndColor, ratio.clamp(0.0, 1.0))!;
}

// AFTER (D-05 — sources from palette, no more duplicate constants):
Color joyTargetProgressColor(double ratio, AppPalette palette) {
  return Color.lerp(palette.daily, palette.joy, ratio.clamp(0.0, 1.0))!;
}
// _joyTargetStartColor and _joyTargetEndColor are DELETED.
```

### Dark-mode adaptation conversion

```dart
// Source: transaction_edit_screen.dart existing pattern → after migration [VERIFIED: codebase]
// BEFORE:
final isDark = Theme.of(context).brightness == Brightness.dark;
backgroundColor: isDark ? AppColorsDark.background : AppColors.backgroundWarm,

// AFTER (ThemeExtension resolves):
backgroundColor: context.palette.background,
// No isDark needed — AppPalette.light.background and AppPalette.dark.background differ
```

### Decorative avatar token (D-04 re-hue pattern)

```dart
// Source: avatar_display.dart current pattern → after D-04 re-hue [VERIFIED: codebase]
// BEFORE:
static const _lightGradient = [
  Color(0xFFFFD4CC),   // coral pink — old identity
  Color(0xFFFEEAE6),
  Color(0xFFFEF5F4),
];

// AFTER (planner derives teal-family hex for D-04):
// In AppPalette.light:
// avatarGradientStart: Color(0xFF__TEAL_A),  // planner fills from ADR-018 teal family
// avatarGradientMid:   Color(0xFF__TEAL_B),
// avatarGradientEnd:   Color(0xFF__TEAL_C),
// In widget:
final colors = palette.isDark
    ? [palette.avatarGradientDarkStart, ...]
    : [palette.avatarGradientStart, ...];
// Pure alpha border stays as-is (D-04 exception):
border: Border.all(color: const Color(0x26FFFFFF), width: 2),  // alpha-only, OK
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Static `AppColors.*` + manual `isDark ? dark : light` ternary | `ThemeExtension<T>` registered in `ThemeData.extensions` | Flutter 3.0 (2022) | Automatic light/dark resolution; single source of truth |
| `ThemeData.primaryColor` for custom colors | `ThemeData.colorScheme` + `ThemeExtension` | Flutter 3.0+ | M3 uses `ColorScheme`; project-specific semantic tokens go in extensions |

**Deprecated/outdated:**
- `AppThemeColors` / `context.wm*` brightness-ternary pattern: functional but non-idiomatic; replaced by `ThemeExtension`
- Inline `const isDark` + `AppColorsDark.*` direct references: scattered, non-central; eliminated by ThemeExtension

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Profile screens' old dark bg `#141418` should be replaced by ADR-018 dark background `#0C1719` | §Dark Mode Rollout, Pitfall 5 | Profile screens look different in dark mode; may need user confirmation before Phase 34 golden re-baseline |
| A2 | `list_calendar_header._weekendColor #1565C0` → `info #2A8FB8` and `_todayColor #D32F2F` → `error #E5484D` | §Literal Inventory Bucket F | Calendar semantics may differ from ADR-018 intent; planner should verify the `today` highlight purpose |
| A3 | `ThemeExtension.lerp` implementation is required for correctness even though this project likely does not animate theme transitions | §Pattern 1 | Low risk — lerp is a required override; not implementing it causes compile errors |
| A4 | `AppColors`/`AppColorsDark` can be kept as transitional internal-only constants (not deleted until W2 end) rather than wrapped by the extension | §Pitfall 1 | None — this is an implementation sequencing choice with no observable behavior difference |

**Verified claims (no assumptions):** All hex values from ADR-018 are the authoritative source. All literal counts and file locations verified by grep in this session. All `context.wm*` getter usages verified by grep. `olive` co-occurrence with `daily` verified in codebase.

---

## Open Questions

1. **Profile screen dark background hex (`#141418` vs `#0C1719`)**
   - What we know: profile screens hard-coded `#141418` before a unified dark palette existed
   - What's unclear: whether `#141418` (near-black) vs `#0C1719` (teal-dark) is a meaningful design choice for the profile context, or an accident of history
   - Recommendation: treat as intentional alignment to ADR-018 (use `#0C1719`); document in Phase 34 golden expectations

2. **`surfaceCream`/`satisfactionPillBg`/`satisfactionPillRose` in `AppColors` — no ADR-018 counterpart**
   - What we know: these three "Best Joy strip" tokens (`0xFFFFFDF8`, `0xFFF1F1F1`, `0xFFD45F65`) are in `AppColors` but have no listed role in ADR-018's hex table
   - What's unclear: `satisfactionPillRose #D45F65` is coral-red — does this map to `error`, or does it map to `joy` in the new palette? The satisfaction pill is a UI affordance expressing "high joy score," not an error state.
   - Recommendation: `satisfactionPillBg` → derived from `joyLight #FBEFCF`; `satisfactionPillRose` → `joy #F0A81E` (joy affordance context; not amount text). Planner should confirm.

3. **Recording gradient (`recordingGradientStart #E05050`, `recordingGradientEnd #C03030`) — not in ADR-018 hex table**
   - What we know: recording state (mic button) uses red gradients independent of accent color (Phase 22 D-04)
   - What's unclear: should recording gradient stay red (as a distinct functional affordance) or adopt `error #E5484D` family?
   - Recommendation: recording gradient = `error` semantic family (`#E5484D`/`#F0676B` dark). Recording = "active/live" state which benefits from the universal red-danger signal.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | All | ✓ | 3.44.0 | — |
| Dart SDK | All | ✓ | ^3.10.8 | — |
| `flutter analyze` | Analyze gate | ✓ | bundled | — |
| `build_runner` | Code gen after changes | ✓ | ^2.4.14 | — |
| `flutter test` | Golden gate | ✓ | bundled | — |

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | flutter_test (bundled with Flutter SDK) |
| Config file | None — `flutter test` discovers tests in `test/` automatically |
| Quick run command | `flutter test --exclude-tags golden` |
| Full suite command | `flutter test` |
| Analyze command | `flutter analyze` |
| Grep gate command | `grep -rn 'Color(0x\|Color(0X' lib/features/ lib/application/ lib/shared/` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | Notes |
|--------|----------|-----------|-------------------|-------|
| COLOR-01 | Zero raw hex literals in `lib/features/` | grep gate | `grep -rn 'Color(0x\|Color(0X' lib/features/ lib/application/ lib/shared/'` returns 0 lines | Automated; run per task wave |
| COLOR-02 | Correct palette applied uniformly | Visual/golden | `flutter test test/golden/` (Phase 34) | Phase 33: golden tests WILL FAIL — expected. Skip in Phase 33 CI. |
| COLOR-03 | Single token system; no duplicate constants | analyze + grep | `flutter analyze` (0 issues); `grep -rn '_joyTargetStartColor\|_joyTargetEndColor\|_editDark\|_onboardingDark\|_profileDark' lib/` returns 0 | After W2 all profile-screen inline constants deleted |
| THEME-V2-02 (absorbed) | Every screen responds to dark mode | Widget test (new) | `flutter test test/widget/theme_dark_mode_coverage_test.dart` | Wave 0 gap — create test |
| (analyze gate) | 0 analyzer warnings | Static analysis | `flutter analyze` | Run at every task commit |

### Sampling Rate

- **Per task commit:** `flutter analyze` (mandatory, 0 issues)
- **Per wave merge:** `flutter analyze` + `grep -rn 'Color(0x' lib/features/' (must return 0 after W2)
- **Phase gate:** Full `flutter test --exclude-tags golden` green before `/gsd-verify-work`; golden tests deferred to Phase 34

### Wave 0 Gaps

- [ ] `test/widget/theme_dark_mode_coverage_test.dart` — verifies that a representative set of screens builds without error under `ThemeMode.dark` (widget pump + no exceptions)
- [ ] `test/architecture/color_literal_scan_test.dart` — architecture test that runs the COLOR-01 grep gate as a test case (mirrors the existing `stale_suppressions_scan_test.dart` pattern)
- [ ] AppPalette unit test `test/core/theme/app_palette_test.dart` — verifies: (a) `AppPalette.light` and `AppPalette.dark` are non-null constants; (b) `copyWith` returns a new instance; (c) `lerp` at `t=0.0` returns the original; (d) all required ADR-018 hex values match their expected literals

---

## Security Domain

> Phase 33 is a purely cosmetic refactor (color constants only). No authentication, session management, access control, input validation, cryptographic operations, or user data processing changes. Security domain is not applicable to this phase.

---

## Project Constraints (from CLAUDE.md)

| Directive | Impact on Phase 33 |
|-----------|-------------------|
| `flutter analyze` MUST be 0 issues before commit | Hard gate on every task; keep `AppColors` shim until all call sites migrated |
| `build_runner` clean-diff required | Run after any Riverpod/Freezed/Drift annotation changes; color migration does not touch those files but verify |
| Amount display: use `AppTextStyles.amountLarge/Medium/Small` with `tabularFigures` | Amount-colored text must use `.copyWith(color: palette.*Text)` not inline TextStyle |
| Widget parameter pattern: nullable + provider fallback | No color values should be hardcoded widget constructor defaults |
| Do NOT modify generated files (`.g.dart`, `.freezed.dart`) | Color migration does not touch generated files |
| `sqlcipher_flutter_libs` only (NOT `sqlite3_flutter_libs`) | No change from this phase |
| Podfile `post_install` strip preserved | Do NOT touch Podfile |
| `Thin Feature` rule | `AppPalette` definition stays in `lib/core/theme/`, not in a feature directory |
| Don't duplicate repository provider definitions | No providers in this phase |
| `daily`/`joy` identifier naming (ADR-017) | No `survival`/`soul` identifiers may be created |

---

## Sources

### Primary (HIGH confidence)

- ADR-018 (`docs/arch/03-adr/ADR-018_Palette_Selection_v1_5.md`) — all hex values, role names, WCAG rationale; verified in this session
- `lib/core/theme/app_colors.dart` — current symbol inventory (117 LOC); verified by Read
- `lib/core/theme/app_theme_colors.dart` — `context.wm*` getter inventory; verified by Read
- `lib/core/theme/app_theme.dart` — ThemeData registration point; verified by Read
- Grep of `lib/features/` — all 61 literal locations and all `context.wm*` usages; verified by Bash
- Flutter API docs: [ThemeExtension class](https://api.flutter.dev/flutter/material/ThemeExtension-class.html) — `copyWith`, `lerp`, registration pattern

### Secondary (MEDIUM confidence)

- [Flutter 3: How to extend ThemeData](https://medium.com/geekculture/flutter-3-how-to-extend-themedata-56b8923bf1aa) — BuildContext extension access pattern
- [Custom Theme using Theme Extensions](https://itnext.io/custom-theme-using-theme-extensions-8afb67248d2b) — idiomatic access pattern confirmed

### Tertiary (LOW confidence)

- None — all critical claims verified against codebase or official docs.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — ThemeExtension is the Flutter 3 official API; verified in Flutter 3.44 (used by project)
- Literal inventory: HIGH — verified by grep in this session (61 exact count)
- Architecture patterns: HIGH — verified against existing codebase and Flutter official docs
- Dark-mode rollout scope: HIGH — verified by grep (15 screens with no dark adaptation)
- Olive merge recommendation: HIGH — verified by code co-occurrence analysis
- Decorative re-hue hex values (D-04): LOW — not in ADR-018; planner derives from anchor colors

**Research date:** 2026-06-01
**Valid until:** 2026-07-01 (stable Flutter API; 30-day horizon)
