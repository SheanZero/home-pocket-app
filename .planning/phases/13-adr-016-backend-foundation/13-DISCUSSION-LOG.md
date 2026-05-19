# Phase 13: ADR-016 Backend Foundation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-19
**Phase:** 13-ADR-016 Backend Foundation
**Areas discussed:** monthly_joy_target persistence, Spike scoping, Density-removal scope

---

## Gray Area Selection

| Option | Description | Selected |
|--------|-------------|----------|
| monthly_joy_target persistence | Drift table (ROADMAP wording) vs SharedPreferences (current code) vs hybrid | ✓ |
| Spike scoping (fallback baseline + outlier policy + recommendation-after-config behavior) | ADR-016 §4 explicit TBDs for 1-day spike | ✓ |
| HappinessReport return type + field naming | MetricResult<int> vs <double>; field naming; ARB downstream impact | (skipped — to planner discretion) |
| Density-removal scope (what Phase 13 owns vs Phase 14) | Backend-only vs full UI rip vs Phase 14 split | ✓ |

**User's choice:** Persistence, Spike scoping, Density-removal scope.
**Notes:** HappinessReport field naming + numeric type intentionally left to planner per Phase 9 conventions (recommended in CONTEXT.md §Claude's Discretion).

---

## monthly_joy_target persistence

### Q1 — Where should `monthly_joy_target` live?

| Option | Description | Selected |
|--------|-------------|----------|
| New Drift table `user_settings` | Matches ROADMAP SC-2 wording; schema bump 16→17; encryption-aligned | |
| Extend existing `AppSettings` (SharedPreferences) | No migration; matches current convention | ✓ |
| Hybrid — SharedPreferences now, Drift later | Defers migration but doesn't eliminate it | |

**User's choice:** Extend existing `AppSettings` via SharedPreferences (with follow-up request to continue in Chinese).
**Notes:** User explicitly opted out of a Drift table for a single nullable integer; ROADMAP SC-2 wording deviation accepted with fixup task in Phase 13 plan.

### Q2 — ROADMAP SC-2 wording disposition

| Option | Description | Selected |
|--------|-------------|----------|
| Plan task #1 corrects SC-2 + REQUIREMENTS wording | Phase 13 plan synchronously edits ROADMAP/REQUIREMENTS | ✓ |
| Keep SC-2 wording + plan note explains deviation | Preserves history; verify-phase will flag mismatch | |
| Keep SC-2 wording + build empty `user_settings` table | Dead code shim to honor literal wording | |

**User's choice:** Plan task #1 corrects SC-2 + REQUIREMENTS wording.
**Notes:** Phase 13 plan first task = wording correction; AppSettings round-trip getter/setter unit test replaces the "schema-migration test" framing.

### Q3 — Null encoding for "未配置"

| Option | Description | Selected |
|--------|-------------|----------|
| Key absence = null | `prefs.getInt(key)` returns null; matches existing pattern | ✓ |
| Sentinel value (0 = unconfigured) | Hidden semantic; classic anti-pattern | |
| Two-key (isConfigured: bool + value: int) | Extra inconsistency surface for no benefit | |

**User's choice:** Key absence = null; domain layer uses `int?`.
**Notes:** Aligns with `_languageKey` / `_themeModeKey` pattern in current `settings_repository_impl.dart`.

### Q4 — Recommendation calculation organization

| Option | Description | Selected |
|--------|-------------|----------|
| Independent `GetMonthlyJoyTargetRecommendationUseCase` | One use case per output; clean separation | ✓ |
| Fold into `GetHappinessReportUseCase` output | Single round-trip but mixes scopes (current month vs past 3) | |
| Repository-layer helper, skip use case | Layer-violation risk; inconsistent with sibling use cases | |

**User's choice:** Independent use case in `lib/application/analytics/`.
**Notes:** Mirrors Phase 9 D-22 "use case per aggregate" pattern; DAO support strategy (3× existing calls vs new range method) left to planner.

---

## Spike scoping (Phase 13 plan deliverable)

### Q1 — Spike form

| Option | Description | Selected |
|--------|-------------|----------|
| Demo data-driven simulation + Markdown report | Use `demo_data_service.dart` to seed scenarios; run formula | ✓ |
| Pure product judgment / experience | No data run; just pick numbers | |
| Use v1.1 local dogfood data if any | Only developer-self data; likely <3 complete months | |

**User's choice:** Demo data-driven simulation + Markdown spike report as Phase 13 plan deliverable.
**Notes:** Spike output filed at `.planning/phases/13-adr-016-backend-foundation/13-SPIKE.md` (planner discretion on exact path).

### Q2 — Fallback baseline anchor

| Option | Description | Selected |
|--------|-------------|----------|
| Anchor 50, spike may adjust within [30, 100] | Calibrated against ~10 soul tx at ¥500/sat=6 mental model | ✓ |
| Fully open — no plan-side anchor | Spike output not biased; may exit ADR-016 candidate range | |
| Anchor 30 (conservative) | Low-activity users see progress; high-activity users saturate fast | |

**User's choice:** Anchor 50; spike has authority to revise within [30, 100].
**Notes:** Anchor reflects the "10 笔 ¥500 sat=6 → 60" intuition. Exit-range adjustments require re-discussion.

### Q3 — Outlier policy

| Option | Description | Selected |
|--------|-------------|----------|
| No trim — rely on median robustness | 3-point median is naturally robust; trim further shrinks tiny sample | ✓ |
| Per-transaction trim (single-tx > 3× p75 of month) | ADR-016 §4 candidate; ADR-013 already attenuates large tx via PTVF α | |
| Month-level trim (drop max + min) | Mathematically equivalent to median itself on 3 points | |

**User's choice:** No trim.
**Notes:** Spike report records explicit decision; manual user override (Settings UI) is the safety valve if recommendation feels off.

### Q4 — Recommendation persistence in Settings UI

| Option | Description | Selected |
|--------|-------------|----------|
| Only show recommendation when unconfigured (hint) | Hint disappears once user types a value | |
| Always show both values (user value + recommended) | Recommendation persists as parallel reference | ✓ |
| Settings page toggle to view recommendation | Hidden by default | |

**User's choice:** Always show both values.
**Notes:** Critical follow-up constraint added by Claude: framing must be reference-only — no delta language ("高于建议 +N", "比推荐低", arrow indicators, colored deltas). This is the load-bearing protection against ADR-012 §4 in Phase 14 ARB review.

---

## Density-removal scope (Phase 13 boundary vs Phase 14)

### Q1 — How aggressive on UI density rip

| Option | Description | Selected |
|--------|-------------|----------|
| Backend + AnalyticsScreen full rip; HomeHero = field rename + draft | Two-tier scope split | ✓ |
| Backend only; UI untouched in Phase 13 | Dual-field interim state; SC-5 not met | |
| Phase 13 also redesigns HomeHero ring | Compresses Phases 13+14 into one phase | |

**User's choice:** Backend + AnalyticsScreen full rip; HomeHero minimal migration only.
**Notes:** HomeHero gets field rename (`joyPerYen → joyContribution`) and formatter switch (`formatJoyDensity → formatJoyCumulative`); ring color, monthly reset, 100% behavior all deferred to Phase 14.

### Q2 — AnalyticsScreen trend section after `joy_trend_line_chart.dart` deletion

| Option | Description | Selected |
|--------|-------------|----------|
| Delete entire wrapper section | Screen reflows; Phase 14 Variant ε adds new structure | ✓ |
| Leave placeholder SizedBox + TODO | Backwards-compat shim, violates CLAUDE.md "no shims" | |
| Banner "section under reconstruction" | Useless if no intermediate release between Phase 13 and Phase 14 | |

**User's choice:** Delete entire wrapper section; `dailyJoyPerYen` provider also deleted.
**Notes:** Phase 14 Variant ε will introduce the new layout from scratch.

---

## Claude's Discretion

- **HappinessReport field name + numeric type.** User explicitly did not select this gray area. Recommendation: `joyContribution` field name + `MetricResult<double>` numeric type (preserve precision through model; formatter rounds at display).
- **DAO support strategy for recommendation use case.** Reuse `getSoulRowsForPtvf` × 3 month calls vs add range method — either acceptable at v1.2 volumes; planner picks per current convention.
- **Spike report file location and format.** Recommended path `.planning/phases/13-adr-016-backend-foundation/13-SPIKE.md`.
- **Test fixture strategy.** Extend Phase 9 `valueMetric<T>` / `emptyMetric<T>` helpers; reuse `demo_data_service.dart` shapes.
- **Drift DAO method rename.** `getSoulRowsForPtvf` may be renamed to `getSoulRowsForJoyContribution` for clarity; not required.
- **`build_runner` regeneration ordering and atomic commit grouping.** Planner decides per project convention.

## Deferred Ideas

### Within v1.2 (other phases)
- HomeHero ring color / monthly reset / 100% behavior → Phase 14 (JOYMIG-01/03/04/06).
- Settings UI for `monthly_joy_target` configuration → Phase 14.
- ARB key reconciliation (`homeJoyPerYen`, `homeHappinessROI`, etc.) → Phase 14 (TOOL-V2-02).
- AnalyticsScreen Variant ε layout → Phase 14.
- Golden regen for HomeHero 0/50/100/>100% states → Phase 14.
- ARB framing review for forbidden delta substrings around `monthly_joy_target` cluster → Phase 14.
- Custom time-window for recommendation calculation → Phase 15 (if needed).
- Manual-only Joy filter influence on recommendation → Phase 17 (entry_source schema).

### v1.3+ / future milestones
- Per-book `monthly_joy_target` (multi-book scenario).
- Target history persistence (user changes target over time).
- Multi-currency PTVF base extensions (EUR, GBP, KRW).
- Drift `user_settings` table — revisit IF/when 2+ additional user-finance config fields accumulate.

### Forbidden anti-features (cross-phase boundary defense)
- Delta UI on Settings target.
- Multi-month progress ring on HomeHero.
- Recommendation that updates dynamically as current month accumulates.
- Auto-adjust target based on actual achievement.

### Reviewed Todos (not folded)
None — no STATE.md pending todos matched Phase 13 scope.
