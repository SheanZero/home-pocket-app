import 'package:home_pocket/features/accounting/domain/models/book.dart';

/// Repository interface for book data access
abstract class BookRepository {
  /// Insert new book
  Future<void> insert(Book book);

  /// Update existing book
  Future<void> update(Book book);

  /// Delete book
  Future<void> delete(String id);

  /// Find book by ID
  Future<Book?> findById(String id);

  /// Get all books
  Future<List<Book>> findAll();

  /// Get active books (not archived)
  Future<List<Book>> findActive();

  /// Get books by device
  Future<List<Book>> findByDevice(String deviceId);

  /// Archive book
  Future<void> archive(String id);

  /// Update book statistics
  Future<void> updateStatistics({
    required String bookId,
    required int transactionCount,
    required int survivalBalance,
    required int soulBalance,
  });
}
