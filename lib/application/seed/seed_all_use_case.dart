import '../accounting/seed_categories_use_case.dart';
import '../accounting/seed_merchants_use_case.dart';
import '../accounting/seed_voice_synonyms_use_case.dart';
import '../../shared/utils/result.dart';

/// Orchestrates seed use cases in the correct order per Phase 23 D-14.
///
/// This wrapper composes [SeedCategoriesUseCase], [SeedMerchantsUseCase], and
/// [SeedVoiceSynonymsUseCase] with enforced ordering — categories MUST be
/// seeded first, because both merchant rows (Phase 49 D-05) and synonym rows
/// reference category ids that must already exist.
///
/// **Pitfall 8 (RESEARCH):** The leaf use cases remain publicly accessible.
/// This wrapper composes them; it does NOT replace them. Existing corpus tests
/// that call the leaf providers directly continue to work unchanged.
///
/// **Phase 49 Pitfall #1:** the merchant seed is wired HERE (the real seed
/// path, reached via `HomePocketApp._initialize()` → `seedAllUseCaseProvider`),
/// NOT into the AppInitializer `seedRunner` no-op.
///
/// The ordering contract is encoded structurally here and verified by a unit
/// test (`seed_all_use_case_test.dart`, Phase 23 D-14 + Phase 49) — no longer
/// reliant on a comment in `main.dart`.
class SeedAllUseCase {
  SeedAllUseCase({
    required SeedCategoriesUseCase seedCategories,
    required SeedVoiceSynonymsUseCase seedVoiceSynonyms,
    required SeedMerchantsUseCase seedMerchants,
  }) : _seedCategories = seedCategories,
       _seedVoiceSynonyms = seedVoiceSynonyms,
       _seedMerchants = seedMerchants;

  final SeedCategoriesUseCase _seedCategories;
  final SeedVoiceSynonymsUseCase _seedVoiceSynonyms;
  final SeedMerchantsUseCase _seedMerchants;

  /// Seeds categories, then merchants, then voice synonyms, in that order.
  ///
  /// Short-circuits on categories failure — if categories seeding fails,
  /// neither merchants nor synonyms are invoked (their category-id references
  /// would be broken). Merchants seed after categories because each merchant's
  /// `categoryId` references a seeded L2 category (Phase 49 D-05).
  Future<Result<void>> execute() async {
    final categoriesResult = await _seedCategories.execute();
    if (!categoriesResult.isSuccess) return categoriesResult;

    final merchantsResult = await _seedMerchants.execute();
    if (!merchantsResult.isSuccess) return merchantsResult;

    return _seedVoiceSynonyms.execute();
  }
}
