import 'dart:async';

import 'package:flutter/gestures.dart'
    show LongPressGestureRecognizer, LongPressStartDetails, LongPressEndDetails;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../features/accounting/domain/models/transaction.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../infrastructure/i18n/formatters/number_formatter.dart';
import '../../../../shared/widgets/feedback_toast.dart';
import '../../../../application/voice/start_speech_recognition_use_case.dart';
import '../../../settings/presentation/providers/state_locale.dart';
import '../../../settings/presentation/providers/state_settings.dart';
import '../../domain/models/entry_source.dart';
import '../../domain/models/transaction_details_form_config.dart';
import '../widgets/amount_display.dart';
import '../widgets/amount_edit_bottom_sheet.dart';
import '../widgets/entry_mode_switcher.dart';
import '../widgets/input_mode_tabs.dart';
import '../widgets/transaction_details_form.dart';
import '../../../../shared/widgets/soft_toast.dart';
import '../widgets/voice_waveform.dart';
import 'voice_input_screen_helpers.dart';
import 'voice_locale_readiness_mixin.dart';
import 'voice_ptt_session_mixin.dart';
import 'voice_recognition_event_handler_mixin.dart';

/// Voice input screen for creating transactions through natural language speech.
///
/// Quick task 260622-nhs (D-3): the recording/transcription/parse/merger/
/// foreign-triple/satisfaction logic is now owned by [VoicePttSessionMixin]
/// (reuse-not-rewrite) — this screen only renders the legacy voice UI wired to
/// the mixin's session. It is retained but no longer the primary voice entry
/// (the single-page push-to-talk bar on the manual screen is) — see Task 4.
class VoiceInputScreen extends ConsumerStatefulWidget {
  const VoiceInputScreen({
    super.key,
    required this.bookId,
    this.speechService,
    this.continuousMode = false,
  });

  final String bookId;
  final StartSpeechRecognitionUseCase? speechService;

  /// 260614-iww: when true the screen stays open after each save (continuous
  /// entry); when false a save pops back to the previous page (single-tap).
  final bool continuousMode;

  @override
  ConsumerState<VoiceInputScreen> createState() => _VoiceInputScreenState();
}

class _VoiceInputScreenState extends ConsumerState<VoiceInputScreen>
    with
        WidgetsBindingObserver,
        VoiceRecognitionEventHandlerMixin,
        VoiceLocaleReadinessMixin,
        VoicePttSessionMixin {
  // ── Phase 22: embedded form integration (D-01) ──

  final _formKey = GlobalKey<TransactionDetailsFormState>();

  late final FocusNode _merchantFocus;
  late final FocusNode _noteFocus;

  /// Submit-in-flight flag for the Save button.
  bool _isSubmitting = false;

  /// Host-cache mirror of the form's amount state (BLOCKER B-2 resolution).
  int _hostAmount = 0;

  /// Effective voice locale (updated reactively from voiceLocaleIdProvider).
  String _voiceLocaleId = 'zh-CN';

  bool get _canSave => !_isSubmitting;

  // ── VoicePttSessionMixin abstract contract ──────────────────────────────────

  @override
  TransactionDetailsFormState? get pttFormState => _formKey.currentState;
  @override
  StartSpeechRecognitionUseCase? get pttInjectedSpeechService =>
      widget.speechService;
  @override
  String get pttVoiceLocaleId => _voiceLocaleId;
  @override
  void onPttSessionChanged(VoidCallback apply) {
    if (mounted) setState(apply);
  }

  /// After a PTT batch-fill, mirror the filled amount into the host cache so
  /// AmountDisplay renders it (B-2 precedent).
  @override
  void onPttCommitted() {
    if (!mounted) return;
    setState(() => _hostAmount = pttLastFilledAmount);
  }

  @override
  void onVoiceLocaleResolved(String localeId) => _voiceLocaleId = localeId;

  @override
  void initState() {
    super.initState();

    _merchantFocus = FocusNode()..addListener(_handleFocusChange);
    _noteFocus = FocusNode()..addListener(_handleFocusChange);

    WidgetsBinding.instance.addObserver(this);

    _initSpeechService();
  }

  Future<void> _initSpeechService() async {
    final available = await initPttSpeechService();
    if (mounted && !available) {
      _showPermissionError();
    }
    // Phase 23 D-07 (WR-01) cold-start gate — owned by VoiceLocaleReadinessMixin.
    initLocaleReadiness();
  }

  void _showPermissionError() {
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
    if (!pttServiceInitialized || !isLocaleReady || pttIsRecording) return;
    onPttHoldStart();
  }

  void _onLongPressEnd(LongPressEndDetails details) => onPttHoldEnd();

  void _onLongPressCancel() => onPttHoldCancel();

  /// Save handler — delegates to the embedded form's submit() with the same
  /// try/finally + result.when shape as before.
  Future<void> _onSavePressed() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final result = await _formKey.currentState!.submit();
      if (!mounted) return;
      result.when(
        success: (tx) {
          if (widget.continuousMode) {
            void keepGoing() {
              if (!mounted) return;
              showSuccessFeedback(
                context,
                S.of(context).continuousKeepGoing,
                duration: const Duration(seconds: 5),
                actionLabel: S.of(context).recordingExitLink,
                onAction: () {
                  if (!mounted) return;
                  Navigator.of(context).pop();
                },
              );
              _resetForContinuousEntry();
            }

            if (tx.ledgerType == LedgerType.joy) {
              _formKey.currentState?.waitForCelebrationDismissed().then((_) {
                keepGoing();
              });
            } else {
              keepGoing();
            }
          } else {
            showSuccessFeedback(context, S.of(context).entrySavedDone);
            if (tx.ledgerType == LedgerType.joy) {
              _formKey.currentState?.waitForCelebrationDismissed().then((_) {
                if (!mounted) return;
                Navigator.of(context).pop();
              });
            } else {
              Navigator.of(context).pop();
            }
          }
        },
        validationError: (msg) {
          showErrorFeedback(context, msg);
        },
        persistError: (msg) {
          showErrorFeedback(context, msg);
        },
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// 260614-iww: reset the voice form in place after a continuous-mode save.
  Future<void> _resetForContinuousEntry() async {
    if (!mounted) return;
    final state = _formKey.currentState;
    state?.updateAmount(0);
    state?.updateCurrencyTriple(
      originalCurrency: null,
      originalAmount: null,
      appliedRate: null,
    );
    state?.updateMerchant('');
    state?.updateNote('');
    state?.updateDate(DateTime.now());
    if (!mounted) return;
    setState(() => _hostAmount = 0);
    resetPttSessionState();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final palette = context.palette;
    ref.watch(currentLocaleProvider);

    final voiceLocaleAsync = ref.watch(voiceLocaleIdProvider);
    if (voiceLocaleAsync case AsyncData(:final value)) {
      _voiceLocaleId = value;
    }

    final amountStr = _hostAmount > 0 ? _hostAmount.toString() : '';
    final pillLocale =
        ref.watch(currentLocaleProvider).value ?? const Locale('ja');
    final pillSymbol =
        NumberFormatter.formatCurrency(0, pttDisplayCurrency, pillLocale)
            .replaceAll(RegExp(r'[\d.,\s]'), '');

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.card,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: palette.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.addTransaction,
          style: AppTextStyles.headlineMedium.copyWith(
            color: palette.textPrimary,
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
            continuousMode: widget.continuousMode,
          ),

          const SizedBox(height: 8),

          GestureDetector(
            onTap: () async {
              await AmountEditBottomSheet.show(
                context,
                initialAmount: _hostAmount,
                onConfirm: (value) {
                  _formKey.currentState?.updateAmount(value);
                  if (!mounted) return;
                  setState(() => _hostAmount = value);
                },
              );
            },
            behavior: HitTestBehavior.opaque,
            child: AmountDisplay(
              amount: amountStr,
              currencySymbol: pillSymbol,
              currencyLabel: pttDisplayCurrency,
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: TransactionDetailsForm(
                key: _formKey,
                config: TransactionDetailsFormConfig.$new(
                  bookId: widget.bookId,
                  voiceKeyword: _voiceKeyword,
                  entrySource: EntrySource.voice,
                ),
                merchantFocusNode: _merchantFocus,
                noteFocusNode: _noteFocus,
              ),
            ),
          ),

          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              color: palette.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: palette.borderDefault,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                    child: SizedBox(
                      key: const ValueKey('voice-transcript'),
                      height: 28,
                      child: Center(
                        child: Text(
                          pttPartialText.isNotEmpty
                              ? pttPartialText
                              : pttFinalText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.caption.copyWith(
                            color: pttPartialText.isNotEmpty
                                ? palette.textTertiary
                                : palette.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: VoiceWaveform(
                      soundLevel: pttSoundLevel,
                      isActive: pttIsRecording,
                      color: palette.daily,
                    ),
                  ),

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
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.circular(
                          pttIsRecording ? 16 : 36,
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: pttIsRecording
                              ? [
                                  palette.recordingGradientStart,
                                  palette.recordingGradientEnd,
                                ]
                              : [
                                  palette.fabGradientStart,
                                  palette.fabGradientEnd,
                                ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: palette.actionShadow,
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.mic,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    child: Text(
                      pttIsRecording ? l10n.recording : l10n.holdToRecord,
                      key: ValueKey(pttIsRecording),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: palette.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            key: const ValueKey('voice-save-button'),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: _canSave
                      ? LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            palette.fabGradientStart,
                            palette.fabGradientEnd,
                          ],
                        )
                      : LinearGradient(
                          colors: [
                            palette.fabGradientStart.withValues(
                              alpha: 0.4,
                            ),
                            palette.fabGradientEnd.withValues(alpha: 0.4),
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
                        l10n.record,
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

  /// Voice-correction learning keyword (Phase 18 D-09 hook) — only meaningful
  /// when a parse result exists. The mixin owns the parse result; the screen
  /// reads it through [pttParseResult] for the form's voiceKeyword config.
  String? get _voiceKeyword =>
      pttParseResult != null ? extractVoiceKeyword(pttParseResult!) : null;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && pttIsRecording) {
      cancelPttSessionAndDiscard();
    }
  }

  /// D-09: text-field focus during recording auto-stops the session.
  void _handleFocusChange() {
    final hasTextFocus = _merchantFocus.hasFocus || _noteFocus.hasFocus;
    if (hasTextFocus && pttIsRecording) {
      cancelPttSessionAndDiscard();
    }
  }

  @override
  void dispose() {
    disposePttSession();
    WidgetsBinding.instance.removeObserver(this);
    _merchantFocus.dispose();
    _noteFocus.dispose();
    super.dispose();
  }
}
