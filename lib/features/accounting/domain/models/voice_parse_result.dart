import 'package:freezed_annotation/freezed_annotation.dart';

import 'transaction.dart';

part 'voice_parse_result.freezed.dart';

/// Result of parsing a voice input into structured transaction data.
///
/// Holds all extracted fields as primitives — no infrastructure types.
/// [merchantName], [merchantCategoryId], [merchantLedgerType] store the
/// results of merchant lookup without referencing MerchantMatch directly.
@freezed
abstract class VoiceParseResult with _$VoiceParseResult {
  const factory VoiceParseResult({
    required String rawText,
    int? amount,
    // Parsed date from voice text (null = not mentioned, default to today)
    DateTime? parsedDate,
    // Merchant fields stored as primitives (no MerchantMatch reference)
    String? merchantName,
    String? merchantCategoryId,
    LedgerType? merchantLedgerType,
    // Category keyword match
    CategoryMatchResult? categoryMatch,
    // Resolved ledger type (from merchant or category)
    LedgerType? ledgerType,
    // Quick task 260526-pg6 (Option F — Task 1):
    // Canonical keyword string used internally by the resolver (post-strip:
    // amount/currency suffix stripped, particles stripped per `localeId`).
    // Surfaced here so the form-side write path (`recordCorrection`) can
    // persist the SAME string the resolver will later look up — closing
    // the silent-orphan bug where a divergent re-extractor wrote keys that
    // never matched the resolver's lookup key.
    //
    // Null when no extraction occurred (e.g. caller did not provide enough
    // context, or amount-only utterances). Consumers MUST treat null/empty
    // as "fall back to legacy behavior" — see voice_input_screen_helpers.dart.
    String? resolvedKeyword,
    // Phase 42 (VOICE-CUR-01/02/03): ISO 4217 code of a spoken foreign currency
    // detected in the utterance (e.g. 「五十美元」 → 'USD', 「五十元」 in zh →
    // 'CNY'). Null means JPY-native (「昼ごはんに680円」, bare 円) — no foreign
    // conversion, preserving the pre-Phase-42 default. The shared form reads
    // this to trigger the normal rate-fetch flow; null skips it entirely
    // (Pitfall 1: JPY path must stay byte-identical).
    String? detectedCurrency,
    @Default(5) int estimatedSatisfaction,
  }) = _VoiceParseResult;
}

/// Result of matching a category from voice text keywords.
@freezed
abstract class CategoryMatchResult with _$CategoryMatchResult {
  const factory CategoryMatchResult({
    required String categoryId,
    required double confidence,
    required MatchSource source,
  }) = _CategoryMatchResult;
}

/// How the category match was derived.
enum MatchSource {
  merchant, // matched via MerchantDatabase
  keyword, // matched via keyword map
  learning, // matched via user correction history
  fallback, // default fallback
}

/// Audio features collected during voice recording.
///
/// Used by [VoiceSatisfactionEstimator] to estimate satisfaction score.
@freezed
abstract class VoiceAudioFeatures with _$VoiceAudioFeatures {
  const factory VoiceAudioFeatures({
    required List<double> soundLevels,
    required List<DateTime> timestamps,
    required DateTime startTime,
    required DateTime endTime,
    required int partialResultCount,
    required int wordCount,
  }) = _VoiceAudioFeatures;
}
