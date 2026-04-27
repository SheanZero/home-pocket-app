import '../../infrastructure/ml/merchant_database.dart';

/// Application-layer use case wrapping [MerchantDatabase.findMerchant] for
/// screens that need merchant lookup without importing infrastructure/ directly.
///
/// Constructor-injection pattern per PATTERNS.md §2/§3 and CLAUDE.md conventions.
class LookupMerchantUseCase {
  LookupMerchantUseCase({required MerchantDatabase database})
    : _database = database;

  final MerchantDatabase _database;

  /// Look up a merchant by [text] (name, alias, or substring).
  ///
  /// Returns [MerchantMatch] if found, [null] on no match or error.
  /// Graceful failure (null instead of throw) follows the project's
  /// use-case error-handling convention.
  Future<MerchantMatch?> execute(String text) async {
    try {
      return _database.findMerchant(text);
    } catch (_) {
      return null;
    }
  }
}
