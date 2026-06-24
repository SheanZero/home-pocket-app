import 'package:freezed_annotation/freezed_annotation.dart';

import 'voice_parse_result.dart';

part 'recognition_outcome.freezed.dart';

/// Confidence band assigned by [RecognitionReconciler] (D-10).
///
/// Computed in Phase 51 (here, in the voice domain), NOT in Phase 52. The
/// reconciler maps the none/weak/strong 3×3 truth-table cell to one of three
/// bands per RESEARCH §XVAL-01:
///   - [strong]  — user-validated keyword (learning), or an exact-L2-agreement
///                 boost between a strong keyword/merchant pair (D-06).
///   - [medium]  — a single corroborated signal (weak keyword alone, or a
///                 merchant-only auto-fill at/above the 0.85 floor).
///   - [weak]    — best-guess fill from a below-floor merchant, or both-none.
enum ConfidenceBand { strong, medium, weak }

/// Ledger-free reconciliation contract (D-09).
///
/// The pure output of [RecognitionReconciler.reconcile]: it carries the chosen
/// category, its confidence band, the ranked alternates (for Phase-52 chips),
/// the verbatim resolved keyword (D-13 learning-key identity contract), and a
/// flag marking that the keyword verdict won over a strong merchant (XVAL-02).
///
/// It deliberately carries NO `ledgerType` field — the ledger is a pure
/// function of [selectedCategoryId], derived by the use case AFTER
/// reconciliation via `resolveLedgerType(selectedCategoryId) ?? daily`. Keeping
/// the outcome ledger-free is what lets the reconciler stay pure/sync with no
/// DB dependency.
@freezed
abstract class RecognitionOutcome with _$RecognitionOutcome {
  const factory RecognitionOutcome({
    /// The reconciled L2 category id. Null ONLY in the both-none cell
    /// (keyword missed and no merchant surfaced) — the form then collects
    /// amount/date only and the user picks the category manually.
    String? selectedCategoryId,

    /// The confidence band for [selectedCategoryId] (D-10).
    required ConfidenceBand band,

    /// Ranked alternate categories for Phase-52 chips: the keyword's category
    /// first (if any), then merchant-derived categories in recognizer rank
    /// order, de-duplicated by L2 id.
    @Default(<CategoryMatchResult>[]) List<CategoryMatchResult> alternates,

    /// D-13: the canonical keyword string threaded verbatim from the keyword
    /// verdict (260526-pg6 learning-key identity contract — write-key ==
    /// read-key). Null when no keyword was extracted.
    String? resolvedKeyword,

    /// True when the keyword verdict won over a strong (>=0.85) merchant whose
    /// L2 differs — i.e. XVAL-02 「在星巴克买杯子」→购物 (the merchant cafe is
    /// demoted to an alternate). False otherwise.
    @Default(false) bool keywordMerchantConflict,
  }) = _RecognitionOutcome;
}
