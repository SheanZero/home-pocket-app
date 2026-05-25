import 'dart:async';

import 'package:flutter/gestures.dart'
    show
        LongPressGestureRecognizer,
        LongPressStartDetails,
        LongPressEndDetails;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../features/accounting/domain/models/transaction.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../application/voice/repository_providers.dart'
    show
        appSpeechRecognitionServiceProvider,
        chineseNumeralStateMachineProvider,
        japaneseNumeralStateMachineProvider;
import '../../../../application/voice/start_speech_recognition_use_case.dart';
import '../../../../application/voice/voice_chunk_merger.dart';
import '../../../settings/presentation/providers/state_locale.dart';
import '../../../settings/presentation/providers/state_settings.dart';
import '../../domain/models/category.dart';
import '../../domain/models/entry_source.dart';
import '../../domain/models/transaction_details_form_config.dart';
import '../../domain/models/voice_parse_result.dart';
import '../providers/repository_providers.dart';
import '../widgets/amount_display.dart';
import '../widgets/amount_edit_bottom_sheet.dart';
import '../widgets/entry_mode_switcher.dart';
import '../widgets/input_mode_tabs.dart';
import '../widgets/soft_toast.dart';
import '../widgets/transaction_details_form.dart';
import '../widgets/voice_error_toast.dart';
import '../widgets/voice_waveform.dart';

/// Voice input screen for creating transactions through natural language speech.
///
/// Replaces the previous static stub with a full [ConsumerStatefulWidget]
/// implementation. Manages [StartSpeechRecognitionUseCase] lifecycle directly
/// (not from provider) for correct stateful lifecycle binding.
class VoiceInputScreen extends ConsumerStatefulWidget {
  const VoiceInputScreen({super.key, required this.bookId, this.speechService});

  final String bookId;
  final StartSpeechRecognitionUseCase? speechService;

  @override
  ConsumerState<VoiceInputScreen> createState() => _VoiceInputScreenState();
}

class _VoiceInputScreenState extends ConsumerState<VoiceInputScreen>
    with WidgetsBindingObserver {
  // Speech recognition use case — managed directly (stateful lifecycle)
  late final StartSpeechRecognitionUseCase _speechService;

  // Recording state
  bool _isRecording = false;
  bool _isInitialized = false;

  // Transcript state
  String _partialText = '';
  String _finalText = '';

  // Sound level state (normalized 0.0–1.0)
  double _soundLevel = 0.0;

  // Parse result
  VoiceParseResult? _parseResult;

  // Effective voice locale (updated reactively from voiceLocaleIdProvider)
  String _voiceLocaleId = 'zh-CN';

  // ── Phase 22: embedded form integration (D-01) ──

  /// GlobalKey on the embedded TransactionDetailsForm so the voice screen
  /// can call public setters (updateAmount/Category/Merchant/Note/Satisfaction)
  /// on long-press release (D-05 batch-fill).
  final _formKey = GlobalKey<TransactionDetailsFormState>();

  /// Per-host FocusNodes for the form's merchant/note TextFields (D-09).
  /// Listeners auto-stop recording when text-field gains focus.
  late final FocusNode _merchantFocus;
  late final FocusNode _noteFocus;

  /// Captured at _onLongPressStart; consumed at _onLongPressEnd to compute
  /// held duration vs the 300 ms misfire threshold (D-03).
  DateTime? _pressStart;

  /// Submit-in-flight flag for the Save button (mirrors manual screen's
  /// _isSubmitting at manual_one_step_screen.dart:77).
  bool _isSubmitting = false;

  /// Host-cache mirror of the form's amount + category state (BLOCKER B-2
  /// resolution). Mirrors manual_one_step_screen.dart:74-78 precedent.
  /// Updated in the same setState block that pushes values into the form
  /// via _formKey.currentState!.updateXxx — keeps the AmountDisplay render
  /// and the _canSave predicate decoupled from GlobalKey.currentState
  /// first-build null timing.
  int _hostAmount = 0;
  Category? _hostCategory;

  /// Save button enable predicate — pure read from the host-cache mirror
  /// (mirrors manual_one_step_screen.dart:89 _canSave getter shape).
  bool get _canSave =>
      _hostCategory != null && _hostAmount > 0 && !_isSubmitting;

  // Audio features collection
  final List<double> _soundLevels = [];
  final List<DateTime> _timestamps = [];
  DateTime? _startTime;
  int _partialResultCount = 0;
  int _lastWordCount = 0;

  // Debounce timer for partial result parsing
  Timer? _parseDebounce;

  /// Cross-final-result merger for the amount path (VOICE-02).
  /// Null when not recording; rebuilt on each _startRecording with the
  /// locale-correct parser.
  VoiceChunkMerger? _amountMerger;

  /// Latest committed amount from the merger (VOICE-02). Wins over
  /// _parseResult.amount in _navigateToConfirm so that intra-pause merges
  /// (e.g., "1千8百" + "4十元" → 1840) survive the navigation.
  int? _mergedAmount;

  // Sound level sampling throttle
  DateTime? _lastSampleTime;

  @override
  void initState() {
    super.initState();

    // Phase 22 D-09: per-host FocusNodes wired through the form config so the
    // form's TextFields use them; listener auto-stops recording when a
    // text field gains focus mid-session.
    _merchantFocus = FocusNode()..addListener(_handleFocusChange);
    _noteFocus = FocusNode()..addListener(_handleFocusChange);

    // Phase 22 / Pitfall 7 (RESEARCH Open Q1): observe app lifecycle so a
    // paused app cancels any in-progress recording (didChangeAppLifecycleState
    // below). Without this, locking the screen mid-press would leave the mic
    // "live" with no user-visible affordance.
    WidgetsBinding.instance.addObserver(this);

    _speechService =
        widget.speechService ??
        StartSpeechRecognitionUseCase(
          service: ref.read(appSpeechRecognitionServiceProvider),
        );
    _initSpeechService();
  }

  Future<void> _initSpeechService() async {
    final available = await _speechService.initialize(
      onStatus: _onStatus,
      onError: _onError,
    );

    if (mounted) {
      setState(() => _isInitialized = available);

      if (!available) {
        _showPermissionError();
      }
    }
  }

  void _onStatus(String status) {
    if (!mounted) return;
    // G-01: When the platform speech recognizer self-terminates (status 'done'
    // or 'notListening' — triggered by 30s listenFor expiry, 3s pauseFor mid-press,
    // or platform mic interruption) while the user is still holding the mic
    // (_pressStart != null), drive the SAME commit path as _onLongPressEnd.
    // Without this branch, _onLongPressEnd on the eventual finger release
    // short-circuits at its `!_isRecording` guard and silently drops the
    // transcript. CR-01 (22-REVIEW.md:47-83).
    //
    // Idempotency: clear _pressStart BEFORE invoking the commit path so the
    // subsequent _onLongPressEnd hits its `start == null` guard and returns
    // without re-running commit or discard.
    if ((status == 'done' || status == 'notListening') && _isRecording) {
      if (_pressStart != null) {
        _pressStart = null;
        unawaited(_stopRecordingAndCommit());
        return;
      }
      setState(() {
        _isRecording = false;
        _soundLevel = 0.0;
      });
    }
  }

  void _onError(String errorMsg, bool permanent) {
    if (!mounted) return;
    // G-02: surface error to the user — never silently swallow (CLAUDE.md rule
    // "never silently swallow errors", "provide user-friendly error messages
    // in UI-facing code"). The errorMsg comes from the platform speech engine
    // and is English-only (e.g., 'error_network'); showVoiceRecognitionErrorToast
    // maps it to a localized ARB string (WR-05 i18n compliance).
    //
    // CR-02 literal shape (22-REVIEW.md:99-108): on permanent==true, flip
    // _isInitialized = false so the EXISTING _onLongPressStart guard
    // `if (!_isInitialized || _isRecording) return;` short-circuits new
    // presses. Recovery: next successful _initSpeechService() call restores
    // _isInitialized=true (currently only on screen rebuild; no in-screen
    // retry affordance — out of scope for gap closure).
    setState(() {
      _isRecording = false;
      _soundLevel = 0.0;
      if (permanent) {
        _isInitialized = false;
      }
    });
    showVoiceRecognitionErrorToast(context, errorMsg);
  }

  void _showPermissionError() {
    // Insert a SoftToast overlay for permission error feedback
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 0,
        right: 0,
        child: SoftToast(
          message: S.of(context).voiceMicrophonePermissionRequired,
          icon: Icons.mic_off,
          onDismissed: () => entry.remove(),
        ),
      ),
    );
    overlay.insert(entry);
  }

  // ── Phase 22 D-03: hold-to-record gesture lifecycle ──

  void _onLongPressStart(LongPressStartDetails details) {
    if (!_isInitialized || _isRecording) return;
    _pressStart = DateTime.now();
    _startRecording();
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    final start = _pressStart;
    _pressStart = null;
    if (start == null || !_isRecording) return;
    final held = DateTime.now().difference(start);
    // D-03 misfire threshold: presses shorter than 300 ms are treated as
    // accidental taps and discarded without parsing.
    if (held < const Duration(milliseconds: 300)) {
      _cancelRecordingAndDiscard();
    } else {
      _stopRecordingAndCommit();
    }
  }

  void _onLongPressCancel() {
    // Finger slid off the recognizer's hit area before release.
    // Treat as misfire — discard buffer, no commit.
    if (_pressStart == null || !_isRecording) return;
    _pressStart = null;
    _cancelRecordingAndDiscard();
  }

  Future<void> _startRecording() async {
    // Use the locale pre-warmed and kept current by ref.watch in build().
    final localeId = _voiceLocaleId;

    // Reset state
    setState(() {
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

    // Build the per-session merger (VOICE-02). Tear down any prior merger first.
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
        setState(() => _mergedAmount = amount);
      },
    );

    await _speechService.startListening(
      onResult: _onResult,
      onSoundLevel: _onSoundLevel,
      localeId: localeId,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
    );
  }

  /// D-05 commit path: commit merger buffer, drain speech service, then
  /// batch-fill the embedded form via the 4 + 1 public setters added in
  /// Plan 02. BLOCKER B-2: _hostAmount + _hostCategory are mirrored so
  /// AmountDisplay and _canSave see the new values atomically.
  Future<void> _stopRecordingAndCommit() async {
    // Pattern 7: merger.stop() bypasses the 2.5s window. MUST run BEFORE
    // _speechService.stop() to preserve the original ordering invariant.
    _amountMerger?.stop();
    await _speechService.stop();
    if (!mounted) return;
    setState(() {
      _isRecording = false;
      _soundLevel = 0.0;
    });

    // D-05: batch-fill the form via parser + setter calls.
    final text = _finalText.isNotEmpty ? _finalText : _partialText;
    if (text.isEmpty) return;

    final parseUseCase = ref.read(parseVoiceInputUseCaseProvider);
    final parseResult = await parseUseCase.execute(
      text,
      localeId: _voiceLocaleId,
    );
    if (!mounted || !parseResult.isSuccess) return;
    final data = parseResult.data;
    if (data == null) return;

    // Category lookup — voice resolver guarantees a level-2 categoryId per
    // Phase 21 D-03.
    Category? category;
    Category? parent;
    final categoryId = data.categoryMatch?.categoryId ?? data.merchantCategoryId;
    if (categoryId != null) {
      final repo = ref.read(categoryRepositoryProvider);
      category = await repo.findById(categoryId);
      if (category?.parentId != null) {
        parent = await repo.findById(category!.parentId!);
      }
    }

    final amount = _mergedAmount ?? data.amount ?? 0;
    if (!mounted) return;
    final state = _formKey.currentState;
    if (state == null) return;

    // 4 + 1 form setter calls (D-07 — Wave 0 Plan 02 added them).
    // updateNote intentionally absent: parser does not emit a discrete note
    // in v1.3 (RESEARCH §A5). updateSatisfaction wired per Open Q2 (B-1).
    if (amount > 0) state.updateAmount(amount);
    if (category != null) state.updateCategory(category, parent);
    if (data.merchantName != null && data.merchantName!.isNotEmpty) {
      state.updateMerchant(data.merchantName!);
    }
    if (_parseResult?.estimatedSatisfaction != null) {
      state.updateSatisfaction(_parseResult!.estimatedSatisfaction);
    }

    // B-2 host-cache mirror — AmountDisplay + _canSave see consistent values.
    setState(() {
      _hostAmount = amount;
      _hostCategory = category;
    });
  }

  /// Pitfall 6: discard path uses dispose+cancel (NOT stop+stop).
  /// merger.dispose() drops the buffer; speech.cancel() abandons pending
  /// finals. Calling stop() on either would COMMIT instead.
  Future<void> _cancelRecordingAndDiscard() async {
    _amountMerger?.dispose();
    _amountMerger = null;
    await _speechService.cancel();
    if (!mounted) return;
    setState(() {
      _isRecording = false;
      _soundLevel = 0.0;
    });
    _pressStart = null;
  }

  /// Save handler — delegates to the embedded form's submit() with the same
  /// try/finally + result.when shape as manual_one_step_screen.dart:_save
  /// (lines 278-304).
  Future<void> _onSavePressed() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final result = await _formKey.currentState!.submit();
      if (!mounted) return;
      result.when(
        success: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.of(context).transactionSaved)),
          );
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
        validationError: (msg) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        },
        persistError: (msg) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        },
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _onSoundLevel(double level) {
    if (!mounted) return;

    // Throttle sound level sampling to 100ms
    final now = DateTime.now();
    if (_lastSampleTime != null &&
        now.difference(_lastSampleTime!).inMilliseconds < 100) {
      // Update UI only
      setState(() => _soundLevel = level);
      return;
    }
    _lastSampleTime = now;
    _soundLevels.add(level);
    _timestamps.add(now);

    setState(() => _soundLevel = level);
  }

  void _onResult(SpeechRecognitionResult result) {
    if (!mounted) return;

    if (!result.finalResult) {
      _partialResultCount++;
      _lastWordCount = _countWords(result.recognizedWords);

      setState(() => _partialText = result.recognizedWords);

      // Debounce parsing for partial results (300ms)
      _parseDebounce?.cancel();
      _parseDebounce = Timer(const Duration(milliseconds: 300), () {
        if (result.recognizedWords.isNotEmpty) {
          _parseVoiceInput(result.recognizedWords);
        }
      });
    } else {
      // Final result
      final text = result.recognizedWords;
      setState(() {
        _finalText = text;
        _partialText = '';
        // Do NOT clear the recording flag here. The merger orchestrates
        // continued listening across multiple finals (VOICE-02). The screen
        // transitions out of recording only via:
        //   (a) explicit user stop (_stopRecording)
        //   (b) onStatus 'done' / 'notListening' callback (line 110)
        _soundLevel = 0.0;
      });

      _parseDebounce?.cancel();
      if (text.isNotEmpty) {
        // Amount path: merger gates and commits on window expiry / lexical close.
        _amountMerger?.feedChunk(text, isFinal: true);
        // Merchant / category / date path: unchanged — runs every final.
        _parseFinalResult(text);
      }
    }
  }

  Future<void> _parseVoiceInput(String text) async {
    if (!mounted) return;
    final useCase = ref.read(parseVoiceInputUseCaseProvider);
    final result = await useCase.execute(text, localeId: _voiceLocaleId);
    if (mounted && result.isSuccess) {
      setState(() => _parseResult = result.data);
    }
  }

  Future<void> _parseFinalResult(String text) async {
    if (!mounted) return;
    final useCase = ref.read(parseVoiceInputUseCaseProvider);
    final result = await useCase.execute(text, localeId: _voiceLocaleId);

    if (!mounted || !result.isSuccess) return;

    var parseResult = result.data!;

    // For soul ledger transactions, estimate satisfaction from audio features.
    // BLOCKER B-1: this estimator output is the source of
    // _parseResult.estimatedSatisfaction that _stopRecordingAndCommit later
    // pushes into the form via state.updateSatisfaction(...).
    if (parseResult.ledgerType == LedgerType.soul) {
      final features = _buildAudioFeatures();
      final estimator = ref.read(voiceSatisfactionEstimatorProvider);
      final satisfaction = estimator.estimate(
        audioFeatures: features,
        recognizedText: text,
      );
      parseResult = parseResult.copyWith(estimatedSatisfaction: satisfaction);
    }

    setState(() => _parseResult = parseResult);
  }

  VoiceAudioFeatures _buildAudioFeatures() {
    final now = DateTime.now();
    return VoiceAudioFeatures(
      soundLevels: List.unmodifiable(_soundLevels),
      timestamps: List.unmodifiable(_timestamps),
      startTime: _startTime ?? now,
      endTime: now,
      partialResultCount: _partialResultCount,
      wordCount: _lastWordCount,
    );
  }

  int _countWords(String text) {
    if (text.isEmpty) return 0;
    // Japanese/Chinese: estimate by character count (2 chars ≈ 1 word)
    // English: split by whitespace
    final hasLatin = RegExp(r'[a-zA-Z]').hasMatch(text);
    if (hasLatin) {
      return text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    }
    return (text.replaceAll(RegExp(r'\s'), '').length / 2).ceil();
  }

  String _extractVoiceKeyword(VoiceParseResult result) {
    var remaining = result.rawText;

    // Remove amount patterns
    remaining = remaining.replaceAll(
      RegExp(r'[¥￥]?\s*[\d,]+\.?\d*\s*(円|元|ドル)?'),
      '',
    );

    // Remove merchant name if matched
    if (result.merchantName != null) {
      remaining = remaining.replaceFirst(result.merchantName!, '');
    }

    // Remove Japanese particles
    remaining = remaining.replaceAll(RegExp(r'[のにでをはがもへとや]'), '');

    // Remove Chinese particles
    remaining = remaining.replaceAll(RegExp(r'[的了吗呢吧啊呀哦]'), '');

    return remaining.trim();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Watch locale to trigger rebuild on locale change (formatting downstream).
    ref.watch(currentLocaleProvider);

    // Watch voiceLocaleIdProvider so the screen rebuilds when the user changes
    // the voice language in Settings. The current value is stored in
    // _voiceLocaleId for synchronous use in _startRecording().
    final voiceLocaleAsync = ref.watch(voiceLocaleIdProvider);
    if (voiceLocaleAsync case AsyncData(:final value)) {
      _voiceLocaleId = value;
    }

    // BLOCKER B-2: AmountDisplay takes a String — render the host-cache mirror.
    final amountStr = _hostAmount > 0 ? _hostAmount.toString() : '';
    // Voice-correction learning keyword (Phase 18 D-09 hook) — only meaningful
    // when a parse result exists. Keep the helper signature untouched; pass
    // null until a parse runs.
    final voiceKeyword = _parseResult != null
        ? _extractVoiceKeyword(_parseResult!)
        : null;

    return Scaffold(
      backgroundColor: isDark
          ? AppColorsDark.background
          : AppColors.backgroundWarm,
      appBar: AppBar(
        backgroundColor: isDark ? AppColorsDark.card : AppColors.card,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: isDark ? AppColorsDark.textPrimary : AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.addTransaction,
          style: AppTextStyles.headlineMedium.copyWith(
            color: isDark ? AppColorsDark.textPrimary : AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),

          // Input mode tabs (Voice active)
          EntryModeSwitcher(
            selectedMode: InputMode.voice,
            bookId: widget.bookId,
          ),

          const SizedBox(height: 8),

          // D-10: AmountDisplay above the form — tap opens the modal sheet
          // for amount editing. Reads from the host-cache mirror (B-2).
          GestureDetector(
            onTap: () async {
              await AmountEditBottomSheet.show(
                context,
                initialAmount: _hostAmount,
                onConfirm: (value) {
                  // Push into the form AND update the host-cache mirror so
                  // the AmountDisplay and _canSave predicate stay aligned.
                  _formKey.currentState?.updateAmount(value);
                  if (!mounted) return;
                  setState(() => _hostAmount = value);
                },
              );
            },
            behavior: HitTestBehavior.opaque,
            child: AmountDisplay(amount: amountStr),
          ),

          // D-01: scrollable embedded form replaces the read-only result card.
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: TransactionDetailsForm(
                key: _formKey,
                config: TransactionDetailsFormConfig.$new(
                  bookId: widget.bookId,
                  // All initial fields null — voice batch-fills via
                  // _formKey.currentState!.updateXxx on long-press release.
                  voiceKeyword: voiceKeyword,
                  entrySource: EntrySource.voice,
                  merchantFocusNode: _merchantFocus,
                  noteFocusNode: _noteFocus,
                ),
              ),
            ),
          ),

          // Waveform
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: VoiceWaveform(
              soundLevel: _soundLevel,
              isActive: _isRecording,
              color: AppColors.survival,
            ),
          ),

          // D-03 / D-04: hold-to-record mic button. duration: Duration.zero
          // makes LongPress fire on press-down; the 300 ms misfire threshold
          // lives inside _onLongPressEnd (not here, so it's visible at the
          // gesture-decision boundary).
          RawGestureDetector(
            gestures: <Type, GestureRecognizerFactory>{
              LongPressGestureRecognizer:
                  GestureRecognizerFactoryWithHandlers<
                    LongPressGestureRecognizer
                  >(
                    () => LongPressGestureRecognizer(
                      duration: Duration.zero,
                      debugOwner: this,
                    ),
                    (LongPressGestureRecognizer instance) {
                      instance
                        ..onLongPressStart = _onLongPressStart
                        ..onLongPressEnd = _onLongPressEnd
                        ..onLongPressCancel = _onLongPressCancel;
                    },
                  ),
            },
            child: AnimatedContainer(
              key: const ValueKey('voice-mic-button'),
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeInOut,
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                // D-04: shape stays rectangle; borderRadius interpolates 36→16.
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(_isRecording ? 16 : 36),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: _isRecording
                      ? const [
                          AppColors.recordingGradientStart,
                          AppColors.recordingGradientEnd,
                        ]
                      : const [
                          AppColors.actionGradientStart,
                          AppColors.actionGradientEnd,
                        ],
                ),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.actionShadow,
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              // D-04: Icon stays Icons.mic in BOTH states (no Mic→Stop swap).
              child: const Icon(Icons.mic, color: Colors.white, size: 32),
            ),
          ),

          const SizedBox(height: 12),

          // D-06: caption cross-fades between idle and recording.
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: Text(
              _isRecording ? l10n.recording : l10n.holdToRecord,
              key: ValueKey(_isRecording),
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark
                    ? AppColorsDark.textTertiary
                    : AppColors.textTertiary,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // D-11: Save button — gated by _canSave (host-cache, not currentState).
          Padding(
            key: const ValueKey('voice-save-button'),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: _canSave
                      ? const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.actionGradientStart,
                            AppColors.actionGradientEnd,
                          ],
                        )
                      : LinearGradient(
                          colors: [
                            AppColors.actionGradientStart.withValues(
                              alpha: 0.4,
                            ),
                            AppColors.actionGradientEnd.withValues(alpha: 0.4),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _canSave ? _onSavePressed : null,
                    borderRadius: BorderRadius.circular(14),
                    child: Center(
                      child: Text(
                        l10n.save,
                        style: AppTextStyles.titleLarge.copyWith(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pitfall 7 (RESEARCH Open Q1): app-pause must cancel an in-progress
    // recording, otherwise the mic stays "live" with no user awareness.
    if (state == AppLifecycleState.paused && _isRecording) {
      _cancelRecordingAndDiscard();
    }
  }

  /// D-09: text-field focus during recording auto-stops the session.
  /// Mic returns to idle; no batch-fill of the form (caller controls modality).
  void _handleFocusChange() {
    final hasTextFocus = _merchantFocus.hasFocus || _noteFocus.hasFocus;
    if (hasTextFocus && _isRecording) {
      _cancelRecordingAndDiscard();
    }
  }

  @override
  void dispose() {
    _parseDebounce?.cancel();
    _amountMerger?.dispose();
    _amountMerger = null;
    _speechService.cancel();
    // Phase 22: unregister lifecycle observer + dispose FocusNodes.
    WidgetsBinding.instance.removeObserver(this);
    _merchantFocus.dispose();
    _noteFocus.dispose();
    super.dispose();
  }
}

