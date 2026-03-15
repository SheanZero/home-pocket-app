import '../models/book.dart';

/// Abstract repository interface for book data access.
abstract class BookRepository {
  Future<void> insert(Book book);
  Future<Book?> findById(String id);
  Future<Book?> findShadowBookByDeviceId(String ownerDeviceId);
  Future<List<Book>> findShadowBooksByGroupId(String groupId);
  Future<List<Book>> findAll({bool includeArchived});
  Future<void> update(Book book);
  Future<void> archive(String id);
  Future<void> delete(String id);
  Future<void> updateBalances({
    required String bookId,
    required int transactionCount,
    required int survivalBalance,
    required int soulBalance,
  });

  /// Delete all books (for backup restore).
  Future<void> deleteAll();
}
