import 'package:drift/drift.dart';

/// Merchant match-keys table — the lookup index every merchant reader (Phase 50+)
/// queries. Each row maps one normalized surface form (`matchKey`) back to a
/// merchant. One merchant has many rows (name + aliases + per-locale forms).
///
/// `matchKey` is INDEXED but NON-UNIQUE: two different merchants may legally
/// share a match_key (cross-merchant collisions are expected — RESEARCH #6).
/// Disambiguation happens at read time, not via a UNIQUE constraint.
///
/// NOTE: customIndices is DECORATIVE (v1.6 CR-01 lesson — `customIndices` is not
/// a real Drift API and is not consumed by the migrator). The indexes are
/// created explicitly via AppDatabase._createMerchantIndexes() in BOTH onCreate
/// and the from<22 onUpgrade block. Keep this list and that method in sync.
@DataClassName('MerchantMatchKeyRow')
class MerchantMatchKeys extends Table {
  /// Stable string PK — so a re-seed INSERT OR IGNORE is idempotent.
  TextColumn get id => text()();

  /// FK → merchants.id (raw-SQL reference; no Drift relation generated).
  TextColumn get merchantId =>
      text().customConstraint('NOT NULL REFERENCES merchants(id)')();

  /// Original surface form (display/diagnostic; the form before normalization).
  TextColumn get surface => text()();

  /// Seed-normalized lookup key — INDEXED, NON-UNIQUE. Recognizers query on this.
  TextColumn get matchKey => text()();

  /// One of 'name' | 'alias' | 'locale' — the provenance of this surface form.
  TextColumn get kind => text()();

  @override
  Set<Column> get primaryKey => {id};

  // Index declarations (no @override — CLAUDE.md pitfall #11). NOTE: Drift's
  // migrator does NOT consume this getter; the indexes are created explicitly
  // in AppDatabase._createMerchantIndexes() (onCreate + from<22 onUpgrade).
  // matchKey index is NON-UNIQUE by design (cross-merchant collisions legal).
  // Keep this list and that method in sync.
  List<TableIndex> get customIndices => [
    TableIndex(
      name: 'idx_merchant_match_keys_match_key',
      columns: {#matchKey},
    ),
    TableIndex(
      name: 'idx_merchant_match_keys_merchant',
      columns: {#merchantId},
    ),
  ];
}
