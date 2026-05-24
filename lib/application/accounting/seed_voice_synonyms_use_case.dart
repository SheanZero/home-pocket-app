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
/// so the categoryIds the seeds reference already exist. Idempotent — the
/// DAO's `INSERT OR IGNORE` is the SQL-level idempotency guarantee; we trust
/// it unconditionally so the seed step self-heals from any partial-seed state
/// (e.g. decay-deleted rows, or rows missing because an earlier seed run
/// failed mid-batch).
class SeedVoiceSynonymsUseCase {
  SeedVoiceSynonymsUseCase({
    required CategoryKeywordPreferenceRepository preferenceRepository,
  }) : _prefRepo = preferenceRepository;

  final CategoryKeywordPreferenceRepository _prefRepo;

  Future<Result<void>> execute() async {
    // Trust the DAO's INSERT OR IGNORE semantics — it is the SQL-level
    // idempotency guarantee. The probe-then-insert pattern was removed in
    // CR-01 because it short-circuited the entire batch on a single existing
    // row, defeating the self-healing guarantee `INSERT OR IGNORE` provides.
    await _prefRepo.insertSeedBatch(DefaultVoiceSynonyms.all);
    return Result.success(null);
  }
}
