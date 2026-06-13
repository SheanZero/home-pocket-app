import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../infrastructure/i18n/formatters/number_formatter.dart';
import '../../../../shared/utils/currency_conversion.dart'
    show currencyFractionDigitsFor, subunitToUnitFor;
import '../../../../shared/widgets/feedback_toast.dart';
import '../../../../shared/widgets/soft_confirm_dialog.dart';
import '../../../settings/presentation/providers/state_locale.dart';
import '../../domain/models/transaction.dart';
import '../../domain/models/transaction_details_form_config.dart';
import '../providers/repository_providers.dart'
    show deleteTransactionUseCaseProvider;
import '../widgets/amount_display.dart';
import '../widgets/amount_edit_bottom_sheet.dart';
import '../widgets/currency_linked_edit_fields.dart'
    show CurrencyLinkedEditValue;
import '../widgets/transaction_details_form.dart';

/// Host screen for editing an existing transaction.
///
/// Thin Scaffold + AppBar + bottom save CTA wrapper around [TransactionDetailsForm]
/// configured as `.edit(seed: transaction)`. The form widget owns all field-editing
/// logic; the screen owns chrome + navigation only (D-01).
///
/// Phase 19 D-14 spillover: this host renders its own [AmountDisplay] above the
/// embedded form. Tapping the display opens [AmountEditBottomSheet] (modal sheet
/// UX — only ManualOneStepScreen uses the persistent keypad; this host uses modal sheet).
///
/// Post-save: `Navigator.pop(context, true)` per D-18 (pop-with-result, NOT popUntil).
/// Cancel: silent discard — no dirty-state confirmation in Phase 18 (D-10/D-16).
/// Delete: not present in Phase 18 (D-11/D-17).
class TransactionEditScreen extends ConsumerStatefulWidget {
  const TransactionEditScreen({super.key, required this.transaction});

  final Transaction transaction;

  @override
  ConsumerState<TransactionEditScreen> createState() =>
      _TransactionEditScreenState();
}

class _TransactionEditScreenState extends ConsumerState<TransactionEditScreen> {
  final _formKey = GlobalKey<TransactionDetailsFormState>();
  bool _isSubmitting = false;

  /// Host-owned display amount (Phase 19 D-14 spillover).
  ///
  /// JPY-native rows: this IS the JPY figure shown in the top [AmountDisplay],
  /// updated by [_editAmount] (sheet confirm) and the clear button, kept in sync
  /// with the form's internal _amount via [updateAmount].
  ///
  /// Foreign rows: this is NOT shown at the top (the top headline shows the
  /// ORIGINAL currency + amount per the UAT fix). It is still tracked because
  /// the form keeps `_amount` as the derived JPY, but the headline is driven by
  /// [_displayOriginalMinor] / [_displayCurrency] instead.
  late int _displayAmount;

  /// Phase 42 UAT fix: a foreign row's top headline shows the ORIGINAL currency
  /// + original amount (consistent with the entry screen — "原来记录是什么币种，
  /// 修改也是什么币种"), NOT the JPY identity. These hold the original amount in
  /// MINOR units and the ISO code, seeded from the transaction's triple and kept
  /// live as the user edits 原币金额 / 汇率 inside the linked rows. The JPY figure
  /// stays visible only in the card's 日元（换算）read-only row.
  late int _displayOriginalMinor;
  String? _displayCurrency;

  /// Phase 42-09 (ADR-022 D-01): a foreign row's JPY amount is a READ-ONLY
  /// derived value (original × rate). The top [AmountDisplay] must NOT open the
  /// [AmountEditBottomSheet] for foreign rows — editing flows exclusively
  /// through the linked rows inside the form's `.edit` host (two-input /
  /// one-derived; JPY is never directly editable). JPY-native rows are
  /// unchanged (CURR-04 regression protection).
  bool get _isForeignRow => widget.transaction.originalCurrency != null;

  @override
  void initState() {
    super.initState();
    _displayAmount = widget.transaction.amount;
    _displayCurrency = widget.transaction.originalCurrency;
    _displayOriginalMinor = widget.transaction.originalAmount ?? 0;
  }

  /// Formats a minor-unit amount in [currency] as its MAJOR-unit string with the
  /// currency's ISO 4217 decimal cap (e.g. USD 11290 minor → "112.90"; JPY 5000
  /// minor → "5000"). Mirrors CurrencyLinkedEditFields' major-unit treatment and
  /// the entry screen's major-unit input so the headline matches what was
  /// recorded. Returns '' for a non-positive amount (AmountDisplay then renders
  /// '0').
  String _minorToMajorString(int minorUnits, String currency) {
    if (minorUnits <= 0) return '';
    final decimals = currencyFractionDigitsFor(currency);
    final subunit = subunitToUnitFor(currency);
    if (decimals == 0) return (minorUnits ~/ subunit).toString();
    return (minorUnits / subunit).toStringAsFixed(decimals);
  }

  Future<void> _save() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    final result = await _formKey.currentState!.submit();
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    result.when(
      success: (_) {
        showSuccessFeedback(context, S.of(context).transactionUpdated);
        Navigator.of(context).pop(true); // D-18: pop-with-result, not popUntil
      },
      validationError: (msg) => showErrorFeedback(context, msg),
      persistError: (msg) => showErrorFeedback(context, msg),
    );
  }

  /// 260603-nr1 #6: confirm + delete the seed transaction, then pop with
  /// `true` so the caller (list_screen) runs its reactive invalidation (the
  /// shared invalidateTransactionDependents — Home + Analytics + list).
  ///
  /// The edit screen has no active year/month, so it relies on the caller's
  /// pop-with-result path rather than invalidating providers directly.
  Future<void> _onDelete() async {
    if (_isSubmitting) return;
    final l10n = S.of(context);
    final confirmed = await showSoftConfirmDialog(
      context,
      title: l10n.listDeleteConfirmTitle,
      body: l10n.listDeleteConfirmBody,
      confirmLabel: l10n.listDeleteConfirmButton,
      cancelLabel: l10n.listDeleteCancelButton,
    );
    if (!confirmed || !mounted) return;

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(deleteTransactionUseCaseProvider)
          .execute(widget.transaction.id);
      if (!mounted) return;
      Navigator.of(context).pop(true); // caller invalidates dependents.
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// Opens [AmountEditBottomSheet] for amount editing (D-14 spillover modal-sheet UX).
  ///
  /// On confirm: updates host display state AND pushes value to form via [updateAmount].
  Future<void> _editAmount() async {
    await AmountEditBottomSheet.show(
      context,
      initialAmount: _displayAmount,
      onConfirm: (v) {
        if (!mounted) return;
        setState(() => _displayAmount = v);
        _formKey.currentState?.updateAmount(v);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final palette = context.palette;
    final locale = ref.watch(currentLocaleProvider).value ?? const Locale('ja');

    // Foreign row: derive the ORIGINAL currency symbol + ISO label + major-unit
    // amount for the top headline (consistency with the entry screen). The
    // symbol is stripped from a formatted zero exactly as the entry screen does,
    // so the display, keypad, and selector all show the same glyph (no hardcoded
    // '$'). JPY-native rows keep the default '¥ JPY' + JPY amount.
    final currency = _displayCurrency;
    final isForeign = _isForeignRow && currency != null;
    final String topAmount;
    final String topSymbol;
    final String topLabel;
    if (isForeign) {
      topSymbol = NumberFormatter.formatCurrency(
        0,
        currency,
        locale,
      ).replaceAll(RegExp(r'[\d.,\s]'), '');
      topLabel = currency;
      topAmount = _minorToMajorString(_displayOriginalMinor, currency);
    } else {
      topSymbol = '¥';
      topLabel = 'JPY';
      topAmount = _displayAmount > 0 ? _displayAmount.toString() : '';
    }
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.card,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: TextButton.icon(
          onPressed: () => Navigator.pop(context), // D-10 — silent discard
          icon: Icon(Icons.chevron_left, color: palette.daily),
          label: Text(
            l10n.back,
            style: AppTextStyles.titleMedium.copyWith(color: palette.daily),
          ),
        ),
        leadingWidth: 100,
        title: Text(
          l10n.transactionEditTitle,
          style: AppTextStyles.headlineMedium.copyWith(
            color: palette.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          // 260603-nr1 #6: delete the transaction from the edit screen.
          IconButton(
            icon: Icon(Icons.delete_outline, color: palette.error),
            onPressed: _isSubmitting ? null : _onDelete,
          ),
        ],
      ),
      body: Column(
        children: [
          // D-14 spillover: host renders AmountDisplay above the form.
          // JPY-native: tapping opens AmountEditBottomSheet (modal-sheet UX).
          // Foreign (ADR-022 D-01): the JPY figure is read-only derived — no
          // tap-to-edit, no clear; edits flow through the form's linked rows.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _isForeignRow ? null : _editAmount,
            child: AmountDisplay(
              amount: topAmount,
              currencySymbol: topSymbol,
              currencyLabel: topLabel,
              onClear: _isForeignRow
                  ? null
                  : () {
                      if (!mounted) return;
                      setState(() => _displayAmount = 0);
                      _formKey.currentState?.updateAmount(0);
                    },
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: TransactionDetailsForm(
                key: _formKey,
                config: TransactionDetailsFormConfig.edit(
                  seed: widget.transaction,
                ),
                // Phase 42 UAT fix: keep the top headline in lock-step with the
                // linked-row edits. For a foreign row the headline shows the
                // ORIGINAL amount + currency, so we track the original minor amount
                // (Row 1) — NOT the derived JPY. The JPY figure still lives in the
                // card's 日元（换算）read-only row (ADR-022 D-01: one direction only).
                onForeignChanged: (CurrencyLinkedEditValue value) {
                  if (!mounted) return;
                  setState(() {
                    _displayOriginalMinor = value.originalAmount;
                    _displayAmount = value.jpyAmount;
                  });
                },
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: _buildSaveButton(l10n, palette),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(S l10n, AppPalette palette) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [palette.fabGradientStart, palette.fabGradientEnd],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: palette.actionShadow,
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isSubmitting ? null : _save,
            borderRadius: BorderRadius.circular(14),
            child: Center(
              child: _isSubmitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
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
    );
  }
}
