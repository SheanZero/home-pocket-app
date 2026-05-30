import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/accounting/category_localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';
import '../../../accounting/domain/models/category.dart';
import '../../../accounting/presentation/providers/repository_providers.dart'
    show categoryRepositoryProvider;
import '../../../settings/presentation/providers/state_locale.dart';
import '../providers/state_list_filter.dart';

/// Multi-select category filter bottom sheet (D-02: L1→L2 cascade + tristate).
///
/// Pre-populated from [listFilterProvider]'s current [categoryIds].
/// Writes via [listFilterProvider.notifier.setCategories()] only on "Apply".
/// Cancel closes without touching the provider.
class CategoryFilterSheet extends ConsumerStatefulWidget {
  const CategoryFilterSheet({super.key, required this.initialSelected});

  final Set<String> initialSelected;

  @override
  ConsumerState<CategoryFilterSheet> createState() =>
      _CategoryFilterSheetState();
}

enum _L1SelectState { none, partial, all }

class _CategoryFilterSheetState extends ConsumerState<CategoryFilterSheet> {
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

  _L1SelectState _l1State(String l1Id) {
    final children = _l2ByParent[l1Id] ?? [];
    if (children.isEmpty) return _L1SelectState.none;
    final count = children.where((c) => _localSelected.contains(c.id)).length;
    if (count == 0) return _L1SelectState.none;
    if (count == children.length) return _L1SelectState.all;
    return _L1SelectState.partial;
  }

  void _toggleL1(String l1Id) {
    final children = _l2ByParent[l1Id] ?? [];
    final s = _l1State(l1Id);
    setState(() {
      if (s == _L1SelectState.all) {
        for (final c in children) {
          _localSelected.remove(c.id);
        }
      } else {
        for (final c in children) {
          _localSelected.add(c.id);
        }
      }
    });
  }

  void _toggleL2(String l2Id) {
    setState(() {
      if (_localSelected.contains(l2Id)) {
        _localSelected.remove(l2Id);
      } else {
        _localSelected.add(l2Id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(currentLocaleProvider).value ?? const Locale('ja');
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.65,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
                  color: AppColors.borderDivider,
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
                    setState(() => _localSelected.clear());
                  },
                  child: Text(
                    S.of(context).listCategorySheetClear,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(
            height: 1,
            thickness: 1,
            color: AppColors.borderDivider,
          ),
          // Category list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _l1Categories.length,
                    itemBuilder: (context, index) {
                      final l1 = _l1Categories[index];
                      final l2Children = _l2ByParent[l1.id] ?? [];
                      final s = _l1State(l1.id);
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
                                    tristate: s == _L1SelectState.partial,
                                    value: s == _L1SelectState.partial
                                        ? null
                                        : (s == _L1SelectState.all),
                                    onChanged: (_) => _toggleL1(l1.id),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      '${l1.icon.isNotEmpty ? '${l1.icon} ' : ''}$resolvedName',
                                      style: AppTextStyles.titleSmall,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // L2 rows
                          ...l2Children.map((l2) {
                            final isSelected = _localSelected.contains(l2.id);
                            final l2Name = CategoryLocalizationService.resolve(
                              l2.name,
                              locale,
                            );
                            return InkWell(
                              onTap: () => _toggleL2(l2.id),
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: 40,
                                  right: 16,
                                  top: 8,
                                  bottom: 8,
                                ),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      tristate: false,
                                      value: isSelected,
                                      onChanged: (_) => _toggleL2(l2.id),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        l2Name,
                                        style: AppTextStyles.bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                          if (index < _l1Categories.length - 1)
                            const Divider(
                              height: 1,
                              thickness: 1,
                              color: AppColors.borderDivider,
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
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.borderDivider, width: 1),
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
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accentPrimary,
                    ),
                    onPressed: () {
                      ref
                          .read(listFilterProvider.notifier)
                          .setCategories(Set<String>.unmodifiable(_localSelected));
                      Navigator.pop(context);
                    },
                    child: Text(
                      _localSelected.isEmpty
                          ? S.of(context).listCategorySheetApply
                          : S.of(context).listCategorySheetApplyN(_localSelected.length),
                      style: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.card,
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
