import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'websocket_connection_state.dart';

/// Factory for creating WebSocket channels (injectable for testing).
typedef WebSocketChannelFactory =
    WebSocketChannel Function({required String url});

/// Signature function for Ed25519 signing.
typedef SignMessageFn = Future<String> Function(String message);

/// Known event types from the WebSocket relay server.
enum WebSocketEventType {
  authError,
  memberConfirmed,
  joinRequest,
  joinRequestResolved,
  memberLeft,
  groupDissolved,
  groupStatus,
  groupNameUpdated,
  syncAvailable,
  groupKeyRequested,
  ownerTransferred,
}

/// A parsed event received from the WebSocket relay server.
class WebSocketEvent {
  const WebSocketEvent({required this.type, this.groupId, this.data});

  final WebSocketEventType type;
  final String? groupId;

  /// Optional payload delivered with the event.
  ///
  /// Currently populated for [WebSocketEventType.groupStatus] events,
  /// which carry the full group status sent by the server after auth success.
  final Map<String, dynamic>? data;

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
/// Three-layer degradation: WebSocket (primary) -> push (backup) -> polling (fallback).
class WebSocketService with WidgetsBindingObserver {
  WebSocketService({
    required String baseUrl,
    WebSocketChannelFactory? channelFactory,
  }) : _baseUrl = baseUrl,
       _channelFactory = channelFactory ?? _defaultChannelFactory;

  final String _baseUrl;
  final WebSocketChannelFactory _channelFactory;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _messageSubscription;
  Timer? _heartbeatTimer;
  Timer? _pongTimeoutTimer;
  Timer? _reconnectTimer;
  Timer? _backgroundDisconnectTimer;
  bool _isLifecycleObservationActive = false;

  String? _groupId;
  String? _deviceId;
  SignMessageFn? _signMessage;
  int _connectionGeneration = 0;

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

  /// Whether this service currently owns one app lifecycle registration.
  ///
  /// Exposed so callers and tests can reason about lifecycle ownership without
  /// reaching into [WidgetsBinding]'s observer collection.
  @visibleForTesting
  bool get isLifecycleObservationActive => _isLifecycleObservationActive;

  /// Connect to the relay server WebSocket for a specific group.
  ///
  /// [signMessage] is called with the auth payload string and must return
  /// a base64-encoded Ed25519 signature.
  void connect({
    required String groupId,
    required String deviceId,
    required SignMessageFn signMessage,
  }) {
    final hasSameIdentity = _groupId == groupId && _deviceId == deviceId;
    if (hasSameIdentity &&
        (_connectionState != WebSocketConnectionState.disconnected ||
            _reconnectTimer != null)) {
      return;
    }

    if (!hasSameIdentity &&
        (_connectionState != WebSocketConnectionState.disconnected ||
            _groupId != null ||
            _deviceId != null ||
            _reconnectTimer != null)) {
      disconnect();
    }

    _groupId = groupId;
    _deviceId = deviceId;
    _signMessage = signMessage;
    _reconnectAttempts = 0;

    _doConnect();
  }

  void _doConnect() {
    final groupId = _groupId;
    final deviceId = _deviceId;
    final signMessage = _signMessage;
    if (groupId == null || deviceId == null || signMessage == null) return;

    final generation = ++_connectionGeneration;
    _setConnectionState(WebSocketConnectionState.connecting);

    final url = '$_baseUrl/ws/group/$groupId';
    final channel = _channelFactory(url: url);
    _channel = channel;

    _messageSubscription = channel.stream.listen(
      (raw) => _onMessage(raw, generation, channel, groupId),
      onError: (Object error, StackTrace stackTrace) =>
          _onError(error, generation, channel),
      onDone: () => _onDone(generation, channel),
    );

    unawaited(
      _authenticate(
        generation: generation,
        channel: channel,
        groupId: groupId,
        deviceId: deviceId,
        signMessage: signMessage,
      ),
    );
  }

  Future<void> _authenticate({
    required int generation,
    required WebSocketChannel channel,
    required String groupId,
    required String deviceId,
    required SignMessageFn signMessage,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final message = 'ws:connect:$groupId:$deviceId:$timestamp';
    final signature = await signMessage(message);
    if (!_isCurrentConnection(generation, channel)) return;

    final authMessage = jsonEncode({
      'deviceId': deviceId,
      'timestamp': timestamp,
      'signature': signature,
      'protocolVersion': 1,
    });

    channel.sink.add(authMessage);
  }

  bool _isCurrentConnection(int generation, WebSocketChannel channel) {
    return generation == _connectionGeneration && identical(channel, _channel);
  }

  void _onMessage(
    dynamic raw,
    int generation,
    WebSocketChannel channel,
    String groupId,
  ) {
    if (!_isCurrentConnection(generation, channel)) return;
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
      _startHeartbeat(generation, channel);
      return;
    }

    if (type == 'auth_error') {
      // Auth errors are non-recoverable — do not reconnect
      if (!_eventController.isClosed) {
        _eventController.add(
          WebSocketEvent(type: WebSocketEventType.authError, groupId: groupId),
        );
      }
      _reconnectAttempts = -1; // Sentinel to prevent reconnect
      _handleDisconnect(generation, channel);
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
    final eventData = data['data'] as Map<String, dynamic>?;
    final eventType = switch (type) {
      'member_confirmed' => WebSocketEventType.memberConfirmed,
      'join_request' => WebSocketEventType.joinRequest,
      'join_request_rejected' ||
      'join_request_cancelled' ||
      'join_request_expired' => WebSocketEventType.joinRequestResolved,
      'member_left' => WebSocketEventType.memberLeft,
      'group_dissolved' => WebSocketEventType.groupDissolved,
      'group_status' => WebSocketEventType.groupStatus,
      'group_name_updated' => WebSocketEventType.groupNameUpdated,
      'sync_available' => WebSocketEventType.syncAvailable,
      'group_key_requested' => WebSocketEventType.groupKeyRequested,
      'owner_transferred' => WebSocketEventType.ownerTransferred,
      _ => null,
    };

    if (eventType == null) {
      return null;
    }

    final mergedData = <String, dynamic>{...?eventData};
    for (final key in const [
      'eventId',
      'revision',
      'occurredAt',
      'actorDeviceId',
      'reason',
      'requestId',
    ]) {
      final value = data[key];
      if (value != null) mergedData[key] = value;
    }
    if (data['eventId'] != null) mergedData['controlEventType'] = type;
    if (eventType == WebSocketEventType.memberLeft ||
        eventType == WebSocketEventType.joinRequestResolved) {
      final deviceId = data['deviceId'];
      if (deviceId is String) {
        mergedData['deviceId'] = deviceId;
      }
    }

    return WebSocketEvent(
      type: eventType,
      groupId: groupId,
      data: mergedData.isEmpty ? null : mergedData,
    );
  }

  void _startHeartbeat(int generation, WebSocketChannel channel) {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!_isCurrentConnection(generation, channel)) {
        timer.cancel();
        return;
      }
      channel.sink.add(jsonEncode({'type': 'ping'}));

      // Expect pong within 45s
      _pongTimeoutTimer?.cancel();
      _pongTimeoutTimer = Timer(const Duration(seconds: 45), () {
        if (!_isCurrentConnection(generation, channel)) return;
        if (kDebugMode) {
          debugPrint('WebSocketService: pong timeout, reconnecting');
        }
        _handleDisconnect(generation, channel);
      });
    });
  }

  void _onError(Object error, int generation, WebSocketChannel channel) {
    if (!_isCurrentConnection(generation, channel)) return;
    if (kDebugMode) {
      debugPrint('WebSocketService: error: $error');
    }
    _handleDisconnect(generation, channel);
  }

  void _onDone(int generation, WebSocketChannel channel) {
    if (!_isCurrentConnection(generation, channel)) return;
    _handleDisconnect(generation, channel);
  }

  void _handleDisconnect(int generation, WebSocketChannel channel) {
    if (!_isCurrentConnection(generation, channel)) return;
    _cleanup();
    _connectionGeneration++;
    _setConnectionState(WebSocketConnectionState.disconnected);

    // Don't reconnect if auth failed
    if (_reconnectAttempts < 0) return;
    if (_groupId == null) return;

    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    final generation = _connectionGeneration;
    final groupId = _groupId;
    final deviceId = _deviceId;
    final delay = Duration(
      milliseconds: (1000 * (1 << _reconnectAttempts)).clamp(
        1000,
        _maxReconnectDelay.inMilliseconds,
      ),
    );
    _reconnectAttempts++;

    if (kDebugMode) {
      debugPrint(
        'WebSocketService: reconnecting in ${delay.inSeconds}s '
        '(attempt $_reconnectAttempts)',
      );
    }

    _reconnectTimer = Timer(delay, () {
      if (generation != _connectionGeneration ||
          groupId != _groupId ||
          deviceId != _deviceId ||
          _channel != null) {
        return;
      }
      _reconnectTimer = null;
      _doConnect();
    });
  }

  /// Disconnect from the WebSocket and stop all timers.
  void disconnect() {
    _connectionGeneration++;
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
    stopLifecycleObservation();
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
    if (_isLifecycleObservationActive) return;
    WidgetsBinding.instance.addObserver(this);
    _isLifecycleObservationActive = true;
  }

  /// Stop observing app lifecycle.
  void stopLifecycleObservation() {
    if (!_isLifecycleObservationActive) return;
    WidgetsBinding.instance.removeObserver(this);
    _isLifecycleObservationActive = false;
    _backgroundDisconnectTimer?.cancel();
    _backgroundDisconnectTimer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // Schedule disconnect after 60s in background
      _backgroundDisconnectTimer?.cancel();
      final generation = _connectionGeneration;
      _backgroundDisconnectTimer = Timer(const Duration(seconds: 60), () {
        if (generation != _connectionGeneration) return;
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
          _connectionState == WebSocketConnectionState.disconnected &&
          _reconnectTimer == null) {
        _doConnect();
      }
    }
  }

  static WebSocketChannel _defaultChannelFactory({required String url}) {
    return WebSocketChannel.connect(Uri.parse(url));
  }
}
