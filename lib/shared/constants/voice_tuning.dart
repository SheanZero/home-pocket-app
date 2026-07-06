/// MOD-009 P0-2: single home for the voice pipeline's tuning constants.
///
/// Quick task 260706-saz: these values were previously scattered as magic
/// literals across the infrastructure / application / presentation layers
/// (S5). Each constant below documents its origin site and semantics; the
/// values are byte-identical to the pre-consolidation literals and are
/// locked by `test/unit/application/voice/voice_tuning_consistency_test.dart`
/// against silent drift.
///
/// NOT in here (deliberately):
///   - `kMerchantAutoFillFloor` (0.85) — dual-declared in
///     `application/voice/parse_voice_input_use_case.dart` (application) and
///     `features/voice/domain/services/recognition_reconciler.dart` (domain).
///     The domain layer must stay import-free of shared tuning; the
///     consistency test asserts the two declarations stay equal.
///   - `MerchantRecognizer._scoreAnchoredPrefix` (0.85) — an anchored-prefix
///     scoring TIER that only coincidentally equals the auto-fill floor;
///     semantically unrelated, so it must not track floor changes.
class VoiceTuning {
  VoiceTuning._();

  /// Maximum recognizer listen span per session (speech_to_text `listenFor`).
  /// Origin: `voice_ptt_session_mixin.dart` (startPttSession /
  /// resetPttSessionAndRestart) and `speech_recognition_service.dart` default.
  static const Duration listenFor = Duration(seconds: 30);

  /// End-of-utterance silence window (speech_to_text `pauseFor`) — the
  /// recognizer finalizes after this much silence. Same origin sites as
  /// [listenFor]. Tolerates in-sentence pauses in the one-shot listen model.
  static const Duration pauseFor = Duration(seconds: 3);

  /// Debounce for parsing PARTIAL recognition results (`_onResult` Timer in
  /// `voice_ptt_session_mixin.dart`). NOT the same semantic as
  /// [holdMisfireThreshold] despite the equal value — this one throttles
  /// live re-parses while the user is still speaking.
  static const Duration partialParseDebounce = Duration(milliseconds: 300);

  /// D-03 hold-misfire threshold (`onPttHoldEnd`): presses held shorter than
  /// this are treated as accidental taps and discarded instead of committed.
  /// NOT the same semantic as [partialParseDebounce] despite the equal value.
  static const Duration holdMisfireThreshold = Duration(milliseconds: 300);

  /// Cross-final-result merge window owned by `VoiceChunkMerger` — finals
  /// arriving within this window are merged into one amount buffer.
  static const Duration mergerWindow = Duration(milliseconds: 2500);

  /// Phase 23 D-05 intra-session `notListening` heuristic: a `notListening`
  /// status within this span of the last merger final is a recognizer
  /// self-restart, not a terminal stop. ≈3× typical iOS partial cadence.
  /// Origin: `voice_recognition_event_handler_mixin.dart`.
  static const Duration intraSessionThreshold = Duration(milliseconds: 800);

  /// Sound-level sample throttle (`_onSoundLevel`): samples inside this
  /// window update the live level but are not recorded into the
  /// satisfaction-feature buffers.
  static const Duration soundLevelThrottle = Duration(milliseconds: 100);

  /// 260703 (1E): voice-filled JPY amounts at/above this figure surface a
  /// "please double-check" notice. Origin: `voice_ptt_session_mixin.dart`
  /// (`kVoiceLargeAmountNoticeThreshold` alias preserved there).
  static const int largeAmountNoticeThresholdJpy = 1000000;

  /// T-52-10 amount upper bound — EXCLUSIVE (`amount < bound`). Applied by
  /// both the Arabic-numeral path (`voice_text_parser.dart`) and the bounded
  /// English number-word parser (`english_number_words.dart`) so no
  /// unbounded amount can leak through either route.
  static const int amountUpperBoundExclusive = 10000000;

  /// 260526-pg6 (Option F): hitCount at/above which a learned keyword row is
  /// promoted into the recognizer's substring-fallback step alongside seeds.
  /// Origin: `category_recognizer.dart` (`kLearnedPromotionThreshold` alias
  /// preserved there).
  static const int learnedPromotionThreshold = 3;
}
