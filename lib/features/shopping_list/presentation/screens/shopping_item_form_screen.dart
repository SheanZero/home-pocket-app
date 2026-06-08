import 'package:flutter/material.dart';

import '../../domain/models/shopping_item.dart';

/// Form screen for creating and editing shopping list items.
///
/// Constructor: `ShoppingItemFormScreen({super.key, required this.listType, this.item})`
/// - [listType]: 'public' or 'private' — immutable after creation (D6).
/// - [item]: null = create mode; non-null = edit mode (pre-populated form).
///
/// This is a stub screen created by Plan 38-04 to allow [ShoppingItemTile] to
/// compile. The full implementation is delivered in Plan 38-07.
class ShoppingItemFormScreen extends StatelessWidget {
  const ShoppingItemFormScreen({
    super.key,
    required this.listType,
    this.item,
  });

  final String listType;
  final ShoppingItem? item;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}
