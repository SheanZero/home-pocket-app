---
phase: 38-presentation-shell-ui-widgets
plan: "02"
subsystem: ui
tags: [riverpod, flutter, shopping-list, providers, state-management, freezed]

requires:
  - phase: 38-01
    provides: ShoppingListFilter domain model with categoryIds field; import_guard.yaml; test infra skeleton

provides:
  - listTypeProvider (keepAlive:true) — current segment ('public'|'private'), resets filter on switch (D5/FILT-02)
  - shoppingFilterProvider (keepAlive:true) — ShoppingListFilter state with setLedgerFilter/setStatusFilter/setCategoryIds/clearAll/resetForNewSegment
  - batchSelectModeProvider (transient, app-root scope) — BatchSelectModeState Freezed model with enter/toggle/selectAll/exit
  - 6 use-case providers (createShoppingItemUseCaseProvider through clearCompletedItemsUseCaseProvider)
  - filteredShoppingItemsProvider StreamProvider — watchByListType + client-side filter (D38-04 Pitfall 5)

affects:
  - 38-03 (shell wiring, screens, widgets depend on all 7 providers in this plan)
  - 38-04 (form screen uses createShoppingItemUseCaseProvider + updateShoppingItemUseCaseProvider)
  - 38-05+ (batch action bar reads batchSelectModeProvider, filter bar reads shoppingFilterProvider)

tech-stack:
  added: []
  patterns:
    - keepAlive: true on segment + filter providers (IndexedStack tab-switch persistence, SC2)
    - Riverpod 3 suffix-stripping (class ListType → listTypeProvider, class ShoppingFilter → shoppingFilterProvider, class BatchSelectMode → batchSelectModeProvider)
    - D5/FILT-02 filter reset: setListType calls ref.read(shoppingFilterProvider.notifier).resetForNewSegment()
    - D38-03 batch scope: batchSelectModeProvider never wrapped in local ProviderScope
    - D38-04 Pitfall 5: filteredShoppingItemsProvider applies client-side filter on Drift stream, never calls ref.invalidate
    - D37-01: reorderShoppingItemsUseCaseProvider wired with repository ONLY (no changeTracker/syncEngine)

key-files:
  created:
    - lib/features/shopping_list/presentation/providers/state_shopping_filter.dart
    - lib/features/shopping_list/presentation/providers/state_shopping_filter.g.dart
    - lib/features/shopping_list/presentation/providers/state_shopping_batch.dart
    - lib/features/shopping_list/presentation/providers/state_shopping_batch.freezed.dart
    - lib/features/shopping_list/presentation/providers/state_shopping_batch.g.dart
  modified:
    - lib/features/shopping_list/presentation/providers/repository_providers.dart
    - lib/features/shopping_list/presentation/providers/repository_providers.g.dart
    - test/unit/features/shopping_list/providers/state_shopping_filter_test.dart
    - test/widget/features/shopping_list/helpers/mock_use_cases.dart

key-decisions:
  - "listTypeProvider and shoppingFilterProvider both keepAlive:true (IndexedStack tab-switch persistence SC2)"
  - "batchSelectModeProvider is NOT keepAlive — transient, resets when provider is no longer watched (D38-03)"
  - "filteredShoppingItemsProvider uses Stream.map client-side filter; never ref.invalidate; reactive delivery via Drift .watch() (D38-04 / SC-5)"
  - "reorderShoppingItemsUseCaseProvider wired with repository only — no sync deps (D37-01 local-only reorder)"
  - "BatchSelectModeState defined as Freezed model in same file as BatchSelectMode notifier"

patterns-established:
  - "keepAlive notifier with cross-provider reset: setListType() calls ref.read(otherProvider.notifier).method()"
  - "Derived StreamProvider over Drift stream with .map() client-side filter (D38-04 Pitfall 5 pattern)"
  - "ProviderContainer.test() with listen() for keepAlive retention verification in unit tests"

requirements-completed: [FILT-02, NAV-01, MGMT-02, MGMT-03, DONE-03, ITEM-01, ITEM-02, ITEM-04]

duration: 9min
completed: 2026-06-08
---

# Phase 38 Plan 02: Provider Graph Summary

**Riverpod 3 keepAlive + transient + derived StreamProvider graph wiring all 6 shopping-list use cases with D5/FILT-02 segment-switch filter reset and client-side stream filter**

## Performance

- **Duration:** ~9 min
- **Started:** 2026-06-08T11:34:48Z
- **Completed:** 2026-06-08T11:43:45Z
- **Tasks:** 2
- **Files modified:** 9

## Accomplishments

- Created `state_shopping_filter.dart` — `listTypeProvider` (keepAlive, default 'private') + `shoppingFilterProvider` (keepAlive), with `setListType` automatically calling `resetForNewSegment()` on segment switch (D5/FILT-02)
- Created `state_shopping_batch.dart` — `BatchSelectModeState` (Freezed) + `batchSelectModeProvider` (transient, app-root scope, D38-03); enter/toggle/selectAll/exit methods
- Extended `repository_providers.dart` with all 6 use-case providers + `filteredShoppingItemsProvider` (StreamProvider with client-side ledger/category/status filter per D38-04 Pitfall 5)
- Full build_runner generation: 3 new `.g.dart` files + 1 new `.freezed.dart` file
- 5 unit tests written and passing for keepAlive retention, setListType filter reset, clearAll semantics
- Full test suite: 2400/2400 green

## Task Commits

1. **Task 1: state_shopping_filter.dart + state_shopping_batch.dart** - `0890fdbc` (feat)
2. **Task 2: repository_providers.dart extensions + unit tests** - `6ef75f4d` (feat)
3. **Bug fix: mock_use_cases.dart stale suppress removal** - `2c711ee6` (fix)

## Files Created/Modified

- `lib/features/shopping_list/presentation/providers/state_shopping_filter.dart` — listTypeProvider + shoppingFilterProvider (both keepAlive:true)
- `lib/features/shopping_list/presentation/providers/state_shopping_filter.g.dart` — generated
- `lib/features/shopping_list/presentation/providers/state_shopping_batch.dart` — BatchSelectModeState Freezed model + batchSelectModeProvider (transient)
- `lib/features/shopping_list/presentation/providers/state_shopping_batch.freezed.dart` — generated
- `lib/features/shopping_list/presentation/providers/state_shopping_batch.g.dart` — generated
- `lib/features/shopping_list/presentation/providers/repository_providers.dart` — extended with 6 use-case providers + filteredShoppingItemsProvider
- `lib/features/shopping_list/presentation/providers/repository_providers.g.dart` — regenerated
- `test/unit/features/shopping_list/providers/state_shopping_filter_test.dart` — 5 unit tests (stub → real assertions)
- `test/widget/features/shopping_list/helpers/mock_use_cases.dart` — removed stale unused_import suppression

## Decisions Made

- `listTypeProvider` defaults to 'private' (T-38-02-01: conservative default, no accidental public exposure)
- `BatchSelectModeState` modeled as Freezed (immutability per CLAUDE.md; `copyWith` for `toggle()` and `selectAll()`)
- `filteredShoppingItemsProvider` watches both `listTypeProvider` AND `shoppingFilterProvider` — filter chip changes trigger re-emission without `ref.invalidate`
- `reorderShoppingItemsUseCaseProvider` wired with repository ONLY (D37-01 confirmed, no sync deps)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed stale `// ignore_for_file: unused_import` from mock_use_cases.dart**
- **Found during:** Task 2 verification (full test suite run)
- **Issue:** `test/widget/features/shopping_list/helpers/mock_use_cases.dart` had `// ignore_for_file: unused_import` + two actually unused imports (`flutter_riverpod/flutter_riverpod.dart`, `flutter_test/flutter_test.dart`) added as placeholders in Plan 38-01. The `stale_suppressions_scan_test.dart` architecture test correctly rejected the unapproved suppress directive.
- **Fix:** Removed the `// ignore_for_file:` line and the two genuinely unused imports; `flutter_riverpod/misc.dart` (provides `Override`) retained as it is used by `shoppingRepositoryOverride`.
- **Files modified:** `test/widget/features/shopping_list/helpers/mock_use_cases.dart`
- **Verification:** `flutter test test/architecture/stale_suppressions_scan_test.dart` passes; `flutter analyze mock_use_cases.dart` — no issues
- **Committed in:** `2c711ee6`

---

**Total deviations:** 1 auto-fixed (Rule 1 — bug in pre-existing Wave 0 test helper)
**Impact on plan:** Necessary correctness fix; restores architecture test green. No scope creep.

## Issues Encountered

None during planned work. The stale ignore suppression was a pre-existing issue from Plan 38-01 that was naturally surfaced by the full test suite run.

## Known Stubs

None — this plan creates provider logic only, no UI files. No placeholder strings or empty data sources.

## Threat Flags

No new threat surface. The plan's threat model was fully addressed:
- T-38-02-02 (batchSelectModeProvider scope leak) — MITIGATED: provider is at app-root scope, no local ProviderScope override
- T-38-02-01 and T-38-02-03 — ACCEPTED per plan design (conservative default, cosmetic client-side filter)

## Next Phase Readiness

All providers required by Wave 2 screens and widgets are now ready:
- `listTypeProvider` + `shoppingFilterProvider` — filter bar, segmented control
- `batchSelectModeProvider` — batch selection header + action bar + nav bar hide
- `createShoppingItemUseCaseProvider` through `clearCompletedItemsUseCaseProvider` — form screen + tile swipe-delete + batch delete + clear completed
- `filteredShoppingItemsProvider` — main list body in `ShoppingListScreen`

No blockers for Wave 2 (Plan 38-03).

---
*Phase: 38-presentation-shell-ui-widgets*
*Completed: 2026-06-08*
