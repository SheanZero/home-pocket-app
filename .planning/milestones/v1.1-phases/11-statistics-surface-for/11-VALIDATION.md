---
phase: 11
slug: statistics-surface-for
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-03
---

# Phase 11 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Source: `11-RESEARCH.md` § Validation Architecture (lines 516–567).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `flutter_test` (built-in) + `mocktail` (existing analytics tests) |
| **Config file** | `pubspec.yaml` (test deps) — no separate `dart_test.yaml` |
| **Quick run command** | `flutter test test/unit/features/analytics/ test/widget/features/analytics/` |
| **Full suite command** | `flutter test --coverage` |
| **Estimated runtime** | ~15s quick · ~90s full (current baseline) |

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/unit/features/analytics/ test/widget/features/analytics/`
- **After every plan wave:** Run `flutter test --coverage`
- **Before `/gsd-verify-work`:** Full suite must be green; coverage ≥ 80%
- **Max feedback latency:** 90 seconds

---

## Per-Task Verification Map

> Plans MUST cite these REQ-IDs in their `requirements_addressed` frontmatter and reference the corresponding test file in each task's `<acceptance_criteria>`.

| Task scope | Plan (expected) | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|------------|-----------------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| Footprint audit doc | 01 | 0 | STATSUI-04 | — | N/A (planning artifact) | manual (file-presence gate) | `git log --diff-filter=A --name-only -- .planning/phases/11-statistics-surface-for/11-AUDIT.md \| grep -q AUDIT.md` | ✅ | ✅ green |
| New DAO `getDailySoulRowsForPtvf` | 02 | 1 | D-05 (domain) | T-Tampering-1 | Drift parameterized `Variable.withString` (no string interpolation in SQL) | unit | `flutter test test/unit/data/daos/analytics_dao_daily_joy_test.dart` | ✅ | ✅ green |
| New use case `GetDailyJoyPerYenUseCase` | 02 | 1 | NEW (domain) | — | per-day fold matches monthly fold within rounding | unit | `flutter test test/unit/application/analytics/get_daily_joy_per_yen_use_case_test.dart` | ✅ | ✅ green |
| New use case `GetLargestMonthlyExpenseUseCase` | 02 | 1 | NEW (domain) | — | argmax (amount DESC, timestamp DESC) returns single row | unit | `flutter test test/unit/application/analytics/get_largest_monthly_expense_use_case_test.dart` | ✅ | ✅ green |
| Trilingual ARB additions (3 locales) | 02 | 1 | STATSUI-02, STATSUI-03 | — | ARB key parity across ja/zh/en | static | `flutter gen-l10n && flutter analyze` | ✅ | ✅ green |
| `JoyHeadlineKpiTile` widget | 04 | 2 | STATSUI-03, STATSUI-07 | T-Information-1 | error widget uses `l10n.analyticsCardErrorBody`; no raw `error.toString()` | widget | `flutter test test/widget/features/analytics/presentation/widgets/joy_headline_kpi_tile_test.dart` | ✅ | ✅ green |
| `KpiMiniHeroStrip` widget | 04 | 2 | STATSUI-07 | — | re-keys on `(bookId, year, month)`; tabularFigures alignment | widget | `flutter test test/widget/features/analytics/presentation/widgets/kpi_mini_hero_strip_test.dart` | ✅ | ✅ green |
| `MonthChipPicker` widget | 04 | 2 | STATSUI-07 | — | Range bound to `[earliestTxMonth, currentMonth]` | widget | `flutter test test/widget/features/analytics/presentation/widgets/month_chip_picker_test.dart` | ✅ | ✅ green |
| `MonthlySpendTrendBarChart` (6 か月) | 05 | 2 | STATSUI-06 | — | current month bar highlighted; respects `selectedMonthProvider` anchor | widget | `flutter test test/widget/features/analytics/presentation/widgets/monthly_spend_trend_bar_chart_test.dart` | ✅ | ✅ green |
| `JoyTrendLineChart` (Joy/¥) | 05 | 2 | STATSUI-01 | — | baseline-anchored y-axis; gap-vs-zero (segmented `LineChartBarData`) | widget | `flutter test test/widget/features/analytics/presentation/widgets/joy_trend_line_chart_test.dart` | ✅ | ✅ green |
| `CategorySpendDonutChart` (類別支出) | 05 | 2 | STATSUI-06 | — | Top-N + その他 grouping | widget | `flutter test test/widget/features/analytics/presentation/widgets/category_spend_donut_chart_test.dart` | ✅ | ✅ green |
| `SatisfactionDistributionHistogram` | 05 | 2 | STATSUI-02 | — | bar-5 trilingual annotation; n<5 → joint fallback | widget | `flutter test test/widget/features/analytics/presentation/widgets/satisfaction_distribution_histogram_test.dart` | ✅ | ✅ green |
| `LargestExpenseStoryCard` (今月の最大支出) | 06 | 2 | STATSUI-06 | T-Information-1 | semantic label reads category + amount, NOT merchant/description | widget | `flutter test test/widget/features/analytics/presentation/widgets/largest_expense_story_card_test.dart` | ✅ | ✅ green |
| `BestJoyStoryStrip` story | 06 | 2 | STATSUI-02 | T-Information-1 | semantic label reads category + score + amount, NOT merchant | widget | `flutter test test/widget/features/analytics/presentation/widgets/best_joy_story_strip_test.dart` | ✅ | ✅ green |
| `FamilyInsightCard` group-mode render gate | 06 | 2 | STATSUI-02 | — | renders ONLY when `shadowBooks.isNotEmpty && groupMode`; aggregate-only | widget | `flutter test test/widget/features/analytics/presentation/widgets/family_insight_card_test.dart` | ✅ | ✅ green |
| `JoyLedgerThinSampleFallback` (n<5 joint placeholder) | 06 | 2 | STATSUI-02 | — | rendered in 時間 group when `dailyJoyPerYenProvider` sample size < 5; histogram slot suppressed jointly per D-07 | widget | `flutter test test/widget/features/analytics/presentation/widgets/joy_ledger_thin_sample_fallback_test.dart` | ✅ | ✅ green |
| AnalyticsScreen rebuild + 8-widget delete + characterization-test delete (atomic) | 07 | 3 | STATSUI-05 | — | Variant δ structure; `grep -rl '<8 widget names>' lib/` returns empty | widget + grep gate | `flutter test test/widget/features/analytics/presentation/screens/analytics_screen_test.dart && [ -z "$(grep -rl 'SummaryCards\|CategoryPieChart\|DailyExpenseChart\|LedgerRatioChart\|BudgetProgressList\|ExpenseTrendChart\|CategoryBreakdownList\|MonthComparisonCard' lib/)" ]` | ✅ | ✅ green |
| (optional) Goldens for Joy/¥ + histogram | 08 | 4 | STATSUI-01, STATSUI-02 | — | golden parity across themes | golden | `flutter test test/golden/joy_trend_line_chart_golden_test.dart test/golden/satisfaction_distribution_histogram_golden_test.dart` | — skipped | ⚪ optional deferred |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Sample Points (Nyquist Dimension 8)

> The plan-checker AND `/gsd-verify-work` MUST verify these scenarios appear as test fixtures. Source: RESEARCH.md lines 544–557.

1. **n=0 (empty month)** — all soul cards Empty state; histogram joint fallback; KPI 悦己 tile shows `データを集計中...` placeholder.
2. **n=1..4 (thin sample)** — Joy/¥ trend + histogram render joint fallback; KPI 悦己 tile shows mean + `n=k` even for small n.
3. **n=5 cluster (only sat=5)** — histogram shows bar 5 only (with 1px stubs on others to anchor `BarChartRodLabel`); annotation visible; mean=median=5; coverage `n=k/k`.
4. **All sat=10** — histogram visible only on bar 10; bar-5 stub still renders trilingual annotation per Pitfall 5 normalization.
5. **Group mode + shadowBooks empty** — `FamilyInsightCard` does NOT render; rest of dashboard unaffected.
6. **Group mode + shadowBooks present + family Empty (no shared insight, n<3 per category)** — FamilyInsightCard renders empty-state body sentence (anti-leaderboard preserved).
7. **Joy/¥ gap-vs-zero** — day with no soul tx renders as line gap, NOT zero point; legend caption visible.
8. **Per-card AsyncError** — if `dailyJoyPerYenProvider` errors, only Joy/¥ card shows error state; histogram + 6 か月 + KPI tiles still render.
9. **Currency = CNY** — Joy/¥ Y-axis labels use `/ ¥100` suffix not `/ ¥1k`; ¥ formatting uses 2 decimals not 0.
10. **Locale parity (ja/zh/en)** — month chip labels render correctly per locale; trilingual annotation reflects current locale.

---

## Wave 0 Requirements

> First-commit gate before any wiring code. Plans MUST schedule these in Wave 0 / Wave 1 BEFORE Wave 2 widgets reference them.

- [x] `.planning/phases/11-statistics-surface-for/11-AUDIT.md` — STATSUI-04 footprint audit doc, FIRST commit of the phase
- [x] `test/unit/data/daos/analytics_dao_daily_joy_test.dart` — covers `getDailySoulRowsForPtvf` (Wave 1)
- [x] `test/unit/application/analytics/get_daily_joy_per_yen_use_case_test.dart` — Wave 1
- [x] `test/unit/application/analytics/get_largest_monthly_expense_use_case_test.dart` — Wave 1
- [x] 9 widget test files (KPI tile + month chip + 4 chart cards + 3 story cards + family card) — Wave 2 alongside the widgets
- [x] `test/widget/features/analytics/presentation/screens/analytics_screen_test.dart` — replaces deleted characterization test, Wave 3 atomic
- [ ] (optional) `test/golden/joy_trend_line_chart_golden_test.dart` + `test/golden/satisfaction_distribution_histogram_golden_test.dart` — Wave 4 polish deferred in Plan 11-08; existing `test/golden/` suite verified green
- [x] ARB key parity check: `flutter gen-l10n` is part of Wave 1 commit; CI guardrail catches missing ja/zh/en additions

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Variant δ visual hierarchy (KPI strip → 時間 → 分布 → 物語 with 総-first ordering) matches UI-SPEC | STATSUI-05 | Visual layout judgement is not grep-verifiable beyond widget tree shape | Run `flutter run -d <emulator>`, navigate to Analytics, compare against `11-UI-SPEC.md` Variant δ wireframe |
| Trilingual annotation visually anchored to bar-5 across ja/zh/en switches | STATSUI-02 | Font metrics + character-width vary per locale; widget test confirms presence but not visual anchoring | Manually switch app locale (Settings → Language) ja → zh → en and confirm annotation stays anchored to bar 5 with no clipping |
| Native-speaker register check on histogram + KPI ARB strings | STATSUI-02, STATSUI-03 | Tone/register requires native-speaker review; can't be automated | Schedule 30 min review with native ja/zh/en speakers before Wave 4 close (or defer to Phase 12 native review pass) |
| FamilyInsightCard anti-leaderboard policy (no per-member breakdown UI ever surfaces) | STATSUI-02 | Contract is structural ("aggregate-only"); widget tests can verify current state but cannot prove the contract holds across future code paths | Code review checkpoint: confirm `familyHappinessProvider` API does not expose `byMemberId`/`byShadowBookId` fields; document in PLAN.md `must_haves` |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify (check after planner emits PLAN.md files)
- [x] Wave 0 covers all MISSING references (footprint audit + ARB additions + 3 unit test stubs + 9 widget test stubs)
- [x] No watch-mode flags in any test command (one-shot only — `flutter test test/...`, never `flutter test --watch`)
- [x] Feedback latency < 90s for full suite, < 15s for quick suite
- [x] `nyquist_compliant` frontmatter flag set to true once plans pass checker

**Approval:** approved 2026-05-04 (Phase 11 plans 01-08 complete; `flutter analyze` clean; analytics and golden test targets green; per-task automated verify present in every PLAN.md)
