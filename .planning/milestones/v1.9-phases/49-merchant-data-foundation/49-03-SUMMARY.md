---
phase: 49-merchant-data-foundation
plan: 03
subsystem: merchant-data
status: complete
tags: [merchant-seed, const-data, ledger-derivation, hard-gate-test]
requirements_completed: [MERCH-01, MERCH-02, MERCH-05]
dependency_graph:
  requires:
    - "lib/shared/constants/default_categories.dart (L2 id set + defaultLedgerConfigs — source of truth)"
    - "lib/application/accounting/category_service.dart (resolveLedgerType precedence — parity target)"
  provides:
    - "DefaultMerchants.all (~391 authored merchant rows) + DefaultMerchant row type"
    - "deriveLedgerHint(String categoryId) -> LedgerType (single-source-of-truth ledger derivation)"
  affects:
    - "Plan 05 SeedMerchantsUseCase (iterates DefaultMerchants.all, calls deriveLedgerHint, normalizes each surface)"
tech_stack:
  added: []
  patterns:
    - "const-list-with-getter (DefaultMerchants mirrors DefaultCategories)"
    - "split-by-group const data aggregated by a single getter (each file < 800 lines)"
    - "ledger derived from category single source of truth (no second merchant->ledger map)"
key_files:
  created:
    - lib/shared/constants/default_merchants.dart
    - lib/shared/constants/merchants/merchants_convenience.dart
    - lib/shared/constants/merchants/merchants_supermarket.dart
    - lib/shared/constants/merchants/merchants_dining.dart
    - lib/shared/constants/merchants/merchants_cafe.dart
    - lib/shared/constants/merchants/merchants_daily_drugstore.dart
    - lib/shared/constants/merchants/merchants_home_electronics.dart
    - lib/shared/constants/merchants/merchants_fashion.dart
    - lib/shared/constants/merchants/merchants_transport_fuel.dart
    - lib/shared/constants/merchants/merchants_leisure_hobby.dart
    - lib/shared/constants/merchants/merchants_subscription_delivery.dart
    - lib/application/accounting/ledger_hint_deriver.dart
    - test/unit/shared/constants/default_merchants_categoryid_test.dart
    - test/unit/application/accounting/ledger_hint_derivation_test.dart
  modified: []
decisions:
  - "Split DefaultMerchants into 10 per-category-group files aggregated by DefaultMerchants.all (RESEARCH Open Q #2 — ~391 multi-field rows exceed the 800-line guideline as one file)"
  - "GMS/general-merchandisers (イオン, イトーヨーカドー) mapped to cat_food_groceries — daily-necessities is the dominant basket; recognition refinement is Phase 50's job, not the seed's"
  - "deriveLedgerHint throws StateError on unresolvable categoryId — a data-integrity bug, not a runtime-recoverable case (callers must pass gate-validated ids)"
metrics:
  merchants_authored: 391
  distinct_l2_categories_used: 36
  tasks_completed: 3
  files_created: 14
  duration_minutes: 12
  completed_date: 2026-06-23
---

# Phase 49 Plan 03: Merchant Data Foundation Summary

JWT-free pure-Dart const data plan: authored the `DefaultMerchants` seed list (391 national-chain Japanese merchants, each mapped to a verified real L2 `categoryId`) plus the `deriveLedgerHint(categoryId)` helper that derives the non-authoritative ledger hint from the single source of truth (`DefaultCategories.defaultLedgerConfigs` precedence), guarded by two hard-gate unit tests (categoryId-∈-L2 and `deriveLedgerHint == resolveLedgerType`).

## What Was Built

- **`DefaultMerchant` row type** (`default_merchants.dart`): `id` (stable `mer_<ascii_slug>`), `nameJa` (required), `nameZh?`/`nameEn?`, `aliases` (romaji + Kansai abbreviations + kana), `categoryId` (real L2). **No per-merchant ledger column** — the ledger hint is derived (D-09).
- **`DefaultMerchants.all`**: aggregates 10 per-group const lists. 391 merchants spanning the ROADMAP-enumerated national-chain spine: 便利店 / 超市 / 牛丼·拉面 / 咖啡 / ファミレス / 药妆 / 百元店 / 家电 / 服饰 / 交通IC / 加油 / 外卖 / 订阅, plus Tokyo·Osaka focus chains (Disney/USJ, regional rail, izakaya).
- **`deriveLedgerHint(String categoryId)`** (`ledger_hint_deriver.dart`): evaluates purely against the const `DefaultCategories` list (no DB round-trip). Mirrors `CategoryService.resolveLedgerType` precedence — direct config lookup (L1 / L2-override), else L1-parent inheritance. Throws `StateError` on unresolvable id.
- **Two hard-gate tests**: `default_merchants_categoryid_test.dart` (every categoryId ∈ L2 set, ids unique + `mer_`-prefixed, full-list coverage no sampling) and `ledger_hint_derivation_test.dart` (parity against the DB-backed `resolveLedgerType` using fakes seeded from the same `DefaultCategories` const data — exercises every seeded categoryId and the whole category tree).

## Task Commits

| Task | Name | Commit |
|------|------|--------|
| 1 | categoryId-L2 hard-gate + ledger parity tests (RED) | `94ef6138` |
| 2 | implement deriveLedgerHint(categoryId) | `06a86c60` |
| 3 | author DefaultMerchants (~391) + DefaultMerchant row type (GREEN) | `0976449e` |

## D-08 Derived-vs-Old-Tag Diffs (commit-time human spot-check)

The legacy 12-entry `merchant_database.dart` hand-tagged some merchants with a ledger that differs from what the category now derives. **The derived value WINS** (expected, per A4 — these are NOT bugs):

| Merchant | categoryId | Old hand-tag | Derived (wins) | Reason |
|----------|-----------|--------------|----------------|--------|
| Amazon | `cat_daily_other` | joy | **daily** | `cat_daily` L1 = daily, no L2 override |
| ヤマダ電機 | `cat_housing_appliances` | joy | **daily** | `cat_housing` L1 = daily, no L2 override |
| ユニクロ | `cat_clothing_clothes` | joy | **daily** | `cat_clothing_clothes` L2 override = daily |
| Netflix | `cat_hobbies_subscription` | joy | joy (same) | `cat_hobbies` L1 = joy, no override |
| マクドナルド | `cat_food_dining_out` | daily | daily (same) | `cat_food` L1 = daily |

All apparel merchants (cat_clothing_clothes/shoes/cleaning) derive to **daily** via L2 overrides; accessories/cosmetics/hair (no override) inherit **joy** from `cat_clothing`.

## Deviations from Plan

**1. [Rule 2 - Missing critical functionality] Expanded seed from initial 281 to 391 to meet the ~400 MERCH-02 coverage target**
- **Found during:** Task 3
- **Issue:** First authored pass produced 281 merchants — meaningfully short of the plan's "~400 national-chain spine" truth (MERCH-02 coverage requirement).
- **Fix:** Added ~110 more national chains across all spine groups (more supermarkets, drugstores, apparel, cafes, izakaya, fast food, gyms, hotels, regional rail, gas). Final: 391.
- **Files modified:** all 10 per-group files
- **Commit:** `0976449e`

**2. [Rule 1 - Lint] Fixed prefer_single_quotes on LOWRYS FARM**
- **Found during:** Task 3 verify (`flutter analyze`)
- **Issue:** `"LOWRYS FARM"` used double quotes without an apostrophe → `prefer_single_quotes` info (project requires 0 analyzer issues).
- **Fix:** changed to single quotes (legitimate apostrophe strings like `"McDonald's"`/`"Denny's"` left as-is).
- **Commit:** `0976449e`

No architectural changes; no authentication gates.

## Verification

- `flutter test` (both gate tests): **10/10 pass** — categoryId-∈-L2 hard gate + ledger parity green.
- `flutter analyze lib/shared/constants/ + ledger_hint_deriver.dart + both tests`: **0 issues**.
- `grep ledgerType|LedgerType. lib/shared/constants/default_merchants.dart + merchants/`: **0** (no per-merchant ledger column — D-09 prohibition honored).
- All group files ≤ 523 lines (under 800 guideline).
- 391 merchants, 36 distinct L2 categories used, all unique `mer_`-prefixed ids.

## Notes for Consumers (Plan 05)

`SeedMerchantsUseCase` iterates `DefaultMerchants.all`, calls `deriveLedgerHint(m.categoryId)` per merchant for the `ledger_hint` column, and normalizes each surface form (nameJa + nameZh + nameEn + each alias) via Plan 02's `normalizeMerchantKey` into `merchant_match_keys` rows. Stable `mer_` ids + `INSERT OR IGNORE` keep re-seed idempotent.

## Self-Check: PASSED
