import '../../features/accounting/domain/models/transaction.dart';
import '../../features/accounting/domain/models/voice_parse_result.dart';
import '../../infrastructure/voice/chinese_numeral_state_machine.dart';
import '../../infrastructure/voice/japanese_numeral_state_machine.dart';
import '../../shared/constants/voice_currency_suffixes.dart';
import '../../shared/utils/result.dart';
import 'recognition/category_recognizer.dart';
import 'recognition/merchant_recognizer.dart';
import 'voice_text_parser.dart';

/// Auto-fill floor (D-03). When the keyword engine misses, the orchestrator
/// auto-fills the category from the best merchant candidate ONLY when its raw
/// score is at or above this floor (the exact / anchored-prefix tier). Below
/// the floor the category stays null and the ranked candidates are surfaced
/// for Phase-52 chips — never silently auto-filled. The floor lives in the
/// ORCHESTRATOR, not the engine (the engine is recall-first / floor-agnostic).
const double kMerchantAutoFillFloor = 0.85;

/// Use case for parsing voice-recognized text into structured transaction data.
///
/// Phase 50 (DECOUP-01): orchestrates two INDEPENDENT engines that never call
/// each other — [CategoryRecognizer] (keyword-only, runs unconditionally) and
/// [MerchantRecognizer] (anchored scorer over the merchant match-key table) —
/// and applies one thin keyword-priority merge with the 0.85 auto-fill floor
/// (D-02 / D-03):
///   - keyword hit  → keyword wins; ledger = resolveLedgerType(categoryId).
///   - keyword null + best merchant candidate score >= 0.85 → auto-fill the
///     category from the merchant's L2 (via normalizeToL2); ledger is STILL
///     resolveLedgerType(finalCategoryId) — NEVER the merchant's ledger hint
///     (LEDGER-01: the line-106 merchant-ledger short-circuit is deleted).
///   - keyword null + below floor (or no candidate) → category stays null; the
///     ranked candidates are still surfaced on the result.
///
/// Flow: text parsing (amount/currency/date/keyword) → two-engine resolution →
/// thin merge → ledger derivation → [VoiceParseResult] construction.
class ParseVoiceInputUseCase {
  final VoiceTextParser _textParser;
  final CategoryRecognizer _categoryRecognizer;
  final MerchantRecognizer _merchantRecognizer;

  /// Currency-token detectors (Phase 42, VOICE-CUR-01/02/03). Stateless — the
  /// `detectCurrencyToken` scan is locale-routed identically to the amount path.
  static const ChineseNumeralStateMachine _zhMachine =
      ChineseNumeralStateMachine();
  static final JapaneseNumeralStateMachine _jaMachine =
      JapaneseNumeralStateMachine();

  ParseVoiceInputUseCase({
    required VoiceTextParser textParser,
    required CategoryRecognizer categoryRecognizer,
    required MerchantRecognizer merchantRecognizer,
  }) : _textParser = textParser,
       _categoryRecognizer = categoryRecognizer,
       _merchantRecognizer = merchantRecognizer;

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

      // Quick task 260526-pg6 (Option F — Task 1): compute the canonical
      // keyword ONCE, at the top, so the returned VoiceParseResult carries the
      // SAME string the CategoryRecognizer looks up internally. Form-side
      // `recordCorrection` then writes that exact key — closing the
      // silent-orphan bug where a divergent re-extractor wrote keys the
      // recognizer never looked up. `_extractKeyword` is the single canonical
      // key source (T-50-06).
      final keyword = _extractKeyword(recognizedText, localeId: localeId);
      final resolvedKeyword = keyword.isEmpty ? null : keyword;

      // 3. Run the two engines INDEPENDENTLY (DECOUP-01) — neither calls the
      // other; the merge happens only here. The category engine runs
      // unconditionally (DECOUP-02); the merchant engine is recall-first and
      // surfaces every scored candidate (the orchestrator owns the floor).
      final categoryMatch = await _categoryRecognizer.resolve(keyword);
      final merchantCandidates = await _merchantRecognizer.recognize(
        recognizedText,
      );

      // 4. Thin keyword-priority merge (D-02) + 0.85 auto-fill floor (D-03).
      CategoryMatchResult? finalCategory;
      LedgerType? ledgerType;
      if (categoryMatch != null) {
        // Keyword wins (XVAL-02). Ledger is a pure function of the final
        // category (LEDGER-01) — there is NO merchant-ledger short-circuit.
        finalCategory = categoryMatch;
        ledgerType = await _categoryRecognizer.resolveLedgerType(
          categoryMatch.categoryId,
        );
      } else {
        // Keyword miss: auto-fill from the best merchant candidate ONLY at or
        // above the floor. Below the floor finalCategory stays null and the
        // ranked candidates are still surfaced for Phase-52 chips.
        final best = merchantCandidates.isEmpty
            ? null
            : merchantCandidates.first;
        if (best != null && best.score >= kMerchantAutoFillFloor) {
          final l2 = await _categoryRecognizer.normalizeToL2(best.categoryId);
          finalCategory = CategoryMatchResult(
            categoryId: l2 ?? best.categoryId,
            confidence: best.score,
            source: MatchSource.merchant,
          );
          // Ledger derived from the final category — NEVER best.ledgerHint
          // (Phase 49 D-09 non-authoritative; LEDGER-01).
          ledgerType = await _categoryRecognizer.resolveLedgerType(
            finalCategory.categoryId,
          );
        }
      }

      // The best candidate's merchant primitives ride along on the result so
      // the form can pre-fill the (already-encrypted) merchant field. These are
      // descriptive only — the ledger never derives from merchantLedgerType.
      final bestCandidate = merchantCandidates.isEmpty
          ? null
          : merchantCandidates.first;

      return Result.success(
        VoiceParseResult(
          rawText: recognizedText,
          amount: amount,
          parsedDate: parsedDate,
          merchantName: bestCandidate?.displayName,
          merchantCategoryId: bestCandidate?.categoryId,
          categoryMatch: finalCategory,
          ledgerType: ledgerType,
          resolvedKeyword: resolvedKeyword,
          detectedCurrency: detectedCurrency,
          merchantCandidates: merchantCandidates,
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
    // 260614-goh: caseSensitive:false so lowercase English tokens strip
    // STT-capitalized words ("Dollars") too, mirroring _extractArabicAmount.
    remaining = remaining.replaceAll(
      RegExp(
        r'[¥￥]?\s*[\d,]+\.?\d*\s*(?:' +
            VoiceCurrencySuffixes.regexAlternation +
            r')?',
        caseSensitive: false,
      ),
      '',
    );

    // WR-04: the suffix group above is optional (`?`), so a currency-suffix
    // token NOT directly attached to a number (e.g. a stray '元' after the
    // amount was matched without its suffix) survives into the category
    // keyword and degrades resolution. Strip any standalone currency-suffix
    // token left behind. Longest-first ordering inside `regexAlternation`
    // ensures multi-char tokens ('块钱', '日元') are consumed whole, not split.
    remaining = remaining.replaceAll(
      RegExp(
        '(?:${VoiceCurrencySuffixes.regexAlternation})',
        caseSensitive: false,
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
