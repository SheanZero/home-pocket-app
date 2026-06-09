import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/accounting/category_localization_service.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';
import '../../../accounting/domain/models/category.dart';
import '../../../accounting/presentation/providers/repository_providers.dart'
    show categoryRepositoryProvider;
import '../../../accounting/presentation/utils/category_display_utils.dart';
import '../../../settings/presentation/providers/state_locale.dart';

/// Shopping-only L1-only category filter bottom sheet (D-3, D-4, D-5).
///
/// A SHOPPING-specific copy of the list-tab [CategoryFilterSheet] that renders
/// ONLY level-1 (L1) category rows — the 列表 tab sheet keeps its full L1+L2
/// cascade behaviour and is deliberately left untouched (D-3).
///
/// Selecting an L1 row toggles the union of that L1's L2 leaf child ids
/// (shopping items are tagged with leaf ids), so the under-the-hood selected
/// set is always a set of leaf ids (D-4).
///
/// Each L1 row renders a real leading [Icon] via [resolveCategoryIcon] rather
/// than leaking the raw icon-name string into the label (D-5).
///
/// Pre-populated from [initialSelected]. On "Apply" the selected leaf ids are
/// passed to [onApply] (non-nullable here — the shopping caller always owns the
/// write target via `shoppingFilterProvider`); this sheet never imports or
/// writes to `listFilterProvider`. Cancel closes without touching any provider.
class ShoppingCategoryFilterSheet extends ConsumerStatefulWidget {
  const ShoppingCategoryFilterSheet({
    super.key,
    required this.initialSelected,
    required this.onApply,
  });

  final Set<String> initialSelected;

  /// Invoked when the user taps Apply with the union of selected leaf ids.
  final ValueChanged<Set<String>> onApply;

  @override
  ConsumerState<ShoppingCategoryFilterSheet> createState() =>
      _ShoppingCategoryFilterSheetState();
}

class _ShoppingCategoryFilterSheetState
    extends ConsumerState<ShoppingCategoryFilterSheet> {
  late Set<String> _localSelected;
  List<Category> _l1Categories = [];
  Map<String, List<Category>> _l2ByParent = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _localSelected = Set<String>.from(widget.initialSelected);
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

    l1.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    for (final children in l2Map.values) {
      children.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    }

    if (mounted) {
      setState(() {
        _l1Categories = l1;
        _l2ByParent = l2Map;
        _isLoading = false;
      });
    }
  }

  /// True when every L2 leaf child of [l1Id] is currently selected.
  bool _isL1AllSelected(String l1Id) {
    final childIds = (_l2ByParent[l1Id] ?? []).map((c) => c.id);
    return childIds.isNotEmpty && _localSelected.containsAll(childIds);
  }

  /// Toggles the union of [l1Id]'s L2 leaf child ids (D-4).
  void _toggleL1(String l1Id) {
    final childIds = (_l2ByParent[l1Id] ?? []).map((c) => c.id);
    setState(() {
      final next = {..._localSelected};
      if (_isL1AllSelected(l1Id)) {
        next.removeAll(childIds);
      } else {
        next.addAll(childIds);
      }
      _localSelected = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(currentLocaleProvider).value ?? const Locale('ja');
    final screenHeight = MediaQuery.of(context).size.height;

    final palette = context.palette;
    return Container(
      height: screenHeight * 0.65,
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Drag handle
          Padding(
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
          ),
          // Header row
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  S.of(context).listCategorySheetTitle,
                  style: AppTextStyles.titleMedium,
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _localSelected = <String>{});
                  },
                  child: Text(
                    S.of(context).listCategorySheetClear,
                    style: AppTextStyles.caption.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: palette.borderDivider,
          ),
          // Category list — L1 rows only (D-4)
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _l1Categories.length,
                    itemBuilder: (context, index) {
                      final l1 = _l1Categories[index];
                      final isAllSelected = _isL1AllSelected(l1.id);
                      final resolvedName = CategoryLocalizationService.resolve(
                        l1.name,
                        locale,
                      );
                      return Column(
                        children: [
                          // L1 row
                          InkWell(
                            onTap: () => _toggleL1(l1.id),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: isAllSelected,
                                    onChanged: (_) => _toggleL1(l1.id),
                                  ),
                                  const SizedBox(width: 12),
                                  // D-5: real leading Icon, not the raw
                                  // icon-name string (fixes "restaurant 食费").
                                  Icon(
                                    resolveCategoryIcon(l1.icon),
                                    size: 20,
                                    color: palette.textSecondary,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      resolvedName,
                                      style: AppTextStyles.titleSmall,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (index < _l1Categories.length - 1)
                            Divider(
                              height: 1,
                              thickness: 1,
                              color: palette.borderDivider,
                              indent: 16,
                              endIndent: 16,
                            ),
                        ],
                      );
                    },
                  ),
          ),
          // Apply bar
          Container(
            height: 56,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: palette.borderDivider, width: 1),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    S.of(context).listDeleteCancelButton,
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
                    onPressed: () {
                      widget.onApply(Set<String>.unmodifiable(_localSelected));
                      Navigator.pop(context);
                    },
                    child: Text(
                      _localSelected.isEmpty
                          ? S.of(context).listCategorySheetApply
                          : S
                              .of(context)
                              .listCategorySheetApplyN(_localSelected.length),
                      style: AppTextStyles.titleSmall.copyWith(
                        color: palette.card,
                      ),
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
