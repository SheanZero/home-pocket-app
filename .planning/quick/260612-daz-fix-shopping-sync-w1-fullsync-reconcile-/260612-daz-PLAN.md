---
phase: quick-260612-daz
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/application/family_sync/apply_sync_operations_use_case.dart
  - lib/application/family_sync/full_sync_use_case.dart
  - lib/application/family_sync/shopping_item_change_tracker.dart
  - lib/features/family_sync/presentation/providers/repository_providers.dart
  - lib/features/family_sync/presentation/providers/repository_providers.g.dart
  - test/unit/application/family_sync/apply_sync_operations_use_case_test.dart
  - test/unit/application/family_sync/full_sync_use_case_test.dart
  - test/integration/sync/shopping_sync_round_trip_test.dart
autonomous: true
requirements: [SYNC-01, SYNC-02, SYNC-03]

must_haves:
  truths:
    - "Full sync pushes all local PUBLIC shopping items as create ops alongside transactions (W1/SYNC-01)"
    - "Private shopping items never appear in any full-sync push payload (privacy gate, defense-in-depth)"
    - "Inbound shopping_item create/update ops with listType != 'public' are dropped by the receiver (W2/SYNC-02)"
    - "An inbound update op can never change an existing item's listType — receiver pins existing.listType (W2/SYNC-03, D37-04 invariant)"
    - "shopping_item_change_tracker.dart doc comment accurately describes the loss window and reconcile path"
  artifacts:
    - path: "lib/application/family_sync/full_sync_use_case.dart"
      provides: "FetchAllShoppingOpsCallback + defensive public-only filter in execute()"
      contains: "fetchAllShoppingOps"
    - path: "lib/application/family_sync/apply_sync_operations_use_case.dart"
      provides: "Receiver-side listType gate + listType pin in update merge"
    - path: "test/integration/sync/shopping_sync_round_trip_test.dart"
      provides: "Full-sync round trip: public included, private excluded"
  key_links:
    - from: "lib/features/family_sync/presentation/providers/repository_providers.dart"
      to: "ShoppingItemRepository.watchByListType('public')"
      via: "fullSyncUseCase provider fetchAllShoppingOps callback"
      pattern: "watchByListType\\('public'\\)"
    - from: "lib/application/family_sync/apply_sync_operations_use_case.dart"
      to: "ShoppingItemSyncMapper.fromSyncMap"
      via: "_handleShoppingUpdate copyWith listType pin"
      pattern: "listType: existing\\.listType"
---

<objective>
Fix v1.6 milestone-audit warnings W1 (SYNC-01) and W2 (SYNC-02/03) in shopping sync.

W1: `FullSyncUseCase` has zero shopping support, yet `shopping_item_change_tracker.dart` documents full sync as the safety net for in-memory ops lost on hard kill. Extend full sync to push PUBLIC shopping items (mirroring transactions, via `ShoppingItemSyncMapper`), respecting the D37-06 privacy gate.

W2: The receiver trusts the wire — `_applyShoppingItemOp` upserts whatever `listType` arrives, so a buggy/older peer could write into the private list or flip an item's `listType` via update. Add a receiver-side public-only gate (D37-05 per-op skip pattern) and pin `listType: existing.listType` in the update merge (D37-04 invariant, receiver side).

Purpose: Close the data-loss window and the receiver-side privacy hole recorded in `.planning/v1.6-MILESTONE-AUDIT.md` tech_debt (phase 37 items W1, W2).
Output: Hardened sync code + unit and integration tests proving both fixes.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/v1.6-MILESTONE-AUDIT.md
@lib/application/family_sync/full_sync_use_case.dart
@lib/application/family_sync/shopping_item_change_tracker.dart
@lib/application/family_sync/apply_sync_operations_use_case.dart
@lib/features/shopping_list/domain/models/shopping_item_sync_mapper.dart
@lib/features/family_sync/presentation/providers/repository_providers.dart
@test/unit/application/family_sync/apply_sync_operations_use_case_test.dart
@test/unit/application/family_sync/full_sync_use_case_test.dart
@test/integration/sync/shopping_sync_round_trip_test.dart

Interface facts (verified during planning — do not re-derive):
- `FullSyncUseCase` is constructed in exactly 2 places: `repository_providers.dart:179` and `full_sync_use_case_test.dart:14`. Adding a required constructor param ripples nowhere else.
- `ShoppingItemRepository.watchByListType(String)` is the only list-type query; the backing DAO SQL already filters `is_deleted = 0`, so `.first` on `watchByListType('public')` yields exactly the public, non-deleted set.
- `SyncMode.initialSync` (the only mode that calls `FullSyncUseCase.execute`) fires only on `onMemberConfirmed` in `lib/infrastructure/sync/sync_scheduler.dart` — NOT on app launch. `onAppPaused` already flushes the debounce via `incrementalPush`. The tracker comment's "fullSync on next launch" claim is therefore wrong on two counts and must be corrected (Task 2).
- `_handleShoppingUpdate` already has tombstone guard (SC-4), LWW staleness drop (CR-01), and sortOrder preservation (D37-01) — the listType pin slots into the existing `copyWith(id: entityId, sortOrder: existing.sortOrder)` call.
- riverpod_generator embeds a source hash per provider, so changing the `fullSyncUseCase` provider BODY requires `flutter pub run build_runner build --delete-conflicting-outputs` (AUDIT-10 CI catches stale .g.dart).
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: W2 — receiver-side listType gate + immutability pin</name>
  <files>lib/application/family_sync/apply_sync_operations_use_case.dart, test/unit/application/family_sync/apply_sync_operations_use_case_test.dart</files>
  <behavior>
    - Test 1 (gate, create): inbound shopping_item create op with data['listType'] == 'private' → repository upsert/insert is NEVER called; remaining ops in the batch still apply (per-op skip, not abort).
    - Test 2 (gate, update): inbound shopping_item update op with data['listType'] == 'private' targeting an existing public item → dropped; existing item unchanged.
    - Test 3 (pin): existing item with listType 'private' (seeded directly via repo/mock), inbound update op claiming listType 'public' with newer updatedAt → upsert IS called but the upserted item's listType equals 'private' (existing.listType preserved); other fields (e.g. name) DO take the incoming values.
    - Test 4 (regression guard): inbound public create + public update still apply exactly as before (existing tests stay green).
  </behavior>
  <action>
    RED first: add the four tests above to apply_sync_operations_use_case_test.dart following its existing mock/fixture style; run them, confirm Tests 1-3 fail.

    GREEN: in apply_sync_operations_use_case.dart:
    1. In `_applyShoppingItemOp`, for the 'create'/'insert' and 'update' arms (after the existing `data == null` guards), add a receiver-side privacy gate: if `data['listType'] != 'public'`, return without applying — consistent with the D37-05 per-op skip pattern (silent skip; optionally a kDebugMode debugPrint mirroring the surrounding style). Do NOT gate the 'delete' arm — delete ops carry no listType (tracker contract) and tombstones are id-addressed.
    2. In `_handleShoppingUpdate`, extend the final merge to pin listType: `copyWith(id: entityId, sortOrder: existing.sortOrder, listType: existing.listType)` — listType can never change post-creation (D37-04 invariant, receiver side). Add a one-line comment citing D37-04/W2.
    Keep the existing SC-4 tombstone guard, CR-01 LWW drop, and WR-01 unknown-ID early return untouched and ordered before the merge.

    Why receiver-side: sender-side gates (use-case + tracker D37-06) do not protect against buggy or older peers; the wire is untrusted input and must be validated at the application boundary.
  </action>
  <verify>
    <automated>flutter test test/unit/application/family_sync/apply_sync_operations_use_case_test.dart</automated>
  </verify>
  <done>Inbound non-public shopping ops are dropped; update ops cannot flip listType; all pre-existing apply-ops tests still pass.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: W1 — extend FullSyncUseCase with public shopping ops + provider wiring + tracker comment</name>
  <files>lib/application/family_sync/full_sync_use_case.dart, lib/features/family_sync/presentation/providers/repository_providers.dart, lib/features/family_sync/presentation/providers/repository_providers.g.dart, lib/application/family_sync/shopping_item_change_tracker.dart, test/unit/application/family_sync/full_sync_use_case_test.dart</files>
  <behavior>
    - Test 1: fetchAllShoppingOps returns 2 public-item create ops, fetchAllTransactions returns 3 txn ops → execute() pushes all 5 ops (combined into the same chunked push stream) and returns 5.
    - Test 2 (defense-in-depth): fetchAllShoppingOps returns 1 public op + 1 op whose data['listType'] == 'private' → only the public op is pushed; returned count excludes the dropped op.
    - Test 3: zero transactions but 1 public shopping op → push still happens (the existing "no transactions → return 0" early-exit must not swallow shopping ops).
    - Test 4 (regression): transactions-only path behaves exactly as today (chunking at 50, PushSyncSuccess/PushSyncQueued counting).
  </behavior>
  <action>
    RED first: in full_sync_use_case_test.dart, add a `fetchAllShoppingOps` argument to the existing construction (compile break is expected at RED) and write the four tests; confirm failures.

    GREEN, three edits:

    1. full_sync_use_case.dart — add `typedef FetchAllShoppingOpsCallback = Future<List<Map<String, dynamic>>> Function();` and a required constructor param `fetchAllShoppingOps` (mirror the transactions callback). In `execute()`: fetch both lists; defensively filter shopping ops, keeping only those where `op == 'delete'` is absent from full sync anyway — concretely: keep ops whose `(operation['data'] as Map?)?['listType'] == 'public'` (mirrors the tracker's D37-06 second safety net; full sync emits create ops only, so every op carries data.listType). Concatenate `[...transactions, ...publicShoppingOps]` BEFORE the empty-check and chunk loop so chunking, vectorClock, and syncType 'full' apply uniformly. Update debugPrints to report both counts.

    2. repository_providers.dart — in the `fullSyncUseCase` provider, wire `fetchAllShoppingOps`: read `shoppingItemRepositoryProvider` (already imported at top of file), fetch `await repo.watchByListType('public').first` (DAO already excludes is_deleted rows), and map each item via `ShoppingItemSyncMapper.toCreateOperation(item)` — receiver `_handleShoppingCreate` is idempotent (skips existing ids), so create ops are correct for reconcile. Add the `shopping_item_sync_mapper.dart` import. Then run `flutter pub run build_runner build --delete-conflicting-outputs` — the riverpod provider source hash changes with the body, and stale .g.dart fails AUDIT-10 CI.

    3. shopping_item_change_tracker.dart — correct the class doc comment (lines 13-15): the loss window is a hard kill inside the 10s debounce (onAppPaused already flushes via incrementalPush, so normal backgrounding is safe), and reconcile happens at the next FULL SYNC (pairing-time initialSync / any future full-sync trigger), which now includes public shopping items — not "on next launch". Keep the D37-06 paragraphs untouched.

    NOT in scope: no new SyncMode, no scheduler changes, no pull-side change (fullPull already routes pulled shopping ops through ApplySyncOperationsUseCase hardened in Task 1).
  </action>
  <verify>
    <automated>flutter test test/unit/application/family_sync/full_sync_use_case_test.dart test/unit/application/family_sync/repository_providers_test.dart test/unit/application/family_sync/shopping_item_change_tracker_test.dart</automated>
  </verify>
  <done>Full sync pushes public shopping items mixed into the chunked op stream; private ops are filtered defensively in the use case; provider wiring compiles with regenerated .g.dart; tracker comment matches actual behavior.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 3: Integration round trip + quality gates</name>
  <files>test/integration/sync/shopping_sync_round_trip_test.dart</files>
  <behavior>
    - Test 1 (W1 round trip): seed the in-memory DB with one PUBLIC and one PRIVATE shopping item; build full-sync ops exactly as the provider does (`watchByListType('public').first` → `ShoppingItemSyncMapper.toCreateOperation`); assert the op list contains only the public item's id; apply the ops via the existing `applyOps` harness against a fresh receiver state; assert the public item exists post-apply and the private item does not.
    - Test 2 (W2 end-to-end): apply an inbound create op hand-built with `listType: 'private'` → item is NOT persisted; apply an inbound update op with `listType: 'private'` against a persisted public item → item unchanged.
  </behavior>
  <action>
    Extend shopping_sync_round_trip_test.dart using its existing setUp harness (AppDatabase.forTesting + ShoppingItemRepositoryImpl + ApplySyncOperationsUseCase with passthrough mock encryption). For Test 1, simulate the receiver either with a second AppDatabase.forTesting instance or by soft-clearing between push-build and apply — follow whichever pattern the file's existing round-trip tests use.

    Then run the full quality gates:
    1. `flutter analyze` — must report 0 issues.
    2. `dart format` ONLY on the files touched in this plan (never whole test/ — repo is not format-clean).
    3. Affected suites: `flutter test test/unit/application/family_sync/ test/integration/sync/` — all green.
  </action>
  <verify>
    <automated>flutter analyze && flutter test test/unit/application/family_sync/ test/integration/sync/</automated>
  </verify>
  <done>Round-trip integration proves public-in/private-out for full sync and receiver gate end-to-end; analyze 0 issues; both affected suites fully green.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| sync wire → ApplySyncOperationsUseCase | E2EE-decrypted peer payloads are still untrusted application input (buggy/older/malicious peer) |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-q260612-01 | Tampering | _applyShoppingItemOp (create/update) | mitigate | Task 1: drop inbound shopping ops with listType != 'public' (receiver-side D37-06 mirror) |
| T-q260612-02 | Tampering | _handleShoppingUpdate merge | mitigate | Task 1: pin listType: existing.listType — wire can never flip an item public↔private |
| T-q260612-03 | Information Disclosure | FullSyncUseCase push payload | mitigate | Task 2: provider fetches watchByListType('public') only + defensive in-use-case listType filter; tests assert private exclusion |
| T-q260612-04 | Spoofing | delete ops (id-addressed, no listType) | accept | Pre-existing behavior; ids are UUIDs unknown to peers for private items; transport is E2EE-authenticated. Out of audit scope (W1/W2 only) |
</threat_model>

<verification>
- `flutter analyze` → 0 issues
- `flutter test test/unit/application/family_sync/ test/integration/sync/` → all green
- `git diff --stat` touches only the files listed in frontmatter (plus regenerated repository_providers.g.dart)
- grep checks: `grep -n "fetchAllShoppingOps" lib/application/family_sync/full_sync_use_case.dart` non-empty; `grep -n "listType: existing.listType" lib/application/family_sync/apply_sync_operations_use_case.dart` non-empty; `grep -c "next launch" lib/application/family_sync/shopping_item_change_tracker.dart` returns 0
</verification>

<success_criteria>
- W1 closed: full sync includes public shopping items, excludes private; tracker comment accurate
- W2 closed: receiver drops non-public shopping ops and pins listType on update
- All four audit-mandated test scenarios exist and pass (public round trip, private exclusion, private-op drop, listType-flip rejection)
- Zero analyzer issues; no unrelated files reformatted; build_runner output committed (no stale .g.dart)
</success_criteria>

<output>
Create `.planning/quick/260612-daz-fix-shopping-sync-w1-fullsync-reconcile-/260612-daz-SUMMARY.md` when done.
</output>
