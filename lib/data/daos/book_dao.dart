import 'package:drift/drift.dart';

import '../app_database.dart';

/// Data access object for the Books table.
class BookDao {
  BookDao(this._db);

  final AppDatabase _db;

  Future<void> insertBook({
    required String id,
    required String name,
    required String currency,
    required String deviceId,
    required DateTime createdAt,
    bool isArchived = false,
    bool isShadow = false,
    String? groupId,
    String? ownerDeviceId,
    String? ownerDeviceName,
  }) async {
    await _db
        .into(_db.books)
        .insert(
          BooksCompanion.insert(
            id: id,
            name: name,
            currency: currency,
            deviceId: deviceId,
            createdAt: createdAt,
            isArchived: Value(isArchived),
            isShadow: Value(isShadow),
            groupId: Value(groupId),
            ownerDeviceId: Value(ownerDeviceId),
            ownerDeviceName: Value(ownerDeviceName),
          ),
        );
  }

  Future<void> insertShadowBook({
    required String id,
    required String name,
    required String currency,
    required String deviceId,
    required DateTime createdAt,
    required String groupId,
    required String ownerDeviceId,
    String? ownerDeviceName,
  }) {
    return insertBook(
      id: id,
      name: name,
      currency: currency,
      deviceId: deviceId,
      createdAt: createdAt,
      isShadow: true,
      groupId: groupId,
      ownerDeviceId: ownerDeviceId,
      ownerDeviceName: ownerDeviceName,
    );
  }

  Future<BookRow?> findById(String id) async {
    return (_db.select(
      _db.books,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<BookRow?> findShadowBookByOwnerDeviceId(String ownerDeviceId) async {
    final query = _db.select(_db.books)
      ..where((t) => t.isShadow.equals(true))
      ..where((t) => t.ownerDeviceId.equals(ownerDeviceId))
      ..limit(1);
    return query.getSingleOrNull();
  }

  Future<List<BookRow>> findShadowBooksByGroupId(String groupId) {
    final query = _db.select(_db.books)
      ..where((t) => t.isShadow.equals(true))
      ..where((t) => t.groupId.equals(groupId))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return query.get();
  }

  Future<List<BookRow>> findAll({
    bool includeArchived = false,
    bool includeShadow = false,
  }) async {
    final query = _db.select(_db.books);
    if (!includeArchived) {
      query.where((t) => t.isArchived.equals(false));
    }
    if (!includeShadow) {
      query.where((t) => t.isShadow.equals(false));
    }
    query.orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return query.get();
  }

  Future<void> updateBook({
    required String id,
    String? name,
    String? currency,
    bool? isArchived,
    DateTime? updatedAt,
  }) async {
    await (_db.update(_db.books)..where((t) => t.id.equals(id))).write(
      BooksCompanion(
        name: name != null ? Value(name) : const Value.absent(),
        currency: currency != null ? Value(currency) : const Value.absent(),
        isArchived: isArchived != null
            ? Value(isArchived)
            : const Value.absent(),
        updatedAt: updatedAt != null ? Value(updatedAt) : const Value.absent(),
      ),
    );
  }

  Future<void> archiveBook(String id) async {
    await updateBook(id: id, isArchived: true, updatedAt: DateTime.now());
  }

  /// Delete all books (hard delete, for backup restore).
  Future<void> deleteAll() async {
    await _db.delete(_db.books).go();
  }

  Future<void> deleteBook(String id) async {
    await (_db.delete(_db.books)..where((t) => t.id.equals(id))).go();
  }

  Future<void> updateBalances({
    required String bookId,
    required int transactionCount,
    required int survivalBalance,
    required int soulBalance,
  }) async {
    await (_db.update(_db.books)..where((t) => t.id.equals(bookId))).write(
      BooksCompanion(
        transactionCount: Value(transactionCount),
        survivalBalance: Value(survivalBalance),
        soulBalance: Value(soulBalance),
      ),
    );
  }
}
