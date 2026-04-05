# Realtime Sync — Client Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make ledger sync realtime: transaction changes push immediately, partner device pulls within 1-2s via persistent WebSocket, with push notification as fallback.

**Architecture:** Three changes: (1) Wire push notification handlers to SyncEngine, (2) Make WebSocket persistent when app is in foreground with active group, (3) Add `sync_available` WebSocket event type so sync pull triggers immediately. Transaction push already works via `onTransactionChanged()` → 10s debounce → `incrementalPush`. The missing piece is notifying the partner to pull.

**Tech Stack:** Flutter, Riverpod, WebSocketService (existing), PushNotificationService (existing), SyncEngine (existing)

---

## Current State

| Component | Status | Gap |
|-----------|--------|-----|
| Transaction push (10s debounce) | ✅ Works | incrementalPush only drains queue + profiles, not new txns |
| Push notification handlers | ❌ `registerHandlers()` never called | `sync_available` push arrives but no action taken |
| WebSocket | ⚠️ On-demand only (join/approval screens) | Not active during normal app usage |
| SyncEngine.onSyncAvailable() | ✅ Exists | Never called (no handler wired) |
| WebSocket `sync_available` event | ❌ Not in enum | Server will add this event type |

## Architecture Flow (Target State)

```
Device A creates transaction
  → 10s debounce → incrementalPush
  → _executeIncrementalPush(): push txn operations + drain queue
  → Server stores sync message
  → Server broadcasts sync_available via WebSocket to Device B
  → Device B receives sync_available event
  → SyncEngine.onSyncAvailable() → incrementalPull
  → Device B pulls and applies new transaction
  
Fallback: Push notification sync_available → same SyncEngine.onSyncAvailable() path
Fallback: 15-min polling → same incrementalPull path
```

---

## File Structure

| Action | File | Responsibility |
|--------|------|----------------|
| Modify | `lib/infrastructure/sync/websocket_service.dart` | Add `syncAvailable` event type |
| Modify | `lib/application/family_sync/sync_engine.dart` | Add persistent WebSocket lifecycle, wire push handlers |
| Modify | `lib/infrastructure/sync/sync_orchestrator.dart` | Fix incrementalPush to push actual transaction changes |
| Create | `lib/application/family_sync/transaction_change_tracker.dart` | Track changed transactions for incremental push |
| Modify | `lib/features/family_sync/presentation/providers/sync_providers.dart` | Wire transaction change tracker |
| Modify | `lib/l10n/app_ja.arb`, `app_en.arb`, `app_zh.arb` | No new strings needed |
| Modify | Tests for each changed component | |

---

## Task 1: Add `syncAvailable` to WebSocket event types

**Files:**
- Modify: `lib/infrastructure/sync/websocket_service.dart:22-28` (enum) and `:195-215` (_parseEvent)
- Modify: `test/infrastructure/sync/websocket_service_test.dart`

- [ ] **Step 1: Write failing test**

```dart
test('parses sync_available event from WebSocket', () async {
  final events = <WebSocketEvent>[];
  service.eventStream.listen(events.add);

  service.connect(
    groupId: 'group-1',
    deviceId: 'device-1',
    signMessage: (msg) async => 'mock-sig',
  );
  incomingController.add(
    jsonEncode({'type': 'auth_success', 'groupId': 'group-1'}),
  );
  await Future<void>.delayed(Duration.zero);

  incomingController.add(jsonEncode({
    'type': 'sync_available',
    'groupId': 'group-1',
    'deviceId': 'device-2',
    'timestamp': '2026-04-05T12:00:00Z',
  }));
  await Future<void>.delayed(Duration.zero);

  expect(events, hasLength(1));
  expect(events.first.type, WebSocketEventType.syncAvailable);
});
```

- [ ] **Step 2: Run test — should FAIL**

Run: `flutter test test/infrastructure/sync/websocket_service_test.dart -v`

- [ ] **Step 3: Add `syncAvailable` to enum and parser**

```dart
// websocket_service.dart
enum WebSocketEventType {
  memberConfirmed,
  joinRequest,
  memberLeft,
  groupDissolved,
  groupStatus,
  syncAvailable, // NEW
}

// In _parseEvent switch:
'sync_available' => WebSocketEventType.syncAvailable,
```

- [ ] **Step 4: Update exhaustive switches in other files**

Check and add `case WebSocketEventType.syncAvailable:` to:
- `lib/features/family_sync/presentation/screens/waiting_approval_screen.dart`
- Any other exhaustive switch on `WebSocketEventType`

- [ ] **Step 5: Run tests — should PASS**

Run: `flutter test test/infrastructure/sync/websocket_service_test.dart -v`

- [ ] **Step 6: Run `flutter analyze`**

- [ ] **Step 7: Commit**

```bash
git commit -m "feat: add syncAvailable WebSocket event type"
```

---

## Task 2: Wire push notification handlers to SyncEngine

**Files:**
- Modify: `lib/application/family_sync/sync_engine.dart` — add method to wire push handlers
- Modify: `lib/main.dart` or startup code — call registration after initialization

Currently `PushNotificationService.registerHandlers()` is never called. The SyncEngine should wire itself to push notifications so `sync_available` push triggers `onSyncAvailable()`.

- [ ] **Step 1: Add `connectPushNotifications` method to SyncEngine**

```dart
// sync_engine.dart — add after initialize()

/// Wire push notification handlers to trigger sync operations.
///
/// Call once after both SyncEngine.initialize() and
/// PushNotificationService.initialize() have completed.
void connectPushNotifications(PushNotificationService pushService) {
  pushService.registerHandlers(
    onSyncAvailable: (_) async => onSyncAvailable(),
    onMemberConfirmed: (_) async => onMemberConfirmed(),
  );
}
```

Add import: `import '../../infrastructure/sync/push_notification_service.dart';`

- [ ] **Step 2: Call `connectPushNotifications` at app startup**

In `lib/main.dart`, after `syncEngine.initialize()`:

```dart
final syncEngine = ref.read(syncEngineProvider);
syncEngine.initialize();

// Wire push notifications → sync engine
final pushService = ref.read(pushNotificationServiceProvider);
syncEngine.connectPushNotifications(pushService);
```

- [ ] **Step 3: Run `flutter analyze`**

- [ ] **Step 4: Commit**

```bash
git commit -m "feat: wire push notification handlers to SyncEngine"
```

---

## Task 3: Make WebSocket persistent when app has active group

**Files:**
- Modify: `lib/application/family_sync/sync_engine.dart` — manage WebSocket lifecycle

Currently WebSocket only connects in join/approval screens. We need it connected whenever the app is in foreground with an active group.

- [ ] **Step 1: Add WebSocket lifecycle management to SyncEngine**

```dart
// sync_engine.dart — add fields
WebSocketService? _webSocketService;
StreamSubscription<WebSocketEvent>? _wsEventSubscription;
KeyManager? _keyManager;

// Update constructor to accept dependencies
SyncEngine({
  required SyncOrchestrator orchestrator,
  required GroupRepository groupRepo,
  required WebSocketService webSocketService,
  required KeyManager keyManager,
})
```

- [ ] **Step 2: Add `_connectWebSocket` and `_disconnectWebSocket` methods**

```dart
Future<void> _connectWebSocket() async {
  final group = await _groupRepo.getActiveGroup();
  if (group == null) return;

  final deviceId = await _keyManager!.getDeviceId();
  if (deviceId == null) return;

  // Subscribe to events before connecting
  _wsEventSubscription ??= _webSocketService!.eventStream.listen(_handleWebSocketEvent);

  _webSocketService!.connect(
    groupId: group.groupId,
    deviceId: deviceId,
    signMessage: (message) async {
      final sig = await _keyManager!.signData(utf8.encode(message));
      return base64Encode(sig.bytes);
    },
  );
  _webSocketService!.startLifecycleObservation();
}

void _disconnectWebSocket() {
  _wsEventSubscription?.cancel();
  _wsEventSubscription = null;
  _webSocketService
    ?..stopLifecycleObservation()
    ..disconnect();
}

void _handleWebSocketEvent(WebSocketEvent event) {
  switch (event.type) {
    case WebSocketEventType.syncAvailable:
      onSyncAvailable();
    case WebSocketEventType.memberConfirmed:
      onMemberConfirmed();
    case WebSocketEventType.joinRequest:
    case WebSocketEventType.memberLeft:
    case WebSocketEventType.groupDissolved:
    case WebSocketEventType.groupStatus:
      break;
  }
}
```

- [ ] **Step 3: Connect WebSocket during initialize() when group is active**

```dart
void initialize() {
  _lifecycleObserver = SyncLifecycleObserver(
    onResume: () async {
      _scheduler.onAppResumed();
      await _connectWebSocket(); // Reconnect on resume
    },
    onPaused: () {
      _scheduler.onAppPaused();
      // WebSocket handles its own 60s background timeout
    },
  );
  _lifecycleObserver!.start();

  unawaited(_refreshInitialStatus());
  unawaited(_connectWebSocket()); // Initial connect
}
```

- [ ] **Step 4: Disconnect WebSocket in dispose()**

```dart
void dispose() {
  _scheduler.dispose();
  _lifecycleObserver?.dispose();
  _disconnectWebSocket();
  unawaited(_statusController.close());
}
```

- [ ] **Step 5: Update syncEngineProvider to inject WebSocket + KeyManager**

In `lib/features/family_sync/presentation/providers/sync_providers.dart`:

```dart
@Riverpod(keepAlive: true)
SyncEngine syncEngine(Ref ref) {
  final engine = SyncEngine(
    orchestrator: ref.watch(syncOrchestratorProvider),
    groupRepo: ref.watch(groupRepositoryProvider),
    webSocketService: ref.watch(webSocketServiceProvider),
    keyManager: ref.watch(keyManagerProvider),
  );
  ref.onDispose(engine.dispose);
  return engine;
}
```

Add imports for `webSocketServiceProvider` and `keyManagerProvider`.

- [ ] **Step 6: Remove WebSocket management from WaitingApprovalScreen**

Since SyncEngine now manages WebSocket globally, `WaitingApprovalScreen` should NOT create its own connection. Remove:
- `_webSocketService` field
- `_wsEventSubscription` field
- `_connectWebSocket()` method
- `_activateAndSync()` method
- WebSocket cleanup in `dispose()`

Replace the WebSocket-based navigation with SyncEngine status listening (already has `_listenForSyncStatus`). Keep polling as-is.

The `_verifyGroupAndNavigate()` is still triggered by polling and by the SyncEngine status stream.

- [ ] **Step 7: Remove WebSocket management from MemberApprovalScreen and CreateGroupScreen**

Same pattern — these screens no longer own WebSocket connections. The SyncEngine handles it globally.

For `CreateGroupScreen`: The `join_request` event handling needs to stay, but it should listen to a provider/stream from SyncEngine rather than directly managing WebSocket. For now, keep the WebSocket in CreateGroupScreen since the owner might not have an active group yet (pending status).

- [ ] **Step 8: Run `flutter analyze` and `flutter test`**

- [ ] **Step 9: Commit**

```bash
git commit -m "feat: persistent WebSocket in SyncEngine for realtime sync"
```

---

## Task 4: Fix incrementalPush to push actual transaction changes

**Files:**
- Create: `lib/application/family_sync/transaction_change_tracker.dart`
- Modify: `lib/application/family_sync/sync_orchestrator.dart` — use tracker in incrementalPush
- Modify: `lib/application/accounting/create_transaction_use_case.dart` — track change
- Modify: `lib/application/accounting/delete_transaction_use_case.dart` — track change
- Modify: `lib/features/family_sync/presentation/providers/sync_providers.dart` — wire tracker

Currently `_executeIncrementalPush()` only pushes profile changes and drains the offline queue. It does NOT push newly created/deleted transactions because there's no change tracking.

- [ ] **Step 1: Create TransactionChangeTracker**

```dart
// lib/application/family_sync/transaction_change_tracker.dart
import '../accounting/domain/models/transaction.dart';

/// Tracks transaction operations pending sync push.
///
/// When a transaction is created/updated/deleted locally,
/// the operation is recorded here. On incrementalPush,
/// all pending operations are flushed and pushed.
///
/// Note: In-memory only. If the app is killed before flush,
/// pending ops are lost. This is acceptable because:
/// - 10s debounce means ops flush quickly
/// - fullSync on next app launch will reconcile
/// - Partner's pull deduplicates by entityId
class TransactionChangeTracker {
  final _pendingOps = <Map<String, dynamic>>[];

  /// Record a create operation for sync.
  void trackCreate(Map<String, dynamic> operation) {
    _pendingOps.add(operation);
  }

  /// Record a delete operation for sync.
  void trackDelete({
    required String transactionId,
    required String bookId,
  }) {
    _pendingOps.add({
      'op': 'delete',
      'entityType': 'bill',
      'entityId': transactionId,
      'data': {'bookId': bookId},
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    });
  }

  /// Flush all pending operations. Returns the list and clears internal state.
  List<Map<String, dynamic>> flush() {
    final ops = List<Map<String, dynamic>>.of(_pendingOps);
    _pendingOps.clear();
    return ops;
  }

  /// Number of pending operations.
  int get pendingCount => _pendingOps.length;
}
```

- [ ] **Step 2: Add provider for TransactionChangeTracker**

```dart
// sync_providers.dart
@Riverpod(keepAlive: true)
TransactionChangeTracker transactionChangeTracker(Ref ref) {
  return TransactionChangeTracker();
}
```

- [ ] **Step 3: Track changes in CreateTransactionUseCase**

In `create_transaction_use_case.dart`, after `_transactionRepo.insert(transaction)`:

```dart
// Track for sync
_changeTracker?.trackCreate(
  TransactionSyncMapper.toCreateOperation(
    transaction,
    sourceBookId: bookId,
    sourceBookName: book.name,
    sourceBookType: 'remote_book:$bookId',
  ),
);
_syncEngine?.onTransactionChanged();
```

Add `TransactionChangeTracker?` as optional constructor parameter.

- [ ] **Step 4: Track changes in DeleteTransactionUseCase**

```dart
_changeTracker?.trackDelete(
  transactionId: transactionId,
  bookId: transaction.bookId,
);
_syncEngine?.onTransactionChanged();
```

- [ ] **Step 5: Use tracker in SyncOrchestrator._executeIncrementalPush()**

```dart
Future<SyncOrchestratorResult> _executeIncrementalPush() async {
  final group = await _groupRepo.getActiveGroup();
  if (group == null) return const SyncOrchestratorNoGroup();

  // Check group validity (5-min cache)
  final validity = await _checkValidity.execute();
  if (validity is GroupInvalid) {
    return SyncOrchestratorError('Group invalid: ${validity.reason}');
  }
  if (validity is GroupNoGroup) {
    return const SyncOrchestratorNoGroup();
  }

  // Flush pending transaction changes
  final txnOps = _changeTracker.flush();
  if (txnOps.isNotEmpty) {
    if (kDebugMode) {
      debugPrint('[SyncOrchestrator] incrementalPush: pushing ${txnOps.length} transaction ops');
    }
    await _pushSync.execute(
      operations: txnOps,
      vectorClock: const {},
    );
  }

  // Build profile operation if changed
  final profileOps = await _buildProfileOperationsIfChanged();
  if (profileOps.isNotEmpty) {
    await _pushSync.execute(
      operations: profileOps,
      vectorClock: const {},
    );
  }

  // Drain offline queue
  await _queueManager.drainQueue();

  return SyncOrchestratorSuccess(pushedCount: txnOps.length);
}
```

Add `TransactionChangeTracker` to SyncOrchestrator constructor.

- [ ] **Step 6: Wire tracker into providers**

Update `syncOrchestratorProvider` to inject `transactionChangeTrackerProvider`.

Update `createTransactionUseCaseProvider` and `deleteTransactionUseCaseProvider` to inject `transactionChangeTrackerProvider`.

- [ ] **Step 7: Run `flutter analyze` and `flutter test`**

- [ ] **Step 8: Commit**

```bash
git commit -m "feat: track and push individual transaction changes in incrementalPush"
```

---

## Task 5: End-to-end verification

- [ ] **Step 1: Run full test suite**

```bash
flutter analyze
flutter test
```

- [ ] **Step 2: Manual test — transaction sync**

1. Device A and B in same group
2. Device A creates a transaction
3. Check debug log: `[SyncEngine] onTransactionChanged` → 10s → `[SyncOrchestrator] incrementalPush: pushing 1 transaction ops`
4. Device B should receive `sync_available` via WebSocket within 1-2s
5. Debug log on B: `[SyncEngine] onSyncAvailable` → `[PullSync] Applied 1 ops`

- [ ] **Step 3: Manual test — fallback**

1. Kill WebSocket on Device B (airplane mode briefly)
2. Device A creates transaction
3. Device B should pull via push notification or 15-min polling

- [ ] **Step 4: Commit any fixes**

---

## Summary: Data Flow After Implementation

```
Device A: Create Transaction
  ↓
  TransactionChangeTracker.trackCreate(op)
  SyncEngine.onTransactionChanged()
  ↓ 10s debounce
  SyncScheduler → incrementalPush
  ↓
  SyncOrchestrator._executeIncrementalPush()
    → flush tracker → PushSyncUseCase.execute(txnOps)
    → REST POST /sync/push
  ↓
  Server stores message
    → WebSocket broadcast sync_available to Device B   ← PRIMARY (1-2s)
    → Push notification sync_available to Device B      ← FALLBACK
  ↓
  Device B: WebSocket event → SyncEngine.onSyncAvailable()
    → SyncScheduler → incrementalPull
    → PullSyncUseCase.execute() → pull + decrypt + apply
    → Transaction appears on Device B
```

**Three-layer degradation:**
1. WebSocket `sync_available` → immediate pull (1-2s)
2. Push notification `sync_available` → pull (1-30s)
3. 15-min polling → pull (max 15 min)
