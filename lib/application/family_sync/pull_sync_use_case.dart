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
import 'group_operation_error.dart';
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
    required this._apiClient,
    required this._e2eeService,
    required this._groupRepo,
    required this._queueManager,
    required this._keyManager,
    required this._applyOperations,
    this._rejectOperationsBatch,
    int maxPagesPerExecution = 50,
  }) : _maxPagesPerExecution = maxPagesPerExecution {
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
    final progress = _PullProgress();
    try {
      final group = await _resolveGroup();
      if (group == null) return const PullSyncResult.noPair();
      progress
        ..group = group
        ..deviceId = await _keyManager.getDeviceId();
      return await _pullPages(progress);
    } on RelayApiException catch (e) {
      return PullSyncResult.error(
        e.message,
        statusCode: e.statusCode,
        appliedCount: progress.appliedCount,
        ackedCount: progress.ackedCount,
        pageCount: progress.pageCount,
      );
    } catch (e) {
      final failure = groupOperationFailureFrom(
        e,
        fallbackMessage: 'Failed to pull family sync data',
      );
      return PullSyncResult.error(
        failure.message,
        appliedCount: progress.appliedCount,
        ackedCount: progress.ackedCount,
        pageCount: progress.pageCount,
      );
    }
  }

  Future<GroupInfo?> _resolveGroup() async =>
      await _groupRepo.getActiveGroup() ?? await _groupRepo.getPendingGroup();

  Future<PullSyncResult> _pullPages(_PullProgress progress) async {
    while (progress.pageCount < _maxPagesPerExecution) {
      final response = RelayPullResponse.fromJson(await _apiClient.pullSync());
      progress.pageCount++;
      _logReceivedPage(response, progress.pageCount);

      if (response.messages.isEmpty) {
        return _finishEmptyPage(response, progress);
      }
      final page = await _processMessages(response.messages, progress);
      final result = await _finishPage(response, page, progress);
      if (result != null) return result;

      // A large backlog must not monopolize the UI isolate between pages.
      await Future<void>.delayed(Duration.zero);
    }
    return _pageLimitResult(progress);
  }

  Future<PullSyncResult> _finishEmptyPage(
    RelayPullResponse response,
    _PullProgress progress,
  ) async {
    if (response.hasMore) {
      return PullSyncResult.error(
        'Relay returned an empty page with hasMore=true',
        appliedCount: progress.appliedCount,
        ackedCount: progress.ackedCount,
        pageCount: progress.pageCount,
      );
    }
    if (progress.ackedCount == 0) {
      return PullSyncResult.noNewData(pageCount: progress.pageCount);
    }
    return _complete(progress);
  }

  Future<_ProcessedPage> _processMessages(
    List<Map<String, dynamic>> messages,
    _PullProgress progress,
  ) async {
    final page = _ProcessedPage();
    for (final message in messages) {
      final result = await _processMessage(message, progress);
      progress.appliedCount += result.appliedCount;
      progress.unsupportedEnvelopeSeen |= result.unsupportedEnvelope;
      if (result.acknowledge) {
        page.ackedMessageIds.add(result.messageId);
      } else {
        page.unacknowledgedMessageIds.add(result.messageId);
      }
      if (result.refreshGroup) {
        progress.group =
            await _groupRepo.getGroupById(progress.group!.groupId) ??
            progress.group;
      }
    }
    return page;
  }

  Future<_MessageResult> _processMessage(
    Map<String, dynamic> message,
    _PullProgress progress,
  ) async {
    final messageId = message['messageId'] as String;
    final payload = message['payload'] as String;
    E2EEService.validateInboundPayloadSize(payload);
    final fromDeviceId = message['fromDeviceId'] as String?;
    final keyEpoch = (message['keyEpoch'] as num?)?.toInt() ?? 1;
    return switch (E2EEService.detectPayloadType(payload)) {
      'v2_key' => _processKeyMessage(
        messageId: messageId,
        payload: payload,
        fromDeviceId: fromDeviceId,
        keyEpoch: keyEpoch,
        messageKind: message['messageKind'] as String? ?? 'data',
        progress: progress,
      ),
      'v2_data' => _processDataMessage(
        message: message,
        messageId: messageId,
        payload: payload,
        fromDeviceId: fromDeviceId,
        keyEpoch: keyEpoch,
        progress: progress,
      ),
      _ => Future.value(_MessageResult.deferred(messageId)),
    };
  }

  Future<_MessageResult> _processKeyMessage({
    required String messageId,
    required String payload,
    required String? fromDeviceId,
    required int keyEpoch,
    required String messageKind,
    required _PullProgress progress,
  }) async {
    final processed = await _handleGroupKeyMessage(
      group: progress.group!,
      payload: payload,
      fromDeviceId: fromDeviceId,
      localDeviceId: progress.deviceId,
      messageKeyEpoch: keyEpoch,
      messageKind: messageKind,
    );
    return processed
        ? _MessageResult.acknowledged(messageId, refreshGroup: true)
        : _MessageResult.deferred(messageId);
  }

  Future<_MessageResult> _processDataMessage({
    required Map<String, dynamic> message,
    required String messageId,
    required String payload,
    required String? fromDeviceId,
    required int keyEpoch,
    required _PullProgress progress,
  }) async {
    final group = progress.group!;
    if (!_canDecryptDataMessage(group, payload, keyEpoch)) {
      return _MessageResult.deferred(messageId);
    }
    final plaintext = _e2eeService.decryptFromGroup(
      encryptedPayload: payload,
      groupKeyBase64: group.groupKey!,
    );
    try {
      final operations = _decodeAndNormalizeOperations(
        plaintext,
        message: message,
        messageId: messageId,
        fromDeviceId: fromDeviceId,
        keyEpoch: keyEpoch,
      );
      final result = await _applyOperations(operations, groupId: group.groupId);
      if (result is ApplySyncOperationsResult) {
        return result.isAckSafe
            ? _MessageResult.acknowledged(
                messageId,
                appliedCount: result.appliedCount,
              )
            : _MessageResult.deferred(messageId);
      }
      return _MessageResult.acknowledged(
        messageId,
        appliedCount: operations.length,
      );
    } on _InboundOperationLimitExceeded {
      return _rejectOversizedMessage(
        groupId: group.groupId,
        messageId: messageId,
        plaintext: plaintext,
      );
    } on _UnsupportedSyncEnvelopeException {
      return _MessageResult.unsupported(messageId);
    } on FormatException {
      return _MessageResult.unsupported(messageId);
    }
  }

  bool _canDecryptDataMessage(GroupInfo group, String payload, int keyEpoch) =>
      group.groupKey != null &&
      keyEpoch == group.keyEpoch &&
      _payloadMatchesEpoch(payload, keyEpoch);

  List<Map<String, dynamic>> _decodeAndNormalizeOperations(
    String plaintext, {
    required Map<String, dynamic> message,
    required String messageId,
    required String? fromDeviceId,
    required int keyEpoch,
  }) {
    final envelope = _decodeOperationsEnvelope(
      jsonDecode(plaintext),
      fromDeviceId: fromDeviceId,
      createdAt: message['createdAt'],
    );
    return envelope.operations.indexed.map((entry) {
      return _normalizeOperation(
        entry.$2,
        fromDeviceId: fromDeviceId,
        transportKeyEpoch: keyEpoch,
        transportMessageId: messageId,
        envelopeVersion: envelope.version,
        operationIndex: entry.$1,
      );
    }).toList();
  }

  Future<_MessageResult> _rejectOversizedMessage({
    required String groupId,
    required String messageId,
    required String plaintext,
  }) async {
    final reject = _rejectOperationsBatch;
    if (reject == null) return _MessageResult.deferred(messageId);
    final bytes = utf8.encode(plaintext);
    final result = await reject(
      groupId: groupId,
      messageId: messageId,
      sourceBytes: bytes.length,
      digest: sha256.convert(bytes).toString(),
    );
    return result.isAckSafe
        ? _MessageResult.acknowledged(messageId)
        : _MessageResult.deferred(messageId);
  }

  Future<PullSyncResult?> _finishPage(
    RelayPullResponse response,
    _ProcessedPage page,
    _PullProgress progress,
  ) async {
    if (page.ackedMessageIds.isEmpty) {
      return _deferredPageResult(
        progress,
        'Pull page contains no currently ACKable messages',
        page.unacknowledgedMessageIds,
      );
    }
    await _apiClient.ackSync(messageIds: page.ackedMessageIds);
    progress.ackedCount += page.ackedMessageIds.length;

    if (page.unacknowledgedMessageIds.isNotEmpty && !response.hasMore) {
      return _deferredPageResult(
        progress,
        'Pull page contains deferred messages',
        page.unacknowledgedMessageIds,
      );
    }
    if (!response.hasMore) return _complete(progress);
    if (progress.pageCount >= _maxPagesPerExecution) {
      return _pageLimitResult(
        progress,
        unacknowledgedMessageIds: page.unacknowledgedMessageIds,
      );
    }
    return null;
  }

  PullSyncResult _deferredPageResult(
    _PullProgress progress,
    String message,
    List<String> unacknowledgedMessageIds,
  ) => PullSyncResult.deferred(
    reason: progress.unsupportedEnvelopeSeen
        ? PullSyncDeferredReason.unsupportedEnvelope
        : PullSyncDeferredReason.noProgress,
    message: message,
    appliedCount: progress.appliedCount,
    ackedCount: progress.ackedCount,
    pageCount: progress.pageCount,
    unacknowledgedMessageIds: unacknowledgedMessageIds,
  );

  PullSyncResult _pageLimitResult(
    _PullProgress progress, {
    List<String> unacknowledgedMessageIds = const [],
  }) => PullSyncResult.deferred(
    reason: PullSyncDeferredReason.pageLimitReached,
    message: 'Pull stopped at the $_maxPagesPerExecution-page limit',
    appliedCount: progress.appliedCount,
    ackedCount: progress.ackedCount,
    pageCount: progress.pageCount,
    unacknowledgedMessageIds: unacknowledgedMessageIds,
  );

  Future<PullSyncResult> _complete(_PullProgress progress) async {
    await _queueManager.drainQueue();
    if (kDebugMode) {
      debugPrint(
        '[PullSync] Applied ${progress.appliedCount} ops, '
        "ACK'd ${progress.ackedCount} messages across "
        '${progress.pageCount} pages',
      );
    }
    return PullSyncResult.success(
      progress.appliedCount,
      ackedCount: progress.ackedCount,
      pageCount: progress.pageCount,
    );
  }

  void _logReceivedPage(RelayPullResponse response, int pageCount) {
    if (kDebugMode) {
      debugPrint(
        '[PullSync] Received ${response.messages.length} messages '
        'on page $pageCount',
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
    final targetDeviceId = envelope['toDeviceId'] as String?;
    if (!_keyEnvelopeMatchesTransport(
      envelope: envelope,
      messageKeyEpoch: messageKeyEpoch,
      targetDeviceId: targetDeviceId,
      localDeviceId: localDeviceId,
    )) {
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
    if (!_isAuthorizedKeySender(
      sender: sender,
      messageKind: messageKind,
      requestId: requestId,
      purpose: purpose,
    )) {
      return false;
    }

    try {
      final groupKey = await _e2eeService.decryptGroupKeyFromOwner(
        encryptedPayload: payload,
        ownerPublicKey: sender!.publicKey,
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

  bool _keyEnvelopeMatchesTransport({
    required Map<String, dynamic> envelope,
    required int messageKeyEpoch,
    required String? targetDeviceId,
    required String? localDeviceId,
  }) =>
      ((envelope['e'] as num?)?.toInt() ?? 1) == messageKeyEpoch &&
      targetDeviceId != null &&
      targetDeviceId == localDeviceId;

  bool _isAuthorizedKeySender({
    required GroupMember? sender,
    required String messageKind,
    required String? requestId,
    required String? purpose,
  }) {
    if (sender == null || sender.status != 'active') return false;
    final hasRequestId = requestId != null && requestId.isNotEmpty;
    return switch (messageKind) {
      'group_key_response' => hasRequestId,
      'owner_transfer_key' =>
        hasRequestId && purpose == OwnerTransferUseCase.envelopePurpose,
      'member_rotation_key' =>
        hasRequestId &&
            sender.role == 'owner' &&
            (purpose == 'member_remove' || purpose == 'member_leave_rotation'),
      _ => sender.role == 'owner',
    };
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
    if (_hasByteSignature(bytes, const [0xff, 0xd8, 0xff])) {
      return 'image/jpeg';
    }
    if (_hasByteSignature(bytes, const [
      0x89,
      0x50,
      0x4e,
      0x47,
      0x0d,
      0x0a,
      0x1a,
      0x0a,
    ])) {
      return 'image/png';
    }
    if (_hasByteSignature(bytes, const [0x52, 0x49, 0x46, 0x46]) &&
        _hasByteSignature(bytes, const [0x57, 0x45, 0x42, 0x50], offset: 8)) {
      return 'image/webp';
    }
    return null;
  }

  bool _hasByteSignature(
    List<int> bytes,
    List<int> signature, {
    int offset = 0,
  }) {
    if (bytes.length < offset + signature.length) return false;
    for (var index = 0; index < signature.length; index++) {
      if (bytes[offset + index] != signature[index]) return false;
    }
    return true;
  }
}

class _PullProgress {
  GroupInfo? group;
  String? deviceId;
  int appliedCount = 0;
  int ackedCount = 0;
  int pageCount = 0;
  bool unsupportedEnvelopeSeen = false;
}

class _ProcessedPage {
  final List<String> ackedMessageIds = [];
  final List<String> unacknowledgedMessageIds = [];
}

class _MessageResult {
  const _MessageResult._({
    required this.messageId,
    required this.acknowledge,
    this.appliedCount = 0,
    this.unsupportedEnvelope = false,
    this.refreshGroup = false,
  });

  factory _MessageResult.acknowledged(
    String messageId, {
    int appliedCount = 0,
    bool refreshGroup = false,
  }) => _MessageResult._(
    messageId: messageId,
    acknowledge: true,
    appliedCount: appliedCount,
    refreshGroup: refreshGroup,
  );

  factory _MessageResult.deferred(String messageId) =>
      _MessageResult._(messageId: messageId, acknowledge: false);

  factory _MessageResult.unsupported(String messageId) => _MessageResult._(
    messageId: messageId,
    acknowledge: false,
    unsupportedEnvelope: true,
  );

  final String messageId;
  final bool acknowledge;
  final int appliedCount;
  final bool unsupportedEnvelope;
  final bool refreshGroup;
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
