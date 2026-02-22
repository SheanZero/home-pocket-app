import '../../features/accounting/domain/models/transaction.dart';
import '../../features/accounting/domain/models/voice_parse_result.dart';
import '../../infrastructure/ml/merchant_database.dart';
import '../../shared/utils/result.dart';
import 'category_matcher.dart';
import 'voice_text_parser.dart';

/// Use case for parsing voice-recognized text into structured transaction data.
///
/// Orchestrates: text parsing → merchant matching → category matching →
/// ledger type resolution → [VoiceParseResult] construction.
///
/// Merchant matching has higher priority than keyword category matching.
class ParseVoiceInputUseCase {
  final VoiceTextParser _textParser;
  final CategoryMatcher _categoryMatcher;
  final MerchantDatabase _merchantDatabase;

  ParseVoiceInputUseCase({
    required VoiceTextParser textParser,
    required CategoryMatcher categoryMatcher,
    required MerchantDatabase merchantDatabase,
  })  : _textParser = textParser,
        _categoryMatcher = categoryMatcher,
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

      // 3. Match category and resolve ledger type
      CategoryMatchResult? categoryMatch;
      LedgerType? ledgerType;

      if (merchantMatch != null) {
        // Merchant found: derive category from merchant data
        // Map MerchantMatch (infrastructure) to CategoryMatchResult (domain)
        categoryMatch = CategoryMatchResult(
          categoryId: merchantMatch.categoryId,
          confidence: merchantMatch.confidence,
          source: MatchSource.merchant,
        );
        ledgerType = merchantMatch.ledgerType;
      } else {
        // No merchant: fall back to keyword-based category matching
        categoryMatch = await _categoryMatcher.matchFromText(recognizedText);
        if (categoryMatch != null) {
          ledgerType =
              await _categoryMatcher.resolveLedgerType(categoryMatch.categoryId);
        }
      }

      // Build result with primitives only (no MerchantMatch reference in domain)
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
}
