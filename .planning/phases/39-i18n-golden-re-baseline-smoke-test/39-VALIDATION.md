---
phase: 39
slug: i18n-golden-re-baseline-smoke-test
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-08
---

# Phase 39 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test (SDK-bundled) |
| **Config file** | none — tests invoked via `flutter test` |
| **Quick run command** | `flutter test test/golden/shopping_*_golden_test.dart test/integration/presentation/shopping_provider_smoke_test.dart --tags golden` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~120 seconds (full suite); ~20s (shopping golden + smoke subset) |

---

## Sampling Rate

- **After every task commit:** Run `flutter analyze && flutter test test/golden/shopping_*_golden_test.dart test/integration/presentation/shopping_provider_smoke_test.dart --tags golden`
- **After every plan wave:** Run `flutter test` (full suite — catches architecture tests like `hardcoded_cjk_ui_scan`)
- **Before `/gsd-verify-work`:** Full suite must be green + `flutter analyze` 0 issues
- **Max feedback latency:** ~120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 39-01 (i18n rename) | 01 | 1 | NAV-03 (SC1/SC2) | — | N/A | shell gate | `grep -rn 'homeTabTodo\|todoTab\|待办\|Todo' lib/l10n/` returns 0 hits; `jq 'keys\|length' lib/l10n/app_{ja,zh,en}.arb` all equal; `flutter gen-l10n` 0 warnings | ✅ existing ARBs | ⬜ pending |
| 39-01 (nav test update) | 01 | 1 | NAV-03 (SC2) | — | N/A | widget | `flutter test test/widget/features/shopping_list/presentation/widgets/home_bottom_nav_bar_shopping_test.dart` | ✅ exists (asserts stale label — must update) | ⬜ pending |
| 39-02 (empty goldens) | 02 | 2 | NAV-03 (SC3) | T-39-01 | private items never in public golden fixtures | golden | `flutter test test/golden/shopping_empty_state_golden_test.dart --tags golden` | ❌ W0 | ⬜ pending |
| 39-03 (tile goldens) | 03 | 2 | NAV-03 (SC3) | — | N/A | golden | `flutter test test/golden/shopping_item_tile_golden_test.dart --tags golden` | ❌ W0 | ⬜ pending |
| 39-04 (filter bar golden) | 04 | 2 | NAV-03 (SC3) | — | N/A | golden | `flutter test test/golden/shopping_filter_bar_golden_test.dart --tags golden` | ❌ W0 | ⬜ pending |
| 39-05 (batch chrome golden) | 05 | 2 | NAV-03 (SC3) | — | N/A | golden | `flutter test test/golden/shopping_batch_chrome_golden_test.dart --tags golden` | ❌ W0 | ⬜ pending |
| 39-06 (provider smoke) | 06 | 2 | NAV-03 (SC4) | T-39-01 | private item excluded from public StreamProvider emission | integration | `flutter test test/integration/presentation/shopping_provider_smoke_test.dart` | ❌ W0 | ⬜ pending |
| 39-07 (quality gate) | 07 | 3 | NAV-03 (SC5) | — | N/A | static + coverage | `flutter analyze` 0 issues; `flutter test --coverage` ≥70% on `lib/features/shopping_list/` + `lib/application/shopping_list/` | ✅ existing CI | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*
*Task IDs / wave assignment are indicative — the planner owns final plan/wave decomposition.*

---

## Wave 0 Requirements

New golden + smoke test files this phase introduces (created before baselines exist):

- [ ] `test/golden/shopping_empty_state_golden_test.dart` — SC3: 3 empty variants (private / public-solo / public-family) × 3 locales × 2 modes
- [ ] `test/golden/shopping_item_tile_golden_test.dart` — SC3: active (daily border) + completed (joy border, strikethrough+fade) + attribution chip × 3 locales × 2 modes
- [ ] `test/golden/shopping_filter_bar_golden_test.dart` — SC3: filter-active state × 3 locales × 2 modes
- [ ] `test/golden/shopping_batch_chrome_golden_test.dart` — SC3: selection header + bottom batch action bar × 3 locales × 2 modes
- [ ] `test/integration/presentation/shopping_provider_smoke_test.dart` — SC4: reactive emit without `ref.invalidate` + private-item-excluded re-assertion
- [ ] `test/golden/goldens/shopping_*.png` — baseline PNGs generated via `flutter test --update-goldens` once test code lands

*Existing infrastructure (`flutter_test`, golden harness, `waitForFirstValue` helper) covers all framework needs — no installs required.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visual correctness of generated golden baselines | NAV-03 (SC3) | First-time baselines have no prior reference; a human must confirm the rendered PNGs look right before they become the source of truth | After `--update-goldens`, visually inspect `test/golden/goldens/shopping_*.png` for correct locale text, dark-mode palette (`AppPalette.dark`), dual-ledger border colors, strikethrough on completed tile, before committing |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
