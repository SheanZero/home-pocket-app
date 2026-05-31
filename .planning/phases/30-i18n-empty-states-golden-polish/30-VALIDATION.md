---
phase: 30
slug: i18n-empty-states-golden-polish
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-31
---

# Phase 30 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test (Flutter SDK) |
| **Config file** | none — no `flutter_test_config.dart`; each test self-contained |
| **Quick run command** | `flutter test test/golden/list_empty_state_golden_test.dart` |
| **Full suite command** | `flutter test --coverage` |
| **Estimated runtime** | ~60–120 seconds (full suite) |

---

## Sampling Rate

- **After every task commit:** Run `flutter analyze` + the relevant widget/golden test file
- **After every plan wave:** Run `flutter test --coverage` (full suite)
- **Before `/gsd-verify-work`:** Full suite green + `build_runner` diff clean
- **Max feedback latency:** ~120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| (ARB) | i18n | early | D-06/D-07/D-09/D-12/D-13 | — | N/A | architecture | `flutter test test/architecture/arb_key_parity_test.dart` | ✅ | ⬜ pending |
| (ARB) | i18n | early | D-09 | — | N/A | static | `flutter gen-l10n && flutter analyze --no-fatal-infos` | ✅ | ⬜ pending |
| (widget) | empty-state | mid | LIST-03 | — | N/A | widget | `flutter test test/widget/features/list/list_empty_state_test.dart` | ✅ needs update | ⬜ pending |
| (provider) | empty-state | mid | LIST-03 (day-only clear) | — | N/A | unit | `flutter test test/unit/features/list/presentation/providers/list_filter_notifier_test.dart` | ✅ needs day-only case | ⬜ pending |
| (golden) | goldens | late | LIST-03 / D-01 / D-02 / D-03 | — | N/A | golden | `flutter test test/golden/list_empty_state_golden_test.dart` | ❌ W0 | ⬜ pending |
| (golden) | goldens | late | D-01 / D-03 (calendar determinism) | — | N/A | golden | `flutter test test/golden/list_calendar_header_golden_test.dart` | ❌ W0 | ⬜ pending |
| (CI gate) | ci-gate | final | D-10 / D-11 | — | N/A | static+coverage | `flutter analyze` · `dart run custom_lint --no-fatal-infos` · `build_runner build` diff · `flutter test --coverage` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

All 6 golden test files are new and must be created with `--update-goldens` baseline generation:

- [ ] `test/golden/list_transaction_tile_golden_test.dart` — 3 locales = 3 PNGs
- [ ] `test/golden/list_day_group_header_golden_test.dart` — 3 locales = 3 PNGs
- [ ] `test/golden/list_sort_filter_bar_golden_test.dart` — 3 locales = 3 PNGs
- [ ] `test/golden/list_empty_state_golden_test.dart` — 3 variants × 3 locales = 9 PNGs
- [ ] `test/golden/list_calendar_header_golden_test.dart` — 3 locales = 3 PNGs (determinism: pin `listFilterProvider` to Jan 2025)
- [ ] `test/golden/list_category_filter_sheet_golden_test.dart` — 3 locales = 3 PNGs
- [ ] Update `test/widget/features/list/list_empty_state_test.dart` — migrate from binary `isFilterActive:` to `variant: ListEmptyVariant` (noData/dayEmpty/filtered)
- [ ] Add day-only-clear case to `test/unit/features/list/presentation/providers/list_filter_notifier_test.dart` — `selectDay(null)` preserves ledgerType, categoryIds, searchQuery, memberBookId

Baseline generation command (run once per file after UI is final):
`flutter test test/golden/<file>.dart --update-goldens` — commit resulting PNGs in `test/golden/goldens/`.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Empty-state copy reads naturally per locale | D-04/D-06 | Native-language nuance; goldens verify layout not phrasing quality | Verified at discuss-phase — copy locked verbatim to D-04 table; no further manual check needed |

*All structural/behavioral phase requirements have automated verification (golden + widget + unit + architecture + CI gate).*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (6 golden files + 2 test updates)
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
