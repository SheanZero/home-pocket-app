import 'package:drift/drift.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/tables/transactions_table.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart'
    as domain;

part 'transaction_dao.g.dart';

@DriftAccessor(tables: [Transactions])
class TransactionDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionDaoMixin {
  TransactionDao(super.attachedDatabase);

  /// Insert new transaction
  Future<void> insertTransaction(domain.Transaction transaction) async {
    await into(transactions).insert(
      _toEntity(transaction),
      mode: InsertMode.insertOrReplace,
    );
  }

  /// Get transaction by ID
  Future<domain.Transaction?> getTransactionById(String id) async {
    final entity = await (select(transactions)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();

    return entity != null ? _toDomain(entity) : null;
  }

  /// Get transactions by book with optional filters
  Future<List<domain.Transaction>> getTransactionsByBook(
    String bookId, {
    DateTime? startDate,
    DateTime? endDate,
    List<String>? categoryIds,
    domain.LedgerType? ledgerType,
    int limit = 100,
    int offset = 0,
  }) async {
    var query = select(transactions)
      ..where((t) => t.bookId.equals(bookId) & t.isDeleted.equals(false));

    if (startDate != null) {
      query.where((t) => t.timestamp.isBiggerOrEqualValue(startDate));
    }

    if (endDate != null) {
      query.where((t) => t.timestamp.isSmallerThanValue(endDate));
    }

    if (categoryIds != null && categoryIds.isNotEmpty) {
      query.where((t) => t.categoryId.isIn(categoryIds));
    }

    if (ledgerType != null) {
      query.where((t) => t.ledgerType.equals(ledgerType.name));
    }

    query
      ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
      ..limit(limit, offset: offset);

    final entities = await query.get();
    return entities.map(_toDomain).toList();
  }

  /// Update transaction
  Future<void> updateTransaction(domain.Transaction transaction) async {
    await update(transactions).replace(_toEntity(transaction));
  }

  /// Delete transaction (hard delete)
  Future<void> deleteTransaction(String id) async {
    await (delete(transactions)..where((t) => t.id.equals(id))).go();
  }

  /// Soft delete transaction
  Future<void> softDeleteTransaction(String id) async {
    await (update(transactions)..where((t) => t.id.equals(id)))
        .write(const TransactionsCompanion(isDeleted: Value(true)));
  }

  /// Get latest hash for hash chain
  Future<String?> getLatestHash(String bookId) async {
    final result = await (select(transactions)
          ..where((t) => t.bookId.equals(bookId) & t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(1))
        .getSingleOrNull();

    return result?.currentHash;
  }

  /// Count transactions in book
  Future<int> countTransactions(String bookId) async {
    final count = countAll();
    final query = selectOnly(transactions)
      ..addColumns([count])
      ..where(transactions.bookId.equals(bookId) &
          transactions.isDeleted.equals(false));

    return await query.map((row) => row.read(count)!).getSingle();
  }

  /// Convert domain model to entity
  TransactionsCompanion _toEntity(domain.Transaction tx) {
    return TransactionsCompanion.insert(
      id: tx.id,
      bookId: tx.bookId,
      deviceId: tx.deviceId,
      amount: tx.amount,
      type: tx.type.name,
      categoryId: tx.categoryId,
      ledgerType: tx.ledgerType.name,
      timestamp: tx.timestamp,
      note: Value(tx.note),
      photoHash: Value(tx.photoHash),
      merchant: Value(tx.merchant),
      metadata: Value(tx.metadata),
      prevHash: Value(tx.prevHash),
      currentHash: tx.currentHash,
      createdAt: tx.createdAt,
      updatedAt: Value(tx.updatedAt),
      isPrivate: Value(tx.isPrivate),
      isSynced: Value(tx.isSynced),
      isDeleted: Value(tx.isDeleted),
    );
  }

  /// Convert entity to domain model
  domain.Transaction _toDomain(TransactionEntity entity) {
    return domain.Transaction(
      id: entity.id,
      bookId: entity.bookId,
      deviceId: entity.deviceId,
      amount: entity.amount,
      type: domain.TransactionType.values.firstWhere(
        (e) => e.name == entity.type,
      ),
      categoryId: entity.categoryId,
      ledgerType: domain.LedgerType.values.firstWhere(
        (e) => e.name == entity.ledgerType,
      ),
      timestamp: entity.timestamp,
      note: entity.note,
      photoHash: entity.photoHash,
      merchant: entity.merchant,
      metadata: entity.metadata,
      prevHash: entity.prevHash,
      currentHash: entity.currentHash,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      isPrivate: entity.isPrivate,
      isSynced: entity.isSynced,
      isDeleted: entity.isDeleted,
    );
  }
}
