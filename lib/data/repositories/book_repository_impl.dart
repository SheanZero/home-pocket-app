import 'package:home_pocket/data/daos/book_dao.dart';
import 'package:home_pocket/features/accounting/domain/models/book.dart';
import 'package:home_pocket/features/accounting/domain/repositories/book_repository.dart';

/// Implementation of BookRepository
///
/// LOCATION: lib/data/repositories/ (SHARED)
/// This is in the shared data layer because multiple features need book access:
/// - Accounting module (manage books)
/// - Reports module (read book data)
/// - Sync module (sync book data)
/// - Settings module (book configuration)
///
/// Per CLAUDE.md Capability Classification Rule: "Will other features need this?" → YES
/// Per Phase 2 Design Doc: Repositories are shared capabilities in lib/data/
///
/// Handles:
/// - Simple CRUD operations
/// - Archive functionality (soft delete)
/// - Find active books (not archived)
/// - Update denormalized statistics (transactionCount, balances)
/// - Filter by device
class BookRepositoryImpl implements BookRepository {
  final BookDao _bookDao;

  BookRepositoryImpl(this._bookDao);

  @override
  Future<void> insert(Book book) async {
    await _bookDao.insertBook(book);
  }

  @override
  Future<void> update(Book book) async {
    // Set updatedAt timestamp
    final bookWithTimestamp = book.copyWith(
      updatedAt: DateTime.now(),
    );
    await _bookDao.updateBook(bookWithTimestamp);
  }

  @override
  Future<void> delete(String id) async {
    await _bookDao.deleteBook(id);
  }

  @override
  Future<Book?> findById(String id) async {
    return await _bookDao.getBookById(id);
  }

  @override
  Future<List<Book>> findAll() async {
    return await _bookDao.getAllBooks();
  }

  @override
  Future<List<Book>> findActive() async {
    return await _bookDao.getActiveBooks();
  }

  @override
  Future<List<Book>> findByDevice(String deviceId) async {
    return await _bookDao.getBooksByDevice(deviceId);
  }

  @override
  Future<void> archive(String id) async {
    await _bookDao.archiveBook(id);
  }

  @override
  Future<void> updateStatistics({
    required String bookId,
    required int transactionCount,
    required int survivalBalance,
    required int soulBalance,
  }) async {
    await _bookDao.updateBookStatistics(
      bookId: bookId,
      transactionCount: transactionCount,
      survivalBalance: survivalBalance,
      soulBalance: soulBalance,
    );
  }
}
