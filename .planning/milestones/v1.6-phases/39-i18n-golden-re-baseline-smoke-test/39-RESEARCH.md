# Phase 39: i18n + Golden Re-baseline + Smoke Test — Research

**Researched:** 2026-06-08
**Domain:** Flutter i18n (ARB / gen-l10n), golden testing harness, Riverpod 3 StreamProvider smoke testing
**Confidence:** HIGH — all findings from direct codebase inspection of the actual files

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D39-01:** 4th nav tab label shortened to `買い物 / 购物 / Shopping` (avoids wrapping; matches sibling tab length).
- **D39-02:** Rename ARB key `homeTabTodo` → `homeTabShopping` (values = D39-01 text, three locales simultaneously). Delete stale key `todoTab` (no Dart code references it). Update single code call site `home_bottom_nav_bar.dart:45`. Run `flutter gen-l10n`. Verification: `grep -rn 'homeTabTodo\|todoTab\|待办\|Todo' lib/l10n/` must return 0 hits.
- **D39-03:** Component-level goldens only (no full-screen ShoppingListScreen golden). Acceptance: each SC3 state has a corresponding component golden (3 locales × 2 color modes). Absence of a full-screen golden does NOT constitute a gap.
- **D39-04:** Golden set variants — Empty 3 variants: `shoppingEmptyPrivate` / `shoppingEmptyPublicSolo` / `shoppingEmptyPublicFamily`. ShoppingItemTile: active + completed. Tile attribution chip (public-family). Filter bar active state. Batch selection header + bottom batch action bar.
- **D39-05:** No dedicated daily-vs-joy tile pair golden. Active tile uses one ledger, completed tile uses the other — dual borders covered incidentally. No separate "dual-ledger pair" golden required.
- **D39-06:** Smoke test = two assertions: (1) public item written via `ApplySyncOperationsUseCase` → `filteredShoppingItemsProvider` auto-emits, no `ref.invalidate`; (2) private item via same path does NOT appear in any `watchByListType` emission. No tombstone test (Phase 37 already covers it).
- **D39-07:** Phase 38 ARB values accepted as-is. This phase only does the D39-01/02 tab key rename/delete. No other ARB values are changed.

### Claude's Discretion

- New key name confirmed as `homeTabShopping` (consistent with `homeTabHome`, `homeTabList`, `homeTabChart` naming pattern).
- Golden sizing / seed data / provider override strategy: follow existing harness pattern.
- D39-05 ledger assignments: active tile uses `LedgerType.daily`, completed tile uses `LedgerType.joy` (or vice versa — planner discretion).
- Coverage ≥70% tradeoffs: prioritize real tests over lowering the threshold.
- Golden test file location: `test/golden/`, baseline PNGs: `test/golden/goldens/`.

### Deferred Ideas (OUT OF SCOPE)

- Full-screen ShoppingListScreen golden.
- Dedicated daily-vs-joy dual-border golden pair.
- v2 shopping enhancements: SUBTOTAL-01, AUTO-01, GROUP-01, TAGFILT-01, DUP-01, COLLAPSE-01, REORDER-01.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| NAV-03 | ARB key parity holds across ja/zh/en and `flutter gen-l10n` succeeds without warnings. | SC1/SC2 verification commands documented below; rename/delete sequence fully specified; confirmed 586 keys per locale currently (will remain 586 after rename+delete of one pair). |
</phase_requirements>

---

## Summary

Phase 39 is a closeout/verification phase for the v1.6 购物清单 milestone. No new production features are introduced — the work is: one ARB key rename + one stale key deletion, a new batch of golden masters for shopping list widgets, and a presentation-layer smoke test confirming Drift reactive delivery without `ref.invalidate`.

All three domains are well-paved by existing codebase patterns. The ARB rename is mechanical (two keys across three files, one Dart call site). The golden harness is already established in `test/golden/` with 11 existing tests and 73 PNGs — the shopping goldens reuse the exact same scaffold. The smoke test structure already exists in `test/integration/sync/shopping_sync_round_trip_test.dart` (Phase 37 work), but that test covers the application/repository layer; the new smoke test targets the Riverpod presentation layer (`filteredShoppingItemsProvider`, not raw `watchByListType`).

The primary planning risk is the theme mode question for goldens: existing golden files use `ThemeData.light()` / `ThemeData.dark()` as bare theme arguments — NOT `AppTheme.light()` / `AppTheme.dark()`. This means `context.palette` resolves via the `ThemeExtension` mechanism. For dark-mode goldens, the test harness must supply both `theme:` (carrying `AppPalette.light` extension) AND `darkTheme:` (carrying `AppPalette.dark` extension), plus `themeMode: ThemeMode.dark`. Widgets that access `AppPalette.*` static constants directly (as the `list_transaction_tile` golden does for explicit color parameters) must be handed the dark-palette values explicitly. The shopping widgets (`ShoppingItemTile`, `ShoppingFilterBar`, etc.) all use `context.palette` (not static `AppPalette.light.*` constants), so they resolve correctly once the `ThemeExtension` is registered in the `MaterialApp.theme`.

**Primary recommendation:** Follow the `list_empty_state_golden_test.dart` scaffold exactly — it uses `ThemeData.light()` / `ThemeData.dark()` as the MaterialApp themes, which carry the `AppPalette` ThemeExtension via the app's `AppTheme.light` / `AppTheme.dark`. For the shopping goldens, wire in the `AppTheme` extensions (read how the app theme is constructed to confirm ThemeExtension registration), or fall back to the simpler pattern and add the extensions manually.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| ARB key rename + gen-l10n | — (file edit + CLI) | — | Pure text/codegen, no runtime tier |
| Golden masters | Frontend test harness | Presentation (widgets under test) | Component-level; asserts rendered pixels, not logic |
| Smoke test (reactive emit) | Presentation (Riverpod providers) | Data (Drift stream) | Verifies `filteredShoppingItemsProvider` emits reactively — presentation layer wrapping data layer stream |
| ARB parity verification | CI / test gate | — | Automated via jq / flutter gen-l10n |

---

## Standard Stack

### Core (established — no new packages this phase)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| flutter_test (golden) | SDK-bundled | Golden image comparison via `matchesGoldenFile` | Built into Flutter SDK |
| flutter_riverpod | ^3.1.0 | Provider scaffolding for golden + smoke tests | Project standard |
| mocktail | ^1.0.4 | Use case mocks in widget tests | Project standard |
| drift | ^2.25.0 | In-memory DB for smoke test (`AppDatabase.forTesting()`) | Project standard |

No new packages required this phase. [VERIFIED: direct pubspec.yaml inspection]

### Supporting CLI

| Tool | Command | Purpose |
|------|---------|---------|
| flutter gen-l10n | `flutter gen-l10n` | Regenerate `lib/generated/` after ARB edits |
| jq | `jq 'keys|length' lib/l10n/app_*.arb` | Verify key parity across all three locales |
| flutter test --update-goldens | `flutter test test/golden/ --update-goldens` | Regenerate all golden PNGs |

---

## Package Legitimacy Audit

No new external packages installed this phase. All tooling is existing project dependencies.

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

---

## Architecture Patterns

### Golden Harness — Established Pattern [VERIFIED: codebase inspection]

All 11 existing golden tests share one structure. It is defined in:
- `test/golden/list_sort_filter_bar_golden_test.dart` — canonical template with `currentLocaleProvider` override
- `test/golden/list_empty_state_golden_test.dart` — loop-based variant (used when enums drive variants)
- `test/golden/list_transaction_tile_golden_test.dart` — shows explicit `AppPalette.dark.*` parameter injection for tiles that take explicit color params

**Exact reusable scaffold:**

```dart
@Tags(['golden'])
library;

Widget _wrap({required Locale locale, ThemeMode themeMode = ThemeMode.light}) {
  return ProviderScope(
    overrides: [
      // Synchronous override prevents settings-repo async timer pending
      locale_providers.currentLocaleProvider.overrideWith((_) async => locale),
      // Additional widget-specific overrides (e.g., isGroupModeProvider, shadowBooksProvider)
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.supportedLocales,
      theme: ThemeData.light(),    // bare ThemeData — AppPalette extension resolved differently
      darkTheme: ThemeData.dark(),
      themeMode: themeMode,
      home: Scaffold(
        body: SizedBox(
          width: 390,
          height: NN, // fixed per widget
          child: WidgetUnderTest(...),
        ),
      ),
    ),
  );
}

void main() {
  group('WidgetName golden', () {
    testWidgets('locale ja', (tester) async {
      await tester.pumpWidget(_wrap(locale: const Locale('ja')));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(WidgetUnderTest),
        matchesGoldenFile('goldens/widget_name_ja.png'),
      );
    });
    // ... zh, en, ja dark, zh dark, en dark
  });
}
```

**CRITICAL theme question resolved:** The shopping widgets (`ShoppingItemTile`, `ShoppingFilterBar`, `ShoppingEmptyState`, `ShoppingSelectionHeader`, `ShoppingBatchActionBar`) ALL use `context.palette` (via `BuildContext.palette` extension on `ThemeData.extension<AppPalette>()`). With bare `ThemeData.light()` / `ThemeData.dark()`, the `AppPalette` extension is NOT registered, so `context.palette` would throw or return null.

Inspection of the existing golden files confirms they use `ThemeData.light()` — yet the `list_transaction_tile` golden explicitly passes `AppPalette.light.*` static constants as constructor parameters to avoid `context.palette` entirely. The `list_empty_state` golden works because `ListEmptyState` uses `context.palette` — meaning either (a) the test harness registers the ThemeExtension elsewhere, or (b) there is a null-safe fallback.

**Action required by planner:** Before generating goldens, confirm how `context.palette` is wired in the test harness. Two options:
1. **Option A (recommended):** Replace `ThemeData.light()` with the app's real theme — import `AppTheme` from `lib/core/theme/app_theme.dart` and use `theme: AppTheme.light, darkTheme: AppTheme.dark` in the `_wrap` helper. This registers the `AppPalette` extension automatically.
2. **Option B (fallback):** Keep bare `ThemeData.light()` but add the extension manually:
   ```dart
   theme: ThemeData.light().copyWith(extensions: [AppPalette.light]),
   darkTheme: ThemeData.dark().copyWith(extensions: [AppPalette.dark]),
   ```

Option A is simpler and matches what the production app does. The planner must inspect `lib/core/theme/app_theme.dart` to confirm it exists and exports `AppTheme.light` / `AppTheme.dark` before committing to Option A.

### Synchronous Locale Override (anti-async-timer pitfall)

`currentLocaleProvider` is backed by a `SettingsRepository` that reads from secure storage — an async operation with a timer. Overriding it synchronously in goldens prevents `pumpAndSettle` from timing out waiting for that async chain.

```dart
// CORRECT — synchronous override prevents timer pending
locale_providers.currentLocaleProvider.overrideWith((_) async => locale),
```

### Shopping Widget Provider Overrides

Each shopping widget requires specific provider overrides:

**ShoppingEmptyState:** [VERIFIED: shopping_empty_state.dart + shopping_empty_state_test.dart]
```dart
overrides: [
  isGroupModeProvider.overrideWith((_) => true),  // or false for solo/private
]
```

**ShoppingItemTile:** [VERIFIED: shopping_item_tile_test.dart]
```dart
overrides: [
  deleteShoppingItemUseCaseProvider.overrideWithValue(mockDelete),
  toggleItemCompletedUseCaseProvider.overrideWithValue(mockToggle),
  shadowBooksProvider.overrideWith((_) async => [
    ShadowBookInfo(book: _makeBook(bookId), memberDisplayName: 'Alice', memberAvatarEmoji: '🐱'),
  ]),
  batchSelectModeProvider.overrideWith(() => _FixedBatchSelectMode(...)),  // if testing batch mode
]
```

`ShoppingItemTile` requires a `SliverReorderableList` parent (for `ReorderableDragStartListener`). Wrap in:
```dart
CustomScrollView(
  slivers: [
    SliverReorderableList(
      onReorderItem: (_, _) {},
      itemCount: 1,
      itemBuilder: (ctx, i) => ReorderableDelayedDragStartListener(
        key: ValueKey('tile-0'),
        index: 0,
        child: ShoppingItemTile(item: item, index: 0, isActive: true),
      ),
    ),
  ],
)
```

**ShoppingFilterBar:** [VERIFIED: shopping_filter_bar.dart]
Reads `shoppingFilterProvider` + `listTypeProvider`. For "active state" golden, override `shoppingFilterProvider` with a non-default filter.

**ShoppingSelectionHeader:** [VERIFIED: shopping_selection_header.dart]
Reads `batchSelectModeProvider`. Override with a fixed state showing N selected items. Pass `allItemIds: ['id-1', 'id-2']`.

**ShoppingBatchActionBar:** [VERIFIED: shopping_batch_action_bar.dart]
Reads `batchSelectModeProvider`. Override with `selectedIds: {'id-1'}` so the delete button is enabled (not greyed out).

### Widget Inventory for Goldens

| Widget | File | Variants (D39-04) | Approximate Size | Key Provider Overrides |
|--------|------|-------------------|-----------------|----------------------|
| `ShoppingEmptyState` | `shopping_empty_state.dart` | privateEmpty, publicSolo, publicFamily | 390×300 (match `list_empty_state` precedent) | `isGroupModeProvider`, `currentLocaleProvider` |
| `ShoppingItemTile` (active) | `shopping_item_tile.dart` | active, daily ledger | 390×80 | mock use cases, `shadowBooksProvider` empty |
| `ShoppingItemTile` (completed) | `shopping_item_tile.dart` | completed+strikethrough, joy ledger | 390×80 | same, `isActive: false` |
| `ShoppingItemTile` (attribution chip) | `shopping_item_tile.dart` | public + family attribution | 390×80 | `shadowBooksProvider` with one member |
| `ShoppingFilterBar` (active) | `shopping_filter_bar.dart` | at least one chip active (e.g., daily ledger) | 390×44 | `shoppingFilterProvider` overridden |
| `ShoppingSelectionHeader` | `shopping_selection_header.dart` | N items selected | 390×48 | `batchSelectModeProvider` overridden |
| `ShoppingBatchActionBar` | `shopping_batch_action_bar.dart` | N items selected | 390×56 | `batchSelectModeProvider` overridden |

**Total golden count:** 7 component states × 3 locales × 2 color modes = **42 new PNG masters**
(Attribution chip tile can be counted as a separate variant = up to 6 variants × 6 = 36, depending on whether attribution chip tile is counted separately or as part of the active tile.)

### ARB Rename Sequence [VERIFIED: app_ja.arb, app_zh.arb, app_en.arb, home_bottom_nav_bar.dart]

Current state:
- Line 709-712 of each ARB: `"homeTabTodo": "<long text>"` + `"@homeTabTodo": { "description": "Bottom nav todo tab label" }`
- Lines 1624-1627 of each ARB: `"todoTab": "<stale>"` + `"@todoTab": { "description": "Todo tab label in bottom navigation" }`
- Dart call site: `home_bottom_nav_bar.dart:45` — `l10n.homeTabTodo`
- Generated files: `lib/generated/app_localizations_ja.dart`, `..._zh.dart`, `..._en.dart` — these are REGENERATED, do not edit manually

**Rename steps (all three ARB files atomically):**
1. Rename key `homeTabTodo` → `homeTabShopping` with new value: `ja: 買い物`, `zh: 购物`, `en: Shopping`
2. Rename metadata `@homeTabTodo` → `@homeTabShopping`, update description to "Bottom nav shopping tab label"
3. Delete key `todoTab` + its `@todoTab` metadata block (lines 1624-1627)
4. Update `home_bottom_nav_bar.dart:45`: `l10n.homeTabTodo` → `l10n.homeTabShopping`
5. Run `flutter gen-l10n`

**Important:** The `home_bottom_nav_bar_shopping_test.dart` test currently asserts `find.text('買い物リスト')` (the OLD long value). After D39-01, the new value is `買い物`. That test must be updated in the same commit.

**Verification commands (SC1 + SC2):**
```bash
# SC1: key count parity (must all output same integer — expected: 585 after deleting todoTab)
jq 'keys | length' lib/l10n/app_ja.arb
jq 'keys | length' lib/l10n/app_zh.arb
jq 'keys | length' lib/l10n/app_en.arb

# SC2: stale key + value elimination (must return 0 hits)
grep -rn 'homeTabTodo\|todoTab\|待办\|Todo' lib/l10n/

# Also verify no dart references to old key remain
grep -rn 'homeTabTodo\|todoTab' lib/
```

Note: the `grep` for `Todo` in `lib/l10n/` will also match the `@todoTab` description text. After deletion, both the key and the description line must be gone — the grep-0-hits check covers this.

Note: `jq 'keys|length'` counts ALL keys including `@`-metadata keys. After deleting `todoTab` + `@todoTab`, the count drops by 2 per file (from 491×2=982 JSON-level entries to 980). The non-`@` key count drops by 1 (from 586 to 585). All three files must match.

### Smoke Test — Presentation Layer [VERIFIED: repository_providers.dart, shopping_sync_round_trip_test.dart]

The Phase 37 integration test (`shopping_sync_round_trip_test.dart`) tests at the application/repository level: it calls `ApplySyncOperationsUseCase.execute()` directly and asserts `shoppingItemRepo.watchByListType('public')` emits. This does NOT cover the Riverpod presentation layer.

The Phase 39 smoke test covers: `filteredShoppingItemsProvider` (a `StreamProvider<List<ShoppingItem>>`) which wraps `shoppingItemRepository.watchByListType(listType)` — and verifies the Riverpod subscription auto-emits without `ref.invalidate`.

**Smoke test pattern:**

```dart
// Source: CLAUDE.md Riverpod 3 async test pattern + test/helpers/test_provider_scope.dart
test('public item via ApplySync → filteredShoppingItemsProvider emits (SC4)', () async {
  final db = AppDatabase.forTesting();
  // wire all dependencies...
  final container = ProviderContainer.test(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      // override encryption, group repo, etc.
    ],
  );

  // Subscribe to filteredShoppingItemsProvider BEFORE the write
  // Use waitForFirstValue from test/helpers/test_provider_scope.dart
  // to avoid Riverpod 3 "disposed during loading" trap (CLAUDE.md)
  final firstEmission = waitForFirstValue(container, filteredShoppingItemsProvider);

  // Apply sync op via use case (NOT via direct DAO)
  final applyOps = container.read(applySyncOperationsUseCaseProvider);
  await applyOps.execute([{
    'op': 'create',
    'entityType': 'shopping_item',
    'entityId': 'item-smoke',
    'fromDeviceId': 'partner-device',
    'data': { 'id': 'item-smoke', 'listType': 'public', 'name': 'Milk',
              'quantity': 1, 'isCompleted': false,
              'createdAt': '2026-06-08T10:00:00.000Z' },
  }]);

  final result = await firstEmission;
  expect(result.hasValue, isTrue);
  expect(result.value!.any((i) => i.id == 'item-smoke'), isTrue,
    reason: 'filteredShoppingItemsProvider must emit reactively WITHOUT ref.invalidate (SC4)');
  // D39-06 second assertion: private item excluded from public stream
  // (covered by separate test case)
});
```

**Provider name (Riverpod 3 suffix stripping):** `filteredShoppingItems` class → `filteredShoppingItemsProvider` [VERIFIED: repository_providers.g.dart line 427]. `listType` class → `listTypeProvider`, `shoppingFilter` class → `shoppingFilterProvider` [VERIFIED: state_shopping_filter.g.dart implied by `.overrideWith` usage in tests].

**CRITICAL:** Use `ProviderContainer.test()` (not `ProviderContainer() + addTearDown`). Use `waitForFirstValue<T>` from `test/helpers/test_provider_scope.dart` — NOT bare `await container.read(provider.future)` (Riverpod 3 "disposed during loading" trap, CLAUDE.md).

**D39-06 second assertion (privacy re-check):**
```dart
test('private item NEVER appears in filteredShoppingItemsProvider (D39-06)', () async {
  // Set listTypeProvider to 'public', write private item via applyOps,
  // assert filteredShoppingItemsProvider does NOT include the private item.
  // This is different from the Phase 37 test (which checked raw watchByListType).
  // This checks the presentation-layer provider with the full Riverpod graph.
});
```

### Recommended Project Structure

```
test/golden/
├── shopping_empty_state_golden_test.dart   # NEW — 3 variants × 3 locales × 2 modes = 18 PNGs
├── shopping_item_tile_golden_test.dart     # NEW — 3 variants (active/completed/attribution) × 6 = 18 PNGs
├── shopping_filter_bar_golden_test.dart    # NEW — active state × 6 = 6 PNGs
├── shopping_batch_chrome_golden_test.dart  # NEW — header + action bar × 6 = 12 PNGs each (or 2 files)
└── goldens/
    ├── shopping_empty_state_private_empty_{ja,zh,en}.png
    ├── shopping_empty_state_private_empty_dark_{ja,zh,en}.png
    ├── shopping_empty_state_public_solo_{ja,zh,en}.png
    ├── shopping_empty_state_public_solo_dark_{ja,zh,en}.png
    ├── shopping_empty_state_public_family_{ja,zh,en}.png
    ├── shopping_empty_state_public_family_dark_{ja,zh,en}.png
    ├── shopping_item_tile_active_{ja,zh,en}.png
    ├── shopping_item_tile_active_dark_{ja,zh,en}.png
    ├── shopping_item_tile_completed_{ja,zh,en}.png
    ├── shopping_item_tile_completed_dark_{ja,zh,en}.png
    ├── shopping_item_tile_attribution_{ja,zh,en}.png
    ├── shopping_item_tile_attribution_dark_{ja,zh,en}.png
    ├── shopping_filter_bar_active_{ja,zh,en}.png
    ├── shopping_filter_bar_active_dark_{ja,zh,en}.png
    ├── shopping_selection_header_{ja,zh,en}.png
    ├── shopping_selection_header_dark_{ja,zh,en}.png
    ├── shopping_batch_action_bar_{ja,zh,en}.png
    └── shopping_batch_action_bar_dark_{ja,zh,en}.png

test/
└── integration/presentation/
    └── shopping_provider_smoke_test.dart   # NEW — D39-06 Riverpod presentation-layer smoke test
```

### Anti-Patterns to Avoid

- **Bare `await container.read(provider.future)`:** Riverpod 3 disposes auto-dispose providers before the future resolves. Use `waitForFirstValue` from `test/helpers/test_provider_scope.dart`.
- **`ref.invalidate(filteredShoppingItemsProvider)` in production code:** The `ShoppingListScreen` has a comment explicitly forbidding this except in the error-state retry button. The smoke test MUST assert the provider emits WITHOUT invalidation.
- **Editing generated files:** `lib/generated/app_localizations*.dart` are always regenerated by `flutter gen-l10n`. Never hand-edit them.
- **Bare `ThemeData.light()` without AppPalette extension:** Shopping widgets all use `context.palette`. The golden harness MUST register `AppPalette` via either `AppTheme.light` or `.copyWith(extensions: [AppPalette.light])`.
- **Missing `@Tags(['golden'])` library tag:** All existing golden files open with `@Tags(['golden'])\nlibrary;`. New files must follow this convention.
- **Testing filter bar in default-clear state for "active" golden:** The "filter bar active" golden must supply a non-default `shoppingFilterProvider` state (e.g., `ledgerType: LedgerType.daily`). Default state shows no active chips — not useful as a golden variant.
- **`homeTabTodo` key left in test assertions:** `home_bottom_nav_bar_shopping_test.dart` currently asserts `find.text('買い物リスト')` — after D39-01 the value becomes `買い物`. This test must be updated in the same commit as the ARB rename.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| ARB key count parity | Custom script | `jq 'keys|length'` | Authoritative JSON tool, already available |
| Golden image comparison | Custom pixel diff | `matchesGoldenFile()` | Built into flutter_test SDK |
| Async provider settlement | Polling loop | `waitForFirstValue` from `test/helpers/test_provider_scope.dart` | Riverpod 3 compliant pattern already in project |
| In-memory DB for tests | Mock repository | `AppDatabase.forTesting()` | Already established, avoids platform channel issues |
| Theme color for goldens | Hardcoded hex values | `AppPalette.light.*` / `AppPalette.dark.*` static constants | Single source of truth — palette changes don't break goldens |

---

## Common Pitfalls

### Pitfall 1: context.palette Unresolved in Goldens (bare ThemeData)
**What goes wrong:** Shopping widgets call `context.palette` which resolves via `ThemeData.extension<AppPalette>()`. With bare `ThemeData.light()`, no extension is registered — `context.palette` throws `Null check operator used on a null value` or returns null.
**Why it happens:** Existing goldens for `ListTransactionTile` work because that widget takes explicit color parameters bypassing `context.palette`. Shopping widgets do NOT take explicit color params.
**How to avoid:** Use `theme: ThemeData.light().copyWith(extensions: [AppPalette.light])` and `darkTheme: ThemeData.dark().copyWith(extensions: [AppPalette.dark])`, OR use the app's real `AppTheme.light` / `AppTheme.dark`.
**Warning signs:** Golden generation fails with `Null check operator` or produces blank/white widgets.

### Pitfall 2: Stale Test Assertion for Nav Bar Label
**What goes wrong:** `home_bottom_nav_bar_shopping_test.dart` asserts `find.text('買い物リスト')` (old value). After D39-01/02, the ARB value becomes `買い物`. The test fails.
**Why it happens:** The test was written for Phase 38 which set the nav label to the long form. Phase 39 shortens it.
**How to avoid:** Update the test in the same commit as the ARB rename. Replace `find.text('買い物リスト')` with `find.text('買い物')` (ja), `find.text('购物')` (zh), `find.text('Shopping')` (en).
**Warning signs:** `flutter test` fails on `home_bottom_nav_bar_shopping_test.dart` after ARB rename.

### Pitfall 3: ShoppingItemTile Golden Without SliverReorderableList Parent
**What goes wrong:** `ReorderableDragStartListener` (used for the drag handle in `ShoppingItemTile`) requires a `SliverReorderableList` ancestor. Without it, `pumpAndSettle` throws "No Reorderable found in widget tree".
**Why it happens:** The tile is placed in a bare `Scaffold` + `SizedBox` without the required list ancestor.
**How to avoid:** Wrap in `CustomScrollView` + `SliverReorderableList` as shown in `shopping_item_tile_test.dart`. For the completed tile golden (`isActive: false`), the drag handle is not rendered — the `SliverReorderableList` wrapper is still needed but the handle icon will not appear.
**Warning signs:** Exception: "Reorderable ancestor not found" or equivalent.

### Pitfall 4: `todoTab` Has No Dart Code Reference — Deletion Is Safe
**What goes wrong:** Developer hesitates to delete `todoTab` because it seems "risky".
**Why it happens:** Missing context that `todoTab` was a legacy stale key.
**How to avoid:** Confirmed via grep: `grep -rn 'todoTab' lib/` returns only generated files (`lib/generated/`) and ARB files. No hand-written Dart code references it. Deletion from all three ARBs + `flutter gen-l10n` removes it cleanly from the generated class. Safe to delete.

### Pitfall 5: waitForFirstValue Not Used for Smoke Test
**What goes wrong:** `await container.read(filteredShoppingItemsProvider.future)` fails with "Bad state: disposed during loading" in Riverpod 3.
**Why it happens:** Riverpod 3 disposes auto-dispose providers if the reader doesn't maintain a subscription.
**How to avoid:** Use `waitForFirstValue<List<ShoppingItem>>(container, filteredShoppingItemsProvider)` from `test/helpers/test_provider_scope.dart`. Subscribe BEFORE triggering the write.
**Warning signs:** Intermittent "Bad state: disposed during loading" or "StateError" in test output.

### Pitfall 6: SC2 grep Matches Metadata Description Text
**What goes wrong:** `grep -rn 'Todo' lib/l10n/` matches the description string `"Todo tab label in bottom navigation"` even after the key value is changed.
**Why it happens:** SC2 requires ALL `todoTab`/`Todo` strings to be gone — including the `@todoTab` metadata entry which contains "Todo" in its description field.
**How to avoid:** Delete BOTH the value key (`todoTab`) AND the metadata key (`@todoTab`) including its description. After deletion, `grep -rn 'todoTab\|Todo' lib/l10n/` must return 0 hits.

---

## Code Examples

### Example 1: Empty State Golden with Variant Loop
```dart
// Source: adapted from test/golden/list_empty_state_golden_test.dart pattern
@Tags(['golden'])
library;

import 'package:home_pocket/features/shopping_list/presentation/widgets/shopping_empty_state.dart';

Widget _wrap({
  required Locale locale,
  required String listType,
  required bool isGroupMode,
  ThemeMode themeMode = ThemeMode.light,
}) {
  return ProviderScope(
    overrides: [
      locale_providers.currentLocaleProvider.overrideWith((_) async => locale),
      isGroupModeProvider.overrideWith((_) => isGroupMode),
    ],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: const [S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate],
      supportedLocales: S.supportedLocales,
      theme: ThemeData.light().copyWith(extensions: [AppPalette.light]),
      darkTheme: ThemeData.dark().copyWith(extensions: [AppPalette.dark]),
      themeMode: themeMode,
      home: Scaffold(
        body: Center(
          child: SizedBox(width: 390, height: 300,
            child: ShoppingEmptyState(listType: listType)),
        ),
      ),
    ),
  );
}
```

### Example 2: Smoke Test Provider Subscription Pattern
```dart
// Source: test/helpers/test_provider_scope.dart + CLAUDE.md Riverpod 3 conventions
test('SC4 reactive emit without invalidate', () async {
  final db = AppDatabase.forTesting();
  final container = ProviderContainer.test(
    overrides: [appDatabaseProvider.overrideWithValue(db), ...],
  );

  // Subscribe BEFORE write — Riverpod 3 disposes orphan reads
  final subscription = container.listen(
    filteredShoppingItemsProvider,
    (_, __) {},
    fireImmediately: true,
  );
  addTearDown(subscription.close);

  await applyOps.execute([/* public item op */]);

  // Use waitForFirstValue to avoid "disposed during loading"
  final result = await waitForFirstValue(container, filteredShoppingItemsProvider);
  expect(result.hasValue && result.value!.isNotEmpty, isTrue);
});
```

### Example 3: ARB Parity Verification
```bash
# Run after any ARB edit — all three must output the same number
jq 'keys | length' lib/l10n/app_ja.arb
jq 'keys | length' lib/l10n/app_zh.arb
jq 'keys | length' lib/l10n/app_en.arb

# Stale key elimination — must return empty
grep -rn 'homeTabTodo\|todoTab\|待办\|Todo' lib/l10n/
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `AsyncValue.valueOrNull` | `AsyncValue.value` (nullable) | Riverpod 3 | `.valueOrNull` removed; `.value` is now the nullable accessor |
| `ProviderContainer() + addTearDown` | `ProviderContainer.test()` | Riverpod 3 | Auto-disposes on test teardown |
| Bare `await container.read(provider.future)` | `waitForFirstValue()` helper | Riverpod 3 | Prevents "disposed during loading" |
| `StateNotifierProvider` | `AsyncNotifier` / `@riverpod` codegen | Riverpod 3 | Legacy — still compiles but discouraged |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `AppTheme.light` / `AppTheme.dark` exist in `lib/core/theme/app_theme.dart` and carry the `AppPalette` ThemeExtension | Architecture Patterns — theme question | Planner must use `ThemeData.light().copyWith(extensions: [AppPalette.light])` fallback instead |
| A2 | `filteredShoppingItemsProvider` is auto-dispose (not keepAlive) | Smoke Test | If keepAlive, bare `container.read` might work — but `waitForFirstValue` is safer either way |
| A3 | `applySyncOperationsUseCaseProvider` is exposed in `repository_providers.dart` or accessible via DI in the test | Smoke Test | May need direct instantiation of `ApplySyncOperationsUseCase` (as done in Phase 37 integration test) |

**If table is not empty:** A1 and A3 need planner verification before writing the golden harness and smoke test respectively.

---

## Open Questions

1. **AppTheme registration of AppPalette**
   - What we know: shopping widgets use `context.palette`; existing goldens use bare `ThemeData.light()` which would not carry `AppPalette` by default.
   - What's unclear: whether the existing `list_empty_state_golden_test.dart` somehow works with bare `ThemeData.light()` (perhaps `ListEmptyState` has a null-safe fallback for palette?) or whether there is a test setup that registers the extension.
   - Recommendation: Planner should read `lib/core/theme/app_theme.dart` and check if `AppTheme.light` registers the extension; also check `lib/core/theme/app_palette.dart` for a `BuildContext.palette` extension getter to confirm null-safety. Use `.copyWith(extensions: [AppPalette.light])` as the safe default.

2. **Smoke test provider wiring complexity**
   - What we know: `filteredShoppingItemsProvider` depends on `shoppingItemRepositoryProvider` which depends on `appDatabaseProvider` + `appFieldEncryptionServiceProvider`. The Phase 37 test manually wires these.
   - What's unclear: whether `applySyncOperationsUseCaseProvider` exists as a Riverpod provider (so it can be resolved from the container) or if the smoke test must manually instantiate `ApplySyncOperationsUseCase`.
   - Recommendation: Use the same direct-instantiation pattern as `shopping_sync_round_trip_test.dart` (Phase 37 test) — manual construction is explicit and avoids DI complexity.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | All tasks | ✓ | 3.44.0 | — |
| Dart SDK | All tasks | ✓ | 3.12.0 | — |
| jq | ARB parity verification | ✓ | system | `python3 -c "import json; ..."` |
| flutter gen-l10n | ARB codegen | ✓ | SDK-bundled | — |
| flutter test --update-goldens | Golden generation | ✓ | SDK-bundled | — |

**Missing dependencies with no fallback:** None.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | flutter_test (SDK-bundled) |
| Config file | none — tests invoked via `flutter test` |
| Quick run command | `flutter test test/golden/ test/widget/features/shopping_list/ --tags golden` |
| Full suite command | `flutter test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| NAV-03 (SC1) | ARB key count parity after rename | shell gate | `jq 'keys\|length' lib/l10n/app_{ja,zh,en}.arb` | ❌ Wave 0 (shell command, not a test file) |
| NAV-03 (SC2) | No stale keys/values remain in lib/l10n/ | shell gate | `grep -rn 'homeTabTodo\|todoTab\|待办\|Todo' lib/l10n/` returns 0 hits | ❌ Wave 0 (shell command) |
| NAV-03 (SC3) | Golden masters exist for all D39-04 states × 3 locales × 2 modes | golden | `flutter test test/golden/shopping_*_golden_test.dart --tags golden` | ❌ Wave 0 (new files) |
| NAV-03 (SC4) | `filteredShoppingItemsProvider` emits reactively without `ref.invalidate` | integration | `flutter test test/integration/presentation/shopping_provider_smoke_test.dart` | ❌ Wave 0 (new file) |
| NAV-03 (SC5-a) | `flutter analyze` 0 issues | static analysis | `flutter analyze` | ✓ existing CI |
| NAV-03 (SC5-b) | Coverage ≥70% on shopping_list/ + application/shopping_list/ | coverage | `flutter test --coverage && lcov --summary coverage/lcov.info` | ✓ existing CI |

### Sampling Rate

- **Per task commit:** `flutter analyze && flutter test test/golden/shopping_*_golden_test.dart test/integration/presentation/shopping_provider_smoke_test.dart --tags golden`
- **Per wave merge:** `flutter test` (full suite)
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `test/golden/shopping_empty_state_golden_test.dart` — covers SC3 (3 empty variants × 6)
- [ ] `test/golden/shopping_item_tile_golden_test.dart` — covers SC3 (active + completed + attribution × 6)
- [ ] `test/golden/shopping_filter_bar_golden_test.dart` — covers SC3 (active filter state × 6)
- [ ] `test/golden/shopping_batch_chrome_golden_test.dart` — covers SC3 (selection header + batch bar × 6 each)
- [ ] `test/integration/presentation/shopping_provider_smoke_test.dart` — covers SC4 (D39-06)
- [ ] `test/golden/goldens/shopping_*.png` — 42 baseline PNG files (generated via `--update-goldens` in Wave 0)

---

## Security Domain

> `security_enforcement` is not explicitly disabled in config.json — treating as enabled.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | n/a (no auth changes) |
| V3 Session Management | no | n/a |
| V4 Access Control | no (privacy already enforced in Phases 36/37) | n/a |
| V5 Input Validation | no | n/a (no new user inputs) |
| V6 Cryptography | no | n/a (no crypto changes) |

### Known Threat Patterns

This phase introduces no production runtime changes. The smoke test verifies that the privacy contract (private items excluded from public stream) holds at the presentation layer — this is a defence-in-depth regression test, not a new control.

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Private item leaks into golden fixture | Information Disclosure | Use only `listType: 'private'` for private-variant goldens; never mix private items into public-list golden fixtures |

---

## Sources

### Primary (HIGH confidence — direct codebase inspection)
- `test/golden/list_sort_filter_bar_golden_test.dart` — canonical golden scaffold with `currentLocaleProvider.overrideWith` synchronous pattern, `ThemeData.light()` / `dark()`, `themeMode` parameterization
- `test/golden/list_empty_state_golden_test.dart` — loop-based variant golden pattern, `ProviderScope` without locale override (stateless widget)
- `test/golden/list_transaction_tile_golden_test.dart` — dark-mode `AppPalette.dark.*` explicit color injection pattern for tiles with explicit color params
- `lib/features/shopping_list/presentation/widgets/shopping_empty_state.dart` — `ShoppingEmptyVariant` enum, `context.palette` usage, `isGroupModeProvider` dependency
- `lib/features/shopping_list/presentation/widgets/shopping_item_tile.dart` — `context.palette` for border color, `SliverReorderableList` requirement, attribution chip code, `batchSelectModeProvider`
- `lib/features/shopping_list/presentation/widgets/shopping_filter_bar.dart` — `shoppingFilterProvider` dependency
- `lib/features/shopping_list/presentation/widgets/shopping_selection_header.dart` — `batchSelectModeProvider`, `allItemIds` param
- `lib/features/shopping_list/presentation/widgets/shopping_batch_action_bar.dart` — `batchSelectModeProvider`, delete confirmation pattern
- `lib/features/shopping_list/presentation/providers/repository_providers.dart` — `filteredShoppingItemsProvider` as `Stream<List<ShoppingItem>>` wrapping `watchByListType`, doc comment "NEVER call ref.invalidate"
- `lib/features/shopping_list/presentation/providers/repository_providers.g.dart` — confirmed `filteredShoppingItemsProvider` generated name
- `lib/features/shopping_list/presentation/providers/state_shopping_filter.dart` — `listTypeProvider` (keepAlive), `shoppingFilterProvider` (keepAlive)
- `lib/features/home/presentation/widgets/home_bottom_nav_bar.dart:45` — confirmed single Dart call site `l10n.homeTabTodo`
- `lib/l10n/app_ja.arb`, `app_zh.arb`, `app_en.arb` — confirmed `homeTabTodo` at line 709, `todoTab` at line 1624 in all three; 586 non-`@` keys each
- `test/helpers/test_provider_scope.dart` — `waitForFirstValue<T>` implementation
- `test/integration/sync/shopping_sync_round_trip_test.dart` — Phase 37 application-layer reactive test (not the presentation-layer smoke test needed here)
- `test/widget/features/shopping_list/presentation/widgets/shopping_empty_state_test.dart` — pump/override scaffold for `ShoppingEmptyState`
- `test/widget/features/shopping_list/presentation/widgets/shopping_item_tile_test.dart` — pump/override scaffold for `ShoppingItemTile` including `SliverReorderableList` wrapper
- `test/widget/features/shopping_list/presentation/widgets/shopping_filter_bar_test.dart` — pump/override scaffold for `ShoppingFilterBar`
- `test/widget/features/shopping_list/presentation/widgets/home_bottom_nav_bar_shopping_test.dart` — asserts stale label values (must be updated)
- `lib/core/theme/app_palette.dart` — `AppPalette` ThemeExtension with `light`/`dark` statics; `context.palette` getter
- `.planning/research/PITFALLS.md` — GAP-2 reactivity lesson; Pitfall 10 (ARB rename); Pitfall 15 (golden churn)
- `CLAUDE.md` — Riverpod 3 conventions, i18n rules, `flutter gen-l10n` workflow

### Secondary (MEDIUM confidence)
- `.planning/ROADMAP.md` Phase 39 section — 5 success criteria
- `.planning/REQUIREMENTS.md` — NAV-03, D1-D8
- `.planning/phases/39-i18n-golden-re-baseline-smoke-test/39-CONTEXT.md` — all 7 locked decisions

---

## Metadata

**Confidence breakdown:**
- ARB rename mechanics: HIGH — direct file inspection, exact line numbers, confirmed call sites
- Golden harness: HIGH — 11 existing golden tests read directly; scaffold fully documented
- Theme mode in goldens: MEDIUM — bare `ThemeData.light()` usage confirmed but `context.palette` resolution path requires planner verification (A1)
- Smoke test pattern: HIGH — existing Phase 37 test read; `waitForFirstValue` helper confirmed; `filteredShoppingItemsProvider` confirmed
- Widget provider overrides: HIGH — widget source files + existing widget tests both read

**Research date:** 2026-06-08
**Valid until:** 2026-07-08 (stable domain — no fast-moving dependencies)
