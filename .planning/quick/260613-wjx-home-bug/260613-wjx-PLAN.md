---
quick_id: 260613-wjx
title: Fix Home recent-items edit — save quantity / delete not reflected
mode: quick
status: planned
date: 2026-06-13
---

# Quick Task 260613-wjx

修复 Home 首页"最近项"的 bug：从最近项点击进入编辑后，修改数量和删除都没有生效。

## Root cause (verified)

`lib/features/home/presentation/screens/home_screen.dart:340-345` — the recent-items
`HomeTransactionTile.onTap` fires `Navigator.push` **fire-and-forget**: it never awaits the
`bool` result and never invalidates the providers that feed the Home list. So edits/deletes
**are persisted to the DB**, but `todayTransactionsProvider` keeps serving its cached value,
making the change look like it "didn't take effect" until the screen is rebuilt from scratch.

The List screen does it correctly (`list_screen.dart:324-342`): it awaits the push result and
calls `invalidateTransactionDependents(...)` when `result == true`. `TransactionEditScreen`
intentionally `pop(true)` on both save (`_save`) and delete (`_onDelete`) and delegates
invalidation to the caller. The Home caller never honored that contract — a regression from the
recent edit-flow refactors.

## Task 1 — Fix Home onTap to honor the pop-with-result contract

**Files:** `lib/features/home/presentation/screens/home_screen.dart`

**Action:**
- Add import: `../../../../shared/utils/invalidate_transaction_dependents.dart`
- Replace the fire-and-forget `onTap` (lines 340-345) with an async handler that awaits the
  `bool` result and, on `result == true`, calls
  `invalidateTransactionDependents(ref, bookId: bookId, year: year, month: month)`.
  Wrap in try/catch and `FlutterError.reportError` to avoid an unhandled-future on the
  `onTap: () async` closure — mirror `list_screen.dart`'s WR-03 pattern.
- `ref`, `bookId`, `year`, `month` are all already in scope at the tile build site.

**Verify:** `flutter analyze` → 0 new issues.
**Done:** Home onTap awaits result and invalidates `todayTransactionsProvider` (+ list/calendar/analytics) on save or delete.

## Task 2 — Regression test

**Files:**
- `test/widget/features/home/presentation/screens/home_screen_test.dart` (add test)
- `test/widget/features/home/presentation/screens/home_tap_to_edit_test.dart` (fix stale "exactly reproduces home_screen wiring" comment)

**Action:** In the real-`HomeScreen` harness, override `todayTransactionsProvider` with a
counting builder, tap a recent tile to push `TransactionEditScreen`, pop it with `true`
(the edit screen's save/delete contract), pump, and assert the provider was re-fetched
(counter incremented) — i.e. the Home list refreshes. Add edit-screen provider overrides
(`categoryRepositoryProvider`, `categoryServiceProvider`, `updateTransactionUseCaseProvider`)
so the pushed screen builds.

**Verify:** the new test FAILS against the old wiring, PASSES after Task 1.
**Done:** Regression test green; full home test files green.

## must_haves
- truths:
  - Home recent-item edit (modify quantity) reflects immediately on the Home list.
  - Home recent-item delete reflects immediately on the Home list.
  - `invalidateTransactionDependents` invoked from the Home onTap when edit returns true.
- artifacts:
  - `lib/features/home/presentation/screens/home_screen.dart` (await + invalidate)
  - regression test in `home_screen_test.dart`
- key_links:
  - `lib/shared/utils/invalidate_transaction_dependents.dart`
  - `lib/features/list/presentation/screens/list_screen.dart` (reference pattern)
