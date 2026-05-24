import '../../features/accounting/domain/models/transaction.dart';
import '../../features/accounting/domain/models/voice_parse_result.dart';
import '../../infrastructure/ml/merchant_database.dart';
import '../../shared/utils/result.dart';
import 'voice_category_resolver.dart';
import 'voice_text_parser.dart';

/// Use case for parsing voice-recognized text into structured transaction data.
///
/// Orchestrates: text parsing → merchant matching → category matching →
/// ledger type resolution → [VoiceParseResult] construction.
///
/// Merchant matching has higher priority than keyword category matching.
/// Per Phase 21 PATTERNS.md §9 caveat, BOTH the merchant branch and the
/// fallback keyword branch route through [VoiceCategoryResolver.resolve] so
/// the always-L2 contract has no escape hatch — even if MerchantDatabase
/// regresses and yields an L1 id, the resolver's `_ensureL2` re-maps it.
class ParseVoiceInputUseCase {
  final VoiceTextParser _textParser;
  final VoiceCategoryResolver _voiceCategoryResolver;
  final MerchantDatabase _merchantDatabase;

  ParseVoiceInputUseCase({
    required VoiceTextParser textParser,
    required VoiceCategoryResolver voiceCategoryResolver,
    required MerchantDatabase merchantDatabase,
  }) : _textParser = textParser,
       _voiceCategoryResolver = voiceCategoryResolver,
       _merchantDatabase = merchantDatabase;

  /// Parses [recognizedText] into a [VoiceParseResult].
  ///
  /// [localeId] is optional. When provided, amount extraction routes to the
  /// locale-specific numeral state machine (e.g. 'ja-JP' → Japanese, 'zh-CN' → Chinese).
  /// When null, the transfer station falls back to ja-then-zh heuristic.
  ///
  /// Returns [Result.error] if an unexpected exception occurs.
  Future<Result<VoiceParseResult>> execute(
    String recognizedText, {
    String? localeId,
  }) async {
    try {
      // 1. Extract amount
      final amount = _textParser.extractAmount(recognizedText, localeId: localeId);

      // 2. Extract date
      final parsedDate = _textParser.extractDate(recognizedText);

      // 3. Match merchant (higher priority than keyword category)
      final merchantMatch = _textParser.extractAndMatchMerchant(
        recognizedText,
        _merchantDatabase,
      );

      // 4. Match category and resolve ledger type
      CategoryMatchResult? categoryMatch;
      LedgerType? ledgerType;

      if (merchantMatch != null) {
        // PATTERNS.md §9 caveat: route merchant categoryId through
        // VoiceCategoryResolver._ensureL2 so the always-L2 contract has no
        // escape hatch — never trust an external source to deliver L2 directly.
        categoryMatch = await _voiceCategoryResolver.resolve(
          recognizedText,
          merchantMatch.merchantName,
        );
        // merchant-specific ledgerType continues to win when present.
        ledgerType = merchantMatch.ledgerType;
        // Defensive fallback — if the resolver could not normalize the
        // merchant id (e.g. unknown id, missing _other L2), surface the
        // raw merchant categoryId rather than dropping the category.
        categoryMatch ??= CategoryMatchResult(
          categoryId: merchantMatch.categoryId,
          confidence: merchantMatch.confidence,
          source: MatchSource.merchant,
        );
      } else {
        // Extract keyword: remove amount/date/merchant text from input.
        final keyword = _extractKeyword(recognizedText);
        categoryMatch = await _voiceCategoryResolver.resolve(
          recognizedText,
          keyword,
        );
        if (categoryMatch != null) {
          ledgerType = await _voiceCategoryResolver.resolveLedgerType(
            categoryMatch.categoryId,
          );
        }
      }

      return Result.success(
        VoiceParseResult(
          rawText: recognizedText,
          amount: amount,
          parsedDate: parsedDate,
          merchantName: merchantMatch?.merchantName,
          merchantCategoryId: merchantMatch?.categoryId,
          merchantLedgerType: merchantMatch?.ledgerType,
          categoryMatch: categoryMatch,
          ledgerType: ledgerType,
        ),
      );
    } catch (e) {
      return Result.error('Voice parse failed: $e');
    }
  }

  /// Extracts the category-relevant keyword from voice input.
  ///
  /// Strips away recognized amount, date, and common particles,
  /// leaving only the word(s) that describe the expense category.
  String _extractKeyword(String text) {
    var remaining = text;

    // Remove amount patterns (numbers with currency markers)
    remaining = remaining.replaceAll(
      RegExp(r'[¥￥]?\s*[\d,]+\.?\d*\s*(円|元|ドル)?'),
      '',
    );

    // Remove common Japanese particles
    remaining = remaining.replaceAll(RegExp(r'[のにでをはがもへとや]'), '');

    // Remove common Chinese particles
    remaining = remaining.replaceAll(RegExp(r'[的了吗呢吧啊呀哦]'), '');

    return remaining.trim();
  }
}
