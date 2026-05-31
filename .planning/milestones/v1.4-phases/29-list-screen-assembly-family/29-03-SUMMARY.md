---
phase: 29-list-screen-assembly-family
plan: "03"
subsystem: ui
tags: [flutter, riverpod, family-sync, member-attribution, filter-bar, shadow-books]

requires:
  - phase: 29-02
    provides: setMemberFilter() mutator on listFilterProvider + listMineOnly ARB key

provides:
  - Member attribution chip renders on shadow-book tile rows (FAM-02)
  - Family filter segment (Mine-only + per-member chips) in group mode (FAM-03/FAM-04)
  - anyFilterActive includes memberBookId so Clear chip shows when member filter active (Pitfall B)

affects:
  - 29-04 (list_screen.dart anyFilterActive must mirror this fix)
  - Phase 30 (golden baselines include member chip on tile rows)

tech-stack:
  added: []
  patterns:
    - "if (taggedTx.memberTag case final tag?) — pattern-match for nullable data; zero isOwn branch"
    - "if (isGroupMode) [...] family chip block — D-04 gating keeps solo mode byte-for-byte unchanged"
    - "shadowBooksAsync.when(data:, loading:, error:) spread into Row children list"

key-files:
  created: []
  modified:
    - lib/features/list/presentation/widgets/list_transaction_tile.dart
    - lib/features/list/presentation/widgets/list_sort_filter_bar.dart

key-decisions:
  - "anyFilterActive fix applied only in list_sort_filter_bar.dart (Task 2); list_screen.dart fix deferred to Plan 04 per plan scope"
  - "error callback uses explicit types (Object e, StackTrace s) to satisfy Dart lint (unnecessary_underscores + no_leading_underscores_for_local_identifiers)"
  - "Member chip positioned BEFORE amount, AFTER Expanded info column — amount stays rightmost alignment anchor"

patterns-established:
  - "Member attribution chip: ConstrainedBox(maxWidth:72) + Container(sharedLight bg, radius 3) + AppTextStyles.micro + TextOverflow.ellipsis"
  - "Family segment gating: final isGroupMode = ref.watch(isGroupModeProvider); if (isGroupMode) [...] — never conditionally watch shadowBooksProvider in D-04 compliant way"

requirements-completed: [FAM-02, FAM-03, FAM-04]

duration: 8min
completed: 2026-05-31
---

# Phase 29 Plan 03: Member Attribution Chip + Family Filter Segment Summary

**Member chip on shadow-book tile rows (AppColors.sharedLight/shared, maxWidth 72) plus Mine-only + per-member ActionChips in sort/filter bar, guarded by isGroupMode, with anyFilterActive 5th condition fix**

## Performance

- **Duration:** ~8 min
- **Started:** 2026-05-31T00:00Z
- **Completed:** 2026-05-31T00:08Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Member attribution chip renders on shadow-book tile rows using `if (taggedTx.memberTag case final tag?)` pattern — no isOwn branch, fully data-driven (D-01/SC#3/FAM-02)
- Family filter segment (Mine-only chip with Icons.person_outline + per-member chips from shadowBooksProvider) added to sort/filter bar, wrapped in `if (isGroupMode)` guard (D-04/CC-4/FAM-03/FAM-04)
- anyFilterActive 5th condition `|| filter.memberBookId != null` added so Clear chip appears when member filter is active (Pitfall B fix)
- All 15 targeted tests pass: 5 tile tests + 6 member bar tests + 4 existing bar tests (no regressions)

## Task Commits

Each task was committed atomically:

1. **Task 1: Member attribution chip in list_transaction_tile.dart** - `9b1f6958` (feat)
2. **Task 2: Family filter segment + anyFilterActive fix in list_sort_filter_bar.dart** - `6d2ef3f8` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified

- `lib/features/list/presentation/widgets/list_transaction_tile.dart` — Added ConstrainedBox(maxWidth:72) + Container(sharedLight bg, radius 3) member chip between Expanded info column and amount Text; conditional on memberTag null-check pattern
- `lib/features/list/presentation/widgets/list_sort_filter_bar.dart` — Added imports for state_active_group.dart + state_shadow_books.dart; Fix 1 (anyFilterActive 5th condition); Fix 2 (isGroupMode + shadowBooksAsync watch); family segment with Mine-only + per-member chips before Clear chip block

## Decisions Made

- `error` callback in `shadowBooksAsync.when(...)` uses explicit types `(Object e, StackTrace s)` to satisfy both `unnecessary_underscores` and `no_leading_underscores_for_local_identifiers` Dart lint rules
- anyFilterActive fix applied to list_sort_filter_bar.dart only in this plan; list_screen.dart mirror fix is explicitly scoped to Plan 04

## Deviations from Plan

None — plan executed exactly as written, with one minor lint-driven adjustment to the `error` callback parameter names (Rule 1 auto-fix, no behavioral change).

## Issues Encountered

One Dart lint issue on the `error: (_, __) => const []` closure pattern. Resolved inline by using `(Object e, StackTrace s)` explicit types which satisfies both the `unnecessary_underscores` and `no_leading_underscores_for_local_identifiers` lint rules.

## Known Stubs

None — all member chip and filter chip behavior is fully wired to live providers (shadowBooksProvider, isGroupModeProvider, listFilterProvider).

## Threat Flags

No new threat surface. T-29-03-02 (D-04 gating) is implemented: family chips render only when `isGroupModeProvider == true`, consistent with the threat register.

## Self-Check: PASSED

- `lib/features/list/presentation/widgets/list_transaction_tile.dart` — exists, modified
- `lib/features/list/presentation/widgets/list_sort_filter_bar.dart` — exists, modified
- Commit `9b1f6958` — exists (feat: member attribution chip)
- Commit `6d2ef3f8` — exists (feat: family filter segment + anyFilterActive fix)
- All 15 tests pass: `flutter test test/widget/features/list/list_transaction_tile_test.dart test/widget/features/list/list_sort_filter_bar_member_test.dart test/widget/features/list/list_sort_filter_bar_test.dart --no-pub` → All tests passed!
- `flutter analyze lib/features/list/presentation/widgets/` → No issues found

## Next Phase Readiness

- Plan 04 (list_screen.dart): RefreshIndicator + anyFilterActive mirror fix + group-mode gating for isGroupModeProvider in list_screen.dart — ready to execute
- The `list_screen_refresh_test.dart` Phase 29 group remains RED (expected — those tests target Plan 04 changes)

---
*Phase: 29-list-screen-assembly-family*
*Completed: 2026-05-31*
