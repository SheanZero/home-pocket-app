import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../infrastructure/category/category_service.dart';
import '../../../settings/presentation/providers/locale_provider.dart';
import '../../domain/models/category.dart';
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
            CategoryService.resolve(c.name, locale)
                .toLowerCase()
                .contains(q),
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
              CategoryService.resolve(c.name, locale)
                  .toLowerCase()
                  .contains(q),
        )
        .toList();
  }

  IconData _resolveIcon(String iconName) {
    // Map icon name strings to Material Icons
    const iconMap = <String, IconData>{
      'restaurant': Icons.restaurant,
      'local_mall': Icons.local_mall,
      'directions_bus': Icons.directions_bus,
      'sports_esports': Icons.sports_esports,
      'checkroom': Icons.checkroom,
      'people': Icons.people,
      'local_hospital': Icons.local_hospital,
      'school': Icons.school,
      'credit_card': Icons.credit_card,
      'flash_on': Icons.flash_on,
      'phone_iphone': Icons.phone_iphone,
      'home': Icons.home,
      'directions_car': Icons.directions_car,
      'account_balance': Icons.account_balance,
      'security': Icons.security,
      'star': Icons.star,
      'savings': Icons.savings,
      'more_horiz': Icons.more_horiz,
      'help_outline': Icons.help_outline,
      'shopping_basket': Icons.shopping_basket,
      'restaurant_menu': Icons.restaurant_menu,
      'free_breakfast': Icons.free_breakfast,
      'lunch_dining': Icons.lunch_dining,
      'dinner_dining': Icons.dinner_dining,
      'local_cafe': Icons.local_cafe,
      'cleaning_services': Icons.cleaning_services,
      'child_care': Icons.child_care,
      'pets': Icons.pets,
      'smoking_rooms': Icons.smoking_rooms,
      'train': Icons.train,
      'local_taxi': Icons.local_taxi,
      'flight': Icons.flight,
      'sports_tennis': Icons.sports_tennis,
      'event': Icons.event,
      'movie': Icons.movie,
      'videogame_asset': Icons.videogame_asset,
      'menu_book': Icons.menu_book,
      'luggage': Icons.luggage,
      'watch': Icons.watch,
      'dry_cleaning': Icons.dry_cleaning,
      'content_cut': Icons.content_cut,
      'face_retouching_natural': Icons.face_retouching_natural,
      'spa': Icons.spa,
      'local_laundry_service': Icons.local_laundry_service,
      'local_bar': Icons.local_bar,
      'card_giftcard': Icons.card_giftcard,
      'celebration': Icons.celebration,
      'fitness_center': Icons.fitness_center,
      'self_improvement': Icons.self_improvement,
      'medication': Icons.medication,
      'newspaper': Icons.newspaper,
      'cast_for_education': Icons.cast_for_education,
      'auto_stories': Icons.auto_stories,
      'edit_note': Icons.edit_note,
      'bolt': Icons.bolt,
      'water_drop': Icons.water_drop,
      'local_fire_department': Icons.local_fire_department,
      'smartphone': Icons.smartphone,
      'phone': Icons.phone,
      'wifi': Icons.wifi,
      'live_tv': Icons.live_tv,
      'info': Icons.info,
      'local_shipping': Icons.local_shipping,
      'apartment': Icons.apartment,
      'real_estate_agent': Icons.real_estate_agent,
      'corporate_fare': Icons.corporate_fare,
      'chair': Icons.chair,
      'kitchen': Icons.kitchen,
      'construction': Icons.construction,
      'shield': Icons.shield,
      'local_gas_station': Icons.local_gas_station,
      'local_parking': Icons.local_parking,
      'toll': Icons.toll,
      'payments': Icons.payments,
      'receipt_long': Icons.receipt_long,
      'build': Icons.build,
      'receipt': Icons.receipt,
      'elderly': Icons.elderly,
      'health_and_safety': Icons.health_and_safety,
      'favorite': Icons.favorite,
      'medical_services': Icons.medical_services,
      'weekend': Icons.weekend,
      'home_repair_service': Icons.home_repair_service,
      'favorite_border': Icons.favorite_border,
      'child_friendly': Icons.child_friendly,
      'accessible': Icons.accessible,
      'swap_horiz': Icons.swap_horiz,
      'send': Icons.send,
      'wallet': Icons.wallet,
      'business_center': Icons.business_center,
      'money_off': Icons.money_off,
      'category': Icons.category,
      'trending_up': Icons.trending_up,
      'attach_money': Icons.attach_money,
      'stars': Icons.stars,
    };
    return iconMap[iconName] ?? Icons.help_outline;
  }

  Color _parseColor(String colorHex) {
    final hex = colorHex.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final locale = ref.watch(currentLocaleProvider);
    final filteredL1 = _getFilteredL1(locale);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.selectCategory,
          style: AppTextStyles.headlineMedium,
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search bar
                Container(
                  color: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                      fillColor: const Color(0xFFF5F9FD),
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
                            _expandedL1Id =
                                _expandedL1Id == l1.id ? null : l1.id;
                          });
                        },
                        onChildSelected: (child) {
                          Navigator.pop(context, child);
                        },
                        resolveIcon: _resolveIcon,
                        parseColor: _parseColor,
                        resolveName: (key) =>
                            CategoryService.resolve(key, locale),
                      );
                    },
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
  final IconData Function(String) resolveIcon;
  final Color Function(String) parseColor;
  final String Function(String) resolveName;

  @override
  Widget build(BuildContext context) {
    final color = parseColor(category.color);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isExpanded
            ? Border.all(color: AppColors.survival, width: 1.5)
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
                      style: AppTextStyles.titleMedium,
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.expand_less
                        : Icons.chevron_right,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          // L2 children (expanded)
          if (isExpanded && children.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: children.map((child) {
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
                            ? AppColors.survival
                            : const Color(0xFFEEF4FA),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        resolveName(child.name),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isSelected
                              ? Colors.white
                              : AppColors.survival,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
