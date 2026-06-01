---
phase: 33-color-token-system-consolidation
reviewed: 2026-06-01T12:08:39Z
depth: standard
files_reviewed: 67
files_reviewed_list:
  - lib/core/initialization/init_failure_screen.dart
  - lib/core/theme/app_palette.dart
  - lib/core/theme/app_text_styles.dart
  - lib/core/theme/app_theme.dart
  - lib/features/accounting/presentation/screens/category_selection_screen.dart
  - lib/features/accounting/presentation/screens/manual_one_step_screen.dart
  - lib/features/accounting/presentation/screens/ocr_review_screen.dart
  - lib/features/accounting/presentation/screens/ocr_scanner_screen.dart
  - lib/features/accounting/presentation/screens/transaction_edit_screen.dart
  - lib/features/accounting/presentation/screens/voice_input_screen.dart
  - lib/features/accounting/presentation/widgets/amount_display.dart
  - lib/features/accounting/presentation/widgets/amount_edit_bottom_sheet.dart
  - lib/features/accounting/presentation/widgets/category_reorder_row.dart
  - lib/features/accounting/presentation/widgets/detail_info_card.dart
  - lib/features/accounting/presentation/widgets/input_mode_tabs.dart
  - lib/features/accounting/presentation/widgets/keyboard_toolbar.dart
  - lib/features/accounting/presentation/widgets/ledger_type_selector.dart
  - lib/features/accounting/presentation/widgets/satisfaction_emoji_picker.dart
  - lib/features/accounting/presentation/widgets/smart_keyboard.dart
  - lib/features/accounting/presentation/widgets/soft_toast.dart
  - lib/features/accounting/presentation/widgets/transaction_details_form.dart
  - lib/features/accounting/presentation/widgets/voice_waveform.dart
  - lib/features/analytics/presentation/widgets/analytics_card_error_state.dart
  - lib/features/analytics/presentation/widgets/analytics_screen_section_header.dart
  - lib/features/analytics/presentation/widgets/best_joy_story_strip.dart
  - lib/features/analytics/presentation/widgets/category_spend_donut_chart.dart
  - lib/features/analytics/presentation/widgets/daily_vs_joy_card.dart
  - lib/features/analytics/presentation/widgets/family_insight_card.dart
  - lib/features/analytics/presentation/widgets/joy_headline_kpi_tile.dart
  - lib/features/analytics/presentation/widgets/joy_ledger_thin_sample_fallback.dart
  - lib/features/analytics/presentation/widgets/joy_metric_variant_chip.dart
  - lib/features/analytics/presentation/widgets/largest_expense_story_card.dart
  - lib/features/analytics/presentation/widgets/monthly_spend_trend_bar_chart.dart
  - lib/features/analytics/presentation/widgets/per_category_breakdown_card.dart
  - lib/features/analytics/presentation/widgets/satisfaction_distribution_histogram.dart
  - lib/features/analytics/presentation/widgets/time_window_chip.dart
  - lib/features/analytics/presentation/widgets/time_window_picker_sheet.dart
  - lib/features/analytics/presentation/widgets/total_spending_kpi_tile.dart
  - lib/features/family_sync/presentation/screens/confirm_join_screen.dart
  - lib/features/family_sync/presentation/screens/create_group_screen.dart
  - lib/features/family_sync/presentation/screens/group_choice_screen.dart
  - lib/features/family_sync/presentation/screens/group_management_screen.dart
  - lib/features/family_sync/presentation/screens/join_group_screen.dart
  - lib/features/family_sync/presentation/screens/member_approval_screen.dart
  - lib/features/family_sync/presentation/screens/waiting_approval_screen.dart
  - lib/features/family_sync/presentation/widgets/member_list_tile.dart
  - lib/features/home/presentation/screens/home_screen.dart
  - lib/features/home/presentation/widgets/family_invite_banner.dart
  - lib/features/home/presentation/widgets/hero_header.dart
  - lib/features/home/presentation/widgets/home_bottom_nav_bar.dart
  - lib/features/home/presentation/widgets/home_hero_card.dart
  - lib/features/home/presentation/widgets/home_transaction_tile.dart
  - lib/features/home/presentation/widgets/section_divider.dart
  - lib/features/home/presentation/widgets/transaction_list_card.dart
  - lib/features/list/presentation/screens/list_screen.dart
  - lib/features/list/presentation/widgets/list_calendar_header.dart
  - lib/features/list/presentation/widgets/list_category_filter_sheet.dart
  - lib/features/list/presentation/widgets/list_day_group_header.dart
  - lib/features/list/presentation/widgets/list_empty_state.dart
  - lib/features/list/presentation/widgets/list_sort_filter_bar.dart
  - lib/features/list/presentation/widgets/list_transaction_tile.dart
  - lib/features/profile/presentation/screens/avatar_picker_screen.dart
  - lib/features/profile/presentation/screens/profile_edit_screen.dart
  - lib/features/profile/presentation/screens/profile_onboarding_screen.dart
  - lib/features/profile/presentation/widgets/avatar_display.dart
  - lib/features/profile/presentation/widgets/profile_section_card.dart
  - lib/features/profile/presentation/widgets/scattered_emoji_background.dart
findings:
  critical: 4
  warning: 6
  info: 3
  total: 13
status: issues_found
---

# Phase 33: Code Review Report

**Reviewed:** 2026-06-01T12:08:39Z
**Depth:** standard
**Files Reviewed:** 67
**Status:** issues_found

## Summary

Phase 33 migrated ~62 hardcoded `Color(0x…)` literals and all `AppColors`/`AppColorsDark` references to the new `AppPalette` ThemeExtension (ADR-018 Teal Clarity). The migration is structurally sound: the palette definition is correct, `lerp`/`copyWith` round-trip, the `context.palette` getter fallback is architecturally well-designed, and the vast majority of ledger-color assignments correctly distinguish `daily`/`dailyText`/`joyText`/`sharedText`. No old-era `isDark` ternaries or raw `Color(0x…)` literals survive in the reviewed feature files.

Four blockers were found: the init-failure path uses `context.palette` without a registered `AppTheme` extension (the fallback fires every time, which masks the bug silently); the trend chip applies `success` green unconditionally to spending increases (wrong semantic token — ADR-018 assigns `error` to negative signals and the ADR says red is reserved for `error`); the `AmountDisplay` currency-symbol badge applies `palette.daily` (#1C7A86, contrast 4.39:1) against `palette.dailyLight` (#E0F0F2) with `AppTextStyles.amountMedium`, violating the CLAUDE.md "amounts must use `*Text` variants" rule; and `group_management_screen.dart` hardcodes `Colors.white` for the member-card container background instead of `palette.card`, breaking dark mode.

---

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: `InitFailureApp` omits `AppTheme` — `context.palette` always takes fallback path

**File:** `lib/core/initialization/init_failure_screen.dart:109-120`

**Issue:** `InitFailureApp.build` constructs a bare `MaterialApp` with no `theme:` parameter. `AppTheme` registers `AppPalette` as a `ThemeExtension` in its `extensions: const [AppPalette.light]` list. Without that registration, `Theme.of(this).extension<AppPalette>()` returns `null` on every `context.palette` access inside `InitFailureScreen`. The brightness-aware fallback in `AppPaletteContext.palette` then fires silently — this is not a crash, it is a masked configuration bug. If a future developer changes the fallback to throw (or removes it for test harnesses), this screen breaks. More concretely: any color divergence between `AppPalette.light` and the defaults used by `ThemeData()` will render the error screen with wrong colors, invisible against the scaffold, or mismatched CTA.

**Fix:**
```dart
// lib/core/initialization/init_failure_screen.dart
@override
Widget build(BuildContext context) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,          // ← register AppPalette extension
    darkTheme: AppTheme.dark,
    localizationsDelegates: const [...],
    supportedLocales: S.supportedLocales,
    home: InitFailureScreen(onRetry: onRetry),
  );
}
```
Also add `import '../theme/app_theme.dart';` to the file.

---

### CR-02: `_trendChip` applies `success` (green) for spending increases — wrong semantic token

**File:** `lib/features/home/presentation/widgets/home_hero_card.dart:170-197`

**Issue:** `_trendChip` uses `palette.success` and `palette.successLight` unconditionally for both positive and negative trends. When `trend > 0` (total spending increased vs. previous month), the chip renders a green `trending_up` icon with green text. ADR-018 explicitly reserves green for `success` (positive outcome) and red for `error` (problem signal). In a spending-tracking context, an upward trend is at minimum neutral and potentially a warning — rendering it in `success` green actively contradicts the palette semantics. The icon is correct (`trending_up`), but the color signals the opposite meaning to users.

**Fix:**
```dart
Widget _trendChip(AppPalette palette, int trend) {
  final text = trend <= 0 ? '$trend%' : '+$trend%';
  final isPositiveTrend = trend > 0; // spending increased = caution
  final bgColor = isPositiveTrend ? palette.errorSurface : palette.successLight;
  final fgColor = isPositiveTrend ? palette.error : palette.success;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          trend <= 0 ? Icons.trending_down : Icons.trending_up,
          size: 14,
          color: fgColor,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: fgColor,
          ),
        ),
      ],
    ),
  );
}
```

---

### CR-03: `AmountDisplay` currency-symbol badge uses `palette.daily` (not `dailyText`) on `amountMedium` — WCAG violation

**File:** `lib/features/accounting/presentation/widgets/amount_display.dart:79-92`

**Issue:** The currency badge renders `currencySymbol` (e.g. "¥") with `AppTextStyles.amountMedium` (a tabular-figures style) and `color: palette.daily` (#1C7A86) on a background of `palette.dailyLight` (#E0F0F2). CLAUDE.md "Amount Display Style" states: "Never use generic text styles for amounts" and the `AppPalette` doc comment states: "NEVER use `daily`, `joy`, or `shared` directly for numeric amount text — use the `*Text` variants". Although the currency symbol badge is a label, not a pure numeric field, `AppTextStyles.amountMedium` is the amount style and the rule is explicit. More materially: #1C7A86 on #E0F0F2 has a contrast ratio of approximately 4.39:1, which fails WCAG AA for large text at the 14sp fontSize. `dailyText` (#145E68) on the same background yields approximately 5.8:1 which passes.

**Fix:**
```dart
// currency symbol text — use dailyText for WCAG AA compliance
Text(
  currencySymbol,
  style: AppTextStyles.amountMedium.copyWith(
    color: palette.dailyText,   // #145E68, contrast ≥4.5:1 on dailyLight
    fontSize: 14,
  ),
),
const SizedBox(width: 4),
Text(
  currencyLabel,
  style: AppTextStyles.bodySmall.copyWith(
    color: palette.dailyText,   // same token for visual consistency
    fontWeight: FontWeight.w600,
    fontSize: 10,
  ),
),
```

---

### CR-04: `group_management_screen.dart` hardcodes `Colors.white` for member card background — dark mode breakage

**File:** `lib/features/family_sync/presentation/screens/group_management_screen.dart:355`

**Issue:** The member card container sets `color: Colors.white` explicitly. This bypasses the palette entirely. In dark mode, `palette.card` is `#162527` (a very dark teal). Using `Colors.white` in dark mode renders an all-white card on a near-black scaffold — the entire member section becomes a stark white box, crushing contrast on the surrounding dark UI and violating the ADR-018 dark palette.

**Fix:**
```dart
Container(
  decoration: BoxDecoration(
    color: palette.card,          // was: Colors.white
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: palette.surfaceScrimMedium,
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  ),
  ...
)
```

---

## Warnings

### WR-01: `_ErrorText` in `home_screen.dart` uses `Colors.red` instead of `palette.error`

**File:** `lib/features/home/presentation/screens/home_screen.dart:388`

**Issue:** The private `_ErrorText` widget hardcodes `color: Colors.red`. This bypasses the palette system. `Colors.red` (`#F44336`) is neither the light-mode `palette.error` (`#E5484D`) nor dark-mode `#F0676B`. Inconsistency with the semantic error token and will diverge further in dark mode.

**Fix:**
```dart
style: AppTextStyles.bodySmall.copyWith(color: context.palette.error),
```

---

### WR-02: `list_transaction_tile.dart` Dismissible background uses `Colors.red` instead of `palette.error`

**File:** `lib/features/list/presentation/widgets/list_transaction_tile.dart:90`

**Issue:** The swipe-to-delete background sets `color: Colors.red` directly. In dark mode `Colors.red` (`#F44336`) diverges from `palette.error` (`#F0676B`). The delete confirm dialog's TextButton also hardcodes `Colors.red` at lines 120 and 124 for the same semantic context.

**Fix:**
```dart
// Dismissible background (line 90)
color: context.palette.error,

// TextButton.styleFrom (line 120)
style: TextButton.styleFrom(foregroundColor: context.palette.error),

// Text style (line 124)
style: AppTextStyles.titleSmall.copyWith(color: palette.error),
```

---

### WR-03: `category_selection_screen.dart` uses `Colors.red` for delete action background

**File:** `lib/features/accounting/presentation/screens/category_selection_screen.dart:161, 180`

**Issue:** Two `Colors.red` references in the category deletion flow (delete action `backgroundColor: Colors.red` and the confirm dialog `TextButton.styleFrom(foregroundColor: Colors.red)`). Same dark-mode divergence as WR-02.

**Fix:**
```dart
// line 161
backgroundColor: context.palette.error,

// line 180
style: TextButton.styleFrom(foregroundColor: context.palette.error),
```

---

### WR-04: `soft_toast.dart` uses `'IBM Plex Sans'` font family — not the project font

**File:** `lib/features/accounting/presentation/widgets/soft_toast.dart:109`

**Issue:** The toast message `TextStyle` hardcodes `fontFamily: 'IBM Plex Sans'`. The project's designated font is `'Outfit'` (set in `AppTheme` via `fontFamily: 'Outfit'` and referenced throughout `AppTextStyles`). IBM Plex Sans is not declared in the project's font assets. Flutter will silently fall back to the system font when the specified family is absent, producing inconsistent typography that differs per-platform.

**Fix:**
```dart
style: TextStyle(
  fontFamily: 'Outfit',         // was: 'IBM Plex Sans'
  fontSize: 13,
  fontWeight: FontWeight.w500,
  color: palette.error,
),
```

---

### WR-05: `context.palette` fallback in `AppPaletteContext` silently masks missing `ThemeExtension` registration

**File:** `lib/core/theme/app_palette.dart:612-617`

**Issue:** The `palette` getter extension reads:
```dart
AppPalette get palette =>
    Theme.of(this).extension<AppPalette>() ??
    (Theme.of(this).brightness == Brightness.dark
        ? AppPalette.dark
        : AppPalette.light);
```
This fallback is intentional for test harnesses, but it calls `Theme.of(this)` twice per access — once to look up the extension and once more to check `brightness`. Every widget that accesses `context.palette` in a loop (e.g., chart builders iterating over data) pays this double-lookup cost per frame. More critically, the fallback silently swallows the "AppTheme was never installed" configuration failure (as evidenced by CR-01), making misconfigured screens invisible during development. The comment says "instead of throwing", but a development-mode assertion would catch bugs while keeping production silent.

**Fix:**
```dart
AppPalette get palette {
  final theme = Theme.of(this);
  return theme.extension<AppPalette>() ??
      (theme.brightness == Brightness.dark
          ? AppPalette.dark
          : AppPalette.light);
}
```
Cache the `Theme.of(this)` call to a single local variable. For the silent-masking concern, consider adding a debug-mode assertion:
```dart
assert(
  theme.extension<AppPalette>() != null,
  'AppPalette ThemeExtension not registered in this ThemeData. '
  'Ensure AppTheme.light/dark is applied at the root MaterialApp.',
);
```

---

### WR-06: `satisfaction_distribution_histogram.dart` — off-by-one in `_colorForScore` lerp range for score=5

**File:** `lib/features/analytics/presentation/widgets/satisfaction_distribution_histogram.dart:162-171`

**Issue:**
```dart
Color _colorForScore(int score, AppPalette palette) {
  if (score <= 5) {
    return Color.lerp(palette.daily, palette.joy, (score - 1) / 4)!;
  }
  return Color.lerp(
    palette.joy,
    palette.accentPrimary,
    (score - 5) / 5,
  )!;
}
```
Score 5 maps to `(5-1)/4 = 1.0` → pure `joy` gold (correct for the first branch). Score 6 maps to `(6-5)/5 = 0.2` → 20% lerp from `joy` toward `accentPrimary`. This creates a gradient discontinuity at the 5→6 boundary: the two branches share score=5 as the boundary (`joy` gold) and score=6 starts at 20% shift — which is fine. However, score=10 maps to `(10-5)/5 = 1.0` → pure `accentPrimary` (teal). The visual effect is that the upper satisfaction range fades toward the teal primary colour rather than an intuitively "higher positive" colour. The comment in ADR-018 notes `olive` (emerald `#3DA77E`) is for trends. Using `palette.joy` → `palette.success` for the upper range (scores 6-10) would be semantically consistent (joy satisfaction is a positive signal). This is a design correctness issue: the current mapping makes scores 6-10 trend toward the navigation accent colour rather than a semantically meaningful warm/positive hue.

**Fix (semantic correctness):**
```dart
Color _colorForScore(int score, AppPalette palette) {
  if (score <= 5) {
    // daily-blue → joy-gold across the neutral range
    return Color.lerp(palette.daily, palette.joy, (score - 1) / 4)!;
  }
  // joy-gold → success-green across the positive range (6-10)
  return Color.lerp(palette.joy, palette.success, (score - 5) / 5)!;
}
```

---

## Info

### IN-01: `home_hero_card.dart` — local variable `joyText`/`dailyText` shadow the palette field names

**File:** `lib/features/home/presentation/widgets/home_hero_card.dart:205-206`

**Issue:** In `_splitBar`:
```dart
final joyText = _fmt.formatCurrency(joy, currencyCode, locale);
final dailyText = _fmt.formatCurrency(daily, currencyCode, locale);
```
These local variables shadow the palette field names `palette.joyText` and `palette.dailyText` within the same method. The method passes `amountColor: palette.joyText` at line 216 — the correct palette field is still accessed — but the shadowing creates a cognitive risk: a future refactor searching for `joyText` in this widget will find the local formatted string instead of the palette token. The palette doc comment already flags this pattern ("NEVER use `joy` directly for numeric amount text — use the `*Text` variants").

**Fix:** Rename the locals:
```dart
final joyFormatted = _fmt.formatCurrency(joy, currencyCode, locale);
final dailyFormatted = _fmt.formatCurrency(daily, currencyCode, locale);
```

---

### IN-02: `voice_waveform.dart` doc comment references `AppPalette.light.daily` — stale after migration

**File:** `lib/features/accounting/presentation/widgets/voice_waveform.dart:16-17`

**Issue:** The doc comment reads:
```dart
/// Color of the waveform bars. Defaults to [AppPalette.light.daily] when
/// no color is provided by the caller.
```
The actual implementation at line 29 uses `context.palette.daily` (the brightness-resolved token), not the hardcoded `AppPalette.light.daily`. This makes the comment inaccurate — it implies only the light palette value is used, whereas `context.palette.daily` correctly adapts to dark mode.

**Fix:**
```dart
/// Color of the waveform bars. Defaults to [AppPalette.daily] (brightness-resolved
/// from [context.palette]) when no color is provided by the caller.
```

---

### IN-03: `home_bottom_nav_bar.dart` comment describes "coral-coloured pill" — stale pre-migration comment

**File:** `lib/features/home/presentation/widgets/home_bottom_nav_bar.dart:12`

**Issue:** The class-level doc comment reads:
> "the active tab is highlighted with a coral-coloured pill (14px radius)"

Post Phase 33 migration, the active tab pill uses `context.palette.accentPrimary` (teal `#0E9AA7`), not coral. This is a stale comment from the pre-ADR-018 identity.

**Fix:**
```dart
/// The active tab is highlighted with a teal-coloured pill ([AppPalette.accentPrimary]).
```

---

_Reviewed: 2026-06-01T12:08:39Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
