---
sketch: 006
name: home-existing-layout-redraw
question: "How should the selected warm Japanese system redraw Home without changing the shipped Flutter layout?"
winner: "C · 层次纸面"
tags: [home, faithful-redraw, existing-layout, design-system]
---

# Sketch 006: Existing Home Layout Redraw

## Design Question

Can the selected A design system improve the shipped Home visually while preserving the exact
implementation composition and interaction placement?

## Implementation Layout Preserved

1. `HeroHeader` — month picker, mode badge, settings.
2. `HomeHeroCard` — monthly total, two-ledger split, three-ring section, Best Joy ticket, optional
   family-member rows.
3. `FamilyInviteBanner` — existing vertical solo-mode invite card.
4. Recent-transactions header and `TransactionListCard`.
5. `HomeBottomNavBar` — detached pill navigation and circular FAB.

## Variants

- **A: 温润纸感** — balanced border, quiet elevation, and the canonical warm-paper system.
- **B: 克制平面** — stronger borders with no card shadow; closest to the shipped structural feel.
- **C: 层次纸面 ★ Selected** — subtle pine-tinted hero surface, larger radius, and stronger paper layering.

All variants use identical DOM order, region dimensions, data, states, and interactions. Only
surface treatment changes.

## How to View

Open `.planning/sketches/006-home-existing-layout-redraw/index.html` in a browser.

## What to Look For

Compare only surface hierarchy: whether the single integrated hero still reads clearly, whether
the three-ring and Best Joy regions remain understandable, and how much elevation the Home needs.
