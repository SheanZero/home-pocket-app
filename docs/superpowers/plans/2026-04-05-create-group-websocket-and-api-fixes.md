# CreateGroupScreen WebSocket + API Alignment Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add WebSocket realtime `join_request` listening to CreateGroupScreen so the owner sees a join request immediately, and fix API request/response mismatches against `docs/server/API_PROTOCOL.md`.

**Architecture:** CreateGroupScreen connects WebSocket after group creation. On `join_request` event, fetches group status from API to populate local DB with pending member info, then navigates to MemberApprovalScreen. Additionally, fix `confirm-join` request body to match server spec (remove `deviceId` from body, it's in auth header).

**Tech Stack:** Flutter, Riverpod, WebSocketService (existing), RelayApiClient (existing)

---

## Issues Found (vs API_PROTOCOL.md)

| # | File | Issue | Severity |
|---|------|-------|----------|
| 1 | `create_group_screen.dart` | No WebSocket → owner gets no realtime join notification | **HIGH** |
| 2 | `relay_api_client.dart:162-170` | `confirmJoin` sends `{deviceId, confirmed}` but spec says `{confirmed, displayName?, avatarEmoji?, avatarImageHash?}`. `deviceId` is redundant (auth header) | MEDIUM |
| 3 | `websocket_service.dart:188-206` | `group_status` event from server (sent on auth success) is silently dropped — not parsed or stored | MEDIUM |
| 4 | `websocket_service.dart:29-45` | `WebSocketEvent` doesn't carry event `data` payload — can't extract joiner info from `join_request` | LOW (not needed if we fetch via API) |

---

## File Structure

| Action | File | Responsibility |
|--------|------|----------------|
| Modify | `lib/features/family_sync/presentation/screens/create_group_screen.dart` | Add WebSocket lifecycle + `join_request` → navigate to MemberApprovalScreen |
| Modify | `lib/infrastructure/sync/relay_api_client.dart` | Fix `confirmJoin` request body to match API spec |
| Modify | `lib/infrastructure/sync/websocket_service.dart` | Parse `group_status` event, expose data in WebSocketEvent |
| Create | `test/unit/features/family_sync/presentation/screens/create_group_screen_websocket_test.dart` | WebSocket integration test for CreateGroupScreen |
| Modify | `test/unit/application/family_sync/confirm_join_use_case_test.dart` | Update mock to match new `confirmJoin` signature |

---

## Task 1: Fix `confirmJoin` API request body

**Files:**
- Modify: `lib/infrastructure/sync/relay_api_client.dart:162-170`
- Modify: `lib/application/family_sync/confirm_join_use_case.dart:42-55`
- Modify: `test/unit/application/family_sync/confirm_join_use_case_test.dart`

Per `API_PROTOCOL.md` §4.4, the `confirm-join` endpoint:
- Uses auth header for device identity (no `deviceId` in body)
- Request body: `{confirmed: true, displayName?, avatarEmoji?, avatarImageHash?}`
- Response: `{success: true}` (no members)

- [ ] **Step 1: Write failing test for new confirmJoin signature**

Update test to verify `confirmJoin` is called without `deviceId` param:

```dart
// test/unit/application/family_sync/confirm_join_use_case_test.dart
// Update the mock setup — confirmJoin no longer takes deviceId
when(
  () => apiClient.confirmJoin(groupId: any(named: 'groupId')),
).thenAnswer((_) async => <String, dynamic>{'success': true});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/application/family_sync/confirm_join_use_case_test.dart -v`
Expected: FAIL — `confirmJoin` still requires `deviceId` parameter

- [ ] **Step 3: Update `RelayApiClient.confirmJoin` to match API spec**

```dart
// lib/infrastructure/sync/relay_api_client.dart
/// Joiner confirms join after previewing group info.
Future<Map<String, dynamic>> confirmJoin({
  required String groupId,
}) async {
  final response = await _post(
    '/group/$groupId/confirm-join',
    jsonEncode({'confirmed': true}),
  );
  return _parseResponse(response);
}
```

- [ ] **Step 4: Update `ConfirmJoinUseCase` — remove deviceId from confirmJoin call**

```dart
// lib/application/family_sync/confirm_join_use_case.dart
// In execute(), change:
await _apiClient.confirmJoin(
  groupId: groupId,
);
```

Note: `_keyManager.getDeviceId()` is still called to verify the device is initialized. The auth header (handled by `RelayApiClient._signer`) provides the deviceId to the server.

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/unit/application/family_sync/confirm_join_use_case_test.dart -v`
Expected: All 4 tests PASS

- [ ] **Step 6: Run `flutter analyze` to verify no issues**

Run: `flutter analyze lib/application/family_sync/confirm_join_use_case.dart lib/infrastructure/sync/relay_api_client.dart`
Expected: No issues found

- [ ] **Step 7: Commit**

```bash
git add lib/infrastructure/sync/relay_api_client.dart lib/application/family_sync/confirm_join_use_case.dart test/unit/application/family_sync/confirm_join_use_case_test.dart
git commit -m "fix: align confirmJoin request body with API spec"
```

---

## Task 2: Add `group_status` event parsing to WebSocketService

**Files:**
- Modify: `lib/infrastructure/sync/websocket_service.dart`
- Modify: existing WebSocket tests

Per `API_PROTOCOL.md`, after auth success the server immediately sends a `group_status` event containing the full `GroupStatusResponse`. Currently this is silently dropped by `_parseEvent`.

The `WebSocketEvent` class also needs a `data` field to carry the event payload.

- [ ] **Step 1: Write failing test for group_status event parsing**

```dart
// Verify that a group_status message produces a WebSocketEvent with data
test('parses group_status event with data payload', () async {
  // Send auth_success followed by group_status
  // Assert eventStream emits WebSocketEvent with type groupStatus and data
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/infrastructure/sync/websocket_service_test.dart -v --name "parses group_status"`
Expected: FAIL

- [ ] **Step 3: Add `groupStatus` to WebSocketEventType and `data` field to WebSocketEvent**

```dart
// lib/infrastructure/sync/websocket_service.dart

enum WebSocketEventType {
  memberConfirmed,
  joinRequest,
  memberLeft,
  groupDissolved,
  groupStatus, // NEW
}

class WebSocketEvent {
  const WebSocketEvent({required this.type, this.groupId, this.data});

  final WebSocketEventType type;
  final String? groupId;
  final Map<String, dynamic>? data; // NEW
  // ... update == and hashCode
}
```

- [ ] **Step 4: Update `_parseEvent` to handle `group_status` and pass through data**

```dart
WebSocketEvent? _parseEvent(String type, Map<String, dynamic> data) {
  final groupId = data['groupId'] as String?;
  final eventData = data['data'] as Map<String, dynamic>?;
  final eventType = switch (type) {
    'member_confirmed' => WebSocketEventType.memberConfirmed,
    'join_request' => WebSocketEventType.joinRequest,
    'member_left' => WebSocketEventType.memberLeft,
    'group_dissolved' => WebSocketEventType.groupDissolved,
    'group_status' => WebSocketEventType.groupStatus,
    _ => null,
  };

  if (eventType == null) {
    if (kDebugMode) {
      debugPrint('WebSocketService: unknown event type: $type');
    }
    return null;
  }

  return WebSocketEvent(type: eventType, groupId: groupId, data: eventData);
}
```

- [ ] **Step 5: Run tests**

Run: `flutter test test/unit/infrastructure/sync/websocket_service_test.dart -v`
Expected: All PASS

- [ ] **Step 6: Commit**

```bash
git add lib/infrastructure/sync/websocket_service.dart test/unit/infrastructure/sync/websocket_service_test.dart
git commit -m "feat: parse group_status event and add data field to WebSocketEvent"
```

---

## Task 3: Add WebSocket lifecycle to CreateGroupScreen

**Files:**
- Modify: `lib/features/family_sync/presentation/screens/create_group_screen.dart`

This is the core change. After group creation succeeds, connect WebSocket and listen for `join_request` events. On receiving one, fetch group status from API to populate local DB, then navigate to MemberApprovalScreen.

The pattern mirrors `MemberApprovalScreen._connectWebSocket()` and `WaitingApprovalScreen._connectWebSocket()`.

- [ ] **Step 1: Add imports and WebSocket state fields**

Add to `_CreateGroupScreenState`:

```dart
import 'dart:convert';
import '../../../../infrastructure/crypto/providers.dart';
import '../../../../infrastructure/sync/websocket_connection_state.dart';
import '../../../../infrastructure/sync/websocket_service.dart';
import '../providers/repository_providers.dart' show webSocketServiceProvider;
import 'member_approval_screen.dart';
import '../../use_cases/check_group_use_case.dart';
import '../providers/group_providers.dart' show checkGroupUseCaseProvider;

// In state class:
bool _hasNavigated = false;
StreamSubscription<WebSocketEvent>? _wsEventSubscription;
WebSocketService? _webSocketService;
```

- [ ] **Step 2: Add `_connectWebSocket` method**

```dart
Future<void> _connectWebSocket(String groupId) async {
  final ws = ref.read(webSocketServiceProvider);
  _webSocketService = ws;
  final keyManager = ref.read(keyManagerProvider);

  _wsEventSubscription = ws.eventStream.listen((event) {
    if (!mounted) return;
    if (event.type == WebSocketEventType.joinRequest) {
      unawaited(_handleJoinRequest());
    }
  });

  final deviceId = await keyManager.getDeviceId();
  if (!mounted || deviceId == null) return;

  ws.connect(
    groupId: groupId,
    deviceId: deviceId,
    signMessage: (message) async {
      final sig = await keyManager.signData(utf8.encode(message));
      return base64Encode(sig.bytes);
    },
  );
  ws.startLifecycleObservation();
}
```

- [ ] **Step 3: Add `_handleJoinRequest` method**

Fetch group status from server to update local DB with pending member info, then navigate:

```dart
bool _hasNavigated = false;

Future<void> _handleJoinRequest() async {
  if (_hasNavigated) return; // Guard against multiple rapid events

  // Fetch group status from server to update local DB with pending member
  final groupId = _groupId;
  if (groupId == null) return;

  final result = await ref.read(checkGroupUseCaseProvider).execute();
  if (!mounted || _hasNavigated) return;

  switch (result) {
    case CheckGroupInGroup():
      _hasNavigated = true;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => MemberApprovalScreen(groupId: groupId),
        ),
      );
    case CheckGroupNotInGroup():
    case CheckGroupError():
      break; // Stay on screen, will retry on next event
  }
}
```

**Note:** `CheckGroupUseCase.execute()` calls `registerDevice` internally (idempotent). While slightly wasteful, it reuses the existing tested use case and keeps CreateGroupScreen thin. If performance becomes an issue, a lighter `FetchGroupStatusUseCase` can be extracted later.

- [ ] **Step 4: Call `_connectWebSocket` after successful group creation**

In `_createGroup`, after `CreateGroupSuccess` state update:

```dart
case CreateGroupSuccess(:final groupId, :final inviteCode, :final expiresAt):
  setState(() {
    _groupId = groupId;
    _inviteCode = inviteCode;
    _expiresAt = expiresAt;
    _isLoading = false;
  });
  unawaited(_connectWebSocket(groupId)); // ADD THIS
```

- [ ] **Step 5: Add `dispose` for WebSocket cleanup**

```dart
@override
void dispose() {
  unawaited(_wsEventSubscription?.cancel());
  _webSocketService
    ?..stopLifecycleObservation()
    ..disconnect();
  super.dispose();
}
```

- [ ] **Step 6: Run `flutter analyze`**

Run: `flutter analyze lib/features/family_sync/presentation/screens/create_group_screen.dart`
Expected: No issues found

- [ ] **Step 7: Commit**

```bash
git add lib/features/family_sync/presentation/screens/create_group_screen.dart
git commit -m "feat(sync): add WebSocket join_request listener to CreateGroupScreen"
```

---

## Task 4: Write tests for CreateGroupScreen WebSocket behavior

**Files:**
- Create: `test/unit/features/family_sync/presentation/screens/create_group_screen_websocket_test.dart`

- [ ] **Step 1: Write test that verifies WebSocket connect is called after group creation**

Test that after `CreateGroupUseCase` returns success, `WebSocketService.connect` is called with the correct groupId.

- [ ] **Step 2: Write test that verifies navigation to MemberApprovalScreen on join_request**

Simulate WebSocket emitting a `join_request` event, mock `CheckGroupUseCase` to return `CheckGroupInGroup`, verify `MemberApprovalScreen` is pushed.

- [ ] **Step 3: Write test that verifies WebSocket disconnect on dispose**

Verify that `disconnect()` and `stopLifecycleObservation()` are called when screen is disposed.

- [ ] **Step 4: Run all tests**

Run: `flutter test test/unit/features/family_sync/ -v`
Expected: All PASS

- [ ] **Step 5: Commit**

```bash
git add test/unit/features/family_sync/presentation/screens/create_group_screen_websocket_test.dart
git commit -m "test: add WebSocket lifecycle tests for CreateGroupScreen"
```

---

## Task 5: Verify existing screens still work

**Files:**
- No changes — verification only

- [ ] **Step 1: Run full test suite**

Run: `flutter test`
Expected: All tests PASS

- [ ] **Step 2: Run analyzer**

Run: `flutter analyze`
Expected: No issues

- [ ] **Step 3: Verify WebSocketEvent change doesn't break existing screens**

The `data` field addition to `WebSocketEvent` is non-breaking (optional parameter with default null). The `groupStatus` enum addition doesn't affect existing switch statements because they use specific case matching (not exhaustive on the enum).

Check: `WaitingApprovalScreen` and `MemberApprovalScreen` both use `event.type == WebSocketEventType.xxx` pattern — unaffected by new enum value.

- [ ] **Step 4: Final commit if any fixups needed**

```bash
git commit -m "fix: address review feedback"
```
