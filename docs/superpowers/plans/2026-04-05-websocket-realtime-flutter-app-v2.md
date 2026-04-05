# WebSocket Realtime Group Status — Flutter App Implementation Plan (v2)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add WebSocket-based realtime notifications to the Flutter app's group join flow, with three-layer degradation (WebSocket → push → polling).

**Architecture:** New `WebSocketService` in infrastructure layer manages on-demand WebSocket connections. It feeds sync-relevant events (e.g. `member_confirmed`) into `SyncEngine` via its existing public API (`onMemberConfirmed()`). Waiting screens observe `WebSocketService.connectionStateStream` to toggle between realtime mode (WebSocket connected) and adaptive polling fallback. Event deduplication prevents double-processing when the same event arrives via both WebSocket and push notification. Note: `syncAvailable` is excluded from WebSocket per spec — it arrives only via push notifications.

**Tech Stack:** Flutter, `web_socket_channel` ^3.0.0, Riverpod, `mocktail` (tests)

**Spec:** `docs/superpowers/specs/2026-04-04-websocket-realtime-group-status-design.md`

**Supersedes:** `docs/superpowers/plans/2026-04-05-websocket-realtime-flutter-app.md` (based on deleted `SyncTriggerService`)

---

## File Structure

### New Files
| File | Responsibility |
|------|---------------|
| `lib/infrastructure/sync/websocket_connection_state.dart` | Enum: `connected`, `connecting`, `disconnected` |
| `lib/infrastructure/sync/websocket_service.dart` | WebSocket connection lifecycle, auth, heartbeat, reconnect, event parsing |
| `test/infrastructure/sync/websocket_service_test.dart` | Unit tests for WebSocketService |
| `test/application/family_sync/sync_engine_dedup_test.dart` | Deduplication tests for SyncEngine |
| `test/widget/features/family_sync/presentation/screens/waiting_approval_screen_websocket_test.dart` | Widget tests for three-layer degradation |
| `test/widget/features/family_sync/presentation/screens/member_approval_screen_websocket_test.dart` | Widget tests for MemberApprovalScreen WebSocket integration |

### Modified Files
| File | Change |
|------|--------|
| `pubspec.yaml` | Add `web_socket_channel: ^3.0.0` |
| `lib/application/family_sync/sync_engine.dart` | Add event deduplication, accept WebSocket events via existing API |
| `lib/features/family_sync/presentation/providers/repository_providers.dart` | Add `webSocketServiceProvider` |
| `lib/features/family_sync/presentation/screens/waiting_approval_screen.dart` | Add `groupId` param, WebSocket connect/disconnect, three-layer degradation |
| `lib/features/family_sync/presentation/screens/confirm_join_screen.dart` | Pass `groupId` to WaitingApprovalScreen |
| `lib/features/family_sync/presentation/screens/member_approval_screen.dart` | Add WebSocket connect/disconnect for join_request events |
| `lib/infrastructure/sync/relay_api_client.dart` | Add `wsBaseUrl` static getter |
| `test/widget/features/family_sync/presentation/screens/waiting_approval_screen_test.dart` | Add `groupId` param, WebSocket/KeyManager mock overrides |
| `test/widget/features/family_sync/presentation/screens/member_approval_screen_test.dart` | Add WebSocket mock overrides |

---

## Task 1: Add `web_socket_channel` dependency

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Add dependency**

In `pubspec.yaml` under `dependencies:`, add:

```yaml
  web_socket_channel: ^3.0.0
```

- [ ] **Step 2: Run pub get**

Run: `flutter pub get`
Expected: Resolves successfully, no version conflicts.

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add web_socket_channel dependency for WebSocket realtime notifications"
```

---

## Task 2: Create `WebSocketConnectionState` enum

**Files:**
- Create: `lib/infrastructure/sync/websocket_connection_state.dart`

- [ ] **Step 1: Write the enum file**

```dart
/// Connection state for the WebSocket realtime channel.
enum WebSocketConnectionState {
  /// Not connected. Fallback to polling.
  disconnected,

  /// Connection attempt in progress.
  connecting,

  /// Connected and authenticated. Receiving realtime events.
  connected,
}
```

- [ ] **Step 2: Verify no analyzer issues**

Run: `flutter analyze lib/infrastructure/sync/websocket_connection_state.dart`
Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
git add lib/infrastructure/sync/websocket_connection_state.dart
git commit -m "feat(sync): add WebSocketConnectionState enum"
```

---

## Task 3: Create `WebSocketService` with tests (TDD)

**Files:**
- Create: `test/infrastructure/sync/websocket_service_test.dart`
- Create: `lib/infrastructure/sync/websocket_service.dart`

- [ ] **Step 1: Write the failing test — connect, disconnect, and event parsing**

```dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/sync/websocket_connection_state.dart';
import 'package:home_pocket/infrastructure/sync/websocket_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class MockWebSocketChannel extends Mock implements WebSocketChannel {}

class MockWebSocketSink extends Mock implements WebSocketSink {}

void main() {
  group('WebSocketService', () {
    late WebSocketService service;
    late StreamController<dynamic> incomingController;
    late MockWebSocketSink sink;

    setUp(() {
      incomingController = StreamController<dynamic>.broadcast();
      sink = MockWebSocketSink();
      when(() => sink.close(any(), any())).thenAnswer((_) async {});
      when(() => sink.add(any())).thenReturn(null);

      service = WebSocketService(
        baseUrl: 'wss://sync.happypocket.app',
        channelFactory: ({required String url}) {
          final channel = MockWebSocketChannel();
          when(() => channel.stream)
              .thenAnswer((_) => incomingController.stream);
          when(() => channel.sink).thenReturn(sink);
          return channel;
        },
      );
    });

    tearDown(() async {
      service.dispose();
      await incomingController.close();
    });

    test('initial state is disconnected', () {
      expect(service.connectionState, WebSocketConnectionState.disconnected);
    });

    test('connect transitions to connecting then connected', () async {
      final states = <WebSocketConnectionState>[];
      service.connectionStateStream.listen(states.add);

      service.connect(
        groupId: 'group-1',
        deviceId: 'device-1',
        signMessage: (msg) async => 'mock-signature',
      );

      // Simulate server sending auth success
      incomingController.add(jsonEncode({
        'type': 'auth_success',
        'groupId': 'group-1',
      }));

      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(states, contains(WebSocketConnectionState.connecting));
      expect(service.connectionState, WebSocketConnectionState.connected);
    });

    test('disconnect transitions to disconnected', () async {
      service.connect(
        groupId: 'group-1',
        deviceId: 'device-1',
        signMessage: (msg) async => 'mock-signature',
      );
      incomingController.add(
        jsonEncode({'type': 'auth_success', 'groupId': 'group-1'}),
      );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      service.disconnect();

      expect(service.connectionState, WebSocketConnectionState.disconnected);
    });

    test('parses member_confirmed event from WebSocket', () async {
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
        'type': 'member_confirmed',
        'groupId': 'group-1',
        'deviceId': 'device-2',
        'timestamp': '2026-04-04T12:00:00Z',
      }));
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
      expect(events.first.type, WebSocketEventType.memberConfirmed);
      expect(events.first.groupId, 'group-1');
    });

    test('parses join_request event from WebSocket', () async {
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
        'type': 'join_request',
        'groupId': 'group-1',
        'deviceId': 'device-3',
        'timestamp': '2026-04-04T12:00:00Z',
      }));
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
      expect(events.first.type, WebSocketEventType.joinRequest);
    });

    test('ignores unknown event types', () async {
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

      incomingController
          .add(jsonEncode({'type': 'unknown_event', 'groupId': 'group-1'}));
      await Future<void>.delayed(Duration.zero);

      expect(events, isEmpty);
    });

    test('auth_error disconnects without reconnect', () async {
      service.connect(
        groupId: 'group-1',
        deviceId: 'device-1',
        signMessage: (msg) async => 'mock-sig',
      );

      incomingController.add(
        jsonEncode({'type': 'auth_error', 'message': 'invalid signature'}),
      );
      await Future<void>.delayed(Duration.zero);

      expect(service.connectionState, WebSocketConnectionState.disconnected);
    });

    test('sends auth message on connect', () async {
      service.connect(
        groupId: 'group-1',
        deviceId: 'device-1',
        signMessage: (msg) async => 'mock-signature',
      );

      await Future<void>.delayed(Duration.zero);

      final captured = verify(() => sink.add(captureAny())).captured;
      expect(captured, isNotEmpty);

      final authMessage =
          jsonDecode(captured.first as String) as Map<String, dynamic>;
      expect(authMessage['deviceId'], 'device-1');
      expect(authMessage['protocolVersion'], 1);
      expect(authMessage, contains('timestamp'));
      expect(authMessage, contains('signature'));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/infrastructure/sync/websocket_service_test.dart`
Expected: FAIL — `websocket_service.dart` does not exist.

- [ ] **Step 3: Write `WebSocketService` implementation**

```dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'websocket_connection_state.dart';

/// Factory for creating WebSocket channels (injectable for testing).
typedef WebSocketChannelFactory = WebSocketChannel Function({
  required String url,
});

/// Signature function for Ed25519 signing.
typedef SignMessageFn = Future<String> Function(String message);

/// Known event types from the WebSocket relay server.
///
/// Note: `syncAvailable` is intentionally excluded — per spec, it is
/// only delivered via push notifications, not the WebSocket channel.
enum WebSocketEventType {
  memberConfirmed,
  joinRequest,
  memberLeft,
  groupDissolved,
}

/// A parsed event received from the WebSocket relay server.
class WebSocketEvent {
  const WebSocketEvent({required this.type, this.groupId});

  final WebSocketEventType type;
  final String? groupId;

  @override
  bool operator ==(Object other) {
    return other is WebSocketEvent &&
        other.type == type &&
        other.groupId == groupId;
  }

  @override
  int get hashCode => Object.hash(type, groupId);
}

/// Manages an on-demand WebSocket connection to the relay server
/// for realtime group status notifications.
///
/// Connection is scoped to a single group and established only when
/// entering waiting/approval screens. Events are exposed as a stream
/// of [WebSocketEvent] for consumption by providers that bridge to
/// [SyncEngine] or UI navigation.
///
/// Three-layer degradation: WebSocket (primary) → push (backup) → polling (fallback).
class WebSocketService with WidgetsBindingObserver {
  WebSocketService({
    required String baseUrl,
    WebSocketChannelFactory? channelFactory,
  })  : _baseUrl = baseUrl,
        _channelFactory = channelFactory ?? _defaultChannelFactory;

  final String _baseUrl;
  final WebSocketChannelFactory _channelFactory;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _messageSubscription;
  Timer? _heartbeatTimer;
  Timer? _pongTimeoutTimer;
  Timer? _reconnectTimer;
  Timer? _backgroundDisconnectTimer;

  String? _groupId;
  String? _deviceId;
  SignMessageFn? _signMessage;

  int _reconnectAttempts = 0;
  static const _maxReconnectDelay = Duration(seconds: 30);

  var _connectionState = WebSocketConnectionState.disconnected;
  final _connectionStateController =
      StreamController<WebSocketConnectionState>.broadcast(sync: true);
  final _eventController = StreamController<WebSocketEvent>.broadcast();

  /// Current connection state.
  WebSocketConnectionState get connectionState => _connectionState;

  /// Stream of connection state changes.
  Stream<WebSocketConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  /// Stream of parsed events from the WebSocket.
  Stream<WebSocketEvent> get eventStream => _eventController.stream;

  /// Connect to the relay server WebSocket for a specific group.
  ///
  /// [signMessage] is called with the auth payload string and must return
  /// a base64-encoded Ed25519 signature.
  void connect({
    required String groupId,
    required String deviceId,
    required SignMessageFn signMessage,
  }) {
    if (_connectionState != WebSocketConnectionState.disconnected) {
      disconnect();
    }

    _groupId = groupId;
    _deviceId = deviceId;
    _signMessage = signMessage;
    _reconnectAttempts = 0;

    _doConnect();
  }

  void _doConnect() {
    _setConnectionState(WebSocketConnectionState.connecting);

    final url = '$_baseUrl/ws/group/$_groupId';
    _channel = _channelFactory(url: url);

    _messageSubscription = _channel!.stream.listen(
      _onMessage,
      onError: _onError,
      onDone: _onDone,
    );

    _authenticate();
  }

  Future<void> _authenticate() async {
    if (_channel == null || _deviceId == null || _signMessage == null) return;

    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final message = 'ws:connect:$_groupId:$_deviceId:$timestamp';
    final signature = await _signMessage!(message);

    final authMessage = jsonEncode({
      'deviceId': _deviceId,
      'timestamp': timestamp,
      'signature': signature,
      'protocolVersion': 1,
    });

    _channel!.sink.add(authMessage);
  }

  void _onMessage(dynamic raw) {
    if (raw is! String) return;

    Map<String, dynamic> data;
    try {
      data = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    final type = data['type'] as String?;
    if (type == null) return;

    // Handle auth response
    if (type == 'auth_success') {
      _setConnectionState(WebSocketConnectionState.connected);
      _reconnectAttempts = 0;
      _startHeartbeat();
      return;
    }

    if (type == 'auth_error') {
      // Auth errors are non-recoverable — do not reconnect
      _reconnectAttempts = -1; // Sentinel to prevent reconnect
      disconnect();
      return;
    }

    if (type == 'pong') {
      _pongTimeoutTimer?.cancel();
      return;
    }

    // Parse event
    final event = _parseEvent(type, data);
    if (event != null && !_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  WebSocketEvent? _parseEvent(String type, Map<String, dynamic> data) {
    final groupId = data['groupId'] as String?;
    final eventType = switch (type) {
      'member_confirmed' => WebSocketEventType.memberConfirmed,
      'join_request' => WebSocketEventType.joinRequest,
      'member_left' => WebSocketEventType.memberLeft,
      'group_dissolved' => WebSocketEventType.groupDissolved,
      _ => null,
    };

    if (eventType == null) {
      if (kDebugMode) {
        debugPrint('WebSocketService: unknown event type: $type');
      }
      return null;
    }

    return WebSocketEvent(type: eventType, groupId: groupId);
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_channel == null) return;
      _channel!.sink.add(jsonEncode({'type': 'ping'}));

      // Expect pong within 45s
      _pongTimeoutTimer?.cancel();
      _pongTimeoutTimer = Timer(const Duration(seconds: 45), () {
        if (kDebugMode) {
          debugPrint('WebSocketService: pong timeout, reconnecting');
        }
        _handleDisconnect();
      });
    });
  }

  void _onError(Object error) {
    if (kDebugMode) {
      debugPrint('WebSocketService: error: $error');
    }
    _handleDisconnect();
  }

  void _onDone() {
    _handleDisconnect();
  }

  void _handleDisconnect() {
    _cleanup();
    _setConnectionState(WebSocketConnectionState.disconnected);

    // Don't reconnect if auth failed
    if (_reconnectAttempts < 0) return;
    if (_groupId == null) return;

    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    final delay = Duration(
      milliseconds: (1000 * (1 << _reconnectAttempts))
          .clamp(1000, _maxReconnectDelay.inMilliseconds),
    );
    _reconnectAttempts++;

    if (kDebugMode) {
      debugPrint(
        'WebSocketService: reconnecting in ${delay.inSeconds}s '
        '(attempt $_reconnectAttempts)',
      );
    }

    _reconnectTimer = Timer(delay, _doConnect);
  }

  /// Disconnect from the WebSocket and stop all timers.
  void disconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _backgroundDisconnectTimer?.cancel();
    _backgroundDisconnectTimer = null;
    _cleanup();
    _groupId = null;
    _deviceId = null;
    _signMessage = null;
    _reconnectAttempts = 0;
    _setConnectionState(WebSocketConnectionState.disconnected);
  }

  void _cleanup() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _pongTimeoutTimer?.cancel();
    _pongTimeoutTimer = null;
    _messageSubscription?.cancel();
    _messageSubscription = null;
    _channel?.sink.close();
    _channel = null;
  }

  /// Dispose the service and close all streams.
  void dispose() {
    disconnect();
    unawaited(_connectionStateController.close());
    unawaited(_eventController.close());
  }

  void _setConnectionState(WebSocketConnectionState state) {
    if (_connectionState == state) return;
    _connectionState = state;
    if (!_connectionStateController.isClosed) {
      _connectionStateController.add(state);
    }
  }

  // --- App Lifecycle ---

  /// Start observing app lifecycle for background disconnect.
  void startLifecycleObservation() {
    WidgetsBinding.instance.addObserver(this);
  }

  /// Stop observing app lifecycle.
  void stopLifecycleObservation() {
    WidgetsBinding.instance.removeObserver(this);
    _backgroundDisconnectTimer?.cancel();
    _backgroundDisconnectTimer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // Schedule disconnect after 60s in background
      _backgroundDisconnectTimer?.cancel();
      _backgroundDisconnectTimer = Timer(const Duration(seconds: 60), () {
        if (kDebugMode) {
          debugPrint('WebSocketService: background timeout, disconnecting');
        }
        disconnect();
      });
    } else if (state == AppLifecycleState.resumed) {
      _backgroundDisconnectTimer?.cancel();
      _backgroundDisconnectTimer = null;
      // Reconnect if we were previously connected
      if (_groupId != null &&
          _connectionState == WebSocketConnectionState.disconnected) {
        _doConnect();
      }
    }
  }

  static WebSocketChannel _defaultChannelFactory({required String url}) {
    return WebSocketChannel.connect(Uri.parse(url));
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/infrastructure/sync/websocket_service_test.dart`
Expected: All 8 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/infrastructure/sync/websocket_service.dart test/infrastructure/sync/websocket_service_test.dart
git commit -m "feat(sync): add WebSocketService with connect/disconnect/auth/event parsing"
```

---

## Task 4: Add event deduplication to `SyncEngine`

**Files:**
- Create: `test/application/family_sync/sync_engine_dedup_test.dart`
- Modify: `lib/application/family_sync/sync_engine.dart`

**Context:** When the same event arrives via both WebSocket and push notification, `SyncEngine` should suppress duplicates. We add a deduplication window around the public event methods (`onMemberConfirmed`, `onSyncAvailable`). The dedup key is the method name — if the same method was called within the last 10 seconds, skip it.

We test dedup via the `_isDuplicate` method's observable side-effect: the `SyncEngine.statusStream`. When `onMemberConfirmed()` is called and there's an active group, `SyncEngine` emits `initialSyncing` status. If dedup suppresses the second call, only one `initialSyncing` emission occurs.

- [ ] **Step 1: Write failing deduplication test**

```dart
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/sync_engine.dart';
import 'package:home_pocket/application/family_sync/sync_orchestrator.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_member.dart';
import 'package:home_pocket/features/family_sync/domain/models/sync_status_model.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockSyncOrchestrator extends Mock implements SyncOrchestrator {}

class MockGroupRepository extends Mock implements GroupRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(SyncMode.initialSync);
  });

  group('SyncEngine deduplication', () {
    late SyncEngine engine;
    late MockSyncOrchestrator orchestrator;
    late MockGroupRepository groupRepo;

    final activeGroup = GroupInfo(
      groupId: 'group-1',
      groupName: 'Test Family',
      status: GroupStatus.active,
      role: 'member',
      members: const [
        GroupMember(
          deviceId: 'owner-1',
          publicKey: 'pk',
          deviceName: 'Phone',
          displayName: 'Owner',
          avatarEmoji: '🏠',
          role: 'owner',
          status: 'active',
        ),
      ],
      createdAt: DateTime(2026, 4, 1),
    );

    setUp(() {
      orchestrator = MockSyncOrchestrator();
      groupRepo = MockGroupRepository();
      when(() => orchestrator.needsFullPull()).thenAnswer((_) async => false);
      when(() => orchestrator.getPendingQueueCount())
          .thenAnswer((_) async => 0);
      when(() => orchestrator.execute(any()))
          .thenAnswer((_) async => const SyncOrchestratorSuccess());
      when(() => groupRepo.getActiveGroup())
          .thenAnswer((_) async => activeGroup);

      engine = SyncEngine(
        orchestrator: orchestrator,
        groupRepo: groupRepo,
      );
    });

    tearDown(() {
      engine.dispose();
    });

    test('duplicate onMemberConfirmed within 10s is suppressed', () async {
      final statuses = <SyncStatus>[];
      engine.statusStream.listen(statuses.add);

      engine.onMemberConfirmed();
      engine.onMemberConfirmed(); // duplicate — should be suppressed

      // Allow async sync request to process
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Only one initialSyncing emission (not two)
      final syncingCount =
          statuses.where((s) => s.state == SyncState.initialSyncing).length;
      expect(syncingCount, 1);
    });

    test('duplicate onSyncAvailable within 10s is suppressed', () async {
      final statuses = <SyncStatus>[];
      engine.statusStream.listen(statuses.add);

      engine.onSyncAvailable();
      engine.onSyncAvailable(); // duplicate

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final syncingCount =
          statuses.where((s) => s.state == SyncState.syncing).length;
      expect(syncingCount, 1);
    });

    test('different event types are not deduplicated', () async {
      final statuses = <SyncStatus>[];
      engine.statusStream.listen(statuses.add);

      engine.onMemberConfirmed();
      // Wait for first to start processing before sending second
      await Future<void>.delayed(const Duration(milliseconds: 50));
      engine.onSyncAvailable(); // different type — should go through

      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Both should trigger sync status changes
      final allSyncing = statuses
          .where((s) =>
              s.state == SyncState.syncing ||
              s.state == SyncState.initialSyncing)
          .length;
      expect(allSyncing, greaterThanOrEqualTo(2));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/application/family_sync/sync_engine_dedup_test.dart`
Expected: FAIL — test compiles but dedup behavior doesn't exist yet (both calls go through, producing 2 `initialSyncing` emissions).

- [ ] **Step 3: Add deduplication to `SyncEngine`**

In `lib/application/family_sync/sync_engine.dart`, add a dedup map field after the `_currentStatus` field (around line 29):

```dart
  /// Tracks event key → timestamp for cross-source deduplication.
  /// Prevents double-processing when the same event arrives via
  /// both WebSocket and push notification.
  final _recentEvents = <String, DateTime>{};
  static const _deduplicationWindow = Duration(seconds: 10);
```

Add a private dedup helper method after `_updateStatus` (around line 135):

```dart
  /// Returns true if this event should be suppressed (duplicate).
  bool _isDuplicate(String eventKey) {
    final now = DateTime.now();

    // Prune expired entries
    _recentEvents.removeWhere(
      (_, ts) => now.difference(ts) > _deduplicationWindow,
    );

    if (_recentEvents.containsKey(eventKey)) {
      return true;
    }

    _recentEvents[eventKey] = now;
    return false;
  }
```

Update the public API methods to use dedup:

```dart
  /// Push notification: syncAvailable.
  void onSyncAvailable() {
    if (_isDuplicate('syncAvailable')) return;
    _scheduler.onSyncAvailable();
  }

  /// Push notification or WebSocket: memberConfirmed (Group activated).
  void onMemberConfirmed() {
    if (_isDuplicate('memberConfirmed')) return;
    _scheduler.onMemberConfirmed();
  }
```

**Important:** Do NOT add dedup to `onTransactionChanged`, `onProfileChanged`, or `onManualSync` — those are local-only events that don't arrive from multiple sources.

- [ ] **Step 4: Run tests**

Run: `flutter test test/application/family_sync/sync_engine_dedup_test.dart`
Expected: All 3 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/application/family_sync/sync_engine.dart test/application/family_sync/sync_engine_dedup_test.dart
git commit -m "feat(sync): add event deduplication to SyncEngine"
```

---

## Task 5: Add `wsBaseUrl` helper and `webSocketServiceProvider`

**Files:**
- Modify: `lib/infrastructure/sync/relay_api_client.dart`
- Modify: `lib/features/family_sync/presentation/providers/repository_providers.dart`

**Context:** The `WebSocketService` needs a WebSocket URL derived from the REST API base URL. We add a dedicated `wsBaseUrl` getter to `RelayApiClient` for safe URL transformation. The provider is defined manually (not `@riverpod` code-gen) to support `.overrideWithValue()` in tests.

- [ ] **Step 1: Add `wsBaseUrl` to `RelayApiClient`**

In `lib/infrastructure/sync/relay_api_client.dart`, add after the `defaultBaseUrl` getter (around line 74):

```dart
  /// WebSocket base URL derived from the REST base URL.
  ///
  /// Transforms `https://sync.happypocket.app/api/v1`
  /// into `wss://sync.happypocket.app`.
  static String get wsBaseUrl {
    final uri = Uri.parse(defaultBaseUrl);
    final wsScheme = uri.scheme == 'https' ? 'wss' : 'ws';
    return '$wsScheme://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
  }
```

- [ ] **Step 2: Add `webSocketServiceProvider` to `repository_providers.dart`**

Add import at top of file:

```dart
import '../../../../infrastructure/sync/websocket_service.dart';
```

Add manual provider at end of file (outside the `part` generated code):

```dart
/// WebSocketService provider for realtime group status notifications.
///
/// Defined manually (not @riverpod) to support .overrideWithValue() in tests.
/// On-demand — screens connect/disconnect as needed.
final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  final service = WebSocketService(
    baseUrl: RelayApiClient.wsBaseUrl,
  );
  ref.onDispose(service.dispose);
  return service;
});
```

- [ ] **Step 3: Run analyzer**

Run: `flutter analyze`
Expected: No issues.

- [ ] **Step 4: Commit**

```bash
git add lib/infrastructure/sync/relay_api_client.dart lib/features/family_sync/presentation/providers/repository_providers.dart
git commit -m "feat(sync): add wsBaseUrl helper and webSocketServiceProvider"
```

---

## Task 6: Add `groupId` parameter to `WaitingApprovalScreen`

**Files:**
- Modify: `lib/features/family_sync/presentation/screens/waiting_approval_screen.dart`
- Modify: `lib/features/family_sync/presentation/screens/confirm_join_screen.dart`
- Modify: `test/widget/features/family_sync/presentation/screens/waiting_approval_screen_test.dart`

**Context:** The WebSocket connection needs a `groupId` to connect to the correct group channel. Currently `WaitingApprovalScreen` doesn't receive `groupId`. The `ConfirmJoinScreen` that navigates here has `JoinGroupVerified.groupId` available.

- [ ] **Step 1: Add `groupId` parameter to `WaitingApprovalScreen`**

In `waiting_approval_screen.dart`, update the constructor:

```dart
class WaitingApprovalScreen extends ConsumerStatefulWidget {
  const WaitingApprovalScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.ownerDisplayName,
  });

  final String groupId;
  final String groupName;
  final String ownerDisplayName;
```

- [ ] **Step 2: Pass `groupId` from `confirm_join_screen.dart`**

In `confirm_join_screen.dart`, update the navigation (around line 42):

```dart
        Navigator.pushReplacement(
          context,
          MaterialPageRoute<void>(
            builder: (_) => WaitingApprovalScreen(
              groupId: widget.result.groupId,
              groupName: widget.result.groupName,
              ownerDisplayName: widget.result.ownerDisplayName,
            ),
          ),
        );
```

- [ ] **Step 3: Update existing tests**

In `waiting_approval_screen_test.dart`, update every `WaitingApprovalScreen(` constructor call to include `groupId: 'group-1'`:

```dart
const WaitingApprovalScreen(
  groupId: 'group-1',
  groupName: 'Test Family',
  ownerDisplayName: 'Owner phone',
),
```

There are 5 occurrences in the test file — update all of them.

- [ ] **Step 4: Run tests**

Run: `flutter test test/widget/features/family_sync/presentation/screens/waiting_approval_screen_test.dart`
Expected: All 5 existing tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/family_sync/presentation/screens/waiting_approval_screen.dart lib/features/family_sync/presentation/screens/confirm_join_screen.dart test/widget/features/family_sync/presentation/screens/waiting_approval_screen_test.dart
git commit -m "feat(sync): add groupId parameter to WaitingApprovalScreen"
```

---

## Task 7: Update `WaitingApprovalScreen` with three-layer degradation

**Files:**
- Modify: `lib/features/family_sync/presentation/screens/waiting_approval_screen.dart`
- Create: `test/widget/features/family_sync/presentation/screens/waiting_approval_screen_websocket_test.dart`

**Context:** The screen currently uses a fixed 30-second polling timer + SyncEngine status listener. We add WebSocket connection management and adaptive polling:
- When WebSocket is connected → stop polling (realtime via WS)
- When WebSocket disconnects → start adaptive polling (5s → 10s → 15s → 30s)
- SyncEngine status listener stays as-is (it catches push notification events too)

- [ ] **Step 1: Write failing widget test — WebSocket connected stops polling**

```dart
import 'dart:async';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/sync_engine.dart';
import 'package:home_pocket/application/family_sync/sync_orchestrator.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/group_providers.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/sync_providers.dart';
import 'package:home_pocket/features/family_sync/presentation/screens/waiting_approval_screen.dart';
import 'package:home_pocket/features/family_sync/use_cases/check_group_use_case.dart';
import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';
import 'package:home_pocket/infrastructure/crypto/providers.dart';
import 'package:home_pocket/infrastructure/sync/websocket_connection_state.dart';
import 'package:home_pocket/infrastructure/sync/websocket_service.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/test_localizations.dart';

class MockGroupRepository extends Mock implements GroupRepository {}

class MockCheckGroupUseCase extends Mock implements CheckGroupUseCase {}

class MockSyncOrchestrator extends Mock implements SyncOrchestrator {}

class MockWebSocketService extends Mock implements WebSocketService {}

class MockKeyManager extends Mock implements KeyManager {}

void main() {
  setUpAll(() {
    registerFallbackValue(SyncMode.initialSync);
  });

  late MockGroupRepository groupRepository;
  late MockCheckGroupUseCase checkGroupUseCase;
  late SyncEngine syncEngine;
  late MockSyncOrchestrator mockOrchestrator;
  late MockWebSocketService webSocketService;
  late MockKeyManager keyManager;
  late StreamController<WebSocketConnectionState> wsStateController;

  setUp(() {
    groupRepository = MockGroupRepository();
    checkGroupUseCase = MockCheckGroupUseCase();
    mockOrchestrator = MockSyncOrchestrator();
    webSocketService = MockWebSocketService();
    keyManager = MockKeyManager();
    wsStateController = StreamController<WebSocketConnectionState>.broadcast();

    when(() => mockOrchestrator.needsFullPull()).thenAnswer((_) async => false);
    when(() => mockOrchestrator.getPendingQueueCount())
        .thenAnswer((_) async => 0);
    when(() => mockOrchestrator.execute(any()))
        .thenAnswer((_) async => const SyncOrchestratorSuccess());
    when(() => groupRepository.getActiveGroup()).thenAnswer((_) async => null);

    syncEngine = SyncEngine(
      orchestrator: mockOrchestrator,
      groupRepo: groupRepository,
    );

    when(() => checkGroupUseCase.execute())
        .thenAnswer((_) async => const CheckGroupNotInGroup());

    // WebSocket mocks
    when(() => webSocketService.connectionStateStream)
        .thenAnswer((_) => wsStateController.stream);
    when(() => webSocketService.connectionState)
        .thenReturn(WebSocketConnectionState.disconnected);
    when(() => webSocketService.connect(
          groupId: any(named: 'groupId'),
          deviceId: any(named: 'deviceId'),
          signMessage: any(named: 'signMessage'),
        )).thenReturn(null);
    when(() => webSocketService.disconnect()).thenReturn(null);
    when(() => webSocketService.startLifecycleObservation()).thenReturn(null);
    when(() => webSocketService.stopLifecycleObservation()).thenReturn(null);
    when(() => webSocketService.eventStream)
        .thenAnswer((_) => const Stream.empty());

    // KeyManager mock
    when(() => keyManager.getDeviceId())
        .thenAnswer((_) async => 'test-device-id');
    when(() => keyManager.signData(any()))
        .thenAnswer((_) async => Signature([], publicKey: SimplePublicKey([])));
  });

  tearDown(() async {
    syncEngine.dispose();
    await wsStateController.close();
  });

  List<Override> buildOverrides() => [
        groupRepositoryProvider.overrideWithValue(groupRepository),
        checkGroupUseCaseProvider.overrideWithValue(checkGroupUseCase),
        syncEngineProvider.overrideWithValue(syncEngine),
        webSocketServiceProvider.overrideWithValue(webSocketService),
        keyManagerProvider.overrideWithValue(keyManager),
      ];

  testWidgets('does not poll when WebSocket is connected', (tester) async {
    when(() => webSocketService.connectionState)
        .thenReturn(WebSocketConnectionState.connected);

    await tester.pumpWidget(
      createLocalizedWidget(
        const WaitingApprovalScreen(
          groupId: 'group-1',
          groupName: 'Test Family',
          ownerDisplayName: 'Owner',
        ),
        overrides: buildOverrides(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // Simulate WebSocket connected
    wsStateController.add(WebSocketConnectionState.connected);
    await tester.pump();

    // Wait past initial polling interval
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(seconds: 6));
    });
    await tester.pump();

    verifyNever(() => checkGroupUseCase.execute());
  });

  testWidgets('starts adaptive polling when WebSocket disconnects',
      (tester) async {
    when(() => checkGroupUseCase.execute())
        .thenAnswer((_) async => const CheckGroupNotInGroup());

    await tester.pumpWidget(
      createLocalizedWidget(
        const WaitingApprovalScreen(
          groupId: 'group-1',
          groupName: 'Test Family',
          ownerDisplayName: 'Owner',
        ),
        overrides: buildOverrides(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // WebSocket disconnected -> polling should start with 5s interval
    wsStateController.add(WebSocketConnectionState.disconnected);
    await tester.pump();

    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(seconds: 6));
    });
    await tester.pump();

    verify(() => checkGroupUseCase.execute()).called(greaterThanOrEqualTo(1));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget/features/family_sync/presentation/screens/waiting_approval_screen_websocket_test.dart`
Expected: FAIL — screen does not use WebSocket yet.

- [ ] **Step 3: Update `WaitingApprovalScreen` with three-layer degradation**

Replace the state class in `waiting_approval_screen.dart`. Keep the build method identical, only change state management.

Add these imports at the top:

```dart
import 'dart:convert';
import '../../../../infrastructure/crypto/providers.dart';
import '../../../../infrastructure/sync/websocket_connection_state.dart';
import '../../../../infrastructure/sync/websocket_service.dart';
import '../providers/repository_providers.dart';
```

Replace the `_WaitingApprovalScreenState` class (keep the `build` method as-is):

```dart
class _WaitingApprovalScreenState extends ConsumerState<WaitingApprovalScreen> {
  bool _hasNavigated = false;
  StreamSubscription<SyncStatus>? _syncSubscription;
  StreamSubscription<WebSocketConnectionState>? _wsStateSubscription;
  StreamSubscription<WebSocketEvent>? _wsEventSubscription;
  Timer? _pollingTimer;
  int _pollCount = 0;

  @override
  void initState() {
    super.initState();
    _listenForSyncStatus();
    _connectWebSocket();
  }

  void _listenForSyncStatus() {
    final engine = ref.read(syncEngineProvider);
    _syncSubscription = engine.statusStream.listen((status) {
      if (!mounted || _hasNavigated) return;
      if (status.state == SyncState.initialSyncing ||
          status.state == SyncState.synced) {
        unawaited(_verifyGroupAndNavigate());
      }
    });
  }

  Future<void> _connectWebSocket() async {
    final ws = ref.read(webSocketServiceProvider);
    final keyManager = ref.read(keyManagerProvider);

    // Route WebSocket events to SyncEngine
    final engine = ref.read(syncEngineProvider);
    _wsEventSubscription = ws.eventStream.listen((event) {
      switch (event.type) {
        case WebSocketEventType.memberConfirmed:
          engine.onMemberConfirmed();
        case WebSocketEventType.joinRequest:
        case WebSocketEventType.memberLeft:
        case WebSocketEventType.groupDissolved:
          // These are UI navigation events — handled elsewhere
          break;
      }
    });

    // Toggle polling based on WebSocket connection state
    _wsStateSubscription = ws.connectionStateStream.listen((state) {
      if (!mounted) return;
      if (state == WebSocketConnectionState.connected) {
        _stopPolling();
      } else if (state == WebSocketConnectionState.disconnected) {
        _startAdaptivePolling();
      }
    });

    // Get device ID and connect
    final deviceId = await keyManager.getDeviceId();
    if (!mounted || deviceId == null) {
      _startAdaptivePolling();
      return;
    }

    ws.connect(
      groupId: widget.groupId,
      deviceId: deviceId,
      signMessage: (message) async {
        final sig = await keyManager.signData(utf8.encode(message));
        return base64Encode(sig.bytes);
      },
    );

    // Start polling as initial fallback until WebSocket connects
    _startAdaptivePolling();
    ws.startLifecycleObservation();
  }

  void _startAdaptivePolling() {
    _pollingTimer?.cancel();
    _pollCount = 0;
    _scheduleNextPoll();
  }

  void _scheduleNextPoll() {
    if (_hasNavigated) return;

    // Adaptive backoff: 5s → 10s → 15s → 30s, then stays at 30s
    const delays = [5, 10, 15, 30];
    final delaySeconds = delays[_pollCount.clamp(0, delays.length - 1)];

    _pollingTimer = Timer(Duration(seconds: delaySeconds), () {
      if (!mounted || _hasNavigated) return;
      _pollCount++;
      unawaited(_verifyGroupAndNavigate());
      _scheduleNextPoll();
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _verifyGroupAndNavigate() async {
    if (_hasNavigated) return;

    final result = await ref.read(checkGroupUseCaseProvider).execute();
    if (!mounted || _hasNavigated) return;

    switch (result) {
      case CheckGroupInGroup(:final groupId):
        _hasNavigated = true;
        _stopPolling();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => GroupManagementScreen(groupId: groupId),
          ),
        );
      case CheckGroupNotInGroup():
        break;
      case CheckGroupError():
        break;
    }
  }

  @override
  void dispose() {
    _stopPolling();
    unawaited(_syncSubscription?.cancel());
    unawaited(_wsStateSubscription?.cancel());
    unawaited(_wsEventSubscription?.cancel());
    ref.read(webSocketServiceProvider)
      ..stopLifecycleObservation()
      ..disconnect();
    super.dispose();
  }

  // build method stays identical — no changes needed
```

- [ ] **Step 4: Run new WebSocket tests**

Run: `flutter test test/widget/features/family_sync/presentation/screens/waiting_approval_screen_websocket_test.dart`
Expected: All tests PASS.

- [ ] **Step 5: Run existing waiting_approval tests**

Run: `flutter test test/widget/features/family_sync/presentation/screens/waiting_approval_screen_test.dart`
Expected: May need to add `webSocketServiceProvider` and `keyManagerProvider` overrides. See Task 8 for fixing existing tests.

- [ ] **Step 6: Commit**

```bash
git add lib/features/family_sync/presentation/screens/waiting_approval_screen.dart test/widget/features/family_sync/presentation/screens/waiting_approval_screen_websocket_test.dart
git commit -m "feat(sync): add three-layer degradation to WaitingApprovalScreen"
```

---

## Task 8: Fix existing tests with WebSocket provider overrides

**Files:**
- Modify: `test/widget/features/family_sync/presentation/screens/waiting_approval_screen_test.dart`

**Context:** The existing `WaitingApprovalScreen` tests now fail for two reasons:
1. The screen reads `webSocketServiceProvider` and `keyManagerProvider` in `initState` — need mock overrides.
2. Polling changed from fixed 30-second intervals to adaptive 5s → 10s → 15s → 30s — timing assertions in existing tests must be updated.

- [ ] **Step 1: Add mock imports and setup**

Add imports at top of `waiting_approval_screen_test.dart`:

```dart
import 'package:cryptography/cryptography.dart';
import 'package:home_pocket/infrastructure/crypto/providers.dart';
import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';
import 'package:home_pocket/infrastructure/sync/websocket_connection_state.dart';
import 'package:home_pocket/infrastructure/sync/websocket_service.dart';
```

Add mock classes after existing mock classes:

```dart
class MockWebSocketService extends Mock implements WebSocketService {}

class MockKeyManager extends Mock implements KeyManager {}
```

In `setUp()`, add after the existing setup:

```dart
    webSocketService = MockWebSocketService();
    keyManager = MockKeyManager();

    when(() => webSocketService.connectionStateStream)
        .thenAnswer((_) => const Stream.empty());
    when(() => webSocketService.connectionState)
        .thenReturn(WebSocketConnectionState.disconnected);
    when(() => webSocketService.eventStream)
        .thenAnswer((_) => const Stream.empty());
    when(() => webSocketService.connect(
          groupId: any(named: 'groupId'),
          deviceId: any(named: 'deviceId'),
          signMessage: any(named: 'signMessage'),
        )).thenReturn(null);
    when(() => webSocketService.disconnect()).thenReturn(null);
    when(() => webSocketService.startLifecycleObservation()).thenReturn(null);
    when(() => webSocketService.stopLifecycleObservation()).thenReturn(null);
    when(() => keyManager.getDeviceId())
        .thenAnswer((_) async => 'test-device');
    when(() => keyManager.signData(any()))
        .thenAnswer((_) async => Signature([], publicKey: SimplePublicKey([])));
```

Declare the late variables alongside existing ones:

```dart
  late MockWebSocketService webSocketService;
  late MockKeyManager keyManager;
```

Add these providers to every test's `overrides` list (alongside existing ones):

```dart
webSocketServiceProvider.overrideWithValue(webSocketService),
keyManagerProvider.overrideWithValue(keyManager),
```

- [ ] **Step 2: Update polling timing in existing tests**

The test `'polls server every 30 seconds'` must be updated for adaptive polling (first poll at 5s, not 30s). Rename and adjust:

Change the test from:

```dart
  testWidgets('polls server every 30 seconds', (tester) async {
    ...
    await Future<void>.delayed(const Duration(seconds: 31));
    ...
    verify(() => checkGroupUseCase.execute()).called(1);
```

To:

```dart
  testWidgets('polls server with adaptive backoff starting at 5s', (tester) async {
    ...
    // First poll at 5s (adaptive backoff starts at 5s)
    await Future<void>.delayed(const Duration(seconds: 6));
    ...
    verify(() => checkGroupUseCase.execute()).called(1);
```

Similarly update `'stops polling after successful navigation'`:

```dart
    // Wait for first poll (5s adaptive) to fire and navigate
    await Future<void>.delayed(const Duration(seconds: 6));
    ...
    // Wait past second poll interval (10s) — should not call again after navigation
    await Future<void>.delayed(const Duration(seconds: 11));
```

- [ ] **Step 3: Run all waiting_approval tests**

Run: `flutter test test/widget/features/family_sync/presentation/screens/waiting_approval_screen_test.dart`
Expected: All 5 existing tests PASS.

- [ ] **Step 4: Run all family_sync widget tests**

Run: `flutter test test/widget/features/family_sync/`
Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add test/widget/features/family_sync/presentation/screens/waiting_approval_screen_test.dart
git commit -m "test(sync): add WebSocket mock overrides and update polling timing in existing tests"
```

---

## Task 9: Integration test — WebSocket disconnect fallback

**Files:**
- Create: `test/integration/sync/websocket_degradation_test.dart`

- [ ] **Step 1: Write integration test**

```dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/sync/websocket_connection_state.dart';
import 'package:home_pocket/infrastructure/sync/websocket_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class MockWebSocketChannel extends Mock implements WebSocketChannel {}

class MockWebSocketSink extends Mock implements WebSocketSink {}

void main() {
  test('WebSocket disconnect triggers state change for polling fallback',
      () async {
    final incomingController = StreamController<dynamic>.broadcast();
    final sink = MockWebSocketSink();
    when(() => sink.close(any(), any())).thenAnswer((_) async {});
    when(() => sink.add(any())).thenReturn(null);

    final service = WebSocketService(
      baseUrl: 'wss://test.example.com',
      channelFactory: ({required String url}) {
        final channel = MockWebSocketChannel();
        when(() => channel.stream)
            .thenAnswer((_) => incomingController.stream);
        when(() => channel.sink).thenReturn(sink);
        return channel;
      },
    );

    final states = <WebSocketConnectionState>[];
    service.connectionStateStream.listen(states.add);

    // Connect and authenticate
    service.connect(
      groupId: 'group-1',
      deviceId: 'device-1',
      signMessage: (msg) async => 'sig',
    );
    incomingController.add(
      jsonEncode({'type': 'auth_success', 'groupId': 'group-1'}),
    );
    await Future<void>.delayed(Duration.zero);

    expect(service.connectionState, WebSocketConnectionState.connected);

    // Simulate disconnect
    await incomingController.close();
    await Future<void>.delayed(Duration.zero);

    expect(service.connectionState, WebSocketConnectionState.disconnected);
    expect(states, contains(WebSocketConnectionState.disconnected));

    service.dispose();
  });

  test('WebSocket event is forwarded to eventStream', () async {
    final incomingController = StreamController<dynamic>.broadcast();
    final sink = MockWebSocketSink();
    when(() => sink.close(any(), any())).thenAnswer((_) async {});
    when(() => sink.add(any())).thenReturn(null);

    final service = WebSocketService(
      baseUrl: 'wss://test.example.com',
      channelFactory: ({required String url}) {
        final channel = MockWebSocketChannel();
        when(() => channel.stream)
            .thenAnswer((_) => incomingController.stream);
        when(() => channel.sink).thenReturn(sink);
        return channel;
      },
    );

    final events = <WebSocketEvent>[];
    service.eventStream.listen(events.add);

    service.connect(
      groupId: 'group-1',
      deviceId: 'device-1',
      signMessage: (msg) async => 'sig',
    );
    incomingController.add(
      jsonEncode({'type': 'auth_success', 'groupId': 'group-1'}),
    );
    await Future<void>.delayed(Duration.zero);

    incomingController.add(jsonEncode({
      'type': 'member_confirmed',
      'groupId': 'group-1',
    }));
    await Future<void>.delayed(Duration.zero);

    expect(events, hasLength(1));
    expect(events.first.type, WebSocketEventType.memberConfirmed);

    service.dispose();
    await incomingController.close();
  });
}
```

- [ ] **Step 2: Run test**

Run: `flutter test test/integration/sync/websocket_degradation_test.dart`
Expected: PASS.

- [ ] **Step 3: Commit**

```bash
git add test/integration/sync/websocket_degradation_test.dart
git commit -m "test(sync): add WebSocket degradation integration test"
```

---

## Task 10: Add WebSocket lifecycle to `MemberApprovalScreen`

**Files:**
- Modify: `lib/features/family_sync/presentation/screens/member_approval_screen.dart`
- Create: `test/widget/features/family_sync/presentation/screens/member_approval_screen_websocket_test.dart`
- Modify: `test/widget/features/family_sync/presentation/screens/member_approval_screen_test.dart`

**Context:** The owner's `MemberApprovalScreen` currently loads group data once with no event listening. Per the spec, it should connect to WebSocket for `join_request` events to refresh the pending members list in realtime. No polling fallback is needed — the owner can navigate away and come back. The WebSocket just makes the experience snappier.

- [ ] **Step 1: Write failing widget test**

```dart
import 'dart:async';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_member.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/group_providers.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/family_sync/presentation/screens/member_approval_screen.dart';
import 'package:home_pocket/application/family_sync/confirm_member_use_case.dart';
import 'package:home_pocket/features/family_sync/use_cases/remove_member_use_case.dart';
import 'package:home_pocket/infrastructure/crypto/providers.dart';
import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';
import 'package:home_pocket/infrastructure/sync/websocket_connection_state.dart';
import 'package:home_pocket/infrastructure/sync/websocket_service.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/test_localizations.dart';

class MockGroupRepository extends Mock implements GroupRepository {}

class MockConfirmMemberUseCase extends Mock implements ConfirmMemberUseCase {}

class MockRemoveMemberUseCase extends Mock implements RemoveMemberUseCase {}

class MockWebSocketService extends Mock implements WebSocketService {}

class MockKeyManager extends Mock implements KeyManager {}

void main() {
  late MockGroupRepository groupRepository;
  late MockConfirmMemberUseCase confirmMemberUseCase;
  late MockRemoveMemberUseCase removeMemberUseCase;
  late MockWebSocketService webSocketService;
  late MockKeyManager keyManager;
  late StreamController<WebSocketEvent> wsEventController;

  setUp(() {
    groupRepository = MockGroupRepository();
    confirmMemberUseCase = MockConfirmMemberUseCase();
    removeMemberUseCase = MockRemoveMemberUseCase();
    webSocketService = MockWebSocketService();
    keyManager = MockKeyManager();
    wsEventController = StreamController<WebSocketEvent>.broadcast();

    when(() => groupRepository.getActiveGroup()).thenAnswer(
      (_) async => GroupInfo(
        groupId: 'group-1',
        groupName: 'Test Family',
        status: GroupStatus.active,
        role: 'owner',
        groupKey: 'group-key',
        members: const [
          GroupMember(
            deviceId: 'owner-1',
            publicKey: 'pk-owner',
            deviceName: 'Owner phone',
            displayName: 'Owner phone',
            avatarEmoji: '🏠',
            role: 'owner',
            status: 'active',
          ),
          GroupMember(
            deviceId: 'member-1',
            publicKey: 'pk-member',
            deviceName: 'Kitchen tablet',
            displayName: 'Kitchen tablet',
            avatarEmoji: '🏠',
            role: 'member',
            status: 'pending',
          ),
        ],
        createdAt: DateTime(2026, 3, 1),
      ),
    );
    when(() => groupRepository.getGroupById(any()))
        .thenAnswer((_) async => null);

    when(() => confirmMemberUseCase.execute(
          groupId: any(named: 'groupId'),
          deviceId: any(named: 'deviceId'),
        )).thenAnswer((_) async => const ConfirmMemberSuccess());

    when(() => removeMemberUseCase.execute(
          groupId: any(named: 'groupId'),
          deviceId: any(named: 'deviceId'),
        )).thenAnswer((_) async => const RemoveMemberResult.success());

    // WebSocket mocks
    when(() => webSocketService.connectionStateStream)
        .thenAnswer((_) => const Stream.empty());
    when(() => webSocketService.connectionState)
        .thenReturn(WebSocketConnectionState.disconnected);
    when(() => webSocketService.eventStream)
        .thenAnswer((_) => wsEventController.stream);
    when(() => webSocketService.connect(
          groupId: any(named: 'groupId'),
          deviceId: any(named: 'deviceId'),
          signMessage: any(named: 'signMessage'),
        )).thenReturn(null);
    when(() => webSocketService.disconnect()).thenReturn(null);
    when(() => webSocketService.startLifecycleObservation()).thenReturn(null);
    when(() => webSocketService.stopLifecycleObservation()).thenReturn(null);

    // KeyManager mock
    when(() => keyManager.getDeviceId())
        .thenAnswer((_) async => 'test-device');
    when(() => keyManager.signData(any())).thenAnswer(
        (_) async => Signature([], publicKey: SimplePublicKey([])));
  });

  tearDown(() async {
    await wsEventController.close();
  });

  List<Override> buildOverrides() => [
        groupRepositoryProvider.overrideWithValue(groupRepository),
        confirmMemberUseCaseProvider.overrideWithValue(confirmMemberUseCase),
        removeMemberUseCaseProvider.overrideWithValue(removeMemberUseCase),
        webSocketServiceProvider.overrideWithValue(webSocketService),
        keyManagerProvider.overrideWithValue(keyManager),
      ];

  testWidgets('connects WebSocket on init', (tester) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        const MemberApprovalScreen(),
        overrides: buildOverrides(),
      ),
    );
    await tester.pumpAndSettle();

    verify(() => webSocketService.startLifecycleObservation()).called(1);
  });

  testWidgets('reloads group when join_request event arrives', (tester) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        const MemberApprovalScreen(),
        overrides: buildOverrides(),
      ),
    );
    await tester.pumpAndSettle();

    // First load happened
    verify(() => groupRepository.getActiveGroup()).called(1);

    // Simulate join_request WebSocket event
    wsEventController.add(
      const WebSocketEvent(
        type: WebSocketEventType.joinRequest,
        groupId: 'group-1',
      ),
    );
    await tester.pumpAndSettle();

    // Group should be reloaded
    verify(() => groupRepository.getActiveGroup()).called(1);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget/features/family_sync/presentation/screens/member_approval_screen_websocket_test.dart`
Expected: FAIL — screen does not use WebSocket.

- [ ] **Step 3: Update `MemberApprovalScreen` with WebSocket lifecycle**

In `member_approval_screen.dart`, add imports:

```dart
import 'dart:async';
import 'dart:convert';
import '../../../../infrastructure/crypto/providers.dart';
import '../../../../infrastructure/sync/websocket_service.dart';
import '../providers/repository_providers.dart' show webSocketServiceProvider;
```

Add WebSocket subscription field and update `initState` and `dispose` in `_MemberApprovalScreenState`:

```dart
  StreamSubscription<WebSocketEvent>? _wsEventSubscription;

  @override
  void initState() {
    super.initState();
    _loadGroup();
    _connectWebSocket();
  }

  Future<void> _connectWebSocket() async {
    final ws = ref.read(webSocketServiceProvider);
    final keyManager = ref.read(keyManagerProvider);
    final groupId = widget.groupId;

    // Listen for join_request events to refresh the pending list
    _wsEventSubscription = ws.eventStream.listen((event) {
      if (!mounted) return;
      if (event.type == WebSocketEventType.joinRequest) {
        _loadGroup(); // Reload to pick up new pending member
      }
    });

    // Determine groupId for WebSocket connection
    String? wsGroupId = groupId;
    if (wsGroupId == null) {
      final group = await ref.read(groupRepositoryProvider).getActiveGroup();
      wsGroupId = group?.groupId;
    }
    if (!mounted || wsGroupId == null) return;

    final deviceId = await keyManager.getDeviceId();
    if (!mounted || deviceId == null) return;

    ws.connect(
      groupId: wsGroupId,
      deviceId: deviceId,
      signMessage: (message) async {
        final sig = await keyManager.signData(utf8.encode(message));
        return base64Encode(sig.bytes);
      },
    );
    ws.startLifecycleObservation();
  }

  @override
  void dispose() {
    unawaited(_wsEventSubscription?.cancel());
    ref.read(webSocketServiceProvider)
      ..stopLifecycleObservation()
      ..disconnect();
    super.dispose();
  }
```

Remove the existing `@override void initState()` that only calls `_loadGroup()`.

- [ ] **Step 4: Run new WebSocket tests**

Run: `flutter test test/widget/features/family_sync/presentation/screens/member_approval_screen_websocket_test.dart`
Expected: All tests PASS.

- [ ] **Step 5: Fix existing member_approval_screen_test.dart**

Add mock overrides for `webSocketServiceProvider` and `keyManagerProvider` to the existing test file. Same pattern as Task 8:

Add imports:

```dart
import 'package:cryptography/cryptography.dart';
import 'package:home_pocket/infrastructure/crypto/providers.dart';
import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';
import 'package:home_pocket/infrastructure/sync/websocket_connection_state.dart';
import 'package:home_pocket/infrastructure/sync/websocket_service.dart';
```

Add mock classes:

```dart
class MockWebSocketService extends Mock implements WebSocketService {}
class MockKeyManager extends Mock implements KeyManager {}
```

Add mock setup in `setUp()` and include overrides in `buildOverrides()`.

- [ ] **Step 6: Run all member_approval tests**

Run: `flutter test test/widget/features/family_sync/presentation/screens/member_approval_screen_test.dart`
Expected: All existing tests PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/features/family_sync/presentation/screens/member_approval_screen.dart test/widget/features/family_sync/presentation/screens/member_approval_screen_websocket_test.dart test/widget/features/family_sync/presentation/screens/member_approval_screen_test.dart
git commit -m "feat(sync): add WebSocket lifecycle to MemberApprovalScreen"
```

---

## Task 11: Run full test suite and analyzer

**Files:** None (verification only)

- [ ] **Step 1: Run analyzer**

Run: `flutter analyze`
Expected: No issues.

- [ ] **Step 2: Run all tests**

Run: `flutter test`
Expected: All tests PASS.

- [ ] **Step 3: Run code generation to ensure clean state**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`
Expected: No errors.
