# Plan 17-08 Summary — AnalyticsScreen Integration + Close-Out Tests

**Date:** 2026-05-21  
**Status:** Complete  
**Plan:** `17-08-PLAN.md`

## What Changed

- Integrated `JoyMetricVariantChip(locale: locale)` into `AnalyticsScreen` AppBar immediately after `TimeWindowChip`.
- Read `selectedJoyMetricVariantProvider` once at the top of `AnalyticsScreen.build` and threaded `joyMetricVariant` through every AnalyticsScreen card/provider consumer.
- Extended `_refresh()` with current-variant invalidation keys for all variant-aware AnalyticsScreen providers.
- Preserved the existing D-12 no-home-invalidation comment and added the Phase 17 D-18 comment for variant-aware refresh keys.
- Kept HomeHero source isolated: no `lib/features/home/*` source files changed.
- Preserved HomeHero caller compatibility by making `JoyMetricVariant.all` the provider-family default while AnalyticsScreen passes the explicit variant.

## Diff Notes

- `lib/features/analytics/presentation/screens/analytics_screen.dart`: 88 insertions / 6 deletions.
- D-12 comment preserved verbatim:
  - `D-12: _refresh MUST NOT invalidate any home/* provider`
- Static gates:
  - `joyMetricVariant: variant,` occurrences in `_refresh`: 11
  - `joyMetricVariant: joyMetricVariant,` body-level occurrences: 28
  - `ref.invalidate(selectedJoyMetricVariantProvider)`: absent
  - HomeHero-exclusive invalidations (`todayTransactionsProvider`, `shadowAggregateProvider`, `monthlyJoyTargetRecommendationProvider`): absent

## Tests Added / Extended

Entry-path stamping:
- PASS — `voice entry path stamps entry_source = voice (SC-2)`
- PASS — `manual entry path stamps entry_source = manual (SC-2)`
- PASS — `ocr entry path stamps entry_source = ocr (reserved smoke test; D-07 — no UI stamps this in v1.2)`
- PASS — `hash chain inputs unchanged when entrySource varies (D-02)`

Sync round trip:
- PASS — `end-to-end sync preserves entry_source across device round-trip (D-03)`
- PASS — `end-to-end sync from older-schema peer falls back to manual (D-09)`

HomeHero isolation:
- PASS — `AnalyticsScreen JoyMetricVariant toggle does not invalidate or change HomeHero (Phase 17 SC-4 / D-15)`

## Verification

- PASS — `flutter analyze`
  - Output: `No issues found!`
- PASS — focused Phase 17 regression bundle
  - 189 tests passed.
- PASS — `flutter test --coverage -r expanded`
  - 1669 tests passed.
- PASS — coverage gate
  - `64 checked, 0 failed, 96 missing-from-lcov (skipped), 10 deferred (skipped), threshold: 70`
  - Filtered `coverage/lcov_clean.info`: 74.63% (7079/9485)

Representative per-file coverage:
- `lib/application/accounting/create_transaction_use_case.dart`: 83.33% (40/48)
- `lib/data/repositories/transaction_repository_impl.dart`: 93.18% (82/88)
- `lib/features/analytics/presentation/screens/analytics_screen.dart`: 52.73% (58/110), existing deferred coverage item remains tracked by `coverage-gate-deferred.txt`

## Manual UAT Deferred

Per `17-VALIDATION.md`, these remain human/device checks:
- Two-device sync verification.
- Cold-start toggle reset verification.
- Narrow-viewport AppBar chip layout check.
