import 'package:ulid/ulid.dart';

import '../../features/accounting/domain/models/book.dart';
import '../../features/accounting/domain/repositories/book_repository.dart';
import '../../features/accounting/domain/repositories/transaction_repository.dart';

/// Manages remote-member shadow books and their synced data lifecycle.
class ShadowBookService {
  ShadowBookService({
    required BookRepository bookRepository,
    required TransactionRepository transactionRepository,
  }) : _bookRepository = bookRepository,
       _transactionRepository = transactionRepository;

  final BookRepository _bookRepository;
  final TransactionRepository _transactionRepository;

  Future<String> createShadowBook({
    required String groupId,
    required String memberDeviceId,
    required String memberDeviceName,
    String? currency,
  }) async {
    final existing = await _bookRepository.findShadowBookByDeviceId(
      memberDeviceId,
    );
    if (existing != null) {
      return existing.id;
    }

    final shadowBook = Book(
      id: Ulid().toString(),
      name: '$memberDeviceName Records',
      currency: currency ?? await _resolveShadowCurrency(),
      deviceId: memberDeviceId,
      createdAt: DateTime.now(),
      isShadow: true,
      groupId: groupId,
      ownerDeviceId: memberDeviceId,
      ownerDeviceName: memberDeviceName,
    );
    await _bookRepository.insert(shadowBook);
    return shadowBook.id;
  }

  Future<Book?> findShadowBook(String memberDeviceId) {
    return _bookRepository.findShadowBookByDeviceId(memberDeviceId);
  }

  Future<void> cleanSyncData(String groupId) async {
    final shadowBooks = await _bookRepository.findShadowBooksByGroupId(groupId);
    for (final book in shadowBooks) {
      await _transactionRepository.deleteAllByBook(book.id);
      await _bookRepository.delete(book.id);
    }
  }

  Future<String> _resolveShadowCurrency() async {
    final books = await _bookRepository.findAll();
    if (books.isNotEmpty) {
      return books.first.currency;
    }
    return 'JPY';
  }
}
