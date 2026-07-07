import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../currency/domain/models/rate_result.dart';
import '../../../../application/voice/start_speech_recognition_use_case.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../infrastructure/i18n/formatters/number_formatter.dart';
import '../../../../shared/utils/currency_conversion.dart';
import '../../../settings/presentation/providers/state_locale.dart';
import '../../domain/models/category.dart';
import '../../domain/models/entry_source.dart';
import '../../domain/models/transaction_details_form_config.dart';
import '../providers/state_recent_currency.dart';
import '../providers/repository_providers.dart';
import '../widgets/amount_display.dart';
import '../widgets/amount_input_controller.dart';
import '../widgets/conversion_preview_panel.dart';
import '../widgets/currency_linked_edit_fields.dart';
import '../widgets/currency_selector_sheet.dart';
import '../widgets/hold_to_talk_bar.dart';
import '../../../../shared/widgets/feedback_toast.dart';
import '../widgets/keyboard_toolbar.dart';
import '../widgets/smart_keyboard.dart';
import '../widgets/transaction_details_form.dart';
import '../widgets/voice_listening_overlay.dart' show VoiceRecordPanel;
import 'manual_one_step_foreign_card.dart';
import 'manual_one_step_snapshot.dart';
import 'voice_locale_readiness_mixin.dart';
import 'voice_ptt_session_mixin.dart';
import 'voice_recognition_event_handler_mixin.dart';

part 'manual_one_step_voice_wiring.dart';
part 'manual_one_step_keypad.dart';
part 'manual_one_step_currency.dart';
part 'manual_one_step_save.dart';

/// WR-01: returns true when a foreign rate-fetch's captured inputs no longer
/// match the screen's current inputs — i.e. the user changed the currency,
/// amount, or DATE while the rate fetch was in flight. The caller must then
/// withhold the push so a STALE-date (or stale-currency/amount) rate is never
/// persisted against a different timestamp (ADR-021 — currency fields are
/// excluded from the hash chain, so such a mismatch is undetectable once saved).
///
/// Extracted as a pure top-level function (vs. an inline `||` chain) so the
/// guard — especially the WR-01 date dimension — is independently testable.
@visibleForTesting
bool foreignPushIsStale({
  required String capturedCurrency,
  required String currentCurrency,
  required int capturedMinorUnits,
  required int currentMinorUnits,
  required DateTime capturedDate,
  required DateTime currentDate,
}) {
  return capturedCurrency != currentCurrency ||
      capturedMinorUnits != currentMinorUnits ||
      capturedDate != currentDate;
}

/// Single-screen manual transaction entry replacing the legacy two-screen flow
/// (manual entry hub → confirmation screen).
///
/// Layout (top-to-bottom — 260622-nhs single-page push-to-talk):
///   AppBar → AmountDisplay → scrollable details form
///   → AnimatedSlide(SmartKeyboard) → HoldToTalkBar
///
/// Focus state machine (D-05/D-10/D-13):
///   - SmartKeyboard is visible when `_amountFocused && !_isTextFieldFocused`
///   - TextField focus tracked via per-host FocusNode listeners (P19-W3)
///   - KeyboardToolbar floats over soft keyboard (D-11)
///
/// Save guard (P19-W1): both save entry points are disabled until
/// `_selectedCategory != null` to prevent stray DB writes during the
/// async default-category init race.
///
/// See Phase 19 CONTEXT D-01..D-13, D-24 for full decision rationale.
class ManualOneStepScreen extends ConsumerStatefulWidget {
  const ManualOneStepScreen({
    super.key,
    required this.bookId,
    this.initialAmount,
    this.initialCategory,
    this.initialParentCategory,
    this.initialDate,
    this.initialMerchant,
    this.initialSatisfaction,
    this.voiceKeyword,
    this.entrySource = EntrySource.manual,
    this.continuousMode = false,
    this.speechService,
  });

  final String bookId;
  final int? initialAmount;
  final Category? initialCategory;
  final Category? initialParentCategory;
  final DateTime? initialDate;
  final String? initialMerchant;
  final int? initialSatisfaction;
  final String? voiceKeyword;
  final EntrySource entrySource;

  /// 260614-iww: when true the screen stays open after each save (continuous
  /// entry, opened via FAB long-press); when false a save pops back to the
  /// previous page (single-tap entry).
  final bool continuousMode;

  /// 260622-nhs: injectable speech use case for the single-page PTT bar (tests
  /// pass a fake; production builds it from the provider via the mixin).
  final StartSpeechRecognitionUseCase? speechService;

  @override
  ConsumerState<ManualOneStepScreen> createState() =>
      _ManualOneStepScreenState();
}

class _ManualOneStepScreenState extends ConsumerState<ManualOneStepScreen>
    with
        WidgetsBindingObserver,
        VoiceRecognitionEventHandlerMixin,
        VoiceLocaleReadinessMixin,
        VoicePttSessionMixin {
  final _formKey = GlobalKey<TransactionDetailsFormState>();

  late final FocusNode _merchantFocus;
  late final FocusNode _noteFocus;

  String _amount = '';
  bool _amountFocused = true;
  bool _isTextFieldFocused = false;
  bool _isSubmitting = false;

  /// 260622-nhs (D-2 / T-nhs-03): the synchronous voice-locale mirror, and the
  /// provenance flag flipped true after a PTT batch-fill so the saved row stamps
  /// `EntrySource.voice`. Reset to false whenever the amount is cleared.
  String _voiceLocaleId = 'zh-CN';
  bool _lastFillWasVoice = false;

  /// 260622-nhs R2 (D-2 reset-restore): the pre-speech form snapshot taken when
  /// the user taps 「语音记录」. Null when no voice session is open. The modal's
  /// 「重置·恢复账目」 button rolls the form back to this snapshot.
  ManualEntrySnapshot? _voiceSnapshot;

  /// 260622-nhs R6 (BUG 1): true while the inline voice panel is open. Panel
  /// visibility is gated on THIS, NOT `pttIsRecording` — the one-shot recognizer
  /// stops after a single listen, but the panel must STAY (showing 「停止聆听」 +
  /// the tap-reset hint) until the user taps the blank area to exit.
  bool _voiceModalOpen = false;

  // ── VoicePttSessionMixin contract ─────────────────────────────────────────

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

  /// quick-260707-kfb A2: the sole sanctioned repaint hook for the keypad /
  /// currency / save `part` extensions. `setState` is `@protected` and cannot be
  /// called from an extension, so the moved `setState(...)` bodies call this
  /// instead — behavior-identical (the added `mounted` guard is always true in
  /// the synchronous handlers and already present in the async ones).
  void _rebuild(VoidCallback apply) {
    if (mounted) setState(apply);
  }

  // voice-consolidation P1-7 (R2): body moved verbatim to
  // [_mirrorPttFillIntoKeypad] in `manual_one_step_voice_wiring.dart`; the
  // `@override` must stay in the class, so it delegates.
  @override
  void onPttCommitted() => _mirrorPttFillIntoKeypad();

  @override
  void onVoiceLocaleResolved(String localeId) => _voiceLocaleId = localeId;

  // Phase 42 (CURR-01/04/05): host owns the currency-aware decimal input.
  // [_controller] replaces the old inline 4-decimal cap in _onDigit/_onDot;
  // its [text] is mirrored into [_amount] so AmountDisplay + save validation
  // keep working unchanged. [_currency] starts at 'JPY' — the CURR-04 invariant
  // path: no rate fetch, no preview, no annotation, dot gated off (decimals==0).
  late final AmountInputController _controller = AmountInputController(
    decimals: currencyFractionDigitsFor(_currency),
  );
  String _currency = 'JPY';

  bool get _isForeign => _currency.toUpperCase() != 'JPY';

  // Quick 260613-ufn (D-1): the add screen now renders the unified
  // CurrencyLinkedEditFields card whose 汇率 row is EDITABLE. When the user
  // hand-edits the rate this holds the override string so `_pushForeignTriple`
  // persists the edited rate (manual override) instead of the auto-resolved
  // one. Cleared whenever the currency or date changes (the override is keyed
  // to a specific currency+date rate; a fresh re-resolve supersedes it).
  String? _manualForeignRate;

  /// Entered amount in the active currency's MINOR units (cents for USD,
  /// whole units for JPY). Derived from the controller text via the currency's
  /// subunit factor — the single input into [convertToJpy].
  int get _originalMinorUnits {
    final value = double.tryParse(_controller.text) ?? 0.0;
    return (value * subunitToUnitFor(_currency)).round();
  }

  Category? _selectedCategory;
  Category? _selectedParentCategory;
  Map<String, Category> _categoryById = {};
  late DateTime _selectedDate;

  // P19-W1: safe guard — both save entry points are disabled until category
  // resolves. Callers pass `isSubmitting: _isSubmitting || !_canSave` to
  // KeyboardToolbar and `onNext: _trySave` to SmartKeyboard (which internally
  // shows a toast and returns if !_canSave).
  bool get _canSave => _selectedCategory != null && !_isSubmitting;

  // D-05: SmartKeyboard slides off-screen when any TextField is focused.
  bool get _showSmartKeypad => _amountFocused && !_isTextFieldFocused;

  @override
  void initState() {
    super.initState();

    // P19-W3: per-host FocusNodes wired through the form config so the form's
    // TextFields use them. Listeners update _isTextFieldFocused.
    _merchantFocus = FocusNode()..addListener(_handleFocusChange);
    _noteFocus = FocusNode()..addListener(_handleFocusChange);

    // 260622-nhs: single-page push-to-talk. Observe app lifecycle so a paused
    // app cancels any in-progress recording (T-nhs-02), and init the speech
    // service + locale-readiness gate via the shared mixin.
    WidgetsBinding.instance.addObserver(this);
    initPttSpeechService();
    initLocaleReadiness();

    // Initialize amount string from widget param. The initial amount is a JPY
    // integer (foreign pre-fill is not a v1.7 entry path) — seed both the raw
    // string and the controller so digit edits continue from it.
    if (widget.initialAmount != null && widget.initialAmount! > 0) {
      _amount = widget.initialAmount!.toString();
      for (final ch in _amount.split('')) {
        _controller.onDigit(ch);
      }
    }

    // Initialize date
    _selectedDate = widget.initialDate ?? DateTime.now();

    // Initialize category — prefer pre-seeded, otherwise load defaults async.
    if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory;
      _selectedParentCategory = widget.initialParentCategory;
      if (_selectedCategory != null) {
        _categoryById[_selectedCategory!.id] = _selectedCategory!;
      }
      if (_selectedParentCategory != null) {
        _categoryById[_selectedParentCategory!.id] = _selectedParentCategory!;
      }
    } else {
      _initializeDefaultCategory();
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // T-nhs-02: app-pause must cancel an in-progress recording.
    if (state == AppLifecycleState.paused && pttIsRecording) {
      cancelPttSessionAndDiscard();
    }
  }

  // ── Category init (ported verbatim from transaction_entry_screen.dart:52-82, D-24) ──

  Future<void> _initializeDefaultCategory() async {
    final repo = ref.read(categoryRepositoryProvider);
    final allCategories = await repo.findActive();

    final categoryById = <String, Category>{
      for (final category in allCategories) category.id: category,
    };

    final l1Categories = allCategories.where((c) => c.level == 1).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final defaultL1 = l1Categories.isNotEmpty ? l1Categories.first : null;

    Category? defaultL2;
    if (defaultL1 != null) {
      final l2UnderSelectedL1 =
          allCategories
              .where((c) => c.level == 2 && c.parentId == defaultL1.id)
              .toList()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      if (l2UnderSelectedL1.isNotEmpty) {
        defaultL2 = l2UnderSelectedL1.first;
      }
    }

    if (!mounted) return;
    setState(() {
      _categoryById = categoryById;
      _selectedParentCategory = defaultL1;
      _selectedCategory = defaultL2;
    });
    // P19-W1: _canSave flips to true here (assuming !_isSubmitting) — the
    // SmartKeyboard Save key and KeyboardToolbar Save button become tappable.
    //
    // 260603-ti2: the embedded form reads `initialCategory` only in its own
    // initState, which already ran (with null) before this async load resolved
    // — so the setState rebuild above never reaches it and the chip would stay
    // on "请选择类别". Push the resolved default in via the form's imperative API
    // (idempotent + resolves ledger type), mirroring the picker-result and
    // voice-fill paths. `_formKey.currentState` is non-null here because the
    // first build completed during the awaited repo read above.
    if (defaultL2 != null) {
      _formKey.currentState?.updateCategory(defaultL2, defaultL1);
    }
  }

  // ── FocusNode listener (P19-W3 — per-host FocusNodes, no Focus walker) ──

  void _handleFocusChange() {
    final hasTextFocus = _merchantFocus.hasFocus || _noteFocus.hasFocus;
    // Equality guard: prevents rebuild storms during soft-keyboard animation.
    if (hasTextFocus == _isTextFieldFocused) return;
    setState(() {
      _isTextFieldFocused = hasTextFocus;
      // Mirror text focus: when IME opens we yield amount focus; when IME
      // dismisses (via toolbar 完成, IME ✓, or onTapOutside) we reclaim it so
      // SmartKeyboard reappears automatically instead of leaving a blank gap.
      _amountFocused = !hasTextFocus;
    });
  }

  // ── Amount tap handler (D-10) ──

  /// Item 4 (260526-j98) / D-10: reclaim amount focus so the SmartKeyboard
  /// reappears. Shared by `_onAmountTap` and the form's `onPickerDismissed`
  /// callback (fired after the date/category picker dismisses).
  void _restoreKeypadFocus() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (mounted) setState(() => _amountFocused = true);
    // Unfocusing the text field triggers _handleFocusChange →
    // _isTextFieldFocused = false → _showSmartKeypad = true.
  }

  // quick-260707-kfb A2: the keypad handlers (_onAmountTap / _onDigit /
  // _onDoubleZero / _onDot / _onDelete / _onClear / _syncAmountToForm) moved
  // verbatim to `manual_one_step_keypad.dart`; the currency / foreign-triple
  // handlers (_pushForeignTriple / _rateStringOf / _onRateSignal /
  // _onFormDateChanged / _onForeignRateEdited / _onCurrencyTap /
  // _onCurrencySelected) to `manual_one_step_currency.dart`; and the save path
  // (_trySave / _save / _resetForContinuousEntry) to `manual_one_step_save.dart`
  // — all as same-library `part` extensions on _ManualOneStepScreenState.

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    // Watch locale provider to trigger rebuild on locale change.
    final locale = ref.watch(currentLocaleProvider).value ?? const Locale('ja');
    final palette = context.palette;

    // Currency symbol for the active currency — derived the same way the
    // selector sheet does (strip digits/separators from a formatted zero) so the
    // display, keypad, and sheet all show the same glyph.
    final currencySymbol = NumberFormatter.formatCurrency(
      0,
      _currency,
      locale,
    ).replaceAll(RegExp(r'[\d.,\s]'), '');

    final viewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;
    // Item 3 (260526-j98): bottom padding clears IME only — the SmartKeyboard
    // sits AFTER the Expanded in the Column so it naturally bounds the
    // scrollable from below. 32dp = one comfortable rest gap per user spec.
    final scrollPaddingBottom = math.max(viewInsetsBottom, 32.0);

    return Scaffold(
      key: const ValueKey('manual-one-step-screen'),
      // D-13: manual control prevents layout jitter during AnimatedSlide.
      resizeToAvoidBottomInset: false,
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.card,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: palette.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.addTransaction,
          style: AppTextStyles.headlineMedium.copyWith(
            color: palette.textPrimary,
          ),
        ),
        centerTitle: true,
        // 260614-iww: the leading AppBar close (×) already exits continuous
        // mode; no separate right-side text exit button (per user request).
      ),
      body: Stack(
        children: [
          // Main content column
          Column(
            children: [
              const SizedBox(height: 8),

              // 260614-iww: continuous-mode hint explaining the exit affordance.
              if (widget.continuousMode)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 2,
                  ),
                  child: Text(
                    l10n.continuousExitHint,
                    style: AppTextStyles.caption.copyWith(
                      color: palette.textTertiary,
                    ),
                  ),
                ),

              // 260622-nhs (D-3): the 手工/语音 mode Tab is gone — manual keypad is
              // the only resident state; voice is the push-to-talk bar below the
              // keypad. No mode switching, no page replacement.
              const SizedBox(height: 8),

              // Amount display — tap to activate SmartKeyboard (D-10)
              GestureDetector(
                onTap: _onAmountTap,
                behavior: HitTestBehavior.opaque,
                child: AmountDisplay(
                  amount: _amount,
                  onClear: _onClear,
                  currencySymbol: currencySymbol,
                  currencyLabel: _currency,
                ),
              ),

              // Scrollable details section with smart bottom padding (D-13)
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, scrollPaddingBottom),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Quick 260613-wuv (WUV-01): the foreign conversion card
                      // now scrolls WITH the form (only the AmountDisplay stays
                      // pinned) and is wrapped in the same
                      // card chrome the EDIT screen uses (_formCard: palette.card
                      // / radius 14 / palette.borderDefault). The unified
                      // CurrencyLinkedEditFields renders 汇率 (editable) / 日元
                      // （换算）(derived) / 汇率日期 (non-clickable + staleness).
                      // Quick 260613-wuv2: fed the LIVE amount. The rate provider
                      // is keyed only on (currency, date) now, so amount changes
                      // never re-resolve the rate — the same cached card stays
                      // mounted and only its derived-JPY number updates (no
                      // whole-card spinner flash). Mounted ONLY for foreign rows
                      // with an amount; the JPY path stays byte-identical (CURR-04).
                      if (_isForeign && _originalMinorUnits > 0) ...[
                        Container(
                          decoration: BoxDecoration(
                            color: palette.card,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: palette.borderDefault),
                          ),
                          child: AddScreenForeignCard(
                            currency: _currency,
                            date: _selectedDate,
                            originalMinorUnits: _originalMinorUnits,
                            manualRateOverride: _manualForeignRate,
                            onRateEdited: _onForeignRateEdited,
                            onSignal: _onRateSignal,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      TransactionDetailsForm(
                        key: _formKey,
                        config: TransactionDetailsFormConfig.$new(
                          bookId: widget.bookId,
                          initialAmount: widget.initialAmount,
                          initialCategory: _selectedCategory,
                          initialParentCategory: _selectedParentCategory,
                          initialDate: _selectedDate,
                          initialMerchant: widget.initialMerchant,
                          initialSatisfaction: widget.initialSatisfaction,
                          voiceKeyword: widget.voiceKeyword,
                          // 260622-nhs (T-nhs-03): a PTT-filled row stamps voice
                          // provenance; a pure keypad row keeps widget.entrySource
                          // (manual). submit() reads entrySource from this live
                          // config, so the flag survives the single-page merge.
                          entrySource: _lastFillWasVoice
                              ? EntrySource.voice
                              : widget.entrySource,
                        ),
                        // P19-W3: per-host FocusNodes so _handleFocusChange fires.
                        merchantFocusNode: _merchantFocus,
                        noteFocusNode: _noteFocus,
                        // Item 4 (260526-j98): reclaim amount focus after date /
                        // category picker dismisses so SmartKeyboard reappears.
                        onPickerDismissed: _restoreKeypadFocus,
                        // Quick 260613-ufn (D-4): keep the screen's _selectedDate
                        // in lock-step with the form's date picker so the keyed
                        // rate provider re-resolves the rate for the new date.
                        onDateChanged: _onFormDateChanged,
                      ),
                    ],
                  ),
                ),
              ),

              // D-05: SmartKeyboard slides off-screen when a TextField is
              // focused. 260622-nhs R3/R6: the bottom slot swaps IN PLACE — while
              // the voice modal is open (`_voiceModalOpen`, R6 BUG 1: gated on
              // this NOT `pttIsRecording`, so the one-shot recognizer stopping
              // does NOT snap the keypad back) the inline VoiceRecordPanel
              // occupies the keypad's footprint; otherwise the 「语音记录」 strip +
              // SmartKeyboard. The SmartKeyboard's built-in 24dp bottom padding
              // clears the home indicator (no SafeArea wrapper).
              AnimatedSlide(
                offset: Offset(0, _showSmartKeypad ? 0 : 1),
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                child: _voiceModalOpen
                    // voice-consolidation P1-7 (R2): panel construction moved
                    // verbatim to `manual_one_step_voice_wiring.dart`.
                    ? _buildVoicePanel()
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 260622-nhs R2: tap 「语音记录」 (line mic) to raise the
                          // inline auto-fill panel. Above the keypad; hidden with
                          // the keypad when a TextField is focused.
                          if (_showSmartKeypad)
                            VoiceRecordBar(onTap: _onVoiceRecordTap),
                          SmartKeyboard(
                            onDigit: _onDigit,
                            onDoubleZero: _onDoubleZero,
                            // D-06: gate the dot key on the active currency's
                            // minor unit. 0-decimal currencies (JPY/KRW) pass
                            // null → disabled blank tile; JPY keeps onDot:null.
                            onDot: _controller.decimals > 0 ? _onDot : null,
                            onDelete: _onDelete,
                            // P19-W1: route through _trySave for category guard.
                            onNext: _trySave,
                            actionLabel: l10n.record,
                            currencyLabel: _currency,
                            currencySymbol: currencySymbol,
                            // CURR-01: open the currency selector sheet.
                            onCurrencyTap: _onCurrencyTap,
                            // 260623-0cj R2: the white VoiceRecordBar above
                            // carries the assembly's top border, so the keypad
                            // omits its own → voice key + keypad read as ONE
                            // unified white surface (一体).
                            showTopBorder: false,
                          ),
                        ],
                      ),
              ),
            ],
          ),

          // D-11/D-13: floating KeyboardToolbar rides on top of soft keyboard.
          // Only visible when a TextField is focused.
          if (_isTextFieldFocused)
            Positioned(
              left: 0,
              right: 0,
              bottom: viewInsetsBottom,
              child: KeyboardToolbar(
                onDone: () => FocusManager.instance.primaryFocus?.unfocus(),
                onSave: _trySave,
                // P19-W1: disable while category null or submit in flight.
                isSubmitting: _isSubmitting || !_canSave,
              ),
            ),
        ],
      ),
    );
  }
}
