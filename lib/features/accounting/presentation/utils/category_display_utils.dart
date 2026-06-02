import 'package:flutter/material.dart';

import '../../../../application/accounting/category_localization_service.dart';
import '../../../../shared/constants/default_categories.dart';
import '../../domain/models/category.dart';

String formatCategoryPath({
  required Category category,
  Category? parentCategory,
  required Locale locale,
}) {
  final childName = CategoryLocalizationService.resolve(category.name, locale);
  if (parentCategory == null || parentCategory.id == category.id) {
    return childName;
  }

  final parentName = CategoryLocalizationService.resolve(
    parentCategory.name,
    locale,
  );
  return '$parentName > $childName';
}

Category? resolveParentCategory(
  Category category,
  Map<String, Category> categoryById,
) {
  if (category.level == 1) return category;
  final parentId = category.parentId;
  if (parentId == null) return null;
  return categoryById[parentId];
}

/// Pure, provider-free resolver from a category id to a Material [IconData].
///
/// Looks the id up in [DefaultCategories.all] (both L1 and L2) and feeds the
/// matched category's icon-name string into [resolveCategoryIcon]. On no match
/// (custom / unknown id) returns [Icons.favorite_border] — a joy-flavored
/// fallback chosen for the Best Joy strip rather than [resolveCategoryIcon]'s
/// generic `help_outline` default.
///
/// Safe by construction: never throws on an unknown id.
IconData categoryIconFromId(String categoryId) {
  final matches = DefaultCategories.all.where((c) => c.id == categoryId);
  if (matches.isEmpty) return Icons.favorite_border;
  return resolveCategoryIcon(matches.first.icon);
}

/// Parent-aware sibling of [categoryIconFromId] used by the home Best Joy
/// strip's leading icon, which shows the L1 (parent) category icon rather
/// than the more specific L2 icon.
///
/// Resolution chain (never throws):
/// 1. No match in [DefaultCategories.all] → [Icons.favorite_border] (mirrors
///    [categoryIconFromId]'s joy-flavored fallback for custom/unknown ids).
/// 2. Matched and L1 (level == 1) or no parentId → the category's own icon.
/// 3. Matched L2 with a parentId → the parent's icon when the parent exists
///    in defaults; otherwise the category's OWN icon (graceful fallback).
IconData parentCategoryIconFromId(String categoryId) {
  final matches = DefaultCategories.all.where((c) => c.id == categoryId);
  if (matches.isEmpty) return Icons.favorite_border;
  return parentCategoryIconForCategory(matches.first);
}

/// Resolves the parent-aware leading icon for a concrete [Category].
///
/// L1 (or parent-less) categories map to their own icon. L2 categories map to
/// their parent's icon, falling back to their own icon when the parent is not
/// present in [DefaultCategories.all]. Pure and provider-free; never throws.
IconData parentCategoryIconForCategory(Category category) {
  final parentId = category.parentId;
  if (category.level == 1 || parentId == null) {
    return resolveCategoryIcon(category.icon);
  }
  final parents = DefaultCategories.all.where((c) => c.id == parentId);
  if (parents.isEmpty) {
    return resolveCategoryIcon(category.icon);
  }
  return resolveCategoryIcon(parents.first.icon);
}

IconData resolveCategoryIcon(String iconName) {
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
