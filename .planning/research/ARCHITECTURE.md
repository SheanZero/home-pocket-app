# Architecture Research

**Domain:** v1.9 voice category + merchant recognition redesign — decoupled recognizers, cross-validation, Japan merchant Drift store, learning loop, daily/joy rule rework, inside Home Pocket's 5-layer Clean Architecture.
**Researched:** 2026-06-23
**Confidence:** HIGH (grounded in the actual code paths; every claim below is traced to a file:line read during this research)

---

## 0. Executive Integration Summary

The v1.9 redesign is a **layered decomposition + an arbitration insert**, not a rewrite. The existing pipeline already has the right *bones* — a use case orchestrator (`ParseVoiceInputUseCase`), a category resolver, a merchant lookup, a learning table per signal, and a DB-backed ledger resolver (`CategoryService.resolveLedgerType`). What it lacks is **independence** (merchant matching is embedded in `VoiceTextParser` AND short-circuits the category resolver) and **arbitration** (there is no place where two independent verdicts are reconciled).

The cleanest integration:

1. **Extract two independent pure-Dart recognizer services into `lib/application/voice/recognition/`** — `MerchantRecognizer` and `CategoryRecognizer` — each returning a *candidate verdict* domain object. Neither calls the other.
2. **Insert a pure domain reconciliation service** (`RecognitionReconciler`) that consumes both verdicts and produces a final `RecognitionOutcome` (chosen category + ledger + confidence + alternatives + source provenance). `ParseVoiceInputUseCase` becomes a thin coordinator: parse → run both recognizers → reconcile → build result.
3. **Migrate the 13-entry in-memory `MerchantDatabase` to a Drift table** (`merchants`) with `region` + multi-locale name variants, seeded 600–800 rows from a bundled JSON asset on create/upgrade. `MerchantRecognizer` reads it through a repository.
4. **Keep the two learning tables** (`category_keyword_preferences`, `merchant_category_preferences`) exactly as-is structurally; the recognizers read them, inline corrections write them. No new learning table needed.
5. **Collapse the dual ledger-resolution mechanism**: the live path is `CategoryService.resolveLedgerType` (DB-backed `category_ledger_configs`). The hardcoded `RuleEngine` + `ClassificationService` are a **dead stub** (Layer-2/3 are `// TODO`, never wired into the voice path). The daily/joy "rework" is best done as a **seed/config rework of `category_ledger_configs`** + retiring/absorbing the dead `RuleEngine`, NOT by extending the dead map.

---

## 1. Standard Architecture

### System Overview (target v1.9 data flow)

```
┌──────────────────────────────────────────────────────────────────────┐
│ PRESENTATION  lib/features/accounting/presentation/                    │
│  VoiceInputScreen → TransactionDetailsForm                             │
│   • renders confidence + alternative chips (RecognitionOutcome)        │
│   • inline correction → RecordCategoryCorrectionUseCase                 │
│   •                   → MerchantCategoryLearningService.recordSelection │
└───────────────────────────────┬────────────────────────────────────────┘
                                 │ VoiceParseResult (+ RecognitionOutcome)
┌───────────────────────────────▼────────────────────────────────────────┐
│ APPLICATION  lib/application/voice/                                     │
│                                                                        │
│   ParseVoiceInputUseCase (thin coordinator)                            │
│      1. VoiceTextParser.extract{Amount,Date,Currency}  (NO merchant)   │
│      2. MerchantRecognizer.recognize(text)   ─┐  independent           │
│      3. CategoryRecognizer.recognize(text)   ─┤  independent           │
│      4. RecognitionReconciler.reconcile(▲,▲) ─┘  pure domain           │
│      5. CategoryService.resolveLedgerType(finalCategoryId)             │
│                                                                        │
│   recognition/                                                         │
│     MerchantRecognizer   (reads MerchantRepository + merchant prefs)   │
│     CategoryRecognizer   (reads keyword prefs + category repo)         │
└───────────────────────────────┬────────────────────────────────────────┘
                                 │
┌───────────────────────────────▼────────────────────────────────────────┐
│ DOMAIN  lib/features/{voice|accounting}/domain/                        │
│   RecognitionReconciler (pure service, no I/O)                         │
│   models: MerchantVerdict, CategoryVerdict, RecognitionOutcome         │
│           Merchant (domain model), CategoryMatchResult (existing)      │
│   repositories (interfaces): MerchantRepository,                       │
│           CategoryKeywordPreferenceRepository (existing),              │
│           MerchantCategoryPreferenceRepository (existing)              │
└───────────────────────────────┬────────────────────────────────────────┘
                                 │ (Data implements Domain interfaces)
┌───────────────────────────────▼────────────────────────────────────────┐
│ DATA  lib/data/                                                        │
│   tables/merchants_table.dart            (NEW, region + locale names)  │
│   daos/merchant_dao.dart                 (NEW, FTS / index lookup)     │
│   repositories/merchant_repository_impl.dart (NEW)                     │
│   tables/category_keyword_preferences_table.dart  (existing)          │
│   tables/merchant_category_preferences_table.dart (existing)          │
│   app_database.dart  schemaVersion 21 → 22  + seed-on-create          │
│   assets/merchants/japan_merchants.json  (bundled 600–800 rows)       │
└──────────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Layer | Status | Responsibility |
|-----------|-------|--------|----------------|
| `VoiceTextParser` | application | **MODIFIED** | Amount/date/currency extraction ONLY. `extractAndMatchMerchant` + `_extractPotentialMerchantNames` (lines 504–567) are **extracted out**. |
| `MerchantRecognizer` | application | **NEW** | Independent merchant identification: candidate-name extraction → `MerchantRepository` lookup → merchant-preference override → `MerchantVerdict`. |
| `CategoryRecognizer` | application | **NEW** | Independent category identification from activity/object keywords: keyword-prefs exact → substring → seed fallback → `CategoryVerdict`. Absorbs the *non-merchant* logic of `VoiceCategoryResolver`. |
| `RecognitionReconciler` | domain | **NEW** | Pure arbitration: keyword-intent priority, merchant fallback, agreement boost, conflict→keyword-wins, category-only path. Produces `RecognitionOutcome`. |
| `ParseVoiceInputUseCase` | application | **MODIFIED** | Coordinator only. Loses the merchant-branch short-circuit (lines 93–106). |
| `MerchantRepository` (+impl) | domain / data | **NEW** | CRUD + lookup over the `merchants` Drift table. |
| `merchants` table + `MerchantDao` | data | **NEW** | Persistent merchant store, region-scoped, multi-locale, FTS/index-backed. |
| `MerchantDatabase` (in-memory) | infrastructure | **REMOVED** (or shimmed) | The 13-entry `lib/infrastructure/ml/merchant_database.dart` is replaced. `MerchantMatch` type either moves to domain or is replaced by `MerchantVerdict`. |
| `VoiceCategoryResolver` | application | **DISSOLVED** | Its merchant short-circuit (lines 86–99) is deleted; its keyword/substring logic (lines 100–166) + `_ensureL2`/`normalizeToL2` move into `CategoryRecognizer`. |
| `CategoryService.resolveLedgerType` | application | **KEPT (live path)** | DB-backed daily/joy resolution via `category_ledger_configs`. The daily/joy rework re-seeds this config, not the dead `RuleEngine`. |
| `RuleEngine` + `ClassificationService` | application | **DEAD — RETIRE/ABSORB** | Hardcoded category→ledger map; Layer-2/3 are `// TODO` stubs; not on the voice path. Decide: delete, or fold its rules into `category_ledger_configs` seed. |
| `category_keyword_preferences` / `merchant_category_preferences` | data | **KEPT** | Learning tables. No structural change; recognizers read, corrections write. |

---

## 2. Where to Split — MerchantRecognizer vs CategoryRecognizer

### 2.1 What gets extracted out of `VoiceTextParser` (568 LOC → ~440 LOC)

**Remove (lines 504–567):**
- `extractAndMatchMerchant(text, merchantDB)` — the embedded coupling. Caller `ParseVoiceInputUseCase:71` is rewired to call `MerchantRecognizer`.
- `_extractPotentialMerchantNames(text)` — the candidate-segment generator. **Moves into `MerchantRecognizer`** (it is merchant-specific NLP, not amount/date parsing).

**Keep:** all amount (`extractAmount`, `_extractArabicAmount`, state-machine routing), date (`extractDate` + 5 sub-extractors), and the parser stays merchant-free. The `import merchant_database.dart` at line 1 is removed.

> **Why:** `VoiceTextParser`'s single responsibility becomes "turn an utterance into amount/date/currency primitives." Merchant identification is a *recognition* concern, not a *text-parsing* concern. This is the concrete decoupling the milestone names.

### 2.2 `MerchantRecognizer` (NEW — `lib/application/voice/recognition/merchant_recognizer.dart`)

Pure-Dart application service. Constructor-injected with `MerchantRepository` + `MerchantCategoryPreferenceRepository`.

```dart
class MerchantRecognizer {
  MerchantRecognizer({
    required MerchantRepository merchantRepository,
    required MerchantCategoryPreferenceRepository merchantPrefs,
  });

  /// Independent — never calls CategoryRecognizer.
  Future<MerchantVerdict?> recognize(String text, {String? localeId}) async {
    final candidates = _extractCandidateNames(text);      // moved from VoiceTextParser
    final hit = await _merchantRepository.findBestMatch(   // exact → alias → locale-name → FTS
      candidates, region: 'JP', localeId: localeId,
    );
    if (hit == null) return null;
    // merchant_category_preferences override wins over the merchant's default category
    final learned = await _merchantPrefs.suggestCategoryId(_normalize(hit.canonicalName));
    return MerchantVerdict(
      merchantName: hit.canonicalName,
      categoryId: learned ?? hit.defaultCategoryId,
      ledgerType: hit.defaultLedgerType,          // a *hint*, not authoritative
      confidence: learned != null ? 0.95 : hit.matchConfidence,
      isLearnedOverride: learned != null,
    );
  }
}
```

### 2.3 `CategoryRecognizer` (NEW — `lib/application/voice/recognition/category_recognizer.dart`)

Absorbs the *non-merchant* half of `VoiceCategoryResolver` (lines 100–202): keyword-prefs exact match → step-2.5 seed/learned substring fallback → `_ensureL2` always-L2 normalization. **The step-1 merchant short-circuit (resolver lines 86–99) is deleted** — that is exactly the "商家短路" the milestone removes.

```dart
class CategoryRecognizer {
  CategoryRecognizer({
    required CategoryKeywordPreferenceRepository preferenceRepository,
    required CategoryRepository categoryRepository,   // for _ensureL2
  });

  Future<CategoryVerdict?> recognize(String text, {String? localeId}) async {
    final keyword = _extractKeyword(text, localeId: localeId);  // moved from ParseVoiceInputUseCase._extractKeyword
    if (keyword.isEmpty) return null;
    // exact → substring(seed+learned≥3) → _ensureL2  (today's resolver body, minus merchant step)
    ...
    return CategoryVerdict(
      categoryId: l2Id, confidence: ..., keyword: keyword, source: ...,
    );
  }
}
```

> **Decision — where does `_extractKeyword` live?** Today it sits in `ParseVoiceInputUseCase` (lines 192–237). Move it into `CategoryRecognizer` so the category engine owns its own input preprocessing and is independently testable. The `resolvedKeyword` that the form's learning write-back depends on (`voice_parse_result.dart:38`, `voice_input_screen_helpers.dart:66`) is now surfaced from `CategoryVerdict.keyword` through the use case — **this is a load-bearing contract: the write key must stay identity-equal to the read key, or the silent-orphan bug returns.**

### 2.4 Layer-placement table (Thin Feature respected)

| Artifact | Path | Layer | Rationale |
|----------|------|-------|-----------|
| `MerchantRecognizer`, `CategoryRecognizer` | `lib/application/voice/recognition/` | Application | Business logic / use-case-grade services. NOT in `features/` (Thin Feature). |
| `RecognitionReconciler` | `lib/features/voice/domain/services/` *(or* `lib/application/voice/recognition/` *— see §3)* | Domain or Application | Pure, no I/O → domain-eligible. |
| `MerchantVerdict`, `CategoryVerdict`, `RecognitionOutcome`, `Merchant` | `lib/features/accounting/domain/models/` | Domain | Plain Freezed models alongside existing `VoiceParseResult`/`CategoryMatchResult`. |
| `MerchantRepository` (interface) | `lib/features/accounting/domain/repositories/` | Domain | Mirrors existing `*_preference_repository.dart` interfaces. |
| `merchants_table.dart`, `merchant_dao.dart`, `merchant_repository_impl.dart` | `lib/data/tables|daos|repositories/` | Data | ALL tables/DAOs/repo-impls live in `lib/data/` per Thin Feature. |
| `japan_merchants.json` | `assets/merchants/` | Asset | Bundled seed. |

---

## 3. Reconciliation / Arbitration Layer

### 3.1 Placement decision: **pure domain service**, not a use case

`RecognitionReconciler` has **zero I/O** — it takes two already-computed verdicts and returns an outcome. By the project's Placement Decision Rule (#4 "Domain model or pure logic → `features/{feature}/domain/`"), a pure deterministic function belongs in domain. Concretely: `lib/features/accounting/domain/services/recognition_reconciler.dart` (or `features/voice/domain/services/`). It must not import `application/`, `data/`, or `infrastructure/`.

> **Why not a use case?** Use cases orchestrate repositories and side effects. The reconciler is a pure decision function — making it domain keeps it trivially unit-testable (no mocks) and lets the always-L2/ledger-resolution side effects stay in the use case. `ParseVoiceInputUseCase` remains the only orchestrator.
>
> **Caveat (honest):** `_ensureL2` currently needs `CategoryRepository` (an async I/O call). Keep `_ensureL2` inside `CategoryRecognizer` (application) so verdicts arrive **already L2-normalized**. The reconciler then stays pure. The final `resolveLedgerType` call also stays in the use case, after reconciliation.

### 3.2 Reconciliation algorithm (the four milestone rules)

```dart
RecognitionOutcome reconcile(CategoryVerdict? cat, MerchantVerdict? merch) {
  // (a) category-only path: no merchant recognized
  if (merch == null) {
    if (cat == null) return RecognitionOutcome.miss();           // → manual pick
    return RecognitionOutcome(categoryId: cat.categoryId,
        confidence: cat.confidence, source: cat.source, alternatives: []);
  }
  // merchant present but no category keyword: merchant fallback
  if (cat == null) {
    return RecognitionOutcome(categoryId: merch.categoryId,
        confidence: merch.confidence, source: MatchSource.merchant, alternatives: []);
  }
  // both present:
  if (cat.categoryId == merch.categoryId) {
    // (c) agreement → confidence boost
    return RecognitionOutcome(categoryId: cat.categoryId,
        confidence: min(1.0, max(cat.confidence, merch.confidence) + kAgreementBoost),
        source: MatchSource.keyword, alternatives: []);
  }
  // (d) conflict → keyword (intent) wins; merchant becomes an alternative chip
  //     "在星巴克买了个杯子" → 购物 (keyword), Starbucks→咖啡 demoted to alt
  return RecognitionOutcome(categoryId: cat.categoryId,
      confidence: cat.confidence /* optionally * kConflictPenalty */,
      source: MatchSource.keyword,
      alternatives: [Alt(merch.categoryId, MatchSource.merchant, merch.confidence)]);
}
```

- **Keyword-intent priority** — the conflict branch always returns the category verdict's id; merchant never overrides a present keyword verdict. This is the inversion of today's behavior (`ParseVoiceInputUseCase:93` lets merchant win).
- **Merchant fallback** — only fires when `cat == null`.
- **Agreement boost** — `kAgreementBoost` (~+0.05–0.10) applied only on equal ids.
- **Conflict → keyword wins** — merchant demoted to `alternatives`, surfaced as a chip.

### 3.3 `MatchSource` extension

The existing `MatchSource` enum (`voice_parse_result.dart:61`) — `merchant | keyword | learning | fallback` — is reused. Add `reconciledAgreement` if the UI needs to distinguish boosted matches (optional; otherwise reuse `keyword`).

---

## 4. Merchant Drift Table — Schema, Migration, Seeding

### 4.1 Schema (`lib/data/tables/merchants_table.dart`, NEW)

```dart
@DataClassName('MerchantRow')
class Merchants extends Table {
  TextColumn get id => text()();                 // 'jp_starbucks'
  TextColumn get region => text().withDefault(const Constant('JP'))(); // future CN/etc
  TextColumn get canonicalName => text()();      // 'スターバックス'
  TextColumn get localeNames => text().withDefault(const Constant('{}'))(); // JSON {"ja":"...","zh":"...","en":"..."}
  TextColumn get aliases => text().withDefault(const Constant('[]'))();     // JSON ["スタバ","Starbucks"]
  TextColumn get categoryId => text()();         // L2 default, e.g. cat_food_cafe
  TextColumn get ledgerType => text()();         // 'daily' | 'joy' (hint)
  TextColumn get source => text().withDefault(const Constant('seed'))();    // 'seed' | 'user'
  IntColumn  get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
```

**Design notes:**
- `region` + `localeNames` JSON give the "future CN expansion" + "multi-locale店名变体" the milestone requires, without a child table (keeps lookups single-row). Aliases stay denormalized JSON like `shopping_items` tags precedent.
- `categoryId` stores the **L2** id directly (the in-memory entries already do, post D-04 fix). `ledgerType` is a *hint*; the authoritative ledger still flows through `CategoryService.resolveLedgerType` after reconciliation.
- `source='user'` rows let a future "add merchant" feature coexist with seeds (mirrors the seed/learned discriminator in `category_keyword_preferences`).

### 4.2 Indexing / matching strategy

`customIndices` on the table is **decorative** (project pitfall #11 + the v1.6/v1.7 CR-01 lesson — `customIndices` is never consumed by Drift's migrator). **Emit `CREATE INDEX IF NOT EXISTS` by hand** in a `_createMerchantIndexes()` helper called from BOTH `onCreate` and the `from < 22` upgrade branch — exactly the `_createShoppingItemIndexes` / `_createExchangeRateIndexes` pattern (`app_database.dart:473`, `:501`).

```dart
Future<void> _createMerchantIndexes() async {
  await customStatement('CREATE INDEX IF NOT EXISTS idx_merchants_region_name '
      'ON merchants (region, canonical_name)');
  await customStatement('CREATE INDEX IF NOT EXISTS idx_merchants_category '
      'ON merchants (category_id)');
}
```

**Matching tiers in `MerchantDao` / `MerchantRepositoryImpl`** (replacing the in-memory exact→alias→substring scan):
1. Exact `canonicalName` / `localeNames[locale]` equality (indexed).
2. Alias JSON contains — load region-scoped rows, in-memory JSON-decode + match (600–800 rows × ~80 B ≈ ~50 KB, cache once like `_seedCache`).
3. Substring (len ≥ 3 guard, preserved from `merchant_database.dart:155`).

> **FTS recommendation (MEDIUM confidence):** Drift supports `fts5` virtual tables. For 600–800 rows an indexed exact-match + a cached in-memory alias/substring scan is **simpler and sufficient** (sub-millisecond). Recommend FTS5 **only if** later growth (CN expansion → thousands of rows) makes the in-memory scan costly. Do NOT add FTS5 in v1.9 — it complicates the migration and the encrypted-DB build for marginal gain at this row count. (Verify Drift FTS5 + SQLCipher interaction before committing if pursued.)

### 4.3 Migration v21 → v22

```dart
@override int get schemaVersion => 22;   // app_database.dart:49

// in onCreate, after createAll():
await _createMerchantIndexes();
await _seedMerchants();                   // fresh install seeds too

// in onUpgrade:
if (from < 22) {
  await migrator.createTable(merchants);
  await _createMerchantIndexes();
  await _seedMerchants();                 // populate the new table on upgrade
}
```

### 4.4 Seeding 600–800 rows (bundled asset → seed-on-create)

- Ship `assets/merchants/japan_merchants.json` (declared in `pubspec.yaml`). Each entry: `{id, canonicalName, localeNames{}, aliases[], categoryId, ledgerType, sortOrder}`.
- `_seedMerchants()` reads the asset via `rootBundle`, batch-inserts with `InsertMode.insertOrIgnore` (mirrors `insertSeedBatch` at `category_keyword_preference_dao.dart:137`) so user rows / re-runs are idempotent.
- **Migration-purity caveat (HIGH confidence pitfall):** `onCreate`/`onUpgrade` run inside the Drift opening sequence, which here is over an **encrypted SQLCipher executor** initialized at app boot. Reading a bundled asset from inside the migration is acceptable (it is pure asset I/O, no plugins), but verify `rootBundle` is available that early in `AppInitializer` order (KeyManager → Database → others). If asset access is unreliable pre-`runApp`, seed in a **post-open one-shot** guarded by a `merchants` row-count check instead of inside the migrator — both patterns are valid; the count-guarded post-open seed is the safer default.
- **categoryId integrity:** every seed `categoryId` MUST be a real L2 id in `default_categories.dart` (the in-memory DB had three D-04 "non-existent L1 → silent null" bugs — `merchant_database.dart:86,99,112`). Add a unit test asserting every seed row's `categoryId` resolves via `CategoryRepository.findById` to a level-2 row.

### 4.5 Coexistence with `merchant_category_preferences`

Unchanged. The two tables are orthogonal:
- `merchants` = the **catalog** (what merchants exist, their default category).
- `merchant_category_preferences` = the **learning overlay** (`merchant_category_preferences_table.dart`: `merchantKey → preferredCategoryId`, `overrideStreak`).

`MerchantRecognizer` reads the catalog for identification, then consults the preference overlay for a learned category override (§2.2). The preference's `merchantKey` is the normalized name (`MerchantCategoryLearningService.normalizeMerchant`, `:14`) — keep that normalization as the join key so existing learned rows survive.

---

## 5. Learning Feedback Loop

The loop is **already wired** in `transaction_details_form.dart` — v1.9 keeps both writers, just feeds them from the new outcome:

| Signal | Write path (KEEP) | Read path (REWIRE) |
|--------|-------------------|--------------------|
| Keyword → category | `RecordCategoryCorrectionUseCase.execute(keyword, correctedCategoryId)` → `category_keyword_preferences` upsert (`form:579`) | `CategoryRecognizer` (was `VoiceCategoryResolver` steps 2–2.5) |
| Merchant → category | `MerchantCategoryLearningService.recordSelection(merchantRaw, selectedCategoryId)` → `merchant_category_preferences` upsert (`form:767`) | `MerchantRecognizer` (was unread by the resolver merchant step) |

**Critical contract preserved:** the keyword written by `recordCorrection` must equal the keyword the recognizer looked up. Today that identity flows via `VoiceParseResult.resolvedKeyword` (`:38`) ← `ParseVoiceInputUseCase._extractKeyword` ← consumed by `voice_input_screen_helpers.extractVoiceKeyword:66`. In v1.9 the source becomes `CategoryVerdict.keyword`, surfaced unchanged through `VoiceParseResult.resolvedKeyword`. **Do not let the use case re-extract a divergent keyword** — that re-opens the silent-orphan bug (quick task 260526-pg6).

**Inline correction → which writer fires:**
- User corrects category on a **merchant-driven** outcome → fire `recordSelection` (merchant overlay) AND optionally `recordCorrection` (keyword overlay) if a keyword was present. The form already calls both conditionally; keep that.
- User corrects category on a **category-only** outcome → fire `recordCorrection` only (no merchant to attach to).

**Alternative-chip selection** (new UX) is just a correction with a pre-filled target id → routes through the same two writers. No new persistence.

---

## 6. daily/joy Rule-Engine Rework

### 6.1 The dual-mechanism finding (key)

There are **two** ledger resolvers in the codebase, and only one is live on the voice path:

| Mechanism | File | Backed by | On voice path? |
|-----------|------|-----------|----------------|
| `CategoryService.resolveLedgerType` | `category_service.dart:26` | **DB `category_ledger_configs`** (L1 config + L2 override + parent inheritance) | **YES** — called at `voice_category_resolver.dart:205` / `parse_voice_input_use_case.dart:111` |
| `RuleEngine` + `ClassificationService` | `rule_engine.dart`, `classification_service.dart` | **Hardcoded in-memory map** (~14 entries), Layer-2/3 `// TODO` stubs | **NO** — `ClassificationService` is never invoked by the voice flow read here |

> **Recommendation:** Do the daily/joy rework **on `category_ledger_configs`** (the live, user-overridable, DB-backed mechanism), NOT by extending the dead `RuleEngine` map. Specifically:
> 1. Re-seed/expand the default `category_ledger_configs` so every L1 (19) + meaningful L2 (~103) has the correct daily/joy default under the v1.5 `LedgerType { daily, joy }` vocabulary.
> 2. **Retire `RuleEngine` + `ClassificationService`** (or fold their intent into the config seed). Leaving a second, divergent, hardcoded daily/joy map is a latent inconsistency bug. Verify no non-voice caller depends on `ClassificationService` before deleting (grep first).
> 3. Merchant `ledgerType` stays a **hint** only; the authoritative ledger is `resolveLedgerType(finalCategoryId)` run by the use case **after** reconciliation — so a merchant→category conflict resolved toward the keyword category also gets the keyword category's ledger (correct: 星巴克买杯子 → 购物/joy, not 咖啡/daily).

### 6.2 Integration point

`ParseVoiceInputUseCase` step 5: after `RecognitionOutcome.categoryId` is chosen, call `CategoryService.resolveLedgerType(categoryId)`. Drop the special-case `ledgerType = merchantMatch.ledgerType` branch (`parse_voice_input_use_case.dart:106`) — ledger now always derives from the final reconciled category, never directly from the merchant.

---

## 7. Data Flow — Before vs After

### Before (today)

```
text → VoiceTextParser.extractAndMatchMerchant ──(hit)──► merchant.categoryId wins (short-circuit)
                                              └─(miss)─► VoiceCategoryResolver
                                                          └ MerchantDB step1 (again!) → keyword → substring
                          ledger = merchant.ledgerType OR resolveLedgerType(category)
```
Problems: merchant matched in TWO places; merchant always beats keyword; resolver re-runs merchant lookup.

### After (v1.9)

```
text ─┬─► VoiceTextParser → amount/date/currency
      ├─► MerchantRecognizer ─► MerchantVerdict? ─┐
      └─► CategoryRecognizer ─► CategoryVerdict? ─┤
                                                  ▼
                          RecognitionReconciler (keyword-priority, fallback, boost, conflict)
                                                  ▼
                                          RecognitionOutcome (category + alts + confidence)
                                                  ▼
                          CategoryService.resolveLedgerType(finalCategoryId)
                                                  ▼
                          VoiceParseResult (+ resolvedKeyword from CategoryVerdict)
```

---

## 8. New vs Modified vs Removed (explicit)

| # | Component | Verdict | Notes |
|---|-----------|---------|-------|
| 1 | `merchants` table + `MerchantDao` + `MerchantRepositoryImpl` | NEW (data) | schema v22, indexed, seeded |
| 2 | `MerchantRepository` interface | NEW (domain) | |
| 3 | `MerchantRecognizer` | NEW (application) | absorbs `_extractPotentialMerchantNames` |
| 4 | `CategoryRecognizer` | NEW (application) | absorbs resolver steps 2–2.5 + `_ensureL2` + `_extractKeyword` |
| 5 | `RecognitionReconciler` | NEW (domain, pure) | arbitration |
| 6 | `MerchantVerdict`, `CategoryVerdict`, `RecognitionOutcome`, `Merchant` models | NEW (domain) | Freezed |
| 7 | `assets/merchants/japan_merchants.json` | NEW (asset) | 600–800 rows |
| 8 | `VoiceTextParser` | MODIFIED | drop merchant methods (504–567) + merchant import |
| 9 | `ParseVoiceInputUseCase` | MODIFIED | coordinator; drop merchant short-circuit (93–106) + ledger-from-merchant (106) |
| 10 | `category_ledger_configs` seed | MODIFIED | daily/joy rework target |
| 11 | `app_database.dart` | MODIFIED | v21→v22, register `Merchants`, seed + index helpers |
| 12 | `transaction_details_form.dart` | MODIFIED | render confidence + alt chips; correction routing unchanged underneath |
| 13 | `VoiceParseResult` | MODIFIED | optionally carry `RecognitionOutcome` alternatives for the UI |
| 14 | `VoiceCategoryResolver` | REMOVED/DISSOLVED | logic split into CategoryRecognizer + reconciler |
| 15 | `MerchantDatabase` (in-memory) | REMOVED | replaced by `merchants` table; `MerchantMatch` → `MerchantVerdict` |
| 16 | `RuleEngine` + `ClassificationService` | REMOVED/ABSORBED | dead stub; fold into `category_ledger_configs` seed after grep-verify |
| 17 | `category_keyword_preferences`, `merchant_category_preferences` (+ DAOs/repos) | KEPT | learning loop unchanged |
| 18 | `RecordCategoryCorrectionUseCase`, `MerchantCategoryLearningService` | KEPT | write paths unchanged |

---

## 9. Suggested Build Order (dependency-honoring)

```
Phase A — Data foundation (no behavior change)
  • merchants table + DAO + repo interface/impl + import_guard
  • schema v21→v22 migration + _createMerchantIndexes (explicit CREATE INDEX)
  • japan_merchants.json asset (600–800 rows) + seed-on-create/upgrade
  • seed-categoryId-is-real-L2 integrity test
  Depends on: nothing.  Risk: migration/seed timing vs AppInitializer order.

Phase B — Decoupled recognizers (parallel-safe once A lands)
  • Extract merchant methods out of VoiceTextParser → MerchantRecognizer (reads merchants repo + merchant prefs)
  • Carve CategoryRecognizer out of VoiceCategoryResolver (keyword/substring/_ensureL2 + _extractKeyword)
  • Domain verdict models (MerchantVerdict/CategoryVerdict)
  Depends on: A (MerchantRepository).  Keep VoiceCategoryResolver temporarily as a delegating shim if needed.

Phase C — Reconciliation
  • RecognitionReconciler (pure domain) + RecognitionOutcome model
  • Rewire ParseVoiceInputUseCase as coordinator; delete merchant short-circuit + ledger-from-merchant
  Depends on: B.

Phase D — daily/joy rework
  • Re-seed category_ledger_configs; retire RuleEngine/ClassificationService (grep-verify no other callers)
  Depends on: C (final categoryId → resolveLedgerType is the single ledger site).

Phase E — Recognition UX + learning surface
  • Confidence display + alternative chips + inline correction in TransactionDetailsForm
  • Verify resolvedKeyword identity contract (write key == read key) end-to-end
  Depends on: C (RecognitionOutcome shape).

Phase F — English voice + alias/keyword coverage
  • English merchant aliases/locale-names + category keyword + currency-word coverage
  Depends on: A (alias columns), B (recognizers).  Mostly data, low structural risk.
```

> **Rationale:** Data before logic (A blocks everything that reads `merchants`). Recognizers (B) are independent of each other and can be two parallel plans but both depend on A. Reconciliation (C) needs both verdict shapes. Ledger rework (D) is safest last because it depends on the single post-reconciliation ledger site existing. UX (E) needs the outcome contract. English (F) is additive data + coverage, lowest risk, can trail.

---

## 10. Integration Points & Anti-Patterns

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| `ParseVoiceInputUseCase` ↔ recognizers | direct constructor injection | both recognizers injected; use case never reaches into the other |
| recognizers ↔ `RecognitionReconciler` | pass verdict value objects | reconciler is pure; no repo access |
| `MerchantRecognizer` ↔ `merchants` | `MerchantRepository` interface | data impl in `lib/data/`; domain interface in `features/.../domain/repositories/` |
| use case ↔ ledger | `CategoryService.resolveLedgerType` | single authoritative ledger site, post-reconciliation |
| form ↔ learning | two existing use cases/services | unchanged write paths |

### Anti-Patterns to avoid (domain-specific)

1. **Re-coupling merchant into category** — do NOT let `MerchantRecognizer` short-circuit `CategoryRecognizer` or vice-versa. They run independently; only the reconciler combines them. (This is the exact regression the milestone reverses.)
2. **Two ledger maps** — do NOT extend the dead `RuleEngine` *and* `category_ledger_configs`. Pick the DB config as the single source; retire the map.
3. **Trusting `customIndices`** — it is decorative. Always emit `CREATE INDEX IF NOT EXISTS` by hand in onCreate AND onUpgrade (project pitfall #11, CR-01 lesson).
4. **Divergent correction key** — never re-extract the learning keyword in the use case; thread `CategoryVerdict.keyword` through `resolvedKeyword` verbatim.
5. **Seed categoryId drift** — every merchant/seed `categoryId` must be a live L2 id (the three D-04 bugs). Guard with a test.
6. **Infra→domain leak** — `MerchantMatch` lived in infrastructure because it was a return type of an infra component. With the catalog in `data/` and verdicts in `domain/`, keep verdict models in domain (plain Freezed, no Drift types).

---

## 11. Open Questions for Roadmap

1. **Reconciler home** — `features/voice/domain/` vs `features/accounting/domain/`? Voice is currently spread across `application/voice/` + `features/accounting/domain/` (no `features/voice/` module exists). Recommend `features/accounting/domain/services/` to avoid creating a new feature module for one pure service — confirm during phase planning.
2. **`RuleEngine` deletion blast radius** — grep for `ClassificationService` consumers (OCR MOD-005? tests?) before retiring. If OCR is expected to reuse it, fold into config instead of deleting.
3. **Seed timing** — inside-migrator asset read vs count-guarded post-open seed (§4.4). Decide based on `rootBundle` availability in `AppInitializer` order.
4. **FTS5** — defer unless CN expansion lands; confirm SQLCipher + fts5 build compatibility if pursued.
5. **Merchant `ledgerType` column** — keep as a stored hint, or drop it entirely and always derive ledger from `categoryId`? Dropping is cleaner (single ledger source) but loses a future "merchant-specific ledger" affordance. Recommend keep-but-non-authoritative.

---

## Sources

- Codebase (read this session, authoritative): `lib/application/voice/parse_voice_input_use_case.dart`, `voice_category_resolver.dart`, `voice_text_parser.dart`; `lib/infrastructure/ml/merchant_database.dart`; `lib/application/dual_ledger/rule_engine.dart`, `classification_service.dart`; `lib/application/accounting/category_service.dart`, `merchant_category_learning_service.dart`; `lib/application/voice/record_category_correction_use_case.dart`; `lib/data/tables/{merchant_category_preferences,category_keyword_preferences}_table.dart`; `lib/data/daos/{merchant_category_preference,category_keyword_preference}_dao.dart`; `lib/data/app_database.dart`; `lib/features/accounting/domain/models/voice_parse_result.dart`; `lib/features/accounting/presentation/screens/voice_input_screen_helpers.dart`.
- `.planning/PROJECT.md` (v1.9 milestone scope), `.planning/research/voice-category-recognition-improvements.md` (prior voice research).
- `CLAUDE.md` — Thin Feature rule, Placement Decision Rule, Drift TableIndex/customIndices pitfall (#11), schema-versioning convention, AppInitializer order.

---
*Architecture research for: v1.9 voice recognition redesign (decoupled recognizers + cross-validation + Japan merchant Drift store)*
*Researched: 2026-06-23*
