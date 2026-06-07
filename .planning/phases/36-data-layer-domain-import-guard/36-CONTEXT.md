# Phase 36: Data Layer + Domain + Import Guard - Context

**Gathered:** 2026-06-07
**Status:** Ready for planning

<domain>
## Phase Boundary

Build the **data + domain + boundary foundation** for the shopping list, before any use-case or UI code exists:

- `ShoppingItems` Drift table at `lib/data/tables/` (schema **v20**, `if (from < 20)` → `migrator.createTable(shoppingItems)`)
- `ShoppingItemDao` with a reactive `watchByListType(listType)` (`.watch()` + `readsFrom:` the shopping table; completed-to-bottom ordering in SQL)
- Repository impl in `lib/data/repositories/` (note encryption + JSON tags encode/decode at this boundary)
- Wave-0 raw-sqlite3 contract test asserting the v20 `shopping_items` physical structure
- Freezed domain models (`ShoppingItem`, `ShoppingListFilter`, `ShoppingItemParams`) + `ShoppingItemRepository` interface (no Drift imports) under `lib/features/shopping_list/domain/`
- `LedgerTypeSelector` move `accounting/presentation/widgets/` → `shared/widgets/` (+ update all import sites)
- `import_guard.yaml` files for every new `lib/features/shopping_list/` subdir, mirroring `lib/features/list/`; `CategorySelectionScreen` allow-listed in the presentation guard

**Out of scope (later phases):** use-case logic + sync apply handlers (Phase 37), all UI/widgets/providers (Phase 38), ARB/goldens/smoke test (Phase 39).

</domain>

<decisions>
## Implementation Decisions

### v20 Schema — open fields resolved this phase

- **D-01 (tags storage):** `tags` is a **nullable `TextColumn` holding a JSON-encoded `List<String>`**. Encode/decode happens at the **repository boundary** (same layer where `note` is encrypted). Rationale: there is **no existing tag system** in the codebase to "reuse" (ITEM-03's premise is unfounded — no tags column on transactions, no tag entity/table), so it must be designed from scratch; JSON is safe for tags containing commas/special chars and needs no schema change if tag-filter is added in v2. v1.6 does **not** filter by tag, so the lack of SQL-level tag querying is acceptable.

- **D-02 (quantity type):** `quantity` is a **nullable `IntColumn`** (whole-count). A blank quantity defaults to 1 in the UI layer, not the schema. Rationale: the dominant shopping case is "buy N of X"; consistent with `estimatedPrice` being `IntColumn`; D8 already defers unit parsing, so decimal/weight quantities (1.5 kg) are explicitly out.

- **D-03 (completion-merge — ⚠ SUPERSEDES locked D7 / SYNC-05):** Add a **`completedAt DateTime?` nullable column** to the v20 table (table field count becomes **15**, not 14). The completion state uses a **sticky-complete** merge rule instead of pure last-write-wins: when `completedAt > incoming.updatedAt`, `isCompleted: true` is preserved and is NOT overwritten by a newer non-completion edit (e.g. a remote rename op). Rationale: this is a **family-shared public list**, so the un-check race (member A completes at T1; member B renames at T2 > T1 with their stale `isCompleted:false` → LWW silently un-checks) is real and user-visible; adding the column later would require another migration. **User explicitly chose this over the locked D7** ("LWW, no completedAt column") after being shown that D7 was locked.
  - **Phase 36 deliverable:** the column exists in v20 + is covered by the Wave-0 contract test. The merge *algorithm* itself lives in Phase 37's `ApplySyncOperationsUseCase` apply handler — Phase 36 only lands the column and documents the intended rule.
  - **Ripple to fix this phase:** the ROADMAP Phase-36 success-criteria field list (currently 14 fields, no `completedAt`) and **REQUIREMENTS.md SYNC-05 / D7** (which assert "no completedAt column / pure LWW") conflict with this decision and must be reconciled in the same commit, or the plan-checker / planner will re-derive the old D7 behavior.

### Carried forward — locked, do NOT re-ask

- Schema **v20**; migration is `if (from < 20)` → `migrator.createTable(shoppingItems)` (current code is **v19**, confirmed in `lib/data/app_database.dart:45`).
- `estimatedPrice`: nullable `IntColumn` (integer sub-units, JPY = yen, rendered via `NumberFormatter`) — ITEM-05.
- `note`: `TEXT NOT NULL`, **encrypted at the repository boundary** (mirror `TransactionRepositoryImpl`) — ITEM-05.
- DAO ordering: completed items to the bottom via SQL `ORDER BY is_completed ASC, sort_order ASC, created_at ASC` — DONE-02 (DAO query order, not client sort).
- Reactive delivery via `.watch()` + `readsFrom:` the shopping table — SYNC-06 / applies the v1.4 GAP-2 lesson.
- Domain models + repo interface carry **no Drift imports**; every new `shopping_list/` subdir gets an `import_guard.yaml` mirroring `lib/features/list/`; `CategorySelectionScreen` allow-listed in the presentation guard.
- `LedgerTypeSelector` → `lib/shared/widgets/` with all import sites updated.
- D1 (public/private = two independent lists), D6 (listType immutable — Phase 37/38), D5 (filter shared+reset — Phase 38) remain as locked; only D7 is overridden (see D-03).

### Claude's Discretion
- `sortOrder` initial-value strategy, `addedByBookId` null-handling at attribution display (omit member chip if shadow book not yet local — never throw), and exact Freezed model field granularity were left to the planner/researcher (standard approaches, not user-facing choices).
- Index design on `shopping_items` (likely `listType`, `listType+isDeleted`) is the planner's call, following the `transactions` `customIndices` pattern.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone scope & locked decisions
- `.planning/REQUIREMENTS.md` — D1–D8 locked decisions + all 27 SHOP/DONE/ITEM/FILT/MGMT/SYNC/NAV requirements. **NOTE:** SYNC-05 / D7 are overridden by D-03 above and must be reconciled this phase.
- `.planning/ROADMAP.md` §"Phase 36" — success criteria + field list (must be updated to add `completedAt`).

### v1.6 research (milestone-level, 2026-06-07)
- `.planning/research/SUMMARY.md` §"Open Questions" — OPEN-1/2/3; OPEN-1 (completedAt) is resolved here as D-03 (user chose the column, against the research's recommended Option B).
- `.planning/research/ARCHITECTURE.md` — file placement, migration pattern (6 prior `from < N` blocks), repo/DAO shapes.
- `.planning/research/PITFALLS.md` — private-item sync leak, GAP-2 reactivity, addedByBookId null-attribution, completion CRDT race.
- `.planning/research/STACK.md` — confirms zero new packages, schemaVersion v19.

### Codebase patterns to mirror
- `lib/data/tables/transactions_table.dart` — canonical `@DataClassName`, `customConstraints`, `List<TableIndex> get customIndices` with `{#symbol}` syntax.
- `lib/data/app_database.dart` (`schemaVersion => 19`, line 45) — migration `from < N` + `migrator.createTable` pattern; bump to 20.
- `lib/data/daos/transaction_dao.dart` — DAO method shapes, soft-delete, `readsFrom:` reactivity (GAP-2 source).
- `lib/data/repositories/` `TransactionRepositoryImpl` — field-encryption-at-boundary pattern (apply to `note` + JSON `tags`).
- `lib/features/list/domain/import_guard.yaml`, `lib/features/list/presentation/import_guard.yaml`, `lib/features/list/domain/models/import_guard.yaml` — guard files to mirror.
- `lib/features/accounting/presentation/widgets/ledger_type_selector.dart` — the widget being moved to `lib/shared/widgets/`.
- `.planning/codebase/CONVENTIONS.md`, `.planning/codebase/STRUCTURE.md` — layer placement + naming conventions.

### Project rules
- `CLAUDE.md` — Drift `TableIndex` syntax, layer/thin-feature rules, crypto-at-boundary rules. **Stale ref to fix:** CLAUDE.md/PROJECT.md say schema "v18→v19"; actual is v19→(this phase)v20.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `transactions_table.dart` is the table template (DataClassName, constraints, indices-with-symbols).
- `TransactionRepositoryImpl` note-encryption is the exact pattern for `note` + the new JSON `tags` encode/decode.
- `transaction_dao.dart` `.watch()` + `readsFrom:` is the reactive-stream template (SYNC-06).
- `lib/features/list/` is the full structural analog (module layout + 3 import_guard.yaml files).
- `LedgerTypeSelector` already exists — this phase relocates it, it is not rebuilt.

### Established Patterns
- Drift migration is additive `if (from < N)` blocks calling `migrator.createTable(...)` — 6 prior blocks exist.
- Field encryption is done at the repository boundary, never in tables/DAO.
- Layer boundaries are enforced by `import_guard.yaml` + custom_lint (`dart run custom_lint --no-fatal-infos`).

### Integration Points
- `lib/data/app_database.dart`: register `ShoppingItems` table, bump `schemaVersion` 19→20, add the `from < 20` migration block.
- `lib/shared/widgets/`: new home for `LedgerTypeSelector`; all current accounting import sites repoint.
- Domain interface `ShoppingItemRepository` is the lock other phases depend on (Phase 37 use cases, Phase 38 providers) — column names + method signatures must be final by end of this phase.

</code_context>

<specifics>
## Specific Ideas

- The `completedAt` sticky-complete behavior should be framed (in Phase 37) the way Bring!/AnyList-style apps avoid the "someone un-checked my item" surprise — completion is intentionally harder to undo than a normal field edit.
- Tags this version are **input + display only** — no tag-based filtering UI (deferred to v2 TAGFILT-01).

</specifics>

<deferred>
## Deferred Ideas

- Tag-based filtering (v2 TAGFILT-01) — drove the JSON-column choice so it's a non-breaking add later.
- Decimal / unit-bearing quantity ("1.5 kg", "500 g") — D8 / out-of-scope; `quantity` stays integer.
- Per-segment independent filter providers (research OPEN-2 Option A) — conflicts with locked D5 (shared+reset); a Phase 38 decision, not this phase.

None of these are acted on in Phase 36.

</deferred>

---

*Phase: 36-data-layer-domain-import-guard*
*Context gathered: 2026-06-07*
