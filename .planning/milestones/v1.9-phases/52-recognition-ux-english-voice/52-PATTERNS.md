# Phase 52: Recognition UX + English Voice - Pattern Map

**Mapped:** 2026-06-24
**Files analyzed:** 9 (6 modified, 3 new)
**Analogs found:** 9 / 9 (RESEARCH.md pre-traced every touchpoint with file:line provenance — this map cross-references rather than re-derives)

> This is a **render + data-completion** phase over the Phase-51 `RecognitionOutcome` contract. ~70% of plumbing exists; every analog below is an *in-repo idiom to copy exactly*, not a greenfield template. Match Freezed / Riverpod 3 / Drift conventions per `./CLAUDE.md`. Domain types live in `lib/features/voice/domain/` and MUST NOT import application/data/infrastructure.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/features/voice/domain/models/voice_parse_result.dart` (MOD) | model (Freezed DTO) | transform | `recognition_outcome.dart` (same dir, same `@Default`/nullable idiom) | exact |
| `lib/application/voice/parse_voice_input_use_case.dart` (MOD ~174-187) | use case | transform / request-response | self (existing VPR ctor site) | exact (in-place) |
| `lib/features/accounting/presentation/widgets/transaction_details_form.dart` (MOD) — band + chips + deferred correction | component (widget) | event-driven | `list/.../widgets/list_sort_filter_bar.dart` (ActionChip+Semantics+palette); self lines 555-588 (correction) | exact |
| `lib/shared/constants/synonyms/synonyms_*.dart` (MOD) — en category seeds | config / const data | batch (seed) | `synonyms_daily_living.dart` (`seed(kw, catId)` rows) | exact |
| `lib/shared/constants/default_synonyms.dart` (MOD docstring) | config | batch | self (lines 44-47 defer note → reverse) | exact |
| `lib/application/voice/voice_text_parser.dart` (MOD ~77) — en number-word fallback | use case (parser) | transform | self `_runStateMachine` (isolation boundary, line 80-88) | exact (in-place) |
| `test/widget/.../anti_toxicity_phase52_test.dart` (NEW) | test (widget sweep) | event-driven | `anti_toxicity_phase47_test.dart` | exact |
| `test/.../voice_text_parser_*_test.dart` (NEW en-number + isolation) | test (unit) | transform | existing voice_text_parser tests | role-match |
| `test/architecture/arb_key_parity_test.dart` (MOD/extend) | test (architecture) | batch | self | exact |

## Pattern Assignments

### `voice_parse_result.dart` (model, transform) — D-11 thread

**Analog:** sibling `recognition_outcome.dart` (the source of the 3 fields). Mirror its nullable + `@Default` shape exactly.

Add 3 fields to the `VoiceParseResult` factory (after `merchantCandidates`, line 54). Use the SAME types the outcome carries so the use-case mapping is a 1:1 copy:

```dart
// outcome.dart shapes to mirror:
ConfidenceBand band;                                 // required there → nullable here
@Default(<CategoryMatchResult>[]) List<CategoryMatchResult> alternates;
@Default(false) bool keywordMerchantConflict;
```

Target VPR additions (nullable/defaulted — `OcrParseDraft`/manual path construct VPR with NO outcome; defaults keep D-10 "no band on manual entry" correct-by-construction):
```dart
ConfidenceBand? band,                                            // null = manual entry (D-10)
@Default(<CategoryMatchResult>[]) List<CategoryMatchResult> alternates,
@Default(false) bool keywordMerchantConflict,
```
`ConfidenceBand` is already importable via `recognition_outcome.dart` (same domain dir). **Requires `build_runner` to regenerate `voice_parse_result.freezed.dart`.**

---

### `parse_voice_input_use_case.dart` (use case, transform) — D-11 mapping site

**Analog:** self. `outcome` is already in scope (assigned line 120). The VPR ctor at **lines 174-187** currently DROPS the 3 fields. Add them inline:

```dart
return Result.success(
  VoiceParseResult(
    rawText: recognizedText,
    // ...existing fields through merchantCandidates...
    band: outcome.band,                                   // ADD (D-11)
    alternates: outcome.alternates,                       // ADD
    keywordMerchantConflict: outcome.keywordMerchantConflict, // ADD
  ),
);
```

**Casing fix (VEN-01 / Pitfall 1) — same file, `_extractKeyword` ~line 293:** the residual is returned via `.trim()` with NO `.toLowerCase()`, but `findByKeyword` is exact/case-sensitive. For `localeId?.startsWith('en') == true`, lowercase the residual so lowercase en seeds match capitalized iOS STT keywords. Keep zh/ja byte-identical (gate on en locale only). Write-key==read-key contract (260526-pg6) holds because both sides become lowercase.

---

### `transaction_details_form.dart` (component, event-driven)

**Analog A — band + alternate chips render:** `lib/features/list/presentation/widgets/list_sort_filter_bar.dart` lines 155-178. This is the canonical in-repo **ActionChip + Semantics + `context.palette` + `AppTextStyles`** idiom — copy it verbatim for the chip atom (D-04) and the a11y-only band Semantics label (D-03):

```dart
final palette = context.palette;          // ADR-019 tokens — invent no new color
Semantics(
  label: 'Sort by',                       // ← band: a11y-ONLY label (D-03, no visible text)
  child: ActionChip(
    avatar: Icon(Icons.sort, size: 14, color: palette.textSecondary),
    label: Text(_label, style: AppTextStyles.caption.copyWith(color: palette.textPrimary)),
    onPressed: () => ...,
    side: BorderSide(color: palette.accentPrimary, width: 1),  // band intensity = side color/depth
    backgroundColor: palette.card,
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
  ),
)
```
Band intensity (strong/medium/weak) maps to chip `side` color/depth per UI-SPEC §Color (daily/joy family) — NEVER a number/%/gauge (ADR-012). For amounts in the form use `AppTextStyles.amount*` per CLAUDE.md. Exit chip → reuse `CategorySelectionScreen` (already invoked by `_editCategory`).

**Analog B — correction reflux (RECUX-03 / D-05 / D-06):** self, lines 560-588. EXISTING flow writes immediately, full-selector only:
```dart
if (voiceKeyword != null && voiceKeyword.isNotEmpty && result.id != _initialCategoryId) {
  final correctionUseCase = ref.read(recordCategoryCorrectionUseCaseProvider);
  await correctionUseCase.execute(keyword: voiceKeyword, correctedCategoryId: result.id);
}
```
**Rework:** move this comparison to the **save** path; chip-tap (D-06) updates `_category` + re-derives ledger but does NOT write; stash pending `(resolvedKeyword, correctedCategoryId)` and fire ONE write at confirmed save (D-05 — discard on reset/连续记账/back). `_initialCategoryId` (the "recognized original" memory, set ~line 193/222) already exists. Write key = `resolvedKeyword` verbatim; null/empty → no write, NEVER the merchant table (D-07).

---

### `synonyms/synonyms_*.dart` (config, batch) — VEN-01 en seeds

**Analog:** `synonyms_daily_living.dart` lines 17-40. Replicate the exact `seed(keyword, categoryId)` row shape — author en keywords **lowercase** (pairs with the casing fix above). Every L2 with zh/ja keywords gets ≥1 en keyword (D-12 full alignment):
```dart
// existing ja/zh shape to mirror, en added inline per family:
seed('コーヒー', 'cat_food_cafe'),   // ja (existing)
seed('咖啡', 'cat_food_cafe'),       // zh (existing)
seed('coffee', 'cat_food_cafe'),    // en (NEW — lowercase)
```
`seed(...)` factory: `synonyms/synonyms_support.dart` (writes `hitCount:0` + `kVoiceSynonymSeedEpoch`). Coverage is machine-gated by `default_synonyms_speakable_coverage_test.dart` + `default_synonyms_categoryid_test.dart` — en additions must keep those green. Reverse the `default_synonyms.dart` defer docstring (lines 44-47).

---

### `voice_text_parser.dart` (use case, transform) — VEN-02 en number-word fallback

**Analog / isolation boundary:** self, `_runStateMachine` lines 80-88:
```dart
int? _runStateMachine(String text, String? localeId) {
  if (localeId != null && localeId.startsWith('ja')) return _jaMachine.parse(text);
  if (localeId != null && localeId.startsWith('zh')) return _zhMachine.parse(text);
  return _jaMachine.parse(text) ?? _zhMachine.parse(text);   // ← null-locale fallthrough = the leak risk
}
```
Integration point: `extractAmount` line 77 (after `_extractArabicAmount` returns null). New bounded ~30-line pure fn fires ONLY when: Arabic missed AND `localeId?.startsWith('en') == true` AND money context (`VoiceCurrencySuffixes` hit / `$`/dollar word). Token set: zero…nineteen / tens / hundred / thousand / a|an→1; 「X fifty」→X.50 idiom money-context-only. **MUST route around `_runStateMachine` entirely** (D-14 isolation, guards v1.8 WR-04). Clamp to the same `0 < amount < 10_000_000` bound `_extractArabicAmount` uses (V5/security).

---

### `anti_toxicity_phase52_test.dart` (test, NEW)

**Analog:** `anti_toxicity_phase47_test.dart`. Copy its structure: pump each new-UI surface (band-strong / band-weak+chips / correction-open / manual-no-affordance / voice-panel) × {en, ja, zh}; assert no forbidden substring in rendered output. **COPY the forbidden lists VERBATIM** (lines 54-70 `forbiddenEn` etc., themselves copied from `anti_toxicity_phase16_test.dart` lines 33-78) and EXTEND with the COMPLETE v1.8-WR-02 list: `score/streak/accuracy/正确率/連続/ストリーク/達成`. Never shrink the list — fix the copy.

## Shared Patterns

### ADR-019 palette tokens (band/chip styling)
**Source:** `list_sort_filter_bar.dart` (`final palette = context.palette;` then `palette.accentPrimary/card/textPrimary/textSecondary`).
**Apply to:** all new band/chip rendering. No new color tokens; no numbers/%/gauge (ADR-012, D-03).

### a11y-only Semantics label (band)
**Source:** `list_sort_filter_bar.dart` lines 157, 181 (`Semantics(label: ..., child: ...)`).
**Apply to:** confidence band — visual intensity only, screen-reader label via `Semantics`, NO visible text, NO new ARB band key (D-03).

### Seed-row factory (en keyword data)
**Source:** `synonyms/synonyms_support.dart` `seed(keyword, categoryId)` + `kVoiceSynonymSeedEpoch`.
**Apply to:** every en category-keyword addition. Additive, idempotent via existing seed epoch — NOT a schema migration.

### Correction write path (KEYWORD table only)
**Source:** `record_category_correction_use_case.dart` (full body, 30 lines) — `recordCorrection(keyword, categoryId)`, no-ops on empty keyword.
**Apply to:** RECUX-03. This use case is the ONLY reflux target. NEVER touch `merchant_category_preferences`.

### macOS-only golden rebaseline gate
**Source:** `test/flutter_test_config.dart` (swaps `BaselineExistenceGoldenComparator` off-macOS).
**Apply to:** any golden touched by new UI. Rebaseline ONLY on macOS; never `dart format` whole `test/`. `git add -f lib/generated/` after `flutter gen-l10n` (gitignored-yet-tracked).

## No Analog Found

None. Every file has an exact or role-match in-repo analog (this phase builds on Phase-51/49/50 infrastructure).

## Metadata

**Analog search scope:** `lib/features/voice/domain/models`, `lib/application/voice`, `lib/features/accounting/presentation/widgets`, `lib/features/list/presentation/widgets`, `lib/shared/constants/synonyms`, `test/widget/.../analytics`, `test/architecture`.
**Files scanned:** ~14 (RESEARCH.md pre-resolved provenance; reads were targeted).
**Pattern extraction date:** 2026-06-24
