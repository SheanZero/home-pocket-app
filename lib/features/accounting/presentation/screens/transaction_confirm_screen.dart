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
import '../providers/repository_providers.dart';
import '../providers/use_case_providers.dart';
import '../utils/category_display_utils.dart';
import '../widgets/amount_display.dart';
import '../widgets/ledger_type_selector.dart';
import '../widgets/smart_keyboard.dart';
import '../widgets/soul_satisfaction_slider.dart';
import 'category_selection_screen.dart';

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

  late int _amount;
  late Category _category;
  Category? _parentCategory;
  late DateTime _date;
  final Map<String, Category> _categoryById = {};

  LedgerType _ledgerType = LedgerType.survival;
  int _soulSatisfaction = 5;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _amount = widget.amount;
    _category = widget.category;
    _parentCategory = widget.parentCategory;
    _date = widget.date;
    _ledgerType = LedgerType.survival;
  }

  String _formatAmount(int amount, Locale locale) {
    return NumberFormatter.formatCurrency(amount.toDouble(), 'JPY', locale);
  }

  // ── Amount editing via bottom sheet ──

  void _editAmount() {
    var editStr = _amount.toString();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void onDigit(String digit) {
              final dotIndex = editStr.indexOf('.');
              if (dotIndex >= 0) {
                final decimals = editStr.length - dotIndex - 1;
                if (decimals >= 4) return;
              }
              if (editStr == '0' && digit != '0') {
                setSheetState(() => editStr = digit);
              } else if (editStr == '0' && digit == '0') {
                return;
              } else {
                setSheetState(() => editStr += digit);
              }
            }

            void onDoubleZero() {
              if (editStr.isEmpty || editStr == '0') return;
              final dotIndex = editStr.indexOf('.');
              if (dotIndex >= 0) {
                final decimals = editStr.length - dotIndex - 1;
                if (decimals >= 4) return;
                final zerosToAdd = (4 - decimals).clamp(0, 2);
                setSheetState(() => editStr += '0' * zerosToAdd);
              } else {
                setSheetState(() => editStr += '00');
              }
            }

            void onDot() {
              if (editStr.contains('.')) return;
              if (editStr.isEmpty) {
                setSheetState(() => editStr = '0.');
              } else {
                setSheetState(() => editStr += '.');
              }
            }

            void onDelete() {
              if (editStr.isNotEmpty) {
                setSheetState(
                  () => editStr = editStr.substring(0, editStr.length - 1),
                );
              }
            }

            void onClear() {
              setSheetState(() => editStr = '');
            }

            void onConfirm() {
              final cleaned = editStr.endsWith('.')
                  ? editStr.substring(0, editStr.length - 1)
                  : editStr;
              final parsed = double.tryParse(cleaned);
              if (parsed != null && parsed > 0) {
                setState(() => _amount = parsed.round());
              }
              Navigator.pop(context);
            }

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag handle
                    const SizedBox(height: 8),
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD0D8E0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    AmountDisplay(
                      amount: editStr,
                      onClear: onClear,
                    ),
                    SmartKeyboard(
                      onDigit: onDigit,
                      onDoubleZero: onDoubleZero,
                      onDot: onDot,
                      onDelete: onDelete,
                      onNext: onConfirm,
                      nextLabel: S.of(context).record,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Category editing via navigation ──

  Future<void> _editCategory() async {
    final result = await Navigator.of(context).push<Category>(
      MaterialPageRoute<Category>(
        builder: (_) =>
            CategorySelectionScreen(selectedCategoryId: _category.id),
      ),
    );
    if (result == null || !mounted) return;

    var parent = resolveParentCategory(result, _categoryById);
    if (parent == null && result.parentId != null) {
      final repo = ref.read(categoryRepositoryProvider);
      parent = await repo.findById(result.parentId!);
    }

    if (!mounted) return;
    setState(() {
      _categoryById[result.id] = result;
      if (parent != null) {
        _categoryById[parent.id] = parent;
      }
      _category = result;
      _parentCategory = parent;
    });
  }

  // ── Date editing via date picker ──

  Future<void> _editDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.survival,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() => _date = picked);
    }
  }

  Future<void> _save() async {
    setState(() => _isSubmitting = true);

    final createUseCase = ref.read(createTransactionUseCaseProvider);
    final result = await createUseCase.execute(
      CreateTransactionParams(
        bookId: widget.bookId,
        amount: _amount,
        type: TransactionType.expense,
        categoryId: _category.id,
        timestamp: _date,
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
    final displayCategory = _parentCategory ?? _category;
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
                          onTap: _editAmount,
                          trailing: Text(
                            _formatAmount(_amount, locale),
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
                          onTap: _editCategory,
                          trailing: Text(
                            formatCategoryPath(
                              category: _category,
                              parentCategory: _parentCategory,
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
                          onTap: _editDate,
                          trailing: Text(
                            DateFormatter.formatDate(_date, locale),
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
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
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

    if (onTap != null) {
      return InkWell(onTap: onTap, child: content);
    }
    return content;
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
