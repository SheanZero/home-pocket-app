---
phase: 05-medium-fixes
reviewed: 2026-04-27T05:25:30Z
depth: standard
files_reviewed: 35
files_reviewed_list:
  - lib/application/accounting/category_localization_service.dart
  - lib/features/accounting/presentation/screens/voice_input_screen.dart
  - lib/features/analytics/presentation/widgets/budget_progress_list.dart
  - lib/features/analytics/presentation/widgets/category_breakdown_list.dart
  - lib/features/analytics/presentation/widgets/daily_expense_chart.dart
  - lib/features/analytics/presentation/widgets/expense_trend_chart.dart
  - lib/features/analytics/presentation/widgets/ledger_ratio_chart.dart
  - lib/features/analytics/presentation/widgets/month_comparison_card.dart
  - lib/features/analytics/presentation/widgets/summary_cards.dart
  - lib/features/home/presentation/screens/home_screen.dart
  - lib/features/home/presentation/widgets/soul_fullness_card.dart
  - lib/features/settings/presentation/widgets/appearance_section.dart
  - lib/generated/app_localizations.dart
  - lib/generated/app_localizations_en.dart
  - lib/generated/app_localizations_ja.dart
  - lib/generated/app_localizations_zh.dart
  - lib/infrastructure/category/category_locale_service.dart
  - lib/infrastructure/ml/merchant_database.dart
  - lib/l10n/app_en.arb
  - lib/l10n/app_ja.arb
  - lib/l10n/app_zh.arb
  - test/architecture/arb_key_parity_test.dart
  - test/architecture/hardcoded_cjk_ui_scan_test.dart
  - test/architecture/medium_findings_closed_test.dart
  - test/architecture/mod009_live_lib_scan_test.dart
  - test/architecture/service_name_collision_test.dart
  - test/features/home/presentation/screens/home_screen_test.dart
  - test/features/home/presentation/widgets/soul_fullness_card_test.dart
  - test/unit/features/home/presentation/providers/shadow_books_provider_characterization_test.dart
  - test/unit/infrastructure/category/category_locale_service_test.dart
  - test/unit/infrastructure/ml/merchant_database_test.dart
  - test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart
  - test/widget/features/analytics/presentation/widgets/analytics_money_widgets_test.dart
  - test/widget/features/home/presentation/screens/home_screen_test.dart
  - test/widget/features/home/presentation/widgets/soul_fullness_card_test.dart
findings:
  critical: 0
  warning: 2
  info: 1
  total: 3
status: issues_found
---

# Phase 5: Code Review Report

**Reviewed:** 2026-04-27T05:25:30Z
**Depth:** standard
**Files Reviewed:** 35
**Status:** issues_found

## Summary

Reviewed the supplied Flutter source, generated localization output, ARB files, and tests for correctness, security, regressions, and maintainability. The localization changes are mostly consistent, but one analytics widget can assert/crash for exceeded budgets, and category localization does not cover legacy category IDs that are still emitted by in-scope merchant matching. One remaining user-visible hardcoded comparison label should also be localized.

## Warnings

### WR-01: Budget Progress Value Can Exceed Flutter's Valid Range

**File:** `lib/features/analytics/presentation/widgets/budget_progress_list.dart:116`
**Issue:** `LinearProgressIndicator.value` is clamped to `1.5`, but Flutter requires determinate progress values to stay between `0.0` and `1.0`. Any exceeded budget between 100% and 150% can trip framework assertions in debug/test builds.
**Fix:**
```dart
LinearProgressIndicator(
  value: (progress.percentage / 100).clamp(0.0, 1.0),
  backgroundColor: Colors.grey[200],
  valueColor: AlwaysStoppedAnimation<Color>(_statusColor),
  minHeight: 8,
)
```

### WR-02: Legacy Category IDs Resolve To Raw Localization Keys

**File:** `lib/infrastructure/category/category_locale_service.dart:16`
**Issue:** `resolveFromId()` converts every `cat_*` ID to `category_*`, but the new localization map only contains current IDs such as `category_hobbies` and `category_clothing`. Existing producers still emit legacy IDs such as `cat_shopping` and `cat_entertainment` (`lib/infrastructure/ml/merchant_database.dart:86`, `:116`), so UI fallback paths can display raw strings like `category_shopping` instead of a localized label.
**Fix:**
```dart
static const _legacyCategoryAliases = {
  'cat_shopping': 'category_clothing',
  'cat_entertainment': 'category_hobbies',
};

static String resolveFromId(String categoryId, Locale locale) {
  if (!categoryId.startsWith('cat_')) return categoryId;
  final nameKey =
      _legacyCategoryAliases[categoryId] ?? 'category_${categoryId.substring(4)}';
  return resolve(nameKey, locale);
}
```

Alternatively, migrate the remaining producers to current category IDs, e.g. map Netflix to `cat_hobbies_subscription` and clothing merchants to `cat_clothing`.

## Info

### IN-01: Month Comparison Header Still Bypasses Localization

**File:** `lib/features/analytics/presentation/widgets/month_comparison_card.dart:23`
**Issue:** The header string hardcodes `vs` and formats the year/month manually. This conflicts with the phase's i18n cleanup and the project rule that user-visible text and dates should go through localization/formatting helpers.
**Fix:** Add a localized ARB message such as `analyticsMonthComparisonTitle` and use `FormatterService`/`DateFormatter` or localized placeholders for the displayed month.

---

_Reviewed: 2026-04-27T05:25:30Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
