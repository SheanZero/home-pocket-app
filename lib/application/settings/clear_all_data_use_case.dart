import '../../features/settings/domain/models/app_settings.dart';
import '../../features/accounting/domain/repositories/book_repository.dart';
import '../../features/accounting/domain/repositories/category_repository.dart';
import '../../features/accounting/domain/repositories/transaction_repository.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../shared/utils/result.dart';

/// Deletes all user data and resets settings to defaults.
class ClearAllDataUseCase {
  ClearAllDataUseCase({
    required TransactionRepository transactionRepo,
    required CategoryRepository categoryRepo,
    required BookRepository bookRepo,
    required SettingsRepository settingsRepo,
  }) : _transactionRepo = transactionRepo,
       _categoryRepo = categoryRepo,
       _bookRepo = bookRepo,
       _settingsRepo = settingsRepo;

  final TransactionRepository _transactionRepo;
  final CategoryRepository _categoryRepo;
  final BookRepository _bookRepo;
  final SettingsRepository _settingsRepo;

  Future<Result<void>> execute() async {
    try {
      // Delete all transactions for all books
      final books = await _bookRepo.findAll(includeArchived: true);
      for (final book in books) {
        await _transactionRepo.deleteAllByBook(book.id);
      }

      // Delete all categories and books
      await _categoryRepo.deleteAll();
      await _bookRepo.deleteAll();

      // Reset settings to defaults
      await _settingsRepo.updateSettings(const AppSettings());

      return Result.success(null);
    } catch (e) {
      return Result.error('Failed to clear data: $e');
    }
  }
}
