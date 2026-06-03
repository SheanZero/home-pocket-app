import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';
import '../../../settings/presentation/providers/state_locale.dart';
import '../../domain/models/category.dart';
import '../../domain/models/entry_source.dart';
import '../../domain/models/transaction_details_form_config.dart';
import '../providers/repository_providers.dart';
import '../widgets/amount_display.dart';
import '../widgets/entry_mode_switcher.dart';
import '../widgets/feedback_toast.dart';
import '../widgets/input_mode_tabs.dart';
import '../widgets/keyboard_toolbar.dart';
import '../widgets/smart_keyboard.dart';
import '../widgets/transaction_details_form.dart';

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

    // Initialize amount string from widget param
    if (widget.initialAmount != null && widget.initialAmount! > 0) {
      _amount = widget.initialAmount!.toString();
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

  // ── Digit handlers (ported verbatim from transaction_entry_screen.dart:84-129) ──

  void _onDigit(String digit) {
    final dotIndex = _amount.indexOf('.');
    if (dotIndex >= 0) {
      final decimals = _amount.length - dotIndex - 1;
      if (decimals >= 4) return;
    }
    // Don't allow leading zeros (except "0.")
    if (_amount.isEmpty && digit == '0') return;
    setState(() => _amount += digit);
    final parsed = (double.tryParse(_amount) ?? 0.0).round();
    _formKey.currentState?.updateAmount(parsed);
  }

  void _onDoubleZero() {
    if (_amount.isEmpty) return;

    final dotIndex = _amount.indexOf('.');
    if (dotIndex >= 0) {
      final decimals = _amount.length - dotIndex - 1;
      if (decimals >= 4) return;
      final zerosToAdd = (4 - decimals).clamp(0, 2);
      setState(() => _amount += '0' * zerosToAdd);
    } else {
      setState(() => _amount += '00');
    }
    final parsed = (double.tryParse(_amount) ?? 0.0).round();
    _formKey.currentState?.updateAmount(parsed);
  }

  void _onDot() {
    if (_amount.contains('.')) return;
    if (_amount.isEmpty) {
      setState(() => _amount = '0.');
    } else {
      setState(() => _amount += '.');
    }
    final parsed = (double.tryParse(_amount) ?? 0.0).round();
    _formKey.currentState?.updateAmount(parsed);
  }

  void _onDelete() {
    if (_amount.isNotEmpty) {
      setState(() => _amount = _amount.substring(0, _amount.length - 1));
      final parsed = (double.tryParse(_amount) ?? 0.0).round();
      _formKey.currentState?.updateAmount(parsed);
    }
  }

  void _onClear() {
    setState(() => _amount = '');
    _formKey.currentState?.updateAmount(0);
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
          showSuccessFeedback(context, S.of(context).successKeepGoing);
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
      _amount = '';
      _selectedDate = DateTime.now();
    });
    final formState = _formKey.currentState;
    formState?.updateAmount(0);
    formState?.updateMerchant('');
    formState?.updateNote('');
    formState?.updateDate(DateTime.now());
    // Re-seed the default category and push it into the form so the next entry
    // starts from a clean slate (the form's GlobalKey preserves its own state
    // across rebuilds, so a config change alone would not reset it).
    await _initializeDefaultCategory();
    if (!mounted) return;
    if (_selectedCategory != null) {
      _formKey.currentState?.updateCategory(
        _selectedCategory!,
        _selectedParentCategory,
      );
    }
    _restoreKeypadFocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    // Watch locale provider to trigger rebuild on locale change.
    ref.watch(currentLocaleProvider);
    final palette = context.palette;

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
                child: AmountDisplay(amount: _amount, onClear: _onClear),
              ),

              // Scrollable details section with smart bottom padding (D-13)
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, scrollPaddingBottom),
                  child: TransactionDetailsForm(
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
                  onDot: _onDot,
                  onDelete: _onDelete,
                  // P19-W1: route through _trySave for category-null guard.
                  onNext: _trySave,
                  actionLabel: l10n.record,
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
