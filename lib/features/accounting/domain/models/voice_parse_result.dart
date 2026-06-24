import 'package:freezed_annotation/freezed_annotation.dart';

import 'merchant_candidate.dart';
import 'transaction.dart';

part 'voice_parse_result.freezed.dart';

/// Result of parsing a voice input into structured transaction data.
///
/// Holds all extracted fields as primitives — no infrastructure types.
/// [merchantName] / [merchantCategoryId] carry the best merchant candidate's
/// descriptive primitives (for form pre-fill). [merchantLedgerType] is retained
/// for backward compatibility but is no longer populated — the ledger is a pure
/// function of the final category (LEDGER-01), never the merchant hint.
/// [merchantCandidates] carries the full ranked list (recall-first).
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
    // Phase 50 (DECOUP-03 / D-01): the full ranked list of merchant candidates
    // the MerchantRecognizer produced for this utterance, recall-first (score
    // DESC). Surfaced regardless of the 0.85 auto-fill floor so Phase-52 chips
    // can offer below-floor candidates as manual picks. Empty when no merchant
    // surface matched (or the utterance had no recognizable merchant token).
    @Default(<MerchantCandidate>[]) List<MerchantCandidate> merchantCandidates,
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
  merchant, // matched via MerchantRecognizer (auto-filled at the 0.85 floor)
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
