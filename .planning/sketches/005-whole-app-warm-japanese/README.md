---
sketch: 005
name: whole-app-warm-japanese
question: "How does A scale coherently across every primary Home Pocket journey and state?"
winner: null
tags: [design-system, whole-app, navigation, entry, family, security]
---

# Sketch 005: Whole App — A 温润日系

## Design Question

Can the selected A direction become a coherent, accessible whole-app system while preserving the
existing information architecture, privacy model, dual-ledger semantics, and mature feature set?

## How to View

Open `.planning/sketches/005-whole-app-warm-japanese/index.html` in a browser.

## Variants / Required States

- **A1: 个人 · 浅色** — canonical baseline for primary review.
- **A2: 家庭 · 浅色** — shared-ledger and family-sync surfaces layered onto the same visual system.
- **A3: 个人 · 深色** — low-light expression with the same semantic color hierarchy.

### Home integration — Sketch 006 C

The selected **C · 层次纸面** redraw from Sketch 006 is now the canonical Home inside this
whole-app design center. It preserves the shipped Flutter composition exactly:

`HeroHeader → HomeHeroCard → FamilyInviteBanner → TransactionListCard → HomeBottomNavBar`

Only the visual surface changes: a subtly pine-tinted hero, 22px radius, stronger paper layering,
a single Joy-target ring with satisfaction and small-win support metrics, a ticket-style monthly
favorite, and a detached pill navigation plus FAB. The support stack and target ring share a fixed
100px height; its 1px divider sits at the exact 50px centerline of the ring.
All three metrics stay within the benizakura Joy family: the target ring uses the base Joy color,
satisfaction uses the deeper Joy text tone, and the small-win count uses an intermediate mix.
The satisfaction value and small-win count now share the same 16px primary-numeral size; their
supporting units remain secondary.
Personal/family and light/dark states remain connected to the same system controls.
The personal Home now uses the selected compact horizontal family invitation. It keeps the
existing warm-paper surface while exposing three distinct actions: dismiss the card, add a family
immediately, or follow the explicit `設定 › 家庭` path for later setup. Dismissing removes only the
invitation from the current Home state; choosing a personal preset restores it for prototype QA.
The Home month title now shares the same 18px/800 title style and 20px content edge as the other
main pages; Home cards therefore match the Analytics card width exactly. Its header also uses the
shared 46px height and 13px content gap, keeping title baselines and first-card positions stable
when switching between primary pages. The monthly-favorite ticket uses small arc notches at both
ends of its right-hand perforation, reinforcing the tear-off ticket metaphor without adding an
outline around the cutouts. The cutouts sit above the ticket border so the outer top and bottom
rules visibly break at the perforation instead of running through it.

### Locked Home and transaction-list baseline

The personal Home is now treated as a locked design baseline. Work moves page-by-page from the
List tab without changing the Home composition, metrics, invitation, or typography.

The List tab restores the production Flutter structure from `ListScreen`, `CalendarHeaderWidget`,
`ListSortFilterBar`, `ListDayGroupHeader`, and `ListTransactionTile`, then maps those structures to
the warm Japanese tokens. The List header keeps the earlier layout with the year/month aligned left
and a calendar picker icon aligned right. The calendar uses Monday-first weekday labels, 44px date
cells, per-day compact expense totals, day-toggle
selection, and the month/day summary rows. The pinned 44px filter bar keeps the production order:
sort field, direction, ledger chips, category sheet, search expansion, and conditional clear-all.
Transaction groups use muted 32px date headers and category-first rows with ledger badge, merchant,
amount, and chevron. Expense values display as absolute amounts without a leading minus sign.

### Locked List and analytics restoration

The List tab is now locked as the accepted baseline. The Analytics tab has been restored from the
current production `AnalyticsScreen` and `analyticsCardRegistry` rather than recomposed as a generic
dashboard. Its visible solo-mode order is fixed as:

`WithinMonthTrendCard → CategoryDonutCard (+ JoySpendDrawer) → JoyCalendarCard → SatisfactionHistogramCard`

The conditional `FamilyInsightDataCard` remains group-mode-only and is appended after those four
cards. The warm Japanese system changes only the visual surface: practical sections keep the leaf
green marker, Joy sections use benizakura, and every card shares the same 20px screen edge and paper
border treatment. Production interactions are represented in the HTML: time-window sheet, spend/
daily/Joy trend tabs (Joy has no previous-period line), category/member dimension switch, global
member filter, category drill-down, and inline calendar-day expansion.

The priority analytics refinement raises chart annotations and supporting data to 10–11px, gives
period and analysis controls a 44px touch target, and adds a single evidence-led takeaway to each
analysis block. The Joy-spend breakdown is collapsed by default so the category comparison remains
the primary scan path, while its disclosure preserves the full three-category detail on demand.
Japanese analytics terminology consistently uses `ときめき`, and the calendar keeps compact one-pixel
gaps while expanding each date target to approximately 44px on the 375px review viewport.

### Superseded Home exploration

- **H1: 环形总览** — ring progress beside the existing Joy explanation.
- **H2: 线性进度** — compact horizontal Joy progress plus a secondary satisfaction
  progress using its explicit 10-point scale.
- **H3: 数字留白** — large cumulative value with quieter supporting metrics and less chart weight.

Fixed across all three: the month uses the same sans-serif title style as following page headings,
the current `joy-story` card is preserved, and recent Home expense amounts omit plus/minus signs.

This earlier H1/H2/H3 exploration is retained for decision history but is superseded by Sketch 006
C for the whole-app Home. Satisfaction can use a linear progress because its
denominator is explicit (`8.2 / 10`). Small-win count stays `12件` rather than becoming a progress
bar because the product has no monthly small-win target; inventing one would imply gamification.
The existing `joy-story` row now has a clear “今月の悦己ストーリー” heading, a one-line purpose
explanation, and an explicit “詳しく見る” affordance for first-time users.

## Coverage

- Foundations: palette, typography, buttons, inputs, feedback, cards, navigation.
- Main shell: Home, transactions, analytics, shopping.
- Entry: manual, voice, OCR review, category selection, edit.
- Family: choice, join, group management, owner/member states.
- Setup and safety: onboarding, preferences, app lock, profile, settings, legal/sponsor.

## Constraints Preserved

- Current four-tab information architecture and context-sensitive FAB.
- Daily/Joy/Shared remain distinct; monetary text uses high-contrast variants.
- `Σ joy_contribution` is the only Joy expression; no density/ROI reintroduction.
- No discrete celebration at Joy target completion.
- App lock, E2EE, local-first, and privacy copy remain calm and explicit.
- Japanese is the default content language; layouts remain viable for zh/en expansion.

## What to Look For

Review whether the same page rhythm, color semantics, touch-target scale, and feedback language feel
consistent across very different tasks: scanning a month, entering quickly, managing a family, and
unlocking sensitive data.
