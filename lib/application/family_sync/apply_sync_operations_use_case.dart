import 'package:flutter/foundation.dart';

import '../../features/accounting/domain/models/transaction_sync_mapper.dart';
import '../../features/accounting/domain/models/book.dart';
import '../../features/accounting/domain/repositories/transaction_repository.dart';
import '../../features/family_sync/domain/repositories/group_repository.dart';
import '../../features/shopping_list/domain/models/shopping_item_sync_mapper.dart';
import '../../features/shopping_list/domain/repositories/shopping_item_repository.dart';
import 'shadow_book_service.dart';
import 'sync_avatar_use_case.dart';

/// Applies pulled sync operations into local shadow books and group members.
class ApplySyncOperationsUseCase {
  ApplySyncOperationsUseCase({
    required TransactionRepository transactionRepository,
    required ShoppingItemRepository shoppingItemRepository,
    required ShadowBookService shadowBookService,
    required GroupRepository groupRepository,
    SyncAvatarUseCase? syncAvatarUseCase,
    String? appDirectory,
  }) : _transactionRepository = transactionRepository,
       _shoppingItemRepository = shoppingItemRepository,
       _shadowBookService = shadowBookService,
       _groupRepository = groupRepository,
       _syncAvatarUseCase = syncAvatarUseCase,
       _appDirectory = appDirectory;

  final TransactionRepository _transactionRepository;
  final ShoppingItemRepository _shoppingItemRepository;
  final ShadowBookService _shadowBookService;
  final GroupRepository _groupRepository;
  final SyncAvatarUseCase? _syncAvatarUseCase;
  final String? _appDirectory;

  Future<void> execute(
    List<Map<String, dynamic>> operations, {
    String? groupId,
  }) async {
    for (final operation in operations) {
      final entityType = operation['entityType'] as String?;

      // WR-04 / D37-05: per-operation fault isolation around EVERY entity type.
      // A single poison op (e.g. an unguarded DateTime.parse in a bill op, or
      // any repository throw) must not abort the remaining ops in the pulled
      // batch. Skip-and-continue; the next fullSync reconciles dropped ops.
      try {
        switch (entityType) {
          case 'bill':
            await _applyBillOperation(operation);
          case 'profile':
            await _applyProfileOperation(operation, groupId: groupId);
          case 'avatar':
            await _applyAvatarOperation(operation, groupId: groupId);
          case 'shopping_item':
            await _applyShoppingItemOp(operation);
          default:
            continue;
        }
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint(
            '[ApplySyncOps] $entityType op failed, skipping: $e\n$st',
          );
        }
        continue; // skip-and-continue; next fullSync reconciles
      }
    }
  }

  Future<void> _applyBillOperation(Map<String, dynamic> operation) async {
    final op = operation['op'] as String?;
    final entityId = operation['entityId'] as String?;
    final fromDeviceId = operation['fromDeviceId'] as String?;
    final data = operation['data'] as Map<String, dynamic>?;
    if (op == null || entityId == null) return;

    switch (op) {
      case 'create':
      case 'insert':
        if (fromDeviceId == null || data == null) return;
        await _handleCreate(entityId, fromDeviceId, data);
      case 'delete':
        await _transactionRepository.softDelete(entityId);
      case 'update':
        if (fromDeviceId == null || data == null) return;
        await _handleUpdate(entityId, fromDeviceId, data);
    }
  }

  Future<void> _applyProfileOperation(
    Map<String, dynamic> operation, {
    String? groupId,
  }) async {
    if (groupId == null) return;
    final fromDeviceId = operation['fromDeviceId'] as String?;
    final data = operation['data'] as Map<String, dynamic>?;
    if (fromDeviceId == null || data == null) return;

    await _groupRepository.updateMemberProfile(
      groupId: groupId,
      deviceId: fromDeviceId,
      displayName: data['displayName'] as String? ?? '',
      avatarEmoji: data['avatarEmoji'] as String? ?? '',
    );
  }

  Future<void> _applyAvatarOperation(
    Map<String, dynamic> operation, {
    String? groupId,
  }) async {
    if (groupId == null ||
        _syncAvatarUseCase == null ||
        _appDirectory == null) {
      return;
    }
    final fromDeviceId = operation['fromDeviceId'] as String?;
    final data = operation['data'] as Map<String, dynamic>?;
    if (fromDeviceId == null || data == null) return;

    await _syncAvatarUseCase.handleAvatarSync(
      groupId: groupId,
      senderDeviceId: fromDeviceId,
      payload: data,
      appDirectory: _appDirectory,
    );
  }

  Future<void> _handleCreate(
    String entityId,
    String fromDeviceId,
    Map<String, dynamic> data,
  ) async {
    final existing = await _transactionRepository.findById(entityId);
    if (existing != null) {
      return;
    }

    final shadowBook = await _shadowBookService.findShadowBook(fromDeviceId);
    final resolvedShadowBook =
        shadowBook ?? await _createShadowBookForSender(fromDeviceId);
    if (resolvedShadowBook == null) {
      return;
    }

    final transaction = TransactionSyncMapper.fromSyncMap(
      data,
      bookId: resolvedShadowBook.id,
      deviceId: fromDeviceId,
    );
    await _transactionRepository.insert(transaction);
  }

  Future<void> _handleUpdate(
    String entityId,
    String fromDeviceId,
    Map<String, dynamic> data,
  ) async {
    final existing = await _transactionRepository.findById(entityId);
    if (existing == null) {
      await _handleCreate(entityId, fromDeviceId, data);
      return;
    }

    final updated =
        TransactionSyncMapper.fromSyncMap(
          data,
          bookId: existing.bookId,
          deviceId: fromDeviceId,
        ).copyWith(
          updatedAt: data['updatedAt'] != null
              ? DateTime.parse(data['updatedAt'] as String)
              : DateTime.now(),
        );
    await _transactionRepository.update(updated);
  }

  Future<void> _applyShoppingItemOp(Map<String, dynamic> operation) async {
    final op = operation['op'] as String?;
    final entityId = operation['entityId'] as String?;
    final fromDeviceId = operation['fromDeviceId'] as String?;
    final data = operation['data'] as Map<String, dynamic>?;
    if (op == null || entityId == null) return;

    switch (op) {
      case 'create':
      case 'insert':
        if (data == null) return;
        await _handleShoppingCreate(entityId, fromDeviceId, data);
      case 'delete':
        // Soft-delete (tombstone) — never hard-delete
        await _shoppingItemRepository.softDelete(entityId);
      case 'update':
        if (data == null) return;
        await _handleShoppingUpdate(entityId, data);
    }
  }

  Future<void> _handleShoppingCreate(
    String entityId,
    String? fromDeviceId,
    Map<String, dynamic> data,
  ) async {
    // Idempotent: skip if already exists (analog _handleCreate)
    final existing = await _shoppingItemRepository.findById(entityId);
    if (existing != null) return;

    // No shadow-book concept for shopping items — they belong to the shared list
    final item = ShoppingItemSyncMapper.fromSyncMap(
      data,
      fromDeviceId: fromDeviceId,
    );
    await _shoppingItemRepository.upsert(item);
  }

  Future<void> _handleShoppingUpdate(
    String entityId,
    Map<String, dynamic> data,
  ) async {
    final existing = await _shoppingItemRepository.findById(entityId);
    if (existing == null) {
      // WR-01: do NOT fabricate a live row from an unknown-ID update. The SC-4
      // tombstone guard (existing.isDeleted) only protects rows that exist
      // locally; fromSyncMap never parses isDeleted (defaults to false), so a
      // synthesized row is always live. If a 'delete' op was dropped (D37-05
      // fault-isolation skip) or arrives out-of-order after this 'update',
      // creating a live row here would resurrect a deleted item. Defer to the
      // next fullSync to reconcile rows we have never seen.
      return;
    }

    // SC-4: tombstone wins — soft-deleted item never resurrected
    // MUST be first check, before any field merging
    if (existing.isDeleted) return;

    final incomingUpdatedAt = data['updatedAt'] != null
        ? DateTime.parse(data['updatedAt'] as String)
        : DateTime.now();

    // CR-01: last-writer-wins — drop the ENTIRE incoming op when it is strictly
    // older than the local row, instead of applying it and patching a single
    // field. This is symmetric across all fields and closes the asymmetric
    // completion hole (a stale remote completion can no longer revert a newer
    // local un-complete, and a stale remote edit can no longer clobber a newer
    // local rename/quantity/note/etc.). The previous completion-only guard only
    // protected completedAt and left every other field exposed.
    final localUpdatedAt = existing.updatedAt ?? existing.createdAt;
    if (incomingUpdatedAt.isBefore(localUpdatedAt)) {
      // Local row is newer — remote op is stale, ignore it entirely.
      return;
    }

    // sortOrder is a local-only field excluded from the sync wire
    // (ShoppingItemSyncMapper). fromSyncMap therefore rebuilds it with the
    // Freezed default (0); preserve the local order so a remote edit does not
    // reset a locally-reordered item to position 0 (defeats D37-01).
    final updated = ShoppingItemSyncMapper.fromSyncMap(
      data,
      fromDeviceId: null,
    ).copyWith(id: entityId, sortOrder: existing.sortOrder);

    await _shoppingItemRepository.upsert(updated);
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
