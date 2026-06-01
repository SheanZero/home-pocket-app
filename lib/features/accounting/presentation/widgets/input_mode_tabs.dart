import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
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
    final palette = context.palette;

    return Container(
      key: const ValueKey('input_mode_tabs_root'),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.backgroundMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _tab(context, manualLabel, Icons.keyboard_outlined, InputMode.manual, palette),
          _tab(
            context,
            ocrLabel,
            Icons.document_scanner_outlined,
            InputMode.ocr,
            palette,
          ),
          _tab(context, voiceLabel, Icons.mic_outlined, InputMode.voice, palette),
        ],
      ),
    );
  }

  Widget _tab(
    BuildContext context,
    String label,
    IconData icon,
    InputMode mode,
    AppPalette palette,
  ) {
    final isActive = selected == mode;

    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? palette.card : Colors.transparent,
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
                color: isActive ? palette.accentPrimary : palette.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: isActive ? palette.accentPrimary : palette.textSecondary,
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
