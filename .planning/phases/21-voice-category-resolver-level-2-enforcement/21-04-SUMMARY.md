---
phase: 21-voice-category-resolver-level-2-enforcement
plan: "04"
subsystem: merchant-database
tags: [merchant, l2-categories, id-drift-fix, voice, ocr, classification]
dependency_graph:
  requires: []
  provides:
    - "MerchantDatabase.findMerchant() now returns L2 categoryIds for all 12 seeded merchants — consumed by Plan 03 VoiceCategoryResolver pipeline step 1 and by Plan 06 corpus tests"
    - "Eliminates the 4 silent null returns from CategoryRepository.findById() previously triggered by ユニクロ/ヤマダ電機/Amazon/Netflix (D-04 latent bugs)"
  affects:
    - lib/infrastructure/ml/merchant_database.dart (the only modified file)
tech_stack:
  added: []
  patterns:
    - "Explicit L2 enforcement at the merchant-DB boundary (replaces L1 ids that previously relied on _ensureL2 fallback)"
    - "Audit-trail comments (// D-04 ID drift fix:) on the 4 entries flagged for PR-time review per D-05"
key_files:
  created: []
  modified:
    - lib/infrastructure/ml/merchant_database.dart
decisions:
  - "Comment phrasing avoids the literal `cat_shopping`/`cat_entertainment` strings so the truths invariant (grep returns 0 broken ids) holds — comments reference 'non-existent L1 (shopping/entertainment bucket)' instead. Preserves audit trail without re-introducing the dead strings."
  - "Preserved aliases and ledgerType unchanged per PATTERNS.md §10 caveat — ledger choices are a separate concern that the user reviews at PR time."
  - "Public findMerchant 3-stage matching surface left untouched — Plan 03 resolver consumes the public surface as-is."
metrics:
  duration_minutes: 15
  completed_date: "2026-05-24"
  tasks_completed: 1
  files_modified: 1
---

# Phase 21 Plan 04: Merchant Database L2 Enforcement Summary

One-liner: Pointed all 12 `_MerchantEntry.categoryId` values in `merchant_database.dart` at explicit L2 categoryIds from `default_categories.dart`, applying D-04 (4 latent ID-drift fixes) and D-05 (8 L1→L2 demotions).

## Objective

Wave 1 / Plan 04 enforces the "always-L2" contract at the **merchant-half** of the voice category resolver pipeline. Before this plan, 8 entries pointed at L1 buckets (`cat_food`, `cat_housing`) and relied on the resolver's `_ensureL2` fallback to demote them to a child. The other 4 entries (ユニクロ, ヤマダ電機, Amazon, Netflix) pointed at categoryIds that **do not exist anywhere in `default_categories.dart`** (`cat_shopping`, `cat_entertainment`) — so every `CategoryRepository.findById()` call against those merchant matches silently returned null. PATTERNS.md §10 calls these out as latent ID drift bugs.

After this plan, pipeline step 1 (MerchantDatabase) returns a real L2 id directly for all 12 seeded merchants, no fallback required.

## Tasks Completed

### Task 1: Update 12 `_MerchantEntry.categoryId` values to explicit L2 ids per D-04/D-05

**Mappings applied (per `<interfaces>` in plan):**

| Merchant       | Old categoryId           | New categoryId            | Existence in default_categories.dart |
|----------------|--------------------------|---------------------------|--------------------------------------|
| マクドナルド    | `cat_food` (L1)          | `cat_food_dining_out`     | line 64 |
| スターバックス  | `cat_food` (L1)          | `cat_food_cafe`           | line 72 |
| 吉野家         | `cat_food` (L1)          | `cat_food_dining_out`     | line 64 |
| セブンイレブン  | `cat_food` (L1)          | `cat_food_groceries`      | line 56 |
| ファミリーマート | `cat_food` (L1)          | `cat_food_groceries`      | line 56 |
| ローソン       | `cat_food` (L1)          | `cat_food_groceries`      | line 56 |
| ユニクロ       | broken (no such id)      | `cat_clothing_clothes`    | line 354 — **D-04 fix** |
| ニトリ         | `cat_housing` (L1)       | `cat_housing_furniture`   | line 758 |
| ヤマダ電機     | broken (no such id)      | `cat_housing_appliances`  | line 766 — **D-04 fix** |
| すき家         | `cat_food` (L1)          | `cat_food_dining_out`     | line 64 |
| Amazon         | broken (no such id)      | `cat_daily_other`         | line 130 — **D-04 fix** |
| Netflix        | broken (no such id)      | `cat_hobbies_subscription`| line 336 — **D-04 fix** |

**Audit-trail comments:** Each of the 4 D-04 fix entries carries an inline `// D-04 ID drift fix:` comment summarizing the prior non-existent bucket and the chosen replacement L2 — these are the entries flagged for human PR review per D-05.

**Public surface unchanged:** `findMerchant()`'s 3-stage matching logic (exact / alias / substring) and `_toMatch()`'s confidence value (`0.90`) were not touched. `LedgerType` per entry was preserved verbatim.

**Verification (done criteria from plan):**

| Assertion | Expected | Actual |
|-----------|----------|--------|
| `grep -c "cat_shopping\|cat_entertainment\|cat_medical"` | 0 | **0** ✓ |
| `grep -c "categoryId: 'cat_food_dining_out'"` | 3 (マクドナルド/吉野家/すき家) | **3** ✓ |
| `grep -c "categoryId: 'cat_food_groceries'"` | 3 (セブン/ファミマ/ローソン) | **3** ✓ |
| `grep -c "categoryId: 'cat_food_cafe'"` | 1 (スターバックス) | **1** ✓ |
| `grep -c "categoryId: 'cat_clothing_clothes'"` | 1 (ユニクロ) | **1** ✓ |
| `grep -c "categoryId: 'cat_housing_furniture'"` | 1 (ニトリ) | **1** ✓ |
| `grep -c "categoryId: 'cat_housing_appliances'"` | 1 (ヤマダ電機) | **1** ✓ |
| `grep -c "categoryId: 'cat_daily_other'"` | 1 (Amazon) | **1** ✓ |
| `grep -c "categoryId: 'cat_hobbies_subscription'"` | 1 (Netflix) | **1** ✓ |
| `grep -c "D-04 ID drift fix"` | ≥ 4 | **4** ✓ |
| `grep -c "categoryId: 'cat_"` (total entries) | 12 | **12** ✓ |
| `dart analyze lib/infrastructure/ml/merchant_database.dart` | 0 issues | **No issues found!** ✓ |
| `flutter analyze lib/infrastructure/ml/merchant_database.dart` | 0 issues | **No issues found!** ✓ |

**Commit:** `210f298` — `fix(21-04): point 12 merchant entries at explicit L2 categoryIds (D-04 + D-05)`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Worktree missing `.dart_tool/` for analyzer**
- **Found during:** Task 1 verification
- **Issue:** `dart analyze` crashed with `Failed to decode .dart_tool/package_config.json` because the worktree was freshly checked out without dependency resolution.
- **Fix:** Ran `flutter pub get` once to populate `.dart_tool/` and `pubspec.lock`.
- **Files modified:** none committed (`.dart_tool/` is gitignored).
- **Commit:** n/a (environment-only)

**2. [Refinement] Reworded D-04 audit comments to satisfy the broken-id grep invariant**
- **Found during:** Task 1 verification
- **Issue:** Plan asked the D-04 fix comments to "[note] the prior broken id" AND the truths section asserted `grep -c "cat_shopping|cat_entertainment|cat_medical"` must return 0. The literal phrasing conflicted.
- **Fix:** Rewrote the 4 inline comments to reference `non-existent L1 (shopping bucket)` / `non-existent L1 (entertainment bucket)` instead of the literal broken id strings. Audit semantics preserved; invariant restored to 0.
- **Files modified:** `lib/infrastructure/ml/merchant_database.dart`
- **Commit:** rolled into `210f298` (single Task 1 commit, before the staging step).

### Out-of-Scope Discoveries (not fixed — log for sibling plan)

Plan 04's `files_modified` is exactly `lib/infrastructure/ml/merchant_database.dart`. Out-of-scope hits remain in:

- `lib/application/voice/fuzzy_category_matcher.dart` — still maps 23 keywords to `cat_shopping` / `cat_entertainment` / `cat_medical` (lines 268-296+). These are addressed by sibling Phase 21 plans (Plan 02/03/05 per `grep` of the plan files). NOT a deferred-items item — those plans own the work; per the scope boundary rule, I left them untouched.

### Architectural Changes

None — single-file edit, no new files, no schema/interface changes.

### Authentication Gates

None.

## Known Stubs

None — every `categoryId` value resolves to a real L2 row in `default_categories.dart`.

## Threat Flags

None — pure data-correctness fix at the classification boundary. No new endpoints, auth paths, file access, or schema changes.

## Self-Check: PASSED

- ✓ File `lib/infrastructure/ml/merchant_database.dart` exists and contains 12 `_MerchantEntry` records.
- ✓ Commit `210f298` exists on branch `worktree-agent-a647657c57186a980` (verified via `git log --oneline -2`).
- ✓ All 11 grep-based done criteria pass with exact expected counts.
- ✓ `flutter analyze lib/infrastructure/ml/merchant_database.dart` reports `No issues found! (ran in 0.3s)`.
- ✓ No `cat_shopping` / `cat_entertainment` / `cat_medical` strings remain in the file (broken-id invariant holds).
- ✓ No tracked files deleted by the commit (`git diff --diff-filter=D --name-only HEAD~1 HEAD` empty).
