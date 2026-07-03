/// Voice chunk merger — stateful cross-final-result buffer with 2.5s continued-listening window.
///
/// Owned per recording session by VoiceInputScreen. Single-responsibility:
/// buffer string + window timer + double-gate predicate + restartListen orchestration.
///
/// Per CONTEXT.md D-09, NOT inside ParseVoiceInputUseCase (must stay stateless)
/// and NOT inside the recognizer service. Tested via fake_async for deterministic
/// window behaviour.
library;

import 'dart:async';

import '../../infrastructure/speech/speech_recognition_service.dart';
import '../../infrastructure/voice/numeral_state_machine.dart';

/// Callback invoked when the merger commits a resolved integer amount.
typedef AmountResolvedCallback = void Function(int amount);

/// Stateful cross-final-result buffer that owns the 2.5s window timer,
/// the double-gate merge predicate, and the restartListen orchestration.
///
/// Usage:
/// ```dart
/// final merger = VoiceChunkMerger(
///   parser: ChineseNumeralStateMachine(),
///   speechService: speechService,
///   onAmountResolved: (amount) => setState(() => _amount = amount),
/// );
/// // Feed results from the speech recognizer:
/// merger.feedChunk(result.recognizedWords, isFinal: result.finalResult);
/// // On session end:
/// merger.stop();
/// // On widget disposal:
/// merger.dispose();
/// ```
class VoiceChunkMerger {
  VoiceChunkMerger({
    required NumeralStateMachine parser,
    required SpeechRecognitionService speechService,
    required AmountResolvedCallback onAmountResolved,
    int? Function(String text)? amountExtractor,
    DateTime Function()? clock,
  }) : _parser = parser,
       _speechService = speechService,
       _onAmountResolved = onAmountResolved,
       _amountExtractor = amountExtractor,
       _clock = clock ?? DateTime.now;

  static const _windowDuration = Duration(milliseconds: 2500);

  final NumeralStateMachine _parser;
  final SpeechRecognitionService _speechService;
  final AmountResolvedCallback _onAmountResolved;

  /// 260703 BUG-1 (1E hardening): commit-time amount extractor. When provided,
  /// the merged buffer is parsed through the FULL VoiceTextParser routing —
  /// comma-authoritative guard included — instead of the bare state machine.
  /// A comma-grouped final like 「2,546元」 would otherwise lose its leading
  /// groups (the scanner drops commas and keeps only the tail → 546). The
  /// state machine stays in charge of the two lexical gates below (they are
  /// token-shape predicates, not value parses).
  final int? Function(String text)? _amountExtractor;

  final DateTime Function() _clock;

  String _buffer = '';
  DateTime? _lastFinalAt;
  Timer? _windowTimer;

  /// Phase 23 D-05: last final-result timestamp, exposed for the voice
  /// screen's intra-session `notListening` heuristic guard. Null when no
  /// final has been fed yet in the current session.
  ///
  /// RESEARCH §Open Q1: chose `lastFinalAt` over `lastPartialAt` because
  /// the merger does not track partials (feedChunk ignores non-finals).
  /// If device UAT in Plan 08 shows finals are too sparse to drive the
  /// D-05 guard reliably, v1.4+ pivots to adding `_lastPartialAt` on
  /// _VoiceInputScreenState directly and exposing via the mixin's
  /// abstract `DateTime? get lastPartialAt` — see RESEARCH §Open Q1.
  DateTime? get lastFinalAt => _lastFinalAt;

  /// Feed a speech recognition result chunk into the merger.
  ///
  /// - Partial results (`isFinal: false`) are ignored — only finals drive the merger.
  /// - Empty finals are ignored.
  /// - First final in a session: seeds the buffer, starts the 2.5s window, calls restartListen().
  /// - Subsequent finals: evaluated by the double-gate (time + lexical).
  ///   - Gate pass: appended to buffer, window restarted, restartListen() called.
  ///   - Gate fail: existing buffer committed (parse + emit), dropped chunk discarded
  ///     (NOT seeded as a new buffer — per RESEARCH §Pattern 3 "现金" walk-through).
  Future<void> feedChunk(String text, {required bool isFinal}) async {
    if (!isFinal) return;
    if (text.isEmpty) return;

    final now = _clock();

    if (_buffer.isEmpty) {
      // First final in this session: seed buffer, start window.
      _buffer = text;
      _lastFinalAt = now;
      _restartWindowTimer();
      await _speechService.restartListen();
      return;
    }

    if (_shouldMerge(_buffer, text, now)) {
      // Gate pass: extend buffer, reset window.
      //
      // 260703 BUG-1: the chunks are joined with a SPACE so two STT-normalized
      // Arabic groups ("2500" + "46元") tokenize as separate Digits and the
      // scanner's positional merge reads 2546 — raw concatenation would fuse
      // them into the poisoned "250046元". Kanji/kana chunks are unaffected
      // (whitespace is silently dropped by both tokenizers).
      _buffer = '$_buffer $text';
      _lastFinalAt = now;
      _restartWindowTimer();
      await _speechService.restartListen();
    } else {
      // Gate fail: commit existing buffer; drop new chunk.
      // Per CONTEXT.md D-09: the screen owns the actual recognizer stop.
      // The merger only commits the accumulated amount.
      _commitAndClear();
    }
  }

  /// User-initiated commit — called when the screen's tap-to-stop fires.
  ///
  /// Commits any pending buffer immediately (synchronous parse + emit),
  /// then clears all state. Does NOT call the recognizer stop — that is
  /// the screen's responsibility.
  void stop() {
    _commitAndClear();
  }

  /// Cancel the window timer and clear all merger state.
  ///
  /// Does NOT emit any pending buffer (synchronous teardown — caller
  /// should call [stop] first if they want a final commit). Idempotent.
  void dispose() {
    _windowTimer?.cancel();
    _windowTimer = null;
    _buffer = '';
    _lastFinalAt = null;
  }

  // ─── Internals ───────────────────────────────────────────────────────────

  /// Double-gate predicate: time gate AND lexical gate must both pass.
  bool _shouldMerge(String buffer, String chunk, DateTime now) {
    if (_lastFinalAt == null) return false;
    if (now.difference(_lastFinalAt!) > _windowDuration) return false;
    if (!_bufferLooksOpen(buffer)) return false;
    if (!_chunkStartsNumeric(chunk)) return false;
    return true;
  }

  /// Lexical gate — buffer side.
  ///
  /// Returns true when the buffer's token stream suggests the speaker
  /// is about to add a lower-order digit (e.g. "1千8百" → open, waiting
  /// for tens/ones). Cases per RESEARCH §lines 432-461:
  ///
  /// - Case A: last token is Unit(power >= 100) — "千/百/万" tail.
  /// - Case C: last token is Digit AND there is at least one Unit(power >= 100)
  ///   earlier in the stream — bare digit after a higher unit (e.g. "1千8").
  ///
  /// [PackedToken]s are flattened before evaluation — the last effective
  /// token inside a packed entry drives the predicate (e.g. はっぴゃく ends
  /// in Unit(100), so the buffer is open after せんはっぴゃく).
  bool _bufferLooksOpen(String buffer) {
    final rawTokens = _parser.normalize(buffer);
    if (rawTokens.isEmpty) return false;
    // Flatten PackedTokens to get the true last token.
    final flat = _flattenTokens(rawTokens);
    if (flat.isEmpty) return false;
    final last = flat.last;
    if (last is Unit && last.power >= 100) return true;
    if (last is Digit) {
      // 260703 BUG-1: a buffer ending in a "round" pre-normalized Arabic group
      // (≥100 with at least two trailing zeros — the 「两千五百」→"2500" ITN
      // shape) is open: the recognizer may deliver the tail group ("46元") as
      // the next final. The old rule judged pure-Arabic buffers closed, which
      // committed 2500 and silently dropped the tail.
      if (last.value >= 100 && last.value % 100 == 0) return true;
      final units = flat.whereType<Unit>().toList();
      if (units.isNotEmpty && units.last.power >= 100) return true;
    }
    return false;
  }

  /// Lexical gate — chunk side.
  ///
  /// Returns true when the chunk's first token is numeric (Digit, Unit,
  /// or PackedToken — all signal the speaker is continuing the number).
  /// ZeroPlaceholder as first token is rejected (implausible leading zero
  /// in a continuation).
  bool _chunkStartsNumeric(String chunk) {
    final tokens = _parser.normalize(chunk);
    if (tokens.isEmpty) return false;
    final first = tokens.first;
    return first is Digit || first is Unit || first is PackedToken;
  }

  /// Flatten [PackedToken]s in a token list to their [PackedToken.inner] elements.
  ///
  /// Non-PackedToken tokens pass through unchanged. Only one level of nesting is
  /// expected (the dictionary produces PackedToken([Digit, Unit]) flat entries).
  List<NumeralToken> _flattenTokens(List<NumeralToken> tokens) {
    final result = <NumeralToken>[];
    for (final tok in tokens) {
      if (tok is PackedToken) {
        result.addAll(tok.inner);
      } else {
        result.add(tok);
      }
    }
    return result;
  }

  void _restartWindowTimer() {
    _windowTimer?.cancel();
    _windowTimer = Timer(_windowDuration, _commitAndClear);
  }

  void _commitAndClear() {
    final pending = _buffer;
    _windowTimer?.cancel();
    _windowTimer = null;
    _buffer = '';
    _lastFinalAt = null;
    if (pending.isEmpty) return;
    final extractor = _amountExtractor;
    final amount = extractor != null
        ? extractor(pending)
        : _parser.parse(pending);
    if (amount != null) {
      _onAmountResolved(amount);
    }
  }
}
