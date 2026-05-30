# Phase 27: Calendar Header + Month Summary - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-30
**Phase:** 27-Calendar Header + Month Summary
**Areas discussed:** Per-day total display, Month nav surface, Calendar height/format, Day-filter ↔ summary

---

## Per-day total display

### Q1 — How should each day cell show its expense total?

| Option | Description | Selected |
|--------|-------------|----------|
| Compact amount | Abbreviated number under date (1.2万 / 1.2k) via NumberFormatter compact | |
| Full amount | Full formatted amount (¥1,235), may overflow 40dp cell | |
| Dot marker only | Colored dot when day has expense; figure on tap | ✓ (initial) |

**User's choice (initial):** Dot marker only.
**Notes:** Flagged conflict with ROADMAP SC#2 ("cell shows the total expense" + "no amount indicator for empty days"). Dot-only shows presence, not total → would fail SC#2. Reconciled below.

### Q1b — Reconcile dot-only preference with SC#2

| Option | Description | Selected |
|--------|-------------|----------|
| Dot + tiny amount | Dot/underline PLUS compact amount | |
| Dot only, amend SC#2 | True dot-only, requires relaxing SC#2 wording | |
| Compact amount, no dot | Drop dot, just compact amount under date | ✓ |

**User's choice:** Compact amount, no dot.
**Notes:** SC#2-compliant; readable in small cells. Resolves the conflict without amending the roadmap.

### Q2 — today / selected-day cell visual states

| Option | Description | Selected |
|--------|-------------|----------|
| Ring for selected, subtle today | Accent ring on selected; faint bg/outline on today | |
| Minimal — selected only | Only selected day emphasized; today plain | |
| You decide | Claude picks defaults from Wa-Modern + research | ✓ |

**User's choice:** You decide.
**Notes:** Captured as Claude's Discretion (likely accent ring for selected + faint today marker).

---

## Month nav surface

### Q1 — How should users move between months?

| Option | Description | Selected |
|--------|-------------|----------|
| Arrows + swipe | Prev/next chevrons + horizontal swipe; no picker | ✓ |
| Arrows + swipe + picker | Add tappable label → month/year picker (CAL-01 literal) | |
| Arrows only | Chevrons only, swipe disabled | |

**User's choice:** Arrows + swipe.
**Notes:** CAL-01's "month picker" deferred to a later milestone. Swipe is table_calendar's default — kept rather than disabled.

### Q2 — Quick way back to current month?

| Option | Description | Selected |
|--------|-------------|----------|
| Tap month label = today | Tapping month-label text jumps to current real month | ✓ |
| No shortcut | Manual arrow/swipe back | |
| You decide | Claude judges from header layout | |

**User's choice:** Tap month label = today.
**Notes:** Cheap, discoverable, no extra picker UI.

---

## Calendar height/format

### Q1 — How should the calendar size behave above the list?

| Option | Description | Selected |
|--------|-------------|----------|
| Always full month | Full grid always; list scrolls below | ✓ |
| Collapsible week/month | Toggle/swipe between full-month and week row | |
| You decide | Claude picks based on Phase 28/29 layout | |

**User's choice:** Always full month.
**Notes:** table_calendar default, no format state. Collapsibility deferred to v1.5.

---

## Day-filter ↔ summary

### Q1 — What does the summary line show when a day is selected?

| Option | Description | Selected |
|--------|-------------|----------|
| Always month total | Summary always = month total (strict SC#4) | |
| Switch to selected day | Summary swaps to selected day's total | |
| Month total + day subline | Month total always + small day-total subline when day selected | ✓ |

**User's choice:** Month total + day subline.
**Notes:** Month total always present (SC#4); day subline is additive context. Day subline reuses the calendar's per-day map (no extra query).

### Q2 — Labeling for the summary lines (ARB implications)

| Option | Description | Selected |
|--------|-------------|----------|
| Labeled both | Month: '今月の支出 ¥…'; day: '5月3日 ¥…' (~2 ARB keys) | |
| Amount-only month, labeled day | Month amount-only; day subline carries date label (~1 key) | |
| You decide | Claude picks copy + ARB keys at planning/Phase 30 | ✓ |

**User's choice:** You decide.
**Notes:** Captured as Claude's Discretion; ARB copy finalized in Phase 30 across ja/zh/en.

---

## Claude's Discretion

- today / selected-day cell visual states (accent ring + faint today marker direction).
- Summary line label/copy + ARB keys (finalized Phase 30).
- `calendarDailyTotals` family param shape `(bookId, year, month)` vs `(bookId, focusedMonth)` — must depend only on `(bookId, month)`, not filter.
- `startingDayOfWeek` (locale-aware week start, ja/zh Sunday vs ISO Monday).
- Day-tap toggle-clear logic placement (widget callback vs ListFilter helper).
- Widget/provider test construction (`ProviderContainer.test()` + `waitForFirstValue` + Mocktail).

## Deferred Ideas

- Arbitrary-month jump picker (CAL-01 literal "month picker") → later milestone.
- Family multi-book per-day total combine (CAL-02 family mode) → Phase 29 (FAM).
- Collapsible week/month format toggle → v1.5.
- ARB key trilingual copy + golden baselines → Phase 30.
- Per-day cell ledger-color split (survival/soul) → not this phase (cells are combined expense totals).
