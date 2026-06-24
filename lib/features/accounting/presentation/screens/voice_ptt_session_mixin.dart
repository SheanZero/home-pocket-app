// lib/features/accounting/presentation/screens/voice_ptt_session_mixin.dart
//
// Quick task 260622-nhs (D-3 reuse-not-rewrite): the recording / transcription
// / parse / chunk-merger / satisfaction / foreign-triple logic that used to be
// inlined in `_VoiceInputScreenState` is extracted VERBATIM into this reusable
// mixin so BOTH the legacy voice screen AND the single-page push-to-talk bar on
// `ManualOneStepScreen` drive the SAME session code (no behavior fork, D-4).
//
// The mixin OWNS the recording-session state and the hold lifecycle. The host
// supplies, via abstract members:
//   - `pttFormState`        — the `TransactionDetailsFormState` to batch-fill
//   - `pttSpeechService`    — an injectable `StartSpeechRecognitionUseCase?`
//                             (null → built from the provider) for tests
//   - `pttVoiceLocaleId`    — the synchronous locale string mirror
//   - `onPttSessionChanged` — a setState hook the host calls to re-render its UI
//                             (the host owns the widget tree; the mixin owns the
//                             data, and asks the host to repaint)
//
// It composes with `VoiceRecognitionEventHandlerMixin` (status/error callbacks)
// and `VoiceLocaleReadinessMixin` (cold-start gate) — the host wires all three
// `with` mixins, and this mixin satisfies the former's abstract contract.

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

import '../../../../application/currency/get_exchange_rate_use_case.dart';
import '../../../../application/currency/rate_result.dart';
import '../../../../application/currency/repository_providers.dart'
    show appGetExchangeRateUseCaseProvider;
import '../../../../application/voice/repository_providers.dart'
    show
        appSpeechRecognitionServiceProvider,
        chineseNumeralStateMachineProvider,
        japaneseNumeralStateMachineProvider;
import '../../../../application/voice/start_speech_recognition_use_case.dart';
import '../../../../application/voice/voice_chunk_merger.dart';
import '../../../../shared/utils/currency_conversion.dart'
    show convertToJpy, subunitToUnitFor;
import '../../domain/models/category.dart';
import '../../domain/models/transaction.dart';
import '../../../voice/domain/models/voice_parse_result.dart';
import '../providers/repository_providers.dart';
import '../widgets/transaction_details_form.dart';
import '../widgets/voice_error_toast.dart';
import 'voice_input_screen_helpers.dart';
import 'voice_recognition_event_handler_mixin.dart';

/// 260622-nhs R4 (BUG C): the live recognizer-driven session status surfaced to
/// the inline [VoiceRecordPanel] so its title + pulse-dot reflect reality
/// instead of a hardcoded 「正在聆听…」.
///
/// - [listening]  — the recognizer is actively listening (red 「正在聆听…」).
/// - [processing] — a result arrived and a parse / form-fill is in flight
///   (amber 「正在解析…」).
/// - [stopped]    — the recognizer self-terminated and was not re-armed, or the
///   session ended / a restart failed (grey 「停止聆听」).
enum PttListenStatus { listening, processing, stopped }

/// Reusable hold-to-record session: speech lifecycle + transcript + chunk merger
/// + parse + batch-fill + foreign triple + satisfaction, host-agnostic.
///
/// All recording-session fields (`_isRecording`, `_partialText`, `_finalText`,
/// `_soundLevel`, `_amountMerger`, `_mergedAmount`, `_parseResult`,
/// `_displayCurrency`) and methods (`startRecording`, `stopRecordingAndCommit`,
/// `cancelRecordingAndDiscard`, `pushVoiceForeignTriple`, `onResult`,
/// `onSoundLevel`, `parseVoiceInput`, `parseFinalResult`, speech init/dispose)
/// are byte-faithful ports of the prior `_VoiceInputScreenState` members — this
/// is a pure extraction (no parse/merger/foreign/satisfaction semantics change).
mixin VoicePttSessionMixin<W extends ConsumerStatefulWidget>
    on ConsumerState<W>, VoiceRecognitionEventHandlerMixin<W> {
  // ── Abstract host contract ────────────────────────────────────────────────

  /// The embedded form's live state to batch-fill on release. Null until the
  /// host's form is mounted (the mixin no-ops the fill if null).
  TransactionDetailsFormState? get pttFormState;

  /// Injectable speech use case (tests pass a fake); null → built from
  /// [appSpeechRecognitionServiceProvider].
  StartSpeechRecognitionUseCase? get pttInjectedSpeechService;

  /// Synchronous mirror of the resolved voice locale id (e.g. 'ja-JP'). The
  /// host keeps this current from `voiceLocaleIdProvider` (via
  /// [VoiceLocaleReadinessMixin.onVoiceLocaleResolved] and build()).
  String get pttVoiceLocaleId;

  /// setState hook — the mixin calls this whenever its session data changes so
  /// the host repaints. The host MUST wrap the callback in `setState`.
  void onPttSessionChanged(VoidCallback apply);

  /// Optional: notified after a successful PTT commit batch-fill so the host can
  /// flip provenance to `EntrySource.voice`. Default no-op.
  void onPttCommitted() {}

  // ── Owned recording-session state (ported from _VoiceInputScreenState) ─────

  late final StartSpeechRecognitionUseCase pttSpeechService;
  bool _pttServiceInitialized = false;

  bool _isRecording = false;
  String _partialText = '';
  String _finalText = '';
  double _soundLevel = 0.0;
  VoiceParseResult? _parseResult;
  String _displayCurrency = 'JPY';

  DateTime? _pressStart;

  /// 260622-nhs R2: true while a tap-toggled continuous listening session (the
  /// auto-fill modal on the manual screen) is open. In this mode there is no
  /// hold/`pressStart`; the recognizer is re-armed on self-termination and each
  /// speech-final result auto-fills the form live. The legacy hold path leaves
  /// this false so its behavior is byte-unchanged.
  bool _continuousActive = false;

  /// 260622-nhs R4 (BUG B): true while [resetPttSessionAndRestart] is serializing
  /// a `cancel() → startListening()` sequence. While set, [onStatus] must NOT
  /// auto-re-arm — the cancel emits `notListening`/`done`, and re-arming there
  /// would race the reset's own `startListening` into a double-start (the
  /// speech_to_text plugin then hangs / goes silent: the post-reset 「假死」).
  bool _restarting = false;

  /// 260622-nhs R4 (BUG C): true while a final/partial parse + form-fill is in
  /// flight, so the status surfaces 「正在解析…」 (processing). Live-driven, set
  /// around the parse/fill calls and cleared when they settle.
  bool _parsing = false;

  /// 260622-nhs R4 (BUG C): live recognizer status mirror. Driven by
  /// [onStatus] (listening ↔ stopped) and the [_parsing] flag (processing).
  PttListenStatus _listenStatus = PttListenStatus.stopped;

  final List<double> _soundLevels = [];
  final List<DateTime> _timestamps = [];
  DateTime? _startTime;
  int _partialResultCount = 0;
  int _lastWordCount = 0;
  Timer? _parseDebounce;

  VoiceChunkMerger? _amountMerger;
  int? _mergedAmount;
  DateTime? _lastSampleTime;

  /// The amount last pushed into the form by a commit batch-fill (JPY units —
  /// already converted for a foreign utterance). Hosts mirror this into their
  /// own AmountDisplay cache. 0 until the first successful fill.
  int _lastFilledAmount = 0;

  // ── Public read surface (host UI reads these) ──────────────────────────────

  bool get pttIsRecording => _isRecording;
  String get pttPartialText => _partialText;
  String get pttFinalText => _finalText;

  /// Live transcript for the overlay — partial wins while recording, else final.
  String get pttTranscript => _partialText.isNotEmpty ? _partialText : _finalText;
  double get pttSoundLevel => _soundLevel;
  String get pttDisplayCurrency => _displayCurrency;
  bool get pttServiceInitialized => _pttServiceInitialized;

  /// JPY amount last batch-filled by a commit (0 before the first fill).
  int get pttLastFilledAmount => _lastFilledAmount;

  /// Latest parse result (drives the voice-correction learning keyword hook).
  VoiceParseResult? get pttParseResult => _parseResult;

  /// 260622-nhs R2: true while the tap-toggled continuous auto-fill session is
  /// open (the manual-screen modal). False during the legacy hold path.
  bool get pttContinuousActive => _continuousActive;

  /// 260622-nhs R4 (BUG C): live recognizer-driven status for the panel title +
  /// pulse-dot. `processing` while a parse/fill is in flight overrides
  /// `listening` so the user sees 「正在解析…」 the instant a result lands.
  PttListenStatus get pttListenStatus =>
      _parsing && _listenStatus != PttListenStatus.stopped
          ? PttListenStatus.processing
          : _listenStatus;

  // ── VoiceRecognitionEventHandlerMixin abstract contract ────────────────────

  @override
  bool get isRecording => _isRecording;
  @override
  set isRecording(bool value) => _isRecording = value;
  @override
  DateTime? get pressStart => _pressStart;
  @override
  set pressStart(DateTime? value) => _pressStart = value;
  @override
  set isInitialized(bool value) =>
      onPttSessionChanged(() => _pttServiceInitialized = value);
  @override
  set soundLevel(double value) => _soundLevel = value;
  @override
  DateTime? get lastMergerFinalAt => _amountMerger?.lastFinalAt;
  @override
  Future<void> stopRecordingAndCommit() => stopPttSessionAndCommit();

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  /// Build (or adopt the injected) speech service and initialize it. Returns
  /// `true` when the recognizer is available. Call from the host's initState
  /// (after super.initState).
  Future<bool> initPttSpeechService() async {
    pttSpeechService =
        pttInjectedSpeechService ??
        StartSpeechRecognitionUseCase(
          service: ref.read(appSpeechRecognitionServiceProvider),
        );
    final available = await pttSpeechService.initialize(
      onStatus: onStatus,
      onError: onError,
    );
    if (mounted) {
      onPttSessionChanged(() => _pttServiceInitialized = available);
    }
    return available;
  }

  /// Tear down the session. Call from the host's dispose (before super.dispose).
  void disposePttSession() {
    _continuousActive = false;
    _parseDebounce?.cancel();
    _amountMerger?.dispose();
    _amountMerger = null;
    pttSpeechService.cancel();
  }

  // ── Recording start (ported from _startRecording) ──────────────────────────

  Future<void> startPttSession() async {
    final localeId = pttVoiceLocaleId;

    onPttSessionChanged(() {
      _isRecording = true;
      _partialText = '';
      _finalText = '';
      _soundLevel = 0.0;
      _parseResult = null;
      _mergedAmount = null;
      _listenStatus = PttListenStatus.listening;
    });
    _soundLevels.clear();
    _timestamps.clear();
    _startTime = DateTime.now();
    _partialResultCount = 0;
    _lastWordCount = 0;

    _rebuildAmountMerger();

    await pttSpeechService.startListening(
      onResult: _onResult,
      onSoundLevel: _onSoundLevel,
      localeId: localeId,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
    );
  }

  // ── Commit (ported verbatim from _stopRecordingAndCommit) ───────────────────

  Future<void> stopPttSessionAndCommit() async {
    // Pattern 7: merger.stop() bypasses the 2.5s window. MUST run BEFORE
    // pttSpeechService.stop() to preserve the original ordering invariant.
    _amountMerger?.stop();
    await pttSpeechService.stop();
    if (!mounted) return;
    onPttSessionChanged(() {
      _isRecording = false;
      _soundLevel = 0.0;
      _listenStatus = PttListenStatus.stopped;
    });

    final text = _finalText.isNotEmpty ? _finalText : _partialText;
    await _fillFormFromText(text);
  }

  /// 260622-nhs R2: parse [text] and batch-fill the embedded form (amount /
  /// category / merchant / date / satisfaction / foreign triple). Extracted
  /// VERBATIM from the prior `stopPttSessionAndCommit` body so BOTH the legacy
  /// hold-release commit AND the new continuous auto-fill (each speech-final)
  /// share one fill path — no parse/merger/foreign/satisfaction fork.
  /// 260622-nhs R4 (BUG D): accepts an optional already-parsed [data] so the
  /// final/partial paths parse ONCE and reuse the result here (the prior code
  /// parsed `text` again inside this method — a redundant second parse). When
  /// [data] is null this still parses [text] itself (legacy hold-release path).
  Future<void> _fillFormFromText(String text, {VoiceParseResult? data}) async {
    if (text.isEmpty && data == null) return;

    onPttSessionChanged(() => _parsing = true);
    try {
      await _fillFormFromTextInner(text, preParsed: data);
    } finally {
      if (mounted) onPttSessionChanged(() => _parsing = false);
    }
  }

  Future<void> _fillFormFromTextInner(
    String text, {
    VoiceParseResult? preParsed,
  }) async {
    var resolved = preParsed;
    if (resolved == null) {
      if (text.isEmpty) return;
      final parseUseCase = ref.read(parseVoiceInputUseCaseProvider);
      final parseResult = await parseUseCase.execute(
        text,
        localeId: pttVoiceLocaleId,
      );
      if (!mounted || !parseResult.isSuccess) return;
      resolved = parseResult.data;
    }
    if (resolved == null) return;
    final data = resolved;

    Category? category;
    Category? parent;
    final categoryId =
        data.categoryMatch?.categoryId ?? data.merchantCategoryId;
    if (categoryId != null) {
      final repo = ref.read(categoryRepositoryProvider);
      category = await repo.findById(categoryId);
      if (category?.parentId != null) {
        parent = await repo.findById(category!.parentId!);
      }
    }

    final amount = _mergedAmount ?? data.amount ?? 0;
    if (!mounted) return;
    final state = pttFormState;
    if (state == null) return;

    if (amount > 0) {
      state.updateAmount(amount);
      _lastFilledAmount = amount;
    }
    if (category != null) state.updateCategory(category, parent);
    if (data.merchantName != null && data.merchantName!.isNotEmpty) {
      state.updateMerchant(data.merchantName!);
    }
    if (data.parsedDate != null) state.updateDate(data.parsedDate!);
    if (_parseResult?.estimatedSatisfaction != null) {
      state.updateSatisfaction(_parseResult!.estimatedSatisfaction);
    }

    var nextCurrency = 'JPY';
    final detectedCurrency = data.detectedCurrency;
    if (amount > 0 &&
        detectedCurrency != null &&
        detectedCurrency.isNotEmpty) {
      final switched = await pushVoiceForeignTriple(
        state: state,
        currency: detectedCurrency,
        wholeUnitAmount: amount,
        date: data.parsedDate ?? DateTime.now(),
      );
      if (switched) nextCurrency = detectedCurrency;
    }

    onPttSessionChanged(() {
      _displayCurrency = nextCurrency;
    });
    // Provenance hook: a PTT fill happened — host stamps EntrySource.voice.
    onPttCommitted();
  }

  // ── 260622-nhs R2: tap-toggled continuous auto-fill session ────────────────

  /// Start a tap-toggled continuous listening session (manual-screen modal):
  /// reset buffers, begin recognition, and keep listening (re-armed via
  /// [onStatus]) so every speech-final result auto-fills the form. There is NO
  /// hold/`pressStart`; the host exits via [exitPttTapSession] (a tap on the
  /// modal/scrim) or rolls back via the host's snapshot restore.
  Future<void> startPttTapSession() async {
    _continuousActive = true;
    _pressStart = null;
    await startPttSession();
  }

  /// Exit the tap session: stop the recognizer, flush the merger, fill the form
  /// one last time from the latest transcript (D-2 fill-and-stay), and end the
  /// session. Filled content is RETAINED — no discard, no auto-save.
  Future<void> exitPttTapSession() async {
    _continuousActive = false;
    _amountMerger?.stop();
    await pttSpeechService.stop();
    if (!mounted) return;
    onPttSessionChanged(() {
      _isRecording = false;
      _soundLevel = 0.0;
      _listenStatus = PttListenStatus.stopped;
    });
    final text = _finalText.isNotEmpty ? _finalText : _partialText;
    await _fillFormFromText(text);
  }

  /// 260622-nhs R4 (BUG A + BUG B): the 「重置·恢复账目」 reset. Unlike the weak
  /// R3 `resetPttSessionState() + restartPttListening()` pair (which left the
  /// iOS recognizer's ACCUMULATED in-window buffer alive, so the next partial
  /// re-surfaced the old transcript), this:
  ///   1. CANCELS the recognizer — `cancel()` discards its accumulated buffer
  ///      (the real fix for the "old text comes back" bug).
  ///   2. Clears the app-side transcript / parse / merged-amount buffers and
  ///      REBUILDS the chunk merger so the amount re-accumulates from the
  ///      startSession baseline.
  ///   3. Starts a FRESH `startListening` so the user can immediately re-speak.
  ///
  /// BUG B serialization: `_restarting` is held across the whole cancel→start
  /// window so [onStatus] does NOT auto-re-arm on the cancel's
  /// notListening/done — that would race a second concurrent startListening and
  /// hang the plugin (post-reset 「假死」). The `await cancel()` completes before
  /// the fresh `await startListening()`, and the guard is cleared in `finally`.
  Future<void> resetPttSessionAndRestart() async {
    if (!_continuousActive || !mounted) return;
    _restarting = true;
    _parseDebounce?.cancel();
    try {
      // 1. Cancel the recognizer to clear its accumulated buffer.
      await pttSpeechService.cancel();
      if (!mounted) return;

      // 2. Clear app-side buffers + rebuild the merger from the baseline.
      onPttSessionChanged(() {
        _displayCurrency = 'JPY';
        _partialText = '';
        _finalText = '';
        _parseResult = null;
        _mergedAmount = null;
        _soundLevel = 0.0;
        _lastFilledAmount = 0;
        _parsing = false;
        _listenStatus = PttListenStatus.listening;
      });
      _rebuildAmountMerger();

      // 3. Fresh listening session so the user can re-speak immediately.
      await pttSpeechService.startListening(
        onResult: _onResult,
        onSoundLevel: _onSoundLevel,
        localeId: pttVoiceLocaleId,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      );
      if (mounted) {
        onPttSessionChanged(() {
          _isRecording = true;
          _listenStatus = PttListenStatus.listening;
        });
      }
    } finally {
      _restarting = false;
    }
  }

  /// Rebuild the chunk merger (used by [resetPttSessionAndRestart]) so a reset
  /// re-accumulates the amount from a clean baseline. Mirrors the merger setup
  /// in [startPttSession] (same parser selection + onAmountResolved hook).
  void _rebuildAmountMerger() {
    _amountMerger?.dispose();
    final speechService = ref.read(appSpeechRecognitionServiceProvider);
    final parser = pttVoiceLocaleId.startsWith('ja')
        ? ref.read(japaneseNumeralStateMachineProvider)
        : ref.read(chineseNumeralStateMachineProvider);
    _amountMerger = VoiceChunkMerger(
      parser: parser,
      speechService: speechService,
      onAmountResolved: (amount) {
        if (!mounted) return;
        onPttSessionChanged(() => _mergedAmount = amount);
      },
    );
  }

  /// 260622-nhs R5 (BUG 1): silence-class recognizer errors that are NORMAL in
  /// hands-free continuous mode — the user simply paused/stopped speaking and
  /// the recognizer timed out with nothing to transcribe. iOS reports
  /// `error_no_match` as `permanent: true`, so the base handler would flip
  /// `isInitialized=false` (locking the 「语音记录」 bar) and toast 「未识别到语音内容」.
  /// In the continuous session these are swallowed and the recognizer is
  /// re-armed instead. Everything else (permission/audio/client/network) is
  /// fatal and tears the session down.
  static const Set<String> _transientSilenceErrors = {
    'error_no_match',
    'error_speech_timeout',
  };

  @override
  void onError(String errorMsg, bool permanent) {
    if (!mounted) return;

    // Legacy hold path: keep the base behavior byte-unchanged (toast + flip
    // isInitialized on permanent) so voice_input_screen tests stay green.
    if (!_continuousActive) {
      super.onError(errorMsg, permanent);
      return;
    }

    // ── Continuous tap session ───────────────────────────────────────────────
    if (_transientSilenceErrors.contains(errorMsg)) {
      // 260622-nhs R6 (BUG 1): normal silence (the user paused/stopped). Keep
      // R5's swallow — do NOT toast, do NOT flip isInitialized, do NOT tear the
      // session down or lock the bar. But unlike R5 (which re-armed via an
      // unreliable iOS restart that left the mic dead + status stuck on
      // listening), the ONE-SHOT model STOPS cleanly: status → stopped so the
      // panel shows 「停止聆听」 + the tap-reset hint, and the user taps 重置 to
      // record again. No re-arm.
      onPttSessionChanged(() {
        _isRecording = false;
        _soundLevel = 0.0;
        _listenStatus = PttListenStatus.stopped;
      });
      return;
    }

    // 260622-nhs R5 (BUG 1): fatal error — clean teardown (BUG 2: status →
    // stopped), surface the toast, AND recover the bar so the next tap works
    // without an app restart (re-initialize if the platform flipped
    // isInitialized=false on a permanent error).
    onPttSessionChanged(() {
      _continuousActive = false;
      _isRecording = false;
      _restarting = false;
      _soundLevel = 0.0;
      _listenStatus = PttListenStatus.stopped;
    });
    showVoiceRecognitionErrorToast(context, errorMsg);
    unawaited(_recoverBarAfterFatalError());
  }

  /// 260622-nhs R5 (BUG 1): after a fatal error the platform may have flipped
  /// `isInitialized=false` (iOS reports permanent), which would lock the bar's
  /// tap guard. Re-initialize the speech service so the next 「语音记录」 tap can
  /// re-enter, and re-enable the bar (`_pttServiceInitialized=true`).
  Future<void> _recoverBarAfterFatalError() async {
    if (!mounted) return;
    final available = await pttSpeechService.initialize(
      onStatus: onStatus,
      onError: onError,
    );
    if (!mounted) return;
    onPttSessionChanged(() => _pttServiceInitialized = available);
  }

  @override
  void onStatus(String status) {
    final terminal = status == 'done' || status == 'notListening';
    // 260622-nhs R4 (BUG B): while a reset is serializing cancel→start, the
    // cancel emits notListening/done. Acting on it here would race the reset's
    // own startListening — the reset owns the restart, so suppress entirely.
    if (_restarting && terminal) {
      return;
    }
    // 260622-nhs R6 (BUG 1): ONE-SHOT model. The iOS continuous re-arm was
    // unreliable — re-calling startListening on a terminal status often left the
    // mic dead while the status optimistically stayed 「正在聆听」. Instead, when
    // the recognizer naturally terminates in the continuous tap session, STOP
    // cleanly (status → stopped, isRecording → false) and DO NOT re-arm. The
    // panel then shows 「停止聆听」 + the tap-reset hint; the user taps 重置 to
    // record again (resetPttSessionAndRestart). pauseFor:3s already tolerates
    // in-sentence pauses, so a single listen spans a normal utterance.
    if (_continuousActive && terminal && _isRecording) {
      onPttSessionChanged(() {
        _isRecording = false;
        _soundLevel = 0.0;
        _listenStatus = PttListenStatus.stopped;
      });
      super.onStatus(status);
      return;
    }
    // 260622-nhs R4 (BUG C): a terminal status outside the continuous path means
    // the recognizer stopped — surface it.
    if (terminal && !_isRecording) {
      onPttSessionChanged(() => _listenStatus = PttListenStatus.stopped);
    }
    super.onStatus(status);
  }

  // ── Foreign triple (ported verbatim from _pushVoiceForeignTriple) ───────────

  Future<bool> pushVoiceForeignTriple({
    required TransactionDetailsFormState state,
    required String currency,
    required int wholeUnitAmount,
    required DateTime date,
  }) async {
    final minorUnits = wholeUnitAmount * subunitToUnitFor(currency);
    if (minorUnits <= 0) return false;
    try {
      final useCase = ref.read(appGetExchangeRateUseCaseProvider);
      final withSignal = await useCase.execute(
        GetExchangeRateParams(currency: currency, date: date),
      );
      if (!mounted) return false;
      final rate = _extractRate(withSignal.result);
      if (rate == null) {
        return false;
      }
      final jpy = convertToJpy(
        originalMinorUnits: minorUnits,
        appliedRate: rate,
        subunitToUnit: subunitToUnitFor(currency),
      );
      state.updateAmount(jpy);
      _lastFilledAmount = jpy;
      state.updateCurrencyTriple(
        originalCurrency: currency,
        originalAmount: minorUnits,
        appliedRate: rate,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  String? _extractRate(RateResult result) => switch (result) {
    RateFetched(:final rate) => rate,
    RateCached(:final rate) => rate,
    RateFallback(:final rate) => rate,
    RateManual(:final rate) => rate,
    RateUnavailable() => null,
  };

  // ── Cancel/discard (ported verbatim from _cancelRecordingAndDiscard) ────────

  Future<void> cancelPttSessionAndDiscard() async {
    _continuousActive = false;
    _amountMerger?.dispose();
    _amountMerger = null;
    await pttSpeechService.cancel();
    if (!mounted) return;
    onPttSessionChanged(() {
      _isRecording = false;
      _soundLevel = 0.0;
      _listenStatus = PttListenStatus.stopped;
    });
    _pressStart = null;
  }

  // ── Sound-level / result callbacks (ported verbatim) ───────────────────────

  void _onSoundLevel(double level) {
    if (!mounted) return;
    final now = DateTime.now();
    if (_lastSampleTime != null &&
        now.difference(_lastSampleTime!).inMilliseconds < 100) {
      onPttSessionChanged(() => _soundLevel = level);
      return;
    }
    _lastSampleTime = now;
    _soundLevels.add(level);
    _timestamps.add(now);
    onPttSessionChanged(() => _soundLevel = level);
  }

  void _onResult(SpeechRecognitionResult result) {
    if (!mounted) return;

    if (!result.finalResult) {
      _partialResultCount++;
      _lastWordCount = countVoiceWords(result.recognizedWords);
      onPttSessionChanged(() => _partialText = result.recognizedWords);

      _parseDebounce?.cancel();
      _parseDebounce = Timer(const Duration(milliseconds: 300), () {
        if (result.recognizedWords.isNotEmpty) {
          _parseVoiceInput(result.recognizedWords);
        }
      });
    } else {
      final text = result.recognizedWords;
      onPttSessionChanged(() {
        _finalText = text;
        _partialText = '';
        _soundLevel = 0.0;
      });

      _parseDebounce?.cancel();
      if (text.isNotEmpty) {
        _amountMerger?.feedChunk(text, isFinal: true);
        // R2/R4: in the continuous tap session, parse ONCE (with satisfaction)
        // and reuse that single result to auto-fill the form live (BUG D dedupe
        // — the prior code parsed `text` here AND again inside _fillFormFromText).
        // The legacy hold path only refreshes _parseResult here; the fill happens
        // on release (still one parse, via the release commit).
        if (_continuousActive) {
          _parseFinalResult(text).then((parsed) {
            if (mounted && _continuousActive) {
              _fillFormFromText(text, data: parsed);
            }
          });
        } else {
          _parseFinalResult(text);
        }
      }
    }
  }

  /// 260622-nhs R4 (BUG D): the debounced PARTIAL parse now ALSO drives a live
  /// form-fill (continuous session only) so the user sees the entry update as
  /// they speak — sub-second, not after the 3s pauseFor final. Idempotent: the
  /// fill is overwritten by the final fill and revertible by reset (the snapshot
  /// baseline is unchanged). Parses ONCE and reuses the result for both the
  /// `_parseResult` mirror and the fill.
  Future<void> _parseVoiceInput(String text) async {
    if (!mounted) return;
    final useCase = ref.read(parseVoiceInputUseCaseProvider);
    final result = await useCase.execute(text, localeId: pttVoiceLocaleId);
    if (!mounted || !result.isSuccess) return;
    final data = result.data;
    onPttSessionChanged(() => _parseResult = data);
    if (_continuousActive && data != null) {
      await _fillFormFromText(text, data: data);
    }
  }

  /// 260622-nhs R4 (BUG D): now RETURNS the resolved parse result so the caller
  /// can reuse it for the form-fill instead of parsing the same text a second
  /// time. Still mirrors `_parseResult` (drives the learning keyword hook /
  /// satisfaction read) as before.
  Future<VoiceParseResult?> _parseFinalResult(String text) async {
    if (!mounted) return null;
    final useCase = ref.read(parseVoiceInputUseCaseProvider);
    final result = await useCase.execute(text, localeId: pttVoiceLocaleId);

    if (!mounted || !result.isSuccess) return null;

    var parseResult = result.data;
    if (parseResult == null) return null;

    if (parseResult.ledgerType == LedgerType.joy) {
      final features = buildVoiceAudioFeatures(
        soundLevels: _soundLevels,
        timestamps: _timestamps,
        startTime: _startTime,
        partialResultCount: _partialResultCount,
        wordCount: _lastWordCount,
      );
      final estimator = ref.read(voiceSatisfactionEstimatorProvider);
      final satisfaction = estimator.estimate(
        audioFeatures: features,
        recognizedText: text,
      );
      parseResult = parseResult.copyWith(estimatedSatisfaction: satisfaction);
    }

    onPttSessionChanged(() => _parseResult = parseResult);
    return parseResult;
  }

  // ── Hold-gesture lifecycle (ported from _onLongPress* + misfire 300ms) ──────

  /// Read by the host's hold-start guard alongside isLocaleReady/isInitialized.
  bool get pttCanStart => _pttServiceInitialized && !_isRecording;

  void onPttHoldStart() {
    _pressStart = DateTime.now();
    startPttSession();
  }

  void onPttHoldEnd() {
    final start = _pressStart;
    _pressStart = null;
    if (start == null || !_isRecording) return;
    final held = DateTime.now().difference(start);
    // D-03 misfire threshold: presses shorter than 300 ms are discarded.
    if (held < const Duration(milliseconds: 300)) {
      cancelPttSessionAndDiscard();
    } else {
      stopPttSessionAndCommit();
    }
  }

  void onPttHoldCancel() {
    if (_pressStart == null || !_isRecording) return;
    _pressStart = null;
    cancelPttSessionAndDiscard();
  }

  /// Reset the session's transcript/parse buffers (continuous-entry reset).
  void resetPttSessionState() {
    onPttSessionChanged(() {
      _displayCurrency = 'JPY';
      _partialText = '';
      _finalText = '';
      _parseResult = null;
      _mergedAmount = null;
      _soundLevel = 0.0;
      _lastFilledAmount = 0;
    });
  }
}
