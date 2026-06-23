# Project Research Summary

**Project:** Home Pocket (まもる家計簿) — v1.9 voice category & merchant recognition redesign
**Domain:** Offline-first, on-device voice expense-entry recognition (category + Japanese merchant, decoupled & cross-validated) for a local-first dual-ledger kakeibo Flutter app
**Researched:** 2026-06-23
**Confidence:** HIGH

## Executive Summary

v1.9 is a **layered decomposition + an arbitration insert, not a rewrite, and it needs essentially ZERO new heavy dependencies.** The existing voice pipeline already has the right bones — a use-case orchestrator (`ParseVoiceInputUseCase`), a category resolver, a merchant lookup, two learning tables (`category_keyword_preferences` / `merchant_category_preferences`), and a DB-backed ledger resolver (`CategoryService.resolveLedgerType`). What it lacks is **independence** (today merchant matching is embedded in `VoiceTextParser` AND short-circuits the category resolver) and **arbitration** (there is no place where two independent verdicts are reconciled). The redesign splits the pipeline into two pure-Dart engines — `MerchantRecognizer` and `CategoryRecognizer` that never call each other — and inserts a pure-domain `RecognitionReconciler` that combines their verdicts. The whole thing is in-house Dart over existing infra; the only structurally new artifact is a Drift `merchants` table (schema v21→v22) holding a hand-curated ~600-800-row Japanese merchant catalog. The single (optional) candidate package is `kana_kit` for kana/romaji normalization.

The recommended approach is **dictionary + deterministic rules + curated data + a correction-learning loop — explicitly NOT the embedding/ML path** that the v1.3-era prior research (`voice-category-recognition-improvements.md`) floated as the eventual accuracy ceiling. That embedding fallback (~40 MB asset) remains the v2+ ceiling but is deliberately out of v1.9 scope; v1.9 instead realizes that research's cheap-compounding "Option F" (close the active-learning loop, record the FULL extracted keyword) as a first-class part of the new UX. The two utterances the milestone is judged against are **Case A** 「在星巴克买了个杯子」→ 购物 (keyword intent beats the merchant's cafe default) and **Case B** 「加油用了400块」→ fuel (a merchant-less, category-only resolution). Both are only servable once the engines are decoupled and run unconditionally in parallel.

The dominant risks are all about **getting the edges right, not the happy path.** Cross-validation is a none/weak/strong 3×3 truth table (NOT a literal "keyword always wins" — a bare 「スタバ」 must still let the merchant win, a weak keyword must not veto a strong merchant, both-weak falls to ask-user). The 600-800-row merchant matcher will produce silent false-positives from the existing bidirectional-`contains` strategy at scale (短 kana aliases like スギ/コメ collide on incidental overlap) and must be rewritten to anchored/token matching with NFKC + kana-fold normalization. Removing the merchant short-circuit without re-homing `ledgerType` will silently desync the daily/joy split that every downstream aggregate reads. And the new recognition UX is fresh surface where ADR-012 anti-gamification violations (a "95% score", a "corrections streak") can slip past the existing anti-toxicity sweeps. Each of these has a documented prevention and a named regression test.

## Key Findings

### Recommended Stack

v1.9 adds **no heavy dependencies**: the decoupled engines, cross-validation, and category-only logic are pure in-house Dart over the existing voice infra; the merchant library is a new Drift table + curated seed data with no external dataset import. Explicitly REJECTED: FTS5 (CJK tokenization is broken by default and SQLCipher ships no custom CJK tokenizer; the 600-800-row set is too small to need an inverted index anyway), Levenshtein/fuzzy-match libs (v1.3 already deleted `FuzzyCategoryMatcher` as net-negative), TFLite/embeddings/on-device LLM, any cloud NLU (breaks zero-knowledge), and bumping `drift` past 2.31.0 (≥2.32.0 drops easy SQLCipher support). See `.planning/research/STACK.md`.

**Core technologies:**
- `drift` **2.31.0** (keep) — new `merchants` table, schema v21→v22 — established migration pattern; do NOT bump to ≥2.32.0 (breaks the SQLCipher story).
- `sqlcipher_flutter_libs` **0.6.8** (keep) — encrypts merchant catalog at rest — pinned by CLAUDE.md; never `sqlite3_flutter_libs`.
- `speech_to_text` **7.3.0** (keep) — en-US already returns Arabic digits — no spelled-out English numeral state machine needed (verify on-device in UAT, non-blocking).
- `kana_kit` **^2.1.1** (the ONLY candidate new dep, OPTIONAL) — kana ⇄ romaji normalization for the merchant `matchKey` — pure Dart, MIT, SDK-compatible. Hand-rolled NFKC + katakana→hiragana + fullwidth/lowercase covers the 80% case if zero new deps is preferred; kana_kit's marginal value is romaji handling.
- `flutter_riverpod`/`freezed` (keep) — wire the two new recognizer providers + verdict value objects.

### Expected Features

The full feature landscape is in `.planning/research/FEATURES.md`. Neither major JP competitor (Zaim, MoneyForward ME) does utterance-level cross-validation — they classify by merchant only and would book the Starbucks cup as cafe. "Keyword beats merchant on conflict" is the headline differentiator, made possible because a voice app hears intent.

**Must have (table stakes):**
- Decoupled `CategoryRecognizer` + `MerchantRecognizer` — the milestone's premise; nothing works without it.
- Keyword-intent-priority cross-validation — the user-confirmed correctness rule (serves Case A).
- Category-only path — serves Case B; mostly falls out of decoupling.
- JP merchant DB migration + national-chain spine load (~150-250 chains capture the bulk of *spoken everyday* spend).
- Confidence band (3-tier, not a raw %) + alternative chips + inline correction → learning.
- Daily/Joy rule rework reading the FINAL cross-validated category.
- EN pragmatic path — aliases/keywords/currency words; no EN number state machine.

**Should have (competitive):**
- Conflict-aware resolution (keyword beats merchant) — the differentiator competitors structurally cannot do.
- Region-tagged, multi-variant merchant schema — future CN expansion + OCR (MOD-005) reuse.
- Learning that generalizes the KEYWORD, not the merchant — correcting 「买杯子」→shopping must teach `category_keyword_preferences`, NOT pollute `merchant_category_preferences` (that would wreck the next coffee entry).

**Defer (v2+):**
- Regional/depachika rows toward the 600-800 ceiling (load after the national spine proves out).
- "Why this category" transparency tooltip; two-facet independent merchant/category correction.
- On-device embedding-similarity fallback (the accuracy ceiling; ~40 MB asset — defer until correction-loop data justifies it).

**Anti-features (hard-excluded):** any scoring/streak/badge/accuracy-% around recognition (ADR-012 permanent block), confidence as a precise percentage, auto-commit of low-confidence guesses, cloud NLU, an exhaustive every-store-in-Japan DB, punitive copy.

### Architecture Approach

The integration (full detail in `.planning/research/ARCHITECTURE.md`) extracts two independent recognizers into `lib/application/voice/recognition/`, inserts a pure-domain reconciler, migrates the 13-entry in-memory `MerchantDatabase` to a seeded Drift table, and keeps both learning tables structurally unchanged. `ParseVoiceInputUseCase` becomes a thin coordinator: parse → run both recognizers in parallel → reconcile → resolve ledger from the final category. Thin-Feature rule respected: recognizers/use case in `application/`, reconciler + verdict models + repo interface in `domain/`, table/DAO/repo-impl in `data/`.

**Major components:**
1. `MerchantRecognizer` (application, NEW) — independent merchant identification via `MerchantRepository`; merchant's default category is a **weak signal only**, its `ledgerType` a **hint only**, never authoritative.
2. `CategoryRecognizer` (application, NEW) — independent keyword-intent → L2 category; absorbs the non-merchant half of `VoiceCategoryResolver` + `_extractKeyword`; runs **unconditionally** (this is the category-only path).
3. `RecognitionReconciler` (domain, pure, NEW) — the none/weak/strong arbitration: agreement → boost, conflict → keyword wins, merchant fallback when keyword absent, both-weak → ask-user.
4. `merchants` Drift table + DAO + repo + `japan_merchants.json` asset (data, NEW) — region + multi-locale-name + normalized-key schema, v21→v22, idempotent upsert seeding, explicit `CREATE INDEX`.
5. `category_ledger_configs` re-seed (data, MODIFIED) — the daily/joy rework target.

### Critical Pitfalls

Top 5 of 10 from `.planning/research/PITFALLS.md`:

1. **Bidirectional-substring merchant false-positives at scale** — the current `query.contains(alias) || alias.contains(query)` matcher fires on incidental overlap once short kana aliases (スギ/コメ/丸) multiply 50×, silently forcing wrong category+ledger. Avoid: anchored/token-boundary matching, per-script min alias length, ranked-candidates-with-scores (not first-match-wins), and a `merchant_false_positive_test.dart` adversarial corpus.
2. **Ledger desync when removing the merchant short-circuit** — if category decouples but merchant `ledgerType` still flows through, a keyword-resolved 购物/joy entry gets stamped daily. Avoid: make ledger a **pure function of the FINAL categoryId** via `resolveLedgerType` AFTER reconciliation; drop the merchant `ledgerType` routing input; invariant test `ledgerType == resolveLedgerType(finalCategoryId)` on every path.
3. **Cross-validation mis-fires on weak/absent signals** — "keyword wins" must NOT mean "keyword's null wins" (bare 「スタバ」 → merchant wins); a weak `コップ` must not veto a 0.90 Starbucks hit; both-weak → ask-user; "agreement" defined at L1/ledger granularity. Avoid: an explicit 3×3 truth table baked into `cross_validation_test.dart`.
4. **Japanese name-variant gaps** — スタバ/スターバックス/Starbucks/ｽﾀﾊﾞ/マクド(関西) all miss if the seed stores only canonical kanji; misses are invisible (resolve to null). Avoid: NFKC + lowercase + katakana↔hiragana fold + long-vowel/sokuon-tolerant key, computed at SEED time into a stored normalized-key column; seed regional abbreviations + romaji.
5. **`customIndices` is decorative + non-idempotent seeding** — the table ships unindexed (full 800-row scan per utterance) and re-seed duplicates rows. Avoid: explicit `CREATE INDEX IF NOT EXISTS` in BOTH onCreate and onUpgrade (verify via `PRAGMA index_list`), stable string ids + `INSERT OR IGNORE`/upsert, batched single-transaction insert, and test the FULL migration ladder (v3→v22, v17→v22) against real sqlite3 with the SQLCipher key.

(Also: #7 English STT returns number-words + locale-not-threaded; #8 ADR-012 leaks in recognition UX; #9 ARB parity — merchant proper-nouns are DATA not ARB, category labels ARE ARB; #10 low-confidence thrash on STT partials — resolve on final + hysteresis.)

### Reconciled Cross-Document Tensions

Three places where the dimension files appeared to disagree, resolved into a single story:

- **The daily/joy "rule rework" target.** ARCHITECTURE found `RuleEngine`/`ClassificationService` is a **DEAD STUB** (Layer-2/3 are `// TODO`, never on the voice path), while PITFALLS noted `RuleEngine` maps only ~14 of the 19 L1/103 L2 ids. These agree once you see the live path is `CategoryService.resolveLedgerType` over the DB-backed `category_ledger_configs`. **Single story:** rework daily/joy by **re-seeding/expanding `category_ledger_configs`** (the live, user-overridable mechanism) and **retiring the dead `RuleEngine`/`ClassificationService`** (grep-verify no other caller — e.g. future OCR — before deleting; fold its intent into the config seed if a consumer exists). Ledger becomes a pure function of the FINAL category; the merchant-`ledgerType` short-circuit at `parse_voice_input_use_case.dart:106` is killed.
- **Merchant DB size: 600-800 vs "150-250 covers the bulk".** STACK says merchant data is MANUAL CURATION (no importable dataset maps to the 19 L1/103 L2 taxonomy; the expensive work is the per-merchant category mapping, which no source carries). FEATURES says ~150-250 national chains capture the large majority of *spoken everyday* spend, and the 600-800 ceiling buys the regional/depachika tail + OCR-reuse robustness. **No conflict:** the v1.9 MVP loads the **national-chain spine first**; the regional tail toward 600-800 is a post-validation (v1.9.x) load. Quality is "did we get the top chains per everyday category," not row count.
- **Cross-validation is a 3×3 truth table, NOT "keyword always wins".** FEATURES' Case-A headline ("keyword beats merchant") is only the strong-vs-strong-conflict cell. The full rule (PITFALLS #3, ARCHITECTURE §3.2) is none/weak/strong × none/weak/strong → {merchant, keyword, ask-user}. And corrections on a conflict must teach the **KEYWORD table** (generalizes), never the merchant table (would regress the next coffee entry).

## Implications for Roadmap

Continues phase numbering from Phase 48 — **v1.9 starts at Phase 49.** The order below is dependency-forced: data before logic, recognizers before arbitration, arbitration before ledger (single ledger site must exist first), then UX, then English/coverage as additive trailing data.

### Phase 49: Merchant Data Foundation (Drift v21→v22)
**Rationale:** Blocks everything that reads `merchants`; no behavior change, so it lands safely first.
**Delivers:** `merchants` table + DAO + repo interface/impl + import_guard; v21→v22 migration with explicit `CREATE INDEX`; `japan_merchants.json` (national-chain spine, normalized-key + region + multi-locale-name + aliases schema); idempotent upsert seeding.
**Uses:** drift 2.31.0, sqlcipher_flutter_libs 0.6.8, (optional) kana_kit for seed-time normalized keys.
**Avoids:** Pitfall 5 (decorative `customIndices` + non-idempotent seed + migration ladder), Pitfall 4 (normalized-key column computed at seed time), Pitfall 9 (merchant names as DATA, not ARB).

### Phase 50: Decoupled Recognizers
**Rationale:** Both recognizers depend on Phase 49 (`MerchantRepository`) but are independent of each other — two parallel-safe plans.
**Delivers:** Extract merchant methods out of `VoiceTextParser` → `MerchantRecognizer` (anchored/token matcher + NFKC); carve `CategoryRecognizer` out of `VoiceCategoryResolver` (keyword/substring/`_ensureL2`/`_extractKeyword`); `MerchantVerdict`/`CategoryVerdict` domain models. CategoryRecognizer runs unconditionally.
**Implements:** Components 1 & 2.
**Avoids:** Pitfall 1 (anchored matcher + ranked scores), Pitfall 4 (NFKC on query), Pitfall 4-quadrant decoupling (category engine runs even when a merchant is present/unmatched).

### Phase 51: Cross-Validation / Reconciliation
**Rationale:** Needs both verdict shapes from Phase 50.
**Delivers:** `RecognitionReconciler` (pure domain) + `RecognitionOutcome`; rewire `ParseVoiceInputUseCase` as coordinator; **delete the merchant short-circuit + ledger-from-merchant branch**; resolve-on-final + hysteresis.
**Implements:** Component 3.
**Avoids:** Pitfall 3 (3×3 truth table incl. bare-merchant/weak-keyword/both-weak), Pitfall 10 (no flicker on partials).

### Phase 52: Daily/Joy Ledger Rework
**Rationale:** Safest last among the logic phases — depends on the single post-reconciliation ledger site (Phase 51) existing.
**Delivers:** Re-seed/expand `category_ledger_configs` for all 19 L1 + meaningful L2; retire `RuleEngine`/`ClassificationService` (grep-verify first).
**Avoids:** Pitfall 2 (ledger as pure function of final category; invariant test; no second hardcoded ledger map).

### Phase 53: Recognition UX + Learning Surface
**Rationale:** Needs the `RecognitionOutcome` contract from Phase 51.
**Delivers:** Confidence band (3-tier, no number) + alternative chips + inline correction in `TransactionDetailsForm`; verify the `resolvedKeyword` identity contract (write key == read key) end-to-end; correction routes to KEYWORD table on conflict.
**Avoids:** Pitfall 8 (ADR-012 — qualitative affordance, no score/streak; extend the anti-toxicity sweep), the silent-orphan-key bug (260526-pg6), keyword-vs-merchant correction mis-routing.

### Phase 54: English Voice + Alias/Keyword/Coverage
**Rationale:** Additive data + coverage, lowest structural risk, can trail.
**Delivers:** English merchant aliases/locale-names, category keywords, currency words; bounded English number-word fallback (~30 lines, not a state machine); end-to-end `localeId` threading.
**Avoids:** Pitfall 7 ("fifty dollars" → 0; English entering CJK numeral path).

(An i18n/ARB-parity + golden-rebaseline + anti-toxicity-sweep gate runs as a cross-cutting close-out concern across Phases 53-54 — keep it inline, not at milestone close, per v1.7/v1.8 lessons. `git add -f lib/generated/` after `flutter gen-l10n`.)

### Phase Ordering Rationale
- **Data before logic:** Phase 49 blocks every component that reads `merchants`; re-migrating the schema after rows are loaded is the expensive mistake.
- **Recognizers before arbitration:** the reconciler is a pure function of two verdicts — both shapes must exist (Phase 50) before Phase 51.
- **Ledger rework last among logic:** it depends on the single post-reconciliation `resolveLedgerType` site existing (Phase 51), and doing it earlier risks the two-ledger-maps inconsistency.
- **English/coverage trailing:** additive data over the engines from Phase 50 + alias columns from Phase 49; lowest risk.

### Research Flags

Phases likely needing deeper research / careful spec during planning:
- **Phase 51 (Cross-Validation):** the 3×3 truth table (band definitions, agreement granularity, confidence floors, hysteresis margin) is where the real logic lives and is easy to under-spec — write the truth table as the test spec before coding.
- **Phase 49 (Data Foundation):** seed-timing decision (inside-migrator `rootBundle` read vs count-guarded post-open seed, given `AppInitializer` order KeyManager→Database→others) needs an early answer; full migration-ladder test against the encrypted-executor path (not just `NativeDatabase.memory()`).

Phases with standard patterns (skip research-phase):
- **Phase 52 (Ledger rework):** mechanism is understood (re-seed `category_ledger_configs`, retire dead stub); just grep-verify the blast radius.
- **Phase 54 (English):** additive data + a small bounded number-word fallback; well-scoped.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Grounded in `pubspec.lock`, pub.dev API, Drift/SQLCipher docs; "no new heavy deps" verified; en-US digit output is engine-dependent (MEDIUM, UAT-verify, non-blocking). |
| Features | MEDIUM-HIGH | Chain coverage & spend-dominance HIGH (store-count rankings); UX patterns MEDIUM (general AI-UX literature, no kakeibo-voice competitor); ADR-012 boundary HIGH (first-party). |
| Architecture | HIGH | Every claim traced to a read file:line in the actual code paths this session. |
| Pitfalls | HIGH | Grounded in this codebase's actual wiring + documented prior regressions (CR-01 migration lessons, 260526-pg6 orphan-key, voice iOS gotchas). |

**Overall confidence:** HIGH

### Gaps to Address
- **Seed timing** (`rootBundle` availability pre-`runApp`): decide inside-migrator vs count-guarded post-open seed in Phase 49 planning; both are valid, the count-guarded post-open is the safer default.
- **`RuleEngine`/`ClassificationService` deletion blast radius:** grep for consumers (OCR MOD-005? tests?) before retiring in Phase 52; fold into config instead of deleting if a consumer exists.
- **Reconciler home** (`features/accounting/domain/services/` vs a new `features/voice/`): recommend `accounting` to avoid a one-service feature module; confirm at Phase 51 planning.
- **Merchant `ledgerType` column:** keep as a stored non-authoritative hint vs drop entirely (always derive). Recommend keep-but-non-authoritative for a future merchant-specific-ledger affordance.
- **en-US STT digit output** on target iOS/Android versions: confirm in a Phase 54 UAT; if a regional engine returns words, the bounded fallback already covers it.
- **FTS5:** deferred; only revisit if CN expansion pushes the catalog into the thousands, and verify SQLCipher+fts5 build compatibility first.

## Sources

### Primary (HIGH confidence)
- Codebase (read this session): `parse_voice_input_use_case.dart`, `voice_category_resolver.dart`, `voice_text_parser.dart`, `merchant_database.dart`, `rule_engine.dart`, `classification_service.dart`, `category_service.dart`, `app_database.dart`, learning-table DAOs/tables, `voice_parse_result.dart`, `default_categories.dart` (19 L1 / 103 L2).
- `pubspec.lock` — drift 2.31.0, speech_to_text 7.3.0, sqlcipher_flutter_libs 0.6.8.
- pub.dev API + kana_kit page — kana_kit 2.1.1 (MIT, pure Dart, SDK-compatible).
- Drift FTS5 / extensions docs + drift #3702 — FTS5 available but ≥2.32.0 drops easy SQLCipher.
- MEMORY.md / CLAUDE.md — `customIndices` decorative, drift/sqlcipher pins, Thin-Feature & Placement rules, ADR-012, voice iOS gotchas, 260526-pg6 orphan-key, CR-01 migration lessons.
- Statista / chain-ranking sources — top-3 konbini ~90%; per-category chain concentration (HIGH for spend-dominance claim).

### Secondary (MEDIUM confidence)
- AI-UX confidence-visualization literature — 3-tier band, avoid false precision, "easy to ignore when right".
- Finance-gamification-harm literature — backs the ADR-012 anti-feature boundary.
- JP text-normalization (NFKC + katakana/hiragana fold + regional abbrev) — standard CJK matching preprocessing.
- `voice-category-recognition-improvements.md` (v1.3-era) — "3-layer pipeline is documentation-only"; dict-as-label-set; Option F (close the learning loop) folded into v1.9; embedding fallback (Option D) confirmed as the v2+ ceiling, out of v1.9 scope.

### Tertiary (LOW confidence)
- en-US STT digit-vs-word formatting — engine/OS-version dependent; verify on-device (non-blocking; bounded fallback covers it).

---
*Research completed: 2026-06-23*
*Ready for roadmap: yes*
