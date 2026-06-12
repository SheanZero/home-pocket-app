// No Drift imports. Domain-owned interface — data layer satisfies it via
// ExchangeRateRepositoryImpl in `lib/data/repositories/`.
import '../models/exchange_rate.dart';

/// Abstract repository interface for exchange rate data access.
///
/// Implemented by [ExchangeRateRepositoryImpl] in `lib/data/repositories/`.
/// All method signatures are pure Dart — no Drift or Flutter types (Thin Feature rule).
abstract class ExchangeRateRepository {
  /// Return the rate row for [currency] on [date], or null if not cached.
  Future<ExchangeRate?> findByDate(String currency, DateTime date);

  /// Return the most-recent cached rate for [currency], or null if none exists.
  Future<ExchangeRate?> findLatest(String currency);

  /// Insert or update a rate entry by composite key (currency, rateDate).
  Future<void> upsert(ExchangeRate rate);
}
