import '../../features/accounting/domain/models/transaction.dart';
import '../../features/accounting/domain/models/voice_parse_result.dart';
import '../../infrastructure/ml/merchant_database.dart';
import '../../infrastructure/voice/chinese_numeral_state_machine.dart';
import '../../infrastructure/voice/japanese_numeral_state_machine.dart';
import '../../shared/constants/voice_currency_suffixes.dart';
import '../../shared/utils/result.dart';
import 'voice_category_resolver.dart';
import 'voice_text_parser.dart';

/// Use case for parsing voice-recognized text into structured transaction data.
///
/// Orchestrates: text parsing → merchant matching → category matching →
/// ledger type resolution → [VoiceParseResult] construction.
///
/// Merchant matching has higher priority than keyword category matching.
/// Per Phase 21 PATTERNS.md §9 caveat, the merchant branch routes the
/// derived categoryId through [VoiceCategoryResolver.normalizeToL2] so the
/// always-L2 contract has no escape hatch — even if MerchantDatabase
/// regresses and yields an L1 id, the resolver's `_ensureL2` re-maps it.
///
/// WR-05: merchant branch no longer re-runs [MerchantDatabase.findMerchant]
/// through the resolver; it normalizes the already-derived categoryId
/// directly, preserving the original match's confidence.
class ParseVoiceInputUseCase {
  final VoiceTextParser _textParser;
  final VoiceCategoryResolver _voiceCategoryResolver;
  final MerchantDatabase _merchantDatabase;

  /// Currency-token detectors (Phase 42, VOICE-CUR-01/02/03). Stateless — the
  /// `detectCurrencyToken` scan is locale-routed identically to the amount path.
  static const ChineseNumeralStateMachine _zhMachine =
      ChineseNumeralStateMachine();
  static final JapaneseNumeralStateMachine _jaMachine =
      JapaneseNumeralStateMachine();

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
  /// [localeId] also gates particle stripping in keyword extraction (WR-06).
  ///
  /// Returns [Result.error] if an unexpected exception occurs.
  Future<Result<VoiceParseResult>> execute(
    String recognizedText, {
    String? localeId,
  }) async {
    try {
      // 1. Extract amount
      final amount = _textParser.extractAmount(recognizedText, localeId: localeId);

      // 1b. Detect spoken currency (Phase 42, VOICE-CUR-01/02/03). Runs the
      // longest-first token scan SEPARATELY from the amount path so the
      // integer amount is never polluted (T-42-07). Locale resolves the
      // bare 元/円 ambiguity (D-08 locked: zh→CNY, ja→JPY).
      final detectedCurrency = _detectCurrency(recognizedText, localeId);

      // 2. Extract date
      final parsedDate = _textParser.extractDate(recognizedText);

      // 3. Match merchant (higher priority than keyword category)
      final merchantMatch = _textParser.extractAndMatchMerchant(
        recognizedText,
        _merchantDatabase,
      );

      // Quick task 260526-pg6 (Option F — Task 1): lift the resolver-bound
      // keyword to the top so BOTH branches (merchant + keyword) populate the
      // returned VoiceParseResult with the SAME canonical key the resolver
      // uses internally. Form-side `recordCorrection` then writes that exact
      // key — closing the silent-orphan bug where a divergent re-extractor
      // wrote keys the resolver never looked up.
      //
      // We compute it unconditionally (cheap) so the merchant branch also
      // surfaces a usable correction key when the user changes the
      // merchant-derived category.
      final keyword = _extractKeyword(recognizedText, localeId: localeId);
      final resolvedKeyword = keyword.isEmpty ? null : keyword;

      // 4. Match category and resolve ledger type
      CategoryMatchResult? categoryMatch;
      LedgerType? ledgerType;

      if (merchantMatch != null) {
        // WR-05: normalize the merchantMatch's categoryId directly via the
        // resolver's public _ensureL2 wrapper. Avoids a second findMerchant
        // pass and preserves the original match's confidence.
        final normalizedId = await _voiceCategoryResolver.normalizeToL2(
          merchantMatch.categoryId,
        );
        categoryMatch = CategoryMatchResult(
          categoryId: normalizedId ?? merchantMatch.categoryId,
          confidence: merchantMatch.confidence,
          source: MatchSource.merchant,
        );
        // merchant-specific ledgerType continues to win when present.
        ledgerType = merchantMatch.ledgerType;
      } else {
        // Keyword branch: pass the pre-computed keyword to the resolver.
        categoryMatch = await _voiceCategoryResolver.resolve(keyword);
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
          resolvedKeyword: resolvedKeyword,
          detectedCurrency: detectedCurrency,
        ),
      );
    } catch (e) {
      return Result.error('Voice parse failed: $e');
    }
  }

  /// Resolves the spoken-currency ISO 4217 code for [text] (Phase 42).
  ///
  /// Returns null when no currency token is present OR the token is JPY-native
  /// (`円`/`日元`/`えん`/`yen`/`块`/`塊`/`块钱`) — null means "no foreign
  /// conversion", preserving the pre-Phase-42 JPY path (Pitfall 1).
  ///
  /// Token → ISO via [VoiceCurrencySuffixes.tokenToIso] for explicit foreign
  /// tokens. The locale-ambiguous bare `元` resolves by [localeId] (D-08
  /// locked): zh → 'CNY', ja → 'JPY' (which we surface as null = JPY-native).
  ///
  /// Locale routing mirrors [VoiceTextParser._runStateMachine]: ja-prefixed →
  /// Japanese detector, zh-prefixed → Chinese detector, null → try ja then zh.
  String? _detectCurrency(String text, String? localeId) {
    final lower = (localeId ?? '').toLowerCase();
    final isJa = lower.startsWith('ja');
    final isZh = lower.startsWith('zh');

    final String? token;
    if (isJa) {
      token = _jaMachine.detectCurrencyToken(text);
    } else if (isZh) {
      token = _zhMachine.detectCurrencyToken(text);
    } else {
      token =
          _jaMachine.detectCurrencyToken(text) ??
          _zhMachine.detectCurrencyToken(text);
    }
    if (token == null) return null;

    // Explicit foreign token → its ISO directly.
    final iso = VoiceCurrencySuffixes.tokenToIso[token];
    if (iso != null) return iso;

    // Bare locale-ambiguous yuan token (D-08): zh → CNY, ja → JPY (native →
    // null). Compared against the named constant so no raw CJK literal lives
    // in this file (keeps it out of the hardcoded-CJK architecture scan).
    if (token == VoiceCurrencySuffixes.bareYuanToken) {
      return isZh ? 'CNY' : null;
    }

    // All remaining tokens (円/日元/えん/yen/块/塊/块钱) are JPY-native → null.
    return null;
  }

  /// Extracts the category-relevant keyword from voice input.
  ///
  /// Strips away recognized amount, date, and common particles, leaving only
  /// the word(s) that describe the expense category.
  ///
  /// WR-06: particle stripping is gated on [localeId] when available so a
  /// Japanese sentence does not have its hiragana fragments mangled by the
  /// Chinese particle strip (and vice-versa). When `localeId` is null both
  /// strips run (preserves pre-WR-06 behavior for callers that don't know).
  ///
  /// WR-07: currency suffix tokens come from [VoiceCurrencySuffixes.all] so
  /// the set stays consistent with [VoiceTextParser]'s own stripping pass.
  String _extractKeyword(String text, {String? localeId}) {
    var remaining = text;

    // Remove amount patterns (numbers with currency markers). Longer suffix
    // tokens (e.g. '块钱') win via VoiceCurrencySuffixes.all ordering.
    remaining = remaining.replaceAll(
      RegExp(
        r'[¥￥]?\s*[\d,]+\.?\d*\s*(?:' +
            VoiceCurrencySuffixes.regexAlternation +
            r')?',
      ),
      '',
    );

    final lower = (localeId ?? '').toLowerCase();
    final isJapanese = lower.startsWith('ja');
    final isChinese = lower.startsWith('zh');

    if (isJapanese || (!isJapanese && !isChinese)) {
      // Remove common Japanese particles.
      remaining = remaining.replaceAll(RegExp(r'[のにでをはがもへとや]'), '');
    }
    if (isChinese || (!isJapanese && !isChinese)) {
      // Remove common Chinese particles.
      remaining = remaining.replaceAll(RegExp(r'[的了吗呢吧啊呀哦]'), '');
    }

    return remaining.trim();
  }
}
