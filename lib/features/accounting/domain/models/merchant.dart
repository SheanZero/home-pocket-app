import 'package:freezed_annotation/freezed_annotation.dart';

part 'merchant.freezed.dart';
part 'merchant.g.dart';

/// One normalized surface form that maps back to a [Merchant].
///
/// A merchant has many match keys — its display name plus aliases and
/// per-locale forms. `matchKey` is the seed-normalized lookup value the
/// recognizer (Phase 50+) queries; `surface` is the original (pre-normalize)
/// form kept for display/diagnostics; `kind` is the provenance
/// (`name` | `alias` | `locale`).
@freezed
abstract class MerchantMatchKey with _$MerchantMatchKey {
  const factory MerchantMatchKey({
    required String surface,
    required String matchKey,
    required String kind,
  }) = _MerchantMatchKey;

  factory MerchantMatchKey.fromJson(Map<String, dynamic> json) =>
      _$MerchantMatchKeyFromJson(json);
}

/// Domain model for a curated merchant (Japan spine, v1.9).
///
/// The boundary type the repository maps `MerchantRow` + its
/// `MerchantMatchKeyRow`s to and from. The seed (Plan 05) builds [Merchant]
/// instances and calls `insertBatch`; readers (Phase 50+) consume them.
///
/// Merchant proper-nouns are DATA (multi-locale fields), NOT ARB keys
/// (MERCH-05, D-01). `ledgerHint` is a stored NON-authoritative hint (D-09) —
/// the authoritative ledger type is derived from the final category.
@freezed
abstract class Merchant with _$Merchant {
  const factory Merchant({
    /// Stable string id (e.g. "mer_seven_eleven") — drives idempotent re-seed.
    required String id,

    /// Japanese display name (required — ja is the default locale).
    required String nameJa,

    /// Chinese display name (nullable — falls back to nameJa at render time).
    String? nameZh,

    /// English display name (nullable — falls back to nameJa at render time).
    String? nameEn,

    /// Region code (default 'JP' at the data layer).
    required String region,

    /// Real L2 category id (e.g. "cat_food_convenience_store").
    required String categoryId,

    /// Seed-derived ledger hint ('daily' | 'joy') — non-authoritative (D-09).
    required String ledgerHint,

    /// Expanded surface forms (name + aliases + per-locale) for this merchant.
    @Default(<MerchantMatchKey>[]) List<MerchantMatchKey> surfaces,
  }) = _Merchant;

  factory Merchant.fromJson(Map<String, dynamic> json) =>
      _$MerchantFromJson(json);
}
