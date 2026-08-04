---
sketch: 004
name: onboarding-pin-setup
question: "How should the initial-settings security card present and launch required 4-digit PIN setup?"
winner: "A"
tags: [onboarding, security, pin, layout]
---

# Sketch 004: Onboarding PIN Setup

## Design Question

When App Lock is enabled and the user chooses a 4-digit PIN, how should the
initial-settings screen communicate the unfinished requirement and launch the
double-entry PIN flow without turning the security card into a tall nested card?

## How to View

Open `.planning/sketches/004-onboarding-pin-setup/index.html`.

## Variants

- **A: Compact action row** — keeps both unlock methods visible and folds the missing-PIN state into the selected PIN row.
- **B: Guided security card** — separates method choice from a warmer, branded PIN task card with one strong action.
- **C: Focused bottom sheet** — keeps the settings card short and moves PIN entry into an immediate app-owned numeric sheet.

## Decision

**A: Compact action row** was selected on 2026-08-04. Production and the V16
mockup use the same compact row for both pending and configured states; only
the status copy, dot color, and Set/Update action change.

## What to Look For

- Which version makes “PIN is required before starting” obvious without feeling heavy?
- Does the method selection remain understandable after PIN is selected?
- Is the setup action prominent enough without introducing an unrelated blue CTA?
- Which transition feels most natural after editing the nickname field?
