import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../infrastructure/crypto/providers.dart';
import '../../../../infrastructure/sync/websocket_connection_state.dart';
import '../../../../infrastructure/sync/websocket_service.dart';
import '../../domain/models/sync_status_model.dart';
import '../../use_cases/check_group_use_case.dart';
import '../providers/group_providers.dart';
import '../providers/repository_providers.dart';
import '../providers/sync_providers.dart';
import 'group_management_screen.dart';

/// Centered waiting screen displayed after the joiner has confirmed their
/// join request and is waiting for the group owner to approve.
///
/// Preserves the existing polling + event-listener pattern from the previous
/// implementation but with a redesigned UI matching the Pencil design.
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

  @override
  ConsumerState<WaitingApprovalScreen> createState() =>
      _WaitingApprovalScreenState();
}

class _WaitingApprovalScreenState extends ConsumerState<WaitingApprovalScreen> {
  bool _hasNavigated = false;
  StreamSubscription<SyncStatus>? _syncSubscription;
  StreamSubscription<WebSocketConnectionState>? _wsStateSubscription;
  StreamSubscription<WebSocketEvent>? _wsEventSubscription;
  Timer? _pollingTimer;
  int _pollCount = 0;
  WebSocketService? _webSocketService;

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
    _webSocketService = ws;
    final keyManager = ref.read(keyManagerProvider);

    // Handle WebSocket events
    _wsEventSubscription = ws.eventStream.listen((event) {
      if (!mounted || _hasNavigated) return;
      switch (event.type) {
        case WebSocketEventType.memberConfirmed:
          // Activate group first, then trigger initial data sync
          unawaited(_activateAndSync());
        case WebSocketEventType.joinRequest:
        case WebSocketEventType.memberLeft:
        case WebSocketEventType.groupDissolved:
        case WebSocketEventType.groupStatus:
        case WebSocketEventType.syncAvailable:
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

    // Adaptive backoff: 5s -> 10s -> 15s -> 30s, then stays at 30s
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

  /// Activate group locally first, then trigger initial data sync and navigate.
  ///
  /// Must be sequential: [checkGroupUseCaseProvider] updates the local group
  /// status from 'confirming' → 'active'. Only then can [SyncEngine] find
  /// the active group for initialSync (which queries status='active').
  Future<void> _activateAndSync() async {
    // Step 1: Activate group locally (confirming → active)
    await _verifyGroupAndNavigate();

    // Step 2: Trigger full initial sync (group is now active)
    if (_hasNavigated) {
      ref.read(syncEngineProvider).onMemberConfirmed();
    }
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
    _webSocketService
      ?..stopLifecycleObservation()
      ..disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 42),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Group name row
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '\u{1F3E0}',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.groupName,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Circular progress indicator
                SizedBox(
                  width: 64,
                  height: 64,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    color: AppColors.accentPrimary,
                    backgroundColor: AppColors.borderDefault,
                  ),
                ),
                const SizedBox(height: 28),

                // Waiting title
                Text(
                  l10n.groupWaitingApproval,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),

                // Description with owner name
                Text(
                  l10n.groupWaitingDesc(widget.ownerDisplayName),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                // Hint lines
                Text(
                  l10n.groupWaitingHint1,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.groupWaitingHint2,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
