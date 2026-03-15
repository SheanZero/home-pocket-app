import 'package:drift/drift.dart';

import '../app_database.dart';

/// Data access object for [CategoryKeywordPreferences] table.
class CategoryKeywordPreferenceDao {
  CategoryKeywordPreferenceDao(this._db);

  final AppDatabase _db;

  /// Find all learned mappings for a keyword.
  Future<List<CategoryKeywordPreferenceRow>> findByKeyword(
    String keyword,
  ) async {
    return (_db.select(_db.categoryKeywordPreferences)
          ..where((t) => t.keyword.equals(keyword))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.hitCount, mode: OrderingMode.desc),
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

  /// Decay stale preferences: reduce hitCount by 1 for entries not used
  /// within [staleDuration]. Entries that reach hitCount=0 are deleted.
  Future<void> decayStalePreferences(Duration staleDuration) async {
    final cutoff = DateTime.now().subtract(staleDuration);

    // Delete entries with hitCount <= 1 that are stale
    await (_db.delete(_db.categoryKeywordPreferences)..where(
          (t) =>
              t.lastUsed.isSmallerThan(Variable(cutoff)) &
              t.hitCount.isSmallerOrEqual(const Variable(1)),
        ))
        .go();

    // Decrement hitCount for remaining stale entries
    await _db.customUpdate(
      'UPDATE category_keyword_preferences '
      'SET hit_count = hit_count - 1 '
      'WHERE last_used < ?',
      variables: [Variable(cutoff)],
      updates: {_db.categoryKeywordPreferences},
    );
  }

  /// Delete all preferences (for testing/reset).
  Future<void> deleteAll() => _db.delete(_db.categoryKeywordPreferences).go();
}
