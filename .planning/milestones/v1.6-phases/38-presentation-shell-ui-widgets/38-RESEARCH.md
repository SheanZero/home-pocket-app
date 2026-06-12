# Phase 38: Presentation Shell + UI Widgets - Research

**Researched:** 2026-06-08
**Domain:** Flutter presentation layer — Riverpod 3, Material widgets, SliverReorderableList, Dismissible, cross-provider batch-mode coordination
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D38-01:** Tap row body = toggle completed (DONE-01). Edit via explicit trailing chevron/info affordance. Trailing cluster on active items: edit chevron + drag handle (both ≥44px). Completed items: edit chevron only (no drag handle).
- **D38-02:** Drag-reorder via `ReorderableDragStartListener` handle (NOT long-press, which is owned by batch-select). Active items in `SliverReorderableList`. Completed items fixed below divider, not reorderable. Wires `ReorderShoppingItemsUseCase`. Handles hidden while batch mode active.
- **D38-03:** Material contextual-action-mode. `batchSelectModeProvider` (transient, not keepAlive) shared between `MainShellScreen` and `ShoppingListScreen`. `MainShellScreen` watches it and hides the entire `Positioned(nav bar + FAB)` block while batch mode active. Screen shows top selection header + bottom floating batch action bar.
- **D38-04:** Build a NEW shopping-specific chip bar (NOT reuse/refactor `list_sort_filter_bar.dart`). Dimensions: ledger (All/日常/悦己) + category + status (active/all). Category reuses `list_category_filter_sheet.dart`. One-tap clear-all-filters. Sticky beneath the segmented control. Filter state reset on segment switch (D5/SC2).

### Claude's Discretion

- Empty-state copy + layout for 3 SHOP-04 variants (final ARB strings are Phase 39)
- Family attribution chip (SYNC-04) — mirror `taggedTx.memberTag` chip
- Strikethrough + fade animation (DONE-01) timing/curve
- Loading-state style (spinner vs skeleton)
- Add/edit form layout (full-screen `MaterialPageRoute` mirroring `ManualOneStepScreen`)
- Estimated-price input widget shape

### Deferred Ideas (OUT OF SCOPE)

- Cross-device synced shopping-list ordering (D37-01; D38-02 reorder is local-only)
- v2 shopping enhancements (SUBTOTAL-01, AUTO-01, GROUP-01, TAGFILT-01, DUP-01, COLLAPSE-01)
- ARB key parity / `flutter gen-l10n` / golden re-baseline / reactive-sync smoke test (Phase 39, NAV-03)
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SHOP-02 | Scrollable list showing item name, category emoji, quantity, estimated price | `ShoppingItem` model fields confirmed: name, categoryId, quantity, estimatedPrice |
| SHOP-03 | Dual-ledger left border accent (`palette.daily`/`palette.joy`/neutral) | Tile left-border pattern: `BoxDecoration(border: Border(left: BorderSide(color: ..., width: 4)))` |
| SHOP-04 | 3-variant empty state (empty private / empty public solo / empty public family) | Mirror `ListEmptyState` structure; 3-way branch on (segment, `isGroupMode`) |
| DONE-01 | Tap row to toggle completed with animated strikethrough + fade | `AnimatedDefaultTextStyle` + `AnimatedOpacity` at ~200ms; `ToggleItemCompletedUseCase.execute(itemId)` |
| DONE-03 | "Clear all completed" button (confirmation; fires `ClearCompletedItemsUseCase`) | `ClearCompletedItemsUseCase.execute(listType)` — visible only when completed section non-empty |
| ITEM-01 | Add item form — name required only | `CreateShoppingItemUseCase.execute(CreateShoppingItemParams(...))` |
| ITEM-02 | Optional ledger, category, tags, note, quantity, estimated price in form | All optional fields on `CreateShoppingItemParams` confirmed |
| ITEM-04 | Edit form pre-populated | `UpdateShoppingItemUseCase.execute(UpdateShoppingItemParams(itemId: ..., ...))` |
| FILT-01 | Chip bar: ledger/category/status | New `ShoppingFilterBar` widget; `shoppingFilterProvider` state |
| FILT-02 | Filter shared across segments; resets on segment switch | `shoppingFilterProvider` keepAlive: true + reset in `listTypeProvider` notifier |
| FILT-03 | Clear-all-filters in one tap | Conditional clear chip (same pattern as `ListSortFilterBar` clear chip) |
| MGMT-01 | Swipe-to-delete with confirmation | `Dismissible` + `showSoftConfirmDialog` + `showSuccessFeedback` BEFORE provider call |
| MGMT-02 | Long-press batch-select → batch-delete | `batchSelectModeProvider`; `DeleteShoppingItemUseCase.execute(id)` per selected item |
| MGMT-03 | Swipe/drag disabled during batch mode | Guard `Dismissible` direction and handle visibility via `batchSelectModeProvider` watch |
| NAV-01 | Context-aware FAB: index 3 → add-shopping-item; others → ManualOneStepScreen + all invalidations | Exact invalidation lines from `main_shell_screen.dart` lines 153-187 (preserved verbatim) |
| NAV-02 | Nav tab rename + `Icons.shopping_bag_outlined`/`shopping_bag` | `home_bottom_nav_bar.dart` `_icons[3]` + `homeTabTodo` ARB key |
| SYNC-04 | Attribution chip on public tiles (avatar emoji + display name from shadow books) | `addedByBookId` on `ShoppingItem`; resolve `ShadowBookInfo` from `shadowBooksProvider` |
</phase_requirements>

---

## Summary

Phase 38 is a pure presentation phase. All domain models (Phase 36), use cases (Phase 37), and repository layer are complete and available for wiring. The work is: (1) replace the `Center(Text(todoTab))` placeholder in `MainShellScreen`'s `IndexedStack` with `ShoppingListScreen`; (2) build the provider graph (`listTypeProvider`, `shoppingFilterProvider`, `batchSelectModeProvider`); (3) implement `ShoppingItemTile`, `ShoppingFilterBar`, `ShoppingListScreen` shell, add/edit form, empty states, and batch-select chrome.

The biggest integration site is `main_shell_screen.dart` — the planner must preserve every existing post-transaction-entry `ref.invalidate(...)` call verbatim (SC1 accounting regression requirement) while adding the `currentIndex == 3` FAB branch and the `batchSelectModeProvider` guard around the `Positioned` block.

Two notable landmines: (1) `ShoppingListFilter` (Phase 36 model) lacks a `categoryIds` field — the filter bar needs it; the planner must decide whether to extend the Freezed model or use a separate state object in the screen-state provider; (2) the DAO `watchByListType` returns ALL items for the segment (ledger/category/status filtering is client-side in the provider layer, same as how `listTransactionsProvider` applies filter state).

**Primary recommendation:** Structure the wave plan as: W0 (provider graph + test stubs) → W1 (shell + tile + empty states) → W2 (filter bar + form + swipe/batch/reorder) → W3 (MainShellScreen integration + batch-mode guard).

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Reactive item stream | DAO (data) | Repository | `watchByListType` already wired with `readsFrom:`; never manual-invalidate |
| Filtering (ledger/category/status) | Provider (presentation) | — | DAO stream returns all non-deleted items for segment; client filter in `shoppingFilterProvider`-derived StreamProvider |
| Toggle completed | Application (use case) | Presentation (animation) | `ToggleItemCompletedUseCase` handles persistence + sticky-complete + sync; tile adds animated UI on top |
| Reorder | Application (local only) | Presentation | `ReorderShoppingItemsUseCase` (local-only, no sync) |
| Context-aware FAB routing | Presentation shell | — | `currentIndex == 3` branch in `MainShellScreen.onFabTap` |
| Batch-mode hide nav/FAB | Presentation shell (parent) | Presentation screen (child) | `batchSelectModeProvider` bridges parent (`MainShellScreen`) and child (`ShoppingListScreen`) |
| Attribution chip | Presentation tile | Shadow books provider | `addedByBookId` on `ShoppingItem` → lookup against `shadowBooksProvider` |
| Form encryption | Application → Repository boundary | — | Note field encrypted at `ShoppingItemRepositoryImpl` (Phase 36); form passes plaintext |

---

## Standard Stack

No new packages this phase. [VERIFIED: flutter pub deps]

### Core (all already in pubspec)
| Library | Purpose | Already Present |
|---------|---------|----------------|
| flutter_riverpod / riverpod_annotation | Provider state management | Yes — Riverpod 3 |
| freezed_annotation / build_runner | Immutable state models | Yes — Freezed |
| flutter (Material 3) | SliverReorderableList, Dismissible, AnimatedDefaultTextStyle | Yes |

### No New Packages
Phase 38 assembles only from Material 3 widgets + first-party project widgets (`lib/shared/widgets/`, `lib/features/list/presentation/widgets/`). Zero new dependencies enter the codebase.

---

## Package Legitimacy Audit

Not applicable — no external packages installed in this phase.

---

## Architecture Patterns

### System Architecture Diagram

```
DAO watchByListType('public'|'private')
    ↓ Stream<List<ShoppingItem>>
shoppingItemsStreamProvider (StreamProvider — binds stream, no invalidate)
    ↓ applies filter state from shoppingFilterProvider
filteredShoppingItemsProvider (derived)
    ↓ List<ShoppingItem>
ShoppingListScreen
  ├── [active items] → SliverReorderableList → ShoppingItemTile (active)
  │       ├── long-press → batchSelectModeProvider.enter()
  │       ├── tap row → ToggleItemCompletedUseCase.execute(id)
  │       ├── swipe → DeleteShoppingItemUseCase.execute(id)
  │       ├── drag handle → ReorderShoppingItemsUseCase.execute(id, newOrder)
  │       └── chevron tap → push ShoppingItemFormScreen(item)
  ├── [divider] "Completed" — visible when completed section non-empty
  ├── [completed items] → SliverList → ShoppingItemTile (completed)
  │       └── chevron tap → push ShoppingItemFormScreen(item)
  └── [empty state] → ShoppingEmptyState (3-way branch)

MainShellScreen watches batchSelectModeProvider:
  batchMode=false → show Positioned(HomeBottomNavBar + FAB)
  batchMode=true  → hide Positioned block entirely
                    ShoppingListScreen shows top-header + bottom-batch-bar
```

### Recommended Project Structure

```
lib/features/shopping_list/presentation/
├── providers/
│   ├── repository_providers.dart          # EXISTING (Phase 36/37) — extend with use-case providers
│   ├── repository_providers.g.dart        # EXISTING
│   ├── state_shopping_filter.dart         # NEW: listTypeProvider + shoppingFilterProvider (both keepAlive: true)
│   ├── state_shopping_filter.g.dart       # generated
│   ├── state_shopping_batch.dart          # NEW: batchSelectModeProvider (transient)
│   ├── state_shopping_batch.g.dart        # generated
│   └── import_guard.yaml                  # EXISTING (Phase 36)
├── screens/
│   ├── shopping_list_screen.dart          # NEW: main shell replacing todoTab placeholder
│   ├── shopping_item_form_screen.dart     # NEW: add/edit full-screen MaterialPageRoute
│   └── import_guard.yaml                  # NEW (mirror list/presentation/screens/)
└── widgets/
    ├── shopping_item_tile.dart            # NEW: Dismissible + toggle + trailing cluster
    ├── shopping_filter_bar.dart           # NEW: ledger/category/status chip bar
    ├── shopping_empty_state.dart          # NEW: 3-variant empty state
    ├── shopping_batch_action_bar.dart     # NEW: floating bottom bar (batch-delete)
    ├── shopping_selection_header.dart     # NEW: top header (N selected + Select-all + Cancel)
    └── import_guard.yaml                  # NEW
```

### Pattern 1: keepAlive Provider with Reset on Segment Switch

Mirror of `state_list_filter.dart`:

```dart
// lib/features/shopping_list/presentation/providers/state_shopping_filter.dart
// Source: lib/features/list/presentation/providers/state_list_filter.dart

@Riverpod(keepAlive: true)
class ListType extends _$ListType {
  @override
  String build() => 'private'; // default segment

  void setListType(String type) {
    // D5/SC2: reset ALL filter state when switching segments
    state = type;
    // Notifier chain: inform ShoppingFilter to reset
    ref.read(shoppingFilterProvider.notifier).resetForNewSegment();
  }
}

@Riverpod(keepAlive: true)
class ShoppingFilter extends _$ShoppingFilter {
  @override
  ShoppingListFilter build() => ShoppingListFilter.initial();

  void setLedgerFilter(LedgerType? type) =>
      state = state.copyWith(ledgerType: type);

  void setStatusFilter(String status) =>  // 'all' | 'active'
      state = state.copyWith(statusFilter: status);

  void setCategoryIds(Set<String> ids) =>
      state = state.copyWith(categoryIds: ids);  // ⚠ LANDMINE: field missing — see below

  void clearAll() => state = ShoppingListFilter.initial();

  /// Called by listTypeProvider on segment switch (D5/SC2).
  void resetForNewSegment() => state = ShoppingListFilter.initial();
}
```

**⚠ LANDMINE 1 — categoryIds missing from ShoppingListFilter model:**
`ShoppingListFilter` (Phase 36, `lib/features/shopping_list/domain/models/shopping_list_filter.dart`) has `listType`, `ledgerType`, `statusFilter`, `searchQuery` — **but no `categoryIds: Set<String>` field**. The filter bar (D38-04) needs a category dimension. The planner must either:
- Option A (preferred): Add `@Default(<String>{}) Set<String> categoryIds` to `ShoppingListFilter` + run build_runner to regenerate `.freezed.dart`
- Option B: Hold category state separately in the screen-state provider

Option A is cleaner (single source of truth) but requires touching the Phase 36 model + regenerating. This is a concrete plan task.

### Pattern 2: Dismissible Swipe-Delete (VERIFIED ordering from list_transaction_tile.dart)

The CRITICAL ordering from `list_transaction_tile.dart` lines 99-114:

```dart
// Source: lib/features/list/presentation/widgets/list_transaction_tile.dart:90-115
Dismissible(
  key: ValueKey(item.id),
  direction: DismissDirection.endToStart,
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
    // CRITICAL order: feedback toast BEFORE any provider calls (context still valid here)
    showSuccessFeedback(context, S.of(context).shoppingDeletedSnackBar);
    // Fire-and-forget — do NOT await inside onDismissed
    ref.read(deleteShoppingItemUseCaseProvider).execute(item.id);
  },
  // ...
)
```

**Rule:** `showSuccessFeedback` fires BEFORE `ref.read(useCase).execute()` because by the time the use-case async completes the widget may be unmounted. This ordering is the established codebase convention.

**Batch mode guard:** When `batchSelectModeProvider.state.isActive`, set `direction: DismissDirection.none` on the Dismissible to disable swipe (MGMT-03).

### Pattern 3: SliverReorderableList + ReorderableDragStartListener

Example from `category_selection_screen.dart` lines 354-388:

```dart
// Source: lib/features/accounting/presentation/screens/category_selection_screen.dart:354
SliverReorderableList(
  itemCount: activeItems.length,
  onReorder: (oldIndex, newIndex) {
    // Adjust newIndex for Flutter's reorder convention (newIndex > oldIndex → subtract 1)
    final adjusted = newIndex > oldIndex ? newIndex - 1 : newIndex;
    ref.read(reorderShoppingItemsUseCaseProvider)
       .execute(activeItems[oldIndex].id, adjusted);
  },
  itemBuilder: (context, index) {
    final item = activeItems[index];
    return ShoppingItemTile(
      key: ValueKey(item.id),  // REQUIRED: unique key for each reorderable item
      item: item,
      // ... other props
    );
  },
)
```

The `ReorderableDragStartListener` wraps the drag handle **inside** the tile:

```dart
// Source: category_selection_screen.dart:476-488
ReorderableDragStartListener(
  index: index,   // must match the SliverReorderableList itemBuilder index
  child: Icon(Icons.drag_handle, ...),
)
```

**⚠ LANDMINE 2 — SliverReorderableList + Dismissible gesture conflict:**
`SliverReorderableList` internally wraps each item in a gesture recognizer for drag detection. A `Dismissible` inside the reorderable item creates a gesture competition between horizontal swipe (Dismissible) and vertical drag (reorder). The established workaround: use `ReorderableDragStartListener` on an **explicit handle icon** with `buildDefaultDragHandles: false` on the `SliverReorderableList` — this restricts reorder gesture to only the handle's bounds, leaving horizontal swipe uncontested on the row body. Verify by checking `buildDefaultDragHandles` parameter (must be `false`).

### Pattern 4: Context-Aware FAB in MainShellScreen

The existing `onFabTap` block (lines 136-188) must be replaced with an index-conditional:

```dart
// Modified from main_shell_screen.dart:136-188
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
    // Shopping items are reactive via .watch() stream — no invalidate needed
  } else {
    // SC1: ALL existing invalidations PRESERVED VERBATIM
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ManualOneStepScreen(bookId: bookId),
      ),
    );
    // PRESERVE these exact lines (lines 153-187 verbatim):
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

**Batch-mode guard around the Positioned block:**

```dart
// Wrap the ENTIRE Positioned block at main_shell_screen.dart:128-190
final batchActive = ref.watch(batchSelectModeProvider).isActive;
if (!batchActive)
  Positioned(
    left: 0, right: 0, bottom: 0,
    child: HomeBottomNavBar(
      currentIndex: currentIndex,
      onTap: ...,
      onFabTap: ...,
    ),
  ),
```

### Pattern 5: keepAlive + IndexedStack Tab Persistence

From `state_list_filter.dart` line 16:

```dart
// Source: lib/features/list/presentation/providers/state_list_filter.dart:16
@Riverpod(keepAlive: true)
class ListFilter extends _$ListFilter { ... }
```

The `keepAlive: true` annotation on the `@Riverpod(...)` constructor ensures Riverpod does not dispose the notifier when no widgets are actively watching it (e.g., when the IndexedStack hides the shopping tab). The generated provider name follows Riverpod 3's suffix-stripping rule: `class ListFilter` → `listFilterProvider` (not `listFilterNotifierProvider`).

Apply identically:
- `class ListType extends _$ListType` → generates `listTypeProvider`
- `class ShoppingFilter extends _$ShoppingFilter` → generates `shoppingFilterProvider`
- `class BatchSelectMode extends _$BatchSelectMode` → generates `batchSelectModeProvider` (NOT keepAlive — transient)

### Pattern 6: Attribution Chip (SYNC-04)

From `list_transaction_tile.dart` lines 198-221 (verbatim):

```dart
// Source: lib/features/list/presentation/widgets/list_transaction_tile.dart:198-221
if (taggedTx.memberTag case final tag?) ...[
  ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 72),
    child: Container(
      decoration: BoxDecoration(
        color: palette.sharedLight,
        borderRadius: BorderRadius.circular(3),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      child: Text(
        '${tag.emoji} ${tag.name}',
        style: AppTextStyles.micro.copyWith(color: palette.sharedText),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ),
  ),
  const SizedBox(width: 8),
],
```

For `ShoppingItemTile`, the chip logic branches on `item.addedByBookId`:
- `null` → no chip (own item, or private list)
- non-null → look up in `shadowBooksProvider` to resolve emoji + name → render chip

**Attribution null-handling rule (D36-Claude's Discretion):** If `addedByBookId` is set but the shadow book is not yet local (family not yet synced), omit the chip silently. Never throw.

```dart
// In ShoppingItemTile or parent screen:
final shadows = ref.watch(shadowBooksProvider).valueOrNull ?? const [];
final memberTag = item.addedByBookId != null
    ? shadows.firstWhereOrNull((s) => s.book.id == item.addedByBookId)
    : null;
// memberTag?.memberAvatarEmoji, memberTag?.memberDisplayName → chip
```

**Note:** `ValueOrNull` is Riverpod 2 syntax. In Riverpod 3, use `.value` (nullable): `ref.watch(shadowBooksProvider).value ?? const []`.

### Pattern 7: Segmented Control (Public/Private)

No existing segmented-control pattern in the project. Implement with `SegmentedButton` (Material 3) or a custom two-chip row:

```dart
// Recommended: Material 3 SegmentedButton
SegmentedButton<String>(
  segments: const [
    ButtonSegment(value: 'public', label: Text('公開')),
    ButtonSegment(value: 'private', label: Text('プライベート')),
  ],
  selected: {ref.watch(listTypeProvider)},
  onSelectionChanged: (newSet) =>
      ref.read(listTypeProvider.notifier).setListType(newSet.first),
  style: SegmentedButton.styleFrom(
    selectedBackgroundColor: palette.borderInputActive,
    selectedForegroundColor: Colors.white,
  ),
)
```

Or a simpler two-chip custom row if SegmentedButton doesn't match the design spec exactly.

### Anti-Patterns to Avoid

- **Calling `ref.invalidate(shoppingItemsStreamProvider)` after mutations:** The DAO stream is reactive via `readsFrom:`. Mutations through the repo → DAO automatically trigger re-emission. Manual invalidate for sync-driven changes violates the GAP-2 lesson (STATE.md).
- **Long-press as drag trigger:** Long-press is owned by batch-select (D38-02). Drag must use `ReorderableDragStartListener` on an explicit handle icon.
- **Putting `batchSelectModeProvider` as `keepAlive: true`:** It is transient UI state. If the user leaves the shopping tab, batch mode should exit. Do NOT keepAlive.
- **Using `context.palette.joy` for amount text:** Use `palette.joyText` for ledger-tinted price text (raw `joy` fails WCAG AA on white at ~2.2:1 — see CLAUDE.md ADR-019 warning).
- **Skipping `showSuccessFeedback` before provider call in `onDismissed`:** Context validity is NOT guaranteed after the async use-case call. The feedback line must appear first.
- **Using `ref.watch` for side-effects (navigation, toasts):** Use `ref.listen` (Riverpod 3 convention from CLAUDE.md).

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Confirm dialog | Custom AlertDialog | `showSoftConfirmDialog(context, title:, body:, confirmLabel:, cancelLabel:)` | Already in `lib/shared/widgets/soft_confirm_dialog.dart`; warm rounded design, palette-driven |
| Success/error toast | Custom overlay | `showSuccessFeedback(context, message)` / `showErrorFeedback(context, message)` | Singleton toast in `lib/shared/widgets/feedback_toast.dart`; suppresses stacking |
| Category picker | Custom picker | Push `CategorySelectionScreen(selectedCategoryId: ...)` | Returns `Category?` via `Navigator.pop(context, child)` |
| Ledger selector chips | Custom chips | `LedgerTypeSelector(selected:, onChanged:, dailyLabel:, joyLabel:)` | In `lib/shared/widgets/ledger_type_selector.dart` |
| Category filter bottom sheet | Custom sheet | `showModalBottomSheet` with `CategoryFilterSheet(initialSelected: ids)` | In `lib/features/list/presentation/widgets/list_category_filter_sheet.dart`; writes via `listFilterProvider`... ⚠ see landmine below |
| Amount formatting | Custom format | `NumberFormatter.formatCurrency(amount, 'JPY', locale)` | In `lib/infrastructure/i18n/formatters/number_formatter.dart` |
| Amount text style | `TextStyle(fontSize:...)` | `AppTextStyles.amountSmall.copyWith(color: palette.dailyText)` | Tabular figures, CLAUDE.md rule |

**Key insight:** `CategoryFilterSheet` writes to `listFilterProvider` — if reused for shopping, it writes to the wrong provider. See Landmine 3 below.

---

## Common Pitfalls

### Pitfall 1: CategoryFilterSheet writes to listFilterProvider (wrong provider)
**What goes wrong:** `list_category_filter_sheet.dart` line 288 calls `ref.read(listFilterProvider.notifier).setCategories(...)`. If reused as-is in the shopping context, it silently mutates the transaction list filter state instead of the shopping filter state.
**Why it happens:** The sheet uses the imported `listFilterProvider` from the accounting/list feature.
**How to avoid:** One of:
- Option A: Pass a callback `onApply(Set<String> ids)` to the sheet (requires a minor addition to its constructor)
- Option B: Copy the sheet and wire to `shoppingFilterProvider`
- Option C: Use the sheet but override the provider in `ProviderScope` around it
Option A is cleanest and minimally invasive. Verify against CONTEXT.md: D38-04 says "reuses the existing `list_category_filter_sheet.dart`" — a callback parameter addition qualifies as reuse.
**Warning signs:** Category filter selection on the shopping list changes the List tab's active category filter instead.

### Pitfall 2: SliverReorderableList + Dismissible gesture conflict
**What goes wrong:** Default `SliverReorderableList` builds drag handles for every item (`buildDefaultDragHandles: true`). The long-press drag activator fights with Dismissible horizontal swipe and with the long-press batch-select trigger.
**Why it happens:** Flutter's default drag activation for `SliverReorderableList` is a long-press delay, which conflicts with two other long-press uses.
**How to avoid:** Set `buildDefaultDragHandles: false` on `SliverReorderableList`. Wrap an explicit handle icon in `ReorderableDragStartListener`. This makes drag start only from the handle widget's bounding box.
**Warning signs:** Swipe-to-delete activates a drag instead, or long-press-to-batch-select fails.

### Pitfall 3: Batch-mode provider visibility — `batchSelectModeProvider` scope
**What goes wrong:** If `batchSelectModeProvider` is scoped to `ShoppingListScreen` (e.g., via overrides), `MainShellScreen` cannot read it. The nav bar + FAB never hide.
**Why it happens:** Riverpod providers are available app-wide by default, but local overrides break cross-widget access.
**How to avoid:** Do NOT override `batchSelectModeProvider` in a local `ProviderScope`. Place it at the app-root scope (auto-dispose, no keepAlive). Both `MainShellScreen` and `ShoppingListScreen` watch the same instance.
**Warning signs:** Batch mode enters correctly but nav bar and FAB remain visible.

### Pitfall 4: ShoppingListFilter model missing categoryIds field
**What goes wrong:** The `ShoppingListFilter` Freezed model (Phase 36) has `listType`, `ledgerType`, `statusFilter`, `searchQuery` — **no `categoryIds` field**. The filter bar (D38-04) needs category filtering. The planner will call `.copyWith(categoryIds: ids)` which does not exist → compile error.
**Why it happens:** Phase 36 built the model without full filter-bar scope knowledge.
**How to avoid:** Add `@Default(<String>{}) Set<String> categoryIds` to `ShoppingListFilter` in Wave 0. Run `flutter pub run build_runner build --delete-conflicting-outputs`. The model has zero consumers other than its own model file at this point, so the change is safe.
**Warning signs:** Compiler error on `copyWith(categoryIds: ...)`.

### Pitfall 5: Client-side filtering pattern — filter applied in provider, not DAO
**What goes wrong:** Calling `watchByListType('public')` and expecting the stream to honor ledger/category/status filter from `shoppingFilterProvider`. The DAO query returns ALL non-deleted items for the segment — filtering is client-side.
**Why it happens:** The DAO `watchByListType` SQL is `WHERE list_type = ? AND is_deleted = 0`. No ledger/category/status clauses.
**How to avoid:** Create a derived provider:
```dart
@riverpod
Stream<List<ShoppingItem>> filteredShoppingItems(Ref ref) {
  final filter = ref.watch(shoppingFilterProvider);
  final listType = ref.watch(listTypeProvider);
  return ref.watch(shoppingItemRepositoryProvider)
      .watchByListType(listType)
      .map((items) => items.where((item) {
        if (filter.ledgerType != null && item.ledgerType != filter.ledgerType) return false;
        if (filter.categoryIds.isNotEmpty && !filter.categoryIds.contains(item.categoryId)) return false;
        if (filter.statusFilter == 'active' && item.isCompleted) return false;
        return true;
      }).toList());
}
```
This is a `StreamProvider`, not `FutureProvider` — preserves reactivity.
**Warning signs:** Filter chips appear to change but list doesn't update.

### Pitfall 6: `ref.listen` vs `ref.watch` for side-effects (navigation)
**What goes wrong:** Using `ref.watch(someErrorProvider)` to trigger a toast or navigate. In Riverpod 3, `watch`-driven side-effects may not fire consistently (CLAUDE.md: "Side-effect listeners belong in `ref.listen`").
**How to avoid:** Use `ref.listen(provider, (prev, next) { ... })` for navigation, snackbars, and toasts triggered by provider state changes.

### Pitfall 7: NAV-02 rename — two ARB keys need updating
**What goes wrong:** Only updating `homeTabTodo` but leaving `todoTab`. Both keys render in the nav bar and the placeholder text respectively.
**Current state:** `lib/l10n/app_ja.arb` has:
- `"homeTabTodo": "やること"` (line 709) — used by `HomeBottomNavBar`
- `"todoTab": "やること"` (line 1624) — used in the `Center(Text(...))` placeholder
The placeholder disappears when replaced by `ShoppingListScreen`, so `todoTab` becomes dead after Phase 38. But `homeTabTodo` MUST be updated (and its zh/en equivalents).
**How to avoid:** Update `homeTabTodo` in all 3 ARB files. Note: NAV-03 (full ARB parity) is Phase 39, but the `homeTabTodo` rename must land in Phase 38 to satisfy SC1 "zero Todo strings remain in any rendered UI." Add `shoppingTab` or rename `homeTabTodo` ARB key in Phase 38 (or add a Phase 39 dependency note to the plan).

---

## Code Examples

### Creating `listTypeProvider` + `shoppingFilterProvider` (verbatim keepAlive pattern)

```dart
// Source: lib/features/list/presentation/providers/state_list_filter.dart (template)
// lib/features/shopping_list/presentation/providers/state_shopping_filter.dart

part 'state_shopping_filter.g.dart';

@Riverpod(keepAlive: true)
class ListType extends _$ListType {
  @override
  String build() => 'private';

  void setListType(String type) {
    state = type;
    // D5/SC2: reset filter on segment switch
    ref.read(shoppingFilterProvider.notifier).resetForNewSegment();
  }
}

@Riverpod(keepAlive: true)
class ShoppingFilter extends _$ShoppingFilter {
  @override
  ShoppingListFilter build() => ShoppingListFilter.initial();

  void setLedgerFilter(LedgerType? type) =>
      state = state.copyWith(ledgerType: type);
  void setStatusFilter(String status) =>
      state = state.copyWith(statusFilter: status);
  void setCategoryIds(Set<String> ids) =>
      state = state.copyWith(categoryIds: ids);  // ⚠ requires field addition
  void clearAll() => state = ShoppingListFilter.initial();
  void resetForNewSegment() => state = ShoppingListFilter.initial();
}
```

### Tile left-border accent (SHOP-03)

```dart
// Dual-ledger 4px left border on ShoppingItemTile
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
  // ... tile content
)
```

### Animated strikethrough + fade on completed toggle (DONE-01)

```dart
// AnimatedDefaultTextStyle + AnimatedOpacity pattern
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

### Use-case providers (wiring Phase 37 use cases into Riverpod)

```dart
// lib/features/shopping_list/presentation/providers/repository_providers.dart — EXTEND
// Add after existing shoppingItemRepositoryProvider

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
ReorderShoppingItemsUseCase reorderShoppingItemsUseCase(Ref ref) =>
    ReorderShoppingItemsUseCase(
      shoppingItemRepository: ref.watch(shoppingItemRepositoryProvider),
      // No changeTracker, no syncEngine — D37-01
    );

@riverpod
ClearCompletedItemsUseCase clearCompletedItemsUseCase(Ref ref) =>
    ClearCompletedItemsUseCase(
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
```

**Note on tracker/engine provider names:** `shoppingItemChangeTrackerProvider` and `syncEngineProvider` were wired in Phase 37 (`lib/features/family_sync/presentation/providers/state_sync.dart`). The planner must verify the exact provider names before wiring.

### CategoryFilterSheet adapter (avoiding listFilterProvider contamination)

The simplest fix — add an optional `onApply` callback to `CategoryFilterSheet`:

```dart
// Minimal change to list_category_filter_sheet.dart
// Add: final ValueChanged<Set<String>>? onApply; to constructor
// In apply button onPressed:
if (widget.onApply != null) {
  widget.onApply!(_localSelected);
  Navigator.pop(context);
} else {
  ref.read(listFilterProvider.notifier).setCategories(...);
  Navigator.pop(context);
}
```

Then in the shopping filter bar, pass `onApply: (ids) => ref.read(shoppingFilterProvider.notifier).setCategoryIds(ids)`.

---

## State of the Art

| Old Approach | Current Approach | Notes |
|--------------|------------------|-------|
| Manual `ref.invalidate` after sync mutations | Reactive `.watch()` stream via `readsFrom:` | GAP-2 lesson from v1.4; MANDATORY for shopping list |
| Riverpod 2: `AsyncValue.valueOrNull` | Riverpod 3: `AsyncValue.value` (nullable) | `valueOrNull` removed |
| Riverpod 2: provider name + `Notifier` suffix | Riverpod 3: suffix stripped (`ListFilter` → `listFilterProvider`) | Critical for wiring |
| `StateNotifierProvider` (legacy) | `@riverpod class X extends _$X` (generator) | Use generator pattern |
| `await container.read(provider.future)` in tests | `await waitForFirstValue(container, provider)` | Riverpod 3 disposal race fix |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `shoppingItemChangeTrackerProvider` and `syncEngineProvider` exist at known paths from Phase 37 wiring | Use-case provider wiring | Need to verify exact provider names before adding `repository_providers.dart` entries |
| A2 | `CategoryFilterSheet` can be adapted with an `onApply` callback without breaking existing test goldens | Pitfall 1 / Don't Hand-Roll | If the existing tests assert exact `CategoryFilterSheet` signature, an optional param addition is backwards-compatible |
| A3 | `SegmentedButton` (Material 3) is available in the Flutter version this project uses | Pattern 7 | Material 3 `SegmentedButton` is stable in Flutter 3.10+; project already uses Material 3 `AppBar`, `FilledButton`, `Dialog` |

---

## Open Questions (RESOLVED)

1. **`ShoppingItemChangeTracker` and `SyncEngine` provider names from Phase 37**
   - What we know: Phase 37 wired `ShoppingItemChangeTracker` + extended `SyncOrchestrator`; providers live in `lib/features/family_sync/presentation/providers/state_sync.dart`
   - What's unclear: Exact Riverpod provider names (do they follow the `@riverpod` suffix-strip rule?)
   - **RESOLVED:** PATTERNS.md confirmed the names from source — `shoppingItemChangeTrackerProvider` (state_sync.dart:27) and `syncEngineProvider` (state_sync.dart:55). Executor still reads `state_sync.dart` before wiring use-case providers (Plan 38-02 read_first).

2. **categoryIds addition to ShoppingListFilter — Wave ordering**
   - What we know: The field is missing and needed for the filter bar
   - What's unclear: Should this be Wave 0 (before any filter bar code) or Wave 1?
   - **RESOLVED:** Wave 0 (Plan 38-01, Task 1) — add `categoryIds: Set<String>` to `ShoppingListFilter` + run build_runner before any other work, so all Wave 1+ code can assume the field exists.

3. **`homeTabTodo` ARB key rename vs new key**
   - What we know: SC1 requires zero "Todo" strings in rendered UI; Phase 39 is the full ARB pass (NAV-03)
   - What's unclear: Whether to rename `homeTabTodo` to `homeTabShopping` in Phase 38 (changing the ARB key name) or just update its value
   - **RESOLVED:** Update the VALUE in all 3 ARB files (Plan 38-03); keep key name `homeTabTodo` for now. Phase 39 renames the key. SC1 checks rendered string content, not key names.

---

## Environment Availability

Step 2.6: SKIPPED (no external dependencies — Flutter project, Material 3 only, no new packages).

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | flutter_test (built-in) |
| Config file | none (uses `flutter test`) |
| Quick run command | `flutter test test/widget/features/shopping_list/ -x slow` |
| Full suite command | `flutter test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| NAV-01 | FAB routes to add-shopping-item at index 3; transaction FAB at other indices | widget | `flutter test test/widget/features/shopping_list/presentation/screens/main_shell_screen_fab_test.dart` | ❌ Wave 0 |
| NAV-02 | 4th tab label = "買い物リスト"; icon = shopping_bag_outlined; no "Todo" strings | widget | `flutter test test/widget/features/shopping_list/presentation/widgets/home_bottom_nav_bar_shopping_test.dart` | ❌ Wave 0 |
| FILT-02 | Filter resets on segment switch; shoppingFilterProvider is keepAlive | unit (ProviderContainer) | `flutter test test/unit/features/shopping_list/providers/state_shopping_filter_test.dart` | ❌ Wave 0 |
| DONE-01 | Tap tile toggles completed; animated strikethrough applied | widget | `flutter test test/widget/features/shopping_list/presentation/widgets/shopping_item_tile_test.dart` | ❌ Wave 0 |
| MGMT-01 | Swipe-to-delete calls DeleteShoppingItemUseCase | widget | `flutter test test/widget/features/shopping_list/presentation/widgets/shopping_item_tile_swipe_test.dart` | ❌ Wave 0 |
| MGMT-03 | Swipe disabled in batch mode | widget | `flutter test test/widget/features/shopping_list/presentation/widgets/shopping_item_tile_test.dart` | ❌ Wave 0 |
| SHOP-02 | Tile renders name, category emoji, qty, price | widget (golden) | Phase 39 | ❌ Wave 0 |
| SHOP-04 | Empty state 3 variants render | widget | `flutter test test/widget/features/shopping_list/presentation/widgets/shopping_empty_state_test.dart` | ❌ Wave 0 |
| SYNC-04 | Attribution chip on public tiles, absent on private | widget | included in `shopping_item_tile_test.dart` | ❌ Wave 0 |
| D38-03 | batchSelectMode hides nav bar + FAB in MainShellScreen | widget | `flutter test test/widget/features/home/presentation/screens/main_shell_screen_test.dart` (EXTEND) | extend existing |
| ITEM-01 | Form validates name required | widget | `flutter test test/widget/features/shopping_list/presentation/screens/shopping_item_form_screen_test.dart` | ❌ Wave 0 |

### Note: on-device / manual-only items

- **Gesture conflicts (drag handle vs swipe vs long-press):** Cannot be asserted in `flutter_test` widget tests because `SliverReorderableList` drag gesture simulation is limited. Mark as manual UAT.
- **Screen-reader a11y labels** on edit chevron and drag handle: Code-grep verifiable (check `Semantics(label:...)` exists); on-device VoiceOver/TalkBack confirmation is UAT.

### Sampling Rate
- **Per task commit:** `flutter test test/widget/features/shopping_list/ test/unit/features/shopping_list/`
- **Per wave merge:** `flutter test` (full suite)
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `test/widget/features/shopping_list/` — directory + all test files listed above
- [ ] Shared test helpers: `test/widget/features/shopping_list/helpers/` — mock use cases (Mocktail stubs for Create/Update/Delete/Toggle/Reorder/Clear)
- [ ] Provider overrides for `shoppingItemRepositoryProvider`, `batchSelectModeProvider`, `listTypeProvider`, `shoppingFilterProvider` in test helpers
- [ ] `ShoppingListFilter.categoryIds` field addition + build_runner (blocks all filter tests)

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V5 Input Validation | yes (form name field) | Form `validator:` callback — name must not be empty (enforced in `CreateShoppingItemUseCase` too, but UI validates first) |
| V5 Input Validation | yes (quantity, estimated price) | Integer-only TextField; parse with `int.tryParse` + null-check |
| V4 Access Control | yes (privacy gate) | Phase 37 use-case boundary + Phase 38 UI must not offer listType change on edit (D6/SYNC-03) |
| V6 Cryptography | note field encryption | Handled at repository boundary (Phase 36/37); form passes plaintext — correct |
| V2 Authentication | no | Not in scope |
| V3 Session Management | no | Not in scope |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| listType change via edit form | Tampering | `listType` field not rendered in edit form (D6 immutable); `UpdateShoppingItemUseCase` rejects listType change at use-case layer with error result |
| Attribution chip spoofing (display malicious name) | Spoofing | `memberDisplayName` comes from shadow book + group member data (synced from family member's own device); not user-editable text input in this phase |
| XSS via item name in web context | — | N/A (Flutter native app, no DOM) |

---

## Sources

### Primary (HIGH confidence)
- Codebase direct reads — `main_shell_screen.dart`, `list_transaction_tile.dart`, `list_screen.dart`, `state_list_filter.dart`, `list_sort_filter_bar.dart`, `list_category_filter_sheet.dart`, `list_empty_state.dart`, `home_bottom_nav_bar.dart`, `soft_confirm_dialog.dart`, `feedback_toast.dart`, `ledger_type_selector.dart`, `category_selection_screen.dart`, `state_home.dart` — all verbatim signatures extracted
- Phase 37 use cases: `create_shopping_item_use_case.dart`, `toggle_item_completed_use_case.dart`, `delete_shopping_item_use_case.dart`, `update_shopping_item_use_case.dart`, `reorder_shopping_items_use_case.dart`, `clear_completed_items_use_case.dart` — exact signatures confirmed
- Phase 36 models: `shopping_item.dart`, `shopping_list_filter.dart`, `shopping_item_params.dart`, `shopping_item_repository.dart` — all field names confirmed
- Phase 36 DAO: `shopping_item_dao.dart` — `watchByListType` SQL query confirmed
- `repository_providers.dart` (shopping) — existing provider structure confirmed
- `test/helpers/test_provider_scope.dart` — `waitForFirstValue` helper confirmed
- CLAUDE.md Riverpod 3 conventions table — verified against `state_list_filter.dart` and `state_home.dart` examples

### Secondary (MEDIUM confidence)
- `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md` §Phase 38 — 5 success criteria verified against codebase
- `.planning/phases/36-CONTEXT.md`, `37-CONTEXT.md` — upstream decisions referenced and cross-checked against actual shipped code
- `38-CONTEXT.md`, `38-UI-SPEC.md` — design contract and locked decisions

### Tertiary (LOW confidence — none)
No claims in this research rely solely on web search or unverified training knowledge.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — zero new packages; all libraries already present and verified in `pubspec.yaml`
- Architecture: HIGH — all patterns extracted directly from codebase; use-case signatures confirmed from Phase 37 source
- Pitfalls: HIGH — landmines 1 (ShoppingListFilter missing categoryIds) and 2 (SliverReorderableList + Dismissible) directly confirmed from source reads; pitfall 7 (two ARB keys) confirmed from `app_ja.arb`

**Research date:** 2026-06-08
**Valid until:** 2026-07-08 (stable, no fast-moving dependencies)
