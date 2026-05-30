---
phase: 29-list-screen-assembly-family
plan: "02"
subsystem: list-providers
tags: [family, providers, riverpod, i18n, FAM-01, FAM-02, FAM-03, FAM-04]
dependency_graph:
  requires: [29-01]
  provides: [29-03, 29-04]
  affects: [state_list_transactions, state_calendar_totals, l10n]
tech_stack:
  added: []
  patterns: [shadow-book-fan-out, per-book-loop-merge, member-filter-narrowing]
key_files:
  created: []
  modified:
    - lib/features/list/presentation/providers/state_list_transactions.dart
    - lib/features/list/presentation/providers/state_calendar_totals.dart
    - lib/l10n/app_en.arb
    - lib/l10n/app_ja.arb
    - lib/l10n/app_zh.arb
decisions:
  - "SQL-level member filter narrowing via effectiveBookIds (D-02) — avoids Dart-side post-filter inconsistency"
  - "bookIdToShadow map built once per provider invocation for O(1) memberTag lookup (D-01)"
  - "calendarDailyTotalsProvider NEVER watches listFilterProvider — Pitfall 3 / D-06 compliance enforced"
metrics:
  duration_minutes: 3
  completed_date: "2026-05-30"
  tasks_completed: 2
  tasks_total: 2
  files_changed: 5
---

# Phase 29 Plan 02: Family-Aware Providers — Multi-Book Fan-Out + ARB Key Summary

Family-aware expansion of both list providers: `state_list_transactions.dart` fans out bookIds to include shadow books in group mode, fills `memberTag` per shadow lookup, and narrows SQL-level via `effectiveBookIds`; `state_calendar_totals.dart` loops per-book `getDailyTotals` and sums daily maps; `listMineOnly` ARB key added to all 3 locale files.

## Tasks Completed

### Task 1: Expand state_list_transactions.dart (FAM-01/02/03/04)

Replaced the `final bookIds = [bookId];` seam (Step 3) with full group-mode fan-out:
- `isGroupModeProvider` watched synchronously (keepAlive)
- `shadowBooksProvider.future` awaited in group mode; `const <ShadowBookInfo>[]` in solo
- `bookIds = [bookId, ...shadowBookList.map((s) => s.book.id)]` fan-out
- `bookIdToShadow = {for (final s in shadowBookList) s.book.id: s}` lookup map
- `effectiveBookIds` narrows to `[memberBookId]` when `filter.memberBookId != null` and the ID is in `bookIds`; passes `const <String>[]` if not found (D-02 SQL-level narrowing)
- `GetListParams.bookIds` updated to use `effectiveBookIds` (not unfiltered `bookIds`)

Replaced Step 7 `.map((tx) => TaggedTransaction(transaction: tx, memberTag: null))` with shadow lookup:
- `bookIdToShadow[tx.bookId]` returns null for own-book rows → `memberTag: null` (D-01/SC#3)
- Non-null shadow → `MemberTag(emoji: shadow.memberAvatarEmoji, name: shadow.memberDisplayName)` (FAM-02)

Added imports: `state_active_group.dart`, `state_shadow_books.dart`.

**Result:** All 15 tests in `list_transactions_provider_test.dart` pass including all 6 Phase 29 group tests (FAM-01/02/03/04 + D-01 + D-04).

### Task 2: Expand state_calendar_totals.dart + ARB listMineOnly (D-06, Pitfall 3)

Replaced the single-book provider body seam with per-book loop:
- `isGroupModeProvider` watched (NEVER `listFilterProvider` — Pitfall 3 / D-06)
- `shadowBooksProvider.future` awaited in group mode; empty in solo
- `allBookIds = [bookId, ...shadows.map((s) => s.book.id)]`
- Per-book `repo.getDailyTotals(bookId: bid, ...)` loop; `merged[k] = (merged[k] ?? 0) + t.totalAmount` accumulation
- Provider signature `(bookId, year, month)` UNCHANGED — confirmed by caller inspection

Added `listMineOnly: "Mine only"` to `app_en.arb`, `app_ja.arb`, `app_zh.arb` after `listClearAll`. `flutter gen-l10n` succeeded.

**Result:** All 10 tests in `calendar_totals_provider_test.dart` pass including all 3 Phase 29 group tests. `arb_key_parity_test` passes.

## Verification

1. `flutter analyze lib/features/list/presentation/providers/` — 0 issues
2. `flutter test ...list_transactions_provider_test.dart ...calendar_totals_provider_test.dart --no-pub` — 23/23 passed
3. `flutter test test/architecture/arb_key_parity_test.dart --no-pub` — passed
4. `flutter gen-l10n` — 0 warnings
5. `grep -n "listFilterProvider" state_calendar_totals.dart` — 0 lines (only in docstring comment)
6. `calendarDailyTotalsProvider` call signatures in `list_screen.dart` and `list_calendar_header.dart` unchanged

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None. All data is properly wired: shadow books are fetched from `shadowBooksProvider`, member tags are built from `ShadowBookInfo.memberAvatarEmoji` / `memberDisplayName`, and `listMineOnly` ARB values are placeholder English strings per spec (ja and zh will be localized in Phase 30 / i18n polish).

## Threat Flags

None. No new network endpoints, auth paths, or trust boundary crossings introduced. `bookIdToShadow` is keyed only on shadow book IDs (T-29-02-01 accepted per plan threat model); own-book rows cannot appear as shadow keys (T-29-02-02 mitigated by key construction logic).

## Self-Check: PASSED

Files confirmed:
- `lib/features/list/presentation/providers/state_list_transactions.dart` — FOUND (modified, 15 tests GREEN)
- `lib/features/list/presentation/providers/state_calendar_totals.dart` — FOUND (modified, 10 tests GREEN)
- `lib/l10n/app_en.arb` — FOUND (listMineOnly key present)
- `lib/l10n/app_ja.arb` — FOUND (listMineOnly key present)
- `lib/l10n/app_zh.arb` — FOUND (listMineOnly key present)

Commits confirmed:
- `197ca242` — Task 1: feat(29-02): expand listTransactionsProvider
- `37143115` — Task 2: feat(29-02): expand calendarDailyTotalsProvider + ARB
