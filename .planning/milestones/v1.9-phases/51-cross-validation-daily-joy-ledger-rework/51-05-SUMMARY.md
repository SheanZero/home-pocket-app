---
phase: 51-cross-validation-daily-joy-ledger-rework
plan: 05
subsystem: dual-ledger
tags: [ledger, dual-ledger, seed, category-service, invariant-tests, LEDGER-02]
status: complete
requires:
  - 51-04 (CreateTransactionUseCase ledger re-route to CategoryService.resolveLedgerType)
provides:
  - _defaultLedgerConfigs with 14 user-approved L2 ledger overrides (D-18)
  - D-19 reachable-L2 non-null hard gate
  - D-20 ledgerType == resolveLedgerType(categoryId) invariant (create + change-category)
  - D-21 merchant ledgerHint never-read invariant
affects:
  - lib/shared/constants/default_categories.dart
tech_stack:
  added: []
  patterns:
    - "L2-inherits-L1 ledger with selective overrides (conservative D-16 bias)"
    - "ledger = pure function of final category id (never merchant hint)"
key_files:
  created:
    - test/architecture/ledger_reachable_l2_invariant_test.dart
    - test/integration/features/accounting/ledger_invariant_test.dart
    - test/unit/application/accounting/merchant_ledger_hint_never_read_test.dart
  modified:
    - lib/shared/constants/default_categories.dart
    - test/unit/shared/constants/default_categories_test.dart
decisions:
  - "D-18: user approved ALL 5 candidate L2 overrides at the blocking spot-check gate — total 14 overrides"
metrics:
  duration: continuation-session
  completed: 2026-06-24
---

# Phase 51 Plan 05: Daily/Joy Ledger Rework (LEDGER-02) Summary

Locked the single ledger source of truth with three regression gates (D-19/D-20/D-21) and expanded the L2 ledger-override set to the user-approved 14, all behind a blocking spot-check checkpoint — no schema change, the ledger is now provably a pure function of the final category id.

## What Was Built

- **D-19 reachable-L2 non-null hard gate** (`test/architecture/ledger_reachable_l2_invariant_test.dart`, commit 6444e3b0): iterates every reachable category (19 L1 + all L2) and asserts each resolves to a non-null `LedgerType` via the same direct-config-or-L1-inheritance rule `CategoryService.resolveLedgerType` uses, with a `reason:` naming the silent-daily-fallback drift it traps. Sanity-guards the 19-L1 count.
- **D-20 ledger invariant + D-21 merchant-hint-never-read** (commit e218a63d): `ledger_invariant_test.dart` asserts `ledgerType == resolveLedgerType(categoryId)` on create (daily + joy + unknown→daily fallback) and on change-category re-derive (daily→joy), with an explicit note that edit-LOAD preservation (W3/D-23, historical overrides allowed) is intentionally NOT asserted. `merchant_ledger_hint_never_read_test.dart` drives a create with a merchant `ledgerHint` set to the OPPOSITE of the category-resolved ledger and proves the persisted ledger follows the category, not the hint.
- **L2 override expansion to 14** (`_defaultLedgerConfigs`, commit ed48c006): applied the user-approved D-18 all-5 expansion on top of the existing 9.

## D-18 Override Decision (user-approved all 5)

NEW overrides added (5):
- `cat_food_drinks` → joy
- `cat_health_fitness` → joy
- `cat_health_massage` → joy
- `cat_clothing_hair` → daily
- `cat_clothing_accessories` → daily

EXISTING overrides kept unchanged (9): `cat_clothing_clothes`→daily, `cat_clothing_shoes`→daily, `cat_clothing_underwear`→daily, `cat_clothing_cleaning`→daily, `cat_social_drinks`→joy, `cat_social_gifts`→joy, `cat_special_wedding`→joy, `cat_special_movement`→joy, `cat_special_newyear`→joy.

Total = 14 L2 overrides. The three new joy overrides flip their daily L1 parent (food→daily, health→daily) to joy for the clearly enjoyment/self-investment L2s; the two new daily overrides pin enjoyment-adjacent clothing items (hair, accessories) to daily. No schema change — pure `_defaultLedgerConfigs` Dart-literal edit + re-seed.

## Verification

- `flutter analyze` = 0 issues.
- Full `flutter test` suite: **3270/3270 passed**, 0 failures (run directly, not via the empty GSD config commands).
- Targeted gates (D-19 + D-20 + D-21 + the config test): 41/41 passed after the override edit — the new overrides create no null gaps and the invariant holds (newly-overridden L2s now resolve to their override ledger).
- Schema unchanged: `grep -c 'schemaVersion =>' lib/data/app_database.dart` == 1, no migration edits.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - missing critical coverage] Extended `default_categories_test.dart` to guard the new overrides**
- **Found during:** Task 3
- **Issue:** The existing `default_categories_test.dart` ledger-override assertions covered only the original 9; the 5 newly-approved overrides had no unit guard, so a future seed regression on them would go undetected.
- **Fix:** Added `cat_clothing_hair` + `cat_clothing_accessories` to the clothing-daily override test set, and added a new `D-18: food_drinks + health fitness/massage override to joy` test asserting the 3 new joy overrides flip their daily L1 parents.
- **Files modified:** `test/unit/shared/constants/default_categories_test.dart`
- **Commit:** ed48c006

No pre-existing test asserted the OLD (L1-inherited) ledger for any of the 5 newly-overridden categories (the three tests referencing those category ids — `category_v19_dining_out_first_test.dart`, `voice_category_corpus_{zh,ja}_test.dart` — contain no ledger assertions), so no assertion-flip was required.

## Self-Check: PASSED

- FOUND: `lib/shared/constants/default_categories.dart` (14 overrides present)
- FOUND: `test/architecture/ledger_reachable_l2_invariant_test.dart`
- FOUND: `test/integration/features/accounting/ledger_invariant_test.dart`
- FOUND: `test/unit/application/accounting/merchant_ledger_hint_never_read_test.dart`
- FOUND commit 6444e3b0 (D-19 gate)
- FOUND commit e218a63d (D-20 + D-21 gates)
- FOUND commit ed48c006 (14-override seed + test extension)
