---
phase: 48-address-v1-8-tech-debt-member-filter-donut-refresh-stale-tre
reviewed: 2026-06-22T00:00:00Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - lib/features/analytics/presentation/analytics_card_registry.dart
  - lib/features/analytics/presentation/widgets/cards/category_donut_card.dart
  - test/widget/features/analytics/presentation/analytics_card_registry_test.dart
  - lib/features/analytics/presentation/providers/repository_providers.dart
  - test/unit/features/analytics/presentation/providers/analytics_providers_characterization_test.dart
findings:
  critical: 0
  warning: 1
  info: 3
  total: 4
status: issues_found
---

# Phase 48: Code Review Report

**Reviewed:** 2026-06-22
**Depth:** standard
**Files Reviewed:** 5
**Status:** issues_found

## Summary

Phase 48 is a two-item v1.8 tech-debt cleanup. I reviewed both with an adversarial
stance, tracing the full data path end-to-end (state model → context builder →
refresh-targets function → shell `_refresh`) and verifying provider-family key
equality between what the donut card *watches* and what the refresh union
*invalidates*.

**TD-1 (member-filter donut refresh):** Correctly implemented. `memberFilterDeviceId`
is threaded `donutDimensionStateProvider` → `buildAnalyticsCardContext` →
`AnalyticsCardContext` → `categoryDonutRefreshTargets`, and the conditional append
(`if (ctx.memberFilterDeviceId != null)`) keys the filtered provider IDENTICALLY to
the card's watch (`bookId`/`startDate`/`endDate`/`deviceId`/`joyMetricVariant`,
verified against `state_analytics.dart:102-109`), so Riverpod family dedup makes the
union actually invalidate the watched instance. The unfiltered union stays the
byte-stable 4-target order (the append is the last list element, guarded). GUARD-01
holds: no `home/*` imports were added. The shell `_refresh`
(`analytics_screen.dart:151`) derives the union from the registry, so the new context
field flows through automatically — no hand-listing.

**TD-2 (stale dartdoc scrub):** Clean. The two references to the removed
`getExpenseTrendUseCase`/`MonthlyTrend` symbols are gone (one dartdoc block, one test
description string); the replacement prose is accurate ("retired in Phase 46, D-E2").
No code behavior changed.

The findings below are all maintainability/edge-case observations — no correctness,
security, or data-loss defects were found. The single WARNING is a real (if benign
in current call paths) semantic mismatch between the refresh-target append condition
and the card's actual watch condition.

## Warnings

### WR-01: Refresh-target append condition is broader than the card's actual watch condition

**File:** `lib/features/analytics/presentation/widgets/cards/category_donut_card.dart:335` (target) vs `:139` / `:194` (watch)
**Issue:** `categoryDonutRefreshTargets` appends `memberFilteredCategoryBreakdownProvider`
whenever `ctx.memberFilterDeviceId != null` — **regardless of the active dimension**.
But the card only *watches* that provider when `dimension == category && memberFilterDeviceId != null`.
When `dimension == DonutDimension.member` AND a member filter is active, the card takes
the member-dimension branch (line 139) and watches `memberSpendBreakdownProvider`, never
`memberFilteredCategoryBreakdownProvider` — yet the refresh union still invalidates the
latter.

This is currently **harmless** (invalidating an uncached/unwatched provider is a no-op
in Riverpod, and the union ⊇ watched invariant the phase cares about still holds), so it
is not a BLOCKER. But it is a real divergence between "what we refresh" and "what we
watch," which is exactly the build-vs-invalidation drift class D-B2 was written to prevent.
If a future change makes invalidation of an inactive family non-trivial (e.g. eager
re-fetch), this becomes a latent bug. The completeness regression test `(f)` does NOT
catch it because it only exercises the category-dimension scenario.

**Fix:** Either (a) gate the append on the same condition the card watches — but
`DonutDimension` is not currently a field on `AnalyticsCardContext`, so this would require
threading `dimension` through the context — or (b) document explicitly in the
`categoryDonutRefreshTargets` dartdoc that the filtered target is intentionally appended
in member-dimension mode too as a harmless over-invalidation. Option (b) is the lower-risk
choice given the no-op semantics; the existing dartdoc (lines 293-299) implies the append
tracks the watch 1:1 ("the donut watches `memberFilteredCategoryBreakdownProvider`"),
which is only true in category dimension — tighten that wording:

```dart
/// TD-1 / D-01: appended whenever a member filter is active. In the CATEGORY
/// dimension the donut watches this exact family; in the MEMBER dimension it is
/// a harmless over-invalidation (no-op — the family is uncached there). Either
/// way the union ⊇ watched invariant holds.
```

## Info

### IN-01: `category_donut_card.dart` `_ctx().locale`/`isGroupMode` are dead placeholders

**File:** `lib/features/analytics/presentation/widgets/cards/category_donut_card.dart:274-275`
**Issue:** The card-local `_ctx(...)` hardcodes `isGroupMode: false` and
`locale: const Locale('ja')` purely to satisfy the required constructor params, even
though `categoryDonutRefreshTargets` reads neither. This is benign (the targets function
provably ignores those fields), but it is a code smell — a future target that *does* read
`isGroupMode`/`locale` would silently get wrong values from this card-local context.
**Fix:** Acceptable as-is given the constructor requires them; if churn allows, consider a
narrower `AnalyticsCardRefreshKey` record holding only the fields the targets functions
consume, so card-local contexts cannot supply misleading values. Low priority.

### IN-02: Unused import `state_happiness.dart` in registry test

**File:** `test/widget/features/analytics/presentation/analytics_card_registry_test.dart:8`
**Issue:** `import '.../providers/state_happiness.dart';` is present but no symbol from it
is referenced in the file (`happinessReportProvider` comes from `state_analytics.dart`).
This pre-dates Phase 48 (not introduced by this diff), but it is in a reviewed file.
`flutter analyze` is reported 0, so it may be re-exported transitively; still worth a quick
check.
**Fix:** Remove the import if `flutter analyze` confirms it is unused, or leave it if a
`.g.dart`/re-export depends on it. Verify with `flutter analyze`.

### IN-03: Completeness test `(f)` does not cover the member-dimension + filter scenario

**File:** `test/widget/features/analytics/presentation/analytics_card_registry_test.dart:372-430`
**Issue:** The new regression guard `(f)` is well-constructed for the category-dimension
path (positive: filtered family present; negative control: absent when unfiltered; mutual
consistency: still ⊆ whitelist). But because `AnalyticsCardContext` carries no `dimension`
field, the test cannot — and does not — assert behavior for the
`dimension == member && filter active` case described in WR-01. The guard therefore proves
"the filtered target enters the union when a filter is set" but not "the union matches what
the card actually watches across all dimensions."
**Fix:** No action required if WR-01 is resolved via documentation (option b). If
`dimension` is ever added to the context, extend `(f)` with a member-dimension assertion.

---

_Reviewed: 2026-06-22_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
