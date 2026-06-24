import '../../../features/accounting/domain/models/category_keyword_preference.dart';

/// Phase 21 D-01 / Phase 23 D-12 IN-01: Fixed epoch used as `lastUsed`
/// sentinel for all voice synonym seed rows. Single source of truth —
/// imported by both [DefaultVoiceSynonyms] and
/// [CategoryKeywordPreferenceDao.insertSeedBatch] so that audit queries
/// filtering on `lastUsed = epoch` see consistent row counts across
/// both write paths.
final DateTime kVoiceSynonymSeedEpoch = DateTime(2026, 1, 1);

/// Shared seed-row factory for the split synonym group files
/// (`synonyms/synonyms_*.dart`). Builds a documentary
/// [CategoryKeywordPreference] carrying the seed values; the downstream DAO
/// writes its own `hitCount=0` and epoch (Phase 21 D-01 sentinel) regardless
/// of what is set here.
CategoryKeywordPreference seed(String keyword, String categoryId) =>
    CategoryKeywordPreference(
      keyword: keyword,
      categoryId: categoryId,
      hitCount: 0,
      lastUsed: kVoiceSynonymSeedEpoch,
    );
