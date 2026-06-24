# Phase 51: Cross-Validation + Daily/Joy Ledger Rework - Pattern Map

**Mapped:** 2026-06-24
**Files analyzed:** 14 (4 new, 6 modified, 5 retired, + tests)
**Analogs found:** 13 / 14 (1 net-new contract type — `RecognitionOutcome` — has a structural analog in existing `@freezed` verdict models)

This phase is a **pure-domain insert + dead-code retirement**, not a feature build. Almost every new file has a strong in-repo analog because the verdict models, seed-gate tests, use-case wiring, and config seed all already exist. The planner should copy concrete shapes below rather than invent.

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/features/voice/domain/services/recognition_reconciler.dart` (NEW) | service (pure domain) | transform | `lib/application/voice/parse_voice_input_use_case.dart:108-147` (inline merge being formalized) | role+flow match |
| `lib/features/voice/domain/models/recognition_outcome.dart` (NEW) | model | transform/value-object | `lib/features/accounting/domain/models/merchant_candidate.dart` (freezed verdict) | role match |
| `lib/features/voice/domain/models/merchant_candidate.dart` (MOVED) | model | value-object | itself (move only) | exact |
| `lib/features/voice/domain/models/voice_parse_result.dart` (MOVED + field-delete) | model (DTO) | value-object | itself (move + `merchantLedgerType` delete) | exact |
| `lib/features/voice/domain/import_guard.yaml` chain (NEW ×3) | config | n/a | `lib/features/accounting/domain/import_guard.yaml` + `models/import_guard.yaml` | exact |
| `lib/application/accounting/create_transaction_use_case.dart` (MODIFIED) | use-case | request-response | itself (injection swap) — analog wiring in `category_service.dart` | exact |
| `lib/features/accounting/presentation/providers/repository_providers.dart` (MODIFIED) | provider | DI wiring | itself, `createTransactionUseCase` provider lines 145-156 | exact |
| `lib/shared/constants/default_categories.dart` `_defaultLedgerConfigs` (MODIFIED) | config/seed | data | itself, lines 1192-1222 (existing 9 L2 overrides) | exact |
| `test/unit/features/voice/domain/services/cross_validation_test.dart` (NEW) | test | spec | recognizer/merger tests + 3×3 spec in RESEARCH | role match |
| `test/architecture/ledger_reachable_l2_invariant_test.dart` (NEW) | test (arch gate) | n/a | `test/architecture/category_other_l2_invariant_test.dart` | exact pattern |
| ledger invariant test D-20 (NEW) | test | n/a | rebuilt `create_transaction_*_test.dart` | role match |
| merchant-ledgerHint-never-read test D-21 (NEW) | test | n/a | behavioral assertion | partial |
| `test/architecture/domain_import_rules_test.dart` (MODIFIED) | test | n/a | itself, `features` const lines 21-28 | exact |
| `lib/application/dual_ledger/` (5 files RETIRED) | — | — | — | delete |

**Retired files (D-14/D-15):** `classification_service.dart`, `rule_engine.dart`, `classification_result.dart`, `repository_providers.dart`, `repository_providers.g.dart`.

**DO NOT TOUCH:** `lib/application/accounting/ledger_hint_deriver.dart` (LIVE seed code, KEEP — RESEARCH Pitfall 1); `lib/features/dual_ledger/` (joy-celebration UI, grep false-positive — RESEARCH Pitfall 2).

---

## Pattern Assignments

### `recognition_outcome.dart` (NEW model — voice domain)

**Analog:** `lib/features/accounting/domain/models/merchant_candidate.dart` (whole file — a pure `@freezed` verdict value object that imports ONLY `freezed_annotation`).

**Imports + part + class shape to copy** (`merchant_candidate.dart:1-3,19-32`):
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'recognition_outcome.dart' -> 'recognition_outcome.freezed.dart';

@freezed
abstract class RecognitionOutcome with _$RecognitionOutcome { ... }
```

**Target contract (D-09/D-10, RESEARCH §RecognitionOutcome):**
```dart
enum ConfidenceBand { strong, medium, weak }

@freezed
abstract class RecognitionOutcome with _$RecognitionOutcome {
  const factory RecognitionOutcome({
    String? selectedCategoryId,                 // null only in both-none cell
    required ConfidenceBand band,
    @Default(<CategoryMatchResult>[]) List<CategoryMatchResult> alternates,
    String? resolvedKeyword,                    // D-13 verbatim passthrough
    @Default(false) bool keywordMerchantConflict,
    // NO ledgerType — D-09. Use case derives resolveLedgerType(...) ?? daily.
  }) = _RecognitionOutcome;
}
```
Note the `@Default(<...>[])` collection pattern is copied directly from `voice_parse_result.dart:55` (`@Default(<MerchantCandidate>[]) List<MerchantCandidate> merchantCandidates`).

---

### `recognition_reconciler.dart` (NEW pure service — voice domain)

**Analog:** the inline merge it formalizes — `parse_voice_input_use_case.dart:108-147`. That block IS the pre-existing reconciliation logic; the reconciler extracts it pure.

**Current inline keyword-priority merge to formalize** (lines 108-147 — keyword wins, else best merchant ≥ `kMerchantAutoFillFloor` (0.85)):
```dart
if (categoryMatch != null) {
  finalCategory = categoryMatch;                       // keyword wins (XVAL-02)
} else {
  final best = merchantCandidates.isEmpty ? null : merchantCandidates.first;
  if (best != null && best.score >= kMerchantAutoFillFloor) {
    // auto-fill from merchant
  }
}
```

**Pure signature (D-09, RESEARCH Pattern 1) — NO Future, NO repo:**
```dart
class RecognitionReconciler {
  const RecognitionReconciler();
  RecognitionOutcome reconcile(
    CategoryMatchResult? keywordVerdict,
    List<MerchantCandidate> merchantCandidates,
  ) { /* 3×3 banding + selection; NO ledger; NO normalizeToL2 (Pitfall 5) */ }
}
```

**CRITICAL purity rules (RESEARCH Pitfall 5 / D-06):** compare `merchant.categoryId == keywordVerdict.categoryId` directly (both are L2 seed ids) — do NOT call the async `normalizeToL2` inside the reconciler. The use case normalizes BEFORE calling `reconcile` if needed. Banding source ranking from `CategoryMatchResult.source` (`voice_parse_result.dart:71-76`): `learning`→strong, `keyword`→weak, `null`→none. Full 3×3 truth-table is in RESEARCH §XVAL-01 — copy cell-by-cell.

---

### `merchant_candidate.dart` + `voice_parse_result.dart` (MOVED to `features/voice/domain/models/`)

**Analog:** the files themselves. Move-only for `merchant_candidate.dart`; move + field-delete for `voice_parse_result.dart` (drop `merchantLedgerType` at line 26 — already unpopulated, comment confirms). `VoiceAudioFeatures` (same file) moves too.

**Cascade import-update sites** (RESEARCH §D-11/D-12, grep-confirmed — planner applies path updates):
- MerchantCandidate movers: `merchant_recognizer.dart:1`, `voice_parse_result.dart:3`, + 4 tests.
- VoiceParseResult movers: `parse_voice_input_use_case.dart:2`, `voice_satisfaction_estimator.dart`, `category_recognizer.dart:24`, `voice_ptt_session_mixin.dart`, `voice_input_screen_helpers.dart` + ~11 tests.

Feature→feature domain-model imports are ALLOWED by arch test (`domain_import_rules_test.dart:105-109`), so the move is a cleanliness choice, not forced — but DO it (D-11) to avoid accounting↔voice coupling.

---

### `import_guard.yaml` chain (NEW — `features/voice/domain/`)

**Analog (copy verbatim, retarget paths):**

Feature-level deny (copy `lib/features/accounting/domain/import_guard.yaml` — parent owns deny only, no allow):
```yaml
deny:
  - package:home_pocket/data/**
  - package:home_pocket/infrastructure/**
  - package:home_pocket/application/**
  - package:home_pocket/features/**/presentation/**
  - package:flutter/**
inherit: true
```

Per-subdir `models/import_guard.yaml` (copy `accounting/domain/models/import_guard.yaml` — children own the allow whitelist):
```yaml
allow:
  - dart:core
  - package:freezed_annotation/**
  - merchant_candidate.dart       # intra-domain leaf for voice_parse_result + recognition_outcome
inherit: true
```
A `services/import_guard.yaml` is also needed (allow `freezed_annotation` + the model leaves).

---

### `create_transaction_use_case.dart` (MODIFIED — injection swap)

**Analog:** the constructor + fallback branch in this same file, and `CategoryService` shape (`category_service.dart:8-41`).

**Concrete swap (RESEARCH §LEDGER-02, lines 12, 62, 69, 77, 137-147):**
```dart
// REMOVE: import '../dual_ledger/classification_service.dart';
// ADD:    import 'category_service.dart';
// constructor: required ClassificationService classificationService
//          ->  required CategoryService categoryService
// fallback branch (currently 137-147):
if (params.ledgerType != null) {
  resolvedLedgerType = params.ledgerType!;
} else {
  resolvedLedgerType =
      await _categoryService.resolveLedgerType(params.categoryId)
          ?? LedgerType.daily;   // D-16 conservative fallback
}
```

**MUST-SURVIVE invariants** in this file (do NOT lose during edit — RESEARCH ASVS V5/V6): input validation (lines 87-95), currency-triple validation (101-122), amount↔triple consistency (109-122), category-exists check (124-128), hash-chain (line ~176). The re-route touches ONLY the ledger-resolution branch.

---

### `repository_providers.dart` (MODIFIED — provider rewiring)

**Analog:** the `createTransactionUseCase` provider itself (lines 145-156).

**Concrete (RESEARCH §LEDGER-02 line 152):**
```dart
// drop:  import '...dual_ledger/repository_providers.dart';
// line 152: classificationService: ref.watch(classificationServiceProvider),
//   ->      categoryService: ref.watch(categoryServiceProvider),
//   (categoryServiceProvider already exists — used at form ~line 277)
```

---

### `_defaultLedgerConfigs` seed audit (MODIFIED — `default_categories.dart:1192-1222`)

**Analog:** the existing literal + its 9 L2 overrides (lines 1213-1221). Same `_config(id, LedgerType.x)` factory pattern.

**Action (D-17/D-18):** all 19 L1 already covered, no null gaps. This is selective L2-override expansion. RESEARCH §LEDGER-02 L2 Audit lists the full proposal (food_drinks→joy, health_fitness/massage→joy, clothing_hair→daily, etc.) — **commit only after user spot-check** (Phase 49/50 seed pattern). Safest minimal: add ZERO new overrides; the 9 existing cover the clear cases.

---

### Test patterns

**`cross_validation_test.dart` (NEW, write FIRST — Wave 0):** No direct analog file; the SPEC is RESEARCH §XVAL-01 (3×3 matrix + 4 named boundary cases). Use existing recognizer test structure (`category_recognizer_test.dart`, `merchant_recognizer_test.dart`) for fixture/group style. Write each cell as a named test before coding the reconciler.

**`ledger_reachable_l2_invariant_test.dart` (NEW — D-19):** **Exact pattern analog:** `test/architecture/category_other_l2_invariant_test.dart`. Copy its structure — iterate `DefaultCategories.all`, sanity-guard the 19-L1 count, assert each category resolves non-null. The const-data variant (assert against `_defaultLedgerConfigs` + inheritance, no DB) mirrors `deriveLedgerHint`'s pure evaluation and runs fast.

**`domain_import_rules_test.dart` (MODIFIED — Pitfall 6):** Add `'voice'` to the `features` const (lines 21-28, currently `[accounting, analytics, family_sync, home, profile, settings]`). The test then auto-enforces the yaml shape for the new `voice/domain` dir.

**Rebuild-not-delete (D-22 / Pitfall 3):** `create_transaction_currency_test.dart`, `entry_path_stamping_test.dart`, `manual_save_entry_source_test.dart`, `voice_save_entry_source_test.dart` import `dual_ledger` but assert currency-triple / hash-chain / entry-source. Rebuild swapping `ClassificationService`→`CategoryService`, RE-ASSERT those invariants. Pure deletes (test retired code): `rule_engine_test.dart`, `classification_service_test.dart`, `classification_result_test.dart`, `dual_ledger/providers_characterization_test.dart`.

---

## Shared Patterns

### Freezed value-object convention
**Source:** `lib/features/accounting/domain/models/merchant_candidate.dart`
**Apply to:** `recognition_outcome.dart`, all moved models.
- `import 'package:freezed_annotation/freezed_annotation.dart';` + `part 'x.freezed.dart';` + `@freezed abstract class X with _$X`.
- Collections via `@Default(<T>[]) List<T> field` (`voice_parse_result.dart:55`).
- Pure domain: imports ONLY freezed_annotation + intra-domain leaves.
- Run `build_runner build --delete-conflicting-outputs` after add/move (regenerates `.freezed.dart`). These are beside-source generated files — NOT l10n, so no `git add -f` needed.

### Authoritative ledger resolution (single source of truth)
**Source:** `lib/application/accounting/category_service.dart:26-41` (`resolveLedgerType`)
**Apply to:** `create_transaction_use_case` (re-route), D-19/D-20 gates.
- Direct config → L2-override; else L2 inherits parent L1 config; null if no config.
- Derived ledger NEVER reads `merchant.ledgerHint` (D-21).

### Seed-gate / arch-invariant test
**Source:** `test/architecture/category_other_l2_invariant_test.dart`
**Apply to:** D-19 reachable-L2 gate.
- Iterate `DefaultCategories.all`, sanity-guard the 19-L1 count, assert reachability with a `reason:` that names the drift it traps.

### V7 logging discipline
**Apply to:** `recognition_reconciler.dart` — never `print`/log verdicts (raw transcript/amount/merchant). Covered by `production_logging_privacy_test.dart`.

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| (none — full coverage) | — | — | `RecognitionOutcome` is net-new but copies the `merchant_candidate.dart` freezed shape; `RecognitionReconciler` formalizes existing inline merge. All other files have exact in-repo analogs. |

---

## Metadata

**Analog search scope:** `lib/features/accounting/domain/models/`, `lib/application/accounting/`, `lib/application/dual_ledger/`, `lib/application/voice/`, `lib/shared/constants/`, `test/architecture/`.
**Files scanned:** ~12 (verdict models, use case, category service, seed config, provider wiring, import_guards, 2 arch-test patterns).
**Pattern extraction date:** 2026-06-24

---

## PATTERN MAPPING COMPLETE

**Phase:** 51 - cross-validation-daily-joy-ledger-rework
**Files classified:** 14
**Analogs found:** 13 / 14

### Coverage
- Files with exact analog: 9
- Files with role-match analog: 4
- Files with no analog: 1 (`RecognitionOutcome` — net-new contract, but copies existing freezed verdict shape)

### Key Patterns Identified
- All domain models are pure `@freezed` value objects importing only `freezed_annotation` + intra-domain leaves; `RecognitionOutcome`/`ConfidenceBand` follow `merchant_candidate.dart` verbatim.
- The reconciler formalizes the existing inline keyword-priority merge (`parse_voice_input_use_case.dart:108-147`) into a pure sync function — compares L2 ids directly, NO `normalizeToL2`, NO ledger (D-09 purity, Pitfall 5).
- Ledger derivation has ONE authoritative path: `CategoryService.resolveLedgerType(...) ?? daily`; retirement deletes the second divergent map (`RuleEngine` with dead ids) — that deletion IS the value of LEDGER-02.
- Seed-gate D-19 mirrors `category_other_l2_invariant_test.dart` exactly; new `voice` feature must be added to `domain_import_rules_test.dart` features list (Pitfall 6).
- D-22: rebuild (swap to `CategoryService`) the 4 tests carrying non-classification invariants — do not delete them with the retired-code tests.

### File Created
`/Users/xinz/Development/home-pocket-app/.planning/phases/51-cross-validation-daily-joy-ledger-rework/51-PATTERNS.md`

### Ready for Planning
Pattern mapping complete. Planner can reference analog file:line excerpts directly in PLAN.md actions.
