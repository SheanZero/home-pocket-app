# Roadmap: Home Pocket

## Milestones

- ✅ **v1.0 Codebase Cleanup Initiative** — Phases 1-8 (shipped 2026-04-29) — see [archive](milestones/v1.0-ROADMAP.md)
- ✅ **v1.1 Happiness Metric & Display** — Phases 9-12 (shipped 2026-05-05) — see [archive](milestones/v1.1-ROADMAP.md)
- ✅ **v1.2 Happiness Metric Refresh** — Phases 13-17 (shipped 2026-05-21) — see [archive](milestones/v1.2-ROADMAP.md)
- ✅ **v1.3 迭代帐本输入** — Phases 18-23 (shipped 2026-05-26) — see [archive](milestones/v1.3-ROADMAP.md)
- ✅ **v1.4 列表功能** — Phases 24-30 (shipped 2026-05-31) — see [archive](milestones/v1.4-ROADMAP.md)
- ✅ **v1.5 文案与配色统一** — Phases 31-35 (shipped 2026-06-02) — see [archive](milestones/v1.5-ROADMAP.md)
- 🔄 **v1.6 购物清单** — Phases 36-39 (in progress, started 2026-06-07)

## Phases

<details>
<summary>✅ v1.0 Codebase Cleanup Initiative (Phases 1-8) — SHIPPED 2026-04-29</summary>

- [x] Phase 1: Audit Pipeline + Tooling Setup (8/8 plans) — completed 2026-04-25
- [x] Phase 2: Coverage Baseline (4/4 plans) — completed 2026-04-26
- [x] Phase 3: CRITICAL Fixes (5/5 plans) — completed 2026-04-26
- [x] Phase 4: HIGH Fixes (6/6 plans) — completed 2026-04-27
- [x] Phase 5: MEDIUM Fixes (5/5 plans) — completed 2026-04-27
- [x] Phase 6: LOW Fixes (6/6 plans) — completed 2026-04-27
- [x] Phase 7: Documentation Sweep (6/6 plans) — completed 2026-04-28
- [x] Phase 8: Re-Audit + Exit Verification (8/8 plans) — completed 2026-04-28

**Outcome:** REAUDIT-DIFF.json reports `resolved=50, regression=0, new=0, open_in_baseline=0`. 4 permanent CI guardrails active. Full details: `.planning/milestones/v1.0-ROADMAP.md`.

</details>

<details>
<summary>✅ v1.1 Happiness Metric & Display (Phases 9-12) — SHIPPED 2026-05-05</summary>

- [x] Phase 9: Happiness Domain & Formula Layer (14/14 plans) — completed 2026-05-02
- [x] Phase 10: HomePage SoulFullnessCard Redesign (13/13 plans) — completed 2026-05-03
- [x] Phase 11: AnalyticsScreen Unified Dashboard (8/8 plans) — completed 2026-05-04
- [x] Phase 12: UI Copy Rename Pass (5/5 plans) — completed 2026-05-04

**Outcome:** v1.1 delivered the happiness metric domain, integrated HomeHeroCard, Variant δ AnalyticsScreen, trilingual Joy/Daily ledger copy rename, and accepted ADR-015 lexical hierarchy. One Phase 11 human UAT verification item is acknowledged as deferred at close in `.planning/STATE.md`. Full details: `.planning/milestones/v1.1-ROADMAP.md`.

</details>

<details>
<summary>✅ v1.2 Happiness Metric Refresh (Phases 13-17) — SHIPPED 2026-05-21</summary>

- [x] Phase 13: ADR-016 Backend Foundation (7/7 plans) — completed 2026-05-19
- [x] Phase 14: ADR-016 Frontend + ARB Reconciliation (6/6 plans) — completed 2026-05-19
- [x] Phase 15: Custom Time Windows (6/6 plans) — completed 2026-05-19
- [x] Phase 16: Per-Category Breakdown + Soul-vs-Survival (10/10 plans) — completed 2026-05-20
- [x] Phase 17: Manual-Only Joy Sub-Metric (8/8 plans) — completed 2026-05-21

**Outcome:** v1.2 migrated the Joy metric from density (Joy/¥) to cumulative `Σ joy_contribution` (ADR-016): HomeHero rebuilt with sage-green→gold target ring, Settings exposes user-configurable `monthly_joy_target` with 3-month median recommendation + fallback baseline 50, AnalyticsScreen Variant ε retired density and added Custom Time Windows (week/month/quarter/year/arbitrary), Per-Category breakdown + Soul-vs-Survival comparison with anti-toxicity framing, and Manual-Only Joy sub-metric variant on Drift schema v17 (`entry_source` column). HomeHero isolation invariant (ADR-016 §3) structurally enforced. Audit status `tech_debt` accepted at close — Phase 13/17 lack VERIFICATION.md; 3 Nyquist VALIDATION.md drafts; documentation-grade debt only. Full details: `.planning/milestones/v1.2-ROADMAP.md` + `.planning/milestones/v1.2-MILESTONE-AUDIT.md`.

</details>

<details>
<summary>✅ v1.3 迭代帐本输入 (Phases 18-23) — SHIPPED 2026-05-26</summary>

- [x] Phase 18: Shared Details Form Foundation (8/8 plans) — completed 2026-05-22
- [x] Phase 19: Manual One-Step + Keypad Polish (5/5 plans) — completed 2026-05-23
- [x] Phase 20: Voice Number Parser (zh + ja) (9/9 plans) — completed 2026-05-24
- [x] Phase 21: Voice Category Resolver Level-2 Enforcement (6/6 plans) — completed 2026-05-25
- [x] Phase 22: Voice One-Step Integration + Record Button UX (10/10 plans) — completed 2026-05-25
- [x] Phase 23: v1.3 Cleanup — Scanner Allow-Lists + Voice Flow Polish (9/9 plans) — completed 2026-05-26

**Outcome:** v1.3 transformed ledger entry into single-screen, voice-trustworthy core experience. Single shared `TransactionDetailsForm` widget powers 4 hosts (manual, voice, edit, OCR review). `ManualOneStepScreen` collapses 2-screen entry chain; SmartKeyboard 48dp non-negotiable touch-target floor with 6 golden baselines. Locale-aware zh+ja voice number parsing (state machines + `VoiceChunkMerger` 2.5s continued-listening window) at zh 96% + ja 100% corpus accuracy. `VoiceCategoryResolver` always-L2 contract with merchant DB + extensible synonym dictionary. Hold-to-record gesture with AnimatedContainer shape morph + caption swap (`<100ms` verified). 2 BLOCKER gaps (G-01/G-02) elevated and closed in Phase 22. Phase 23 cleanup absorbed carried tech-debt: scanner allow-lists, 6 voice-flow surgical fixes, 4 mechanical polish items, REQUIREMENTS.md reconciliation, 9/9 device UATs passed, `voice_input_screen.dart` slimmed 838→776 LOC via mixin + helpers extraction. Audit status `tech_debt` accepted at close — documentation-grade Nyquist debt only; all 15 v1.3 requirements satisfied and reconciled. Full details: `.planning/milestones/v1.3-ROADMAP.md` + `.planning/milestones/v1.3-MILESTONE-AUDIT.md`.

</details>

<details>
<summary>✅ v1.4 列表功能 (Phases 24-30) — SHIPPED 2026-05-31</summary>

- [x] Phase 24: Data Layer Extension (3/3 plans) — completed 2026-05-29
- [x] Phase 25: Domain Models + Use Case (2/2 plans) — completed 2026-05-29
- [x] Phase 26: Providers + Shell Wiring (4/4 plans) — completed 2026-05-30
- [x] Phase 27: Calendar Header + Month Summary (4/4 plans) — completed 2026-05-30
- [x] Phase 28: Transaction Tile + Sort/Filter Bar (7/7 plans) — completed 2026-05-30
- [x] Phase 29: List Screen Assembly + Family (4/4 plans) — completed 2026-05-30
- [x] Phase 30: i18n + Empty States + Golden Polish (5/5 plans) — completed 2026-05-31

**Outcome:** Built the placeholder List tab into a full transaction overview. New `lib/features/list/` module: `table_calendar` month header (per-day expense grid + month nav + day-tap filter + month summary), a sortable (date / edit-time / amount ± direction) · searchable (category·merchant·note) · filterable (ledger · multi-category · family-member, AND-composed) transaction list, family-aware shadow-book merge with per-row owner attribution + "Mine only", reactive updates + pull-to-refresh reusing the v1.3 edit / soft-delete (hash-chain-safe) path, 3-variant empty states, and ~20–25 new ARB keys × 3 locales with golden baselines. Shared `DateBoundaries` util consolidated month-boundary arithmetic. GAP-1 (calendar staleness after family-sync / FAB) closed at milestone close via quick task 260531-u34. Audit `tech_debt` accepted — 22/22 requirements, 7/7 phases, 7/7 E2E flows satisfied; residual GAP-2 dead-code + draft-Nyquist documentation debt only. Full details: `.planning/milestones/v1.4-ROADMAP.md` + `.planning/milestones/v1.4-MILESTONE-AUDIT.md`.

</details>

<details>
<summary>✅ v1.5 文案与配色统一 (Phases 31-35) — SHIPPED 2026-06-02</summary>

- [x] Phase 31: Terminology Rename (6/6 plans) — completed 2026-06-01
- [x] Phase 32: Palette Exploration & Selection (3/3 plans) — completed 2026-06-01
- [x] Phase 33: Color Token System & Consolidation (8/8 plans) — completed 2026-06-01
- [x] Phase 34: Golden Re-baseline & Verification (5/5 plans) — completed 2026-06-01
- [x] Phase 35: Close Vocab Leaks — a11y Semantics labels (W1) + totalSoulTx identifiers (W2) (2/2 plans) — completed 2026-06-02

**Outcome:** Brownfield consistency refactor unifying the half-migrated dual-ledger vocabulary across all 3 locales + internal code, and consolidating scattered colors into a single semantic token system. Phase 31 renamed the `LedgerType` enum (survival→daily, soul→joy) across 242 call sites, all 25 ledger-vocab ARB key roots + values to canonical 日常/悦己/ときめき/Daily/Joy, and ran the v17→v18 Drift migration (stored enum-value rewrite + `soul_satisfaction`→`joy_fullness`), recorded in ADR-017. Phase 32 mined 5 candidate palette directions → 5 Pencil schemes × 6 frames → user-selected Scheme D "Teal Clarity" (teal primary, Daily teal-navy ↔ Joy gold), recorded in ADR-018 with a full light+dark hex-per-role table. Phase 33 built the `AppPalette` ThemeExtension as the single source of truth, replaced all `Color(0x…)` literals, deleted the AppColors/AppColorsDark shims, and rolled out full dark mode (THEME-V2-02 pulled forward, D-07). Phase 34 re-baselined 50 golden masters + added 27 dark masters (77 total) to the teal palette with full suite 2281/2281 green. Phase 35 closed two residual leaks found by the milestone audit (W1 hardcoded a11y Semantics labels → l10n; W2 `totalSoulTx`→`totalJoyTx` across Freezed models + use-cases + 9 tests). Audit `tech_debt` accepted at close — 15/15 requirements, 5/5 phases, 6/6 integration seams wired; residual is one pending on-device screen-reader UAT, draft-Nyquist docs (P31/32/34/35), and the documented out-of-scope `Book.*Balance` DB-column carve-out. Full details: `.planning/milestones/v1.5-ROADMAP.md` + `.planning/milestones/v1.5-MILESTONE-AUDIT.md`.

</details>

### v1.6 购物清单 (Phases 36-39) — IN PROGRESS

- [ ] **Phase 36: Data Layer + Domain + Import Guard** — ShoppingItems table (schema v20), DAO, repository impl, Wave-0 migration contract test, Freezed domain models, repository interface, LedgerTypeSelector move, import_guard files
- [ ] **Phase 37: Application Use Cases + Sync Integration** — 6 use cases with private-item privacy gate, ShoppingItemChangeTracker, SyncOrchestrator extension, ApplySyncOperationsUseCase branch, reactive-stream integration test
- [ ] **Phase 38: Presentation Shell + UI Widgets** — nav rename + shopping-bag icon, context-aware FAB, keepAlive providers, ShoppingListScreen shell, ShoppingItemTile, add/edit form, filter bar, swipe-delete, batch-select, empty states
- [ ] **Phase 39: i18n + Golden Re-baseline + Smoke Test** — ARB key parity ja/zh/en, golden masters all states × locales × color modes, reactive-sync smoke test, analyze 0 + coverage ≥70%

## Phase Details

### Phase 36: Data Layer + Domain + Import Guard

**Goal:** The shopping list has a persistent, encrypted, migration-safe database foundation, a clearly defined domain contract, and enforced layer boundaries before any use-case or UI code is written
**Depends on:** Nothing (column names and domain interface must be locked before all other phases)
**Requirements:** DONE-02, ITEM-05, SYNC-05, SHOP-01, ITEM-03
**Success Criteria** (what must be TRUE):

  1. A `ShoppingItems` Drift table exists at `lib/data/tables/` with all 15 business fields (name, listType, ledgerType, categoryId, tags, note, estimatedPrice, quantity, isCompleted, completedAt, sortOrder, addedByBookId, isDeleted, createdAt, updatedAt); `completedAt DateTime?` is nullable (D-03: sticky-complete merge timestamp, added per 2026-06-07 planning session overriding D7); `estimatedPrice` is `IntColumn` nullable; `note` is `TEXT NOT NULL`; Drift schema version is `20` (not 19) with an `if (from < 20)` migration block calling `migrator.createTable(shoppingItems)`
  2. `ShoppingItemDao` has `watchByListType(listType)` returning a reactive `Stream` via `.watch()` with `readsFrom:` the shopping table — completed items sort to the bottom via SQL `ORDER BY is_completed ASC, sort_order ASC, created_at ASC`; soft-delete and upsert behavior is tested (deleted item has `isDeleted=true`, not physically removed)
  3. A Wave-0 raw-sqlite3 contract test opens the v20 database and verifies the `shopping_items` table structure (column names, types, NOT NULL constraints) without going through the Drift ORM
  4. `ShoppingItem`, `ShoppingListFilter`, and `ShoppingItemParams` Freezed models exist at `lib/features/shopping_list/domain/models/`; `ShoppingItemRepository` interface exists at `lib/features/shopping_list/domain/repositories/` with no Drift imports; all new `lib/features/shopping_list/` subdirectories have `import_guard.yaml` files mirroring the `lib/features/list/` pattern; `flutter analyze` reports 0 issues
  5. `LedgerTypeSelector` widget is moved from `lib/features/accounting/presentation/widgets/` to `lib/shared/widgets/` and all existing import sites updated; `CategorySelectionScreen` is allow-listed in `lib/features/shopping_list/presentation/import_guard.yaml`; `dart run custom_lint --no-fatal-infos` passes with zero new violations

**Plans:** 2/7 plans executed

Plans:
**Wave 1**

- [x] 36-01-PLAN.md — Wave-0 test scaffolds (contract, DAO, repo)
- [x] 36-02-PLAN.md — ShoppingItems table + app_database v19→v20 migration + build_runner
- [ ] 36-03-PLAN.md — LedgerTypeSelector move to shared/widgets/ + import_guard YAMLs
- [ ] 36-04-PLAN.md — Domain Freezed models (ShoppingItem, ShoppingListFilter, ShoppingItemParams) + repository interface
- [ ] 36-07-PLAN.md — Documentation reconciliation (D-03 ripple: REQUIREMENTS.md/ROADMAP/CLAUDE.md)

**Wave 2** *(blocked on Wave 1 completion)*

- [ ] 36-05-PLAN.md — ShoppingItemDao implementation (reactive watchByListType, soft-delete, upsert, reorder)
- [ ] 36-06-PLAN.md — ShoppingItemRepositoryImpl (note encryption + JSON tags at boundary)

**Cross-cutting constraints:**

- `flutter analyze` reports 0 issues

### Phase 37: Application Use Cases + Sync Integration

**Goal:** Every shopping list mutation is mediated by a use case that enforces the private-item privacy contract, and public items sync bidirectionally through the existing family_sync pipeline with reactive delivery and tombstone safety
**Depends on:** Phase 36 (repository interface and column names locked)
**Requirements:** ITEM-01, ITEM-02, ITEM-04, DONE-01, DONE-03, MGMT-01, MGMT-02, MGMT-03, SYNC-01, SYNC-02, SYNC-03, SYNC-05, SYNC-06
**Success Criteria** (what must be TRUE):

  1. Six use cases exist at `lib/application/shopping_list/`: `CreateShoppingItemUseCase`, `UpdateShoppingItemUseCase`, `DeleteShoppingItemUseCase`, `ToggleItemCompletedUseCase`, `ReorderShoppingItemsUseCase`, `ClearCompletedItemsUseCase`; a dedicated Mocktail test verifies that after inserting a private item via `CreateShoppingItemUseCase`, `ShoppingItemChangeTracker.pendingCount == 0`; after inserting a public item, `pendingCount == 1`
  2. `UpdateShoppingItemUseCase` rejects any attempt to change an item's `listType` field (immutable after creation per D6/SYNC-03), returning an error or no-op with a documented invariant; `ClearCompletedItemsUseCase` soft-deletes all completed items for the given `listType` regardless of active filter state
  3. `ShoppingItemChangeTracker` exists at `lib/application/family_sync/` mirroring `TransactionChangeTracker`; it accepts only public items (the `listType == 'public'` guard is enforced inside the tracker as a second safety net after the use-case gate); `SyncOrchestrator._executeIncrementalPush` is extended to push shopping item ops; `ApplySyncOperationsUseCase` has a `case 'shopping_item':` branch routing to a `_applyShoppingItemOp` handler; adding `ShoppingItemRepository` to `ApplySyncOperationsUseCase`'s constructor is done atomically with updating all existing construction sites
  4. A soft-deleted item (tombstone) is not resurrected by a subsequent remote update op arriving after the deletion — the apply handler checks `isDeleted` before applying updates
  5. A reactive-stream integration test verifies: a public item created by member A appears in member B's `watchByListType('public')` stream without manual refresh; a private item created by member A does NOT appear in the stream for any remote member; `flutter test test/application/shopping_list/` and the sync integration tests both pass

**Plans:** TBD

### Phase 38: Presentation Shell + UI Widgets

**Goal:** Users can fully manage their shopping lists — adding, completing, filtering, and batch-deleting items — through a complete, gesture-safe, accessibility-respecting UI on a correctly renamed and icon-updated nav tab with a context-aware FAB
**Depends on:** Phase 36 (domain interfaces), Phase 37 (use cases available for provider wiring)
**Requirements:** SHOP-02, SHOP-03, SHOP-04, DONE-01, DONE-03, ITEM-01, ITEM-02, ITEM-04, FILT-01, FILT-02, FILT-03, MGMT-01, MGMT-02, MGMT-03, NAV-01, NAV-02, SYNC-04
**Success Criteria** (what must be TRUE):

  1. The 4th nav tab reads 购物清单 (zh) / 買い物リスト (ja) / Shopping List (en) with a shopping-bag icon; zero `待办`/`Todo` strings remain in any rendered UI; on the shopping tab the bottom-right FAB navigates to the add-shopping-item screen; on every other tab the FAB navigates to the transaction-entry flow with all existing post-entry provider invalidations intact — no accounting regression; a widget test confirms the FAB routes correctly for index 3 vs any other index
  2. `listTypeProvider` (public/private segment selection) and `shoppingFilterProvider` (filter state) both have `keepAlive: true`; filter state resets when the user switches between the public and private segments (D5); the reset is observed in a widget test using `ProviderContainer`; the `ShoppingListScreen` shell replaces the `Center(Text(l10n.todoTab))` placeholder and shows a loading state while the stream initializes
  3. `ShoppingItemTile` renders: item name as primary text; category emoji, quantity, and estimated price as secondary text (when set); a dual-ledger color accent left border (`palette.daily`/`palette.joy`, neutral when no ledger set); a family attribution chip (avatar emoji + display name) on public list tiles only (SYNC-04); animated strikethrough + fade when toggled completed (DONE-01)
  4. The add/edit form accepts all D4 fields — name (required, validated), optional ledger selector (reuses `LedgerTypeSelector` from `lib/shared/widgets/`), optional category (pushes to `CategorySelectionScreen`), optional tags, note (encrypted at repo boundary), quantity (plain numeric), and estimated price (integer yen via `NumberFormatter`); completed items sort exclusively below a visual divider; active items in a `SliverReorderableList`; swipe-to-delete uses `Dismissible` and is disabled while batch-select mode is active (MGMT-03)
  5. Long-pressing any item enters batch-select mode with a floating bottom action bar; "Select all" is available; the batch-delete confirmation fires `DeleteShoppingItemUseCase` for each selected item with soft-delete semantics; "Clear all completed" appears only when the completed section is non-empty and fires `ClearCompletedItemsUseCase` for the current segment regardless of active filters; all three empty state variants (empty private, empty public solo, empty public family) render correctly (SHOP-04)

**Plans:** TBD
**UI hint**: yes

### Phase 39: i18n + Golden Re-baseline + Smoke Test

**Goal:** Every user-facing string in the shopping list is internationalized and pixel-verified across all three locales and both color modes; the end-to-end sync flow is confirmed to work reactively without manual refresh
**Depends on:** Phase 38 (UI stable before goldens), Phase 37 (sync wired for smoke test)
**Requirements:** NAV-03
**Success Criteria** (what must be TRUE):

  1. All shopping list ARB keys exist across ja/zh/en in the same commit; `jq 'keys | length' lib/l10n/app_ja.arb` equals `jq 'keys | length' lib/l10n/app_zh.arb` equals `jq 'keys | length' lib/l10n/app_en.arb`; `flutter gen-l10n` succeeds with 0 warnings
  2. A `grep -rn 'homeTabTodo\|todoTab\|待办\|Todo' lib/l10n/` returns 0 hits confirming complete rename
  3. Golden masters cover all shopping list screen states × 3 locales (ja/zh/en) × 2 color modes (light/dark): empty state (3 variants), list with active items, list with completed items, filter bar active, batch-select mode; full test suite passes green
  4. A sync smoke test verifies that a public item written by a simulated family-sync operation (directly via `ApplySyncOperationsUseCase`) causes the `watchByListType('public')` `StreamProvider` to emit a new state without any `ref.invalidate` call — confirming the v1.4 GAP-2 lesson is applied
  5. `flutter analyze` reports 0 issues; `flutter test --coverage` passes with coverage ≥70% on all new files in `lib/features/shopping_list/` and `lib/application/shopping_list/`

**Plans:** TBD

## Milestone Progress

| Milestone | Phases | Plans Complete | Status | Shipped |
|-----------|--------|----------------|--------|---------|
| v1.0 Codebase Cleanup Initiative | 1-8 | 48/48 | Complete | 2026-04-29 |
| v1.1 Happiness Metric & Display | 9-12 | 40/40 | Complete | 2026-05-05 |
| v1.2 Happiness Metric Refresh | 13-17 | 37/37 | Complete | 2026-05-21 |
| v1.3 迭代帐本输入 | 18-23 | 47/47 | Complete | 2026-05-26 |
| v1.4 列表功能 | 24-30 | 29/29 | Complete | 2026-05-31 |
| v1.5 文案与配色统一 | 31-35 | 24/24 | Complete | 2026-06-02 |
| v1.6 购物清单 | 36-39 | 0/0 | In progress | — |

## Phase Progress (v1.6)

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 36. Data Layer + Domain + Import Guard | 2/7 | In Progress|  |
| 37. Application Use Cases + Sync Integration | 0/TBD | Not started | - |
| 38. Presentation Shell + UI Widgets | 0/TBD | Not started | - |
| 39. i18n + Golden Re-baseline + Smoke Test | 0/TBD | Not started | - |
