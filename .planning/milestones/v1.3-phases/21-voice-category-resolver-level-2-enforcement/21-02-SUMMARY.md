---
phase: 21-voice-category-resolver-level-2-enforcement
plan: "02"
subsystem: data-application
tags: [flutter, dart, drift, riverpod, voice, synonyms, seed, dao, repository]

requires: []

provides:
  - "CategoryKeywordPreferenceDao.insertSeedBatch — INSERT OR IGNORE batch writer (hitCount=0 sentinel, fixed epoch DateTime(2026,1,1))"
  - "CategoryKeywordPreferenceDao.findByKeyword — orders by hitCount DESC, lastUsed DESC (D-07 step 2)"
  - "CategoryKeywordPreferenceDao.decayStalePreferences — WHERE clauses now exclude hitCount=0 seed sentinel rows"
  - "CategoryKeywordPreferenceRepository.insertSeedBatch — domain interface + impl pass-through"
  - "DefaultVoiceSynonyms.all — 59-entry zh+ja Dart-literal seed source in lib/shared/constants/default_synonyms.dart"
  - "SeedVoiceSynonymsUseCase — idempotent first-launch seeder in lib/application/accounting/seed_voice_synonyms_use_case.dart"
  - "@riverpod seedVoiceSynonymsUseCaseProvider — wires SeedVoiceSynonymsUseCase from preferenceRepository"
  - "AppInitializer chain — synonyms seeded AFTER categories so referenced L1/L2 ids exist"

affects:
  - 21-03 (VoiceCategoryResolver will consume CategoryKeywordPreferenceRepository.findByKeyword + the seeded rows)
  - 21-05 (FuzzyCategoryMatcher deletion — _seedKeywordMap entries are now seed rows in the table)
  - 21-06 (Corpus tests rely on the same seed rows being present at test setup)

tech-stack:
  added: []
  patterns:
    - "hitCount=0 sentinel — unified lookup surface across seed + learned rows in a single Drift table (D-01)"
    - "INSERT OR IGNORE seeding — preserves user-corrected rows verbatim on re-run (Claude's-Discretion option a)"
    - "Idempotency probe by first-keyword findByKeyword (mirrors SeedCategoriesUseCase.findAll().isNotEmpty pattern)"
    - "D-04 ID-drift correction at seed source — cat_clothing*/cat_hobbies*/cat_health* replace previously-broken IDs"

key-files:
  created:
    - lib/shared/constants/default_synonyms.dart
    - lib/application/accounting/seed_voice_synonyms_use_case.dart
  modified:
    - lib/data/daos/category_keyword_preference_dao.dart
    - lib/features/accounting/domain/repositories/category_keyword_preference_repository.dart
    - lib/data/repositories/category_keyword_preference_repository_impl.dart
    - lib/features/accounting/presentation/providers/repository_providers.dart
    - lib/features/accounting/presentation/providers/repository_providers.g.dart
    - lib/main.dart

key-decisions:
  - "Seed source format: Dart-literal abstract-final-class (D-01 + Claude's-Discretion option (a)) — chosen over YAML per 21-PATTERNS.md §2; YAML has no analog in repo and would add rootBundle + yaml package dependency without precedent"
  - "Batch insertion via dedicated insertSeedBatch (not per-row recordCorrection) — recordCorrection writes hitCount=1, which would defeat the D-01 sentinel that distinguishes seed from learned rows"
  - "decayStalePreferences amended in BOTH the typed delete AND the customUpdate SQL — sentinel protection is semantic (hitCount=0), not temporal; lastUsed=epoch alone would leave a regression footprint when the decay duration grows"
  - "59 zh+ja entries (target ≥56); zero English entries — REQUIREMENTS.md §Out of scope explicitly defers English voice input to v1.4+"
  - "DAO writes hitCount=0 + epoch by construction regardless of model values — repository impl docs note that the seed model's hitCount/lastUsed fields are documentary only"

requirements-completed: [VOICE-04, VOICE-06]

duration: ~20min
completed: 2026-05-24
---

# Phase 21 Plan 02: Voice Synonym Dictionary Infrastructure Summary

**Installs the synonym dictionary surface that the upcoming VoiceCategoryResolver (Plan 03) will consume: DAO ordering aligned to D-07, INSERT-OR-IGNORE batch seed with hitCount=0 sentinel (D-01), decay-WHERE amendment to protect seeds, 59-entry zh+ja Dart-literal seed source with D-04 ID-drift fixes, idempotent SeedVoiceSynonymsUseCase, and AppInitializer chain wiring synonyms after categories.**

## Performance

- **Duration:** ~20 min
- **Tasks:** 5
- **Commits:** 5 (1 per task)
- **Files modified:** 7 (2 new, 5 modified — including generated repository_providers.g.dart)

## Accomplishments

- **DAO** — added `insertSeedBatch(List<({String keyword, String categoryId})>)` using Drift `_db.batch(...)` + `InsertMode.insertOrIgnore`; extended `findByKeyword` ordering to `hitCount DESC, lastUsed DESC` per D-07 step 2; amended `decayStalePreferences` so both the typed delete and the `customUpdate` SQL exclude `hitCount=0` seed sentinel rows.
- **Repository** — extended domain interface `CategoryKeywordPreferenceRepository` with `insertSeedBatch(List<CategoryKeywordPreference>)`; impl maps model list to DAO record shape and forwards.
- **Seed source** — created `lib/shared/constants/default_synonyms.dart` (`abstract final class DefaultVoiceSynonyms`) with 59 zh+ja entries across Food / Transport / Clothing / Hobbies / Health / Housing / Utilities / Education. All D-04 ID drifts corrected at the seed source — zero references to `cat_shopping`, `cat_entertainment`, or `cat_medical` in literals.
- **Use case** — created `lib/application/accounting/seed_voice_synonyms_use_case.dart` mirroring `SeedCategoriesUseCase`; idempotent via first-keyword probe; never calls the incrementing learning surface so the D-01 sentinel survives.
- **Wiring** — added `@riverpod seedVoiceSynonymsUseCase` next to `seedCategoriesUseCase`; extended `main.dart` import-show; placed `seedVoiceSynonyms.execute()` directly after `seedCategories.execute()` so referenced categoryIds always exist before insertion. Regenerated `repository_providers.g.dart` via `build_runner`.
- **Quality** — `dart analyze` on all 7 touched files: 0 issues. Existing `CategoryKeywordPreferenceDao` unit test (7 assertions) still passes — backward compatible with prior ordering callers. `flutter analyze` repo-wide reports only 4 pre-existing/unrelated issues (firebase_messaging build artifact + onReorder deprecation in category_selection_screen.dart, neither touched by this plan).

## Task Commits

1. **Task 1: Extend DAO — findByKeyword ordering, insertSeedBatch, decay-WHERE amendment** — `8d9f18a` (feat)
2. **Task 2: Extend domain repository interface + impl with insertSeedBatch** — `ab02439` (feat)
3. **Task 3: Create DefaultVoiceSynonyms seed source (Dart-literal, ID-drift-corrected, zh+ja only)** — `0ff403b` (feat)
4. **Task 4: Create SeedVoiceSynonymsUseCase** — `62221bf` (feat)
5. **Task 5: Wire Riverpod provider + AppInitializer chain, then run build_runner** — `ab8ea83` (feat)

## Files Created

- `lib/shared/constants/default_synonyms.dart` — `abstract final class DefaultVoiceSynonyms` with `static List<CategoryKeywordPreference> get all`. 59 zh+ja entries: 14 ja food + 9 zh food + 12 transport + 5 clothing + 6 hobbies + 4 health + 7 housing/utilities + 2 education. `_seed(keyword, categoryId)` helper builds documentary `CategoryKeywordPreference` with `hitCount=0` + `_epoch = DateTime(2026,1,1)`. File-header doc-comment quotes D-01 sentinel, Claude's-Discretion seed-source rationale (Dart literal over YAML), and explicit "no English entries" deferral list.
- `lib/application/accounting/seed_voice_synonyms_use_case.dart` — `SeedVoiceSynonymsUseCase.execute()` returns `Result<void>`. Probes idempotency via `_prefRepo.findByKeyword(DefaultVoiceSynonyms.all.first.keyword)`; if non-empty, short-circuits to `Result.success(null)`. Otherwise calls `_prefRepo.insertSeedBatch(DefaultVoiceSynonyms.all)`.

## Files Modified

- `lib/data/daos/category_keyword_preference_dao.dart` — `findByKeyword` now adds `OrderingTerm(expression: t.lastUsed, mode: OrderingMode.desc)` as a second order term; new `insertSeedBatch` method uses `_db.batch(...)` + `InsertMode.insertOrIgnore` with `hitCount: const Value(0)` and `lastUsed: epoch (DateTime(2026,1,1))`; `decayStalePreferences` typed-delete WHERE now AND's `t.hitCount.isBiggerThan(const Variable(0))`, and the `customUpdate` SQL string appends `AND hit_count > 0`.
- `lib/features/accounting/domain/repositories/category_keyword_preference_repository.dart` — added abstract `Future<void> insertSeedBatch(List<CategoryKeywordPreference> seeds)` directly below `recordCorrection`.
- `lib/data/repositories/category_keyword_preference_repository_impl.dart` — added `@override insertSeedBatch` that maps `seeds.map((s) => (keyword: s.keyword, categoryId: s.categoryId)).toList(growable: false)` and forwards to `_dao.insertSeedBatch(...)`; inline comment notes the DAO writes hitCount=0/epoch by construction.
- `lib/features/accounting/presentation/providers/repository_providers.dart` — new import `seed_voice_synonyms_use_case.dart`; new `@riverpod SeedVoiceSynonymsUseCase seedVoiceSynonymsUseCase(Ref ref)` calling `ref.watch(categoryKeywordPreferenceRepositoryProvider)`.
- `lib/features/accounting/presentation/providers/repository_providers.g.dart` — regenerated by `build_runner` to include `seedVoiceSynonymsUseCaseProvider` (2 references in the generated file).
- `lib/main.dart` — extended import-show to include `seedVoiceSynonymsUseCaseProvider`; `_initialize()` now reads the provider and awaits `seedVoiceSynonyms.execute()` immediately after `seedCategories.execute()`.

## Decisions Made

- **Seed source format**: Dart-literal `abstract final class` (chosen over YAML asset). Rationale: zero existing YAML-asset loading pattern in repo (per 21-PATTERNS.md §2 "no analog found"); adding `flutter/services rootBundle` + `yaml` package + pubspec asset entry has no precedent. The Dart-literal path mirrors `DefaultCategories` line-for-line.
- **Sentinel protection in decay**: amended both the typed delete (`& t.hitCount.isBiggerThan(const Variable(0))`) AND the raw `customUpdate` SQL (`AND hit_count > 0`). Skipping either would leave the decay UPDATE path pushing seeds toward negative hitCount on long-idle databases.
- **DAO writes canonical values, model fields documentary**: kept the seed model carrying `hitCount=0` + epoch for symmetry/audit clarity, but DAO ignores those fields and writes its own. This means future seed-source authors can't accidentally promote a row to "learned" by passing `hitCount=2` in the literal; the DAO is the single source of truth for the sentinel.
- **Idempotency probe via first-keyword findByKeyword** (not a `findAll().isEmpty` check): the table already participates in user-correction writes that could populate unrelated keywords; probing the actual first seed keyword distinguishes "seed phase ran" from "table has been touched."
- **D-04 ID-drift fixes applied directly to seed entries** rather than via runtime translation. Seed source MUST emit valid IDs that resolve in `default_categories.dart`; broken IDs would cascade into Plan 03 resolver `_ensureL2(...)` returning null and the L1→`_other` fallback silently masking the data error.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] worktree missing `.dart_tool/`**
- **Found during:** Task 1 verification (initial `dart analyze` failed with `PathNotFoundException` for `.dart_tool/pub/workspace_ref.json`)
- **Issue:** Fresh git worktree had no `.dart_tool/` directory; dart analyze and build_runner depend on it.
- **Fix:** Ran `flutter pub get` in the worktree to populate `.dart_tool/`. No code change; this is standard worktree setup that the plan didn't explicitly enumerate.
- **Files modified:** none (idempotent setup step)
- **Commit:** N/A (no committable diff)

**2. [Rule 3 - Done-criteria literal compliance] comment phrasing in seed source + use case**
- **Found during:** Task 3 / Task 4 verification grep
- **Issue:** Initial comments contained literal strings `cat_shopping`/`cat_entertainment`/`cat_medical` (in the D-04 fix-explanation comments) and `recordCorrection` (in the use-case rationale), which made the done-criteria `grep -c ... must return 0` checks fail even though the actual code carried zero such references.
- **Fix:** Rephrased the comments to drop the literal forbidden tokens without losing the design rationale (e.g., "prior placeholder L1 corrected to cat_clothing*" and "the incrementing learning surface is NOT used here"). All semantic content preserved; verification criteria now pass literally.
- **Files modified:** `lib/shared/constants/default_synonyms.dart`, `lib/application/accounting/seed_voice_synonyms_use_case.dart`
- **Commit:** Folded into the same Task 3 / Task 4 commits (no separate commit).

**3. [Rule 3 - Done-criteria literal compliance] main.dart comment line-spacing**
- **Found during:** Task 5 verification `grep -A2 "seedCategories.execute()" lib/main.dart | grep -c "seedVoiceSynonyms"` returned 0.
- **Issue:** Original two-line comment between `seedCategories.execute()` and the new `seedVoiceSynonyms` block pushed the `seedVoiceSynonyms` line beyond `grep -A2`'s window.
- **Fix:** Condensed the inter-block comment to a single line (`// Phase 21 D-01: synonyms must run AFTER categories.`). Code semantics unchanged; the literal verification criteria now finds `seedVoiceSynonyms` within 2 lines of `seedCategories.execute()`.
- **Files modified:** `lib/main.dart`
- **Commit:** Folded into Task 5 commit.

No architectural deviations (Rule 4) were necessary. No checkpoints were hit.

## Verification

- `dart analyze` on all 7 touched files — 0 issues
- `flutter analyze` repo-wide — 4 issues, all pre-existing/unrelated (firebase_messaging build artifact in `build/ios/SourcePackages/...`; `onReorder` deprecation in `category_selection_screen.dart` not touched by this plan)
- `flutter pub run build_runner build --delete-conflicting-outputs` — clean (1320 outputs written; `repository_providers.g.dart` now includes `seedVoiceSynonymsUseCaseProvider`)
- `flutter test test/unit/data/daos/category_keyword_preference_dao_test.dart` — 7/7 pass (existing ordering test still asserts `hitCount DESC` as the primary key, which the new ordering preserves)
- `grep -c "cat_shopping\|cat_entertainment\|cat_medical" lib/shared/constants/default_synonyms.dart` returns 0 (D-04 fully enforced at seed source)

## Patterns Established

- **Sentinel-protected decay**: When a Drift DAO uses a count column as both "hit counter" and a sentinel value, decay paths MUST protect the sentinel in BOTH the typed query AND any raw SQL companion. Semantic protection (`WHERE hit_count > 0`) survives schema changes; temporal protection (`lastUsed = epoch`) does not.
- **Documentary model values + DAO canonical write**: When a seed source carries values that semantically belong to the persistence layer (e.g., `hitCount=0` sentinel + epoch), let the DAO own the canonical write and document the seed-source fields as informational. Prevents future authors from accidentally bypassing the sentinel by editing the seed literal.
- **Idempotency by first-key probe, not table-empty probe**: Drift tables that participate in user-driven writes can't use "table is empty" as the seeding gate. Probing the actual first seed keyword distinguishes "seed phase ran" from "user has touched the table."

## Self-Check: PASSED

- FOUND: `lib/shared/constants/default_synonyms.dart`
- FOUND: `lib/application/accounting/seed_voice_synonyms_use_case.dart`
- FOUND commit `8d9f18a` (Task 1 DAO)
- FOUND commit `ab02439` (Task 2 repository)
- FOUND commit `0ff403b` (Task 3 seed source)
- FOUND commit `62221bf` (Task 4 use case)
- FOUND commit `ab8ea83` (Task 5 wiring + build_runner)
- FOUND: `repository_providers.g.dart` includes `seedVoiceSynonymsUseCaseProvider` (2 references)
- VERIFIED: `dart analyze` clean on all touched files
- VERIFIED: `flutter test test/unit/data/daos/category_keyword_preference_dao_test.dart` 7/7 passing
