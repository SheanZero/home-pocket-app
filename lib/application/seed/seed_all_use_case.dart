import '../accounting/seed_categories_use_case.dart';
import '../accounting/seed_voice_synonyms_use_case.dart';
import '../../shared/utils/result.dart';

/// Orchestrates seed use cases in the correct order per Phase 23 D-14.
///
/// This wrapper composes [SeedCategoriesUseCase] and [SeedVoiceSynonymsUseCase]
/// with enforced ordering — categories MUST be seeded before voice synonyms,
/// because synonym rows reference category ids that must already exist.
///
/// **Pitfall 8 (RESEARCH):** The leaf use cases remain publicly accessible.
/// This wrapper composes them; it does NOT replace them. Existing corpus tests
/// that call the leaf providers directly continue to work unchanged.
///
/// The ordering contract is encoded structurally here and verified by a unit
/// test (`seed_all_use_case_test.dart`, Phase 23 D-14) — no longer reliant on
/// a comment in `main.dart`.
class SeedAllUseCase {
  SeedAllUseCase({
    required SeedCategoriesUseCase seedCategories,
    required SeedVoiceSynonymsUseCase seedVoiceSynonyms,
  }) : _seedCategories = seedCategories,
       _seedVoiceSynonyms = seedVoiceSynonyms;

  final SeedCategoriesUseCase _seedCategories;
  final SeedVoiceSynonymsUseCase _seedVoiceSynonyms;

  /// Seeds categories then voice synonyms, in that order.
  ///
  /// Short-circuits on categories failure — if categories seeding fails,
  /// synonyms are NOT invoked (their category-id references would be broken).
  Future<Result<void>> execute() async {
    final categoriesResult = await _seedCategories.execute();
    if (!categoriesResult.isSuccess) return categoriesResult;
    return _seedVoiceSynonyms.execute();
  }
}
