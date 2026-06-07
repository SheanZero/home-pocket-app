# Feature Research: Shopping List (v1.6)

**Domain:** Shopping list / to-buy-list feature inside a local-first family accounting app (dual-ledger: 日常/悦己)
**Researched:** 2026-06-07
**Confidence:** HIGH — dominant patterns verified across AnyList, OurGroceries, Bring!, Listonic, and general mobile UX research

---

## Locked Decisions (Do Not Re-Question)

These are fixed by pre-research user decisions (D1–D4). Every feature below is evaluated with these as constraints:

- **D1** — Public / Private as top segmented control (two independent lists, not a per-item visibility flag)
- **D2** — Context-aware FAB on the shopping tab routes to add-item screen
- **D3** — Pure list: completing an item only checks it off, no transaction linkage
- **D4** — Add-item form includes: name (required), ledger (日常/悦己), category, tags, note, quantity, estimated price

---

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist in any shopping list. Missing these makes the feature feel unfinished regardless of other qualities.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| **Tap to check off item** | Every shopping list app uses single-tap on item row or checkbox; the primary gesture | LOW | Entire row tappable (not just a small checkbox). Animate the check (strikethrough + muted opacity). AnyList, Bring!, OurGroceries all use tap-to-complete. |
| **Checked items sort to bottom** | Universal expectation in modern apps — completed items should not clutter active items. D locked this. | LOW | Already locked (D). Place a visual divider between active and completed sections. Completed section is collapsible (LOW complexity add-on). |
| **One-tap "clear all completed"** | Standard affordance in every shopping app; users expect a bulk-remove button when the completed section has items | LOW | Already locked (D). Show only when completed section is non-empty. Require confirmation dialog (one-liner: "Clear X completed items?"). |
| **Add item with name** | Core CRUD | LOW | Name is the only required field. All others optional (D4). |
| **Edit item** | Tap-to-edit after creation; standard list management | LOW | Reuse same form sheet as add-item. |
| **Swipe-to-delete single item** | iOS/Android convention for quick row removal | LOW | Destructive swipe (red background, trash icon). Confirm with "Delete item?" dialog or rely on swipe-and-release pattern. Match v1.4 list swipe-delete convention for app consistency. |
| **Batch delete (multi-select)** | Users managing many items (post-shopping cleanup) expect select-all + delete | MEDIUM | Long-press to enter selection mode (industry standard: iOS Files, Apple Reminders, OurGroceries). Bottom action bar appears with "Delete (N)" button. "Select All" toggle at top. Confirm with dialog. |
| **Public / Private segmented control** | Locked (D1). Users of family apps expect a clear public vs private split | LOW | Already locked. Top-of-screen segmented control. Each segment is a fully independent list. |
| **Filter bar** | Users with many items expect filtering; mirrors the existing v1.4 list pattern in the app | MEDIUM | Filter dimensions: ledger (日常/悦己/All) + category + tags + completed/active. Chip bar pattern matches existing `ListSortFilterBar`. One-tap clear. |
| **Empty state per list** | Both public and private lists start empty; clear guidance needed | LOW | Three variants: (1) empty private list, (2) empty public list (solo user), (3) empty public list (family joined). Each answers "what to do next" with a CTA. Matches v1.4 `ListEmptyState` 3-variant pattern. |
| **Context-aware FAB** | Locked (D2). Tab-contextual FAB is the primary add-entry point | LOW | On shopping tab: FAB opens add-item screen. Other tabs: FAB opens transaction entry. Already decided. |
| **Item name as primary display** | The item name must be the largest, most prominent text in the row | LOW | Category emoji + item name headline. Quantity and estimated price as secondary. Ledger color badge as tertiary. |
| **Item quantity display** | Locked (D4). Users adding "3x milk" or "500g flour" expect quantity visible on the row | LOW | Show inline on tile: "×3" or just the number beside the item name. If quantity is 1 or null, omit the quantity display to reduce clutter. |
| **Estimated price display** | Locked (D4). Users entering a price budget expect it visible on the tile | LOW | Show estimated price inline. Format via existing `NumberFormatter` (locale-aware ¥/$/€). |

### Differentiators (Competitive Advantage)

Features that go beyond the expected. Should align with the app's core privacy + family-trust values.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **Estimated total (per-list subtotal)** | A running total of estimated cost across all active (unchecked) items is the most-requested missing feature in Bring! and OurGroceries. Privacy-respecting — purely local calculation. | MEDIUM | Display at bottom of active section or in list header. Formula: `Σ (estimatedPrice × quantity)` for all active items. Update reactively. Omit items without an estimated price from the sum (show "estimated" label to set expectation). |
| **Dual-ledger item coloring** | Items tagged 日常 vs 悦己 get ledger-color accents. Unique to this app — no competitor has this. Reinforces the app's core dual-ledger identity even in the shopping feature. | LOW | Use existing `palette.daily` / `palette.joy` accent colors as a left-border or dot badge on each item tile. Zero new infrastructure. |
| **Category + tags from existing tree** | Reusing the app's 19-L1 category tree + tags makes shopping items first-class members of the accounting vocabulary. No competitor does this. | MEDIUM | Category selection reuses existing `CategorySelectionScreen`. Tags reuse existing tag system. Dependency: category tree and tag repository must be accessible from `shopping_list` feature domain. |
| **Per-item family attribution (who added)** | On the public list, showing which family member added each item prevents duplication and builds trust. 68% of unstructured family list users report weekly duplication caused by unclear ownership. | MEDIUM | Tie each item's `addedByBookId` to the existing family member display name + avatar emoji (already in shadow books). Show attribution chip on item tile, public list only. Private list: no attribution. |
| **Ledger filter maps to Joy/Daily budget intent** | Filtering the shopping list by ledger (悦己 = joy purchases I'm planning) directly connects shopping planning to the app's happiness metric. No competitor supports this. | LOW | Pure filter logic. UI reuses the ledger chip pattern from `ListSortFilterBar`. |
| **Sort by category (group items)** | Grouping items by category (produce together, household together) is a shopping-efficiency win. AnyList and Listonic both support this. | MEDIUM | In-memory grouping by `categoryId` after fetch, similar to v1.4 day-group headers. Category groups displayed with collapsible group headers. Completed section remains unsorted (chronological). |
| **Name autocomplete from item history** | Suggesting previously added item names as the user types reduces friction for repeat shoppers. AnyList's most-praised UX feature. | MEDIUM | Store a `shopping_item_names` local history (simple string list in SharedPreferences or a lightweight table). Suggest matching names on each keystroke in the name field. Max 8 suggestions. No network call — fully local and privacy-respecting. History is NOT shared across public/private lists. |

### Anti-Features (Explicitly Skip)

Features to deliberately not build for v1.6. Each has a reason grounded in locked decisions, ADRs, or scope discipline.

| Feature | Why Requested | Why Skip | What to Do Instead |
|---------|---------------|----------|--------------------|
| **Completion creates transaction** | "I bought it, auto-record expense" seems logical | Locked out by D3. Would violate the pure-list contract and require amount-entry UX at check-off time — a different product entirely. | Keep lists pure. If user wants to record an expense, use the normal FAB on other tabs. |
| **Gamification: streaks / badges** | "Completed 10 lists this week!" | Hard-blocked by ADR-012. No streaks, no badges, no achievement unlocks cross-milestone. | No shopping-list gamification whatsoever. |
| **Quantity autocomplete with unit parsing ("500g")** | Voice or text parsing of "500 grams of flour" into quantity=500 + unit="g" + name="flour" | MEDIUM-HIGH complexity; unit normalization (g/kg/L/ml/個/本) requires locale-aware parsing similar to the voice number parser. No user has requested this explicitly. | Accept raw text in the quantity field as-is. Quantity is a free-text or numeric field only. Defer to a future voice-for-shopping feature. |
| **Real-time push notifications when family member adds item** | "Notify me when 妈妈 adds milk" | Requires APNS/FCM notification payload routing for shopping events — a non-trivial addition to the sync pipeline. | Family member additions appear when user next opens the public list (sync on open). Same behavior as v1.4 transaction list. |
| **Barcode / QR scan to add items** | OurGroceries offers barcode scanning | Requires camera + product database or network lookup. Breaks local-first + privacy values if calling a product API. | Name autocomplete + category selection for quick item identification. |
| **Multiple shopping lists (beyond Public/Private)** | "I want a separate list for Costco vs Supermarket" | D1 locks the model to exactly two lists. Adding a third requires new list-management UI and a fundamentally different data model. | Users can use tags or categories to distinguish store-specific items within the public list. |
| **List templates / recurring items** | "Auto-add milk every week" | Requires scheduled background tasks, template management, and conflict handling. High complexity for an unproven use case. | Name autocomplete history reduces re-add friction. |
| **Sort by store / aisle** | Bring! and AnyList offer store-aisle mapping | Requires a store model + aisle assignment per item — a second metadata dimension on top of the existing category tree. Scope explosion. | Category grouping as a proxy for aisle-based sorting. |
| **Price history / price tracking** | "Show me the price trend for milk" | No external data source; manual price history requires persistence layer. OurGroceries users have been requesting price tracking for 3+ years with no implementation — that reveals the complexity. | Estimated price field records the user's budget estimate at add-time only. Sufficient for running total. |
| **"I'm going shopping" mode / streamlined checkout UI** | Some apps switch to a check-off-only mode | An extra UX mode adds cognitive overhead. The main list with completed-to-bottom IS the shopping mode. | Default list view is already optimized for the shopping experience. |
| **Drag-to-reorder items (manual order)** | Users of Bring! and OurGroceries often drag items to match store layout | Drag-and-drop on mobile conflicts with swipe-delete gestures and must interact correctly with completed-to-bottom. High complexity, diminishing returns given category-grouping covers 80% of the use case. | Category grouping sort covers store-layout needs. |
| **Item images / photos** | "Add a photo so I know what brand to buy" | Requires photo storage, display, and privacy handling for synced images in the E2EE pipeline. Out of proportion for v1.6. | Notes field handles brand guidance ("organic only", "Jake's favorite brand"). |
| **Sharing list with non-family members (guest link)** | "Share my shopping list with a friend" | The public list syncs through the family_sync pipeline which is family-scoped (join code, not open link). | Public list is family-only. |
| **Text search within shopping list** | Power users with 30+ items may want search | A single shopping list rarely exceeds 20-30 items; the filter bar handles category + ledger narrowing. Full-text search adds a text field to an already-dense chip bar. | Filter by category or tags. Defer search if users organically report finding items difficult. |

---

## Feature Dependencies

```
[Public list tab]
    └──requires──> [family_sync pipeline]  (existing — reuse)
    └──requires──> [ShoppingItem Drift table + DAO]  (new in v1.6)
    └──enhances──> [per-item family attribution]  (uses existing shadow books)

[Private list tab]
    └──requires──> [ShoppingItem Drift table + DAO]  (new in v1.6, same table, list_type column)
    └──independent of──> [family_sync pipeline]  (private items never sync)

[Add-item form]
    └──requires──> [ShoppingItem Drift table + DAO]
    └──requires──> [CategorySelectionScreen]  (existing — reuse)
    └──requires──> [Tag system]  (existing — reuse)
    └──requires──> [LedgerType selector]  (existing — reuse `LedgerTypeSelector` widget)

[Estimated total / subtotal]
    └──requires──> [quantity + estimated price fields on ShoppingItem]  (D4, locked)
    └──computes──> [Σ (estimatedPrice × quantity) for active items only]

[Filter bar]
    └──requires──> [ShoppingItemFilterState Freezed model]  (new)
    └──requires──> [ledger field on ShoppingItem]  (from D4)
    └──enhances──> [category filter — requires category tree access]
    └──mirrors──> [ListFilterState + ListSortFilterBar]  (reuse chip pattern)

[Batch delete]
    └──requires──> [selection mode state — ephemeral provider]  (new)
    └──requires──> [ShoppingItem DAO deleteMany]  (new DAO method)
    └──conflicts with──> [swipe-to-delete]  (disable swipe while in selection mode)

[Name autocomplete history]
    └──requires──> [item-name history store — SharedPreferences or lightweight table]  (new)
    └──independent of──> [category/tag system]

[Sort by category]
    └──requires──> [category field on ShoppingItem]  (optional field, from D4)
    └──enhances──> [group headers per category]  (mirrors v1.4 ListDayGroupHeader pattern)

[Check-off / completed-to-bottom]
    └──requires──> [isCompleted boolean + completedAt timestamp on ShoppingItem]  (new)
    └──requires──> [completed section divider widget]  (new)
    └──blocks──> [clear all completed]  (must exist before clear CTA is shown)
```

### Dependency Notes

- **Public list requires family_sync pipeline:** The public list's items must be wrapped in the existing E2EE sync payload format. New `ShoppingItem` objects need a sync-compatible serialization path. This is the highest-risk dependency — verify that the existing sync pipeline's `apply` stage can accept a new entity type without breaking transaction sync.
- **Filter bar mirrors v1.4 ListSortFilterBar:** Do not fork the chip pattern. The filter state model (`ShoppingItemFilterState`) should be a new Freezed class modeled on `ListFilterState` but scoped to shopping item fields.
- **Batch delete conflicts with swipe-delete:** When selection mode is active (long-press triggered), disable all swipe-delete recognizers. Exit selection mode on tap-outside or explicit "Cancel" button.
- **Estimated total requires null-safe quantity × price:** Many items will have neither quantity nor price. The subtotal calculation must handle partial metadata gracefully — skip items without estimated price; treat quantity=null as 1.
- **Category selection reuses existing screen:** `CategorySelectionScreen` is currently accessed from `TransactionDetailsForm`. The shopping item form must be able to invoke the same screen. This is a presentation-layer dependency, not a domain one.

---

## UX Patterns — Detailed Decisions

These resolve non-obvious UX choices where research has a clear answer.

### Check-Off Interaction

**Decision: single tap on the item row triggers check-off.**

- OurGroceries also offers a "press and hold" option to reduce accidental checks, but this is an advanced setting. AnyList uses simple tap. For v1.6: tap anywhere on the item row (except the edit icon area) = check off.
- Animate: 200ms strikethrough appears on the item name, row fades to ~50% opacity, item smoothly slides to the bottom of the completed section.
- Un-checking: tap a completed item → it animates back to the active section, inserted at top of active section.

### Completed-to-Bottom Composition with Filters

**Decision: completed items sort to bottom within the current filter view.**

If a filter is active (e.g., ledger=joy), the completed section shows only completed Joy items, active section shows only active Joy items. The active/completed split is preserved regardless of filter state.

"Clear all completed" clears ALL completed items in the current list (public or private), ignoring the current filter. The user's intent when tapping "clear all completed" is to wipe the done section entirely, not a filtered subset.

### Batch-Select UX

**Decision: long-press to enter selection mode; floating bottom bar for actions.**

- Long-press any item row → enter selection mode. The long-pressed item is auto-selected (count = 1). All rows show checkboxes. A bottom action bar appears with "Select All" and "Delete (N)" CTA in error color.
- "Delete (N)" requires confirmation dialog: "Delete 5 items? This cannot be undone." with Cancel / Delete buttons.
- Tap-outside any item row OR explicit "Cancel" button in the action bar to exit selection mode.
- Batch mode is delete-only. Batch check-off is deliberately excluded (adds confusion; check-off is a one-by-one action).

### Filter Bar Structure

**Chip order (left-to-right):** `All / 日常 / 悦己` → `Category` → `Active/All` → `[Clear]`

- Ledger chips: same 3-chip pattern as `ListSortFilterBar` (All / 日常 / 悦己). Reuse existing chip widget.
- Category: opens bottom sheet (same `CategoryFilterSheet` pattern from v1.4), scoped to categories present on at least one item in the current list.
- Active/All toggle: by default shows ALL items (active at top, completed at bottom). Toggle to "Active only" to hide completed section.
- Tags filter: deferred to P2 (not in v1.6 unless tags see heavy use on shopping items).
- Clear chip: appears when any filter is active. One-tap clears all filters.
- NO text search in v1.6 — shopping lists are rarely large enough to need full-text search. Defer if user requests it.
- NO sort-field selector chip in v1.6 — default sort (insertion order for active, chronological for completed) is sufficient. Category-grouping as a toggle, not a sort chip.

### Item Tile Layout

```
[ledger-color left border] [category emoji] Item Name                [edit icon]
                           Qty: ×2 · Est. ¥450       [member chip if public]
```

- Left border color: `palette.daily` or `palette.joy` (if ledger set); neutral border if no ledger
- Category emoji: from existing category tree (same as v1.4 `ListTransactionTile`)
- Item name: primary text, `AppTextStyles.body` weight
- Qty and estimated price: secondary text, `AppTextStyles.caption`; omit if both null
- Completed: name gets strikethrough + full row at ~50% opacity
- Member chip: public list only, visible when family is joined; shows `memberAvatarEmoji + memberDisplayName` (same shadow books data as v1.4)
- Edit icon: right edge, tappable, does NOT trigger check-off

### Running Estimated Total

**Show as a sticky row at the top of the active section (or bottom of screen):**

```
見積合計 ¥3,200 (12 点のうち8点に価格あり)
```

- Include only active (unchecked) items in the sum
- Show count of priced items vs total active items
- Format via existing `NumberFormatter` (locale-aware ¥/$/€)
- Show only when at least one active item has an estimated price
- Hide when no active items exist or no prices are set

### Duplicate Item Detection

**Decision: warn, do not block.**

When the user types a name that exactly matches (case-insensitive) an existing active item in the same list, show a non-blocking inline hint below the name field:

`"牛乳" is already on your list`

With two tappable options: "Add anyway" (proceeds) / "Go to item" (dismisses form, scrolls to the existing item).

This matches AnyList's approach: prevent duplication via suggestion, not hard block.

---

## MVP Definition

### Launch With (v1.6 — this milestone)

All table stakes plus high-value, low-to-medium complexity differentiators.

- [x] Tap to check off (animate + move to completed section)
- [x] Checked items sort to bottom + visual divider between active and completed
- [x] One-tap "clear all completed" (with confirmation) — locked D
- [x] Add item: name + optional ledger/category/tags/note/quantity/estimated price (D4)
- [x] Edit item (same form sheet)
- [x] Swipe-to-delete single item (confirm, matches v1.4 pattern)
- [x] Batch delete via long-press selection mode + bottom bar + confirmation
- [x] Public / Private segmented control (D1)
- [x] Public list syncs via existing family_sync pipeline
- [x] Filter bar: ledger chips + category + active/all toggle + clear
- [x] Empty states (3 variants per list type)
- [x] Context-aware FAB (D2) — already locked
- [x] 待办→购物清单 rename across zh/ja/en ARB
- [x] Per-item family attribution chip on public list tile
- [x] Dual-ledger color accent (left border on item tile — near-zero complexity)
- [x] Estimated total / running subtotal (high value, main unmet need in all competitors)

### Add After Validation (v1.x)

- [ ] Name autocomplete from item history — add when users report friction re-adding common items
- [ ] Sort by category (group headers) — add when users have 15+ items and report list feels unordered
- [ ] Tag filter chip — add when users actively use tags on shopping items
- [ ] Duplicate item detection (warn on exact-match name) — add when duplicate complaints arise
- [ ] Collapsible completed section — add if completed section grows large and clutters view

### Future Consideration (v2+)

- [ ] Voice-add shopping item — requires voice pipeline extension to a new entity type
- [ ] APNS push for family additions to public list — after family_sync is stable at scale
- [ ] Category-group drag reorder — after category grouping is validated in use
- [ ] Price history per item name — after estimatedPrice field has been used for 1+ months

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Tap to check off + completed-to-bottom | HIGH | LOW | P1 |
| Clear all completed | HIGH | LOW | P1 |
| Add item form (D4 fields) | HIGH | MEDIUM | P1 |
| Public/Private segmented control | HIGH | LOW | P1 |
| Public list sync (family_sync reuse) | HIGH | MEDIUM | P1 |
| Filter bar (ledger + category + status) | HIGH | MEDIUM | P1 |
| Empty states | HIGH | LOW | P1 |
| Context-aware FAB | HIGH | LOW | P1 |
| Batch delete (long-press mode) | MEDIUM | MEDIUM | P1 |
| Swipe-to-delete | MEDIUM | LOW | P1 |
| Estimated total / running subtotal | HIGH | MEDIUM | P1 |
| Dual-ledger color accent on tiles | MEDIUM | LOW | P1 |
| Per-item family attribution | MEDIUM | LOW | P1 |
| 待办→购物清单 rename (ARB) | LOW | LOW | P1 |
| Name autocomplete history | MEDIUM | MEDIUM | P2 |
| Sort by category (group headers) | MEDIUM | MEDIUM | P2 |
| Tag filter | LOW | LOW | P2 |
| Duplicate item detection | LOW | LOW | P2 |
| Voice add item | HIGH | HIGH | P3 |
| Push notifications for family additions | LOW | HIGH | P3 |
| Category-group drag reorder | LOW | HIGH | P3 |
| Price history | LOW | HIGH | P3 |

---

## Competitor Feature Analysis

| Feature | AnyList | Bring! | OurGroceries | Our Approach |
|---------|---------|--------|--------------|--------------|
| Check-off UX | Single tap (default); hold configurable | Tap | Configurable: tap / hold | Single tap; entire row is tap target |
| Completed-to-bottom | Yes | Yes | Yes (configurable) | Yes, fixed to bottom (D locked) |
| Clear all completed | Yes | Yes | Yes (batch delete crossed-off) | Yes with confirmation dialog |
| Quantity | Yes | Yes (visual) | Yes | Yes (D4 locked) |
| Estimated price | No (paid tier only) | No (missing for 3+ years) | No (most-requested missing feature) | Yes (D4) — differentiator |
| Running total | Paid tier only | No | No | Yes — strongest differentiator vs competitors |
| Batch delete | Yes (multi-select) | Limited | Yes | Yes via long-press selection mode |
| Filter | By store, category | By category | By category | By ledger + category + status |
| Sort by category | Yes | Yes (drag category order) | Yes | Yes (v1.6 sort option) |
| Drag-to-reorder items | Yes | Yes (category level) | Yes | Deferred — category grouping covers it |
| Family sharing | Yes (real-time) | Yes (real-time) | Yes (real-time) | Yes (family_sync pipeline, public list) |
| Per-item attribution | No | No | No | Yes — differentiator |
| Dual-ledger tagging | No | No | No | Yes — unique to this app |
| Autocomplete history | Yes (flagship feature) | No | No | P2 (deferred from v1.6) |
| Duplicate detection | Yes (scroll to existing) | No | No | P2 (warn, not block) |
| Offline-first | No (requires internet) | No | No | Yes (SQLCipher + local Drift) — core differentiator |
| Privacy | Cloud-dependent | Ad-supported, tracks users | Cloud-dependent | Local-first, E2EE sync — core differentiator |

---

## Sources

- [AnyList feature overview — Getting Started](https://help.anylist.com/articles/getting-started/)
- [AnyList autocomplete icons](https://help.anylist.com/articles/autocomplete-icons/)
- [AnyList recent items / history](https://help.anylist.com/articles/recent-items/)
- [OurGroceries User Guide — sorting and crossed-off behavior](https://www.ourgroceries.com/user-guide)
- [Bring! collaborative features](https://www.getbring.com/en/features/collaborative)
- [SmartCart: comparison of Listonic, Bring!, AnyList, OurGroceries](https://smartcartfamily.com/en/blog/grocery-apps-comparison)
- [Eleken: Bulk action UX guidelines](https://www.eleken.co/blog-posts/bulk-actions-ux)
- [Baymard Institute: Autocomplete design patterns](https://baymard.com/blog/autocomplete-design)
- [LogRocket: Swipe-to-delete UX](https://blog.logrocket.com/ux-design/accessible-swipe-contextual-action-triggers/)
- [NNGroup: Checkboxes design guidelines](https://www.nngroup.com/articles/checkboxes-design-guidelines/)
- [Family Tools App — per-item attribution](https://familytoolsapp.com/solutions/lists)
- [ListAIse — real-time family sync patterns](https://www.listaise.com/docs/sharing-lists)

---

*Feature research for: Shopping List feature (v1.6) inside Home Pocket (まもる家計簿)*
*Researched: 2026-06-07*
