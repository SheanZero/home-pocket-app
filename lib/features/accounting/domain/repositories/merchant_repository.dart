import '../models/merchant.dart';
import '../models/merchant_match_entry.dart';

/// Abstract repository interface for merchant data access.
///
/// Phase 49 defines the interface shape only; no consumer is wired (the
/// recognizer cutover is Phase 50). The seed (Plan 05) drives [findAll] as a
/// count guard and [insertBatch] for the one-transaction idempotent insert.
abstract class MerchantRepository {
  /// Return all merchants (each with its expanded surface forms).
  Future<List<Merchant>> findAll();

  /// Cheap existence probe (`SELECT EXISTS`) — true if any merchant row exists.
  ///
  /// Drives the seed count-guard without materializing the merchant object
  /// graph: a true result means seeding is skipped.
  Future<bool> hasAny();

  /// Return the merchant with [id], or null if not found.
  Future<Merchant?> findById(String id);

  /// Insert all [merchants] (and their match keys) in ONE transaction with
  /// INSERT OR IGNORE semantics — re-inserting the same ids is a no-op.
  Future<void> insertBatch(List<Merchant> merchants);

  /// Load every match-key row paired with its merchant's category/ledger hint,
  /// for in-memory recognizer matching (Plan 50-01, DECOUP-03).
  ///
  /// Returns one flat [MerchantMatchEntry] per `merchant_match_keys` row
  /// (~391+ surfaces), each carrying its parent merchant's
  /// categoryId/ledgerHint/displayName denormalized inline. Loaded once
  /// (keepAlive) by the recognizer; per research A5, load-all-in-memory beats
  /// a per-call DB query for the ~391-row table. Joins both tables inside ONE
  /// read transaction for point-in-time consistency (WR-04, mirrors findAll).
  Future<List<MerchantMatchEntry>> loadAllForMatching();
}
