import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/models/transaction.dart';
import '../../domain/models/transaction_details_form_config.dart';
import '../widgets/amount_display.dart';
import '../widgets/amount_edit_bottom_sheet.dart';
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
  /// Initialized to the seed transaction's amount; updated by
  /// [_editAmount] (sheet confirm) and the clear button.
  /// Must stay in sync with the form's internal _amount via [updateAmount].
  late int _displayAmount;

  @override
  void initState() {
    super.initState();
    _displayAmount = widget.transaction.amount;
  }

  Future<void> _save() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    final result = await _formKey.currentState!.submit();
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).transactionUpdated)),
        );
        Navigator.of(context).pop(true); // D-18: pop-with-result, not popUntil
      },
      validationError: (msg) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg))),
      persistError: (msg) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg))),
    );
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? AppColorsDark.background : AppColors.backgroundWarm,
      appBar: AppBar(
        backgroundColor: isDark ? AppColorsDark.card : AppColors.card,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: TextButton.icon(
          onPressed: () => Navigator.pop(context), // D-10 — silent discard
          icon: const Icon(Icons.chevron_left, color: AppColors.survival),
          label: Text(l10n.back,
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.survival,
              )),
        ),
        leadingWidth: 100,
        title: Text(l10n.transactionEditTitle,
            style: AppTextStyles.headlineMedium.copyWith(
              color: isDark ? AppColorsDark.textPrimary : AppColors.textPrimary,
            )),
        centerTitle: true,
      ),
      body: Column(children: [
        // D-14 spillover: host renders AmountDisplay above the form.
        // Tapping opens AmountEditBottomSheet (modal-sheet UX, not persistent keyboard).
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _editAmount,
          child: AmountDisplay(
            amount: _displayAmount > 0 ? _displayAmount.toString() : '',
            onClear: () {
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
              config: TransactionDetailsFormConfig.edit(seed: widget.transaction),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: _buildSaveButton(l10n),
          ),
        ),
      ]),
    );
  }

  Widget _buildSaveButton(S l10n) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.actionGradientStart, AppColors.actionGradientEnd],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(color: AppColors.actionShadow, blurRadius: 14, offset: Offset(0, 4)),
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
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(l10n.save,
                      style: AppTextStyles.titleLarge.copyWith(
                        color: Colors.white,
                        fontSize: 16,
                      )),
            ),
          ),
        ),
      ),
    );
  }
}
