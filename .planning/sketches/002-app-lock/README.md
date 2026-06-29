---
sketch: 002
name: app-lock
question: "Two separate lock surfaces — a Face ID page and a PIN page — chosen by settings; Face ID wins when both are enabled."
winner: "B"
tags: [security, lock, biometric]
---

# Sketch 002: App Lock (v2)

## Design Question
Phase 55 re-locks on cold start + foreground return. The lock is **two distinct pages**, not one mixed
screen: a **Face ID page** and a **PIN page**. Which page shows is decided by settings:
- only Face ID, or Face ID + PIN → **Face ID page** (with a "PIN で解除" escape to the PIN page on failure)
- only PIN → **PIN page** directly
- both enabled → **Face ID is preferred** (PIN is the fallback)

## How to View
open .planning/sketches/002-app-lock/index.html

## Variants (each shows Face ID page + PIN page)
- **A: 温柔抛茶感** — warm sakura gradient, large rounded Face ID glyph + scanline; PIN page same visual language.
- **B: 清爽极简** ★ **WINNER** — system-native, follows theme: a **light-mode** set + a **dark-mode** set (minimal Face ID page + standard iOS-style passcode grid each).
- **C: 混合** — warm but calm; Face ID page + PIN page with a retry counter (残り N 回).

## What to Look For
- Are the two surfaces clearly distinct yet visually consistent?
- Which tone reads as most trustworthy for a finance lock — warm (A), native-dark (B), or calm-warm (C)?
- Face ID→PIN escape affordance: ghost text (A), keypad Face ID key (B), or outline button (C)?
- App-switcher privacy mask is unified across the app (not a variant axis).
