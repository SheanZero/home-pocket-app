import 'package:drift/drift.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/tables/books_table.dart';
import 'package:home_pocket/features/accounting/domain/models/book.dart'
    as domain;

part 'book_dao.g.dart';

@DriftAccessor(tables: [Books])
class BookDao extends DatabaseAccessor<AppDatabase> with _$BookDaoMixin {
  BookDao(super.attachedDatabase);

  /// Insert new book
  Future<void> insertBook(domain.Book book) async {
    await into(books).insert(
      _toEntity(book),
      mode: InsertMode.insertOrReplace,
    );
  }

  /// Get book by ID
  Future<domain.Book?> getBookById(String id) async {
    final entity =
        await (select(books)..where((b) => b.id.equals(id))).getSingleOrNull();

    return entity != null ? _toDomain(entity) : null;
  }

  /// Get all books
  Future<List<domain.Book>> getAllBooks() async {
    final entities = await select(books).get();
    return entities.map(_toDomain).toList();
  }

  /// Get active books (not archived)
  Future<List<domain.Book>> getActiveBooks() async {
    final entities =
        await (select(books)..where((b) => b.isArchived.equals(false))).get();
    return entities.map(_toDomain).toList();
  }

  /// Get books by device
  Future<List<domain.Book>> getBooksByDevice(String deviceId) async {
    final entities = await (select(books)
          ..where((b) => b.deviceId.equals(deviceId)))
        .get();
    return entities.map(_toDomain).toList();
  }

  /// Update book
  Future<void> updateBook(domain.Book book) async {
    await update(books).replace(_toEntity(book));
  }

  /// Delete book (hard delete)
  Future<void> deleteBook(String id) async {
    await (delete(books)..where((b) => b.id.equals(id))).go();
  }

  /// Archive book (soft delete)
  Future<void> archiveBook(String id) async {
    await (update(books)..where((b) => b.id.equals(id))).write(
      BooksCompanion(
        isArchived: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Update book statistics
  Future<void> updateBookStatistics({
    required String bookId,
    required int transactionCount,
    required int survivalBalance,
    required int soulBalance,
  }) async {
    await (update(books)..where((b) => b.id.equals(bookId))).write(
      BooksCompanion(
        transactionCount: Value(transactionCount),
        survivalBalance: Value(survivalBalance),
        soulBalance: Value(soulBalance),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Convert domain Book to BookEntity
  BookEntity _toEntity(domain.Book book) {
    return BookEntity(
      id: book.id,
      name: book.name,
      currency: book.currency,
      deviceId: book.deviceId,
      createdAt: book.createdAt,
      updatedAt: book.updatedAt,
      isArchived: book.isArchived,
      transactionCount: book.transactionCount,
      survivalBalance: book.survivalBalance,
      soulBalance: book.soulBalance,
    );
  }

  /// Convert BookEntity to domain Book
  domain.Book _toDomain(BookEntity entity) {
    return domain.Book(
      id: entity.id,
      name: entity.name,
      currency: entity.currency,
      deviceId: entity.deviceId,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      isArchived: entity.isArchived,
      transactionCount: entity.transactionCount,
      survivalBalance: entity.survivalBalance,
      soulBalance: entity.soulBalance,
    );
  }
}
