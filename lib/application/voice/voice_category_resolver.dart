/// Voice category resolver — short-circuit pipeline that always returns an L2 categoryId.
///
/// Per Phase 21 CONTEXT D-07 + D-03 + D-08 + D-09. Two lookups + L2
/// normalization (WR-03 doc-fix — the prior "4-stage pipeline" framing was
/// not what the code did; there is no fuzzy stage in this phase):
///   1. MerchantDatabase lookup (extracted keyword → MerchantMatch)
///   2. category_keyword_preferences lookup (extracted keyword → first row by
///      hitCount DESC, lastUsed DESC; seeds carry `hitCount=0`)
/// Each successful lookup is normalized to L2 via `_ensureL2` (D-03 always-L2
/// contract, with `cat_other_expense → cat_other_other` override).
///
/// Short-circuit semantics (WR-02 doc-fix): a SUCCESSFUL step-1 hit
/// short-circuits step 2; a step-1 hit whose categoryId cannot be normalized
/// to L2 (e.g. stale/typo'd merchant entry) DOES fall through to step 2 so
/// the caller still has a chance at a useful result.
///
/// Replaces the pre-Phase-21 multi-signal matcher (Plan 05 — D-06 dropped the
/// hardcoded seed map and D-08 dropped edit-distance scoring).
library;

import '../../features/accounting/domain/models/transaction.dart';
import '../../features/accounting/domain/models/voice_parse_result.dart';
import '../../features/accounting/domain/repositories/category_keyword_preference_repository.dart';
import '../../features/accounting/domain/repositories/category_repository.dart';
import '../../infrastructure/ml/merchant_database.dart';
import '../../shared/constants/category_other_id_overrides.dart';
import '../accounting/category_service.dart';

// _ensureL2 override map lives in lib/shared/constants/category_other_id_overrides.dart per Phase 23 D-12 IN-05

/// Short-circuit voice category resolver.
///
/// Constructed with the four data sources required by the pipeline. Each
/// source is independently mockable — see test/unit/application/voice/
/// voice_category_resolver_test.dart for the VOICE-06 structural verification.
class VoiceCategoryResolver {
  VoiceCategoryResolver({
    required CategoryRepository categoryRepository,
    required CategoryKeywordPreferenceRepository preferenceRepository,
    required CategoryService categoryService,
    required MerchantDatabase merchantDatabase,
  }) : _categoryRepository = categoryRepository,
       _preferenceRepository = preferenceRepository,
       _categoryService = categoryService,
       _merchantDatabase = merchantDatabase;

  final CategoryRepository _categoryRepository;
  final CategoryKeywordPreferenceRepository _preferenceRepository;
  final CategoryService _categoryService;
  final MerchantDatabase _merchantDatabase;

  /// Resolve [extractedKeyword] to an L2 [CategoryMatchResult] via the D-07
  /// short-circuit pipeline. Returns null when neither step produces a hit
  /// (or [extractedKeyword] is empty).
  ///
  /// Pipeline short-circuit semantics: a SUCCESSFUL step-1 hit (merchant
  /// match whose categoryId normalizes cleanly to L2) skips step 2. A
  /// step-1 hit whose categoryId is unresolvable falls through to step 2.
  /// Both steps route their resolved categoryId through [_ensureL2], so the
  /// public surface always returns an L2 id (D-03 always-L2 contract).
  ///
  /// WR-04: prior `inputText` parameter dropped — only `extractedKeyword`
  /// drove lookups. Callers should pass the already-extracted keyword.
  Future<CategoryMatchResult?> resolve(String extractedKeyword) async {
    if (extractedKeyword.isEmpty) return null;

    // Step 1: MerchantDatabase (synchronous lookup).
    final merchantMatch = _merchantDatabase.findMerchant(extractedKeyword);
    if (merchantMatch != null) {
      final l2 = await _ensureL2(merchantMatch.categoryId);
      if (l2 != null) {
        return CategoryMatchResult(
          categoryId: l2,
          confidence: merchantMatch.confidence,
          source: MatchSource.merchant,
        );
      }
      // Unresolvable merchant categoryId — fall through to step 2 rather than
      // hide a usable keyword signal behind a stale merchant entry.
    }

    // Step 2: category_keyword_preferences — DAO orders by hitCount DESC,
    // lastUsed DESC (Plan 02). The first row is the best candidate; isLearned
    // (hitCount >= 2) drives the MatchSource branch.
    final prefs = await _preferenceRepository.findByKeyword(extractedKeyword);
    if (prefs.isNotEmpty) {
      final best = prefs.first;
      final l2 = await _ensureL2(best.categoryId);
      if (l2 != null) {
        final source = best.isLearned
            ? MatchSource.learning
            : MatchSource.keyword;
        return CategoryMatchResult(
          categoryId: l2,
          confidence: (0.85 + best.scoreBonus).clamp(0.0, 1.0),
          source: source,
        );
      }
    }

    // Miss — caller renders a manual-pick affordance.
    return null;
  }

  /// Public entry to the L2-normalization step.
  ///
  /// WR-05: surfaces `_ensureL2` so callers (e.g. `ParseVoiceInputUseCase`'s
  /// merchant branch) can normalize a pre-derived categoryId to L2 without
  /// re-running [MerchantDatabase.findMerchant] against the canonical name.
  /// Returns null when [categoryId] resolves to no category at all, or when
  /// no L2 child can be found via override / convention / first-child safety
  /// net (PATTERNS.md §7).
  Future<String?> normalizeToL2(String categoryId) => _ensureL2(categoryId);

  /// Resolve [categoryId] (L1 or L2) to a concrete L2 id.
  ///
  /// Returns the input unchanged when it is already L2. For an L1 input,
  /// synthesizes `${l1Id}_other` (with the [kCategoryOtherIdOverrides] aliasing) and
  /// validates it via [CategoryRepository.findById]; if missing, falls back
  /// to the first L2 child by `sortOrder` (D-03 safety net).
  Future<String?> _ensureL2(String categoryId) async {
    final cat = await _categoryRepository.findById(categoryId);
    if (cat == null) return null;
    if (cat.level == 2) return cat.id;

    // L1 case — synthesize the conventional `_other` id, honoring overrides.
    final otherId = kCategoryOtherIdOverrides[cat.id] ?? '${cat.id}_other';
    final otherCat = await _categoryRepository.findById(otherId);
    if (otherCat != null && otherCat.level == 2) return otherCat.id;

    // Safety net — first L2 child by sortOrder when the convention fails.
    final children = await _categoryRepository.findByParent(cat.id);
    if (children.isNotEmpty) return children.first.id;
    return null;
  }

  /// Thin pass-through to [CategoryService.resolveLedgerType].
  Future<LedgerType?> resolveLedgerType(String categoryId) =>
      _categoryService.resolveLedgerType(categoryId);
}
