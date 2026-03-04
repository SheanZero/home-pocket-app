# Server Protocol Alignment Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Align the Flutter client codebase with the server-app interaction protocol defined in `docs/arch/server/PROTOCOL.md`.

**Architecture:** The protocol defines push notification payloads, sync message formats, and lifecycle events. The client needs: (1) handlers for new push event types (`member_left`, `group_dissolved`), (2) sync message format alignment (operation naming, `syncType`/`syncId` fields), (3) UX improvements (WaitingApprovalScreen auto-navigation, group status refresh after `member_confirmed`), (4) robustness against missing `groupId` in current server payloads.

**Tech Stack:** Flutter, Riverpod, Freezed, Dart, Ed25519 crypto

---

## Gap Analysis Summary

| # | Gap | Protocol Section | Severity | Client Action |
|---|-----|-----------------|----------|---------------|
| 1 | `member_left` push not handled | §1.3, §3 | Medium | Add handler + UI cleanup |
| 2 | `group_dissolved` push not handled | §1.3, §3 | Medium | Add handler + UI cleanup |
| 3 | Operation naming mismatch (`insert` vs `create`, `table` vs `entityType`) | §2.3 | High | Align to protocol spec |
| 4 | Sync payload missing `syncType`, `syncId` fields | §2.1 | High | Add envelope wrapper |
| 5 | WaitingApprovalScreen no auto-navigation on `member_confirmed` | §1.3 | Medium | Listen to SyncTriggerService events |
| 6 | No group status refresh from server after `member_confirmed` | §1.3 | Medium | Call `GET /group/{id}/status` |
| 7 | `_handleMemberConfirmed` silently returns when `groupId` is null | §1.1 current | Low | Graceful fallback for current server (no `groupId`) |
| 8 | `join_request` foreground notification doesn't show `deviceName` | §1.3 | Low | Use payload `deviceName` when available |
| 9 | Navigation screens don't receive/use `groupId` from push | §1.3 | Low | Pass `groupId` through navigation |

---

## Task 1: Add `member_left` Push Notification Handler

**Context:** Protocol §3.1/§3.2 defines `member_left` sent to remaining members when someone leaves or is removed. The client must handle this by removing the member from local state and updating UI. Server hasn't implemented this yet (🔜), but client should be ready.

**Files:**
- Modify: `lib/infrastructure/sync/push_notification_service.dart` (add case in switch)
- Modify: `lib/infrastructure/sync/sync_trigger_service.dart` (add handler + event type)
- Modify: `lib/features/family_sync/domain/repositories/group_repository.dart` (add `removeMember` if missing)
- Test: `test/infrastructure/sync/push_notification_service_test.dart`
- Test: `test/infrastructure/sync/sync_trigger_service_test.dart`

**Step 1: Write failing test for SyncTriggerService `member_left` handler**

In `test/infrastructure/sync/sync_trigger_service_test.dart`, add a new group:

```dart
group('member_left handling', () {
  test('removes member from local group and emits event', () async {
    // Arrange: set up an active group with 2 members
    when(mockGroupRepo.getActiveGroup()).thenAnswer((_) async => testActiveGroup);
    when(mockGroupRepo.getGroupById(any)).thenAnswer((_) async => testActiveGroup);
    when(mockGroupRepo.updateMembers(any, any)).thenAnswer((_) async {});

    // Act
    await service.handleMessage({
      'type': 'member_left',
      'groupId': testGroupId,
      'deviceId': 'leaving-device-id',
      'reason': 'left',
    });

    // Assert
    verify(mockGroupRepo.updateMembers(testGroupId, any)).called(1);

    final event = service.takePendingEvent();
    expect(event, isNotNull);
    expect(event!.type, SyncTriggerEventType.memberLeft);
    expect(event.groupId, testGroupId);
  });

  test('handles removed member that is self - deactivates group', () async {
    when(mockGroupRepo.getActiveGroup()).thenAnswer((_) async => testActiveGroup);
    when(mockGroupRepo.deactivateGroup(any)).thenAnswer((_) async {});

    await service.handleMessage({
      'type': 'member_left',
      'groupId': testGroupId,
      'deviceId': localDeviceId, // self
      'reason': 'removed',
    });

    verify(mockGroupRepo.deactivateGroup(testGroupId)).called(1);
  });
});
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/infrastructure/sync/sync_trigger_service_test.dart --name "member_left"`
Expected: FAIL — `SyncTriggerEventType.memberLeft` doesn't exist

**Step 3: Add `memberLeft` event type to SyncTriggerService**

In `lib/infrastructure/sync/sync_trigger_service.dart`:

1. Add `memberLeft` to `SyncTriggerEventType` enum
2. Add `SyncTriggerEvent.memberLeft` named constructor
3. Add `_handleMemberLeft` method:
   - Extract `groupId`, `deviceId`, `reason` from data
   - If `deviceId` matches local device AND `reason == 'removed'` → call `deactivateGroup(groupId)`
   - Otherwise → get current group → filter out the member → call `updateMembers(groupId, filteredMembers)`
   - Publish `SyncTriggerEvent.memberLeft(groupId: groupId)`
4. Register handler in `initialize()` via `_pushNotificationService.registerHandlers(..., onMemberLeft: _handleMemberLeft)`

**Step 4: Add `member_left` case to PushNotificationService switch**

In `lib/infrastructure/sync/push_notification_service.dart`:

1. Add `PushMessageHandler? _onMemberLeft` field
2. Add `onMemberLeft` parameter to `registerHandlers()`
3. Add case `'member_left':` in `_handleIncomingMessage` switch — calls handler, silent (no UI notification)

**Step 5: Run tests to verify they pass**

Run: `flutter test test/infrastructure/sync/sync_trigger_service_test.dart --name "member_left"`
Expected: PASS

**Step 6: Write failing test for PushNotificationService routing**

In `test/infrastructure/sync/push_notification_service_test.dart`, add test:

```dart
test('routes member_left to onMemberLeft handler', () async {
  final completer = Completer<Map<String, dynamic>>();
  service.registerHandlers(onMemberLeft: (data) async { completer.complete(data); });

  await service.handleMessage({'type': 'member_left', 'groupId': 'g1', 'deviceId': 'd1', 'reason': 'left'});

  final data = await completer.future;
  expect(data['type'], 'member_left');
  expect(data['groupId'], 'g1');
});
```

**Step 7: Run test to verify it passes**

Run: `flutter test test/infrastructure/sync/push_notification_service_test.dart --name "member_left"`
Expected: PASS (already wired in Step 4)

**Step 8: Commit**

```bash
git add lib/infrastructure/sync/push_notification_service.dart \
        lib/infrastructure/sync/sync_trigger_service.dart \
        test/infrastructure/sync/push_notification_service_test.dart \
        test/infrastructure/sync/sync_trigger_service_test.dart
git commit -m "feat(family_sync): add member_left push notification handler

Prepare client for protocol §3.1/§3.2 member_left event.
Handles both 'left' (voluntary) and 'removed' (by owner) cases.
Self-removal triggers group deactivation."
```

---

## Task 2: Add `group_dissolved` Push Notification Handler

**Context:** Protocol §3.3 defines `group_dissolved` sent to all members (except Owner) when Owner dissolves the group. Client must deactivate the group locally and navigate to home.

**Files:**
- Modify: `lib/infrastructure/sync/push_notification_service.dart`
- Modify: `lib/infrastructure/sync/sync_trigger_service.dart`
- Test: `test/infrastructure/sync/push_notification_service_test.dart`
- Test: `test/infrastructure/sync/sync_trigger_service_test.dart`

**Step 1: Write failing test**

In `test/infrastructure/sync/sync_trigger_service_test.dart`:

```dart
group('group_dissolved handling', () {
  test('deactivates group locally and emits event', () async {
    when(mockGroupRepo.getActiveGroup()).thenAnswer((_) async => testActiveGroup);
    when(mockGroupRepo.deactivateGroup(any)).thenAnswer((_) async {});
    when(mockQueueManager.clearQueue()).thenAnswer((_) async {});

    await service.handleMessage({
      'type': 'group_dissolved',
      'groupId': testGroupId,
    });

    verify(mockGroupRepo.deactivateGroup(testGroupId)).called(1);
    verify(mockQueueManager.clearQueue()).called(1);

    final event = service.takePendingEvent();
    expect(event!.type, SyncTriggerEventType.groupDissolved);
    expect(event.groupId, testGroupId);
  });
});
```

**Step 2: Run test — should fail**

**Step 3: Implement `groupDissolved` in SyncTriggerService**

1. Add `groupDissolved` to `SyncTriggerEventType`
2. Add `SyncTriggerEvent.groupDissolved` constructor
3. Add `_handleGroupDissolved`:
   - Extract `groupId` from data
   - Verify active group matches `groupId`
   - Call `_queueManager.clearQueue()` then `_groupRepo.deactivateGroup(groupId)`
   - Publish `SyncTriggerEvent.groupDissolved(groupId: groupId)`
4. Register handler in push notification service

**Step 4: Add `group_dissolved` case to PushNotificationService switch**

Same pattern as Task 1 — silent push, no visible notification, just calls handler.

**Step 5: Run tests — should pass**

**Step 6: Add PushNotificationService routing test**

**Step 7: Commit**

```bash
git commit -m "feat(family_sync): add group_dissolved push notification handler

Prepare client for protocol §3.3 group_dissolved event.
Deactivates group locally and clears sync queue."
```

---

## Task 3: Add Navigation Intents for `member_left` and `group_dissolved`

**Context:** When `member_left` (self removed) or `group_dissolved` happens, the app should navigate the user back to the home/settings screen. The existing `PushNavigationIntent` and `FamilySyncNotificationRouteListener` need to support these new destinations.

**Files:**
- Modify: `lib/infrastructure/sync/push_notification_service.dart` (add new destinations)
- Modify: `lib/features/family_sync/presentation/widgets/family_sync_notification_route_listener.dart`
- Test: `test/widget/features/family_sync/presentation/widgets/family_sync_notification_route_listener_test.dart`

**Step 1: Write failing test for navigation on group_dissolved**

```dart
test('pops to root on groupDissolved navigation intent', () async {
  // Verify that receiving a groupDissolved intent pops back to root
});
```

**Step 2: Add `groupDissolved` and `memberRemoved` to `PushNavigationDestination` enum**

In `push_notification_service.dart`:
- Add `PushNavigationDestination.groupDissolved`
- Add `PushNavigationDestination.memberRemoved`
- Add corresponding `PushNavigationIntent` named constructors
- Update `_intentForMessage` to map `member_left` (when self + reason=removed) and `group_dissolved` to new destinations

**Step 3: Update FamilySyncNotificationRouteListener**

In `family_sync_notification_route_listener.dart`:
- Handle `groupDissolved` / `memberRemoved` → `Navigator.of(context).popUntil((route) => route.isFirst)` + show snackbar
- Update SyncStatusNotifier to `SyncStatus.unpaired`

**Step 4: Run tests — should pass**

**Step 5: Commit**

```bash
git commit -m "feat(family_sync): add navigation for member_left and group_dissolved

Navigate back to home when user is removed from group or group is dissolved.
Shows informational snackbar to explain what happened."
```

---

## Task 4: Align Operation Naming with Protocol

**Context:** Protocol §2.3 defines operations as `{op: "create"|"update"|"delete", entityType: "bill"|"category"|"budget", entityId, data, timestamp}`. Current code uses `{op: "insert"|"update"|"delete", table: "transactions", data|id}`. Must align.

**Files:**
- Modify: `lib/infrastructure/sync/sync_trigger_service.dart` (change operation format)
- Modify: `lib/application/family_sync/pull_sync_use_case.dart` (parse both old and new formats)
- Test: `test/infrastructure/sync/sync_trigger_service_test.dart`
- Test: `test/unit/application/family_sync/pull_sync_use_case_test.dart`

**Step 1: Write failing test for new operation format**

In `test/infrastructure/sync/sync_trigger_service_test.dart`:

```dart
test('onTransactionCreated builds protocol-compliant operation', () async {
  when(mockGroupRepo.getActiveGroup()).thenAnswer((_) async => testActiveGroup);

  await service.onTransactionCreated({'id': 'tx-1', 'amount': 1000, 'category': 'food'});

  final captured = verify(mockPushSync.execute(
    operations: captureAnyNamed('operations'),
    vectorClock: anyNamed('vectorClock'),
  )).captured.first as List<Map<String, dynamic>>;

  expect(captured[0]['op'], 'create');  // NOT 'insert'
  expect(captured[0]['entityType'], 'bill');  // NOT 'table': 'transactions'
  expect(captured[0]['entityId'], 'tx-1');
  expect(captured[0]['data'], isNotNull);
  expect(captured[0]['timestamp'], isA<int>());
});
```

**Step 2: Run — should fail (currently produces `op: 'insert'`)**

**Step 3: Update SyncTriggerService operation format**

Change convenience methods:

```dart
Future<void> onTransactionCreated(Map<String, dynamic> transactionData) async {
  await onTransactionChanged(operations: [
    {
      'op': 'create',
      'entityType': 'bill',
      'entityId': transactionData['id'] as String,
      'data': transactionData,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    },
  ]);
}

Future<void> onTransactionUpdated(Map<String, dynamic> transactionData) async {
  await onTransactionChanged(operations: [
    {
      'op': 'update',
      'entityType': 'bill',
      'entityId': transactionData['id'] as String,
      'data': transactionData,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    },
  ]);
}

Future<void> onTransactionDeleted(String transactionId) async {
  await onTransactionChanged(operations: [
    {
      'op': 'delete',
      'entityType': 'bill',
      'entityId': transactionId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    },
  ]);
}
```

**Step 4: Update PullSyncUseCase to handle both formats**

In the apply logic, accept both `table`/`op:insert` (legacy) and `entityType`/`op:create` (protocol):

```dart
// Normalize legacy format to protocol format
String normalizeOp(String op) => op == 'insert' ? 'create' : op;
String normalizeEntityType(Map<String, dynamic> op) =>
    (op['entityType'] as String?) ??
    (op['table'] == 'transactions' ? 'bill' : op['table'] as String? ?? 'bill');
```

**Step 5: Run tests — should pass**

**Step 6: Commit**

```bash
git commit -m "feat(sync): align operation format with protocol §2.3

Change op naming: insert→create, table→entityType.
Add entityId and timestamp fields per protocol spec.
PullSync handles both legacy and new formats for backward compat."
```

---

## Task 5: Add Sync Message Envelope (`syncType`, `syncId`)

**Context:** Protocol §2.1 defines the sync payload envelope as `{syncType, syncId, operations[], vectorClock}`. Current code sends just `operations[]` as the encrypted payload and `vectorClock` as a separate API parameter. Need to wrap in the protocol-defined envelope.

**Files:**
- Modify: `lib/application/family_sync/push_sync_use_case.dart` (wrap in envelope)
- Modify: `lib/application/family_sync/pull_sync_use_case.dart` (unwrap envelope)
- Modify: `lib/application/family_sync/full_sync_use_case.dart` (pass `syncType: 'full'`)
- Test: `test/unit/application/family_sync/push_sync_use_case_test.dart`
- Test: `test/unit/application/family_sync/pull_sync_use_case_test.dart`

**Step 1: Write failing test for PushSyncUseCase envelope**

```dart
test('wraps operations in protocol envelope before encryption', () async {
  // Verify the plaintext passed to E2EE contains syncType, syncId, operations, vectorClock
  when(mockE2ee.encryptForGroup(
    plaintext: captureAnyNamed('plaintext'),
    groupKeyBase64: anyNamed('groupKeyBase64'),
  )).thenReturn('encrypted');

  await useCase.execute(
    operations: [{'op': 'create', 'entityType': 'bill', 'entityId': 'tx-1', 'data': {}, 'timestamp': 123}],
    vectorClock: {'device-a': 5},
  );

  final plaintext = verify(mockE2ee.encryptForGroup(
    plaintext: captureAnyNamed('plaintext'),
    groupKeyBase64: anyNamed('groupKeyBase64'),
  )).captured.last as String;

  final envelope = jsonDecode(plaintext) as Map<String, dynamic>;
  expect(envelope['syncType'], 'incremental');
  expect(envelope['syncId'], isA<String>()); // UUID
  expect(envelope['operations'], hasLength(1));
  expect(envelope['vectorClock'], {'device-a': 5});
});
```

**Step 2: Run — should fail**

**Step 3: Implement envelope in PushSyncUseCase**

```dart
final envelope = {
  'syncType': syncType,  // 'full' or 'incremental' (new parameter)
  'syncId': _uuid.v4(),
  'operations': operations,
  'vectorClock': vectorClock,
};
final plaintext = jsonEncode(envelope);
final encrypted = _e2eeService.encryptForGroup(
  plaintext: plaintext,
  groupKeyBase64: group.groupKey!,
);
```

Add `syncType` parameter (default `'incremental'`) to `PushSyncUseCase.execute()`.

**Step 4: Update FullSyncUseCase to pass `syncType: 'full'`**

```dart
await _pushSync.execute(
  operations: chunk,
  vectorClock: {'full_sync': i ~/ _chunkSize},
  syncType: 'full',
);
```

**Step 5: Update PullSyncUseCase to unwrap envelope**

After decryption, detect if payload is an envelope (has `syncType` key) or raw operations list (legacy):

```dart
final decoded = jsonDecode(plaintext);
List<dynamic> operations;
if (decoded is Map && decoded.containsKey('syncType')) {
  // Protocol envelope format
  operations = decoded['operations'] as List;
  // Could use syncId for deduplication in future
} else if (decoded is List) {
  // Legacy format: raw operations list
  operations = decoded;
}
```

**Step 6: Run tests — should pass**

**Step 7: Commit**

```bash
git commit -m "feat(sync): add protocol §2.1 sync message envelope

Wrap operations in {syncType, syncId, operations, vectorClock} envelope.
PullSync handles both envelope and legacy raw list formats.
FullSync passes syncType='full', incremental uses syncType='incremental'."
```

---

## Task 6: `member_confirmed` Graceful Fallback When `groupId` Is Missing

**Context:** Current server sends `{type: "member_confirmed"}` without `groupId` (Protocol §1.1 current state). `_handleMemberConfirmed` silently returns when `groupId == null`. For the current server, we should fall back to finding any pending/confirming group.

**Files:**
- Modify: `lib/infrastructure/sync/sync_trigger_service.dart`
- Test: `test/infrastructure/sync/sync_trigger_service_test.dart`

**Step 1: Write failing test**

```dart
test('handles member_confirmed without groupId by finding any pending group', () async {
  when(mockGroupRepo.getPendingGroup()).thenAnswer((_) async => testConfirmingGroup);
  when(mockGroupRepo.confirmLocalGroup(any)).thenAnswer((_) async {});
  when(mockPullSync.execute()).thenAnswer((_) async => testPullResult);

  await service.handleMessage({
    'type': 'member_confirmed',
    // No groupId! Current server behavior.
  });

  verify(mockGroupRepo.confirmLocalGroup(testConfirmingGroup.groupId)).called(1);
  verify(mockPullSync.execute()).called(1);
});
```

**Step 2: Run — should fail (current code returns early when groupId is null)**

**Step 3: Modify `_handleMemberConfirmed`**

```dart
Future<void> _handleMemberConfirmed(Map<String, dynamic> data) async {
  final groupId = data['groupId'] as String?;

  try {
    final group = await _groupRepo.getPendingGroup();
    if (group == null) return;

    // If server provides groupId, verify it matches. If not, use the pending group.
    if (groupId != null && group.groupId != groupId) return;

    final effectiveGroupId = groupId ?? group.groupId;
    await _groupRepo.confirmLocalGroup(effectiveGroupId);
    await _pullSync.execute();
    _publishEvent(SyncTriggerEvent.memberConfirmed(groupId: effectiveGroupId));
  } catch (e) {
    if (kDebugMode) {
      debugPrint('SyncTrigger: member confirmation failed: $e');
    }
  }
}
```

**Step 4: Run tests — should pass**

**Step 5: Apply same pattern to `_handleJoinRequest`**

Current `_handleJoinRequest` just publishes event with `groupId` (nullable). No change needed — it already handles null groupId gracefully.

**Step 6: Commit**

```bash
git commit -m "fix(sync): handle member_confirmed without groupId

Current server doesn't include groupId in push payload (protocol §1.1).
Fall back to finding any pending/confirming group when groupId is absent.
Maintains forward compatibility for when server adds groupId."
```

---

## Task 7: WaitingApprovalScreen Auto-Navigation on `member_confirmed`

**Context:** After joining a group, the joiner sees `WaitingApprovalScreen`. When Owner approves, a `member_confirmed` push arrives. Currently, the screen has no push listener — user must manually refresh. Per protocol §1.3, the screen should auto-navigate to `GroupManagementScreen`.

**Files:**
- Modify: `lib/features/family_sync/presentation/screens/waiting_approval_screen.dart`
- Test: `test/widget/features/family_sync/presentation/screens/waiting_approval_screen_test.dart`

**Step 1: Write failing test**

```dart
test('auto-navigates to GroupManagementScreen on memberConfirmed event', () async {
  // Mock SyncTriggerService to emit memberConfirmed event
  // Verify Navigator.pushReplacement to GroupManagementScreen is called
});
```

**Step 2: Implement event listener in WaitingApprovalScreen**

Add a `StreamSubscription` to `SyncTriggerService.events`:

```dart
late final StreamSubscription<SyncTriggerEvent> _eventSubscription;

@override
void initState() {
  super.initState();
  _loadGroup();

  final syncTrigger = ref.read(syncTriggerServiceProvider);
  _eventSubscription = syncTrigger.events.listen((event) {
    if (!mounted) return;
    if (event.type == SyncTriggerEventType.memberConfirmed) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const GroupManagementScreen()),
      );
    }
  });
}

@override
void dispose() {
  _eventSubscription.cancel();
  super.dispose();
}
```

**Step 3: Run tests — should pass**

**Step 4: Commit**

```bash
git commit -m "feat(family_sync): auto-navigate WaitingApprovalScreen on member_confirmed

Listen to SyncTriggerService events stream. When memberConfirmed fires,
automatically navigate to GroupManagementScreen instead of requiring
manual refresh. Implements protocol §1.3 client behavior."
```

---

## Task 8: Refresh Group Status from Server After `member_confirmed`

**Context:** Protocol §1.3 says after `member_confirmed`, the new member should call `GET /group/{groupId}/status` to get the full group info (member list, public keys). Currently, `_handleMemberConfirmed` only transitions local status and pulls sync. The member list in local DB may be stale.

**Files:**
- Modify: `lib/infrastructure/sync/sync_trigger_service.dart`
- Modify: `lib/infrastructure/sync/relay_api_client.dart` (verify `getGroupStatus` response parsing)
- Modify: `lib/data/repositories/group_repository_impl.dart` (add method to refresh from server response)
- Test: `test/infrastructure/sync/sync_trigger_service_test.dart`

**Step 1: Write failing test**

```dart
test('refreshes group status from server after member_confirmed', () async {
  when(mockGroupRepo.getPendingGroup()).thenAnswer((_) async => testConfirmingGroup);
  when(mockGroupRepo.confirmLocalGroup(any)).thenAnswer((_) async {});
  when(mockApiClient.getGroupStatus(any)).thenAnswer((_) async => {
    'groupId': testGroupId,
    'members': [
      {'deviceId': 'owner-id', 'publicKey': 'pk1', 'deviceName': 'Owner Phone', 'role': 'owner', 'status': 'active'},
      {'deviceId': 'my-id', 'publicKey': 'pk2', 'deviceName': 'My Phone', 'role': 'member', 'status': 'active'},
    ],
  });
  when(mockGroupRepo.updateMembers(any, any)).thenAnswer((_) async {});
  when(mockPullSync.execute()).thenAnswer((_) async => testPullResult);

  await service.handleMessage({
    'type': 'member_confirmed',
    'groupId': testGroupId,
  });

  verify(mockApiClient.getGroupStatus(testGroupId)).called(1);
  verify(mockGroupRepo.updateMembers(testGroupId, any)).called(1);
});
```

**Step 2: Run — should fail**

**Step 3: Add `RelayApiClient` dependency to SyncTriggerService**

Add `relayApiClient` parameter to constructor. After `confirmLocalGroup`, call:

```dart
try {
  final status = await _apiClient.getGroupStatus(effectiveGroupId);
  final members = (status['members'] as List?)
      ?.map((m) => GroupMember(
            deviceId: m['deviceId'] as String,
            publicKey: m['publicKey'] as String,
            deviceName: m['deviceName'] as String,
            role: m['role'] as String,
            status: m['status'] as String,
          ))
      .toList();
  if (members != null) {
    await _groupRepo.updateMembers(effectiveGroupId, members);
  }
} catch (e) {
  // Non-fatal: group status refresh is best-effort
  if (kDebugMode) {
    debugPrint('SyncTrigger: group status refresh failed: $e');
  }
}
```

**Step 4: Update provider wiring**

In `sync_providers.dart`, add `relayApiClient` to `SyncTriggerService` constructor call.

**Step 5: Run tests — should pass**

**Step 6: Commit**

```bash
git commit -m "feat(sync): refresh group status from server after member_confirmed

Call GET /group/{groupId}/status after local confirmation to get
up-to-date member list and public keys. Best-effort: failure doesn't
block the confirmation flow. Implements protocol §1.3 client behavior."
```

---

## Task 9: Use `deviceName` from Push Payload in Foreground Notification

**Context:** Protocol §1.3 target payload includes `deviceName` for `join_request`. When server eventually sends it, use it in the notification body instead of generic localized text.

**Files:**
- Modify: `lib/infrastructure/sync/push_notification_service.dart` (update `_showForegroundNotification`)
- Test: `test/infrastructure/sync/push_notification_service_test.dart`

**Step 1: Write failing test**

```dart
test('uses deviceName from payload in join_request notification body', () async {
  await service.handleMessage(
    {'type': 'join_request', 'groupId': 'g1', 'deviceName': 'Alice iPhone'},
    source: foreground,
  );

  verify(mockLocalNotification.show(
    id: 1001,
    title: anyNamed('title'),
    body: contains('Alice iPhone'), // Should include device name
    payload: anyNamed('payload'),
  )).called(1);
});
```

**Step 2: Modify `_showForegroundNotification`**

```dart
case 'join_request':
case 'pair_request':
  final deviceName = data['deviceName'] as String?;
  await _localNotificationClient.show(
    id: 1001,
    title: l10n.familySyncNewRequest,
    body: deviceName != null
        ? l10n.familySyncJoinRequestWithName(deviceName) // new l10n key
        : l10n.familySyncJoinRequestNotificationBody,
    payload: data,
  );
```

**Step 3: Add l10n key**

Add to all 3 ARB files:
- `familySyncJoinRequestWithName`: ja `{deviceName} があなたの家計簿に参加したいです` / en `{deviceName} wants to join your family ledger` / zh `{deviceName} 想要加入你的家庭账本`

**Step 4: Run `flutter gen-l10n` then tests**

**Step 5: Commit**

```bash
git commit -m "feat(family_sync): use deviceName in join_request notification

When server provides deviceName in push payload, display it in the
notification body. Falls back to generic text for current server.
Adds l10n key familySyncJoinRequestWithName for all 3 locales."
```

---

## Task 10: Pass `groupId` Through Navigation to Screens

**Context:** `FamilySyncNotificationRouteListener` currently navigates to `MemberApprovalScreen()` and `GroupManagementScreen()` without passing `groupId`. When the push intent contains a `groupId`, it should be forwarded.

**Files:**
- Modify: `lib/features/family_sync/presentation/widgets/family_sync_notification_route_listener.dart`
- Modify: `lib/features/family_sync/presentation/screens/member_approval_screen.dart` (accept optional groupId)
- Test: `test/widget/features/family_sync/presentation/widgets/family_sync_notification_route_listener_test.dart`

**Step 1: Write failing test**

```dart
test('passes groupId from push intent to MemberApprovalScreen', () async {
  // Emit intent with groupId, verify MemberApprovalScreen receives it
});
```

**Step 2: Add optional `groupId` parameter to MemberApprovalScreen**

```dart
class MemberApprovalScreen extends ConsumerStatefulWidget {
  const MemberApprovalScreen({super.key, this.groupId});
  final String? groupId;
  // Use groupId to fetch specific group, falling back to getActiveGroup
}
```

**Step 3: Update FamilySyncNotificationRouteListener**

```dart
case PushNavigationDestination.memberApproval:
  Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => MemberApprovalScreen(groupId: intent.groupId),
  ));
case PushNavigationDestination.groupManagement:
  Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => GroupManagementScreen(groupId: intent.groupId),
  ));
```

**Step 4: Run tests — should pass**

**Step 5: Commit**

```bash
git commit -m "feat(family_sync): pass groupId from push to navigation screens

Forward groupId from PushNavigationIntent to MemberApprovalScreen
and GroupManagementScreen. Prepares for multi-group support and
ensures correct group context from push notifications."
```

---

## Task 11: Run Full Test Suite and Fix Regressions

**Files:** All modified files from Tasks 1-10

**Step 1: Run analyzer**

```bash
flutter analyze
```

Expected: 0 issues. Fix any warnings.

**Step 2: Run full test suite**

```bash
flutter test
```

Fix any failures.

**Step 3: Run format check**

```bash
dart format --set-exit-if-changed .
```

**Step 4: Run code generation (if Freezed/Riverpod files changed)**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

**Step 5: Commit any fixes**

```bash
git commit -m "fix: resolve test regressions from protocol alignment changes"
```

---

## Not In Scope (Server-Side Changes Needed)

These items from PROTOCOL.md §6 require server modifications and are **not** part of this client-side plan:

1. **Push payload enhancement** — Server adding `groupId` to all push types (§1.2)
2. **Server sending `member_left` push** — In Leave/Remove handlers (§6.2)
3. **Server sending `group_dissolved` push** — In Deactivate handler (§6.2)
4. **`deviceName` in `join_request` push body** — Server using `deviceName` instead of `deviceID` (§6.3)
5. **PushNotifier interface refactoring** — Server-side `PushRequest` struct (§6.1)

The client changes in this plan make the app **forward-compatible** — when the server implements these features, the client will work without additional changes.

---

## Deferred (Future Tasks)

These are identified gaps that don't block protocol alignment but should be addressed later:

1. **CRDT apply logic** — `sync_providers.dart` TODO at line 34-36 (wiring `applyOperations`)
2. **Full sync `fetchAllTransactions`** — `sync_providers.dart` TODO at line 45-48
3. **Vector Clock conflict resolution** — Protocol §2.4 LWW strategy not implemented
4. **`syncId` deduplication** — Envelope includes `syncId` but receiver doesn't deduplicate
5. **Existing member full sync push** — Protocol §2.2 says other active members should also push full data to new member on `sync_available` after confirm; current code only pulls

---

## Execution Order & Dependencies

```
Task 1 (member_left handler)        ─┐
Task 2 (group_dissolved handler)     ─┼── Task 3 (navigation intents) depends on 1 & 2
                                      │
Task 4 (operation naming)            ─┤
Task 5 (sync envelope)              ─┘── Independent, no deps on 1-3

Task 6 (graceful groupId fallback)   ── Independent
Task 7 (waiting screen auto-nav)     ── Depends on Task 1/2 (uses event types)
Task 8 (group status refresh)        ── Independent
Task 9 (deviceName in notification)  ── Independent
Task 10 (groupId in navigation)      ── Depends on Task 3

Task 11 (full regression test)       ── Must be last
```

Parallelizable groups:
- **Group A (can run in parallel):** Tasks 1+2, then Task 3
- **Group B (can run in parallel):** Tasks 4+5
- **Group C (can run in parallel):** Tasks 6, 8, 9
- **Sequential:** Task 7 after Group A, Task 10 after Task 3, Task 11 last
