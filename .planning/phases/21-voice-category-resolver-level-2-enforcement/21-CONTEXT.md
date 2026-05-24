# Phase 21: Voice Category Resolver Level-2 Enforcement - Context

**Gathered:** 2026-05-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 21 builds the voice category resolver that guarantees voice-driven Transactions always carry a level-2 categoryId (VOICE-04/05/06). The resolver replaces today's `lib/application/voice/fuzzy_category_matcher.dart` (3-signal scoring with hardcoded `_seedKeywordMap`) with a focused, level-2-enforcing pipeline that consults `MerchantDatabase` + the existing `category_keyword_preferences` Drift table (now doubling as the synonym dictionary via a `hitCount=0` seed sentinel). When a match resolves only to a level-1 categoryId, the resolver routes to `${l1Id}_other` by naming convention. The resolver itself lives in `lib/application/voice/voice_category_resolver.dart` and is consumed by `ParseVoiceInputUseCase`. No new Drift schema migration is introduced; v17 stays. No UI work — record-button UX (REC-01/02) and the voice→shared-details-form integration (INPUT-02) are Phase 22.

**In scope:**
- New `lib/application/voice/voice_category_resolver.dart` class (`VoiceCategoryResolver`), the single entry point for voice-utterance → level-2 categoryId resolution. Owns the 4-stage lookup pipeline (D-07) and the `${l1Id}_other` L1→L2 fallback (D-03).
- Migration of 70+ entries from the current `_seedKeywordMap` in `lib/application/voice/fuzzy_category_matcher.dart` into seed rows of the existing `category_keyword_preferences` table with `hitCount=0` sentinel (D-01, D-06). Migration is one-shot at app first-launch via a SeedCategoriesUseCase-style seeder (or extension of it); idempotent.
- ID drift fixes (D-04): `cat_shopping` → `cat_clothing`, `cat_entertainment` → `cat_hobbies`, `cat_medical` → `cat_health` references in both `_seedKeywordMap` (migration) and `lib/infrastructure/ml/merchant_database.dart` (in-place edit). All ID references must resolve to a real L1 in `default_categories.dart`.
- Enrichment of the 12 hardcoded `_MerchantEntry` records in `MerchantDatabase` to point at explicit L2 categoryIds (e.g., `スターバックス` → `cat_food_cafe`, `マクドナルド` → `cat_food_dining_out`, `ニトリ` → `cat_housing_furniture`). Mapping decisions made at planner/executor time per "business intent" heuristic (D-05); user reviews at PR.
- Architectural safety net: structural test `every L1 has a ${l1Id}_other L2` to prevent drift when `default_categories.dart` is edited (D-03).
- Voice category corpus test fixtures (D-10): `test/fixtures/voice_category_corpus_zh.dart` + `_ja.dart`, ~30 cases per locale, 5 anchor categories (direct L2 hit / merchant L2 hit / L1→_other fallback / learned override / ID-drift regression). Per-locale accuracy reported separately, ≥95% gate (mirrors Phase 20's pattern).
- Removal of `_matchSeedKeywords` and `_matchEditDistance` code paths in `FuzzyCategoryMatcher` (D-06, D-08); `_matchLearned` semantics migrate into the new resolver. The `FuzzyCategoryMatcher` class is fully deleted.
- Update of `ParseVoiceInputUseCase` (`lib/application/voice/parse_voice_input_use_case.dart`) to inject `VoiceCategoryResolver` in place of `FuzzyCategoryMatcher`.
- Update of Riverpod wiring in `lib/features/accounting/presentation/providers/repository_providers.dart` (delete fuzzy matcher provider, add resolver provider).

**Out of scope:**
- New Drift schema migration (v17 → v18). Cross-cutting constraint (REQUIREMENTS.md §Cross-cutting): "No new Drift schema migration unless absolutely required by EDIT-01/02." Phase 21 reuses the existing `category_keyword_preferences` table; the `hitCount=0` sentinel is a runtime convention, not a schema change.
- English (en) synonym entries. The current `_seedKeywordMap` has ~14 English entries (breakfast, lunch, dinner, coffee, food, clothes, shoes, book, hospital, medicine, rent, utilities, movie, game, train, bus, taxi). These are NOT migrated; they're recorded as deferred ideas to backfill when English voice input is enabled in v1.4+ (REQUIREMENTS.md §Out of scope explicitly defers English voice input).
- Settings UI for user-configurable per-L1 default L2. The `${l1Id}_other` naming convention is the chosen fallback; user-configurable defaults are deferred to v1.4+.
- Edit-distance fuzzy matcher (`_matchEditDistance`). Removed; rationale: low signal-to-noise in production observations, complicates testing surface, and the new pipeline (merchant + keyword_preferences) covers the relevant matching ground without it.
- Phase 22 integration work — INPUT-02 (voice fills shared details form) and REC-01/02 (record button UX) consume the resolver but are not built here.
- MerchantDatabase as an extensible asset/data file. The 12 entries stay in-code with explicit L2 ids; making merchants extensible-without-code-changes is acknowledged as a potential follow-up but VOICE-06's "two data sources extensible by adding entries" is satisfied by `category_keyword_preferences` table + the merchant code (both can grow by adding entries — merchant entries via PR, synonym entries via correction or seed table additions).
- Remote sync of synonym overrides. The user-corrected entries in `category_keyword_preferences` already sync via the existing P2P sync queue (table is participating in sync infrastructure); no Phase 21 sync work.

</domain>

<decisions>
## Implementation Decisions

### Synonym dictionary data source

- **D-01:** Synonym dictionary is the existing **`category_keyword_preferences` Drift table** (v17 schema). Seed synonyms are inserted on first launch with `hitCount = 0` as a sentinel distinguishing "seed" from "user-learned." User-corrected entries already update this table via `RecordCategoryCorrectionUseCase`, so seed + learned synonyms unify into a single lookup surface. Zero schema migration. VOICE-06 "extensible without code changes" is satisfied two ways: (a) operations can extend seed by editing the seeder source (Dart literal or YAML source; planner chooses) and bumping a seed version key, (b) end users implicitly extend by correcting voice-resolved categories (hitCount increments). Seed-source format (Dart literal vs YAML asset) is Claude's discretion at planner stage — both meet the "without modifying resolver code" intent.

- **D-02 (DEPRECATED):** Original YAML asset proposal superseded by D-01. Marked here for traceability; do not implement YAML-as-runtime-source.

### L1 → first-L2 fallback identity

- **D-03:** When a match resolves only to L1, the resolver returns `${l1Id}_other` (e.g., `cat_food` → `cat_food_other`, `cat_transport` → `cat_transport_other`). Verified: all 19 L1 categories in `lib/shared/constants/default_categories.dart` have a `cat_{l1}_other` L2 entry (38 `_other'` grep hits — 19 categoryId + 19 localization-key occurrences). Resolver validates the synthesized L2 id via `CategoryRepository.findById` before returning; if the `_other` L2 is somehow missing (user deletion, future schema drift), the resolver falls back to `CategoryRepository.findByParent(l1Id).first` (sortOrder-min) as a safety net. **Architectural test required:** `test/architecture/category_other_l2_invariant_test.dart` (or similar) asserts every L1 in `default_categories.dart` has a corresponding `${l1Id}_other` L2 with matching `parentId` and `level=2`. Settings-based per-L1 default L2 is explicitly deferred to v1.4+ (not implemented here).

### Merchant DB L2 enrichment + ID drift fixes

- **D-04:** All 12 `_MerchantEntry` records in `lib/infrastructure/ml/merchant_database.dart` are updated to point at explicit L2 categoryIds. Concurrently, three ID drift errors are corrected: `cat_shopping` → `cat_clothing` or relevant L2 child, `cat_entertainment` → `cat_hobbies` or relevant L2 child, `cat_medical` → `cat_health` or relevant L2 child. These three IDs do not exist in `default_categories.dart` (verified: 19 L1 IDs are cat_food/cat_daily/cat_pet/cat_transport/cat_hobbies/cat_clothing/cat_social/cat_health/cat_education/cat_utilities/cat_communication/cat_housing/cat_car/cat_tax/cat_insurance/cat_special/cat_allowance/cat_asset/cat_other_expense — no cat_shopping, cat_entertainment, or cat_medical). Currently these references silently fail `findById` and return null, which is a latent bug Phase 21 closes.

- **D-05:** Claude decides each merchant → L2 mapping at planner/executor stage using "closest business intent" heuristic. User reviews and adjusts at PR time. Provisional mapping (planner can override):
  - `マクドナルド` (McDonald) → `cat_food_dining_out`
  - `スターバックス` (Starbucks) → `cat_food_cafe`
  - `吉野家` (Yoshinoya) → `cat_food_dining_out`
  - `セブンイレブン` (7-Eleven) → `cat_food_groceries` (convenience-store food predominantly groceries; user may move to `_dining_out`)
  - `ファミリーマート` (FamilyMart) → `cat_food_groceries`
  - `ローソン` (Lawson) → `cat_food_groceries`
  - `すき家` (Sukiya) → `cat_food_dining_out`
  - `ユニクロ` (Uniqlo) → `cat_clothing_outerwear` or `_other` (fix `cat_shopping` ID drift)
  - `ニトリ` (Nitori, furniture) → `cat_housing_furniture`
  - `ヤマダ電機` (Yamada, appliances) → `cat_housing_appliances` (fix `cat_shopping` ID drift; ledgerType stays `LedgerType.soul` per current entry)
  - `Amazon` → `cat_daily_other` (fix `cat_shopping` ID drift; generic e-commerce; user may relocate)
  - `Netflix` → `cat_hobbies` subscription L2 (fix `cat_entertainment` ID drift; user may pick the best `cat_hobbies_*` L2)

### Lookup pipeline order

- **D-07:** Resolver lookup order (strict short-circuit, NOT score-based merge):
  1. **`MerchantDatabase.findMerchant(extractedMerchantSegment)`** — if hit, return its L2 categoryId (D-04 guarantees explicit L2).
  2. **`category_keyword_preferences` table query** — match by `keyword` against extracted tokens (precise + `contains` semantics, mirrors current `_matchSeedKeywords` `contains` policy). Order results by `hitCount DESC, lastUsed DESC`; take first row. If the categoryId is L2, return it. If L1, route to step 3.
  3. **L1 → `${l1Id}_other` fallback** (D-03) — applies if either MerchantDatabase or keyword_preferences resolved only to L1.
  4. **All miss** — return `null`. Voice screen surfaces "no category recognized" affordance; user picks manually via the shared details form (Phase 22 wiring).
- **D-08:** Edit-distance fuzzy matching (`_matchEditDistance` in `FuzzyCategoryMatcher`) is **removed**. Rationale: low signal-to-noise on category-name fuzzy matching against user-typed category names; complicates testing; pipeline above covers the relevant ground via merchant DB (canonical names) + keyword_preferences (user/seed synonyms with learning). The resolver is intentionally simpler than today's 3-signal matcher.

### Resolver class location + structure

- **D-09:** Resolver class lives at **`lib/application/voice/voice_category_resolver.dart`** (class name `VoiceCategoryResolver`). Sits alongside `voice_text_parser.dart`, `voice_chunk_merger.dart`, `parse_voice_input_use_case.dart` — application-layer orchestrator semantics. Dependencies: `CategoryRepository`, `CategoryKeywordPreferenceRepository`, `MerchantDatabase` (the last being infrastructure, the first two being domain interfaces backed by data). Provider wiring goes in `lib/features/accounting/presentation/providers/repository_providers.dart` (replaces `fuzzyCategoryMatcherProvider`). `FuzzyCategoryMatcher` class is fully deleted along with `_KeywordMapping`, `_ScoredCandidate`, `_matchEditDistance`, `_seedKeywordMap`, and `levenshtein.dart` (if no other caller; verify before deletion).

### Test corpus shape

- **D-10:** Two committed fixture files: `test/fixtures/voice_category_corpus_zh.dart` + `_ja.dart`, mirroring Phase 20's fixture pattern. ~30 cases per locale (smaller than Phase 20 because the category space is more bounded than free-form numerals). Five anchor case categories, each with at least one strict `test()` block:
  1. **Direct L2 synonym hit** — e.g. zh `早餐 100元` → `cat_food_dining_out`; ja `朝ごはん500円` → `cat_food_dining_out`
  2. **Merchant → L2 hit** — e.g. zh `星巴克咖啡` → `cat_food_cafe`; ja `スタバでコーヒー` → `cat_food_cafe`
  3. **L1 → `_other` fallback** — e.g. zh `吃饭 300元` (no synonym mapping to L2) → `cat_food_other`; ja `何か食べた` → `cat_food_other`
  4. **Learned override** — seed says `咖啡` → `cat_food_cafe`; after user corrects `咖啡` to `cat_hobbies_subscription` (hypothetical), hitCount≥2 makes the learned mapping win over seed.
  5. **ID drift regression** — verify that `cat_shopping`/`cat_entertainment`/`cat_medical` are nowhere in the resolver's outputs; verify that fixed mappings (`cat_clothing`, `cat_hobbies`, `cat_health` and their L2 children) resolve correctly.
- Per-locale accuracy printed separately at end of suite (`zh: 28/30 (93%)` / `ja: 29/30 (97%)`); suite fails if either drops below 95%. Anchor tests are strict (each its own `test()` block, must pass 100%); the statistical bucket aggregates the rest.

### Claude's Discretion

- **Seed source format** for synonym entries (Dart literal in a `default_synonyms.dart` next to `default_categories.dart`, OR YAML asset like `assets/voice/synonyms_seed.yaml` loaded at seed time and discarded after first launch). Planner picks whichever fits the existing seeding pattern more cleanly. **Important:** whichever format is chosen, it must NOT be the runtime data source — runtime data source is the Drift table per D-01. The seed source is just where the bootstrap rows come from.
- **Exact migration policy** for users with existing learned data: planner decides whether `hitCount=0` seed insertion uses `INSERT OR IGNORE` (preserve existing rows verbatim) or `INSERT OR REPLACE` for seed rows where hitCount was `0` previously. Recommendation: `INSERT OR IGNORE` to never destroy user data; seed bumps require a separate seed-version mechanism.
- **Detailed merchant → L2 mappings beyond the provisional list in D-05.** Planner finalizes each of the 12 mappings, user reviews at PR. Mapping for Amazon/Netflix is especially flexible (generic merchants with no strong L2 affinity).
- **Whether to also delete `levenshtein.dart`.** Currently only consumed by `_matchEditDistance` (deleted in D-08); verify before deleting the file.
- **Whether to keep `_extractKeyword` in `ParseVoiceInputUseCase`** or move it into the new resolver. Current code path is `parse_voice_input_use_case.dart:97-113` — could be relocated. Planner decides.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/ROADMAP.md` §Phase 21 — phase goal + 5 Success Criteria (always-L2 contract, first-L2 fallback, two data sources extensible, lookup order documented, `lib/application/` or `lib/infrastructure/` placement)
- `.planning/REQUIREMENTS.md` — VOICE-04 (L2 hit when matchable), VOICE-05 (L1→first-L2 fallback), VOICE-06 (two data sources extensible without code changes); §Cross-cutting (no Drift schema migration unless EDIT-01/02 requires)
- `.planning/PROJECT.md` — milestone constraint that v1.3 is zh + ja voice only; English voice input deferred to v1.4+

### Project state and adjacent phases
- `.planning/STATE.md` — Phase 20 PASS_WITH_DEBT (parser/corpus layer verified; only VOICE-02-DEVICE-VERIFY device test pending); Phase 21 inherits Phase 20's parser pipeline output (corrected amount → `VoiceParseResult.amount`)
- `.planning/phases/20-voice-number-parser-zh-ja/20-CONTEXT.md` — established the `infrastructure/voice/` NLP placement pattern + per-locale Dart-literal corpus fixture format + ≥95% gate; Phase 21 mirrors corpus shape (D-10) and class-placement convention (resolver in application/voice/ rather than infrastructure/voice/ because resolver is an orchestrator, not pure NLP)
- `.planning/phases/20-voice-number-parser-zh-ja/20-08-SUMMARY.md` — Phase 20 final summary including the deferred device verification context; Phase 21 corpus structure references this

### Architecture
- `docs/arch/02-module-specs/MOD-009_VoiceInput.md` — canonical voice-input module spec (lines 107 mentions "匹配到 L2 子分类时自动关联 L1 父分类" — Phase 21 inverts this: always-L2 output, never bare L1)
- `docs/arch/01-core-architecture/ARCH-001_Complete_Guide.md` — Clean Architecture layering (resolver as application orchestrator, not infrastructure)
- `CLAUDE.md` — Thin Feature rule (resolver lives in `lib/application/voice/`, NEVER inside `lib/features/`), Riverpod 3 provider conventions (`@riverpod` codegen, provider naming drops `Notifier` suffix), `repository_providers.dart` single-source-of-truth rule, immutability (`copyWith` on Freezed), intl 0.20.2 pin, `sqlcipher_flutter_libs` pin

### Code touchpoints (Phase 21 will modify or replace)
- `lib/application/voice/fuzzy_category_matcher.dart` — fully deleted; `_matchSeedKeywords`/`_matchEditDistance`/`_matchLearned`/`_seedKeywordMap`/`_KeywordMapping`/`_ScoredCandidate` all removed (D-06, D-08)
- `lib/application/voice/parse_voice_input_use_case.dart` — `FuzzyCategoryMatcher` field replaced with `VoiceCategoryResolver`; lines 5, 16-25, 52-74 updated; `_extractKeyword` (lines 97-113) may relocate to resolver (Claude discretion)
- `lib/infrastructure/ml/merchant_database.dart` — 12 `_MerchantEntry` `categoryId` values updated per D-04/D-05; three ID drifts fixed
- `lib/features/accounting/presentation/providers/repository_providers.dart` — `fuzzyCategoryMatcherProvider` deleted, `voiceCategoryResolverProvider` added
- `lib/application/voice/levenshtein.dart` — delete if no other consumer (verify before removing)
- New file: `lib/application/voice/voice_category_resolver.dart` (the resolver itself)
- New file (planner choice): seed source for synonyms — `lib/shared/constants/default_synonyms.dart` or `assets/voice/synonyms_seed.yaml`
- Seed-insertion entrypoint: extend `lib/application/accounting/seed_categories_use_case.dart` OR add a parallel `seed_voice_synonyms_use_case.dart` (planner decides; recommend extending existing seed flow for idempotency reuse)

### Existing data layer to reuse
- `lib/data/tables/category_keyword_preferences_table.dart` — primary key `(keyword, categoryId)`, columns `hitCount`, `lastUsed`; reused as-is for synonym dict (D-01)
- `lib/data/daos/category_keyword_preference_dao.dart` — may need a `findBestForKeyword(keyword)` method ordered by `hitCount DESC, lastUsed DESC` if not already present (D-07 step 2)
- `lib/features/accounting/domain/repositories/category_keyword_preference_repository.dart` — `findByKeyword`, `suggestForKeyword` already exist; verify they meet D-07's ordering requirement or extend
- `lib/features/accounting/domain/repositories/category_repository.dart` — `findById`, `findByParent`, `findByLevel` already exist (resolver uses `findById` for the `_other` validation step)
- `lib/shared/constants/default_categories.dart` — 19 L1 + 103 L2 system categories; every L1 has a `${l1Id}_other` L2 (D-03 invariant)

### Existing tests to retire / replace
- `test/unit/application/voice/fuzzy_category_matcher_test.dart` — retired (FuzzyCategoryMatcher deleted); replaced by `test/unit/application/voice/voice_category_resolver_test.dart`
- `test/unit/application/voice/levenshtein_test.dart` — retire if levenshtein.dart deleted (Claude discretion)
- New: `test/integration/voice/voice_category_corpus_zh_test.dart` + `_ja_test.dart` (D-10 corpus)
- New: `test/architecture/category_other_l2_invariant_test.dart` (D-03 safety net)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `MerchantDatabase.findMerchant` (`lib/infrastructure/ml/merchant_database.dart:125-161`) — current 3-stage matching (exact → alias → substring); resolver uses as-is in pipeline step 1 (D-07). Only the embedded `categoryId` values change (D-04).
- `CategoryRepository.findById` / `findByParent` (`lib/features/accounting/domain/repositories/category_repository.dart`) — used to verify the synthesized `${l1Id}_other` exists (D-03) and to enumerate L2 children for the safety net fallback.
- `CategoryKeywordPreferenceRepository.suggestForKeyword` and `findByKeyword` (`lib/features/accounting/domain/repositories/category_keyword_preference_repository.dart`) — existing surface for keyword → categoryId lookups; resolver consumes (D-07 step 2). Verify ordering semantics match `hitCount DESC, lastUsed DESC`; extend DAO if needed.
- `RecordCategoryCorrectionUseCase` (`lib/application/voice/record_category_correction_use_case.dart`) — already increments `hitCount` on user correction; the `hitCount=0` seed sentinel coexists cleanly with this (seed → user correction is just hitCount++ from 0).
- `SeedCategoriesUseCase` (`lib/application/accounting/seed_categories_use_case.dart`) — idempotent first-launch seeder pattern; new synonym seed should follow this shape (check `existing.isNotEmpty` against synonyms-or-seed-version-key before re-inserting).
- `CategoryService.resolveLedgerType` and `resolveL1` (`lib/application/accounting/category_service.dart`) — resolver may want to call `resolveLedgerType` after returning an L2 to populate `VoiceParseResult.ledgerType` (or `ParseVoiceInputUseCase` continues to call it post-resolver as today).

### Established Patterns
- "Thin Feature" rule: resolver and seed source live in `lib/application/` and/or `lib/shared/constants/`, NEVER inside `lib/features/`. Resolver tests live in `test/unit/application/voice/` and `test/integration/voice/`.
- Idempotent seeding via `existing.isNotEmpty` check (per `SeedCategoriesUseCase.execute`). Synonym seed adopts the same pattern; if seed rows already exist (hitCount=0 rows), skip re-insert.
- Per-locale corpus fixture files in `test/fixtures/voice_corpus_{zh,ja}.dart` with `case`-style records + anchor `test()` blocks + statistical bucket — Phase 20 pattern, Phase 21 mirrors (D-10).
- Riverpod `@riverpod` codegen with `repository_providers.dart` as single source of truth; `fuzzyCategoryMatcherProvider` replaced by `voiceCategoryResolverProvider` in the same file.
- `Result<T>` wrapper for use-case return values (`lib/shared/utils/result.dart`); resolver returns `CategoryMatchResult?` directly (no Result wrap — null = no match is a meaningful semantics), but `ParseVoiceInputUseCase.execute` continues to wrap the whole VoiceParseResult in Result.

### Integration Points
- `ParseVoiceInputUseCase.execute` (`lib/application/voice/parse_voice_input_use_case.dart:34-91`) — sole consumer of category resolution today; switches from `FuzzyCategoryMatcher.match` to `VoiceCategoryResolver.resolve`. The contract returned to the screen (`VoiceParseResult.categoryMatch.categoryId` + `ledgerType`) does not change shape — `categoryId` is now guaranteed L2 (was sometimes L1).
- `lib/features/accounting/presentation/screens/voice_input_screen.dart:351-368` (Phase 19 voice → ManualOneStepScreen push site) consumes `result.categoryMatch?.categoryId` indirectly via the parse-result chain; no changes here, but Phase 22 will wire this into the shared details form (INPUT-02).
- `category_keyword_preferences` table already participates in sync via the existing P2P sync queue; user-learned synonym rows propagate automatically.
- App initialization: seed step runs after KeyManager → Database via `AppInitializer`. New synonym seed should chain after `SeedCategoriesUseCase` (so categories exist before synonyms reference them by `categoryId`).

</code_context>

<specifics>
## Specific Ideas

Anchor cases that downstream agents MUST encode verbatim as named `test()` blocks (not just rolled into the statistical corpus):

- **zh `"早餐 100元"` → `cat_food_dining_out`** (direct L2 synonym hit; reuses seed `早餐 → cat_food_dining_out` migrated from `_seedKeywordMap`)
- **zh `"星巴克咖啡"` → `cat_food_cafe`** (merchant DB hit; verifies D-04 Starbucks → cat_food_cafe enrichment)
- **zh `"吃饭 300元"` → `cat_food_other`** (L1 hit only via 吃饭 → cat_food seed; verifies D-03 L1→`_other` fallback)
- **zh `"打车回家"` → `cat_transport_taxi`** (direct L2 synonym hit; verifies `打车 → cat_transport_taxi` migrated from `_seedKeywordMap`)
- **ja `"朝ごはん500円"` → `cat_food_dining_out`** (direct L2 synonym hit; verifies kana seed)
- **ja `"スタバでコーヒー"` → `cat_food_cafe`** (merchant DB hit with sokuon/katakana; verifies Starbucks enrichment)
- **ja `"何か食べた"` → `cat_food_other`** (L1 hit only via 食べた→cat_food; verifies _other fallback)
- **ja `"電車で会社"` → `cat_transport_train`** (direct L2 synonym hit; verifies `電車 → cat_transport_train`)
- **ID drift regression cases (3, must verify NO regression to the broken IDs):**
  - `"洋服を買った"` resolves to a real L2 under `cat_clothing` (NOT `cat_shopping`, which doesn't exist)
  - `"映画を見た"` resolves to a real L2 under `cat_hobbies` (NOT `cat_entertainment`)
  - `"病院に行った"` resolves to a real L2 under `cat_health` (NOT `cat_medical`)
- **Learned override case:** in-test setup pre-inserts `("咖啡", "cat_hobbies_某 L2", hitCount=3)` into `category_keyword_preferences`; assert `"咖啡 500円"` resolves to that L2, NOT to the seed `cat_food_cafe`.

VOICE-06 "extensibility without code changes" test: add a new keyword row to `category_keyword_preferences` table directly in the test setup (e.g. `("珍珠奶茶", "cat_food_drinks", hitCount=2)`) and assert the resolver picks it up without any resolver-code change.

Architectural invariant test: load `DefaultCategories.all`, group by parentId for L2 rows, verify each L1 in `DefaultCategories.expenseL1` has a corresponding `${l1Id}_other` entry in the L2 list.

</specifics>

<deferred>
## Deferred Ideas

- **English (en) synonym seed** — the ~14 English entries in current `_seedKeywordMap` (breakfast, lunch, dinner, coffee, food, clothes, shoes, book, hospital, medicine, rent, utilities, movie, game, train, bus, taxi) are NOT migrated. Backfill when English voice input lands in v1.4+ (REQUIREMENTS.md §Out of scope explicitly defers en voice).
- **MerchantDatabase as extensible asset/data file** — the 12 hardcoded merchant entries remain in `lib/infrastructure/ml/merchant_database.dart`. Making merchant entries extensible-without-code-changes (e.g., move to `category_keyword_preferences`-style table or YAML asset) is a candidate follow-up. VOICE-06 is already met by D-01 (synonym dict via DB table) + D-04 (merchant entries enriched in this phase); future extensibility-driven refactor is its own work.
- **Settings UI for user-configurable per-L1 default L2** — `${l1Id}_other` is the fixed convention in v1.3; user-configurable default fallback is v1.4+.
- **Phase 22 integration** (INPUT-02 voice fills shared details form; REC-01/02 record button UX) — separate phase.
- **Score-based merge of merchant + keyword_preferences** — D-07 chose strict short-circuit. If real-world accuracy data later shows score-based wins, revisit in v1.4+ as a focused tuning phase.
- **`category_keyword_preferences` table sync conflict resolution** — table syncs via existing P2P sync queue. If multi-device users see synonym divergence (one device has user-corrected 咖啡→cafe, another has 咖啡→drinks), the sync layer's last-write-wins or merge policy applies — no special Phase 21 work, but family-sync hardening (FAMILY-V2-01/02/03) is a v1.4+ candidate.
- **Recursive sub-L2 (level-3+) categories** — out of scope; the model is strictly 2 levels.

</deferred>

---

*Phase: 21-voice-category-resolver-level-2-enforcement*
*Context gathered: 2026-05-24*
