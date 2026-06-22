# Phase 48: Address v1.8 tech debt — member-filter donut refresh + stale trend comments - Context

**Gathered:** 2026-06-22
**Status:** Ready for planning
**Source:** Inline decision capture (orchestrator + user) — derived from `.planning/v1.8-MILESTONE-AUDIT.md` Tech Debt §1/§2

<domain>
## Phase Boundary

Post-milestone cleanup phase appended to v1.8 (range 43→48) to clear the **two code-grade**
tech-debt items recorded in `.planning/v1.8-MILESTONE-AUDIT.md`. No new feature, no new card,
no new surface — this is a correctness + doc-hygiene cleanup over existing analytics code.

**In scope (exactly two items):**

- **TD-1 — member-filtered donut pull-to-refresh staleness (WARNING).** `category_donut_card.dart:191`
  watches `memberFilteredCategoryBreakdownProvider(deviceId:)` when a member filter is active, but
  `categoryDonutRefreshTargets` (`category_donut_card.dart:283`) does NOT list it, so pull-to-refresh
  serves cached filtered data. Introduced by quick-task `260622-d5i` after Phase 47 closed.

- **TD-2 — stale TREND-01 dartdoc (doc-hygiene).** `GetExpenseTrendUseCase` + `MonthlyTrend` were
  removed in Phase 46 (D-E2) and replaced by `GetWithinMonthCumulativeUseCase`. No code references
  the removed symbols, but stale dartdoc comments naming them remain in
  `repository_providers.dart` (source line ~64) + its generated `.g.dart` (lines 168/180/196,
  three copies of the one source dartdoc) + one characterization test description string
  (`analytics_providers_characterization_test.dart:60`).

**Out of scope (documentation-grade audit residue — explicitly deferred, matches v1.2–v1.7 close pattern):**
- Phase 47 Nyquist VALIDATION.md / `nyquist_compliant` drafts.
- SUMMARY.md frontmatter `status:` drift across quick tasks.
- Any analytics behavior/visual change, new drill-down, new provider family, or schema work.
</domain>

<decisions>
## Implementation Decisions

### TD-1 — Member-filter donut refresh (USER-SELECTED: proper fix)

- **D-01 (TD-1 proper fix — thread the filter):** Add a nullable `memberFilterDeviceId` field to
  `AnalyticsCardContext` (`analytics_card_registry.dart:32`). Read `donutDimensionStateProvider`
  inside `buildAnalyticsCardContext` (`analytics_card_registry.dart:117`) and pass its
  `memberFilterDeviceId` into the context. In `categoryDonutRefreshTargets`
  (`category_donut_card.dart:283`), conditionally append
  `memberFilteredCategoryBreakdownProvider(bookId/startDate/endDate/deviceId/joyMetricVariant)`
  when `ctx.memberFilterDeviceId != null`, so the shell's pull-to-refresh union
  (`registry.where(isVisible).expand(refreshTargets)`) actually invalidates the displayed
  filtered breakdown. The card's local `_ctx()` (`category_donut_card.dart:260`) must pass the
  same filter so its self-derived `targets` stays consistent (its error-retry already invalidates
  the filtered provider directly — keep that path). `donutDimensionStateProvider` is an analytics
  `state_*` provider → GUARD-01 (registry imports zero `home/*`) stays intact.

- **D-02 (registry-test whitelist):** Add `'MemberFilteredCategoryBreakdownProvider'` to
  `_analyticsProviderTypeWhitelist` in `analytics_card_registry_test.dart`, since the refresh
  union may now legally contain that analytics family. The union ⊆ analytics (isolation /
  zero `home/*`) assertion must still pass.

- **D-03 (USER-SELECTED: add completeness guard):** Add a completeness assertion to
  `analytics_card_registry_test.dart`: when a member filter is active, the provider the donut
  card actively watches (`memberFilteredCategoryBreakdownProvider`) MUST appear in the
  registry-derived refresh union. This closes the gap that let TD-1 slip in — the existing test
  asserts union ⊆ whitelist (isolation) but never union ⊇ active card-watches (completeness).

### TD-2 — Stale TREND-01 dartdoc (doc-hygiene)

- **D-04 (scrub removed-symbol references + regenerate):** Rewrite the dartdoc on
  `getWithinMonthCumulativeUseCase` in `repository_providers.dart` so it no longer names the
  removed `getExpenseTrendUseCase` / `MonthlyTrend` symbols (keep the useful "reuses
  `findByBookIds`, NOT analyticsRepository" rationale; drop or rephrase the "Replaces the deleted
  6-month getExpenseTrendUseCase / MonthlyTrend/BarChart" clause). Then run build_runner so the
  three generated copies in `repository_providers.g.dart` (168/180/196) update automatically —
  **never hand-edit `.g.dart`** (project pitfall #1). Update the one characterization test
  description string at `analytics_providers_characterization_test.dart:60` to not name the
  removed symbol. After the run: `grep -rn "getExpenseTrend\|MonthlyTrend" lib/ test/` returns 0.

### Claude's Discretion
- Exact reworded dartdoc text and test-description wording (constraint: name no removed symbol;
  keep meaning accurate).
- Exact shape of the D-03 completeness assertion (synthetic ctx vs widget-pump) — prefer the
  existing test's pure-over-ctx, no-widget-pump style (RESEARCH A3).
- Whether D-01/D-02/D-03 land as one plan or two waves (they touch overlapping files —
  `category_donut_card.dart`, `analytics_card_registry.dart`, the registry test — so likely ONE
  plan/wave to avoid same-file merge collisions; TD-2 is independent and may be parallel).
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Audit source of truth
- `.planning/v1.8-MILESTONE-AUDIT.md` — Tech Debt §1 (TD-1) and §2 (TD-2); fix options enumerated.

### TD-1 code
- `lib/features/analytics/presentation/analytics_card_registry.dart` — `AnalyticsCardContext`
  class (32), `buildAnalyticsCardContext` (117), `shellRefreshTargets` (148), the
  `registry.where(isVisible).expand(refreshTargets)` union contract (152+).
- `lib/features/analytics/presentation/widgets/cards/category_donut_card.dart` — member-filtered
  watch (190–226), `categoryDonutRefreshTargets` (283), local `_ctx()` (260).
- `lib/features/analytics/presentation/providers/state_donut_dimension.dart` —
  `donutDimensionStateProvider`, `DonutDimension`, nullable `memberFilterDeviceId` (24–55).
- `lib/features/analytics/presentation/providers/state_analytics.dart` —
  `memberFilteredCategoryBreakdown` provider + `MemberFilteredCategoryBreakdown` model (91–157).
- `test/widget/features/analytics/presentation/analytics_card_registry_test.dart` —
  `_analyticsProviderTypeWhitelist` + the D-B3/GUARD-01 isolation assertions to extend.

### TD-2 code
- `lib/features/analytics/presentation/providers/repository_providers.dart` — stale dartdoc (~64).
- `lib/features/analytics/presentation/providers/repository_providers.g.dart` — generated mirror
  (168/180/196); regenerated, never hand-edited.
- `test/unit/features/analytics/presentation/providers/analytics_providers_characterization_test.dart`
  — stale test description (60).

### Project invariants
- `CLAUDE.md` — pitfall #1 (don't hand-edit `.g.dart`), Drift v21 (no migration), Riverpod 3
  conventions, all UI text via `S.of(context)`, zero raw hex.
</canonical_refs>

<specifics>
## Specific Ideas

- **Verification probe for TD-1:** with a member filter active, a pull-to-refresh should now
  re-fetch the filtered breakdown (no stale data). The completeness test (D-03) is the durable
  regression guard; a widget refresh test is optional if the unit-level union assertion proves
  membership.
- **Golden expectation:** D-01 changes refresh *wiring* only, not rendered bytes → expect
  **0 golden re-baseline**. If any golden unexpectedly shifts, re-baseline on **macOS only**
  (CI is ubuntu; `flutter_test_config.dart` swaps in `BaselineExistenceGoldenComparator` off-macOS).
- **Gate:** per-wave gate is the FULL `flutter test` (not a scoped subset — architecture tests
  like the registry isolation test and `anti_toxicity_*` sweeps must run), `flutter analyze` 0.
- **build_runner required** after the D-04 source-comment edit (regenerates `.g.dart`) and after
  any `@riverpod` touch.
</specifics>

<deferred>
## Deferred Ideas

- Phase 47 Nyquist VALIDATION.md drafts (`/gsd-validate-phase 47`) — documentation-grade; deferred,
  consistent with accepted v1.2–v1.7 close pattern.
- SUMMARY.md frontmatter `status:` drift — cosmetic metadata, no functional gap.
- TD-1 option (b) "document-only / retry-only semantics" — **rejected** in favor of D-01 proper fix.
</deferred>

<scope_fence>
## Scope Fence (do NOT cross)

- NO Drift migration — schema stays **v21**. NO new DAO, NO new provider family, NO new card.
- GUARD-01: the registry and its context builder import **zero `home/*`** providers.
- ADR-012 anti-gamification unaffected — no new surface, no streak/target/delta; `anti_toxicity_*`
  sweeps stay green.
- ADR-016 §3 HomeHero isolation untouched — analytics reads/invalidates NO `home/*` provider.
- All UI text via `S.of(context)`; zero raw hex (none expected — no new UI).
- Do NOT hand-edit any `.g.dart`; regenerate via build_runner.
- Do NOT touch the doc-grade out-of-scope items above.
</scope_fence>

---

*Phase: 48-address-v1-8-tech-debt-member-filter-donut-refresh-stale-tre*
*Context gathered: 2026-06-22 via inline decision capture*
