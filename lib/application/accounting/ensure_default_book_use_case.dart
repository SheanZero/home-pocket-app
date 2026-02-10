import 'package:ulid/ulid.dart';

import '../../features/accounting/domain/models/book.dart';
import '../../features/accounting/domain/repositories/book_repository.dart';
import '../../features/accounting/domain/repositories/device_identity_repository.dart';
import '../../shared/utils/result.dart';

/// Ensures a default book exists.
///
/// Returns the existing book if one is found, otherwise creates
/// a default "My Book" with JPY currency.
class EnsureDefaultBookUseCase {
  EnsureDefaultBookUseCase({
    required BookRepository bookRepository,
    required DeviceIdentityRepository deviceIdentityRepository,
  }) : _bookRepo = bookRepository,
       _deviceIdentityRepo = deviceIdentityRepository;

  final BookRepository _bookRepo;
  final DeviceIdentityRepository _deviceIdentityRepo;

  Future<Result<Book>> execute() async {
    final books = await _bookRepo.findAll();
    if (books.isNotEmpty) {
      return Result.success(books.first);
    }

    final deviceId = await _deviceIdentityRepo.getDeviceId();
    if (deviceId == null || deviceId.isEmpty) {
      return Result.error('deviceId is not available');
    }

    final book = Book(
      id: Ulid().toString(),
      name: 'My Book',
      currency: 'JPY',
      deviceId: deviceId,
      createdAt: DateTime.now(),
    );

    await _bookRepo.insert(book);
    return Result.success(book);
  }
}
