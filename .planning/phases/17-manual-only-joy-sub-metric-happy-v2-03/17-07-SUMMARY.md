---
phase: 17-manual-only-joy-sub-metric-happy-v2-03
plan: 07
subsystem: analytics-presentation-state
tags: [analytics, riverpod, i18n, widget, anti-toxicity, happy-v2-03]

requires:
  - phase: 17-06
    provides: Analytics use-case entrySourceFilter surface
provides:
  - Trilingual Joy metric variant ARB keys and generated localizations
  - JoyMetricVariant enum and selectedJoyMetricVariantProvider
  - Analytics provider family-key extensions for joyMetricVariant
  - JoyMetricVariantChip with bottom-sheet selection flow
  - Anti-toxicity and chip interaction widget tests
affects: [analytics-state, analytics-widgets, l10n, manual-only-toggle]

tech-stack:
  added: []
  patterns:
    - Session-scoped Riverpod notifier defaults to all entries
    - Analytics provider family keys carry the variant; HomeHero stays isolated
    - Chip UI mirrors TimeWindowChip tap-target and theme tokens

key-files:
  created:
    - lib/features/analytics/presentation/providers/state_joy_metric_variant.dart
    - lib/features/analytics/presentation/providers/state_joy_metric_variant.g.dart
    - lib/features/analytics/presentation/widgets/joy_metric_variant_chip.dart
    - test/widget/features/analytics/presentation/widgets/anti_toxicity_phase17_test.dart
    - test/widget/features/analytics/presentation/widgets/joy_metric_variant_chip_test.dart
    - .planning/phases/17-manual-only-joy-sub-metric-happy-v2-03/17-07-SUMMARY.md
  modified:
    - lib/l10n/app_en.arb
    - lib/l10n/app_ja.arb
    - lib/l10n/app_zh.arb
    - lib/generated/app_localizations.dart
    - lib/generated/app_localizations_en.dart
    - lib/generated/app_localizations_ja.dart
    - lib/generated/app_localizations_zh.dart
    - lib/features/analytics/presentation/providers/state_happiness.dart
    - lib/features/analytics/presentation/providers/state_happiness.g.dart
    - lib/features/analytics/presentation/providers/state_analytics.dart
    - lib/features/analytics/presentation/providers/state_analytics.g.dart
    - lib/features/analytics/presentation/providers/state_ledger_snapshot.dart
    - lib/features/analytics/presentation/providers/state_ledger_snapshot.g.dart

key-decisions:
  - "Kept monthlyJoyTargetRecommendation provider free of joyMetricVariant and entrySourceFilter."
  - "Used descriptive copy: voice-estimated entries are excluded, without judging those entries as invalid or inaccurate."
  - "Left AnalyticsScreen AppBar placement and refresh wiring to Plan 17-08 as scoped."

patterns-established:
  - "Presentation variant selection is a session-only analytics concern, not a HomeHero or Settings concern."

requirements-completed: [HAPPY-V2-03]

duration: 11 min
completed: 2026-05-21
---

# Phase 17 Plan 07: Joy Metric Variant State and Chip Summary

**The manual-only audit lens now has localized copy, Riverpod state, provider family keys, and a tested chip/bottom-sheet UI.**

## ARB Keys

| Key | en | ja | zh |
|---|---|---|---|
| `analyticsJoyMetricVariantChipLabel` | Entries | エントリ | 条目 |
| `analyticsJoyMetricVariantSheetTitle` | Joy metric variant | Joy 指標バリアント | Joy 指标变体 |
| `analyticsJoyMetricVariantOptionAll` | All entries | すべてのエントリ | 全部条目 |
| `analyticsJoyMetricVariantOptionManualOnly` | Manual entries only | 手動入力のみ | 仅手动输入 |
| `analyticsJoyMetricVariantManualOnlyExplain` | Manual entries only · excludes voice-estimated entries | 手動入力のみ · 音声推定を除外 | 仅手动输入 · 不含语音估算条目 |

## Provider Extensions

| Provider | Family key changed? | entrySource threaded? |
|---|---:|---:|
| `happinessReport` | Yes | Yes |
| `bestJoyMoment` | Yes | Yes |
| `largestMonthlyExpense` | Yes | Yes |
| `familyHappiness` | Yes | Yes |
| `monthlyReport` | Yes | Yes |
| `expenseTrend` | Yes | Yes |
| `satisfactionDistribution` | Yes | Yes |
| `perCategorySoulBreakdown` | Yes | Yes |
| `perCategorySoulBreakdownFamily` | Yes | Yes |
| `soulVsSurvivalSnapshot` | Yes | Yes |
| `soulVsSurvivalSnapshotFamily` | Yes | Yes |
| `monthlyJoyTargetRecommendation` | No (D-15) | No (D-15) |

## Task Commits

1. **Task 1: Add trilingual Joy metric variant copy** - `bd6f019` (feat)
2. **Task 2: Add Joy metric variant state provider** - `d1bdb40` (feat)
3. **Task 3: Key analytics providers by variant** - `9b655ca` (feat)
4. **Task 4: Add JoyMetricVariantChip** - `ad55e18` (feat)
5. **Task 5: Widget and anti-toxicity coverage** - `25c5473` (test)

**Plan metadata:** pending current commit

## Verification

- `flutter gen-l10n` exited 0.
- `flutter analyze lib/generated lib/features/analytics/presentation/providers lib/features/analytics/presentation/widgets/joy_metric_variant_chip.dart test/widget/features/analytics/presentation/widgets/anti_toxicity_phase17_test.dart test/widget/features/analytics/presentation/widgets/joy_metric_variant_chip_test.dart` returned `No issues found`.
- `grep -r "selectedJoyMetricVariantProvider" lib/features/home` returned no hits.
- `grep -r "JoyMetricVariant" lib/features/home` returned no hits.
- `git diff lib/application/analytics/get_monthly_joy_target_recommendation_use_case.dart` remained empty from Plan 17-06; provider-level recommendation key was not extended.
- Combined regression command passed 164 tests:
  - `test/widget/features/analytics/presentation/widgets/anti_toxicity_phase17_test.dart`
  - `test/widget/features/analytics/presentation/widgets/joy_metric_variant_chip_test.dart`
  - `test/unit/application/analytics`
  - `test/unit/data/daos/analytics_dao_test.dart`
  - `test/unit/data/migrations/migration_v16_to_v17_test.dart`
  - `test/unit/features/accounting/domain/models/transaction_sync_mapper_test.dart`

## Widget Tests

- Anti-toxicity: 3 locales × 2 variants covered for chip + bottom sheet visible text.
- Chip flow: initial all label, sheet open, manual-only selection update + sheet close, all selection update from manual-only + sheet close.

## Deviations from Plan

None. AnalyticsScreen placement and refresh wiring remain scoped to Plan 17-08.

## Issues Encountered

None.

## User Setup Required

None.

## Next Phase Readiness

Plan 17-08 can place `JoyMetricVariantChip` in the AnalyticsScreen AppBar, pass the selected variant into all provider calls, and add the HomeHero isolation/integration tests.

---
*Phase: 17-manual-only-joy-sub-metric-happy-v2-03*
*Completed: 2026-05-21*
