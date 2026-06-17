---
phase: 46
slug: cards
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-17
---

# Phase 46 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from 46-RESEARCH.md § Validation Architecture.

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

- **After every task commit:** Run `flutter test test/widget/features/analytics/` + `flutter analyze` (MUST be 0 issues)
- **After every plan wave:** Run **FULL `flutter test`** — scoped runs miss architecture tests (`hardcoded_cjk_ui_scan`, 生存/灵魂 grep-ban, import_guard, registry isolation). Documented project gotcha (Phase 38 memory).
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** ~60 seconds (quick) per task; full suite per wave
- **Goldens:** NOT authored in Phase 46 — re-baseline is Phase 47 (macOS only). Per the golden CI platform gate, do not attempt pixel baselines off-macOS.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| _planner-populates_ | — | — | — | — | — | — | — | — | ⬜ pending |

*Planner populates this table from the task breakdown. Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

### Requirement → Test Map (from research, to be expanded by planner)

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| REDES-02 | histogram uses native `BarChartRodData.label` (no Stack hack) | widget | `flutter test test/widget/features/analytics/presentation/widgets/` | ✅ update |
| GUARD-02 | new card copy passes forbidden-substring sweep ja/zh/en | widget | `flutter test test/widget/features/analytics/presentation/widgets/anti_toxicity_phase17_test.dart` | ✅ extend subjects (W0) |
| GUARD-01 (carry) | HomeHero isolation preserved | widget | `flutter test test/widget/features/home/presentation/screens/home_screen_isolation_test.dart` | ✅ stays green |
| REDES-01 (carry) | registry union ⊆ analytics, zero `home/*` | widget | `flutter test test/widget/features/analytics/presentation/analytics_card_registry_test.dart` | ✅ update expected shape |
| DRILL-01 (UI) | drill page read-only list (no swipe/edit) | widget | new `category_drill_down_screen_test.dart` | ❌ W0 |
| OVW-02 / JOY-01..02 | new cards render, ADR-012-safe | widget/unit | new per-card tests | ❌ W0 |

---

## Wave 0 Requirements

- [ ] `within_month_trend_card` + within-month cumulative line chart widget tests — covers D-E1/D-E2
- [ ] new trend use-case / provider unit test (per-day cumulative + per-ledger split)
- [ ] 悦己花在哪 card test — per-L1 joy **amount** rollup + tap-highlight
- [ ] 小确幸日历 card test — per-day joy COUNT + tap-day inline expand
- [ ] `category_drill_down_screen` test — read-only tile (no swipe/edit)
- [ ] update `analytics_card_registry_test.dart` expected shape (5 cards + conditional family_insight)
- [ ] extend `anti_toxicity_phase17_test.dart` subjects to include new cards (GUARD-02 readiness; full 扫描扩充 = Phase 47)
- [ ] delete tests for removed cards (`monthly_spend_trend_bar_chart_test`, dead-card tests)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Real-device visual fidelity vs round-5 B mocks | REDES-02/03 | Pixel/golden baselining is Phase 47 (macOS-only); device UAT is Phase 47 | Deferred to Phase 47 UAT |

*Phase 46 ships structure + behavior; visual golden + device UAT are Phase 47 by milestone design.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
