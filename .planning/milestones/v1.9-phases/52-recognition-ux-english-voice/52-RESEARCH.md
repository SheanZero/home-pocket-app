# Phase 52: Recognition UX + English Voice - Research

**Researched:** 2026-06-24
**Domain:** Flutter voice-entry UX (qualitative confidence rendering + inline correction reflux) + English voice parity (data completion + locale threading)
**Confidence:** HIGH (this is a render + data-completion phase over an already-built recognition contract; nearly every "unknown" resolved by reading current source)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01 mock-first.** HTML design稿 (Phase 43 / 260622-nhs / 260623-0cj precedent); band visual / chip form / layout / correction-sheet shape decided in the mock, user-approved BEFORE production Dart. CONTEXT locks only constraints: ADR-012 purely qualitative, NEVER number %/fraction/gauge/meter; reuse ADR-019 tokens, invent no new palette; pass anti-toxicity sweep.
- **D-02 mock scope = re-design `VoiceRecordPanel` too** (not "affordance pasted on a static form") — covers 说话中 → 类目落定 → 纠错 full flow.
- **D-03 band purely visual, NO visible text.** 3-tier `ConfidenceBand{strong,medium,weak}` expressed only by color/icon intensity; only an a11y-hidden `Semantics` label. Zero gamification-word risk, no new ARB band-copy key.
- **D-04 chips ≤ ~3 + one exit chip.** Top ~3 alternates by reconciler rank (conflict-demoted merchant default category included, L2-deduped) + a trailing 其他/更多 exit chip → full category selector.
- **D-05 teaching deferred to save.** Tapping a chip immediately swaps category + re-derives ledger (instant UI feedback) but the `category_keyword_preferences` write is DEFERRED to actual transaction save (avoids polluting the learning table from reset / 连续记账 / abandoned drafts).
- **D-06 chip AND full selector both count as correction.** Any change away from "recognized original category" records a correction at save. Form state must remember the recognized original category.
- **D-07 write key = `resolvedKeyword` verbatim; no keyword → don't teach.** Write key == read key (260526-pg6 orphan-key contract, locked). `resolvedKeyword == null` (bare merchant / both-weak / no keyword) → write NO learning row, NEVER the merchant table.
- **D-08 band+chips render at first end-of-speech `isFinal` resolution** (Phase 51 D-02 resolve-on-final); visible alongside the record panel if still on-screen.
- **D-09 band clears the instant the user selects any category** (chip or selector) → user-authoritative, no "guess" marker; chips may collapse.
- **D-10 manual entry shows no affordance** (no outcome → no render, correct-by-construction).
- **D-12 full English alignment.** Every L2 with zh/ja keywords gets English category keywords; every Japanese merchant with an English name gets `nameEn`/English alias.
- **D-13 reuse English currency words, don't fork** (`VoiceCurrencySuffixes`, 260614-goh, longest-first). Optionally add buck/bucks/quid (non-essential).
- **D-14 「X fifty」→X.50 idiom + bounded fallback**, money-context-only to avoid 550 ambiguity; ~30-line bounded fallback (one…twenty / thirty…ninety / hundred / thousand / a|an→1), fires ONLY when the numeric regex misses, NEVER enters CJK paths. Arabic STT digits win priority. Isolation assertion: any English utterance NEVER enters ja/zh numeral path (guard v1.8 golden WR-04 regression class).
- **D-15 independent voice-recognition language switch (zh/ja/en), decoupled from app UI locale.** Threads a session voice locale end-to-end to STT + both recognizers + number/currency parsing. Goldens must override the correct locale provider.
- **D-16 merchant name editable/clearable but teaches no table.** No dedicated merchant-correction affordance this phase.
- **D-17 trilingual close-out inline (NOT deferred to milestone close):** ARB parity (equal key counts, no orphans, `flutter gen-l10n` clean, `git add -f lib/generated/`) + anti-toxicity sweep (new chips/correction/band × ja/zh/en × all states, COMPLETE banned-token list incl. score/streak/accuracy/正确率/連続/ストリーク/達成 — fixes v1.8 WR-02 incompleteness) + macOS golden rebaseline.

### Claude's Discretion (research/plan to resolve)
- D-11 outcome→VoiceParseResult→form thread shape (extend VPR fields vs carry whole outcome) → **RESOLVED below: extend VPR with 3 fields.**
- band visual / chip form / layout / correction-sheet shape → HTML mock.
- voice-language selector placement (panel / form / settings) → **RESOLVED below: settings already exists; quick in-panel selector is the only net-new option.**
- English number-word bounded token set + money-context logic → **proposed below.**
- merchant `nameEn` fill strategy (recognizer-wiring vs data-write) → **RESOLVED below: data already 98% filled + already wired; near-zero work on merchant side.**
- correction write path entry (`recordCorrection` in use case / repo) → **RESOLVED below: `RecordCategoryCorrectionUseCase` already exists & wired; gap is deferral + chip path.**

### Deferred Ideas (OUT OF SCOPE)
- Merchant correction reflux learning (`merchant_category_preferences`) — explicitly OUT.
- Merchant-specific ledger affordance — future.
- Full spoken English number state machine — NOT doing (only ~30-line bounded fallback + Arabic STT priority).
- Merchant library to 600-800 / regional catalogs / FTS5 — MERCH-V2.
- Re-arbitration / band recomputation — Phase 51 locked, untouched.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| RECUX-01 | Form shows selected category + 3-tier qualitative band (never numeric), ADR-012-safe | `RecognitionOutcome.band` already computed (Phase 51); D-11 thread + pure visual render. UI-SPEC §Color band→intensity mapping. New widget (no existing reusable atom). |
| RECUX-02 | Low-confidence → tappable alternate chips (alt categories + merchant default) | `RecognitionOutcome.alternates` already ranked & L2-deduped; thread via D-11; render ≤3 + exit chip. No existing category-chip atom → net-new (mock-first). |
| RECUX-03 | Inline correction teaches KEYWORD table (`category_keyword_preferences`), never merchant table; write-key==read-key | `RecordCategoryCorrectionUseCase` + `recordCorrection` repo path ALREADY EXIST & wired in form (line 579). Gaps: defer to save (D-05), include chip path (D-06). Write key = `resolvedKeyword` (D-07). |
| RECUX-04 | No gamification; anti-toxicity sweep covers new UI × ja/zh/en | `anti_toxicity_phase47_test.dart` is the canonical pattern. COMPLETE banned-token list (see §Validation). Band has NO text (D-03) → minimal new copy surface. |
| RECUX-05 | Merchant names = DATA (Drift columns); category labels = ARB; trilingual parity, gen-l10n clean | `arb_key_parity_test.dart` exists. Merchant `nameEn` is a Drift column (already). New ARB keys minimized (exit-chip label + a11y band labels + selector option labels). |
| VEN-01 | English keyword/alias/currency-word recognition, practical parity with zh/ja | Merchant side ALREADY wired (nameEn→`locale` match-key, English aliases→`alias` match-key, normalizer lowercases Latin; 98% nameEn fill). Category side: en synonym seeds ABSENT (explicitly deferred) → must add. Currency words DONE (260614-goh). |
| VEN-02 | English STT amount parsing; ~30-line bounded number-word fallback (not CJK path); localeId end-to-end | Arabic path already wins (`_extractArabicAmount`). Bounded fallback is net-new, gated to fire ONLY when Arabic misses + money context. `localeId`/voice-locale plumbing already exists end-to-end (`pttVoiceLocaleId`). |
</phase_requirements>

## Summary

Phase 52 is a **render-and-complete** phase, not a build-from-scratch one. Phase 51 already produces the pure-domain `RecognitionOutcome` (`selectedCategoryId` / `ConfidenceBand{strong,medium,weak}` / ranked `alternates` / `resolvedKeyword` / `keywordMerchantConflict`), and most of the English/locale plumbing the roadmap framed as "research unknowns" turns out to already exist in the codebase. The dominant risk is therefore **reconciling existing behavior with the new contract**, not greenfield construction.

Five concrete findings reshape the effort estimate: (1) the **D-11 unread-outcome thread** is the genuine prerequisite — `ParseVoiceInputUseCase` computes `outcome.band`/`alternates`/`keywordMerchantConflict` but drops all three when constructing `VoiceParseResult`; (2) **merchant English recognition is already fully wired** — `SeedMerchantsUseCase` emits a `locale`-kind match-key from `nameEn` and `alias`-kind keys from English aliases, the normalizer just lowercases Latin, and `nameEn` is **98% filled (383/391)** — so VEN-01's merchant side is near-zero work; (3) the **voice locale is already decoupled** from app UI locale via a separate `AppSettings.voiceLanguage` setting (`voiceLocaleIdProvider`, already supporting `en`→`en-US`, surfaced by an existing Settings dialog), threaded end-to-end as `pttVoiceLocaleId` — so D-15 is mostly verification + an optional in-panel quick-selector; (4) **`RecordCategoryCorrectionUseCase` already exists and is already wired** in `TransactionDetailsForm` (fires on full-selector category change), so RECUX-03's gaps are narrow: defer the write to save (D-05) and also count the chip-tap path (D-06); (5) the **English category-keyword seeds are explicitly absent** (`default_synonyms.dart` covers zh+ja only, English deferred to "v1.4+") — so VEN-01's category side is the real data-write work, and it carries a **casing pitfall**: `findByKeyword` is exact/case-sensitive and `_extractKeyword` does NOT lowercase its residual, so English STT capitalization will miss lowercase seeds unless both sides agree on case.

**Primary recommendation:** Sequence as the roadmap directs — RECUX wave first (D-11 thread → band/chips render → defer+broaden correction), VEN wave second (add en category seeds with a casing-normalization fix → bounded number-word fallback → isolation assertions), then the inline trilingual close-out (ARB parity + anti-toxicity sweep with the COMPLETE banned list + macOS golden rebaseline). Extend VPR with three nullable fields rather than carrying the whole outcome (smallest blast radius across existing consumers).

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Band/chips visual render | Presentation (`features/accounting/.../widgets`) | — | Phase 51 D-10: band computed in domain, presentation only renders [VERIFIED: recognition_outcome.dart dartdoc] |
| Outcome→VPR thread | Application (`ParseVoiceInputUseCase`) + Domain (`VoiceParseResult`) | — | DTO extension is a domain model change; mapping is in the use case [VERIFIED: parse_voice_input_use_case.dart:174-187] |
| Correction reflux | Application (`RecordCategoryCorrectionUseCase`) → Data (`category_keyword_preferences`) | Presentation (trigger at save) | Use case already exists; presentation owns the deferral/trigger [VERIFIED: record_category_correction_use_case.dart] |
| English category keywords | Data/const (`default_synonyms.dart` seeds) | Application (`_extractKeyword` casing) | Additive seed data; recognizer wiring already exists [VERIFIED: default_synonyms.dart:44-47] |
| English merchant recognition | Data/const (`nameEn`/aliases — already filled) | Application (`MerchantRecognizer` — already script-agnostic) | Seed pipeline already emits locale/alias keys [VERIFIED: seed_merchants_use_case.dart:52-57] |
| English number-word fallback | Application (`VoiceTextParser`) | — | Net-new bounded parser, gated after Arabic miss [VERIFIED: voice_text_parser.dart:51-78] |
| Voice locale routing | Presentation mirror (`pttVoiceLocaleId`) ← Settings (`voiceLocaleId`) | Application (recognizers consume localeId) | Already decoupled; thread verified end-to-end [VERIFIED: state_settings.dart:21-24] |
| Trilingual close-out gates | Test (`arb_key_parity`, anti-toxicity sweep, golden) | — | Inline merge gate (D-17) |

## Standard Stack

No external packages are added this phase. This is a Flutter app working entirely within its established in-house stack.

### Core (existing, reused)
| Component | Location | Purpose | Why Standard |
|-----------|----------|---------|--------------|
| `RecognitionOutcome` + `ConfidenceBand` | `lib/features/voice/domain/models/recognition_outcome.dart` | Band already computed in domain (Phase 51) | 52 renders, never recomputes [VERIFIED: file read] |
| `VoiceParseResult` (freezed) | `lib/features/voice/domain/models/voice_parse_result.dart` | DTO to extend with 3 fields (D-11) | Single thread surface to the form [VERIFIED] |
| `RecordCategoryCorrectionUseCase` | `lib/application/voice/record_category_correction_use_case.dart` | KEYWORD-table write path (RECUX-03) | Already exists, already wired [VERIFIED] |
| `CategoryRecognizer` / `MerchantRecognizer` | `lib/application/voice/recognition/` | en-locale matching (VEN-01) | Merchant already script-agnostic; category needs en seeds [VERIFIED] |
| `VoiceTextParser` | `lib/application/voice/voice_text_parser.dart` | Arabic amount priority + state-machine routing | Bounded en fallback hooks in after Arabic miss [VERIFIED] |
| `VoiceCurrencySuffixes` | `lib/shared/constants/voice_currency_suffixes.dart` | English currency words (DONE 260614-goh) | Reuse, don't fork (D-13) [VERIFIED via grep + parse_voice_input refs] |
| `voiceLocaleId` provider | `lib/features/settings/presentation/providers/state_settings.dart` | Session voice locale (en→en-US), decoupled from UI locale | Already supports en + decoupled (D-15 infra exists) [VERIFIED] |
| `AppPalette` (ADR-019) + `AppTextStyles` | `lib/core/theme/` | Band/chip styling tokens | UI-SPEC: no new tokens |
| `CategorySelectionScreen` | `lib/features/accounting/presentation/screens/category_selection_screen.dart` | Exit chip → full category selector (D-04) | Already used by `_editCategory` [VERIFIED] |

### Supporting (existing test infra)
| Component | Location | When to Use |
|-----------|----------|-------------|
| `anti_toxicity_phase47_test.dart` | `test/widget/.../analytics/.../` | Pattern to copy for the new-UI sweep (RECUX-04) |
| `arb_key_parity_test.dart` | `test/architecture/` | Trilingual parity gate (RECUX-05) |
| `BaselineExistenceGoldenComparator` | `test/helpers/ci_golden_comparator.dart` (wired in `test/flutter_test_config.dart`) | macOS-only golden rebaseline platform gate |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Extend `VoiceParseResult` with 3 fields | Carry whole `RecognitionOutcome` in VPR | Carrying the outcome leaks the reconciler's full domain shape into every VPR consumer (currency tests, ocr draft, save path). Extending with 3 nullable fields touches only the use case mapper + the form reader — smaller blast radius. **Recommend: extend.** |
| In-panel quick voice-locale selector | Keep settings-only selector (exists today) | Settings selector already works + is decoupled. An in-panel selector is "experience over minimal wiring" (D-15 stated preference) but is the ONLY net-new wiring; it reads/writes the same `voiceLanguage` setting. **Recommend: settings is sufficient for the contract; in-panel is optional polish decided in the mock.** |
| Bounded ~30-line en number-word fallback | Full spoken-number state machine | Explicitly OUT of scope (deferred). Bounded fallback only. |

**Installation:** None — no `pubspec.yaml` change. (`flutter pub get` only if codegen deps move, which they do not.)

## Package Legitimacy Audit

Not applicable — this phase installs no external packages. All work is first-party Dart under `lib/` plus const seed data. No npm/PyPI/crates dependency is introduced.

## Architecture Patterns

### System Data Flow (the recognition → render → reflux path)

```
[Voice utterance] ─ STT (localeId = pttVoiceLocaleId, decoupled from UI locale)
      │
      ▼
ParseVoiceInputUseCase.execute(text, localeId)
      │   ├─ VoiceTextParser.extractAmount ── Arabic regex (priority)
      │   │        └─ MISS + en + money-context ──▶ [NEW] bounded en number-word fallback (X.50 idiom)
      │   │                                          (NEVER _runStateMachine → CJK isolation)
      │   ├─ _detectCurrency (VoiceCurrencySuffixes — en words already covered)
      │   ├─ _extractKeyword ──▶ resolvedKeyword  [NEW: lowercase residual for en parity]
      │   ├─ CategoryRecognizer.resolve(keyword) ── findByKeyword (exact) over seeds
      │   │        └─ [NEW: en seeds added to default_synonyms; case must agree]
      │   ├─ MerchantRecognizer.recognize(query) ── over nameEn/alias match-keys (already wired)
      │   └─ RecognitionReconciler.reconcile(...) ──▶ RecognitionOutcome{band, alternates, conflict}
      │
      ▼
VoiceParseResult  ◀── [D-11 GAP] band/alternates/keywordMerchantConflict currently DROPPED here
      │              [FIX: extend VPR with 3 nullable fields; map them in the use case]
      ▼
voice_ptt_session_mixin._applyFill ──▶ pttFormState (category resolve-on-final, D-08)
      │
      ▼
TransactionDetailsForm
      ├─ band render (pure visual, ADR-019 intensity, a11y-only Semantics) ── clears on user pick (D-09)
      ├─ alternate chips (≤3 + exit chip) ── tap = instant swap + re-derive ledger (D-05)
      │        └─ remembers _initialCategoryId (recognized original) for D-06 change detection
      └─ on SAVE ──▶ [D-05 DEFER] RecordCategoryCorrectionUseCase.execute(
                         keyword = resolvedKeyword,  // verbatim, D-07; null → skip
                         correctedCategoryId)
                     writes category_keyword_preferences ONLY (NEVER merchant table)
```

File-to-responsibility mapping is in the Architectural Responsibility Map above.

### Pattern 1: D-11 — Extend the DTO, map in the use case
**What:** Add three nullable fields to `VoiceParseResult` — `ConfidenceBand? band`, `List<CategoryMatchResult> alternates` (defaulted `[]`), `bool keywordMerchantConflict` (defaulted `false`) — and populate them from `outcome` in the use case's `Result.success(VoiceParseResult(...))` construction.
**When to use:** This is the prerequisite for all band/chips rendering.
**Why nullable/defaulted:** `OcrParseDraft` and the manual path construct/consume `VoiceParseResult` without an outcome; defaults keep them correct-by-construction (manual entry → no band → no affordance, D-10).
```dart
// Source: VERIFIED against parse_voice_input_use_case.dart:120-187 + recognition_outcome.dart
// In execute(), `outcome` is already in scope (line 120). Add to the VPR ctor:
return Result.success(VoiceParseResult(
  // ...existing fields...
  band: outcome.band,
  alternates: outcome.alternates,
  keywordMerchantConflict: outcome.keywordMerchantConflict,
));
```
**Consumers to update (grepped this session):** `voice_ptt_session_mixin.dart` (reads `.categoryMatch` at line 348 — add band/alternates read), `voice_input_screen_helpers.dart` (reads `.resolvedKeyword` — unaffected), `ocr_parse_draft.dart` (constructs VPR — defaults cover it), plus the existing tests of VPR. Adding freezed fields requires `build_runner` (regenerate `.freezed.dart`).

### Pattern 2: Correction reflux — defer + broaden (RECUX-03 / D-05 / D-06)
**What:** Today `_editCategory` (full selector) fires `recordCorrection` immediately when `result.id != _initialCategoryId` (the recognized-original memory already exists as `_initialCategoryId`, set at line 193/222). The new contract requires: (a) defer the write to actual transaction save; (b) also count chip-tap changes.
**When to use:** RECUX-03 core.
**How to avoid (the D-05 draft-pollution trap):** Do NOT write on tap. Stash the pending `(resolvedKeyword, correctedCategoryId)` in form state; on the real save path, if final category ≠ `_initialCategoryId` AND `resolvedKeyword != null/empty`, call `RecordCategoryCorrectionUseCase.execute`. Reset/连续记账/abandon paths discard the stash without writing.
```dart
// Source: VERIFIED against transaction_details_form.dart:560-588
// EXISTING (immediate, full-selector only):
if (voiceKeyword != null && voiceKeyword.isNotEmpty && result.id != _initialCategoryId) {
  await correctionUseCase.execute(keyword: voiceKeyword, correctedCategoryId: result.id);
}
// TARGET: move this comparison to SAVE time; have chip-tap update _category +
// re-derive ledger but NOT write; the single save-time write covers both paths.
```
**Write key (D-07):** `voiceKeyword` here is `result.resolvedKeyword` verbatim (260526-pg6 write==read). `null/empty` → write nothing, never the merchant table.

### Pattern 3: English number-word bounded fallback (VEN-02 / D-14)
**What:** A ~30-line pure function that fires ONLY when `_extractArabicAmount` returns null, the locale is `en*`, and a money context is present. Maps a bounded token set; supports the「X fifty」→X.50 idiom.
**When to use:** VEN-02. Must hook into `extractAmount` AFTER the Arabic path and the CJK-hint path, and must NOT call `_runStateMachine`.
**Token set (proposed):**
- units 0–19: zero/one…nineteen
- tens: twenty/thirty/forty/fifty/sixty/seventy/eighty/ninety
- scales: hundred (×100), thousand (×1000)
- `a`/`an` → 1 (e.g. "a hundred")
**「X fifty」→ X.50 money idiom (D-14):** only when `<int> fifty` (or other tens that read as cents — keep it to the explicit「X fifty」per CONTEXT, i.e. tens-word immediately after an integer in a money context) AND the plain numeric reading didn't already match. Money context = currency token present (`VoiceCurrencySuffixes` hit) OR a `$`/dollar word. "five fifty" + money ctx → 5.50; bare "five fifty" with no money ctx → do NOT fire (550 ambiguity). Arabic STT digits (which dominate iOS en STT) always win first, so this fallback fires rarely — it is a safety net, not the main path.
```dart
// Source: design (ASSUMED token set — confirm exact list at plan); isolation VERIFIED
// against voice_text_parser.dart:80-88 (_runStateMachine only branches ja/zh).
// Integration point: voice_text_parser.dart:77 (after _extractArabicAmount returns null,
// before returning null). Gate: localeId?.startsWith('en') == true.
```
**Isolation assertion (D-14, guard v1.8 WR-04):** add a test that an English utterance with `localeId='en-US'` NEVER produces a value via `_zhMachine`/`_jaMachine` — `_runStateMachine` already only branches `ja`/`zh` and falls to `_jaMachine ?? _zhMachine` ONLY when localeId is null, so the en branch must route around it entirely.

### Pattern 4: English category-keyword parity (VEN-01 / D-12) with the casing fix
**What:** Add English seed rows to the `synonyms_*.dart` group files (each L2 with zh/ja keywords gets ≥1 en keyword), via the existing `seed(keyword, categoryId)` factory.
**The casing pitfall (load-bearing):** `CategoryKeywordPreferenceDao.findByKeyword` does `t.keyword.equals(keyword)` — **exact, case-sensitive** [VERIFIED: dao line 22]. `_extractKeyword` strips currency case-insensitively but returns the residual via `.trim()` with **no `.toLowerCase()`** [VERIFIED: parse_voice_input_use_case.dart:293]. iOS English STT capitalizes ("Coffee", "Lunch"). So lowercase seeds will MISS capitalized extracted keywords. **Fix options (decide at plan):** (a) lowercase the residual in `_extractKeyword` when `localeId` is `en*` (mirrors the merchant normalizer's `.toLowerCase()`); seeds authored lowercase. This keeps zh/ja paths byte-identical. Confirm it does not regress the existing `resolvedKeyword` write==read contract (the write key would then also be lowercase — consistent on both sides, so the contract holds).

### Anti-Patterns to Avoid
- **Recomputing the band in presentation.** Band is domain-owned (Phase 51 D-10). Render `outcome.band`, never derive intensity from a score.
- **Writing the correction on chip tap.** Violates D-05 (draft pollution). Defer to save.
- **Letting the en number-word fallback reach `_runStateMachine`.** Violates D-14 isolation; risks v1.8 WR-04 regression.
- **Adding ARB keys for the band.** D-03: band has no visible text. Only the exit-chip label, a11y band labels, and (if added) in-panel selector labels are new ARB keys.
- **Putting merchant names in ARB.** RECUX-05: merchant names are Drift DATA columns (`nameEn`), category labels are ARB.
- **Shrinking the banned-token list to make the sweep pass.** Fix the copy, escalate; never relax the list (anti_toxicity_phase47 §locked list rule).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Confidence band value | A new score→band mapper | `RecognitionOutcome.band` (already computed) | Phase 51 owns arbitration; 52 renders [VERIFIED] |
| Correction write to learning table | A new repo/DAO write | `RecordCategoryCorrectionUseCase` (exists, wired) | Already implements write==read + hitCount increment [VERIFIED] |
| English merchant match-keys | A new en recognizer/path | Existing seed pipeline (`nameEn`→locale key, aliases→alias key) | 98% nameEn filled, normalizer lowercases Latin [VERIFIED] |
| English currency words | A new currency word list | `VoiceCurrencySuffixes` (260614-goh, longest-first) | Already complete (D-13) [VERIFIED via refs] |
| Voice-locale decoupling | A new app-locale-derived voice locale | `voiceLocaleId` provider over `AppSettings.voiceLanguage` | Already decoupled + supports en [VERIFIED] |
| Full category selector for exit chip | A new picker | `CategorySelectionScreen` | Already used by `_editCategory` [VERIFIED] |
| Golden CI parity | A new comparator | `BaselineExistenceGoldenComparator` (wired) | macOS-baseline platform gate already solved [VERIFIED] |

**Key insight:** The roadmap framed this phase as if much had to be built; reading the source shows ~70% of the plumbing exists. The real net-new code is: the 3-field VPR thread, the band/chips widgets (mock-first), the deferral+broadening of correction recording, the en category seeds (+casing fix), and the bounded en number-word fallback. Everything else is verification and the inline close-out gates.

## Runtime State Inventory

Not a rename/refactor/migration phase. Schema is explicitly NOT touched (drift schema stays at v21; CONTEXT + ROADMAP: "drift 2.31.0 / schema 不动"). Two data-write notes that are NOT migrations:
- **English category seeds** are written to the existing `category_keyword_preferences` table via `SeedVoiceSynonymsUseCase` with `hitCount=0` sentinel. This is additive seed data, idempotent via the existing seed path — NOT a schema migration. Confirm the seed epoch/idempotency guard handles re-seed (existing `kVoiceSynonymSeedEpoch` + DAO `insertSeedBatch`).
- **No `nameEn` data write needed** — 383/391 already filled. The ~8 gaps (if any L2-with-zh/ja-keyword merchant lacks nameEn) are const-data edits, re-seeded only on a fresh install (existing `hasAny()` guard skips re-seed on populated DBs — note: existing installs won't pick up new merchant rows without a seed-version bump, but CONTEXT scopes nameEn to "every Japanese merchant with an English name" and they are already filled).

## Common Pitfalls

### Pitfall 1: English keyword casing mismatch (VEN-01)
**What goes wrong:** Lowercase en category seeds never match capitalized STT keywords.
**Why it happens:** `findByKeyword` is exact/case-sensitive; `_extractKeyword` does not lowercase its residual; iOS en STT capitalizes.
**How to avoid:** Lowercase the en residual in `_extractKeyword` (localeId `en*`), author seeds lowercase; verify the `resolvedKeyword` write==read contract still holds (both sides lowercase).
**Warning signs:** "Coffee" recognizes nothing while "coffee" does in a test.

### Pitfall 2: Correction written from abandoned drafts (RECUX-03 / D-05)
**What goes wrong:** Tapping a chip during exploration teaches the table, then the user resets/abandons — the learning table is polluted.
**Why it happens:** The existing path writes immediately on category change.
**How to avoid:** Defer the write to the actual save path; discard the pending correction on reset/连续记账/back.
**Warning signs:** Learning rows appear for entries that were never saved.

### Pitfall 3: English utterance leaks into a CJK numeral path (VEN-02 / D-14, v1.8 WR-04 class)
**What goes wrong:** An en utterance produces a wrong amount via the zh/ja state machine; goldens drift.
**Why it happens:** `_runStateMachine` falls back to `_jaMachine ?? _zhMachine` when localeId is null. If the en path doesn't carry a proper `en*` localeId, it can hit the null branch.
**How to avoid:** Ensure `pttVoiceLocaleId` is `en-US` end-to-end for en sessions (it already is via the settings selector); the bounded fallback must route around `_runStateMachine` entirely; add the isolation assertion test.
**Warning signs:** "fifty dollars" yields a CJK-parsed integer; golden diffs on the en variant.

### Pitfall 4: Golden rebaseline on the wrong platform (close-out)
**What goes wrong:** Goldens regenerated on Linux/CI never pixel-match (font AA).
**Why it happens:** Baselines are macOS-rendered; CI uses `BaselineExistenceGoldenComparator`.
**How to avoid:** Rebaseline ONLY on macOS; never `dart format` the whole `test/` (repo isn't format-clean) — MEMORY `golden-ci-platform-gate`.

### Pitfall 5: ARB generated files left uncommitted (RECUX-05 / D-17)
**What goes wrong:** `lib/generated/` is gitignored-yet-tracked; new S keys leave stale generated Dart, breaking analyze from clean.
**Why it happens:** `git add` rejects gitignored paths.
**How to avoid:** `git add -f lib/generated/` after `flutter gen-l10n` — MEMORY `gsd-executor-l10n-generated-uncommitted`. Update ALL THREE arb files together.

### Pitfall 6: Incomplete banned-token list (RECUX-04 / D-17, fixes v1.8 WR-02)
**What goes wrong:** A gamification word slips through because the sweep list is incomplete.
**Why it happens:** v1.8 WR-02 shipped an incomplete list.
**How to avoid:** Use the COMPLETE list (§Validation below) including score/streak/accuracy/正确率/連続/ストリーク/達成 PLUS the existing forbidden vocabulary from `anti_toxicity_phase47_test.dart`.

## Code Examples

### Reading the band/chips in the form (after D-11 thread)
```dart
// Source: design over VERIFIED voice_ptt_session_mixin.dart:348 (existing categoryMatch read)
final band = data.band;                 // ConfidenceBand? — null on manual entry (D-10)
final alternates = data.alternates;      // ranked, L2-deduped (cap to ~3 in the widget)
// render band intensity from ledger family (daily/joy) per UI-SPEC §Color; NO numbers, NO text.
```

### macOS-only golden rebaseline gate (already in place)
```dart
// Source: VERIFIED test/flutter_test_config.dart
if (!Platform.isMacOS && comparator is LocalFileComparator) {
  goldenFileComparator = BaselineExistenceGoldenComparator(comparator.basedir);
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| English voice input deferred to "v1.4+" | Full English parity this phase (VEN) | Phase 52 (v1.9) | `default_synonyms.dart:44-47` explicit defer note becomes obsolete — replace with en seeds |
| Correction written immediately on category change | Deferred to save + chip path included | Phase 52 (RECUX-03) | `transaction_details_form.dart:560-588` flow reworked |
| Band as future Phase-52 concept | Band computed in domain (Phase 51), rendered in 52 | Phase 51→52 | 52 is pure render |

**Deprecated/outdated:**
- The `default_synonyms.dart` "English (en) entries are deferred to v1.4+" docstring (lines 44-47) — this phase reverses it; update the docstring when adding en seeds.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The exact en number-word token set (one…twenty / tens / hundred / thousand / a\|an→1) is sufficient for VEN-02 | Pattern 3 | Low — bounded by design; Arabic STT dominates so fallback fires rarely. Finalize list at plan. |
| A2 | Lowercasing the en residual in `_extractKeyword` is the right casing fix and won't regress zh/ja or the write==read contract | Pattern 4 / Pitfall 1 | Medium — must verify resolvedKeyword stays consistent on both write and read sides; add a test. |
| A3 | Extending VPR with 3 fields (vs carrying the outcome) is lower blast radius | Pattern 1 | Low — grepped consumers confirm few readers; defaults cover constructors. |
| A4 | The「X fifty」→X.50 idiom should fire only on an explicit integer-then-tens pattern in money context | Pattern 3 | Medium — exact trigger grammar decided at plan/mock; CONTEXT only fixes the「five fifty」→5.50 example + money-context gate. |
| A5 | Settings-only voice-locale selector satisfies the D-15 contract; in-panel selector is optional polish | Stack / Alternatives | Low — CONTEXT marks placement as discretion; an in-panel selector is the only net-new wiring and reads the same setting. |
| A6 | The ~8 merchants without `nameEn` are not L2-with-zh/ja-keyword gaps that VEN-01 must fill | Runtime State Inventory | Low — 98% fill; verify the 8 at plan, edit const data if needed. |

**If a claim here is load-bearing for your plan, gate it behind a `checkpoint:human-verify` or confirm in discuss.**

## Open Questions

1. **Exact band visual + chip form**
   - What we know: pure-visual, ADR-019 tokens, daily/joy family intensity, ≤3 chips + exit chip (UI-SPEC §Color/§Interaction).
   - What's unclear: pixel form (dot vs border depth, chip pill vs outline).
   - Recommendation: decided in the HTML mock (D-01), user-approved before Dart.

2. **In-panel voice-locale selector placement**
   - What we know: settings selector exists + works + decoupled.
   - What's unclear: whether the mock adds a quick selector inside `VoiceRecordPanel`.
   - Recommendation: decide in the mock; if added, it reads/writes the same `voiceLanguage` setting (no new state).

3. **Save-path hook for deferred correction**
   - What we know: `RecordCategoryCorrectionUseCase` + `_initialCategoryId` exist; the form's save flow is the natural trigger.
   - What's unclear: the exact save call site across the 4 hosts that mount `TransactionDetailsForm`.
   - Recommendation: locate the single save path in plan; stash pending correction in form state, fire once on confirmed save.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK + build_runner | freezed VPR field addition | ✓ (project) | per pubspec | — |
| `flutter gen-l10n` | ARB parity (RECUX-05) | ✓ | l10n.yaml present | — |
| macOS host | golden rebaseline | ✓ (darwin) | — | CI uses BaselineExistenceGoldenComparator (no rebaseline on CI) |
| iOS/Android STT (en-US) | VEN runtime | device/sim | — | en STT availability is device-dependent; tests drive parser directly, not live STT |

**Missing dependencies with no fallback:** none.
**Missing dependencies with fallback:** live en-US STT is device-dependent, but VEN-02 parsing is unit-tested against the parser directly (no live STT in tests), so it does not block execution.

## Validation Architecture

(Nyquist enabled — `workflow.nyquist_validation: true` in config.)

### Test Framework
| Property | Value |
|----------|-------|
| Framework | `flutter_test` (+ `flutter test --coverage`) |
| Config file | `test/flutter_test_config.dart` (golden platform gate); `l10n.yaml`; `analysis_options.yaml` |
| Quick run command | `flutter test test/<changed-area> -x` |
| Full suite command | `flutter analyze && flutter test` |

### Phase Requirements → Test Map (per ROADMAP Pitfall→Phase→Regression-Test Map; pitfalls 5/7/8/9/10 land here)
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| RECUX-01 | Band renders qualitatively (no number/%/gauge) at resolve-on-final | widget | `flutter test test/widget/.../transaction_details_form*_test.dart` | ❌ Wave 0 (new band render test) |
| RECUX-02 | ≤3 alternate chips + exit chip; tap swaps category | widget | new chip-render/tap test | ❌ Wave 0 |
| RECUX-03 | Correction teaches KEYWORD table only, deferred to save, write==read; null keyword → no write | unit + widget | extend `record_category_correction` + form correction tests | ⚠️ partial (correction use case tested; defer/chip path new) |
| RECUX-04 (pitfall 8) | Anti-toxicity sweep over new UI × ja/zh/en × states, COMPLETE banned list | widget sweep | new `anti_toxicity_phase52_test.dart` (copy phase47 pattern) | ❌ Wave 0 |
| RECUX-05 / pitfall 9 | ARB parity: equal key counts, no orphans, gen-l10n clean, merchant names not in ARB | architecture | `flutter test test/architecture/arb_key_parity_test.dart` | ✅ extend |
| VEN-01 / pitfall 5 | English keyword + alias + romaji + currency-word recognition | unit | extend `category_recognizer` + `merchant_recognizer` tests (en cases) | ⚠️ extend |
| VEN-02 / pitfall 7 | "fifty dollars" → amount + USD; English NEVER enters CJK numeral path; localeId threaded; X.50 idiom | unit | new `voice_text_parser` en-number tests + isolation assertion | ❌ Wave 0 |
| pitfall 10 | Resolve-on-final / no flicker on partials (partial-vs-committed render) | widget | extend resolve-on-final render test | ⚠️ extend |

### Sampling Rate
- **Per task commit:** scoped `flutter test` for the changed area.
- **Per wave merge:** `flutter analyze && flutter test` (FULL suite — scoped tests miss architecture/sweep tests; MEMORY `gsd-parallel-executor` + `gsd-post-merge-gate-flutter-mismatch`: run flutter commands manually as orchestrator, the GSD post-merge gate auto-sniffs xcodebuild).
- **Phase gate:** full suite green + `flutter analyze` 0 issues + `flutter gen-l10n` clean + `git add -f lib/generated/` before `/gsd-verify-work`.

### Wave 0 Gaps
- [ ] `anti_toxicity_phase52_test.dart` — new-UI sweep (copy phase47 structure), COMPLETE banned list, ja/zh/en × {resolved-strong, resolved-weak+chips, correction-open, manual-no-affordance, voice-panel}.
- [ ] `voice_text_parser` en-number + isolation tests — covers VEN-02 incl. the「five fifty」→5.50 idiom and the "English never enters CJK path" assertion.
- [ ] band/chips widget render tests — RECUX-01/02 (after mock locks the visual).
- [ ] correction defer + chip-path tests — RECUX-03/D-05/D-06.
- [ ] extend `arb_key_parity_test.dart` for new keys (or confirm it auto-covers).
- [ ] extend recognizer tests with en cases (VEN-01, pitfall 5: romaji/EN match).
- [ ] `build_runner` after VPR field addition (regenerate `.freezed.dart`).

## Security Domain

(`security_enforcement` not disabled in config — included.)

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | No auth surface touched |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | yes | Voice transcript is untrusted input; amount/keyword extraction already bounds ranges (`amount < 10000000`) and the en number-word fallback must clamp identically |
| V6 Cryptography | no (don't touch) | Merchant names already encrypted at the field layer; band/chips render display values only — never log raw transcript/amount/merchant (no-log discipline V7, already in MerchantRecognizer) |
| V7 Errors & Logging | yes | Zero-knowledge: NEVER `print`/log raw transcript, amount, or merchant in the new band/chips/correction code (matches existing MerchantRecognizer V7 discipline) |

### Known Threat Patterns for Flutter voice/learning surface
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Sensitive transcript/amount leaked via logs | Information Disclosure | No-log discipline (V7); new code logs nothing sensitive |
| Learning-table pollution from drafts | Tampering (data integrity) | D-05 deferral; D-07 write==read; never write merchant table |
| Unbounded amount from number-word fallback | Tampering | Clamp to the same `0 < amount < 10_000_000` range as `_extractArabicAmount` |

## Sources

### Primary (HIGH confidence — read this session)
- `lib/application/voice/parse_voice_input_use_case.dart` — outcome computed, 3 fields dropped at VPR construction (D-11 gap); `_extractKeyword` no lowercase on residual.
- `lib/features/voice/domain/models/recognition_outcome.dart` + `voice_parse_result.dart` — contract shapes; alternates "for Phase-52 chips".
- `lib/application/voice/recognition/{category_recognizer,merchant_recognizer}.dart` — exact `findByKeyword`; merchant scorer script-agnostic.
- `lib/application/accounting/seed_merchants_use_case.dart` — `nameEn`→`locale` key, aliases→`alias` key (English merchant recognition already wired).
- `lib/infrastructure/ml/merchant_name_normalizer.dart` — lowercases Latin (en merchant match works).
- `lib/shared/constants/default_merchants.dart` + `merchants/*.dart` — nameEn 383/391 (98%), aliases on all 391 (grep counts).
- `lib/shared/constants/default_synonyms.dart` — zh+ja only, English explicitly deferred (lines 44-47).
- `lib/application/voice/record_category_correction_use_case.dart` + `transaction_details_form.dart:560-588` — correction path exists, fires immediately, full-selector only; `_initialCategoryId` memory exists.
- `lib/features/settings/presentation/providers/state_settings.dart` + `utils/voice_locale_helpers.dart` + `widgets/voice_section.dart` — voice locale decoupled from UI locale, supports en, has a settings selector.
- `lib/application/voice/voice_text_parser.dart` — Arabic priority; `_runStateMachine` only branches ja/zh (isolation point).
- `lib/data/daos/category_keyword_preference_dao.dart:18-30` — `findByKeyword` exact/case-sensitive.
- `test/widget/.../anti_toxicity_phase47_test.dart` + `test/flutter_test_config.dart` + `test/architecture/arb_key_parity_test.dart` — close-out gate patterns.
- `.planning/ROADMAP.md` §Pitfall→Phase→Regression-Test Map (pitfalls 5/7/8/9/10).
- `.planning/phases/52-recognition-ux-english-voice/52-CONTEXT.md` + `52-UI-SPEC.md` — locked decisions + visual contract.

### Secondary (MEDIUM confidence)
- MEMORY gotchas: `golden-ci-platform-gate`, `gsd-executor-l10n-generated-uncommitted`, `voice-form-merchant-floor-bypass`, `gsd-post-merge-gate-flutter-mismatch`.

### Tertiary (LOW confidence)
- The exact en number-word token list + X.50 trigger grammar (A1/A4) — design proposal, finalize at plan.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — everything is first-party, read this session; no external packages.
- Architecture: HIGH — data flow traced through actual source with file:line provenance.
- Pitfalls: HIGH — casing/isolation/defer pitfalls confirmed against current code, not assumed.
- En number-word token set + X.50 grammar: LOW/MEDIUM — design proposal (A1/A4), bounded by CONTEXT.

**Research date:** 2026-06-24
**Valid until:** ~2026-07-24 (stable; code-grounded findings only drift if the recognition contract or seed pipeline changes before planning)
