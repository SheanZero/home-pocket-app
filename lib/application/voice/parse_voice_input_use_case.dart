import '../../features/accounting/domain/models/transaction.dart';
import '../../features/accounting/domain/models/voice_parse_result.dart';
import '../../infrastructure/ml/merchant_database.dart';
import '../../shared/utils/result.dart';
import 'fuzzy_category_matcher.dart';
import 'voice_text_parser.dart';

/// Use case for parsing voice-recognized text into structured transaction data.
///
/// Orchestrates: text parsing → merchant matching → category matching →
/// ledger type resolution → [VoiceParseResult] construction.
///
/// Merchant matching has higher priority than keyword category matching.
class ParseVoiceInputUseCase {
  final VoiceTextParser _textParser;
  final FuzzyCategoryMatcher _fuzzyCategoryMatcher;
  final MerchantDatabase _merchantDatabase;

  ParseVoiceInputUseCase({
    required VoiceTextParser textParser,
    required FuzzyCategoryMatcher fuzzyCategoryMatcher,
    required MerchantDatabase merchantDatabase,
  }) : _textParser = textParser,
       _fuzzyCategoryMatcher = fuzzyCategoryMatcher,
       _merchantDatabase = merchantDatabase;

  /// Parses [recognizedText] into a [VoiceParseResult].
  ///
  /// Returns [Result.error] if an unexpected exception occurs.
  Future<Result<VoiceParseResult>> execute(String recognizedText) async {
    try {
      // 1. Extract amount
      final amount = _textParser.extractAmount(recognizedText);

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
        categoryMatch = CategoryMatchResult(
          categoryId: merchantMatch.categoryId,
          confidence: merchantMatch.confidence,
          source: MatchSource.merchant,
        );
        ledgerType = merchantMatch.ledgerType;
      } else {
        // Extract keyword: remove amount/date/merchant text from input
        final keyword = _extractKeyword(recognizedText);
        categoryMatch = await _fuzzyCategoryMatcher.match(
          recognizedText,
          keyword,
        );
        if (categoryMatch != null) {
          ledgerType = await _fuzzyCategoryMatcher.resolveLedgerType(
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
