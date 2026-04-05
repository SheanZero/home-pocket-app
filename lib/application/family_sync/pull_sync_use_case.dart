import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../features/family_sync/domain/models/group_info.dart';
import '../../features/family_sync/domain/models/group_member.dart';
import '../../features/family_sync/domain/repositories/group_repository.dart';
import '../../infrastructure/crypto/services/key_manager.dart';
import '../../infrastructure/sync/e2ee_service.dart';
import '../../infrastructure/sync/relay_api_client.dart';
import '../../infrastructure/sync/sync_queue_manager.dart';

/// Result of pulling sync data.
sealed class PullSyncResult {
  const PullSyncResult();

  const factory PullSyncResult.success(int appliedCount) = PullSyncSuccess;
  const factory PullSyncResult.noNewData() = PullSyncNoNewData;
  const factory PullSyncResult.noPair() = PullSyncNoPair;
  const factory PullSyncResult.error(String message) = PullSyncError;
}

class PullSyncSuccess extends PullSyncResult {
  const PullSyncSuccess(this.appliedCount);
  final int appliedCount;
}

class PullSyncNoNewData extends PullSyncResult {
  const PullSyncNoNewData();
}

class PullSyncNoPair extends PullSyncResult {
  const PullSyncNoPair();
}

class PullSyncError extends PullSyncResult {
  const PullSyncError(this.message);
  final String message;
}

/// Callback for applying decrypted sync operations.
typedef ApplyOperationsCallback =
    Future<void> Function(List<Map<String, dynamic>> operations);

/// Pulls pending sync messages from the relay server and applies them.
///
/// Flow:
/// 1. Get active pair info
/// 2. Pull messages since last sync cursor (server timestamp)
/// 3. Decrypt each message
/// 4. Apply operations via callback
/// 5. ACK messages on server (triggers deletion)
/// 6. Server physically deletes ACK'd messages (no cursor needed)
/// 7. Drain offline queue
class PullSyncUseCase {
  PullSyncUseCase({
    required RelayApiClient apiClient,
    required E2EEService e2eeService,
    required GroupRepository groupRepo,
    required SyncQueueManager queueManager,
    required KeyManager keyManager,
    required ApplyOperationsCallback applyOperations,
  }) : _apiClient = apiClient,
       _e2eeService = e2eeService,
       _groupRepo = groupRepo,
       _queueManager = queueManager,
       _keyManager = keyManager,
       _applyOperations = applyOperations;

  final RelayApiClient _apiClient;
  final E2EEService _e2eeService;
  final GroupRepository _groupRepo;
  final SyncQueueManager _queueManager;
  final KeyManager _keyManager;
  final ApplyOperationsCallback _applyOperations;

  Future<PullSyncResult> execute() async {
    try {
      final activeGroup = await _groupRepo.getActiveGroup();
      final pendingGroup = activeGroup == null
          ? await _groupRepo.getPendingGroup()
          : null;
      final group = activeGroup ?? pendingGroup;
      if (group == null) return const PullSyncResult.noPair();

      if (kDebugMode) {
        debugPrint('[PullSync] Pulling all pending messages...');
      }

      // Pull all pending messages — server returns only un-ACK'd messages
      final response = await _apiClient.pullSync();
      final messages =
          (response['messages'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      if (kDebugMode) {
        debugPrint('[PullSync] Received ${messages.length} messages');
      }

      if (messages.isEmpty) return const PullSyncResult.noNewData();

      var appliedCount = 0;
      final ackedMessageIds = <String>[];
      final deviceId = await _keyManager.getDeviceId();

      for (final msg in messages) {
        final messageId = msg['messageId'] as String;
        final fromDeviceId = msg['fromDeviceId'] as String?;
        final payload = msg['payload'] as String;
        final payloadType = E2EEService.detectPayloadType(payload);

        if (kDebugMode) {
          debugPrint('[PullSync] Processing $payloadType from $fromDeviceId');
        }

        switch (payloadType) {
          case 'v2_key':
            final processed = await _handleGroupKeyMessage(
              group: group,
              payload: payload,
              fromDeviceId: fromDeviceId,
              localDeviceId: deviceId,
            );
            if (processed) {
              ackedMessageIds.add(messageId);
            }
            break;
          case 'v2_data':
            if (group.groupKey == null) {
              continue;
            }

            final plaintext = _e2eeService.decryptFromGroup(
              encryptedPayload: payload,
              groupKeyBase64: group.groupKey!,
            );
            final decoded = jsonDecode(plaintext);
            final rawOperations = decoded is Map<String, dynamic>
                ? (decoded['operations'] as List? ?? const [])
                : decoded as List;
            final operations = rawOperations
                .map(
                  (operation) => _normalizeOperation(
                    operation as Map<String, dynamic>,
                    fromDeviceId: fromDeviceId,
                  ),
                )
                .toList();
            await _applyOperations(operations);
            appliedCount += operations.length;
            ackedMessageIds.add(messageId);
            break;
          case 'v1':
            continue;
        }
      }

      if (ackedMessageIds.isEmpty) {
        return const PullSyncResult.noNewData();
      }

      await _apiClient.ackSync(messageIds: ackedMessageIds);

      // Drain offline queue
      await _queueManager.drainQueue();

      if (kDebugMode) {
        debugPrint(
          '[PullSync] Applied $appliedCount ops, ACK\'d ${ackedMessageIds.length} messages',
        );
      }

      return PullSyncResult.success(appliedCount);
    } on RelayApiException catch (e) {
      return PullSyncResult.error(e.message);
    } catch (e) {
      return PullSyncResult.error(e.toString());
    }
  }

  Future<bool> _handleGroupKeyMessage({
    required GroupInfo group,
    required String payload,
    required String? fromDeviceId,
    required String? localDeviceId,
  }) async {
    final envelope = jsonDecode(payload) as Map<String, dynamic>;
    final targetDeviceId = envelope['toDeviceId'] as String?;
    if (targetDeviceId == null) {
      return false;
    }

    if (targetDeviceId != localDeviceId) {
      return true;
    }

    final owner = _findGroupMember(group.members, fromDeviceId);
    if (owner == null) {
      return false;
    }

    try {
      final groupKey = await _e2eeService.decryptGroupKeyFromOwner(
        encryptedPayload: payload,
        ownerPublicKey: owner.publicKey,
      );
      await _groupRepo.storeGroupKey(group.groupId, groupKey);
      return true;
    } catch (_) {
      return false;
    }
  }

  GroupMember? _findGroupMember(List<GroupMember> members, String? deviceId) {
    if (deviceId == null) return null;
    for (final member in members) {
      if (member.deviceId == deviceId) {
        return member;
      }
    }
    return null;
  }

  Map<String, dynamic> _normalizeOperation(
    Map<String, dynamic> operation, {
    String? fromDeviceId,
  }) {
    final normalized = Map<String, dynamic>.from(operation);
    final op = normalized['op'] as String?;
    if (op == 'insert') {
      normalized['op'] = 'create';
    }

    final entityType = normalized['entityType'] as String?;
    final table = normalized['table'] as String?;
    if (entityType == null && table != null) {
      normalized['entityType'] = switch (table) {
        'transactions' => 'bill',
        _ => table,
      };
      normalized.remove('table');
    }

    if (!normalized.containsKey('entityId')) {
      final data = normalized['data'];
      if (data is Map<String, dynamic> && data['id'] is String) {
        normalized['entityId'] = data['id'];
      } else if (normalized['id'] is String) {
        normalized['entityId'] = normalized['id'];
      }
    }
    normalized.remove('id');
    if (fromDeviceId != null && !normalized.containsKey('fromDeviceId')) {
      normalized['fromDeviceId'] = fromDeviceId;
    }

    return normalized;
  }
}
