import 'package:drift/drift.dart';

import '../app_database.dart';

class MerchantCategoryPreferenceDao {
  MerchantCategoryPreferenceDao(this._db);

  final AppDatabase _db;

  Future<MerchantCategoryPreferenceRow?> findByMerchantKey(
    String merchantKey,
  ) async {
    return (_db.select(
      _db.merchantCategoryPreferences,
    )..where((t) => t.merchantKey.equals(merchantKey))).getSingleOrNull();
  }

  Future<void> upsert({
    required String merchantKey,
    required String preferredCategoryId,
    String? lastOverrideCategoryId,
    required int overrideStreak,
    required DateTime updatedAt,
  }) async {
    await _db
        .into(_db.merchantCategoryPreferences)
        .insertOnConflictUpdate(
          MerchantCategoryPreferencesCompanion.insert(
            merchantKey: merchantKey,
            preferredCategoryId: preferredCategoryId,
            lastOverrideCategoryId: Value(lastOverrideCategoryId),
            overrideStreak: Value(overrideStreak),
            updatedAt: updatedAt,
          ),
        );
  }

  Future<void> deleteAll() => _db.delete(_db.merchantCategoryPreferences).go();
}
