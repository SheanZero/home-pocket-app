import 'package:flutter/material.dart';

import '../../../../application/accounting/category_localization_service.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/models/category.dart';
import '../screens/category_selection_screen.dart';
import '../utils/category_display_utils.dart';
import '../../../voice/domain/models/voice_parse_result.dart';

/// Alternate-category correction chips (RECUX-02 / CONTEXT D-04).
///
/// Renders **at most 3** ranked alternate-category chips (the already-ranked,
/// already-L2-deduped reconciler `alternates` from Phase 51 — never re-ranked
/// here) plus exactly **one trailing exit chip** that opens the existing full
/// [CategorySelectionScreen] (reuse, do not rebuild a picker).
///
/// Each chip:
///   - shows the localized category label only (`AppTextStyles.labelMedium`) —
///     no confidence figure of any kind is ever painted (ADR-012);
///   - has a ≥44px touch height (HIG floor, UI-SPEC §Spacing);
///   - on tap fires [onSelect] with its category id.
///
/// The currently-selected chip uses the `accentPrimary` leaf-green outline;
/// unselected chips use `borderDefault` on `backgroundMuted`.
class AlternateCategoryChips extends StatelessWidget {
  const AlternateCategoryChips({
    super.key,
    required this.alternates,
    required this.selectedCategoryId,
    required this.onSelect,
  });

  /// The ranked, L2-deduped alternates from the reconciler (Phase 51). Capped
  /// to the first 3 here — NOT re-ranked.
  final List<CategoryMatchResult> alternates;

  /// The currently-selected category id (drives the active-outline styling).
  final String? selectedCategoryId;

  /// Fired with the chosen category id when an alternate chip is tapped OR the
  /// full selector (opened by the exit chip) returns a category.
  final ValueChanged<String> onSelect;

  static const double _kChipHeight = 44; // HIG touch floor (UI-SPEC §Spacing).

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final l10n = S.of(context);

    // Cap to the first 3 (already ranked + L2-deduped upstream).
    final capped = alternates.take(3).toList(growable: false);

    final chips = <Widget>[
      for (final alt in capped)
        _AltChip(
          key: ValueKey('alt-chip-${alt.categoryId}'),
          label: CategoryLocalizationService.resolveFromId(
            alt.categoryId,
            locale,
          ),
          icon: categoryIconFromId(alt.categoryId),
          selected: alt.categoryId == selectedCategoryId,
          height: _kChipHeight,
          onTap: () => onSelect(alt.categoryId),
        ),
      // Trailing exit chip → full category selector (D-04).
      _AltChip(
        key: const ValueKey('alt-chip-exit'),
        label: l10n.recognitionAlternatesMore,
        icon: Icons.more_horiz,
        selected: false,
        height: _kChipHeight,
        muted: true,
        onTap: () => _openFullSelector(context),
      ),
    ];

    // A short, bounded row (≤3 alternates + 1 exit) — build all chips eagerly
    // (no lazy ListView) so the exit chip always renders; scroll horizontally
    // if the row overflows on narrow viewports.
    return SizedBox(
      height: _kChipHeight,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < chips.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              chips[i],
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openFullSelector(BuildContext context) async {
    final result = await Navigator.of(context).push<Category>(
      MaterialPageRoute<Category>(
        builder: (_) =>
            CategorySelectionScreen(selectedCategoryId: selectedCategoryId),
      ),
    );
    if (result == null) return;
    onSelect(result.id);
  }
}

/// A single chip atom mirroring the `list_sort_filter_bar.dart` ActionChip idiom
/// (icon + label + palette-token outline), tuned to a ≥44px touch height.
class _AltChip extends StatelessWidget {
  const _AltChip({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.height,
    required this.onTap,
    this.muted = false,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final double height;
  final VoidCallback onTap;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final Color sideColor = selected
        ? palette.accentPrimary
        : palette.borderDefault;
    final Color iconColor = selected
        ? palette.accentPrimary
        : (muted ? palette.textTertiary : palette.textSecondary);
    final Color labelColor = muted ? palette.textTertiary : palette.textPrimary;

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: height),
      child: ActionChip(
        avatar: Icon(icon, size: 16, color: iconColor),
        label: Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(color: labelColor),
        ),
        onPressed: onTap,
        side: BorderSide(color: sideColor, width: selected ? 1.5 : 1),
        backgroundColor: palette.backgroundMuted,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        materialTapTargetSize: MaterialTapTargetSize.padded,
      ),
    );
  }
}
