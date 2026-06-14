import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/currency/rate_result.dart';
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
import '../widgets/entry_mode_switcher.dart';
import '../widgets/input_mode_tabs.dart';
import '../../../../shared/widgets/feedback_toast.dart';
import '../widgets/keyboard_toolbar.dart';
import '../widgets/smart_keyboard.dart';
import '../widgets/transaction_details_form.dart';

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
/// Layout (top-to-bottom per D-03):
///   AppBar → EntryModeSwitcher → AmountDisplay → scrollable details form
///   → AnimatedSlide(SmartKeyboard)
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

  @override
  ConsumerState<ManualOneStepScreen> createState() =>
      _ManualOneStepScreenState();
}

class _ManualOneStepScreenState extends ConsumerState<ManualOneStepScreen> {
  final _formKey = GlobalKey<TransactionDetailsFormState>();

  late final FocusNode _merchantFocus;
  late final FocusNode _noteFocus;

  String _amount = '';
  bool _amountFocused = true;
  bool _isTextFieldFocused = false;
  bool _isSubmitting = false;

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
    _merchantFocus.dispose();
    _noteFocus.dispose();
    super.dispose();
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
          // 260603-nr1 #1: keep the page open for continuous entry — show a
          // top success toast and reset the form instead of popping.
          // Ask 2 follow-up: longer-lived toast that reads "可以继续记账" plus an
          // inline "退出记账" link returning to the page before recording.
          showSuccessFeedback(
            context,
            S.of(context).successKeepGoing,
            duration: const Duration(seconds: 5),
            actionLabel: S.of(context).recordingExitLink,
            onAction: () {
              if (!mounted) return;
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          );
          _resetForContinuousEntry();
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
    });
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
      ),
      body: Stack(
        children: [
          // Main content column
          Column(
            children: [
              const SizedBox(height: 8),

              // D-04: mode switcher at top
              EntryModeSwitcher(
                selectedMode: InputMode.manual,
                bookId: widget.bookId,
              ),

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
                      // now scrolls WITH the form (only AmountDisplay +
                      // EntryModeSwitcher stay pinned) and is wrapped in the same
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
                          child: _AddScreenForeignCard(
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
                          entrySource: widget.entrySource,
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

              // D-05: SmartKeyboard slides off-screen when a TextField is focused.
              AnimatedSlide(
                offset: Offset(0, _showSmartKeypad ? 0 : 1),
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                child: SmartKeyboard(
                  onDigit: _onDigit,
                  onDoubleZero: _onDoubleZero,
                  // D-06: gate the dot key on the active currency's minor unit.
                  // 0-decimal currencies (JPY/KRW) pass null → disabled blank
                  // tile; the JPY path keeps onDot:null exactly as before.
                  onDot: _controller.decimals > 0 ? _onDot : null,
                  onDelete: _onDelete,
                  // P19-W1: route through _trySave for category-null guard.
                  onNext: _trySave,
                  actionLabel: l10n.record,
                  currencyLabel: _currency,
                  currencySymbol: currencySymbol,
                  // CURR-01: open the currency selector sheet.
                  onCurrencyTap: _onCurrencyTap,
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

/// Quick 260613-ufn (D-1): thin Consumer wrapper that mounts the unified
/// [CurrencyLinkedEditFields] card on the ADD screen, fed by the keyed
/// [conversionRateProvider]. It reuses the SAME card and the SAME single
/// staleness-derivation site as the edit host — the two screens are now visually
/// and interactively identical (no large ≈¥ preview block).
///
/// Date auto-refetch (D-4): because the provider is keyed on (currency, date,
/// amount), the host bumping `_selectedDate` re-resolves the rate and re-seeds
/// the card's 汇率 / 日元 / 汇率日期 / staleness. A user hand-edit of the 汇率 row
/// flips manual override via [onRateEdited] (the host persists the edited rate).
class _AddScreenForeignCard extends ConsumerWidget {
  const _AddScreenForeignCard({
    required this.currency,
    required this.date,
    required this.originalMinorUnits,
    required this.manualRateOverride,
    required this.onRateEdited,
    required this.onSignal,
  });

  final String currency;
  final DateTime date;
  final int originalMinorUnits;

  /// Active manual-override rate (null when the auto-resolved rate is in use).
  /// When set it seeds the card so the user's edit survives provider re-reads.
  final String? manualRateOverride;

  /// Fired when the user hand-edits the 汇率 row (manual override).
  final ValueChanged<CurrencyLinkedEditValue> onRateEdited;

  /// ADR-022 RateSignal sink (D-02/D-03), forwarded via ref.listen only.
  final void Function(RateSignal signal) onSignal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = S.of(context);
    final locale = ref.watch(currentLocaleProvider).value ?? const Locale('ja');

    final args = ConversionPreviewArgs(
      currency: currency,
      date: date,
    );

    // RateSignal side-effects (D-02 dialog / D-03 toast) belong in ref.listen,
    // NEVER ref.watch (Riverpod 3 — CLAUDE.md side-effect rule).
    ref.listen<AsyncValue<RateResultWithSignal>>(
      conversionRateProvider(args),
      (previous, next) {
        final signal = next.value?.signal;
        if (signal != null) onSignal(signal);
      },
    );

    final rateAsync = ref.watch(conversionRateProvider(args));

    return rateAsync.when(
      loading: () => const SizedBox(
        height: kAddScreenForeignCardLoadingHeight,
        child: Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, _) => _RateRequiredRow(l10n: l10n, palette: context.palette),
      data: (withSignal) {
        final result = withSignal.result;
        final resolvedRate = rateStringOf(result);
        // RateUnavailable (P41 D-08): prompt for a manual rate; the host's
        // _pushForeignTriple already withholds the triple so save is gated.
        if (resolvedRate == null && manualRateOverride == null) {
          return _RateRequiredRow(l10n: l10n, palette: context.palette);
        }
        // A user-edited (manual) rate wins over the auto-resolved one as the
        // seed, so the edit survives provider re-reads.
        final seedRate = manualRateOverride ?? resolvedRate!;
        final actualRateDate = rateEffectiveDateOf(result, date);
        final stalenessNote = manualRateOverride != null
            ? null // manual override supersedes the auto-rate staleness
            : stalenessNoteFor(
                result: result,
                requestedDate: date,
                l10n: l10n,
                locale: locale,
              );

        return CurrencyLinkedEditFields(
          // Re-seed the card when the resolved/override rate changes (date
          // re-resolve or currency switch) — a stable key preserves in-card
          // edits within the same seed.
          key: ValueKey('add-foreign-card-$currency-$seedRate'),
          originalCurrency: currency,
          originalAmount: originalMinorUnits,
          appliedRate: seedRate,
          manualOverride: manualRateOverride != null,
          rateDate: date,
          actualRateDate: actualRateDate,
          stalenessNote: stalenessNote,
          onChanged: onRateEdited,
        );
      },
    );
  }
}

/// Fixed loading height so the add-screen card area does not jump while the
/// keyed rate provider resolves.
const double kAddScreenForeignCardLoadingHeight = 56;

/// Mandatory-manual-rate prompt row (P41 D-08 / RateUnavailable) for the add
/// screen. Error color — save is gated on a present rate by the host.
class _RateRequiredRow extends StatelessWidget {
  const _RateRequiredRow({required this.l10n, required this.palette});

  final S l10n;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          l10n.conversionRateRequired,
          style: AppTextStyles.labelMedium.copyWith(color: palette.error),
        ),
      ),
    );
  }
}
