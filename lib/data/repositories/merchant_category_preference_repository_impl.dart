import '../../features/accounting/domain/models/merchant_category_preference.dart';
import '../../features/accounting/domain/repositories/merchant_category_preference_repository.dart';
import '../app_database.dart';
import '../daos/merchant_category_preference_dao.dart';

class MerchantCategoryPreferenceRepositoryImpl
    implements MerchantCategoryPreferenceRepository {
  MerchantCategoryPreferenceRepositoryImpl({
    required MerchantCategoryPreferenceDao dao,
  }) : _dao = dao;

  final MerchantCategoryPreferenceDao _dao;

  @override
  Future<MerchantCategoryPreference?> findByMerchantKey(
    String merchantKey,
  ) async {
    final row = await _dao.findByMerchantKey(merchantKey);
    if (row == null) return null;
    return _toModel(row);
  }

  @override
  Future<void> upsert(MerchantCategoryPreference preference) async {
    await _dao.upsert(
      merchantKey: preference.merchantKey,
      preferredCategoryId: preference.preferredCategoryId,
      lastOverrideCategoryId: preference.lastOverrideCategoryId,
      overrideStreak: preference.overrideStreak,
      updatedAt: preference.updatedAt,
    );
  }

  @override
  Future<void> recordSelection({
    required String merchantKey,
    required String selectedCategoryId,
  }) async {
    final now = DateTime.now();
    final existing = await findByMerchantKey(merchantKey);

    if (existing == null) {
      await upsert(
        MerchantCategoryPreference(
          merchantKey: merchantKey,
          preferredCategoryId: selectedCategoryId,
          lastOverrideCategoryId: null,
          overrideStreak: 0,
          updatedAt: now,
        ),
      );
      return;
    }

    if (selectedCategoryId == existing.preferredCategoryId) {
      await upsert(
        existing.copyWith(
          clearLastOverrideCategoryId: true,
          overrideStreak: 0,
          updatedAt: now,
        ),
      );
      return;
    }

    final streak = existing.lastOverrideCategoryId == selectedCategoryId
        ? existing.overrideStreak + 1
        : 1;

    if (streak >= 2) {
      await upsert(
        existing.copyWith(
          preferredCategoryId: selectedCategoryId,
          clearLastOverrideCategoryId: true,
          overrideStreak: 0,
          updatedAt: now,
        ),
      );
      return;
    }

    await upsert(
      existing.copyWith(
        lastOverrideCategoryId: selectedCategoryId,
        overrideStreak: streak,
        updatedAt: now,
      ),
    );
  }

  @override
  Future<String?> suggestCategoryId(String merchantKey) async {
    final pref = await findByMerchantKey(merchantKey);
    return pref?.preferredCategoryId;
  }

  MerchantCategoryPreference _toModel(MerchantCategoryPreferenceRow row) {
    return MerchantCategoryPreference(
      merchantKey: row.merchantKey,
      preferredCategoryId: row.preferredCategoryId,
      lastOverrideCategoryId: row.lastOverrideCategoryId,
      overrideStreak: row.overrideStreak,
      updatedAt: row.updatedAt,
    );
  }
}
