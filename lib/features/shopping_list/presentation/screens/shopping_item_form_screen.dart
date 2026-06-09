import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_palette.dart';
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
import '../../../accounting/presentation/utils/category_display_utils.dart';
import '../../../settings/presentation/providers/state_locale.dart';
// isGroupModeProvider import removed — selector no longer gated on group mode (G8Z)
import '../../domain/models/shopping_item.dart';
import '../providers/repository_providers.dart'
    show createShoppingItemUseCaseProvider, updateShoppingItemUseCaseProvider;
import '../../../../application/shopping_list/create_shopping_item_use_case.dart';
import '../../../../application/shopping_list/update_shopping_item_use_case.dart';

/// Full-screen add/edit form for a shopping list item.
///
/// - Create mode: [item] is null; calls [CreateShoppingItemUseCase].
///   Default ledger: [LedgerType.daily] (always non-null; cannot toggle to null).
///   Default list type: 'public' (user may switch to 'private' via selector).
/// - Edit mode: [item] is non-null; pre-populates all fields; calls [UpdateShoppingItemUseCase].
/// - List-type selector (public/private) shown in ALL modes:
///   interactive in create mode, read-only in edit mode — reflects stored [listType]
///   and cannot be changed (D37-04/SYNC-03 immutability; the update path never alters it).
///   Placed AFTER the ledger selector (order: name → ledger → list-type → category → ...).
///   Always shown regardless of group membership (G8Z).
/// - Tags field is hidden from UI (D-2); edit mode transparently passes original item.tags.
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
  // Tags controller: holds original value but NOT rendered in UI (D-2).
  // Edit mode: used to hold item.tags for transparency; save uses widget.item!.tags directly.
  // Create mode: not used in save path.
  late final TextEditingController _tagsController;

  // Non-null LedgerType — defaults to daily; cannot be toggled to null (D-1).
  LedgerType _ledgerType = LedgerType.daily;
  String? _categoryId;
  // Target list for a NEW item ('private' | 'public'). Mutable only in create
  // mode via selector; immutable in edit mode (D6/SYNC-03).
  late String _listType;
  // Selected category + its parent, so the form can render the full
  // "parent > child" path via formatCategoryPath (mirrors transaction_details_form).
  // The model stores only categoryId, so both are loaded async in edit mode.
  Category? _category;
  Category? _parentCategory;

  // Focus node for the name field; autofocus only in create mode (D-4).
  late final FocusNode _nameFocusNode;

  @override
  void initState() {
    super.initState();
    _listType = widget.listType;
    _nameFocusNode = FocusNode(debugLabel: 'shoppingNameFocus');

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
      _tagsController = TextEditingController(text: item.tags.join(', '));
      // If item.ledgerType is null, display as daily (D-1).
      _ledgerType = item.ledgerType ?? LedgerType.daily;
      _categoryId = item.categoryId;
      if (item.categoryId != null) {
        _loadCategory(item.categoryId!);
      }
    } else {
      // Create mode — quantity defaults to '1' (D-3); daily ledger pre-selected (D-1).
      _ledgerType = LedgerType.daily;
      _nameController = TextEditingController();
      _quantityController = TextEditingController(text: '1');
      _priceController = TextEditingController();
      _noteController = TextEditingController();
      _tagsController = TextEditingController();
      // Autofocus name field in create mode (D-4).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _nameFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _noteController.dispose();
    _tagsController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

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
          tags: const [],
          note: _noteController.text.isEmpty ? null : _noteController.text,
          quantity: quantity,
          estimatedPrice: estimatedPrice,
        );
        final result =
            await ref.read(createShoppingItemUseCaseProvider).execute(params);
        if (result.isError) throw Exception(result.error);
      } else {
        // Edit mode — update existing item (ITEM-04).
        // Tags are passed through directly from the original item (D-2).
        final params = UpdateShoppingItemParams(
          itemId: widget.item!.id,
          name: _nameController.text.trim(),
          ledgerType: _ledgerType,
          categoryId: _categoryId,
          tags: widget.item!.tags,
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
    if (selected == null || !mounted) return;
    final parent = await _resolveParent(selected);
    if (!mounted) return;
    setState(() {
      _categoryId = selected.id;
      _category = selected;
      _parentCategory = parent;
    });
  }

  /// Loads the category AND its parent from a stored id (edit-mode
  /// pre-population), so the form can render the full "parent > child" path
  /// at build time via [formatCategoryPath] (CR-01; mirrors transaction form).
  Future<void> _loadCategory(String categoryId) async {
    final category =
        await ref.read(categoryRepositoryProvider).findById(categoryId);
    if (category == null || !mounted) return;
    final parent = await _resolveParent(category);
    if (!mounted) return;
    setState(() {
      _category = category;
      _parentCategory = parent;
    });
  }

  /// Fetches the parent category for an L2 category (null for L1 / orphaned).
  Future<Category?> _resolveParent(Category category) async {
    final parentId = category.parentId;
    if (category.level == 1 || parentId == null) return null;
    return ref.read(categoryRepositoryProvider).findById(parentId);
  }

  Widget _buildSaveButton(S l) {
    final palette = context.palette;
    return GestureDetector(
      onTap: _isSubmitting ? null : _save,
      child: Container(
        constraints: const BoxConstraints(minWidth: 64, minHeight: 36),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [palette.fabGradientStart, palette.fabGradientEnd],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: palette.fabShadow,
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          l.shoppingFormSave,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildStepper() {
    final palette = context.palette;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: palette.borderDefault),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _stepBtn(
            '−',
            () {
              final v = int.tryParse(_quantityController.text) ?? 1;
              if (v > 1) setState(() => _quantityController.text = (v - 1).toString());
            },
            isLeft: true,
            palette: palette,
          ),
          SizedBox(
            width: 52,
            child: TextField(
              key: const Key('shopping_form_quantity_field'),
              controller: _quantityController,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: palette.textPrimary,
              ),
              onChanged: (v) {
                final n = int.tryParse(v);
                if (n != null && n < 1) {
                  setState(() => _quantityController.text = '1');
                }
              },
            ),
          ),
          _stepBtn(
            '＋',
            () {
              final v = int.tryParse(_quantityController.text) ?? 1;
              setState(() => _quantityController.text = (v + 1).toString());
            },
            isLeft: false,
            palette: palette,
          ),
        ],
      ),
    );
  }

  Widget _stepBtn(
    String label,
    VoidCallback onTap, {
    required bool isLeft,
    required AppPalette palette,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: palette.backgroundMuted,
          borderRadius: isLeft
              ? const BorderRadius.only(
                  topLeft: Radius.circular(11),
                  bottomLeft: Radius.circular(11),
                )
              : const BorderRadius.only(
                  topRight: Radius.circular(11),
                  bottomRight: Radius.circular(11),
                ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: palette.dailyText,
              fontWeight: FontWeight.w500,
              fontSize: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _divider(AppPalette palette) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(height: 1, color: palette.backgroundDivider),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = S.of(context);
    final palette = context.palette;
    final isEditMode = widget.item != null;
    final locale = ref.watch(currentLocaleProvider).value ?? const Locale('ja');
    // Render the full "parent > child" localized path at build time (mirrors
    // transaction_details_form — never render the raw key/id).
    final categoryDisplay = _category == null
        ? null
        : formatCategoryPath(
            category: _category!,
            parentCategory: _parentCategory,
            locale: locale,
          );

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? l.shoppingFormEditTitle : l.shoppingFormAddTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _buildSaveButton(l),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          children: [
            // ── Zone 1: Item name card ─────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: palette.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: palette.borderDefault),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: TextFormField(
                key: const Key('shopping_form_name_field'),
                controller: _nameController,
                focusNode: _nameFocusNode,
                autofocus: !isEditMode,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: l.shoppingFormNameLabel,
                  hintStyle: TextStyle(
                    color: palette.textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: palette.textPrimary,
                ),
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l.shoppingFormNameRequired : null,
              ),
            ),
            const SizedBox(height: 16),

            // ── Zone 2: Quantity / Purpose / Type card ─────────────────────
            Container(
              decoration: BoxDecoration(
                color: palette.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: palette.borderDefault),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Row 1: Quantity stepper
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Text(
                          l.shoppingFormQuantityLabel,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: palette.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        _buildStepper(),
                      ],
                    ),
                  ),

                  _divider(palette),

                  // Row 2: Purpose (ledger type) — always daily/joy, no null (D-1)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Text(
                          l.expenseClassification,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: palette.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        LedgerTypeSelector(
                          key: const Key('shopping_form_ledger_selector'),
                          selected: _ledgerType,
                          onChanged: (type) => setState(() => _ledgerType = type),
                          dailyLabel: l.dailyExpense,
                          joyLabel: l.joyExpense,
                        ),
                      ],
                    ),
                  ),

                  _divider(palette),

                  // Row 3: Type (list type) — read-only in edit mode (D37-04/SYNC-03)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Text(
                          l.shoppingFormListTypeLabel,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: palette.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        ListTypeSelector(
                          key: const Key('shopping_form_list_type_selector'),
                          selected: _listType == 'public' ? 'public' : 'private',
                          onChanged: (v) => setState(() => _listType = v),
                          publicLabel: l.shoppingSegmentPublic,
                          privateLabel: l.shoppingSegmentPrivate,
                          enabled: !isEditMode,
                        ),
                      ],
                    ),
                  ),

                  if (isEditMode)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                      child: Text(
                        l.shoppingListTypeLockedHint,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Zone 3: Category / Estimated price / Note card ─────────────
            Container(
              decoration: BoxDecoration(
                color: palette.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: palette.borderDefault),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Row 1: Category — full-row tap (replaces OutlinedButton)
                  InkWell(
                    onTap: _pickCategory,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(14),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.label_outline,
                            size: 16,
                            color: palette.textTertiary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l.shoppingFormCategoryLabel,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: palette.textSecondary,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            categoryDisplay ?? l.shoppingFormNoCategorySelected,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: categoryDisplay != null
                                  ? palette.textPrimary
                                  : palette.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.chevron_right,
                            size: 14,
                            color: palette.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),

                  _divider(palette),

                  // Row 2: Estimated price
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Text(
                          '¥',
                          style: TextStyle(
                            fontSize: 15,
                            color: palette.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l.shoppingFormPrice,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: palette.textSecondary,
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            key: const Key('shopping_form_price_field'),
                            controller: _priceController,
                            textAlign: TextAlign.right,
                            keyboardType: TextInputType.number,
                            style: AppTextStyles.amountSmall,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              isDense: true,
                            ),
                            onSubmitted: (_) => _save(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  _divider(palette),

                  // Row 3: Note
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              size: 15,
                              color: palette.textTertiary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              l.shoppingFormNoteLabel,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: palette.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          key: const Key('shopping_form_note_field'),
                          controller: _noteController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: l.shoppingFormNoteLabel,
                            hintStyle: TextStyle(color: palette.textTertiary),
                            filled: true,
                            fillColor: palette.backgroundMuted,
                            contentPadding: const EdgeInsets.all(12),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
