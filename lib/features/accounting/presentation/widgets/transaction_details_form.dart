/// TransactionDetailsForm — embeddable form widget for creating and editing
/// transactions. Host screens own all chrome (Scaffold, AppBar, save CTA).
///
/// Configuration via [TransactionDetailsFormConfig]:
///   - `.$new(...)` — new entry mode
///   - `.edit(seed: tx)` — edit-existing mode
///
/// Submit via GlobalKey[TransactionDetailsFormState].currentState!.submit()
/// which returns [Future] of [TransactionDetailsFormResult].
///
/// Locale-aware formatting is delegated to child widgets (AmountDisplay,
/// DetailInfoCard); Phase 19/22 may revisit if in-form formatting is needed.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/accounting/create_transaction_use_case.dart';
import '../../../../application/accounting/update_transaction_use_case.dart';
import '../../../../application/i18n/formatter_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../features/dual_ledger/presentation/widgets/soul_celebration_overlay.dart';
import '../../../../generated/app_localizations.dart';
import '../../../settings/presentation/providers/state_locale.dart';
import '../../domain/models/category.dart';
import '../../domain/models/transaction.dart';
import '../../domain/models/transaction_details_form_config.dart';
import '../providers/repository_providers.dart';
import '../screens/category_selection_screen.dart';
import '../utils/category_display_utils.dart';
import '../widgets/amount_display.dart';
import '../widgets/detail_info_card.dart';
import '../widgets/ledger_type_selector.dart';
import '../widgets/satisfaction_emoji_picker.dart';
import '../widgets/smart_keyboard.dart';

/// Embeddable form for creating and editing transactions.
///
/// No Scaffold, AppBar, or save CTA inside — the host screen owns all chrome
/// (D-01). The host calls [TransactionDetailsFormState.submit] via a
/// [GlobalKey] of [TransactionDetailsFormState] and handles post-save
/// navigation.
class TransactionDetailsForm extends ConsumerStatefulWidget {
  const TransactionDetailsForm({super.key, required this.config});

  final TransactionDetailsFormConfig config;

  @override
  ConsumerState<TransactionDetailsForm> createState() =>
      TransactionDetailsFormState();
}

/// Public state class — required for GlobalKey of [TransactionDetailsFormState]
/// in host screens (D-02).
class TransactionDetailsFormState
    extends ConsumerState<TransactionDetailsForm> {
  final _storeController = TextEditingController();
  final _memoController = TextEditingController();

  late int _amount;
  Category? _category;
  Category? _parentCategory;
  late DateTime _date;
  String? _initialCategoryId;
  LedgerType _ledgerType = LedgerType.survival;
  int _soulSatisfaction = 2;
  bool _isSubmitting = false;

  // Drives the celebration Stack overlay; only mutated by .new branch (D-15).
  bool _showCelebration = false;

  // Local category cache for parent-lookup (mirrors analog _categoryById).
  final Map<String, Category> _categoryById = {};

  @override
  void initState() {
    super.initState();
    widget.config.when(
      $new: (
        bookId,
        initialAmount,
        initialCategory,
        initialParentCategory,
        initialMerchant,
        initialSatisfaction,
        initialDate,
        entrySource,
        voiceKeyword,
      ) {
        _amount = initialAmount ?? 0;
        _category = initialCategory;
        _parentCategory = initialParentCategory;
        _date = initialDate ?? DateTime.now();
        _initialCategoryId = initialCategory?.id;
        if (initialMerchant != null) _storeController.text = initialMerchant;
        if (initialSatisfaction != null) {
          _soulSatisfaction = initialSatisfaction.clamp(1, 10);
        }
        // Resolve ledger type from category if one was pre-seeded.
        if (_category != null) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _resolveLedgerType(_category!.id),
          );
        }
      },
      edit: (seed) {
        // .edit init: preload all mutable fields from seed verbatim (D-07).
        // seed.ledgerType used as-is — _resolveLedgerType is NOT called (W3).
        _amount = seed.amount;
        _date = seed.timestamp;
        _ledgerType = seed.ledgerType;
        _soulSatisfaction = seed.soulSatisfaction;
        _storeController.text = seed.merchant ?? '';
        _memoController.text = seed.note ?? '';
        _initialCategoryId = seed.categoryId;
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _loadCategoryFromSeed(seed.categoryId),
        );
      },
    );
  }

  @override
  void dispose() {
    _storeController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  // ── Async helpers ──────────────────────────────────────────────────────────

  /// Loads the category and its parent from the repository for .edit mode.
  ///
  /// W3 fix: handles null gracefully (deleted/orphaned categoryId) — sets both
  /// _category and _parentCategory to null so the form renders in
  /// "please select" state rather than crashing.
  Future<void> _loadCategoryFromSeed(String categoryId) async {
    final cat = await ref.read(categoryRepositoryProvider).findById(categoryId);
    if (!mounted) return;
    if (cat == null) {
      setState(() {
        _category = null;
        _parentCategory = null;
      });
      return;
    }
    // Warm the local cache.
    _categoryById[cat.id] = cat;
    Category? parent = resolveParentCategory(cat, _categoryById);
    if (parent == null && cat.parentId != null) {
      parent = await ref
          .read(categoryRepositoryProvider)
          .findById(cat.parentId!);
      if (parent != null) _categoryById[parent.id] = parent;
    }
    if (!mounted) return;
    setState(() {
      _category = cat;
      _parentCategory = parent;
    });
    // .edit mode: DO NOT call _resolveLedgerType here — seed.ledgerType is
    // authoritative and was already set in initState (W3 clarification).
  }

  /// Resolves the default ledger type for [categoryId] via CategoryService.
  ///
  /// Called only in .new mode — after initState and after a category change.
  /// .edit mode uses seed.ledgerType verbatim (W3).
  Future<void> _resolveLedgerType(String categoryId) async {
    final service = ref.read(categoryServiceProvider);
    final resolved = await service.resolveLedgerType(categoryId);
    if (mounted && resolved != null) {
      setState(() => _ledgerType = resolved);
    }
  }

  // ── Field edit affordances ─────────────────────────────────────────────────

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

  Future<void> _editCategory() async {
    final result = await Navigator.of(context).push<Category>(
      MaterialPageRoute<Category>(
        builder: (_) =>
            CategorySelectionScreen(selectedCategoryId: _category?.id),
      ),
    );
    if (result == null || !mounted) return;

    // Resolve parent for display path.
    Category? parent = resolveParentCategory(result, _categoryById);
    if (parent == null && result.parentId != null) {
      final repo = ref.read(categoryRepositoryProvider);
      parent = await repo.findById(result.parentId!);
    }

    if (!mounted) return;
    setState(() {
      _categoryById[result.id] = result;
      if (parent != null) _categoryById[parent.id] = parent;
      _category = result;
      _parentCategory = parent;
    });

    // Resolve ledger type for .new mode after category change.
    await _resolveLedgerType(result.id);

    if (!mounted) return;

    // Voice-correction gate (D-09): .new mode only, fires when category
    // changed from the initial voice-matched one.
    await widget.config.maybeWhen(
      $new: (
        nBookId,
        nInitialAmount,
        nInitialCategory,
        nInitialParentCategory,
        nInitialMerchant,
        nInitialSatisfaction,
        nInitialDate,
        nEntrySource,
        voiceKeyword,
      ) async {
        if (voiceKeyword != null &&
            voiceKeyword.isNotEmpty &&
            result.id != _initialCategoryId) {
          final correctionUseCase = ref.read(
            recordCategoryCorrectionUseCaseProvider,
          );
          await correctionUseCase.execute(
            keyword: voiceKeyword,
            correctedCategoryId: result.id,
          );
        }
      },
      orElse: () {},
    );
  }

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

  // ── Public submit() — invoked by host CTA via GlobalKey (D-02) ─────────────

  /// Validates the form and persists via the appropriate use case.
  ///
  /// Returns [TransactionDetailsFormResult.validationError] if [_category] is
  /// null (user has not selected a category), without calling any use case.
  ///
  /// On success:
  /// - `.new` mode: may show [SoulCelebrationOverlay] if saved as soul (D-15).
  /// - `.edit` mode: never shows celebration overlay (D-15 invariant).
  ///
  /// Host is responsible for post-save navigation and snackbars.
  Future<TransactionDetailsFormResult> submit() async {
    if (_category == null) {
      return TransactionDetailsFormResult.validationError(
        S.of(context).pleaseSelectCategory,
      );
    }
    setState(() => _isSubmitting = true);
    try {
      return await widget.config.when(
        $new: (
          bookId,
          newInitialAmount,
          newInitialCategory,
          newInitialParentCategory,
          newInitialMerchant,
          newInitialSatisfaction,
          newInitialDate,
          entrySource,
          voiceKeyword,
        ) async {
          final result = await ref
              .read(createTransactionUseCaseProvider)
              .execute(
                CreateTransactionParams(
                  bookId: bookId,
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
                  entrySource: entrySource,
                ),
              );
          if (!result.isSuccess) {
            if (!mounted) {
              return const TransactionDetailsFormResult.persistError(
                'Save failed',
              );
            }
            return TransactionDetailsFormResult.persistError(
              result.error ?? S.of(context).failedToSave,
            );
          }
          final tx = result.data!;
          // D-15: celebration only for .new soul saves. .edit branch never
          // touches _showCelebration.
          if (tx.ledgerType == LedgerType.soul && mounted) {
            setState(() => _showCelebration = true);
          }
          return TransactionDetailsFormResult.success(tx);
        },
        edit: (seed) async {
          final result = await ref
              .read(updateTransactionUseCaseProvider)
              .execute(
                UpdateTransactionParams(
                  seed: seed,
                  amount: _amount,
                  categoryId: _category!.id,
                  timestamp: _date,
                  note: _memoController.text.trim().isEmpty
                      ? null
                      : _memoController.text.trim(),
                  merchant: _storeController.text.trim().isEmpty
                      ? null
                      : _storeController.text.trim(),
                  ledgerType: _ledgerType,
                  soulSatisfaction: _ledgerType == LedgerType.soul
                      ? _soulSatisfaction
                      : null,
                ),
              );
          // .edit branch NEVER sets _showCelebration (D-15 invariant).
          if (!result.isSuccess) {
            if (!mounted) {
              return const TransactionDetailsFormResult.persistError(
                'Update failed',
              );
            }
            return TransactionDetailsFormResult.persistError(
              result.error ?? S.of(context).failedToUpdate,
            );
          }
          return TransactionDetailsFormResult.success(result.data!);
        },
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ── UI helpers ─────────────────────────────────────────────────────────────

  String _formatAmount(int amount, Locale locale) {
    return const FormatterService().formatCurrency(
      amount.toDouble(),
      'JPY',
      locale,
    );
  }

  String _categoryLabel(Locale locale, S l10n) {
    if (_category == null) return l10n.pleaseSelectCategory;
    return formatCategoryPath(
      category: _category!,
      parentCategory: _parentCategory,
      locale: locale,
    );
  }

  Widget _buildStoreAndMemoSection(S l10n, bool isDark) {
    final secondaryColor =
        isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;
    final tertiaryColor =
        isDark ? AppColorsDark.textTertiary : AppColors.textTertiary;
    final primaryColor =
        isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;

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

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final localeAsync = ref.watch(currentLocaleProvider);
    final locale = localeAsync.value ?? const Locale('ja');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayCategory = _parentCategory ?? _category;

    // AbsorbPointer prevents field interaction while submit is in progress.
    final formBody = AbsorbPointer(
      absorbing: _isSubmitting,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    onChanged: (type) => setState(() => _ledgerType = type),
                    survivalLabel: l10n.survivalExpense,
                    soulLabel: l10n.soulExpense,
                  ),
                  if (_ledgerType == LedgerType.soul) ...[
                    const SizedBox(height: 20),
                    SatisfactionEmojiPicker(
                      value: _soulSatisfaction,
                      onChanged: (v) => setState(() => _soulSatisfaction = v),
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
          ],
        ),
      ),
    );

    // Wrap body in Stack for celebration overlay (D-15).
    return Stack(
      children: [
        formBody,
        // D-15: soul-celebration overlay — .new mode only; dismissed on
        // animation completion. .edit branch never sets _showCelebration.
        if (_showCelebration)
          Positioned.fill(
            child: SoulCelebrationOverlay(
              onDismissed: () {
                if (mounted) setState(() => _showCelebration = false);
              },
            ),
          ),
      ],
    );
  }
}
