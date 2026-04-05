# WebSocket Realtime Group Status — Flutter App Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add WebSocket-based realtime notifications to the Flutter app's group join flow, with three-layer degradation (WebSocket → push → polling).

**Architecture:** New `WebSocketService` in infrastructure layer manages on-demand WebSocket connections. It feeds events into the existing `SyncTriggerService` stream via a new `addExternalEvent()` method. Waiting screens observe WebSocket connection state to toggle between realtime and polling fallback. Event deduplication at `SyncTriggerService` level prevents double-processing.

**Tech Stack:** Flutter, `web_socket_channel` ^3.0.0, Riverpod, `mocktail` (tests)

**Spec:** `docs/superpowers/specs/2026-04-04-websocket-realtime-group-status-design.md`

---

## File Structure

### New Files
| File | Responsibility |
|------|---------------|
| `lib/infrastructure/sync/websocket_service.dart` | WebSocket connection lifecycle, auth, heartbeat, reconnect, event parsing |
| `lib/infrastructure/sync/websocket_connection_state.dart` | Enum: `connected`, `connecting`, `disconnected` |
| `test/infrastructure/sync/websocket_service_test.dart` | Unit tests for WebSocketService |
| `test/widget/features/family_sync/presentation/screens/waiting_approval_screen_websocket_test.dart` | Widget tests for three-layer degradation |
| `test/widget/features/family_sync/presentation/screens/member_approval_screen_websocket_test.dart` | Widget tests for WebSocket integration |
| `test/infrastructure/sync/sync_trigger_service_dedup_test.dart` | Deduplication tests |

### Modified Files
| File | Change |
|------|--------|
| `pubspec.yaml` | Add `web_socket_channel: ^3.0.0` |
| `lib/infrastructure/sync/sync_trigger_service.dart` | Add `addExternalEvent()` with deduplication, accept optional `WebSocketService` |
| `lib/features/family_sync/presentation/providers/sync_providers.dart` | Add `webSocketServiceProvider`, wire into `syncTriggerServiceProvider` |
| `lib/features/family_sync/presentation/providers/repository_providers.dart` | Add `webSocketServiceProvider` (infrastructure DI) |
| `lib/features/family_sync/presentation/screens/waiting_approval_screen.dart` | Add WebSocket connect/disconnect, three-layer degradation |
| `lib/features/family_sync/presentation/screens/member_approval_screen.dart` | Add WebSocket connect/disconnect for join_request events |

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

## Task 3: Create `WebSocketService` — core class with connect/disconnect

**Files:**
- Create: `lib/infrastructure/sync/websocket_service.dart`
- Create: `test/infrastructure/sync/websocket_service_test.dart`

- [ ] **Step 1: Write the failing test — connect and disconnect**

```dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/family_sync/domain/models/sync_trigger_event.dart';
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

    setUp(() {
      incomingController = StreamController<dynamic>.broadcast();
      service = WebSocketService(
        baseUrl: 'wss://sync.happypocket.app',
        channelFactory: ({required String url}) {
          final channel = MockWebSocketChannel();
          final sink = MockWebSocketSink();
          when(() => channel.stream).thenAnswer((_) => incomingController.stream);
          when(() => channel.sink).thenReturn(sink);
          when(() => sink.close(any(), any())).thenAnswer((_) async {});
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
      incomingController.add(jsonEncode({'type': 'auth_success', 'groupId': 'group-1'}));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      service.disconnect();

      expect(service.connectionState, WebSocketConnectionState.disconnected);
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

import '../../features/family_sync/domain/models/sync_trigger_event.dart';
import 'websocket_connection_state.dart';

/// Factory for creating WebSocket channels (injectable for testing).
typedef WebSocketChannelFactory = WebSocketChannel Function({
  required String url,
});

/// Signature function for Ed25519 signing.
typedef SignMessageFn = Future<String> Function(String message);

/// Manages an on-demand WebSocket connection to the relay server
/// for realtime group status notifications.
///
/// Connection is scoped to a single group and established only when
/// entering waiting/approval screens. Events are exposed as a stream
/// of [SyncTriggerEvent] for consumption by [SyncTriggerService].
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
  final _eventController = StreamController<SyncTriggerEvent>.broadcast();

  /// Current connection state.
  WebSocketConnectionState get connectionState => _connectionState;

  /// Stream of connection state changes.
  Stream<WebSocketConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  /// Stream of parsed sync trigger events from the WebSocket.
  Stream<SyncTriggerEvent> get eventStream => _eventController.stream;

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

    // Parse sync trigger event
    final event = _parseEvent(type, data);
    if (event != null && !_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  SyncTriggerEvent? _parseEvent(String type, Map<String, dynamic> data) {
    final groupId = data['groupId'] as String?;
    switch (type) {
      case 'member_confirmed':
        return SyncTriggerEvent.memberConfirmed(groupId: groupId);
      case 'join_request':
        return SyncTriggerEvent.joinRequest(groupId: groupId);
      case 'member_left':
        return SyncTriggerEvent.memberLeft(groupId: groupId);
      case 'group_dissolved':
        return SyncTriggerEvent.groupDissolved(groupId: groupId);
      default:
        if (kDebugMode) {
          debugPrint('WebSocketService: unknown event type: $type');
        }
        return null;
    }
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
Expected: All 3 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/infrastructure/sync/websocket_service.dart test/infrastructure/sync/websocket_service_test.dart
git commit -m "feat(sync): add WebSocketService with connect/disconnect/auth"
```

---

## Task 4: Add WebSocket event parsing tests

**Files:**
- Modify: `test/infrastructure/sync/websocket_service_test.dart`

- [ ] **Step 1: Write failing tests — event parsing**

Add to the existing test file's `main()`:

```dart
    test('parses member_confirmed event from WebSocket', () async {
      final events = <SyncTriggerEvent>[];
      service.eventStream.listen(events.add);

      service.connect(
        groupId: 'group-1',
        deviceId: 'device-1',
        signMessage: (msg) async => 'mock-sig',
      );
      incomingController.add(jsonEncode({'type': 'auth_success', 'groupId': 'group-1'}));
      await Future<void>.delayed(Duration.zero);

      incomingController.add(jsonEncode({
        'type': 'member_confirmed',
        'groupId': 'group-1',
        'deviceId': 'device-2',
        'timestamp': '2026-04-04T12:00:00Z',
      }));
      await Future<void>.delayed(Duration.zero);

      expect(events, [
        const SyncTriggerEvent.memberConfirmed(groupId: 'group-1'),
      ]);
    });

    test('parses join_request event from WebSocket', () async {
      final events = <SyncTriggerEvent>[];
      service.eventStream.listen(events.add);

      service.connect(
        groupId: 'group-1',
        deviceId: 'device-1',
        signMessage: (msg) async => 'mock-sig',
      );
      incomingController.add(jsonEncode({'type': 'auth_success', 'groupId': 'group-1'}));
      await Future<void>.delayed(Duration.zero);

      incomingController.add(jsonEncode({
        'type': 'join_request',
        'groupId': 'group-1',
        'deviceId': 'device-3',
        'timestamp': '2026-04-04T12:00:00Z',
      }));
      await Future<void>.delayed(Duration.zero);

      expect(events, [
        const SyncTriggerEvent.joinRequest(groupId: 'group-1'),
      ]);
    });

    test('ignores unknown event types', () async {
      final events = <SyncTriggerEvent>[];
      service.eventStream.listen(events.add);

      service.connect(
        groupId: 'group-1',
        deviceId: 'device-1',
        signMessage: (msg) async => 'mock-sig',
      );
      incomingController.add(jsonEncode({'type': 'auth_success', 'groupId': 'group-1'}));
      await Future<void>.delayed(Duration.zero);

      incomingController.add(jsonEncode({'type': 'unknown_event', 'groupId': 'group-1'}));
      await Future<void>.delayed(Duration.zero);

      expect(events, isEmpty);
    });

    test('auth_error prevents reconnection', () async {
      service.connect(
        groupId: 'group-1',
        deviceId: 'device-1',
        signMessage: (msg) async => 'mock-sig',
      );

      incomingController.add(jsonEncode({'type': 'auth_error', 'message': 'invalid signature'}));
      await Future<void>.delayed(Duration.zero);

      expect(service.connectionState, WebSocketConnectionState.disconnected);
    });
```

- [ ] **Step 2: Run tests**

Run: `flutter test test/infrastructure/sync/websocket_service_test.dart`
Expected: All 7 tests PASS (3 existing + 4 new).

- [ ] **Step 3: Commit**

```bash
git add test/infrastructure/sync/websocket_service_test.dart
git commit -m "test(sync): add WebSocket event parsing and auth error tests"
```

---

## Task 5: Add event deduplication to `SyncTriggerService`

**Files:**
- Modify: `lib/infrastructure/sync/sync_trigger_service.dart`
- Create: `test/infrastructure/sync/sync_trigger_service_dedup_test.dart`

- [ ] **Step 1: Write failing deduplication test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/family_sync/domain/models/sync_trigger_event.dart';
import 'package:home_pocket/infrastructure/sync/sync_trigger_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/application/family_sync/pull_sync_use_case.dart';
import 'package:home_pocket/application/family_sync/push_sync_use_case.dart';
import 'package:home_pocket/infrastructure/sync/sync_queue_manager.dart';
import 'package:home_pocket/infrastructure/sync/push_notification_service.dart';
import 'package:home_pocket/infrastructure/sync/relay_api_client.dart';
import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';

class MockGroupRepository extends Mock implements GroupRepository {}
class MockPullSyncUseCase extends Mock implements PullSyncUseCase {}
class MockPushSyncUseCase extends Mock implements PushSyncUseCase {}
class MockSyncQueueManager extends Mock implements SyncQueueManager {}
class MockPushNotificationService extends Mock implements PushNotificationService {}
class MockRelayApiClient extends Mock implements RelayApiClient {}
class MockKeyManager extends Mock implements KeyManager {}

void main() {
  group('SyncTriggerService deduplication', () {
    late SyncTriggerService service;

    setUp(() {
      service = SyncTriggerService(
        groupRepo: MockGroupRepository(),
        pullSync: MockPullSyncUseCase(),
        pushSync: MockPushSyncUseCase(),
        queueManager: MockSyncQueueManager(),
        pushNotificationService: MockPushNotificationService(),
        apiClient: MockRelayApiClient(),
        keyManager: MockKeyManager(),
      );
    });

    // NOTE: These tests intentionally do NOT call service.initialize(),
    // because that would require stubbing PushNotificationService.registerHandlers
    // and PushNotificationService.initialize. We only test addExternalEvent here.

    test('addExternalEvent publishes event to stream', () async {
      final events = <SyncTriggerEvent>[];
      service.events.listen(events.add);

      service.addExternalEvent(
        const SyncTriggerEvent.memberConfirmed(groupId: 'group-1'),
      );
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
      expect(events.first.type, SyncTriggerEventType.memberConfirmed);
    });

    test('duplicate event within 10s is suppressed', () async {
      final events = <SyncTriggerEvent>[];
      service.events.listen(events.add);

      service.addExternalEvent(
        const SyncTriggerEvent.memberConfirmed(groupId: 'group-1'),
      );
      service.addExternalEvent(
        const SyncTriggerEvent.memberConfirmed(groupId: 'group-1'),
      );
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
    });

    test('different event types are not deduplicated', () async {
      final events = <SyncTriggerEvent>[];
      service.events.listen(events.add);

      service.addExternalEvent(
        const SyncTriggerEvent.memberConfirmed(groupId: 'group-1'),
      );
      service.addExternalEvent(
        const SyncTriggerEvent.joinRequest(groupId: 'group-1'),
      );
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(2));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/infrastructure/sync/sync_trigger_service_dedup_test.dart`
Expected: FAIL — `addExternalEvent` method does not exist.

- [ ] **Step 3: Add `addExternalEvent()` with deduplication to `SyncTriggerService`**

In `lib/infrastructure/sync/sync_trigger_service.dart`, add after the `_pendingEvent` field (around line 59):

```dart
  /// Tracks (type, groupId) → timestamp for deduplication.
  final _recentEvents = <String, DateTime>{};
  static const _deduplicationWindow = Duration(seconds: 10);
```

Add new public method after `takePendingEvent()` (around line 98):

```dart
  /// Accept an event from an external source (e.g., WebSocket).
  ///
  /// Deduplicates against recently processed events within a 10-second window
  /// to prevent double-processing when the same event arrives via both
  /// WebSocket and push notification.
  void addExternalEvent(SyncTriggerEvent event) {
    final key = '${event.type.name}:${event.groupId ?? ''}';
    final now = DateTime.now();

    // Prune expired entries
    _recentEvents.removeWhere(
      (_, ts) => now.difference(ts) > _deduplicationWindow,
    );

    if (_recentEvents.containsKey(key)) {
      if (kDebugMode) {
        debugPrint('SyncTrigger: dedup suppressed $key');
      }
      return;
    }

    // _publishEvent records the event in _recentEvents, no need to record here
    _publishEvent(event);
  }
```

Also update `_publishEvent` to record events for dedup:

Replace the existing `_publishEvent` method:

```dart
  void _publishEvent(SyncTriggerEvent event) {
    // Record for cross-source deduplication: when a push notification event
    // is processed here, the recording prevents a duplicate WebSocket event
    // (arriving seconds later) from being processed again, and vice versa.
    final key = '${event.type.name}:${event.groupId ?? ''}';
    _recentEvents[key] = DateTime.now();

    _pendingEvent = event;
    if (!_eventsController.isClosed) {
      _eventsController.add(event);
    }
  }
```

- [ ] **Step 4: Run tests**

Run: `flutter test test/infrastructure/sync/sync_trigger_service_dedup_test.dart`
Expected: All 3 tests PASS.

- [ ] **Step 5: Run existing sync_trigger_service tests to verify no regression**

Run: `flutter test test/infrastructure/sync/sync_trigger_service_test.dart`
Expected: All existing tests PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/infrastructure/sync/sync_trigger_service.dart test/infrastructure/sync/sync_trigger_service_dedup_test.dart
git commit -m "feat(sync): add event deduplication to SyncTriggerService"
```

---

## Task 6: Wire `WebSocketService` into providers

**Files:**
- Modify: `lib/features/family_sync/presentation/providers/repository_providers.dart`
- Modify: `lib/features/family_sync/presentation/providers/sync_providers.dart`

- [ ] **Step 1: Add `webSocketServiceProvider` to `repository_providers.dart`**

Add import at top:

```dart
import '../../../../infrastructure/sync/websocket_service.dart';
```

Add provider at end of file:

```dart
/// WebSocketService provider for realtime group status notifications.
@riverpod
WebSocketService webSocketService(Ref ref) {
  final service = WebSocketService(
    baseUrl: RelayApiClient.defaultBaseUrl.replaceFirst('/api/v1', ''),
  );
  ref.onDispose(service.dispose);
  return service;
}
```

- [ ] **Step 2: Wire WebSocket events into `SyncTriggerService`**

In `sync_providers.dart`, update the `syncTriggerServiceProvider`:

Add import:

```dart
import '../../../../infrastructure/sync/websocket_service.dart';
import 'repository_providers.dart' show webSocketServiceProvider;
```

After `final service = SyncTriggerService(...)` and before `ref.onDispose(service.dispose)`, add WebSocket event forwarding:

```dart
  // Forward WebSocket events through deduplication
  final webSocket = ref.watch(webSocketServiceProvider);
  final wsSubscription = webSocket.eventStream.listen(service.addExternalEvent);
  ref.onDispose(wsSubscription.cancel);
```

- [ ] **Step 3: Run code generation**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`
Expected: Generates updated `.g.dart` files.

- [ ] **Step 4: Run analyzer**

Run: `flutter analyze`
Expected: No issues.

- [ ] **Step 5: Commit**

```bash
git add lib/features/family_sync/presentation/providers/repository_providers.dart lib/features/family_sync/presentation/providers/sync_providers.dart lib/features/family_sync/presentation/providers/repository_providers.g.dart lib/features/family_sync/presentation/providers/sync_providers.g.dart
git commit -m "feat(sync): wire WebSocketService into provider graph"
```

---

## Task 7: Update `WaitingApprovalScreen` with three-layer degradation

**Files:**
- Modify: `lib/features/family_sync/presentation/screens/waiting_approval_screen.dart`
- Create: `test/widget/features/family_sync/presentation/screens/waiting_approval_screen_websocket_test.dart`

- [ ] **Step 1: Write failing widget test — WebSocket connected stops polling**

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/family_sync/domain/models/sync_trigger_event.dart';
import 'package:home_pocket/features/family_sync/presentation/screens/waiting_approval_screen.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/group_providers.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/sync_providers.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/family_sync/use_cases/check_group_use_case.dart';
import 'package:home_pocket/infrastructure/sync/sync_trigger_service.dart';
import 'package:home_pocket/infrastructure/sync/websocket_connection_state.dart';
import 'package:home_pocket/infrastructure/sync/websocket_service.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/test_localizations.dart';

class MockSyncTriggerService extends Mock implements SyncTriggerService {}
class MockCheckGroupUseCase extends Mock implements CheckGroupUseCase {}
class MockWebSocketService extends Mock implements WebSocketService {}

void main() {
  late MockSyncTriggerService syncTriggerService;
  late MockCheckGroupUseCase checkGroupUseCase;
  late MockWebSocketService webSocketService;
  late StreamController<SyncTriggerEvent> eventsController;
  late StreamController<WebSocketConnectionState> wsStateController;

  setUp(() {
    syncTriggerService = MockSyncTriggerService();
    checkGroupUseCase = MockCheckGroupUseCase();
    webSocketService = MockWebSocketService();
    eventsController = StreamController<SyncTriggerEvent>.broadcast();
    wsStateController = StreamController<WebSocketConnectionState>.broadcast();

    when(() => syncTriggerService.events).thenAnswer((_) => eventsController.stream);
    when(() => webSocketService.connectionStateStream).thenAnswer((_) => wsStateController.stream);
    when(() => webSocketService.connectionState).thenReturn(WebSocketConnectionState.disconnected);
    when(() => webSocketService.connect(
      groupId: any(named: 'groupId'),
      deviceId: any(named: 'deviceId'),
      signMessage: any(named: 'signMessage'),
    )).thenReturn(null);
    when(() => webSocketService.disconnect()).thenReturn(null);
    when(() => webSocketService.startLifecycleObservation()).thenReturn(null);
    when(() => webSocketService.stopLifecycleObservation()).thenReturn(null);
  });

  tearDown(() async {
    await eventsController.close();
    await wsStateController.close();
  });

  testWidgets('does not poll when WebSocket is connected', (tester) async {
    when(() => webSocketService.connectionState)
        .thenReturn(WebSocketConnectionState.connected);

    await tester.pumpWidget(
      createLocalizedWidget(
        const WaitingApprovalScreen(
          groupName: 'Test Family',
          ownerDisplayName: 'Owner',
        ),
        overrides: [
          syncTriggerServiceProvider.overrideWithValue(syncTriggerService),
          checkGroupUseCaseProvider.overrideWithValue(checkGroupUseCase),
          webSocketServiceProvider.overrideWithValue(webSocketService),
        ],
      ),
    );

    // Simulate WebSocket connected
    wsStateController.add(WebSocketConnectionState.connected);
    await tester.pump();

    // Wait past polling interval
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(seconds: 6));
    });
    await tester.pump();

    verifyNever(() => checkGroupUseCase.execute());
  });

  testWidgets('starts polling when WebSocket disconnects', (tester) async {
    when(() => checkGroupUseCase.execute())
        .thenAnswer((_) async => const CheckGroupNotInGroup());

    await tester.pumpWidget(
      createLocalizedWidget(
        const WaitingApprovalScreen(
          groupName: 'Test Family',
          ownerDisplayName: 'Owner',
        ),
        overrides: [
          syncTriggerServiceProvider.overrideWithValue(syncTriggerService),
          checkGroupUseCaseProvider.overrideWithValue(checkGroupUseCase),
          webSocketServiceProvider.overrideWithValue(webSocketService),
        ],
      ),
    );

    // WebSocket disconnected -> polling should start
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
Expected: FAIL — screen does not accept/use WebSocketService.

- [ ] **Step 3: Update `WaitingApprovalScreen` with three-layer degradation**

Replace the state class fields and lifecycle methods in `waiting_approval_screen.dart`:

First, add `groupId` to the constructor. The screen currently accepts `groupName` and `ownerDisplayName` but not `groupId`. Add it:

```dart
class WaitingApprovalScreen extends ConsumerStatefulWidget {
  const WaitingApprovalScreen({
    super.key,
    required this.groupId,          // NEW
    required this.groupName,
    required this.ownerDisplayName,
  });

  final String groupId;              // NEW
  final String groupName;
  final String ownerDisplayName;
```

**NOTE:** Update all call sites that construct `WaitingApprovalScreen` to pass `groupId`. Search for `WaitingApprovalScreen(` across the codebase and add the parameter. Key locations: `confirm_join_screen.dart` and any navigation that pushes this screen.

Replace `_WaitingApprovalScreenState` class — keep all build methods identical, only change the state management:

```dart
class _WaitingApprovalScreenState extends ConsumerState<WaitingApprovalScreen> {
  bool _hasNavigated = false;
  StreamSubscription<SyncTriggerEvent>? _eventSubscription;
  StreamSubscription<WebSocketConnectionState>? _wsStateSubscription;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _listenForSyncEvents();
    _connectWebSocket();
  }

  void _listenForSyncEvents() {
    final syncTrigger = ref.read(syncTriggerServiceProvider);
    _eventSubscription = syncTrigger.events.listen((event) {
      if (!mounted || _hasNavigated) return;
      if (event.type != SyncTriggerEventType.memberConfirmed) return;
      unawaited(_verifyGroupAndNavigate());
    });
  }

  Future<void> _connectWebSocket() async {
    final ws = ref.read(webSocketServiceProvider);
    final keyManager = ref.read(keyManagerProvider);

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

  int _pollCount = 0;

  void _startAdaptivePolling() {
    _pollingTimer?.cancel();
    _pollCount = 0;
    _scheduleNextPoll();
  }

  void _scheduleNextPoll() {
    if (_hasNavigated) return;

    // Adaptive backoff: 5s → 10s → 15s → 30s, then stays at 30s
    final delays = [5, 10, 15, 30];
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
        ref
            .read(syncStatusNotifierProvider.notifier)
            .updateStatus(SyncStatus.synced);
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
    unawaited(_eventSubscription?.cancel());
    unawaited(_wsStateSubscription?.cancel());
    ref.read(webSocketServiceProvider)
      ..stopLifecycleObservation()
      ..disconnect();
    super.dispose();
  }

  // ... build method stays identical ...
}
```

Add these imports to the top of the file:

```dart
import 'dart:convert';
import '../../../../infrastructure/crypto/providers.dart';
import '../../../../infrastructure/sync/websocket_connection_state.dart';
import '../../../../infrastructure/sync/websocket_service.dart';
import '../providers/repository_providers.dart';
```

- [ ] **Step 4: Run tests**

Run: `flutter test test/widget/features/family_sync/presentation/screens/waiting_approval_screen_websocket_test.dart`
Expected: All tests PASS.

- [ ] **Step 5: Run existing waiting_approval_screen tests**

Run: `flutter test test/widget/features/family_sync/presentation/screens/waiting_approval_screen_test.dart`
Expected: All existing tests PASS (may need to add `webSocketServiceProvider` override to existing tests).

- [ ] **Step 6: Commit**

```bash
git add lib/features/family_sync/presentation/screens/waiting_approval_screen.dart test/widget/features/family_sync/presentation/screens/waiting_approval_screen_websocket_test.dart
git commit -m "feat(sync): add three-layer degradation to WaitingApprovalScreen"
```

---

## Task 8: Update `MemberApprovalScreen` with WebSocket

**Files:**
- Modify: `lib/features/family_sync/presentation/screens/member_approval_screen.dart`
- Create: `test/widget/features/family_sync/presentation/screens/member_approval_screen_websocket_test.dart`

- [ ] **Step 1: Write failing widget test — WebSocket join_request triggers reload**

```dart
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_pocket/features/family_sync/domain/models/sync_trigger_event.dart';
import 'package:home_pocket/features/family_sync/presentation/screens/member_approval_screen.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/sync_providers.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/infrastructure/sync/sync_trigger_service.dart';
import 'package:home_pocket/infrastructure/sync/websocket_service.dart';
import 'package:home_pocket/infrastructure/sync/websocket_connection_state.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/test_localizations.dart';

class MockSyncTriggerService extends Mock implements SyncTriggerService {}
class MockWebSocketService extends Mock implements WebSocketService {}
class MockGroupRepository extends Mock implements GroupRepository {}

void main() {
  late MockSyncTriggerService syncTriggerService;
  late MockWebSocketService webSocketService;
  late MockGroupRepository groupRepository;
  late StreamController<SyncTriggerEvent> eventsController;
  late StreamController<WebSocketConnectionState> wsStateController;

  setUp(() {
    syncTriggerService = MockSyncTriggerService();
    webSocketService = MockWebSocketService();
    groupRepository = MockGroupRepository();
    eventsController = StreamController<SyncTriggerEvent>.broadcast();
    wsStateController = StreamController<WebSocketConnectionState>.broadcast();

    when(() => syncTriggerService.events).thenAnswer((_) => eventsController.stream);
    when(() => webSocketService.connectionStateStream).thenAnswer((_) => wsStateController.stream);
    when(() => webSocketService.connectionState).thenReturn(WebSocketConnectionState.disconnected);
    when(() => webSocketService.connect(
      groupId: any(named: 'groupId'),
      deviceId: any(named: 'deviceId'),
      signMessage: any(named: 'signMessage'),
    )).thenReturn(null);
    when(() => webSocketService.disconnect()).thenReturn(null);
    when(() => webSocketService.startLifecycleObservation()).thenReturn(null);
    when(() => webSocketService.stopLifecycleObservation()).thenReturn(null);
    when(() => groupRepository.getActiveGroup()).thenAnswer((_) async => null);
    when(() => groupRepository.getGroupById(any())).thenAnswer((_) async => null);
  });

  tearDown(() async {
    await eventsController.close();
    await wsStateController.close();
  });

  testWidgets('connects WebSocket on init and disconnects on dispose', (tester) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        const MemberApprovalScreen(groupId: 'group-1'),
        overrides: [
          syncTriggerServiceProvider.overrideWithValue(syncTriggerService),
          webSocketServiceProvider.overrideWithValue(webSocketService),
          groupRepositoryProvider.overrideWithValue(groupRepository),
        ],
      ),
    );

    verify(() => webSocketService.startLifecycleObservation()).called(1);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget/features/family_sync/presentation/screens/member_approval_screen_websocket_test.dart`
Expected: FAIL — screen does not use WebSocket.

- [ ] **Step 3: Update `MemberApprovalScreen`**

Add WebSocket connection management to `_MemberApprovalScreenState`.

**Note:** `MemberApprovalScreen` does not poll — it only refreshes via `SyncTriggerEvent.joinRequest` events. The WebSocket connection enables realtime delivery of these events. No polling fallback is needed here because the owner is not "stuck waiting" — they can navigate away and come back. The WebSocket just makes the experience snappier.

In `_MemberApprovalScreenState`, add a new method and update `initState` and `dispose`:

```dart
  @override
  void initState() {
    super.initState();
    _loadGroup();
    _listenForSyncEvents();
    _connectWebSocket();       // NEW
  }

  Future<void> _connectWebSocket() async {
    final ws = ref.read(webSocketServiceProvider);
    final keyManager = ref.read(keyManagerProvider);
    final groupId = widget.groupId;
    if (groupId == null) return;

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

  @override
  void dispose() {
    unawaited(_eventSubscription?.cancel());
    ref.read(webSocketServiceProvider)
      ..stopLifecycleObservation()
      ..disconnect();
    super.dispose();
  }
```

Add imports:

```dart
import 'dart:convert';
import '../../../../infrastructure/crypto/providers.dart';
import '../../../../infrastructure/sync/websocket_service.dart';
import '../providers/repository_providers.dart' show webSocketServiceProvider, keyManagerProvider;
```

- [ ] **Step 4: Run tests**

Run: `flutter test test/widget/features/family_sync/presentation/screens/member_approval_screen_websocket_test.dart`
Expected: All tests PASS.

- [ ] **Step 5: Run existing member_approval tests**

Run: `flutter test test/widget/features/family_sync/presentation/screens/member_approval_screen_test.dart`
Expected: All existing tests PASS (may need to add `webSocketServiceProvider` override).

- [ ] **Step 6: Commit**

```bash
git add lib/features/family_sync/presentation/screens/member_approval_screen.dart test/widget/features/family_sync/presentation/screens/member_approval_screen_websocket_test.dart
git commit -m "feat(sync): add WebSocket lifecycle to MemberApprovalScreen"
```

---

## Task 9: Fix existing tests with WebSocket provider overrides

**Files:**
- Modify: `test/widget/features/family_sync/presentation/screens/waiting_approval_screen_test.dart`
- Modify: `test/widget/features/family_sync/presentation/screens/member_approval_screen_test.dart`

- [ ] **Step 1: Add mock WebSocketService to existing waiting_approval test**

Add mock class and override `webSocketServiceProvider` in each test's provider overrides. The mock should return `WebSocketConnectionState.disconnected` to preserve existing polling behavior.

- [ ] **Step 2: Add mock WebSocketService to existing member_approval test**

Same pattern — add mock and override.

- [ ] **Step 3: Run all family_sync widget tests**

Run: `flutter test test/widget/features/family_sync/`
Expected: All tests PASS.

- [ ] **Step 4: Commit**

```bash
git add test/widget/features/family_sync/
git commit -m "test(sync): add WebSocket mock overrides to existing widget tests"
```

---

## Task 10: Integration test — WebSocket disconnect fallback

**Files:**
- Create: `test/integration/sync/websocket_degradation_test.dart`

- [ ] **Step 1: Write integration test**

```dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/family_sync/domain/models/sync_trigger_event.dart';
import 'package:home_pocket/infrastructure/sync/websocket_connection_state.dart';
import 'package:home_pocket/infrastructure/sync/websocket_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class MockWebSocketChannel extends Mock implements WebSocketChannel {}
class MockWebSocketSink extends Mock implements WebSocketSink {}

void main() {
  test('WebSocket disconnect triggers state change for polling fallback', () async {
    final incomingController = StreamController<dynamic>.broadcast();
    final sink = MockWebSocketSink();
    when(() => sink.close(any(), any())).thenAnswer((_) async {});
    when(() => sink.add(any())).thenReturn(null);

    final service = WebSocketService(
      baseUrl: 'wss://test.example.com',
      channelFactory: ({required String url}) {
        final channel = MockWebSocketChannel();
        when(() => channel.stream).thenAnswer((_) => incomingController.stream);
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
    incomingController.add(jsonEncode({'type': 'auth_success', 'groupId': 'group-1'}));
    await Future<void>.delayed(Duration.zero);

    expect(service.connectionState, WebSocketConnectionState.connected);

    // Simulate disconnect
    await incomingController.close();
    await Future<void>.delayed(Duration.zero);

    expect(service.connectionState, WebSocketConnectionState.disconnected);
    expect(states, contains(WebSocketConnectionState.disconnected));

    service.dispose();
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
