import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../features/family_sync/presentation/providers/state_active_group.dart';
import '../../../../generated/app_localizations.dart';
import '../screens/shopping_item_form_screen.dart';

/// Three render variants for [ShoppingEmptyState] (SHOP-04).
enum ShoppingEmptyVariant {
  /// Private list with no items.
  privateEmpty,

  /// Public list, no family group joined.
  publicSolo,

  /// Public list, family group is active.
  publicFamily,
}

/// Empty-state placeholder for the shopping list.
///
/// Three distinct render paths driven by [ShoppingEmptyVariant]:
/// - [privateEmpty]    → shopping bag icon, private list copy.
/// - [publicSolo]      → group icon, invite-family copy.
/// - [publicFamily]    → add-cart icon, "be the first" copy.
///
/// Variant is determined from [listType] and [isGroupModeProvider]:
/// - private → [privateEmpty]
/// - public + isGroupMode  → [publicFamily]
/// - public + !isGroupMode → [publicSolo]
///
/// CTA button routes to [ShoppingItemFormScreen] with the same [listType].
class ShoppingEmptyState extends ConsumerWidget {
  const ShoppingEmptyState({super.key, required this.listType});

  /// 'public' | 'private' — determines the 3-way variant branch.
  final String listType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGroupMode = ref.watch(isGroupModeProvider);
    // 'all' (全部) and 'private' (个人) both show the generic empty placeholder.
    // The public-specific variants only apply to an explicit 'public' list.
    final variant = (listType == 'private' || listType == 'all')
        ? ShoppingEmptyVariant.privateEmpty
        : (isGroupMode
            ? ShoppingEmptyVariant.publicFamily
            : ShoppingEmptyVariant.publicSolo);
    // Create-target for the CTA: new items default to 'public' (G8Z2 FIX-2),
    // independent of the current view ('all'/'private' are views, not storable
    // list_types). Private is opt-in via the form's public/private selector.
    const createListType = 'public';

    final l10n = S.of(context);
    final (icon, heading, body) = switch (variant) {
      ShoppingEmptyVariant.privateEmpty => (
          Icons.shopping_bag_outlined,
          l10n.shoppingEmptyPrivateHeading,
          l10n.shoppingEmptyPrivateBody,
        ),
      ShoppingEmptyVariant.publicSolo => (
          Icons.group_outlined,
          l10n.shoppingEmptyPublicSoloHeading,
          l10n.shoppingEmptyPublicSoloBody,
        ),
      ShoppingEmptyVariant.publicFamily => (
          Icons.add_shopping_cart_outlined,
          l10n.shoppingEmptyPublicFamilyHeading,
          l10n.shoppingEmptyPublicFamilyBody,
        ),
    };

    final palette = context.palette;
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        // v15 `.shopping-empty` — warm card surface, rounded 14, soft border.
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: palette.borderDefault, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: palette.textTertiary),
            const SizedBox(height: 16),
            Text(
              heading,
              style: AppTextStyles.headlineSmall
                  .copyWith(color: palette.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: AppTextStyles.bodyMedium.copyWith(
                color: palette.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: palette.borderInputActive,
              ),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      ShoppingItemFormScreen(listType: createListType),
                ),
              ),
              child: Text(
                l10n.shoppingEmptyCta,
                style:
                    AppTextStyles.titleSmall.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
