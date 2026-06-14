import 'package:flutter/material.dart';

import '../../../../generated/app_localizations.dart';
import '../navigation/entry_mode_navigation_config.dart';
import 'input_mode_tabs.dart';

/// Shared add-transaction mode switcher with unified navigation behavior.
class EntryModeSwitcher extends StatelessWidget {
  const EntryModeSwitcher({
    super.key,
    required this.selectedMode,
    required this.bookId,
    this.onBeforeNavigate,
    this.continuousMode = false,
  });

  final InputMode selectedMode;
  final String bookId;
  final VoidCallback? onBeforeNavigate;

  /// 260614-iww: preserved across manual↔voice switching so a continuous-entry
  /// session keeps its mode when the user changes input method.
  final bool continuousMode;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    return InputModeTabs(
      selected: selectedMode,
      onChanged: (mode) {
        if (mode == selectedMode) return;
        onBeforeNavigate?.call();
        navigateToEntryMode(
          context: context,
          fromMode: selectedMode,
          toMode: mode,
          bookId: bookId,
          continuousMode: continuousMode,
        );
      },
      manualLabel: l10n.manualInput,
      ocrLabel: l10n.ocrScan,
      voiceLabel: l10n.voiceInput,
    );
  }
}
