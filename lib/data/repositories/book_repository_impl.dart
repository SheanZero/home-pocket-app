import '../../features/accounting/domain/models/book.dart';
import '../../features/accounting/domain/repositories/book_repository.dart';
import '../app_database.dart';
import '../daos/book_dao.dart';

/// Concrete implementation of [BookRepository].
class BookRepositoryImpl implements BookRepository {
  BookRepositoryImpl({required BookDao dao}) : _dao = dao;

  final BookDao _dao;

  @override
  Future<void> insert(Book book) async {
    await _dao.insertBook(
      id: book.id,
      name: book.name,
      currency: book.currency,
      deviceId: book.deviceId,
      createdAt: book.createdAt,
      isArchived: book.isArchived,
      isShadow: book.isShadow,
      groupId: book.groupId,
      ownerDeviceId: book.ownerDeviceId,
      ownerDeviceName: book.ownerDeviceName,
    );
  }

  @override
  Future<Book?> findById(String id) async {
    final row = await _dao.findById(id);
    if (row == null) return null;
    return _toModel(row);
  }

  @override
  Future<Book?> findShadowBookByDeviceId(String ownerDeviceId) async {
    final row = await _dao.findShadowBookByOwnerDeviceId(ownerDeviceId);
    if (row == null) return null;
    return _toModel(row);
  }

  @override
  Future<List<Book>> findShadowBooksByGroupId(String groupId) async {
    final rows = await _dao.findShadowBooksByGroupId(groupId);
    return rows.map(_toModel).toList();
  }

  @override
  Future<List<Book>> findAll({bool includeArchived = false}) async {
    final rows = await _dao.findAll(includeArchived: includeArchived);
    return rows.map(_toModel).toList();
  }

  @override
  Future<void> update(Book book) async {
    await _dao.updateBook(
      id: book.id,
      name: book.name,
      currency: book.currency,
      isArchived: book.isArchived,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> archive(String id) async {
    await _dao.archiveBook(id);
  }

  @override
  Future<void> delete(String id) => _dao.deleteBook(id);

  @override
  Future<void> deleteAll() => _dao.deleteAll();

  @override
  Future<void> updateBalances({
    required String bookId,
    required int transactionCount,
    required int survivalBalance,
    required int soulBalance,
  }) async {
    await _dao.updateBalances(
      bookId: bookId,
      transactionCount: transactionCount,
      survivalBalance: survivalBalance,
      soulBalance: soulBalance,
    );
  }

  Book _toModel(BookRow row) {
    return Book(
      id: row.id,
      name: row.name,
      currency: row.currency,
      deviceId: row.deviceId,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      isArchived: row.isArchived,
      isShadow: row.isShadow,
      groupId: row.groupId,
      ownerDeviceId: row.ownerDeviceId,
      ownerDeviceName: row.ownerDeviceName,
      transactionCount: row.transactionCount,
      survivalBalance: row.survivalBalance,
      soulBalance: row.soulBalance,
    );
  }
}
