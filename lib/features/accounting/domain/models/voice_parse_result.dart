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
