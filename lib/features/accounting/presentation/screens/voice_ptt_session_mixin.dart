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
import '../../domain/models/voice_parse_result.dart';
import '../providers/repository_providers.dart';
import '../widgets/transaction_details_form.dart';
import 'voice_input_screen_helpers.dart';
import 'voice_recognition_event_handler_mixin.dart';

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
    });
    _soundLevels.clear();
    _timestamps.clear();
    _startTime = DateTime.now();
    _partialResultCount = 0;
    _lastWordCount = 0;

    _amountMerger?.dispose();
    final speechService = ref.read(appSpeechRecognitionServiceProvider);
    final parser = localeId.startsWith('ja')
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
    });

    final text = _finalText.isNotEmpty ? _finalText : _partialText;
    if (text.isEmpty) return;

    final parseUseCase = ref.read(parseVoiceInputUseCaseProvider);
    final parseResult = await parseUseCase.execute(
      text,
      localeId: pttVoiceLocaleId,
    );
    if (!mounted || !parseResult.isSuccess) return;
    final data = parseResult.data;
    if (data == null) return;

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
    _amountMerger?.dispose();
    _amountMerger = null;
    await pttSpeechService.cancel();
    if (!mounted) return;
    onPttSessionChanged(() {
      _isRecording = false;
      _soundLevel = 0.0;
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
        _parseFinalResult(text);
      }
    }
  }

  Future<void> _parseVoiceInput(String text) async {
    if (!mounted) return;
    final useCase = ref.read(parseVoiceInputUseCaseProvider);
    final result = await useCase.execute(text, localeId: pttVoiceLocaleId);
    if (mounted && result.isSuccess) {
      onPttSessionChanged(() => _parseResult = result.data);
    }
  }

  Future<void> _parseFinalResult(String text) async {
    if (!mounted) return;
    final useCase = ref.read(parseVoiceInputUseCaseProvider);
    final result = await useCase.execute(text, localeId: pttVoiceLocaleId);

    if (!mounted || !result.isSuccess) return;

    var parseResult = result.data!;

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
