import '../../features/accounting/domain/repositories/category_keyword_preference_repository.dart';
import '../../shared/constants/default_synonyms.dart';
import '../../shared/utils/result.dart';

/// Seeds default voice synonyms into `category_keyword_preferences`.
///
/// Phase 21 D-01: seed rows use the `hitCount = 0` sentinel that distinguishes
/// seed entries from user-learned entries (`hitCount >= 1`). The underlying
/// DAO writes seeds with `INSERT OR IGNORE` semantics — Phase 21 Claude's-
/// Discretion option (a) — so user-corrected rows (whose `hitCount` has been
/// bumped by the learning use-case) are NEVER destroyed by a re-seed.
///
/// Called during app initialization AFTER `SeedCategoriesUseCase.execute()`
/// so the categoryIds the seeds reference already exist. Idempotent — once
/// the first probe keyword is present, subsequent invocations short-circuit.
class SeedVoiceSynonymsUseCase {
  SeedVoiceSynonymsUseCase({
    required CategoryKeywordPreferenceRepository preferenceRepository,
  }) : _prefRepo = preferenceRepository;

  final CategoryKeywordPreferenceRepository _prefRepo;

  Future<Result<void>> execute() async {
    // Idempotency probe: if the first seed keyword already has any row,
    // assume seeding has run (mirrors SeedCategoriesUseCase.execute's
    // `existing.isNotEmpty` pattern).
    final probeKeyword = DefaultVoiceSynonyms.all.first.keyword;
    final existing = await _prefRepo.findByKeyword(probeKeyword);
    if (existing.isNotEmpty) {
      return Result.success(null);
    }

    // Batch insert with hitCount=0 sentinel via INSERT OR IGNORE.
    // The incrementing learning surface is NOT used here — it would write
    // hitCount=1, defeating the D-01 sentinel that separates seed rows from
    // learned rows.
    await _prefRepo.insertSeedBatch(DefaultVoiceSynonyms.all);
    return Result.success(null);
  }
}
