import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/currency/rate_result.dart';
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

  @override
  void onPttCommitted() {
    if (!mounted) return;
    // A PTT fill happened — the session mixin already pushed amount / category /
    // merchant / date / satisfaction (+ foreign triple) into _formKey's state.
    // Mirror the booked JPY amount into AmountDisplay's string + the keypad
    // controller so an edit continues from the fill, and flip provenance to
    // voice so the saved row stamps EntrySource.voice (T-nhs-03). Keep the
    // keypad on the JPY native path: the form already carries the real foreign
    // triple for the save, so the headline shows the booked JPY figure (mirrors
    // the legacy voice screen, D-4) without re-driving _syncAmountToForm.
    setState(() {
      _lastFillWasVoice = true;
      final filled = pttLastFilledAmount;
      if (filled > 0) {
        while (_controller.text.isNotEmpty) {
          _controller.onDelete();
        }
        for (final ch in filled.toString().split('')) {
          _controller.onDigit(ch);
        }
        _amount = _controller.text;
      }
    });
  }

  @override
  void onVoiceLocaleResolved(String localeId) => _voiceLocaleId = localeId;

  // Phase 42 (CURR-01/04/05): host owns the currency-aware decimal input.
  // [_controller] replaces the old inline 4-decimal cap in _onDigit/_onDot;
  // its [text] is mirrored into [_amount] so AmountDisplay + save validation
  // keep working unchanged. [_currency] starts at 'JPY' — the CURR-04 invariant
  // path: no rate fetch, no preview, no annotation, dot gated off (decimals==0).
  late final AmountInputController _controller =
      AmountInputController(decimals: currencyFractionDigitsFor(_currency));
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

  // ── 260622-nhs R2: tap-modal voice-record lifecycle ───────────────────────

  /// Tap 「语音记录」: snapshot the form (D-2 reset-restore), then start a
  /// continuous auto-fill listening session and raise the modal.
  void _onVoiceRecordTap() {
    if (!pttServiceInitialized || !isLocaleReady || _voiceModalOpen) return;
    final form = _formKey.currentState;
    if (form != null) {
      _voiceSnapshot = ManualEntrySnapshot.capture(
        amountText: _amount,
        currency: _currency,
        manualForeignRate: _manualForeignRate,
        lastFillWasVoice: _lastFillWasVoice,
        form: form,
      );
    }
    // 260622-nhs R6 (BUG 1): open the modal (panel visibility) independent of
    // the recognizer lifecycle, then start the one-shot listening session.
    setState(() => _voiceModalOpen = true);
    startPttTapSession();
  }

  /// Tap the modal/scrim: stop listening + final fill + close, keep content.
  void _onVoiceModalExit() {
    exitPttTapSession();
    setState(() => _voiceModalOpen = false);
    _voiceSnapshot = null;
  }

  /// 「重置·恢复账目」: restore the form to the pre-speech snapshot, clear the
  /// transcript/merger/parse buffers, and KEEP listening (the user can re-speak).
  void _onVoiceReset() {
    final snapshot = _voiceSnapshot;
    final form = _formKey.currentState;
    if (snapshot != null && form != null) {
      snapshot.restoreForm(form);
      setState(() {
        _currency = snapshot.currency;
        _amount = snapshot.restoreHostAmount(_controller);
        _manualForeignRate = snapshot.manualForeignRate;
        // Revert provenance: if the snapshot was a pure-manual slate, drop the
        // voice flag so a later keypad save stays manual (T-nhs-03).
        _lastFillWasVoice = snapshot.lastFillWasVoice;
      });
    }
    // 260622-nhs R4 (BUG A + BUG B): a reset must CANCEL the recognizer (to
    // clear its accumulated in-window buffer — the R3 buffer-only clear left the
    // iOS recognizer's prior transcript alive, so the next partial re-surfaced
    // the old text) and start a FRESH serialized listening session (the cancel→
    // start is guarded so onStatus can't double-start into a freeze).
    resetPttSessionAndRestart();
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

  void _onAmountTap() {
    _restoreKeypadFocus();
  }

  // ── Digit handlers (Phase 42: delegated to the currency-aware controller) ──
  //
  // Each handler mutates [_controller] (which owns the D-06 dot-gating + D-07
  // decimal cap per currency) then mirrors the result into [_amount] and the
  // form via [_syncAmountToForm]. JPY (decimals==0) behaves byte-identically to
  // the old inline cap: dot gated off, no fractional digits (CURR-04).

  void _onDigit(String digit) {
    _controller.onDigit(digit);
    _syncAmountToForm();
  }

  void _onDoubleZero() {
    _controller.onDoubleZero();
    _syncAmountToForm();
  }

  void _onDot() {
    _controller.onDot();
    _syncAmountToForm();
  }

  void _onDelete() {
    _controller.onDelete();
    _syncAmountToForm();
  }

  void _onClear() {
    while (_controller.text.isNotEmpty) {
      _controller.onDelete();
    }
    // 260622-nhs: clearing the amount drops voice provenance — a row the user
    // re-enters by keypad after a clear is `manual`, not `voice` (T-nhs-03).
    _lastFillWasVoice = false;
    _syncAmountToForm();
  }

  /// Mirror the controller's text into [_amount] (for AmountDisplay + the empty
  /// / zero save guard) and push the converted JPY amount + currency triple into
  /// the form so `submit()` persists the right figures.
  ///
  /// - JPY (CURR-04): the entered figure IS the JPY amount; triple cleared so
  ///   the create use case persists a native JPY row, byte-identical to before.
  /// - Foreign: the JPY amount comes from the single-site [convertToJpy] using
  ///   the rate resolved by the preview's keyed provider; the triple is pushed
  ///   alongside. When no rate has resolved yet the JPY mirror stays 0 and the
  ///   triple is withheld (save is still guarded on a non-empty amount).
  void _syncAmountToForm() {
    setState(() => _amount = _controller.text);
    if (!_isForeign) {
      final parsed = (double.tryParse(_amount) ?? 0.0).round();
      _formKey.currentState?.updateAmount(parsed);
      _formKey.currentState?.updateCurrencyTriple(
        originalCurrency: null,
        originalAmount: null,
        appliedRate: null,
      );
      return;
    }
    // Push the freshly-entered amount/triple immediately so an instant Save
    // persists the correct figure and the staleness guard compares against live
    // input. The FX card now reads the LIVE amount too (Quick 260613-wuv2): with
    // the amount out of the rate provider key, feeding it live refreshes only the
    // derived-JPY number with no whole-card reload, so no debounce is needed.
    _pushForeignTriple();
  }

  /// Resolve the current rate (cache-first via the preview's keyed provider) and
  /// push the converted JPY amount + foreign triple into the form. The rate
  /// figure used here is the SAME one the preview renders (single conversion
  /// site, ADR-020) — guaranteeing preview == persisted.
  Future<void> _pushForeignTriple() async {
    final minorUnits = _originalMinorUnits;
    final currency = _currency;
    final date = _selectedDate;
    if (minorUnits <= 0) {
      _formKey.currentState?.updateAmount(0);
      _formKey.currentState?.updateCurrencyTriple(
        originalCurrency: null,
        originalAmount: null,
        appliedRate: null,
      );
      return;
    }
    // Quick 260613-ufn (D-1): a user-edited (manual-override) rate wins over the
    // auto-resolved one. validateAppliedRate gates a malformed override out so
    // we never persist garbage; an invalid override falls through to the
    // auto-resolved rate (the card surfaces its own inline error).
    final manualRate = _manualForeignRate;
    if (manualRate != null && validateAppliedRate(manualRate) == null) {
      final jpy = convertToJpy(
        originalMinorUnits: minorUnits,
        appliedRate: manualRate,
        subunitToUnit: subunitToUnitFor(currency),
      );
      _formKey.currentState?.updateAmount(jpy);
      _formKey.currentState?.updateCurrencyTriple(
        originalCurrency: currency,
        originalAmount: minorUnits,
        appliedRate: manualRate,
      );
      return;
    }

    final args = ConversionPreviewArgs(
      currency: currency,
      date: date,
    );
    try {
      final withSignal = await ref.read(conversionRateProvider(args).future);
      // Bail if the user changed currency/amount/date while awaiting.
      // WR-01: `date` is captured before the await; a date change mid-fetch
      // would otherwise persist an OLD-date rate against the NEW-date timestamp
      // (undetectable post-persist — the triple is excluded from the hash chain,
      // ADR-021). The date guard makes the stale-date push impossible.
      if (!mounted ||
          foreignPushIsStale(
            capturedCurrency: currency,
            currentCurrency: _currency,
            capturedMinorUnits: minorUnits,
            currentMinorUnits: _originalMinorUnits,
            capturedDate: date,
            currentDate: _selectedDate,
          )) {
        return;
      }
      final rate = _rateStringOf(withSignal.result);
      if (rate == null) {
        // RateUnavailable — no rate to persist yet. Withhold the triple; the
        // preview surfaces the mandatory-rate prompt.
        //
        // WR-02: a PRIOR successful push may have left `_amount = someJpy`.
        // Clearing only the triple here would leave that stale JPY as a
        // JPY-native row, so a Save in this window persists a stale converted
        // amount. Reset the form amount to 0 FIRST so the create use case
        // rejects the save (amount <= 0) instead. When the user later supplies
        // a manual rate the normal push (mandatory-manual-rate, P41 D-08)
        // re-computes the JPY amount.
        _formKey.currentState?.updateAmount(0);
        _formKey.currentState?.updateCurrencyTriple(
          originalCurrency: null,
          originalAmount: null,
          appliedRate: null,
        );
        return;
      }
      final jpy = convertToJpy(
        originalMinorUnits: minorUnits,
        appliedRate: rate,
        subunitToUnit: subunitToUnitFor(currency),
      );
      _formKey.currentState?.updateAmount(jpy);
      _formKey.currentState?.updateCurrencyTriple(
        originalCurrency: currency,
        originalAmount: minorUnits,
        appliedRate: rate,
      );
    } catch (_) {
      // Rate fetch failed unexpectedly — leave the triple withheld; the preview
      // renders the mandatory-rate prompt and the save guard blocks an empty
      // amount. (Network failure degrades to a fallback rate upstream.)
    }
  }

  /// Rate string for any rate-bearing [RateResult] variant; null for
  /// [RateUnavailable].
  String? _rateStringOf(RateResult r) => switch (r) {
        RateFetched(:final rate) => rate,
        RateCached(:final rate) => rate,
        RateFallback(:final rate) => rate,
        RateManual(:final rate) => rate,
        RateUnavailable() => null,
      };

  /// Passive sink for the preview's ADR-022 rate signals (D-02 dialog / D-03
  /// toast). During FRESH entry there is no `previousRate` — the entry flow
  /// does not carry a prior applied rate — so the use case never emits these
  /// signals on this screen (verified: the panel's args omit previousRate /
  /// wasManualOverride, the two inputs that gate signal emission). The full
  /// dialog/toast UX (ADR-022 D-02/D-03) belongs to the EDIT host (42-09),
  /// where a prior rate exists to diff against. This callback is the documented
  /// 42-08 boundary; it intentionally no-ops so signals can never block keypad
  /// entry. Kept non-null so the panel's `ref.listen` has a sink.
  void _onRateSignal(RateSignal signal) {
    // No-op on the entry screen (see doc comment). 42-09 wires the real UX.
  }

  /// Quick 260613-ufn (D-4): the form's date picker changed the transaction
  /// date. Update the screen's `_selectedDate` so the keyed
  /// `conversionRateProvider(currency,date)` re-resolves the rate for the
  /// new date and the unified card's 汇率/日元/汇率日期/staleness all update. A
  /// date change supersedes any manual override (the override was keyed to the
  /// previous date's rate), then re-pushes the freshly-resolved triple.
  void _onFormDateChanged(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    if (normalized == DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    )) {
      return;
    }
    setState(() {
      _selectedDate = normalized;
      _manualForeignRate = null;
    });
    if (_isForeign) {
      _pushForeignTriple();
    }
  }

  /// Quick 260613-ufn (D-1): the user hand-edited the 汇率 row in the unified
  /// card. Record the override so `_pushForeignTriple` persists the edited rate
  /// (manual override) and immediately push the recomputed triple. The card's
  /// own derived JPY row already reflects the edit (single convertToJpy site).
  void _onForeignRateEdited(CurrencyLinkedEditValue value) {
    setState(() => _manualForeignRate = value.appliedRate);
    _pushForeignTriple();
  }

  // ── Currency selection (CURR-01/03/05) ──

  /// CURR-01: open the currency selector without leaving the entry screen.
  void _onCurrencyTap() {
    FocusManager.instance.primaryFocus?.unfocus();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CurrencySelectorSheet(
        selectedCode: _currency,
        onSelect: _onCurrencySelected,
      ),
    );
    if (mounted) setState(() => _amountFocused = true);
  }

  /// Apply a selected currency: truncate the amount per the new minor unit
  /// (D-08), gate the dot key (D-06), feed recent-use (CURR-03), and re-sync the
  /// converted JPY + triple. Selecting JPY clears the triple (CURR-04).
  void _onCurrencySelected(String code) {
    final newCode = code.toUpperCase();
    final newDecimals = currencyFractionDigitsFor(newCode);
    // CURR-03: record the foreign selection for the LRU (JPY is ignored inside).
    ref.read(recentCurrencyProvider.notifier).recordUse(newCode);
    setState(() {
      _currency = newCode;
      // D-08: truncate-not-round to the new minor unit; adopts the new cap.
      _controller.onCurrencyChange(newDecimals);
      _amount = _controller.text;
      // Quick 260613-ufn: a currency change supersedes any manual rate override
      // (the override was keyed to the previous currency's rate).
      _manualForeignRate = null;
    });
    _syncAmountToForm();
  }

  // ── Save path ──

  /// P19-W1: short-circuits with a top error toast when category hasn't loaded
  /// yet or the amount is empty/zero. Both SmartKeyboard.onNext and
  /// KeyboardToolbar.onSave point here.
  Future<void> _trySave() async {
    // 260603-nr1 #1: reject empty / zero amount before any save attempt.
    if (_amount.isEmpty || (double.tryParse(_amount) ?? 0) <= 0) {
      showErrorFeedback(context, S.of(context).pleaseEnterAmount);
      return;
    }
    if (!_canSave) {
      if (_selectedCategory == null) {
        showErrorFeedback(context, S.of(context).pleaseSelectCategory);
      }
      return;
    }
    await _save();
  }

  /// Core save handler — delegates to the embedded form's submit().
  /// Ported from transaction_confirm_screen.dart:55-81.
  ///
  /// WR-01: try/finally ensures _isSubmitting is always reset even if
  /// submit() throws an unexpected exception, preventing a permanent
  /// disabled-save-button deadlock.
  Future<void> _save() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final result = await _formKey.currentState!.submit();
      if (!mounted) return;
      result.when(
        success: (_) {
          // 260614-iww: branch on continuousMode.
          if (widget.continuousMode) {
            // Continuous (FAB long-press) entry: keep the page open, show a
            // longer-lived warm "keep going" toast with an inline exit link
            // that returns ONCE to the page before recording, then reset the
            // form in place for the next entry.
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
          } else {
            // Single-tap entry: show a warm "recorded" toast then pop back to
            // the previous page (no form reset — the screen is closing).
            showSuccessFeedback(context, S.of(context).entrySavedDone);
            Navigator.of(context).pop();
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

  /// 260603-nr1 #1: reset the form in place after a successful save so the user
  /// can keep entering without the page closing. Clears the amount (mirrors
  /// [_onClear]), resets merchant/note, resets the date to today, re-seeds the
  /// default category, and reclaims amount focus so the SmartKeyboard reappears.
  Future<void> _resetForContinuousEntry() async {
    if (!mounted) return;
    setState(() {
      // Clear the controller text (mirrors _onClear) and reset to JPY so the
      // next entry starts on the CURR-04 native path.
      while (_controller.text.isNotEmpty) {
        _controller.onDelete();
      }
      _currency = 'JPY';
      _controller.onCurrencyChange(currencyFractionDigitsFor(_currency));
      _amount = '';
      _selectedDate = DateTime.now();
      _manualForeignRate = null;
      // 260622-nhs: a fresh continuous-entry slate starts as manual provenance.
      _lastFillWasVoice = false;
    });
    resetPttSessionState();
    final formState = _formKey.currentState;
    formState?.updateAmount(0);
    formState?.updateCurrencyTriple(
      originalCurrency: null,
      originalAmount: null,
      appliedRate: null,
    );
    formState?.updateMerchant('');
    formState?.updateNote('');
    formState?.updateDate(DateTime.now());
    // Re-seed the default category for the next entry. _initializeDefaultCategory
    // now pushes the resolved default into the form itself (260603-ti2), so the
    // form's GlobalKey-preserved state is reset to the default category too.
    await _initializeDefaultCategory();
    if (!mounted) return;
    _restoreKeypadFocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    // Watch locale provider to trigger rebuild on locale change.
    final locale =
        ref.watch(currentLocaleProvider).value ?? const Locale('ja');
    final palette = context.palette;

    // Currency symbol for the active currency — derived the same way the
    // selector sheet does (strip digits/separators from a formatted zero) so the
    // display, keypad, and sheet all show the same glyph.
    final currencySymbol = NumberFormatter.formatCurrency(0, _currency, locale)
        .replaceAll(RegExp(r'[\d.,\s]'), '');

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
                    ? VoiceRecordPanel(
                        transcript: pttTranscript,
                        soundLevel: pttSoundLevel,
                        // 260622-nhs R4 (BUG C): live recognizer status drives
                        // the panel title + pulse-dot colour.
                        status: pttListenStatus,
                        onExit: _onVoiceModalExit,
                        onReset: _onVoiceReset,
                      )
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
