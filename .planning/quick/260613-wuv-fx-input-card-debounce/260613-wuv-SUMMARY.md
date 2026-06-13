---
phase: quick-260613-wuv
plan: 01
subsystem: accounting / entry-ui
tags: [foreign-currency, fx-card, debounce, scroll-region, add-screen, ADR-019]
requires:
  - "_AddScreenForeignCard (existing)"
  - "CurrencyLinkedEditFields (existing)"
  - "conversionRateProvider (keyed, P41/P42-07)"
provides:
  - "FX card relocated into ADD-screen scroll region with EDIT-screen card chrome (WUV-01)"
  - "Debounced (~300ms) FX provider-key/JPY-reseed feed (WUV-02)"
affects:
  - "lib/features/accounting/presentation/screens/manual_one_step_screen.dart"
tech_stack:
  added: []
  patterns:
    - "Timer-based input debounce mirroring voice_input_screen.dart precedent"
    - "Live-vs-debounced split: SAVE path reads live amount, display/provider-key reads debounced"
    - "context.palette card chrome (ADR-019) — palette.card / radius 14 / palette.borderDefault"
key_files:
  created: []
  modified:
    - "lib/features/accounting/presentation/screens/manual_one_step_screen.dart"
decisions:
  - "Single atomic commit for both tasks: Task 1 references _debouncedMinorUnits (defined by Task 2); committing Task 1 alone would not compile"
  - "Clearing amount to 0 collapses the card synchronously (no stale spinner) rather than waiting out the 300ms window"
metrics:
  duration: "~6min"
  completed: 2026-06-13
  tasks: 3
  files: 1
---

# Quick 260613-wuv: FX Input Card — Scroll Region + Debounce Summary

Moved the ADD-screen foreign 汇率/换算/汇率日期 block into the scroll region with EDIT-screen card chrome, and added a ~300ms input debounce so the FX card stops flickering on every keystroke — while keeping the save path on the live amount.

## What Changed

### WUV-01 — FX card into scroll region with EDIT-screen chrome
- Removed the pinned `Padding(horizontal:16) > _AddScreenForeignCard` block that previously sat between `AmountDisplay` and the `Expanded(SingleChildScrollView)`.
- The `SingleChildScrollView`'s child is now a `Column(crossAxisAlignment: stretch)` whose first child (conditional) is the FX card and whose second child is the unchanged `TransactionDetailsForm`. A `SizedBox(height: 8)` separates them when the card is present.
- The FX card is wrapped in the same chrome the EDIT host's `_formCard` uses: `Container(decoration: BoxDecoration(color: palette.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: palette.borderDefault)))`. No extra horizontal padding (the scroll view already supplies `horizontal:16`); no inner padding (matches edit — `CurrencyLinkedEditFields` carries its own inset).
- Result: only `AmountDisplay` + `EntryModeSwitcher` stay pinned; the FX card scrolls with category/date/merchant.

### WUV-02 — Debounced FX input feed
- Added two State fields: `int _debouncedMinorUnits = 0;` and `Timer? _fxDebounce;` (imported `dart:async`).
- `_syncAmountToForm()` now calls `_scheduleFxDebounce()` AFTER the live `_pushForeignTriple()`. The new helper cancels any pending timer, and:
  - if `_originalMinorUnits == 0` → collapses `_debouncedMinorUnits` to 0 synchronously (card unmounts immediately on clear/full-delete, no stale spinner);
  - otherwise → schedules a 300ms `Timer` that recomputes the live value and `setState`s `_debouncedMinorUnits` only when it actually changed.
- Card MOUNT GUARD and the card's `originalMinorUnits` ARG now read `_debouncedMinorUnits` (was the live `_originalMinorUnits`), so the keyed `conversionRateProvider` re-resolves only on the debounced value → no per-keystroke loading flash.
- `dispose()` cancels `_fxDebounce` before `super.dispose()`.

### Save-path invariant preserved
- `_pushForeignTriple()` is untouched — it still reads the LIVE `_originalMinorUnits` (at the entry and in the staleness guard). An immediate Save after typing persists the freshly-entered amount; the debounce affects display/provider-key only, never persistence.

### CURR-04 (JPY-native) byte-identical
- The FX card renders only in the `_isForeign` branch; the JPY early-return in `_syncAmountToForm` is unchanged and the debounce scheduler is never reached for JPY. JPY entry has no card and no debounce side-effects.

## Deviations from Plan

None — plan executed as written. The two tasks were combined into a single git commit because Task 1's markup references `_debouncedMinorUnits` (a field introduced by Task 2); a Task-1-only commit would not compile. All Task 1 and Task 2 actions were applied exactly as specified.

## Verification

- `flutter analyze` (whole project): **No issues found** (0 issues).
- `flutter analyze` (file): **No issues found**.
- `test/widget/.../manual_one_step_screen_test.dart` + `manual_one_step_foreign_triple_test.dart` + `test/unit/.../manual_one_step_screen_foreign_push_stale_test.dart`: **17/17 passed**.
- `test/integration/features/accounting/manual_save_entry_source_test.dart`: **2/2 passed**.
- No add-screen GOLDEN test exists (confirmed by planner) → no golden re-baseline performed.

## Note for human

The debounce introduces a ~300ms delay before the JPY 換算 updates while typing — this is intended (anti-flicker). Saving immediately uses the live amount, so there is no data loss.

## Self-Check: PASSED

- FOUND: lib/features/accounting/presentation/screens/manual_one_step_screen.dart
- FOUND: commit d98f7e92
