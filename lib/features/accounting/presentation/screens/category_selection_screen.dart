import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../application/accounting/category_localization_service.dart';
import '../../../settings/presentation/providers/state_locale.dart';
import '../../domain/models/category.dart';
import '../../domain/models/category_reorder_state.dart';
import '../providers/state_category_reorder.dart';
import '../providers/repository_providers.dart';
import '../utils/category_display_utils.dart';
import '../widgets/category_reorder_row.dart';

/// Full-screen category picker with expandable L1 groups and L2 chip selection.
///
/// Loads categories from [categoryRepositoryProvider], groups L2 under L1
/// parents, and supports search filtering. Pops with the selected [Category].
class CategorySelectionScreen extends ConsumerStatefulWidget {
  const CategorySelectionScreen({super.key, this.selectedCategoryId});

  /// Currently selected category ID (for pre-selection highlight).
  final String? selectedCategoryId;

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

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
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

    // Auto-expand the parent of the currently selected category
    if (widget.selectedCategoryId != null) {
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
    }

    if (mounted) {
      setState(() {
        _l1Categories = l1;
        _l2ByParent = l2Map;
        _isLoading = false;
      });
    }
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
        (c) =>
            CategoryLocalizationService.resolve(c.name, locale).toLowerCase().contains(q),
      );
    }).toList();
  }

  List<Category> _getFilteredL2(String parentId, Locale locale) {
    final children = _l2ByParent[parentId] ?? [];
    if (_searchQuery.isEmpty) return children;
    final q = _searchQuery.toLowerCase();
    return children
        .where(
          (c) =>
              CategoryLocalizationService.resolve(c.name, locale).toLowerCase().contains(q),
        )
        .toList();
  }

  Color _parseColor(String colorHex) {
    final hex = colorHex.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  void _onEnterReorderMode() {
    ref
        .read(categoryReorderNotifierProvider.notifier)
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
      ref.read(categoryReorderNotifierProvider.notifier).cancel();
      return;
    }
    Navigator.pop(context);
  }

  Future<void> _onSave() async {
    try {
      await ref.read(categoryReorderNotifierProvider.notifier).save();
      await _loadCategories();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(S.of(context).orderUpdated)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).orderSaveFailed),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showDiscardDialog() async {
    final l10n = S.of(context);
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.discardUnsavedChanges),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.keepEditing),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.discard),
          ),
        ],
      ),
    );
    if (discard == true) {
      ref.read(categoryReorderNotifierProvider.notifier).cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final localeAsync = ref.watch(currentLocaleProvider);
    final locale = localeAsync.valueOrNull ?? const Locale('ja');
    final filteredL1 = _getFilteredL1(locale);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reorderState = ref.watch(categoryReorderNotifierProvider);
    final isEditing = reorderState.isEditing;

    return Scaffold(
      backgroundColor: isDark
          ? AppColorsDark.background
          : AppColors.backgroundWarm,
      appBar: AppBar(
        backgroundColor: isDark ? AppColorsDark.card : AppColors.card,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: isDark ? AppColorsDark.textPrimary : AppColors.textPrimary,
          ),
          onPressed: () => _onLeadingTap(context, reorderState),
        ),
        title: Text(
          isEditing ? l10n.editCategoryOrder : l10n.selectCategory,
          style: AppTextStyles.headlineMedium.copyWith(
            color: isDark ? AppColorsDark.textPrimary : AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: isEditing
            ? [
                TextButton(
                  onPressed: _onSave,
                  child: Text(
                    l10n.save,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.accentPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ]
            : [
                IconButton(
                  icon: Icon(
                    Icons.reorder,
                    color: isDark
                        ? AppColorsDark.textSecondary
                        : AppColors.textSecondary,
                  ),
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
                    color: isDark ? AppColorsDark.card : AppColors.card,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: l10n.searchCategory,
                        hintStyle: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppColors.textSecondary,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? AppColorsDark.backgroundMuted
                            : AppColors.backgroundMuted,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: isEditing
                      ? _buildReorderBody(reorderState, locale, isDark)
                      : _buildReadBody(filteredL1, locale, isDark, l10n),
                ),
                if (!isEditing)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: GestureDetector(
                      onTap: () {},
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: isDark ? AppColorsDark.card : AppColors.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? AppColorsDark.borderDefault
                                : AppColors.borderDefault,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_circle_outline,
                              size: 18,
                              color: isDark
                                  ? AppColorsDark.textSecondary
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              l10n.addCategory,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: isDark
                                    ? AppColorsDark.textSecondary
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildReadBody(
    List<Category> filteredL1,
    Locale locale,
    bool isDark,
    S l10n,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: filteredL1.length,
      itemBuilder: (context, index) {
        final l1 = filteredL1[index];
        return _CategoryGroup(
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
          isDark: isDark,
          addSubcategoryLabel: l10n.addSubcategory,
          resolveIcon: resolveCategoryIcon,
          parseColor: _parseColor,
          resolveName: (key) => CategoryLocalizationService.resolve(key, locale),
        );
      },
    );
  }

  Widget _buildReorderBody(
    CategoryReorderState state,
    Locale locale,
    bool isDark,
  ) {
    return Column(
      children: [
        _buildHintBanner(isDark),
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverReorderableList(
                itemCount: state.l1.length,
                onReorder: (o, n) => ref
                    .read(categoryReorderNotifierProvider.notifier)
                    .reorderL1(o, n),
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
                        .read(categoryReorderNotifierProvider.notifier)
                        .reorderL2(l1.id, o, n),
                    locale: locale,
                    isDark: isDark,
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHintBanner(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: isDark ? AppColorsDark.backgroundMuted : AppColors.backgroundMuted,
      child: Row(
        children: [
          Icon(Icons.drag_indicator, size: 18, color: AppColors.accentPrimary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              S.of(context).dragToReorder,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark
                    ? AppColorsDark.textSecondary
                    : AppColors.textSecondary,
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
    required this.isDark,
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
  final bool isDark;

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
            onReorder: onReorderChild,
            itemBuilder: (ctx, i) {
              final child = children[i];
              final childColor = l2Colors[child.id] ?? const Color(0xFFABABAB);
              return Padding(
                key: ValueKey('l2_${child.id}'),
                padding: const EdgeInsets.only(left: 24, bottom: 4),
                child: ReorderableDragStartListener(
                  index: i,
                  child: CategoryReorderRow(
                    label: CategoryLocalizationService.resolve(child.name, locale),
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
    required this.category,
    required this.children,
    required this.isExpanded,
    required this.selectedCategoryId,
    required this.onToggle,
    required this.onChildSelected,
    required this.isDark,
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
  final bool isDark;
  final String addSubcategoryLabel;
  final IconData Function(String) resolveIcon;
  final Color Function(String) parseColor;
  final String Function(String) resolveName;

  @override
  Widget build(BuildContext context) {
    final color = parseColor(category.color);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColorsDark.card : AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isExpanded
              ? color
              : (isDark
                    ? AppColorsDark.borderDefault
                    : AppColors.borderDefault),
          width: isExpanded ? 1.5 : 1,
        ),
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
                        color: isDark
                            ? AppColorsDark.textPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.chevron_right,
                    color: isDark
                        ? AppColorsDark.textSecondary
                        : AppColors.textSecondary,
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
                    return GestureDetector(
                      onTap: () => onChildSelected(child),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color
                              : color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          resolveName(child.name),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: isSelected ? Colors.white : color,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? AppColorsDark.borderDefault
                              : AppColors.borderDefault,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add,
                            size: 14,
                            color: isDark
                                ? AppColorsDark.textSecondary
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            addSubcategoryLabel,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isDark
                                  ? AppColorsDark.textSecondary
                                  : AppColors.textSecondary,
                              fontSize: 12,
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
