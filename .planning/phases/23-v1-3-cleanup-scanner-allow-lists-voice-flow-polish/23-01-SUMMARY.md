---
phase: 23-v1-3-cleanup-scanner-allow-lists-voice-flow-polish
plan: 01
subsystem: voice-category-resolver, merchant-database, shared-constants
tags: [phase-21-polish, constants-dedup, merchant-database, cleanup]
requirements: []
requirements-completed: []
decisions-implemented: [D-12, D-13]
dependency-graph:
  requires: []
  provides: [kVoiceSynonymSeedEpoch, kCategoryOtherIdOverrides, merchant-db-length-guard]
  affects: [voice-category-resolver, category-keyword-preference-dao, architecture-invariant-test]
tech-stack:
  added: []
  patterns: [single-source-of-truth-constant, early-return-input-guard, tdd-red-green]
key-files:
  created:
    - lib/shared/constants/category_other_id_overrides.dart
  modified:
    - lib/shared/constants/default_synonyms.dart
    - lib/data/daos/category_keyword_preference_dao.dart
    - lib/application/voice/voice_category_resolver.dart
    - test/architecture/category_other_l2_invariant_test.dart
    - lib/infrastructure/ml/merchant_database.dart
    - test/unit/infrastructure/ml/merchant_database_test.dart
decisions:
  - "kVoiceSynonymSeedEpoch promoted from private class-static to top-level final in default_synonyms.dart; DAO imports it via show"
  - "kCategoryOtherIdOverrides in new category_other_id_overrides.dart; resolver + arch test both import from single source"
  - "D-15 IN-06 seed rows (その他/其他/other → cat_other_expense) added to DefaultVoiceSynonyms.all"
  - "lowerQuery.length < 3 guard added before substring pass in MerchantDatabase.findMerchant"
  - "Pre-existing stale category IDs in merchant_database_test.dart fixed as Rule 1 auto-fix"
metrics:
  duration: "~15 minutes"
  completed_date: "2026-05-25"
  tasks_completed: 2
  tasks_total: 2
  files_changed: 7
---

# Phase 23 Plan 01: Phase 21 Constant Dedup + Merchant DB Length Guard Summary

Single-source-of-truth constant extraction (D-12 IN-01 + IN-05) and MerchantDatabase substring-pass 3-char minimum length guard (D-13 IN-03), completing Phase 21 mechanical polish items.

## What Was Built

### Task 1.1: Extract kVoiceSynonymSeedEpoch + kCategoryOtherIdOverrides shared constants

Eliminated two constant drift sources left from Phase 21:

**D-12 IN-01 (epoch dedup):** The `DateTime(2026, 1, 1)` literal existed in both `default_synonyms.dart` (as `_epoch`, class-static, private) and `category_keyword_preference_dao.dart` (line 90, local variable). Extracted to a top-level `final DateTime kVoiceSynonymSeedEpoch = DateTime(2026, 1, 1)` in `default_synonyms.dart`. The DAO now imports it via `show kVoiceSynonymSeedEpoch`.

**D-12 IN-05 (override map dedup):** `const Map<String, String> _otherIdOverrides` was duplicated identically in both `voice_category_resolver.dart` and `test/architecture/category_other_l2_invariant_test.dart`. Created new `lib/shared/constants/category_other_id_overrides.dart` with `kCategoryOtherIdOverrides`. Both the resolver and the architecture test now import from the single source.

**D-15 IN-06 (seed expansion):** Added three seed rows to `DefaultVoiceSynonyms.all`:
- `_seed('その他', 'cat_other_expense')` — Japanese "other"
- `_seed('其他', 'cat_other_expense')` — Chinese "other"  
- `_seed('other', 'cat_other_expense')` — English "other" (v1.4+ hedge; en voice gated in v1.3)

All five edits landed in a single atomic task per RESEARCH Pitfall 5 to prevent silent literal drift.

### Task 1.2: 3-char min-length guard + D-13 regression tests

**D-13 guard:** Added `if (lowerQuery.length < 3) return null;` guard immediately before the substring `for` loop in `MerchantDatabase.findMerchant`. Single-letter and two-character queries no longer false-positive against substring matches (e.g., `'a'` was matching `'Amazon'` via `'amazon'.contains('a')`). The exact-match passes (steps 1+2) are unaffected.

**3 new regression tests (TDD RED → GREEN):**
- `D-13: findMerchant returns null for queries shorter than 3 chars` — `findMerchant('a')` and `findMerchant('ab')` return null
- `D-13: findMerchant continues to substring-match at 3 chars` — `findMerchant('mac')` still returns McDonald entry
- `D-13: Pitfall 7 regression — all merchant entries have name length >= 3` — enumerates all 12 entry names

**Rule 1 auto-fix (pre-existing test drift):** The 4 pre-existing merchant database tests had stale category IDs (`cat_shopping`, `cat_food`, `cat_entertainment` → Phase 21 D-04 updated the entries but the tests were never updated). Fixed to match current production values (`cat_daily_other`, `cat_food_dining_out`, `cat_food_cafe`, `cat_hobbies_subscription`).

## Verification Results

| Check | Result |
|-------|--------|
| `flutter analyze` (5 Task 1.1 files) | 0 issues |
| `flutter analyze` (2 Task 1.2 files) | 0 issues |
| `flutter test test/architecture/category_other_l2_invariant_test.dart` | PASS (1/1) |
| `flutter test test/unit/infrastructure/ml/merchant_database_test.dart` | PASS (8/8) |
| `grep 'DateTime(2026, 1, 1)' lib/` (DAO + synonyms paths) | 1 match (kVoiceSynonymSeedEpoch declaration only; default_categories.dart has separate pre-existing literal not in scope) |
| `grep '_otherIdOverrides' lib/ test/` | 0 matches |
| `grep 'kCategoryOtherIdOverrides' lib/ test/` | 7 matches (declaration + resolver + arch test + comments) |
| `grep 'lowerQuery.length < 3' merchant_database.dart` | 1 match |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed pre-existing stale category IDs in merchant_database_test.dart**
- **Found during:** Task 1.2 (running full test suite after adding D-13 tests)
- **Issue:** 4 pre-existing tests had category IDs from before Phase 21 D-04 (Amazon: `cat_shopping`, McDonald: `cat_food`, Starbucks: `cat_food`, Netflix: `cat_entertainment`)
- **Fix:** Updated all 4 to match current production values with Phase 21 D-04 comments
- **Files modified:** `test/unit/infrastructure/ml/merchant_database_test.dart`
- **Commit:** 024842d (included in Task 1.2 commit)

### Note on DateTime(2026, 1, 1) count

The plan acceptance criterion `grep -rn 'DateTime(2026, 1, 1)' lib/ | grep -v '^#'` returns 2 matches (not 1) because `lib/shared/constants/default_categories.dart` has its own `static final DateTime _epoch = DateTime(2026, 1, 1)` that was pre-existing and out of scope for this plan (it serves categories seeding, not voice synonyms seeding). The plan's IN-01 requirement was satisfied: the DAO no longer has a local literal; it imports from `kVoiceSynonymSeedEpoch`. The `default_categories.dart` literal is a separate concern deferred to a future plan.

## Self-Check

- [x] `lib/shared/constants/category_other_id_overrides.dart` — FOUND
- [x] `lib/shared/constants/default_synonyms.dart` — FOUND (modified)
- [x] `lib/data/daos/category_keyword_preference_dao.dart` — FOUND (modified)
- [x] `lib/application/voice/voice_category_resolver.dart` — FOUND (modified)
- [x] `test/architecture/category_other_l2_invariant_test.dart` — FOUND (modified)
- [x] `lib/infrastructure/ml/merchant_database.dart` — FOUND (modified)
- [x] `test/unit/infrastructure/ml/merchant_database_test.dart` — FOUND (modified)
- [x] Commit d779bc6 — FOUND (Task 1.1: refactor constant dedup)
- [x] Commit 024842d — FOUND (Task 1.2: merchant DB guard + D-13 tests)

## Self-Check: PASSED

All files exist, both commits verified in git log.
