import 'package:drift/drift.dart';

import '../app_database.dart';

/// Data access object for the Merchants + MerchantMatchKeys tables.
///
/// Plain class taking [AppDatabase] (NOT `@DriftAccessor` — recent DAOs are
/// plain wrappers; RESEARCH #5). Provides the `findAll` count-guard surface
/// and a single-transaction batch seed.
///
/// Inserts are built via Drift companions with `InsertMode.insertOrIgnore` —
/// parameterized, never string-interpolated raw SQL (T-49-02 SQL-injection
/// mitigation). Stable string PKs make re-seed idempotent (T-49-IDEM).
class MerchantDao {
  MerchantDao(this._db);

  final AppDatabase _db;

  /// Return all merchant rows, unfiltered.
  ///
  /// Drives the seed count-guard (empty → seed runs).
  Future<List<MerchantRow>> findAllMerchantRows() async {
    return _db.select(_db.merchants).get();
  }

  /// Return all match-key rows, unfiltered.
  Future<List<MerchantMatchKeyRow>> findAllMatchKeyRows() async {
    return _db.select(_db.merchantMatchKeys).get();
  }

  /// Return the match-key rows for [merchantId].
  Future<List<MerchantMatchKeyRow>> findMatchKeysFor(String merchantId) async {
    return (_db.select(_db.merchantMatchKeys)
          ..where((t) => t.merchantId.equals(merchantId)))
        .get();
  }

  /// Return the merchant row with [id], or null if not found.
  Future<MerchantRow?> findById(String id) async {
    return (_db.select(_db.merchants)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Insert all [merchants] and [keys] in ONE transaction with
  /// `INSERT OR IGNORE` semantics.
  ///
  /// Re-running with the same PKs is a no-op (idempotent re-seed). Companions
  /// are parameterized — no string interpolation.
  Future<void> insertSeed(
    List<MerchantsCompanion> merchants,
    List<MerchantMatchKeysCompanion> keys,
  ) async {
    await _db.transaction(() async {
      await _db.batch((batch) {
        batch.insertAll(
          _db.merchants,
          merchants,
          mode: InsertMode.insertOrIgnore,
        );
        batch.insertAll(
          _db.merchantMatchKeys,
          keys,
          mode: InsertMode.insertOrIgnore,
        );
      });
    });
  }
}
