import 'dart:convert';

import '../../infrastructure/crypto/services/key_manager.dart';
import '../../infrastructure/sync/websocket_service.dart';

/// Application-layer use case encapsulating WebSocket management for the
/// member approval screen.
///
/// Wraps the business actions currently performed directly in
/// `member_approval_screen.dart` (WebSocket connection, event listening,
/// and sign-message callback wiring).
///
/// Constructor-injection pattern per PATTERNS.md §C.
class NotifyMemberApprovalUseCase {
  NotifyMemberApprovalUseCase({
    required WebSocketService wsService,
    required KeyManager keyManager,
  }) : _wsService = wsService,
       _keyManager = keyManager;

  final WebSocketService _wsService;
  final KeyManager _keyManager;

  /// Connect WebSocket to the group channel for real-time join-request events.
  ///
  /// Obtains the device ID from [_keyManager]; no-ops if not available.
  /// Starts lifecycle observation so the connection survives background/foreground.
  Future<void> connectWebSocket({required String groupId}) async {
    final deviceId = await _keyManager.getDeviceId();
    if (deviceId == null) return;

    _wsService.connect(
      groupId: groupId,
      deviceId: deviceId,
      signMessage: (message) async {
        final sig = await _keyManager.signData(utf8.encode(message));
        return base64Encode(sig.bytes);
      },
    );
    _wsService.startLifecycleObservation();
  }

  /// Disconnect the WebSocket and stop lifecycle observation.
  void disconnectWebSocket() {
    _wsService
      ..stopLifecycleObservation()
      ..disconnect();
  }

  /// Returns the raw WebSocket event stream so the screen can filter for
  /// `joinRequest` events and reload the pending member list.
  Stream<WebSocketEvent> listenForJoinRequests() => _wsService.eventStream;
}
