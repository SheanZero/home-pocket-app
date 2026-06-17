---
phase: 47
slug: i18n-macos-golden-uat
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-17
---

# Phase 47 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from RESEARCH.md `## Validation Architecture`. This phase IS verification
> coverage, so the requirement→test mapping below is exhaustive. Per-task rows are
> filled in once PLAN.md files exist (task IDs unknown until planning completes).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `flutter_test` (bundled with Flutter 3.44.0) + golden via `matchesGoldenFile` |
| **Config file** | `test/flutter_test_config.dart` (global golden platform gate — already present) |
| **Quick run command** | `flutter test test/widget/features/analytics/ <plus the touched file>` |
| **Full suite command** | `flutter test` (FULL, never a subset — per-wave gate) |
| **Golden author command** | `flutter test --update-goldens --tags golden` (macOS host ONLY) |
| **Estimated runtime** | quick scoped run ~seconds; full suite ~minutes (2000+ tests) |

---

## Sampling Rate

- **After every task commit:** `flutter test test/widget/features/analytics/ <plus the touched file>` + `flutter analyze` (0 issues)
- **After every plan wave:** `flutter test` (FULL suite — includes `home_screen_isolation_test.dart`, all 3 anti-toxicity scans, and the architecture/CJK/density grep guards) + `flutter analyze` + golden baselines committed (macOS)
- **Before `/gsd-verify-work`:** Full suite green + `flutter test --coverage` ≥80%
- **Phase gate (D-12 blocking):** full suite green + on-device UAT checklist all-green BEFORE v1.8 milestone closeout — no acknowledged-deferred path
- **Max feedback latency:** scoped quick-run (seconds) per task; full suite (minutes) per wave

---

## Per-Task Verification Map

> Filled in during planning/execution — task IDs do not exist until PLAN.md files are written.
> Requirement→test mapping below is authoritative; map each task to its row here.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 47-NN-NN | NN | N | GUARD-03 | — | ARB parity en/ja/zh | architecture | `flutter test test/architecture/arb_key_parity_test.dart` | ✅ exists | ⬜ pending |
| 47-NN-NN | NN | N | GUARD-03 | — | `flutter gen-l10n` clean | build | `flutter gen-l10n && flutter analyze` | ✅ toolchain | ⬜ pending |
| 47-NN-NN | NN | N | GUARD-03 | — | 生存/灵魂 grep-ban green (ADR-017) | architecture | `flutter test` (terminology guard) | ✅ exists | ⬜ pending |
| 47-NN-NN | NN | N | GUARD-03 | — | no hardcoded CJK in new UI | architecture | `flutter test test/architecture/hardcoded_cjk_ui_scan_test.dart` | ✅ exists | ⬜ pending |
| 47-NN-NN | NN | N | GUARD-02-wording + GUARD-03 | — | 5 cards × 3 langs × all states → no forbidden substrings | widget | `flutter test test/widget/features/analytics/presentation/widgets/anti_toxicity_phase47_test.dart` | ❌ NEW | ⬜ pending |
| 47-NN-NN | NN | N | GUARD-02 | — | density/joyPerYen single-expression | grep/architecture | runs in full `flutter test` | ✅ existing guard | ⬜ pending |
| 47-NN-NN | NN | N | GUARD-04 | — | per-card goldens (≈30+) render deterministically | golden | `flutter test --tags golden` (macOS exact; CI existence) | ❌ NEW masters | ⬜ pending |
| 47-NN-NN | NN | N | GUARD-04 | — | full-page card-order scroll smoke | golden | `flutter test test/golden/analytics_screen_scroll_smoke_golden_test.dart` | ❌ NEW | ⬜ pending |
| 47-NN-NN | NN | N | GUARD-04 | — | HomeHero isolation preserved | widget | `flutter test test/widget/features/home/presentation/screens/home_screen_isolation_test.dart` | ✅ exists | ⬜ pending |
| 47-NN-NN | NN | N | GUARD-04 | — | full-suite gate green every wave | suite | `flutter test` (full) | ✅ harness | ⬜ pending |
| 47-NN-NN | NN | N | (WR-01) | — | `currencyCode` deleted; registry compiles; cards JPY-literal | unit/widget | `flutter test test/widget/features/analytics/presentation/analytics_card_registry_test.dart` | ✅ exists (update) | ⬜ pending |
| 47-NN-NN | NN | N | (WR-02) | — | center == true total; slices+legend reconcile under >10 L1 | unit/widget | new donut card test: `Σ(slices incl Other) == center` | ❌ NEW assertion | ⬜ pending |
| 47-NN-NN | NN | N | (WR-03) | T-46-* | single-pass aggregation; correct per-L1 amounts; aggregate-only ints (no per-tx logging) | unit | `flutter test test/.../get_joy_category_amounts_use_case_test.dart` | ✅ exists (update) | ⬜ pending |
| 47-NN-NN | NN | N | (WR-04) | — | pull-to-refresh re-fetches expanded day's list | widget | new test: pump calendar, expand day, invalidate, assert re-fetch | ❌ NEW | ⬜ pending |
| 47-NN-NN | NN | N | GUARD-05 | — | on-device visual UAT (D-10 checklist) | manual | physical iOS device, locale=ja; D-10 itemized checklist | ❌ manual | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/widget/features/analytics/presentation/widgets/anti_toxicity_phase47_test.dart` — GUARD-02-wording/GUARD-03 (5 cards × 3 langs × states)
- [ ] `test/golden/{category_donut,joy_spend,joy_calendar,satisfaction_histogram,within_month_trend}_card_golden_test.dart` — per-card goldens (GUARD-04)
- [ ] `test/golden/category_drill_down_screen_golden_test.dart` — drill screen golden (D-08①)
- [ ] `test/golden/family_insight_data_card_golden_test.dart` — group-mode card golden (D-08③)
- [ ] `test/golden/analytics_screen_scroll_smoke_golden_test.dart` — full-page card-order scroll smoke (D-07)
- [ ] `test/golden/goldens/*.png` — ≈30+ macOS baselines (author with `--update-goldens --tags golden` on macOS)
- [ ] WR-02 reconciliation assertion + WR-04 refresh test (new assertions on existing/new test files)
- [ ] Deterministic golden fixtures seeded from the 43-01 sample-data numbers (Dart fixtures — the data file is `.md`, not a Dart symbol)

*Framework install: none needed (`flutter_test` is bundled). count-up `TweenAnimationBuilder` goldens must pump to settled end-state.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| On-device visual UAT of redesigned analytics page | GUARD-05 | Real font/rendering/gesture fidelity cannot be asserted in widget tests; golden CI is existence-only off-macOS | Physical iOS device, locale=ja (zh/en spot-check). Run D-10 checklist: 5 cards render + count-up anchors (donut center + 悦己 header) + ring full-row drill-down + calendar inline expand + WR-02/WR-04 fixes visible + dark mode + 3-lang switch + group-mode family card. **Blocking (D-12)** — failures must be fixed + re-verified before v1.8 closeout. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (new test/golden files above)
- [ ] No watch-mode flags
- [ ] Feedback latency acceptable (scoped seconds / full suite minutes)
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
