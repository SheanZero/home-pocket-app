import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/models/category.dart';
import '../../domain/models/entry_source.dart';
import '../../domain/models/transaction_details_form_config.dart';
import '../widgets/transaction_details_form.dart';

/// Confirmation / review screen before saving a transaction.
///
/// Shows amount, category, date, editable store & memo fields,
/// ledger type toggle, soul satisfaction slider, and a save button.
class TransactionConfirmScreen extends ConsumerStatefulWidget {
  const TransactionConfirmScreen({
    super.key,
    required this.bookId,
    required this.amount,
    this.category,
    this.parentCategory,
    required this.date,
    this.initialMerchant,
    this.initialSatisfaction,
    this.voiceKeyword,
    required this.entrySource,
  });

  final String bookId;
  final int amount;
  final Category? category;
  final Category? parentCategory;
  final DateTime date;

  /// Optional pre-filled merchant name from voice input.
  final String? initialMerchant;

  /// Optional pre-filled soul satisfaction score (1–10) from voice input.
  final int? initialSatisfaction;

  /// Extracted keyword from voice input for learning corrections.
  final String? voiceKeyword;

  // D-06: pushed by the upstream entry-path screen; no default.
  final EntrySource entrySource;

  @override
  ConsumerState<TransactionConfirmScreen> createState() =>
      _TransactionConfirmScreenState();
}

class _TransactionConfirmScreenState
    extends ConsumerState<TransactionConfirmScreen> {
  final _formKey = GlobalKey<TransactionDetailsFormState>();
  bool _isSubmitting = false;

  Future<void> _save() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    final result = await _formKey.currentState!.submit();
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).transactionSaved)),
        );
        // Pop all the way back to main shell — D-04 preserved.
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
      validationError: (msg) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      },
      persistError: (msg) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      },
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
            colors: [
              AppColors.actionGradientStart,
              AppColors.actionGradientEnd,
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: AppColors.actionShadow,
              blurRadius: 14,
              offset: Offset(0, 4),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColorsDark.background
          : AppColors.backgroundWarm,
      appBar: AppBar(
        backgroundColor: isDark ? AppColorsDark.card : AppColors.card,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.chevron_left, color: AppColors.survival),
          label: Text(
            l10n.back,
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.survival,
            ),
          ),
        ),
        leadingWidth: 100,
        title: Text(
          l10n.expenseDetail,
          style: AppTextStyles.headlineMedium.copyWith(
            color: isDark ? AppColorsDark.textPrimary : AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: TransactionDetailsForm(
                key: _formKey,
                config: TransactionDetailsFormConfig.$new(
                  bookId: widget.bookId,
                  initialAmount: widget.amount,
                  initialCategory: widget.category,
                  initialParentCategory: widget.parentCategory,
                  initialDate: widget.date,
                  initialMerchant: widget.initialMerchant,
                  initialSatisfaction: widget.initialSatisfaction,
                  voiceKeyword: widget.voiceKeyword,
                  entrySource: widget.entrySource,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: _buildSaveButton(l10n),
            ),
          ),
        ],
      ),
    );
  }
}
