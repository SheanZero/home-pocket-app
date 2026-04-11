# Category Selection Reorder Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let users drag-reorder L1 and L2 categories directly on the Category Selection screen; persist the new order by overwriting `Category.sortOrder` in a single transaction. Seed `sortOrder` only initializes on first install — once the user saves, their order is the only truth.

**Architecture:** Pure reuse of the existing `sortOrder` column. Add one DAO helper, one repository method, one Riverpod state notifier, one reorder-row widget, and refit `CategorySelectionScreen` with a `ReorderableListView` edit mode. Zero schema migration, zero new tables, zero new enums.

**Tech Stack:** Flutter · Dart · Drift (SQLCipher) · Riverpod (`@riverpod` codegen) · Freezed · flutter_test / flutter_localizations · Material 3 `ReorderableListView`.

**Spec:** `docs/superpowers/specs/2026-04-11-category-selection-sort-prd.md` (v2 scope)

**Design:** `docs/superpowers/specs/2026-04-11-category-selection-sort.pen` (4 Pencil frames — read state · edit L1 · edit L2 expanded · discard-unsaved dialog)

---

## File Structure

| File | Role | Action |
|------|------|--------|
| `lib/data/daos/category_dao.dart` | Add dedicated `updateSortOrder(id, int)` single-row helper | Modify |
| `lib/features/accounting/domain/repositories/category_repository.dart` | Add `updateSortOrders(Map<String,int>)` interface method | Modify |
| `lib/data/repositories/category_repository_impl.dart` | Implement `updateSortOrders` wrapping dao calls in one Drift transaction | Modify |
| `lib/features/accounting/domain/models/category_reorder_state.dart` | Freezed state: `mode` enum (`idle`/`editing`) + `l1` + `l2ByParent` + `isDirty` — single abstract class to match existing `Category` pattern | **Create** |
| `lib/features/accounting/presentation/providers/category_reorder_notifier.dart` | `@riverpod` class notifier: enter / reorderL1 / reorderL2 / save / cancel | **Create** |
| `lib/features/accounting/presentation/widgets/category_reorder_row.dart` | Drag-handle + icon + label row used in edit mode (L1 and L2 variants) | **Create** |
| `lib/features/accounting/presentation/screens/category_selection_screen.dart` | Add `Icons.reorder` AppBar button, edit-mode branch (`ReorderableListView`), save/cancel/discard flow, refresh after save | Modify |
| `lib/l10n/app_ja.arb` + `app_zh.arb` + `app_en.arb` | **+7 i18n keys** (editCategoryOrder · dragToReorder · orderUpdated · orderSaveFailed · discardUnsavedChanges · keepEditing · discard). PRD §7.6 lists 6 keys; `orderSaveFailed` is added here to cover PRD FR-6 red-SnackBar requirement that the spec key table missed. | Modify (all 3) |
| `test/unit/data/daos/category_dao_sort_order_test.dart` | `updateSortOrder` DAO test | **Create** |
| `test/unit/data/repositories/category_repository_sort_order_test.dart` | `updateSortOrders` repo test (transactional batch) | **Create** |
| `test/unit/features/accounting/presentation/providers/category_reorder_notifier_test.dart` | Notifier enter/reorder/save/cancel tests | **Create** |
| `test/widget/features/accounting/presentation/widgets/category_reorder_row_test.dart` | Reorder row widget test | **Create** |
| `test/widget/features/accounting/presentation/screens/category_selection_screen_test.dart` | Extend existing with edit-mode / drag / save / discard tests + update `FakeCategoryRepository` | Modify |
| `docs/worklog/2026-04-11_HHMM_category_reorder.md` | Worklog per project rule | **Create** at the end |

### What this plan does NOT touch

- `lib/data/tables/categories_table.dart` — no schema change
- `lib/data/app_database.dart` — no `schemaVersion` bump
- `lib/features/settings/**` — no `SettingsRepository` or `AppSettings` changes
- `lib/shared/constants/default_categories.dart` — seed is already the initial source of `sortOrder`; untouched
- **v14 migration tests** (PRD AC-11) — the v13 → v14 categories migration itself is authored by the parallel `feature/categories-v2-upgrade` work (see `docs/plans/2026-04-10-categories-upgrade.md`). This reorder plan must **not break** that migration, but does not add migration tests of its own. Verify by running `flutter test` after each phase — any pre-existing migration test suite must stay green.

---

## Pre-flight

- [ ] **Step 0.1: Verify you're on the right branch**

```bash
cd /Users/xinz/Development/home-pocket-app
git status
git branch --show-current
```

Expected: on `feature/categories-v2-upgrade` (or a child branch cut from it). If you're on `main`, stop and create a branch first.

- [ ] **Step 0.2: Baseline — analyzer and tests must be green before touching anything**

```bash
flutter analyze
flutter test
```

Expected: `No issues found!` + all tests pass. If either fails, fix the baseline first — don't start building on a red tree.

- [ ] **Step 0.3: Read the spec once**

```bash
cat docs/superpowers/specs/2026-04-11-category-selection-sort-prd.md
```

Pay special attention to: §2.2 Non-Goals (no mode toggle, no reset), §4 FR-1..FR-6, §6 ASCII mockups, §9 AC list.

---

## Phase 1 — Data Layer: DAO helper

### Task 1.1: Add `updateSortOrder(id, int)` DAO helper

**Files:**
- Create: `test/unit/data/daos/category_dao_sort_order_test.dart`
- Modify: `lib/data/daos/category_dao.dart`

**Why a new helper?** `CategoryDao.updateCategory(...)` at `lib/data/daos/category_dao.dart:76-97` already accepts `sortOrder: int?` but requires many other optional fields. A single-purpose helper keeps the reorder hot-path minimal (one `UPDATE ... SET sort_order = ?, updated_at = ? WHERE id = ?`), and makes the batch-transaction call site readable.

- [ ] **Step 1: Write the failing DAO test**

Create `test/unit/data/daos/category_dao_sort_order_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/category_dao.dart';

void main() {
  late AppDatabase db;
  late CategoryDao dao;

  setUp(() {
    db = AppDatabase.forTesting();
    dao = CategoryDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('CategoryDao.updateSortOrder', () {
    test('updates only sortOrder and updatedAt; leaves other fields intact', () async {
      final now = DateTime(2026, 4, 11, 9, 0);
      await dao.insertCategory(
        id: 'cat_food',
        name: 'category_food',
        icon: 'restaurant',
        color: '#FF5722',
        level: 1,
        isSystem: true,
        sortOrder: 1,
        createdAt: now,
      );

      await dao.updateSortOrder('cat_food', 42);

      final row = await dao.findById('cat_food');
      expect(row, isNotNull);
      expect(row!.sortOrder, 42);
      expect(row.name, 'category_food'); // untouched
      expect(row.icon, 'restaurant'); // untouched
      expect(row.color, '#FF5722'); // untouched
      expect(row.isSystem, true); // untouched
      expect(row.updatedAt, isNotNull); // stamped
    });

    test('no-op when id does not exist (does not throw)', () async {
      await dao.updateSortOrder('cat_missing', 99);
      final row = await dao.findById('cat_missing');
      expect(row, isNull);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/unit/data/daos/category_dao_sort_order_test.dart
```

Expected: compile error / `method 'updateSortOrder' isn't defined`.

- [ ] **Step 3: Implement the helper**

In `lib/data/daos/category_dao.dart`, add after the existing `updateCategory` method (after line 97):

```dart
  /// Update only the [sortOrder] column for a single row.
  ///
  /// Dedicated hot-path helper for drag-reorder; avoids the many-optional-
  /// field signature of [updateCategory]. Stamps [updatedAt] to now.
  Future<void> updateSortOrder(String id, int sortOrder) async {
    await (_db.update(_db.categories)..where((t) => t.id.equals(id))).write(
      CategoriesCompanion(
        sortOrder: Value(sortOrder),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/unit/data/daos/category_dao_sort_order_test.dart
```

Expected: both tests pass.

- [ ] **Step 5: Run analyzer**

```bash
flutter analyze
```

Expected: `No issues found!`.

- [ ] **Step 6: Commit**

```bash
git add lib/data/daos/category_dao.dart test/unit/data/daos/category_dao_sort_order_test.dart
git commit -m "feat(data): add CategoryDao.updateSortOrder single-row helper"
```

---

## Phase 2 — Data Layer: Repository batch method

### Task 2.1: Add `updateSortOrders(Map)` to the interface

**Files:**
- Modify: `lib/features/accounting/domain/repositories/category_repository.dart`

- [ ] **Step 1: Add the abstract method**

In `lib/features/accounting/domain/repositories/category_repository.dart`, add inside the `abstract class CategoryRepository` body (after the existing `update` method around line 13):

```dart
  /// Batch-update `sortOrder` for many categories in one transaction.
  ///
  /// Keys are category IDs; values are the new sort index within the row's
  /// group (L1 ids share one index space, each parent's L2 ids share their
  /// own). The implementation MUST execute all writes in a single atomic
  /// transaction — partial saves are unacceptable.
  Future<void> updateSortOrders(Map<String, int> idToSortOrder);
```

- [ ] **Step 2: Analyze to confirm the abstract method is the only change**

```bash
flutter analyze
```

Expected: analyzer passes (abstract method, no body required yet).

- [ ] **Step 3: Running the full test suite now will fail**

```bash
flutter test 2>&1 | tail -40
```

Expected: compile errors in `CategoryRepositoryImpl`, `FakeCategoryRepository` (widget test), and any other `implements CategoryRepository` class. **Do NOT try to fix here** — the next task fixes `CategoryRepositoryImpl`, and Phase 5 fixes the test fakes.

- [ ] **Step 4: Don't commit yet** — go to Task 2.2, commit at the end of Phase 2 once the tree compiles.

### Task 2.2: Implement `updateSortOrders` with a Drift transaction

**Files:**
- Create: `test/unit/data/repositories/category_repository_sort_order_test.dart`
- Modify: `lib/data/repositories/category_repository_impl.dart`

- [ ] **Step 1: Write the failing repo test**

Create `test/unit/data/repositories/category_repository_sort_order_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/category_dao.dart';
import 'package:home_pocket/data/repositories/category_repository_impl.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';

void main() {
  late AppDatabase db;
  late CategoryRepositoryImpl repo;

  setUp(() {
    db = AppDatabase.forTesting();
    repo = CategoryRepositoryImpl(dao: CategoryDao(db));
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seed() async {
    final now = DateTime(2026, 4, 11);
    await repo.insertBatch([
      Category(id: 'l1_a', name: 'A', icon: 'a', color: '#000',
          level: 1, isSystem: true, sortOrder: 10, createdAt: now),
      Category(id: 'l1_b', name: 'B', icon: 'b', color: '#000',
          level: 1, isSystem: true, sortOrder: 20, createdAt: now),
      Category(id: 'l1_c', name: 'C', icon: 'c', color: '#000',
          level: 1, isSystem: true, sortOrder: 30, createdAt: now),
      Category(id: 'l2_a1', name: 'A1', icon: 'a', color: '#000',
          parentId: 'l1_a', level: 2, sortOrder: 1, createdAt: now),
      Category(id: 'l2_a2', name: 'A2', icon: 'a', color: '#000',
          parentId: 'l1_a', level: 2, sortOrder: 2, createdAt: now),
    ]);
  }

  group('CategoryRepository.updateSortOrders', () {
    test('atomically rewrites sortOrder for the given ids', () async {
      await seed();

      // Reverse L1 order and swap L2 A1/A2
      await repo.updateSortOrders({
        'l1_c': 0,
        'l1_b': 1,
        'l1_a': 2,
        'l2_a2': 0,
        'l2_a1': 1,
      });

      final all = await repo.findActive();
      final l1 = all.where((c) => c.level == 1).toList();
      expect(l1.map((c) => c.id), ['l1_c', 'l1_b', 'l1_a']);

      final l2 = all.where((c) => c.parentId == 'l1_a').toList();
      expect(l2.map((c) => c.id), ['l2_a2', 'l2_a1']);
    });

    test('does not touch ids absent from the map', () async {
      await seed();
      await repo.updateSortOrders({'l1_a': 99});

      final b = await repo.findById('l1_b');
      expect(b!.sortOrder, 20); // unchanged
    });

    test('empty map is a no-op', () async {
      await seed();
      await repo.updateSortOrders({});
      final a = await repo.findById('l1_a');
      expect(a!.sortOrder, 10);
    });
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
flutter test test/unit/data/repositories/category_repository_sort_order_test.dart
```

Expected: compile error (`updateSortOrders` not yet implemented).

- [ ] **Step 3: Add the batch method to `CategoryDao` (DAO-side transaction)**

**Decision:** The transaction lives in the DAO, not the repository. Rationale: `CategoryDao._db` is private; exposing it to the repo to let it reach `_db.transaction(...)` breaks encapsulation. Other daos in this repo keep `_db` private, so we follow that convention.

In `lib/data/daos/category_dao.dart`, add after the `updateSortOrder` method from Task 1.1:

```dart
  /// Batch-update `sortOrder` for many categories in one atomic transaction.
  ///
  /// Called by [CategoryRepository.updateSortOrders] when the user saves
  /// a drag-reorder. Empty map is a no-op.
  Future<void> updateSortOrders(Map<String, int> idToSortOrder) async {
    if (idToSortOrder.isEmpty) return;
    await _db.transaction(() async {
      for (final entry in idToSortOrder.entries) {
        await updateSortOrder(entry.key, entry.value);
      }
    });
  }
```

- [ ] **Step 4: Implement `CategoryRepositoryImpl.updateSortOrders` as a thin delegate**

In `lib/data/repositories/category_repository_impl.dart`, add inside the class (after the existing `update` method around line 47):

```dart
  @override
  Future<void> updateSortOrders(Map<String, int> idToSortOrder) =>
      _dao.updateSortOrders(idToSortOrder);
```

- [ ] **Step 5: Run the repo test**

```bash
flutter test test/unit/data/repositories/category_repository_sort_order_test.dart
```

Expected: all 3 tests pass.

- [ ] **Step 6: Run the full test suite**

```bash
flutter test 2>&1 | tail -30
```

Expected: the **widget test** `test/widget/features/accounting/presentation/screens/category_selection_screen_test.dart` still fails to compile because `FakeCategoryRepository` doesn't implement `updateSortOrders`. We'll fix that in Phase 5. All **unit** tests should pass.

- [ ] **Step 7: Update `FakeCategoryRepository` now to unblock the green tree**

In `test/widget/features/accounting/presentation/screens/category_selection_screen_test.dart`, add the new override inside the `FakeCategoryRepository` class (after `deleteAll` near line 55, before the closing brace):

```dart
  Map<String, int>? lastSortOrders;

  @override
  Future<void> updateSortOrders(Map<String, int> idToSortOrder) async {
    lastSortOrders = Map.of(idToSortOrder);
  }
```

- [ ] **Step 8: Re-run full tests**

```bash
flutter test 2>&1 | tail -30
```

Expected: all tests pass.

- [ ] **Step 9: Analyze**

```bash
flutter analyze
```

Expected: `No issues found!`.

- [ ] **Step 10: Commit Phase 2 in two slices**

Two slices make the review easier (one DAO-layer commit, one repo+fake commit):

```bash
# Slice 1: DAO batch method (already green because Task 1.1's helper backs it)
git add lib/data/daos/category_dao.dart
git commit -m "feat(data): add CategoryDao.updateSortOrders transactional batch"

# Slice 2: repository interface + impl delegate + widget-test fake update
git add lib/features/accounting/domain/repositories/category_repository.dart \
        lib/data/repositories/category_repository_impl.dart \
        test/unit/data/repositories/category_repository_sort_order_test.dart \
        test/widget/features/accounting/presentation/screens/category_selection_screen_test.dart
git commit -m "feat(data): add CategoryRepository.updateSortOrders delegate"
```

---

## Phase 3 — i18n keys

### Task 3.1: Add 6 new ARB keys to all three locales in lock-step

**Files:**
- Modify: `lib/l10n/app_ja.arb`
- Modify: `lib/l10n/app_zh.arb`
- Modify: `lib/l10n/app_en.arb`

**Keys to add (all three ARB files must be updated together):**

| Key | ja | zh | en |
|-----|----|----|----|
| `editCategoryOrder` | 順序を編集 | 编辑分类顺序 | Edit category order |
| `dragToReorder` | ドラッグして並べ替え | 拖拽重排 | Drag to reorder |
| `orderUpdated` | 順序を更新しました | 顺序已更新 | Order updated |
| `orderSaveFailed` | 保存に失敗しました。再試行してください | 保存失败，请重试 | Failed to save order. Please retry |
| `discardUnsavedChanges` | 未保存の変更を破棄しますか？ | 放弃未保存的修改？ | Discard unsaved changes? |
| `keepEditing` | 編集を続ける | 继续编辑 | Keep editing |
| `discard` | 破棄 | 放弃 | Discard |

(7 keys — `discardUnsavedChanges` dialog needs both `keepEditing` and `discard` action labels.)

- [ ] **Step 1: Pick an insertion point**

Look for the existing block of category-related keys in each ARB file (search for `"selectCategory"` or `"addCategory"` — they're all grouped together). Insert the new keys immediately after that block in each file.

```bash
```

Use Grep to locate the insertion point in each file:

```
pattern: "addCategory"
type: arb
path: lib/l10n
output_mode: content
```

- [ ] **Step 2: Edit `lib/l10n/app_en.arb`**

Insert after the `addCategory` group (around line 538-540). Remember: `app_en.arb` also needs the `@key` description metadata. Example entry:

```json
  "editCategoryOrder": "Edit category order",
  "@editCategoryOrder": { "description": "AppBar title during category reorder edit mode" },
  "dragToReorder": "Drag to reorder",
  "@dragToReorder": { "description": "Hint banner shown in category reorder edit mode" },
  "orderUpdated": "Order updated",
  "@orderUpdated": { "description": "SnackBar shown after successfully saving category reorder" },
  "orderSaveFailed": "Failed to save order. Please retry",
  "@orderSaveFailed": { "description": "SnackBar shown when saving category reorder fails" },
  "discardUnsavedChanges": "Discard unsaved changes?",
  "@discardUnsavedChanges": { "description": "Dialog title when cancelling reorder with unsaved changes" },
  "keepEditing": "Keep editing",
  "@keepEditing": { "description": "Dialog cancel button: keep editing" },
  "discard": "Discard",
  "@discard": { "description": "Dialog confirm button: discard unsaved changes" },
```

- [ ] **Step 3: Edit `lib/l10n/app_ja.arb` and `lib/l10n/app_zh.arb`**

Insert the same 7 keys (no `@key` metadata in ja/zh files — follow the existing house convention). Use the Japanese and Chinese values from the table above.

**Critical:** All three files must have the same key set. If any is missing, `flutter gen-l10n` will warn and `flutter analyze` will flag missing strings in the generated `S` class at the call site later.

- [ ] **Step 4: Regenerate the `S` class**

```bash
flutter gen-l10n
```

Expected: no warnings. If warnings about untranslated messages appear, go back and make sure all three files are in sync.

- [ ] **Step 5: Verify the generated `S` class exposes the new keys**

```bash
```

Use Grep:

```
pattern: "editCategoryOrder|dragToReorder|orderUpdated|orderSaveFailed|discardUnsavedChanges|keepEditing"
path: lib/generated
output_mode: files_with_matches
```

Expected: each key appears in the generated `app_localizations.dart` + `_en`/`_ja`/`_zh` variants.

- [ ] **Step 6: Analyze**

```bash
flutter analyze
```

Expected: `No issues found!`.

- [ ] **Step 7: Commit**

```bash
git add lib/l10n/app_ja.arb lib/l10n/app_zh.arb lib/l10n/app_en.arb lib/generated/
git commit -m "feat(i18n): add category reorder strings (ja/zh/en)"
```

---

## Phase 4 — Domain + Presentation state: reorder notifier

### Task 4.1: Create the reorder state freezed model

**Files:**
- Create: `lib/features/accounting/domain/models/category_reorder_state.dart`

- [ ] **Step 1: Create the file**

Matches the existing `abstract class Category with _$Category` pattern (Freezed 3.0 in this repo; the codebase has no existing sealed-union freezed types, so we stay conservative with a single-class shape + enum):

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

import 'category.dart';

part 'category_reorder_state.freezed.dart';

/// Top-level mode of the category reorder editor.
enum CategoryReorderMode { idle, editing }

/// State of the category reorder editor.
///
/// - [CategoryReorderMode.idle] — the Category Selection screen is in its
///   normal read state; [l1]/[l2ByParent]/[isDirty] are ignored.
/// - [CategoryReorderMode.editing] — the user tapped the reorder button and
///   is actively dragging. [l1] and [l2ByParent] hold the working copies
///   (mutated in-place by the notifier). [isDirty] is true once any drag
///   has moved an item.
@freezed
abstract class CategoryReorderState with _$CategoryReorderState {
  const factory CategoryReorderState({
    @Default(CategoryReorderMode.idle) CategoryReorderMode mode,
    @Default([]) List<Category> l1,
    @Default({}) Map<String, List<Category>> l2ByParent,
    @Default(false) bool isDirty,
  }) = _CategoryReorderState;

  const CategoryReorderState._();

  /// Convenience for callers that want the old `is Editing` idiom.
  bool get isEditing => mode == CategoryReorderMode.editing;
}
```

- [ ] **Step 2: Run build_runner**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: generates `category_reorder_state.freezed.dart`.

- [ ] **Step 3: Analyze the new file**

```bash
flutter analyze
```

Expected: `No issues found!`.

- [ ] **Step 4: Don't commit yet** — commit at the end of Phase 4 together with the notifier.

### Task 4.2: Write failing tests for the reorder notifier

**Files:**
- Create: `test/unit/features/accounting/presentation/providers/category_reorder_notifier_test.dart`

- [ ] **Step 1: Write the test file**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/category_reorder_state.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/accounting/presentation/providers/category_reorder_notifier.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart';

class _FakeRepo implements CategoryRepository {
  Map<String, int>? lastSaved;
  bool shouldThrow = false;

  @override
  Future<void> updateSortOrders(Map<String, int> idToSortOrder) async {
    if (shouldThrow) throw Exception('db failure');
    lastSaved = Map.of(idToSortOrder);
  }

  // Unused in these tests — provide minimal stubs
  @override
  Future<void> deleteAll() async {}
  @override
  Future<List<Category>> findActive() async => const [];
  @override
  Future<List<Category>> findAll() async => const [];
  @override
  Future<List<Category>> findByLevel(int level) async => const [];
  @override
  Future<List<Category>> findByParent(String parentId) async => const [];
  @override
  Future<Category?> findById(String id) async => null;
  @override
  Future<void> insert(Category category) async {}
  @override
  Future<void> insertBatch(List<Category> categories) async {}
  @override
  Future<void> update({
    required String id,
    String? name,
    String? icon,
    String? color,
    bool? isArchived,
    int? sortOrder,
  }) async {}
}

Category _cat(String id, {String? parent, int level = 1, int sortOrder = 0}) {
  return Category(
    id: id,
    name: id,
    icon: 'folder',
    color: '#888',
    parentId: parent,
    level: level,
    sortOrder: sortOrder,
    createdAt: DateTime(2026, 4, 11),
  );
}

void main() {
  late _FakeRepo repo;
  late ProviderContainer container;

  setUp(() {
    repo = _FakeRepo();
    container = ProviderContainer(overrides: [
      categoryRepositoryProvider.overrideWithValue(repo),
    ]);
  });

  tearDown(() => container.dispose());

  CategoryReorderNotifier notifier() =>
      container.read(categoryReorderNotifierProvider.notifier);

  CategoryReorderState state() =>
      container.read(categoryReorderNotifierProvider);

  group('CategoryReorderNotifier', () {
    test('initial state has mode == idle', () {
      expect(state().mode, CategoryReorderMode.idle);
      expect(state().isEditing, isFalse);
    });

    test('enterEditing switches to editing mode with isDirty=false', () {
      notifier().enterEditing(
        l1: [_cat('a'), _cat('b')],
        l2ByParent: {'a': [_cat('a1', parent: 'a', level: 2)]},
      );
      final s = state();
      expect(s.mode, CategoryReorderMode.editing);
      expect(s.isEditing, isTrue);
      expect(s.l1.map((c) => c.id), ['a', 'b']);
      expect(s.isDirty, isFalse);
    });

    test('reorderL1 moves item and sets isDirty=true', () {
      notifier().enterEditing(
        l1: [_cat('a'), _cat('b'), _cat('c')],
        l2ByParent: const {},
      );
      notifier().reorderL1(0, 3); // move a to end (ReorderableListView semantics)
      final s = state();
      expect(s.l1.map((c) => c.id), ['b', 'c', 'a']);
      expect(s.isDirty, isTrue);
    });

    test('reorderL2 moves child within same parent only', () {
      notifier().enterEditing(
        l1: [_cat('food')],
        l2ByParent: {
          'food': [_cat('x', parent: 'food', level: 2), _cat('y', parent: 'food', level: 2)],
        },
      );
      notifier().reorderL2('food', 0, 2); // x → end
      final s = state();
      expect(s.l2ByParent['food']!.map((c) => c.id), ['y', 'x']);
      expect(s.isDirty, isTrue);
    });

    test('save writes flat index map and returns to idle', () async {
      notifier().enterEditing(
        l1: [_cat('a'), _cat('b')],
        l2ByParent: {
          'a': [_cat('a1', parent: 'a', level: 2), _cat('a2', parent: 'a', level: 2)],
        },
      );
      notifier().reorderL1(1, 0); // b → front
      await notifier().save();

      expect(repo.lastSaved, {
        'b': 0,
        'a': 1,
        'a1': 0,
        'a2': 1,
      });
      expect(state().mode, CategoryReorderMode.idle);
    });

    test('save failure keeps editing state dirty (user can retry)', () async {
      repo.shouldThrow = true;
      notifier().enterEditing(l1: [_cat('a'), _cat('b')], l2ByParent: const {});
      notifier().reorderL1(0, 2);
      expect(state().isDirty, isTrue);

      await expectLater(notifier().save(), throwsA(isA<Exception>()));

      // After the failure, caller still sees editing state with isDirty=true
      // and the in-memory order preserved. This is AC-6's "保存失败时不回退
      // 内存状态" requirement.
      final s = state();
      expect(s.mode, CategoryReorderMode.editing);
      expect(s.isDirty, isTrue);
      expect(s.l1.map((c) => c.id), ['b', 'a']);
    });

    test('cancel returns to idle even when dirty', () {
      notifier().enterEditing(
        l1: [_cat('a'), _cat('b')],
        l2ByParent: const {},
      );
      notifier().reorderL1(0, 2);
      notifier().cancel();
      expect(state().mode, CategoryReorderMode.idle);
    });
  });
}
```

- [ ] **Step 2: Run the test to confirm it fails at compile time**

```bash
flutter test test/unit/features/accounting/presentation/providers/category_reorder_notifier_test.dart
```

Expected: import error for `category_reorder_notifier.dart` — notifier not yet created.

### Task 4.3: Create the reorder notifier

**Files:**
- Create: `lib/features/accounting/presentation/providers/category_reorder_notifier.dart`

- [ ] **Step 1: Write the notifier**

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/models/category.dart';
import '../../domain/models/category_reorder_state.dart';
import 'repository_providers.dart';

part 'category_reorder_notifier.g.dart';

@riverpod
class CategoryReorderNotifier extends _$CategoryReorderNotifier {
  @override
  CategoryReorderState build() => const CategoryReorderState();

  /// Enter edit mode, taking ownership of a mutable copy of the lists.
  void enterEditing({
    required List<Category> l1,
    required Map<String, List<Category>> l2ByParent,
  }) {
    state = CategoryReorderState(
      mode: CategoryReorderMode.editing,
      l1: List.of(l1),
      l2ByParent: {
        for (final entry in l2ByParent.entries)
          entry.key: List.of(entry.value),
      },
      isDirty: false,
    );
  }

  /// Reorder an L1 row (`ReorderableListView` semantics: `newIndex` may equal
  /// `list.length` when dropped at the bottom; adjust by -1 if moving down).
  void reorderL1(int oldIndex, int newIndex) {
    if (!state.isEditing) return;
    final updated = List<Category>.of(state.l1);
    if (newIndex > oldIndex) newIndex -= 1;
    final moved = updated.removeAt(oldIndex);
    updated.insert(newIndex, moved);
    state = state.copyWith(l1: updated, isDirty: true);
  }

  /// Reorder an L2 row within a specific parent only.
  void reorderL2(String parentId, int oldIndex, int newIndex) {
    if (!state.isEditing) return;
    final children = List<Category>.of(state.l2ByParent[parentId] ?? const []);
    if (newIndex > oldIndex) newIndex -= 1;
    final moved = children.removeAt(oldIndex);
    children.insert(newIndex, moved);
    final updatedMap = Map<String, List<Category>>.of(state.l2ByParent);
    updatedMap[parentId] = children;
    state = state.copyWith(l2ByParent: updatedMap, isDirty: true);
  }

  /// Persist the working copy via
  /// [CategoryRepository.updateSortOrders] and return to idle.
  ///
  /// Throws through on DB failure — caller (screen) is responsible for
  /// surfacing the error via SnackBar. On failure, [state] is **left
  /// unchanged** so the user can retry without losing their work.
  Future<void> save() async {
    if (!state.isEditing) return;
    final orders = <String, int>{};
    state.l1.asMap().forEach((i, cat) => orders[cat.id] = i);
    for (final entry in state.l2ByParent.entries) {
      entry.value.asMap().forEach((i, cat) => orders[cat.id] = i);
    }
    final repo = ref.read(categoryRepositoryProvider);
    await repo.updateSortOrders(orders); // throws propagate
    state = const CategoryReorderState();
  }

  /// Discard unsaved changes and return to idle.
  void cancel() {
    state = const CategoryReorderState();
  }
}
```

- [ ] **Step 2: Run build_runner**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: generates `category_reorder_notifier.g.dart`.

- [ ] **Step 3: Run the notifier test**

```bash
flutter test test/unit/features/accounting/presentation/providers/category_reorder_notifier_test.dart
```

Expected: all tests pass.

- [ ] **Step 4: Run the full suite + analyze**

```bash
flutter test
flutter analyze
```

Expected: all green.

- [ ] **Step 5: Commit Phase 4**

```bash
git add lib/features/accounting/domain/models/category_reorder_state.dart \
        lib/features/accounting/domain/models/category_reorder_state.freezed.dart \
        lib/features/accounting/presentation/providers/category_reorder_notifier.dart \
        lib/features/accounting/presentation/providers/category_reorder_notifier.g.dart \
        test/unit/features/accounting/presentation/providers/category_reorder_notifier_test.dart
git commit -m "feat(accounting): add CategoryReorderNotifier for drag-reorder state"
```

---

## Phase 5 — UI: reorder row widget

### Task 5.1: Extract `CategoryReorderRow` widget

**Files:**
- Create: `lib/features/accounting/presentation/widgets/category_reorder_row.dart`
- Create: `test/widget/features/accounting/presentation/widgets/category_reorder_row_test.dart`

**Why a separate widget?** The L1 row in edit mode and the L2 row in the expanded area share the same visual pattern (drag handle + small color icon + label) but differ in size/padding. Keep them in one widget with variant params rather than inlining in the screen file.

- [ ] **Step 1: Write a failing widget test first**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/category_reorder_row.dart';

void main() {
  Widget host(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('CategoryReorderRow', () {
    testWidgets('renders drag handle + label + icon', (tester) async {
      await tester.pumpWidget(host(
        const CategoryReorderRow(
          label: '食費',
          iconData: Icons.restaurant,
          color: Color(0xFFFF5722),
          variant: CategoryReorderRowVariant.l1,
        ),
      ));
      expect(find.text('食費'), findsOneWidget);
      expect(find.byIcon(Icons.drag_indicator), findsOneWidget);
      expect(find.byIcon(Icons.restaurant), findsOneWidget);
    });

    testWidgets('L2 variant uses a smaller padding/icon than L1', (tester) async {
      await tester.pumpWidget(host(Column(children: const [
        CategoryReorderRow(
          label: 'L1',
          iconData: Icons.restaurant,
          color: Color(0xFFFF5722),
          variant: CategoryReorderRowVariant.l1,
        ),
        CategoryReorderRow(
          label: 'L2',
          iconData: Icons.restaurant,
          color: Color(0xFFFF5722),
          variant: CategoryReorderRowVariant.l2,
        ),
      ])));
      // Smoke check — both render without throwing
      expect(find.text('L1'), findsOneWidget);
      expect(find.text('L2'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: Run the test — should fail on import**

```bash
flutter test test/widget/features/accounting/presentation/widgets/category_reorder_row_test.dart
```

- [ ] **Step 3: Implement the widget**

```dart
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Size variant for [CategoryReorderRow].
enum CategoryReorderRowVariant { l1, l2 }

/// A single draggable category row used inside a [ReorderableListView] in
/// edit mode. Pure presentation — no tap handlers, no Riverpod deps.
///
/// Uses the existing [Icons.drag_indicator] affordance on the leading edge
/// and respects dark mode via [AppColorsDark].
class CategoryReorderRow extends StatelessWidget {
  const CategoryReorderRow({
    super.key,
    required this.label,
    required this.iconData,
    required this.color,
    required this.variant,
  });

  final String label;
  final IconData iconData;
  final Color color;
  final CategoryReorderRowVariant variant;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isL1 = variant == CategoryReorderRowVariant.l1;
    final rowHeight = isL1 ? 60.0 : 46.0;
    final iconBoxSize = isL1 ? 32.0 : 0.0;
    final innerIconSize = isL1 ? 18.0 : 0.0;
    final labelSize = isL1 ? 15.0 : 14.0;

    return Container(
      height: rowHeight,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColorsDark.card : AppColors.card,
        borderRadius: BorderRadius.circular(isL1 ? 14 : 10),
        border: Border.all(
          color: isDark ? AppColorsDark.borderDefault : AppColors.borderDefault,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.drag_indicator,
            size: 22,
            color:
                isDark ? AppColorsDark.textSecondary : AppColors.textSecondary,
          ),
          const SizedBox(width: 10),
          if (isL1) ...[
            Container(
              width: iconBoxSize,
              height: iconBoxSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(iconData, size: innerIconSize, color: color),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.titleMedium.copyWith(
                fontSize: labelSize,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? AppColorsDark.textPrimary : AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
```

Note: `AppTextStyles.titleMedium` is a `TextStyle`, and `.copyWith(fontSize: ...)` is the standard Flutter API available on any `TextStyle` — use it directly.

- [ ] **Step 4: Run the widget test**

```bash
flutter test test/widget/features/accounting/presentation/widgets/category_reorder_row_test.dart
```

Expected: both tests pass.

- [ ] **Step 5: Analyze**

```bash
flutter analyze
```

- [ ] **Step 6: Commit**

```bash
git add lib/features/accounting/presentation/widgets/category_reorder_row.dart \
        test/widget/features/accounting/presentation/widgets/category_reorder_row_test.dart
git commit -m "feat(accounting): add CategoryReorderRow presentation widget"
```

---

## Phase 6 — UI: CategorySelectionScreen integration

### Task 6.1: Add `Icons.reorder` AppBar button + enter edit mode

**Files:**
- Modify: `lib/features/accounting/presentation/screens/category_selection_screen.dart`
- Modify: `test/widget/features/accounting/presentation/screens/category_selection_screen_test.dart`

This is the biggest change. We're going to **split** it into incremental sub-tasks so each commit leaves a working, testable state.

- [ ] **Step 1: Write the test — reorder button is visible and tapping it enters edit mode**

Append to the existing `category_selection_screen_test.dart`:

```dart
// NOTE: Add these tests at the bottom of the existing main() or in a new group.
  group('reorder entry', () {
    testWidgets('AppBar shows Icons.reorder button in read mode', (tester) async {
      final repo = FakeCategoryRepository(categories);
      await tester.pumpWidget(createLocalizedWidget(
        const CategorySelectionScreen(),
        overrides: [categoryRepositoryProvider.overrideWithValue(repo)],
      ));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.reorder), findsOneWidget);
    });

    testWidgets('tapping reorder button switches AppBar to edit title', (tester) async {
      final repo = FakeCategoryRepository(categories);
      await tester.pumpWidget(createLocalizedWidget(
        const CategorySelectionScreen(),
        overrides: [categoryRepositoryProvider.overrideWithValue(repo)],
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.reorder));
      await tester.pumpAndSettle();

      // Edit state AppBar title should be "Edit category order" in en locale
      expect(find.text('Edit category order'), findsOneWidget);
      // Save button is present
      expect(find.text('Save'), findsOneWidget);
      // Search bar is hidden
      expect(find.byType(TextField), findsNothing);
    });
  });
```

- [ ] **Step 2: Run — expect to fail (no reorder button yet)**

```bash
flutter test test/widget/features/accounting/presentation/screens/category_selection_screen_test.dart
```

- [ ] **Step 3: Modify `category_selection_screen.dart` — add the reorder button and a watch on the reorder notifier**

At the top of the file, add imports:

```dart
import '../../domain/models/category_reorder_state.dart';
import '../providers/category_reorder_notifier.dart';
```

In `_CategorySelectionScreenState.build`, read the reorder state:

```dart
final reorderState = ref.watch(categoryReorderNotifierProvider);
final isEditing = reorderState.isEditing;
```

Rewrite the `AppBar` block (currently at lines 132-150). The new shape:

```dart
appBar: AppBar(
  backgroundColor: isDark ? AppColorsDark.card : AppColors.card,
  elevation: 0,
  scrolledUnderElevation: 0,
  leading: IconButton(
    icon: Icon(
      Icons.close,
      color: isDark ? AppColorsDark.textPrimary : AppColors.textPrimary,
    ),
    onPressed: () => _onLeadingTap(context, reorderState),
  ),
  title: Text(
    isEditing ? l10n.editCategoryOrder : l10n.selectCategory,
    style: AppTextStyles.headlineMedium.copyWith(
      color: isDark ? AppColorsDark.textPrimary : AppColors.textPrimary,
    ),
  ),
  centerTitle: true,
  actions: isEditing
      ? [
          TextButton(
            onPressed: _onSave,
            child: Text(
              l10n.save, // reuse existing or add in Phase 3
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.accentPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ]
      : [
          IconButton(
            icon: Icon(
              Icons.reorder,
              color: isDark
                  ? AppColorsDark.textPrimary
                  : AppColors.textPrimary,
            ),
            tooltip: l10n.editCategoryOrder,
            onPressed: _onEnterReorderMode,
          ),
          IconButton(
            icon: Icon(
              Icons.add,
              color: isDark
                  ? AppColorsDark.textPrimary
                  : AppColors.textPrimary,
            ),
            onPressed: () {}, // placeholder, existing behavior unchanged
          ),
        ],
),
```

Add the helper methods at the bottom of `_CategorySelectionScreenState`:

```dart
void _onEnterReorderMode() {
  ref.read(categoryReorderNotifierProvider.notifier).enterEditing(
        l1: _l1Categories,
        l2ByParent: _l2ByParent,
      );
  // Clear search state so the edit list isn't filtered
  _searchController.clear();
  setState(() => _searchQuery = '');
}

void _onLeadingTap(BuildContext context, CategoryReorderState reorderState) {
  if (reorderState.isEditing && reorderState.isDirty) {
    _showDiscardDialog();
    return;
  }
  if (reorderState.isEditing) {
    ref.read(categoryReorderNotifierProvider.notifier).cancel();
    return;
  }
  Navigator.pop(context);
}

Future<void> _onSave() async {
  try {
    await ref.read(categoryReorderNotifierProvider.notifier).save();
    await _loadCategories(); // refresh local lists from DB
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(S.of(context).orderUpdated)),
    );
  } catch (_) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(S.of(context).orderSaveFailed),
        backgroundColor: AppColors.destructive,
      ),
    );
  }
}

Future<void> _showDiscardDialog() async {
  final l10n = S.of(context);
  final discard = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.discardUnsavedChanges),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n.keepEditing),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(foregroundColor: AppColors.destructive),
          child: Text(l10n.discard),
        ),
      ],
    ),
  );
  if (discard == true) {
    ref.read(categoryReorderNotifierProvider.notifier).cancel();
  }
}
```

- [ ] **Step 4: Verify `AppColors.accentPrimary` and `AppColors.destructive` exist**

```bash
```

Use Grep:

```
pattern: "accentPrimary|destructive"
path: lib/core/theme/app_colors.dart
output_mode: content
```

If either is missing, substitute with an existing brand token (e.g., `AppColors.primary` or `Color(0xFFDC2626)`). Don't invent new tokens in this plan.

- [ ] **Step 5: Run the test — should PASS for the new reorder-entry tests**

```bash
flutter test test/widget/features/accounting/presentation/screens/category_selection_screen_test.dart
```

Expected: existing tests still pass; new reorder-entry tests pass.

- [ ] **Step 6: Analyze**

```bash
flutter analyze
```

- [ ] **Step 7: Commit this first slice**

```bash
git add lib/features/accounting/presentation/screens/category_selection_screen.dart \
        test/widget/features/accounting/presentation/screens/category_selection_screen_test.dart
git commit -m "feat(accounting): add reorder entry button and edit-mode AppBar"
```

### Task 6.2: Replace the ListView with ReorderableListView in edit mode

**Files:**
- Modify: `lib/features/accounting/presentation/screens/category_selection_screen.dart`
- Modify: `test/widget/features/accounting/presentation/screens/category_selection_screen_test.dart`

- [ ] **Step 1: Extend the test fixture to have at least 2 L1 entries**

At the top of `category_selection_screen_test.dart`, the existing `categories` list (starting around line 58) has one L1 (`food`). Add a second L1 so L1 reorder has something to move:

```dart
    Category(
      id: 'daily',
      name: 'category_daily',
      icon: 'shopping_basket',
      color: '#FF9800',
      level: 1,
      isSystem: true,
      sortOrder: 2,
      createdAt: DateTime(2026, 4, 3),
    ),
```

- [ ] **Step 2: Write the test — drive the notifier via `ProviderContainer`, tap save, verify the persisted map**

Driving actual `tester.drag()` on a `ReorderableListView` row is brittle (requires finding a `ReorderableDragStartListener` and sending long-press+move events in exactly the right order). This test uses the `ProviderContainer` route to poke the notifier directly, which is the pattern Task 6.4 Step 1 uses for the discard dialog. Append to the reorder test group:

```dart
    testWidgets('save after L1 reorder writes the new order to the repo',
        (tester) async {
      final repo = FakeCategoryRepository(categories);
      await tester.pumpWidget(createLocalizedWidget(
        const CategorySelectionScreen(),
        overrides: [categoryRepositoryProvider.overrideWithValue(repo)],
      ));
      await tester.pumpAndSettle();

      // Enter edit mode via the AppBar icon (exercises the real entry path)
      await tester.tap(find.byIcon(Icons.reorder));
      await tester.pumpAndSettle();

      // Drive the notifier directly to move 'food' (index 0) to the end.
      final container = ProviderScope.containerOf(
        tester.element(find.byType(CategorySelectionScreen)),
      );
      container
          .read(categoryReorderNotifierProvider.notifier)
          .reorderL1(0, 2); // ReorderableListView semantics: newIndex past end
      await tester.pumpAndSettle();

      // Tap the localized "Save" label (en locale default in the test helper)
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(repo.lastSortOrders, isNotNull);
      // 'daily' is now first, 'food' second
      expect(repo.lastSortOrders!['daily'], 0);
      expect(repo.lastSortOrders!['food'], 1);
    });
```

Add the imports at the top of the test file if not already present:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_pocket/features/accounting/presentation/providers/category_reorder_notifier.dart';
```

- [ ] **Step 2: Run — expect to fail because no reorderable UI yet**

- [ ] **Step 3: In the screen body, branch on `isEditing`**

In the screen `build` method where the current `ListView.builder` lives (around lines 191-223), replace with:

```dart
Expanded(
  child: isEditing
      ? _buildReorderBody(reorderState, locale, isDark)
      : _buildReadBody(filteredL1, locale, isDark),
),
```

Move the existing `ListView.builder` code into a new method `_buildReadBody(...)` — **copy, don't rewrite**. This keeps the read-mode behavior 100% identical.

Add a new `_buildReorderBody(...)` method:

```dart
Widget _buildReorderBody(
  CategoryReorderState state,
  Locale locale,
  bool isDark,
) {
  assert(state.isEditing); // precondition: caller already checked state.isEditing
  return Column(
    children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        color: isDark ? AppColorsDark.backgroundMuted : AppColors.backgroundMuted,
        child: Row(
          children: [
            Icon(
              Icons.drag_indicator,
              size: 18,
              color: AppColors.accentPrimary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                S.of(context).dragToReorder,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark
                      ? AppColorsDark.textSecondary
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
      Expanded(
        child: ReorderableListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: state.l1.length,
          buildDefaultDragHandles: false,
          onReorder: (oldIdx, newIdx) {
            ref
                .read(categoryReorderNotifierProvider.notifier)
                .reorderL1(oldIdx, newIdx);
          },
          itemBuilder: (context, index) {
            final cat = state.l1[index];
            return Padding(
              key: ValueKey(cat.id),
              padding: const EdgeInsets.only(bottom: 8),
              child: ReorderableDragStartListener(
                index: index,
                child: CategoryReorderRow(
                  label: CategoryService.resolve(cat.name, locale),
                  iconData: resolveCategoryIcon(cat.icon),
                  color: _parseColor(cat.color),
                  variant: CategoryReorderRowVariant.l1,
                ),
              ),
            );
          },
        ),
      ),
    ],
  );
}
```

Add import at the top:

```dart
import '../widgets/category_reorder_row.dart';
```

Note: L2 reorder inside an expanded L1 is **out of scope for Task 6.2** — we're landing L1 reorder first. L2 lands in Task 6.3.

- [ ] **Step 4: Run the full widget test suite**

```bash
flutter test test/widget/features/accounting/presentation/screens/category_selection_screen_test.dart
```

Expected: all existing tests + the new drag/save test pass.

- [ ] **Step 5: Analyze**

```bash
flutter analyze
```

- [ ] **Step 6: Commit**

```bash
git add lib/features/accounting/presentation/screens/category_selection_screen.dart \
        test/widget/features/accounting/presentation/screens/category_selection_screen_test.dart
git commit -m "feat(accounting): add L1 drag reorder to category selection edit mode"
```

### Task 6.3: L2 expanded vertical reorder list

**Files:**
- Modify: `lib/features/accounting/presentation/screens/category_selection_screen.dart`
- Modify: `test/widget/features/accounting/presentation/screens/category_selection_screen_test.dart`

The design (Pencil Screen 04) shows a single L1 expanded, revealing its L2 children as a vertical list of `CategoryReorderRow(variant: l2)`, each draggable *within* that parent only.

- [ ] **Step 1: Write a failing test for L2 expand-in-edit-mode**

```dart
    testWidgets('tapping an L1 in edit mode expands its L2 children', (tester) async {
      // Ensure fixture has an L1 with >=2 L2 children (seed as needed)
      final repo = FakeCategoryRepository(categories);
      await tester.pumpWidget(createLocalizedWidget(
        const CategorySelectionScreen(),
        overrides: [categoryRepositoryProvider.overrideWithValue(repo)],
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.reorder));
      await tester.pumpAndSettle();

      await tester.tap(find.text('食費'));
      await tester.pumpAndSettle();

      // L2 children render (e.g., "コンビニ" from the fixture)
      expect(find.text('コンビニ'), findsOneWidget);
    });
```

- [ ] **Step 2: Run — expect to fail (no expand behavior in edit mode)**

- [ ] **Step 3: Extend `_buildReorderBody`**

Change the outer `ReorderableListView.builder` to interleave the expanded L1's L2 list. Maintain a local `_expandedL1IdInEdit` state (separate from the read-mode `_expandedL1Id`). When an L1 row is tapped, set it; render a nested `ReorderableListView` for its children underneath.

Because a `ReorderableListView` can't contain a nested `ReorderableListView`, split into two separate lists:

- Outer `Column` with `SingleChildScrollView`
- For each L1: render the L1 row; if it matches `_expandedL1IdInEdit`, render below it a secondary `ReorderableListView.builder` (shrinkWrap: true) with its L2 children

Sketch:

Replace the entire Task 6.2 version of `_buildReorderBody` with the shape below (same method signature — takes `CategoryReorderState state` — but now rendering `SliverReorderableList` + nested per-L1 L2 reorder):

```dart
Widget _buildReorderBody(CategoryReorderState state, Locale locale, bool isDark) {
  assert(state.isEditing);
  return Column(
    children: [
      _buildHintBanner(isDark),
      Expanded(
        child: CustomScrollView(
          slivers: [
            SliverReorderableList(
              itemCount: state.l1.length,
              onReorder: (o, n) => ref
                  .read(categoryReorderNotifierProvider.notifier)
                  .reorderL1(o, n),
              itemBuilder: (context, index) {
                final l1 = state.l1[index];
                final expanded = _expandedL1IdInEdit == l1.id;
                final children = state.l2ByParent[l1.id] ?? const [];
                return _L1ReorderTile(
                  key: ValueKey('l1_${l1.id}'),
                  index: index,
                  category: l1,
                  expanded: expanded,
                  children: children,
                  onToggle: () => setState(() =>
                      _expandedL1IdInEdit = expanded ? null : l1.id),
                  onReorderChild: (o, n) => ref
                      .read(categoryReorderNotifierProvider.notifier)
                      .reorderL2(l1.id, o, n),
                  locale: locale,
                  isDark: isDark,
                );
              },
            ),
          ],
        ),
      ),
    ],
  );
}
```

…where `_L1ReorderTile` is a small private StatelessWidget that renders the L1 row (using `ReorderableDragStartListener`) plus — when expanded — a `ReorderableListView.builder(shrinkWrap: true, physics: NeverScrollableScrollPhysics())` for L2 children.

**This is the trickiest part of the whole plan.** `SliverReorderableList` + a nested `ReorderableListView.builder` inside each expanded item is the supported Material pattern (flutter.dev/docs/development/ui/widgets/scrolling#reorderablelist). The nested list **must** use `shrinkWrap: true` and `physics: NeverScrollableScrollPhysics()` so the outer sliver handles scrolling; otherwise scroll conflicts will break drag detection.

**AC-5 is not optional** — L2 reorder must land in this PR. Do not defer to a follow-up.

If the nested pattern fights you during implementation:
- First, check that each item in the outer sliver has a stable `Key` (use `ValueKey(l1.id)`).
- Next, make sure the inner list's item keys are `ValueKey('l2_${l2.id}')` (prefix prevents collision with L1 keys).
- Last, verify that tapping an L1 row in edit mode uses a `ReorderableDelayedDragStartListener` wrapper, not a bare `GestureDetector`, so the tap is distinguished from a drag start.

- [ ] **Step 4: Run the widget tests**

```bash
flutter test test/widget/features/accounting/presentation/screens/category_selection_screen_test.dart
```

- [ ] **Step 5: Analyze + commit**

```bash
flutter analyze
git add lib/features/accounting/presentation/screens/category_selection_screen.dart \
        test/widget/features/accounting/presentation/screens/category_selection_screen_test.dart
git commit -m "feat(accounting): add L2 drag reorder within expanded L1 (edit mode)"
```

### Task 6.3b: Dark mode smoke test (AC-13)

**Files:**
- Modify: `test/widget/features/accounting/presentation/screens/category_selection_screen_test.dart`

PRD §9 AC-13 requires dark mode correctness for all new UI. Add a quick smoke test that pumps edit mode under a dark theme and asserts it renders without throwing.

- [ ] **Step 1: Add the test**

Append to the reorder group:

```dart
    testWidgets('edit mode renders in dark theme (AC-13)', (tester) async {
      final repo = FakeCategoryRepository(categories);
      await tester.pumpWidget(ProviderScope(
        overrides: [categoryRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          theme: ThemeData.dark(),
          locale: const Locale('en'),
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: S.supportedLocales,
          home: const CategorySelectionScreen(),
        ),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.reorder));
      await tester.pumpAndSettle();

      // Smoke: the hint banner, title, and at least one reorder row render
      expect(find.text('Edit category order'), findsOneWidget);
      expect(find.text('Drag to reorder'), findsOneWidget);
      expect(find.byIcon(Icons.drag_indicator), findsWidgets);
      expect(tester.takeException(), isNull);
    });
```

Add imports if missing:

```dart
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:home_pocket/generated/app_localizations.dart';
```

- [ ] **Step 2: Run the test**

```bash
flutter test test/widget/features/accounting/presentation/screens/category_selection_screen_test.dart
```

- [ ] **Step 3: Commit**

```bash
git add test/widget/features/accounting/presentation/screens/category_selection_screen_test.dart
git commit -m "test(accounting): add dark-mode smoke test for reorder edit view"
```

### Task 6.4: Discard unsaved changes dialog end-to-end

**Files:**
- Modify: `test/widget/features/accounting/presentation/screens/category_selection_screen_test.dart`

- [ ] **Step 1: Write the test**

```dart
    testWidgets('cancel after dragging shows discard dialog', (tester) async {
      final repo = FakeCategoryRepository(categories);
      await tester.pumpWidget(createLocalizedWidget(
        const CategorySelectionScreen(),
        overrides: [categoryRepositoryProvider.overrideWithValue(repo)],
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.reorder));
      await tester.pumpAndSettle();

      // Simulate a drag by reading and re-writing the notifier directly
      // (driving actual drag events in tests is brittle). This verifies the
      // dialog-on-dirty path specifically.
      //
      // Alternative: drive the notifier state via a ProviderContainer.

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // No drag happened → close dialog NOT shown, we exited directly.
      // So assert no dialog visible AND back in read mode.
      expect(find.text('Discard unsaved changes?'), findsNothing);
      expect(find.text('Select Category'), findsOneWidget);
    });

    testWidgets('discard dialog offers keep editing and discard', (tester) async {
      final repo = FakeCategoryRepository(categories);
      await tester.pumpWidget(createLocalizedWidget(
        const CategorySelectionScreen(),
        overrides: [categoryRepositoryProvider.overrideWithValue(repo)],
      ));
      await tester.pumpAndSettle();

      // Force the notifier into a dirty editing state via the container:
      final container = ProviderScope.containerOf(tester.element(find.byType(CategorySelectionScreen)));
      final notifier = container.read(categoryReorderNotifierProvider.notifier);
      notifier.enterEditing(l1: categories.where((c) => c.level == 1).toList(), l2ByParent: const {});
      notifier.reorderL1(0, 1); // mark dirty (move first item)
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('Discard unsaved changes?'), findsOneWidget);
      expect(find.text('Keep editing'), findsOneWidget);
      expect(find.text('Discard'), findsOneWidget);

      // Tap discard → back to read mode
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      expect(find.text('Select Category'), findsOneWidget);
    });
```

- [ ] **Step 2: Run — should pass if the earlier `_showDiscardDialog` wiring from Task 6.1 is correct**

```bash
flutter test test/widget/features/accounting/presentation/screens/category_selection_screen_test.dart
```

- [ ] **Step 3: Analyze + commit**

```bash
flutter analyze
git add test/widget/features/accounting/presentation/screens/category_selection_screen_test.dart
git commit -m "test(accounting): add discard dialog widget tests for reorder"
```

---

## Phase 7 — Quality gates + manual verification

### Task 7.1: Run the full test suite + analyzer

- [ ] **Step 1: Full test suite**

```bash
flutter test
```

Expected: all unit + widget tests pass. Coverage report optional:

```bash
flutter test --coverage
```

- [ ] **Step 2: Analyzer**

```bash
flutter analyze
```

Expected: `No issues found!`.

- [ ] **Step 3: Format check**

```bash
dart format --set-exit-if-changed lib test
```

Expected: exit code 0 (no format changes). If files need formatting:

```bash
dart format lib test
```

…and amend the last commit or make a `chore: format` commit.

### Task 7.2: Manual smoke test on a simulator / device

- [ ] **Step 1: Boot the app**

```bash
flutter run
```

- [ ] **Step 2: Walk through every acceptance criterion in the PRD §9**

Use the AC-1…AC-13 checklist. Tick each off in a scratch file or the PR description.

Golden path:

1. Open a category picker (from transaction entry).
2. Tap the `≡` button in the AppBar → enters edit mode.
3. Drag "食費" down two slots → hint banner shows, row follows finger, others shuffle.
4. Tap 食費 once to expand → L2 list renders, drag `カフェ` to top.
5. Tap **Save** → SnackBar `顺序已更新`. Exit edit mode.
6. Close and reopen the picker → new order is persisted.
7. Open again, enter edit mode, drag one L1, tap ✕ → discard dialog appears. Tap "編集を続ける" → stays in edit mode. Tap ✕ again → Discard → exits without saving, order unchanged.
8. Switch locale to zh and en via Settings → re-enter edit mode → verify all strings are translated (no English fallback in ja/zh).
9. Toggle dark mode → re-enter edit mode → all new UI has correct dark colors.

- [ ] **Step 3: If anything fails the manual pass**

Fix and re-run the relevant widget test + manual step. Commit each fix with a targeted message.

### Task 7.3: Write the worklog

**Files:**
- Create: `docs/worklog/2026-04-11_HHMM_category_reorder.md`

- [ ] **Step 1: Use the project's worklog template**

Follow `.claude/rules/worklog.md` — the template has fixed sections: 任务概述 / 完成的工作 / 遇到的问题 / 测试验证 / Git 提交记录 / 后续工作 / 参考资源.

Use the actual commit hashes from `git log --oneline`.

- [ ] **Step 2: Commit**

```bash
git add docs/worklog/2026-04-11_HHMM_category_reorder.md
git commit -m "docs: add worklog for category reorder feature"
```

---

## Phase 8 — Open a PR

- [ ] **Step 1: Push the branch**

```bash
git push -u origin <current-branch>
```

- [ ] **Step 2: Open the PR**

```bash
gh pr create --title "feat: category selection drag-reorder (FEAT-CAT-SORT-001)" --body "$(cat <<'EOF'
## Summary

Implements drag-reorder of L1 and L2 categories on the Category Selection screen per `docs/superpowers/specs/2026-04-11-category-selection-sort-prd.md` (v2 simplified scope).

- AppBar `Icons.reorder` button enters edit mode directly — no sort mode toggle, no reset.
- Seed `sortOrder` only initializes on first install; user drags overwrite the column directly via a new `CategoryRepository.updateSortOrders(Map)` transactional batch.
- Zero schema migration, zero new Drift tables.

## Spec & Design

- PRD: `docs/superpowers/specs/2026-04-11-category-selection-sort-prd.md`
- Pencil: `docs/superpowers/specs/2026-04-11-category-selection-sort.pen`
- Plan: `docs/superpowers/plans/2026-04-11-category-reorder.md`

## Test plan

- [ ] `flutter analyze` — 0 issues
- [ ] `flutter test` — all unit + widget tests pass
- [ ] Manual smoke: drag L1, drag L2 within a parent, save, reopen — order persists
- [ ] Manual smoke: discard dialog on dirty cancel
- [ ] Manual smoke: ja / zh / en — no English fallback
- [ ] Manual smoke: dark mode edit view
EOF
)"
```

---

## Appendix A — Quick reference

### Commit list (expected shape)

```
feat(data): add CategoryDao.updateSortOrder single-row helper
feat(data): add CategoryDao.updateSortOrders transactional batch
feat(data): add CategoryRepository.updateSortOrders delegate
feat(i18n): add category reorder strings (ja/zh/en)
feat(accounting): add CategoryReorderNotifier for drag-reorder state
feat(accounting): add CategoryReorderRow presentation widget
feat(accounting): add reorder entry button and edit-mode AppBar
feat(accounting): add L1 drag reorder to category selection edit mode
feat(accounting): add L2 drag reorder within expanded L1 (edit mode)
test(accounting): add dark-mode smoke test for reorder edit view
test(accounting): add discard dialog widget tests for reorder
docs: add worklog for category reorder feature
```

### Key project conventions

- **TDD**: write the failing test first, watch it fail, write minimal code, watch it pass.
- **Code generation** (`build_runner`) must run after any change to `@freezed` / `@riverpod` / Drift tables.
- **ARB files always updated together** — ja + zh + en — followed by `flutter gen-l10n`.
- **`flutter analyze` must be 0** before every commit. Don't suppress with `// ignore:` — fix the root cause.
- **Widget size on mobile:** touch targets ≥ 44×44 pt. `ReorderableListView` handles this out of the box.
- **Dark mode is first-class** — every new surface uses `AppColors` + `AppColorsDark` together; read the existing `category_selection_screen.dart` for the pattern.
- **Never modify generated files** (`*.g.dart`, `*.freezed.dart`) directly — regenerate them.
- **See CLAUDE.md** at the repo root for the full project rules.

### Out-of-scope reminders (from PRD §2.2)

This plan deliberately does NOT implement:
- Sort mode toggle / radio picker
- Reset-to-default dialog or in-app reset button
- New Drift table `category_sort_overrides`
- New `CategorySortMode` enum
- Alphabetical / frequency / "most used" sort options
- Cross-parent L2 drag

If you're tempted to add any of these "while you're in there," stop — they're v1 scope that was explicitly cut in v2.

---

**Status**: Ready for execution
**Estimated time**: 1–2 focused dev sessions (~6–10 hours including manual QA)
