import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../../features/accounting/domain/models/transaction_sync_mapper.dart';
import '../../features/accounting/domain/models/transaction_family_sync_policy.dart';
import '../../features/accounting/domain/models/book.dart';
import '../../features/accounting/domain/models/transaction.dart';
import '../../features/accounting/domain/repositories/transaction_repository.dart';
import '../../features/family_sync/domain/repositories/group_repository.dart';
import '../../features/family_sync/domain/models/group_info.dart';
import '../../features/family_sync/domain/models/inbound_sync_resource_policy.dart';
import '../../features/family_sync/domain/models/member_content_version.dart';
import '../../features/family_sync/domain/repositories/inbound_sync_operation_repository.dart';
import '../../features/shopping_list/domain/models/shopping_item_sync_mapper.dart';
import '../../features/shopping_list/domain/models/shopping_item.dart';
import '../../features/shopping_list/domain/repositories/shopping_item_repository.dart';
import 'shadow_book_service.dart';
import 'category_reference_sync_service.dart';
import 'sync_avatar_use_case.dart';
import 'transaction_sync_version.dart';

typedef AppDirectoryResolver = Future<String> Function();

typedef _OperationInspection = ({
  String operationJson,
  String operationId,
  String messageId,
  String safeEntityType,
  String digest,
  int sourceBytes,
  String? resourceError,
});

enum SyncOperationApplyStatus { applied, alreadyApplied, quarantined, failed }

class SyncOperationApplyResult {
  const SyncOperationApplyResult({
    required this.operationId,
    required this.status,
    this.errorCode,
  });

  final String operationId;
  final SyncOperationApplyStatus status;
  final String? errorCode;
}

class ApplySyncOperationsResult {
  const ApplySyncOperationsResult(this.operations);

  final List<SyncOperationApplyResult> operations;

  bool get isAckSafe => operations.every(
    (entry) => entry.status != SyncOperationApplyStatus.failed,
  );

  int get appliedCount => operations
      .where((entry) => entry.status == SyncOperationApplyStatus.applied)
      .length;
}

class SyncOperationPermanentException implements Exception {
  const SyncOperationPermanentException(this.errorCode);

  final String errorCode;
}

class SyncOperationTransientException implements Exception {
  const SyncOperationTransientException(this.errorCode);

  final String errorCode;
}

/// Applies pulled sync operations into local shadow books and group members.
class ApplySyncOperationsUseCase {
  ApplySyncOperationsUseCase({
    required TransactionRepository transactionRepository,
    required ShoppingItemRepository shoppingItemRepository,
    required ShadowBookService shadowBookService,
    required GroupRepository groupRepository,
    required InboundSyncOperationRepository inboundRepository,
    SyncAvatarUseCase? syncAvatarUseCase,
    String? appDirectory,
    AppDirectoryResolver? appDirectoryResolver,
    CategoryReferenceSyncService? categoryReferenceSyncService,
  }) : _transactionRepository = transactionRepository,
       _shoppingItemRepository = shoppingItemRepository,
       _shadowBookService = shadowBookService,
       _groupRepository = groupRepository,
       _inboundRepository = inboundRepository,
       _syncAvatarUseCase = syncAvatarUseCase,
       _categoryReferenceSyncService = categoryReferenceSyncService,
       _appDirectoryResolver =
           appDirectoryResolver ??
           (appDirectory == null ? null : (() async => appDirectory));

  final TransactionRepository _transactionRepository;
  final ShoppingItemRepository _shoppingItemRepository;
  final ShadowBookService _shadowBookService;
  final GroupRepository _groupRepository;
  final InboundSyncOperationRepository _inboundRepository;
  final SyncAvatarUseCase? _syncAvatarUseCase;
  final CategoryReferenceSyncService? _categoryReferenceSyncService;
  final AppDirectoryResolver? _appDirectoryResolver;

  Future<ApplySyncOperationsResult> execute(
    List<Map<String, dynamic>> operations, {
    String? groupId,
  }) async {
    final resolvedGroupId =
        groupId ?? (await _groupRepository.getActiveGroup())?.groupId;
    if (operations.length > InboundSyncResourcePolicy.maxOperationsPerMessage) {
      return _rejectOversizedOperations(operations, resolvedGroupId);
    }
    if (resolvedGroupId == null || resolvedGroupId.isEmpty) {
      return _missingGroupResults(operations);
    }
    final results = <SyncOperationApplyResult>[];
    for (final operation in operations) {
      results.add(await _applyOne(operation, resolvedGroupId));
    }
    _logQuarantineCounts(results);
    return ApplySyncOperationsResult(results);
  }

  Future<ApplySyncOperationsResult> _rejectOversizedOperations(
    List<Map<String, dynamic>> operations,
    String? groupId,
  ) async {
    if (groupId == null || groupId.isEmpty) {
      return const ApplySyncOperationsResult([
        SyncOperationApplyResult(
          operationId: 'rejected-batch:group-context-unavailable',
          status: SyncOperationApplyStatus.failed,
          errorCode: 'group_context_unavailable',
        ),
      ]);
    }
    final result = await _quarantineBatchSummary(
      operations: operations,
      groupId: groupId,
    );
    return ApplySyncOperationsResult([result]);
  }

  ApplySyncOperationsResult _missingGroupResults(
    List<Map<String, dynamic>> operations,
  ) => ApplySyncOperationsResult(
    operations
        .map(
          (operation) => SyncOperationApplyResult(
            operationId: _operationId(operation),
            status: SyncOperationApplyStatus.failed,
            errorCode: 'group_context_unavailable',
          ),
        )
        .toList(growable: false),
  );

  Future<SyncOperationApplyResult> _applyOne(
    Map<String, dynamic> operation,
    String groupId,
  ) async {
    final inspection = _inspectOperation(operation);
    if (inspection.resourceError != null) {
      return _quarantineSafeSummary(
        operationId: inspection.operationId,
        groupId: groupId,
        messageId: inspection.messageId,
        entityType: inspection.safeEntityType,
        sourceBytes: inspection.sourceBytes,
        digest: inspection.digest,
        errorCode: inspection.resourceError!,
      );
    }
    final prior = await _priorApplicationResult(
      groupId: groupId,
      operationId: inspection.operationId,
    );
    if (prior != null) return prior;

    try {
      await _dispatchOperation(operation, groupId);
      await _inboundRepository.markApplied(
        operationId: inspection.operationId,
        groupId: groupId,
        messageId: inspection.messageId,
      );
      return SyncOperationApplyResult(
        operationId: inspection.operationId,
        status: SyncOperationApplyStatus.applied,
      );
    } catch (error) {
      return _applicationFailureResult(
        error: error,
        inspection: inspection,
        groupId: groupId,
      );
    }
  }

  Future<SyncOperationApplyResult?> _priorApplicationResult({
    required String groupId,
    required String operationId,
  }) async {
    try {
      final isApplied = await _inboundRepository.isApplied(
        groupId: groupId,
        operationId: operationId,
      );
      if (!isApplied) return null;
      // If the process crashed after marking applied but before removing an
      // older quarantine row, converge the UI ledger on redelivery.
      await _inboundRepository.discardQuarantine(
        groupId: groupId,
        operationId: operationId,
      );
      return SyncOperationApplyResult(
        operationId: operationId,
        status: SyncOperationApplyStatus.alreadyApplied,
      );
    } catch (_) {
      return SyncOperationApplyResult(
        operationId: operationId,
        status: SyncOperationApplyStatus.failed,
        errorCode: 'applied_ledger_read_failed',
      );
    }
  }

  Future<void> _dispatchOperation(
    Map<String, dynamic> operation,
    String groupId,
  ) async {
    final protocolError = operation['_protocolErrorCode'];
    if (protocolError is String && protocolError.isNotEmpty) {
      throw SyncOperationPermanentException(
        protocolError == 'operation_not_object'
            ? protocolError
            : 'invalid_operation_payload',
      );
    }
    switch (operation['entityType']) {
      case 'bill':
        await _applyBillOperation(operation);
      case 'profile':
        await _applyProfileOperation(operation, groupId: groupId);
      case 'avatar':
        await _applyAvatarOperation(operation, groupId: groupId);
      case 'shopping_item':
        await _applyShoppingItemOp(operation);
      default:
        throw const SyncOperationPermanentException('unsupported_entity_type');
    }
  }

  Future<SyncOperationApplyResult> _applicationFailureResult({
    required Object error,
    required _OperationInspection inspection,
    required String groupId,
  }) async {
    if (error is SyncOperationTransientException) {
      return SyncOperationApplyResult(
        operationId: inspection.operationId,
        status: SyncOperationApplyStatus.failed,
        errorCode: error.errorCode,
      );
    }
    final quarantineCode = _quarantineCodeFor(error);
    if (quarantineCode != null) {
      return _quarantine(
        operationId: inspection.operationId,
        groupId: groupId,
        messageId: inspection.messageId,
        errorCode: quarantineCode,
        operationJson: inspection.operationJson,
      );
    }
    if (kDebugMode) {
      debugPrint('[ApplySyncOps] operation failed: apply_temporary_failure');
    }
    return SyncOperationApplyResult(
      operationId: inspection.operationId,
      status: SyncOperationApplyStatus.failed,
      errorCode: 'apply_temporary_failure',
    );
  }

  String? _quarantineCodeFor(Object error) {
    if (error is SyncOperationPermanentException) return error.errorCode;
    if (error is AvatarSyncValidationException) {
      return 'avatar_validation_failed';
    }
    if (error is FormatException ||
        error is ArgumentError ||
        error is TypeError) {
      return 'invalid_operation_payload';
    }
    return null;
  }

  String _operationId(Map<String, dynamic> operation, {String? digest}) {
    final value = operation['operationId'];
    if (value is String &&
        value.isNotEmpty &&
        _utf8Length(value) <= InboundSyncResourcePolicy.maxOperationIdBytes) {
      return value;
    }
    final resolvedDigest =
        digest ?? sha256.convert(utf8.encode(jsonEncode(operation))).toString();
    return 'legacy:$resolvedDigest';
  }

  Future<SyncOperationApplyResult> _quarantine({
    required String operationId,
    required String groupId,
    required String messageId,
    required String errorCode,
    required String operationJson,
  }) async {
    try {
      await _inboundRepository.quarantine(
        operationId: operationId,
        groupId: groupId,
        messageId: messageId,
        operationJson: operationJson,
        errorCode: errorCode,
        retryable: true,
      );
      return SyncOperationApplyResult(
        operationId: operationId,
        status: SyncOperationApplyStatus.quarantined,
        errorCode: errorCode,
      );
    } catch (_) {
      return SyncOperationApplyResult(
        operationId: operationId,
        status: SyncOperationApplyStatus.failed,
        errorCode: 'quarantine_write_failed',
      );
    }
  }

  Future<SyncOperationApplyResult> _quarantineBatchSummary({
    required List<Map<String, dynamic>> operations,
    required String groupId,
  }) async {
    final encoded = jsonEncode(operations);
    final bytes = utf8.encode(encoded);
    final digest = sha256.convert(bytes).toString();
    final firstMessageId = operations.isEmpty
        ? ''
        : _boundedMessageId(operations.first['transportMessageId'], digest);
    final result = await rejectOversizedBatch(
      groupId: groupId,
      messageId: firstMessageId,
      sourceBytes: bytes.length,
      digest: digest,
    );
    return result.operations.single;
  }

  /// Durably records a decrypted batch rejected before normalization.
  ///
  /// [PullSyncUseCase] calls this at the trust boundary so a large array never
  /// expands into an unbounded list of normalized operation maps.
  Future<ApplySyncOperationsResult> rejectOversizedBatch({
    required String groupId,
    required String messageId,
    required int sourceBytes,
    required String digest,
  }) async {
    final result = await _quarantineSafeSummary(
      operationId: 'rejected-batch:$digest',
      groupId: groupId,
      messageId: _boundedMessageId(messageId, digest),
      entityType: 'batch',
      sourceBytes: sourceBytes,
      digest: digest,
      errorCode: 'batch_operation_limit_exceeded',
    );
    _logQuarantineCounts([result]);
    return ApplySyncOperationsResult([result]);
  }

  Future<SyncOperationApplyResult> _quarantineSafeSummary({
    required String operationId,
    required String groupId,
    required String messageId,
    required String entityType,
    required int sourceBytes,
    required String digest,
    required String errorCode,
  }) async {
    final summary = jsonEncode({
      'kind': 'inbound_operation_rejection',
      'entityType': entityType,
      'sourceBytes': sourceBytes,
      'sha256': digest,
      'reason': errorCode,
    });
    try {
      await _inboundRepository.quarantine(
        operationId: operationId,
        groupId: groupId,
        messageId: messageId,
        operationJson: summary,
        errorCode: errorCode,
        retryable: false,
      );
      return SyncOperationApplyResult(
        operationId: operationId,
        status: SyncOperationApplyStatus.quarantined,
        errorCode: errorCode,
      );
    } catch (_) {
      return SyncOperationApplyResult(
        operationId: operationId,
        status: SyncOperationApplyStatus.failed,
        errorCode: 'quarantine_write_failed',
      );
    }
  }

  _OperationInspection _inspectOperation(Map<String, dynamic> operation) {
    final operationJson = jsonEncode(operation);
    final bytes = utf8.encode(operationJson);
    final digest = sha256.convert(bytes).toString();
    final rawEntityType = operation['entityType'];
    final safeEntityType =
        rawEntityType is String &&
            _utf8Length(rawEntityType) <=
                InboundSyncResourcePolicy.maxEntityTypeBytes
        ? rawEntityType
        : 'invalid';
    String? resourceError;
    if (bytes.length > InboundSyncResourcePolicy.maxOperationJsonBytes) {
      resourceError = 'operation_payload_too_large';
    } else if (!_boundedOptionalString(
          operation['operationId'],
          InboundSyncResourcePolicy.maxOperationIdBytes,
        ) ||
        !_boundedOptionalString(
          operation['entityType'],
          InboundSyncResourcePolicy.maxEntityTypeBytes,
        ) ||
        !_boundedOptionalString(
          operation['entityId'],
          InboundSyncResourcePolicy.maxEntityIdBytes,
        ) ||
        !_boundedOptionalString(
          operation['fromDeviceId'],
          InboundSyncResourcePolicy.maxOriginDeviceIdBytes,
        ) ||
        !_boundedOptionalString(
          operation['transportMessageId'],
          InboundSyncResourcePolicy.maxMessageIdBytes,
        ) ||
        !_boundedOptionalString(
          operation['op'],
          InboundSyncResourcePolicy.maxOperationNameBytes,
        )) {
      resourceError = 'operation_metadata_too_large';
    }
    return (
      operationJson: operationJson,
      operationId: _operationId(operation, digest: digest),
      messageId: _boundedMessageId(operation['transportMessageId'], digest),
      safeEntityType: safeEntityType,
      digest: digest,
      sourceBytes: bytes.length,
      resourceError: resourceError,
    );
  }

  String _boundedMessageId(Object? raw, String digest) {
    if (raw is String &&
        _utf8Length(raw) <= InboundSyncResourcePolicy.maxMessageIdBytes) {
      return raw;
    }
    return raw == null ? '' : 'rejected:$digest';
  }

  bool _boundedOptionalString(Object? raw, int maxBytes) =>
      raw == null || (raw is String && _utf8Length(raw) <= maxBytes);

  int _utf8Length(String value) => utf8.encode(value).length;

  void _logQuarantineCounts(List<SyncOperationApplyResult> results) {
    if (kDebugMode) {
      final counts = <String, int>{};
      for (final result in results) {
        if (result.status != SyncOperationApplyStatus.quarantined) continue;
        final reason = result.errorCode ?? 'unknown_quarantine_reason';
        counts.update(reason, (count) => count + 1, ifAbsent: () => 1);
      }
      for (final entry in counts.entries) {
        if (kDebugMode) {
          debugPrint(
            '[ApplySyncOps] quarantined: reason=${entry.key} count=${entry.value}',
          );
        }
      }
    }
  }

  Future<void> _applyBillOperation(Map<String, dynamic> operation) async {
    final envelope = _parseBillEnvelope(operation);
    final existing = await _transactionRepository.findById(envelope.entityId);
    final revision = _operationRevision(operation, envelope.data);
    final originDeviceId = _billOriginDeviceId(operation, envelope);
    final incoming = await _buildIncomingBill(
      operation: operation,
      envelope: envelope,
      existing: existing,
      revision: revision,
      originDeviceId: originDeviceId,
    );
    if (!_incomingBillIsNewer(incoming, existing)) return;
    await _persistIncomingBill(incoming, existing);
  }

  _BillEnvelope _parseBillEnvelope(Map<String, dynamic> operation) {
    final op = operation['op'] as String?;
    final entityId = operation['entityId'] as String?;
    final data = operation['data'] as Map<String, dynamic>?;
    if (op == null || entityId == null || entityId.isEmpty) {
      throw const SyncOperationPermanentException('invalid_bill_envelope');
    }
    if (!const {
      'create',
      'insert',
      'update',
      'delete',
      'reconcile',
    }.contains(op)) {
      throw const SyncOperationPermanentException('unsupported_bill_operation');
    }
    if (data != null) {
      final violation = TransactionFamilySyncPolicy.inboundViolation(data);
      if (violation != null) throw SyncOperationPermanentException(violation);
    }
    return _BillEnvelope(
      op: op,
      entityId: entityId,
      fromDeviceId: operation['fromDeviceId'] as String?,
      data: data,
    );
  }

  String _billOriginDeviceId(
    Map<String, dynamic> operation,
    _BillEnvelope envelope,
  ) =>
      operation['originDeviceId'] as String? ??
      envelope.data?['syncOriginDeviceId'] as String? ??
      envelope.fromDeviceId ??
      '';

  Future<Transaction> _buildIncomingBill({
    required Map<String, dynamic> operation,
    required _BillEnvelope envelope,
    required Transaction? existing,
    required int revision,
    required String originDeviceId,
  }) {
    final data = envelope.data;
    if (data != null && _hasCompleteBillState(data)) {
      return _buildCompleteBill(
        operation: operation,
        envelope: envelope,
        existing: existing,
        revision: revision,
        originDeviceId: originDeviceId,
      );
    }
    return Future.value(
      _buildLegacyBill(
        operation: operation,
        envelope: envelope,
        existing: existing,
        revision: revision,
        originDeviceId: originDeviceId,
      ),
    );
  }

  Future<Transaction> _buildCompleteBill({
    required Map<String, dynamic> operation,
    required _BillEnvelope envelope,
    required Transaction? existing,
    required int revision,
    required String originDeviceId,
  }) async {
    final data = envelope.data!;
    final sourceDeviceId = envelope.fromDeviceId ?? originDeviceId;
    if (sourceDeviceId.isEmpty) {
      throw const SyncOperationPermanentException('missing_bill_sender');
    }
    final bookId =
        existing?.bookId ?? (await _resolveShadowBook(sourceDeviceId))?.id;
    if (bookId == null) {
      throw const SyncOperationTransientException('shadow_book_unavailable');
    }

    // Category semantics must be committed before the referencing bill.
    await _categoryReferenceSyncService?.applyFromBillData(data);
    final normalizedData = Map<String, dynamic>.of(data)
      ..['id'] = envelope.entityId
      ..['isDeleted'] = envelope.op == 'delete' || data['isDeleted'] == true
      ..['syncRevision'] = revision
      ..['syncOriginDeviceId'] = originDeviceId;
    if (_billNeedsUpdatedAt(envelope.op, normalizedData)) {
      normalizedData['updatedAt'] = _operationTime(
        operation,
        data,
      ).toUtc().toIso8601String();
    }
    return TransactionSyncMapper.fromSyncMap(
      normalizedData,
      bookId: bookId,
      deviceId: sourceDeviceId,
    );
  }

  bool _billNeedsUpdatedAt(String op, Map<String, dynamic> data) =>
      op != 'create' && op != 'insert' && data['updatedAt'] == null;

  Transaction _buildLegacyBill({
    required Map<String, dynamic> operation,
    required _BillEnvelope envelope,
    required Transaction? existing,
    required int revision,
    required String originDeviceId,
  }) {
    // Legacy deletes can advance an existing row but cannot safely create an
    // unknown tombstone. Current producers always carry the complete state.
    if (envelope.op != 'delete' || existing == null) {
      throw const SyncOperationPermanentException('incomplete_bill_state');
    }
    final legacyRevision = revision > 0
        ? revision
        : effectiveSyncRevision(existing) + 1;
    final operationTime = _operationTime(operation, envelope.data);
    return existing.copyWith(
      isDeleted: true,
      updatedAt: operationTime.millisecondsSinceEpoch == 0
          ? DateTime.fromMicrosecondsSinceEpoch(legacyRevision, isUtc: true)
          : operationTime,
      syncRevision: legacyRevision,
      syncOriginDeviceId: originDeviceId.isEmpty
          ? effectiveSyncOriginDeviceId(existing)
          : originDeviceId,
    );
  }

  bool _incomingBillIsNewer(Transaction incoming, Transaction? existing) =>
      existing == null ||
      TransactionSyncVersion.fromTransaction(
            incoming,
          ).compareTo(TransactionSyncVersion.fromTransaction(existing)) >
          0;

  Future<void> _persistIncomingBill(
    Transaction incoming,
    Transaction? existing,
  ) => existing == null
      ? _transactionRepository.insert(incoming)
      : _transactionRepository.update(incoming);

  Future<void> _applyProfileOperation(
    Map<String, dynamic> operation, {
    String? groupId,
  }) async {
    final profile = _parseProfileOperation(operation, groupId);
    final versionedRepository =
        _groupRepository is VersionedGroupMemberRepository
        ? _groupRepository as VersionedGroupMemberRepository
        : null;
    if (versionedRepository != null) {
      if (!await _profileSenderIsActive(profile)) {
        throw const SyncOperationPermanentException('invalid_profile_sender');
      }
      await versionedRepository.applyMemberIdentityVersioned(
        groupId: profile.groupId,
        deviceId: profile.fromDeviceId,
        displayName: profile.validDisplayName,
        avatarEmoji: profile.validAvatarEmoji,
        version: MemberContentVersion(
          revision: profile.revision,
          originDeviceId: profile.originDeviceId,
          contentDigest: profile.digest,
        ),
      );
    } else {
      await _groupRepository.updateMemberIdentity(
        groupId: profile.groupId,
        deviceId: profile.fromDeviceId,
        displayName: profile.validDisplayName,
        avatarEmoji: profile.validAvatarEmoji,
      );
    }
  }

  _ProfileOperation _parseProfileOperation(
    Map<String, dynamic> operation,
    String? groupId,
  ) {
    if (operation['op'] != 'update') {
      throw const SyncOperationPermanentException(
        'unsupported_profile_operation',
      );
    }
    if (groupId == null || groupId.isEmpty) {
      throw const SyncOperationTransientException('group_context_unavailable');
    }
    final fromDeviceId = operation['fromDeviceId'] as String?;
    final data = operation['data'] as Map<String, dynamic>?;
    if (fromDeviceId == null || fromDeviceId.isEmpty || data == null) {
      throw const SyncOperationPermanentException('invalid_profile_envelope');
    }
    final profile = _profileFields(operation, groupId, fromDeviceId, data);
    if (_profilePayloadIsInvalid(operation, data, profile)) {
      throw const SyncOperationPermanentException('invalid_profile_payload');
    }
    final declaredDigest = data['profileDigest'];
    if (declaredDigest != null && declaredDigest != profile.digest) {
      throw const SyncOperationPermanentException('invalid_profile_payload');
    }
    return profile;
  }

  _ProfileOperation _profileFields(
    Map<String, dynamic> operation,
    String groupId,
    String fromDeviceId,
    Map<String, dynamic> data,
  ) {
    final envelopeRevision = (operation['revision'] as num?)?.toInt();
    final payloadRevision = (data['revision'] as num?)?.toInt();
    final displayName = data['displayName'];
    final avatarEmoji = data['avatarEmoji'];
    return _ProfileOperation(
      groupId: groupId,
      fromDeviceId: fromDeviceId,
      displayName: displayName,
      avatarEmoji: avatarEmoji,
      envelopeRevision: envelopeRevision,
      payloadRevision: payloadRevision,
      revision: envelopeRevision ?? payloadRevision ?? 0,
      originDeviceId: operation['originDeviceId'] as String? ?? fromDeviceId,
      digest: sha256
          .convert(utf8.encode(jsonEncode([displayName, avatarEmoji])))
          .toString(),
    );
  }

  bool _profilePayloadIsInvalid(
    Map<String, dynamic> operation,
    Map<String, dynamic> data,
    _ProfileOperation profile,
  ) {
    final schemaVersion = (data['schemaVersion'] as num?)?.toInt();
    if (schemaVersion != null && schemaVersion != 1) return true;
    final entityId = operation['entityId'] as String?;
    if (entityId != null && entityId != profile.fromDeviceId) return true;
    final ownerDeviceId = data['ownerDeviceId'] as String?;
    if (ownerDeviceId != null && ownerDeviceId != profile.fromDeviceId) {
      return true;
    }
    if (profile.revision < 0) return true;
    if (profile.envelopeRevision != null &&
        profile.payloadRevision != null &&
        profile.envelopeRevision != profile.payloadRevision) {
      return true;
    }
    if (profile.originDeviceId != profile.fromDeviceId) return true;
    return profile.displayName is! String || profile.avatarEmoji is! String;
  }

  Future<bool> _profileSenderIsActive(_ProfileOperation profile) async {
    final group = await _groupRepository.getGroupById(profile.groupId);
    return group != null &&
        group.status == GroupStatus.active &&
        group.members.any(
          (member) =>
              member.deviceId == profile.fromDeviceId &&
              member.status == 'active',
        );
  }

  Future<void> _applyAvatarOperation(
    Map<String, dynamic> operation, {
    String? groupId,
  }) async {
    if (operation['op'] != 'update') {
      throw const SyncOperationPermanentException(
        'unsupported_avatar_operation',
      );
    }
    if (groupId == null) {
      throw const SyncOperationTransientException('group_context_unavailable');
    }
    final avatarSync = _syncAvatarUseCase;
    final directoryResolver = _appDirectoryResolver;
    if (avatarSync == null || directoryResolver == null) {
      throw const SyncOperationTransientException(
        'avatar_persistence_unavailable',
      );
    }
    final fromDeviceId = operation['fromDeviceId'] as String?;
    final entityId = operation['entityId'] as String?;
    final messageKeyEpoch = (operation['transportKeyEpoch'] as num?)?.toInt();
    final data = operation['data'] as Map<String, dynamic>?;
    if (fromDeviceId == null ||
        entityId != fromDeviceId ||
        messageKeyEpoch == null ||
        data == null) {
      throw const AvatarSyncValidationException(
        'avatar operation envelope is invalid',
      );
    }

    final appDirectory = await directoryResolver();
    if (appDirectory.isEmpty) {
      throw const SyncOperationTransientException('avatar_storage_unavailable');
    }
    await avatarSync.handleAvatarSync(
      groupId: groupId,
      senderDeviceId: fromDeviceId,
      messageKeyEpoch: messageKeyEpoch,
      payload: data,
      appDirectory: appDirectory,
      envelopeRevision: (operation['revision'] as num?)?.toInt(),
      originDeviceId: operation['originDeviceId'] as String?,
    );
  }

  Future<Book?> _resolveShadowBook(String fromDeviceId) async {
    final shadowBook = await _shadowBookService.findShadowBook(fromDeviceId);
    final resolvedShadowBook =
        shadowBook ?? await _createShadowBookForSender(fromDeviceId);
    return resolvedShadowBook;
  }

  bool _hasCompleteBillState(Map<String, dynamic> data) {
    return data['amount'] is int &&
        data['type'] is String &&
        data['categoryId'] is String &&
        data['ledgerType'] is String &&
        data['timestamp'] is String &&
        data['createdAt'] is String;
  }

  int _operationRevision(
    Map<String, dynamic> operation,
    Map<String, dynamic>? data,
  ) {
    final explicit =
        (operation['revision'] as num?)?.toInt() ??
        (data?['syncRevision'] as num?)?.toInt();
    if (explicit != null && explicit > 0) return explicit;
    return _operationTime(operation, data).toUtc().microsecondsSinceEpoch;
  }

  DateTime _operationTime(
    Map<String, dynamic> operation,
    Map<String, dynamic>? data,
  ) {
    for (final candidate in [
      operation['timestamp'],
      data?['updatedAt'],
      data?['createdAt'],
    ]) {
      if (candidate is String) {
        final parsed = DateTime.tryParse(candidate);
        if (parsed != null) return parsed;
      }
      if (candidate is int) {
        return DateTime.fromMillisecondsSinceEpoch(candidate, isUtc: true);
      }
    }
    return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }

  Future<void> _applyShoppingItemOp(Map<String, dynamic> operation) async {
    final op = operation['op'] as String?;
    final entityId = operation['entityId'] as String?;
    final fromDeviceId = operation['fromDeviceId'] as String?;
    final data = operation['data'] as Map<String, dynamic>?;
    if (op == null || entityId == null || entityId.isEmpty) {
      throw const SyncOperationPermanentException('invalid_shopping_envelope');
    }

    switch (op) {
      case 'create':
      case 'insert':
        if (data == null) return;
        if (!_isPublicShoppingOp(data, op: op, entityId: entityId)) return;
        await _handleShoppingUpsert(
          operation: operation,
          entityId: entityId,
          fromDeviceId: fromDeviceId,
          data: data,
        );
      case 'delete':
        await _handleShoppingDelete(
          operation: operation,
          entityId: entityId,
          fromDeviceId: fromDeviceId,
          data: data,
        );
      case 'update':
        if (data == null) return;
        if (!_isPublicShoppingOp(data, op: op, entityId: entityId)) return;
        await _handleShoppingUpsert(
          operation: operation,
          entityId: entityId,
          fromDeviceId: fromDeviceId,
          data: data,
        );
      default:
        throw const SyncOperationPermanentException(
          'unsupported_shopping_operation',
        );
    }
  }

  /// W2 / SYNC-02: receiver-side privacy gate (D37-06 mirror).
  ///
  /// Sender-side gates (use case + tracker) do not protect against buggy or
  /// older peers — the wire is untrusted input and must be validated at the
  /// application boundary. Inbound create/update ops whose payload is not
  /// explicitly public are dropped per-op (D37-05 skip pattern, not abort).
  bool _isPublicShoppingOp(
    Map<String, dynamic> data, {
    required String op,
    required String entityId,
  }) {
    if (data['listType'] == 'public') return true;
    if (kDebugMode) {
      debugPrint(
        '[ApplySyncOps] dropped: '
        'reason=non_public_shopping_item count=1',
      );
    }
    return false;
  }

  Future<void> _handleShoppingUpsert({
    required Map<String, dynamic> operation,
    required String entityId,
    required String? fromDeviceId,
    required Map<String, dynamic> data,
  }) async {
    final existing = await _shoppingItemRepository.findById(entityId);
    if (existing?.isDeleted == true) return;
    final revision = _operationRevision(operation, data);
    final origin = operation['originDeviceId'] as String? ?? fromDeviceId ?? '';
    if (existing != null &&
        !_shoppingVersionIsNewer(
          revision: revision,
          originDeviceId: origin,
          existing: existing,
        )) {
      return;
    }
    final incoming = ShoppingItemSyncMapper.fromSyncMap(
      data,
      fromDeviceId: fromDeviceId,
      revision: revision,
      originDeviceId: origin,
    );
    await _shoppingItemRepository.upsert(
      existing == null
          ? incoming.copyWith(id: entityId)
          : incoming.copyWith(
              id: entityId,
              sortOrder: existing.sortOrder,
              listType: existing.listType,
            ),
    );
  }

  Future<void> _handleShoppingDelete({
    required Map<String, dynamic> operation,
    required String entityId,
    required String? fromDeviceId,
    required Map<String, dynamic>? data,
  }) async {
    final existing = await _shoppingItemRepository.findById(entityId);
    if (data == null) {
      // Legacy tombstones carried no merge tuple. Preserve compatibility for
      // known deployments; v36 senders always include the minimal versioned
      // payload used by the durable reconciliation path below.
      await _shoppingItemRepository.softDelete(entityId);
      return;
    }
    if (existing?.listType == 'private') return;
    final revision = _operationRevision(operation, data);
    final origin = operation['originDeviceId'] as String? ?? fromDeviceId ?? '';
    if (existing != null && existing.isDeleted) return;
    final existingRevision = existing == null
        ? 0
        : existing.syncRevision > 0
        ? existing.syncRevision
        : (existing.updatedAt ?? existing.createdAt)
              .toUtc()
              .microsecondsSinceEpoch;
    if (existing != null && revision < existingRevision) {
      return;
    }
    if (existing == null) {
      if (data['listType'] != 'public') return;
      final tombstoneData = <String, dynamic>{
        ...data,
        'id': entityId,
        'name': '(deleted)',
        'deviceId': fromDeviceId ?? '',
      };
      await _shoppingItemRepository.upsert(
        ShoppingItemSyncMapper.fromSyncMap(
          tombstoneData,
          fromDeviceId: fromDeviceId,
          revision: revision,
          originDeviceId: origin,
          isDeleted: true,
        ),
      );
      return;
    }
    await _shoppingItemRepository.upsert(
      existing.copyWith(
        isDeleted: true,
        updatedAt: _operationTime(operation, data),
        syncRevision: revision,
        syncOriginDeviceId: origin,
        isSynced: true,
      ),
    );
  }

  bool _shoppingVersionIsNewer({
    required int revision,
    required String originDeviceId,
    required ShoppingItem existing,
  }) {
    final existingRevision = existing.syncRevision > 0
        ? existing.syncRevision
        : (existing.updatedAt ?? existing.createdAt)
              .toUtc()
              .microsecondsSinceEpoch;
    if (revision != existingRevision) {
      return revision > existingRevision;
    }
    return originDeviceId.compareTo(existing.syncOriginDeviceId) > 0;
  }

  Future<Book?> _createShadowBookForSender(String fromDeviceId) async {
    final group =
        await _groupRepository.getActiveGroup() ??
        await _groupRepository.getPendingGroup();
    if (group == null) {
      return null;
    }

    String memberDeviceName = fromDeviceId;
    for (final member in group.members) {
      if (member.deviceId == fromDeviceId) {
        memberDeviceName = member.deviceName;
        break;
      }
    }

    await _shadowBookService.createShadowBook(
      groupId: group.groupId,
      memberDeviceId: fromDeviceId,
      memberDeviceName: memberDeviceName,
    );
    return _shadowBookService.findShadowBook(fromDeviceId);
  }
}

class _BillEnvelope {
  const _BillEnvelope({
    required this.op,
    required this.entityId,
    required this.fromDeviceId,
    required this.data,
  });

  final String op;
  final String entityId;
  final String? fromDeviceId;
  final Map<String, dynamic>? data;
}

class _ProfileOperation {
  const _ProfileOperation({
    required this.groupId,
    required this.fromDeviceId,
    required this.displayName,
    required this.avatarEmoji,
    required this.envelopeRevision,
    required this.payloadRevision,
    required this.revision,
    required this.originDeviceId,
    required this.digest,
  });

  final String groupId;
  final String fromDeviceId;
  final Object? displayName;
  final Object? avatarEmoji;
  final int? envelopeRevision;
  final int? payloadRevision;
  final int revision;
  final String originDeviceId;
  final String digest;

  String get validDisplayName => displayName as String;
  String get validAvatarEmoji => avatarEmoji as String;
}
