import '../../features/accounting/domain/models/category_keyword_preference.dart';
import 'synonyms/synonyms_admin.dart';
import 'synonyms/synonyms_daily_living.dart';
import 'synonyms/synonyms_health_education_hobbies.dart';
import 'synonyms/synonyms_support.dart';

export 'synonyms/synonyms_support.dart' show kVoiceSynonymSeedEpoch;

/// System default voice synonyms — seed source for VOICE-04 / VOICE-06.
///
/// Phase 21 D-01: seed rows are written into the existing
/// `category_keyword_preferences` Drift table with `hitCount = 0` (sentinel
/// distinguishing seed-source rows from user-learned ones). The same table
/// participates in P2P sync and incremental learning; seed and learned rows
/// share a single lookup surface.
///
/// Phase 21 Claude's-Discretion option (a): Dart-literal seed source (not
/// YAML) per 21-PATTERNS.md §2. Adding a new keyword/categoryId pair is
/// sufficient to extend the synonym dictionary — no resolver code change is
/// required (VOICE-06 extensibility contract).
///
/// Phase 50 D-04 (DECOUP-02): EXPANDED to FULL L2 coverage. Per the user
/// scope decision (continuation of plan 50-02), the seed now covers EVERY
/// level-2 category — including the previously-excluded admin families
/// (`*_other` fallback buckets, `cat_tax_*`, `cat_asset_*`, `cat_insurance_*`,
/// `*_insurance`, `*_tax`, `cat_special_*`) per RESEARCH A4 "err toward
/// including admin buckets". Every L2 (~138 ids) carries at least one zh
/// DIRECT seed AND at least one ja DIRECT seed. Set-completeness over the
/// FULL L2 set is machine-proven by
/// `default_synonyms_speakable_coverage_test.dart`; every categoryId is gated
/// against the real-L2 / L1-with-child legal set by
/// `default_synonyms_categoryid_test.dart`.
///
/// File split (project "many small files" rule, 800-line max): the seed lists
/// live in `synonyms/synonyms_*.dart` group files (daily-living / health-
/// education-hobbies / admin), each built via the shared [seed] factory in
/// `synonyms/synonyms_support.dart`. This class merely aggregates them.
///
/// Direct-seed rule (set-completeness): each L2 needs a seed whose
/// `categoryId` is that EXACT L2 id. An L1 seed (e.g. `食事`->`cat_food`) only
/// routes to that L1's `_other` bucket via the resolver's `_ensureL2`, never
/// to an arbitrary sibling L2 — so L1 catch-alls do NOT satisfy coverage.
///
/// English (en) seeds — ADDED per VEN-01 (Phase 52 D-12). Every L2 that
/// carries a zh and/or ja DIRECT seed now ALSO carries ≥1 lowercase English
/// keyword (e.g. `coffee`->`cat_food_cafe`, `rent`->`cat_housing_rent`). They
/// are authored LOWERCASE on purpose: the 52-01 en-residual lowercasing fix
/// (`_extractKeyword` in `parse_voice_input_use_case.dart`) lowercases the
/// extracted en keyword, and `findByKeyword` is an exact (case-sensitive)
/// lookup — so a capitalized iOS STT keyword ("Coffee") only matches a
/// lowercase seed. This write==read identity contract MUST be preserved: do
/// NOT add Capitalized en seed rows. (Earlier note deferred en to v1.4+; that
/// deferral is reversed — English voice input is in scope as of v1.9 / VEN-01.)
abstract final class DefaultVoiceSynonyms {
  /// All built-in voice synonym seeds (zh + ja + en).
  static List<CategoryKeywordPreference> get all => _all;

  static final List<CategoryKeywordPreference> _all = [
    ...kSynonymsDailyLiving,
    ...kSynonymsHealthEducationHobbies,
    ...kSynonymsAdmin,
  ];
}
