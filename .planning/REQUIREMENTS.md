# Requirements: Home Pocket — v1.6 购物清单 (Shopping List)

**Defined:** 2026-06-07
**Core Value:** A family accounting app users can trust with sensitive financial data — local-first, end-to-end encrypted, with a dual-ledger system that distinguishes 日常 (daily) spending from 悦己 (joy) spending so families can have honest money conversations.

**Milestone goal:** Build the placeholder 4th nav tab (待办事项/Todo) into a complete shopping-list feature with public/private separation, rich add-item metadata, filtering, and batch management.

**Locked decisions (from /gsd-new-milestone questioning, 2026-06-07):**
- **D1** — Public / Private as a top segmented control (two independent lists, not a per-item visibility flag).
- **D2** — Context-aware FAB on the shopping tab routes to the add-item screen.
- **D3** — Pure list: completing an item only checks it off; **no transaction/accounting linkage**.
- **D4** — Add-item form: name (required) + optional ledger (日常/悦己), category, tags, note, quantity, estimated price.
- **D5** (filter scope) — Filter state is **shared** across both segments and **resets** when switching public↔private.
- **D6** (visibility mutability) — An item's public/private attribute is **immutable after creation**.
- **D7** (completion merge) — **SUPERSEDED by D-03** (2026-06-07 planning session): `completedAt DateTime?` nullable column added to v20 schema. Sticky-complete merge rule: when `completedAt > incoming.updatedAt`, `isCompleted: true` is preserved and NOT overwritten by a later non-completion edit. Phase 36 adds the column; Phase 37 implements the merge algorithm in `ApplySyncOperationsUseCase`. Original D7 ("no completedAt / pure LWW") is withdrawn.
- **D8** (differentiators in scope) — **per-item family attribution** + **dual-ledger color accent** are IN; running subtotal, name-autocomplete, category-grouping, tag-filter, and duplicate-detection are deferred.

---

## v1 Requirements

Requirements for this milestone. Each maps to exactly one roadmap phase (see Traceability).

### List & Structure (SHOP)

- [x] **SHOP-01**: User can switch between 公共 (public) and 私人 (private) shopping lists via a top segmented control; each segment is a fully independent list.
- [ ] **SHOP-02**: User sees shopping items in a scrollable list; each tile shows the item name as primary text, a category emoji, and — when set — quantity and estimated price as secondary text.
- [ ] **SHOP-03**: User sees a dual-ledger color accent (日常/悦己 left border via `palette.daily`/`palette.joy`) on each tile when a ledger is set; a neutral accent when none is set. *(differentiator)*
- [ ] **SHOP-04**: User sees a clear empty state per list with a next-step CTA — three variants: empty private list, empty public list (solo), empty public list (family joined).

### Completion (DONE)

- [ ] **DONE-01**: User can tap an item row to toggle its completed state, with an animated strikethrough + fade.
- [x] **DONE-02**: Completed items sort to the bottom of the current list, below a visual divider; active items remain on top (enforced by DAO query order, not client sort).
- [ ] **DONE-03**: User can one-tap "clear all completed" (with confirmation); it clears every completed item in the current list regardless of any active filter, and the control appears only when the completed section is non-empty.

### Add / Edit Item (ITEM)

- [ ] **ITEM-01**: User can add a shopping item; only the item name is required, all other fields optional.
- [ ] **ITEM-02**: User can optionally set ledger (日常/悦己), category, tags, note, quantity, and estimated price on an item.
- [x] **ITEM-03**: The add/edit form reuses the existing category tree, tag system, and ledger selector (no forked pickers).
- [ ] **ITEM-04**: User can edit any existing item via the same form, pre-populated with its current values.
- [x] **ITEM-05**: Estimated price is stored as integer sub-units and rendered locale-aware via `NumberFormatter`; the note field is encrypted at the repository boundary (mirrors `TransactionRepositoryImpl`).

### Filter (FILT)

- [ ] **FILT-01**: User can filter the current list by ledger (All / 日常 / 悦己), category, and status (active / all), using a chip bar consistent with the v1.4 `ListSortFilterBar`.
- [ ] **FILT-02**: Filter state is shared across both segments and resets when switching public↔private (D5).
- [ ] **FILT-03**: User can clear all active filters in one tap; the active/completed split is preserved within any filtered view.

### Management (MGMT)

- [ ] **MGMT-01**: User can swipe an item to delete it (with confirmation), matching the v1.4 list swipe-delete convention.
- [ ] **MGMT-02**: User can long-press to enter batch-select mode, select multiple items (including select-all), and batch-delete with a confirmation dialog.
- [ ] **MGMT-03**: Swipe-to-delete is disabled while batch-select mode is active; user can cancel selection mode via tap-outside or an explicit Cancel control.

### Sync & Privacy (SYNC)

- [ ] **SYNC-01**: Items on the public list sync to family members through the existing family_sync E2EE pipeline once a family is joined.
- [ ] **SYNC-02**: Items on the private list NEVER enter the sync pipeline — the change tracker enqueues only public items, enforced at the use-case boundary and verified by a dedicated test gate. *(privacy-critical)*
- [ ] **SYNC-03**: An item's public/private attribute is fixed at creation and cannot be changed afterward (D6) — eliminates the public→private sync-tombstone edge case.
- [ ] **SYNC-04**: On the public list, each item shows which family member added it (avatar emoji + display name from shadow books); the private list shows no attribution. *(differentiator)*
- [x] **SYNC-05**: Concurrent family edits to the same item resolve via sticky-complete rule (D-03 overrides D7): when `completedAt > incoming.updatedAt`, `isCompleted: true` is preserved; a soft-deleted (tombstoned) item is not resurrected by a remote update op. Phase 36 delivers the `completedAt DateTime?` column; Phase 37 implements the merge algorithm in `ApplySyncOperationsUseCase`.
- [ ] **SYNC-06**: Public-list changes synced from family members appear reactively via a Drift `.watch()` stream (`readsFrom:` the shopping table) without manual refresh (applies the v1.4 GAP-2 lesson).

### Navigation & Rename (NAV)

- [ ] **NAV-01**: On the shopping-list tab, the bottom-right FAB opens the add-shopping-item screen; on every other tab it remains the transaction-entry FAB with its existing post-entry invalidations intact (no accounting regression). *(D2)*
- [ ] **NAV-02**: The 4th nav tab and all user-facing strings read 购物清单 (zh) / 買い物リスト (ja) / Shopping List (en); no 待办/Todo strings remain anywhere, and the tab icon changes from `check_box_outlined` to a shopping icon.
- [ ] **NAV-03**: ARB key parity holds across ja/zh/en and `flutter gen-l10n` succeeds without warnings.

---

## v2 Requirements

Deferred to a future release. Tracked but not in this roadmap. (Research FEATURES.md P2/P3 items.)

### Shopping Enhancements

- **SUBTOTAL-01**: Running estimated total — Σ(estimatedPrice × quantity) across active items, shown in the list header. *(research's #1 competitor gap; deferred this milestone)*
- **AUTO-01**: Name autocomplete from local item-name history (privacy-respecting, not shared across lists).
- **GROUP-01**: Sort / group items by category with collapsible group headers (store-layout proxy).
- **TAGFILT-01**: Tag filter chip in the filter bar (add when tags see heavy shopping use).
- **DUP-01**: Duplicate-item detection — warn (not block) on exact-match active item name.
- **COLLAPSE-01**: Collapsible completed section.

### Future Consideration (v2+)

- **VOICE-SHOP-01**: Voice-add a shopping item (requires voice pipeline extension to a new entity type).
- **PUSH-SHOP-01**: APNS push when a family member adds to the public list (currently appears on next open / sync).
- **REORDER-01**: Manual drag-to-reorder items (conflicts with swipe-delete + completed-to-bottom; category grouping covers most of the need).
- **PRICEHIST-01**: Price history per item name.

---

## Out of Scope

Explicitly excluded for v1.6. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Completion creates a transaction | Locked out by D3 — keeps the list pure; record expenses via the normal FAB on other tabs |
| Gamification (streaks / badges / achievements) | Hard-blocked by ADR-012, cross-milestone |
| Running estimated subtotal | Per-item estimated price IS in scope (D4), but the aggregated running total is deferred (D8 → v2 SUBTOTAL-01) |
| Name autocomplete / category-grouping / tag-filter / duplicate-detection | Deferred per D8 (→ v2 AUTO/GROUP/TAGFILT/DUP) |
| Quantity unit parsing ("500g" → 500 + "g") | MEDIUM-HIGH locale-aware parsing; quantity is a plain numeric field for v1.6 |
| Real-time push for family additions | Non-trivial APNS payload routing; additions appear on next open/sync (→ v2 PUSH-SHOP-01) |
| Barcode / QR scan to add items | Requires camera + product DB/network lookup; breaks local-first/privacy values |
| More than two lists (beyond Public/Private) | D1 locks the model to exactly two; use tags/categories to distinguish within the public list |
| List templates / recurring items | Requires scheduled tasks + template management; unproven use case |
| Sort by store / aisle | Requires a store+aisle metadata dimension; category grouping is the proxy |
| Item images / photos | Photo storage + E2EE-synced image handling out of proportion for v1.6; notes field covers brand guidance |
| Sharing list with non-family (guest link) | family_sync is family-scoped (join code); public list is family-only |
| Full-text search within a list | A single list rarely exceeds 20–30 items; filter bar (ledger/category/status) suffices |
| Changing an item's public/private after creation | Out of scope per D6 — immutable visibility eliminates the sync-tombstone edge case |

---

## Traceability

Which phases cover which requirements. Updated for 4-phase consolidated roadmap (36-39).

| Requirement | Phase | Status |
|-------------|-------|--------|
| SHOP-01 | Phase 36 | Complete |
| SHOP-02 | Phase 38 | Pending |
| SHOP-03 | Phase 38 | Pending |
| SHOP-04 | Phase 38 | Pending |
| DONE-01 | Phase 38 | Pending |
| DONE-02 | Phase 36 | Complete |
| DONE-03 | Phase 38 | Pending |
| ITEM-01 | Phase 38 | Pending |
| ITEM-02 | Phase 38 | Pending |
| ITEM-03 | Phase 36 | Complete |
| ITEM-04 | Phase 38 | Pending |
| ITEM-05 | Phase 36 | Complete |
| FILT-01 | Phase 38 | Pending |
| FILT-02 | Phase 38 | Pending |
| FILT-03 | Phase 38 | Pending |
| MGMT-01 | Phase 38 | Pending |
| MGMT-02 | Phase 38 | Pending |
| MGMT-03 | Phase 38 | Pending |
| SYNC-01 | Phase 37 | Pending |
| SYNC-02 | Phase 37 | Pending |
| SYNC-03 | Phase 37 | Pending |
| SYNC-04 | Phase 38 | Pending |
| SYNC-05 | Phase 37 | Complete |
| SYNC-06 | Phase 37 | Pending |
| NAV-01 | Phase 38 | Pending |
| NAV-02 | Phase 38 | Pending |
| NAV-03 | Phase 39 | Pending |

**Coverage:**
- v1 requirements: 27 total
- Mapped to phases: 27 ✓
- Unmapped: 0 ✓

| Phase | Requirements assigned |
|-------|----------------------|
| Phase 36 | DONE-02, ITEM-03, ITEM-05, SHOP-01, SYNC-05 (data layer + domain + import guard) |
| Phase 37 | DONE-01 (use-case logic), DONE-03 (use-case logic), ITEM-01, ITEM-02, ITEM-04, MGMT-01 (use-case logic), MGMT-02 (use-case logic), MGMT-03 (use-case logic), SYNC-01, SYNC-02, SYNC-03, SYNC-05 (sync apply), SYNC-06 (use cases + sync integration) |
| Phase 38 | SHOP-02, SHOP-03, SHOP-04, DONE-01 (UI animation), DONE-03 (UI button), FILT-01, FILT-02, FILT-03, ITEM-01 (form UI), ITEM-02 (form UI), ITEM-04 (form UI), MGMT-01 (swipe UI), MGMT-02 (batch UI), MGMT-03 (gesture gate UI), NAV-01, NAV-02, SYNC-04 (presentation shell + UI widgets) |
| Phase 39 | NAV-03 (i18n parity + goldens + smoke test) |

---
*Requirements defined: 2026-06-07 (milestone v1.6 购物清单)*
*Last updated: 2026-06-07 — traceability revised for 4-phase consolidated roadmap (Phases 36-39); all 27 requirements mapped; SYNC-05/D7 reconciled with D-03 (completedAt column override, sticky-complete merge rule)*
