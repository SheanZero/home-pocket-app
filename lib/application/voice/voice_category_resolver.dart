/// Voice category resolver — short-circuit pipeline that always returns an L2 categoryId.
///
/// Per Phase 21 CONTEXT D-07 + D-03 + D-08 + D-09:
///   1. MerchantDatabase
///   2. category_keyword_preferences (seed `hitCount=0` + learned, DAO orders hitCount DESC, lastUsed DESC)
///   3. L1 → `${l1Id}_other` fallback (D-03; with cat_other_expense → cat_other_other override)
///   4. miss → null
///
/// Replaces the pre-Phase-21 multi-signal matcher (Plan 05 — D-06 dropped the
/// hardcoded seed map and D-08 dropped edit-distance scoring).
library;

import '../../features/accounting/domain/models/transaction.dart';
import '../../features/accounting/domain/models/voice_parse_result.dart';
import '../../features/accounting/domain/repositories/category_keyword_preference_repository.dart';
import '../../features/accounting/domain/repositories/category_repository.dart';
import '../../infrastructure/ml/merchant_database.dart';
import '../accounting/category_service.dart';

/// L1 ids whose `_other` L2 child does NOT follow the `${l1Id}_other` convention.
/// Mirrors test/architecture/category_other_l2_invariant_test.dart::_otherIdOverrides
/// (Phase 21 D-03 + PATTERNS.md §7 caveat). When adding entries here, update
/// the architecture test allowlist atomically.
const Map<String, String> _otherIdOverrides = {
  'cat_other_expense': 'cat_other_other',
};

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

  /// Resolve voice input to an L2 [CategoryMatchResult] via the D-07
  /// short-circuit pipeline. Returns null when neither step produces a hit.
  ///
  /// Pipeline order is STRICT — a hit in step 1 short-circuits step 2.
  /// Both steps route their resolved categoryId through [_ensureL2], so
  /// the public surface always returns an L2 id (D-03 always-L2 contract).
  Future<CategoryMatchResult?> resolve(
    String inputText,
    String extractedKeyword,
  ) async {
    if (extractedKeyword.isEmpty && inputText.isEmpty) return null;

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

    // Step 3 (miss): no match — the screen surfaces a manual-pick affordance.
    return null;
  }

  /// Resolve [categoryId] (L1 or L2) to a concrete L2 id.
  ///
  /// Returns the input unchanged when it is already L2. For an L1 input,
  /// synthesizes `${l1Id}_other` (with the [_otherIdOverrides] aliasing) and
  /// validates it via [CategoryRepository.findById]; if missing, falls back
  /// to the first L2 child by `sortOrder` (D-03 safety net).
  Future<String?> _ensureL2(String categoryId) async {
    final cat = await _categoryRepository.findById(categoryId);
    if (cat == null) return null;
    if (cat.level == 2) return cat.id;

    // L1 case — synthesize the conventional `_other` id, honoring overrides.
    final otherId = _otherIdOverrides[cat.id] ?? '${cat.id}_other';
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
