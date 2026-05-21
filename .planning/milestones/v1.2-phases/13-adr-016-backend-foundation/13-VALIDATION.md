---
phase: 13
slug: adr-016-backend-foundation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-19
---

# Phase 13 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test (built-in) + mocktail (existing dev_dependency) |
| **Config file** | `pubspec.yaml` dev_dependencies (no extra config needed) |
| **Quick run command** | `flutter test test/unit/application/analytics/ test/unit/infrastructure/i18n/formatters/ test/unit/data/repositories/settings_repository_test.dart -x` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~45s for quick subset, ~3–5 min for full suite |

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/unit/application/analytics/ -x` (or narrower for non-analytics tasks)
- **After every plan wave:** Run `flutter test` (full suite)
- **Before `/gsd:verify-work`:** Full suite must be green AND density grep gates pass
- **Max feedback latency:** 45s for quick subset, 5 min for full suite

---

## Per-Task Verification Map

> Provisional map — planner refines exact task IDs in PLAN.md frontmatter. Plan IDs follow `13-NN-MM` (plan-wave-task) convention.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 13-01-01 | 01 | 1 | JOYMIG-02, JOYMIG-05 | — | ROADMAP SC-2 wording fixed; REQUIREMENTS unchanged | doc | manual grep `grep -n 'Schema migration adds .user_settings' .planning/ROADMAP.md` returns 0 | ✅ | ⬜ pending |
| 13-02-01 | 02 | 1 | JOYMIG-02 | — | Spike scenarios computed; fallback baseline + outlier policy + persistence behavior decided in writing | doc | manual: `test -f .planning/phases/13-adr-016-backend-foundation/13-SPIKE.md` | ❌ W0 | ⬜ pending |
| 13-03-01 | 03 | 2 | JOYMIG-02 | — | `AppSettings.monthlyJoyTarget int?` round-trips through SharedPreferences | unit | `flutter test test/unit/data/repositories/settings_repository_test.dart -x` | ⚠ (likely exists; verify path) | ⬜ pending |
| 13-04-01 | 04 | 3 | JOYMIG-02, JOYMIG-05 | — | `Σ joy_contribution = Σ(soul_satisfaction × (amount/base)^0.88)`; no `/Σamount` denominator anywhere | unit | `flutter test test/unit/application/analytics/get_happiness_report_use_case_test.dart -x` | ✅ (update) | ⬜ pending |
| 13-04-02 | 04 | 3 | JOYMIG-05 | — | `HappinessReport.joyContribution` Freezed field exists; `joyPerYen` field removed | unit | `flutter test test/unit/features/analytics/domain/models/happiness_report_test.dart -x` | ✅ (update) | ⬜ pending |
| 13-05-01 | 05 | 3 | JOYMIG-02 | — | `GetMonthlyJoyTargetRecommendationUseCase` returns `ceil(median(M-1, M-2, M-3))` when ≥3 months data | unit | `flutter test test/unit/application/analytics/get_monthly_joy_target_recommendation_use_case_test.dart -x` | ❌ W0 | ⬜ pending |
| 13-05-02 | 05 | 3 | JOYMIG-02 | — | Returns `Empty()` when <3 months data; <3-month edge cases covered | unit | (same file as 13-05-01) | ❌ W0 | ⬜ pending |
| 13-05-03 | 05 | 3 | JOYMIG-02 | — | Ceil boundary tested (median 50.0 → 50; median 50.1 → 51) | unit | (same file as 13-05-01) | ❌ W0 | ⬜ pending |
| 13-05-04 | 05 | 3 | JOYMIG-02 | — | CNY currency variation covered | unit | (same file as 13-05-01) | ❌ W0 | ⬜ pending |
| 13-05-05 | 05 | 3 | JOYMIG-02 | — | Year boundary month arithmetic (asOf=Feb 2026 → M-3=Nov 2025) verified | unit | (same file as 13-05-01) | ❌ W0 | ⬜ pending |
| 13-06-01 | 06 | 4 | JOYMIG-05 | — | `joy_cumulative_formatter.dart` produces integer + locale thousand-separator; `ptvfBaseFor` preserved | unit | `flutter test test/unit/infrastructure/i18n/formatters/joy_cumulative_formatter_test.dart -x` | ❌ W0 | ⬜ pending |
| 13-07-01 | 07 | 5 | JOYMIG-05 | — | `state_happiness.dart` no longer exposes `dailyJoyPerYen`; `monthlyJoyTargetRecommendation` provider exists | unit + compile | `flutter analyze` returns 0 issues + targeted state provider tests if any | ✅ (update) | ⬜ pending |
| 13-08-01 | 08 | 5 | JOYMIG-05 | — | `joy_trend_line_chart.dart`, `get_daily_joy_per_yen_use_case.dart`, `daily_joy_per_yen_point.dart`, `joy_density_formatter.dart`, related test files all deleted | grep | `grep -rn 'JoyTrendLineChart\|DailyJoyPerYenPoint\|joy_density_formatter' lib/ test/ --include='*.dart' \| grep -v .g.dart\|.freezed.dart` returns 0 | ✅ (delete) | ⬜ pending |
| 13-08-02 | 08 | 5 | JOYMIG-05 | — | `_SatisfactionHistogramOrFallback` gate rewired to `happinessReportProvider.totalSoulTx` (no `dailyJoyPerYenProvider`) | unit + golden | `flutter test test/widget/features/analytics/ -x` if widget tests exist, else compile gate via `flutter analyze` | ✅ (update) | ⬜ pending |
| 13-09-01 | 09 | 5 | JOYMIG-05 | — | `home_hero_card.dart`: `happiness.joyPerYen` → `joyContribution`; `formatJoyDensity` → `formatJoyCumulative`; `_TooltipKey.joyPerYen` renamed | unit/widget | `flutter test test/widget/features/home/ -x` if exists, else `flutter analyze` | ✅ (update) | ⬜ pending |
| 13-10-01 | 10 | 6 | JOYMIG-05 | — | `grep -rn 'density' lib/ --include='*.dart'` returns only deprecation comments | grep gate | `bash -c "grep -rn 'density' lib/ --include='*.dart' \| grep -v 'deprecat\\|removed\\|^.*://'"` returns 0 | N/A (script) | ⬜ pending |
| 13-10-02 | 10 | 6 | JOYMIG-05 | — | No `joyPerYen`, `joyDensity`, `formatJoyDensity`, `_computePtvfDensity` in lib/ (excluding generated) | grep gate | `grep -rn 'joyPerYen\|joyDensity\|formatJoyDensity\|_computePtvfDensity' lib/ --include='*.dart' \| grep -v .g.dart\|.freezed.dart` returns 0 | N/A (script) | ⬜ pending |
| 13-11-01 | 11 | 6 | JOYMIG-02, JOYMIG-05 | — | `flutter pub run build_runner build --delete-conflicting-outputs` succeeds; AUDIT-10 CI guardrail satisfied | build | `flutter pub run build_runner build --delete-conflicting-outputs && flutter analyze` | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

The following files MUST be scaffolded before implementation begins (or the implementing task must create them as part of RED→GREEN test-first cycle):

- [ ] `test/unit/application/analytics/get_monthly_joy_target_recommendation_use_case_test.dart` — stubs for REQ JOYMIG-02 recommendation algorithm (≥3-month, 2-month, 0-month, all-zero-sat, year-boundary, ceil-boundary, CNY currency)
- [ ] `test/unit/infrastructure/i18n/formatters/joy_cumulative_formatter_test.dart` — stubs for REQ JOYMIG-05 formatter (integer rounding, ja/zh/en thousand-separator, `ptvfBaseFor` preservation)
- [ ] `.planning/phases/13-adr-016-backend-foundation/13-SPIKE.md` — D-05 deliverable file (created by spike task in Wave 1)
- [ ] Verify `test/unit/data/repositories/settings_repository_test.dart` exists (research notes it likely exists; if missing, scaffold it with `monthlyJoyTarget` round-trip cases)

*Updates to existing tests (not Wave 0, but required updates):*

- `test/unit/application/analytics/get_happiness_report_use_case_test.dart` — replace `joyPerYen` field assertions with `joyContribution`; verify no `/Σamount` math
- `test/unit/features/analytics/domain/models/happiness_report_test.dart` — Freezed field rename
- `test/unit/application/analytics/get_daily_joy_per_yen_use_case_test.dart` — **delete** entire file
- `test/unit/infrastructure/i18n/formatters/joy_density_formatter_test.dart` — **delete** entire file (replaced by `joy_cumulative_formatter_test.dart`)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| HomeHero KPI tile renders `formatJoyCumulative` output without layout regression | JOYMIG-05 | No widget test exists for HomeHero's central KPI label; layout is Phase 14 redesign scope | Run app on simulator; navigate to Home; confirm KPI label reads integer (e.g., `1,235`) not `1.23`; no overflow, no `null` text |
| Settings UI accepts and persists `monthly_joy_target` via SharedPreferences | JOYMIG-02 | Phase 13 ships persistence path only; Settings UI control is Phase 14 — manual verify uses test harness or temporary debug button (NOT shipped) | Use existing `SettingsRepository.setMonthlyJoyTarget(50)` from a test or via `flutter test` integration, then `getSettings().monthlyJoyTarget` returns 50; null clears the key |
| Spike report (`13-SPIKE.md`) documents 3–5 scenarios with computed Σ joy_contribution and decided fallback | JOYMIG-02 | Spike is a planning artifact, not code; verification is human reading of the Markdown | Verify `.planning/phases/13-adr-016-backend-foundation/13-SPIKE.md` has: ≥3 scenario table rows, fallback baseline number in [30,100], outlier policy stated, persistence framing stated |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies declared
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (the 4 items above)
- [ ] No watch-mode flags (`flutter test --watch` forbidden in CI)
- [ ] Feedback latency < 45s for per-commit quick subset
- [ ] `nyquist_compliant: true` set in frontmatter once planner-checker passes
- [ ] Density grep gates (D-10) added as explicit task-level acceptance criteria in PLAN.md

**Approval:** pending
