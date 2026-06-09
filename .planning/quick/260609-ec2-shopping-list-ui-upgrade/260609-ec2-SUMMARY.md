---
phase: quick-260609-ec2
plan: 01
subsystem: shopping_list (presentation)
tags: [flutter, riverpod, ui, shopping-list, i18n, golden]
requires:
  - shopping_items schema v20 (quantity column, default 1) — pre-existing, no migration
  - ShoppingFilter / ListType providers (keepAlive)
  - ToggleItemCompletedUseCase / ShoppingItemFormScreen
provides:
  - shoppingReorderModeProvider (keepAlive bool Notifier) — manual reorder UI mode
  - EC2 tile interaction model (leading circle toggle / body-tap edit / right qty / gated drag)
  - filter bar left-aligned chips + trailing ≡/✓ reorder toggle
affects:
  - lib/features/shopping_list/presentation/widgets/shopping_item_tile.dart
  - lib/features/shopping_list/presentation/widgets/shopping_filter_bar.dart
tech-stack:
  added: []
  patterns:
    - keepAlive bool Notifier for transient-but-tab-persistent UI mode
    - gesture-lock pattern (reorderMode || batchActive) suppressing toggle/edit/swipe
key-files:
  created:
    - lib/features/shopping_list/presentation/providers/state_shopping_reorder.dart
    - lib/features/shopping_list/presentation/providers/state_shopping_reorder.g.dart
    - docs/worklog/20260609_1106_shopping_list_ui_upgrade.md
  modified:
    - lib/features/shopping_list/presentation/widgets/shopping_item_tile.dart
    - lib/features/shopping_list/presentation/widgets/shopping_filter_bar.dart
    - lib/l10n/app_en.arb
    - lib/l10n/app_ja.arb
    - lib/l10n/app_zh.arb
    - lib/generated/app_localizations*.dart
    - test/widget/.../shopping_item_tile_test.dart
    - test/widget/.../shopping_filter_bar_test.dart
    - test/golden/goldens/shopping_item_tile_*.png (18)
    - test/golden/goldens/shopping_filter_bar_*.png (6)
decisions:
  - Completion circle fill = item ledger accent (daily/joy), null → neutral daily green (Claude's Discretion, ADR-019 palette)
  - Reorder mode suppresses toggle/edit/swipe — drag only (Claude's Discretion)
  - No screen-level change needed — drag gating lives entirely in the tile (handle only rendered in reorder mode)
metrics:
  duration: ~55m
  completed: 2026-06-09
  tasks: 3
  commits: 3 (code) + docs
---

# Quick Task 260609-ec2: Shopping List UI Upgrade Summary

Upgraded the shopping list to a to-do-style interaction model — leading circular completion toggle, tap-the-body-to-edit, right-aligned quantity badge, and an explicit ≡ drag-reorder mode — while keeping home-pocket's 全部 / 日常·悦己 / 分类 dual-ledger filter system intact. Pure presentation-layer change; schema stays v20 (no Drift migration).

## What Was Built

**Task 1 — reorder provider + tile refactor** (commit `13055cbd`)
- New `shoppingReorderModeProvider` (`@Riverpod(keepAlive: true)`, `bool build() => false`, `toggle()`/`exit()`) — transient UI mode that survives IndexedStack tab switches, never persisted.
- Tile gains a leading 24px circular completion toggle (44px hit target, `ValueKey('toggle-<id>')`): unfilled = neutral outline + faint check; filled = ledger-accent fill + white check. Tapping the circle toggles completion.
- Tile body `onTap` now opens `ShoppingItemFormScreen` (replaces the old full-row toggle, D-domain#3).
- Edit chevron removed; quantity moved to the trailing edge as a `${quantity}×` badge, rendered only when `quantity > 1` (D-1). estimatedPrice stays in the secondary row.
- Drag handle (`ReorderableDragStartListener`) is gated on `reorderMode && isActive` — hidden in normal mode (D-2). Reorder/batch mode locks toggle, body-edit, and swipe-delete (Dismissible.direction = none).

**Task 2 — filter bar** (commit `22bd25a8`)
- Chip cluster wrapped in `Expanded(SingleChildScrollView)` (left-aligned); trailing 44px `InkWell` pinned to the right edge toggles `shoppingReorderModeProvider`: `Icons.reorder` (≡) enters, red `Icons.check` (✓) exits.
- Reorder mode adds a `Icons.drag_indicator` (≡) prefix to the 全部 chip, the 日常·悦己 segmented control, and the category chip.

**Task 3 — tests + goldens + worklog** (commit `8d08819d`)
- Tile widget test rewritten: circle-triggered toggle, body-tap-does-not-toggle, body opens form, chevron gone, ×N badge (qty>1 only), reorder-mode drag handle + gesture-lock assertions (19 green).
- Filter bar widget test: ≡→✓ reorder toggle + reorder-mode chip prefixes (9 green).
- 24 affected goldens re-baselined (18 tile + 6 filter bar).
- Worklog written per project rule.

## i18n
Added `shoppingToggleComplete` / `shoppingEnterReorderMode` / `shoppingExitReorderMode` to all 3 ARBs (en/ja/zh), `flutter gen-l10n` succeeded. Reused existing `shoppingReorderItem` for the drag handle.

## Verification
- `flutter analyze` — 0 issues (whole project).
- Shopping tile widget test: 19/19 green. Filter bar widget test: 9/9 green.
- 24 affected goldens re-baselined and passing.
- `provider_graph_hygiene_test` (confirms reorder provider is a valid `state_*.dart` sibling + keepAlive intact) and `hardcoded_cjk_ui_scan_test` both green.
- `grep 0xFF` on tile + filter bar = 0 (all colors via `context.palette`, ADR-019).
- Full `flutter test`: 2513 pass / 1 out-of-scope audit-script flake (see Deferred Issues).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Regenerated stale provider .g.dart files**
- **Found during:** Task 1 (after `build_runner build`).
- **Issue:** `repository_providers.g.dart` and `state_shopping_filter.g.dart` carried docstrings out of sync with their source (stale generated output committed at base). AUDIT-10 would flag these as stale.
- **Fix:** Committed the regenerated output alongside Task 1.
- **Files modified:** both `.g.dart` files.
- **Commit:** `13055cbd`.

## Deferred Issues

**OOS-1: `test/scripts/merge_findings_test.dart` idempotency flake under full-suite parallelism.**
- Fails only in the full parallel suite (1 of 2514); passes 8/8 in isolation.
- Pre-existing audit-tooling subprocess flake with zero coupling to this task's presentation-layer changes.
- Not fixed per scope boundary. Logged in `deferred-items.md`.

## Known Stubs
None. The reorder provider is fully wired (filter bar toggles it, tile reads it); no placeholder/empty data paths introduced.

## Self-Check: PASSED
- FOUND: lib/features/shopping_list/presentation/providers/state_shopping_reorder.dart
- FOUND: lib/features/shopping_list/presentation/providers/state_shopping_reorder.g.dart
- FOUND: docs/worklog/20260609_1106_shopping_list_ui_upgrade.md
- FOUND commit: 13055cbd (feat tile)
- FOUND commit: 22bd25a8 (feat filter bar)
- FOUND commit: 8d08819d (test + goldens + worklog)
