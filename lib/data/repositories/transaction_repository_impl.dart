import 'dart:convert';

import '../../features/accounting/domain/models/entry_source.dart';
import '../../features/accounting/domain/models/transaction.dart';
import '../../features/accounting/domain/models/transaction_family_sync_policy.dart';
import '../../features/accounting/domain/repositories/transaction_repository.dart';
import '../../infrastructure/crypto/services/field_encryption_service.dart';
import '../../shared/constants/sort_config.dart';
import '../app_database.dart';
import '../daos/family_sync_outbox_dao.dart';
import '../daos/transaction_dao.dart';

/// Concrete implementation of [TransactionRepository].
///
/// Handles encrypting/decrypting the `note` field via [FieldEncryptionService].
class TransactionRepositoryImpl
    implements TransactionRepository, DurableFamilySyncTransactionRepository {
  TransactionRepositoryImpl({
    required TransactionDao dao,
    required FieldEncryptionService encryptionService,
  }) : _dao = dao,
       _outboxDao = FamilySyncOutboxDao(dao.attachedDatabase),
       _encryptionService = encryptionService;

  final TransactionDao _dao;
  final FamilySyncOutboxDao _outboxDao;
  final FieldEncryptionService _encryptionService;

  @override
  Future<void> insert(Transaction transaction) async {
    final encryptedNote = await _encryptNote(transaction.note);
    await _insertPersisted(transaction, encryptedNote: encryptedNote);
  }

  Future<void> _insertPersisted(
    Transaction transaction, {
    required String? encryptedNote,
  }) async {
    await _dao.insertTransaction(
      id: transaction.id,
      bookId: transaction.bookId,
      deviceId: transaction.deviceId,
      amount: transaction.amount,
      type: transaction.type.name,
      categoryId: transaction.categoryId,
      ledgerType: transaction.ledgerType.name,
      timestamp: transaction.timestamp,
      currentHash: transaction.currentHash,
      createdAt: transaction.createdAt,
      note: encryptedNote,
      photoHash: transaction.photoHash,
      merchant: transaction.merchant,
      metadata: transaction.metadata != null
          ? jsonEncode(transaction.metadata)
          : null,
      prevHash: transaction.prevHash,
      isPrivate: transaction.isPrivate,
      isSynced: transaction.isSynced,
      isDeleted: transaction.isDeleted,
      syncRevision: _effectiveSyncRevision(transaction),
      syncOriginDeviceId: _effectiveSyncOriginDeviceId(transaction),
      familySyncVisibility: transaction.familySyncVisibility.name,
      familySharedRevision: transaction.familySharedRevision,
      joyFullness: transaction.joyFullness,
      entrySource: transaction.entrySource.name,
      // Phase 42 multi-currency triple — persist so foreign rows round-trip.
      originalCurrency: transaction.originalCurrency,
      originalAmount: transaction.originalAmount,
      appliedRate: transaction.appliedRate,
    );
  }

  @override
  Future<Transaction?> findById(String id) async {
    final row = await _dao.findById(id);
    if (row == null) return null;
    return _toModel(row);
  }

  @override
  Future<List<Transaction>> findByBookId(
    String bookId, {
    LedgerType? ledgerType,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
    int offset = 0,
  }) async {
    final rows = await _dao.findByBookId(
      bookId,
      ledgerType: ledgerType?.name,
      categoryId: categoryId,
      startDate: startDate,
      endDate: endDate,
      limit: limit,
      offset: offset,
    );

    return Future.wait(rows.map(_toModel));
  }

  @override
  Future<void> update(Transaction transaction) async {
    final encryptedNote = await _encryptNote(transaction.note);
    await _updatePersisted(transaction, encryptedNote: encryptedNote);
  }

  Future<void> _updatePersisted(
    Transaction transaction, {
    required String? encryptedNote,
  }) async {
    await _dao.updateTransaction(
      id: transaction.id,
      bookId: transaction.bookId,
      deviceId: transaction.deviceId,
      amount: transaction.amount,
      type: transaction.type.name,
      categoryId: transaction.categoryId,
      ledgerType: transaction.ledgerType.name,
      timestamp: transaction.timestamp,
      currentHash: transaction.currentHash,
      createdAt: transaction.createdAt,
      note: encryptedNote,
      photoHash: transaction.photoHash,
      merchant: transaction.merchant,
      metadata: transaction.metadata != null
          ? jsonEncode(transaction.metadata)
          : null,
      prevHash: transaction.prevHash,
      isPrivate: transaction.isPrivate,
      isSynced: transaction.isSynced,
      isDeleted: transaction.isDeleted,
      syncRevision: _effectiveSyncRevision(transaction),
      syncOriginDeviceId: _effectiveSyncOriginDeviceId(transaction),
      familySyncVisibility: transaction.familySyncVisibility.name,
      familySharedRevision: transaction.familySharedRevision,
      joyFullness: transaction.joyFullness,
      entrySource: transaction.entrySource.name,
      updatedAt: transaction.updatedAt,
      // Phase 42 multi-currency triple — persist edited foreign values.
      originalCurrency: transaction.originalCurrency,
      originalAmount: transaction.originalAmount,
      appliedRate: transaction.appliedRate,
    );
  }

  @override
  Future<bool> insertWithFamilySyncOutbox(
    Transaction transaction, {
    Map<String, dynamic>? operation,
  }) async {
    final encryptedNote = await _encryptNote(transaction.note);
    return _dao.attachedDatabase.transaction(() async {
      await _insertPersisted(transaction, encryptedNote: encryptedNote);
      return _enqueueForCurrentGroup(operation);
    });
  }

  @override
  Future<bool> updateWithFamilySyncOutbox(
    Transaction transaction, {
    Map<String, dynamic>? operation,
  }) async {
    final encryptedNote = await _encryptNote(transaction.note);
    return _dao.attachedDatabase.transaction(() async {
      await _updatePersisted(transaction, encryptedNote: encryptedNote);
      return _enqueueForCurrentGroup(operation);
    });
  }

  Future<bool> _enqueueForCurrentGroup(Map<String, dynamic>? operation) async {
    if (operation == null) return false;
    if (!TransactionFamilySyncPolicy.isSafeOutboundOperation(operation)) {
      throw const FormatException('Unsafe family sync operation');
    }
    final group = await _dao.attachedDatabase
        .customSelect(
          "SELECT group_id FROM groups WHERE status = 'active' "
          'ORDER BY group_id LIMIT 2',
        )
        .get();
    if (group.isEmpty) return false;
    if (group.length != 1) {
      throw StateError('Multiple active family groups found');
    }
    final groupId = group.single.read<String>('group_id');
    final entityType = operation['entityType'] as String;
    final entityId = operation['entityId'] as String;
    final revision = (operation['revision'] as num).toInt();
    final durableOperation = Map<String, dynamic>.of(operation)
      ..['operationId'] = 'outbox:$groupId:$entityType:$entityId:$revision';
    return _outboxDao.upsertOperation(
      groupId: groupId,
      operation: durableOperation,
    );
  }

  Future<String?> _encryptNote(String? note) async {
    if (note == null || note.isEmpty) return null;
    return _encryptionService.encryptField(note);
  }

  @override
  Future<void> softDelete(String id) => _dao.softDelete(id);

  @override
  Future<String?> getLatestHash(String bookId) => _dao.getLatestHash(bookId);

  @override
  Future<int> countByBookId(String bookId) => _dao.countByBookId(bookId);

  @override
  Future<List<Transaction>> findAllByBook(String bookId) async {
    final rows = await _dao.findAllByBook(bookId);
    return Future.wait(rows.map(_toModel));
  }

  @override
  Future<void> deleteAllByBook(String bookId) => _dao.deleteAllByBook(bookId);

  @override
  Future<List<Transaction>> findByBookIds(
    List<String> bookIds, {
    LedgerType? ledgerType,
    String? categoryId,
    required DateTime startDate,
    required DateTime endDate,
    SortField sortField = SortField.timestamp,
    SortDirection sortDirection = SortDirection.desc,
  }) async {
    final rows = await _dao.findByBookIds(
      bookIds,
      startDate: startDate,
      endDate: endDate,
      ledgerType: ledgerType?.name,
      categoryId: categoryId,
      sortField: sortField,
      sortDirection: sortDirection,
    );
    return Future.wait(rows.map(_toModel));
  }

  @override
  Stream<List<Transaction>> watchByBookIds(
    List<String> bookIds, {
    LedgerType? ledgerType,
    String? categoryId,
    required DateTime startDate,
    required DateTime endDate,
    SortField sortField = SortField.timestamp,
    SortDirection sortDirection = SortDirection.desc,
  }) {
    return _dao
        .watchByBookIds(
          bookIds,
          startDate: startDate,
          endDate: endDate,
          ledgerType: ledgerType?.name,
          categoryId: categoryId,
          sortField: sortField,
          sortDirection: sortDirection,
        )
        .asyncMap((rows) => Future.wait(rows.map(_toModel)));
  }

  Future<Transaction> _toModel(TransactionRow row) async {
    String? decryptedNote;
    if (row.note != null && row.note!.isNotEmpty) {
      try {
        decryptedNote = await _encryptionService.decryptField(row.note!);
      } catch (_) {
        // Shadow-book notes are encrypted with the originating device key.
        // Decryption fails on other devices. Return null silently —
        // DO NOT log row.note or the exception (may contain ciphertext).
        decryptedNote = null;
      }
    }

    return Transaction(
      id: row.id,
      bookId: row.bookId,
      deviceId: row.deviceId,
      amount: row.amount,
      type: TransactionType.values.firstWhere((e) => e.name == row.type),
      categoryId: row.categoryId,
      ledgerType: LedgerType.values.firstWhere((e) => e.name == row.ledgerType),
      timestamp: row.timestamp,
      note: decryptedNote,
      photoHash: row.photoHash,
      merchant: row.merchant,
      metadata: row.metadata != null
          ? jsonDecode(row.metadata!) as Map<String, dynamic>
          : null,
      prevHash: row.prevHash,
      currentHash: row.currentHash,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      isPrivate: row.isPrivate,
      isSynced: row.isSynced,
      isDeleted: row.isDeleted,
      syncRevision: row.syncRevision,
      syncOriginDeviceId: row.syncOriginDeviceId,
      familySyncVisibility: FamilySyncVisibility.values.byName(
        row.familySyncVisibility,
      ),
      familySharedRevision: row.familySharedRevision,
      joyFullness: row.joyFullness,
      entrySource: EntrySource.values.byName(row.entrySource),
      // Phase 42 multi-currency triple — map DB columns back so foreign rows
      // read as foreign (edit host renders; list annotation shows). null = JPY.
      originalCurrency: row.originalCurrency,
      originalAmount: row.originalAmount,
      appliedRate: row.appliedRate,
    );
  }

  int _effectiveSyncRevision(Transaction transaction) {
    if (transaction.syncRevision > 0) return transaction.syncRevision;
    return (transaction.updatedAt ?? transaction.createdAt)
        .toUtc()
        .microsecondsSinceEpoch;
  }

  String _effectiveSyncOriginDeviceId(Transaction transaction) {
    return transaction.syncOriginDeviceId.isNotEmpty
        ? transaction.syncOriginDeviceId
        : transaction.deviceId;
  }
}
