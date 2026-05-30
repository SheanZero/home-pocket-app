import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
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
/// Sort chip → Direction arrow → All / 生存 / 魂 → カテゴリ → Search → [Clear]
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
      case SortField.updatedAt:
        return l10n.listSortEditTime;
      case SortField.amount:
        return l10n.listSortAmount;
    }
  }

  /// Shows the sort-field popup menu positioned below the sort chip.
  Future<void> _showSortMenu(
      BuildContext context, ListSortConfig sortConfig) async {
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
                const Icon(Icons.check, size: 16, color: AppColors.accentPrimary)
              else
                const SizedBox(width: 16),
              const SizedBox(width: 8),
              Text(
                _sortFieldLabel(field, context),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight:
                      isActive ? FontWeight.w600 : FontWeight.w500,
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
    final filter = ref.watch(listFilterProvider);
    final l10n = S.of(context);
    final sortConfig = filter.sortConfig;
    final isGroupMode = ref.watch(isGroupModeProvider);
    final shadowBooksAsync = isGroupMode
        ? ref.watch(shadowBooksProvider)
        : const AsyncData<List<ShadowBookInfo>>([]);

    final anyFilterActive = filter.activeDayFilter != null ||
        filter.ledgerType != null ||
        filter.categoryIds.isNotEmpty ||
        filter.searchQuery.isNotEmpty ||
        filter.memberBookId != null; // FAM-03 fix (Pitfall B)

    return Container(
      height: 44,
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppColors.borderDivider, width: 1),
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
                avatar: const Icon(
                  Icons.sort,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                label: Text(
                  _sortFieldLabel(sortConfig.sortField, context),
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textPrimary),
                ),
                onPressed: () =>
                    _showSortMenu(context, sortConfig),
                side: const BorderSide(
                    color: AppColors.accentPrimary, width: 1),
                backgroundColor: AppColors.card,
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
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
                  color: AppColors.textPrimary,
                ),
                onPressed: () =>
                    ref.read(listFilterProvider.notifier).setSort(
                      sortConfig.copyWith(
                        sortDirection:
                            sortConfig.sortDirection == SortDirection.desc
                                ? SortDirection.asc
                                : SortDirection.desc,
                      ),
                    ),
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 32, minHeight: 44),
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
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
                backgroundColor: filter.ledgerType == null
                    ? AppColors.backgroundMuted
                    : AppColors.card,
                side: BorderSide(
                  color: filter.ledgerType == null
                      ? AppColors.borderDefault
                      : AppColors.borderDefault,
                  width: 1,
                ),
                onPressed: () =>
                    ref.read(listFilterProvider.notifier).setLedgerFilter(null),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 4),
            // ── Ledger: 生存 chip (C-03c) ─────────────────────────────────
            Semantics(
              label: 'Survival ledger',
              selected: filter.ledgerType == LedgerType.survival,
              child: ActionChip(
                label: Text(
                  l10n.listLedgerSurvival,
                  style: AppTextStyles.caption.copyWith(
                    color: filter.ledgerType == LedgerType.survival
                        ? AppColors.survival
                        : AppColors.textSecondary,
                  ),
                ),
                backgroundColor: filter.ledgerType == LedgerType.survival
                    ? AppColors.survivalLight
                    : AppColors.card,
                side: BorderSide(
                  color: filter.ledgerType == LedgerType.survival
                      ? AppColors.survival
                      : AppColors.borderDefault,
                  width: 1,
                ),
                onPressed: () => ref
                    .read(listFilterProvider.notifier)
                    .setLedgerFilter(
                      filter.ledgerType == LedgerType.survival
                          ? null
                          : LedgerType.survival,
                    ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 4),
            // ── Ledger: 魂 chip (C-03c) ───────────────────────────────────
            Semantics(
              label: 'Soul ledger',
              selected: filter.ledgerType == LedgerType.soul,
              child: ActionChip(
                label: Text(
                  l10n.listLedgerSoul,
                  style: AppTextStyles.caption.copyWith(
                    color: filter.ledgerType == LedgerType.soul
                        ? AppColors.soul
                        : AppColors.textSecondary,
                  ),
                ),
                backgroundColor: filter.ledgerType == LedgerType.soul
                    ? AppColors.soulLight
                    : AppColors.card,
                side: BorderSide(
                  color: filter.ledgerType == LedgerType.soul
                      ? AppColors.soul
                      : AppColors.borderDefault,
                  width: 1,
                ),
                onPressed: () => ref
                    .read(listFilterProvider.notifier)
                    .setLedgerFilter(
                      filter.ledgerType == LedgerType.soul
                          ? null
                          : LedgerType.soul,
                    ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 8),
            // ── Category count chip (C-03d) ───────────────────────────────
            Semantics(
              label: 'Filter by category',
              child: ActionChip(
                avatar: const Icon(
                  Icons.category_outlined,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                label: Text(
                  filter.categoryIds.isEmpty
                      ? l10n.listCategoryChip
                      : l10n.listCategoryChipN(filter.categoryIds.length),
                  style: AppTextStyles.caption.copyWith(
                    color: filter.categoryIds.isEmpty
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                  ),
                ),
                backgroundColor: filter.categoryIds.isEmpty
                    ? AppColors.card
                    : AppColors.backgroundMuted,
                side: BorderSide(
                  color: filter.categoryIds.isEmpty
                      ? AppColors.borderDefault
                      : AppColors.borderDefault,
                  width: 1,
                ),
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
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: l10n.listSearchHint,
                        hintStyle: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        prefixIcon: const Icon(
                          Icons.search,
                          size: 16,
                          color: AppColors.textSecondary,
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
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: AppColors.textSecondary,
                                ),
                              )
                            : null,
                        suffixIconConstraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                              color: AppColors.borderDefault, width: 1),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                              color: AppColors.borderDefault, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                              color: AppColors.accentPrimary, width: 1),
                        ),
                      ),
                    ),
                  )
                : Semantics(
                    label: 'Search transactions',
                    child: IconButton(
                      icon: const Icon(
                        Icons.search,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () =>
                          setState(() => _searchExpanded = true),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                          minWidth: 44, minHeight: 44),
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
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
                label: Text(
                  S.of(context).listMineOnly,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textPrimary),
                ),
                backgroundColor: AppColors.backgroundMuted,
                side: const BorderSide(
                    color: AppColors.borderDefault, width: 1),
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
                              ? AppColors.shared
                              : AppColors.textSecondary,
                        ),
                      ),
                      backgroundColor:
                          isSelected ? AppColors.sharedLight : AppColors.card,
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.sharedBorder
                            : AppColors.borderDefault,
                        width: 1,
                      ),
                      onPressed: () => ref
                          .read(listFilterProvider.notifier)
                          .setMemberFilter(
                              isSelected ? null : info.book.id),
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                    ),
                  );
                }).toList(),
                loading: () => const [],
                // ignore: avoid_types_on_closure_parameters
                error: (Object e, StackTrace s) => const [],
              ),
            ],
            // ── Conditional clear chip (C-03f) ────────────────────────────
            if (anyFilterActive) ...[
              const SizedBox(width: 8),
              Semantics(
                label: 'Clear all filters',
                child: ActionChip(
                  avatar: const Icon(
                    Icons.clear_all,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  label: Text(
                    l10n.listClearAll,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  backgroundColor: AppColors.backgroundMuted,
                  side: const BorderSide(
                      color: AppColors.borderDefault, width: 1),
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

