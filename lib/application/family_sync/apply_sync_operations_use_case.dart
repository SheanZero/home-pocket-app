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
      if (resolvedGroupId == null || resolvedGroupId.isEmpty) {
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
        groupId: resolvedGroupId,
      );
      return ApplySyncOperationsResult([result]);
    }
    if (resolvedGroupId == null || resolvedGroupId.isEmpty) {
      return ApplySyncOperationsResult(
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
    }
    final results = <SyncOperationApplyResult>[];
    for (final operation in operations) {
      final inspection = _inspectOperation(operation);
      final rawEntityType = operation['entityType'];
      final entityType = rawEntityType is String ? rawEntityType : null;
      final operationId = inspection.operationId;
      final messageId = inspection.messageId;
      if (inspection.resourceError != null) {
        results.add(
          await _quarantineSafeSummary(
            operationId: operationId,
            groupId: resolvedGroupId,
            messageId: messageId,
            entityType: inspection.safeEntityType,
            sourceBytes: inspection.sourceBytes,
            digest: inspection.digest,
            errorCode: inspection.resourceError!,
          ),
        );
        continue;
      }
      try {
        if (await _inboundRepository.isApplied(
          groupId: resolvedGroupId,
          operationId: operationId,
        )) {
          // If the process crashed after marking applied but before removing an
          // older quarantine row, converge the UI ledger on redelivery.
          await _inboundRepository.discardQuarantine(
            groupId: resolvedGroupId,
            operationId: operationId,
          );
          results.add(
            SyncOperationApplyResult(
              operationId: operationId,
              status: SyncOperationApplyStatus.alreadyApplied,
            ),
          );
          continue;
        }
      } catch (_) {
        results.add(
          SyncOperationApplyResult(
            operationId: operationId,
            status: SyncOperationApplyStatus.failed,
            errorCode: 'applied_ledger_read_failed',
          ),
        );
        continue;
      }

      try {
        final protocolError = operation['_protocolErrorCode'];
        if (protocolError is String && protocolError.isNotEmpty) {
          throw SyncOperationPermanentException(
            protocolError == 'operation_not_object'
                ? protocolError
                : 'invalid_operation_payload',
          );
        }
        switch (entityType) {
          case 'bill':
            await _applyBillOperation(operation);
          case 'profile':
            await _applyProfileOperation(operation, groupId: resolvedGroupId);
          case 'avatar':
            await _applyAvatarOperation(operation, groupId: resolvedGroupId);
          case 'shopping_item':
            await _applyShoppingItemOp(operation);
          default:
            throw const SyncOperationPermanentException(
              'unsupported_entity_type',
            );
        }
        await _inboundRepository.markApplied(
          operationId: operationId,
          groupId: resolvedGroupId,
          messageId: messageId,
        );
        results.add(
          SyncOperationApplyResult(
            operationId: operationId,
            status: SyncOperationApplyStatus.applied,
          ),
        );
      } on SyncOperationPermanentException catch (error) {
        results.add(
          await _quarantine(
            operationId: operationId,
            groupId: resolvedGroupId,
            messageId: messageId,
            errorCode: error.errorCode,
            operationJson: inspection.operationJson,
          ),
        );
      } on AvatarSyncValidationException {
        results.add(
          await _quarantine(
            operationId: operationId,
            groupId: resolvedGroupId,
            messageId: messageId,
            errorCode: 'avatar_validation_failed',
            operationJson: inspection.operationJson,
          ),
        );
      } on FormatException {
        results.add(
          await _quarantine(
            operationId: operationId,
            groupId: resolvedGroupId,
            messageId: messageId,
            errorCode: 'invalid_operation_payload',
            operationJson: inspection.operationJson,
          ),
        );
      } on ArgumentError {
        results.add(
          await _quarantine(
            operationId: operationId,
            groupId: resolvedGroupId,
            messageId: messageId,
            errorCode: 'invalid_operation_payload',
            operationJson: inspection.operationJson,
          ),
        );
      } on TypeError {
        results.add(
          await _quarantine(
            operationId: operationId,
            groupId: resolvedGroupId,
            messageId: messageId,
            errorCode: 'invalid_operation_payload',
            operationJson: inspection.operationJson,
          ),
        );
      } on SyncOperationTransientException catch (error) {
        results.add(
          SyncOperationApplyResult(
            operationId: operationId,
            status: SyncOperationApplyStatus.failed,
            errorCode: error.errorCode,
          ),
        );
      } catch (_) {
        if (kDebugMode) {
          debugPrint(
            '[ApplySyncOps] operation failed: apply_temporary_failure',
          );
        }
        results.add(
          SyncOperationApplyResult(
            operationId: operationId,
            status: SyncOperationApplyStatus.failed,
            errorCode: 'apply_temporary_failure',
          ),
        );
      }
    }
    _logQuarantineCounts(results);
    return ApplySyncOperationsResult(results);
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

  ({
    String operationJson,
    String operationId,
    String messageId,
    String safeEntityType,
    String digest,
    int sourceBytes,
    String? resourceError,
  })
  _inspectOperation(Map<String, dynamic> operation) {
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
    final op = operation['op'] as String?;
    final entityId = operation['entityId'] as String?;
    final fromDeviceId = operation['fromDeviceId'] as String?;
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
      final privacyViolation = TransactionFamilySyncPolicy.inboundViolation(
        data,
      );
      if (privacyViolation != null) {
        throw SyncOperationPermanentException(privacyViolation);
      }
    }

    final existing = await _transactionRepository.findById(entityId);
    final revision = _operationRevision(operation, data);
    final originDeviceId =
        operation['originDeviceId'] as String? ??
        data?['syncOriginDeviceId'] as String? ??
        fromDeviceId ??
        '';
    final isDeleted = op == 'delete' || data?['isDeleted'] == true;

    final Transaction incoming;
    if (data != null && _hasCompleteBillState(data)) {
      final sourceDeviceId = fromDeviceId ?? originDeviceId;
      if (sourceDeviceId.isEmpty) {
        throw const SyncOperationPermanentException('missing_bill_sender');
      }
      final bookId =
          existing?.bookId ?? (await _resolveShadowBook(sourceDeviceId))?.id;
      if (bookId == null) {
        throw const SyncOperationTransientException('shadow_book_unavailable');
      }

      // Custom category semantics travel inside the same opaque E2EE bill.
      // Apply them before the bill so a committed transaction is immediately
      // renderable. The merge is idempotent and versioned independently.
      await _categoryReferenceSyncService?.applyFromBillData(data);

      final normalizedData = Map<String, dynamic>.of(data)
        ..['id'] = entityId
        ..['isDeleted'] = isDeleted
        ..['syncRevision'] = revision
        ..['syncOriginDeviceId'] = originDeviceId;
      if (op != 'create' &&
          op != 'insert' &&
          normalizedData['updatedAt'] == null) {
        normalizedData['updatedAt'] = _operationTime(
          operation,
          data,
        ).toUtc().toIso8601String();
      }
      incoming = TransactionSyncMapper.fromSyncMap(
        normalizedData,
        bookId: bookId,
        deviceId: sourceDeviceId,
      );
    } else {
      // Legacy delete operations did not carry complete entity state. They can
      // still advance an existing row, but an unknown legacy delete cannot
      // materialize a safe tombstone. Current producers always send full data.
      if (op != 'delete' || existing == null) {
        throw const SyncOperationPermanentException('incomplete_bill_state');
      }
      final legacyRevision = revision > 0
          ? revision
          : effectiveSyncRevision(existing) + 1;
      final operationTime = _operationTime(operation, data);
      incoming = existing.copyWith(
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

    if (existing != null &&
        TransactionSyncVersion.fromTransaction(
              incoming,
            ).compareTo(TransactionSyncVersion.fromTransaction(existing)) <=
            0) {
      return;
    }

    if (existing == null) {
      await _transactionRepository.insert(incoming);
    } else {
      await _transactionRepository.update(incoming);
    }
  }

  Future<void> _applyProfileOperation(
    Map<String, dynamic> operation, {
    String? groupId,
  }) async {
    if (operation['op'] != 'update') {
      throw const SyncOperationPermanentException(
        'unsupported_profile_operation',
      );
    }
    if (groupId == null || groupId.isEmpty) {
      throw const SyncOperationTransientException('group_context_unavailable');
    }
    final fromDeviceId = operation['fromDeviceId'] as String?;
    final entityId = operation['entityId'] as String?;
    final data = operation['data'] as Map<String, dynamic>?;
    if (fromDeviceId == null || fromDeviceId.isEmpty || data == null) {
      throw const SyncOperationPermanentException('invalid_profile_envelope');
    }
    final schemaVersion = (data['schemaVersion'] as num?)?.toInt();
    final ownerDeviceId = data['ownerDeviceId'] as String?;
    final envelopeRevision = (operation['revision'] as num?)?.toInt();
    final payloadRevision = (data['revision'] as num?)?.toInt();
    final revision = envelopeRevision ?? payloadRevision ?? 0;
    final originDeviceId =
        operation['originDeviceId'] as String? ?? fromDeviceId;
    final displayName = data['displayName'];
    final avatarEmoji = data['avatarEmoji'];
    if ((schemaVersion != null && schemaVersion != 1) ||
        (entityId != null && entityId != fromDeviceId) ||
        (ownerDeviceId != null && ownerDeviceId != fromDeviceId) ||
        revision < 0 ||
        (envelopeRevision != null &&
            payloadRevision != null &&
            envelopeRevision != payloadRevision) ||
        originDeviceId != fromDeviceId ||
        displayName is! String ||
        avatarEmoji is! String) {
      throw const SyncOperationPermanentException('invalid_profile_payload');
    }

    final digest = sha256
        .convert(utf8.encode(jsonEncode([displayName, avatarEmoji])))
        .toString();
    final declaredDigest = data['profileDigest'];
    if (declaredDigest != null && declaredDigest != digest) {
      throw const SyncOperationPermanentException('invalid_profile_payload');
    }

    final versionedRepository =
        _groupRepository is VersionedGroupMemberRepository
        ? _groupRepository as VersionedGroupMemberRepository
        : null;
    if (versionedRepository != null) {
      final group = await _groupRepository.getGroupById(groupId);
      final senderIsActive =
          group != null &&
          group.status == GroupStatus.active &&
          group.members.any(
            (member) =>
                member.deviceId == fromDeviceId && member.status == 'active',
          );
      if (!senderIsActive) {
        throw const SyncOperationPermanentException('invalid_profile_sender');
      }
      await versionedRepository.applyMemberIdentityVersioned(
        groupId: groupId,
        deviceId: fromDeviceId,
        displayName: displayName,
        avatarEmoji: avatarEmoji,
        version: MemberContentVersion(
          revision: revision,
          originDeviceId: originDeviceId,
          contentDigest: digest,
        ),
      );
    } else {
      await _groupRepository.updateMemberIdentity(
        groupId: groupId,
        deviceId: fromDeviceId,
        displayName: displayName,
        avatarEmoji: avatarEmoji,
      );
    }
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
