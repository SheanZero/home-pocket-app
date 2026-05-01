---
phase: 9
slug: happiness-domain-formula-layer
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-01
---

# Phase 9 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test (Dart 3.5+, Flutter 3.24+) |
| **Config file** | `analysis_options.yaml`, `pubspec.yaml` (test dependencies) |
| **Quick run command** | `flutter test test/unit/application/analytics/ test/unit/data/daos/analytics_dao_happiness_test.dart` |
| **Full suite command** | `flutter test --coverage` |
| **Estimated runtime** | ~30s quick, ~120s full |

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/unit/application/analytics/<touched_file>_test.dart` (single file, ~3-5s)
- **After every plan wave:** Run quick command above (~30s)
- **Before `/gsd-verify-work`:** Full suite must be green with `flutter analyze` reporting 0 issues
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

> Filled by the planner. Each plan task with `type: tdd` or `type: execute` MUST appear here with an automated command. The plan-checker will refuse plans whose tasks are not represented.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 09-01-01 | 01-schema-migration | 1 | D-02, D-10 | T-9-01 (default-cluster contamination) | `transactions.soul_satisfaction` defaults to 2; CHECK constraint `BETWEEN 1 AND 10` survives | unit (drift) | `flutter test test/unit/data/migrations/migration_v15_to_v16_test.dart` | ❌ W0 | ⬜ pending |
| 09-02-01 | 02-domain-models | 1 | D-13, D-14, D-15 | — | `MetricResult<T>` has Empty + Value variants only; sealed; pattern matching works | unit | `flutter test test/unit/features/analytics/domain/models/metric_result_test.dart` | ❌ W0 | ⬜ pending |
| 09-02-02 | 02-domain-models | 1 | D-15 | — | `HappinessReport` and `FamilyHappiness` Freezed aggregates compile and accept `MetricResult<...>` field types | unit | `flutter test test/unit/features/analytics/domain/models/happiness_report_test.dart` | ❌ W0 | ⬜ pending |
| 09-03-01 | 03-dao | 2 | D-01, HAPPY-01..03 | T-9-02 (survival contamination) | `_soulOnly()` const present; every soul query consumes it; survival rows excluded | unit (drift) | `flutter test test/unit/data/daos/analytics_dao_happiness_test.dart -n "_soulOnly"` | ❌ W0 | ⬜ pending |
| 09-03-02 | 03-dao | 2 | D-04 | — | Row-wise `(amount, soul_satisfaction)` query returns expected tuples | unit (drift) | `flutter test test/unit/data/daos/analytics_dao_happiness_test.dart -n "row-wise"` | ❌ W0 | ⬜ pending |
| 09-03-03 | 03-dao | 2 | D-06, HAPPY-04 | T-9-03 (¥10 candy domination) | `getBestJoyMoment` orders by `soul_satisfaction DESC, amount DESC, timestamp DESC LIMIT 1`; argmax test pins ordering | unit (drift) | `flutter test test/unit/data/daos/analytics_dao_happiness_test.dart -n "best joy"` | ❌ W0 | ⬜ pending |
| 09-04-01 | 04-repository | 2 | — | — | `AnalyticsRepository` interface extended with 4 new methods; impl delegates correctly | unit | `flutter test test/unit/data/repositories/analytics_repository_happiness_test.dart` | ❌ W0 | ⬜ pending |
| 09-05-01 | 05-use-case-personal | 3 | HAPPY-01, HAPPY-02, HAPPY-03, HAPPY-04 | T-9-02 | `GetHappinessReportUseCase.execute()` returns `HappinessReport` with `MetricResult` fields populated correctly for n=0/1/2 fixtures | unit | `flutter test test/unit/application/analytics/get_happiness_report_use_case_test.dart` | ❌ W0 | ⬜ pending |
| 09-05-02 | 05-use-case-personal | 3 | D-04 | — | PTVF α=0.88 fold matches reference math (≤1e-9 closeTo) for JPY/CNY/USD bases | unit | `flutter test test/unit/application/analytics/get_happiness_report_use_case_test.dart -n "PTVF"` | ❌ W0 | ⬜ pending |
| 09-05-03 | 05-use-case-personal | 3 | D-13, D-15 | — | Empty trigger fires when `totalSoulTx = 0`; sample size carried correctly in Value variants | unit | `flutter test test/unit/application/analytics/get_happiness_report_use_case_test.dart -n "empty"` | ❌ W0 | ⬜ pending |
| 09-05-04 | 05-use-case-personal | 3 | D-15 | — | Median computed from `getSatisfactionDistribution`; matches expected for odd/even sample counts | unit | `flutter test test/unit/application/analytics/get_happiness_report_use_case_test.dart -n "median"` | ❌ W0 | ⬜ pending |
| 09-06-01 | 06-use-case-best-joy | 3 | HAPPY-04, D-06 | T-9-03 | `GetBestJoyMomentUseCase` honors `soul_satisfaction DESC, amount DESC, timestamp DESC` ordering | unit | `flutter test test/unit/application/analytics/get_best_joy_moment_use_case_test.dart` | ❌ W0 | ⬜ pending |
| 09-07-01 | 07-use-case-family | 3 | FAMILY-01 | T-9-04 (per-member leakage) | `GetFamilyHappinessUseCase` returns `FamilyHighlightsSum` as `int`; `Map<MemberId, int>` does NOT compile | unit + analyzer | `flutter test test/unit/application/analytics/get_family_happiness_use_case_test.dart && flutter analyze` | ❌ W0 | ⬜ pending |
| 09-07-02 | 07-use-case-family | 3 | FAMILY-02, D-08 | — | `SharedJoyInsight` returns `(categoryId, avgSatisfaction, totalCount)`; min-N=3 guard returns Empty when no category qualifies; tie-break by count then category_id | unit | `flutter test test/unit/application/analytics/get_family_happiness_use_case_test.dart -n "shared joy"` | ❌ W0 | ⬜ pending |
| 09-07-03 | 07-use-case-family | 3 | D-09 | — | `groupBookIds` empty → Empty result without DAO call; non-empty list passed to DAO | unit | `flutter test test/unit/application/analytics/get_family_happiness_use_case_test.dart -n "shadow books"` | ❌ W0 | ⬜ pending |
| 09-08-01 | 08-providers | 4 | — | — | 3 use case providers added to `repository_providers.dart`; `state_happiness.dart` consumes them; no provider duplication | unit + arch test | `flutter test test/unit/application/analytics/repository_providers_test.dart && flutter test test/arch/provider_graph_hygiene_test.dart` | ❌ W0 | ⬜ pending |
| 09-09-01 | 09-formatter | 4 | D-04, D-20 | — | `joy_density_formatter.formatJoyDensity` returns locale-aware string; PTVF base map has JPY/CNY/USD entries; fallback returns 500 base | unit | `flutter test test/unit/infrastructure/i18n/formatters/joy_density_formatter_test.dart` | ❌ W0 | ⬜ pending |
| 09-10-01 | 10-adr-no-gamification | 5 | HAPPY-07, D-22.1 | — | `ADR-012_No_Gamification_v1_1.md` exists with all required sections (Status/Context/Considered/Decision/Rationale/Consequences/Implementation Plan) | grep | `test -f docs/arch/03-adr/ADR-012_No_Gamification_v1_1.md && grep -q "Goodhart" docs/arch/03-adr/ADR-012_No_Gamification_v1_1.md` | ❌ W0 | ⬜ pending |
| 09-10-02 | 10-adr-no-gamification | 5 | D-22.1 | — | ADR-000_INDEX.md updated with ADR-012 entry | grep | `grep -q "ADR-012" docs/arch/03-adr/ADR-000_INDEX.md` | ❌ W0 | ⬜ pending |
| 09-11-01 | 11-adr-ptvf-scaling | 5 | D-04, D-22.2 | — | `ADR-013_Joy_Density_PTVF_Scaling.md` exists with α=0.88 citation, currency table, perf trade-off section | grep | `test -f docs/arch/03-adr/ADR-013_Joy_Density_PTVF_Scaling.md && grep -q "Kahneman" docs/arch/03-adr/ADR-013_Joy_Density_PTVF_Scaling.md` | ❌ W0 | ⬜ pending |
| 09-12-01 | 12-adr-unipolar | 5 | D-10, D-22.3 | — | `ADR-014_Soul_Satisfaction_Unipolar_Positive_Scale.md` exists with default-2 migration rationale, picker emoji semantic remap, voice realignment defer note | grep | `test -f docs/arch/03-adr/ADR-014_Soul_Satisfaction_Unipolar_Positive_Scale.md` | ❌ W0 | ⬜ pending |
| 09-13-01 | 13-spec-amendments | 6 | HAPPY-02, HAPPY-03, HAPPY-04, HAPPY-08, FAMILY-01 | — | REQUIREMENTS.md amended per CONTEXT.md "Spec Amendments" block; v1.1 active count drops 26→25 | grep | `grep -q "α=0.88" .planning/REQUIREMENTS.md && grep -qE "HAPPY-03.*≥6" .planning/REQUIREMENTS.md` | ❌ W0 | ⬜ pending |
| 09-13-02 | 13-spec-amendments | 6 | HAPPY-09 | — | HAPPY-09 removed from active REQ list; HAPPY-V2-03 dependency note updated | grep | `! grep -qE "^- HAPPY-09:" .planning/REQUIREMENTS.md && grep -q "HAPPY-V2-03" .planning/REQUIREMENTS.md` | ❌ W0 | ⬜ pending |
| 09-13-03 | 13-spec-amendments | 6 | D-22, D-23 | — | ROADMAP.md Phase 9 pitfalls updated (¥500 floor removed, voice-bias removed, schema bump added, PTVF added); Phase 12 scope expanded with 5 emoji ARB labels + picker icon | grep | `! grep -q "¥500 floor" .planning/ROADMAP.md && grep -q "schema bump v15 → v16" .planning/ROADMAP.md` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

> **Threat references** point to entries in each PLAN.md's `<threat_model>` block. T-9-01..T-9-04 are assigned by the planner; the table above uses placeholders that must align with whatever the planner ratifies. Surface secure behavior must be testable in code (no "looks correct").

---

## Wave 0 Requirements

Wave 0 establishes test scaffolding before any production code is written. Files listed below MUST exist (even if empty) before Wave 1 begins.

- [ ] `test/unit/data/migrations/migration_v15_to_v16_test.dart` — Drift migration round-trip (default 5 → 2)
- [ ] `test/unit/features/analytics/domain/models/metric_result_test.dart` — sealed Empty/Value variants, pattern-match exhaustiveness
- [ ] `test/unit/features/analytics/domain/models/happiness_report_test.dart` — Freezed aggregate construction with `MetricResult<...>` fields, copyWith
- [ ] `test/unit/data/daos/analytics_dao_happiness_test.dart` — `_soulOnly()` const exclusion, row-wise PTVF query, `getBestJoyMoment` argmax
- [ ] `test/unit/data/repositories/analytics_repository_happiness_test.dart` — repo impl delegates to DAO
- [ ] `test/unit/application/analytics/get_happiness_report_use_case_test.dart` — n=0/1/2 fixtures, PTVF math closeTo, median, Empty triggers
- [ ] `test/unit/application/analytics/get_best_joy_moment_use_case_test.dart` — argmax ordering pinned
- [ ] `test/unit/application/analytics/get_family_happiness_use_case_test.dart` — `int` aggregate-only signature, min-N=3 guard, shadowBooks integration
- [ ] `test/unit/application/analytics/repository_providers_test.dart` — 3 new use case providers wire correctly
- [ ] `test/unit/infrastructure/i18n/formatters/joy_density_formatter_test.dart` — JPY/CNY/USD/fallback base map, locale-aware formatting
- [ ] Existing `test/arch/provider_graph_hygiene_test.dart` covers no-duplicate-provider rule (verify, do not recreate)

*Test fixture strategy (Claude's Discretion in CONTEXT.md): hand-built fixtures for unit tests + minor `demo_data_service.dart` extension for any happiness-specific seeded rows touched by the schema migration. The `AppDatabase.forTesting()` precedent at existing analytics tests is the idiom.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| ADR prose quality (Goodhart's Law framing, citation accuracy) | D-22.1, D-22.2, D-22.3 | Subjective writing review; auto checks only verify section headings exist | Read each ADR end-to-end; confirm citations are accurate (Kahneman & Tversky 1979; Goodhart 1975), the framing is consistent with HAPPY-07 / D-04 / D-10. |
| ROADMAP.md Phase 12 scope expansion lands accurately | D-23 | Cross-document edit; auto check confirms keyword presence but not semantic accuracy | Open ROADMAP.md Phase 12 section after edit; confirm "5 emoji ARB labels" and "picker icon emoji 1: very_dissatisfied → neutral" are added under Phase 12 critical pitfalls. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
