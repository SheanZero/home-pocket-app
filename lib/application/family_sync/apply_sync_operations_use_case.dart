import '../../features/accounting/domain/models/transaction_sync_mapper.dart';
import '../../features/accounting/domain/models/book.dart';
import '../../features/accounting/domain/repositories/transaction_repository.dart';
import '../../features/family_sync/domain/repositories/group_repository.dart';
import 'shadow_book_service.dart';
import 'sync_avatar_use_case.dart';

/// Applies pulled sync operations into local shadow books and group members.
class ApplySyncOperationsUseCase {
  ApplySyncOperationsUseCase({
    required TransactionRepository transactionRepository,
    required ShadowBookService shadowBookService,
    required GroupRepository groupRepository,
    SyncAvatarUseCase? syncAvatarUseCase,
    String? appDirectory,
  }) : _transactionRepository = transactionRepository,
       _shadowBookService = shadowBookService,
       _groupRepository = groupRepository,
       _syncAvatarUseCase = syncAvatarUseCase,
       _appDirectory = appDirectory;

  final TransactionRepository _transactionRepository;
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

      switch (entityType) {
        case 'bill':
          await _applyBillOperation(operation);
        case 'profile':
          await _applyProfileOperation(operation, groupId: groupId);
        case 'avatar':
          await _applyAvatarOperation(operation, groupId: groupId);
        default:
          continue;
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
    if (groupId == null || _syncAvatarUseCase == null || _appDirectory == null) {
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

    final updated = TransactionSyncMapper.fromSyncMap(
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
