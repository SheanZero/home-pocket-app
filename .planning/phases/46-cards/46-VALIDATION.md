---
phase: 46
slug: cards
status: ready
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-17
---

# Phase 46 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from 46-RESEARCH.md § Validation Architecture; Per-Task Map populated by the planner.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `flutter_test` (+ golden via `test/flutter_test_config.dart` BaselineExistenceGoldenComparator off-macOS) |
| **Config file** | `test/flutter_test_config.dart` (golden platform gate) |
| **Quick run command** | `flutter test test/widget/features/analytics/` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | quick ~30–60s · full several min |

---

## Sampling Rate

- **After every task commit:** Run the task's scoped `<automated>` command + `flutter analyze` (MUST be 0 issues).
- **After every plan wave:** Run **FULL `flutter test`** — scoped runs miss architecture tests (`hardcoded_cjk_ui_scan`, 生存/灵魂 grep-ban, import_guard, registry isolation). Documented project gotcha (Phase 38 memory). The Wave-3 integration plan (46-07) makes the full-suite gate an explicit task.
- **Before `/gsd-verify-work`:** Full suite must be green.
- **Max feedback latency:** ~60 seconds (quick) per task; full suite per wave.
- **Goldens:** NOT authored in Phase 46 — re-baseline is Phase 47 (macOS only). Do not attempt pixel baselines off-macOS.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 46-01·T1 | 01 | 1 | OVW-02 | T-46-01-01/02 | book-set never widened; no tx logging | unit | `flutter test test/unit/application/analytics/get_within_month_cumulative_use_case_test.dart` | ❌ W0 | ⬜ pending |
| 46-01·T2 | 01 | 1 | OVW-02 | T-46-01-03 | bound params | unit | `flutter test test/unit/application/analytics/ test/unit/features/analytics/` | ✅ update | ⬜ pending |
| 46-02·T1 | 02 | 1 | JOY-01/02 | T-46-02-01/02 | book-set faithful; aggregate-only | unit | `flutter test test/unit/application/analytics/get_joy_category_amounts_use_case_test.dart` | ❌ W0 | ⬜ pending |
| 46-02·T2 | 02 | 1 | JOY-01/02 | T-46-02-01/02 | book-set faithful; count not per-member | unit | `flutter test test/unit/application/analytics/get_per_day_joy_counts_use_case_test.dart` | ❌ W0 | ⬜ pending |
| 46-03·T1 | 03 | 1 | JOY-03 | T-46-03-01 | docs-only | n/a (grep) | `grep -c "Descoped" .planning/REQUIREMENTS.md` | ✅ | ⬜ pending |
| 46-03·T2 | 03 | 1 | JOY-04 | T-46-03-01 | docs-only | n/a (grep) | `grep -n "round-5 B" .planning/ROADMAP.md` | ✅ | ⬜ pending |
| 46-06·T1 | 06 | 1 | REDES-02 | T-46-06-SC | no new deps | widget | `flutter test test/widget/features/analytics/presentation/widgets/satisfaction_distribution_histogram_test.dart` | ✅ update | ⬜ pending |
| 46-06·T2 | 06 | 1 | DRILL-01/OVW-02 | T-46-06-01/02/04 | book-set faithful; read-only; neutral header | widget | `flutter test test/widget/features/analytics/presentation/screens/category_drill_down_screen_test.dart` | ❌ W0 | ⬜ pending |
| 46-06·T3 | 06 | 1 | OVW-02 | T-46-06-01 | single-source rollup; row-tap only | widget | `flutter test test/widget/features/analytics/presentation/widgets/cards/category_donut_card_test.dart` | ❌ W0 | ⬜ pending |
| 46-04·T1 | 04 | 2 | OVW-02 | T-46-04-02 | joy line structurally single (no 上月) | widget | `flutter test test/widget/features/analytics/presentation/widgets/within_month_cumulative_line_chart_test.dart` | ❌ W0 | ⬜ pending |
| 46-04·T2 | 04 | 2 | OVW-02/REDES-03 | T-46-04-01/02 | no per-member series; joy tab zero cross-period | widget | `flutter test test/widget/features/analytics/presentation/widgets/cards/within_month_trend_card_test.dart` | ❌ W0 | ⬜ pending |
| 46-05·T1 | 05 | 2 | JOY-01/02/REDES-03 | T-46-05-02/03 | ambient only; no target/streak/cross-period | widget | `flutter test test/widget/features/analytics/presentation/widgets/cards/joy_spend_card_test.dart` | ❌ W0 | ⬜ pending |
| 46-05·T2 | 05 | 2 | JOY-01/02/REDES-03 | T-46-05-01/02/03 | day read book-set faithful; ambient f(count) | widget | `flutter test test/widget/features/analytics/presentation/widgets/cards/joy_calendar_card_test.dart` | ❌ W0 | ⬜ pending |
| 46-07·T1 | 07 | 3 | OVW-02/JOY-01/02/REDES-02 | T-46-07-01/02 | union ⊆ analytics, zero home/* | (build) | `flutter analyze lib/features/analytics/` | ✅ | ⬜ pending |
| 46-07·T2 | 07 | 3 | GUARD-02 | T-46-07-03 | anti-toxicity subjects scan-ready | widget | `flutter test test/widget/features/analytics/` | ✅ update | ⬜ pending |
| 46-07·T3 | 07 | 3 | GUARD-02 | T-46-07-01 | isolation + grep-ban + single-joy-expr | full | `flutter test` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

### Requirement → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| OVW-02 | within-month trend (spend dual + joy single, zero joy cross-period); donut/calendar/histogram neutral; drill header neutral | unit+widget | `flutter test test/unit/application/analytics/ test/widget/features/analytics/` | mix (W0 for new) |
| JOY-01 | 已花悦己 ambient (悦己 trend tab + 悦己花在哪 header); NO analytics target ring (D-A4) | widget | `flutter test test/widget/features/analytics/presentation/widgets/cards/joy_spend_card_test.dart` | ❌ W0 |
| JOY-02 | satisfaction histogram (native label) + 分类悦己 via 悦己花在哪 stacked bar | widget | `flutter test test/widget/features/analytics/presentation/widgets/` | ✅ update + ❌ W0 |
| JOY-03 | DESCOPED — recorded in REQUIREMENTS.md (D-A2) | n/a | `grep "Descoped" .planning/REQUIREMENTS.md` | ✅ |
| JOY-04 | DESCOPED — recorded in REQUIREMENTS.md (D-A2) | n/a | `grep "Descoped" .planning/REQUIREMENTS.md` | ✅ |
| REDES-02 | histogram native `BarChartRodData.label` (no Stack hack) + optional donut cornerRadius | widget | `flutter test test/widget/features/analytics/presentation/widgets/satisfaction_distribution_histogram_test.dart` | ✅ update |
| REDES-03 | TweenAnimationBuilder count-up on 2 anchors (donut center + 悦己 header); calm one-shot card淡入 | widget | `flutter test test/widget/features/analytics/presentation/widgets/cards/` | ❌ W0 |
| GUARD-02 | new cards scan-ready in anti_toxicity_phase17; FamilyHappiness aggregate-only; `grep density\|joyPerYen lib/` == 0 | widget+full | `flutter test test/widget/features/analytics/presentation/widgets/anti_toxicity_phase17_test.dart && flutter test` | ✅ update |
| GUARD-01 (carry) | HomeHero isolation preserved | widget | `flutter test test/widget/features/home/presentation/screens/home_screen_isolation_test.dart` | ✅ stays green |
| REDES-01 (carry) | registry union ⊆ analytics, zero home/* after re-order | widget | `flutter test test/widget/features/analytics/presentation/analytics_card_registry_test.dart` | ✅ update shape |

---

## Wave 0 Requirements

- [ ] `within_month_cumulative_line_chart` + `within_month_trend_card` tests (46-04) — D-E1/D-E2
- [ ] `get_within_month_cumulative_use_case` unit test (46-01) — per-day cumulative + per-ledger split + joy-no-cross-period
- [ ] `get_joy_category_amounts_use_case` + `get_per_day_joy_counts_use_case` unit tests (46-02)
- [ ] `joy_spend_card` (悦己花在哪) + `joy_calendar_card` (小确幸日历) tests (46-05)
- [ ] `category_drill_down_screen` test — read-only tile (no swipe/edit) (46-06)
- [ ] `category_donut_card` test — 10 L1-rollup legend rows + row-tap drill push + count-up (46-06)
- [ ] update `analytics_card_registry_test.dart` expected shape (5 cards + family conditional; whitelist swap) (46-07)
- [ ] update `analytics_screen_test.dart` (no section headers; new cards) + sibling no-delta/group-refresh tests (46-07)
- [ ] extend `anti_toxicity_phase17_test.dart` subjects to include the new cards (GUARD-02 readiness; full 扫描扩充 = Phase 47) (46-07)
- [ ] delete tests for removed cards (`monthly_spend_trend_bar_chart_test`, `get_expense_trend_use_case_test`, `expense_trend_test`, dead-card goldens) (46-01/46-07)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Real-device visual fidelity vs round-5 B mocks | REDES-02/03 | Pixel/golden baselining is Phase 47 (macOS-only); device UAT is Phase 47 | Deferred to Phase 47 UAT |
| Count-up animation feel (~400-600ms) on the 2 anchors | REDES-03 | Animation timing is perceptual | Verified in Phase 47 device UAT; logic asserted by widget tests landing on true total |

*Phase 46 ships structure + behavior; visual golden + device UAT are Phase 47 by milestone design.*

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 60s (quick) per task; full suite per wave
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** ready for execution
