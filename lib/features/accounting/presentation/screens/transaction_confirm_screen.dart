import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/accounting/create_transaction_use_case.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../features/dual_ledger/presentation/widgets/soul_celebration_overlay.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../application/i18n/formatter_service.dart';
import '../../../settings/presentation/providers/locale_provider.dart';
import '../../domain/models/category.dart';
import '../../domain/models/transaction.dart';
import '../providers/repository_providers.dart';
import '../utils/category_display_utils.dart';
import '../widgets/amount_display.dart';
import '../widgets/detail_info_card.dart';
import '../widgets/ledger_type_selector.dart';
import '../widgets/satisfaction_emoji_picker.dart';
import '../widgets/smart_keyboard.dart';
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
    this.category,
    this.parentCategory,
    required this.date,
    this.initialMerchant,
    this.initialSatisfaction,
    this.voiceKeyword,
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

  @override
  ConsumerState<TransactionConfirmScreen> createState() =>
      _TransactionConfirmScreenState();
}

class _TransactionConfirmScreenState
    extends ConsumerState<TransactionConfirmScreen> {
  final _storeController = TextEditingController();
  final _memoController = TextEditingController();

  late int _amount;
  Category? _category;
  Category? _parentCategory;
  late DateTime _date;
  final Map<String, Category> _categoryById = {};
  String? _initialCategoryId;

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
    _initialCategoryId = widget.category?.id;

    if (_category != null) {
      _resolveLedgerType(_category!.id);
    }
    // Pre-fill optional voice input fields
    if (widget.initialMerchant != null) {
      _storeController.text = widget.initialMerchant!;
    }
    if (widget.initialSatisfaction != null) {
      _soulSatisfaction = widget.initialSatisfaction!.clamp(1, 10);
    }
  }

  Future<void> _resolveLedgerType(String categoryId) async {
    final service = ref.read(categoryServiceProvider);
    final resolved = await service.resolveLedgerType(categoryId);
    if (mounted && resolved != null) {
      setState(() => _ledgerType = resolved);
    }
  }

  String _formatAmount(int amount, Locale locale) {
    return const FormatterService().formatCurrency(amount.toDouble(), 'JPY', locale);
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
                    AmountDisplay(amount: editStr, onClear: onClear),
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
            CategorySelectionScreen(selectedCategoryId: _category?.id),
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
    _resolveLedgerType(result.id);

    // Record voice learning correction if category changed
    if (widget.voiceKeyword != null &&
        widget.voiceKeyword!.isNotEmpty &&
        result.id != _initialCategoryId) {
      final correctionUseCase = ref.read(
        recordCategoryCorrectionUseCaseProvider,
      );
      await correctionUseCase.execute(
        keyword: widget.voiceKeyword!,
        correctedCategoryId: result.id,
      );
    }
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
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: AppColors.survival),
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
    if (_category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).pleaseSelectCategory)),
      );
      return;
    }
    setState(() => _isSubmitting = true);

    final createUseCase = ref.read(createTransactionUseCaseProvider);
    final result = await createUseCase.execute(
      CreateTransactionParams(
        bookId: widget.bookId,
        amount: _amount,
        type: TransactionType.expense,
        categoryId: _category!.id,
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
        ledgerType: _ledgerType,
      ),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result.isSuccess) {
      final tx = result.data!;
      final merchant = _storeController.text.trim();
      if (merchant.isNotEmpty) {
        final learningService = ref.read(
          merchantCategoryLearningServiceProvider,
        );
        await learningService.recordSelection(
          merchantRaw: merchant,
          selectedCategoryId: _category!.id,
        );
      }
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

  String _categoryLabel(Locale locale, S l10n) {
    if (_category == null) {
      return l10n.pleaseSelectCategory;
    }
    return formatCategoryPath(
      category: _category!,
      parentCategory: _parentCategory,
      locale: locale,
    );
  }

  Widget _buildStoreAndMemoSection(S l10n, bool isDark) {
    final secondaryColor = isDark
        ? AppColorsDark.textSecondary
        : AppColors.textSecondary;
    final tertiaryColor = isDark
        ? AppColorsDark.textTertiary
        : AppColors.textTertiary;
    final primaryColor = isDark
        ? AppColorsDark.textPrimary
        : AppColors.textPrimary;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(Icons.store_outlined, size: 16, color: tertiaryColor),
              const SizedBox(width: 8),
              Text(
                l10n.merchant,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: secondaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _storeController,
                  textAlign: TextAlign.end,
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintText: l10n.enterStore,
                    hintStyle: AppTextStyles.bodyMedium.copyWith(
                      color: secondaryColor,
                      fontSize: 14,
                    ),
                  ),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            height: 1,
            color: isDark
                ? AppColorsDark.backgroundDivider
                : AppColors.backgroundDivider,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.edit_outlined, size: 16, color: tertiaryColor),
                  const SizedBox(width: 8),
                  Text(
                    l10n.note,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: secondaryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 72,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColorsDark.backgroundMuted
                      : AppColors.backgroundMuted,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _memoController,
                  maxLines: null,
                  expands: true,
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: l10n.enterMemo,
                    hintStyle: AppTextStyles.bodyMedium.copyWith(
                      color: secondaryColor,
                      fontSize: 13,
                    ),
                  ),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: primaryColor,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
    final localeAsync = ref.watch(currentLocaleProvider);
    final locale = localeAsync.valueOrNull ?? const Locale('ja');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayCategory = _parentCategory ?? _category;

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DetailInfoCard(
                    rows: [
                      DetailInfoRow(
                        icon: Icons.payments_outlined,
                        label: l10n.amount,
                        value: _formatAmount(_amount, locale),
                        valueStyle: AppTextStyles.amountMedium,
                        showChevron: true,
                        onTap: _editAmount,
                      ),
                      DetailInfoRow(
                        icon: displayCategory != null
                            ? resolveCategoryIcon(displayCategory.icon)
                            : Icons.shopping_bag_outlined,
                        label: l10n.category,
                        value: _categoryLabel(locale, l10n),
                        showChevron: true,
                        onTap: _editCategory,
                      ),
                      DetailInfoRow(
                        icon: Icons.calendar_today_outlined,
                        label: l10n.date,
                        value: const FormatterService().formatDate(_date, locale),
                        showChevron: true,
                        onTap: _editDate,
                      ),
                    ],
                    trailing: _buildStoreAndMemoSection(l10n, isDark),
                  ),

                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColorsDark.card : AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? AppColorsDark.borderDefault
                            : AppColors.borderDefault,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.expenseClassification,
                          style: AppTextStyles.titleMedium.copyWith(
                            color: isDark
                                ? AppColorsDark.textPrimary
                                : AppColors.textPrimary,
                          ),
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
                          SatisfactionEmojiPicker(
                            value: _soulSatisfaction,
                            onChanged: (v) =>
                                setState(() => _soulSatisfaction = v),
                            title: l10n.satisfactionLevel,
                            levelLabels: [
                              l10n.satisfactionBad,
                              l10n.satisfactionSlightlyBad,
                              l10n.satisfactionNormal,
                              l10n.satisfactionGood,
                              l10n.satisfactionVeryGood,
                            ],
                            bottomLabels: [
                              l10n.satisfactionBad,
                              l10n.satisfactionNormal,
                              l10n.satisfactionExcellent,
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColorsDark.card : AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? AppColorsDark.borderDefault
                            : AppColors.borderDefault,
                      ),
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
                            color: isDark
                                ? AppColorsDark.textSecondary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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

  @override
  void dispose() {
    _storeController.dispose();
    _memoController.dispose();
    super.dispose();
  }
}
