---
phase: quick-260602-u5x
plan: 01
subsystem: home/presentation
tags: [ui, best-joy, ticket-fusion, goldens, i18n]
requires: []
provides:
  - "Best Joy ticket × calendar-tile fusion layout (Region 6 of home_hero_card)"
  - "DateFormatter.formatCalendarMonth / formatCalendarDay"
affects:
  - lib/features/home/presentation/widgets/home_hero_card.dart
  - lib/infrastructure/i18n/formatters/date_formatter.dart
  - test/golden/goldens/home_hero_card_*.png
tech-stack:
  added: []
  patterns:
    - "ClipRRect(14) + IntrinsicHeight + Row(stretch) for non-uniform ticket border (accent bar + rounded body)"
    - "CustomPainter dashed vertical perforation"
    - "Locale date patterns kept in DateFormatter (CJK-whitelisted), not UI widgets"
key-files:
  created: []
  modified:
    - lib/features/home/presentation/widgets/home_hero_card.dart
    - lib/infrastructure/i18n/formatters/date_formatter.dart
    - test/golden/goldens/home_hero_card_all_neutral_cta_ja.png
    - test/golden/goldens/home_hero_card_family_dark_ja.png
    - test/golden/goldens/home_hero_card_family_light_ja.png
    - test/golden/goldens/home_hero_card_joy_target_0_ja.png
    - test/golden/goldens/home_hero_card_joy_target_50_ja.png
    - test/golden/goldens/home_hero_card_joy_target_100_ja.png
    - test/golden/goldens/home_hero_card_joy_target_over_100_ja.png
    - test/golden/goldens/home_hero_card_single_dark_ja.png
    - test/golden/goldens/home_hero_card_single_light_ja.png
    - test/golden/goldens/home_hero_card_thin_sample_ja.png
decisions:
  - "Month-band text uses palette.background (near-white light / #0C1719 dark) instead of a raw Color literal, satisfying COLOR-01"
  - "M月/MMM month pattern lives in DateFormatter (CJK-whitelisted i18n formatter), not the UI widget, satisfying the CJK UI scanner"
  - "Punch-hole notches skipped (plan-OPTIONAL) — dashed perforation already carries the ticket-tear read; logged to deferred-items"
metrics:
  duration: ~25m
  completed: 2026-06-02
  tasks: 3
  source-files: 2
  golden-files: 10
---

# Phase quick-260602-u5x Plan 01: Best Joy Ticket × Calendar Fusion Summary

Rebuilt Region 6 (Best Joy strip) of `home_hero_card.dart` into the user-approved
"融合·轻" ticket × calendar-tile fusion: a rounded ticket with a 6px joy accent bar,
a left calendar tile carrying the date, a middle category-icon + name over amount,
and a right frameless satisfaction seal separated by a dashed perforation.

## What Was Built

- **`_bestJoyTicket`** — ticket chrome via `ClipRRect(14)` + `IntrinsicHeight` +
  `Row(stretch)`[6px joy accent bar, tinted joy body with thin uniform joy border].
  Works around Flutter's `borderRadius` + non-uniform `Border` prohibition.
- **`_bestJoyCalendarTile`** — 48px calendar tile (joy month band / 22px tabular day
  number in joyText / muted weekday) with a soft joy shadow; muted "—" placeholder
  variant for the empty/all-neutral state (no month band, stable size).
- **`_DashedVLine` + `_DashedVLinePainter`** — vertical dashed perforation
  (dash 3 / gap 3, strokeWidth 1.5, `joy @ 0.38`), `shouldRepaint` on color only.
- **VALUE state** now: calendar tile → middle (parentCategoryIconFromId @15 + L2 name
  ellipsis @15 / amount @18 joyText via AppTextStyles.amountSmall) → dashed
  perforation → frameless seal (`_satisfactionPillIcon` @24 over `_satisfactionPillLabel`
  @10, satisfactionPillRose), all inside the ticket chrome.
- **EMPTY / all-neutral state** reuses the ticket chrome with the muted "—" calendar
  placeholder + guide text; no perforation, no seal.
- **`DateFormatter.formatCalendarMonth` / `formatCalendarDay`** added to the
  i18n formatter (canonical home for locale date patterns).
- **Region-6 doc comment** rewritten to describe the ticket fusion and cite 260602-u5x
  (reverses the s9g flat decision, user-approved).
- Removed now-dead `_satisfactionPill` (framed pill) and `_bestJoyIconTile`.

## Verification

- `flutter analyze` on modified files → **0 issues**. Project-wide analyze shows only
  4 pre-existing, out-of-scope issues (2 `onReorder` deprecations in
  `category_selection_screen.dart` — present at base commit; 2 in generated `build/`
  firebase artifacts). Logged to deferred-items.
- `flutter test` → **2294 passed**, full suite green (including re-baselined goldens
  and the COLOR-01 + CJK-UI architecture scanners).
- 10 `home_hero_card_*` golden masters re-baselined; **NO `list_transaction_tile`
  drift** (`git status --porcelain test/golden/goldens/ | grep list_transaction_tile`
  → empty).
- Visual sanity-check of regenerated light/dark single + all-neutral masters confirms:
  accent bar, calendar tile, middle category/amount, frameless seal, dashed perforation
  (value); muted "—" tile + guide text, no seal (empty); dark uses deeper joy-bg alpha.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 — Bug] COLOR-01 raw-literal gate failure (own change)**
- **Found during:** Task 3 (full test run after goldens).
- **Issue:** Initial `_bestJoyCalendarTile` used `const Color(0xFF0C1719)` for the
  dark month-band text — a raw hex literal in a feature file, which the COLOR-01
  architecture scanner forbids.
- **Fix:** Replaced with `palette.background` (semantically the page background
  sitting on the joy band: near-white light / `#0C1719` dark). Dropped the `isDark`
  branch + `Colors.white` literal entirely.
- **Files modified:** `home_hero_card.dart`
- **Commit:** a3842cf6

**2. [Rule 1 — Bug] CJK UI scanner failure (own change)**
- **Found during:** Task 3 (full test run).
- **Issue:** The inline `'M月'` month pattern in the widget's `_bestJoyMonthLabel`
  helper tripped the hardcoded-CJK UI scanner (CJK literals must live in whitelisted
  i18n formatters, not UI widgets).
- **Fix:** Removed the local helper; added `DateFormatter.formatCalendarMonth` /
  `formatCalendarDay` to the whitelisted i18n formatter and called those instead.
  This also better follows CLAUDE.md ("dates via DateFormatter").
- **Files modified:** `home_hero_card.dart`, `date_formatter.dart`
- **Commit:** a3842cf6

**3. [Rule 3 — Blocking] Dead code from the refactor**
- **Found during:** Task 2.
- **Issue:** `_satisfactionPill`, `_bestJoyIconTile`, and the `DateFormatter` import
  became unused after the ticket rewrite (analyzer `unused_*` warnings).
- **Fix:** Removed the two dead widgets; re-added `DateFormatter` import (still needed
  for the new formatter calls + weekday).
- **Commit:** 031a05b5 (removals), a3842cf6 (import re-add)

## Known Stubs

None. No placeholder data, no hardcoded empty values flowing to UI. The empty-state
"—" calendar glyph and guide text are intentional design states, not stubs.

## Deferred (see 260602-u5x-deferred-items.md)

- Punch-hole notches (撕口缺口) — plan-OPTIONAL; skipped because clean implementation
  on a ClipRRect-rounded ticket would need a bespoke CustomClipper, and the dashed
  perforation already carries the ticket read.
- 4 pre-existing, out-of-scope analyzer issues (not introduced by this task).

## Self-Check: PASSED

- FOUND: `lib/features/home/presentation/widgets/home_hero_card.dart`
  (contains `_DashedVLine`, `_bestJoyTicket`, `_bestJoyCalendarTile`)
- FOUND: `lib/infrastructure/i18n/formatters/date_formatter.dart`
  (contains `formatCalendarMonth` / `formatCalendarDay`)
- FOUND commit b563aba9 (Task 1 primitives)
- FOUND commit 031a05b5 (Task 2 wiring)
- FOUND commit a3842cf6 (Task 3 goldens + arch-gate fixes)
