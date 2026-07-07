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
//
// voice-consolidation P1-7: the mixin's method bodies are split across two
// same-library `part` files as extensions `on VoicePttSessionMixin<W>` —
// `voice_ptt_session_fill_orchestration.dart` (result/sound-level callbacks,
// partial/final parse, batch-fill, merger rebuild) and
// `voice_ptt_session_foreign_notice.dart` (foreign triple, post-final amount
// notices, satisfaction estimation). The mixin DECLARATION — fields, abstract
// host contract, overrides, public getters, and the session state machine —
// stays here; the parts share this file's imports and private visibility, so
// the split is a byte-faithful move (no renames, no visibility promotion).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

import '../../../../application/currency/get_exchange_rate_use_case.dart';
import '../../../currency/domain/models/rate_result.dart';
import '../../../../application/currency/repository_providers.dart'
    show appGetExchangeRateUseCaseProvider;
import '../../../../application/voice/repository_providers.dart'
    show
        appSpeechRecognitionServiceProvider,
        chineseNumeralStateMachineProvider,
        japaneseNumeralStateMachineProvider;
import '../../../../application/voice/amount_arbiter.dart';
import '../../../../application/voice/voice_amount_notice_policy.dart';
import '../../../../application/voice/voice_fill_decision.dart';
import '../../../../application/voice/start_speech_recognition_use_case.dart';
import '../../../../application/voice/voice_chunk_merger.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../infrastructure/i18n/formatters/number_formatter.dart';
import '../../../../shared/constants/voice_tuning.dart';
import '../../../../shared/utils/currency_conversion.dart'
    show convertToJpy, subunitToUnitFor;
import '../../domain/models/category.dart';
import '../../domain/models/transaction.dart';
import '../../../voice/domain/models/voice_parse_result.dart';
import '../../../settings/presentation/providers/state_settings.dart'
    show appSettingsProvider;
import '../providers/repository_providers.dart';
import '../widgets/transaction_details_form.dart';
import '../widgets/voice_error_toast.dart';
import 'voice_input_screen_helpers.dart';
import 'voice_recognition_event_handler_mixin.dart';

part 'voice_ptt_session_fill_orchestration.dart';
part 'voice_ptt_session_foreign_notice.dart';

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

/// 260703 (1E): voice-filled amounts at/above this JPY figure surface a
/// "please double-check" notice. Voice is the only entry path that can be
/// poisoned by recognizer ITN artifacts (BUG-1: 「两千五百四十六」 → 250046),
/// so the guardrail lives in the voice session, not in the shared form.
const int kVoiceLargeAmountNoticeThreshold =
    VoiceTuning.largeAmountNoticeThresholdJpy;

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

  /// 260706-saz (voice-consolidation P0-1): single arbitration point for merged-vs-parsed
  /// display conflicts and the merger's commit-time amount extraction. The
  /// mixin no longer carries amount-arbitration business logic (S3 fix).
  late final AmountArbiter _amountArbiter = AmountArbiter();

  /// The amount last pushed into the form by a commit batch-fill (JPY units —
  /// already converted for a foreign utterance). Hosts mirror this into their
  /// own AmountDisplay cache. 0 until the first successful fill.
  int _lastFilledAmount = 0;

  // ── Public read surface (host UI reads these) ──────────────────────────────

  bool get pttIsRecording => _isRecording;
  String get pttPartialText => _partialText;
  String get pttFinalText => _finalText;

  /// Live transcript for the overlay — partial wins while recording, else final.
  String get pttTranscript =>
      _partialText.isNotEmpty ? _partialText : _finalText;
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
      // 260703 (2C): partial fills no longer touch the display currency, so a
      // fresh session resets it here instead of on the first partial fill.
      _displayCurrency = 'JPY';
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
      listenFor: VoiceTuning.listenFor,
      pauseFor: VoiceTuning.pauseFor,
      allowOnDeviceFallback: _voiceAllowOnDeviceFallback,
    );
  }

  /// KFB C2 (T-kfb-01): the user's on-device→cloud auto-degradation policy.
  /// `?? true` keeps behavior byte-identical before the async settings provider
  /// resolves and in tests that do not override [appSettingsProvider].
  bool get _voiceAllowOnDeviceFallback =>
      ref.read(appSettingsProvider).value?.voiceAllowOnDeviceFallback ?? true;

  // ── Commit (ported verbatim from _stopRecordingAndCommit) ───────────────────

  Future<void> stopPttSessionAndCommit() => _stopAndFill(endContinuous: false);

  /// 260706-saz (voice-consolidation P0-3): the shared stop→fill sequence behind
  /// [stopPttSessionAndCommit] and [exitPttTapSession] — the two public
  /// methods were byte-identical except for the exit path's leading
  /// `_continuousActive = false` ([endContinuous]).
  Future<void> _stopAndFill({required bool endContinuous}) async {
    if (endContinuous) _continuousActive = false;
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
    await _fillFormFromText(text, data: _cachedParseFor(text));
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
  Future<void> exitPttTapSession() => _stopAndFill(endContinuous: true);

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
  ///
  /// quick-260706-kax (VRESET-01/02): this ALSO revives a session killed by the
  /// [onError] fatal branch — that branch flips `_continuousActive=false` while
  /// the host panel stays open (停止聆听 + red reset square), so gating entry on
  /// `_continuousActive` made every reset tap a silent no-op. The entry guard is
  /// now the REENTRANCY fence (`_restarting`): a second tap inside the
  /// cancel→start window early-returns instead of double-starting the plugin,
  /// and `_continuousActive` is unconditionally restored in step 2 — the reset
  /// button always honors 重新录入 regardless of how the previous session died.
  Future<void> resetPttSessionAndRestart() async {
    if (_restarting || !mounted) return;
    _restarting = true;
    _parseDebounce?.cancel();
    try {
      // 1. Cancel the recognizer to clear its accumulated buffer.
      await pttSpeechService.cancel();
      if (!mounted) return;

      // 2. Clear app-side buffers + rebuild the merger from the baseline.
      //    `_continuousActive = true` is the recovery semantic: it MUST be set
      //    before startListening so the recovered session's [_onResult]
      //    continuous-branch auto-fill works (VRESET-01).
      onPttSessionChanged(() {
        _continuousActive = true;
        _clearSessionBuffers();
        _parsing = false;
        _listenStatus = PttListenStatus.listening;
      });
      _rebuildAmountMerger();

      // Belt-and-braces: after a fatal error the platform may have flipped
      // availability off, and the async [_recoverBarAfterFatalError] may not
      // have completed yet — re-initialize (idempotent) before restarting. On
      // failure, roll the state back so the panel honestly shows stopped; the
      // `finally` still clears `_restarting`, so a later tap can retry.
      if (!pttSpeechService.isAvailable) {
        final available = await pttSpeechService.initialize(
          onStatus: onStatus,
          onError: onError,
        );
        if (!mounted) return;
        if (!available) {
          onPttSessionChanged(() {
            _continuousActive = false;
            _isRecording = false;
            _listenStatus = PttListenStatus.stopped;
          });
          return;
        }
      }

      // 3. Fresh listening session so the user can re-speak immediately.
      await pttSpeechService.startListening(
        onResult: _onResult,
        onSoundLevel: _onSoundLevel,
        localeId: pttVoiceLocaleId,
        listenFor: VoiceTuning.listenFor,
        pauseFor: VoiceTuning.pauseFor,
        allowOnDeviceFallback: _voiceAllowOnDeviceFallback,
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
    if (held < VoiceTuning.holdMisfireThreshold) {
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
    onPttSessionChanged(_clearSessionBuffers);
  }

  /// 260706-saz (voice-consolidation P0-3): the seven session buffers shared by BOTH
  /// reset paths ([resetPttSessionAndRestart] and [resetPttSessionState]).
  /// Deliberately EXCLUDES `_continuousActive` / `_parsing` / `_listenStatus`
  /// — those belong only to the restart path (VRESET-01 revival semantics);
  /// callers wrap this in [onPttSessionChanged] themselves.
  void _clearSessionBuffers() {
    _displayCurrency = 'JPY';
    _partialText = '';
    _finalText = '';
    _parseResult = null;
    _mergedAmount = null;
    _soundLevel = 0.0;
    _lastFilledAmount = 0;
  }
}
