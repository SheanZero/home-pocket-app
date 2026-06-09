---
status: resolved
phase: 39-i18n-golden-re-baseline-smoke-test
source: [39-VERIFICATION.md]
started: 2026-06-09T00:00:00Z
updated: 2026-06-09T00:00:00Z
---

## Current Test

[awaiting human testing]

## Tests

### 1. Visual inspection of 54 shopping golden baselines
expected: The 54 first-time golden PNGs under `test/golden/goldens/shopping_*.png` render correctly. A human must confirm, across ja/zh/en and light/dark:
- Correct locale text (買い物 / 购物 / Shopping, and all in-widget strings)
- Dual-ledger border colors per ADR-019: leaf-green `#5FAE72` for active/daily tiles, sakura-pink `#D98CA0` for completed/joy tiles
- Correct dark-mode palette (warm cream → warm dark)
- Strikethrough + 50% fade on completed tiles
- Attribution chip (🐱 Alice) on public-list tiles
- Filter bar active-chip state and batch selection header/action-bar chrome
result: [passed] Human-approved 2026-06-09 — golden baselines visually confirmed (border colors, dark mode, strikethrough, attribution chip, locale text).

## Summary

total: 1
passed: 1
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps
