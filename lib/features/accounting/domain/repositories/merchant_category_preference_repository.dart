import '../models/merchant_category_preference.dart';

abstract class MerchantCategoryPreferenceRepository {
  Future<MerchantCategoryPreference?> findByMerchantKey(String merchantKey);
  Future<void> upsert(MerchantCategoryPreference preference);
  Future<void> recordSelection({
    required String merchantKey,
    required String selectedCategoryId,
  });
  Future<String?> suggestCategoryId(String merchantKey);
}
