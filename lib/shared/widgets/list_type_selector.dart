import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_text_styles.dart';

/// Toggle chips for selecting Public or Private list type.
///
/// Visually mirrors [LedgerTypeSelector]: pill chips with AnimatedContainer,
/// radius 20, 1.5px border, icon + label. Uses the shared steel-blue palette
/// tokens (palette.shared / sharedLight / sharedText) — a neutral scope
/// indicator that does not conflict with daily/joy identity colours.
///
/// Props:
/// - [selected]: current value ('public' or 'private').
/// - [onChanged]: called when the user taps a chip.
/// - [publicLabel]: localised label for the public chip (公共 / Public).
/// - [privateLabel]: localised label for the private chip (私有 / Private).
/// - [enabled]: when false, the chips are rendered at 0.6 opacity and all
///   taps are absorbed by [IgnorePointer] — suitable for edit mode where the
///   list type is immutable after creation (D37-04 / SYNC-03).
class ListTypeSelector extends StatelessWidget {
  const ListTypeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.publicLabel,
    required this.privateLabel,
    this.enabled = true,
    this.showIcons = true,
    this.chipMinHeight,
    this.chipMinWidth,
  });

  final String selected;
  final ValueChanged<String> onChanged;
  final String publicLabel;
  final String privateLabel;
  final bool enabled;

  /// Opt-out for text-only segmented controls such as the v16 shopping form.
  final bool showIcons;

  /// Optional opt-in geometry. Null preserves the legacy selector footprint.
  final double? chipMinHeight;
  final double? chipMinWidth;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _chip(
          context: context,
          label: publicLabel,
          icon: Icons.groups_outlined,
          value: 'public',
          key: const ValueKey('list_type_public_chip'),
          palette: palette,
        ),
        const SizedBox(width: 10),
        _chip(
          context: context,
          label: privateLabel,
          icon: Icons.lock_outline,
          value: 'private',
          key: const ValueKey('list_type_private_chip'),
          palette: palette,
        ),
      ],
    );

    if (!enabled) {
      return Opacity(opacity: 0.6, child: IgnorePointer(child: row));
    }

    return row;
  }

  Widget _chip({
    required BuildContext context,
    required String label,
    required IconData icon,
    required String value,
    required Key key,
    required AppPalette palette,
  }) {
    final isActive = selected == value;

    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        key: key,
        duration: const Duration(milliseconds: 200),
        constraints: chipMinHeight == null && chipMinWidth == null
            ? null
            : BoxConstraints(
                minHeight: chipMinHeight ?? 0,
                minWidth: chipMinWidth ?? 0,
              ),
        alignment: chipMinHeight == null && chipMinWidth == null
            ? null
            : Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? palette.sharedLight : palette.backgroundMuted,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? palette.shared : palette.borderDefault,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcons) ...[
              Icon(
                icon,
                size: 15,
                color: isActive ? palette.shared : palette.textSecondary,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AppTextStyles.titleSmall.copyWith(
                color: isActive ? palette.sharedText : palette.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
