import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Input mode for transaction entry.
enum InputMode { manual, ocr, voice }

/// Horizontal tab bar for selecting input mode (Manual / OCR / Voice).
class InputModeTabs extends StatelessWidget {
  const InputModeTabs({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.manualLabel,
    required this.ocrLabel,
    required this.voiceLabel,
  });

  final InputMode selected;
  final ValueChanged<InputMode> onChanged;
  final String manualLabel;
  final String ocrLabel;
  final String voiceLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF4FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _tab(manualLabel, Icons.keyboard_outlined, InputMode.manual),
          _tab(ocrLabel, Icons.document_scanner_outlined, InputMode.ocr),
          _tab(voiceLabel, Icons.mic_outlined, InputMode.voice),
        ],
      ),
    );
  }

  Widget _tab(String label, IconData icon, InputMode mode) {
    final isActive = selected == mode;

    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? AppColors.card : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive
                    ? AppColors.survival
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: isActive
                      ? AppColors.survival
                      : AppColors.textSecondary,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
