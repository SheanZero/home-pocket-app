# Phase 51: Cross-Validation + Daily/Joy Ledger Rework - Research

**Researched:** 2026-06-24
**Domain:** Pure-domain reconciliation logic (Dart) + classification-stub retirement + ledger-config seed audit (Flutter / Riverpod 3 / Drift)
**Confidence:** HIGH (all claims traced to file:line in the working tree; no external deps)

## Summary

Phase 51 is a **pure-domain insert + dead-code retirement**, not a feature build. All inputs already exist on disk: two independent recognizers (`CategoryRecognizer`, `MerchantRecognizer`) emitting typed verdicts (`CategoryMatchResult`, `List<MerchantCandidate>`), a thin keyword-priority merge already inlined in `ParseVoiceInputUseCase` (lines 108–147), and a config-backed authoritative ledger resolver (`CategoryService.resolveLedgerType`). The Phase-50 work already deleted the `parse_voice_input_use_case.dart:106` merchant-ledger short-circuit and landed `kMerchantAutoFillFloor = 0.85`. **Wave-1 (XVAL)** formalizes the inline merge into a pure `RecognitionReconciler` returning a `RecognitionOutcome` contract with an explicit none/weak/strong 3×3 truth table and resolve-on-final hysteresis. **Wave-2 (LEDGER)** retires the `lib/application/dual_ledger/` directory (5 files), re-routes `CreateTransactionUseCase` from `ClassificationService` to `CategoryService`, audits the 9 existing L2 ledger overrides, and adds invariant + reachable-L2-non-null gates.

The blast radius is small and well-bounded. The only **production** consumers of the retired `application/dual_ledger/` logic are `CreateTransactionUseCase` (constructor injection) and `features/accounting/presentation/providers/repository_providers.dart:152` (provider wiring). No OCR consumer exists (no `lib/application/ocr` or `lib/features/ocr` directory). The bulk of the blast radius is **test files** that must be rebuilt — and several carry non-classification invariants (currency-triple, hash-chain, entry-source) that MUST survive the rewrite (D-22).

**Primary recommendation:** Write `cross_validation_test.dart` as a cell-by-cell spec of the 3×3 table (this doc gives every cell) BEFORE coding the reconciler. Create `lib/features/voice/domain/` and move the recognition types there. Keep `deriveLedgerHint` (it is LIVE seed-time code, not dead — see Pitfall 1). Retire only `application/dual_ledger/`. Add the reachable-L2 gate mirroring `category_other_l2_invariant_test.dart`.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Merge two verdicts → outcome + band | `features/voice/domain/services/` (NEW, pure) | — | Pure function of two domain value objects; zero I/O (D-09). Domain layer. |
| 3×3 truth-table / banding | `features/voice/domain/` (reconciler) | — | Logic over verdict shapes; no DB access (D-06 only compares L2 ids). |
| Resolve-on-final hysteresis | `features/.../presentation/screens/voice_ptt_session_mixin.dart` | reconciler (pure) | Hysteresis is a UI-timing concern (when to call the reconciler / when to fill category), not domain logic. |
| Ledger derivation (authoritative) | `application/accounting/category_service.dart` | `data/` config repo | DB-backed config lookup. Already the single authoritative path. |
| Ledger derivation site (use case) | `application/accounting/create_transaction_use_case.dart` | — | Re-routes from `ClassificationService` → `CategoryService`. |
| Ledger config seed + overrides | `lib/shared/constants/default_categories.dart` | — | Dart literal `_defaultLedgerConfigs`; re-seeded, zero new data layer. |
| Merchant `ledger_hint` (non-authoritative, seed-time) | `application/accounting/ledger_hint_deriver.dart` | `lib/shared/constants/default_merchants.dart` | LIVE Phase-49 seed code — derives the merchant column. KEEP. |

## Standard Stack

**No new dependencies.** This phase is pure in-house Dart over existing types. The v1.9 cross-cutting constraints forbid FTS5 / fuzzy / embeddings / `drift ≥2.32.0`. The reconciler imports only `freezed_annotation` (for the new `RecognitionOutcome` / `ConfidenceBand`) and existing domain models.

### Core (existing, reused)
| Component | Location | Purpose | Why Standard |
|-----------|----------|---------|--------------|
| `CategoryRecognizer` | `lib/application/voice/recognition/category_recognizer.dart` | Keyword verdict source | Phase 50 engine; reconciler input. |
| `MerchantRecognizer` | `lib/application/voice/recognition/merchant_recognizer.dart` | Merchant candidates source | Phase 50 engine; reconciler input. |
| `CategoryService.resolveLedgerType` | `lib/application/accounting/category_service.dart:26` | Authoritative DB-backed ledger | Single source of truth post-retirement. |
| `CategoryLedgerConfigRepository` | `lib/features/accounting/domain/repositories/` | Config data path | Backs `CategoryService`. |
| Freezed | (pinned) | Immutable `RecognitionOutcome`, `ConfidenceBand`, `MerchantCandidate`, `CategoryMatchResult` | Project standard; all moving models already `@freezed`. |

**Installation:** none. `flutter pub run build_runner build --delete-conflicting-outputs` required after adding `@freezed` `RecognitionOutcome` and after moving files (regenerates `.freezed.dart` part files). `[VERIFIED: working tree]`

## Package Legitimacy Audit

Not applicable — this phase installs **zero** external packages (v1.9 zero-new-deps constraint; reconciler is pure in-house Dart). `[VERIFIED: .planning/ROADMAP.md §"v1.9 Cross-Cutting Constraints"]`

## Architecture Patterns

### System Architecture Diagram (voice path, post-Phase-51)

```
                 STT engine (speech_to_text)
                         │ SpeechRecognitionResult{recognizedWords, finalResult}
                         ▼
         voice_ptt_session_mixin._onResult  ─────────────────────────────┐
                         │                                                │
        ┌────────────────┴───────────────┐                               │
        │ isFinal == false (partial)     │  isFinal == true (end-speech) │
        ▼                                 ▼                               ▼
  update _partialText            _amountMerger.feedChunk         _parseFinalResult(text)
  (RAW TEXT + amount only;        (2.5s NUMERIC-only window;      → ParseVoiceInputUseCase.execute
   D-01: NO category fill)         amount path, decoupled)            │
                                                                       ▼
                                                  ┌──── two engines run INDEPENDENTLY ────┐
                                                  ▼                                        ▼
                                       CategoryRecognizer.resolve(keyword)    MerchantRecognizer.recognize(query)
                                            → CategoryMatchResult?              → List<MerchantCandidate> (raw scores)
                                                  │                                        │
                                                  └────────────────┬───────────────────────┘
                                                                   ▼
                                            RecognitionReconciler.reconcile(verdict, candidates)   ← NEW (pure)
                                              · band keyword: learning>seed>substring  (none/weak/strong)
                                              · band merchant: score vs 0.85 floor      (none/weak/strong)
                                              · 3×3 truth table → selectedCategoryId + ConfidenceBand + ranked alts
                                              · D-06 exact-L2-agreement boost
                                                                   ▼
                                                          RecognitionOutcome (no ledger)
                                                                   │ use case derives:
                                                                   ▼  resolveLedgerType(selectedCategoryId) ?? daily
                                                          VoiceParseResult { outcome wrapped, amount/date/currency }
                                                                   │ (resolve-on-final: category filled ONCE here)
                                                                   ▼
                                                       form.updateCategory  +  ledgerType = resolveLedgerType(finalCategoryId)
```

### Recommended file layout (NEW + moved)

```
lib/features/voice/                              # NEW feature dir (does not exist yet)
└── domain/
    ├── import_guard.yaml                        # copy accounting/domain pattern (deny data/infra/app/presentation/flutter)
    ├── models/
    │   ├── import_guard.yaml                    # allow: freezed_annotation, intra-domain leaves
    │   ├── merchant_candidate.dart              # MOVED from features/accounting/domain/models/
    │   ├── voice_parse_result.dart              # MOVED (incl. CategoryMatchResult, MatchSource, VoiceAudioFeatures)
    │   └── recognition_outcome.dart             # NEW: RecognitionOutcome + ConfidenceBand
    └── services/
        ├── import_guard.yaml
        └── recognition_reconciler.dart          # NEW: pure reconcile(verdict, candidates) → outcome

lib/application/accounting/create_transaction_use_case.dart   # re-route ClassificationService → CategoryService
lib/shared/constants/default_categories.dart                  # _defaultLedgerConfigs: audit L2 overrides

# DELETED:
lib/application/dual_ledger/                      # all 5 files (classification_service, rule_engine,
                                                  #   classification_result, repository_providers[.g])
```

> **NOTE on `features/voice/` vs `features/accounting/`:** `lib/features/voice/` does NOT exist yet `[VERIFIED: ls returned nothing]`. The plan must create the feature dir + its `import_guard.yaml` chain. `domain_import_rules_test.dart` (line 21–28) hard-codes the feature list `[accounting, analytics, family_sync, home, profile, settings]` — **adding `voice` to that list is a decision for the plan**; the test only enforces yaml shape for listed features, so an unlisted `voice/domain` is not auto-guarded. **Recommendation:** add `voice` to the test's `features` list so the new domain dir inherits the same guard enforcement.

### Pattern 1: Pure reconciler signature (D-09)
**What:** `reconcile` is a pure function — no `Future`, no repository, no I/O.
**Why:** D-06 makes the agreement boost compare only L2 ids (both verdicts already carry L2 ids), so the reconciler needs nothing from the DB. Ledger is derived by the use case AFTER reconciliation.

```dart
// lib/features/voice/domain/services/recognition_reconciler.dart  [NEW]
// Pure domain — imports only domain models + freezed-free logic.
class RecognitionReconciler {
  const RecognitionReconciler();

  RecognitionOutcome reconcile(
    CategoryMatchResult? keywordVerdict,         // null = keyword engine missed
    List<MerchantCandidate> merchantCandidates,  // recall-first, raw scores
  ) {
    // 1. band each engine (see "3×3 Truth Table" below)
    // 2. apply the 3×3 cell → selectedCategoryId + ConfidenceBand + ranked alternates
    // 3. NO ledger here. Outcome is ledger-free (D-09).
  }
}
```

### Pattern 2: Resolve-on-final hysteresis (D-01/D-02)
**What:** Partial STT results update raw text + amount but NOT the category chip. Category is filled exactly once, on the first end-of-speech `isFinal`.
**Where it lives:** `voice_ptt_session_mixin._onResult` (lines 657–698) — a UI-timing change, not domain.
**Current behavior (must change):** Today the **partial** path (line 665–670) debounces 300ms then calls `_parseVoiceInput` → `_fillFormFromText` → `state.updateCategory` (line 338). That fills the category from partials and causes the chip flicker D-01 eliminates.

```dart
// In the partial branch (_onResult, ~line 665): keep raw text + (merger) amount,
// but DO NOT push category from partials. Gate the category fill so it only
// happens on the final-result fill (_parseFinalResult → _fillFormFromText).
// Concretely: in _fillFormFromText, when called from the partial/continuous path,
// skip `state.updateCategory(...)`; only the final-result fill updates category.
```

**Deterministic answer to D-04 research flag #1 (does first final arrive <2s?):** YES, with HIGH confidence by code trace. The category does NOT wait on the merger's 2.5s window — that window is **numeric-only** (`_chunkStartsNumeric` / `_bufferLooksOpen` are digit/unit gates; `voice_chunk_merger.dart:131–178`) and governs only amount accumulation. Category resolution fires on `_parseFinalResult(text)` at the first `isFinal` (`_onResult` line 694). The first end-of-speech `isFinal` is driven by the STT engine's `pauseFor`/end-of-speech detection, independent of the merger. **The merger's `restartListen()` re-arm vs nhs R6 one-shot:** in the non-continuous hold path (`!_continuousActive`), `_parseFinalResult` is called once and the merger commits its amount; the 2.5s tail only matters for multi-segment numeric dictation ("一千…八百"), never for category. **Validation at execution time:** add a widget/integration test asserting that feeding a single `finalResult: true` chunk fills the category exactly once with no intermediate category update from preceding partials (the resolve-on-final no-flicker test, Success Criterion 3). Device-farm timing measurement is out of scope; the code path guarantees category ≠ amount-window-bound. `[VERIFIED: voice_ptt_session_mixin.dart:657-698, voice_chunk_merger.dart:131-178]`

### Anti-Patterns to Avoid
- **Deriving ledger inside the reconciler.** Outcome is ledger-free (D-09); use case derives `resolveLedgerType(selectedCategoryId) ?? daily`. Putting ledger in the reconciler would force a DB dependency and break purity.
- **Deleting `ledger_hint_deriver.dart`.** It is LIVE seed-time code (Pitfall 1). Only `application/dual_ledger/` is dead.
- **Boosting on L1-agreement.** D-06: boost ONLY on exact L2-id equality. L1-same/L2-different does NOT boost.
- **Reading `merchant.ledgerHint` for the transaction ledger.** D-21: column is retained but asserted never-read; ledger always derives from final category.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| L1→L2 normalization | New `_ensureL2` | `CategoryRecognizer.normalizeToL2` (already public, line 168) | D-03 always-L2 contract + override map already handled. |
| Ledger resolution | A second `daily/joy` map | `CategoryService.resolveLedgerType` | Retiring the second map (RuleEngine) is the WHOLE POINT of LEDGER-02. |
| Merchant seed ledger hint | Hand-author ledger column | `deriveLedgerHint` (single source of truth) | Already byte-parity-tested vs `resolveLedgerType`. |
| Reachable-L2 gate | New traversal | Mirror `category_other_l2_invariant_test.dart` | Existing pattern (Phase 21 D-03) for L2 reachability. |

**Key insight:** LEDGER-02's value is **deleting** a hand-rolled map (`RuleEngine._categoryRules`, which still references dead ids `cat_entertainment`/`cat_shopping` that no longer exist in the category tree — `rule_engine.dart:28-31`), not building anything new.

## Runtime State Inventory (rename/move scope — D-11/D-12 type moves)

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None. The type moves (`MerchantCandidate`, `VoiceParseResult`, `CategoryMatchResult`) are pure in-memory domain value objects — no persisted key, collection, or column references them by Dart type name. The merchant `ledger_hint` COLUMN stays (D-21, no schema change). | None. |
| Live service config | None — no external service embeds these type names. | None. |
| OS-registered state | None. | None. |
| Secrets/env vars | None. | None. |
| Build artifacts | `.freezed.dart` part files for `merchant_candidate`, `voice_parse_result`, and the new `recognition_outcome` regenerate on move/create. `dual_ledger/repository_providers.g.dart` is deleted with its source. | Run `build_runner build --delete-conflicting-outputs`; `git add -f lib/generated/` not needed (these are `.freezed.dart`/`.g.dart` beside source, not l10n). |

**Verified:** No `CategoryVerdict` type exists yet (`grep` returned nothing) — CONTEXT.md uses "CategoryVerdict" as a conceptual alias for the existing `CategoryMatchResult`. See "Open Question / Discretion: CategoryMatchResult fate" below.

---

## XVAL-01: The 3×3 Truth Table (cell-by-cell spec for `cross_validation_test.dart`)

This is the load-bearing spec. Write these cells as tests BEFORE coding (Research Flag, ROADMAP §"Phase 51 wave-1").

### Per-engine banding

**Keyword engine band** (from `CategoryMatchResult.source` + presence; D-08). The engine's confidence numbers are at `category_recognizer.dart`: exact-learning `0.85 + scoreBonus`, exact-seed `0.85`, substring-learned `0.80 + bonus*0.5`, substring-seed `0.80`.

| Keyword band | Condition (D-08 source ranking: learning > seed > substring) |
|--------------|--------------------------------------------------------------|
| **none** | `keywordVerdict == null` (engine missed). |
| **strong** | `source == MatchSource.learning` (user-validated `category_keyword_preferences` hit, `isLearned`/hitCount≥2) — exact OR promoted-substring. |
| **weak** | `source == MatchSource.keyword` (seed hit: exact-seed OR substring-seed; not user-learned). |

> Rationale: D-08 ranks `learning > seed keyword > substring fallback`. Map learning→strong; seed (whether exact or substring)→weak. The `source` enum already collapses exact-vs-substring into learning/keyword, so band reads purely off `source` — no need to thread the raw confidence float. **Tie-break note:** if a future plan wants exact-seed > substring-seed granularity, it must thread an extra signal; current `source` does not distinguish them. Recommend keeping the 2-band (learning=strong / keyword=weak) split — it is sufficient for every carried boundary case below.

**Merchant engine band** (from best candidate `score` vs `kMerchantAutoFillFloor = 0.85`; scoring tiers at `merchant_recognizer.dart:43-46`: exact 1.00, anchored-prefix/alias 0.85, containment 0.60, reverse 0.55).

| Merchant band | Condition |
|---------------|-----------|
| **none** | `merchantCandidates.isEmpty`. |
| **strong** | best `score >= 0.85` (exact or anchored-prefix/alias-at-start tier). |
| **weak** | best `score` in `[0.55, 0.85)` (containment / reverse-containment — below the auto-fill floor). |

### The 3×3 matrix (keyword rows × merchant columns)

`selectedCategoryId` = the chosen category; `band` = `ConfidenceBand`; `alternates` = ranked chips for Phase 52.

| keyword \ merchant | merchant=none | merchant=weak (0.55–0.85) | merchant=strong (≥0.85) |
|---|---|---|---|
| **keyword=strong** (learning) | KW wins. cat=KW.l2. **band=strong** (single strong signal). alts=[]. | KW wins. cat=KW.l2. **band=strong**. alts=[merchant.l2 chip]. | KW wins (XVAL-02 「在星巴克买杯子」→购物). cat=KW.l2. merchant→alternate chip. **band=strong** if exact-L2-agree (D-06 boost) else **strong** (kw strong already). alts=[merchant.l2]. |
| **keyword=weak** (seed) | KW wins. cat=KW.l2. **band=medium** (single signal, not user-validated). alts=[]. | KW wins (weak-kw does NOT get vetoed by weak-merchant). cat=KW.l2. **band=medium**. alts=[merchant.l2]. | KW wins (weak keyword still beats merchant per keyword-priority; XVAL-02 generalizes). cat=KW.l2. **band=medium**, OR **strong** iff exact-L2-agreement (D-06: merchant.l2 == KW.l2). alts=[merchant.l2 if differ]. |
| **keyword=none** | **No category.** cat=null (both-none). **band=weak**. alts=[]. Form gets amount/date only; manual pick. | merchant below floor → cat=merchant.l2 as **best-guess** (D-05 fill best-guess). **band=weak**. alts=ranked merchants. | merchant ≥floor auto-fills (bare スタバ→咖啡). cat=merchant.l2 (via normalizeToL2). **band=medium** (single strong merchant signal, no keyword corroboration). alts=other merchants. |

### D-06 exact-L2-agreement boost (the only path to `strong` from corroboration)

- Boost applies ONLY when `keywordVerdict != null` AND best merchant `score >= 0.85` AND `merchant.l2 (normalizeToL2) == keywordVerdict.categoryId` **exactly** (same L2 id).
- Effect: band → **strong** ("boosted-strong" — genuinely earned).
- L1-same / L2-different → NO boost (stays at the keyword's own band per the matrix).
- Reconciler purity preserved: it compares two L2 id strings. **BUT** `normalizeToL2` is async (DB-backed, `category_recognizer.dart:168`). **Design decision for the plan:** the merchant candidate's `categoryId` is already an L2 id at seed time (merchants map to L2 per MERCH-02), so the reconciler can compare `merchant.categoryId == keywordVerdict.categoryId` directly WITHOUT calling `normalizeToL2` — keeping the reconciler pure/sync. Verify at plan time that all seeded merchant `categoryId`s are L2 (Phase 49 invariant); if any merchant maps to an L1, the use case must normalize before handing the candidate to the reconciler. `[VERIFIED: merchant_candidate.dart categoryId is the seed L2 id; merchant_recognizer.dart:103]`

### The 4 carried boundary cases (must appear verbatim as named tests)

| Utterance | keyword band | merchant band | Expected | Cell |
|-----------|--------------|---------------|----------|------|
| 「在星巴克买杯子」→ 购物 (cup→shopping) | strong/weak (买/杯子 keyword) | strong (スタバ/Starbucks ≥0.85) | cat = shopping L2 (KW wins), merchant=咖啡 as alt chip | row keyword=strong/weak × merchant=strong, KW-wins |
| bare 「スタバ」→ 咖啡 | none (no activity keyword) | strong (alias-at-start ≥0.85) | cat = cafe L2 (merchant auto-fill), band=medium | keyword=none × merchant=strong |
| 「加油用了400块」→ 燃料/transport | strong/weak (加油 keyword) | none (no merchant) | cat = fuel L2 (category-only, DECOUP-02) | keyword × merchant=none |
| both-weak | weak (seed) or none | weak (<0.85) | best-guess filled + band=weak (D-05) | keyword=weak×weak or none×weak |

### Deterministic tie-break (Discretion item)

When two candidate categories tie on band/score:
1. **Keyword verdict always wins ties against merchant** (keyword-priority is the phase's core rule).
2. Among merchant candidates, the recognizer already breaks ties deterministically: score DESC, then longer `matchKey` first (`merchant_recognizer.dart:88-95`). The reconciler consumes that pre-sorted order — first element wins. No new tie-break needed.
3. For the `alternates` list ordering: keyword's chosen category first (if any), then merchants in recognizer rank order, de-duplicated by L2 id. Stable, deterministic.

### `RecognitionOutcome` / `ConfidenceBand` contract (D-09/D-10)

```dart
// lib/features/voice/domain/models/recognition_outcome.dart  [NEW @freezed]
enum ConfidenceBand { strong, medium, weak }   // D-10: defined in voice domain, computed here in P51

@freezed
abstract class RecognitionOutcome with _$RecognitionOutcome {
  const factory RecognitionOutcome({
    String? selectedCategoryId,                 // null only in both-none cell
    required ConfidenceBand band,
    @Default(<CategoryMatchResult>[]) List<CategoryMatchResult> alternates,  // ranked chips for P52
    String? resolvedKeyword,                    // D-13: verbatim passthrough (260526-pg6 learning-key contract)
    @Default(false) bool keywordMerchantConflict, // true when KW won over a strong merchant (XVAL-02)
    // NO ledgerType field — D-09. Use case derives resolveLedgerType(selectedCategoryId) ?? daily.
  }) = _RecognitionOutcome;
}
```

> `VoiceParseResult` (D-12) becomes the use-case DTO that WRAPS the outcome plus `amount/parsedDate/detectedCurrency/estimatedSatisfaction/merchantName`. Delete the `merchantLedgerType` field (already unpopulated — `voice_parse_result.dart:26`, comment confirms "no longer populated"). `ledgerType` field stays (the derived value the form reads).

---

## LEDGER-02: Retirement Blast Radius (D-14/D-15) — grep-confirmed

### Production consumers of `application/dual_ledger/` (the ONLY two)

| Site | Usage | Action |
|------|-------|--------|
| `lib/application/accounting/create_transaction_use_case.dart` | imports `dual_ledger/classification_service.dart` (line 12); constructor field `_classificationService` (line 77); calls `.classify(...)` in the `ledgerType == null` fallback branch (line 141–146). | Swap injection to `CategoryService`; replace fallback with `await _categoryService.resolveLedgerType(params.categoryId) ?? LedgerType.daily` (D-14/D-16). |
| `lib/features/accounting/presentation/providers/repository_providers.dart` | imports `dual_ledger/repository_providers.dart` (line 16); wires `classificationService: ref.watch(classificationServiceProvider)` (line 152). | Drop the import; wire `categoryService: ref.watch(categoryServiceProvider)` instead (provider already exists — used at form line ~277). |

**No OCR consumer:** `grep` over `lib/application/ocr` / `lib/features/ocr` → directories do not exist; zero classification refs. Success Criterion 6's "fold into config if a live consumer exists" → **no live non-test consumer beyond create_transaction**, so straight deletion is correct. `[VERIFIED: grep returned no ocr dirs]`

> ⚠️ **False-positive guard:** `transaction_details_form.dart:27` imports `features/dual_ledger/presentation/widgets/joy_celebration_overlay.dart` — that is the **UI** `features/dual_ledger/` (joy celebration), NOT the `application/dual_ledger/` logic being retired. Do NOT touch `features/dual_ledger/`. Only `lib/application/dual_ledger/` (5 files) is retired. `[VERIFIED: transaction_details_form.dart:27]`

### `application/dual_ledger/` directory contents (all 5 retired)

| File | Role | Has consumer outside dir? |
|------|------|---------------------------|
| `classification_service.dart` | The stub service | Yes — `create_transaction_use_case` only (re-routed) |
| `rule_engine.dart` | Hardcoded `daily/joy` map w/ DEAD ids (`cat_entertainment`, `cat_shopping` — `rule_engine.dart:28-29`) | No (only classification_service + own test) |
| `classification_result.dart` | DTO (`ClassificationResult` + `ClassificationMethod`) | No (only classification_service + own test) |
| `repository_providers.dart` | `ruleEngineProvider` + `classificationServiceProvider` | Yes — accounting `repository_providers.dart:152` (re-routed) |
| `repository_providers.g.dart` | generated | deleted with source |

### create_transaction injection swap (concrete)

```dart
// create_transaction_use_case.dart
// REMOVE: import '../dual_ledger/classification_service.dart';
// ADD:    import 'category_service.dart';
// constructor: replace `required ClassificationService classificationService`
//          with `required CategoryService categoryService`
// fallback branch (lines 137-147):
final LedgerType resolvedLedgerType;
if (params.ledgerType != null) {
  resolvedLedgerType = params.ledgerType!;
} else {
  resolvedLedgerType =
      await _categoryService.resolveLedgerType(params.categoryId)
          ?? LedgerType.daily;   // D-16 conservative fallback
}
```

> **Note on the production path:** the form ALWAYS passes `ledgerType: _ledgerType` (`transaction_details_form.dart:737, 801`), derived via `CategoryService.resolveLedgerType` (lines 277/450). So in production the `ledgerType == null` branch rarely fires — but it IS the manual/OCR/test path and must be correct. The re-route makes the fallback consistent with the form's own derivation (single source of truth).

---

## LEDGER-02: L2 Override Audit (D-17/D-18) — complete proposal for user spot-check

**Current state (D-17 confirmed):** All 19 L1 have a config; L2 without override inherits L1. **No null gaps exist** today — `resolveLedgerType` returns the L1 config for any L2 lacking a direct config. So this is an audit + selective expansion, not a gap-fill. `[VERIFIED: category_service.dart:34-38 inheritance; _defaultLedgerConfigs has all 19 L1]`

**Current 9 L2 overrides (baseline):**
- `cat_clothing_clothes/shoes/underwear/cleaning` → **daily** (clothing L1 defaults joy; these basics overridden to daily)
- `cat_social_drinks/gifts` → **joy** (social L1 defaults daily; these enjoyment-types overridden to joy)
- `cat_special_wedding/movement/newyear` → **joy** (special L1 defaults daily; life-event splurges → joy)

**Principle (D-18):** L2 inherits L1; override ONLY clearly enjoyment / self-investment L2. The 138 L2s grouped by L1 default below — **proposed NEW overrides flagged**, everything else inherits. User confirms/strikes individual rows before commit (Phase 49/50 seed pattern). `[ASSUMED]` — these are judgment-based proposals, not verified requirements; see Assumptions Log.

### L1 defaults (for reference)
daily L1s: food, daily, transport, social, health, utilities, communication, housing, car, tax, insurance, special, other_expense.
joy L1s: pet, hobbies, clothing, education, allowance, asset.

### Proposed L2 overrides to ADD (review each)

| L2 id | Parent L1 (default) | Proposed | Rationale | `[ASSUMED]` |
|-------|--------------------|----------|-----------|---|
| `cat_clothing_accessories` | clothing (joy) | **daily**? | Basic accessory vs fashion — borderline; could stay joy. | review |
| `cat_clothing_bags` | clothing (joy) | keep joy | Bags lean fashion/enjoyment → keep joy (inherit). | review |
| `cat_clothing_hair` | clothing (joy) | **daily**? | Haircut is grooming-maintenance, not splurge → daily candidate. | review |
| `cat_clothing_cosmetics` | clothing (joy) | keep joy | Cosmetics lean enjoyment → keep joy. | review |
| `cat_clothing_esthetic` | clothing (joy) | keep joy | Esthetic/beauty = self-investment → joy. | review |
| `cat_food_dining_out` | food (daily) | keep daily | Necessity (already daily via RuleEngine legacy) → daily. | review |
| `cat_food_cafe` | food (daily) | keep daily | Cafe could be joy but legacy mapped daily; conservative daily. | review |
| `cat_food_drinks` | food (daily) | **joy**? | Alcohol/bar drinks lean enjoyment (parallels social_drinks→joy). | review |
| `cat_health_fitness` | health (daily) | **joy**? | Gym/fitness = self-investment → joy candidate. | review |
| `cat_health_massage` | health (daily) | **joy**? | Massage = enjoyment/wellness → joy candidate. | review |
| `cat_health_supplements` | health (daily) | keep daily | Health maintenance → daily. | review |
| `cat_social_ceremonial` | social (daily) | keep daily | Obligatory ceremonial (香典 etc.) → daily. | review |
| `cat_hobbies_*` | hobbies (joy) | keep joy (all inherit) | Hobbies L1 is joy; subscription/music/oshikatsu/travel all enjoyment. | review |
| `cat_education_*` | education (joy) | keep joy | Self-investment. (Note: legacy RuleEngine had education=joy.) | review |
| `cat_asset_*`, `cat_allowance_*` | joy | keep joy | Already joy via L1. | review |
| `cat_special_funeral`, `cat_special_nursing`, `cat_special_fertility` | special (daily) | keep daily | Necessity life-events → daily (NOT joy). | review |

**Recommendation:** The SAFEST minimal change is to add **zero** new overrides (the 9 existing ones cover the clear cases) and instead lean on the principle "inherit L1." The proposals above marked `**...?**` are the only genuine candidates — present them to the user as a short yes/no list. Over-overriding risks mis-classifying necessities as joy (the conservative-daily bias of D-16). `[ASSUMED — needs user confirmation]`

### D-19 reachable-L2-non-null hard gate (mirror Phase 21 / 49 / 50 pattern)

Mirror `test/architecture/category_other_l2_invariant_test.dart`. New gate:

```dart
// test/architecture (or test/unit/.../ledger) — "every reachable L2 resolveLedgerType non-null"
test('every L1 and every L2 resolves to a non-null LedgerType', () async {
  // Build CategoryService over an in-memory seeded DB (or assert against
  // _defaultLedgerConfigs + DefaultCategories.all directly, like deriveLedgerHint).
  for (final cat in DefaultCategories.all) {           // 19 L1 + 138 L2
    final ledger = resolve(cat.id);                     // direct config OR L1 inherit
    expect(ledger, isNotNull,
      reason: 'category ${cat.id} (level ${cat.level}) resolves to null ledger '
              '— silent daily fallback would mask a config gap');
  }
});
```

> Because the inheritance rule already guarantees non-null for every L2 whose L1 has a config (all 19 do), this gate primarily traps a FUTURE edit that adds an L1 without a config or an L2 whose `parentId` config is missing. It is a regression net, not a current-gap filler (D-17). The const-data variant (no DB) mirrors `deriveLedgerHint`'s pure evaluation and runs fast.

### D-20 ledger invariant test (`ledgerType == resolveLedgerType(finalCategoryId)`)

Covers: new entry (voice + manual) and edit-WITH-category-change. **Excludes** edit-load-preserving-stored-ledger (W3 / D-23 — historical overrides allowed). Assert the persisted `transaction.ledgerType == resolveLedgerType(transaction.categoryId)` for create + category-change paths.

---

## D-21: Merchant ledgerType column — keep + assert-never-read

- Column stays (no schema change — v1.9 constraint: schema is Phase-49-only v21→v22). `[VERIFIED: ROADMAP §"v1.9 Cross-Cutting Constraints"]`
- Populated at seed time by `deriveLedgerHint` → `MerchantCandidate.ledgerHint`.
- **Add an invariant test** proving the transaction ledger derivation never reads `MerchantCandidate.ledgerHint` / merchant `ledger_hint`: trace that `create_transaction` and the use case derive ledger ONLY from `selectedCategoryId` via `resolveLedgerType`. A code-structure assertion (grep-based, or a behavioral test where a merchant with a contradictory `ledgerHint` still yields category-derived ledger) satisfies this.

---

## Discretion items resolved

### `ledger_hint_deriver.dart` disposition → **KEEP** (do NOT remove)

`deriveLedgerHint` is **LIVE seed-time code**, NOT dead. Consumers:
- `lib/shared/constants/default_merchants.dart:17-18` (derives `ledger_hint` for each merchant)
- `lib/application/accounting/seed_merchants_use_case.dart:66` (`ledgerHint: deriveLedgerHint(m.categoryId).name`)
- Parity test `test/unit/application/accounting/ledger_hint_derivation_test.dart` asserts byte-equality with `resolveLedgerType`.

It is the single source of truth for the **non-authoritative merchant column** (D-21). Removing it would break Phase-49 merchant seeding. `[VERIFIED: grep deriveLedgerHint]` The CONTEXT line 104 framing ("复核去留") resolves to **keep** — it was a pre-emptive ledger-desync guard AND it's the live seed deriver. Its parity test stays valuable (it proves the merchant column and the authoritative path agree).

### `CategoryMatchResult` vs `CategoryVerdict` → **keep `CategoryMatchResult`** (rename optional)

`CategoryVerdict` does not exist as a type (`grep` empty). `CategoryMatchResult` (`voice_parse_result.dart:62`) is the keyword-engine verdict, carrying `categoryId/confidence/source`. CONTEXT D-12 says "keep `CategoryMatchResult` as keyword verdict input; result side carried by Outcome." **Recommendation:** keep the name `CategoryMatchResult` for the keyword verdict input to minimize cascade churn; the result side is the new `RecognitionOutcome`. A rename to `CategoryVerdict` is cosmetic and expands the cascade — defer unless the plan wants naming symmetry with `MerchantCandidate`. `[VERIFIED: no CategoryVerdict type exists]`

### D-11/D-12 cascade import scope (the move blast radius)

Feature→feature **domain-model** imports are **explicitly ALLOWED** by the arch test (`domain_import_rules_test.dart:105-109` `isCrossFeatureDomainModel`). So moving the types to `features/voice/domain/` is a **cleanliness/convention** choice (avoid accounting↔voice coupling), NOT forced by import_guard. The `features/import_guard.yaml` Thin-Feature deny set (line 4-8) only bans `features/*/use_cases|application|infrastructure|data/**` — NOT cross-feature domain. `[VERIFIED: domain_import_rules_test.dart, features/import_guard.yaml]`

**Concrete reference sites that update when `MerchantCandidate` moves** (`features/accounting/domain/models/` → `features/voice/domain/models/`):
- `lib/application/voice/recognition/merchant_recognizer.dart:1`
- `lib/features/accounting/domain/models/voice_parse_result.dart:3`
- tests: `parse_voice_input_use_case_test.dart`, `merchant_recognizer_test.dart`, `merchant_recognizer_compound_utterance_test.dart`, `currency_detection_test.dart`

**Sites that update when `voice_parse_result.dart` (+ `CategoryMatchResult`/`MatchSource`) moves:**
- `lib/application/voice/parse_voice_input_use_case.dart:2`
- `lib/application/voice/voice_satisfaction_estimator.dart`
- `lib/application/voice/recognition/category_recognizer.dart:24`
- `lib/features/accounting/presentation/screens/voice_ptt_session_mixin.dart`
- `lib/features/accounting/presentation/screens/voice_input_screen_helpers.dart`
- tests (8): `voice_parse_result_test.dart`, `voice_input_screen_helpers_test.dart`, `voice_ptt_session_mixin_test.dart`, `parse_voice_input_use_case_test.dart`, `voice_satisfaction_estimator_test.dart`, `category_recognizer_test.dart`, `manual_one_step_screen_test.dart`, `voice_input_screen_test.dart`, `voice_input_screen_foreign_save_test.dart`, `voice_save_entry_source_test.dart`, `currency_detection_test.dart`

> **Plan guidance:** prefer `rename_symbol`/move-aware tooling or a careful path-update pass. Also move `merchant_candidate.dart`'s allow-leaf into the new `voice/domain/models/import_guard.yaml`. Update `voice_parse_result.dart`'s import of `merchant_candidate.dart` (intra-domain leaf in the new location). `VoiceAudioFeatures` (in the same file) moves too — verify its consumer `voice_satisfaction_estimator.dart`.

---

## Common Pitfalls

### Pitfall 1: Deleting `ledger_hint_deriver.dart` as "dead code"
**What goes wrong:** It LOOKS like a Phase-50 leftover ("byte-equal mirror"). Deleting it breaks merchant seeding (`seed_merchants_use_case.dart:66`).
**How to avoid:** KEEP it. Only `application/dual_ledger/` is dead. `[VERIFIED]`

### Pitfall 2: Touching `features/dual_ledger/` (the joy-celebration UI)
**What goes wrong:** grep for "dual_ledger" hits `features/dual_ledger/presentation/widgets/joy_celebration_overlay.dart` (alive UI). Retiring it breaks the joy celebration.
**How to avoid:** Retire ONLY `lib/application/dual_ledger/`. `[VERIFIED: transaction_details_form.dart:27]`

### Pitfall 3: Dropping non-classification invariants when rebuilding tests (D-22)
**What goes wrong:** Tests like `create_transaction_currency_test.dart`, `entry_path_stamping_test.dart`, `manual_save_entry_source_test.dart`, `voice_save_entry_source_test.dart` import `dual_ledger` but ALSO assert currency-triple / hash-chain / entry-source invariants. Deleting them wholesale loses those guards.
**How to avoid:** Rebuild these tests swapping the `ClassificationService` coupling for `CategoryService`, but RE-ASSERT currency-triple, hash-chain, and entry-source cases. Only `rule_engine_test.dart` / `classification_service_test.dart` / `classification_result_test.dart` / `dual_ledger/providers_characterization_test.dart` are pure-retirement deletes. `[VERIFIED: grep blast radius]`

### Pitfall 4: Category chip flicker from partial-result fills
**What goes wrong:** Today the partial path fills category (`_onResult:668` → `updateCategory:338`). If left as-is, the chip jitters across partials.
**How to avoid:** Gate `state.updateCategory` to the final-result fill only (D-01). Keep raw-text + amount live.

### Pitfall 5: Reconciler made async / impure for the D-06 boost
**What goes wrong:** Calling `normalizeToL2` (async, DB-backed) inside the reconciler breaks D-09 purity.
**How to avoid:** Compare `merchant.categoryId == keyword.categoryId` directly (both are L2 seed ids). If the use case must normalize, do it BEFORE calling `reconcile`. `[VERIFIED: merchant seed ids are L2]`

### Pitfall 6: New `voice/domain` not added to `domain_import_rules_test.dart` features list
**What goes wrong:** The new domain dir escapes the arch-test guard (the test only checks listed features).
**How to avoid:** Add `'voice'` to the `features` const (line 21-28) and create the yaml chain.

---

## Validation Architecture

> nyquist_validation enabled (no config disabling it found).

### Test Framework
| Property | Value |
|----------|-------|
| Framework | `flutter_test` (Flutter 3.44.0) + `mocktail`/manual fakes |
| Config file | `test/flutter_test_config.dart` (golden comparator swap — exists) |
| Quick run command | `flutter test test/unit/.../cross_validation_test.dart -x` |
| Full suite command | `flutter test` (also `flutter analyze` must be 0) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| XVAL-01 | 3×3 truth table, cell-by-cell | unit | `flutter test test/unit/features/voice/domain/services/cross_validation_test.dart` | ❌ Wave 0 |
| XVAL-02 | 星巴克买杯子→购物; bare スタバ→咖啡 | unit | (in cross_validation_test, named boundary cases) | ❌ Wave 0 |
| XVAL-03 | resolve-on-final no-flicker | widget | `flutter test test/.../voice_ptt_session_mixin_test.dart` (new case) | ⚠️ extend |
| LEDGER-01 | `ledgerType == resolveLedgerType(finalCategoryId)` per path | unit/integration | `flutter test test/.../create_transaction_*_test.dart` (rebuilt) | ⚠️ rebuild |
| LEDGER-02 | every reachable L2 non-null; retirement | arch/unit | `flutter test test/architecture/<new>_ledger_l2_invariant_test.dart` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** the scoped test for the file touched + `flutter analyze`.
- **Per wave merge:** **FULL `flutter test`** (MEMORY gotcha: post-merge gates auto-sniff `xcodebuild`/`true` because config build/test commands are empty — run `flutter analyze` + full `flutter test` MANUALLY as the orchestrator; scoped tests miss arch tests like `domain_import_rules_test`, `hardcoded_cjk_ui_scan`).
- **Phase gate:** full suite green + `flutter analyze` 0 before `/gsd-verify-work`.

### Wave 0 Gaps
- [ ] `test/unit/features/voice/domain/services/cross_validation_test.dart` — XVAL-01/02 (3×3 spec + 4 boundary cases). **Write FIRST.**
- [ ] `test/architecture/ledger_reachable_l2_invariant_test.dart` (or unit) — D-19.
- [ ] Ledger invariant test (D-20) — create + category-change paths.
- [ ] Merchant-ledgerHint-never-read assertion (D-21).
- [ ] Resolve-on-final no-flicker test (XVAL-03) — extend mixin test.
- [ ] Rebuild (NOT delete) the 4 non-classification-invariant tests (Pitfall 3).
- [ ] Add `'voice'` to `domain_import_rules_test.dart` features list + create `voice/domain/import_guard.yaml` chain.

---

## Security Domain

`security_enforcement` enabled. This phase touches the voice path (sensitive transcript) and a pure reconciler.

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V5 Input Validation | yes | Reconciler consumes already-validated verdicts; `create_transaction` retains all input validation (bookId/amount/category/currency-triple — lines 86-122) — MUST survive the re-route. |
| V6 Cryptography | indirect | Hash-chain computation in `create_transaction` (line 176) unchanged; the re-route must not alter the hashed fields. |
| V7 Logging | yes | **Never log raw transcript / amount / merchant** (MerchantRecognizer V7 discipline, `merchant_recognizer.dart:20`). The reconciler must not `print`/log verdicts. Covered by `production_logging_privacy_test.dart`. |

### Known Threat Patterns
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Sensitive utterance leaked via log | Information disclosure | No-log discipline in reconciler; `production_logging_privacy_test.dart` gate. |
| Ledger desync (two divergent maps) | Tampering/integrity | LEDGER-02 deletes the second map; D-20 invariant test. |
| Learning-key orphan (write-key ≠ read-key) | Integrity | D-13: `resolvedKeyword` verbatim passthrough; 260526-pg6 contract preserved. |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Proposed NEW L2 overrides (food_drinks→joy, health_fitness/massage→joy, clothing_hair→daily, etc.) | LEDGER-02 L2 Audit | Mis-classified ledger for those L2s; user spot-check is the safety net (D-18). Low risk — conservative default is inherit-L1. |
| A2 | keyword band = 2-tier (learning=strong / keyword=weak) is sufficient | XVAL-01 banding | If exact-seed must outrank substring-seed, `source` enum doesn't distinguish — would need an extra signal threaded from recognizer. Medium: affects band granularity, not category choice. |
| A3 | All seeded merchant `categoryId`s are L2 (so reconciler can compare ids sync without `normalizeToL2`) | D-06 boost / Pitfall 5 | If a merchant maps to an L1, sync id-compare would miss the boost; use case must normalize first. Verify against Phase-49 seed at plan time. |
| A4 | band=medium for single-strong-signal (keyword=weak alone, or merchant-only auto-fill) | 3×3 matrix | The exact band labels for middle cells are a design choice; user/plan may want weak instead of medium. The CONTEXT only fixes strong (exact-L2-agree) and weak (both-weak). Medium for single-signal is the natural third. |

> A4 note: CONTEXT D-10 fixes only two anchors — "精确-L2-agreement→strong / 双弱→weak". The middle band ("单强信号→medium") is stated in D-10 itself ("单强信号→medium"), so A4 is actually CITED, low-risk. The matrix follows D-10's three-anchor definition exactly.

## Open Questions

1. **Should `voice` join `domain_import_rules_test.dart`'s features list?**
   - Known: feature→feature domain-model imports are allowed; the new dir is unguarded unless listed.
   - Recommendation: add `'voice'` to the list for consistent guard enforcement (cheap, safe).

2. **Exact-seed vs substring-seed band granularity (A2).**
   - Known: `source` enum collapses both to `MatchSource.keyword`.
   - Recommendation: keep 2-tier banding unless a boundary case demands finer split (none of the 4 carried cases do).

3. **How many of the proposed L2 overrides does the user actually want?**
   - Resolve via the D-18 spot-check list before the Wave-2 seed commit.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | build/test | ✓ | 3.44.0 (stable) | — |
| `build_runner` | freezed/riverpod gen | ✓ (project pinned) | generator 4.x | — |
| Device/simulator (STT timing) | XVAL-03 device validation | not required | — | Code-trace proves category ≠ amount-window-bound; widget test for no-flicker (no device farm). |

**Missing dependencies with no fallback:** none.

## Sources

### Primary (HIGH confidence — working-tree file:line)
- `lib/application/voice/parse_voice_input_use_case.dart` — inline merge, floor, ledger derivation.
- `lib/application/voice/recognition/{category,merchant}_recognizer.dart` — verdict shapes, scoring tiers, banding inputs.
- `lib/application/voice/voice_chunk_merger.dart:131-178` — numeric-only 2.5s window (decoupling proof).
- `lib/features/accounting/presentation/screens/voice_ptt_session_mixin.dart:657-716` — STT partial/final flow, resolve-on-final site.
- `lib/application/accounting/{category_service,create_transaction_use_case,ledger_hint_deriver}.dart` — ledger path + retirement target.
- `lib/application/dual_ledger/*.dart` (5 files) — retirement contents.
- `lib/shared/constants/default_categories.dart:1192-1222` + parsed 138 L2 tree — config audit.
- `test/architecture/{domain_import_rules,category_other_l2_invariant}_test.dart` — guard posture + gate pattern.
- grep blast radius for `RuleEngine`/`ClassificationService`/`dual_ledger/`/`MerchantCandidate`/`voice_parse_result.dart`.

### Secondary (MEDIUM)
- `.planning/phases/51-cross-validation.../51-CONTEXT.md` (D-01..D-23), `.planning/ROADMAP.md` §Phase 51 + cross-cutting + research flags, `.planning/REQUIREMENTS.md` (XVAL/LEDGER).
- `MEMORY.md` — post-merge gate Flutter mismatch, learning-key identity contract, decoupled-recognizer gotchas.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — zero new deps; all reused types verified on disk.
- 3×3 truth table: HIGH — derived from existing band inputs + CONTEXT D-05..D-08; middle-cell band labels follow D-10's three anchors (one ASSUMED granularity, A2).
- Retirement blast radius: HIGH — grep-confirmed; only 2 production consumers.
- L2 override audit: MEDIUM — current state verified; new override proposals ASSUMED (user spot-check by design, D-18).
- STT/hysteresis: HIGH (code trace) — device timing not measured but path proves decoupling.

**Research date:** 2026-06-24
**Valid until:** 2026-07-24 (stable in-repo domain; re-verify if Phase 50 artifacts change before planning).
