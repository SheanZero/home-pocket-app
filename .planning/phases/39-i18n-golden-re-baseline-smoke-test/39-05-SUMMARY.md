---
phase: 39-i18n-golden-re-baseline-smoke-test
plan: 05
subsystem: testing
tags: [riverpod, drift, flutter-test, shopping-list, reactive-streams, integration-test]

# Dependency graph
requires:
  - phase: 38-shopping-list-ui
    provides: filteredShoppingItemsProvider StreamProvider, listTypeProvider, shoppingFilterProvider
  - phase: 37-shopping-list-sync
    provides: ApplySyncOperationsUseCase, kShoppingItemEntityType, ShoppingItemRepositoryImpl

provides:
  - Presentation-layer Riverpod smoke test with SC4 reactive assertion
  - D39-06 privacy re-assertion at the Riverpod provider layer
  - Custom _waitForItemInStream and _waitForSettledEmission helpers for StreamProvider testing

affects: [phase-40, any phase testing filteredShoppingItemsProvider or shopping Riverpod providers]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "_waitForItemInStream: subscribe-before-write pattern with item-specific Completer resolution"
    - "_waitForSettledEmission: emissionCount guard skips initial cached state, resolves on post-write emission"
    - "ProviderContainer.test() + fieldEncryptionServiceProvider.overrideWithValue() for integration tests without real crypto"
    - "_FixedPublicListType extends ListType for stable keepAlive notifier override in tests"

key-files:
  created:
    - test/integration/presentation/shopping_provider_smoke_test.dart
  modified: []

key-decisions:
  - "Override fieldEncryptionServiceProvider (crypto root) and appDatabaseProvider (security root) rather than app_accounting re-exports — covers the full provider chain without fighting keepAlive resolution"
  - "_FixedPublicListType overrides keepAlive ListType notifier to fix listType='public' for both test cases"
  - "SC4 test uses _waitForItemInStream (resolves only when item ID present) to avoid racing with initial empty emission"
  - "D39-06 privacy test uses _waitForSettledEmission (skips first emission) then checks item absent in post-write emission"

patterns-established:
  - "For StreamProvider integration tests: subscribe BEFORE write, use Completer-based helpers not waitForFirstValue when the initial state might match hasValue=true with wrong data"
  - "_waitForItemInStream pattern: resolves when specific item ID appears in the emission"
  - "_waitForSettledEmission pattern: skips first cached emission, resolves on second (post-write) emission"

requirements-completed: [NAV-03]

# Metrics
duration: 15min
completed: 2026-06-08
---

# Phase 39 Plan 05: Shopping Provider Smoke Test Summary

**Presentation-layer Riverpod integration test asserting filteredShoppingItemsProvider emits reactively via Drift streams (SC4) and excludes private items from public emissions (D39-06), using custom Completer-based stream helpers**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-06-08T14:20:00Z
- **Completed:** 2026-06-08T14:36:04Z
- **Tasks:** 1
- **Files modified:** 1 (created)

## Accomplishments

- Created `test/integration/presentation/shopping_provider_smoke_test.dart` with two test cases covering distinct contracts at the Riverpod presentation layer
- SC4 test: verifies `filteredShoppingItemsProvider` emits 'item-smoke' after `ApplySyncOperationsUseCase.execute()` without any `ref.invalidate` in the production code path — Drift reactive stream propagates through the Riverpod provider graph automatically
- D39-06 privacy test: verifies 'private-smoke' item does NOT appear in the public `filteredShoppingItemsProvider` emission, reinforcing the privacy contract established at the DAO level (Phase 37)
- Both tests use `ProviderContainer.test()`, subscribe-before-write pattern, and custom Completer-based helpers that correctly handle Riverpod 3's auto-dispose behavior

## Task Commits

1. **Task 1: Write shopping_provider_smoke_test.dart** - `f1d48be5` (test)

## Files Created/Modified

- `test/integration/presentation/shopping_provider_smoke_test.dart` - Presentation-layer Riverpod smoke test with SC4 reactive assertion + D39-06 privacy re-assertion

## Decisions Made

- Override `fieldEncryptionServiceProvider` (crypto root) and `appDatabaseProvider` (security root) rather than app_accounting re-exports. The shopping `repository_providers.dart` wires through `app_accounting.appAppDatabaseProvider` and `app_accounting.appFieldEncryptionServiceProvider`, which are themselves re-exports of the root providers. Overriding at the root level covers the entire chain.
- `_FixedPublicListType` subclasses `ListType` (a keepAlive notifier) to return `'public'` from `build()`. This avoids the need to call `.setListType()` after container creation while maintaining the correct Riverpod `overrideWith` contract for `@Riverpod(keepAlive: true)` notifiers.
- SC4 test uses `_waitForItemInStream` (a custom Completer that resolves only when the expected item ID appears) rather than `waitForFirstValue`. The reason: `waitForFirstValue` resolves on the first `hasValue` state, which would be the initial empty list if called after the subscription is already established. The custom helper subscribes before the write and resolves specifically when the written item is present.
- D39-06 privacy test uses `_waitForSettledEmission` which skips the first (cached initial) emission via `emissionCount > 1`. This catches the post-write re-emission and verifies the private item is absent.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed relative import path for test_provider_scope.dart**
- **Found during:** Task 1 (analyzer run)
- **Issue:** PATTERNS.md showed path as `'../../../../helpers/test_provider_scope.dart'` (4 levels up) but the new file is at `test/integration/presentation/` which is only 2 levels from `test/helpers/`
- **Fix:** Used `'../../helpers/test_provider_scope.dart'`
- **Files modified:** test/integration/presentation/shopping_provider_smoke_test.dart
- **Committed in:** f1d48be5

**2. [Rule 1 - Bug] Fixed SC4 test timing (initial empty state vs post-write state)**
- **Found during:** Task 1 (test run — SC4 failed with `found=false`)
- **Issue:** `waitForFirstValue` resolved immediately with the initial empty list (Riverpod caches the value after the first emission, so a subsequent `waitForFirstValue` call resolves with the cached empty state before the write propagates)
- **Fix:** Replaced `waitForFirstValue` with `_waitForItemInStream`, a custom Completer-based helper that establishes the subscription BEFORE the write and resolves only when the specific item ID appears in the stream emission
- **Files modified:** test/integration/presentation/shopping_provider_smoke_test.dart
- **Committed in:** f1d48be5

---

**Total deviations:** 2 auto-fixed (both Rule 1 bugs)
**Impact on plan:** Both fixes necessary for correctness. The import path fix was a PATTERNS.md depth error. The timing fix resolved a subtle Riverpod 3 stream settlement issue where `waitForFirstValue` could return the cached pre-write state.

## Issues Encountered

- `unnecessary_underscores` analyzer warning: `(_, __)` in listener lambdas — fixed by using `(_, _)` (single underscore).
- `ProviderListenable` not exported from `flutter_riverpod.dart` — imported from `flutter_riverpod/misc.dart` per CLAUDE.md Riverpod 3 import table.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Presentation-layer smoke test committed and passing (both SC4 + D39-06)
- Test infrastructure established for testing keepAlive notifier overrides and Drift-to-Riverpod reactive stream propagation
- `_waitForItemInStream` and `_waitForSettledEmission` patterns are reusable for future StreamProvider integration tests

## Threat Flags

None — this plan adds only a test file. No new network endpoints, auth paths, file access patterns, or schema changes introduced.

---

## Self-Check

### Files exist:
- [x] `test/integration/presentation/shopping_provider_smoke_test.dart` — created

### Commits exist:
- [x] `f1d48be5` — test(39-05): add presentation-layer smoke test for filteredShoppingItemsProvider

## Self-Check: PASSED

*Phase: 39-i18n-golden-re-baseline-smoke-test*
*Completed: 2026-06-08*
