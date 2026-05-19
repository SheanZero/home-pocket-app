# Phase 15: Custom Time Windows (HAPPY-V2-02) - Context

**Gathered:** 2026-05-19T09:31:31Z
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 15 delivers a session-persistent custom time-window selector for `AnalyticsScreen`. Users can select week / month / quarter / year / arbitrary date ranges, and the existing AnalyticsScreen metrics re-query against the selected window where specified below.

**In scope:**
- Replace the existing AppBar month chip with a unified time-window chip.
- Add week / month / quarter / year / custom range selection in a bottom sheet.
- Parameterize AnalyticsScreen use cases/providers currently bound to `(year, month)` so they can accept validated `(startDate, endDate)` windows where needed.
- Keep the selected window in session state only; do not persist across app restart.
- Keep HomeHero month-anchored. HomeHero and Home tab prefetch/refresh do not follow this selector.
- Enforce ADR-012/ADR-016 boundaries: no cross-period delta UI, no comparison overlays, no achievement/milestone behavior.

**Out of scope:**
- New analytics capabilities beyond making existing AnalyticsScreen cards respect the selected window.
- Rebuilding the six-month trend card into a window trend; it remains a rolling six-month background card.
- Any HomeHero semantic change, target-history feature, cross-tab time-window sync, family-member breakdown, leaderboard, or family target semantics.

</domain>

<decisions>
## Implementation Decisions

### Selector Shape

- **D-01: Replace the AppBar month chip with a unified time-window chip.** The current `MonthChipPicker` entry point should evolve into a chip that displays the active window label, such as current week, a month, a quarter, a year, or a custom date range.
- **D-02: The bottom sheet first selects window type, then shows the type-specific chooser.** The top of the sheet exposes Week / Month / Quarter / Year / Custom. The body changes according to the selected type: week list, month list, quarter list, year list, or custom date range.
- **D-03: Custom range uses the system date-range picker.** Do not build a custom in-sheet calendar/input control in Phase 15.
- **D-04: Selection applies immediately.** Week/month/quarter/year list selection applies and closes the sheet. Custom applies after the system date-range picker confirms a valid range.

### Date Boundary Semantics

- **D-05: Weeks start on Monday for all locales.** Do not use locale-dependent week starts in Phase 15.
- **D-06: Ranges are inclusive.** The selected range means `startDate 00:00:00` through `endDate 23:59:59`, matching the current DAO/use-case style that includes `timestamp <= endDate`.
- **D-07: Future dates are not selectable.** Preset lists and custom ranges cap at today. The selector is for already-existing financial data, not future projections.
- **D-08: Custom ranges longer than 12 months are rejected after selection with localized error copy.** Do not silently crop the range. Do not rely on the date picker itself to enforce the 12-month span unless implementation makes that trivial; the locked behavior is that invalid ranges cannot apply and users receive a localized message.

### Metric Coverage

- **D-09: The selected window applies across the current AnalyticsScreen cards, with one explicit exception.** Existing KPI, distribution, category, story, and family cards should use the active window once their providers/use cases are parameterized.
- **D-10: The six-month trend card remains a rolling six-month trend.** `TotalSixMonthCard` / `MonthlySpendTrendBarChart` does not become a window-granularity chart in Phase 15. It remains a long-term background card even when the active selector is week, quarter, year, or custom.
- **D-11: FamilyInsightCard follows the active window, but remains aggregate-only.** This phase may pass the active date range into family aggregate queries. It must not add family-member rankings, member comparisons, family target semantics, or any other family-axis feature.
- **D-12: HomeHero and Home tab prefetch/refresh do not follow the AnalyticsScreen window.** HomeHero remains current-calendar-month anchored per ADR-016 ring semantics. Existing Home tab prefetch continues to use current month providers.

### Planner Discretion

- Exact widget/file naming is planner discretion. Recommended direction: rename or replace `MonthChipPicker` with a more general time-window selector only if that keeps tests clearer; avoid keeping misleading "month" names in new public APIs.
- Exact active-window state model is planner discretion, but it should be session-scoped Riverpod state analogous to `selectedMonthProvider`.
- Exact label text and ARB key names are planner discretion, subject to ja/zh/en parity and `DateFormatter`/project formatter usage for date display.
- Exact retry/error placement for invalid custom ranges is planner discretion, but the error must be localized and test-covered.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Planning

- `.planning/PROJECT.md` — v1.2 milestone goal, active requirement list, and cross-phase Joy metric context.
- `.planning/REQUIREMENTS.md` — HAPPY-V2-02 requirement; v1.2 out-of-scope rows; cross-phase constraints for ADR-012, ADR-014, ADR-016, CI, and i18n parity.
- `.planning/ROADMAP.md` — Phase 15 goal and success criteria, especially session-only persistence, `(startDate, endDate)` validation, `>12 months` rejection, HomeHero month anchor, date formatter usage, and no cross-period delta UI.
- `.planning/STATE.md` — Current milestone state and carried decisions from Phases 13/14.

### Prior Phase Hand-Off

- `.planning/phases/13-adr-016-backend-foundation/13-CONTEXT.md` — `joyContribution` backend semantics, date-range capable DAO/repository patterns, and Phase 15 deferred note.
- `.planning/phases/14-adr-016-frontend-arb-reconciliation-tool-v2-02/14-CONTEXT.md` — Analytics Variant epsilon base, HomeHero locked month anchoring, and Phase 15 deferral for custom windows.

### Architecture / ADR Constraints

- `docs/arch/03-adr/ADR-016_Joy_Metric_Visualization_Redesign.md` — single Joy expression and HomeHero monthly ring semantics; Phase 15 must not affect HomeHero.
- `docs/arch/03-adr/ADR-012_No_Gamification_v1_1.md` — no cross-period deltas, streaks, achievement behavior, leaderboards, or public sharing.
- `docs/arch/03-adr/ADR-014_Soul_Satisfaction_Unipolar_Positive_Scale.md` — satisfaction metrics remain unipolar positive support signals.
- `docs/arch/01-core-architecture/ARCH-001_Complete_Guide.md` — Clean Architecture / Thin Feature placement rules.
- `docs/arch/01-core-architecture/ARCH-004_State_Management.md` — Riverpod state/provider conventions.

### Source Integration Points

- `lib/features/analytics/presentation/screens/analytics_screen.dart` — current AnalyticsScreen composition, AppBar `MonthChipPicker`, card provider calls, refresh invalidation, and card-specific date parameters.
- `lib/features/analytics/presentation/widgets/month_chip_picker.dart` — existing AppBar picker entry point and bottom-sheet pattern to evolve into the time-window selector.
- `lib/features/analytics/presentation/providers/state_analytics.dart` — current `selectedMonthProvider`, `monthlyReportProvider`, `expenseTrendProvider`, `earliestTransactionMonthProvider`, and `satisfactionDistributionProvider`.
- `lib/features/analytics/presentation/providers/state_happiness.dart` — current `happinessReportProvider`, `bestJoyMomentProvider`, `familyHappinessProvider`, and story/family integration points.
- `lib/application/analytics/get_happiness_report_use_case.dart` — currently month-bound; should accept/reuse a date-window path for Joy KPI and histogram gating.
- `lib/application/analytics/get_satisfaction_distribution_use_case.dart` — currently month-bound; should accept the active window.
- `lib/application/analytics/get_best_joy_moment_use_case.dart` — currently month-bound; should accept the active window.
- `lib/application/analytics/get_largest_monthly_expense_use_case.dart` — currently month-bound; follows the active window per D-09.
- `lib/application/analytics/get_monthly_report_use_case.dart` — month-specific total/category report; planner decides whether to generalize or introduce a window report path for cards that must follow D-09.
- `lib/application/analytics/get_expense_trend_use_case.dart` — remains rolling six-month trend per D-10.
- `lib/features/analytics/domain/repositories/analytics_repository.dart` and `lib/data/repositories/analytics_repository_impl.dart` — already expose repository methods with `startDate` / `endDate`; use these instead of adding month-only surfaces.
- `lib/data/daos/analytics_dao.dart` — DAO queries already accept `startDate` / `endDate` for many aggregates and use inclusive timestamp filtering.
- `lib/l10n/app_en.arb`, `lib/l10n/app_ja.arb`, `lib/l10n/app_zh.arb` — add selector labels, range labels, invalid-range error copy, and any changed card captions in lockstep.
- `lib/generated/app_localizations*.dart` — generated after `flutter gen-l10n`; do not hand-edit.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `MonthChipPicker` already provides the AppBar chip + bottom-sheet picker pattern. It can be replaced/evolved into the new time-window selector.
- `selectedMonthProvider` is the closest state pattern for session-only AnalyticsScreen selection. A new selected-window provider should follow the same Riverpod style.
- `AnalyticsRepository` and `AnalyticsDao` already use `startDate` / `endDate` for monthly totals, category totals, satisfaction overview, distribution, best Joy, largest expense, and family aggregate queries. Phase 15 should primarily change application/presentation parameters rather than invent new DAO concepts.
- `GetExpenseTrendUseCase` already owns six-month rolling trend semantics and should remain stable per D-10.
- Existing analytics widget tests around `AnalyticsScreen`, `MonthChipPicker`, KPI strip, histogram, story cards, and family card are the likely regression targets.

### Established Patterns

- AnalyticsScreen uses sectioned cards and per-card `AsyncValue.when` fault isolation. Preserve this: a failed windowed provider should not blank the entire page.
- User-facing labels must come from `S.of(context)` with ja/zh/en ARB parity.
- Date display must use project formatter infrastructure, not ad hoc string interpolation.
- Provider families currently key on `(bookId, year, month)` for month-bound reports. New windowed providers should key on stable window values (`startDate`, `endDate`, and possibly window type) so Riverpod cache/invalidation is predictable.
- Domain/application layers should receive date-window values, not presentation-specific selector enums unless the use case truly needs the semantic type.

### Integration Points

- `AnalyticsScreen` should derive an active window from the selector state, then pass `startDate` / `endDate` into every card that follows D-09.
- Refresh invalidation must invalidate providers keyed by the active window. It must not invalidate HomeHero/Home tab providers.
- The selector needs earliest-data awareness for preset lists, while still capping future dates at today.
- The custom-range validation path must block ranges where `start > end`, dates exceed today, or the span is over 12 months.
- Family mode should pass the active window into aggregate family use cases only; no member-level data surface is introduced.

</code_context>

<specifics>
## Specific Ideas

- The new selector is an evolution of the existing AppBar chip, not a new top-of-page filter bar.
- The UI should feel like "choose the Analytics window" rather than "compare periods." No previous-period labels, deltas, arrows, or "vs" language.
- Week starts Monday regardless of locale. This is intentionally stable for accounting/statistics even if it differs from some locale calendar habits.
- The six-month trend is explicitly a context card. It is allowed to remain month-based while the rest of the screen follows the selected window.
- Family insight follows the window only as aggregate insight. Family-member ranking/comparison remains forbidden.

</specifics>

<deferred>
## Deferred Ideas

- Window-granularity trend chart (daily within week/custom, monthly within quarter/year) — deferred. D-10 keeps the six-month trend card unchanged in Phase 15.
- Cross-period comparison labels such as "this quarter vs last quarter" — forbidden by ADR-012 and out of scope.
- HomeHero awareness of the AnalyticsScreen selected window — out of scope; HomeHero remains current-month anchored.
- Persisting the selected window across app restart — out of scope for v1.2 Phase 15; selection persists per session only.
- Family member breakdowns, rankings, or family target semantics — out of scope and blocked by cross-phase privacy/anti-gamification constraints.

</deferred>

---

*Phase: 15-Custom Time Windows (HAPPY-V2-02)*
*Context gathered: 2026-05-19T09:31:31Z*
