import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_text_styles.dart';

/// Shared visual frame for the app's standard modal bottom sheets.
///
/// The content, header copy, and state handling remain feature-owned. This
/// widget intentionally owns only the common height, surface, top corners, and
/// drag handle so sheets retain their distinct interaction contracts.
class AppSheetFrame extends StatelessWidget {
  const AppSheetFrame({
    super.key,
    required this.child,
    this.heightFactor = .65,
  });

  final Widget child;
  final double heightFactor;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      height: MediaQuery.sizeOf(context).height * heightFactor,
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          const AppSheetDragHandle(),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// The standard drag affordance used at the top of modal bottom sheets.
class AppSheetDragHandle extends StatelessWidget {
  const AppSheetDragHandle({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: palette.borderDivider,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

/// Standard cancel/apply action bar for selection sheets.
///
/// Selection ownership remains with the calling sheet: this widget receives
/// labels and callbacks and has no knowledge of providers or category state.
class AppSheetActionBar extends StatelessWidget {
  const AppSheetActionBar({
    super.key,
    required this.cancelLabel,
    required this.applyLabel,
    required this.onCancel,
    required this.onApply,
  });

  final String cancelLabel;
  final String applyLabel;
  final VoidCallback onCancel;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      height: 56,
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: palette.borderDivider, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          TextButton(
            onPressed: onCancel,
            child: Text(
              cancelLabel,
              style: AppTextStyles.titleSmall.copyWith(
                color: palette.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: palette.accentPrimary,
              ),
              onPressed: onApply,
              child: Text(
                applyLabel,
                style: AppTextStyles.titleSmall.copyWith(color: palette.card),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
