import 'package:drift/drift.dart';

import '../../shared/constants/default_synonyms.dart' show kVoiceSynonymSeedEpoch;
import '../app_database.dart';

/// Data access object for [CategoryKeywordPreferences] table.
class CategoryKeywordPreferenceDao {
  CategoryKeywordPreferenceDao(this._db);

  final AppDatabase _db;

  /// Find all learned mappings for a keyword.
  ///
  /// Phase 21 D-07 step 2 ordering: `hitCount DESC, lastUsed DESC`.
  /// Seed rows (Phase 21 D-01, `hitCount=0` sentinel) and learned rows
  /// share this lookup surface; the tiebreaker keeps recently-touched seeds
  /// above ancient seeds when hitCount is equal.
  Future<List<CategoryKeywordPreferenceRow>> findByKeyword(
    String keyword,
  ) async {
    return (_db.select(_db.categoryKeywordPreferences)
          ..where((t) => t.keyword.equals(keyword))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.hitCount, mode: OrderingMode.desc),
            (t) =>
                OrderingTerm(expression: t.lastUsed, mode: OrderingMode.desc),
          ]))
        .get();
  }

  /// Find a specific keyword→categoryId mapping.
  Future<CategoryKeywordPreferenceRow?> findByKeywordAndCategory(
    String keyword,
    String categoryId,
  ) async {
    return (_db.select(_db.categoryKeywordPreferences)..where(
          (t) => t.keyword.equals(keyword) & t.categoryId.equals(categoryId),
        ))
        .getSingleOrNull();
  }

  /// Upsert a keyword→category preference.
  ///
  /// If the mapping exists, increments hitCount and updates lastUsed.
  /// If not, inserts with hitCount=1.
  Future<void> upsert({
    required String keyword,
    required String categoryId,
  }) async {
    final existing = await findByKeywordAndCategory(keyword, categoryId);
    final now = DateTime.now();

    if (existing != null) {
      await (_db.update(_db.categoryKeywordPreferences)..where(
            (t) => t.keyword.equals(keyword) & t.categoryId.equals(categoryId),
          ))
          .write(
            CategoryKeywordPreferencesCompanion(
              hitCount: Value(existing.hitCount + 1),
              lastUsed: Value(now),
            ),
          );
    } else {
      await _db
          .into(_db.categoryKeywordPreferences)
          .insert(
            CategoryKeywordPreferencesCompanion.insert(
              keyword: keyword,
              categoryId: categoryId,
              lastUsed: now,
            ),
          );
    }
  }

  /// Phase 21 D-01 — batch insert seed synonyms with `hitCount=0` sentinel.
  ///
  /// Uses `INSERT OR IGNORE` so existing user-corrected rows
  /// (`hitCount >= 1`) are preserved verbatim (Claude's-Discretion option
  /// (a) per Phase 21 CONTEXT). Idempotent on re-invocation.
  ///
  /// Seed rows use the fixed epoch `kVoiceSynonymSeedEpoch` — this is matched
  /// by [kVoiceSynonymSeedEpoch] in `default_synonyms.dart` so audit queries can distinguish
  /// untouched seeds from seeds whose hitCount has been bumped by
  /// `recordCorrection` (which writes `DateTime.now()`).
  Future<void> insertSeedBatch(
    List<({String keyword, String categoryId})> seeds,
  ) async {
    if (seeds.isEmpty) return;
    await _db.batch((b) {
      for (final seed in seeds) {
        b.insert(
          _db.categoryKeywordPreferences,
          CategoryKeywordPreferencesCompanion.insert(
            keyword: seed.keyword,
            categoryId: seed.categoryId,
            hitCount: const Value(0),
            lastUsed: kVoiceSynonymSeedEpoch,
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });
  }

  /// Decay stale preferences: reduce hitCount by 1 for entries not used
  /// within [staleDuration]. Entries that reach hitCount=0 are deleted.
  ///
  /// Phase 21 D-01 sentinel protection — `hitCount=0` rows are seed entries
  /// (from `insertSeedBatch`) and MUST survive decay so the synonym
  /// dictionary stays intact even after long idle periods.
  ///
  /// WR-01: DELETE and UPDATE run inside a single transaction. If the app is
  /// killed between them the table would otherwise be left in a partial state
  /// (hit_count=1 rows deleted but the rest not decremented).
  Future<void> decayStalePreferences(Duration staleDuration) async {
    final cutoff = DateTime.now().subtract(staleDuration);

    await _db.transaction(() async {
      // Delete entries with hitCount = 1 that are stale.
      // Phase 21 D-01: explicitly exclude `hitCount=0` seed sentinel rows.
      await (_db.delete(_db.categoryKeywordPreferences)..where(
            (t) =>
                t.lastUsed.isSmallerThan(Variable(cutoff)) &
                t.hitCount.equals(1),
          ))
          .go();

      // Decrement hitCount for remaining stale entries with hitCount > 1.
      // WR-01: tightened from `> 0` to `> 1` — the prior DELETE removed the
      // hitCount=1 rows, so the UPDATE never needed to touch them.
      // Phase 21 D-01: this also guards the seed sentinel (hitCount=0).
      await _db.customUpdate(
        'UPDATE category_keyword_preferences '
        'SET hit_count = hit_count - 1 '
        'WHERE last_used < ? AND hit_count > 1',
        variables: [Variable(cutoff)],
        updates: {_db.categoryKeywordPreferences},
      );
    });
  }

  /// Delete all preferences (for testing/reset).
  Future<void> deleteAll() => _db.delete(_db.categoryKeywordPreferences).go();
}
