import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../features/family_sync/presentation/providers/state_active_group.dart';
import '../../../../features/home/presentation/providers/state_shadow_books.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/models/list_filter_state.dart';
import '../../domain/models/list_sort_config.dart';
import '../providers/state_list_filter.dart';
import '../../../../shared/constants/sort_config.dart';
import 'list_category_filter_sheet.dart';

/// Result of the combined sort menu — either a field choice or a direction
/// choice. The menu now owns BOTH (the separate direction arrow button is gone,
/// quick 260714-qit).
sealed class _SortMenuResult {
  const _SortMenuResult();
}

class _FieldChoice extends _SortMenuResult {
  const _FieldChoice(this.field);
  final SortField field;
}

class _DirectionChoice extends _SortMenuResult {
  const _DirectionChoice(this.direction);
  final SortDirection direction;
}

/// Pinned sort + filter bar for the transaction list — v15 `.list-filter-bar`.
///
/// The ledger segments (すべて / 日常 / ときめき) moved out to
/// [ListLedgerSegments]; this bar now owns only the utilities row:
/// combined sort pill (field・direction) → [spacer] → clear → category →
/// search. The direction toggle lives inside the sort menu.
///
/// All interactions route through [listFilterProvider] mutators — no local
/// filter state other than the text-field expand/collapse flag and the
/// [TextEditingController] for the search field.
class ListSortFilterBar extends ConsumerStatefulWidget {
  const ListSortFilterBar({super.key, required this.bookId});

  /// The book ID passed for future invalidation on local chip actions.
  final String bookId;

  @override
  ConsumerState<ListSortFilterBar> createState() => _ListSortFilterBarState();
}

class _ListSortFilterBarState extends ConsumerState<ListSortFilterBar> {
  bool _searchExpanded = false;
  final _searchController = TextEditingController();

  /// Pending debounce for the search field (P2-1). Cancelled on dispose and on
  /// any explicit clear so a stale keystroke can never re-apply after a clear.
  Timer? _searchDebounce;

  // GlobalKey to position the sort menu below the sort chip.
  final _sortChipKey = GlobalKey();

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Applies the search query after a 300ms quiet period (P2-1). Coalesces
  /// rapid keystrokes so the list filter (and its in-memory search scan) updates
  /// once the user pauses, not on every character. Explicit clears bypass this.
  void _onSearchChanged(String value) {
    // Keep the clear (X) affordance in sync with the raw text immediately …
    setState(() {});
    // … but defer the actual filter mutation.
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 300),
      () => ref.read(listFilterProvider.notifier).setSearch(value),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Returns a locale-aware label for the current sort field (SC#4 — MUST NOT
  /// return the generic string "Sort").
  String _sortFieldLabel(SortField field, BuildContext context) {
    final l10n = S.of(context);
    switch (field) {
      case SortField.timestamp:
        return l10n.listSortDate;
      case SortField.amount:
        return l10n.listSortAmount;
    }
  }

  /// Locale-aware direction label (降順 / 昇順).
  String _directionLabel(SortDirection direction, BuildContext context) {
    final l10n = S.of(context);
    return direction == SortDirection.desc
        ? l10n.listSortDirectionDesc
        : l10n.listSortDirectionAsc;
  }

  /// Shows the combined sort menu (field + direction) below the sort pill.
  ///
  /// The direction toggle moved INTO this menu (quick 260714-qit); a
  /// [PopupMenuDivider] separates the field group from the direction group.
  Future<void> _showSortMenu(
    BuildContext context,
    ListSortConfig sortConfig,
  ) async {
    final renderBox =
        _sortChipKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    final rect = RelativeRect.fromLTRB(
      offset.dx,
      offset.dy + renderBox.size.height,
      offset.dx + renderBox.size.width,
      offset.dy + renderBox.size.height + 8,
    );

    final palette = context.palette;

    PopupMenuItem<_SortMenuResult> row(
      _SortMenuResult value,
      String label,
      bool isActive,
    ) {
      return PopupMenuItem<_SortMenuResult>(
        value: value,
        child: Row(
          children: [
            if (isActive)
              Icon(Icons.check, size: 16, color: palette.accentPrimary)
            else
              const SizedBox(width: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: palette.textPrimary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final selected = await showMenu<_SortMenuResult>(
      context: context,
      position: rect,
      items: [
        for (final field in SortField.values)
          row(
            _FieldChoice(field),
            _sortFieldLabel(field, context),
            field == sortConfig.sortField,
          ),
        const PopupMenuDivider(),
        for (final direction in SortDirection.values)
          row(
            _DirectionChoice(direction),
            _directionLabel(direction, context),
            direction == sortConfig.sortDirection,
          ),
      ],
    );

    if (selected == null) return;
    final notifier = ref.read(listFilterProvider.notifier);
    switch (selected) {
      case _FieldChoice(:final field):
        notifier.setSort(sortConfig.copyWith(sortField: field));
      case _DirectionChoice(:final direction):
        notifier.setSort(sortConfig.copyWith(sortDirection: direction));
    }
  }

  /// Opens the category filter bottom sheet.
  void _openCategorySheet(BuildContext context, Set<String> currentIds) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CategoryFilterSheet(initialSelected: currentIds),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final filter = ref.watch(listFilterProvider);
    final sortConfig = filter.sortConfig;
    final isGroupMode = ref.watch(isGroupModeProvider);

    final anyFilterActive =
        filter.activeDayFilter != null ||
        filter.ledgerType != null ||
        filter.categoryIds.isNotEmpty ||
        filter.searchQuery.isNotEmpty ||
        filter.memberBookId != null; // FAM-03 fix (Pitfall B)

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: ClipRect(
        key: const Key('list-filter-glass'),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            decoration: BoxDecoration(
              color: palette.background.withValues(alpha: 0.96),
              border: Border(
                bottom: BorderSide(color: palette.borderDivider, width: 1),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
            child: _searchExpanded
                ? _buildSearchExpanded(context, palette, filter)
                : (isGroupMode
                      ? _buildGroupRow(
                          context,
                          palette,
                          filter,
                          sortConfig,
                          anyFilterActive,
                        )
                      : _buildSoloRow(
                          context,
                          palette,
                          filter,
                          sortConfig,
                          anyFilterActive,
                        )),
          ),
        ),
      ),
    );
  }

  /// Solo-mode utilities row: sort → [spacer] → clear → category → search
  /// (faithful to the v15 `.list-filter-utilities` layout). The direction
  /// toggle now lives inside the combined sort pill's menu (quick 260714-qit).
  Widget _buildSoloRow(
    BuildContext context,
    AppPalette palette,
    ListFilterState filter,
    ListSortConfig sortConfig,
    bool anyFilterActive,
  ) {
    return Row(
      children: [
        // Expanded + left-align lets the combined sort pill grow with its
        // label yet shrink/ellipsize on long locales (en "Date・Descending")
        // instead of overflowing; the leftover space acts as the old Spacer.
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: _buildSortPill(context, palette, sortConfig),
          ),
        ),
        if (anyFilterActive) ...[
          _buildClearAction(context, palette),
          const SizedBox(width: 6),
        ],
        _buildCategoryAction(context, palette, filter),
        const SizedBox(width: 6),
        _buildSearchIconButton(palette),
      ],
    );
  }

  /// Group-mode utilities row — horizontally scrollable to fit the family
  /// member chips (FAM-03/FAM-04) while preserving the same controls.
  Widget _buildGroupRow(
    BuildContext context,
    AppPalette palette,
    ListFilterState filter,
    ListSortConfig sortConfig,
    bool anyFilterActive,
  ) {
    final shadowBooksAsync = ref.watch(shadowBooksProvider);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSortPill(context, palette, sortConfig),
          const SizedBox(width: 6),
          _buildCategoryAction(context, palette, filter),
          const SizedBox(width: 6),
          _buildSearchIconButton(palette),
          const SizedBox(width: 6),
          if (anyFilterActive) ...[
            _buildClearAction(context, palette),
            const SizedBox(width: 6),
          ],
          // Mine-only chip: always visible in group mode (SC#5)
          _memberChip(
            palette,
            label: S.of(context).listMineOnly,
            leadingIcon: Icons.person_outline,
            selected: filter.memberBookId == widget.bookId,
            onTap: () => ref
                .read(listFilterProvider.notifier)
                .setMemberFilter(
                  filter.memberBookId == widget.bookId ? null : widget.bookId,
                ),
          ),
          ...shadowBooksAsync.when(
            data: (shadows) => shadows.map((info) {
              final isSelected = filter.memberBookId == info.book.id;
              return Padding(
                padding: const EdgeInsets.only(left: 6),
                child: _memberChip(
                  palette,
                  label: '${info.memberAvatarEmoji} ${info.memberDisplayName}',
                  selected: isSelected,
                  onTap: () => ref
                      .read(listFilterProvider.notifier)
                      .setMemberFilter(isSelected ? null : info.book.id),
                ),
              );
            }).toList(),
            loading: () => const <Widget>[],
            error: (e, s) => const <Widget>[],
          ),
        ],
      ),
    );
  }

  /// Expanded search state: full-width search field + category action.
  Widget _buildSearchExpanded(
    BuildContext context,
    AppPalette palette,
    ListFilterState filter,
  ) {
    final l10n = S.of(context);
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: palette.card,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: palette.borderInputActive, width: 1),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Icon(Icons.search, size: 16, color: palette.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: TextField(
                    autofocus: true,
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    onSubmitted: (_) {
                      _searchDebounce?.cancel();
                      ref
                          .read(listFilterProvider.notifier)
                          .setSearch(_searchController.text);
                      if (_searchController.text.isEmpty) {
                        setState(() => _searchExpanded = false);
                      }
                    },
                    style: AppTextStyles.caption.copyWith(
                      color: palette.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: l10n.listSearchHint,
                      hintStyle: AppTextStyles.caption.copyWith(
                        color: palette.textSecondary,
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    // Immediate clear — cancel any pending debounce so it can't
                    // re-apply stale text.
                    _searchDebounce?.cancel();
                    ref.read(listFilterProvider.notifier).setSearch('');
                    setState(() {
                      _searchExpanded = false;
                      _searchController.clear();
                    });
                  },
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(
                      Icons.close,
                      size: 18,
                      color: palette.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        _buildCategoryAction(context, palette, filter),
      ],
    );
  }

  // ── Filter-action pieces (v15 `.list-filter-action`) ───────────────────────

  Widget _buildSortPill(
    BuildContext context,
    AppPalette palette,
    ListSortConfig sortConfig,
  ) {
    final l10n = S.of(context);
    // Combined single pill: field・direction (e.g. 日付・降順).
    final pillLabel = l10n.listSortPillLabel(
      _sortFieldLabel(sortConfig.sortField, context),
      _directionLabel(sortConfig.sortDirection, context),
    );
    return Semantics(
      button: true,
      label: 'Sort by',
      value: pillLabel,
      child: GestureDetector(
        key: _sortChipKey,
        behavior: HitTestBehavior.opaque,
        onTap: () => _showSortMenu(context, sortConfig),
        child: Container(
          height: 44,
          // maxWidth keeps the inner Flexible bounded in BOTH layouts: the solo
          // row (Expanded/Align) and the group row (unbounded horizontal
          // scroll). Long locales ellipsize instead of overflowing.
          constraints: const BoxConstraints(minWidth: 108, maxWidth: 220),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: palette.accentPrimary, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sort, size: 14, color: palette.textSecondary),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  pillLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.compact.copyWith(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Icon(Icons.expand_more, size: 16, color: palette.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryAction(
    BuildContext context,
    AppPalette palette,
    ListFilterState filter,
  ) {
    final l10n = S.of(context);
    final active = filter.categoryIds.isNotEmpty;
    return Semantics(
      button: true,
      label: 'Filter by category',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _openCategorySheet(context, filter.categoryIds),
        child: Container(
          height: 44,
          constraints: const BoxConstraints(minWidth: 76),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: active ? palette.accentPrimaryLight : palette.card,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: active ? palette.accentPrimary : palette.borderDefault,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.category_outlined,
                size: 14,
                color: active ? palette.accentPrimary : palette.textSecondary,
              ),
              const SizedBox(width: 5),
              Text(
                active
                    ? l10n.listCategoryChipN(filter.categoryIds.length)
                    : l10n.listCategoryChip,
                style: AppTextStyles.compact.copyWith(
                  color: active ? palette.accentPrimary : palette.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchIconButton(AppPalette palette) {
    return Semantics(
      button: true,
      label: 'Search transactions',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _searchExpanded = true),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: palette.borderDefault, width: 1),
          ),
          child: Icon(Icons.search, size: 18, color: palette.textPrimary),
        ),
      ),
    );
  }

  Widget _buildClearAction(BuildContext context, AppPalette palette) {
    final l10n = S.of(context);
    // v15 `.list-filter-action.clear`: icon-only (transparent, no border, no
    // visible label). The a11y label is preserved via Semantics + tooltip.
    return Semantics(
      button: true,
      label: l10n.listClearAll,
      child: Tooltip(
        message: l10n.listClearAll,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            // Cancel any pending search debounce before the full reset.
            _searchDebounce?.cancel();
            ref.read(listFilterProvider.notifier).clearAll();
            setState(() {
              _searchExpanded = false;
              _searchController.clear();
            });
          },
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            child: Icon(
              Icons.filter_alt_off,
              size: 18,
              color: palette.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _memberChip(
    AppPalette palette, {
    required String label,
    IconData? leadingIcon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        constraints: const BoxConstraints(maxWidth: 140),
        decoration: BoxDecoration(
          color: selected ? palette.sharedLight : palette.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? palette.sharedBorder : palette.borderDefault,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leadingIcon != null) ...[
              Icon(
                leadingIcon,
                size: 14,
                color: selected ? palette.shared : palette.textSecondary,
              ),
              const SizedBox(width: 5),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.compact.copyWith(
                  color: selected ? palette.shared : palette.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
