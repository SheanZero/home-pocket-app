# Phase 33: Color Token System & Consolidation — Pattern Map

**Mapped:** 2026-06-01
**Files analyzed:** 29 new/modified files
**Analogs found:** 29 / 29 (all have close analogs; no file is without precedent)

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/core/theme/app_palette.dart` (NEW) | config/theme | transform | `lib/core/theme/app_colors.dart` + `app_theme_colors.dart` | role-match: replaces both |
| `lib/core/theme/app_theme.dart` (MODIFIED) | config/theme | request-response | itself (current state) | exact |
| `lib/core/theme/app_text_styles.dart` (MODIFIED) | config/theme | transform | itself (current state) | exact |
| `lib/core/theme/app_colors.dart` (TRANSITIONAL→DELETED) | config/theme | — | itself | exact |
| `lib/core/theme/app_theme_colors.dart` (DELETED) | config/theme | — | itself | exact |
| `lib/features/home/presentation/widgets/home_hero_card.dart` (MODIFIED) | component | transform | itself (current state) | exact |
| `lib/features/profile/presentation/widgets/avatar_display.dart` (MODIFIED) | component | transform | itself | exact |
| `lib/features/accounting/presentation/widgets/soft_toast.dart` (MODIFIED) | component | event-driven | itself | exact |
| `lib/features/accounting/presentation/screens/transaction_edit_screen.dart` (MODIFIED) | component | request-response | itself | exact — has isDark pattern |
| `lib/features/accounting/presentation/screens/category_selection_screen.dart` (MODIFIED) | component | request-response | itself | exact — has isDark pattern |
| `lib/features/accounting/presentation/screens/ocr_review_screen.dart` (MODIFIED) | component | request-response | `transaction_edit_screen.dart` | exact — same isDark pattern |
| `lib/features/list/presentation/screens/list_screen.dart` (MODIFIED) | component | CRUD | `analytics_screen.dart` | role-match — same no-dark pattern |
| `lib/features/list/presentation/widgets/list_transaction_tile.dart` (MODIFIED) | component | CRUD | itself | exact — mixed wm*/AppColors pattern |
| `lib/features/list/presentation/widgets/list_empty_state.dart` (MODIFIED) | component | CRUD | `list_transaction_tile.dart` | role-match |
| `lib/features/list/presentation/widgets/list_calendar_header.dart` (MODIFIED) | component | CRUD | itself | exact — has Bucket F literals |
| `lib/features/list/presentation/widgets/list_sort_filter_bar.dart` (MODIFIED) | component | CRUD | `list_transaction_tile.dart` | role-match |
| `lib/features/list/presentation/widgets/list_day_group_header.dart` (MODIFIED) | component | CRUD | `list_transaction_tile.dart` | role-match |
| `lib/features/list/presentation/widgets/list_category_filter_sheet.dart` (MODIFIED) | component | CRUD | `list_transaction_tile.dart` | role-match |
| `lib/features/analytics/presentation/screens/analytics_screen.dart` (MODIFIED) | component | CRUD | itself | exact — pure AppColors.*, no dark |
| `lib/features/family_sync/presentation/screens/create_group_screen.dart` (MODIFIED) | component | event-driven | itself | exact — Bucket B literals |
| `lib/features/family_sync/presentation/screens/member_approval_screen.dart` (MODIFIED) | component | event-driven | `create_group_screen.dart` | exact — same Bucket B/C pattern |
| `lib/features/family_sync/presentation/screens/join_group_screen.dart` (MODIFIED) | component | event-driven | `create_group_screen.dart` | exact — same Bucket B/C pattern |
| `lib/features/family_sync/presentation/screens/confirm_join_screen.dart` (MODIFIED) | component | event-driven | `create_group_screen.dart` | exact — same Bucket B/C pattern |
| `lib/features/family_sync/presentation/screens/group_choice_screen.dart` (MODIFIED) | component | event-driven | `create_group_screen.dart` | role-match |
| `lib/features/family_sync/presentation/screens/group_management_screen.dart` (MODIFIED) | component | event-driven | `analytics_screen.dart` | role-match — no dark, AppColors.* refs |
| `lib/features/family_sync/presentation/screens/waiting_approval_screen.dart` (MODIFIED) | component | event-driven | `analytics_screen.dart` | role-match — no dark |
| `lib/features/settings/presentation/screens/settings_screen.dart` (MODIFIED) | component | CRUD | `analytics_screen.dart` | role-match — no dark |
| `lib/features/home/presentation/screens/main_shell_screen.dart` (MODIFIED) | component | request-response | `analytics_screen.dart` | role-match — no dark |
| `test/core/theme/app_palette_test.dart` (NEW) | test | — | `test/core/theme/app_colors_test.dart` | exact |
| `test/architecture/color_literal_scan_test.dart` (NEW) | test | — | `test/architecture/hardcoded_cjk_ui_scan_test.dart` | exact |
| `test/widget/theme_dark_mode_coverage_test.dart` (NEW) | test | — | `test/widget/features/home/presentation/widgets/home_hero_card_test.dart` | role-match |

---

## Pattern Assignments

### `lib/core/theme/app_palette.dart` (NEW — ThemeExtension definition)

**Analog:** `lib/core/theme/app_colors.dart` (symbol inventory source) + `lib/core/theme/app_theme_colors.dart` (brightness-resolution source)

**Imports pattern** — follows `app_colors.dart` (lines 1):
```dart
import 'dart:ui';
// NOTE: ThemeExtension requires package:flutter/material.dart, not just dart:ui
import 'package:flutter/material.dart';
```

**Static-const abstract-final class pattern** — from `app_colors.dart` (lines 3-76):
```dart
abstract final class AppColors {
  static const background = Color(0xFFFCFBF9);
  static const card = Color(0xFFFFFFFF);
  // ... every field is static const Color
}
```
New file inverts this: fields are `final` instance fields, and two `static const` instances (`light`, `dark`) carry the hex. The field names are inherited from the existing `AppColors` symbol inventory.

**Full symbol inventory to carry over** (from `app_colors.dart` lines 5-76 + `AppColorsDark` lines 79-117):
- Backgrounds: `background`, `card`, `backgroundMuted`, `backgroundSubtle`, `backgroundDivider`
- Text: `textPrimary`, `textSecondary`, `textTertiary`
- Borders: `borderDefault`, `borderDivider`, `borderList`, `borderInputActive`
- Accent primary: `accentPrimary`, `accentPrimaryLight`, `accentPrimaryBorder`, `fabGradientStart`, `fabGradientEnd`, `actionShadow`
- Recording: `recordingGradientStart`, `recordingGradientEnd`
- Ledger daily: `daily`, `dailyLight` **+ NEW** `dailyText` (WCAG amount text)
- Ledger joy: `joy`, `joyLight` **+ NEW** `joyText` (WCAG amount text)
- Ledger shared: `shared`, `sharedLight`, `sharedBorder`, `sharedChevron` **+ NEW** `sharedText` (WCAG amount text)
- Olive/trends: **REMOVED** (`olive`, `oliveLight`, `oliveBorder`); olive merges into `success` (see D-06)
- Shadows: `fabShadow`, `navShadow`
- Joy card: `joyFullnessBg`, `joyFullnessBorder`, `joyRoiBg`, `joyRoiBorder` (from `AppColorsDark`)
- Family: `familyBadgeBg` (from `AppColorsDark`)
- Best Joy strip: `surfaceCream`, `surfaceCreamBorder`, `textMutedGold`, `satisfactionPillBg`, `satisfactionPillRose`
- **NEW semantic family**: `success`, `warning`, `error`, `info`
- **NEW derived error tints**: `errorSurface`, `errorBorder` (replaces Bucket E literals)
- **NEW decorative tokens** (D-03/D-04): `avatarGradientStart`, `avatarGradientMid`, `avatarGradientEnd`, `avatarGradientDarkStart`, `avatarGradientDarkMid`, `avatarGradientDarkEnd`, `memberGradientA`, `memberGradientB`, `memberGradientC`, `avatarBorderAlpha`, `surfaceScrimLight`, `surfaceScrimMedium`
- **Dark-only tokens merged into single instance**: `tagBlue` (→ `dailyLight` dark), `tagGreen` (→ `joyLight` dark), `tagOrange` (→ `sharedLight` dark)

**Stale getters to NOT port** (from `app_theme_colors.dart` lines 59-65 — these names are dead):
```dart
// DELETED — do NOT port these getter names:
// wmSurvivalTagBg  →  palette.dailyLight
// wmSoulTagBg      →  palette.joyLight
```

**ThemeExtension required overrides** (from RESEARCH.md Pattern 1):
```dart
@override
AppPalette copyWith({Color? background, ...}) { ... }

@override
AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
  if (other is! AppPalette) return this;
  return AppPalette(
    background: Color.lerp(background, other.background, t)!,
    // Color.lerp all Color fields
  );
}
```

**BuildContext extension** (bottom of file, replacing `app_theme_colors.dart`'s entire extension pattern):
```dart
// Replaces the entire AppThemeColors extension (app_theme_colors.dart lines 10-65)
extension AppPaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}
// Usage: context.palette.card  (was: context.wmCard)
//        context.palette.daily (was: AppColors.daily)
```

---

### `lib/core/theme/app_theme.dart` (MODIFIED — ThemeExtension registration)

**Analog:** itself — `lib/core/theme/app_theme.dart`

**Current registration pattern** (lines 1-47 — the full file):
```dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorSchemeSeed: AppColors.accentPrimary,    // ← becomes teal Color(0xFF0E9AA7)
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: 'Outfit',
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        side: BorderSide(color: AppColors.borderDefault),
      ),
    ),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    colorSchemeSeed: AppColors.accentPrimary,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColorsDark.background,
    // ...
  );
}
```

**Migration diff** — add `extensions` list to both `ThemeData` blocks; update `colorSchemeSeed` to teal and `scaffoldBackgroundColor` to ADR-018 values; update `AppColors.*` refs to `AppPalette.light.*` / `AppPalette.dark.*`:
```dart
import 'app_palette.dart';  // replaces app_colors.dart import

static ThemeData get light => ThemeData(
  useMaterial3: true,
  colorSchemeSeed: AppPalette.light.accentPrimary,  // teal #0E9AA7
  brightness: Brightness.light,
  scaffoldBackgroundColor: AppPalette.light.background,
  fontFamily: 'Outfit',
  extensions: const [AppPalette.light],             // ← new line
  appBarTheme: AppBarTheme(
    backgroundColor: AppPalette.light.background,
    foregroundColor: AppPalette.light.textPrimary,
    elevation: 0,
  ),
  cardTheme: CardThemeData(
    color: AppPalette.light.card,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: const BorderRadius.all(Radius.circular(14)),
      side: BorderSide(color: AppPalette.light.borderDefault),
    ),
  ),
);
// dark ThemeData follows same structure with AppPalette.dark.*
```

---

### `lib/core/theme/app_text_styles.dart` (MODIFIED — remove static color refs)

**Analog:** itself — `lib/core/theme/app_text_styles.dart`

**Problem pattern** (lines 1-4 + 179-182 — current):
```dart
import 'app_colors.dart';
// ...
static const comparisonDelta = TextStyle(
  color: AppColors.olive,   // ← olive no longer exists; must be removed
);
```

**Migration:** Remove `import 'app_colors.dart'`. Replace `AppColors.textPrimary` static refs in `const` text styles with no color (leave color unset — callers apply `.copyWith(color: context.palette.textPrimary)`). The `comparisonDelta` style loses its `color:` field entirely (or uses `AppColors.textSecondary` until olive is gone). The `static const` constraint means text styles cannot reference `context.palette.*` directly — callers always use `.copyWith(color: ...)`.

**Amount text pattern that must be preserved** (lines 145-168):
```dart
static const amountLarge = TextStyle(
  fontFamily: _fontFamily,
  fontSize: 30,
  fontWeight: FontWeight.w700,
  height: 0.9,
  color: AppColors.textPrimary,      // ← becomes null or removed (color applied at call site)
  fontFeatures: _tabularFigures,     // ← MUST stay — tabularFigures is non-negotiable (CLAUDE.md)
);
```
Call-site pattern (WCAG amount text — from RESEARCH.md Pattern 4):
```dart
Text(
  amount,
  style: AppTextStyles.amountLarge.copyWith(
    color: context.palette.dailyText,  // #145E68 light / #4FB0BC dark
  ),
)
```

---

### `lib/features/home/presentation/widgets/home_hero_card.dart` (MODIFIED)

**Analog:** itself

**Current import block** (lines 1-18):
```dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_colors.dart';
```
**After migration:** Replace `app_colors.dart` and `app_theme_colors.dart` imports with `app_palette.dart`.

**Duplicate constants to DELETE** (lines 20-21 — COLOR-03 target):
```dart
const Color _joyTargetStartColor = Color(0xFF47B88A);   // DELETE
const Color _joyTargetEndColor = Color(0xFFD9A441);     // DELETE
```

**Hero gradient function migration** (lines 23-26):
```dart
// BEFORE:
Color joyTargetProgressColor(double ratio) {
  final clamped = ratio.clamp(0.0, 1.0).toDouble();
  return Color.lerp(_joyTargetStartColor, _joyTargetEndColor, clamped)!;
}

// AFTER (D-05 — signature gains palette param):
Color joyTargetProgressColor(double ratio, AppPalette palette) {
  final clamped = ratio.clamp(0.0, 1.0).toDouble();
  return Color.lerp(palette.daily, palette.joy, clamped)!;  // #1C7A86 → #F0A81E
}
```

**Mixed wm*/AppColors pattern in build()** — representative lines from home_hero_card.dart grep:
```dart
// BEFORE:
color: context.wmCard,
color: context.wmTextPrimary,
color: AppColors.olive,        // trend chip
color: AppColors.oliveLight,   // trend chip background

// AFTER:
color: context.palette.card,
color: context.palette.textPrimary,
color: context.palette.success,       // D-06: olive → success #2FA37A
color: context.palette.successLight,  // derived success tint (planner defines)
```

---

### `lib/features/profile/presentation/widgets/avatar_display.dart` (MODIFIED)

**Analog:** itself — `lib/features/profile/presentation/widgets/avatar_display.dart`

**Current Bucket A/C/D pattern** (lines 23-41):
```dart
static const _lightGradient = [
  Color(0xFFFFD4CC),    // coral pink — D-04 re-hue to teal family
  Color(0xFFFEEAE6),
  Color(0xFFFEF5F4),
];
static const _darkGradient = [
  Color(0xFF3D2020),    // dark coral — D-04 re-hue to teal family
  Color(0xFF2D1818),
  Color(0xFF251518),
];

// In build():
final isDark = Theme.of(context).brightness == Brightness.dark;
final colors = gradientColors ?? (isDark ? _darkGradient : _lightGradient);
final borderColor = isDark
    ? const Color(0x26FFFFFF)    // D-04: alpha-only, stays
    : const Color(0x80FFFFFF);   // D-04: alpha-only, stays
```

**After migration — remove static const fields, use palette tokens**:
```dart
// D-03/D-04: static const lists replaced by palette tokens
// In build():
final palette = context.palette;
final colors = gradientColors ?? [
  palette.avatarGradientStart,   // new teal-family hex (planner defines from ADR-018 accentPrimaryLight)
  palette.avatarGradientMid,
  palette.avatarGradientEnd,
];
// Alpha border stays: Color(0x26FFFFFF) / Color(0x80FFFFFF) become
// palette.avatarBorderAlphaDark / palette.avatarBorderAlphaLight (named tokens per D-03)
```
Shadow line also migrates:
```dart
// BEFORE:
color: AppColors.accentPrimary.withValues(alpha: 0.16),
// AFTER:
color: palette.accentPrimary.withValues(alpha: 0.16),
```

---

### `lib/features/accounting/presentation/widgets/soft_toast.dart` (MODIFIED)

**Analog:** itself — Bucket E (error semantic family)

**Current Bucket E pattern** (lines 87-130):
```dart
decoration: BoxDecoration(
  color: const Color(0xFFFEF2F2),           // errorSurface
  border: Border.all(color: const Color(0xFFFECACA)),  // errorBorder
  boxShadow: const [
    BoxShadow(color: Color(0x15E53E3E), ...),           // errorShadow
  ],
),
Icon(widget.icon, size: 18, color: const Color(0xFFDC2626)),   // error
Text(..., style: const TextStyle(color: Color(0xFFDC2626))),   // error
```

**After migration — all 7 literals become palette tokens**:
```dart
final palette = context.palette;
decoration: BoxDecoration(
  color: palette.errorSurface,
  border: Border.all(color: palette.errorBorder),
  boxShadow: [BoxShadow(color: palette.errorShadow, ...)],
),
Icon(widget.icon, size: 18, color: palette.error),
Text(..., style: TextStyle(color: palette.error)),
```
Note: `SoftToast` is a `StatefulWidget` (not stateless). Access `context.palette` inside `build()`, not in `initState()`.

---

### `lib/features/accounting/presentation/screens/transaction_edit_screen.dart` (MODIFIED)

**Analog:** itself — canonical example of the `isDark` ternary pattern

**Current partial dark-adaptation pattern** (lines 91-110):
```dart
final isDark = Theme.of(context).brightness == Brightness.dark;
return Scaffold(
  backgroundColor: isDark ? AppColorsDark.background : AppColors.backgroundWarm,
  appBar: AppBar(
    backgroundColor: isDark ? AppColorsDark.card : AppColors.card,
    // ...
    title: Text(l10n.transactionEditTitle,
        style: AppTextStyles.headlineMedium.copyWith(
          color: isDark ? AppColorsDark.textPrimary : AppColors.textPrimary,
        )),
  ),
```

**After migration** — delete `isDark` local, replace all ternaries:
```dart
// isDark declaration removed entirely
return Scaffold(
  backgroundColor: context.palette.background,
  appBar: AppBar(
    backgroundColor: context.palette.card,
    // ...
    title: Text(l10n.transactionEditTitle,
        style: AppTextStyles.headlineMedium.copyWith(
          color: context.palette.textPrimary,
        )),
  ),
```
This is the canonical migration pattern for all 3 "partial dark" screens (`transaction_edit_screen.dart`, `ocr_review_screen.dart`, `category_selection_screen.dart`).

---

### `lib/features/analytics/presentation/screens/analytics_screen.dart` (MODIFIED)

**Analog:** itself — canonical no-dark-adaptation screen (pure `AppColors.*` refs)

**Current no-dark pattern** (lines 1-50 imports + representative color refs from grep):
```dart
import '../../../../core/theme/app_colors.dart';

// In build():
backgroundColor: AppColors.background,
color: AppColors.textSecondary,
color: AppColors.accentPrimary,
border: Border.all(color: AppColors.borderDefault),
```

**Also contains Bucket B literals** (lines 480-484 from grep):
```dart
colors: [Color(0xFFE85A4F), Color(0xFFF08070)],   // fabGradientEnd / fabGradientStart
color: Color(0x28E85A4F),                           // actionShadow
```

**After migration**:
```dart
import '../../../../core/theme/app_palette.dart';

// In build():
final palette = context.palette;
backgroundColor: palette.background,
color: palette.textSecondary,
color: palette.accentPrimary,
border: Border.all(color: palette.borderDefault),
// Bucket B:
colors: [palette.fabGradientEnd, palette.fabGradientStart],
color: palette.actionShadow,
```

---

### `lib/features/list/presentation/widgets/list_transaction_tile.dart` (MODIFIED)

**Analog:** itself — canonical mixed `context.wm*` + `AppColors.*` pattern

**Current pattern** (from grep — representative):
```dart
// wm* getters (working, just need rename):
color: context.wmCard,
color: context.wmBorderDefault,
color: context.wmTextPrimary,
color: context.wmTextSecondary,
color: context.wmBackgroundDivider,

// AppColors direct refs (no dark adaptation):
color: AppColors.joy,
color: AppColors.daily,
color: AppColors.shared,
color: AppColors.sharedLight,
color: AppColors.olive,       // → palette.success
color: AppColors.oliveLight,  // → derived successLight token
```

**After migration**:
```dart
// All via context.palette (wm* getters become palette.* directly):
color: context.palette.card,
color: context.palette.borderDefault,
color: context.palette.textPrimary,
color: context.palette.textSecondary,
color: context.palette.backgroundDivider,
color: context.palette.joy,
color: context.palette.daily,
color: context.palette.shared,
color: context.palette.sharedLight,
color: context.palette.success,       // D-06
```

---

### Family Sync Screens — Bucket B/C Pattern (4 screens)

**Analog:** `lib/features/family_sync/presentation/screens/create_group_screen.dart`
**Applies to:** `create_group_screen.dart`, `member_approval_screen.dart`, `join_group_screen.dart`, `confirm_join_screen.dart`

**Current Bucket B pattern** (from grep of `create_group_screen.dart`):
```dart
import '../../../../core/theme/app_colors.dart';

// Pure AppColors refs — no dark adaptation anywhere:
backgroundColor: AppColors.background,
color: AppColors.accentPrimary,
color: AppColors.textPrimary,
border: Border.all(color: AppColors.borderDefault),
// Bucket B coral gradient literals:
colors: [Color(0xFFE85A4F), Color(0xFFF08070)],   // fabGradient
color: Color(0x28E85A4F),                           // actionShadow
color: Color(0x0A000000),                           // surface overlay (pure black alpha — stays)
```

**Bucket C member gradient pattern** (from `member_approval_screen.dart` / `member_list_tile.dart` — purple presets):
```dart
// Current:
const Color(0xFFE8D5F5),  // memberGradientA
const Color(0xFFF3EAF9),  // memberGradientB
const Color(0xFFFAF5FD),  // memberGradientC

// After D-04 re-hue (planner derives teal-tinted versions):
palette.memberGradientA,  // teal-tinted analog
palette.memberGradientB,
palette.memberGradientC,
```

**After migration — all 4 screens**:
```dart
import '../../../../core/theme/app_palette.dart';

final palette = context.palette;
backgroundColor: palette.background,
color: palette.accentPrimary,
color: palette.textPrimary,
border: Border.all(color: palette.borderDefault),
colors: [palette.fabGradientEnd, palette.fabGradientStart],  // teal gradient
color: palette.actionShadow,
color: const Color(0x0A000000),  // EXCEPTION: pure alpha stays (D-04 rule)
```

---

### Profile Screens — Bucket A Pattern (3 screens)

**Analog:** `lib/features/profile/presentation/screens/profile_edit_screen.dart`
**Applies to:** `profile_edit_screen.dart`, `avatar_picker_screen.dart`, `profile_onboarding_screen.dart`

**Current Bucket A inline dark constants** (lines 14-17 of `profile_edit_screen.dart`):
```dart
const _editDarkBackground = Color(0xFF141418);    // DELETE — replaced by palette.background
const _editDarkSurface = Color(0xFF2A2A32);       // DELETE — replaced by palette.card
const _editDarkTextPrimary = Color(0xFFF0F0F5);   // DELETE — replaced by palette.textPrimary
const _editDarkTextSecondary = Color(0xFF6B6B78); // DELETE — replaced by palette.textSecondary

// Usage pattern (lines 112-120):
final isDark = Theme.of(context).brightness == Brightness.dark;
final textPrimary = isDark ? _editDarkTextPrimary : AppColors.textPrimary;
final textSecondary = isDark ? _editDarkTextSecondary : AppColors.textSecondary;
final inputFill = isDark ? _editDarkSurface : AppColors.backgroundMuted;
final inputBorder = isDark ? _editDarkSurface : AppColors.borderDefault;
backgroundColor: isDark ? _editDarkBackground : AppColors.background,
```

**After migration** — delete 4 inline constants + `isDark` local, use palette:
```dart
// All 4 const declarations deleted at file top
// isDark local removed from build()
final palette = context.palette;
final textPrimary = palette.textPrimary;         // resolves ADR-018 dark #E8F2F3
final textSecondary = palette.textSecondary;
final inputFill = palette.backgroundMuted;
final inputBorder = palette.borderDefault;
backgroundColor: palette.background,             // ADR-018 dark #0C1719 (replaces #141418)
```
Note (Pitfall 5): ADR-018 dark `background #0C1719` intentionally replaces profile screen's `#141418`. Document in Phase 34 golden expectations.

---

### `lib/features/list/presentation/widgets/list_calendar_header.dart` (MODIFIED — Bucket F)

**Analog:** itself

**Current Bucket F literals** (from grep):
```dart
static const _weekendColor = Color(0xFF1565C0);  // Material Blue 800
static const _todayColor = Color(0xFFD32F2F);    // Material Red 700
```

**After migration** (assumption A2 from RESEARCH.md):
```dart
// _weekendColor → palette.info (#2A8FB8 light / #2A9FC8 dark approximate)
// _todayColor   → palette.error (#E5484D light / #F0676B dark)
color: palette.info,   // weekend highlight
color: palette.error,  // today highlight
```

---

## Shared Patterns

### Pattern: `context.palette.*` access (replaces ALL `context.wm*` and `AppColors.*`)

**Source:** `lib/core/theme/app_theme_colors.dart` (lines 10-65) — the pattern to replace
**Apply to:** Every modified file

Old access forms and their replacements:
```dart
// OLD → NEW
context.wmCard             → context.palette.card
context.wmBackground       → context.palette.background
context.wmBackgroundMuted  → context.palette.backgroundMuted
context.wmBackgroundSubtle → context.palette.backgroundSubtle
context.wmBackgroundDivider→ context.palette.backgroundDivider
context.wmTextPrimary      → context.palette.textPrimary
context.wmTextSecondary    → context.palette.textSecondary
context.wmTextTertiary     → context.palette.textTertiary
context.wmBorderDefault    → context.palette.borderDefault
context.wmBorderDivider    → context.palette.borderDivider
context.wmBorderList       → context.palette.borderList
context.wmNavShadow        → context.palette.navShadow
context.wmSatisfactionBg   → context.palette.joyFullnessBg
context.wmSatisfactionBorder→context.palette.joyFullnessBorder
context.wmRoiBg            → context.palette.joyRoiBg
context.wmRoiBorder        → context.palette.joyRoiBorder
context.wmFamilyBadgeBg    → context.palette.familyBadgeBg
context.wmSurvivalTagBg    → context.palette.dailyLight   (stale name — rename, not port)
context.wmSoulTagBg        → context.palette.joyLight     (stale name — rename, not port)
context.wmSharedTagBg      → context.palette.sharedLight

AppColors.accentPrimary    → context.palette.accentPrimary (or AppPalette.light.accentPrimary in const context)
AppColors.daily            → context.palette.daily
AppColors.joy              → context.palette.joy
AppColors.olive            → context.palette.success       (D-06: olive merged into success)
AppColors.oliveLight       → context.palette.successLight  (planner defines this derived token)
AppColors.shared           → context.palette.shared
AppColors.sharedLight      → context.palette.sharedLight
```

### Pattern: `isDark` ternary removal

**Source:** `lib/features/accounting/presentation/screens/transaction_edit_screen.dart` (lines 91-110) — the pattern to eliminate
**Apply to:** `transaction_edit_screen.dart`, `ocr_review_screen.dart`, `category_selection_screen.dart`, `avatar_display.dart`, all profile screens

```dart
// BEFORE (brittle, non-idiomatic):
final isDark = Theme.of(context).brightness == Brightness.dark;
backgroundColor: isDark ? AppColorsDark.background : AppColors.background,

// AFTER (idiomatic ThemeExtension):
backgroundColor: context.palette.background,
// No isDark needed — AppPalette resolves brightness from ThemeData
```

### Pattern: Amount text with `*Text` color (WCAG constraint — CLAUDE.md)

**Source:** `lib/core/theme/app_text_styles.dart` (lines 145-168) — `const amountLarge/Medium/Small`
**Apply to:** Every widget that shows a monetary value in a ledger-colored context

```dart
// NEVER use palette.joy directly for amount text (WCAG fail on white card):
// BAD: style: AppTextStyles.amountMedium.copyWith(color: palette.joy)

// ALWAYS use *Text variants:
Text(amount, style: AppTextStyles.amountLarge.copyWith(color: palette.dailyText));
Text(amount, style: AppTextStyles.amountMedium.copyWith(color: palette.joyText));
Text(amount, style: AppTextStyles.amountSmall.copyWith(color: palette.sharedText));
// tabularFigures is preserved because amountLarge/Medium/Small define fontFeatures
```

### Pattern: Architecture test (grep gate)

**Source:** `test/architecture/hardcoded_cjk_ui_scan_test.dart` — filesystem scan pattern
**Apply to:** `test/architecture/color_literal_scan_test.dart` (new)

```dart
// Pattern: scan lib/ recursively with a regex, collect hits, assert isEmpty
for (final entity in Directory('lib').listSync(recursive: true)) {
  if (entity is! File || !_shouldScan(entity)) continue;
  final source = entity.readAsStringSync();
  final offendingMatches = literalPattern.allMatches(source).toList();
  if (offendingMatches.isNotEmpty) {
    hits.add('${entity.path}: ${offendingMatches.length} hit(s)');
  }
}
expect(hits, isEmpty, reason: 'Color(0x…) literals found in lib/features/...');
```

### Pattern: Unit test for static-const palette class

**Source:** `test/core/theme/app_colors_test.dart` (lines 1-29) — existing pattern
**Apply to:** `test/core/theme/app_palette_test.dart` (new)

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/theme/app_palette.dart';
import 'dart:ui';

void main() {
  group('AppPalette light instance', () {
    test('background matches ADR-018', () {
      expect(AppPalette.light.background, const Color(0xFFF8FCFD));
    });
    test('accentPrimary is teal (not coral)', () {
      expect(AppPalette.light.accentPrimary, const Color(0xFF0E9AA7));
    });
    // ... one test per role that has an ADR-018-specified hex
  });
  group('AppPalette copyWith', () {
    test('returns new instance with overridden field', () {
      final modified = AppPalette.light.copyWith(card: const Color(0xFF000000));
      expect(modified.card, const Color(0xFF000000));
      expect(modified.background, AppPalette.light.background); // unchanged
    });
  });
  group('AppPalette lerp', () {
    test('at t=0.0 returns self values', () {
      final result = AppPalette.light.lerp(AppPalette.dark, 0.0);
      expect(result.background, AppPalette.light.background);
    });
  });
}
```

### Pattern: Widget test with theme pump

**Source:** `test/widget/features/home/presentation/widgets/home_hero_card_test.dart` (lines 86-118) — `testLocalizedApp` + `Scaffold` wrapper
**Apply to:** `test/widget/theme_dark_mode_coverage_test.dart` (new)

```dart
// testLocalizedApp provides MaterialApp + localization delegates (test_localizations.dart)
Widget testLocalizedApp({required Widget child, Locale locale = const Locale('ja')}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: const [...],
    supportedLocales: S.supportedLocales,
    home: child,
  );
}

// For dark mode coverage test, wrap with themeMode:
Widget _darkTestApp({required Widget child}) {
  return MaterialApp(
    themeMode: ThemeMode.dark,
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    // localization delegates...
    home: child,
  );
}
// Pattern: pump each screen under ThemeMode.dark + expect no exceptions
```

---

## No Analog Found

All files have close analogs. No file requires pure from-scratch invention.

The closest to "no analog" are the three new test files, but each maps to an existing test in a different category:
- `test/core/theme/app_palette_test.dart` → `test/core/theme/app_colors_test.dart`
- `test/architecture/color_literal_scan_test.dart` → `test/architecture/hardcoded_cjk_ui_scan_test.dart`
- `test/widget/theme_dark_mode_coverage_test.dart` → `home_hero_card_test.dart` + `test_localizations.dart`

---

## Critical Constraints (from CLAUDE.md + ADR chain)

| Constraint | Impact on This Phase |
|-----------|---------------------|
| `flutter analyze` MUST be 0 issues before commit | Keep `AppColors` shim live until W2 is fully complete; delete only after grep returns zero |
| `build_runner` clean-diff required | Color migration does not touch `@riverpod`/`@freezed`/Drift annotations; run as sanity check, no output expected |
| Amount display: `AppTextStyles.amount*` with `tabularFigures` | Always apply via `.copyWith(color: palette.*Text)`; never inline color on amount text |
| Widget parameter nullable + provider fallback | No palette color values in constructor defaults |
| No `survival*`/`soul*` identifiers | `wmSurvivalTagBg` → `palette.dailyLight`; `wmSoulTagBg` → `palette.joyLight`; DO NOT port old names |
| `joy #F0A81E` is affordance-only | Never use `palette.joy` for numeric amount text; use `palette.joyText #9A6500` (light) |
| Golden tests WILL fail in Phase 33 | Do NOT run `--update-goldens`; skip golden tests with `--exclude-tags golden` |
| D-06: olive → success | `AppColors.olive` maps to `palette.success #2FA37A`; confirms no collision on HomeHeroCard or FamilyInsightCard |
| Podfile: do NOT touch | iOS build constraint — color migration is Dart-only |

---

## Metadata

**Analog search scope:** `lib/core/theme/`, `lib/features/`, `test/core/theme/`, `test/architecture/`, `test/widget/`, `test/helpers/`
**Files read:** 15 source files + 4 test files
**Pattern extraction date:** 2026-06-01
