import '../../features/accounting/domain/models/transaction_sync_mapper.dart';
import '../../features/accounting/domain/models/book.dart';
import '../../features/accounting/domain/repositories/transaction_repository.dart';
import '../../features/family_sync/domain/repositories/group_repository.dart';
import 'shadow_book_service.dart';

/// Applies pulled sync operations into local shadow books.
class ApplySyncOperationsUseCase {
  ApplySyncOperationsUseCase({
    required TransactionRepository transactionRepository,
    required ShadowBookService shadowBookService,
    required GroupRepository groupRepository,
  }) : _transactionRepository = transactionRepository,
       _shadowBookService = shadowBookService,
       _groupRepository = groupRepository;

  final TransactionRepository _transactionRepository;
  final ShadowBookService _shadowBookService;
  final GroupRepository _groupRepository;

  Future<void> execute(List<Map<String, dynamic>> operations) async {
    for (final operation in operations) {
      if (operation['entityType'] != 'bill') {
        continue;
      }

      final op = operation['op'] as String?;
      final entityId = operation['entityId'] as String?;
      final fromDeviceId = operation['fromDeviceId'] as String?;
      final data = operation['data'] as Map<String, dynamic>?;
      if (op == null || entityId == null) {
        continue;
      }

      switch (op) {
        case 'create':
        case 'insert':
          if (fromDeviceId == null || data == null) {
            continue;
          }
          await _handleCreate(entityId, fromDeviceId, data);
          break;
        case 'delete':
          await _transactionRepository.softDelete(entityId);
          break;
        case 'update':
          if (fromDeviceId == null || data == null) {
            continue;
          }
          await _handleUpdate(entityId, fromDeviceId, data);
          break;
      }
    }
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
    ).copyWith(updatedAt: DateTime.now());
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
