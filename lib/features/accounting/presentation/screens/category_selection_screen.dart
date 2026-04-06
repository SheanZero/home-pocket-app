import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../infrastructure/category/category_service.dart';
import '../../../settings/presentation/providers/locale_provider.dart';
import '../../domain/models/category.dart';
import '../utils/category_display_utils.dart';
import '../providers/repository_providers.dart';

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
      final name = CategoryService.resolve(cat.name, locale);
      if (name.toLowerCase().contains(q)) return true;
      // Also show L1 if any L2 child matches
      final children = _l2ByParent[cat.id] ?? [];
      return children.any(
        (c) =>
            CategoryService.resolve(c.name, locale).toLowerCase().contains(q),
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
              CategoryService.resolve(c.name, locale).toLowerCase().contains(q),
        )
        .toList();
  }

  Color _parseColor(String colorHex) {
    final hex = colorHex.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final localeAsync = ref.watch(currentLocaleProvider);
    final locale = localeAsync.valueOrNull ?? const Locale('ja');
    final filteredL1 = _getFilteredL1(locale);
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.selectCategory,
          style: AppTextStyles.headlineMedium.copyWith(
            color: isDark ? AppColorsDark.textPrimary : AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search bar
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
                // Category list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
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
                            _expandedL1Id = _expandedL1Id == l1.id
                                ? null
                                : l1.id;
                          });
                        },
                        onChildSelected: (child) {
                          Navigator.pop(context, child);
                        },
                        isDark: isDark,
                        addSubcategoryLabel: l10n.addSubcategory,
                        resolveIcon: resolveCategoryIcon,
                        parseColor: _parseColor,
                        resolveName: (key) =>
                            CategoryService.resolve(key, locale),
                      );
                    },
                  ),
                ),
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
