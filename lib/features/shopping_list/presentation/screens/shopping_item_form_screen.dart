import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../shared/widgets/feedback_toast.dart';
import '../../../../shared/widgets/ledger_type_selector.dart';
import '../../../../shared/widgets/list_type_selector.dart';
import '../../../accounting/domain/models/category.dart';
import '../../../accounting/domain/models/transaction.dart';
import '../../../accounting/presentation/providers/repository_providers.dart'
    show categoryRepositoryProvider, deviceIdentityRepositoryProvider;
import '../../../accounting/presentation/screens/category_selection_screen.dart';
// isGroupModeProvider import removed — selector no longer gated on group mode (G8Z)
import '../../domain/models/shopping_item.dart';
import '../providers/repository_providers.dart'
    show createShoppingItemUseCaseProvider, updateShoppingItemUseCaseProvider;
import '../../../../application/shopping_list/create_shopping_item_use_case.dart';
import '../../../../application/shopping_list/update_shopping_item_use_case.dart';

/// Full-screen add/edit form for a shopping list item.
///
/// - Create mode: [item] is null; calls [CreateShoppingItemUseCase].
///   Default ledger: [LedgerType.daily] (user may toggle to joy or null).
///   Default list type: 'public' (user may switch to 'private' via selector).
/// - Edit mode: [item] is non-null; pre-populates all fields; calls [UpdateShoppingItemUseCase].
/// - List-type selector (public/private, styled like ledger chips) shown in ALL modes:
///   interactive in create mode, read-only in edit mode — reflects stored [listType]
///   and cannot be changed (D37-04/SYNC-03 immutability; the update path never alters it).
///   Placed AFTER the ledger selector (order: name → ledger → list-type → category → ...).
///   Always shown regardless of group membership (G8Z).
/// - Note field is passed as plaintext; encryption is applied at the repository
///   boundary (Phase 36). Do NOT add encryption code here.
class ShoppingItemFormScreen extends ConsumerStatefulWidget {
  const ShoppingItemFormScreen({
    super.key,
    required this.listType,
    this.item,
  });

  /// 'public' or 'private' — immutable after creation (D6).
  final String listType;

  /// null = create mode; non-null = edit mode (ITEM-04).
  final ShoppingItem? item;

  @override
  ConsumerState<ShoppingItemFormScreen> createState() =>
      _ShoppingItemFormScreenState();
}

class _ShoppingItemFormScreenState
    extends ConsumerState<ShoppingItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _priceController;
  late final TextEditingController _noteController;
  late final TextEditingController _tagsController;

  LedgerType? _ledgerType;
  String? _categoryId;
  // Target list for a NEW item ('private' | 'public'). Mutable only in create
  // mode via the group-only selector; immutable in edit mode (D6/SYNC-03).
  late String _listType;
  // Human-readable category label (CR-01). The model stores only categoryId,
  // so in edit mode the name is resolved asynchronously from the repository.
  String? _categoryName;

  @override
  void initState() {
    super.initState();
    _listType = widget.listType;
    final item = widget.item;
    if (item != null) {
      // Edit mode — pre-populate from existing item (ITEM-04)
      _nameController = TextEditingController(text: item.name);
      _quantityController =
          TextEditingController(text: item.quantity.toString());
      _priceController = TextEditingController(
        text: item.estimatedPrice?.toString() ?? '',
      );
      _noteController = TextEditingController(text: item.note ?? '');
      _tagsController = TextEditingController(
        text: item.tags.join(', '),
      );
      _ledgerType = item.ledgerType;
      _categoryId = item.categoryId;
      if (item.categoryId != null) {
        _resolveCategoryName(item.categoryId!);
      }
    } else {
      // Create mode — empty controllers; daily ledger pre-selected (G8Z2).
      _ledgerType = LedgerType.daily;
      _nameController = TextEditingController();
      _quantityController = TextEditingController();
      _priceController = TextEditingController();
      _noteController = TextEditingController();
      _tagsController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _noteController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    // Parse tags from comma-separated input
    final parsedTags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    // Sanitize numeric inputs (WR-03): quantity is at least 1; a negative or
    // zero entry falls back to 1. Estimated price must be non-negative; a
    // negative entry is treated as "not provided".
    final parsedQuantity = int.tryParse(_quantityController.text);
    final quantity = (parsedQuantity == null || parsedQuantity < 1)
        ? 1
        : parsedQuantity;
    final parsedPrice = int.tryParse(_priceController.text);
    final estimatedPrice =
        (parsedPrice == null || parsedPrice < 0) ? null : parsedPrice;

    try {
      if (widget.item == null) {
        // Create mode — obtain deviceId from device identity repository
        final deviceId =
            await ref.read(deviceIdentityRepositoryProvider).getDeviceId() ??
                '';
        final params = CreateShoppingItemParams(
          deviceId: deviceId,
          listType: _listType,
          name: _nameController.text.trim(),
          ledgerType: _ledgerType,
          categoryId: _categoryId,
          tags: parsedTags,
          note: _noteController.text.isEmpty ? null : _noteController.text,
          quantity: quantity,
          estimatedPrice: estimatedPrice,
        );
        final result =
            await ref.read(createShoppingItemUseCaseProvider).execute(params);
        if (result.isError) throw Exception(result.error);
      } else {
        // Edit mode — update existing item (ITEM-04)
        final params = UpdateShoppingItemParams(
          itemId: widget.item!.id,
          name: _nameController.text.trim(),
          ledgerType: _ledgerType,
          categoryId: _categoryId,
          tags: parsedTags,
          note: _noteController.text.isEmpty ? null : _noteController.text,
          quantity: quantity,
          estimatedPrice: estimatedPrice,
        );
        final result =
            await ref.read(updateShoppingItemUseCaseProvider).execute(params);
        if (result.isError) throw Exception(result.error);
      }
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        showErrorFeedback(context, S.of(context).shoppingFormSaveError);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _pickCategory() async {
    final selected = await Navigator.push<Category>(
      context,
      MaterialPageRoute<Category>(
        builder: (_) =>
            CategorySelectionScreen(selectedCategoryId: _categoryId),
      ),
    );
    if (selected != null && mounted) {
      setState(() {
        _categoryId = selected.id;
        _categoryName = selected.name;
      });
    }
  }

  /// Resolves a category's display name from its id (edit-mode pre-population).
  /// The ShoppingItem model stores only categoryId, so the name must be looked
  /// up to avoid rendering a raw UUID to the user (CR-01).
  Future<void> _resolveCategoryName(String categoryId) async {
    final category =
        await ref.read(categoryRepositoryProvider).findById(categoryId);
    if (category != null && mounted) {
      setState(() => _categoryName = category.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = S.of(context);
    final isEditMode = widget.item != null;
    // List-type selector shown in BOTH create and edit (read-only on edit — G8Z).
    const showListTypeSelector = true;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? l.shoppingFormEditTitle : l.shoppingFormAddTitle),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _save,
            child: Text(l.shoppingFormSave),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Name field — required (ITEM-01)
            TextFormField(
              key: const Key('shopping_form_name_field'),
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l.shoppingFormNameLabel,
              ),
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l.shoppingFormNameRequired : null,
            ),
            const SizedBox(height: 16),

            // Ledger type selector — optional (D4, ITEM-02). Defaults to daily
            // in create mode (G8Z2). Toggle off (tap same chip again → null).
            Text(
              l.shoppingFormLedgerLabel,
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            LedgerTypeSelector(
              key: const Key('shopping_form_ledger_selector'),
              selected: _ledgerType ?? LedgerType.daily,
              onChanged: (type) => setState(() {
                // Toggle off if same ledger tapped again — allow null
                _ledgerType = _ledgerType == type ? null : type;
              }),
              dailyLabel: l.listLedgerDaily,
              joyLabel: l.listLedgerJoy,
            ),
            const SizedBox(height: 16),

            // List-type selector (G8Z / G8Z2) — shown in ALL modes.
            // Placed AFTER the ledger selector (order: name → ledger → list-type → category).
            // Create mode: interactive (default 'public').
            // Edit mode: read-only — reflects stored listType and cannot be
            // changed (D37-04/SYNC-03 immutability; update path never alters it).
            if (showListTypeSelector) ...[
              Text(
                l.shoppingFormListTypeLabel,
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 8),
              ListTypeSelector(
                key: const Key('shopping_form_list_type_selector'),
                selected: _listType == 'public' ? 'public' : 'private',
                onChanged: (v) => setState(() => _listType = v),
                publicLabel: l.shoppingSegmentPublic,
                privateLabel: l.shoppingSegmentPrivate,
                enabled: !isEditMode,
              ),
              if (isEditMode) ...[
                const SizedBox(height: 4),
                Text(
                  l.shoppingListTypeLockedHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],

            // Category field — optional (D4, ITEM-02)
            Text(
              l.shoppingFormCategoryLabel,
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _categoryName ?? l.shoppingFormNoCategorySelected,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                OutlinedButton(
                  key: const Key('shopping_form_category_button'),
                  onPressed: _pickCategory,
                  child: Text(l.shoppingFormChangeCategory),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tags field — optional, comma-separated (D4, ITEM-02)
            TextField(
              key: const Key('shopping_form_tags_field'),
              controller: _tagsController,
              decoration: InputDecoration(
                labelText: l.shoppingFormTagsLabel,
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // Note field — optional, plaintext to use case (repo boundary encrypts)
            TextField(
              key: const Key('shopping_form_note_field'),
              controller: _noteController,
              decoration: InputDecoration(
                labelText: l.shoppingFormNoteLabel,
              ),
              maxLines: 3,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // Quantity field — optional (D4, ITEM-02)
            TextField(
              key: const Key('shopping_form_quantity_field'),
              controller: _quantityController,
              decoration: InputDecoration(
                labelText: l.shoppingFormQuantityLabel,
              ),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // Estimated price field — optional, amountSmall style (ITEM-02, CLAUDE.md)
            TextField(
              key: const Key('shopping_form_price_field'),
              controller: _priceController,
              decoration: InputDecoration(
                labelText: l.shoppingFormPrice,
                prefixText: '¥',
              ),
              keyboardType: TextInputType.number,
              style: AppTextStyles.amountSmall,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
