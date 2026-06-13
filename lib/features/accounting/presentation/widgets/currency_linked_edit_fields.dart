/// CurrencyLinkedEditFields — the ADR-022 D-01 two-input / one-derived edit
/// host for a foreign-currency transaction row (DISP-03 / DISP-04).
///
/// THREE rows, always visible (D-11 — rate is NEVER collapsed):
///   1. original amount  — EDITABLE  (TextField)
///   2. applied rate     — EDITABLE  (TextField, key `edit_rate_field`)
///   3. JPY              — READ-ONLY derived `Text` (AppTextStyles.amount*)
///
/// There is EXACTLY ONE data-flow direction: original × rate → JPY (D-12,
/// single site `convertToJpy()`). JPY is NEVER an input, never editable, never
/// writes back. This is the phase's #1 correctness invariant — the ROADMAP
/// "three-field bidirectional" wording is VOID (ADR-022 lines 37-55,
/// circular-dependency risk). "原币是事实，日元是结果."
///
/// Date-change semantics (ADR-022 D-02 / D-03) are surfaced HERE because the
/// edit host owns the original amount it needs to compute the JPY delta:
///   - D-02 (manual override active): re-fetch → two-choice dialog, NO default.
///   - D-03 (no override): re-fetch moving JPY > 1% → non-blocking SnackBar with
///     an Undo (5s) that restores the OLD rate.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../infrastructure/i18n/formatters/number_formatter.dart';
import '../../../../shared/utils/currency_conversion.dart';
import 'change_rate_confirmation_dialog.dart';
import 'currency_edit_strings.dart';

/// The immutable triple the host persists after an edit.
class CurrencyLinkedEditValue {
  const CurrencyLinkedEditValue({
    required this.originalAmount,
    required this.appliedRate,
    required this.jpyAmount,
    required this.manualOverride,
  });

  /// Original amount in minor units (e.g. cents for USD).
  final int originalAmount;

  /// Full-precision applied-rate string (ADR-020).
  final String appliedRate;

  /// Derived JPY amount (`convertToJpy`).
  final int jpyAmount;

  /// True while a manual rate override is active.
  final bool manualOverride;
}

/// Async source of the rate a date-change re-fetch should apply.
///
/// Returns the full-precision rate string (ADR-020) the host's exchange-rate
/// service resolved for the new {currency, date}, or `null` when no rate could
/// be resolved (offline / unavailable — the never-block-save invariant, P41).
/// The host (TransactionDetailsForm) supplies a closure that reads the REAL
/// `appGetExchangeRateUseCaseProvider`; no rate is ever hardcoded here.
typedef DateChangeRefetchRateSource = Future<String?> Function();

class CurrencyLinkedEditFields extends StatefulWidget {
  const CurrencyLinkedEditFields({
    super.key,
    required this.originalCurrency,
    required this.originalAmount,
    required this.appliedRate,
    required this.manualOverride,
    this.onChanged,
    this.dateChangeRefetchRate,
  });

  /// ISO 4217 code of the foreign currency (e.g. 'USD').
  final String originalCurrency;

  /// Initial original amount in minor units.
  final int originalAmount;

  /// Initial full-precision applied-rate string.
  final String appliedRate;

  /// Whether the seed rate is a user manual override (drives D-02 vs D-03).
  final bool manualOverride;

  /// Emitted on every committed change (original/rate edit, re-fetch, undo) so
  /// the host can keep its persistence triple in lock-step.
  final ValueChanged<CurrencyLinkedEditValue>? onChanged;

  /// Async hook: resolves the REAL re-fetched rate for the host's new date via
  /// the exchange-rate use case. When null (or it resolves null), the
  /// date-change trigger is a no-op — there is NO fallback fake rate.
  final DateChangeRefetchRateSource? dateChangeRefetchRate;

  @override
  State<CurrencyLinkedEditFields> createState() =>
      _CurrencyLinkedEditFieldsState();
}

class _CurrencyLinkedEditFieldsState extends State<CurrencyLinkedEditFields> {
  late final TextEditingController _amountController;
  late final TextEditingController _rateController;

  late int _originalAmount;
  late String _appliedRate;
  late bool _manualOverride;

  /// Inline validation error for the rate field (null = valid). T-42-23.
  String? _rateError;

  @override
  void initState() {
    super.initState();
    _originalAmount = widget.originalAmount;
    _appliedRate = widget.appliedRate;
    _manualOverride = widget.manualOverride;
    _amountController = TextEditingController(text: _originalAmount.toString());
    _rateController = TextEditingController(text: _appliedRate);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  int get _subunitToUnit => subunitToUnitFor(widget.originalCurrency);

  /// The SINGLE conversion site (D-12). Returns null when inputs are invalid so
  /// the read-only row can degrade gracefully rather than throw.
  int? _deriveJpy() {
    if (_originalAmount < 0) return null;
    if (validateAppliedRate(_appliedRate) != null) return null;
    return convertToJpy(
      originalMinorUnits: _originalAmount,
      appliedRate: _appliedRate,
      subunitToUnit: _subunitToUnit,
    );
  }

  void _notify() {
    final jpy = _deriveJpy();
    if (jpy == null) return;
    widget.onChanged?.call(
      CurrencyLinkedEditValue(
        originalAmount: _originalAmount,
        appliedRate: _appliedRate,
        jpyAmount: jpy,
        manualOverride: _manualOverride,
      ),
    );
  }

  void _onAmountChanged(String raw) {
    final parsed = int.tryParse(raw.trim());
    setState(() => _originalAmount = parsed ?? -1);
    _notify();
  }

  void _onRateChanged(String raw) {
    final trimmed = raw.trim();
    setState(() {
      _appliedRate = trimmed;
      _rateError = trimmed.isEmpty ? null : validateAppliedRate(trimmed);
      // Editing the rate by hand is a manual override (ADR-022 D-02 source).
      _manualOverride = true;
    });
    _notify();
  }

  /// Built-in date-change trigger. Routes to D-02 (dialog) when a manual
  /// override is active, else D-03 (>1% toast + undo). The re-fetched rate is
  /// resolved by the host-supplied [DateChangeRefetchRateSource] which reads the
  /// REAL exchange-rate use case — no rate is ever hardcoded.
  ///
  /// never-block-save (P41): when no source is supplied OR it resolves null
  /// (offline / RateUnavailable), this is a no-op — no dialog, no toast, the
  /// existing rate stays. Save is never blocked.
  Future<void> _onDateChange() async {
    final source = widget.dateChangeRefetchRate;
    if (source == null) return;

    final newRate = await source();
    if (!mounted) return;
    // never-block-save: the real service could not resolve a rate (offline /
    // unavailable). Degrade gracefully — keep the current rate, no UI noise.
    if (newRate == null) return;

    if (_manualOverride) {
      // D-02: two-choice dialog, NO default.
      final choice = await showChangeRateConfirmationDialog(context);
      if (!mounted) return;
      if (choice == ChangeRateChoice.refetch) {
        _applyRate(newRate, manualOverride: false);
      }
      // keepManual / dismissed → no change.
      return;
    }

    // D-03: no override. Auto-recalculate, then surface a non-blocking,
    // undoable toast IF the JPY change exceeds 1% (|new-old|/old > 0.01).
    final oldRate = _appliedRate;
    final oldJpy = _deriveJpy();
    _applyRate(newRate, manualOverride: false);
    final newJpy = _deriveJpy();

    if (oldJpy == null || newJpy == null || oldJpy == 0) return;
    final changeFraction = (newJpy - oldJpy).abs() / oldJpy;
    if (changeFraction <= 0.01) return;

    if (!mounted) return;
    final l10n = CurrencyEditStrings.of(context);
    final locale = Localizations.localeOf(context);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 5),
          content: Text(
            l10n.rateChangedToast(
              NumberFormatter.formatCurrency(oldJpy, 'JPY', locale),
              NumberFormatter.formatCurrency(newJpy, 'JPY', locale),
            ),
          ),
          action: SnackBarAction(
            key: const Key('toast_undo_button'),
            label: l10n.undo,
            // Undo restores the OLD rate (JPY returns to its prior value).
            onPressed: () => _applyRate(oldRate, manualOverride: false),
          ),
        ),
      );
  }

  void _applyRate(String rate, {required bool manualOverride}) {
    setState(() {
      _appliedRate = rate;
      _manualOverride = manualOverride;
      _rateError = validateAppliedRate(rate);
      _rateController.text = rate;
    });
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = CurrencyEditStrings.of(context);
    final palette = context.palette;
    final locale = Localizations.localeOf(context);
    final jpy = _deriveJpy();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Row 1: original amount (editable).
        _LabeledField(
          label: l10n.originalAmountLabel,
          child: TextField(
            key: const Key('edit_original_amount_field'),
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: false),
            textAlign: TextAlign.end,
            onChanged: _onAmountChanged,
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            style: AppTextStyles.bodyMedium.copyWith(
              color: palette.textPrimary,
            ),
          ),
        ),
        // Row 2: applied rate (editable, NEVER collapsed — D-11).
        _LabeledField(
          label: l10n.rateLabel,
          child: TextField(
            key: const Key('edit_rate_field'),
            controller: _rateController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.end,
            onChanged: _onRateChanged,
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              errorText: _rateError == null
                  ? null
                  : (_appliedRate.isEmpty
                        ? l10n.rateRequired
                        : l10n.rateInvalid),
              errorStyle: AppTextStyles.labelSmall.copyWith(
                color: palette.error,
              ),
            ),
            style: AppTextStyles.bodyMedium.copyWith(
              color: palette.textPrimary,
            ),
          ),
        ),
        // Row 3: JPY (READ-ONLY derived — never an input, ADR-022 D-01).
        _LabeledField(
          label: l10n.jpyDerivedLabel,
          child: Text(
            key: const Key('edit_jpy_derived'),
            jpy == null
                ? '—'
                : NumberFormatter.formatCurrency(jpy, 'JPY', locale),
            textAlign: TextAlign.end,
            style: AppTextStyles.amountSmall.copyWith(
              color: palette.textPrimary,
            ),
          ),
        ),
        // Date-change affordance — routes to ADR-022 D-02 / D-03 semantics.
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            key: const Key('edit_date_change_trigger'),
            onPressed: _onDateChange,
            child: Text(
              l10n.dateLabel,
              style: AppTextStyles.labelMedium.copyWith(color: palette.daily),
            ),
          ),
        ),
      ],
    );
  }
}

/// Shared label + trailing-field row used by all three edit rows so they align
/// to a single visual rhythm.
class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              color: palette.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: child),
        ],
      ),
    );
  }
}
