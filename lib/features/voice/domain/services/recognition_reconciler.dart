import '../models/merchant_candidate.dart';
import '../models/recognition_outcome.dart';
import '../models/voice_parse_result.dart';

/// Auto-fill floor for the merchant engine (mirrors the canonical
/// `kMerchantAutoFillFloor` in `application/voice/parse_voice_input_use_case.dart`).
/// Re-declared as a domain-local const because the domain layer must NOT import
/// the application layer — the value is the contract, not the import.
const double kMerchantAutoFillFloor = 0.85;

/// Pure domain reconciler (D-09) — merges the keyword verdict and merchant
/// candidates via the explicit none/weak/strong 3×3 truth table (RESEARCH
/// §XVAL-01) into a ledger-free [RecognitionOutcome].
///
/// PURE and SYNC: zero I/O, zero awaits, zero DB lookups, zero logging (V7
/// discipline). The D-06 exact-L2-agreement boost compares two L2 id strings
/// directly (merchant `categoryId`s are L2 seed ids per A3), so no L1→L2
/// resolution is needed here. The ledger is derived by the use case AFTER
/// reconciliation from [RecognitionOutcome.selectedCategoryId].
///
/// Selection contract:
///   - keyword present  → keyword always wins (keyword-priority); band = strong
///     when the keyword is `learning` else medium; D-06 boosts to strong when a
///     merchant at/above the floor agrees on the EXACT L2 id.
///   - keyword absent   → fall back to the best merchant: auto-fill (band=medium)
///     when at/above the floor, best-guess (band=weak, D-05) when below, or null
///     (band=weak) when no merchant surfaced.
class RecognitionReconciler {
  const RecognitionReconciler();

  RecognitionOutcome reconcile(
    CategoryMatchResult? keywordVerdict,
    List<MerchantCandidate> merchantCandidates, {
    String? resolvedKeyword,
  }) {
    final MerchantCandidate? bestMerchant =
        merchantCandidates.isEmpty ? null : merchantCandidates.first;
    final bool merchantStrong =
        bestMerchant != null && bestMerchant.score >= kMerchantAutoFillFloor;

    // ---- keyword present: keyword always wins (keyword-priority) ----
    if (keywordVerdict != null) {
      final bool keywordIsStrong =
          keywordVerdict.source == MatchSource.learning;

      // D-06 exact-L2-agreement boost: a merchant at/above the floor agreeing
      // on the EXACT L2 id earns `strong` (compare ids as strings — both are L2
      // seed ids; no L1→L2 resolution).
      final bool exactAgree =
          merchantStrong &&
          bestMerchant.categoryId == keywordVerdict.categoryId;

      final ConfidenceBand band = (keywordIsStrong || exactAgree)
          ? ConfidenceBand.strong
          : ConfidenceBand.medium;

      // Conflict: the keyword won over a STRONG merchant whose L2 differs
      // (XVAL-02 「在星巴克买杯子」→购物 — the cafe is demoted to an alternate).
      final bool conflict =
          merchantStrong &&
          bestMerchant.categoryId != keywordVerdict.categoryId;

      return RecognitionOutcome(
        selectedCategoryId: keywordVerdict.categoryId,
        band: band,
        alternates: _buildAlternates(
          keywordVerdict.categoryId,
          merchantCandidates,
        ),
        resolvedKeyword: resolvedKeyword,
        keywordMerchantConflict: conflict,
      );
    }

    // ---- keyword absent: fall back to the best merchant ----
    if (bestMerchant == null) {
      // both-none: no category at all.
      return RecognitionOutcome(
        selectedCategoryId: null,
        band: ConfidenceBand.weak,
        resolvedKeyword: resolvedKeyword,
      );
    }

    // merchant at/above floor → auto-fill (medium); below floor → best-guess
    // (weak, D-05). Alternates are the ranked merchants (de-duped by L2 id).
    return RecognitionOutcome(
      selectedCategoryId: bestMerchant.categoryId,
      band: merchantStrong ? ConfidenceBand.medium : ConfidenceBand.weak,
      alternates: _buildAlternates(null, merchantCandidates),
      resolvedKeyword: resolvedKeyword,
    );
  }

  /// Builds the ranked, de-duplicated alternates list: the keyword's category
  /// first (when [selectedCategoryId] is set), then merchant-derived categories
  /// in recognizer rank order, de-duplicated by L2 id (the selected id is also
  /// excluded so it never appears as its own alternate).
  List<CategoryMatchResult> _buildAlternates(
    String? selectedCategoryId,
    List<MerchantCandidate> merchantCandidates,
  ) {
    final List<CategoryMatchResult> alternates = <CategoryMatchResult>[];
    final Set<String> seen = <String>{};
    if (selectedCategoryId != null) {
      seen.add(selectedCategoryId);
    }

    for (final candidate in merchantCandidates) {
      if (seen.contains(candidate.categoryId)) continue;
      seen.add(candidate.categoryId);
      alternates.add(
        CategoryMatchResult(
          categoryId: candidate.categoryId,
          confidence: candidate.score,
          source: MatchSource.merchant,
        ),
      );
    }

    return List<CategoryMatchResult>.unmodifiable(alternates);
  }
}
