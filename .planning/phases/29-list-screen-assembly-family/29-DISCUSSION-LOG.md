# Phase 29: List Screen Assembly + Family - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-30
**Phase:** 29-List Screen Assembly + Family
**Areas discussed:** Member row attribution, Member filter + Mine-only, Pull-to-refresh action, Calendar totals ↔ filter, Default view, Solo mode

---

## Member row attribution (FAM-02)

| Option | Description | Selected |
|--------|-------------|----------|
| Trailing chip: emoji + name | Chip mirroring ledger-tag container but different color, showing avatar emoji + short name (🐻 太郎). Research line 76/258. Most legible. | ✓ |
| Leading avatar emoji only | Compact emoji circle at row leading edge, name omitted. Relies on remembering emoji↔member. | |
| Inline emoji before text | Small emoji prefixed to merchant/category text, no chip. Lowest weight, easily missed. | |

**User's choice:** Trailing chip: emoji + name
**Notes:** Own rows stay bare (SC#3). memberTag null for own-book rows → data-driven, no UI isOwn check. Chip reuses `ListTransactionTile` tag container as a 2nd visual element with distinct color.

---

## Member filter + Mine-only controls (FAM-03 / FAM-04)

| Option | Description | Selected |
|--------|-------------|----------|
| Per-member chips + Mine chip | One chip per member + prominent 'Mine only' chip in same scroll row; single-select; Mine always visible in family mode. Matches research. | ✓ |
| Members count-chip + sheet | Single 'Members' chip opens picker sheet + separate Mine-only toggle. Avoids bar overflow with many members. | |
| Segmented All / Mine + picker | Segmented All↔Mine toggle + separate member picker chip. Prominent binary but adds distinct control type. | |

**User's choice:** Per-member chips + Mine chip
**Notes:** Single互斥单选组 — member chip = `setMemberFilter(shadowBookId)`, Mine = `setMemberFilter(ownBookId)`, All = `setMemberFilter(null)`. No second state field (reuses `memberBookId`). member filter AND-composes with ledger+category.

---

## Pull-to-refresh action (LIST-04 / SC#1)

| Option | Description | Selected |
|--------|-------------|----------|
| Reload local DB only | Re-invalidate list providers (re-query local). Relies on background sync having landed writes. Honest, cheap, no P2P hang risk. | ✓ |
| Trigger a real P2P sync round | Pull kicks a peer sync, spinner holds until settled. Most literal but risks hang/no-op when peers offline. | |
| Sync if peers reachable, else reload | Hybrid: sync when peer connection exists, else local reload. Best UX, most logic/states. | |

**User's choice:** Reload local DB only
**Notes:** Reactive Drift watch + shell sync-listener (Phase 26 D-03) already auto-propagate synced writes. Pull = reassurance + fallback for any missed rebuild. Should invalidate list + calendar providers.

---

## Calendar totals ↔ member filter (FAM-01 / SC#2)

| Option | Description | Selected |
|--------|-------------|----------|
| Always full-family combined | Calendar per-day + month totals always sum own + all shadow books regardless of member/Mine filter. Keeps provider isolated (Pitfall 3); matches SC#2 'all members combined'. | ✓ |
| Follow member / mine-only | Calendar totals reflect currently-scoped member(s). More 'consistent' but couples calendar provider to filter state, risks Pitfall 3 re-render cost. | |

**User's choice:** Always full-family combined
**Notes:** List below still filters by member; only the calendar/month total stays full-family. `calendarDailyTotals` watches only (bookIds, year, month) — never memberBookId/search/ledger.

---

## Default view (group mode)

| Option | Description | Selected |
|--------|-------------|----------|
| All members combined | memberBookId starts null — opens with full family merge. Mine-only is opt-in. Makes FAM-01 the visible default. | ✓ |
| Mine only by default | Opens scoped to own entries; widen via chip. More private but hides family merge until user acts. | |

**User's choice:** All members combined

---

## Solo mode (no family group)

| Option | Description | Selected |
|--------|-------------|----------|
| Exactly as Phase 28 | own-book only, no member chips/Mine-only/attribution. Family cluster renders only when isGroupMode true. Pull-to-refresh still works. | ✓ |
| Show Mine-only always | Keep Mine-only visible even solo (no-op). Adds dead control. Avoided per Phase 28 conditional-chip rationale. | |

**User's choice:** Exactly as Phase 28

---

## Claude's Discretion

- Member chip color scheme (distinguishable from survival/soul ledger tag; Wa-Modern theme tokens, no hardcoded hex)
- Member chip ordering/position within the horizontal-scroll bar; Mine-only chip visual emphasis (filled vs outlined)
- Long/duplicate member-name truncation strategy
- Member filter implementation layer (SQL `bookIds` narrowing vs Dart `where`) — lean toward narrowing `findByBookIds` input
- `RefreshIndicator` host widget structure + refresh spinner appearance
- ARB keys / trilingual copy (member chip, Mine-only/自分のみ/仅我的, All) — placeholder this phase, Phase 30 closes
- Widget/provider test construction (mock shadowBooksProvider + isGroupModeProvider)

## Deferred Ideas

- Multi-select member filter (Set<String> memberBookIds) — single-select this phase
- ARB trilingual copy + family/empty-state text + golden baselines → Phase 30 (LIST-03)
- Pull-to-refresh real P2P sync round / hybrid → later (needs peer connection state machine)
- Family privacy hardening (FAMILY-V2-01/02/03) → v2 backlog
- Per-day per-member color split / in-calendar member viz → not this phase
- Pagination / infinite scroll → v1.5 (Phase 24 D-02)
