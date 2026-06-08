# Phase 38: Presentation Shell + UI Widgets — Pattern Map

**Mapped:** 2026-06-08
**Files analyzed:** 12 new/modified files
**Analogs found:** 12 / 12

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/features/shopping_list/presentation/providers/state_shopping_filter.dart` | provider (notifier) | CRUD / keepAlive state | `lib/features/list/presentation/providers/state_list_filter.dart` | exact |
| `lib/features/shopping_list/presentation/providers/state_shopping_batch.dart` | provider (transient notifier) | event-driven / boolean state | `lib/features/home/presentation/providers/state_home.dart` (selectedTabIndexProvider) | role-match |
| `lib/features/shopping_list/presentation/providers/repository_providers.dart` (EXTEND) | provider (factory wiring) | CRUD / dependency injection | `lib/features/shopping_list/presentation/providers/repository_providers.dart` (existing) | exact |
| `lib/features/shopping_list/presentation/screens/shopping_list_screen.dart` | screen / shell | request-response + streaming | `lib/features/list/presentation/screens/list_screen.dart` | exact |
| `lib/features/shopping_list/presentation/screens/shopping_item_form_screen.dart` | screen / form | CRUD / request-response | `lib/features/accounting/presentation/screens/manual_one_step_screen.dart` | role-match |
| `lib/features/shopping_list/presentation/widgets/shopping_item_tile.dart` | widget / tile | event-driven + streaming | `lib/features/list/presentation/widgets/list_transaction_tile.dart` | exact |
| `lib/features/shopping_list/presentation/widgets/shopping_filter_bar.dart` | widget / filter bar | CRUD / filter state | `lib/features/list/presentation/widgets/list_sort_filter_bar.dart` | exact (visual) |
| `lib/features/shopping_list/presentation/widgets/shopping_empty_state.dart` | widget / empty state | request-response | `lib/features/list/presentation/widgets/list_empty_state.dart` | exact |
| `lib/features/shopping_list/presentation/widgets/shopping_batch_action_bar.dart` | widget / action bar | event-driven | `lib/features/list/presentation/widgets/list_sort_filter_bar.dart` | role-match |
| `lib/features/shopping_list/presentation/widgets/shopping_selection_header.dart` | widget / header | event-driven | `lib/features/list/presentation/widgets/list_sort_filter_bar.dart` | role-match |
| `lib/features/home/presentation/screens/main_shell_screen.dart` (MODIFY) | screen / nav shell | event-driven + routing | itself (in-place modification) | exact |
| `lib/features/home/presentation/widgets/home_bottom_nav_bar.dart` (MODIFY) | widget / nav bar | event-driven | itself (in-place modification) | exact |

---

## Pattern Assignments

---

### `lib/features/shopping_list/presentation/providers/state_shopping_filter.dart` (provider, keepAlive state)

**Analog:** `lib/features/list/presentation/providers/state_list_filter.dart`

**Imports pattern** (lines 1-7 of analog):
```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/models/list_filter_state.dart';
import '../../domain/models/list_sort_config.dart';
import '../../../accounting/domain/models/transaction.dart';

part 'state_list_filter.g.dart';
```
Adapt to: import `shopping_list_filter.dart` + `transaction.dart` (for `LedgerType`).

**keepAlive provider pattern** (lines 16-19 of analog):
```dart
@Riverpod(keepAlive: true)
class ListFilter extends _$ListFilter {
  @override
  ListFilterState build() => ListFilterState.initial();
```
Copy exactly; name classes `ListType` (→ generates `listTypeProvider`) and `ShoppingFilter` (→ generates `shoppingFilterProvider`). Riverpod 3 suffix-stripping: `class ListType` NOT `class ListTypeNotifier`.

**Notifier mutation pattern** (lines 21-80 of analog):
```dart
void setLedgerFilter(LedgerType? type) {
  state = state.copyWith(ledgerType: type);
}

void setCategories(Set<String> ids) {
  state = state.copyWith(categoryIds: ids);
}

void clearAll() {
  state = state.clearAll();
}
```
Add these mutators to `ShoppingFilter`: `setLedgerFilter`, `setStatusFilter`, `setCategoryIds`, `clearAll`, `resetForNewSegment`. The `ListType` notifier calls `ref.read(shoppingFilterProvider.notifier).resetForNewSegment()` on segment switch (D5/SC2).

**LANDMINE:** `ShoppingListFilter` model (confirmed at `lib/features/shopping_list/domain/models/shopping_list_filter.dart` lines 17-24) has `listType`, `ledgerType`, `statusFilter`, `searchQuery` — **NO `categoryIds` field**. Wave 0 task: add `@Default(<String>{}) Set<String> categoryIds` to `ShoppingListFilter`, regenerate with `flutter pub run build_runner build --delete-conflicting-outputs`.

---

### `lib/features/shopping_list/presentation/providers/state_shopping_batch.dart` (provider, transient)

**Analog:** `lib/features/home/presentation/providers/state_home.dart` (`selectedTabIndexProvider`)

**Pattern — transient notifier WITHOUT keepAlive:**
```dart
// Do NOT use @Riverpod(keepAlive: true) — batch mode is transient (D38-03)
@riverpod
class BatchSelectMode extends _$BatchSelectMode {
  @override
  BatchSelectModeState build() => BatchSelectModeState.inactive();

  void enter() => state = BatchSelectModeState(isActive: true, selectedIds: {});
  void toggle(String id) { ... state = state.copyWith(selectedIds: ...) }
  void selectAll(Iterable<String> ids) { ... }
  void exit() => state = BatchSelectModeState.inactive();
}
```
`class BatchSelectMode` → generates `batchSelectModeProvider` (Riverpod 3 suffix-stripping). **NEVER override this in a local ProviderScope** — it must be app-root scoped so `MainShellScreen` and `ShoppingListScreen` read the same instance (Pitfall 3).

---

### `lib/features/shopping_list/presentation/providers/repository_providers.dart` (EXTEND)

**Analog:** itself (existing file, lines 1-26)

**Existing wiring pattern** (lines 1-26, confirmed):
```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../application/accounting/repository_providers.dart'
    as app_accounting;
import '../../../../data/daos/shopping_item_dao.dart';
import '../../../../data/repositories/shopping_item_repository_impl.dart';
import '../../domain/repositories/shopping_item_repository.dart';

part 'repository_providers.g.dart';

@riverpod
ShoppingItemRepository shoppingItemRepository(Ref ref) {
  final database = ref.watch(app_accounting.appAppDatabaseProvider);
  final dao = ShoppingItemDao(database);
  final encryptionService = ref.watch(
    app_accounting.appFieldEncryptionServiceProvider,
  );
  return ShoppingItemRepositoryImpl(dao: dao, encryptionService: encryptionService);
}
```

**Add after existing provider — use-case wiring pattern** (verified provider names from `state_sync.dart`):
```dart
// Confirmed provider names from state_sync.dart:
//   shoppingItemChangeTrackerProvider (line 27: class ShoppingItemChangeTracker → shoppingItemChangeTrackerProvider)
//   syncEngineProvider (line 55: class SyncEngine → syncEngineProvider)

import '../../../../application/shopping_list/create_shopping_item_use_case.dart';
import '../../../../application/shopping_list/toggle_item_completed_use_case.dart';
import '../../../../application/shopping_list/delete_shopping_item_use_case.dart';
import '../../../../application/shopping_list/update_shopping_item_use_case.dart';
import '../../../../application/shopping_list/reorder_shopping_items_use_case.dart';
import '../../../../application/shopping_list/clear_completed_items_use_case.dart';
import '../../../family_sync/presentation/providers/state_sync.dart'
    show shoppingItemChangeTrackerProvider, syncEngineProvider;

@riverpod
CreateShoppingItemUseCase createShoppingItemUseCase(Ref ref) =>
    CreateShoppingItemUseCase(
      shoppingItemRepository: ref.watch(shoppingItemRepositoryProvider),
      changeTracker: ref.watch(shoppingItemChangeTrackerProvider),
      syncEngine: ref.watch(syncEngineProvider),
    );

@riverpod
ToggleItemCompletedUseCase toggleItemCompletedUseCase(Ref ref) =>
    ToggleItemCompletedUseCase(
      shoppingItemRepository: ref.watch(shoppingItemRepositoryProvider),
      changeTracker: ref.watch(shoppingItemChangeTrackerProvider),
      syncEngine: ref.watch(syncEngineProvider),
    );

@riverpod
DeleteShoppingItemUseCase deleteShoppingItemUseCase(Ref ref) =>
    DeleteShoppingItemUseCase(
      shoppingItemRepository: ref.watch(shoppingItemRepositoryProvider),
      changeTracker: ref.watch(shoppingItemChangeTrackerProvider),
      syncEngine: ref.watch(syncEngineProvider),
    );

@riverpod
UpdateShoppingItemUseCase updateShoppingItemUseCase(Ref ref) =>
    UpdateShoppingItemUseCase(
      shoppingItemRepository: ref.watch(shoppingItemRepositoryProvider),
      changeTracker: ref.watch(shoppingItemChangeTrackerProvider),
      syncEngine: ref.watch(syncEngineProvider),
    );

@riverpod
ReorderShoppingItemsUseCase reorderShoppingItemsUseCase(Ref ref) =>
    ReorderShoppingItemsUseCase(
      shoppingItemRepository: ref.watch(shoppingItemRepositoryProvider),
      // No changeTracker, no syncEngine — D37-01 (local reorder only)
    );

@riverpod
ClearCompletedItemsUseCase clearCompletedItemsUseCase(Ref ref) =>
    ClearCompletedItemsUseCase(
      shoppingItemRepository: ref.watch(shoppingItemRepositoryProvider),
      changeTracker: ref.watch(shoppingItemChangeTrackerProvider),
      syncEngine: ref.watch(syncEngineProvider),
    );
```

**Also add the filteredShoppingItems derived StreamProvider** (Pitfall 5 — DAO returns ALL non-deleted items, filtering is client-side):
```dart
@riverpod
Stream<List<ShoppingItem>> filteredShoppingItems(Ref ref) {
  final filter = ref.watch(shoppingFilterProvider);
  final listType = ref.watch(listTypeProvider);
  return ref
      .watch(shoppingItemRepositoryProvider)
      .watchByListType(listType)
      .map((items) => items.where((item) {
        if (filter.ledgerType != null && item.ledgerType != filter.ledgerType) return false;
        if (filter.categoryIds.isNotEmpty &&
            !filter.categoryIds.contains(item.categoryId)) return false;
        if (filter.statusFilter == 'active' && item.isCompleted) return false;
        return true;
      }).toList());
}
```

---

### `lib/features/shopping_list/presentation/screens/shopping_list_screen.dart` (screen, streaming)

**Analog:** `lib/features/list/presentation/screens/list_screen.dart`

**Imports pattern** (lines 1-24 of analog):
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../infrastructure/i18n/formatters/number_formatter.dart';
import '../../../../features/settings/presentation/providers/state_locale.dart';
// ...providers, widgets...
```

**Screen scaffold + Sliver list pattern** (lines 36-107 of analog, adapted):
```dart
class ShoppingListScreen extends ConsumerWidget {
  const ShoppingListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final listType = ref.watch(listTypeProvider);
    final batchActive = ref.watch(batchSelectModeProvider).isActive;

    return Scaffold(
      body: Column(
        children: [
          // Public/Private SegmentedButton (SHOP-01)
          _buildSegmentedControl(context, ref, listType),
          // Sticky filter bar (D38-04)
          ShoppingFilterBar(),
          // Batch selection header (D38-03) — visible only when batchActive
          if (batchActive) ShoppingSelectionHeader(),
          Expanded(child: _buildBody(context, ref)),
          // Bottom batch action bar (D38-03)
          if (batchActive) ShoppingBatchActionBar(),
        ],
      ),
    );
  }
```

**Loading/error/data pattern** (lines 133-186 of analog):
```dart
// Mirror txsAsync.when(...) pattern:
final itemsAsync = ref.watch(filteredShoppingItemsProvider);
return itemsAsync.when(
  loading: () => Center(
    child: CircularProgressIndicator(color: palette.accentPrimary, strokeWidth: 2),
  ),
  error: (err, st) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error_outline, size: 40, color: palette.textTertiary),
        const SizedBox(height: 8),
        Text(S.of(context).shoppingListLoadError,
            style: AppTextStyles.caption.copyWith(color: palette.textSecondary)),
        TextButton(onPressed: () => ref.invalidate(filteredShoppingItemsProvider),
            child: Text(S.of(context).shoppingRetry)),
      ],
    ),
  ),
  data: (items) {
    final activeItems = items.where((i) => !i.isCompleted).toList();
    final completedItems = items.where((i) => i.isCompleted).toList();
    if (activeItems.isEmpty && completedItems.isEmpty) {
      return ShoppingEmptyState(listType: listType);
    }
    return CustomScrollView(
      slivers: [
        // Active items — SliverReorderableList (D38-02)
        SliverReorderableList(
          buildDefaultDragHandles: false,  // CRITICAL — Pitfall 2
          itemCount: activeItems.length,
          onReorder: (oldIndex, newIndex) {
            final adjusted = newIndex > oldIndex ? newIndex - 1 : newIndex;
            ref.read(reorderShoppingItemsUseCaseProvider)
               .execute(activeItems[oldIndex].id, adjusted);
          },
          itemBuilder: (context, index) => ShoppingItemTile(
            key: ValueKey(activeItems[index].id),
            item: activeItems[index],
            index: index,
            isActive: true,
          ),
        ),
        // Completed section divider + SliverList
        if (completedItems.isNotEmpty) ...[
          SliverToBoxAdapter(child: _completedDivider(context)),
          SliverList(delegate: SliverChildBuilderDelegate(
            (ctx, i) => ShoppingItemTile(
              key: ValueKey(completedItems[i].id),
              item: completedItems[i],
              index: i,
              isActive: false,
            ),
            childCount: completedItems.length,
          )),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  },
);
```

**Divider pattern** (analog line 356):
```dart
Divider(height: 1, thickness: 1, color: palette.borderList)
```

---

### `lib/features/shopping_list/presentation/screens/shopping_item_form_screen.dart` (screen, form)

**Analog:** `lib/features/accounting/presentation/screens/manual_one_step_screen.dart`

**ConsumerStatefulWidget pattern** (lines 39-66 of analog):
```dart
class ShoppingItemFormScreen extends ConsumerStatefulWidget {
  const ShoppingItemFormScreen({
    super.key,
    required this.listType,  // 'public' | 'private' — NOT editable on edit (D6)
    this.item,               // null = create; non-null = edit (ITEM-04)
  });

  final String listType;
  final ShoppingItem? item;

  @override
  ConsumerState<ShoppingItemFormScreen> createState() =>
      _ShoppingItemFormScreenState();
}

class _ShoppingItemFormScreenState extends ConsumerState<ShoppingItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _priceController;
  late final TextEditingController _noteController;
  LedgerType? _ledgerType;
  String? _categoryId;
  List<String> _tags = [];
```

**Form save pattern** (analog lines ~350-400, adapted):
```dart
Future<void> _save() async {
  if (!_formKey.currentState!.validate()) return;
  setState(() => _isSubmitting = true);
  try {
    if (widget.item == null) {
      // Create
      final params = CreateShoppingItemParams(
        deviceId: ...,
        listType: widget.listType,
        name: _nameController.text.trim(),
        ledgerType: _ledgerType,
        categoryId: _categoryId,
        tags: _tags,
        note: _noteController.text.isEmpty ? null : _noteController.text,
        quantity: int.tryParse(_quantityController.text) ?? 1,
        estimatedPrice: int.tryParse(_priceController.text),
      );
      await ref.read(createShoppingItemUseCaseProvider).execute(params);
    } else {
      // Update (ITEM-04)
      final params = UpdateShoppingItemParams(itemId: widget.item!.id, ...);
      await ref.read(updateShoppingItemUseCaseProvider).execute(params);
    }
    if (mounted) Navigator.pop(context);
  } catch (e) {
    if (mounted) showErrorFeedback(context, S.of(context).shoppingFormSaveError);
  } finally {
    if (mounted) setState(() => _isSubmitting = false);
  }
}
```

**Ledger selector reuse** (`lib/shared/widgets/ledger_type_selector.dart` — use verbatim):
```dart
// Confirmed constructor (lines 9-15 of ledger_type_selector.dart):
LedgerTypeSelector(
  selected: _ledgerType ?? LedgerType.daily,
  onChanged: (type) => setState(() => _ledgerType = type),
  dailyLabel: S.of(context).ledgerDaily,
  joyLabel: S.of(context).ledgerJoy,
)
```

**Amount field with `amountSmall` style** (ITEM-05, CLAUDE.md rule):
```dart
TextField(
  controller: _priceController,
  keyboardType: TextInputType.number,
  style: AppTextStyles.amountSmall.copyWith(color: palette.textPrimary),
  decoration: InputDecoration(
    labelText: S.of(context).shoppingFormPrice,
    prefixText: '¥',
  ),
)
```

---

### `lib/features/shopping_list/presentation/widgets/shopping_item_tile.dart` (widget, tile)

**Analog:** `lib/features/list/presentation/widgets/list_transaction_tile.dart`

**Widget class declaration pattern** (lines 30-48 of analog):
```dart
class ShoppingItemTile extends ConsumerWidget {
  const ShoppingItemTile({
    super.key,
    required this.item,
    required this.index,    // needed for ReorderableDragStartListener
    required this.isActive, // active vs completed — controls trailing cluster
  });

  final ShoppingItem item;
  final int index;
  final bool isActive;
```

**Dismissible + ordering pattern** (lines 90-115 of analog — CRITICAL ordering preserved):
```dart
// MUST read batchActive to disable swipe in batch mode (MGMT-03)
final batchActive = ref.watch(batchSelectModeProvider).isActive;

return Dismissible(
  key: ValueKey(item.id),
  direction: batchActive
      ? DismissDirection.none     // MGMT-03: swipe disabled in batch mode
      : DismissDirection.endToStart,
  background: Container(
    color: palette.error,
    alignment: Alignment.centerRight,
    padding: const EdgeInsets.only(right: 16),
    child: Icon(Icons.delete, color: palette.card, size: 20),
  ),
  confirmDismiss: (_) => showSoftConfirmDialog(
    context,
    title: S.of(context).shoppingDeleteConfirmTitle,
    body: S.of(context).shoppingDeleteConfirmBody,
    confirmLabel: S.of(context).shoppingDeleteConfirmButton,
    cancelLabel: S.of(context).shoppingDeleteCancelButton,
  ),
  onDismissed: (_) {
    // CRITICAL order: feedback toast BEFORE provider call (context validity)
    showSuccessFeedback(context, S.of(context).shoppingDeletedSnackBar);
    ref.read(deleteShoppingItemUseCaseProvider).execute(item.id);
  },
  child: GestureDetector(
    onTap: () => ref.read(toggleItemCompletedUseCaseProvider).execute(item.id), // D38-01
    onLongPress: batchActive ? null : () {
      ref.read(batchSelectModeProvider.notifier).enter();
      ref.read(batchSelectModeProvider.notifier).toggle(item.id);
    }, // MGMT-02
    behavior: HitTestBehavior.opaque,
    child: _buildTileContent(context, ref, palette),
  ),
);
```

**Tile layout with left-border accent** (SHOP-03, UI-SPEC confirmed):
```dart
// Top-level Container for the left-border accent
Container(
  decoration: BoxDecoration(
    border: Border(
      left: BorderSide(
        color: switch (item.ledgerType) {
          LedgerType.daily => palette.daily,
          LedgerType.joy => palette.joy,
          null => palette.borderList,
        },
        width: 4,
      ),
    ),
  ),
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(
      children: [
        // Checkbox toggle target (leading)
        // ...
        const SizedBox(width: 12),
        // Text block (expanded)
        Expanded(child: Column(children: [
          // Primary: animated item name
          // Secondary: emoji + qty + price
        ])),
        const SizedBox(width: 8),
        // Attribution chip — public-list tiles only (lines 198-221 of analog)
        // ...
        // Trailing cluster
        _buildTrailingCluster(context, ref, palette),
      ],
    ),
  ),
)
```

**Animated strikethrough + fade pattern** (DONE-01, discretion):
```dart
AnimatedDefaultTextStyle(
  duration: const Duration(milliseconds: 200),
  curve: Curves.easeInOut,
  style: item.isCompleted
      ? AppTextStyles.bodyLarge.copyWith(
          decoration: TextDecoration.lineThrough,
          color: palette.textTertiary,
        )
      : AppTextStyles.bodyLarge,
  child: AnimatedOpacity(
    duration: const Duration(milliseconds: 200),
    opacity: item.isCompleted ? 0.5 : 1.0,
    child: Text(item.name),
  ),
)
```

**Attribution chip pattern** (lines 198-221 of analog — mirror verbatim for SYNC-04):
```dart
// Public-list tiles only; private list shows none
if (item.addedByBookId != null) ...[
  Builder(builder: (ctx) {
    // Riverpod 3: .value (nullable), not .valueOrNull (removed)
    final shadows = ref.watch(shadowBooksProvider).value ?? const [];
    final tag = shadows.firstWhereOrNull(
        (s) => s.book.id == item.addedByBookId);
    if (tag == null) return const SizedBox.shrink(); // silent omit if not yet synced
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 72),
      child: Container(
        decoration: BoxDecoration(
          color: palette.sharedLight,
          borderRadius: BorderRadius.circular(3),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        child: Text(
          '${tag.memberAvatarEmoji} ${tag.memberDisplayName}',
          style: AppTextStyles.micro.copyWith(color: palette.sharedText),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }),
  const SizedBox(width: 8),
],
```

**Trailing cluster — active items** (D38-01 edit affordance + D38-02 drag handle):
```dart
// Active items: edit chevron + drag handle (both ≥44px, 8px apart)
Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    Semantics(
      label: S.of(context).shoppingEditItem,
      button: true,
      child: Tooltip(
        message: S.of(context).shoppingEditItem,
        child: GestureDetector(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ShoppingItemFormScreen(
              listType: item.listType, item: item),
          )),
          child: Icon(Icons.chevron_right, size: 18, color: palette.textSecondary),
        ),
      ),
    ),
    if (!batchActive) ...[
      const SizedBox(width: 8),
      Semantics(
        label: S.of(context).shoppingReorderItem,
        button: true,
        child: ReorderableDragStartListener(
          index: index,
          child: Tooltip(
            message: S.of(context).shoppingReorderItem,
            child: Icon(Icons.drag_handle, size: 20, color: palette.textTertiary),
          ),
        ),
      ),
    ],
  ],
)
// Completed items: edit chevron only — no drag handle
```

**Estimated price with `amountSmall` style** (ITEM-05, UI-SPEC):
```dart
if (item.estimatedPrice != null)
  Text(
    NumberFormatter.formatCurrency(item.estimatedPrice!, 'JPY', locale),
    style: AppTextStyles.amountSmall.copyWith(
      color: switch (item.ledgerType) {
        LedgerType.daily => palette.dailyText,
        LedgerType.joy => palette.joyText,  // NEVER raw palette.joy (fails WCAG AA)
        null => palette.textSecondary,
      },
    ),
  ),
```

---

### `lib/features/shopping_list/presentation/widgets/shopping_filter_bar.dart` (widget, filter bar)

**Analog:** `lib/features/list/presentation/widgets/list_sort_filter_bar.dart`

**Container + SingleChildScrollView pattern** (lines 143-155 of analog):
```dart
return Container(
  height: 44,
  decoration: BoxDecoration(
    color: palette.background,
    border: Border(
      bottom: BorderSide(color: palette.borderDivider, width: 1),
    ),
  ),
  child: SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Ledger: All chip
        // Ledger: 日常 chip
        // Ledger: 悦己 chip
        // Category chip
        // Status: active / all chip
        // Clear-all chip (conditional — anyFilterActive)
      ],
    ),
  ),
);
```

**Ledger chip active/inactive color pattern** (lines 231-263 of analog):
```dart
ActionChip(
  label: Text(
    l10n.listLedgerDaily,
    style: AppTextStyles.caption.copyWith(
      color: filter.ledgerType == LedgerType.daily
          ? palette.daily
          : palette.textSecondary,
    ),
  ),
  backgroundColor: filter.ledgerType == LedgerType.daily
      ? palette.dailyLight
      : palette.card,
  side: BorderSide(
    color: filter.ledgerType == LedgerType.daily
        ? palette.daily
        : palette.borderDefault,
    width: 1,
  ),
  onPressed: () => ref.read(shoppingFilterProvider.notifier)
      .setLedgerFilter(filter.ledgerType == LedgerType.daily ? null : LedgerType.daily),
  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
)
```

**Category chip opening sheet** (lines 113-120 of analog + Pitfall 1 fix):
```dart
// Open CategoryFilterSheet with onApply callback (Pitfall 1: sheet writes to listFilterProvider by default)
// Add optional onApply to CategoryFilterSheet constructor:
//   final ValueChanged<Set<String>>? onApply;
// Then in apply button:
//   if (widget.onApply != null) { widget.onApply!(_localSelected); Navigator.pop(context); }
//   else { ref.read(listFilterProvider.notifier).setCategories(...); Navigator.pop(context); }

showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (_) => CategoryFilterSheet(
    initialSelected: filter.categoryIds,
    onApply: (ids) => ref.read(shoppingFilterProvider.notifier).setCategoryIds(ids),
  ),
);
```

**Conditional clear-all chip** (lines 493-521 of analog):
```dart
// anyFilterActive computed from shoppingFilterProvider state (same pattern)
final anyFilterActive =
    filter.ledgerType != null ||
    filter.categoryIds.isNotEmpty ||
    filter.statusFilter != 'all';

if (anyFilterActive) ...[
  const SizedBox(width: 8),
  Semantics(
    label: 'Clear all filters',
    child: ActionChip(
      avatar: Icon(Icons.clear_all, size: 14, color: palette.textSecondary),
      label: Text(l10n.listClearAll,
          style: AppTextStyles.caption.copyWith(color: palette.textSecondary)),
      backgroundColor: palette.backgroundMuted,
      side: BorderSide(color: palette.borderDefault, width: 1),
      onPressed: () => ref.read(shoppingFilterProvider.notifier).clearAll(),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
  ),
],
```

---

### `lib/features/shopping_list/presentation/widgets/shopping_empty_state.dart` (widget, empty state)

**Analog:** `lib/features/list/presentation/widgets/list_empty_state.dart`

**Enum + switch pattern** (lines 10-59 of analog):
```dart
enum ShoppingEmptyVariant {
  privateEmpty,     // private list, no items
  publicSolo,       // public list, no family group
  publicFamily,     // public list, family joined but empty
}

class ShoppingEmptyState extends ConsumerWidget {
  const ShoppingEmptyState({super.key, required this.listType});
  final String listType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 3-way branch: (listType, isGroupMode)
    final isGroupMode = ref.watch(isGroupModeProvider);
    final variant = listType == 'private'
        ? ShoppingEmptyVariant.privateEmpty
        : (isGroupMode
            ? ShoppingEmptyVariant.publicFamily
            : ShoppingEmptyVariant.publicSolo);

    final (icon, heading, body) = switch (variant) {
      ShoppingEmptyVariant.privateEmpty => (Icons.shopping_bag_outlined, S.of(context).shoppingEmptyPrivateHeading, S.of(context).shoppingEmptyPrivateBody),
      ShoppingEmptyVariant.publicSolo   => (Icons.group_outlined, S.of(context).shoppingEmptyPublicSoloHeading, S.of(context).shoppingEmptyPublicSoloBody),
      ShoppingEmptyVariant.publicFamily => (Icons.add_shopping_cart_outlined, S.of(context).shoppingEmptyPublicFamilyHeading, S.of(context).shoppingEmptyPublicFamilyBody),
    };
```

**Empty state layout pattern** (lines 61-94 of analog):
```dart
final palette = context.palette;
return Center(
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 32),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 48, color: palette.textTertiary),
        const SizedBox(height: 16),
        Text(heading,
            style: AppTextStyles.headlineSmall.copyWith(color: palette.textPrimary),
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(body,
            style: AppTextStyles.bodyMedium.copyWith(
                color: palette.textSecondary, height: 1.5),
            textAlign: TextAlign.center),
        const SizedBox(height: 24),
        // Leaf-green CTA (UI-SPEC: palette.borderInputActive)
        FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: palette.borderInputActive),
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ShoppingItemFormScreen(listType: listType),
          )),
          child: Text(S.of(context).shoppingEmptyCta,
              style: AppTextStyles.titleSmall.copyWith(color: Colors.white)),
        ),
      ],
    ),
  ),
);
```

---

### `lib/features/shopping_list/presentation/widgets/shopping_batch_action_bar.dart` (widget, bottom bar)

**Analog:** `lib/features/list/presentation/widgets/list_sort_filter_bar.dart` (visual style reference; structure differs)

**Floating bottom-bar pattern** (Material contextual-action-mode, D38-03):
```dart
class ShoppingBatchActionBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final batch = ref.watch(batchSelectModeProvider);
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: palette.card,
        border: Border(top: BorderSide(color: palette.borderDivider, width: 1)),
        boxShadow: [...],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        Text('${batch.selectedIds.length} 件選択中',
            style: AppTextStyles.titleSmall),
        const Spacer(),
        FilledButton.tonal(
          style: FilledButton.styleFrom(backgroundColor: palette.errorSurface),
          onPressed: batch.selectedIds.isEmpty ? null : () async {
            final confirmed = await showSoftConfirmDialog(context,
                title: S.of(context).shoppingBatchDeleteTitle,
                body: S.of(context).shoppingBatchDeleteBody(batch.selectedIds.length),
                confirmLabel: S.of(context).shoppingBatchDeleteConfirm,
                cancelLabel: S.of(context).shoppingDeleteCancelButton);
            if (!confirmed) return;
            showSuccessFeedback(context, S.of(context).shoppingBatchDeletedSnackBar);
            for (final id in batch.selectedIds) {
              ref.read(deleteShoppingItemUseCaseProvider).execute(id);
            }
            ref.read(batchSelectModeProvider.notifier).exit();
          },
          child: Text(S.of(context).shoppingBatchDeleteAction,
              style: AppTextStyles.titleSmall.copyWith(color: palette.error)),
        ),
      ]),
    );
  }
}
```

---

### `lib/features/shopping_list/presentation/widgets/shopping_selection_header.dart` (widget, header)

**Analog:** `list_sort_filter_bar.dart` (structural reference)

**Top selection header pattern** (D38-03, Material contextual-action-mode):
```dart
class ShoppingSelectionHeader extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final batch = ref.watch(batchSelectModeProvider);
    return Container(
      height: 48,
      color: palette.backgroundMuted,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        // Cancel
        TextButton(
          onPressed: () => ref.read(batchSelectModeProvider.notifier).exit(),
          child: Text(S.of(context).shoppingBatchCancel,
              style: AppTextStyles.titleSmall.copyWith(color: palette.textSecondary)),
        ),
        const Spacer(),
        // "N selected"
        Text('${batch.selectedIds.length} 件',
            style: AppTextStyles.titleLarge),
        const Spacer(),
        // Select all
        TextButton(
          onPressed: () {/* ref.read(batchSelectModeProvider.notifier).selectAll(allIds) */},
          child: Text(S.of(context).shoppingBatchSelectAll,
              style: AppTextStyles.titleSmall.copyWith(color: palette.borderInputActive)),
        ),
      ]),
    );
  }
}
```

---

### `lib/features/home/presentation/screens/main_shell_screen.dart` (MODIFY)

**Analog:** itself — in-place modification

**Step 1: Replace 4th-tab placeholder** (line 125 of existing file):
```dart
// BEFORE (line 125):
Center(child: Text(S.of(context).todoTab)),

// AFTER:
const ShoppingListScreen(),  // import added
```

**Step 2: Batch-mode guard around the Positioned block** (lines 128-190):
```dart
// BEFORE: Positioned block is unconditional (lines 128-190)
Positioned(left: 0, right: 0, bottom: 0, child: HomeBottomNavBar(...))

// AFTER: wrap with batch guard
final batchActive = ref.watch(batchSelectModeProvider).isActive;
if (!batchActive)
  Positioned(
    left: 0,
    right: 0,
    bottom: 0,
    child: HomeBottomNavBar(
      currentIndex: currentIndex,
      onTap: (index) =>
          ref.read(selectedTabIndexProvider.notifier).select(index),
      onFabTap: () async { /* see Step 3 */ },
    ),
  ),
```

**Step 3: Context-aware FAB** (lines 136-188 of existing — replace the onFabTap body):
```dart
onFabTap: () async {
  if (currentIndex == 3) {
    // NAV-01: shopping tab → add-shopping-item screen
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ShoppingItemFormScreen(
          listType: ref.read(listTypeProvider),
        ),
      ),
    );
    // Shopping items reactive via .watch() — NO invalidate needed here
  } else {
    // SC1: ALL existing invalidations PRESERVED VERBATIM
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ManualOneStepScreen(bookId: bookId),
      ),
    );
    // PRESERVE THESE LINES VERBATIM (lines 143-187 of current file):
    final now = DateTime.now();
    final currentMonthStart = DateTime(now.year, now.month, 1);
    final currentMonthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    ref.invalidate(monthlyReportProvider(bookId: bookId, startDate: currentMonthStart, endDate: currentMonthEnd));
    ref.invalidate(todayTransactionsProvider(bookId: bookId));
    ref.invalidate(bestJoyMomentProvider(bookId: bookId, startDate: currentMonthStart, endDate: currentMonthEnd));
    final bookAsync = ref.read(bookByIdProvider(bookId: bookId));
    if (bookAsync.hasValue) {
      ref.invalidate(happinessReportProvider(bookId: bookId, startDate: currentMonthStart, endDate: currentMonthEnd, currencyCode: bookAsync.value?.currency ?? 'JPY'));
    }
    ref.invalidate(listTransactionsProvider(bookId: bookId));
    ref.invalidate(calendarDailyTotalsProvider(bookId: bookId, year: now.year, month: now.month));
  }
},
```

---

### `lib/features/home/presentation/widgets/home_bottom_nav_bar.dart` (MODIFY)

**Analog:** itself — in-place modification

**Icon swap** (lines 24-29 of existing file):
```dart
// BEFORE:
static const _icons = [
  Icons.home_outlined,
  Icons.list,
  Icons.bar_chart,
  Icons.check_box_outlined,   // ← line 28
];

// AFTER:
static const _icons = [
  Icons.home_outlined,
  Icons.list,
  Icons.bar_chart,
  Icons.shopping_bag_outlined,  // NAV-02
];
```
The `_buildTab` method uses `_icons[index]` for the inactive state. For active state the same icon is used (no separate active icon array). To show `Icons.shopping_bag` when active, update `_buildTab`:
```dart
// In _buildTab, line 97-99:
Icon(
  isActive ? _activeIcons[index] : _icons[index],  // Add _activeIcons static const
  ...
)
// OR simply check index == 3 inside _buildTab to swap to filled icon
```

**Label swap** (lines 33-38 of existing file):
```dart
// BEFORE:
final labels = [
  l10n.homeTabHome,
  l10n.homeTabList,
  l10n.homeTabChart,
  l10n.homeTabTodo,   // ← line 37 — update VALUE in ARB, keep key for now (Phase 39 renames key)
];
// The rendered label changes because app_ja.arb "homeTabTodo" value → "買い物リスト"
// No Dart code change needed for the label — only ARB value update.
```

---

## Shared Patterns

### Pattern: `context.palette` — palette access
**Source:** `lib/core/theme/app_palette.dart` (ThemeExtension)
**Apply to:** ALL new widget files
```dart
final palette = context.palette;
// Never: AppPalette.light.someColor (static)
// Never: Color(0xFF...)  (inline literal)
```

### Pattern: Error handling + feedback — `showSoftConfirmDialog` + `showSuccessFeedback`
**Source:** `lib/shared/widgets/soft_confirm_dialog.dart` + `lib/shared/widgets/feedback_toast.dart`
**Apply to:** `shopping_item_tile.dart`, `shopping_batch_action_bar.dart`
```dart
// Confirmed signatures (soft_confirm_dialog.dart lines 16-22):
Future<bool> showSoftConfirmDialog(BuildContext context, {
  required String title, required String body,
  required String confirmLabel, required String cancelLabel,
})

// Confirmed signatures (feedback_toast.dart lines 79-94):
void showSuccessFeedback(BuildContext context, String message, {
  Duration duration = _kDefaultFeedbackDuration,
  String? actionLabel, VoidCallback? onAction,
})
void showErrorFeedback(BuildContext context, String message, { ... })
```
**CRITICAL ORDER:** `showSuccessFeedback` BEFORE `ref.read(useCase).execute()` in `onDismissed` callbacks (context may be invalid after async completes).

### Pattern: `AppTextStyles.*` — typography
**Source:** `lib/core/theme/app_text_styles.dart`
**Apply to:** ALL new widget/screen files
Key tokens for this phase (from UI-SPEC typography table):
- `AppTextStyles.bodyLarge` — tile item name (primary)
- `AppTextStyles.bodySmall` — tile secondary metadata
- `AppTextStyles.amountSmall` — estimated price (MUST include `.copyWith(color: palette.dailyText/joyText)`)
- `AppTextStyles.caption` — filter chip labels, attribution chip
- `AppTextStyles.titleLarge` — form app-bar title, batch header "N selected"
- `AppTextStyles.headlineSmall` — empty-state heading
- `AppTextStyles.bodyMedium` — empty-state body

### Pattern: Riverpod 3 `ref.listen` for side-effects
**Source:** `lib/features/home/presentation/screens/main_shell_screen.dart` lines 38-103
**Apply to:** Any provider-driven navigation or toast in screen files
```dart
// CORRECT: side-effects via ref.listen
ref.listen(someErrorProvider, (prev, next) {
  if (next != null) showErrorFeedback(context, next);
});
// WRONG: ref.watch for side-effects (Riverpod 3 dropped watch-driven side-effects)
```

### Pattern: `S.of(context).*` — localization
**Source:** all existing widget files
**Apply to:** ALL new widget/screen files — no hardcoded strings
```dart
// All UI strings via S.of(context).someKey
// Final ARB keys: Phase 39 (NAV-03); this phase wires the string slots
```

### Pattern: `NumberFormatter.formatCurrency` — amount formatting
**Source:** `lib/infrastructure/i18n/formatters/number_formatter.dart` (used in `list_screen.dart` line 277)
**Apply to:** `shopping_item_tile.dart` (estimated price), `shopping_item_form_screen.dart` (price display)
```dart
NumberFormatter.formatCurrency(item.estimatedPrice!, 'JPY', locale)
// locale from: ref.watch(currentLocaleProvider).value ?? const Locale('ja')
```

---

## No Analog Found

All files in this phase have strong analogs. No file requires RESEARCH.md-only patterns.

---

## Critical Landmines (executor must resolve in Wave 0)

| # | File | Issue | Resolution |
|---|------|-------|------------|
| L1 | `lib/features/shopping_list/domain/models/shopping_list_filter.dart` | Missing `categoryIds: Set<String>` field — compiler error when filter bar calls `.copyWith(categoryIds: ids)` | Add `@Default(<String>{}) Set<String> categoryIds` + `flutter pub run build_runner build --delete-conflicting-outputs` |
| L2 | `shopping_item_tile.dart` inside `SliverReorderableList` | Gesture conflict: default `buildDefaultDragHandles: true` fights `Dismissible` horizontal swipe and long-press batch-select | Set `buildDefaultDragHandles: false` on `SliverReorderableList`; wrap handle icon in `ReorderableDragStartListener` |
| L3 | `list_category_filter_sheet.dart` | Apply button writes to `listFilterProvider` (wrong provider for shopping context) | Add `final ValueChanged<Set<String>>? onApply` to `CategoryFilterSheet` constructor; branch on null in apply handler |
| L4 | `batchSelectModeProvider` scope | If overridden in a local ProviderScope, `MainShellScreen` cannot read it — nav bar never hides | Never override in local ProviderScope; place at app-root scope |
| L5 | `main_shell_screen.dart` FAB | All post-`ManualOneStepScreen` invalidations at lines 153-187 MUST be preserved verbatim (SC1 accounting regression) | Copy lines 153-187 verbatim into the `else` branch of the FAB handler |

---

## Metadata

**Analog search scope:** `lib/features/list/presentation/`, `lib/features/home/presentation/`, `lib/features/accounting/presentation/screens/`, `lib/shared/widgets/`, `lib/features/shopping_list/`, `lib/application/shopping_list/`, `lib/features/family_sync/presentation/providers/`
**Files scanned:** 16 source files read directly
**Confirmed provider names:**
- `shoppingItemChangeTrackerProvider` (`state_sync.dart` line 27 — `class ShoppingItemChangeTracker`)
- `syncEngineProvider` (`state_sync.dart` line 55 — `class SyncEngine`)
- `listFilterProvider` (`state_list_filter.dart` line 17 — `class ListFilter`)
- `selectedTabIndexProvider` (`state_home.dart` — `class SelectedTabIndex` → `selectedTabIndexProvider`)
**Pattern extraction date:** 2026-06-08
