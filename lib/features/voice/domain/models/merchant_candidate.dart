import 'package:freezed_annotation/freezed_annotation.dart';

part 'merchant_candidate.freezed.dart';

/// Scored verdict from `MerchantRecognizer` (DECOUP-03, D-01).
///
/// A recall-first candidate: the recognizer is a thin scorer over pre-normalized
/// match keys and returns this typed verdict for one matched merchant. [score]
/// is a RAW double — there is NO none/weak/strong banding here (banding is
/// Phase 51 per RESEARCH Open Q #2). The reconciler (Phase 51) consumes the raw
/// score and decides the confidence tier.
///
/// [ledgerHint] is a stored NON-authoritative hint (Phase 49 D-09): it rides
/// along on the candidate but the orchestrator NEVER stamps it as the ledger —
/// the authoritative ledger is derived from the final reconciled category.
///
/// Pure domain value object: imports only `freezed_annotation`, never any
/// application/data/infrastructure file (Thin Feature Rule).
@freezed
abstract class MerchantCandidate with _$MerchantCandidate {
  const factory MerchantCandidate({
    required String merchantId,
    required String displayName,

    /// Raw match score — no banding this phase (D-01 / RESEARCH Open Q #2).
    required double score,
    required String categoryId,

    /// Non-authoritative ledger hint (Phase 49 D-09) — never stamped as ledger.
    required String ledgerHint,
  }) = _MerchantCandidate;
}
