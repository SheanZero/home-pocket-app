import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../infrastructure/i18n/formatters/date_formatter.dart';
import '../../../settings/presentation/providers/locale_provider.dart';
import '../../domain/models/category.dart';
import '../providers/repository_providers.dart';
import '../utils/category_display_utils.dart';
import '../widgets/amount_display.dart';
import '../widgets/entry_mode_switcher.dart';
import '../widgets/input_mode_tabs.dart';
import '../widgets/smart_keyboard.dart';
import '../widgets/soft_toast.dart';
import 'category_selection_screen.dart';
import 'transaction_confirm_screen.dart';

/// Main transaction entry screen with custom numpad.
///
/// Hub screen for the 5-screen transaction flow. Handles amount entry via
/// [SmartKeyboard], mode switching (Manual/OCR/Voice), date/category selection,
/// and navigation to [TransactionConfirmScreen].
class TransactionEntryScreen extends ConsumerStatefulWidget {
  const TransactionEntryScreen({super.key, required this.bookId});

  final String bookId;

  @override
  ConsumerState<TransactionEntryScreen> createState() =>
      _TransactionEntryScreenState();
}

class _TransactionEntryScreenState
    extends ConsumerState<TransactionEntryScreen> {
  String _amount = '';
  Category? _selectedCategory;
  Category? _selectedParentCategory;
  Map<String, Category> _categoryById = {};
  DateTime _selectedDate = DateTime.now();
  String? _toastMessage;

  @override
  void initState() {
    super.initState();
    _initializeDefaultCategory();
  }

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
  }

  void _onDigit(String digit) {
    _dismissToast();
    final dotIndex = _amount.indexOf('.');
    if (dotIndex >= 0) {
      // Has decimal point — max 4 decimal places
      final decimals = _amount.length - dotIndex - 1;
      if (decimals >= 4) return;
    }
    // Don't allow leading zeros (except "0.")
    if (_amount.isEmpty && digit == '0') return;
    setState(() => _amount += digit);
  }

  void _onDoubleZero() {
    // Only append "00" if current amount > 0
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
  }

  void _onDot() {
    // Only one decimal point allowed
    if (_amount.contains('.')) return;
    if (_amount.isEmpty) {
      setState(() => _amount = '0.');
    } else {
      setState(() => _amount += '.');
    }
  }

  void _onDelete() {
    if (_amount.isNotEmpty) {
      setState(() => _amount = _amount.substring(0, _amount.length - 1));
    }
  }

  void _onClear() {
    setState(() => _amount = '');
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
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
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectCategory() async {
    final result = await Navigator.of(context).push<Category>(
      MaterialPageRoute<Category>(
        builder: (_) =>
            CategorySelectionScreen(selectedCategoryId: _selectedCategory?.id),
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
      _selectedCategory = result;
      _selectedParentCategory = parent;
    });
  }

  IconData _categoryChipIcon() {
    final parent = _selectedParentCategory;
    if (parent == null) return Icons.grid_view_rounded;
    return resolveCategoryIcon(parent.icon);
  }

  String _categoryChipLabel(Locale locale, String placeholder) {
    final selected = _selectedCategory;
    if (selected == null) return placeholder;
    return formatCategoryPath(
      category: selected,
      parentCategory: _selectedParentCategory,
      locale: locale,
    );
  }

  void _showToast(String message) {
    setState(() => _toastMessage = message);
  }

  void _dismissToast() {
    if (mounted) {
      setState(() => _toastMessage = null);
    }
  }

  void _onNext() {
    // Strip trailing dot (e.g. "320." → "320")
    final cleaned = _amount.endsWith('.')
        ? _amount.substring(0, _amount.length - 1)
        : _amount;
    final parsed = double.tryParse(cleaned);
    if (parsed == null || parsed <= 0) {
      _showToast(S.of(context).amountMustBeGreaterThanZero);
      return;
    }
    if (_selectedCategory == null) {
      _showToast(S.of(context).pleaseSelectCategory);
      return;
    }

    // For JPY (0 decimals), round to int
    final amount = parsed.round();

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TransactionConfirmScreen(
          bookId: widget.bookId,
          amount: amount,
          category: _selectedCategory!,
          parentCategory: _selectedParentCategory,
          date: _selectedDate,
        ),
      ),
    );
  }

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final locale = ref.watch(currentLocaleProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(l10n.addTransaction, style: AppTextStyles.headlineMedium),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),

          // Mode tabs
          EntryModeSwitcher(
            selectedMode: InputMode.manual,
            bookId: widget.bookId,
          ),

          const SizedBox(height: 16),

          // Amount display
          AmountDisplay(amount: _amount, onClear: _onClear),

          // Selector chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                // Date chip
                _SelectorChip(
                  icon: Icons.calendar_today_outlined,
                  label: _isToday
                      ? l10n.todayDate
                      : DateFormatter.formatDate(_selectedDate, locale),
                  onTap: _selectDate,
                ),
                const SizedBox(width: 10),
                // Category chip
                Expanded(
                  child: _SelectorChip(
                    icon: _categoryChipIcon(),
                    label: _categoryChipLabel(locale, l10n.selectCategory),
                    isPlaceholder: _selectedCategory == null,
                    onTap: _selectCategory,
                  ),
                ),
              ],
            ),
          ),

          // Inline floating toast
          if (_toastMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: SoftToast(
                key: ValueKey(_toastMessage),
                message: _toastMessage!,
                onDismissed: _dismissToast,
              ),
            ),

          const Spacer(),

          // Keyboard
          SmartKeyboard(
            onDigit: _onDigit,
            onDoubleZero: _onDoubleZero,
            onDot: _onDot,
            onDelete: _onDelete,
            onNext: _onNext,
            nextLabel: l10n.next,
          ),
        ],
      ),
    );
  }
}

class _SelectorChip extends StatelessWidget {
  const _SelectorChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPlaceholder = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPlaceholder;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E8EF)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.survival),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isPlaceholder
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
