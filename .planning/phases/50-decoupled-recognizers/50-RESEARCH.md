# Phase 50: Decoupled Recognizers - Research

**Researched:** 2026-06-23
**Domain:** Voice NLP recognizer decoupling — anchored merchant matching + keyword-only category recognition (pure Dart, zero new deps)
**Confidence:** HIGH (all findings verified against the live codebase; no external dependencies introduced)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01 召回优先 (recall-first).** `MerchantRecognizer` returns **scored, ranked candidates** (including weak ones) for Phase 52 chips. Anchored/normalized matching replaces the old bidirectional substring (`merchant_database.dart:158` `contains||contains`). Per-script (字种) minimum-alias-length stays the anti-false-positive guardrail (research tunes the threshold against the ~40-entry adversarial corpus お米/杉並区/comment-words).
- **D-02 翻成「关键词优先」, 薄规则、不建仲裁器.** One simple merge rule: keyword hit → keyword wins (`ledgerType = resolveLedgerType(finalCategoryId)`); keyword null → merchant fallback (auto-fill only at D-03 floor). Delete `parse_voice_input_use_case.dart:106` merchant-ledger short-circuit. **No** 3×3 truth table / agreement-boost / both-weak-ask / hysteresis — all Phase 51. Bare 「スタバ」 (keyword null) still resolves to Starbucks→咖啡 (regression case required this phase).
  - **⚠ Re-slice flag (Phase 51 MUST read):** This pulls Phase 51's **XVAL-02** + **LEDGER-01** forward into Phase 50. Phase 51 plan must know: line 106 may already be deleted, keyword-priority already in.
- **D-03 提交侧「自动填充置信度地板」.** Recall is the engine's OUTPUT; the SUBMITTED result (filled into form) has a separate floor: only auto-fill the merchant default category when the best candidate ≥ floor; below floor → hang on verdict, don't auto-fill. Resolves the recall-vs-false-positive tension during the chips-less transition window. Floor height set by research against adversarial corpus.
- **D-04 全覆盖可口语 L2 (zh+ja) + 硬门禁.** Expand category-only seeds from ~120 to **full coverage of speakable L2**: every speakable activity/item L2 gets ≥1 zh + ≥1 ja seed. Pure `_other`/fallback buckets NOT required. Keep `default_synonyms.dart` Dart literals (VOICE-06 contract, may split into multiple files). **zh+ja ONLY** (English is Phase 52 VEN). **Hard gate:** `seed-keyword-categoryId-是真L2` integration test (mirrors Phase 49 D-08). SC4 gap「加油/给油/給油」→`cat_car_fuel` (currently only `ガス`→`cat_utilities_gas`). Research produces full list, **user spot-checks before commit**. ~103 L2 × zh+ja Phase-49-scale authored deliverable.
- **D-05 全切新引擎 + 删旧 DB.** Voice pipeline fully cut over to `MerchantRecognizer`/`MerchantRepository`; delete `MerchantDatabase` (13 in-memory) + `VoiceTextParser.extractAndMatchMerchant` embedded merchant matching. `MerchantRepository` gains a match-key lookup method. OCR `LookupMerchantUseCase`: grep consumers first → live consumer cut over, no consumer retire with MerchantDatabase. `VoiceCategoryResolver` evolves into `CategoryRecognizer` (delete step-1 merchant lookup; keep step-2 keyword + step-2.5 substring + `_ensureL2` + `normalizeToL2`).

### Claude's Discretion
- Engine/verdict file placement (`application/voice/recognition/` + `domain/` verdict) — concrete shape.
- Verdict model field shape + whether none/weak/strong banding lands in verdict now or Phase 51 (suggested: raw score + ranking only this phase).
- Match-key lookup: repo per-call DB query vs recognizer load-all in-memory (~400 merchants / ~1600 keys, both viable).
- Per-script minimum-alias-length threshold + submit-confidence floor height (tuned against ~40 adversarial cases).
- Whether to reuse Phase 49 `MerchantNameNormalizer` on the query side (likely yes — same normalization guarantees match).
- Full L2 keyword word list + whether to split into multiple files by category.

### Deferred Ideas (OUT OF SCOPE)
- Full 3×3 `RecognitionReconciler` + agreement-boost + both-weak-ask + STT-final-hysteresis → **Phase 51**.
- `category_ledger_configs` re-seed + `RuleEngine`/`ClassificationService` retirement → **Phase 51**.
- Alt chips UI + 3-tier confidence band + inline-correction KEYWORD reflow → **Phase 52 (RECUX)**.
- English keywords/aliases/currency words + English number-word fallback + `localeId` end-to-end → **Phase 52 (VEN)**.
- Merchant library to 600-800 / China catalog / FTS5 → **MERCH-V2**.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DECOUP-01 | `CategoryRecognizer` and `MerchantRecognizer` are mutually non-calling independent engines; remove `VoiceCategoryResolver`'s "merchant-priority short-circuit" | §Architecture Patterns (two-engine split), §Code Examples (CategoryRecognizer derived from VoiceCategoryResolver by deleting step-1); SC1. The split is *constructional*: each engine takes its own deps, neither references the other. |
| DECOUP-02 | `CategoryRecognizer` runs unconditionally — even with no merchant, resolves L2 from activity/item keywords ("加油用了400块" → 燃料/交通) | §Standard Stack (D-04 full-L2 seed), §Code Examples (seed gap 加油→cat_car_fuel), §Common Pitfalls (orphan categoryId); SC4 + four-quadrant Case B |
| DECOUP-03 | `MerchantRecognizer` identifies merchant (+ weak default category + ledger hint) independent of keyword signal — bare 「スタバ」 → Starbucks → 咖啡 | §Architecture Patterns (anchored matching algorithm), §Code Examples (normalization reuse), §Common Pitfalls (substring false positives); SC2 + SC3 |
</phase_requirements>

## Summary

Phase 50 splits the currently-entangled merchant + category recognition inside the voice pipeline into two pure-Dart engines that never call each other, cuts every consumer over to Phase 49's `MerchantRepository`/`merchant_match_keys` table, and retires the old 13-entry `MerchantDatabase`. The phase is wider than pure decoupling (user decision): it also (1) lands the thin keyword-priority merge rule early (was Phase 51), (2) expands category keyword seeds to full speakable-L2 zh+ja coverage with a hard categoryId-is-real-L2 gate (a Phase-49-scale authored deliverable), and (3) deletes the old merchant path entirely.

All of the hard machinery already exists from Phase 49: `MerchantNameNormalizer` (`normalizeMerchantKey`, zero-dep NFKC-lite + kana-fold, **idempotent**, used at seed time) is the exact normalizer to reuse on the query side; the `merchant_match_keys` table holds one pre-normalized `matchKey` row per surface form (391 merchants, 391+ surface forms, indexed, non-unique); `MerchantRepository`/`MerchantDao`/`MerchantRepositoryImpl` are wired and tested. The new `MerchantRecognizer` is a thin scorer over these match keys. The new `CategoryRecognizer` is `VoiceCategoryResolver` minus its step-1 `_merchantDatabase.findMerchant` lookup — steps 2 (exact keyword), 2.5 (substring), and the `_ensureL2`/`normalizeToL2` always-L2 net carry over verbatim.

**Primary recommendation:** Build `MerchantRecognizer` as an in-memory load-all scorer (load all ~400 merchants once via `merchantRepository.findAll()`, keepAlive provider) that normalizes the query with `normalizeMerchantKey` and scores candidates by anchored exact / prefix / containment match with a per-script minimum-key-length guardrail (kana/latin ≥ 3, kanji ≥ 2). Set the **submit auto-fill floor at the "exact-or-prefix normalized match" tier** (= score ≥ 0.85), so substring/weak candidates are returned for chips but never auto-fill. Reuse the existing `default_synonyms.dart` Dart-literal seed path verbatim for the D-04 expansion, splitting into per-L1 files, and add the `seed-keyword-categoryId-是真L2` gate as a direct clone of `default_merchants_categoryid_test.dart`.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Merchant surface-form matching (`MerchantRecognizer`) | Application (`lib/application/voice/recognition/`) | Data (`MerchantRepository`) | Recognizer is voice business logic; reads merchant DATA via the Phase-49 repo. Per v1.9 layering: recognizers → `application/voice/recognition/`. |
| Query normalization | Infrastructure (`merchant_name_normalizer.dart`) | — | Already exists (Phase 49); pure text-folding tech capability. Reuse, do not re-implement. |
| Category keyword recognition (`CategoryRecognizer`) | Application (`lib/application/voice/recognition/`) | Data (keyword prefs + category repos) | Evolved from `VoiceCategoryResolver`; pure keyword resolution over `category_keyword_preferences`. |
| Verdict / candidate-list models | Domain (`features/accounting/domain/`) | — | Plain value objects with no I/O; Domain must not import application/data/infrastructure. |
| Keyword-priority merge + auto-fill floor | Application (`ParseVoiceInputUseCase`) | — | Orchestration of two engine outputs; the thin merge rule lives in the orchestrator. |
| Merchant seed DATA + keyword seed DATA | `lib/shared/constants/` (const literals) | Data (seed use cases write to Drift) | Public non-sensitive authored data; written via existing idempotent seed paths. |
| Match-key lookup method | Domain interface (`MerchantRepository`) + Data impl (`MerchantRepositoryImpl`/`MerchantDao`) | — | Interface in domain, impl in data — established repository pattern. |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `drift` | ^2.25.0 (pinned <2.32.0) | merchant_match_keys reads | [VERIFIED: pubspec.yaml] Phase-49 data backend. CLAUDE.md: never ≥2.32.0 (drops SQLCipher easy-support). |
| `sqlcipher_flutter_libs` | ^0.6.7 | encrypted DB executor | [VERIFIED: pubspec.yaml] NEVER `sqlite3_flutter_libs`. |
| `flutter_riverpod` | ^3.1.0 | engine/use-case providers | [VERIFIED: pubspec.yaml] Riverpod 3 conventions per CLAUDE.md (provider name strips `Notifier`, `.value` not `.valueOrNull`). |
| `freezed` | ^3.0.0 | verdict/candidate models | [VERIFIED: pubspec.yaml] `Merchant`/`MerchantMatchKey`/`VoiceParseResult` are already `@freezed`. New verdict models follow suit. |

### Supporting (all in-house, zero new deps)

| Asset | Location | Purpose | Reuse As-Is? |
|-------|----------|---------|--------------|
| `normalizeMerchantKey` / `MerchantNameNormalizer.key` | `lib/infrastructure/ml/merchant_name_normalizer.dart` | query-side normalization (same as seed-side) | [VERIFIED: codebase] **Reuse verbatim** — the file's own docstring states it is "used at seed time AND, unchanged, at query time in Phase 50 (`MerchantRecognizer`)". Idempotent. |
| `merchant_match_keys` table + `MerchantDao.findAllMatchKeyRows`/`findMatchKeysFor` | `lib/data/` | match-key data backend | [VERIFIED: codebase] indexed on `matchKey` (non-unique) + `merchantId`. |
| `VoiceCategoryResolver._ensureL2` / `normalizeToL2` | `lib/application/voice/voice_category_resolver.dart` | always-L2 contract + `_other` convention + first-child net | [VERIFIED: codebase] Carries into `CategoryRecognizer` unchanged. |
| `VoiceCategoryResolver` steps 2 + 2.5 | same | exact keyword + substring fallback | [VERIFIED: codebase] Carry over; only step-1 merchant lookup is deleted. |
| `DefaultVoiceSynonyms._seed` pattern + `SeedVoiceSynonymsUseCase` | `lib/shared/constants/default_synonyms.dart`, `lib/application/accounting/` | D-04 keyword expansion path | [VERIFIED: codebase] `INSERT OR IGNORE`, `hitCount=0` sentinel, no resolver code change to extend (VOICE-06). |
| `VoiceTextParser` amount/date/keyword extraction | `lib/application/voice/voice_text_parser.dart` | preserved; only `extractAndMatchMerchant` + `_extractPotentialMerchantNames` deleted | [VERIFIED: codebase] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Reuse `normalizeMerchantKey` | `kana_kit ^2.1.1` (romaji normalization) | [CITED: ROADMAP v1.9 constraints] kana_kit is the *only* sanctioned optional dep, for seed-time romaji. v1.9 chose hand-rolled normalizer (zero new deps). Do NOT add kana_kit in Phase 50 — query normalization must be byte-identical to seed normalization, and seed already uses `normalizeMerchantKey`. |
| In-memory load-all matching | Per-call `merchant_match_keys` DB query | Both viable (~400 merchants / ~391+ keys is tiny). Load-all wins: avoids a DB round-trip per keystroke-window, keeps `MerchantRecognizer` synchronous after warm-up, mirrors `VoiceCategoryResolver._seedCache` pattern already in the codebase. Recommended. |
| Anchored normalized scoring | FTS5 / Levenshtein / fuzzy | [CITED: REQUIREMENTS Out of Scope + ROADMAP] FORBIDDEN: no FTS5 (CJK tokenization broken + SQLCipher ships no CJK tokenizer + 400 rows too small), no Levenshtein (v1.3 deleted `FuzzyCategoryMatcher` as net-negative). |

**Installation:** None. No new packages. `flutter pub run build_runner build --delete-conflicting-outputs` after adding `@freezed` verdict models / `@riverpod` engine providers.

## Package Legitimacy Audit

> No external packages are installed in this phase. All recommended building blocks are existing in-repo Dart assets or already-pinned dependencies (drift, flutter_riverpod, freezed). `kana_kit` is explicitly NOT recommended for this phase.

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```
                 ┌─────────────────────────────────────────────────┐
 voice text  →   │           ParseVoiceInputUseCase (orchestrator) │
 (+ localeId)    │  rewritten: two engines run, thin keyword-prio  │
                 └───────────────┬───────────────────┬─────────────┘
                                 │                   │ (engines NEVER call each other — DECOUP-01)
              keyword extraction │                   │ raw query (merchant candidate text)
              (VoiceTextParser,  │                   │
               kept)             ▼                   ▼
                  ┌──────────────────────┐  ┌──────────────────────────┐
                  │  CategoryRecognizer  │  │     MerchantRecognizer    │
                  │  (was VoiceCategory  │  │  normalizeMerchantKey(q)  │
                  │   Resolver − step1)  │  │   → score vs match_keys   │
                  │  step2 exact keyword │  │   → ranked candidates     │
                  │  step2.5 substring   │  │  (recall-first, D-01)     │
                  │  _ensureL2 always-L2 │  └────────────┬─────────────┘
                  └──────────┬───────────┘               │
                             │ CategoryMatchResult?       │ List<MerchantCandidate> (scored, ranked)
                             ▼                            ▼
                  ┌─────────────────────────────────────────────────────┐
                  │  Thin merge rule (D-02):                            │
                  │   keyword hit → keyword wins;                        │
                  │     ledgerType = resolveLedgerType(finalCategoryId)  │
                  │   keyword null → merchant fallback,                  │
                  │     auto-fill category ONLY if best score ≥ floor   │
                  │     (D-03); below floor → verdict only, no auto-fill │
                  └───────────────────────┬─────────────────────────────┘
                                          │
                                          ▼
                       VoiceParseResult (carries both verdicts +
                        resolvedKeyword learning-key identity 260526-pg6)
                                          │
                                          ▼
                       merchant name → ENCRYPTED transaction field
                       (never logged — zero-knowledge)

  RETIRED this phase (D-05): MerchantDatabase (13 in-memory, :158 contains||contains),
                             VoiceTextParser.extractAndMatchMerchant,
                             VoiceCategoryResolver step-1 merchant lookup.
  Data backend: merchant_match_keys table (Phase 49) — loaded once, keepAlive.
```

### Recommended Project Structure

```
lib/application/voice/recognition/        # NEW directory (v1.9 layering)
├── merchant_recognizer.dart              # MerchantRecognizer (scorer over match keys)
├── category_recognizer.dart              # CategoryRecognizer (VoiceCategoryResolver − step1)
└── (providers wired in features/accounting/presentation/providers/repository_providers.dart)

lib/features/accounting/domain/models/
├── merchant_candidate.dart               # NEW @freezed verdict/candidate (raw score + rank)
└── voice_parse_result.dart               # extend to carry merchant candidate list

lib/shared/constants/synonyms/            # OPTIONAL split of default_synonyms.dart by L1
├── synonyms_food.dart
├── synonyms_transport.dart
└── ... (aggregated by default_synonyms.dart)

lib/data/repositories/merchant_repository_impl.dart  # + findByMatchKey / loadAllForMatching
lib/data/daos/merchant_dao.dart                       # + matching query method
lib/features/accounting/domain/repositories/merchant_repository.dart  # + interface method
```

### Pattern 1: `MerchantRecognizer` — anchored normalized scoring (replaces bidirectional substring)

**What:** Normalize the query with the SAME `normalizeMerchantKey` used at seed time, then score each candidate match-key by anchored match tier. Return a ranked candidate list (recall-first).

**When to use:** Every voice merchant lookup. The old `query.contains(name) || name.contains(query)` (`merchant_database.dart:158-159`) is the anti-pattern this replaces — it false-positives at 400+ scale (お米 contains 米, 杉並区 contains a chain substring, etc.).

**Scoring tiers (recommended, all post-normalization):**

```dart
// Source: derived from merchant_name_normalizer.dart + D-01/D-03 design
// nq = normalizeMerchantKey(query); mk = row.matchKey (already normalized at seed time)
double score;
if (nq == mk)                         score = 1.00;  // exact normalized match
else if (mk.startsWith(nq) ||                          // query is an anchored prefix
         nq.startsWith(mk))           score = 0.85;  // (e.g. すたば ⊂ すたーばっくす)
else if (mk.contains(nq) &&                            // query embedded inside a longer key
         _passesScriptMinLength(nq))  score = 0.60;  // weak — recall only, below floor
else if (nq.contains(mk) &&                            // key embedded in a longer query
         _passesScriptMinLength(mk))  score = 0.55;  // weak — recall only, below floor
else                                  continue;        // no candidate
```

- `_passesScriptMinLength(s)`: per-script minimum length guardrail (the D-01 字种 guardrail). Recommended: **kana/latin ≥ 3 runes, kanji-containing ≥ 2 runes** — mirrors the existing `IN-03` guard (`merchant_database.dart:155` skips substring for <3 chars) and `VoiceCategoryResolver` step-2.5 (`s.keyword.length >= 2`). Tune against the ~40-entry adversarial corpus.
- **Ranking:** sort by score DESC, then longer matchKey first (mirrors `VoiceCategoryResolver` "longest-key-wins"). One candidate per merchant id (dedupe — a merchant has many surface forms; keep its best-scoring one).
- **D-03 submit floor: 0.85.** Only auto-fill the merchant default category when the best candidate scores ≥ 0.85 (exact or anchored-prefix tier). The 0.60/0.55 containment tiers are returned for Phase-52 chips but never auto-fill. This is the recall↔false-positive resolver: bare 「スタバ」 → すたば is an anchored prefix of すたーばっくす ⇒ 0.85 ⇒ auto-fills (SC3 ✓), while お米/杉並区 only ever reach containment tier ⇒ below floor ⇒ no auto-fill (SC2 ✓).

### Pattern 2: `CategoryRecognizer` — `VoiceCategoryResolver` minus step-1

**What:** The new engine IS the current resolver with the `_merchantDatabase` field and step-1 (`_merchantDatabase.findMerchant`) deleted. Steps 2 (exact keyword via `category_keyword_preferences`), 2.5 (substring fallback over seed + promoted-learned rows), and `_ensureL2`/`normalizeToL2` are unchanged.

**When to use:** Runs UNCONDITIONALLY on every utterance (DECOUP-02). No merchant gate.

```dart
// Source: voice_category_resolver.dart — delete lines 86-99 (step 1), drop _merchantDatabase
//  field + constructor param. Everything from "Step 2" down is unchanged.
//  resolve(extractedKeyword) returns CategoryMatchResult? exactly as today.
```

### Pattern 3: Thin keyword-priority merge (D-02) in `ParseVoiceInputUseCase`

**What:** Rewrite the orchestrator's category/ledger block. Both engines produce output; keyword wins when present.

```dart
// Source: rewrite of parse_voice_input_use_case.dart lines 70-115
final keyword = _extractKeyword(recognizedText, localeId: localeId);     // kept
final resolvedKeyword = keyword.isEmpty ? null : keyword;                  // kept (260526-pg6)

// Two engines run independently (DECOUP-01) — neither calls the other.
final categoryMatch = await _categoryRecognizer.resolve(keyword);         // unconditional
final merchantCandidates = _merchantRecognizer.recognize(recognizedText); // ranked, recall-first

CategoryMatchResult? finalCategory;
LedgerType? ledgerType;
if (categoryMatch != null) {
  // Keyword wins (D-02 + XVAL-02 brought forward).
  finalCategory = categoryMatch;
  ledgerType = await _categoryRecognizer.resolveLedgerType(categoryMatch.categoryId);
} else {
  // Keyword null → merchant fallback, auto-fill ONLY at floor (D-03).
  final best = merchantCandidates.isEmpty ? null : merchantCandidates.first;
  if (best != null && best.score >= kMerchantAutoFillFloor) {            // 0.85
    final l2 = await _categoryRecognizer.normalizeToL2(best.categoryId);
    finalCategory = CategoryMatchResult(
      categoryId: l2 ?? best.categoryId,
      confidence: best.score,
      source: MatchSource.merchant,
    );
    // LEDGER-01 (brought forward): ledger is a pure fn of the FINAL category,
    // NOT merchant.ledgerHint. DELETE old line 106 `ledgerType = merchantMatch.ledgerType`.
    ledgerType = await _categoryRecognizer.resolveLedgerType(finalCategory.categoryId);
  }
  // below floor → finalCategory stays null; candidates still surfaced on verdict.
}
```

**Key deletions (confirm in plan):**
- `parse_voice_input_use_case.dart:106` `ledgerType = merchantMatch.ledgerType;` (merchant-ledger short-circuit) — DELETE. Ledger now derives from final category (LEDGER-01 brought forward).
- `voice_text_parser.dart` `extractAndMatchMerchant` (lines 504-519) + `_extractPotentialMerchantNames` (lines 521-567) — DELETE (D-05). amount/date/keyword extraction stays.
- `voice_category_resolver.dart` step-1 (lines 86-99) + `_merchantDatabase` field/param — DELETE (becomes `CategoryRecognizer`).
- `merchant_database.dart` whole file — DELETE (D-05).

### Anti-Patterns to Avoid

- **Bidirectional substring (`query.contains(x) || x.contains(query)`):** the exact thing being retired. At 400+ merchants this false-positives catastrophically (お米→米屋 chains, 杉並区→区-suffixed names). Replaced by anchored tiers + script-min-length.
- **Engines calling each other:** DECOUP-01 requires constructional independence. `MerchantRecognizer` must not import/take `CategoryRecognizer` and vice-versa. The merge happens only in the orchestrator.
- **Deriving ledger from merchant hint:** `merchant.ledgerHint` is explicitly NON-authoritative (Phase 49 D-09). Ledger = `resolveLedgerType(finalCategoryId)`. Stamping a merchant's ledger onto a keyword-won category is the desync bug (Pitfall 2 in the v1.9 map).
- **Auto-filling weak recall:** without chips UI (Phase 52), a low-score merchant candidate that auto-fills IS the false-positive regression. The D-03 floor is the guard.
- **Re-normalizing query differently from seed:** any divergence between query normalization and `merchant_match_keys.matchKey` normalization silently misses. Use `normalizeMerchantKey` for both.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| NFKC + 片↔平 kana fold + 全角/halfwidth + dakuten compose | a second normalizer | `normalizeMerchantKey` (Phase 49) | Already idempotent, zero-dep, used at seed time; a second one guarantees query≠key divergence. |
| Always-L2 contract (`_other` convention + first-child net) | re-derive L2 logic | `VoiceCategoryResolver._ensureL2`/`normalizeToL2` | Carries into `CategoryRecognizer`; battle-tested across Phase 21-23 corpus. |
| Keyword seed write path | new seed loader | `SeedVoiceSynonymsUseCase` + `DefaultVoiceSynonyms._seed` | `INSERT OR IGNORE`, `hitCount=0` sentinel, self-healing; VOICE-06 contract (add a literal, no code change). |
| categoryId-is-real-L2 gate | bespoke validator | clone `default_merchants_categoryid_test.dart` | Phase 49 D-08 gate is a direct template; build the L2 set from `DefaultCategories.all.where((c)=>c.level==2)`. |
| match-key data backend | new table/index | `merchant_match_keys` + `MerchantDao` | Indexed, non-unique, point-in-time-consistent reads already implemented. |
| amount/date extraction | touch the parser | leave `VoiceTextParser` intact | Only the embedded merchant matching is deleted; the rest is heavily corpus-tested. |

**Key insight:** This phase is ~80% deletion + rewiring of existing, tested components and ~20% new authored DATA (the full-L2 keyword seed). The only genuinely new logic is the `MerchantRecognizer` scorer (~60 lines) and the verdict model. Resist building new infrastructure.

## Runtime State Inventory

> This is a refactor/retirement phase (deletes `MerchantDatabase`, rewires consumers). Inventory below.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | `merchant_match_keys` + `merchants` tables already seeded (Phase 49, schema v22). No data migration needed — Phase 50 only adds a READ path. `category_keyword_preferences` gains new seed rows (D-04) via existing `INSERT OR IGNORE` — additive, idempotent, no schema change. | Code-only (new read method + new seed rows). NO migration, NO schema bump (stays v22). |
| Live service config | None — fully offline/local. | None. |
| OS-registered state | None. | None. |
| Secrets/env vars | None. Resolved merchant name flows into the already-encrypted transaction merchant field (never logged — zero-knowledge security constraint). | None — preserve no-log discipline in new engine. |
| Build artifacts | `@freezed` verdict model + `@riverpod` engine providers require codegen; deleting `merchant_database.dart` orphans no `.g.dart`. | `flutter pub run build_runner build --delete-conflicting-outputs` after model/provider edits. |

**Consumer-retirement grep (D-05) — VERIFIED:**
- `MerchantDatabase` consumers (live, non-test): `voice_category_resolver.dart` (→ becomes CategoryRecognizer, drop dep), `parse_voice_input_use_case.dart` (→ rewrite), `voice_text_parser.dart` (→ drop `extractAndMatchMerchant`), `lib/application/ml/lookup_merchant_use_case.dart` + its provider, `lib/features/accounting/presentation/providers/repository_providers.dart` (provider wiring). All must be cut over or deleted.
- **OCR `LookupMerchantUseCase`:** has a use case + provider (`lib/application/ml/repository_providers.dart:27`) + a unit test, BUT **no screen/widget consumer** (grep found only its own provider definition references it; `kOcrEntryEnabled = false` and the OCR scanner screen does not call it). [VERIFIED: grep] → **Retire it with `MerchantDatabase`** (D-05: no live consumer). Delete `lookup_merchant_use_case.dart`, its provider in `application/ml/repository_providers.dart`, and its test. If the planner wants to preserve an OCR merchant-lookup seam for MOD-005, re-point `LookupMerchantUseCase` at `MerchantRecognizer` instead — but with zero current consumers, deletion is the cleaner D-05 path.
- **`ClassificationService` (`lib/application/dual_ledger/classification_service.dart`):** its `MerchantDatabase` reference is a **dead TODO comment only** (`// TODO: Implement MerchantDatabase lookup` — never wired). It has live consumers (`create_transaction_use_case.dart`) but does NOT actually call MerchantDatabase. [VERIFIED: grep] → **Out of scope for Phase 50** (RuleEngine/ClassificationService retirement is Phase 51 LEDGER-02). Just ensure deleting `merchant_database.dart` doesn't break its imports — it only has a comment, so no import to fix. Confirm in plan.

## Common Pitfalls

### Pitfall 1: Query/seed normalization divergence
**What goes wrong:** `MerchantRecognizer` normalizes the query differently from how `merchant_match_keys.matchKey` was computed at seed time → exact matches silently miss (スタバ never finds すたば).
**Why it happens:** Writing a fresh normalizer, or only lowercasing, instead of reusing `normalizeMerchantKey`.
**How to avoid:** Call `normalizeMerchantKey(query)` (or `MerchantNameNormalizer.key`) — the literal same function Phase 49's seed used. It is idempotent, so double-normalization is safe.
**Warning signs:** Test `normalizeMerchantKey('スタバ') == 'すたば'` and assert the seed row for Starbucks has `matchKey == 'すたば'`.

### Pitfall 2: Substring false positives at scale (the whole point of SC2)
**What goes wrong:** お米 (rice) matches a 米-containing chain; 杉並区 (a ward) matches a chain whose name is a substring; comment-words match random merchants.
**Why it happens:** Containment scoring without a script-aware length guardrail, or auto-filling containment-tier candidates.
**How to avoid:** (a) per-script min-length on containment tiers (kana/latin ≥3, kanji ≥2); (b) D-03 floor of 0.85 keeps containment (0.55-0.60) out of auto-fill. Build `merchant_false_positive_test.dart` with the ~40-entry adversarial corpus asserting "no match OR score < floor".
**Warning signs:** Any adversarial entry producing a candidate ≥ 0.85.

### Pitfall 3: Orphan categoryId in the D-04 seed (silent null)
**What goes wrong:** A seeded keyword points at a categoryId that isn't a real L2 (typo, removed id, or an L1 that `_ensureL2` can't resolve) → resolves to null, keyword silently dead.
**Why it happens:** ~103×2 hand-authored seeds; a single typo is invisible at runtime.
**How to avoid:** The `seed-keyword-categoryId-是真L2` hard gate (mirror Phase 49 D-08). Note: existing seeds legitimately use L1 ids (e.g. `食事`→`cat_food`) relying on `_ensureL2`'s `_other` fallback. The gate must therefore allow **either a real L2 id OR an L1 id that `_ensureL2` resolves to a real L2** — clone the Phase-49 test but extend the legal set to include L1 ids whose `_other`/first-child resolves. Simplest: assert every seeded categoryId is in `DefaultCategories.all.map((c)=>c.id)` AND (level==2 OR has at least one L2 child).
**Warning signs:** Gate test names offending `keyword -> categoryId` rows.

### Pitfall 4: Learning-key identity break (260526-pg6 regression)
**What goes wrong:** The `resolvedKeyword` written for correction diverges from the key `CategoryRecognizer` later looks up → orphan learned rows that never match.
**Why it happens:** Rewriting the orchestrator and re-extracting the keyword on a different path than the resolver uses.
**How to avoid:** Keep `_extractKeyword` as the SINGLE source of the canonical key (it already is, lines 86-87), pass that exact string to `CategoryRecognizer.resolve`, and surface it as `resolvedKeyword`. Do not re-extract.
**Warning signs:** Correction taught then same utterance not resolving.

### Pitfall 5: Bare-merchant regression lost (SC3)
**What goes wrong:** After moving to keyword-priority, bare 「スタバ」 (no keyword hit) stops resolving because the merchant fallback floor is set too high or the prefix tier isn't scored ≥ floor.
**Why it happens:** Treating すたば⊂すたーばっくす as containment (0.60) instead of anchored prefix (0.85).
**How to avoid:** Score `mk.startsWith(nq)` (key starts with normalized query) at the 0.85 prefix tier — an abbreviation IS an anchored prefix of the full name. Add the four surface forms (スタバ / ｽﾀﾊﾞ half-width / マクド Kansai / Starbucks romaji) as explicit regression cases. (マクド and マック are already aliases in the Phase-49 dining seed — verified.)
**Warning signs:** Bare-スタバ test returns null or below-floor.

## Code Examples

### Adding the match-key lookup method (Claude's-discretion #3 → load-all recommended)

```dart
// Source: extend lib/features/accounting/domain/repositories/merchant_repository.dart
abstract class MerchantRepository {
  // ... existing findAll / hasAny / findById / insertBatch ...

  /// Return every match-key row paired with its merchant's category/ledger hint,
  /// for in-memory recognizer matching. Loaded once (keepAlive); ~391+ rows.
  Future<List<MerchantMatchEntry>> loadAllForMatching();
}

// MerchantMatchEntry: a flat @freezed record { matchKey, surface, merchantId,
// nameJa/nameZh/nameEn, categoryId, ledgerHint }. Built in MerchantRepositoryImpl
// by joining findAllMatchKeyRows() against findAllMerchantRows() in one read tx.
```

Alternatively, `findByMatchKey(String normalizedKey)` for per-call DB lookup — viable but adds a round-trip per recognition; load-all is recommended given the tiny table.

### The D-04 seed gap that SC4 names

```dart
// Source: lib/shared/constants/default_synonyms.dart — currently MISSING.
// Add (zh + ja) for cat_car_fuel (fuel under cat_car, NOT cat_utilities_gas):
_seed('加油', 'cat_car_fuel'),   // zh — refuel
_seed('给油', 'cat_car_fuel'),   // zh variant
_seed('給油', 'cat_car_fuel'),   // ja/zh-TW — refuel
_seed('ガソリン', 'cat_car_fuel'), // ja — gasoline
// Existing seed only has ガス→cat_utilities_gas (household gas), which is why
// 「加油用了400块」 currently mis-resolves. cat_car_fuel is a real L2 (verified).
```

### The categoryId-is-real-L2 hard gate (clone of Phase 49)

```dart
// Source: clone of test/unit/shared/constants/default_merchants_categoryid_test.dart
// Build legal set; allow L1 ids that _ensureL2 resolves (existing seeds use them).
final allIds = DefaultCategories.all.map((c) => c.id).toSet();
final l2Ids  = DefaultCategories.all.where((c) => c.level == 2).map((c) => c.id).toSet();
final l1WithChild = DefaultCategories.all
    .where((c) => c.level == 1 &&
        DefaultCategories.all.any((x) => x.parentId == c.id))
    .map((c) => c.id).toSet();

for (final s in DefaultVoiceSynonyms.all) {
  final ok = l2Ids.contains(s.categoryId) || l1WithChild.contains(s.categoryId);
  expect(ok, isTrue,
    reason: 'Seed keyword "${s.keyword}" -> ${s.categoryId} is neither a real L2 '
            'nor an L1 with an L2 child (silent-null risk)');
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| 13-entry in-memory `MerchantDatabase` + bidirectional substring | 391-merchant Drift `merchant_match_keys` + anchored normalized scoring | Phase 49 (data) → Phase 50 (matching) | No substring explosion at scale; ranked recall for chips. |
| Merchant lookup inside `VoiceCategoryResolver` step-1, gating category | Two independent engines, category runs unconditionally | Phase 50 (DECOUP-01/02) | Keyword intent owns category; merchant supplements. |
| Ledger = `merchantMatch.ledgerType` (line 106 short-circuit) | Ledger = `resolveLedgerType(finalCategoryId)` pure fn | Phase 50 (LEDGER-01 pulled forward) | No category/ledger desync (星巴克买杯子 → 购物/悦己). |
| ~120 zh/ja keyword seeds (~16 L2 covered) | Full speakable-L2 zh+ja (~103 L2) + hard gate | Phase 50 (D-04) | Category-only path works for most everyday utterances. |

**Deprecated/outdated:**
- `MerchantDatabase` (`lib/infrastructure/ml/merchant_database.dart`): retire entirely (D-05).
- `MerchantMatch` infra type: replaced by domain `MerchantCandidate` verdict model.
- `LookupMerchantUseCase` (`lib/application/ml/`): retire (no live consumer) or re-point at `MerchantRecognizer`.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Submit auto-fill floor = 0.85 (exact/prefix tier); containment tiers 0.55-0.60 | Pattern 1 / D-03 | Floor too low → false-positive auto-fills regress SC2; too high → bare-スタバ stops auto-filling (SC3). **Must be tuned against the ~40-entry adversarial corpus at plan/impl time** — this number is a research recommendation, not a measured value. User/planner should confirm via the false-positive test. |
| A2 | Per-script min length: kana/latin ≥3, kanji ≥2 runes | Pattern 1 | Wrong thresholds change which adversarial entries pass. Derived from existing IN-03 (<3) + step-2.5 (≥2) guards; validate against corpus. |
| A3 | `OCR LookupMerchantUseCase` has no live UI consumer → retire | Runtime State Inventory | If a hidden consumer exists, retiring breaks it. Grep verified only provider+test reference it and `kOcrEntryEnabled=false`; planner should re-grep at impl time. |
| A4 | "Speakable L2" ≈ 103 of the 138 total L2 ids (excluding pure `_other`/fallback + non-speakable admin buckets like cat_tax_*, cat_asset_*) | D-04 | Under-coverage misses utterances; over-coverage wastes effort on un-speakable categories (e.g. cat_asset_ideco). The exact speakable set is an authoring judgment requiring **user spot-check before commit** (D-04 mandates this). |
| A5 | Load-all in-memory matching (not per-call DB) is the better choice | Pattern 1 / Code Examples | If merchant table grows toward 600-800 (MERCH-V2) load-all is still fine (~1600 keys); only matters at thousands. Safe for v1.9. |
| A6 | No schema bump needed (stays v22) | Runtime State Inventory | Phase 50 is read-only over Phase-49 tables + additive keyword seeds. If a new column is wanted for scoring, that's a v22→v23 bump — not anticipated. |

**The A1 floor and A2 thresholds are the load-bearing assumptions.** They are explicitly deferred to research-tunes-against-corpus by CONTEXT; the planner must treat the adversarial-corpus test as the acceptance gate that validates these numbers, not assume the values are final.

## Open Questions

1. **Exact "speakable L2" set for D-04 (~103 of 138).**
   - What we know: 138 total L2 ids; ~16 currently have keyword seeds. Pure `_other`/fallback excluded per D-04. Admin/non-speakable buckets (cat_tax_*, cat_asset_*, cat_insurance_*, cat_special_*) are unlikely to be voice-spoken as activities.
   - What's unclear: the precise inclusion line (is "ふるさと納税" cat_tax_furusato speakable? probably yes; "iDeCo" cat_asset_ideco? edge). 
   - Recommendation: Plan it as a dedicated authoring wave/plan (like Phase 49's `DefaultMerchants`). Research/planner drafts the full list, **user spot-checks before commit** (D-04 mandate). Err toward including borderline cases — over-coverage is cheap, the gate catches typos.

2. **Verdict model granularity — banding now or Phase 51?**
   - What we know: CONTEXT suggests "raw score + ranking only this phase; none/weak/strong banding → Phase 51 reconciler."
   - What's unclear: whether the orchestrator's D-03 floor implies a minimal "auto-fill / no-auto-fill" boolean on the verdict.
   - Recommendation: `MerchantCandidate { merchantId, displayName, score, categoryId, ledgerHint }` (raw score only); the floor comparison lives in the orchestrator, not the model. Leaves 3×3 banding cleanly to Phase 51.

3. **Does `CategoryRecognizer` keep the same provider name / shape?**
   - What we know: `voiceCategoryResolverProvider` exists; consumers reference it.
   - Recommendation: Rename `VoiceCategoryResolver` → `CategoryRecognizer` and move to `application/voice/recognition/`; update the provider + `ParseVoiceInputUseCase` wiring. Riverpod 3: provider name derives from class — `categoryRecognizerProvider`. Update all test imports.

## Environment Availability

> Skipped — phase is code/config + authored-data changes only over existing Phase-49 Drift tables. No new external tools, services, or runtimes. Build toolchain (`flutter`, `build_runner`) already in use.

## Validation Architecture

> nyquist_validation is enabled (config.json `workflow.nyquist_validation: true`).

### Test Framework
| Property | Value |
|----------|-------|
| Framework | `flutter_test` (+ `integration_test` for encrypted-DB ladders) |
| Config file | none (default flutter test discovery) |
| Quick run command | `flutter test test/unit/application/voice/ test/unit/application/voice/recognition/` |
| Full suite command | `flutter test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DECOUP-01 | engines constructionally independent; (merchant✓ keyword✓) produces both outputs, no short-circuit | unit | `flutter test test/unit/application/voice/parse_voice_input_use_case_test.dart` | ⚠️ rewrite (exists for old shape) |
| DECOUP-01 | merchant✓ keyword✓「在星巴克买杯子」→ 购物 (keyword wins, XVAL-02 pulled fwd) | unit | (same four-quadrant test) | ❌ Wave 0 |
| DECOUP-02 | merchant✗ keyword✓「加油用了400块」→ cat_car_fuel | unit/integration | `flutter test test/integration/voice/voice_category_corpus_*` | ⚠️ extend corpus |
| DECOUP-02 | full-L2 seed: every speakable L2 categoryId is real (hard gate) | unit | `flutter test test/unit/shared/constants/default_synonyms_categoryid_test.dart` | ❌ Wave 0 (clone of merchants gate) |
| DECOUP-03 | bare「スタバ」/ｽﾀﾊﾞ / マクド / Starbucks → merchant + 咖啡 (each surface) | unit | `flutter test test/unit/application/voice/recognition/merchant_recognizer_test.dart` | ❌ Wave 0 |
| DECOUP-03 (SC2) | adversarial corpus (お米/杉並区/comment-words ~40) → no/low match | unit | `flutter test test/unit/application/voice/recognition/merchant_false_positive_test.dart` | ❌ Wave 0 |
| (invariant) | normalizeMerchantKey(query) == seed matchKey for known forms | unit | `flutter test test/unit/infrastructure/ml/merchant_name_normalizer_test.dart` | ✅ exists (extend) |
| (regression) | resolvedKeyword write-key == recognizer read-key (260526-pg6) | unit | (in parse use-case test) | ⚠️ preserve |

### Sampling Rate
- **Per task commit:** `flutter test test/unit/application/voice/recognition/ test/unit/application/voice/parse_voice_input_use_case_test.dart`
- **Per wave merge:** **FULL** `flutter analyze` (0 issues) + `flutter test` (MEMORY.md: scoped tests miss architecture tests like hardcoded_cjk_ui_scan, provider_graph_hygiene; post-merge gate must run the full suite).
- **Phase gate:** Full suite green + `flutter analyze` 0 issues before `/gsd-verify-work`.

### Wave 0 Gaps
- [ ] `test/unit/application/voice/recognition/merchant_recognizer_test.dart` — scoring tiers + ranking + four surface forms (DECOUP-03/SC3)
- [ ] `test/unit/application/voice/recognition/merchant_false_positive_test.dart` — ~40-entry adversarial corpus (SC2); validates A1 floor + A2 thresholds
- [ ] `test/fixtures/merchant_false_positive_corpus.dart` — the ~40 adversarial entries (お米/杉並区/comment-words)
- [ ] `test/unit/shared/constants/default_synonyms_categoryid_test.dart` — clone of `default_merchants_categoryid_test.dart`, extended to allow `_ensureL2`-resolvable L1 ids
- [ ] `test/unit/application/voice/parse_voice_input_use_case_test.dart` — REWRITE for two-engine + keyword-priority + floor + four-quadrant (merchant✓keyword✓ / merchant✓keyword✗ / merchant✗keyword✓ / merchant✗keyword✗)
- [ ] `test/unit/application/voice/recognition/category_recognizer_test.dart` — port `voice_category_resolver_test.dart`, drop merchant-step assertions
- [ ] Architecture: confirm `provider_graph_hygiene_test.dart` still passes after provider rename; no `UnimplementedError` providers

## Security Domain

> `security_enforcement` absent in config → treated as enabled. This phase touches voice transcript data and the encrypted merchant field.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V5 Input Validation | yes | Voice transcript is untrusted external input; `normalizeMerchantKey` + bounded scoring are the validation boundary. No raw-SQL interpolation — `MerchantDao` uses parameterized Drift companions/`customSelect` (verified). |
| V6 Cryptography | yes (indirect) | Resolved merchant name flows into the ALREADY-encrypted transaction merchant field (ChaCha20-Poly1305 field encryption). Do not add a plaintext store. Never implement crypto in the recognizer. |
| V7 Error/Logging | yes | **Never log raw transcript / amount / merchant** (zero-knowledge, CLAUDE.md + ROADMAP security constraint). New engines must not `print`/log query strings or candidate names. |
| V2/V3/V4 (auth/session/access) | no | No auth surface in this phase. |

### Known Threat Patterns for {pure-Dart recognizer over Drift}

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| SQL injection via merchant query | Tampering | Parameterized Drift queries only (already enforced in `MerchantDao`); recognizer never builds raw SQL from the transcript. |
| Sensitive-data leak via logs | Information Disclosure | No logging of transcript/amount/merchant; seed list is public non-sensitive data and may be referenced, but user utterances may not. |
| Learning-table poisoning across facets | Tampering | Corrections teach the KEYWORD table only, never the merchant table (260526-pg6); `resolvedKeyword` identity contract preserved. |

## Sources

### Primary (HIGH confidence — live codebase, verified this session)
- `lib/infrastructure/ml/merchant_name_normalizer.dart` — query/seed normalizer (idempotent, zero-dep); docstring confirms Phase-50 query reuse intent.
- `lib/infrastructure/ml/merchant_database.dart` — retirement target; `:158-159` bidirectional substring; `:155` IN-03 <3-char guard.
- `lib/application/voice/parse_voice_input_use_case.dart` — orchestrator; `:106` merchant-ledger short-circuit (delete target); `:86-87` canonical keyword (260526-pg6).
- `lib/application/voice/voice_category_resolver.dart` — `CategoryRecognizer` evolution source; step-1 (delete), steps 2/2.5, `_ensureL2`/`normalizeToL2`.
- `lib/application/voice/voice_text_parser.dart` — `extractAndMatchMerchant` (`:504-519`) + `_extractPotentialMerchantNames` (delete targets); amount/date/keyword (keep).
- `lib/features/accounting/domain/repositories/merchant_repository.dart`, `lib/data/daos/merchant_dao.dart`, `lib/data/repositories/merchant_repository_impl.dart`, `lib/data/tables/merchant_match_keys_table.dart`, `lib/features/accounting/domain/models/merchant.dart` — Phase-49 data backend (add match-key lookup method here).
- `lib/shared/constants/default_synonyms.dart` (159 lines, ~120 seeds, ~16 L2 covered), `lib/shared/constants/default_categories.dart` (138 L2 ids), `lib/shared/constants/merchants/*.dart` (391 merchants; マクド/マック already aliased), `lib/application/accounting/seed_voice_synonyms_use_case.dart` — D-04 expansion source + write path.
- `test/unit/shared/constants/default_merchants_categoryid_test.dart` — Phase-49 D-08 hard-gate template.
- `lib/application/ml/lookup_merchant_use_case.dart` + grep — OCR consumer (no live consumer; `kOcrEntryEnabled=false`).
- `lib/application/dual_ledger/classification_service.dart` — MerchantDatabase reference is a dead TODO comment only.
- `lib/features/accounting/presentation/providers/repository_providers.dart` — provider wiring (rename target).
- `.planning/config.json` — nyquist_validation true; security_enforcement absent (=enabled).

### Secondary (MEDIUM confidence)
- `.planning/ROADMAP.md` §Phase 50/51/52 + v1.9 constraints + pitfall→test map — scope fences, layering, forbidden deps.
- `.planning/REQUIREMENTS.md`, `50-CONTEXT.md`, `50-DISCUSSION-LOG.md` — decisions D-01..D-05, re-slice flags.
- `MEMORY.md` (project) — post-merge full-suite gate gotcha, l10n generated uncommitted, learning-key identity.

### Tertiary (LOW confidence)
- None — no WebSearch was needed; all findings are codebase-verified.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — every recommended asset exists and is verified in the repo; zero new deps.
- Architecture: HIGH — the two-engine split is a mechanical refactor of existing tested code; placement dictated by v1.9 layering constraints.
- Pitfalls: HIGH — each pitfall maps to a verified code line or a named v1.9 regression test.
- Tuning values (A1 floor 0.85, A2 thresholds): MEDIUM — sound defaults from existing guards, but explicitly require corpus validation at impl time (CONTEXT defers them to research-against-corpus).
- D-04 speakable-L2 set: MEDIUM — scale (~103) is clear; exact membership needs user spot-check (D-04 mandate).

**Research date:** 2026-06-23
**Valid until:** 2026-07-23 (stable — pure-Dart in-house components, no fast-moving external deps; only invalidated by schema/dep changes).
