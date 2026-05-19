# Phase 13: ADR-016 Backend Foundation — Research

**Researched:** 2026-05-19
**Domain:** Flutter / Dart — Joy metric formula migration, SharedPreferences persistence, use case + formatter layer refactoring
**Confidence:** HIGH (all key source files read; no web lookups required — domain is entirely internal)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01** SharedPreferences, not Drift. `monthly_joy_target` extends `AppSettings` via `settings_repository_impl.dart`. No new Drift table. Schema version stays at 16.
- **D-02** ROADMAP SC-2 and REQUIREMENTS.md JOYMIG-02 wording corrections are Phase 13 plan task #1.
- **D-03** Null encoding: key absence = null. `prefs.getInt('monthly_joy_target')` returns null when never written. Setting value to null → `prefs.remove(key)`. No sentinel value, no two-key encoding.
- **D-04** Recommendation lives in its own use case: `GetMonthlyJoyTargetRecommendationUseCase` in `lib/application/analytics/`. Not folded into `GetHappinessReportUseCase`. Inputs: `bookId, currencyCode, asOf: DateTime`. Output: `MetricResult<int>`. Empty when <3 complete past-month soul records exist.
- **D-05** Spike: demo-data-driven simulation. Output `.planning/phases/13-adr-016-backend-foundation/13-SPIKE.md`. 3-5 scenarios.
- **D-06** Fallback baseline: anchor 50, spike may adjust within [30, 100].
- **D-07** No outlier trimming on the median. `ceil(median(Σ_M-1, Σ_M-2, Σ_M-3))`.
- **D-08** Recommendation always shown in Settings UI after user configures; reference-only framing, no delta language. Phase 14 scope for the UI itself; Phase 13 ships persistence only.
- **D-09** Phase 13 = backend + AnalyticsScreen full rip; HomeHero = field rename + formatter switch only. No ring/color/monthly-reset changes.
- **D-10** ROADMAP SC-5 grep gates: `grep -rn 'density' lib/ --include='*.dart'` must return 0 executable hits; `grep -rn 'joyPerYen\|joyDensity\|formatJoyDensity\|_computePtvfDensity' lib/ --include='*.dart' | grep -v .g.dart\|.freezed.dart` must return 0 hits.
- **D-11** ADR-013 already has `## Update 2026-05-19: Superseded by ADR-016 §2`. Phase 13 does NOT append further updates. No new ADR created.

### Claude's Discretion

- `HappinessReport` field name: use `joyContribution`. Numeric type: keep `MetricResult<double>` to preserve precision; formatter rounds at display layer.
- DAO support for recommendation: reuse 3× existing `getSoulRowsForPtvf` calls (3 month-specific round-trips). Add `getSoulRowsForPtvfRange` only if Phase 17 warrants it.
- Spike report: `.planning/phases/13-adr-016-backend-foundation/13-SPIKE.md`.
- Test fixtures: extend Phase 9 `valueMetric<T>` / `emptyMetric<T>` helpers.
- DAO rename: preferred — rename `getSoulRowsForPtvf` → `getSoulRowsForJoyContribution` for clarity; callers update accordingly.
- `build_runner` regen: run after each `@freezed` / `@riverpod` change; commit generated files atomically.

### Deferred Ideas (OUT OF SCOPE)

- HomeHero ring color state machine, monthly reset, 100% behavior → Phase 14.
- Settings UI for `monthly_joy_target` → Phase 14.
- ARB key rename (`homeJoyPerYen`, etc.) → Phase 14 (TOOL-V2-02).
- AnalyticsScreen Variant ε redesign → Phase 14.
- Golden regen for HomeHero states → Phase 14.
- `dailyJoyContribution` daily trend use case → Phase 14 decision.
- Phase 17 `entry_source` filter on use cases → Phase 17.
- Per-book target, target history, multi-currency extensions → v1.3+.

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| JOYMIG-02 | User can configure `monthly_joy_target`; system computes recommended value (past-3-months median when ≥3 months data, else spike-decided fallback) | D-01 through D-08 cover persistence + recommendation algorithm + spike. Use case contract + SharedPreferences pattern confirmed in code. |
| JOYMIG-05 | AnalyticsScreen surfaces Σ joy_contribution; density removed from all user-facing surfaces | D-09/D-10 cover removal scope. Full deletion list confirmed by grep audit below. |

</phase_requirements>

---

## Summary

Phase 13 is a backend migration + deletion phase, not a new-feature phase. The primary work is:

1. Replacing the density formula (`/ Σ amount`) with a cumulative sum formula in `GetHappinessReportUseCase`, updating the `HappinessReport` model field, and deleting the daily-density use case + model + widget + provider.
2. Adding `AppSettings.monthlyJoyTarget: int?` + SharedPreferences round-trip, then building `GetMonthlyJoyTargetRecommendationUseCase`.
3. Running a 1-day spike to decide the fallback baseline via demo-data simulation.
4. A HomeHero minimal migration: three field/method renames only, no structural change.
5. Correcting ROADMAP SC-2 + REQUIREMENTS.md wording to match the SharedPreferences decision.

The codebase is clean and consistent. All density code is in a clearly bounded set of files. The grep audit (see §6 Risks) confirms the density vocabulary is fully captured. No hidden coupling was found except one: `_SatisfactionHistogramOrFallback` in `analytics_screen.dart` uses `dailyJoyPerYenProvider` as its n<5 sample-size gate — this gate must be replaced when the provider is deleted (switch to `happinessReportProvider`'s `totalSoulTx` field or the satisfaction distribution directly).

**Primary recommendation:** Order work as spike → settings persistence → HappinessReport model rename + regen → use case rewrite → recommendation use case → density deletion (AnalyticsScreen + formatter + models + tests) → HomeHero minimal migration → ROADMAP/REQUIREMENTS wording fix → grep gate verification.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Joy formula computation (Σ joy_contribution) | Application (`lib/application/analytics/`) | — | Dart-layer fold; SQLite has no POW (ADR-013 §rationale). |
| Recommendation algorithm (median past 3 months) | Application (`lib/application/analytics/`) | — | Business logic, not persistence. Mirrors sibling use cases. |
| `monthly_joy_target` persistence | Data (`lib/data/repositories/settings_repository_impl.dart`) | — | SharedPreferences-backed via existing SettingsRepository pattern. |
| `AppSettings` domain model | Domain (`lib/features/settings/domain/models/`) | — | Freezed model, settings contract. |
| `SettingsRepository` abstract interface | Domain (`lib/features/settings/domain/repositories/`) | — | Repository interface owned by domain. |
| PTVF base table + cumulative formatter | Infrastructure (`lib/infrastructure/i18n/formatters/`) | — | Currency-aware display logic, co-located with base map. |
| `monthlyJoyTargetRecommendation` provider | Presentation (`lib/features/analytics/presentation/providers/state_happiness.dart`) | — | Riverpod provider wires use case. Lives in existing `state_happiness.dart`, NOT a new file. |
| DAO soul-row queries | Data (`lib/data/daos/analytics_dao.dart`) | — | Raw SQL, no POW. Returns row tuples for Dart-layer fold. |
| Density removal (widget/screen) | Presentation (`lib/features/analytics/presentation/`) | — | Delete JoyTrendLineChart + dailyJoyPerYen provider + _JoyTrendOrFallback section. |

---

## Standard Stack

No new external packages are required for Phase 13. All work uses existing dependencies.

| Library | Current Use | Phase 13 Role |
|---------|-------------|---------------|
| `drift` | ORM + SQLite | DAO unchanged structurally; `getSoulRowsForPtvf` renamed only. |
| `freezed_annotation` | Immutable models | `AppSettings` + `HappinessReport` modified; regen required. |
| `riverpod_annotation` | Provider generation | New `monthlyJoyTargetRecommendation` provider added to `state_happiness.dart`; regen required. |
| `shared_preferences` | Key-value storage | `SettingsRepositoryImpl` extended with `_monthlyJoyTargetKey`. |
| `mocktail` | Test mocking | Used by use case tests. |

**Installation:** No new packages. No `pubspec.yaml` changes.

## Package Legitimacy Audit

> No new packages introduced in Phase 13. Section not applicable.

---

## Current Code Map

This is the primary input the planner needs. Each key file is documented with its current state and what changes Phase 13 makes.

### Group A: Files DELETED in Phase 13

**`lib/application/analytics/get_daily_joy_per_yen_use_case.dart`** (84 lines)
- Class: `GetDailyJoyPerYenUseCase`
- Output: `MetricResult<List<DailyJoyPerYenPoint>>`
- Algorithm: per-day `_computePtvfDensity` (same density formula as `GetHappinessReportUseCase`)
- Imports `joy_density_formatter.dart` for `ptvfBaseFor`
- **Phase 13 action:** Delete entire file.

**`lib/features/analytics/domain/models/daily_joy_per_yen_point.dart`** (18 lines, + `.freezed.dart`)
- Freezed model with fields: `day: int`, `joyPerYen: double`, `sampleSize: int`
- **Phase 13 action:** Delete source + generated file.

**`lib/features/analytics/presentation/widgets/joy_trend_line_chart.dart`** (197 lines)
- Widget: `JoyTrendLineChart` (StatelessWidget)
- Consumes: `MetricResult<List<DailyJoyPerYenPoint>>`, `formatJoyDensity`, `DailyJoyPerYenPoint.joyPerYen`
- Uses `fl_chart` `LineChart` widget
- **Phase 13 action:** Delete entire file.

**`lib/infrastructure/i18n/formatters/joy_density_formatter.dart`** (36 lines)
- Exports: `ptvfBaseFor(String) → double`, `formatJoyDensity(double, String) → String`
- Contains: `_ptvfBaseByCurrency` map (JPY→500, CNY→25, USD→5), `_displayUnitByCurrency` map
- **Phase 13 action:** Delete file. Create `joy_cumulative_formatter.dart` co-located.
- The `_ptvfBaseByCurrency` map and `ptvfBaseFor` function MUST be preserved verbatim in the new file.

**Test files deleted:**
- `test/unit/application/analytics/get_daily_joy_per_yen_use_case_test.dart` (193 lines)
- `test/unit/infrastructure/i18n/formatters/joy_density_formatter_test.dart` (65 lines)

---

### Group B: Files MODIFIED in Phase 13

**`lib/application/analytics/get_happiness_report_use_case.dart`** (146 lines)
- Current: imports `joy_density_formatter.dart`, calls `_computePtvfDensity` (has `/ denominator`), returns `joyPerYen: Value(density, totalSoulTx)`.
- Current `_computePtvfDensity`: loop adds `r.soulSatisfaction * pow(r.amount/base, 0.88)` to numerator AND adds `r.amount` to denominator, returns `numerator / denominator`.
- **Phase 13 changes:**
  1. Import: replace `joy_density_formatter.dart` → `joy_cumulative_formatter.dart`
  2. Delete `_computePtvfDensity` method; add `_computeJoyContribution` (same loop body, accumulates numerator only, no denominator, returns `double` sum — no division)
  3. Change field name in `HappinessReport` constructor call: `joyPerYen:` → `joyContribution:`
  4. Empty-state return: `joyPerYen: const Empty()` → `joyContribution: const Empty()`
  5. The `_ptvfAlpha`, `_highlightsThreshold` constants and all other methods (`_computeMedianFromDistribution`, `_countHighlights`) are unchanged.
  6. DAO call: rename `getSoulRowsForPtvf` → `getSoulRowsForJoyContribution` (if DAO method is renamed per Claude's Discretion).

**`lib/features/analytics/domain/models/happiness_report.dart`** (24 lines, + `.freezed.dart`)
- Current field: `required MetricResult<double> joyPerYen`
- **Phase 13 change:** rename field to `required MetricResult<double> joyContribution`
- `@freezed` requires regen after this change.
- `copyWith` signature auto-updates via codegen.

**`lib/features/analytics/domain/repositories/analytics_repository.dart`** (82 lines)
- Current: has `getSoulRowsForPtvf`, `getDailySoulRowsForPtvf`, `getBestJoyMoment`, etc.
- **Phase 13 changes:**
  1. Rename `getSoulRowsForPtvf` → `getSoulRowsForJoyContribution` (method comment updated).
  2. Delete `getDailySoulRowsForPtvf` (no longer needed — daily density use case deleted).
  3. Add `getSoulRowsForJoyContributionRange` OR leave range queries as 3× single-month calls (Claude's Discretion: 3× calls recommended). If adding range method: signature `getSoulRowsForJoyContributionRange({required String bookId, required DateTime startDate, required DateTime endDate})` returning `List<SoulRowSample>`.
  4. No new methods for recommendation needed if reusing existing `getSoulRowsForJoyContribution` 3×.

**`lib/data/daos/analytics_dao.dart`** (lines 408-438: `getSoulRowsForPtvf`)
- Current SQL: `SELECT amount, soul_satisfaction FROM transactions WHERE book_id = ? AND $_soulExpenseFilter AND timestamp >= ? AND timestamp <= ?`
- **Phase 13 changes:**
  1. Rename method `getSoulRowsForPtvf` → `getSoulRowsForJoyContribution`. SQL is unchanged — it still returns `(amount, soul_satisfaction)` tuples.
  2. Delete `getDailySoulRowsForPtvf` method (lines 307–337).
  3. `_soulExpenseFilter` fragment stays as-is (Phase 9 D-01: no satisfaction filter).

**`lib/data/repositories/analytics_repository_impl.dart`**
- Has delegation methods that mirror the DAO. After DAO renames:
  - Rename `getSoulRowsForPtvf` → `getSoulRowsForJoyContribution`.
  - Delete `getDailySoulRowsForPtvf`.

**`lib/features/analytics/presentation/providers/state_happiness.dart`** (111 lines)
- Current: imports `daily_joy_per_yen_point.dart`, has `dailyJoyPerYen` provider (lines 45-61) that watches `getDailyJoyPerYenUseCaseProvider`.
- **Phase 13 changes:**
  1. Delete import for `daily_joy_per_yen_point.dart`.
  2. Delete `dailyJoyPerYen` provider function (entire `@riverpod` block).
  3. Add new `monthlyJoyTargetRecommendation` provider (see §Implementation Approach for signature).
  4. Update import to remove `GetDailyJoyPerYenUseCase` reference; add `GetMonthlyJoyTargetRecommendationUseCase` import.
  5. Riverpod 3 note: the generated provider name for a `@riverpod` function named `monthlyJoyTargetRecommendation` will be `monthlyJoyTargetRecommendationProvider` (no `Notifier` suffix stripping for functional providers).

**`lib/features/analytics/presentation/providers/repository_providers.dart`** (106 lines)
- Current: imports `get_daily_joy_per_yen_use_case.dart` (line 5); has `getDailyJoyPerYenUseCase` provider (lines 67-73).
- **Phase 13 changes:**
  1. Delete import for `get_daily_joy_per_yen_use_case.dart`.
  2. Delete `getDailyJoyPerYenUseCase` provider.
  3. Add import for `get_monthly_joy_target_recommendation_use_case.dart`.
  4. Add `getMonthlyJoyTargetRecommendationUseCase` provider (wires `analyticsRepositoryProvider`).

**`lib/features/analytics/presentation/screens/analytics_screen.dart`** (627 lines)
- **Phase 13 changes:**
  1. Delete import for `joy_trend_line_chart.dart` (line 21).
  2. Delete import for `daily_joy_per_yen_point.dart` (line 8 — via `state_happiness.dart` transitive? Actually it's explicitly imported: line 8).
  3. Delete `_JoyTrendOrFallback` widget class (lines 312–374) and its call site in `build()` (lines 105–113, the `_JoyTrendOrFallback(...)` + surrounding `const SizedBox(height: 8)` spacer).
  4. Delete the `dailyJoyPerYenProvider` invalidation in `_refresh()` (lines 185–192).
  5. **CRITICAL: fix `_SatisfactionHistogramOrFallback`** — it currently uses `dailyJoyPerYenProvider` as a sample-size gate (lines 423–430, 441). Replace this guard: use `happinessReportProvider`'s `totalSoulTx` field (already available via `_KpiHero` data OR re-read from provider). Suggested replacement: watch `happinessReportProvider` directly for the n<5 guard, since `totalSoulTx` is already on `HappinessReport`.
  6. Delete `_refresh` invalidations for `dailyJoyPerYenProvider` (lines 185–192 + 364 + 465 retry callbacks).

**`lib/features/settings/domain/models/app_settings.dart`** (22 lines, + `.freezed.dart` + `.g.dart`)
- Current fields: `themeMode`, `language`, `notificationsEnabled`, `biometricLockEnabled`, `voiceLanguage`.
- **Phase 13 change:** Add `@Default(null) int? monthlyJoyTarget` field.
- `@freezed` regen required (`.freezed.dart` + `.g.dart`).

**`lib/features/settings/domain/repositories/settings_repository.dart`** (12 lines)
- Current: `getSettings()`, `updateSettings(AppSettings)`, plus 5 field-specific setters.
- **Phase 13 changes:** Add `Future<void> setMonthlyJoyTarget(int? value)` method. Optionally add `Future<int?> getMonthlyJoyTarget()` (though `getSettings()` already returns it; the separate getter is convenient for the recommendation use case test harness). Recommended: add both for symmetry with `setVoiceLanguage` pattern.

**`lib/data/repositories/settings_repository_impl.dart`** (70 lines)
- Pattern to follow: `_voiceLanguageKey` constant + `setVoiceLanguage` setter.
- **Phase 13 changes:**
  1. Add `static const String _monthlyJoyTargetKey = 'monthly_joy_target';`
  2. In `getSettings()`: add `monthlyJoyTarget: _prefs.getInt(_monthlyJoyTargetKey),` (nullable — returns null if key absent).
  3. Add `setMonthlyJoyTarget(int? value)` method: if value is null → `_prefs.remove(_monthlyJoyTargetKey)`, else → `_prefs.setInt(_monthlyJoyTargetKey, value)`.
  4. `updateSettings` method: add `if (settings.monthlyJoyTarget != null) await _prefs.setInt(_monthlyJoyTargetKey, settings.monthlyJoyTarget!); else await _prefs.remove(_monthlyJoyTargetKey);`

**`lib/features/home/presentation/widgets/home_hero_card.dart`** (865 lines)
- **Phase 13 changes (minimal — only these 4 touch-points):**
  1. Line 11: `import '.../joy_density_formatter.dart'` → `import '.../joy_cumulative_formatter.dart'`
  2. Line 362: `_outerSingle(happiness.joyPerYen)` → `_outerSingle(happiness.joyContribution)`
  3. Line 478–480: `happiness.joyPerYen` → `happiness.joyContribution`; `formatJoyDensity(data, currencyCode)` → `formatJoyCumulative(data, currencyCode)`
  4. Lines 482, 818, 850: `_TooltipKey.joyPerYen` → `_TooltipKey.joyContribution` (rename the enum case and both usage sites)
- **Not touched:** `_outerSingle` implementation (`data / 2.0` shim stays), `_RingPainter`, ring gradients, center text, KPI tile copy, ARB key references.
- **Important:** `_outerSingle` currently computes `(data / 2.0).clamp(0.0, 1.0)` — this is the Phase-13-baseline shim that will be replaced by Phase 14's ring redesign. After the rename from `joyPerYen: MetricResult<double>` to `joyContribution: MetricResult<double>`, the method type signature doesn't change (`MetricResult<double>` → `MetricResult<double>`), so the shim continues to compile without any logic change.

---

### Group C: Files CREATED in Phase 13

**`lib/infrastructure/i18n/formatters/joy_cumulative_formatter.dart`** (new file)
- Replaces `joy_density_formatter.dart`.
- Must preserve: `_ptvfBaseByCurrency` map (same values), `ptvfBaseFor(String) → double` function (same logic, updated doc comment).
- New function: `formatJoyCumulative(double rawSum, String currencyCode) → String` — formats as integer with locale-appropriate thousand separator. Implementation (planner discretion within "integer + locale thousand-separator"): `NumberFormat('#,##0', 'en').format(rawSum.floor())` or equivalent. No display-unit suffix needed (cumulative count has no per-¥ denominator label).
- Note: `joy_density_formatter.dart` exported both `ptvfBaseFor` AND `formatJoyDensity`. The new file replaces both. Only `ptvfBaseFor` is semantically preserved; `formatJoyCumulative` is a new function.

**`lib/application/analytics/get_monthly_joy_target_recommendation_use_case.dart`** (new file)
- Template: mirrors `GetMonthlyReportUseCase` constructor pattern (see §Architecture Patterns below).
- Constructor: `GetMonthlyJoyTargetRecommendationUseCase({required AnalyticsRepository analyticsRepository})`.
- `execute({required String bookId, required String currencyCode, required DateTime asOf}) → Future<MetricResult<int>>`.
- Algorithm (D-04 + D-07):
  1. Compute M-1, M-2, M-3 month boundaries from `asOf` (first-of-month reset logic).
  2. For each of the 3 past complete months, call `getSoulRowsForJoyContribution(bookId, startDate, endDate)`.
  3. For each month, fold: `Σ (sat × pow(amount/base, 0.88))` using `ptvfBaseFor(currencyCode)`.
  4. Filter: only include months where `Σ joy_contribution > 0` (i.e., had soul tx). If fewer than 3 such months → return `Empty()`.
  5. Sort the 3 month-sum values; take median (index 1 of sorted list).
  6. Return `Value(ceil(median).toInt(), sampleSize: 3)`.
- The `asOf` parameter enables clock-injection for tests (CONTEXT.md D-04 pattern).
- Uses `ptvfBaseFor` from `joy_cumulative_formatter.dart`.

**`test/unit/infrastructure/i18n/formatters/joy_cumulative_formatter_test.dart`** (new test file)
- Replaces `joy_density_formatter_test.dart`.
- Covers: `ptvfBaseFor` (same cases as before); `formatJoyCumulative` (integer rounding, thousand-separator for ja/zh/en, zero case, large values).

**`test/unit/application/analytics/get_monthly_joy_target_recommendation_use_case_test.dart`** (new test file)
- Key test cases (see §Validation Architecture below).

---

### Group D: Existing test files UPDATED

**`test/unit/application/analytics/get_happiness_report_use_case_test.dart`** (451 lines)
- All references to `report.joyPerYen` → `report.joyContribution`.
- The density formula tests (group 'PTVF Joy/yen') must be rewritten to assert the cumulative-sum formula (no denominator). Example: `expected = 8 * pow(3000 / 500, 0.88)` (no `/ 3000`).
- The `valueMetric<double>(report.joyContribution)` type stays `double` (per Claude's Discretion: keep `MetricResult<double>`).
- Sample-size alignment test: update `report.joyPerYen` → `report.joyContribution`.

**`test/unit/features/analytics/domain/models/happiness_report_test.dart`** (109 lines)
- All `joyPerYen:` → `joyContribution:` in fixture constructors.
- The `const Value<double>(0.0025, 8)` fixture value for `joyContribution` should be updated to a plausible cumulative-sum value (e.g., `const Value<double>(48.37, 8)` for a representative scenario).

**`test/helpers/happiness_test_fixtures.dart`** (346 lines)
- `fixtureHappinessReportRich`, `fixtureHappinessReportThin`, `fixtureHappinessReportEmpty`:
  - Field rename: `joyPerYen:` → `joyContribution:`.
  - `fixtureHappinessReportRich`: update value from `1.2` to a plausible cumulative-sum (e.g., `78.4` for 23 soul tx at ~500 avg × sat~7).
  - `fixtureHappinessReportEmpty`: `joyContribution: const Empty()` (unchanged semantically).

**`test/widget/features/analytics/presentation/screens/analytics_screen_test.dart`**
- Remove import for `daily_joy_per_yen_point.dart` and `joy_trend_line_chart.dart`.
- Remove `dailyJoyPerYenProvider.overrideWith(...)` from `_buildSubject`.
- Remove `_dailyJoyRich` fixture references.
- Update `_SatisfactionHistogramOrFallback` tests to use `happinessReportProvider` sample-size gate.
- Any `find.byType(JoyTrendLineChart)` → assert it no longer exists.

---

## Implementation Approach

### Recommended ordering

**Step 0 (Day 1): ROADMAP + REQUIREMENTS wording fix**
Update `.planning/ROADMAP.md` SC-2 and `.planning/REQUIREMENTS.md` JOYMIG-02 wording per D-02. Pure documentation, no code risk. Do this first so the rest of the plan is written against the corrected spec.

**Step 1 (Day 1): Spike**
Before writing any production code, run the spike (D-05). Use `demo_data_service.dart` scenarios to compute `Σ joy_contribution` values. Document in `.planning/phases/13-adr-016-backend-foundation/13-SPIKE.md`. The fallback baseline number decided here anchors the `GetMonthlyJoyTargetRecommendationUseCase` constant.

**Step 2 (Day 1-2): AppSettings + SettingsRepository extension**
- Add `monthlyJoyTarget: int?` to `AppSettings.dart`.
- Add `setMonthlyJoyTarget`, `getMonthlyJoyTarget` to `SettingsRepository` interface.
- Implement in `SettingsRepositoryImpl`.
- Run `build_runner` to regenerate `AppSettings.freezed.dart` + `AppSettings.g.dart`.
- Write / update `settings_repository` unit tests for the round-trip (null → null, set → get, remove → null).

*Justification:* AppSettings and SettingsRepository are isolated from the density-removal changes. Doing them first means the recommendation use case (Step 3) has a stable persistence target to reference. It also isolates the `@freezed` regen to one file before the second `@freezed` regen for `HappinessReport`.

**Step 3 (Day 2): Create `joy_cumulative_formatter.dart` + tests**
- Create new formatter file (preserves `ptvfBaseFor`, adds `formatJoyCumulative`).
- Create `joy_cumulative_formatter_test.dart`.
- Do NOT delete `joy_density_formatter.dart` yet (HomeHeroCard still imports it).

**Step 4 (Day 2): `HappinessReport` model field rename**
- Change `joyPerYen: MetricResult<double>` → `joyContribution: MetricResult<double>`.
- Run `build_runner` to regenerate `happiness_report.freezed.dart`.
- Update `test/helpers/happiness_test_fixtures.dart` fixture field names.
- Update `test/unit/features/analytics/domain/models/happiness_report_test.dart`.
- Run `flutter test test/unit/features/analytics/domain/models/` to verify green before proceeding.

*Justification:* Model rename creates compilation errors in `GetHappinessReportUseCase` and `home_hero_card.dart`. Doing the rename first, then fixing those consumers in the next step, gives a clean compilation-error audit trail.

**Step 5 (Day 2): Rewrite `GetHappinessReportUseCase` (density → cumulative)**
- Replace import, replace `_computePtvfDensity` with `_computeJoyContribution`, update field reference.
- Rename DAO method: `getSoulRowsForPtvf` → `getSoulRowsForJoyContribution` in DAO + repository interface + repository impl.
- Update `GetHappinessReportUseCase` to call `getSoulRowsForJoyContribution`.
- Update use case test: rewrite density formula assertions to cumulative-sum assertions.
- Run `flutter test test/unit/application/analytics/get_happiness_report_use_case_test.dart`.

**Step 6 (Day 2-3): Create `GetMonthlyJoyTargetRecommendationUseCase` + tests**
- Write use case (structure per §Architecture Patterns, algorithm per D-04/D-07/spike-decided baseline).
- Add `getMonthlyJoyTargetRecommendationUseCase` provider to `repository_providers.dart`.
- Add `monthlyJoyTargetRecommendation` provider to `state_happiness.dart`.
- Write `test/unit/application/analytics/get_monthly_joy_target_recommendation_use_case_test.dart`.
- Run `build_runner` for `@riverpod` regen of `state_happiness.g.dart` and `repository_providers.g.dart`.

**Step 7 (Day 3): Delete density path — AnalyticsScreen + providers + models**
- Delete `get_daily_joy_per_yen_use_case.dart`.
- Delete `daily_joy_per_yen_point.dart` + `.freezed.dart`.
- Delete `joy_trend_line_chart.dart`.
- Remove `dailyJoyPerYen` provider from `state_happiness.dart`.
- Remove `getDailyJoyPerYenUseCase` provider from `repository_providers.dart`.
- Fix `analytics_screen.dart`:
  - Remove `_JoyTrendOrFallback` class and call site.
  - Fix `_SatisfactionHistogramOrFallback` — replace `dailyJoyPerYenProvider` gate with `happinessReportProvider` totalSoulTx check.
  - Remove `dailyJoyPerYen` invalidations from `_refresh()`.
- Delete `get_daily_joy_per_yen_use_case_test.dart`.
- Delete `joy_density_formatter_test.dart`.
- Update `analytics_screen_test.dart` (remove `dailyJoyPerYen` overrides).
- Run `build_runner` (provider regen after provider deletions).
- Delete `joy_density_formatter.dart` (final step in this group — after all consumers migrated).

**Step 8 (Day 3): HomeHero minimal migration**
- Change import, rename 4 touch-points in `home_hero_card.dart`.
- Run golden + widget tests for HomeHeroCard (will need fixture values updated).
- Run `flutter analyze`.

**Step 9 (Day 3): Full grep gate verification + CI check**
- Run both D-10 greps; expect 0 hits.
- Run `flutter test` full suite.
- Run `flutter analyze` (0 issues).

### Justification summary

The ordering is bottom-up (domain model → use case → provider → presentation → deletion) because compilation errors cascade upward. Deleting the formatter after all consumers have switched (Step 7 end) avoids intermediate compilation failures. The spike happening before any use case code is written ensures the fallback baseline constant isn't a guess.

---

## Architecture Patterns

### System Architecture Diagram

```
[AnalyticsDAO]  getSoulRowsForJoyContribution(bookId, start, end)
      |                  |
      | (amount, sat)    | (amount, sat) × 3 months
      v                  v
[GetHappinessReportUseCase]     [GetMonthlyJoyTargetRecommendationUseCase]
 Dart fold: Σ(sat × (amt/base)^0.88)   Dart fold × 3 months → median → ceil
      |                                         |
      v                                         v
[HappinessReport.joyContribution: MetricResult<double>]   [MetricResult<int>]
      |                                         |
      v                                         v
[happinessReportProvider]         [monthlyJoyTargetRecommendationProvider]
      |                                         |
      v                                         v
[HomeHeroCard _outerSingle()]     [Phase 14: Settings UI + ring target]

[AppSettings.monthlyJoyTarget: int?]  ←→  [SettingsRepositoryImpl SharedPreferences]
      |
      v
[Phase 14: Settings UI read/write]
```

### Recommended Project Structure additions

```
lib/
├── application/analytics/
│   ├── get_happiness_report_use_case.dart          (modified)
│   ├── get_monthly_joy_target_recommendation_use_case.dart  (NEW)
│   └── [get_daily_joy_per_yen_use_case.dart]       (DELETED)
├── infrastructure/i18n/formatters/
│   ├── joy_cumulative_formatter.dart               (NEW)
│   └── [joy_density_formatter.dart]                (DELETED)
├── features/analytics/domain/
│   ├── models/
│   │   ├── happiness_report.dart                   (modified: joyPerYen→joyContribution)
│   │   └── [daily_joy_per_yen_point.dart]          (DELETED)
│   └── repositories/analytics_repository.dart     (modified: method renames)
├── features/analytics/presentation/
│   ├── providers/
│   │   ├── state_happiness.dart                    (modified: del dailyJoyPerYen, add recommendation)
│   │   └── repository_providers.dart               (modified: del getDailyJoyPerYen, add recommendation)
│   ├── screens/analytics_screen.dart               (modified: del _JoyTrendOrFallback, fix histogram gate)
│   └── widgets/
│       └── [joy_trend_line_chart.dart]             (DELETED)
├── features/settings/domain/
│   ├── models/app_settings.dart                    (modified: add monthlyJoyTarget: int?)
│   └── repositories/settings_repository.dart      (modified: add setMonthlyJoyTarget)
└── data/repositories/settings_repository_impl.dart (modified: key + getter + setter)
```

### Pattern 1: New Use Case Structure (recommendation)

```dart
// Source: mirrors lib/application/analytics/get_monthly_report_use_case.dart
import 'dart:math' as math;
import '../../features/analytics/domain/models/analytics_aggregate.dart';
import '../../features/analytics/domain/models/metric_result.dart';
import '../../features/analytics/domain/repositories/analytics_repository.dart';
import '../../infrastructure/i18n/formatters/joy_cumulative_formatter.dart';

class GetMonthlyJoyTargetRecommendationUseCase {
  GetMonthlyJoyTargetRecommendationUseCase({
    required AnalyticsRepository analyticsRepository,
  }) : _repo = analyticsRepository;

  final AnalyticsRepository _repo;
  static const double _ptvfAlpha = 0.88;

  // Fallback baseline decided by spike (anchor: 50, range [30, 100])
  static const int _fallbackBaseline = 50; // SPIKE-DECIDED

  Future<MetricResult<int>> execute({
    required String bookId,
    required String currencyCode,
    required DateTime asOf, // clock injection for tests
  }) async {
    final base = ptvfBaseFor(currencyCode);
    final monthSums = <double>[];

    for (int offset = 1; offset <= 3; offset++) {
      final monthStart = DateTime(asOf.year, asOf.month - offset, 1);
      final monthEnd = DateTime(asOf.year, asOf.month - offset + 1, 0, 23, 59, 59);
      final rows = await _repo.getSoulRowsForJoyContribution(
        bookId: bookId,
        startDate: monthStart,
        endDate: monthEnd,
      );
      final sum = _foldContribution(rows, base);
      if (sum > 0) monthSums.add(sum);
    }

    if (monthSums.length < 3) {
      return const Empty();
    }

    monthSums.sort();
    final median = monthSums[1]; // middle of 3 sorted values
    return Value(median.ceil(), 3);
  }

  double _foldContribution(List<SoulRowSample> rows, double base) {
    var sum = 0.0;
    for (final r in rows) {
      sum += r.soulSatisfaction * math.pow(r.amount / base, _ptvfAlpha);
    }
    return sum;
  }
}
```

### Pattern 2: Joy Cumulative Formatter

```dart
// Source: replaces joy_density_formatter.dart
// Key: ptvfBaseFor preserved verbatim; formatJoyCumulative is new.
const Map<String, double> _ptvfBaseByCurrency = {
  'JPY': 500.0,
  'CNY': 25.0,
  'USD': 5.0,
};

double ptvfBaseFor(String currencyCode) =>
    _ptvfBaseByCurrency[currencyCode] ?? 500.0;

/// Formats a Σ joy_contribution cumulative sum as an integer with
/// locale-appropriate thousand separators (e.g., "1,234" for en; "1,234" for ja/zh).
String formatJoyCumulative(double rawSum, String currencyCode) {
  // Display as integer; no per-¥ suffix needed (cumulative, not a ratio).
  final intValue = rawSum.floor();
  // NumberFormat locale-aware thousand separator.
  // Planner decides exact format; integer + comma separator is the contract.
  return intValue.toString(); // placeholder — planner finalizes with NumberFormat
}
```

### Pattern 3: Riverpod 3 provider for recommendation

```dart
// In state_happiness.dart
// Riverpod 3: function name monthlyJoyTargetRecommendation
// generates monthlyJoyTargetRecommendationProvider (no Notifier suffix stripped)
@riverpod
Future<MetricResult<int>> monthlyJoyTargetRecommendation(
  Ref ref, {
  required String bookId,
  required String currencyCode,
}) async {
  final useCase = ref.watch(getMonthlyJoyTargetRecommendationUseCaseProvider);
  return useCase.execute(
    bookId: bookId,
    currencyCode: currencyCode,
    asOf: DateTime.now(), // Phase 14 may want clock injection at call site
  );
}
```

### Pattern 4: SharedPreferences null-encoding

```dart
// In settings_repository_impl.dart (follows voiceLanguage pattern)
static const String _monthlyJoyTargetKey = 'monthly_joy_target';

// In getSettings():
monthlyJoyTarget: _prefs.getInt(_monthlyJoyTargetKey),

// New setter:
@override
Future<void> setMonthlyJoyTarget(int? value) async {
  if (value == null) {
    await _prefs.remove(_monthlyJoyTargetKey);
  } else {
    await _prefs.setInt(_monthlyJoyTargetKey, value);
  }
}
```

### Anti-Patterns to Avoid

- **Folding recommendation into `GetHappinessReportUseCase`** — scope mismatch (current-month vs past-3-month). Rejected by D-04.
- **Storing `monthly_joy_target = 0` as null sentinel** — D-03 rejection. Key absence IS null.
- **Deleting `ptvfBaseFor` from the codebase** — it must survive in `joy_cumulative_formatter.dart`; the recommendation use case depends on it.
- **Leaving `_SatisfactionHistogramOrFallback` watching `dailyJoyPerYenProvider`** — will cause a compile error after the provider is deleted. Must replace gate with `happinessReportProvider`'s `totalSoulTx`.
- **Renaming ARB keys** — out of scope for Phase 13 (D-09 + TOOL-V2-02 is Phase 14). The Dart-side field renames happen; ARB key strings (`homeJoyPerYen`, `homeJoyPerYenTooltip`) keep their old values.
- **Adding a Drift `user_settings` table** — D-01 rejection.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Median of 3 values | Custom median algorithm | Sort-and-index on a 3-element list | With exactly 3 elements, `sorted[1]` is always the median. No general algorithm needed. |
| SharedPreferences null-int round-trip | Custom serialization | `prefs.getInt(key)` (returns null if absent) + `prefs.remove(key)` for null | SharedPreferences already handles int? semantics natively. |
| Locale thousand-separator | Custom string formatting | `NumberFormat('#,##0', locale)` from `intl` package (already in project, pinned at 0.20.2) | Standard Dart i18n; handles ja/zh/en correctly. |
| PTVF α=0.88 formula | Re-derive α | Copy verbatim from `GetHappinessReportUseCase._ptvfAlpha` | The value is an empirical constant from K-T 1979; do not invent a different value. |

**Key insight:** Phase 13 is almost entirely deletion + rename work. The one genuinely new algorithm (the recommendation use case) is structurally identical to `GetHappinessReportUseCase`'s fold, minus the denominator and applied across 3 months. The median is trivial for exactly 3 data points. The risk here is not algorithmic complexity — it is compilation correctness after renaming a widely-referenced field.

---

## Test Strategy

### Files to delete

| File | Reason |
|------|--------|
| `test/unit/application/analytics/get_daily_joy_per_yen_use_case_test.dart` (193 lines) | Entire use case deleted. |
| `test/unit/infrastructure/i18n/formatters/joy_density_formatter_test.dart` (65 lines) | Entire formatter deleted. |

### Files to create

| File | Coverage target |
|------|----------------|
| `test/unit/application/analytics/get_monthly_joy_target_recommendation_use_case_test.dart` | ≥70% of new use case lines |
| `test/unit/infrastructure/i18n/formatters/joy_cumulative_formatter_test.dart` | ≥70% of new formatter lines |

### Files to update

| File | What changes |
|------|--------------|
| `test/unit/application/analytics/get_happiness_report_use_case_test.dart` | Rename `joyPerYen` → `joyContribution`; rewrite density formula assertions to cumulative-sum assertions. |
| `test/unit/features/analytics/domain/models/happiness_report_test.dart` | Rename `joyPerYen:` → `joyContribution:` in all constructor calls. |
| `test/helpers/happiness_test_fixtures.dart` | Rename `joyPerYen:` → `joyContribution:` in all 3 `fixtureHappinessReport*` factories; update value to plausible cumulative-sum. |
| `test/widget/features/analytics/presentation/screens/analytics_screen_test.dart` | Remove `dailyJoyPerYen` provider overrides; remove `JoyTrendLineChart` import; update histogram n<5 test if needed. |

### valueMetric / emptyMetric reuse

The `valueMetric<T>` and `emptyMetric<T>` helpers are defined inline in `get_happiness_report_use_case_test.dart` (lines 62–69), not in `test/helpers/`. The new recommendation use case test should either:
- Duplicate the 8-line helpers inline (simple, consistent with existing pattern), OR
- Extract them to `test/helpers/` if the project intends to centralize them (not required by Phase 13).

Recommendation: inline duplication — consistent with Phase 9 pattern.

### Fixture strategy for recommendation use case

The recommendation test must cover:

| Test case | Scenario | Expected output |
|-----------|----------|-----------------|
| 3 months all non-zero | M-1=40, M-2=60, M-3=50 | `Value(50, 3)` (median=50, ceil=50) |
| 3 months with fractional median | M-1=40, M-2=61, M-3=50 | `Value(51, 3)` (median=50.x → but actually median of 40,50,61 = 50.0... recalc: `Value(50, 3)` — planner verifies) |
| Only 2 months have data | M-1=0 (empty), M-2=40, M-3=60 | `Empty()` (<3 months) |
| 0 months have data | All 3 empty | `Empty()` |
| Non-JPY currency | CNY data | Different base (25) changes the sum — verify base plumbing |
| asOf clock injection | asOf=DateTime(2026, 3, 15) | M-1=Feb, M-2=Jan, M-3=Dec 2025 — verify month boundary math |

### DAO daily-joy test file

`test/unit/data/daos/analytics_dao_daily_joy_test.dart` — this file tests `getDailySoulRowsForPtvf`. After deleting that DAO method, this file must also be deleted (or converted to test the renamed `getSoulRowsForJoyContribution` if desired). Recommended: delete the daily-specific test file; the `analytics_dao_happiness_test.dart` covers the remaining PTVF-row query.

---

## Validation Architecture (Nyquist)

### Test Framework

| Property | Value |
|----------|-------|
| Framework | `flutter_test` + `mocktail` (existing) |
| Config file | `pubspec.yaml` dev_dependencies |
| Quick run command | `flutter test test/unit/application/analytics/get_monthly_joy_target_recommendation_use_case_test.dart -x` |
| Full suite command | `flutter test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| JOYMIG-02 | `Σ joy_contribution` formula correct (no `/Σamount`) | unit | `flutter test test/unit/application/analytics/get_happiness_report_use_case_test.dart -x` | Yes (update) |
| JOYMIG-02 | Recommendation: 3-month median ceil | unit | `flutter test test/unit/application/analytics/get_monthly_joy_target_recommendation_use_case_test.dart -x` | No — Wave 0 |
| JOYMIG-02 | Recommendation: <3-months → Empty | unit | (same test file) | No — Wave 0 |
| JOYMIG-02 | SharedPreferences round-trip (null/set/remove) | unit | `flutter test test/unit/data/repositories/settings_repository_test.dart -x` | Verify exists |
| JOYMIG-05 | No density code path in lib/ | grep gate | `grep -rn 'joyPerYen\|formatJoyDensity\|_computePtvfDensity' lib/ --include='*.dart' \| grep -v .g.dart\|.freezed.dart` | N/A (script) |
| JOYMIG-05 | `formatJoyCumulative` produces integer + separator | unit | `flutter test test/unit/infrastructure/i18n/formatters/joy_cumulative_formatter_test.dart -x` | No — Wave 0 |
| JOYMIG-05 | `ptvfBaseFor` preserved in new formatter | unit | (same test file) | No — Wave 0 |

### Sampling Strategy for recommendation use case

**Edge cases requiring explicit test coverage:**

1. **2-month scenario:** One of the 3 past months has 0 soul transactions (the DAO returns empty list for that month). Sum for that month is 0. Filter: only count months with `sum > 0`. Result: 2 qualified months → `Empty()`.

2. **0-month scenario:** All 3 past months have 0 soul transactions. `monthSums.length < 3` → `Empty()`.

3. **All-zero-satisfaction scenario:** Soul transactions exist but all have `soul_satisfaction = 0` (shouldn't happen per schema CHECK 1..10, but defensive test). Result: `sum = 0` → treated as empty month.

4. **Null-month gaps (e.g., asOf = March, M-1 = Feb, M-2 = Jan, M-3 = Dec):** Month arithmetic must handle year boundary (Dec 2025). Verify `DateTime(2026, 1 - 1, 1)` = `DateTime(2026, 0, 1)` → Dart normalizes to `DateTime(2025, 12, 1)`. This is correct Dart behavior; no special-casing needed. Test with `asOf = DateTime(2026, 2, 15)` → M-1=Jan, M-2=Dec, M-3=Nov; and `asOf = DateTime(2026, 1, 10)` → M-1=Dec, M-2=Nov, M-3=Oct.

5. **Currency variation:** CNY base (25) vs JPY base (500) produces a 20× larger contribution sum for the same `amount × sat` input (at `amount = base`, contribution = `sat × 1^0.88 = sat` for both, so only amounts NOT equal to base differ). Include a CNY fixture to verify `ptvfBaseFor` flows through.

6. **Ceil boundary:** Median exactly `50.0` → `Value(50, 3)`. Median `50.1` → `Value(51, 3)`. Cover both via numeric fixtures.

### Sampling rate

- **Per task commit:** `flutter test test/unit/application/analytics/ -x`
- **Per wave merge:** `flutter test` (full suite)
- **Phase gate:** Full suite green + grep gates green before `/gsd:verify-work`

### Wave 0 gaps (must exist before implementation)

- [ ] `test/unit/application/analytics/get_monthly_joy_target_recommendation_use_case_test.dart` — covers REQ JOYMIG-02 recommendation algorithm
- [ ] `test/unit/infrastructure/i18n/formatters/joy_cumulative_formatter_test.dart` — covers REQ JOYMIG-05 formatter
- [ ] Settings repository test update for `monthlyJoyTarget` round-trip

---

## Risks and Unknowns

### Risk 1: `_SatisfactionHistogramOrFallback` uses `dailyJoyPerYenProvider` as gate (HIGH priority)

**Finding:** `analytics_screen.dart` `_SatisfactionHistogramOrFallback` (lines 423–430) watches `dailyJoyPerYenProvider` to get a sample-size count for the n<5 gate. After deleting `dailyJoyPerYenProvider`, this class will not compile.

**Resolution:** Replace the gate with `happinessReportProvider`'s `totalSoulTx` field (integer, always populated when the report exists). Since `_KpiHero` already watches `happinessReportProvider` at the screen level, the planner can either (a) hoist `happinessReportProvider` as a screen-level watch and pass `totalSoulTx` down, or (b) have `_SatisfactionHistogramOrFallback` watch `happinessReportProvider` independently. Option (b) is simpler and consistent with each card owning its data.

### Risk 2: `analytics_screen.dart` refresh() still invalidates `dailyJoyPerYenProvider` (MEDIUM)

**Finding:** `_refresh()` method (line 185) calls `ref.invalidate(dailyJoyPerYenProvider(...))`. Two more `dailyJoyPerYenProvider` calls appear at lines 364 and 465 as retry-error callbacks.

**Resolution:** Remove all 5 `dailyJoyPerYenProvider` references from `analytics_screen.dart` in Step 7.

### Risk 3: `analytics_screen_test.dart` imports `JoyTrendLineChart` and `DailyJoyPerYenPoint` (MEDIUM)

**Finding:** The widget test file (lines 8, 24) imports both deleted symbols. These will cause compilation errors when the source files are deleted.

**Resolution:** Remove both imports and the `_dailyJoyRich` fixture + `dailyJoyPerYenProvider.overrideWith(...)` from the test subject builder.

### Risk 4: `home_hero_card.dart` `_outerSingle` type compatibility (LOW)

**Finding:** `_outerSingle` currently takes `MetricResult<double>` (for `joyPerYen`) and returns `(data / 2.0).clamp(0.0, 1.0)`. After renaming `joyPerYen` → `joyContribution`, the field type remains `MetricResult<double>` (per Claude's Discretion). The method signature is unchanged. The `/ 2.0` divisor will produce nonsensical fill ratios for Σ joy_contribution values (which are in the range ~30-200, not 0-2), but this is the accepted Phase-13-baseline shim state — Phase 14 replaces the ring math.

**Resolution:** No change needed to `_outerSingle` logic. The Phase 13 HomeHero will have a technically incorrect ring fill ratio, which is the accepted cost of the split between Phase 13 (backend) and Phase 14 (frontend redesign). Document in plan as "intentional shim."

### Risk 5: ARB generated files reference `homeJoyPerYenTooltip` (LOW)

**Finding:** `lib/generated/app_localizations.dart` (line 1104) and `app_localizations_en.dart` (line 542) contain the string "Joy density" in generated files. These are generated from ARB files; Phase 13 does NOT rename ARB keys (D-09, TOOL-V2-02 is Phase 14). The generated files will still reference `l10n.homeJoyPerYenTooltip` which is used in `home_hero_card.dart` line 850.

**Resolution:** `home_hero_card.dart` still calls `l10n.homeJoyPerYenTooltip` on line 850 after the `_TooltipKey.joyPerYen` → `_TooltipKey.joyContribution` enum rename. The enum rename means the case `_TooltipKey.joyContribution` maps to the tooltip ARB key `homeJoyPerYenTooltip` (old key, not renamed). This is correct per D-09: ARB keys keep old names in Phase 13. The `_showTooltipDialog` body must update: `_TooltipKey.joyContribution => l10n.homeJoyPerYenTooltip` (ARB key unchanged, but enum case is renamed).

### Risk 6: `getDailySoulRowsForPtvf` in `AnalyticsRepository` + DAO (MEDIUM)

**Finding:** `getDailySoulRowsForPtvf` exists in the abstract interface (`analytics_repository.dart` line 56), the DAO (`analytics_dao.dart` lines 307–337), and `analytics_repository_impl.dart`. Deleting the daily use case requires deleting this DAO method and the interface method.

**Resolution:** Explicitly included in Step 7 deletion list. Verify `analytics_repository_impl.dart` and any test files referencing `getDailySoulRowsForPtvf`.

### Risk 7: `test/unit/data/daos/analytics_dao_daily_joy_test.dart` tests deleted method (MEDIUM)

**Finding:** This test file tests `getDailySoulRowsForPtvf`. After deleting the DAO method, this file will fail to compile.

**Resolution:** Delete `analytics_dao_daily_joy_test.dart` in Step 7.

### Confirmed: schemaVersion stays at 16

`lib/data/app_database.dart` line 45: `int get schemaVersion => 16;` — confirmed. Phase 13 does NOT touch this file.

### Confirmed: `app_initializer.dart` needs no changes

`lib/core/initialization/app_initializer.dart` wires `KeyManager → Database`. `GetMonthlyJoyTargetRecommendationUseCase` has no init-time dependency (injected lazily via Riverpod provider); `AppSettings` is already initialized via `SharedPreferences` (loaded at init time). No changes to `AppInitializer`.

### Confirmed: current density grep audit

Running `grep -rn 'joyPerYen\|joyDensity\|formatJoyDensity\|_computePtvfDensity' lib/ --include='*.dart' | grep -v .g.dart\|.freezed.dart` returns exactly these hits (all in Phase 13 deletion/rename scope):

| File | References |
|------|-----------|
| `home_hero_card.dart` | lines 362, 478, 480, 482, 818, 850 — field/enum/formatter refs |
| `state_happiness.dart` | lines 47 — `dailyJoyPerYen` provider |
| `joy_trend_line_chart.dart` | lines 43, 104, 118, 137, 191 — field + formatter |
| `analytics_screen.dart` | lines 186, 332, 364, 424, 465 — provider refs |
| `daily_joy_per_yen_point.dart` | line 13 — field definition |
| `happiness_report.dart` | line 19 — field definition |
| `get_happiness_report_use_case.dart` | lines 74, 82, 92, 100 — field + method |
| `get_daily_joy_per_yen_use_case.dart` | lines 60, 71 — field + method |
| `joy_density_formatter.dart` | line 30 — function |
| `repository_providers.dart` | lines 67, 69, 70 — provider |

No surprise references found outside the expected set. The `density` grep additionally finds two references in `lib/generated/` (generated files — not in scope) and the `get_happiness_report_use_case.dart` `local density variable` reference. Generated files are excluded from the D-10 grep gate.

---

## Dependencies and Hand-offs

### Phase 13 → Phase 14 contract surface

Phase 14 consumes exactly these symbols from Phase 13:

| Symbol | Location | Type | Phase 14 use |
|--------|----------|------|--------------|
| `HappinessReport.joyContribution` | `lib/features/analytics/domain/models/happiness_report.dart` | `MetricResult<double>` | HomeHero ring fill value + central numeric display |
| `AppSettings.monthlyJoyTarget` | `lib/features/settings/domain/models/app_settings.dart` | `int?` | Settings UI read/write |
| `monthlyJoyTargetRecommendationProvider` | `lib/features/analytics/presentation/providers/state_happiness.dart` | `AsyncValue<MetricResult<int>>` | Settings UI "recommended" display; ring active-target compute |
| `formatJoyCumulative` | `lib/infrastructure/i18n/formatters/joy_cumulative_formatter.dart` | `String Function(double, String)` | HomeHero central numeric display; Analytics KPI tile |
| `setMonthlyJoyTarget` | `lib/features/settings/domain/repositories/settings_repository.dart` | `Future<void> Function(int?)` | Settings UI write path |
| `ptvfBaseFor` | `lib/infrastructure/i18n/formatters/joy_cumulative_formatter.dart` | `double Function(String)` | Phase 14 use cases may need it for additional formula work |

### Phase 13 → Phase 17 hook

The recommendation use case `GetMonthlyJoyTargetRecommendationUseCase.execute()` currently has no `entrySourceFilter` parameter. Phase 17 (schema adds `entry_source`) MAY want an optional parameter to filter manual-only. Phase 13 MUST NOT add this parameter preemptively. Document in code comments: `// Phase 17: may add entrySourceFilter: EntrySource? parameter`.

Similarly, `GetHappinessReportUseCase.execute()` will need the same hook in Phase 17. No action needed in Phase 13.

### Phase 13 → Phase 15 hook

Phase 15 (custom time windows) will want `GetHappinessReportUseCase` and the recommendation use case to accept arbitrary `(startDate, endDate)` pairs (or `year/month` parameters become optional). Phase 13 must NOT generalize the signatures preemptively. The current `year: int, month: int` parameters in `GetHappinessReportUseCase.execute()` are kept unchanged.

---

## Build / CI Considerations

### build_runner regen checkpoints

The following changes require `flutter pub run build_runner build --delete-conflicting-outputs` before the next compile:

| Change | Triggers regen of |
|--------|-------------------|
| Add `monthlyJoyTarget: int?` to `AppSettings` | `app_settings.freezed.dart` + `app_settings.g.dart` |
| Rename `joyPerYen` → `joyContribution` in `HappinessReport` | `happiness_report.freezed.dart` |
| Delete `daily_joy_per_yen_point.dart` | `daily_joy_per_yen_point.freezed.dart` (delete generated file too) |
| Add `monthlyJoyTargetRecommendation` provider to `state_happiness.dart` | `state_happiness.g.dart` |
| Delete `dailyJoyPerYen` provider from `state_happiness.dart` | `state_happiness.g.dart` |
| Delete/add providers in `repository_providers.dart` | `repository_providers.g.dart` |

**Ordering:** Run `build_runner` after each `@freezed` change (model files) and after provider file changes, before running tests. Commit generated files atomically with the source changes.

### AUDIT-10 CI guardrail

AUDIT-10 (`flutter pub run build_runner build --delete-conflicting-outputs` clean-diff check) will flag stale generated files. Ensure generated files are committed in the same commit as the source change that triggers them. Specifically:
- When deleting `daily_joy_per_yen_point.dart`, also delete `daily_joy_per_yen_point.freezed.dart`.
- When modifying `happiness_report.dart`, commit the updated `happiness_report.freezed.dart` in the same PR.

### import_guard guardrail

The project has `import_guard` CI enforcing the Thin Feature rule. Verify:
- `GetMonthlyJoyTargetRecommendationUseCase` lives at `lib/application/analytics/` (correct — application layer).
- `joy_cumulative_formatter.dart` lives at `lib/infrastructure/i18n/formatters/` (correct — infrastructure layer).
- No domain model imports from the data layer (unchanged).

### Test coverage gate

Per REQUIREMENTS.md §Cross-Phase Constraints §5: per-file coverage ≥70% on changed files. Hot spots:
- `get_happiness_report_use_case_test.dart`: existing tests cover formula well; updating density→cumulative assertions maintains coverage.
- `get_monthly_joy_target_recommendation_use_case.dart`: new file, needs dedicated test with multiple edge cases.
- `settings_repository_impl.dart`: needs `monthlyJoyTarget` round-trip test added.
- `joy_cumulative_formatter.dart`: new file, needs formatter + base tests.

### flutter analyze

Zero issues required before commit. Renaming a `@freezed` field without regenerating generates analyzer warnings. Always regen before running analyze.

---

## Security Domain

The `monthly_joy_target` field is a personal preference integer (no spend data, no PII). SharedPreferences storage is unencrypted on-device, which is acceptable per D-01 reasoning (it leaks no spend pattern, not a soul transaction). No ASVS categories are newly implicated by Phase 13 changes.

| ASVS Category | Applies | Notes |
|---------------|---------|-------|
| V2 Authentication | No | No auth changes |
| V5 Input Validation | Low | `monthly_joy_target` is written by Phase 14 Settings UI — Phase 14 must validate range. Phase 13 only adds the persistence layer; the `int?` type provides type safety at the Dart level. |
| V6 Cryptography | No | SharedPreferences is fine for this preference integer. |

---

## Open Questions (RESOLVED)

1. **`formatJoyCumulative` exact locale format** — RESOLVED: use `intl.NumberFormat.decimalPattern('en')` as a safe default that produces comma-separated integers. Phase 14 can make it locale-aware if needed. See UI-SPEC §4 and PATTERNS.md §`joy_cumulative_formatter.dart`; implemented in plan 13-02.
   - What we know: must be integer + thousand-separator.
   - What's unclear: Should it be `intl.NumberFormat('#,##0', 'en')` (always comma), or locale-aware (ja: `1,234`, zh: `1,234`, en: `1,234` — they're all the same for these locales)?

2. **`_SatisfactionHistogramOrFallback` gate replacement** — RESOLVED: watch `happinessReportProvider` directly inside `_SatisfactionHistogramOrFallback` — consistent with other private card widgets that own their data. The provider is already cached by Riverpod from `_KpiHero`'s watch. See PATTERNS.md §`analytics_screen.dart` histogram-gate replacement; implemented in plan 13-07 task 2.
   - What we know: it needs a soul-transaction count to drive the n<5 guard.
   - What's unclear: whether to watch `happinessReportProvider` in `_SatisfactionHistogramOrFallback` (adds a second provider watch) or to receive `totalSoulTx` as a constructor parameter from the parent.

3. **Spike outcome uncertainty** — RESOLVED: keep `_fallbackBaseline` as a private const in the recommendation use case body (not extracted to the formatter). Rationale: the constant is a domain-layer policy of the recommendation use case, not a presentation concern; co-locating it keeps the use case self-contained and matches the existing sibling use case pattern. Phase 14 can re-tune by editing one line at a stable site. Implemented in plan 13-06 task 2; spike (plan 13-05) records the chosen integer in `13-SPIKE.md` for traceability.
   - What we know: baseline anchor is 50; spike decides within [30, 100].
   - What's unclear: whether real demo-data scenarios might push the anchor outside the intuitive range.

---

## Environment Availability

> Phase 13 is code-only (Flutter/Dart). No external services, databases, or CLI tools beyond the existing Flutter toolchain are required. Standard Flutter development environment confirmed from project context.

| Dependency | Required By | Available | Notes |
|------------|------------|-----------|-------|
| Flutter SDK | build + test | Assumed available (existing project) | — |
| `shared_preferences` | persistence | Yes (already in pubspec) | — |
| `intl 0.20.2` | `formatJoyCumulative` | Yes (pinned) | Use `NumberFormat` from existing dep. |
| `drift` | DAO renames | Yes (existing) | No schema change. |
| `build_runner` | code generation | Yes (existing) | Required after model/provider changes. |

---

## Project Constraints (from CLAUDE.md)

- **Thin Feature rule:** New use case at `lib/application/analytics/` (not inside features). New formatter at `lib/infrastructure/i18n/formatters/`. Confirmed correct placement.
- **Riverpod 3 conventions:** `@riverpod` on `monthlyJoyTargetRecommendation` generates `monthlyJoyTargetRecommendationProvider`. `AsyncValue<T>.value` (nullable, not `.valueOrNull`). Errors wrapped in `ProviderException`. Use `ProviderContainer.test()` in provider tests. Use `waitForFirstValue<T>` helper for async provider tests.
- **Single `repository_providers.dart` per feature:** Confirmed — the canonical file is `lib/features/analytics/presentation/providers/repository_providers.dart`. New use case provider goes there.
- **`intl 0.20.2` pin:** Do not upgrade. Use the already-pinned version.
- **`build_runner` regen:** Required after `@freezed` (AppSettings + HappinessReport) and `@riverpod` (state_happiness, repository_providers) changes.
- **AUDIT-10:** Commit generated files atomically with source changes.
- **Zero analyzer warnings:** Run `flutter analyze` before committing.
- **Don't modify generated files (.g.dart, .freezed.dart):** Only regenerate.
- **Worklog:** Phase 13 close requires `doc/worklog/YYYYMMDD_HHMM_*.md` entry.
- **ADR append-only after ✅ 已接受:** Phase 13 does NOT append to ADR-013 (already has the supersede update from 2026-05-19). No new ADR created.

---

## Sources

### Primary (HIGH confidence — all from direct source file inspection)

- `lib/application/analytics/get_happiness_report_use_case.dart` — density formula, field names, DAO call signatures
- `lib/application/analytics/get_daily_joy_per_yen_use_case.dart` — full file reviewed; confirms deletion scope
- `lib/features/analytics/domain/models/happiness_report.dart` — `joyPerYen: MetricResult<double>` confirmed
- `lib/features/analytics/domain/models/metric_result.dart` — `MetricResult<T>` sealed type contract
- `lib/features/analytics/presentation/providers/state_happiness.dart` — `dailyJoyPerYen` provider confirmed
- `lib/features/analytics/presentation/providers/repository_providers.dart` — `getDailyJoyPerYenUseCase` provider confirmed
- `lib/features/analytics/presentation/screens/analytics_screen.dart` — `_JoyTrendOrFallback` section + `_SatisfactionHistogramOrFallback` gate coupling discovered
- `lib/infrastructure/i18n/formatters/joy_density_formatter.dart` — `ptvfBaseFor` + `formatJoyDensity` confirmed
- `lib/data/daos/analytics_dao.dart` lines 307–438 — DAO methods confirmed
- `lib/data/repositories/settings_repository_impl.dart` — SharedPreferences pattern confirmed
- `lib/features/settings/domain/models/app_settings.dart` — existing fields confirmed
- `lib/features/settings/domain/repositories/settings_repository.dart` — interface confirmed
- `lib/data/app_database.dart` — `schemaVersion = 16` confirmed
- `test/unit/application/analytics/get_happiness_report_use_case_test.dart` — `valueMetric<T>` / `emptyMetric<T>` helpers confirmed inline
- `test/helpers/happiness_test_fixtures.dart` — `joyPerYen` field in fixtures confirmed
- `test/widget/features/analytics/presentation/screens/analytics_screen_test.dart` — `dailyJoyPerYenProvider.overrideWith` confirmed
- `docs/arch/03-adr/ADR-016_Joy_Metric_Visualization_Redesign.md` — formula + scope decisions
- `docs/arch/03-adr/ADR-013_Joy_Density_PTVF_Scaling.md` — PTVF α=0.88 + base table
- `.planning/phases/13-adr-016-backend-foundation/13-CONTEXT.md` — all locked decisions

### Secondary

- `.planning/ROADMAP.md` — SC-2 wording requiring fixup confirmed (still reads "Schema migration adds user_settings.monthly_joy_target")
- `.planning/REQUIREMENTS.md` — JOYMIG-02 / JOYMIG-05 traceability confirmed

---

## Metadata

**Confidence breakdown:**
- Current code map: HIGH — all key files read directly; grep audit run
- Formula migration scope: HIGH — density grep returns full picture; no hidden references
- Recommendation use case design: HIGH — locked decisions in CONTEXT.md + mirrors existing use case pattern
- Test strategy: HIGH — test infrastructure understood; Phase 9 helpers confirmed
- Spike baseline: MEDIUM — anchor is 50; actual number is spike-decided (not researchable without running the simulation)

**Research date:** 2026-05-19
**Valid until:** 2026-06-19 (30 days; codebase is stable; formula math is fixed)

---

## RESEARCH COMPLETE
