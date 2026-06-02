import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../features/accounting/domain/models/transaction.dart';
import '../../../../features/family_sync/presentation/providers/state_active_group.dart';
import '../../../../features/home/presentation/providers/state_shadow_books.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/models/list_sort_config.dart';
import '../providers/state_list_filter.dart';
import '../../../../shared/constants/sort_config.dart';
import 'list_category_filter_sheet.dart';

/// Pinned sort + filter chip bar for the transaction list (C-03).
///
/// All interactions route through [listFilterProvider] mutators — no local
/// filter state other than the text-field expand/collapse flag and the
/// [TextEditingController] for the search field.
///
/// Chip order (left-to-right, per UI-SPEC C-03):
/// Sort chip → Direction arrow → All / 日常 / ときめき → カテゴリ → Search → [Clear]
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

  // GlobalKey to position the sort menu below the sort chip.
  final _sortChipKey = GlobalKey();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  /// Shows the sort-field popup menu positioned below the sort chip.
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
    final selected = await showMenu<SortField>(
      context: context,
      position: rect,
      items: SortField.values.map((field) {
        final isActive = field == sortConfig.sortField;
        return PopupMenuItem<SortField>(
          value: field,
          child: Row(
            children: [
              if (isActive)
                Icon(Icons.check, size: 16, color: palette.accentPrimary)
              else
                const SizedBox(width: 16),
              const SizedBox(width: 8),
              Text(
                _sortFieldLabel(field, context),
                style: AppTextStyles.caption.copyWith(
                  color: palette.textPrimary,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );

    if (selected != null) {
      ref
          .read(listFilterProvider.notifier)
          .setSort(sortConfig.copyWith(sortField: selected));
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
    final l10n = S.of(context);
    final sortConfig = filter.sortConfig;
    final isGroupMode = ref.watch(isGroupModeProvider);
    final shadowBooksAsync = isGroupMode
        ? ref.watch(shadowBooksProvider)
        : const AsyncData<List<ShadowBookInfo>>([]);

    final anyFilterActive =
        filter.activeDayFilter != null ||
        filter.ledgerType != null ||
        filter.categoryIds.isNotEmpty ||
        filter.searchQuery.isNotEmpty ||
        filter.memberBookId != null; // FAM-03 fix (Pitfall B)

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: palette.background,
        border: Border(
          bottom: BorderSide(color: palette.borderDivider, width: 1),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Sort chip (C-03a) ─────────────────────────────────────────
            Semantics(
              label: 'Sort by',
              child: ActionChip(
                key: _sortChipKey,
                avatar: Icon(
                  Icons.sort,
                  size: 14,
                  color: palette.textSecondary,
                ),
                label: Text(
                  _sortFieldLabel(sortConfig.sortField, context),
                  style: AppTextStyles.caption.copyWith(
                    color: palette.textPrimary,
                  ),
                ),
                onPressed: () => _showSortMenu(context, sortConfig),
                side: BorderSide(color: palette.accentPrimary, width: 1),
                backgroundColor: palette.card,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 4),
            // ── Direction arrow (C-03b) ───────────────────────────────────
            Semantics(
              label: sortConfig.sortDirection == SortDirection.desc
                  ? 'Descending'
                  : 'Ascending',
              child: IconButton(
                icon: Icon(
                  sortConfig.sortDirection == SortDirection.desc
                      ? Icons.arrow_downward
                      : Icons.arrow_upward,
                  size: 18,
                  color: palette.textPrimary,
                ),
                onPressed: () => ref
                    .read(listFilterProvider.notifier)
                    .setSort(
                      sortConfig.copyWith(
                        sortDirection:
                            sortConfig.sortDirection == SortDirection.desc
                            ? SortDirection.asc
                            : SortDirection.desc,
                      ),
                    ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 44),
              ),
            ),
            const SizedBox(width: 8),
            // ── Ledger: All chip (C-03c) ──────────────────────────────────
            Semantics(
              label: 'Show all ledgers',
              selected: filter.ledgerType == null,
              child: ActionChip(
                label: Text(
                  l10n.listLedgerAll,
                  style: AppTextStyles.caption.copyWith(
                    color: filter.ledgerType == null
                        ? palette.textPrimary
                        : palette.textSecondary,
                  ),
                ),
                backgroundColor: filter.ledgerType == null
                    ? palette.backgroundMuted
                    : palette.card,
                side: BorderSide(color: palette.borderDefault, width: 1),
                onPressed: () =>
                    ref.read(listFilterProvider.notifier).setLedgerFilter(null),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 4),
            // ── Ledger: 日常 chip (C-03c) ─────────────────────────────────
            Semantics(
              label: l10n.listLedgerDaily,
              selected: filter.ledgerType == LedgerType.daily,
              child: ActionChip(
                label: Text(
                  l10n.listLedgerDaily,
                  style: AppTextStyles.caption.copyWith(
                    color: filter.ledgerType == LedgerType.daily
                        ? palette.daily
                        : palette.textSecondary,
                  ),
                ),
                backgroundColor: filter.ledgerType == LedgerType.daily
                    ? palette.dailyLight
                    : palette.card,
                side: BorderSide(
                  color: filter.ledgerType == LedgerType.daily
                      ? palette.daily
                      : palette.borderDefault,
                  width: 1,
                ),
                onPressed: () => ref
                    .read(listFilterProvider.notifier)
                    .setLedgerFilter(
                      filter.ledgerType == LedgerType.daily
                          ? null
                          : LedgerType.daily,
                    ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 4),
            // ── Ledger: ときめき chip (C-03c) ───────────────────────────────────
            Semantics(
              label: l10n.listLedgerJoy,
              selected: filter.ledgerType == LedgerType.joy,
              child: ActionChip(
                label: Text(
                  l10n.listLedgerJoy,
                  style: AppTextStyles.caption.copyWith(
                    color: filter.ledgerType == LedgerType.joy
                        ? palette.joy
                        : palette.textSecondary,
                  ),
                ),
                backgroundColor: filter.ledgerType == LedgerType.joy
                    ? palette.joyLight
                    : palette.card,
                side: BorderSide(
                  color: filter.ledgerType == LedgerType.joy
                      ? palette.joy
                      : palette.borderDefault,
                  width: 1,
                ),
                onPressed: () => ref
                    .read(listFilterProvider.notifier)
                    .setLedgerFilter(
                      filter.ledgerType == LedgerType.joy
                          ? null
                          : LedgerType.joy,
                    ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 8),
            // ── Category count chip (C-03d) ───────────────────────────────
            Semantics(
              label: 'Filter by category',
              child: ActionChip(
                avatar: Icon(
                  Icons.category_outlined,
                  size: 14,
                  color: palette.textSecondary,
                ),
                label: Text(
                  filter.categoryIds.isEmpty
                      ? l10n.listCategoryChip
                      : l10n.listCategoryChipN(filter.categoryIds.length),
                  style: AppTextStyles.caption.copyWith(
                    color: filter.categoryIds.isEmpty
                        ? palette.textSecondary
                        : palette.textPrimary,
                  ),
                ),
                backgroundColor: filter.categoryIds.isEmpty
                    ? palette.card
                    : palette.backgroundMuted,
                side: BorderSide(color: palette.borderDefault, width: 1),
                onPressed: () =>
                    _openCategorySheet(context, filter.categoryIds),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 8),
            // ── Search expand (C-03e) ─────────────────────────────────────
            _searchExpanded
                ? AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    width: 160,
                    height: 32,
                    child: TextField(
                      autofocus: true,
                      controller: _searchController,
                      onChanged: (v) =>
                          ref.read(listFilterProvider.notifier).setSearch(v),
                      onSubmitted: (_) {
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
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          size: 16,
                          color: palette.textSecondary,
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  ref
                                      .read(listFilterProvider.notifier)
                                      .setSearch('');
                                  setState(() {
                                    _searchExpanded = false;
                                    _searchController.clear();
                                  });
                                },
                                child: Icon(
                                  Icons.close,
                                  size: 16,
                                  color: palette.textSecondary,
                                ),
                              )
                            : null,
                        suffixIconConstraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: palette.borderDefault,
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: palette.borderDefault,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: palette.accentPrimary,
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  )
                : Semantics(
                    label: 'Search transactions',
                    child: IconButton(
                      icon: Icon(
                        Icons.search,
                        size: 20,
                        color: palette.textSecondary,
                      ),
                      onPressed: () => setState(() => _searchExpanded = true),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                    ),
                  ),
            // ── Family segment (FAM-03/FAM-04) — group mode only (D-04 / CC-4) ──
            if (isGroupMode) ...[
              const SizedBox(width: 8),
              // Mine-only chip: always visible in group mode (SC#5)
              ActionChip(
                avatar: Icon(
                  Icons.person_outline,
                  size: 14,
                  color: filter.memberBookId == widget.bookId
                      ? palette.textPrimary
                      : palette.textSecondary,
                ),
                label: Text(
                  S.of(context).listMineOnly,
                  style: AppTextStyles.caption.copyWith(
                    color: palette.textPrimary,
                  ),
                ),
                backgroundColor: palette.backgroundMuted,
                side: BorderSide(color: palette.borderDefault, width: 1),
                onPressed: () => ref
                    .read(listFilterProvider.notifier)
                    .setMemberFilter(
                      filter.memberBookId == widget.bookId
                          ? null
                          : widget.bookId,
                    ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              const SizedBox(width: 4),
              // Per-member chips: one per shadow book
              ...shadowBooksAsync.when(
                data: (shadows) => shadows.map((info) {
                  final isSelected = filter.memberBookId == info.book.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: ActionChip(
                      label: Text(
                        '${info.memberAvatarEmoji} ${info.memberDisplayName}',
                        style: AppTextStyles.caption.copyWith(
                          color: isSelected
                              ? palette.shared
                              : palette.textSecondary,
                        ),
                      ),
                      backgroundColor: isSelected
                          ? palette.sharedLight
                          : palette.card,
                      side: BorderSide(
                        color: isSelected
                            ? palette.sharedBorder
                            : palette.borderDefault,
                        width: 1,
                      ),
                      onPressed: () => ref
                          .read(listFilterProvider.notifier)
                          .setMemberFilter(isSelected ? null : info.book.id),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  );
                }).toList(),
                loading: () => const [],
                error: (e, s) => const [],
              ),
            ],
            // ── Conditional clear chip (C-03f) ────────────────────────────
            if (anyFilterActive) ...[
              const SizedBox(width: 8),
              Semantics(
                label: 'Clear all filters',
                child: ActionChip(
                  avatar: Icon(
                    Icons.clear_all,
                    size: 14,
                    color: palette.textSecondary,
                  ),
                  label: Text(
                    l10n.listClearAll,
                    style: AppTextStyles.caption.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
                  backgroundColor: palette.backgroundMuted,
                  side: BorderSide(color: palette.borderDefault, width: 1),
                  onPressed: () {
                    ref.read(listFilterProvider.notifier).clearAll();
                    setState(() {
                      _searchExpanded = false;
                      _searchController.clear();
                    });
                  },
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
