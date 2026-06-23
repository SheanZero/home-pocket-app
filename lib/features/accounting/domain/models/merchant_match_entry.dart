import 'package:freezed_annotation/freezed_annotation.dart';

part 'merchant_match_entry.freezed.dart';

/// Flat join row — one per match-key surface form — that the recognizer scores
/// over (Plan 50-01, research A5: load-all-in-memory beats per-call DB query
/// for the ~391-row table).
///
/// `MerchantRepository.loadAllForMatching()` returns one entry per
/// `merchant_match_keys` row, each carrying its parent merchant's
/// [categoryId]/[ledgerHint]/[displayName] denormalized inline so the in-memory
/// scorer needs no further joins. [matchKey] is the seed-normalized lookup
/// value; [surface] is the original (pre-normalize) form kept for diagnostics.
///
/// Pure domain value object: imports only `freezed_annotation`, never any
/// application/data/infrastructure file (Thin Feature Rule).
@freezed
abstract class MerchantMatchEntry with _$MerchantMatchEntry {
  const factory MerchantMatchEntry({
    required String matchKey,
    required String surface,
    required String merchantId,
    required String displayName,
    required String categoryId,
    required String ledgerHint,
  }) = _MerchantMatchEntry;
}
