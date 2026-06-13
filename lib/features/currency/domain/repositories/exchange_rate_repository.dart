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

  /// Return the most-recent cached rate for [currency] where source != 'manual',
  /// or null if no non-manual row exists.
  ///
  /// D-07: API-cached rows take priority over manual-override rows in the
  /// offline fallback path.
  Future<ExchangeRate?> findLatestNonManual(String currency);

  /// Return the most-recent cached rate for [currency] where source ==
  /// 'manual', or null if no manual row exists.
  ///
  /// WR-03: the offline fallback's manual branch queries this directly instead
  /// of inferring "is the newest row manual?" from [findLatest].
  Future<ExchangeRate?> findLatestManual(String currency);

  /// Delete all rows where rateDate is strictly before [cutoff].
  ///
  /// D-09: called on every upsert to enforce the 2-year TTL.
  Future<void> deleteOlderThan(DateTime cutoff);

  /// Return all cached rate rows, unfiltered.
  ///
  /// D-10: used by the backup export to serialize the full rate cache.
  Future<List<ExchangeRate>> findAll();
}
