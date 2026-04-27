import 'dart:ui';

import '../../infrastructure/category/category_locale_service.dart' as infra;

/// Application-layer façade over the infrastructure category localization maps.
///
/// Allows presentation to resolve system category names (e.g. `category_food`)
/// to locale-appropriate display strings without importing `infrastructure/`
/// directly (HIGH-02 compliance).
///
/// Delegates to the pure-static [infra.CategoryLocaleService] which holds large
/// locale look-up maps; this class adds no state and can be used as a
/// compile-time constant.
abstract final class CategoryLocalizationService {
  /// Resolves [nameKey] (e.g. `category_food`) to its localized display name.
  ///
  /// If [nameKey] is not found in the map (user-created category), returns
  /// [nameKey] unchanged.
  static String resolve(String nameKey, Locale locale) =>
      infra.CategoryLocaleService.resolve(nameKey, locale);

  /// Converts a system category ID (e.g. `cat_food`) to its localized name.
  ///
  /// Strips the `cat_` prefix, constructs the key `category_food`, then
  /// delegates to [resolve]. Non-system IDs pass through unchanged.
  static String resolveFromId(String categoryId, Locale locale) =>
      infra.CategoryLocaleService.resolveFromId(categoryId, locale);
}
