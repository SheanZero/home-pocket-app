# Phase 21: Voice Category Resolver Level-2 Enforcement - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-24
**Phase:** 21-voice-category-resolver-level-2-enforcement
**Areas discussed:** Synonym dictionary data-source format, L1→first-L2 fallback identity, Merchant DB L2 enrichment, Fate of existing _seedKeywordMap, Lookup pipeline order, Resolver class location + file layout, Corpus test shape

---

## Initial gray-area selection

| Option | Description | Selected |
|--------|-------------|----------|
| Synonym dict data-source format | Where synonym dict lives so non-engineers can extend without recompile | ✓ |
| L1 → first L2 fallback identity | What "first L2" means (sortOrder vs designated default vs Settings-configurable) | ✓ |
| Merchant DB L2 enrichment | Whether 12 seed merchants get explicit L2 ids or rely on fallback | ✓ |
| Fate of existing _seedKeywordMap | Migrate / delete / coexist | ✓ |

**User's choice:** All 4 selected (multiSelect).

---

## Area 1: Synonym dictionary data-source format

### Round 1 — format selection

| Option | Description | Selected |
|--------|-------------|----------|
| YAML asset (recommended) | `assets/voice/synonyms_{zh,ja}.yaml`, `yaml ^3.1.0` already in pubspec, startup-load to in-memory Map | (initially selected) |
| JSON asset | Zero extra dep (`dart:convert`), more verbose, no comments | |
| Drift table v17→v18 | Persistent + queryable, conflicts with cross-cutting "no schema migration" constraint | |

**User's choice:** YAML asset (initial); later reconsidered — see Round 3.
**Notes:** User asked to re-ask in Chinese; question re-presented with same options translated. Answer was the same.

### Round 2 — YAML internal schema

| Option | Description | Selected |
|--------|-------------|----------|
| By categoryId grouped | `cat_food_dining_out: [朝ごはん, 朝食, ランチ]`; ops-friendly, build reverse index at startup | ✓ (initially) |
| By synonym flat | `朝ごはん: cat_food_dining_out`; mirrors current _seedKeywordMap shape | |
| Detailed schema with confidence | `朝ごはん: { category, confidence }`; more knobs, higher maintenance burden | |

**User's choice:** By categoryId grouped (later superseded by Round 3 reversal).
**Notes:** Schema choice scoped to YAML implementation, which was later replaced by DB-table implementation. Kept here for traceability.

### Round 3 — DB reconsideration

**User prompt:** "将synonym dictionary改成用DB实现，是不是可以避免这些问题"

| Option | Description | Selected |
|--------|-------------|----------|
| Reuse existing `category_keyword_preferences` table (recommended, D-01 amended) | hitCount=0 sentinel for seed vs learned; unifies with `RecordCategoryCorrectionUseCase`; zero schema migration | ✓ |
| New `voice_synonyms` table v17→v18 | Cleanest semantic separation but conflicts with cross-cutting constraint | |
| Stay with YAML asset (original D-01) | Keep recommended path; learned vs seed remain split sources | |

**User's choice:** Reuse `category_keyword_preferences` table.
**Notes:** Investigation found the existing v17 table has the exact schema needed (`keyword`, `categoryId`, `hitCount`, `lastUsed`). Reuse unifies seed + user-learned synonyms into a single lookup surface and eliminates the synonym-dict-vs-preference split. Original YAML recommendation reversed. D-01 amended; D-02 (YAML schema) deprecated.

---

## Area 2: L1 → first L2 fallback identity

| Option | Description | Selected |
|--------|-------------|----------|
| `${l1Id}_other` naming convention (recommended) | All 19 L1 verified to have `_other` L2; semantically "uncategorized within L1"; string concat + findById validation | ✓ |
| sortOrder-minimum L2 | Simplest implementation but semantically brittle (e.g., cat_food first by sortOrder is `cat_food_groceries`, not the "expected" `_dining_out`) | |
| Designated default L2 (hardcoded mapping) | Per-L1 explicit map; most accurate but subjective + adds maintenance | |
| Settings user-configurable, default to _other | Most flexible but adds Settings UI + i18n + SharedPreferences key; out of Phase 21 scope | |

**User's choice:** `${l1Id}_other` naming convention.
**Notes:** Grep verified 38 `_other'` occurrences in `default_categories.dart` (19 L1 × 2 = id + localization key). Resolver synthesizes id + validates via `findById`; recommended architectural test guards the invariant against future drift. Settings input explicitly deferred to v1.4+.

---

## Area 3: Merchant DB L2 enrichment

### Round 1 — enrichment strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Enrich 12 seed merchants to explicit L2 (recommended) | Update `_MerchantEntry.categoryId` values in-place; matches v1.3 strict-L2 theme | ✓ |
| Leave merchants at L1, rely on _other fallback | Minimal code change; all merchants land at `cat_*_other` semantically washed | |
| Enrich + split into extensible asset file | Most ambitious; merchant entries become YAML-extensible | |
| Partial enrichment + defer asset-ization | Compromise; only enrich the obvious cases | |

**User's choice:** Enrich 12 to explicit L2.
**Notes:** During discussion, discovered that `MerchantDatabase._entries` and `FuzzyCategoryMatcher._seedKeywordMap` reference three category IDs (`cat_shopping`, `cat_entertainment`, `cat_medical`) that do NOT exist in `default_categories.dart` (real L1s are `cat_clothing`, `cat_hobbies`, `cat_health`). Currently these references silently fail `findById` returns null. Phase 21 must include this ID-drift fix.

### Round 2 — who decides the mapping

| Option | Description | Selected |
|--------|-------------|----------|
| Claude decides at planner/executor stage (recommended) | CONTEXT records intent; specific mapping in PR; user reviews and adjusts | ✓ |
| User per-merchant confirmation in discuss-phase | Most accurate but adds 12 questions | |
| Split into dedicated plan in Phase 21 | Sub-plan separates resolver work from merchant L2 work | |

**User's choice:** Claude decides; user reviews at PR.
**Notes:** Provisional mapping recorded in D-05 (CONTEXT.md). Amazon and Netflix flagged as flexible (no strong L2 affinity).

---

## Area 4: Fate of existing _seedKeywordMap

| Option | Description | Selected |
|--------|-------------|----------|
| Full migration + ID-drift fix + delete (recommended) | zh/ja entries migrate to `category_keyword_preferences` seed; en entries deferred; hardcoded map deleted | ✓ |
| Escort migration but keep hardcoded fallback | YAML primary, hardcoded as last-resort; permanent dual path; weakens VOICE-06 | |
| Abandon hardcoded + curate fresh seed from scratch | Cleaner baseline; risks regression surface; harder to verify Phase 22 continuity | |

**User's choice:** Full migration + delete.
**Notes:** English entries documented as deferred ideas (v1.4+ when English voice input is enabled). All Dart code paths for `_seedKeywordMap`, `_matchSeedKeywords`, `_KeywordMapping`, `_ScoredCandidate` deleted along with `FuzzyCategoryMatcher` class itself.

---

## Area 5 (continuation): Lookup pipeline order

| Option | Description | Selected |
|--------|-------------|----------|
| merchant → keyword_preferences → _other fallback, delete edit-distance (recommended) | Simplest pipeline; matches existing "merchant first, then keyword" semantics; removes weak fuzzy path | ✓ |
| merchant → keyword_preferences → edit-distance → _other fallback | One more fallback layer for unusual cases; higher complexity | |
| score-based merge: merchant + keyword_preferences parallel + scoring | Most accurate but biggest testing surface; needs explicit confidence semantics for hitCount=0 seeds | |

**User's choice:** Short-circuit order, delete edit-distance.
**Notes:** `_matchEditDistance` in `FuzzyCategoryMatcher` is removed (D-08). The resolver is intentionally simpler than today's 3-signal matcher; the unified `category_keyword_preferences` table (seed + learned) already covers what edit-distance attempted to provide.

---

## Area 6 (continuation): Resolver class location + file layout

| Option | Description | Selected |
|--------|-------------|----------|
| `lib/application/voice/voice_category_resolver.dart` (recommended) | Sits with existing `voice_text_parser.dart` + `parse_voice_input_use_case.dart`; orchestrator semantics | ✓ |
| `lib/infrastructure/voice/voice_category_resolver.dart` | Follows Phase 20 NLP-in-infrastructure pattern but resolver needs domain interfaces — application is the better fit | |
| Claude discretion | Defer to planner | |

**User's choice:** Application layer.
**Notes:** Class name `VoiceCategoryResolver`, file `voice_category_resolver.dart`. `FuzzyCategoryMatcher` is fully deleted.

---

## Area 7 (continuation): Corpus test shape

| Option | Description | Selected |
|--------|-------------|----------|
| Phase 20 pattern + 5 anchor case categories (recommended) | Two Dart fixtures (zh + ja), ~30 cases each, 5 anchor types (direct L2 / merchant L2 / L1→_other / learned override / ID-drift regression), ≥95% per-locale gate | ✓ |
| Anchor-only, no statistical bucket | Simpler but loses broad-coverage signal | |
| Claude discretion | Defer | |

**User's choice:** Phase 20 pattern + 5 anchor categories.
**Notes:** Per-locale accuracy reported separately. Specific anchor cases listed in CONTEXT.md `<specifics>` section.

---

## Claude's Discretion

- Seed source format for the synonym table (Dart literal `default_synonyms.dart` next to `default_categories.dart`, OR YAML loaded once at seed time and discarded). Either is fine; planner picks based on existing seed-pattern conformance. The runtime source remains the Drift table per D-01.
- Detailed merchant → L2 mapping for the 12 entries beyond the provisional list in D-05. User reviews at PR.
- Whether `levenshtein.dart` is also deleted (depends on whether any other code path consumes `normalizedSimilarity`).
- Whether `_extractKeyword` in `ParseVoiceInputUseCase` (lines 97-113) relocates into the new resolver or stays in the use case.
- Exact INSERT policy for the seed step (recommend `INSERT OR IGNORE` to preserve any pre-existing user-learned rows).
- Whether the existing `CategoryKeywordPreferenceDao` needs a new `findBestForKeyword(keyword)` method ordered by `hitCount DESC, lastUsed DESC`, or existing surface suffices.

## Deferred Ideas

- English (en) synonym entries — backfill when English voice input lands in v1.4+ (REQUIREMENTS.md §Out of scope defers English voice for v1.3).
- MerchantDatabase becoming extensible without code changes (asset/data file) — VOICE-06 met by D-01 + D-04 in this phase; future merchant-extensibility refactor is its own work.
- Settings UI for user-configurable per-L1 default L2 — `${l1Id}_other` is the fixed convention; user-configurable defaults are v1.4+.
- Score-based merge of merchant + keyword_preferences — D-07 chose strict short-circuit. If accuracy data later argues for scoring, revisit.
- `category_keyword_preferences` sync conflict resolution — table already syncs via P2P queue; family-sync hardening (FAMILY-V2-01/02/03) is its own v1.4+ candidate.
- Phase 22 integration of resolver into shared details form (INPUT-02) + record button UX (REC-01/02) — separate phase.
- Recursive sub-L2 (level-3+) categories — out of scope; the model is strictly 2 levels.
