import '../../infrastructure/voice/chinese_numeral_state_machine.dart';
import '../../infrastructure/voice/japanese_numeral_state_machine.dart';
import 'amount_magnitude_guard.dart';
import 'english_number_words.dart';
import 'voice_text_parser.dart';

/// Single arbitration point for voice amount conflicts (MOD-009 P0-1).
///
/// Quick task 260706-saz: the 260703 (ITN-concat repair) and 260706-kzr
/// (magnitude arbitration) decision logic previously lived in TWO places —
/// `ParseVoiceInputUseCase` (parse-time, blocks 1a/1b) and
/// `VoicePttSessionMixin._fillFormFromTextInner` (display-time merged-vs-parsed
/// arbitration). Both sites now delegate to this pure, stateless class so the
/// semantics have exactly one implementation and the presentation layer no
/// longer carries amount-arbitration business logic (S3/S4 fix).
///
/// All decision semantics are migrated VERBATIM — 260703 1a's exact-alternate
/// silent adoption, kzr's precision-over-recall adoption ladder, and the
/// display-time merged-priority default with its two narrow exceptions.
class AmountArbiter {
  /// [textParser] lets the use case share its injected parser instance (test
  /// fakes must flow through). Defaults to a fresh [VoiceTextParser].
  AmountArbiter({VoiceTextParser? textParser})
    : _textParser = textParser ?? VoiceTextParser();

  final VoiceTextParser _textParser;

  // State-machine singletons — mirror ParseVoiceInputUseCase's statics
  // (ChineseNumeralStateMachine is const; the Japanese machine is not, because
  // its dictionary key sort is a non-const static final).
  static const ChineseNumeralStateMachine _zhMachine =
      ChineseNumeralStateMachine();
  static final JapaneseNumeralStateMachine _jaMachine =
      JapaneseNumeralStateMachine();

  /// Parse-time arbitration — the 260703 1a + 260706-kzr 1b pipeline,
  /// migrated verbatim from `ParseVoiceInputUseCase.execute`.
  ///
  /// 1a — 260703 BUG-1: ITN-concat repair. iOS zh ITN can join one spoken
  /// number into a poisoned digit run (「两千五百四十六」 → "250046"). The
  /// signature detector only runs when the amount's own digit string appears
  /// verbatim in the transcript — a kanji-parsed amount never matches and is
  /// never second-guessed. If an alternate transcript independently parses
  /// to the candidate, the recognizer itself disagrees with its primary
  /// reading → adopt the repair directly. Otherwise the candidate rides
  /// along on the result for the form's one-tap confirm affordance.
  ///
  /// 1b — 260706-kzr: magnitude-word ↔ digit-count arbitration. A spoken
  /// magnitude word (千/万/thousand…) pins the amount's expected digit
  /// count (multiplier digits + power) via expectedDigitCountForAmount.
  /// When the primary carries no anchor (ITN already poisoned it into a
  /// pure digit run), the anchor is searched in the alternate transcripts.
  /// If the resolved amount violates the expectation, adopt — in order —
  /// the 1a repair candidate, a state-machine re-read of the primary, or
  /// an alternate-transcript reading, but ONLY when the candidate's own
  /// digit count matches (all candidates come from real parses — never
  /// invented). On adoption the ORIGINAL reading swaps into the returned
  /// `repairCandidate`, so the form's existing 1A notice becomes a one-tap
  /// UNDO back to the raw reading (zero new ARB keys / fields). The 1a
  /// confirmedByAlternate silent adoption is UNTOUCHED — a 1a-repaired
  /// amount usually already satisfies the expectation, making 1b a natural
  /// no-op. Anchor-free utterances yield a null expectation and stay
  /// byte-identical to the 260703 behavior.
  ({int? amount, int? repairCandidate}) resolveParsedAmount({
    required int? parsed,
    required String recognizedText,
    required List<String> alternateTexts,
    required String? localeId,
  }) {
    var resolvedAmount = parsed;
    int? amountRepairCandidate;
    if (parsed != null && recognizedText.contains(parsed.toString())) {
      final candidate = VoiceTextParser.detectConcatRepairCandidate(
        parsed.toString(),
      );
      if (candidate != null) {
        final confirmedByAlternate = alternateTexts.any(
          (alt) =>
              _textParser.extractAmount(alt, localeId: localeId) == candidate,
        );
        if (confirmedByAlternate) {
          resolvedAmount = candidate;
        } else {
          amountRepairCandidate = candidate;
        }
      }
    }

    final expectedDigits =
        expectedDigitCountForAmount(recognizedText, localeId: localeId) ??
        _firstAlternateExpectation(alternateTexts, localeId);
    if (expectedDigits != null &&
        resolvedAmount != null &&
        resolvedAmount.toString().length != expectedDigits) {
      final adopted = _adoptByMagnitude(
        expectedDigits: expectedDigits,
        repairCandidate: amountRepairCandidate,
        recognizedText: recognizedText,
        alternateTexts: alternateTexts,
        localeId: localeId,
      );
      if (adopted != null && adopted != resolvedAmount) {
        final original = resolvedAmount;
        resolvedAmount = adopted;
        amountRepairCandidate = original;
      }
    }

    return (amount: resolvedAmount, repairCandidate: amountRepairCandidate);
  }

  /// Display-time arbitration — merged-vs-parsed conflict resolution,
  /// migrated verbatim from `VoicePttSessionMixin._fillFormFromTextInner`.
  ///
  /// Default: the merger's committed amount wins (`merged ?? parsed` — the
  /// merger sees multi-chunk kanji the single parse misses). Two narrow
  /// exceptions flip to [parsed]:
  ///
  /// Concat exception (260703 BUG-1): when the merger's committed amount is
  /// exactly the ITN-concat poisoning of the parse amount (which the use case
  /// may have already repaired via an alternate transcript, 1D), the parse
  /// amount wins — the merger has no alternates to repair with. The merged
  /// amount keeps its priority for every other divergence (multi-chunk kanji).
  ///
  /// Magnitude exception (260706-kzr): generalization of the concat exception.
  /// When the transcript itself pins an expected digit count (a 千/万/
  /// thousand anchor in [rawText]), a merged amount that VIOLATES it loses to
  /// a parse amount that SATISFIES it — the merger has no alternates or
  /// magnitude awareness to repair with. Every other divergence keeps the
  /// merged-priority semantic untouched (both-compliant, both-violating,
  /// and anchor-free utterances).
  ///
  /// Returns null only when both readings are null (caller falls back to 0).
  int? resolveDisplayAmount({
    required int? parsed,
    required int? merged,
    required String rawText,
    required String? localeId,
  }) {
    var amount = merged ?? parsed;
    if (parsed != null &&
        merged != null &&
        merged != parsed &&
        VoiceTextParser.detectConcatRepairCandidate('$merged') == parsed) {
      amount = parsed;
    }
    if (amount != parsed &&
        parsed != null &&
        merged != null &&
        merged != parsed) {
      final expected = expectedDigitCountForAmount(
        rawText,
        localeId: localeId,
      );
      if (expected != null &&
          '$merged'.length != expected &&
          '$parsed'.length == expected) {
        amount = parsed;
      }
    }
    return amount;
  }

  /// Amount extraction through the full parser routing — the merger's
  /// commit-time extractor (260703 BUG-1 1E: a comma-grouped final like
  /// 「2,546元」 keeps its leading groups; the bare state machine would drop
  /// the comma and read only the tail, 546). Exposed here so the presentation
  /// layer never instantiates [VoiceTextParser] itself.
  int? extractAmount(String text, {String? localeId}) =>
      _textParser.extractAmount(text, localeId: localeId);

  /// 260706-kzr: first non-null magnitude expectation among the alternate
  /// transcripts, in recognizer rank order. Consulted only when the primary
  /// transcript carries no magnitude anchor (ITN poisoned it into digits).
  int? _firstAlternateExpectation(
    List<String> alternateTexts,
    String? localeId,
  ) {
    for (final alt in alternateTexts) {
      final expected = expectedDigitCountForAmount(alt, localeId: localeId);
      if (expected != null) return expected;
    }
    return null;
  }

  /// 260706-kzr: candidate adoption ladder for a digit-count violation.
  /// Sources in order: ① the 1a concat repair candidate, ② a state-machine
  /// (or en number-word) re-read of the primary transcript, ③ each alternate
  /// transcript through the full parser routing. A source is adopted ONLY
  /// when its own digit count matches [expectedDigits] — precision over
  /// recall; no match keeps the current value and any riding candidate.
  int? _adoptByMagnitude({
    required int expectedDigits,
    required int? repairCandidate,
    required String recognizedText,
    required List<String> alternateTexts,
    required String? localeId,
  }) {
    bool fits(int? value) =>
        value != null && value.toString().length == expectedDigits;
    if (fits(repairCandidate)) return repairCandidate;
    final reread = _magnitudeReread(recognizedText, localeId);
    if (fits(reread)) return reread;
    for (final alt in alternateTexts) {
      final fromAlternate = _textParser.extractAmount(alt, localeId: localeId);
      if (fits(fromAlternate)) return fromAlternate;
    }
    return null;
  }

  /// 260706-kzr: source-② re-read of the primary transcript. Locale routing
  /// mirrors [VoiceTextParser]: en stays fully isolated on the bounded
  /// English number-word parser; ja/zh use their state machine; null falls
  /// back ja-then-zh.
  int? _magnitudeReread(String text, String? localeId) {
    final lower = (localeId ?? '').toLowerCase();
    if (lower.startsWith('en')) {
      return parseEnglishNumberWords(text, moneyContext: true);
    }
    if (lower.startsWith('ja')) return _jaMachine.parse(text);
    if (lower.startsWith('zh')) return _zhMachine.parse(text);
    return _jaMachine.parse(text) ?? _zhMachine.parse(text);
  }
}
