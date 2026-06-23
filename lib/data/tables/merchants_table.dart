import 'package:drift/drift.dart';

/// Merchants table — curated Japan merchant spine (national-chain entries per
/// everyday category). Seeded from a const list in Phase 49 Plan 05; this plan
/// defines schema only (no rows).
///
/// Merchant proper-nouns are DATA (multi-locale Drift columns), NOT ARB keys
/// (per MERCH-05, D-01) — category labels remain ARB, merchant names do not.
///
/// NOTE: customIndices is DECORATIVE (v1.6 CR-01 lesson — `customIndices` is not
/// a real Drift API and is not consumed by the migrator). The indexes are
/// created explicitly via AppDatabase._createMerchantIndexes() in BOTH onCreate
/// and the from<22 onUpgrade block. Keep this list and that method in sync.
@DataClassName('MerchantRow')
class Merchants extends Table {
  /// Stable string PK (e.g. "mer_seven_eleven") — so re-seed INSERT OR IGNORE
  /// is idempotent.
  TextColumn get id => text()();

  /// Japanese display name (required — ja is the default locale).
  TextColumn get nameJa => text()();

  /// Chinese display name (nullable — falls back to nameJa at render time).
  TextColumn get nameZh => text().nullable()();

  /// English display name (nullable — falls back to nameJa at render time).
  TextColumn get nameEn => text().nullable()();

  /// Region code. Companion-layer default 'JP' (per A3) — v1.9 scope is the
  /// Japan spine; schema designed for a regional/depachika tail (MERCH-V2-01).
  TextColumn get region => text().withDefault(const Constant('JP'))();

  /// Real L2 category id (e.g. "cat_food_convenience_store") — references the
  /// category taxonomy by id; validated as a real L2 by the seed integrity test.
  TextColumn get categoryId => text()();

  /// Seed-derived ledger hint ('daily' | 'joy') — a stored NON-authoritative
  /// hint (per D-09). Ledger type is derived from the final category after
  /// reconciliation; this column is a future merchant-specific-ledger affordance.
  TextColumn get ledgerHint => text()();

  @override
  Set<Column> get primaryKey => {id};

  // Index declarations (no @override — CLAUDE.md pitfall #11). NOTE: Drift's
  // migrator does NOT consume this getter; the indexes are created explicitly
  // in AppDatabase._createMerchantIndexes() (onCreate + from<22 onUpgrade).
  // Keep this list and that method in sync.
  List<TableIndex> get customIndices => [
    TableIndex(name: 'idx_merchants_region', columns: {#region}),
    TableIndex(name: 'idx_merchants_category', columns: {#categoryId}),
  ];
}
