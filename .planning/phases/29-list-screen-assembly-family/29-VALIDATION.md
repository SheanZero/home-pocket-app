---
phase: 29
slug: list-screen-assembly-family
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-30
---

# Phase 29 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Flutter Test (built-in) + Mocktail |
| **Config file** | none — `flutter test` runs automatically |
| **Quick run command** | `flutter test test/unit/features/list/ test/widget/features/list/ --no-pub` |
| **Full suite command** | `flutter test --no-pub` |
| **Estimated runtime** | ~30–60 seconds (scoped list tests); full suite longer |

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/unit/features/list/ test/widget/features/list/ --no-pub`
- **After every plan wave:** Run `flutter test --no-pub`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** ~60 seconds (scoped list tests)

---

## Per-Task Verification Map

| Req ID | Behavior | Test Type | Automated Command | File Exists |
|--------|----------|-----------|-------------------|-------------|
| LIST-04 | `RefreshIndicator.onRefresh` invalidates list + calendar providers; spinner completes | Widget | `flutter test test/widget/features/list/list_screen_refresh_test.dart` | ❌ W0 |
| FAM-01 | Group mode: `listTransactionsProvider` includes own + shadow book rows; solo mode: own-only | Unit (provider) | `flutter test test/unit/features/list/presentation/providers/list_transactions_provider_test.dart` | ✅ (extends) |
| FAM-01 | Calendar daily totals = sum over all books in group mode; ignores `memberBookId` | Unit (provider) | `flutter test test/unit/features/list/presentation/providers/calendar_totals_provider_test.dart` | ✅ (extends) |
| FAM-02 | Shadow-book rows get `memberTag != null`; own-book rows get `memberTag == null` | Unit (provider) | `flutter test test/unit/features/list/presentation/providers/list_transactions_provider_test.dart` | ✅ (extends) |
| FAM-02 | Member chip renders on tile when `memberTag != null`; absent (bare) when null | Widget | `flutter test test/widget/features/list/list_transaction_tile_test.dart` | ✅ (extends) |
| FAM-03 | `setMemberFilter(shadowBookId)` narrows list to that book; AND-composes with ledger/category | Unit (provider) | `flutter test test/unit/features/list/presentation/providers/list_transactions_provider_test.dart` | ✅ (extends) |
| FAM-03 | Member filter active → `anyFilterActive == true` → Clear chip visible + filtered-empty shown | Widget | `flutter test test/widget/features/list/list_sort_filter_bar_member_test.dart` | ❌ W0 |
| FAM-04 | `setMemberFilter(ownBookId)` shows only own rows; re-tap clears to All | Unit (provider) | `flutter test test/unit/features/list/presentation/providers/list_transactions_provider_test.dart` | ✅ (extends) |
| FAM-04 | Mine-only chip always visible in group mode regardless of other filters | Widget | `flutter test test/widget/features/list/list_sort_filter_bar_member_test.dart` | ❌ W0 |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/widget/features/list/list_screen_refresh_test.dart` — covers LIST-04 (RefreshIndicator fires invalidate, spinner completes)
- [ ] `test/widget/features/list/list_sort_filter_bar_member_test.dart` — covers FAM-03/FAM-04 (member chips render per `shadowBooksProvider`, Mine-only always visible in group mode, `anyFilterActive` includes `memberBookId`, Clear chip visible on member filter)
- New test cases to ADD to existing files:
  - `list_transactions_provider_test.dart`: group mode returns merged rows; shadow rows get `memberTag`; own rows get null `memberTag`; SQL member-filter narrowing; Mine-only = own-book only
  - `calendar_totals_provider_test.dart`: group mode sums per-book day totals; calendar ignores `memberBookId`
  - `list_transaction_tile_test.dart`: member chip renders + truncates; absent on own rows

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Pull-to-refresh gesture reflects entries synced from another device | LIST-04 / SC#1 | Cross-device P2P sync timing not reproducible in unit/widget tests | Two paired devices in a family group; add entry on device B; pull-to-refresh on device A; confirm new entry + updated month total appear |
| Member chip color is visually distinguishable from ledger tag | FAM-02 / SC#3 | Visual judgment against Wa-Modern theme | Group mode list with mixed own + member rows; confirm member chip uses distinct accent from survival/soul ledger tags |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (2 new widget test files)
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
