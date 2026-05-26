import '../models/category_keyword_preference.dart';

/// Repository interface for keyword→category learning data.
abstract class CategoryKeywordPreferenceRepository {
  /// Find all learned mappings for a given keyword.
  Future<List<CategoryKeywordPreference>> findByKeyword(String keyword);

  /// Record a user correction: keyword was mapped to categoryId.
  /// Increments hitCount if mapping already exists.
  Future<void> recordCorrection({
    required String keyword,
    required String categoryId,
  });

  /// Phase 21 D-01: batch insert seed rows with `hitCount=0` sentinel using
  /// `INSERT OR IGNORE` semantics — preserves user-corrected rows. Idempotent.
  ///
  /// The seed model values for `hitCount`/`lastUsed` are documentary only —
  /// the underlying DAO writes `hitCount=0` and a fixed epoch regardless.
  Future<void> insertSeedBatch(List<CategoryKeywordPreference> seeds);

  /// Quick task 260526-l0o (Issue 2): fetch all curated seed rows
  /// (hitCount = 0) for the resolver's substring fallback. Returns models
  /// in DAO order — the resolver applies its own length + containment filter.
  Future<List<CategoryKeywordPreference>> findAllSeedRows();

  /// Quick task 260526-pg6 (Option F — Task 3): fetch learned rows whose
  /// hitCount has reached at least [minHitCount]. Used by
  /// [VoiceCategoryResolver]'s step 2.5 substring fallback so user-validated
  /// phrases (e.g. "新干线" at hitCount=3) join seed rows in substring
  /// matching. Ordered by hitCount DESC, lastUsed DESC.
  Future<List<CategoryKeywordPreference>> findLearnedRowsAtOrAbove(
    int minHitCount,
  );

  /// Quick task 260526-pg6 (Option F — Task 4): dev/ops CLI surface. Returns
  /// top-[limit] learned rows (hitCount >= 1) for inspection. Excludes seeds.
  Future<List<CategoryKeywordPreference>> findTopLearned({int limit = 20});

  /// Suggest the best category for a keyword based on learning data.
  /// Returns null if no learned mapping exists.
  Future<CategoryKeywordPreference?> suggestForKeyword(String keyword);

  /// Decay stale preferences older than [staleDuration].
  Future<void> decayStalePreferences(Duration staleDuration);
}
