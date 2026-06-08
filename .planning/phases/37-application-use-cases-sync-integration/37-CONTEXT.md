# Phase 37: Application Use Cases + Sync Integration - Context

**Gathered:** 2026-06-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Build the **application layer + family-sync integration** for the shopping list, on top of the Phase 36 data+domain foundation (repository interface and `shopping_items` v20 columns are locked). No UI/providers (Phase 38), no ARB/goldens/smoke test (Phase 39).

Deliverables:
- **Six use cases** at `lib/application/shopping_list/`: `CreateShoppingItemUseCase`, `UpdateShoppingItemUseCase`, `DeleteShoppingItemUseCase`, `ToggleItemCompletedUseCase`, `ReorderShoppingItemsUseCase`, `ClearCompletedItemsUseCase`. Every mutation enforces the private-item privacy gate.
- **`ShoppingItemChangeTracker`** at `lib/application/family_sync/`, mirroring `TransactionChangeTracker`; `listType == 'public'` guard inside the tracker as a *second* safety net after the use-case gate.
- **`SyncOrchestrator._executeIncrementalPush`** extended to flush + push shopping item ops.
- **`ApplySyncOperationsUseCase`** gains a `case 'shopping_item':` branch → `_applyShoppingItemOp` handler, with `ShoppingItemRepository` added to its constructor **atomically** with all construction sites.
- **Sticky-complete merge algorithm** (D-03) implemented in the apply handler; tombstone-not-resurrected safety.
- **Reactive-stream integration test**: public item from member A appears in member B's `watchByListType('public')` without manual refresh; private item from A never appears for any remote member.

**Out of scope:** all UI/widgets/providers wiring (Phase 38); ARB/golden/smoke (Phase 39).

</domain>

<decisions>
## Implementation Decisions

### Reorder sync policy
- **D37-01:** `sortOrder` is **local-per-device — NOT synced**. `ReorderShoppingItemsUseCase` updates local `sortOrder` only and does **NOT** push any sync op (does not route through `ShoppingItemChangeTracker`). Rationale: syncing reorder would emit a burst of update ops on every drag and create member-vs-member "reorder war" LWW races; the DAO already provides a deterministic fallback order (`is_completed ASC, sort_order ASC, created_at ASC`). Cross-device shared ordering is explicitly out of v1.6 scope (deferred).
  - **Implication for planner:** reorder is the one mutation use case that does NOT touch the change tracker. It still must be reactive locally (writes go through the repo → `.watch()` stream). The privacy gate is moot here (no sync), but reorder must still operate per-segment correctly.

### Completion-state merge behavior (extends locked D-03 sticky-complete)
- **D37-02:** A family member **CAN deliberately un-check** a completed item and have it sync. On an explicit un-complete (`ToggleItemCompletedUseCase` → incomplete), the use case **clears `completedAt` to null** and stamps a fresh `updatedAt`. Because the un-complete op carries a newer `updatedAt`, the sticky-complete guard (`local.completedAt > incoming.updatedAt` → keep `isCompleted: true`) correctly does NOT fire, so the un-check applies normally.
- **D37-03:** The sticky-complete guard exists ONLY to stop a **stale rename/price edit** from silently un-checking. To make this robust, **update ops should carry field-level deltas (or at minimum NOT carry/overwrite `isCompleted`) for non-completion edits** — a rename op must not clobber a remote completion. Planner/researcher: confirm how `TransactionSyncMapper.toUpdateOperation` builds ops (full snapshot vs delta) and mirror a delta-style update for shopping items so a rename never carries a stale `isCompleted`. This is the cleanest implementation of D-03's intent. (Full-snapshot ops would force the apply handler to rely solely on the `completedAt > updatedAt` timestamp comparison, which only protects out-of-order delivery — weaker.)
- **Locked carry-forward (do NOT re-derive):** D-03 sticky-complete + `completedAt DateTime?` column **overrides** the original D7 / SYNC-05 / research-recommended pure-LWW. Tombstone (`isDeleted`) is checked BEFORE applying any update — a soft-deleted item is never resurrected by a later remote update op (SC4).

### listType immutability enforcement (D6 / SYNC-03)
- **D37-04:** `UpdateShoppingItemUseCase` **rejects** any attempt to change `listType` — returns a failure / throws a documented invariant error (fail-fast), NOT a silent no-op. Rationale: the UI (D6) never offers a listType-change entry point, so a normal user never hits this; the error is a safety net that surfaces buggy callers in tests. Document the invariant inline.

### Apply-loop fault isolation
- **D37-05:** Wrap **only the `shopping_item` branch** of `ApplySyncOperationsUseCase.execute` in try/catch with **skip-and-continue** (log + drop the bad op; next `fullSync` reconciles). The existing `bill`/`profile`/`avatar` branches keep their current semantics **unchanged** (zero regression). Rationale: a malformed shopping op must never abort the batch and starve `bill` apply, but we don't widen the blast radius by changing bill behavior.

### Privacy gate (locked, privacy-critical — restated for emphasis)
- **D37-06:** SYNC-02 — the `listType == 'public'` gate lives at the **use-case boundary** (Create/Update/Toggle/Delete/ClearCompleted — NOT Reorder, which doesn't sync). A private item must NEVER reach `ShoppingItemChangeTracker`. The tracker enforces a **second** `listType == 'public'` guard internally as defense-in-depth. Test gate: after a private `Create`, `tracker.pendingCount == 0`; after a public `Create`, `pendingCount == 1`.

### Claude's Discretion (planner/researcher)
- Exact `shopping_item` op wire payload field set (which of name/ledgerType/categoryId/tags/note/estimatedPrice/quantity/isCompleted/completedAt/sortOrder travel) — follow the bill-op mapper shape; note `sortOrder` does NOT travel (D37-01); `note` field-encryption-across-sync handling should mirror however bill `note`/sensitive fields are handled today (confirm in research).
- `ShoppingItemChangeTracker` as a **separate instance** vs folded into the transaction tracker — research SUMMARY says separate class mirroring `TransactionChangeTracker`; whether the orchestrator does a separate `_pushSync.execute` call or merges shopping ops into one push is the planner's call (separate call is simplest and matches the existing profile-ops pattern).
- `ClearCompletedItemsUseCase` mechanics: it soft-deletes every completed item for the given `listType` regardless of active filter, and each public soft-delete emits a delete (tombstone) op via the tracker — same path as single delete.
- Provider wiring shape (where the shopping tracker provider lives, how `ApplySyncOperationsUseCase` gets `ShoppingItemRepository`) — mirror `lib/features/family_sync/presentation/providers/state_sync.dart` + `repository_providers.dart`; final wiring is Phase 38 territory but the constructor change is atomic in THIS phase.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone scope & locked decisions
- `.planning/REQUIREMENTS.md` — D1–D8 locked decisions + all 27 requirements. Phase 37 requirements: ITEM-01, ITEM-02, ITEM-04, DONE-01, DONE-03, MGMT-01, MGMT-02, MGMT-03, SYNC-01, SYNC-02, SYNC-03, SYNC-05, SYNC-06. **NOTE:** SYNC-05/D7's original "pure-LWW, no completedAt" wording was overridden by D-03 in Phase 36 (already reconciled in plan 36-07).
- `.planning/ROADMAP.md` §"Phase 37" — 5 success criteria (the implementation acceptance bar for this phase).
- `.planning/phases/36-data-layer-domain-import-guard/36-CONTEXT.md` — D-01..D-03 + carried-forward locks (v20 schema, `completedAt` nullable, repo-boundary note encryption + JSON tags, DAO `readsFrom:` reactivity, D6 listType-immutable). **D-03 sticky-complete is the direct predecessor of D37-02/03.**

### v1.6 research (milestone-level, 2026-06-07)
- `.planning/research/SUMMARY.md` — §family-sync integration (the 3 targeted changes: tracker + apply branch + orchestrator 4-line push); §"PITFALLS" #1 (private-item leak), #7 (FAB providers — Phase 38), #8 (keepAlive — Phase 38); OPEN-1 (completedAt — RESOLVED as D-03, user chose Option A against the research's Option B recommendation).
- `.planning/research/PITFALLS.md` — private-item sync leak, GAP-2 reactivity, completion CRDT race, **apply-loop error isolation** (D37-05 origin), constructor-not-updated-atomically.
- `.planning/research/ARCHITECTURE.md` — application-layer file placement, use-case shapes.
- `.planning/research/STACK.md` — zero new packages.

### Codebase patterns to mirror (READ before writing)
- `lib/application/family_sync/transaction_change_tracker.dart` — the exact template for `ShoppingItemChangeTracker` (in-memory `_pendingOps`, `trackCreate/Update/Delete`, `flush()`, `pendingCount`).
- `lib/application/family_sync/sync_orchestrator.dart` (`_executeIncrementalPush`, lines ~138–177) — where to add the shopping flush+push; `_changeTracker.flush()` → `_pushSync.execute(...)` pattern; profile-ops second-push is the model for a separate shopping push.
- `lib/application/family_sync/apply_sync_operations_use_case.dart` (178 lines) — `execute` switch on `entityType` (add `case 'shopping_item':`), `_applyBillOperation` op-switch (create/insert/delete/update), `_handleCreate`/`_handleUpdate` (mirror for `_applyShoppingItemOp`); `softDelete` on delete; constructor (add `ShoppingItemRepository`).
- `lib/application/accounting/create_transaction_use_case.dart` / `update_transaction_use_case.dart` / `delete_transaction_use_case.dart` — `TransactionChangeTracker? changeTracker` injection + `_changeTracker?.trackCreate/Update/Delete(...)` call pattern; mirror for shopping use cases WITH the public-only gate before the track call.
- `lib/features/accounting/domain/models/transaction_sync_mapper.dart` — `toUpdateOperation` op-builder (confirm full-snapshot vs delta for D37-03).
- `lib/features/family_sync/presentation/providers/state_sync.dart` + `repository_providers.dart` — provider construction of tracker/orchestrator/apply use case (constructor-change construction sites for the atomic update).
- `lib/features/shopping_list/domain/repositories/shopping_item_repository.dart` + domain models (Phase 36) — the locked interface the use cases depend on.
- `lib/data/daos/shopping_item_dao.dart` (Phase 36) — `watchByListType` reactive stream used by the integration test (SYNC-06).
- `test/integration/sync/bill_sync_round_trip_test.dart` + `test/unit/application/family_sync/apply_sync_operations_use_case_test.dart` + `transaction_change_tracker_test.dart` + `phase6_sync_coverage_test.dart` — test templates for the round-trip integration test and tracker/apply unit tests.

### Project rules
- `CLAUDE.md` — layer/thin-feature rules (application layer is GLOBAL at `lib/application/`, NOT inside features), crypto-at-boundary, Riverpod 3 conventions, Drift `TableIndex` syntax.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `TransactionChangeTracker` — copy verbatim structure for `ShoppingItemChangeTracker`; add the internal `listType == 'public'` guard in the track methods (second safety net).
- Accounting use cases (`Create/Update/DeleteTransactionUseCase`) — the nullable-`changeTracker` injection + conditional `?.track*()` call is the exact pattern; shopping use cases add the public-only gate around it.
- `ApplySyncOperationsUseCase._applyBillOperation` + `_handleCreate`/`_handleUpdate` — the shape `_applyShoppingItemOp` mirrors, including the `isDeleted` tombstone check before update and the create/insert/delete/update op switch.
- `SyncOrchestrator._executeIncrementalPush` profile-ops block — model for adding a separate shopping flush+push without disturbing the txn push.

### Established Patterns
- Sync ops are entity-agnostic at the wire level: `{op, entityType, entityId, fromDeviceId?, data?, timestamp}`. Adding an entity = new `entityType` literal + apply branch + tracker; no relay-server change.
- Apply loop currently: a thrown op aborts `execute()` (no per-op try/catch). D37-05 adds isolation ONLY to the shopping branch.
- Soft-delete = tombstone (`isDeleted = true`), never physical delete; tombstone checked before applying remote updates.

### Integration Points
- `ApplySyncOperationsUseCase` constructor gains `ShoppingItemRepository` — **must** be updated atomically with `lib/features/family_sync/presentation/providers/repository_providers.dart:130` and any test construction sites (`test/integration/sync/bill_sync_round_trip_test.dart:81`, `test/unit/application/family_sync/apply_sync_operations_use_case_test.dart:49`).
- `SyncOrchestrator` already receives one `changeTracker`; decide whether shopping tracker is a new constructor param + new push call (recommended) — touches `state_sync.dart:28` construction site + `phase6_sync_coverage_test.dart` orchestrator construction.
- Reactive delivery (SYNC-06): the integration test asserts member B's `watchByListType('public')` updates after apply writes through the repo — applies the v1.4 GAP-2 lesson (reactivity via `.watch()`/`readsFrom:`, not manual invalidate).

</code_context>

<specifics>
## Specific Ideas

- Frame sticky-complete the way Bring!/AnyList-style shared lists avoid the "someone un-checked my item" surprise: completion is intentionally harder to *accidentally* undo (stale edit can't un-check) but a *deliberate* un-check still works and syncs (D37-02).
- The privacy gate is the single highest-severity invariant in the whole feature — the dedicated `pendingCount` test gate (private→0, public→1) is the canonical proof and must be a first-class test, not an afterthought.

</specifics>

<deferred>
## Deferred Ideas

- **Cross-device shared shopping-list ordering** (sync `sortOrder`) — deferred out of v1.6 per D37-01; would need a reorder-merge/LWW strategy and op-burst throttling. Revisit if users ask for synchronized manual order.
- Tag-based filtering (v2 TAGFILT-01) — unchanged from Phase 36; not in this phase.
- Decimal/unit-bearing quantity — D8 / out of scope.

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 37-application-use-cases-sync-integration*
*Context gathered: 2026-06-08*
