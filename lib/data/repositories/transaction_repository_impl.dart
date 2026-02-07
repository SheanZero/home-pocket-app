import 'dart:developer' as dev;
import 'dart:math' as math;

import '../../features/accounting/domain/models/transaction.dart';
import '../../features/accounting/domain/repositories/transaction_repository.dart';
import '../../infrastructure/crypto/services/field_encryption_service.dart';
import '../app_database.dart';
import '../daos/transaction_dao.dart';

String _trunc(String s, [int len = 16]) =>
    s.length <= len ? s : '${s.substring(0, math.min(len, s.length))}...';

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
    dev.log(
      '[4/7 Repo Insert] amount=${transaction.amount} (int), '
      'note(plain)="${transaction.note}"',
      name: 'DataFlow',
    );

    String? encryptedNote;
    if (transaction.note != null && transaction.note!.isNotEmpty) {
      encryptedNote = await _encryptionService.encryptField(transaction.note!);
      dev.log(
        '[5/7 Note Encrypted] plain="${transaction.note}" → '
        'cipher="${_trunc(encryptedNote, 20)}" '
        '(len=${encryptedNote.length})',
        name: 'DataFlow',
      );
    }

    dev.log(
      '[6/7 DAO Insert] amount=${transaction.amount} (int, stored as-is), '
      'note(cipher)="${encryptedNote ?? "null"}", '
      'hash=${_trunc(transaction.currentHash)}',
      name: 'DataFlow',
    );

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
      prevHash: transaction.prevHash,
      isPrivate: transaction.isPrivate,
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
    await _dao.softDelete(transaction.id);
    await insert(transaction);
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

  Future<Transaction> _toModel(TransactionRow row) async {
    dev.log(
      '[Read DB] id=${row.id}, amount=${row.amount} (int from DB), '
      'note(cipher)="${row.note != null ? _trunc(row.note!, 20) : "null"}"',
      name: 'DataFlow',
    );

    String? decryptedNote;
    if (row.note != null && row.note!.isNotEmpty) {
      decryptedNote = await _encryptionService.decryptField(row.note!);
      dev.log(
        '[Read Decrypt] cipher → plain="$decryptedNote"',
        name: 'DataFlow',
      );
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
      prevHash: row.prevHash,
      currentHash: row.currentHash,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      isPrivate: row.isPrivate,
      isSynced: row.isSynced,
      isDeleted: row.isDeleted,
    );
  }
}
