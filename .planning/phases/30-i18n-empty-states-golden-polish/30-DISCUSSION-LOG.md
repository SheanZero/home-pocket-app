# Phase 30: i18n + Empty States + Golden Polish - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-31
**Phase:** 30-i18n-empty-states-golden-polish
**Areas discussed:** Golden baseline scope, Empty-state polish, Untranslated copy, Coverage & CI gate

---

## Golden baseline scope — which widgets

| Option | Description | Selected |
|--------|-------------|----------|
| 4 stable widgets | tile, day-group header, sort/filter bar, empty state; skip calendar (flaky) + sheet | |
| All 6 widgets | everything incl. calendar header + category sheet | ✓ |
| Empty states only | just list_empty_state | |

**User's choice:** All 6 widgets.
**Notes:** Calendar header (table_calendar) flakiness acknowledged; addressed via determinism work rather than exclusion.

## Golden baseline scope — locale/theme coverage

| Option | Description | Selected |
|--------|-------------|----------|
| ja-only, light | 1 golden/widget, home_hero precedent | |
| All 3 locales, light | ja+zh+en/widget — verifies cross-language layout (the i18n phase) | ✓ |
| ja, light + dark | per_category precedent | |

**User's choice:** All 3 locales, light theme.

## Empty-state polish — presentation

| Option | Description | Selected |
|--------|-------------|----------|
| Keep as-is | current icons + copy, just verify + lock golden | |
| Refine copy/icons | revisit wording/icons before locking | ✓ |

**User's choice:** Refine copy/icons.
**Notes:** Claude proposed a 3-state design with refined trilingual copy + `event_busy_outlined` for the new day-empty state. User initially picked "Approve states, tweak copy", then replied "no change" — copy locked verbatim as proposed.

## Empty-state polish — filtered-state nuance

| Option | Description | Selected |
|--------|-------------|----------|
| Keep single message | one filtered-empty message for any filter | |
| Distinguish day-filter | distinct message when only a day-filter is active | ✓ |

**User's choice:** Distinguish day-filter.
**Notes:** Resolved into 3-state branching (no-data / day-empty / filtered) with two distinct clear actions ("show full month" vs "clear filters").

## Untranslated copy — listMineOnly wording

| Option | Description | Selected |
|--------|-------------|----------|
| 自分のみ / 仅自己 | concise, fits toggle-chip | ✓ |
| 自分の記録 / 仅本人 | more explicit/formal | |

**User's choice:** ja 自分のみ · zh 仅自己 · en Mine only.

## Untranslated copy — sweep scope

| Option | Description | Selected |
|--------|-------------|----------|
| List tab only | fix only lib/features/list/, log nothing elsewhere | |
| List tab + log app-wide | fix list tab, document app-wide leaks as inventory | ✓ |

**User's choice:** List tab + log app-wide (document, don't fix, outside the list tab).

## Coverage & CI gate — coverage threshold

| Option | Description | Selected |
|--------|-------------|----------|
| ≥70% (roadmap SC) | honor phase success criterion | ✓ |
| ≥80% (global rule) | stricter global CLAUDE.md default | |

**User's choice:** ≥70% — roadmap SC governs for this polish phase.

## Coverage & CI gate — golden CI behavior

| Option | Description | Selected |
|--------|-------------|----------|
| Hard-fail, stabilize first | hard-fail + pin fonts/textScale, disable animations, freeze table_calendar date | ✓ |
| Hard-fail, exclude calendar | exclude calendar header from CI golden gate | |
| Tolerance threshold | allow per-pixel diff tolerance | |

**User's choice:** Hard-fail, stabilize first.

---

## Claude's Discretion

- Golden test file organization, fixture construction, determinism harness mechanics (follow existing `test/golden/*.dart` conventions).
- ARB key insertion order and `@`-metadata formatting.

## Deferred Ideas

- App-wide hardcoded-string inventory — documented this phase, fixed in a future i18n-cleanup phase.
- Dark-theme goldens for the list tab — out of scope this phase; candidate for a future visual-QA phase.
