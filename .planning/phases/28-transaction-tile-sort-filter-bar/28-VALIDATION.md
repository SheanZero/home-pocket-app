---
phase: 28
slug: transaction-tile-sort-filter-bar
status: approved
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-30
---

# Phase 28 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `flutter_test` (Flutter SDK) + Mocktail |
| **Config file** | none — standard `flutter test` (no external config file) |
| **Quick run command** | `flutter test test/unit/features/list/ && flutter test test/widget/features/list/` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~45 seconds (unit: ~10s, widget: ~35s, full suite: ~45s) |

---

## Sampling Rate

- **After every task commit:** `flutter analyze && flutter test test/unit/features/list/`
- **After every plan wave:** `flutter test` (full suite)
- **Before `/gsd-verify-work`:** Full suite must be green AND `flutter analyze` 0 issues
- **Max feedback latency:** ~45 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 28-01-T1 | 01 | 1 | FILTER-03, D-01 | T-28-01-01 | categoryIds.contains() — in-memory Dart, no SQL injection | unit | `flutter pub run build_runner build --delete-conflicting-outputs && flutter analyze` | ✅ (source) ❌ W0 (test) | ⬜ pending |
| 28-01-T2 | 01 | 1 | LIST-01, FILTER-01..04 | T-28-01-02 | ARB keys — locale strings, no PII | analyze | `flutter gen-l10n && flutter analyze` | ✅ | ⬜ pending |
| 28-02-T1 | 02 | 1 | ROW-02, FILTER-03, D-01 | T-28-02-01 | Synthetic test data — no real financial data on disk | unit (stub) | `flutter analyze test/unit/features/list/ && flutter test test/unit/features/list/list_filter_notifier_test.dart --no-pub 2>&1 \| grep -E "(FAIL\|ERROR)"` | ❌ W0 | ⬜ pending |
| 28-02-T2 | 02 | 1 | ROW-01, ROW-02, SORT-01..04, FILTER-01..04 | T-28-02-01 | Synthetic test fixtures | widget (stub) | `flutter analyze test/widget/features/list/ 2>&1 \| grep -v "Couldn't resolve" \| grep -E "(error\|warning)"` | ❌ W0 | ⬜ pending |
| 28-03-T1 | 03 | 2 | LIST-01, ROW-01, ROW-02 | T-28-03-01, T-28-03-02 | Delete via deleteTransactionUseCaseProvider only (hash-chain); Transaction object never serialized to route | widget | `flutter test test/widget/features/list/list_transaction_tile_test.dart && flutter analyze lib/features/list/presentation/widgets/list_transaction_tile.dart` | ❌ W0 | ⬜ pending |
| 28-03-T2 | 03 | 2 | LIST-01, D-09 | — | Day-group sort direction must mirror sortConfig (Pitfall 4) | unit | `flutter test test/unit/features/list/list_grouping_test.dart && flutter analyze lib/features/list/presentation/widgets/list_day_group_header.dart` | ❌ W0 | ⬜ pending |
| 28-04-T1 | 04 | 2 | FILTER-03, D-02 | T-28-04-01 | setCategories writes L2 leaf Set only; no cross-book data; no duplicate repository_providers.dart | widget | `flutter test test/widget/features/list/list_category_filter_sheet_test.dart && flutter analyze lib/features/list/presentation/widgets/list_category_filter_sheet.dart` | ❌ W0 | ⬜ pending |
| 28-04-T2 | 04 | 2 | LIST-01, FILTER-04 | — | clearAll() is safe; no leakage of financial data in empty state placeholder | widget | `flutter test test/widget/features/list/list_empty_state_test.dart && flutter analyze lib/features/list/presentation/widgets/list_empty_state.dart` | ❌ W0 | ⬜ pending |
| 28-05-T1 | 05 | 3 | SORT-01..04, FILTER-01..04 | T-28-05-01, T-28-05-02 | searchQuery in-memory only; sort chip must NOT show generic "Sort" (SC#4); keepAlive filter is own-book | widget | `flutter test test/widget/features/list/list_sort_filter_bar_test.dart && flutter analyze lib/features/list/presentation/widgets/list_sort_filter_bar.dart` | ❌ W0 | ⬜ pending |
| 28-06-T1a | 06 | 4 | LIST-01, ROW-01, ROW-02, SORT-01..04, FILTER-01..04 | T-28-06-01..04 | No new decryption path; Transaction never serialized to route; calendarDailyTotalsProvider invalidated on edit/delete (Open Q#2) | widget | `flutter analyze lib/features/list/presentation/screens/list_screen.dart && flutter test test/widget/features/list/ 2>&1 \| tail -10` | ✅ (existing) | ⬜ pending |
| 28-06-T1b | 06 | 4 | LIST-01, ROW-01 | T-28-06-01, T-28-06-02 | formattedAmount via NumberFormatter (not raw string); merchant/note — decrypted domain model only; calendarDailyTotalsProvider invalidated (UI-SPEC C-04 step 5) | widget | `flutter analyze lib/features/list/presentation/screens/list_screen.dart && flutter test test/widget/features/list/` | ✅ (existing) | ⬜ pending |
| 28-06-T2 | 06 | 4 | ROW-02, D-01 | T-28-06-04 | Delete path MUST use DeleteTransactionUseCase (hash-chain + sync hooks); direct DAO bypass detected by provider_graph_hygiene_test | unit | `flutter test test/unit/features/list/delete_hash_chain_integrity_test.dart test/unit/features/list/list_filter_notifier_test.dart && flutter test` | ❌ W0 | ⬜ pending |
| 28-07-T1 | 07 | 5 | ALL (LIST-01, ROW-01, ROW-02, SORT-01..04, FILTER-01..04) | T-28-07-01 | Real transaction data visible in simulator — developer device only; no network | automated-gate | `flutter analyze && flutter test && flutter build ios --debug --no-codesign 2>&1 \| tail -5` | ✅ | ⬜ pending |
| 28-07-T2 | 07 | 5 | ALL | T-28-07-01 | SC#1..5 user-observable behaviors — human confirms in running app | human-verify | (see 28-07 checkpoint: 21 behavioral checks) | n/a | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Wave 0 test stubs are created in Plan 28-02 (Wave 1, parallel with Plan 28-01). The following files must exist before any Wave 2+ implementation task begins:

- [ ] `test/unit/features/list/list_filter_notifier_test.dart` — stubs for D-01: setCategories, toggleCategory, clearAll, immutability (5 tests)
- [ ] `test/unit/features/list/delete_hash_chain_integrity_test.dart` — stub for ROW-02 SC#3: soft-delete + verifyChain valid (1 test, RED with fail() body)
- [ ] `test/unit/features/list/list_grouping_test.dart` — stubs for buildFlatList asc/desc day-ordering behavior (2 tests, B3 Nyquist gap)
- [ ] `test/widget/features/list/list_transaction_tile_test.dart` — stubs for ROW-01 tap navigation and ROW-02 swipe+confirm dialog
- [ ] `test/widget/features/list/list_sort_filter_bar_test.dart` — stubs for SORT-01..04 + FILTER-01..04 SC#4 and chip interactions
- [ ] `test/widget/features/list/list_category_filter_sheet_test.dart` — stubs for FILTER-03 D-02 Apply flow, L1→L2 cascade, tristate rendering (3 tests, B2 requirement)
- [ ] `test/widget/features/list/list_empty_state_test.dart` — stubs for ListEmptyState isFilterActive: false and isFilterActive: true render paths (2 tests, B3 requirement)

*All 7 files created in Wave 1 (Plan 28-02). Tests are RED (fail) — this is expected.*

---

## Manual-Only Verifications

The following behaviors are verified by the human checkpoint in Plan 28-07 Task 2. They require a running app (Flutter simulator or device) and cannot be automated with widget tests.

| Behavior | Requirement | Why Manual | Test Instructions (from 28-07 checkpoint) |
|----------|-------------|------------|-------------------------------------------|
| SC#1: Tile display — ledger-color tag, category, tabular-figure amount, time slot | LIST-01 | Tabular figure alignment and visual correctness cannot be asserted in `flutter test` (font rendering varies) | Steps 1–3 in 28-07 checkpoint |
| SC#2: Tap-to-edit → list reflects update without manual refresh | ROW-01 | Requires live navigation flow and data reactivity visible in running app | Steps 4–5 in 28-07 checkpoint |
| SC#3: Swipe-delete flow — red background, dialog, SnackBar | ROW-02 | Dismissible animation and gesture threshold must be verified visually; SnackBar timing is runtime-only | Steps 6–9 in 28-07 checkpoint |
| SC#4: Sort chip shows field name, popup checkmark, direction arrow | SORT-01..04 | Sort popup menu positioning and visual state require running app; chip label locale depends on device locale | Steps 10–13 in 28-07 checkpoint |
| SC#5: Category sheet L1/L2 hierarchy, tristate checkboxes, apply → list filters | FILTER-03, D-02 | Modal bottom sheet visual layout and tristate Checkbox rendering require running app | Steps 16–17 in 28-07 checkpoint |

**Sampling rate for manual checks:** All 5 scenarios verified in a single 28-07 checkpoint session (steps 1–21). No sampling — full pass required.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive implementation tasks lack an automated behavioral test
  - 28-03 T2 (buildFlatList): `flutter test test/unit/features/list/list_grouping_test.dart` (B3 fix)
  - 28-04 T1 (CategoryFilterSheet): `flutter test test/widget/features/list/list_category_filter_sheet_test.dart` (B2 fix)
  - 28-04 T2 (ListEmptyState): `flutter test test/widget/features/list/list_empty_state_test.dart` (B3 fix)
- [x] Wave 0 covers all MISSING references (7 stub files in 28-02)
- [x] No watch-mode flags in any automated command
- [x] Feedback latency < 45s (unit suite ~10s, widget suite ~35s)
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-30
