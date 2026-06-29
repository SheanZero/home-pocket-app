import '../../features/settings/domain/models/app_settings.dart';
import '../../features/accounting/domain/repositories/book_repository.dart';
import '../../features/accounting/domain/repositories/category_repository.dart';
import '../../features/accounting/domain/repositories/transaction_repository.dart';
import '../../features/profile/domain/repositories/user_profile_repository.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../shared/utils/result.dart';

/// Deletes all user data and resets settings to defaults.
class ClearAllDataUseCase {
  ClearAllDataUseCase({
    required TransactionRepository transactionRepo,
    required CategoryRepository categoryRepo,
    required BookRepository bookRepo,
    required SettingsRepository settingsRepo,
    required UserProfileRepository userProfileRepo,
  }) : _transactionRepo = transactionRepo,
       _categoryRepo = categoryRepo,
       _bookRepo = bookRepo,
       _settingsRepo = settingsRepo,
       _userProfileRepo = userProfileRepo;

  final TransactionRepository _transactionRepo;
  final CategoryRepository _categoryRepo;
  final BookRepository _bookRepo;
  final SettingsRepository _settingsRepo;
  final UserProfileRepository _userProfileRepo;

  Future<Result<void>> execute() async {
    try {
      // Delete all transactions for all books
      final books = await _bookRepo.findAll(
        includeArchived: true,
        includeShadow: true,
      );
      for (final book in books) {
        await _transactionRepo.deleteAllByBook(book.id);
      }

      // Delete all categories and books
      await _categoryRepo.deleteAll();
      await _bookRepo.deleteAll();

      // Reset settings to defaults — onboardingComplete returns to false so a
      // wipe behaves like a fresh install and re-triggers onboarding (D-05).
      await _settingsRepo.updateSettings(const AppSettings());

      // Wipe identity (D-05): delete the UserProfile so nickname/avatar do not
      // survive "delete all data" — re-onboarding rebuilds them from blank
      // (mitigates T-54-05 identity-disclosure-after-wipe).
      final profile = await _userProfileRepo.find();
      if (profile != null) {
        await _userProfileRepo.delete(profile.id);
      }

      return Result.success(null);
    } catch (e) {
      return Result.error('Failed to clear data: $e');
    }
  }
}
