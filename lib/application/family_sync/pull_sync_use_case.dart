import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../../features/family_sync/domain/models/group_info.dart';
import '../../features/family_sync/domain/models/group_member.dart';
import '../../features/family_sync/domain/models/inbound_sync_resource_policy.dart';
import '../../features/family_sync/domain/repositories/group_repository.dart';
import '../../infrastructure/crypto/services/key_manager.dart';
import '../../infrastructure/sync/e2ee_service.dart';
import '../../infrastructure/sync/relay_api_client.dart';
import '../../infrastructure/sync/sync_queue_manager.dart';
import 'apply_sync_operations_use_case.dart';
import 'transfer_owner_use_case.dart';

/// Result of pulling sync data.
sealed class PullSyncResult {
  const PullSyncResult();

  const factory PullSyncResult.success(
    int appliedCount, {
    int ackedCount,
    int pageCount,
  }) = PullSyncSuccess;
  const factory PullSyncResult.noNewData({int pageCount}) = PullSyncNoNewData;
  const factory PullSyncResult.noPair() = PullSyncNoPair;
  const factory PullSyncResult.deferred({
    required PullSyncDeferredReason reason,
    required String message,
    int appliedCount,
    int ackedCount,
    int pageCount,
    List<String> unacknowledgedMessageIds,
  }) = PullSyncDeferred;
  const factory PullSyncResult.error(
    String message, {
    int? statusCode,
    int appliedCount,
    int ackedCount,
    int pageCount,
  }) = PullSyncError;
}

class PullSyncSuccess extends PullSyncResult {
  const PullSyncSuccess(
    this.appliedCount, {
    this.ackedCount = 0,
    this.pageCount = 1,
  });
  final int appliedCount;
  final int ackedCount;
  final int pageCount;
}

class PullSyncNoNewData extends PullSyncResult {
  const PullSyncNoNewData({this.pageCount = 1});
  final int pageCount;
}

class PullSyncNoPair extends PullSyncResult {
  const PullSyncNoPair();
}

/// Why a pull stopped without claiming full reconciliation.
///
/// F-16 can use this stable classification to route blocked messages into a
/// retry/dead-letter policy without parsing human-readable error text.
enum PullSyncDeferredReason {
  noProgress,
  pageLimitReached,
  unsupportedEnvelope,
}

class PullSyncDeferred extends PullSyncResult {
  const PullSyncDeferred({
    required this.reason,
    required this.message,
    this.appliedCount = 0,
    this.ackedCount = 0,
    this.pageCount = 0,
    this.unacknowledgedMessageIds = const [],
  });

  final PullSyncDeferredReason reason;
  final String message;
  final int appliedCount;
  final int ackedCount;
  final int pageCount;
  final List<String> unacknowledgedMessageIds;
}

class PullSyncError extends PullSyncResult {
  const PullSyncError(
    this.message, {
    this.statusCode,
    this.appliedCount = 0,
    this.ackedCount = 0,
    this.pageCount = 0,
  });
  final String message;
  final int? statusCode;
  final int appliedCount;
  final int ackedCount;
  final int pageCount;
}

/// Callback for applying decrypted sync operations.
typedef ApplyOperationsCallback =
    Future<dynamic> Function(
      List<Map<String, dynamic>> operations, {
      String? groupId,
    });

/// Persists a bounded, non-retryable summary for a decrypted operation array
/// rejected before normalization. ACK is allowed only when this callback
/// returns an ACK-safe durable result.
typedef RejectOperationsBatchCallback =
    Future<ApplySyncOperationsResult> Function({
      required String groupId,
      required String messageId,
      required int sourceBytes,
      required String digest,
    });

/// Pulls pending sync messages from the relay server and applies them.
///
/// Flow:
/// 1. Get active pair info
/// 2. Pull one bounded page of unacknowledged messages
/// 3. Decrypt and apply operations via callback
/// 4. ACK the durable messages so the server window advances
/// 5. Repeat while the server reports `hasMore`
/// 6. Drain the offline queue only after full reconciliation
class PullSyncUseCase {
  PullSyncUseCase({
    required RelayApiClient apiClient,
    required E2EEService e2eeService,
    required GroupRepository groupRepo,
    required SyncQueueManager queueManager,
    required KeyManager keyManager,
    required ApplyOperationsCallback applyOperations,
    RejectOperationsBatchCallback? rejectOperationsBatch,
    int maxPagesPerExecution = 50,
  }) : _apiClient = apiClient,
       _e2eeService = e2eeService,
       _groupRepo = groupRepo,
       _queueManager = queueManager,
       _keyManager = keyManager,
       _applyOperations = applyOperations,
       _rejectOperationsBatch = rejectOperationsBatch,
       _maxPagesPerExecution = maxPagesPerExecution {
    if (maxPagesPerExecution <= 0) {
      throw ArgumentError.value(
        maxPagesPerExecution,
        'maxPagesPerExecution',
        'must be greater than zero',
      );
    }
  }

  final RelayApiClient _apiClient;
  final E2EEService _e2eeService;
  final GroupRepository _groupRepo;
  final SyncQueueManager _queueManager;
  final KeyManager _keyManager;
  final ApplyOperationsCallback _applyOperations;
  final RejectOperationsBatchCallback? _rejectOperationsBatch;
  final int _maxPagesPerExecution;

  Future<PullSyncResult> execute() async {
    var appliedCount = 0;
    var ackedCount = 0;
    var pageCount = 0;
    try {
      final activeGroup = await _groupRepo.getActiveGroup();
      final pendingGroup = activeGroup == null
          ? await _groupRepo.getPendingGroup()
          : null;
      final resolvedGroup = activeGroup ?? pendingGroup;
      if (resolvedGroup == null) return const PullSyncResult.noPair();
      var group = resolvedGroup;

      final deviceId = await _keyManager.getDeviceId();
      var unsupportedEnvelopeSeen = false;
      while (pageCount < _maxPagesPerExecution) {
        // Pull returns only messages that have not been ACKed. ACKing each page
        // advances the server-side window without a separate cursor.
        final response = RelayPullResponse.fromJson(
          await _apiClient.pullSync(),
        );
        pageCount++;

        if (kDebugMode) {
          debugPrint(
            '[PullSync] Received ${response.messages.length} messages on page $pageCount',
          );
        }

        if (response.messages.isEmpty) {
          if (response.hasMore) {
            return PullSyncResult.error(
              'Relay returned an empty page with hasMore=true',
              appliedCount: appliedCount,
              ackedCount: ackedCount,
              pageCount: pageCount,
            );
          }
          if (ackedCount == 0) {
            return PullSyncResult.noNewData(pageCount: pageCount);
          }
          await _queueManager.drainQueue();
          return PullSyncResult.success(
            appliedCount,
            ackedCount: ackedCount,
            pageCount: pageCount,
          );
        }

        final ackedMessageIds = <String>[];
        final unacknowledgedMessageIds = <String>[];
        for (final msg in response.messages) {
          final messageId = msg['messageId'] as String;
          final fromDeviceId = msg['fromDeviceId'] as String?;
          final payload = msg['payload'] as String;
          final messageKeyEpoch = (msg['keyEpoch'] as num?)?.toInt() ?? 1;
          final messageKind = msg['messageKind'] as String? ?? 'data';
          final payloadType = E2EEService.detectPayloadType(payload);

          switch (payloadType) {
            case 'v2_key':
              final processed = await _handleGroupKeyMessage(
                group: group,
                payload: payload,
                fromDeviceId: fromDeviceId,
                localDeviceId: deviceId,
                messageKeyEpoch: messageKeyEpoch,
                messageKind: messageKind,
              );
              if (processed) {
                ackedMessageIds.add(messageId);
                group = await _groupRepo.getGroupById(group.groupId) ?? group;
              } else {
                unacknowledgedMessageIds.add(messageId);
              }
              break;
            case 'v2_data':
              if (group.groupKey == null ||
                  messageKeyEpoch != group.keyEpoch ||
                  !_payloadMatchesEpoch(payload, messageKeyEpoch)) {
                unacknowledgedMessageIds.add(messageId);
                continue;
              }

              final plaintext = _e2eeService.decryptFromGroup(
                encryptedPayload: payload,
                groupKeyBase64: group.groupKey!,
              );
              try {
                final decoded = jsonDecode(plaintext);
                final envelope = _decodeOperationsEnvelope(
                  decoded,
                  fromDeviceId: fromDeviceId,
                  createdAt: msg['createdAt'],
                );
                final operations = envelope.operations.indexed.map((entry) {
                  return _normalizeOperation(
                    entry.$2,
                    fromDeviceId: fromDeviceId,
                    transportKeyEpoch: messageKeyEpoch,
                    transportMessageId: messageId,
                    envelopeVersion: envelope.version,
                    operationIndex: entry.$1,
                  );
                }).toList();
                final applyResult = await _applyOperations(
                  operations,
                  groupId: group.groupId,
                );
                if (applyResult is ApplySyncOperationsResult) {
                  if (!applyResult.isAckSafe) {
                    unacknowledgedMessageIds.add(messageId);
                    continue;
                  }
                  appliedCount += applyResult.appliedCount;
                } else {
                  // Compatibility seam for callers that still expose the old
                  // Future<void> callback. Production always returns the
                  // structured result above.
                  appliedCount += operations.length;
                }
                ackedMessageIds.add(messageId);
              } on _InboundOperationLimitExceeded {
                final rejectOperationsBatch = _rejectOperationsBatch;
                if (rejectOperationsBatch == null) {
                  unacknowledgedMessageIds.add(messageId);
                  break;
                }
                final plaintextBytes = utf8.encode(plaintext);
                final rejectResult = await rejectOperationsBatch(
                  groupId: group.groupId,
                  messageId: messageId,
                  sourceBytes: plaintextBytes.length,
                  digest: sha256.convert(plaintextBytes).toString(),
                );
                if (rejectResult.isAckSafe) {
                  ackedMessageIds.add(messageId);
                } else {
                  unacknowledgedMessageIds.add(messageId);
                }
              } on _UnsupportedSyncEnvelopeException {
                unsupportedEnvelopeSeen = true;
                unacknowledgedMessageIds.add(messageId);
              } on FormatException {
                unsupportedEnvelopeSeen = true;
                unacknowledgedMessageIds.add(messageId);
              }
              break;
            case 'v1':
              unacknowledgedMessageIds.add(messageId);
          }
        }

        if (ackedMessageIds.isEmpty) {
          return PullSyncResult.deferred(
            reason: unsupportedEnvelopeSeen
                ? PullSyncDeferredReason.unsupportedEnvelope
                : PullSyncDeferredReason.noProgress,
            message: 'Pull page contains no currently ACKable messages',
            appliedCount: appliedCount,
            ackedCount: ackedCount,
            pageCount: pageCount,
            unacknowledgedMessageIds: unacknowledgedMessageIds,
          );
        }

        await _apiClient.ackSync(messageIds: ackedMessageIds);
        ackedCount += ackedMessageIds.length;

        if (unacknowledgedMessageIds.isNotEmpty && !response.hasMore) {
          return PullSyncResult.deferred(
            reason: unsupportedEnvelopeSeen
                ? PullSyncDeferredReason.unsupportedEnvelope
                : PullSyncDeferredReason.noProgress,
            message: 'Pull page contains deferred messages',
            appliedCount: appliedCount,
            ackedCount: ackedCount,
            pageCount: pageCount,
            unacknowledgedMessageIds: unacknowledgedMessageIds,
          );
        }

        if (!response.hasMore) {
          await _queueManager.drainQueue();
          if (kDebugMode) {
            debugPrint(
              '[PullSync] Applied $appliedCount ops, ACK\'d $ackedCount messages across $pageCount pages',
            );
          }
          return PullSyncResult.success(
            appliedCount,
            ackedCount: ackedCount,
            pageCount: pageCount,
          );
        }

        if (pageCount >= _maxPagesPerExecution) {
          return PullSyncResult.deferred(
            reason: PullSyncDeferredReason.pageLimitReached,
            message: 'Pull stopped at the $_maxPagesPerExecution-page limit',
            appliedCount: appliedCount,
            ackedCount: ackedCount,
            pageCount: pageCount,
            unacknowledgedMessageIds: unacknowledgedMessageIds,
          );
        }

        // A large backlog must not monopolize the UI isolate between pages.
        await Future<void>.delayed(Duration.zero);
      }

      return PullSyncResult.deferred(
        reason: PullSyncDeferredReason.pageLimitReached,
        message: 'Pull stopped at the $_maxPagesPerExecution-page limit',
        appliedCount: appliedCount,
        ackedCount: ackedCount,
        pageCount: pageCount,
      );
    } on RelayApiException catch (e) {
      return PullSyncResult.error(
        e.message,
        statusCode: e.statusCode,
        appliedCount: appliedCount,
        ackedCount: ackedCount,
        pageCount: pageCount,
      );
    } catch (e) {
      return PullSyncResult.error(
        e.toString(),
        appliedCount: appliedCount,
        ackedCount: ackedCount,
        pageCount: pageCount,
      );
    }
  }

  Future<bool> _handleGroupKeyMessage({
    required GroupInfo group,
    required String payload,
    required String? fromDeviceId,
    required String? localDeviceId,
    required int messageKeyEpoch,
    required String messageKind,
  }) async {
    final envelope = jsonDecode(payload) as Map<String, dynamic>;
    final envelopeEpoch = (envelope['e'] as num?)?.toInt() ?? 1;
    if (envelopeEpoch != messageKeyEpoch) {
      return false;
    }
    final targetDeviceId = envelope['toDeviceId'] as String?;
    if (targetDeviceId == null) {
      return false;
    }

    if (targetDeviceId != localDeviceId) {
      // A relay-routing error must not destroy another device's only copy of
      // the key envelope. Leave it unacknowledged for server-side recovery.
      return false;
    }

    // Obsolete key envelopes are safe to discard and ACK. A key for the
    // current epoch is accepted when this member cleared its old key while
    // awaiting rotation.
    if (messageKeyEpoch < group.keyEpoch) {
      return true;
    }

    final sender = _findGroupMember(group.members, fromDeviceId);
    final requestId = envelope['requestId'] as String?;
    final purpose = envelope['purpose'] as String?;
    final isRecoveryResponse =
        messageKind == 'group_key_response' &&
        requestId != null &&
        requestId.isNotEmpty;
    final isOwnerTransfer =
        messageKind == 'owner_transfer_key' &&
        requestId != null &&
        requestId.isNotEmpty &&
        purpose == OwnerTransferUseCase.envelopePurpose;
    final isMembershipRotation =
        messageKind == 'member_rotation_key' &&
        requestId != null &&
        requestId.isNotEmpty &&
        (purpose == 'member_remove' || purpose == 'member_leave_rotation');
    if (sender == null ||
        sender.status != 'active' ||
        (!isRecoveryResponse &&
            !isOwnerTransfer &&
            !isMembershipRotation &&
            sender.role != 'owner') ||
        (isMembershipRotation && sender.role != 'owner')) {
      return false;
    }

    try {
      final groupKey = await _e2eeService.decryptGroupKeyFromOwner(
        encryptedPayload: payload,
        ownerPublicKey: sender.publicKey,
      );
      await _groupRepo.storeGroupKeyForEpoch(
        group.groupId,
        groupKeyBase64: groupKey,
        keyEpoch: messageKeyEpoch,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  bool _payloadMatchesEpoch(String payload, int messageKeyEpoch) {
    try {
      final envelope = jsonDecode(payload) as Map<String, dynamic>;
      return ((envelope['e'] as num?)?.toInt() ?? 1) == messageKeyEpoch;
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
    required int transportKeyEpoch,
    required String transportMessageId,
    required int envelopeVersion,
    required int operationIndex,
  }) {
    final normalized = Map<String, dynamic>.from(operation);
    final rawOp = normalized['op'];
    final op = rawOp is String ? rawOp : null;
    if (rawOp != null && rawOp is! String) {
      normalized['_protocolErrorCode'] = 'invalid_operation_envelope';
    }
    if (op == 'insert') {
      normalized['op'] = 'create';
    }

    final rawEntityType = normalized['entityType'];
    final entityType = rawEntityType is String ? rawEntityType : null;
    final rawTable = normalized['table'];
    final table = rawTable is String ? rawTable : null;
    if ((rawEntityType != null && rawEntityType is! String) ||
        (rawTable != null && rawTable is! String)) {
      normalized['_protocolErrorCode'] = 'invalid_operation_envelope';
    }
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
    // Relay metadata is authenticated; encrypted operation fields must not be
    // able to impersonate another family member.
    if (fromDeviceId != null) {
      normalized['fromDeviceId'] = fromDeviceId;
    }
    normalized['transportKeyEpoch'] = transportKeyEpoch;
    normalized['transportMessageId'] = transportMessageId;
    normalized['transportEnvelopeVersion'] = envelopeVersion;
    normalized.putIfAbsent(
      'operationId',
      () => 'relay:$transportMessageId:$operationIndex',
    );

    return normalized;
  }

  _DecodedSyncEnvelope _decodeOperationsEnvelope(
    Object? decoded, {
    required String? fromDeviceId,
    required Object? createdAt,
  }) {
    if (decoded is List) {
      return _DecodedSyncEnvelope(
        version: 0,
        operations: _normalizeRawOperationList(decoded),
      );
    }
    if (decoded is! Map<String, dynamic>) {
      throw const _UnsupportedSyncEnvelopeException();
    }

    if (decoded.containsKey('schema') || decoded.containsKey('version')) {
      if (decoded['schema'] != 'home-pocket.sync' || decoded['version'] != 1) {
        throw const _UnsupportedSyncEnvelopeException();
      }
      final currentOperations = decoded['operations'];
      if (currentOperations is! List) {
        throw const _UnsupportedSyncEnvelopeException();
      }
      return _DecodedSyncEnvelope(
        version: 1,
        operations: _normalizeRawOperationList(currentOperations),
      );
    }

    final operations = decoded['operations'];
    if (operations is List) {
      return _DecodedSyncEnvelope(
        version: 0,
        operations: _normalizeRawOperationList(operations),
      );
    }

    // Compatibility for the pre-v1 avatar sender, which encrypted an
    // `avatar_sync` object directly instead of placing it in `operations`.
    // Upgrade it at the trust boundary so old in-flight messages receive the
    // same owner/epoch/integrity checks as the current protocol.
    if (decoded['type'] == 'avatar_sync' && fromDeviceId != null) {
      return _DecodedSyncEnvelope(
        version: 0,
        operations: [
          _upgradeLegacyAvatar(
            decoded,
            fromDeviceId: fromDeviceId,
            createdAt: createdAt,
          ),
        ],
      );
    }
    throw const _UnsupportedSyncEnvelopeException();
  }

  List<Map<String, dynamic>> _normalizeRawOperationList(List<dynamic> raw) {
    if (raw.length > InboundSyncResourcePolicy.maxOperationsPerMessage) {
      throw const _InboundOperationLimitExceeded();
    }
    return raw.indexed.map((entry) {
      final operation = entry.$2;
      if (operation is Map<String, dynamic>) {
        return Map<String, dynamic>.of(operation);
      }
      return <String, dynamic>{
        '_protocolErrorCode': 'operation_not_object',
        '_rawOperationType': operation.runtimeType.toString(),
      };
    }).toList();
  }

  Map<String, dynamic> _upgradeLegacyAvatar(
    Map<String, dynamic> legacy, {
    required String fromDeviceId,
    required Object? createdAt,
  }) {
    final encoded = legacy['avatarImageBase64'];
    List<int>? bytes;
    if (encoded is String) {
      try {
        bytes = base64Decode(encoded);
      } on FormatException {
        bytes = null;
      }
    }
    final revision = createdAt is String
        ? (DateTime.tryParse(createdAt)?.toUtc().microsecondsSinceEpoch ?? 1)
        : 1;
    final hash = legacy['avatarImageHash'];
    return {
      'op': 'update',
      'entityType': 'avatar',
      'entityId': fromDeviceId,
      'operationId':
          'legacy-avatar:$fromDeviceId:$revision:${hash ?? 'invalid'}',
      'revision': revision,
      'originDeviceId': fromDeviceId,
      'timestamp': createdAt,
      'data': {
        'schemaVersion': 1,
        'ownerDeviceId': fromDeviceId,
        'revision': revision,
        'displayName': legacy['displayName'],
        'avatarEmoji': legacy['avatarEmoji'],
        'removed': false,
        'mimeType': bytes == null ? null : _detectLegacyAvatarMime(bytes),
        'byteLength': bytes?.length,
        'sha256': hash,
        'bytesBase64': encoded,
      },
    };
  }

  String? _detectLegacyAvatarMime(List<int> bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xff &&
        bytes[1] == 0xd8 &&
        bytes[2] == 0xff) {
      return 'image/jpeg';
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4e &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0d &&
        bytes[5] == 0x0a &&
        bytes[6] == 0x1a &&
        bytes[7] == 0x0a) {
      return 'image/png';
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }
    return null;
  }
}

class _DecodedSyncEnvelope {
  const _DecodedSyncEnvelope({required this.version, required this.operations});

  final int version;
  final List<Map<String, dynamic>> operations;
}

class _UnsupportedSyncEnvelopeException implements Exception {
  const _UnsupportedSyncEnvelopeException();
}

class _InboundOperationLimitExceeded implements Exception {
  const _InboundOperationLimitExceeded();
}
