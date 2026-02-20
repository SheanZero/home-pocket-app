import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/accounting/create_transaction_use_case.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../features/dual_ledger/presentation/widgets/soul_celebration_overlay.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../infrastructure/i18n/formatters/date_formatter.dart';
import '../../../../infrastructure/i18n/formatters/number_formatter.dart';
import '../../../settings/presentation/providers/locale_provider.dart';
import '../../domain/models/category.dart';
import '../../domain/models/transaction.dart';
import '../providers/use_case_providers.dart';
import '../utils/category_display_utils.dart';
import '../widgets/ledger_type_selector.dart';
import '../widgets/soul_satisfaction_slider.dart';

/// Confirmation / review screen before saving a transaction.
///
/// Shows amount, category, date, editable store & memo fields,
/// ledger type toggle, soul satisfaction slider, and a save button.
class TransactionConfirmScreen extends ConsumerStatefulWidget {
  const TransactionConfirmScreen({
    super.key,
    required this.bookId,
    required this.amount,
    required this.category,
    this.parentCategory,
    required this.date,
  });

  final String bookId;
  final int amount;
  final Category category;
  final Category? parentCategory;
  final DateTime date;

  @override
  ConsumerState<TransactionConfirmScreen> createState() =>
      _TransactionConfirmScreenState();
}

class _TransactionConfirmScreenState
    extends ConsumerState<TransactionConfirmScreen> {
  final _storeController = TextEditingController();
  final _memoController = TextEditingController();

  LedgerType _ledgerType = LedgerType.survival;
  int _soulSatisfaction = 5;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Default ledger type could be resolved from category, but let user choose
    _ledgerType = LedgerType.survival;
  }

  String _formatAmount(int amount, Locale locale) {
    return NumberFormatter.formatCurrency(amount.toDouble(), 'JPY', locale);
  }

  Future<void> _save() async {
    setState(() => _isSubmitting = true);

    final createUseCase = ref.read(createTransactionUseCaseProvider);
    final result = await createUseCase.execute(
      CreateTransactionParams(
        bookId: widget.bookId,
        amount: widget.amount,
        type: TransactionType.expense,
        categoryId: widget.category.id,
        timestamp: widget.date,
        note: _memoController.text.trim().isEmpty
            ? null
            : _memoController.text.trim(),
        merchant: _storeController.text.trim().isEmpty
            ? null
            : _storeController.text.trim(),
        soulSatisfaction: _ledgerType == LedgerType.soul
            ? _soulSatisfaction
            : null,
      ),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result.isSuccess) {
      final tx = result.data!;
      if (tx.ledgerType == LedgerType.soul) {
        await _showSoulCelebration();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(S.of(context).transactionSaved)));
      // Pop all the way back to main shell
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? S.of(context).failedToSave)),
      );
    }
  }

  Future<void> _showSoulCelebration() async {
    final completer = Completer<void>();

    final overlay = OverlayEntry(
      builder: (_) => SoulCelebrationOverlay(
        onDismissed: () {
          if (!completer.isCompleted) completer.complete();
        },
      ),
    );

    Overlay.of(context).insert(overlay);
    await completer.future;
    overlay.remove();
  }

  Color _parseColor(String colorHex) {
    final hex = colorHex.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final locale = ref.watch(currentLocaleProvider);
    final displayCategory = widget.parentCategory ?? widget.category;
    final catColor = _parseColor(displayCategory.color);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FD),
      appBar: AppBar(
        backgroundColor: Colors.white,
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
        title: Text(l10n.expenseDetail, style: AppTextStyles.headlineMedium),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Detail card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        // Amount row
                        _DetailRow(
                          icon: Icons.payments_outlined,
                          iconColor: AppColors.survival,
                          label: l10n.amount,
                          trailing: Text(
                            _formatAmount(widget.amount, locale),
                            style: AppTextStyles.amountMedium.copyWith(
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const _Divider(),
                        // Category row
                        _DetailRow(
                          icon: resolveCategoryIcon(displayCategory.icon),
                          iconColor: catColor,
                          label: l10n.category,
                          trailing: Text(
                            formatCategoryPath(
                              category: widget.category,
                              parentCategory: widget.parentCategory,
                              locale: locale,
                            ),
                            style: AppTextStyles.bodyMedium,
                          ),
                        ),
                        const _Divider(),
                        // Date row
                        _DetailRow(
                          icon: Icons.calendar_today_outlined,
                          iconColor: AppColors.survival,
                          label: l10n.date,
                          trailing: Text(
                            DateFormatter.formatDate(widget.date, locale),
                            style: AppTextStyles.bodyMedium,
                          ),
                        ),
                        const _Divider(),
                        // Store row
                        _DetailRow(
                          icon: Icons.store_outlined,
                          iconColor: AppColors.survival,
                          label: l10n.merchant,
                          trailing: Expanded(
                            child: TextField(
                              controller: _storeController,
                              textAlign: TextAlign.end,
                              decoration: InputDecoration(
                                hintText: l10n.enterStore,
                                hintStyle: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: AppTextStyles.bodyMedium,
                            ),
                          ),
                        ),
                        const _Divider(),
                        // Memo section
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.edit_note,
                                    size: 20,
                                    color: AppColors.survival,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    l10n.note,
                                    style: AppTextStyles.titleMedium.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _memoController,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  hintText: l10n.enterMemo,
                                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFF5F9FD),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.all(12),
                                ),
                                style: AppTextStyles.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Ledger & Satisfaction card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.expenseClassification,
                          style: AppTextStyles.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        LedgerTypeSelector(
                          selected: _ledgerType,
                          onChanged: (type) =>
                              setState(() => _ledgerType = type),
                          survivalLabel: l10n.survivalExpense,
                          soulLabel: l10n.soulExpense,
                        ),
                        if (_ledgerType == LedgerType.soul) ...[
                          const SizedBox(height: 20),
                          SoulSatisfactionSlider(
                            value: _soulSatisfaction,
                            onChanged: (v) =>
                                setState(() => _soulSatisfaction = v),
                            label: l10n.soulSatisfaction,
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Add photo button (stub)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.add_a_photo_outlined,
                          color: AppColors.survival,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.addPhoto,
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.survival,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Save button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.fabGradientStart,
                        AppColors.fabGradientEnd,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.fabShadow,
                        blurRadius: 12,
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
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _storeController.dispose();
    _memoController.dispose();
    super.dispose();
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.trailing,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 10),
          Text(
            label,
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          trailing is Expanded ? trailing : const Spacer(),
          if (trailing is! Expanded) trailing,
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1, color: Color(0xFFE8EFF5)),
    );
  }
}
