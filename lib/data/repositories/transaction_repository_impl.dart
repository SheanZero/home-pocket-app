import 'dart:convert';

import '../../features/accounting/domain/models/entry_source.dart';
import '../../features/accounting/domain/models/transaction.dart';
import '../../features/accounting/domain/repositories/transaction_repository.dart';
import '../../infrastructure/crypto/services/field_encryption_service.dart';
import '../../shared/constants/sort_config.dart';
import '../app_database.dart';
import '../daos/transaction_dao.dart';

/// Concrete implementation of [TransactionRepository].
///
/// Handles encrypting/decrypting the `note` field via [FieldEncryptionService].
class TransactionRepositoryImpl implements TransactionRepository {
  TransactionRepositoryImpl({
    required TransactionDao dao,
    required FieldEncryptionService encryptionService,
  }) : _dao = dao,
       _encryptionService = encryptionService;

  final TransactionDao _dao;
  final FieldEncryptionService _encryptionService;

  @override
  Future<void> insert(Transaction transaction) async {
    String? encryptedNote;
    if (transaction.note != null && transaction.note!.isNotEmpty) {
      encryptedNote = await _encryptionService.encryptField(transaction.note!);
    }

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
      joyFullness: transaction.joyFullness,
      entrySource: transaction.entrySource.name,
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
    String? encryptedNote;
    if (transaction.note != null && transaction.note!.isNotEmpty) {
      encryptedNote = await _encryptionService.encryptField(transaction.note!);
    }

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
      joyFullness: transaction.joyFullness,
      entrySource: transaction.entrySource.name,
      updatedAt: transaction.updatedAt,
    );
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
      joyFullness: row.joyFullness,
      entrySource: EntrySource.values.byName(row.entrySource),
    );
  }
}
