# Phase 28: Transaction Tile + Sort/Filter Bar - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-30
**Phase:** 28-Transaction Tile + Sort/Filter Bar
**Areas discussed:** Category filter cardinality, Sort control interaction, Bar composition & search, List structure

---

## Category filter cardinality

| Option | Description | Selected |
|--------|-------------|----------|
| Multi-select (match SC#5) | Extend categoryId:String? → Set<String>; update provider AND-compose + bottom-sheet to multi-select. Honors SC#5 literal. | ✓ |
| Single-select (match built state) | Keep single categoryId; bottom sheet single-select. Conflicts with SC#5 literal. | |
| You decide | Weigh effort vs spec fidelity. | |

**User's choice:** Multi-select (match SC#5)
**Notes:** Phase 25 D-02 had pre-flagged multi-category as "deferred to Phase 28"; this phase is the decision point. State extension is localized (one field type + provider filter + sheet UI).

### Follow-up: L1/L2 selection semantics

| Option | Description | Selected |
|--------|-------------|----------|
| L2 leaves only | Only leaf L2 categories checkable; L1 just expands. | |
| L1 selects all its children | Checking L1 selects all its L2 children; tristate when partial. | ✓ |
| You decide | Recommend L2-leaves-only. | |

**User's choice:** L1 selects all its children (with tristate for partial)

### Follow-up: active category indication in bar

| Option | Description | Selected |
|--------|-------------|----------|
| Count chip | Single 'Categories (N)' chip; tap reopens sheet. | ✓ |
| One chip per category | Removable chip per selection; can overflow. | |
| You decide | Recommend count chip. | |

**User's choice:** Count chip

---

## Sort control interaction

| Option | Description | Selected |
|--------|-------------|----------|
| Menu + direction arrow | Tap chip → menu of 3 fields; separate arrow toggles asc/desc. | ✓ |
| Cycle-on-tap chip | One chip cycles field per tap; second target toggles direction. | |
| You decide | Recommend menu + direction arrow. | |

**User's choice:** Menu + direction arrow

### Follow-up: where to indicate active sort state

| Option | Description | Selected |
|--------|-------------|----------|
| On the chip itself | Chip shows field name + direction arrow. | |
| Checkmark in the menu | Active field checkmarked in menu; chip stays generic 'Sort'. | ✓ (initial) |
| You decide | Recommend on-the-chip. | |

**User's choice (initial):** Checkmark in the menu

### Reconciliation: SC#4 requires active field + direction *in the bar*

| Option | Description | Selected |
|--------|-------------|----------|
| Chip shows field + checkmark in menu | Chip label = active field, arrow beside it, menu also checkmarks. Passes SC#4. | ✓ |
| Keep generic 'Sort' chip | Only direction in bar; field menu-only. Risks failing SC#4 literal. | |
| You decide | Recommend chip-shows-field. | |

**User's choice:** Chip shows field + checkmark in menu
**Notes:** Claude flagged that menu-only field indication would fail SC#4's literal "active field visually indicated in the sort bar." User accepted the reconciliation — sort chip must display the current field name, not a generic 'Sort' label.

---

## Bar composition & search

### Text search UI placement

| Option | Description | Selected |
|--------|-------------|----------|
| Search icon expands | Icon expands inline field on tap; collapses when empty. | ✓ |
| Always-visible search field | Persistent TextField row; consumes vertical space. | |
| You decide | Recommend expanding search icon. | |

**User's choice:** Search icon expands

### Bar layout & scroll behavior

| Option | Description | Selected |
|--------|-------------|----------|
| One scrollable chip row, pinned | Single horizontally-scrollable chip row pinned under calendar. | (Claude's discretion lean) |
| Wrapped multi-row, scrolls with list | Chips wrap; whole bar scrolls away. | |
| You decide | Recommend single pinned scrollable row. | ✓ |

**User's choice:** You decide → Claude chose single horizontally-scrollable chip row pinned under the calendar header.

### Clear-all control (FILTER-04)

| Option | Description | Selected |
|--------|-------------|----------|
| Conditional clear chip | Appears only when a filter/search is active; calls clearAll(). | ✓ |
| Always-present clear button | Persistent, greyed when nothing active. | |
| You decide | Recommend conditional clear chip. | |

**User's choice:** Conditional clear chip

---

## List structure

| Option | Description | Selected |
|--------|-------------|----------|
| Grouped by day | Date section header per day; rows show time. | ✓ |
| Flat list | Continuous list; every row carries its DateFormatter date. | |
| You decide | Recommend grouped-by-day. | |

**User's choice:** Grouped by day
**Notes:** Claude flagged SC#1 reconciliation — with grouping, the DateFormatter date lives on the day header (rows show time); header-date is treated as satisfying SC#1.

### Follow-up: day-filter active appearance

| Option | Description | Selected |
|--------|-------------|----------|
| Single day group | One day-group header + its rows. Consistent with grouped view. | ✓ |
| Flat rows, no header | Just that day's rows, no header. | |
| You decide | Recommend single day group. | |

**User's choice:** Single day group

---

## Claude's Discretion

- Bar layout details (single pinned scrollable chip row chosen; spacing/order/visuals per Wa-Modern theme).
- Swipe-delete observable details (red trash background, AlertDialog confirm, right-swipe no-op — research-locked; animation/threshold/SnackBar copy per existing Dismissible usages).
- Soul-ledger satisfaction icon reuse on list tile (HomeTransactionTile already supports it).
- Category multi-select sheet widget construction (mirror category_selection_screen.dart, add multi-select + tristate).
- ARB keys / trilingual copy (placeholders this phase; Phase 30 finalizes).
- Empty-filter (0 rows) state structure (placeholder copy; Phase 30 polishes).
- Widget/provider test construction (ProviderContainer.test() + waitForFirstValue + Mocktail; ROW-02 hash-chain unit test).

## Deferred Ideas

- Family member attribution chip + member filter + "mine only" (FAM-01..04) → Phase 29.
- Pull-to-refresh + reactive sync auto-propagation (LIST-04) → Phase 29.
- ARB trilingual copy + empty-state copy + golden baselines (LIST-03) → Phase 30.
- Swipe-right-to-edit → deferred (research line 162); tap-to-edit sufficient.
- Advanced cross-L1 mixed hierarchy selection UI beyond L1-cascade + tristate → later milestone.
- Pagination / infinite scroll → v1.5 (Phase 24 D-02).
- Refined empty-state (illustration/guidance) → Phase 30.
