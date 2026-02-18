import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../infrastructure/category/category_service.dart';
import '../../../../infrastructure/i18n/formatters/date_formatter.dart';
import '../../../settings/presentation/providers/locale_provider.dart';
import '../../domain/models/category.dart';
import '../widgets/amount_display.dart';
import '../widgets/input_mode_tabs.dart';
import '../widgets/smart_keyboard.dart';
import 'category_selection_screen.dart';
import 'ocr_scanner_screen.dart';
import 'transaction_confirm_screen.dart';
import 'voice_input_screen.dart';

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
  DateTime _selectedDate = DateTime.now();

  void _onDigit(String digit) {
    // Max 7 digits (9,999,999)
    if (_amount.length >= 7) return;
    // Don't allow leading zeros
    if (_amount.isEmpty && digit == '0') return;
    setState(() => _amount += digit);
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
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.survival,
                ),
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
        builder: (_) => CategorySelectionScreen(
          selectedCategoryId: _selectedCategory?.id,
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() => _selectedCategory = result);
    }
  }

  void _onNext() {
    final amount = int.tryParse(_amount);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).amountMustBeGreaterThanZero),
        ),
      );
      return;
    }
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).pleaseSelectCategory)),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TransactionConfirmScreen(
          bookId: widget.bookId,
          amount: amount,
          category: _selectedCategory!,
          date: _selectedDate,
        ),
      ),
    );
  }

  void _onModeChanged(InputMode mode) {
    switch (mode) {
      case InputMode.manual:
        break; // already here
      case InputMode.ocr:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const OcrScannerScreen(),
          ),
        );
      case InputMode.voice:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const VoiceInputScreen(),
          ),
        );
    }
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
        title: Text(
          l10n.addTransaction,
          style: AppTextStyles.headlineMedium,
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),

          // Mode tabs
          InputModeTabs(
            selected: InputMode.manual,
            onChanged: _onModeChanged,
            manualLabel: l10n.manualInput,
            ocrLabel: l10n.ocrScan,
            voiceLabel: l10n.voiceInput,
          ),

          const SizedBox(height: 16),

          // Amount display
          AmountDisplay(
            amount: _amount,
            onClear: _onClear,
          ),

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
                    icon: Icons.grid_view_rounded,
                    label: _selectedCategory != null
                        ? CategoryService.resolve(
                            _selectedCategory!.name,
                            locale,
                          )
                        : l10n.selectCategory,
                    isPlaceholder: _selectedCategory == null,
                    onTap: _selectCategory,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Keyboard
          SmartKeyboard(
            onDigit: _onDigit,
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
            Icon(
              icon,
              size: 16,
              color: AppColors.survival,
            ),
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
