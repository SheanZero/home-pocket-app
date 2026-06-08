import 'package:flutter/material.dart';

import '../../domain/models/shopping_item.dart';

/// Add / edit form for a shopping item (ITEM-01, ITEM-02, ITEM-04).
///
/// Stub — full implementation in Phase 38 Plan 07.
/// Required here so [ShoppingEmptyState] CTA and [ShoppingItemTile] edit
/// affordance can reference the class without forward-declaration hacks.
class ShoppingItemFormScreen extends StatelessWidget {
  const ShoppingItemFormScreen({
    super.key,
    required this.listType,
    this.item,
  });

  /// 'public' | 'private' — immutable after creation (D6).
  final String listType;

  /// null = create mode; non-null = edit mode (ITEM-04).
  final ShoppingItem? item;

  @override
  Widget build(BuildContext context) {
    // TODO(Phase38-Plan07): replace with full form implementation
    return Scaffold(
      appBar: AppBar(
        title: Text(item == null ? 'Add Item' : 'Edit Item'),
      ),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}
