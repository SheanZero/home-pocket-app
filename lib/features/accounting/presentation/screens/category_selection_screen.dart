import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/accounting/create_category_use_case.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../shared/widgets/feedback_toast.dart';
import '../../../../shared/widgets/soft_confirm_dialog.dart';
import '../../../../application/accounting/category_localization_service.dart';
import '../../../settings/presentation/providers/state_locale.dart';
import '../../domain/models/category.dart';
import '../../domain/models/category_reorder_state.dart';
import '../../domain/models/transaction.dart';
import '../providers/state_category_reorder.dart';
import '../providers/repository_providers.dart';
import '../utils/category_display_utils.dart';
import '../widgets/category_reorder_row.dart';

const _categoryIconChoices = <String>[
  'category',
  'restaurant',
  'local_mall',
  'home',
  'directions_car',
  'flight',
  'sports_esports',
  'pets',
  'school',
  'local_hospital',
  'card_giftcard',
  'savings',
];

const _categoryColorChoices = <String>[
  '#47B88A',
  '#E85A4F',
  '#F59E0B',
  '#22A6B3',
  '#3B82F6',
  '#8B5CF6',
  '#EC4899',
];

/// Full-screen category picker with expandable L1 groups and L2 chip selection.
///
/// Loads categories from [categoryRepositoryProvider], groups L2 under L1
/// parents, and supports search filtering. Pops with the selected [Category].
class CategorySelectionScreen extends ConsumerStatefulWidget {
  const CategorySelectionScreen({
    super.key,
    this.selectedCategoryId,
    this.suggestedLedgerType,
  });

  /// Currently selected category ID (for pre-selection highlight).
  final String? selectedCategoryId;

  /// Initial ledger choice shown when the user creates an L1 category.
  ///
  /// Callers with an active form ledger should pass it; standalone entry
  /// points fall back to daily in the creation sheet.
  final LedgerType? suggestedLedgerType;

  @override
  ConsumerState<CategorySelectionScreen> createState() =>
      _CategorySelectionScreenState();
}

class _CategorySelectionScreenState
    extends ConsumerState<CategorySelectionScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _expandedL1Id;
  String? _expandedL1IdInEdit;
  List<Category> _l1Categories = [];
  Map<String, List<Category>> _l2ByParent = {};
  bool _isLoading = true;
  bool _didApplyInitialSelection = false;

  /// One-shot scroll target: the L1 group that contains the pre-selected
  /// category. Set during [_loadCategories] and cleared after the first
  /// post-frame scroll so manual scrolling is never forced back.
  String? _pendingScrollL1Id;
  final _selectedGroupKey = GlobalKey();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories({
    String? preferredExpandedL1Id,
    bool scrollToPreferred = false,
  }) async {
    final repo = ref.read(categoryRepositoryProvider);
    final all = await repo.findActive();

    final l1 = <Category>[];
    final l2Map = <String, List<Category>>{};

    for (final cat in all) {
      if (cat.level == 1) {
        l1.add(cat);
      } else if (cat.level == 2 && cat.parentId != null) {
        l2Map.putIfAbsent(cat.parentId!, () => []).add(cat);
      }
    }

    // Sort L1 by sortOrder, L2 by sortOrder
    l1.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    for (final children in l2Map.values) {
      children.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    }

    if (preferredExpandedL1Id != null) {
      _expandedL1Id = preferredExpandedL1Id;
      if (scrollToPreferred) {
        _pendingScrollL1Id = preferredExpandedL1Id;
      }
    } else if (!_didApplyInitialSelection &&
        widget.selectedCategoryId != null) {
      // Auto-expand the parent of the initially selected category once.
      for (final entry in l2Map.entries) {
        if (entry.value.any((c) => c.id == widget.selectedCategoryId)) {
          _expandedL1Id = entry.key;
          break;
        }
      }
      // If selected is L1, expand it
      if (_expandedL1Id == null &&
          l1.any((c) => c.id == widget.selectedCategoryId)) {
        _expandedL1Id = widget.selectedCategoryId;
      }
      // Queue a one-shot scroll to the selected L1 group (null when the
      // selected id is stale and resolves to no L1).
      _pendingScrollL1Id = _expandedL1Id;
    }
    _didApplyInitialSelection = true;

    if (mounted) {
      setState(() {
        _l1Categories = l1;
        _l2ByParent = l2Map;
        _isLoading = false;
      });
      if (_pendingScrollL1Id != null) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _scrollToSelectedGroup(),
        );
      }
    }
  }

  /// Scrolls the read-mode list so the pre-selected L1 group aligns to the top
  /// of the viewport. Runs once, then clears [_pendingScrollL1Id].
  ///
  /// Two phases because [ListView.builder] only builds near-viewport items: a
  /// rough jump (estimated group extent) brings the target into the build
  /// range, then [Scrollable.ensureVisible] refines to an exact, animated
  /// top-aligned position. No-op for a stale id (target never resolves).
  void _scrollToSelectedGroup() {
    if (!mounted) return;
    final id = _pendingScrollL1Id;
    final index = id == null ? -1 : _l1Categories.indexWhere((c) => c.id == id);
    if (index < 0 || !_scrollController.hasClients) {
      _pendingScrollL1Id = null;
      return;
    }

    // Phase 1 — rough jump so the lazy list lays out the target group.
    const estimatedGroupExtent = 72.0;
    const listTopPadding = 12.0;
    final position = _scrollController.position;
    final estimate = (listTopPadding + index * estimatedGroupExtent).clamp(
      0.0,
      position.maxScrollExtent,
    );
    _scrollController.jumpTo(estimate);

    // Phase 2 — refine to an exact top-aligned position once laid out.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pendingScrollL1Id = null;
      if (!mounted) return;
      final ctx = _selectedGroupKey.currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    });
  }

  List<Category> _getFilteredL1(Locale locale) {
    if (_searchQuery.isEmpty) return _l1Categories;
    final q = _searchQuery.toLowerCase();
    return _l1Categories.where((cat) {
      final name = CategoryLocalizationService.resolve(cat.name, locale);
      if (name.toLowerCase().contains(q)) return true;
      // Also show L1 if any L2 child matches
      final children = _l2ByParent[cat.id] ?? [];
      return children.any(
        (c) => CategoryLocalizationService.resolve(
          c.name,
          locale,
        ).toLowerCase().contains(q),
      );
    }).toList();
  }

  List<Category> _getFilteredL2(String parentId, Locale locale) {
    final children = _l2ByParent[parentId] ?? [];
    if (_searchQuery.isEmpty) return children;
    final q = _searchQuery.toLowerCase();
    return children
        .where(
          (c) => CategoryLocalizationService.resolve(
            c.name,
            locale,
          ).toLowerCase().contains(q),
        )
        .toList();
  }

  Color _parseColor(String colorHex) {
    final hex = colorHex.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  void _onEnterReorderMode() {
    ref
        .read(categoryReorderProvider.notifier)
        .enterEditing(l1: _l1Categories, l2ByParent: _l2ByParent);
    _searchController.clear();
    setState(() => _searchQuery = '');
  }

  void _onLeadingTap(BuildContext context, CategoryReorderState reorderState) {
    if (reorderState.isEditing && reorderState.isDirty) {
      _showDiscardDialog();
      return;
    }
    if (reorderState.isEditing) {
      ref.read(categoryReorderProvider.notifier).cancel();
      return;
    }
    Navigator.pop(context);
  }

  Future<void> _onSave() async {
    try {
      await ref.read(categoryReorderProvider.notifier).save();
      await _loadCategories();
      if (!mounted) return;
      showSuccessFeedback(context, S.of(context).orderUpdated);
    } catch (_) {
      if (!mounted) return;
      showErrorFeedback(context, S.of(context).orderSaveFailed);
    }
  }

  Future<void> _showDiscardDialog() async {
    final l10n = S.of(context);
    final discard = await showSoftConfirmDialog(
      context,
      title: l10n.discardUnsavedChanges,
      body: l10n.discardUnsavedChangesBody,
      confirmLabel: l10n.discard,
      cancelLabel: l10n.keepEditing,
    );
    if (discard) {
      ref.read(categoryReorderProvider.notifier).cancel();
    }
  }

  Set<String> _localizedSiblingNames({
    required Locale locale,
    String? parentId,
  }) {
    final siblings = parentId == null
        ? _l1Categories
        : _l2ByParent[parentId] ?? const <Category>[];
    return {
      for (final category in siblings)
        CategoryLocalizationService.resolve(
          category.name,
          locale,
        ).trim().toLowerCase(),
    };
  }

  Future<void> _addL1(Locale locale) async {
    final draft = await showModalBottomSheet<_AddCategoryDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddCategorySheet(
        title: S.of(context).addL1CategoryTitle,
        existingNames: _localizedSiblingNames(locale: locale),
        initialLedgerType: widget.suggestedLedgerType ?? LedgerType.daily,
        showLedgerChoice: true,
        showAppearanceChoice: true,
      ),
    );
    if (draft == null || !mounted) return;

    final result = await ref
        .read(createCategoryUseCaseProvider)
        .execute(
          CreateCategoryParams(
            name: draft.name,
            ledgerType: draft.ledgerType,
            icon: draft.icon,
            color: draft.color,
          ),
        );
    if (!mounted) return;
    if (result.isError || result.data == null) {
      _showCreateError(result.error);
      return;
    }

    _searchController.clear();
    setState(() => _searchQuery = '');
    await _loadCategories(
      preferredExpandedL1Id: result.data!.id,
      scrollToPreferred: true,
    );
    if (!mounted) return;
    showSuccessFeedback(context, S.of(context).categoryAdded);
  }

  Future<void> _addL2(Category parent, Locale locale) async {
    final parentName = CategoryLocalizationService.resolve(parent.name, locale);
    final draft = await showModalBottomSheet<_AddCategoryDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddCategorySheet(
        title: S.of(context).addL2CategoryTitle(parentName),
        existingNames: _localizedSiblingNames(
          locale: locale,
          parentId: parent.id,
        ),
        initialLedgerType: widget.suggestedLedgerType ?? LedgerType.daily,
        showLedgerChoice: false,
        showAppearanceChoice: false,
      ),
    );
    if (draft == null || !mounted) return;

    final result = await ref
        .read(createCategoryUseCaseProvider)
        .execute(CreateCategoryParams(name: draft.name, parentId: parent.id));
    if (!mounted) return;
    if (result.isError || result.data == null) {
      _showCreateError(result.error);
      return;
    }

    Navigator.pop(context, result.data);
  }

  void _showCreateError(String? error) {
    final l10n = S.of(context);
    final message = switch (error) {
      'emptyName' => l10n.categoryNameRequired,
      'nameTooLong' => l10n.categoryNameTooLong,
      'duplicateName' => l10n.categoryNameExists,
      _ => l10n.categoryAddFailed,
    };
    showErrorFeedback(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final localeAsync = ref.watch(currentLocaleProvider);
    final locale = localeAsync.value ?? const Locale('ja');
    final filteredL1 = _getFilteredL1(locale);
    final palette = context.palette;
    final reorderState = ref.watch(categoryReorderProvider);
    final isEditing = reorderState.isEditing;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.card,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 56,
        shape: Border(bottom: BorderSide(color: palette.borderDefault)),
        leading: IconButton(
          icon: Icon(Icons.close, color: palette.textPrimary),
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          onPressed: () => _onLeadingTap(context, reorderState),
        ),
        title: Text(
          isEditing ? l10n.editCategoryOrder : l10n.selectCategory,
          style: AppTextStyles.pageTitle.copyWith(color: palette.textPrimary),
        ),
        centerTitle: true,
        actions: isEditing
            ? [
                TextButton(
                  onPressed: _onSave,
                  child: Text(
                    l10n.save,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: palette.accentPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ]
            : [
                IconButton(
                  icon: Icon(Icons.reorder, color: palette.textSecondary),
                  tooltip: l10n.editCategoryOrder,
                  onPressed: _onEnterReorderMode,
                ),
              ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (!isEditing)
                  Container(
                    color: palette.card,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: SizedBox(
                      height: 48,
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) => setState(() => _searchQuery = v),
                        style: AppTextStyles.body.copyWith(
                          color: palette.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: l10n.searchCategory,
                          hintStyle: AppTextStyles.body.copyWith(
                            color: palette.textSecondary,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: palette.textSecondary,
                            size: 21,
                          ),
                          filled: true,
                          fillColor: palette.backgroundMuted,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: isEditing
                      ? _buildReorderBody(reorderState, locale)
                      : _buildReadBody(filteredL1, locale, l10n),
                ),
                if (!isEditing)
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          palette.background.withValues(alpha: 0.65),
                          palette.background,
                        ],
                      ),
                    ),
                    child: Material(
                      color: palette.card,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        key: const ValueKey('category-add-l1'),
                        onTap: () => _addL1(locale),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: palette.borderDefault),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_circle_outline,
                                size: 18,
                                color: palette.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                l10n.addCategory,
                                style: AppTextStyles.label.copyWith(
                                  color: palette.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildReadBody(List<Category> filteredL1, Locale locale, S l10n) {
    if (filteredL1.isEmpty) {
      final palette = context.palette;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off, size: 30, color: palette.textTertiary),
              const SizedBox(height: 8),
              Text(
                l10n.noMatchingCategories,
                style: AppTextStyles.body.copyWith(
                  color: palette.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: filteredL1.length,
      itemBuilder: (context, index) {
        final l1 = filteredL1[index];
        return _CategoryGroup(
          key: l1.id == _pendingScrollL1Id ? _selectedGroupKey : null,
          category: l1,
          children: _getFilteredL2(l1.id, locale),
          isExpanded: _expandedL1Id == l1.id,
          selectedCategoryId: widget.selectedCategoryId,
          onToggle: () {
            setState(() {
              _expandedL1Id = _expandedL1Id == l1.id ? null : l1.id;
            });
          },
          onChildSelected: (child) {
            Navigator.pop(context, child);
          },
          onAddSubcategory: () => _addL2(l1, locale),
          addSubcategoryLabel: l10n.addSubcategory,
          resolveIcon: resolveCategoryIcon,
          parseColor: _parseColor,
          resolveName: (key) =>
              CategoryLocalizationService.resolve(key, locale),
        );
      },
    );
  }

  Widget _buildReorderBody(CategoryReorderState state, Locale locale) {
    return Column(
      children: [
        _buildHintBanner(),
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverReorderableList(
                itemCount: state.l1.length,
                onReorderItem: (o, n) => ref
                    .read(categoryReorderProvider.notifier)
                    .reorderL1(o, n > o ? n + 1 : n),
                itemBuilder: (context, index) {
                  final l1 = state.l1[index];
                  final expanded = _expandedL1IdInEdit == l1.id;
                  final children = state.l2ByParent[l1.id] ?? const [];
                  final color = _parseColor(l1.color);
                  return _L1ReorderTile(
                    key: ValueKey('l1_${l1.id}'),
                    index: index,
                    category: l1,
                    categoryColor: color,
                    expanded: expanded,
                    children: children,
                    l2Colors: {
                      for (final c in children) c.id: _parseColor(c.color),
                    },
                    onToggle: () => setState(
                      () => _expandedL1IdInEdit = expanded ? null : l1.id,
                    ),
                    onReorderChild: (o, n) => ref
                        .read(categoryReorderProvider.notifier)
                        .reorderL2(l1.id, o, n),
                    locale: locale,
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHintBanner() {
    final palette = context.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: palette.backgroundMuted,
      child: Row(
        children: [
          Icon(Icons.drag_indicator, size: 18, color: palette.accentPrimary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              S.of(context).dragToReorder,
              style: AppTextStyles.bodyMedium.copyWith(
                color: palette.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class _L1ReorderTile extends StatelessWidget {
  const _L1ReorderTile({
    super.key,
    required this.index,
    required this.category,
    required this.categoryColor,
    required this.expanded,
    required this.children,
    required this.l2Colors,
    required this.onToggle,
    required this.onReorderChild,
    required this.locale,
  });

  final int index;
  final Category category;
  final Color categoryColor;
  final bool expanded;
  final List<Category> children;
  final Map<String, Color> l2Colors;
  final VoidCallback onToggle;
  final void Function(int, int) onReorderChild;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: ValueKey('tile_${category.id}'),
      mainAxisSize: MainAxisSize.min,
      children: [
        ReorderableDelayedDragStartListener(
          index: index,
          child: GestureDetector(
            onTap: onToggle,
            child: CategoryReorderRow(
              label: CategoryLocalizationService.resolve(category.name, locale),
              iconData: resolveCategoryIcon(category.icon),
              color: categoryColor,
              variant: CategoryReorderRowVariant.l1,
            ),
          ),
        ),
        if (expanded && children.isNotEmpty)
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: children.length,
            buildDefaultDragHandles: false,
            onReorderItem: (o, n) => onReorderChild(o, n > o ? n + 1 : n),
            itemBuilder: (ctx, i) {
              final child = children[i];
              final palette = ctx.palette;
              final childColor = l2Colors[child.id] ?? palette.textSecondary;
              return Padding(
                key: ValueKey('l2_${child.id}'),
                padding: const EdgeInsets.only(left: 24, bottom: 4),
                child: ReorderableDragStartListener(
                  index: i,
                  child: CategoryReorderRow(
                    label: CategoryLocalizationService.resolve(
                      child.name,
                      locale,
                    ),
                    iconData: resolveCategoryIcon(child.icon),
                    color: childColor,
                    variant: CategoryReorderRowVariant.l2,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _CategoryGroup extends StatelessWidget {
  const _CategoryGroup({
    super.key,
    required this.category,
    required this.children,
    required this.isExpanded,
    required this.selectedCategoryId,
    required this.onToggle,
    required this.onChildSelected,
    required this.onAddSubcategory,
    required this.addSubcategoryLabel,
    required this.resolveIcon,
    required this.parseColor,
    required this.resolveName,
  });

  final Category category;
  final List<Category> children;
  final bool isExpanded;
  final String? selectedCategoryId;
  final VoidCallback onToggle;
  final ValueChanged<Category> onChildSelected;
  final VoidCallback onAddSubcategory;
  final String addSubcategoryLabel;
  final IconData Function(String) resolveIcon;
  final Color Function(String) parseColor;
  final String Function(String) resolveName;

  @override
  Widget build(BuildContext context) {
    final color = parseColor(category.color);
    final palette = context.palette;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isExpanded ? color : palette.borderDefault,
          width: isExpanded ? 1.5 : 1,
        ),
        boxShadow: isExpanded
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.09),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          // L1 header
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      resolveIcon(category.icon),
                      size: 20,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      resolveName(category.name),
                      style: AppTextStyles.titleMedium.copyWith(
                        color: palette.textPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.chevron_right,
                    color: palette.textSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          // L2 children (expanded)
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...children.map((child) {
                    final isSelected = selectedCategoryId == child.id;
                    return InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => onChildSelected(child),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 36),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color
                              : color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          resolveName(child.name),
                          style: AppTextStyles.label.copyWith(
                            color: isSelected ? Colors.white : color,
                          ),
                        ),
                      ),
                    );
                  }),
                  InkWell(
                    key: ValueKey('category-add-l2-${category.id}'),
                    onTap: onAddSubcategory,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 36),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: palette.borderDefault),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add,
                            size: 14,
                            color: palette.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            addSubcategoryLabel,
                            style: AppTextStyles.supporting.copyWith(
                              color: palette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AddCategoryDraft {
  const _AddCategoryDraft({
    required this.name,
    required this.ledgerType,
    required this.icon,
    required this.color,
  });

  final String name;
  final LedgerType ledgerType;
  final String icon;
  final String color;
}

class _AddCategorySheet extends StatefulWidget {
  const _AddCategorySheet({
    required this.title,
    required this.existingNames,
    required this.initialLedgerType,
    required this.showLedgerChoice,
    required this.showAppearanceChoice,
  });

  final String title;
  final Set<String> existingNames;
  final LedgerType initialLedgerType;
  final bool showLedgerChoice;
  final bool showAppearanceChoice;

  @override
  State<_AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends State<_AddCategorySheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  late LedgerType _ledgerType;
  String _icon = _categoryIconChoices.first;
  String _color = _categoryColorChoices.first;

  @override
  void initState() {
    super.initState();
    _ledgerType = widget.initialLedgerType;
  }

  String? _validateName(String? value) {
    final l10n = S.of(context);
    final name = value?.trim() ?? '';
    if (name.isEmpty) return l10n.categoryNameRequired;
    if (name.length > CreateCategoryUseCase.maxNameLength) {
      return l10n.categoryNameTooLong;
    }
    if (widget.existingNames.contains(name.toLowerCase())) {
      return l10n.categoryNameExists;
    }
    return null;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.pop(
      context,
      _AddCategoryDraft(
        name: _nameController.text.trim(),
        ledgerType: _ledgerType,
        icon: _icon,
        color: _color,
      ),
    );
  }

  Color get _selectedColor {
    final hex = _color.substring(1);
    return Color(int.parse('FF$hex', radix: 16));
  }

  Color _checkColor(Color color, AppPalette palette) =>
      color.computeLuminance() > 0.55 ? palette.textPrimary : Colors.white;

  Widget _buildAppearancePicker(S l10n, AppPalette palette) {
    final selectedColor = _selectedColor;
    final previewName = _nameController.text.trim().isEmpty
        ? l10n.categoryPreviewName
        : _nameController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.categoryAppearanceLabel,
          style: AppTextStyles.label.copyWith(color: palette.textPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.categoryAppearanceDescription,
          style: AppTextStyles.supporting.copyWith(
            color: palette.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selectedColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selectedColor.withValues(alpha: 0.34)),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: selectedColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  resolveCategoryIcon(_icon),
                  color: selectedColor,
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  previewName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.itemTitle.copyWith(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          l10n.categoryIconLabel,
          style: AppTextStyles.label.copyWith(color: palette.textPrimary),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: _categoryIconChoices.length,
          itemBuilder: (context, index) {
            final iconName = _categoryIconChoices[index];
            final selected = iconName == _icon;
            final semanticsLabel = '${l10n.categoryIconLabel} ${index + 1}';
            return Semantics(
              label: semanticsLabel,
              button: true,
              selected: selected,
              child: Tooltip(
                message: semanticsLabel,
                child: Material(
                  color: selected
                      ? selectedColor.withValues(alpha: 0.14)
                      : palette.backgroundMuted,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    key: ValueKey('category-icon-$iconName'),
                    onTap: () => setState(() => _icon = iconName),
                    borderRadius: BorderRadius.circular(12),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? selectedColor
                              : palette.borderDefault,
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Icon(
                        resolveCategoryIcon(iconName),
                        size: 21,
                        color: selected ? selectedColor : palette.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 14),
        Text(
          l10n.categoryColorLabel,
          style: AppTextStyles.label.copyWith(color: palette.textPrimary),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var index = 0; index < _categoryColorChoices.length; index++)
              Builder(
                builder: (context) {
                  final colorHex = _categoryColorChoices[index];
                  final color = Color(
                    int.parse('FF${colorHex.substring(1)}', radix: 16),
                  );
                  final selected = colorHex == _color;
                  final semanticsLabel =
                      '${l10n.categoryColorLabel} ${index + 1}';
                  return Semantics(
                    label: semanticsLabel,
                    button: true,
                    selected: selected,
                    child: Tooltip(
                      message: semanticsLabel,
                      child: InkResponse(
                        key: ValueKey(
                          'category-color-${colorHex.substring(1).toLowerCase()}',
                        ),
                        onTap: () => setState(() => _color = colorHex),
                        radius: 24,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                            border: Border.all(
                              color: selected
                                  ? palette.textPrimary
                                  : palette.card,
                              width: selected ? 2.5 : 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.18),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: selected
                              ? Icon(
                                  Icons.check,
                                  size: 20,
                                  color: _checkColor(color, palette),
                                )
                              : null,
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final palette = context.palette;
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: Material(
        color: palette.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height:
              (MediaQuery.sizeOf(context).height - viewInsets.bottom) * 0.92,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: Column(
                    children: [
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: palette.borderDefault,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.title,
                              style: AppTextStyles.sectionTitle.copyWith(
                                color: palette.textPrimary,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            tooltip: MaterialLocalizations.of(
                              context,
                            ).closeButtonTooltip,
                            icon: Icon(
                              Icons.close,
                              color: palette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          key: const ValueKey('category-create-name'),
                          controller: _nameController,
                          autofocus: !widget.showAppearanceChoice,
                          maxLength: CreateCategoryUseCase.maxNameLength,
                          textInputAction: TextInputAction.done,
                          onChanged: widget.showAppearanceChoice
                              ? (_) => setState(() {})
                              : null,
                          onFieldSubmitted: (_) => _submit(),
                          validator: _validateName,
                          style: AppTextStyles.body.copyWith(
                            color: palette.textPrimary,
                          ),
                          decoration: InputDecoration(
                            labelText: l10n.categoryNameLabel,
                            hintText: l10n.categoryNameHint,
                            filled: true,
                            fillColor: palette.backgroundMuted,
                            counterStyle: AppTextStyles.compact.copyWith(
                              color: palette.textTertiary,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: palette.borderDefault,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: palette.borderDefault,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: palette.borderInputActive,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        if (widget.showAppearanceChoice) ...[
                          const SizedBox(height: 16),
                          _buildAppearancePicker(l10n, palette),
                        ],
                        if (widget.showLedgerChoice) ...[
                          const SizedBox(height: 16),
                          Text(
                            l10n.categoryLedgerLabel,
                            style: AppTextStyles.label.copyWith(
                              color: palette.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.categoryLedgerDescription,
                            style: AppTextStyles.supporting.copyWith(
                              color: palette.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _LedgerChoice(
                                  key: const ValueKey('category-ledger-daily'),
                                  label: l10n.dailyLedger,
                                  icon: Icons.wallet_outlined,
                                  color: palette.daily,
                                  background: palette.dailyLight,
                                  selected: _ledgerType == LedgerType.daily,
                                  onTap: () => setState(
                                    () => _ledgerType = LedgerType.daily,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _LedgerChoice(
                                  key: const ValueKey('category-ledger-joy'),
                                  label: l10n.joyLedger,
                                  icon: Icons.favorite_border,
                                  color: palette.joy,
                                  background: palette.joyLight,
                                  selected: _ledgerType == LedgerType.joy,
                                  onTap: () => setState(
                                    () => _ledgerType = LedgerType.joy,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            side: BorderSide(color: palette.borderDefault),
                            foregroundColor: palette.textSecondary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: AppTextStyles.button,
                          ),
                          child: Text(l10n.cancel),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          key: const ValueKey('category-create-submit'),
                          onPressed: _submit,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            backgroundColor: palette.accentPrimary,
                            foregroundColor: palette.card,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: AppTextStyles.button,
                          ),
                          child: Text(l10n.createCategory),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}

class _LedgerChoice extends StatelessWidget {
  const _LedgerChoice({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.background,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color background;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? background : palette.card,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? color : palette.borderDefault,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.label.copyWith(
                      color: selected ? color : palette.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
