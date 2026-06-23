---
phase: 47-i18n-macos-golden-uat
plan: 01
subsystem: ui
tags: [analytics, riverpod, fl_chart, donut, l10n, refresh-invalidation]

# Dependency graph
requires:
  - phase: 46-cards
    provides: round-5 B flat 5-card analytics lineup (AnalyticsCardContext registry, category_donut/joy_calendar/satisfaction_histogram cards, joyDayTransactionsProvider, category_l1_rollup helper)
provides:
  - AnalyticsCardContext with the dead currencyCode field/plumbing removed (JPY-only v1 truth)
  - Donut center-vs-slices reconciliation via a neutral non-tappable "Other" long-tail rollup row/slice
  - Pull-to-refresh now re-fetches the expanded calendar day's inline joy list (no stale/deleted rows)
affects: [47-golden-rebaseline, 47-anti-toxicity-sweep, 47-uat]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Panel-level ref.listen mirror-invalidation for a locally-keyed provider the registry union cannot reach"
    - "Nullable onTap on a legend row to render a non-interactive variant (no InkWell, no chevron)"

key-files:
  created: []
  modified:
    - lib/features/analytics/presentation/analytics_card_registry.dart
    - lib/features/analytics/presentation/widgets/cards/category_donut_card.dart
    - lib/features/analytics/presentation/widgets/cards/joy_calendar_card.dart
    - lib/features/analytics/presentation/widgets/cards/satisfaction_histogram_card.dart
    - lib/features/analytics/presentation/widgets/cards/joy_spend_card.dart
    - lib/features/analytics/presentation/widgets/cards/within_month_trend_card.dart
    - lib/features/analytics/presentation/widgets/cards/family_insight_data_card.dart
    - test/widget/features/analytics/presentation/analytics_card_registry_test.dart
    - test/widget/features/analytics/presentation/widgets/cards/category_donut_card_test.dart

key-decisions:
  - "currencyCode removed from AnalyticsCardContext entirely (WR-01/D-02); happinessReportProvider keeps its required currency key, fed the literal 'JPY' at the call site + refresh-targets (provider keying preserved, only the dead context plumbing dropped)"
  - "Donut Other slice/row uses palette.textTertiary (neutral grey-family, palette-resolved) per 47-UI-SPEC §WR-02; sorted last, non-tappable (null onTap), reuses the existing trilingual analyticsCategoryDonutOther ARB key"
  - "Legend percent divisor switched from donutTotal to the TRUE total so slices + legend reconcile to the count-up center; center TweenAnimationBuilder end stays the true total"
  - "WR-04 implemented as 46-REVIEW option (a): _InlineDayPanel ref.listens the registry-keyed perDayJoyCountsProvider and invalidates the locally-keyed joyDayTransactionsProvider — the registry union is NOT widened (day key is local _JoyCalendarBody state)"

patterns-established:
  - "Mirror-invalidation: a panel whose provider key is local widget state listens to a registry-keyed sibling provider and invalidates its own day-keyed provider on refresh, keeping the registry union home-feature-free (GUARD-01)"

requirements-completed: [GUARD-04]

# Metrics
duration: 10min
completed: 2026-06-17
---

# Phase 47 Plan 01: round-5 B analytics edge-defect fixes (WR-01/WR-02/WR-04) Summary

**Deleted the dead multi-currency plumbing from the analytics card context, made the spend donut center reconcile with its slices via a neutral non-tappable "Other" long-tail rollup, and fixed the expanded calendar day's inline joy list to re-fetch on pull-to-refresh.**

## Performance

- **Duration:** ~10 min
- **Started:** 2026-06-17T14:46Z
- **Completed:** 2026-06-17T14:54Z
- **Tasks:** 3
- **Files modified:** 9

## Accomplishments
- **WR-01** — `AnalyticsCardContext.currencyCode` and its `bookByIdProvider` resolution (plus the now-unused `accounting_providers` import) deleted; all 5 card `_ctx()` builders and the registry test cleaned; `happinessReportProvider` still keyed on a currency (literal `'JPY'`), so no provider behavior changed.
- **WR-02** — Donut center count-up keeps the TRUE `monthly.totalExpenses`; when >10 L1 categories have spend, a neutral (`palette.textTertiary`) non-tappable "Other" slice + legend row of `total - donutTotal` is appended last; every legend percentage now divides by the true total. Reuses the existing trilingual `analyticsCategoryDonutOther` key — no new ARB key.
- **WR-04** — Pulling to refresh while a calendar day is expanded now re-fetches that day's `joyDayTransactionsProvider` alongside the heatmap count, via a panel-level `ref.listen` mirror-invalidation. No `home/*` provider enters the analytics refresh union.

## Task Commits

Each task was committed atomically:

1. **Task 1: WR-01 delete dead currencyCode plumbing** - `4008891a` (refactor)
2. **Task 2: WR-02 donut reconciliation + Other rollup** - `a5009f7e` (test/RED) → `4477d780` (feat/GREEN)
3. **Task 3: WR-04 calendar inline-list refresh** - `94ba8b01` (fix)

_Task 2 was TDD: failing test commit (RED) then implementation (GREEN); no refactor commit needed (code clean)._

## Files Created/Modified
- `analytics_card_registry.dart` - Removed currencyCode field/ctor-param/resolution + unused accounting_providers import; SatisfactionHistogramCard build no longer passes currencyCode
- `category_donut_card.dart` - otherAmount reconciliation, neutral Other PieChart slice + non-tappable legend row, percent divisor → true total, `_LegendRow.onTap` made nullable
- `joy_calendar_card.dart` - `_InlineDayPanel` ref.listens perDayJoyCountsProvider and invalidates the day-keyed joyDayTransactionsProvider; `anchor` threaded into the panel
- `satisfaction_histogram_card.dart` - Dropped currencyCode field/ctor-param/_ctx; feeds happinessReportProvider the literal 'JPY' at build + refresh-targets
- `joy_spend_card.dart`, `within_month_trend_card.dart`, `family_insight_data_card.dart` - Dropped `currencyCode: 'JPY'` from `_ctx()` (+ family_insight doc comment)
- `analytics_card_registry_test.dart` - Dropped currencyCode from build helper; refresh-target expectation matches literal 'JPY'
- `category_donut_card_test.dart` - Added two WR-02 tests (>10-category Other reconciliation + non-tappable; ≤10 no-Other); >10 test wraps the card in a scroll view + ensureVisible to reach the off-screen Other row

## Decisions Made
See `key-decisions` frontmatter. In brief: currencyCode fully removed from the context (not just hardcoded); Other row neutral/palette-resolved/non-tappable/ARB-reused; WR-04 done at the panel (not the registry) because the day key is local widget state.

## Deviations from Plan

None - plan executed exactly as written. (No deviation rules triggered: no bugs, no missing critical functionality, no blocking issues, no architectural changes. No package installs.)

## Issues Encountered

1. **WR-02 >10-category test overflowed the 800x600 test viewport** — the bare card renders 10 L1 rows + Other + donut, taller than 600px, so the off-screen Other row could not be tapped. Resolved by wrapping the test subject in a `Scaffold`/`SingleChildScrollView` and calling `tester.ensureVisible` before the tap (the real screen already hosts the card in a scroll view). Not a production change.
2. **REDES-01 structural test flagged the literal substring `home/` in a WR-04 code comment** — the registry test does a raw `source.contains('home/')` on every `cards/*.dart`. Reworded the comment from "no `home/*` provider" to "no home-feature provider" to avoid the false positive. No semantic change.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Analytics feature compiles with zero `ctx.currencyCode` references; `flutter analyze lib/features/analytics` = 0 issues.
- Scoped analytics widget suite green (176/176), home-isolation green, color-literal + hardcoded-CJK scans green.
- Donut now has a >10-L1 "Other" state and the WR-02 reconciliation that Phase 47's macOS golden re-baseline + anti-toxicity sweep must cover (the new `analyticsCategoryDonutOther` legend state should be exercised in the >10-category fixture per 47-UI-SPEC).
- Full-suite gate is deferred to the Plan 06 wave gate (per the plan's verification note), not run here.

## Self-Check: PASSED

- FOUND: `.planning/phases/47-i18n-macos-golden-uat/47-01-SUMMARY.md`
- FOUND commits: `4008891a`, `a5009f7e`, `4477d780`, `94ba8b01`
- All modified production files present; `flutter analyze lib/features/analytics` = 0 issues; scoped analytics tests green.

---
*Phase: 47-i18n-macos-golden-uat*
*Completed: 2026-06-17*
