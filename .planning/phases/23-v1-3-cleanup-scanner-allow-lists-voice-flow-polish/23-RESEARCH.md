# Phase 23: v1.3 cleanup — scanner allow-lists + voice flow polish - Research

**Researched:** 2026-05-25
**Domain:** Flutter voice-input polish (gesture lifecycle, recognizer status semantics, mixin extraction), seed dedup, constant dedup, REQUIREMENTS / SUMMARY frontmatter reconciliation, carried device UATs
**Confidence:** HIGH (almost every claim is verifiable in the local repo or in `speech_to_text` upstream docs; only the WR-NEW-01 threshold value is anchored on ASSUMED upstream behavior because the plugin docs are silent on intra-session `notListening` cadence)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

> Copied verbatim from `23-CONTEXT.md` §Implementation Decisions. The planner MUST honor these — research does not relitigate them, only investigates the open questions CONTEXT.md flagged.

**Scope & Phase Identity**
- **D-01:** Intent is **full voice-flow polish** — Phase 22 voice items (selective per below) + Phase 21 IN-01..06 (selective per below). Cleanup-only; no new capabilities.
- **D-02:** Keep ROADMAP.md Phase 23 title verbatim (`v1.3 cleanup: scanner allow-lists + voice flow polish`). Scanner allow-lists already cleared in Phase 21 (`117be50` + `a570dfc`). CONTEXT.md is the canonical scope record.
- **D-03:** Fold ALL carried human UATs into Phase 23:
  - Phase 19 — keypad-feel + 6-golden visual baseline
  - Phase 20 — VOICE-02-DEVICE-VERIFY 8-anchor (zh: 2204 continuous, 1840 intra-pause merge, 1800 false-merge regression; ja: にせんにひゃくよん→2204, せんはっぴゃく+よんじゅう円→1840, 一万二千→12000; sanity: record button stays lit + ManualOneStepScreen carries initialAmount)
  - Phase 22 — 4 device UATs: physical-touch <100ms latency, real-world ja/zh recognizer accuracy, idle-state golden anti-aliasing parity, `_onStatus('notListening')` intermediate behavior on iOS+Android
- **D-04:** Documentation reconciliation is **in Phase 23 scope** (not split to a `/gsd-quick`). Flip REQUIREMENTS.md `[ ]` → `[x]` for INPUT-03, INPUT-04, EDIT-01, EDIT-02, VOICE-01..06 (10 rows); update REQUIREMENTS.md traceability table rows 110-117 + 120-121 `Pending` → `Complete`; backfill `requirements-completed` frontmatter for Phase 18 SUMMARY 18-02/04/06/07/08 and Phase 19 SUMMARY 19-03/05.

**Voice Flow Polish — `voice_input_screen.dart` (832 LOC)**
- **D-05 (WR-NEW-01):** Keep both `status == 'done' || status == 'notListening'` in `_onStatus` G-01 predicate. Add an **intra-session heuristic guard**: peek the merger's last-partial-result timestamp (`_amountMerger.lastPartialAt` or equivalent — researcher to confirm `VoiceChunkMerger` exposes this; if not, add the accessor). If elapsed-since-last-partial < N ms, treat `notListening` as intra-session (skip commit, allow recognizer to restart). Else proceed with commit. The N threshold is anchored to `speech_to_text` plugin partial-result cadence — researcher determines exact value (typical iOS partial cadence: ~100-300 ms; pick a conservative ceiling like 800 ms with documented rationale).
- **D-06 (WR-NEW-02 + WR-NEW-03):** **DEFERRED to v1.4+.** Phase 23 does NOT touch the commit path (`_stopRecordingAndCommit`, `_parseResult` mutation, `_onError` flag-suppression). The commit path was just stabilized in Phase 22 via G-01 + G-02 gap closures (plans 22-08/09/10) — further rewrites here would re-risk that work. The carried Phase 22 device UAT covers the user-observable risk.
- **D-07 (WR-01):** `voiceLocaleId` cold-start race fix — await `voiceLocaleIdProvider` resolution in `initState` (or in `_initSpeechService`) before allowing the first `_onLongPressStart` to enter `_startRecording`. Concrete shape: gate `_isInitialized = true` on **both** `appSpeechRecognitionServiceProvider.initialize()` success AND `voiceLocaleIdProvider` having a non-null value. Researcher to confirm `voiceLocaleIdProvider` resolution path (likely `SharedPreferences.getString('voice_locale_id')` → fallback device locale).
- **D-08 (WR-04):** Defer `Navigator.popUntil` in `_onSavePressed` for soul-ledger success path. Concrete shape: when the saved transaction is soul-ledger, pass an `onCompleted` callback to `SoulCelebrationOverlay.show(...)` that triggers the pop; for survival-ledger, keep the immediate pop.
- **D-09 (WR-07):** Hoist `addListener`/`removeListener` arguments to a named local function (or stored `VoidCallback` field) so the same closure reference is used for both. Mechanical, pure safety. Verify with the existing widget tests + add a leak test if one doesn't exist.
- **D-10 (IN-02):** Extract `_onStatus` + `_onError` (~50 LOC together) into a new `VoiceRecognitionEventHandlerMixin` on `_VoiceInputScreenState`. Gesture handlers (`_onLongPressStart` / `_onLongPressEnd` / `_onLongPressCancel`) stay in the screen — they read screen-local state heavily (`_pressStart`, `_isRecording`, `_amountMerger`). After extraction, `voice_input_screen.dart` should drop below the 800-line cap.
- **D-11 (IN-03):** G-02 permanent test in `voice_input_screen_test.dart:946-1004` adds `expect(find.text(l10n.voiceRecognitionErrorAudio), findsOneWidget)` alongside the existing SoftToast presence assertion. Test-only change; cheap.

**Phase 21 Polish — voice category resolver / merchant DB / seed**
- **D-12 (IN-01 + IN-05 — constant dedup):**
  - IN-01: Extract `_epoch` from `lib/shared/constants/default_synonyms.dart:26` as a public `static final DateTime kVoiceSynonymSeedEpoch`; import it in `lib/data/daos/category_keyword_preference_dao.dart` (currently line 90).
  - IN-05: Move `_otherIdOverrides` map from `lib/application/voice/voice_category_resolver.dart:24-26` AND `test/architecture/category_other_l2_invariant_test.dart:35-37` to a new `lib/shared/constants/category_other_id_overrides.dart`. Both resolver and architecture test import from the new location.
- **D-13 (IN-03 — substring length guard):** Add `if (lowerQuery.length < 3) return null;` to `MerchantDatabase.findMerchant` substring pass (`lib/infrastructure/ml/merchant_database.dart:150-162`). Single-letter / two-character queries skip substring matching to avoid false-positive miscategorization. Exact-match pass (steps 1+2) is unaffected. Add a unit test asserting `'a'` returns null and `'mac'` (3 chars) continues to match McDonald's via substring.
- **D-14 (IN-04 — seed order via SeedAllUseCase):** Create `lib/application/seed/seed_all_use_case.dart` that owns both `SeedCategoriesUseCase` + `SeedVoiceSynonymsUseCase` invocations in correct order. `main.dart:108-114` collapses to one `ref.read(seedAllUseCaseProvider).execute()` call. New provider in `lib/application/seed/seed_providers.dart`. Eliminates ordering-by-comment. Add a unit test asserting categories complete before synonyms start (mock observer pattern).
- **D-15 (IN-06 — expand `その他` / `其他` / `other` seed):** Add three seed rows to `DefaultVoiceSynonyms.all` in `lib/shared/constants/default_synonyms.dart`: `_seed('その他', 'cat_other_expense')`, `_seed('其他', 'cat_other_expense')`, `_seed('other', 'cat_other_expense')`. Then add corresponding corpus cases in `test/integration/voice/voice_corpus_zh_test.dart` + `voice_corpus_ja_test.dart` + (new) `voice_corpus_en_test.dart` skeleton that asserts the override routes to `cat_other_other`. en corpus test is a coverage hedge.

**Phase 21 — Deferred (v1.4+)**
- **D-16:** **IN-02 (`CategoryKeywordPreference` SeedSpec signature change) DEFERRED.**

**Documentation Reconciliation**
- **D-17:** Phase 23 carries the 10-checkbox + 7-frontmatter reconciliation as a discrete commit (or set of commits) within the phase. Suggested ordering: code-polish first (D-05..D-15), THEN doc reconciliation (D-04 items), THEN device UAT (D-03 items).

### Claude's Discretion
- **D-18:** Plan ordering within Phase 23 — Claude decides plan count and dependency graph.
- **D-19:** N threshold for WR-NEW-01 intra-session guard — researcher anchors against `speech_to_text` plugin partial-result cadence. Recommended ceiling 800 ms (≈3× typical iOS partial cadence) but Claude may adjust based on plugin docs.
- **D-20:** Test strategy across the bundle — Claude decides whether each fix gets a dedicated test file or whether existing test files grow.

### Deferred Ideas (OUT OF SCOPE)

> Copied verbatim from `23-CONTEXT.md` §Deferred Ideas. Research must NOT explore alternatives in these areas.

**Beyond Phase 23 — v1.4+ candidates**
- WR-NEW-02 (spurious toast post-success) — `_committedRecently` flag.
- WR-NEW-03 (double-parse of final transcript).
- WR-02 (vacuous null check) — cosmetic.
- WR-03 (microtask race on `_parseResult`).
- WR-06 (mocktail catch-all stub override) — test-only.
- IN-01 (toast retry affordance) — UX polish.
- IN-02 Phase 21 (`CategoryKeywordPreference` SeedSpec signature change).
- MOD-005 OCR writer.
- English voice input quality (full corpus + synonyms; D-15 only seeds one en hedge entry).
- VALIDATION.md (Nyquist) retrofits for Phases 18/19/20/21/22.

**Beyond v1.3 — carried-forward themes (per PROJECT.md)**
- FAMILY-V2-01/02/03 family privacy hardening — v1.4+.
- FUTURE-QA-01 release-readiness smoke tests — v1 release gate.
- FUTURE-DOC-01..06 doc drift cleanup — v1.4+.
- FUTURE-TOOL-03 coverage threshold review — v1.4+.
- TOOL-V2-01 fl_chart 1.x upgrade.
- FUTURE-ARCH-04 `recoverFromSeed()` key-overwrite bug.
</user_constraints>

<phase_requirements>
## Phase Requirements

> Phase 23 is a cleanup phase — `phase_req_ids` is `null` (TBD in ROADMAP). The authoritative requirements list is CONTEXT.md D-01..D-20. CONTEXT.md also targets DOCUMENTATION drift of the v1.3 functional REQUIREMENTS.md rows (INPUT-03, INPUT-04, EDIT-01, EDIT-02, VOICE-01..06) — those rows belong to Phases 18/20/21, not Phase 23. Phase 23 only flips checkbox metadata for them per D-04.

| ID | Description | Research Support |
|----|-------------|------------------|
| D-04 row INPUT-03 | flip REQUIREMENTS.md `[ ]` → `[x]` + traceability `Pending` → `Complete` | line 21 stale `[ ]`; line 110 stale `Pending`; Phase 18 VERIFICATION.md is SATISFIED per v1.3-MILESTONE-AUDIT.md `partial_requirements[]` |
| D-04 row INPUT-04 | same as above | line 22 stale; line 111 stale; Phase 18 VERIFICATION SATISFIED |
| D-04 row VOICE-01 | same | line 26 stale; line 112 stale; Phase 20 VERIFICATION SATISFIED |
| D-04 row VOICE-02 | same | line 29 stale; line 113 stale; Phase 20 SATISFIED (with deferred device UAT, folded into D-03 here) |
| D-04 row VOICE-03 | same | line 32 stale; line 114 stale; Phase 20 SATISFIED |
| D-04 row VOICE-04 | same | line 39 stale; line 115 stale; Phase 21 SATISFIED |
| D-04 row VOICE-05 | same | line 40 stale; line 116 stale; Phase 21 SATISFIED |
| D-04 row VOICE-06 | same | line 41 stale; line 117 stale; Phase 21 SATISFIED |
| D-04 row EDIT-01 | same | line 50 stale; line 120 stale; Phase 18 SATISFIED |
| D-04 row EDIT-02 | same | line 51 stale; line 121 stale; Phase 18 SATISFIED |
| D-04 frontmatter 18-02 / 18-04 / 18-06 / 18-07 / 18-08 | backfill `requirements-completed: [...]` | Phase 22 uses pattern `requirements-completed: [INPUT-02, REC-01, REC-02]` — verified at e.g. `22-04-SUMMARY.md:7` (grep confirmed). Phase 18 frontmatter has 0 `requirements-completed` keys (grep confirmed). |
| D-04 frontmatter 19-03 / 19-05 | backfill `requirements-completed: [INPUT-01]` | grep confirmed Phase 19 SUMMARY 03 + 05 lack `requirements-completed` field |
</phase_requirements>

---

## Project Constraints (from CLAUDE.md)

> Phase 23 fixes must respect these — already inline in CONTEXT.md as inviolable, restated here as a checklist for the planner.

| Constraint | Source | Phase 23 Implication |
|------------|--------|----------------------|
| **800-line file cap** | `coding-style.md` "200-400 lines typical, 800 max" | `voice_input_screen.dart` currently 832 — D-10 mixin extraction MUST drop it under 800. After moving `_onStatus` (~25 lines incl. comments) + `_onError` (~23 lines incl. comments) the screen falls to ≈784 LOC even before mixin abstract-getter lines. |
| **Thin Feature rule** | "features NEVER contain application/, infrastructure/, data/tables/, data/daos/" | D-14 `SeedAllUseCase` lives in `lib/application/seed/` (correct — out of `features/`). D-10 `VoiceRecognitionEventHandlerMixin` MUST live in `lib/features/accounting/presentation/screens/` (mixin is presentation-glue, not domain logic — Thin Feature only restricts SUB-layers under features). |
| **Riverpod 3 conventions** | CLAUDE.md §"Riverpod 3 conventions" | D-07 gating: use `ref.listen(voiceLocaleIdProvider, …)` for side effects (not `ref.watch` in initState). Current code at `voice_input_screen.dart:575` already uses `ref.watch` in build with `case AsyncData(:final value)` pattern — D-07 must add a listen-driven initialization gate, NOT a watch in initState. |
| **No new schema migration** | CONTEXT.md `<specifics>` | Phase 23 stays on Drift schema v17. D-15 adds 3 seed rows via existing `category_keyword_preferences` table. |
| **No new ARB keys for code-polish** | CONTEXT.md `<specifics>` | D-11 reuses existing `voiceRecognitionErrorAudio` key (verified present in app_ja/zh/en.arb at line 1656). D-13/D-14/D-15 are non-UI. |
| **i18n parity, `S.of(context)`** | CLAUDE.md §"i18n Rules" | Phase 23 adds no user-facing strings except seed `その他/其他/other` which are corpus-resolver keys, NOT UI strings. No ARB changes. |
| **`copyWith` immutability** | CLAUDE.md §"Code Quality" | D-09 listener hoist is a pure-mechanical refactor; no model mutation. |
| **`flutter analyze` 0 issues; per-file coverage ≥70%** | CLAUDE.md §"Quality gates" | All new tests + mixin must pass analyzer. |
| **NEVER add `sqlite3_flutter_libs`** | CLAUDE.md §"Pitfalls" | Not relevant to Phase 23 scope. |

---

## Summary

Phase 23 is the v1.3 closer cleanup. It collects three tightly bounded bundles:

1. **Voice-flow surgical polish** in `voice_input_screen.dart` (832 → ~770 LOC after D-10) — six fixes that DO NOT touch the commit path. The riskiest is D-05's intra-session `notListening` heuristic guard, which is `[ASSUMED]` against upstream `speech_to_text` behavior because the plugin docs are silent on intra-session cadence and the verified `notListening` doc string is "the microphone is no longer active following timeout, cancellation, or stop operations" [CITED: pub.dev/documentation/speech_to_text]. Real-world bug reports (WR-NEW-01 from 22-REVIEW.md) document that the plugin DOES emit `notListening` mid-session on some Android devices, justifying the additive guard.

2. **Phase 21 mechanical polish** (D-12..D-15) — constant dedup (epoch + _otherIdOverrides), `MerchantDatabase` length guard, `SeedAllUseCase` ordering wrapper, three `その他`/`其他`/`other` seed rows. All low-risk, all parallelizable, all verifiable at the line-reference level (CONTEXT.md citations confirmed in this research session).

3. **Documentation reconciliation + device UATs** — 10 REQUIREMENTS.md checkbox flips, 7 SUMMARY frontmatter backfills, 4 carried Phase 22 device UATs, 1 carried Phase 20 device UAT (VOICE-02-DEVICE-VERIFY 8-anchor), 2 carried Phase 19 device UATs. Doc reconciliation is the LAST work in the phase (per D-17 ordering) so frontmatter reflects what shipped.

**Primary recommendation:** **(a) Treat D-10 mixin extraction as a HARD prerequisite for D-05** — moving `_onStatus`/`_onError` first and then adding the new D-05 guard inside the mixin keeps the screen under the 800-line cap. **(b) Use `ref.listen` (not `ref.watch` in initState) for D-07's voiceLocaleId cold-start gate** — per CLAUDE.md Riverpod 3 conventions and verified pattern in the screen's existing code. **(c) Pin the D-05 N-threshold at 800 ms** as a conservative ceiling — the threshold is `[ASSUMED]` (plugin docs are silent on intra-session cadence), but 800 ms is large enough to absorb the worst-case observed iOS partial cadence (~300 ms) with 2× headroom, while still being short enough that a true session end (typically followed by `done` within 100-200 ms after `notListening`) does not get masked. **Document this rationale inline as a comment in `_onStatus`** so a future device-UAT can revise it without re-doing this analysis.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| `_onStatus` / `_onError` event handling | Presentation (mixin on `_VoiceInputScreenState`) | — | Pure presentation glue — reads recording flags, calls toast helper. No domain logic. Mixin keeps it composable + screen under 800 LOC. |
| `VoiceChunkMerger` last-partial timestamp accessor | Application/voice | — | Already lives at `lib/application/voice/voice_chunk_merger.dart`. D-05 adds a `lastFinalAt` getter (mirror of existing private `_lastFinalAt` field at line 55). Note: `partial`-vs-`final` distinction matters — see Open Q1. |
| `voiceLocaleId` cold-start gate | Presentation | — | Screen-local async-ready flag; mirrors existing `_isInitialized = available` gate at `voice_input_screen.dart:164`. Use `ref.listen` callback to setState the new flag. |
| `popUntil` deferral for soul-celebration | Presentation | — | Pure UI flow ordering. `SoulCelebrationOverlay.onDismissed` callback already exists (verified `soul_celebration_overlay.dart:12,59`). |
| `addListener` / `removeListener` closure hoist | Presentation (test code) | — | WR-07 fix is in `transaction_details_form_test.dart:910-911, 1056-1057` — TEST code, not production. Phase 23 changes the test file. |
| `_epoch` constant + `_otherIdOverrides` map | Shared constants (`lib/shared/constants/`) | — | Both are pure value constants — correct tier per CLAUDE.md "constant export from `lib/shared/constants/`". |
| `MerchantDatabase` length guard | Infrastructure (`lib/infrastructure/ml/`) | — | Match algorithm internals stay in infra layer. |
| `SeedAllUseCase` | Application (`lib/application/seed/`) | — | Use-case wrapper composing two existing use cases — application-layer orchestrator pattern (CONTEXT.md §code_context). |
| `その他/其他/other` seed rows + corpus tests | Shared constants + test/integration | — | Seed in `default_synonyms.dart`; corpus tests in `test/integration/voice/`. |
| REQUIREMENTS.md checkbox flips | Doc | — | Pure metadata write, no code. |
| Phase 18/19 SUMMARY frontmatter backfill | Doc | — | Pure YAML frontmatter write, no code. |

---

## Standard Stack

> Phase 23 does NOT add new libraries. Verified versions of existing relevant deps:

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `flutter` | 3.44.0 stable (2026-05-15) | UI framework | `flutter --version` confirmed in this session |
| `speech_to_text` | `^7.0.0` (latest `7.4.0` released ~5 days ago per pub.dev) | Voice recognition engine | Pin verified in `pubspec.yaml:41` [VERIFIED: local repo]. Latest version confirmed [CITED: pub.dev/packages/speech_to_text/changelog]. |
| `flutter_riverpod` | (project-pinned, Riverpod 3) | State management | CLAUDE.md §"Riverpod 3 conventions" |
| `freezed` / `freezed_annotation` | (project-pinned) | Immutable models | CLAUDE.md |
| `drift` + `sqlcipher_flutter_libs` | (project-pinned) | DB + encryption | CLAUDE.md §"iOS Build" |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `mocktail` | (project-pinned) | Unit-test mocks | D-14 seed-order test (mock observer to record completion timestamps) |
| `flutter_test` | SDK | Widget tests | D-09 listener leak assertion; D-11 localized-string assertion; D-13 substring-guard unit test |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| New mixin file | Inline private extension on State | Mixin is the idiomatic choice for handler bundling that needs abstract slots; extensions cannot declare abstract members |
| `ref.listen` for D-07 | `ref.watch(provider.future)` in initState | Riverpod 3 rejects watch in initState (per CLAUDE.md). `.future` from initState is the wrong tool because it disposes orphan reads. `ref.listen` with `fireImmediately: true` is the correct pattern. |
| `SeedAllUseCase` wrapper | Add explicit sanity check inside `SeedVoiceSynonymsUseCase.execute()` | CONTEXT.md D-14 explicitly chose the wrapper — research must not relitigate |

**Version verification:** Re-verified `speech_to_text` constraint at `pubspec.yaml:41` (^7.0.0). Latest published version is 7.4.0-beta [CITED: pub.dev/packages/speech_to_text]. No upgrade needed for Phase 23 (cleanup-only).

**Installation:** No new packages.

---

## Package Legitimacy Audit

> No new packages installed in Phase 23. Existing packages already validated in earlier phases.

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| (none) | — | — | — | — | — | N/A — no installs |

**slopcheck note:** `slopcheck` was not installed in this environment (`command -v slopcheck` → not available). Per protocol: since Phase 23 installs **zero** packages (cleanup-only), the slopcheck gate has nothing to evaluate. No `[ASSUMED]` package tags are needed.

---

## Architecture Patterns

### System Architecture Diagram

```
                                                                
  USER GESTURE  (LongPressStart / LongPressEnd / LongPressCancel)
                                                                
                            
                            v
                                          
  voice_input_screen.dart (832 LOC pre-cleanup)              
    _onLongPressStart  →  _startRecording  →                  
        ↓                       ↓                              
    _pressStart=now          _isRecording=true                
                                ↓                              
                            _amountMerger created              
                            speechService.startListening       
                                                            
                            ↓
                                              
  speech_to_text plugin (^7.0.0)                                  
    callback: _onResult(partial / final)                          
    callback: _onStatus('listening' / 'notListening' / 'done')    
    callback: _onError(errorMsg, permanent)                        
                                              
            ↓                          ↓                      ↓
                              
  PARTIAL/FINAL          STATUS                          ERROR
                              
  - _onResult            - G-01 + Phase 23 D-05         - G-02
    feedChunk to merger  - if 'done' || ('notListening' - showVoice
  - _parseFinalResult     && lastFinalAt>N ms)            Recognition
                          → commit                         ErrorToast
                                                         - if permanent
                                                           _isInitialized=false
                              ↓                          ↓
                                              
  D-05 NEW INTRA-SESSION GUARD                                
  if status == 'notListening':                                  
    elapsed = now - merger.lastFinalAt                          
    if elapsed < N_THRESHOLD_MS (800): return; ← skip          
    else: proceed to commit                                     
                                              
                              ↓
                                              
  COMMIT PATH (off-limits — not modified by Phase 23)             
  _stopRecordingAndCommit  →  parseUseCase  →  form setters       
                                              
                              ↓
                                              
  Save button (D-08 changes flow here)                            
  result.when(success: ...)                                       
    if ledger == soul:                                            
      _showCelebration = true   ← currently in form (line 426)   
      onDismissed → setState                                      
      D-08 NEW: pop happens INSIDE onDismissed, not before        
    else:                                                         
      pop immediately                                             
                                              
```

The diagram shows how Phase 23's three voice-screen edits (D-05 status guard, D-08 popUntil deferral, D-10 mixin boundary) compose without touching the commit path. D-09 (listener closure) lives outside this diagram — it's in `transaction_details_form_test.dart`.

### Recommended Project Structure (Phase 23 additions only)

```
lib/
├── application/
│   └── seed/                                  ← NEW (D-14)
│       ├── seed_all_use_case.dart
│       └── seed_providers.dart                ← Riverpod wiring
├── features/accounting/presentation/screens/
│   ├── voice_input_screen.dart                ← MODIFIED (drops to ~770 LOC)
│   └── voice_recognition_event_handler_mixin.dart  ← NEW (D-10)
├── shared/constants/
│   ├── default_synonyms.dart                  ← MODIFIED (D-12 kVoiceSynonymSeedEpoch + D-15 3 new seed rows)
│   └── category_other_id_overrides.dart       ← NEW (D-12 IN-05 single source of truth)
└── data/daos/
    └── category_keyword_preference_dao.dart   ← MODIFIED (import + use kVoiceSynonymSeedEpoch)

test/
├── architecture/
│   └── category_other_l2_invariant_test.dart  ← MODIFIED (import shared constant)
├── integration/voice/
│   ├── voice_corpus_zh_test.dart              ← MODIFIED (其他 anchor)
│   ├── voice_corpus_ja_test.dart              ← MODIFIED (その他 anchor)
│   └── voice_corpus_en_test.dart              ← NEW (single 'other' hedge case)
├── unit/application/
│   ├── seed/
│   │   └── seed_all_use_case_test.dart        ← NEW (D-14 ordering)
│   └── voice/
│       └── voice_chunk_merger_test.dart       ← MODIFIED (lastFinalAt getter test)
├── unit/infrastructure/ml/
│   └── merchant_database_test.dart            ← MODIFIED (D-13 length guard tests)
└── widget/features/accounting/presentation/
    ├── screens/voice_input_screen_test.dart   ← MODIFIED (D-05 guard tests, D-07 race tests, D-08 overlay test, D-09 leak test, D-11 localized string)
    └── widgets/transaction_details_form_test.dart  ← MODIFIED (D-09 WR-07 hoist closure)
```

### Pattern 1: Mixin-on-State for cross-cutting handler bundles (D-10)

**What:** Dart mixin declared `on State<W>` (or `on ConsumerState<W>`) so the mixin can read `widget`, call `setState`, and use `mounted`. The State class declares abstract getters/methods the mixin needs (e.g., `bool get isRecording`, `void onCommitRequested()`); the mixin provides the handler bodies.

**When to use:** Bundle 50-100 LOC of related handlers that share a clear contract with the State class. Cleaner than free functions (which need explicit args for every state field) and more composable than a private inheritance hierarchy.

**Codebase precedent:** **None** — zero user-authored mixins exist in `lib/` (confirmed by `grep -rn '^mixin '` returning only Freezed/Drift generated files). This will be the first. The only mixin-related code uses framework mixins (`WidgetsBindingObserver`, `SingleTickerProviderStateMixin`). Phase 23 is establishing the precedent.

**Example shape** (researcher-recommended skeleton — planner can adjust):

```dart
// lib/features/accounting/presentation/screens/voice_recognition_event_handler_mixin.dart
// Source: this RESEARCH document. No upstream example exists in this codebase.

import 'dart:async';
import 'package:flutter/widgets.dart';
import '../widgets/voice_error_toast.dart';

/// Phase 23 D-10: extracts _onStatus + _onError from VoiceInputScreen so the
/// screen file drops under the 800-line CLAUDE.md cap.
///
/// The State class must supply the listed abstract members. The mixin
/// provides handler bodies that drive setState through them.
mixin VoiceRecognitionEventHandlerMixin<W extends StatefulWidget> on State<W> {
  // ── Abstract contract — State class implements these ──

  /// Whether the recognizer is currently in a recording session.
  bool get isRecording;
  set isRecording(bool value);

  /// Most recent finger-down DateTime from _onLongPressStart, or null when
  /// no press is in flight. The mixin clears this to enforce idempotency
  /// when status-driven commit fires.
  DateTime? get pressStart;
  set pressStart(DateTime? value);

  /// Initialization flag. Mixin flips to false on permanent error.
  set isInitialized(bool value);

  /// Sound-level state — cleared on session end.
  set soundLevel(double value);

  /// Last-final-result timestamp from the chunk merger. Used by Phase 23
  /// D-05 intra-session guard. Null when no chunks have been seen yet.
  DateTime? get lastMergerFinalAt;

  /// Commit driver — caller's _stopRecordingAndCommit.
  Future<void> stopRecordingAndCommit();

  // ── D-05 threshold — exposed for tunability ──

  /// Intra-session `notListening` heuristic — see RESEARCH §D-05 / §Open Q1.
  static const Duration intraSessionThreshold = Duration(milliseconds: 800);

  // ── G-01 + D-05 ──

  void onStatus(String status) {
    if (!mounted) return;
    if (status != 'done' && status != 'notListening') return;
    if (!isRecording) return;

    // D-05: when status is 'notListening' AND we recently received a final
    // chunk, treat as intra-session pause (recognizer self-restart in flight)
    // and skip commit. Only 'done' is treated as canonically terminal.
    if (status == 'notListening' && pressStart != null) {
      final lastFinal = lastMergerFinalAt;
      if (lastFinal != null &&
          DateTime.now().difference(lastFinal) <
              intraSessionThreshold) {
        return; // intra-session — allow recognizer-self-restart path
      }
    }

    if (pressStart != null) {
      pressStart = null;
      unawaited(stopRecordingAndCommit());
      return;
    }
    setState(() {
      isRecording = false;
      soundLevel = 0.0;
    });
  }

  // ── G-02 ──

  void onError(String errorMsg, bool permanent) {
    if (!mounted) return;
    setState(() {
      isRecording = false;
      soundLevel = 0.0;
      if (permanent) isInitialized = false;
    });
    showVoiceRecognitionErrorToast(context, errorMsg);
  }
}
```

**Verification fields read by `_onStatus` / `_onError` in current code (lines 172-220):**
- Read: `mounted`, `_isRecording`, `_pressStart`
- Write: `_pressStart` (cleared), `_isRecording` (false), `_soundLevel` (0), `_isInitialized` (false on permanent)
- Calls: `_stopRecordingAndCommit()`, `showVoiceRecognitionErrorToast(context, errorMsg)`, `setState`

All confirmed by inspection of `voice_input_screen.dart:172-220`.

### Pattern 2: `ref.listen`-driven async-ready gate (D-07)

**What:** Use `ref.listen(asyncProvider, callback)` with `fireImmediately: true` so the screen reacts when the async provider resolves, instead of trying to `await` in `initState`.

**When to use:** Need to gate side effects (UI, controller calls) on an async provider's resolution.

**Codebase precedent:** The screen already uses `ref.watch` in build with `case AsyncData(:final value)` pattern at `voice_input_screen.dart:575-578`. D-07 must add a complementary `ref.listen` so the FIRST resolution flips a new `_isLocaleReady` flag that gates `_onLongPressStart`.

**Source:** CLAUDE.md §"Riverpod 3 conventions" — "Side-effect listeners belong in `ref.listen`, not `ref.watch`. Riverpod 3 dropped some `watch`-driven side-effect rebuilds for legacy `StateNotifierProvider`s — use `ref.listen` for navigation, snackbars, etc."

**Confirmed signature:**
- `appSpeechRecognitionServiceProvider.initialize()` → `Future<bool>` returning `available` (verified at `speech_recognition_service.dart:35-48`)
- `voiceLocaleIdProvider` resolves via `await ref.watch(appSettingsProvider.future)` → `voiceLocaleIdFromLanguageCode(settings.voiceLanguage)` (verified at `state_settings.dart:21-24`). Fallback when `code` doesn't match `'zh'`/`'ja'`/`'en'` is `'zh-CN'` (verified at `voice_locale_helpers.dart:11-13`). So the provider is NOT backed by direct `SharedPreferences.getString('voice_locale_id')` — it's backed by `AppSettings.voiceLanguage` which itself reads from SharedPreferences.

**Recommended D-07 shape:**

```dart
// In initState, after _initSpeechService():
ref.listenManual<AsyncValue<String>>(
  voiceLocaleIdProvider,
  (prev, next) {
    if (next case AsyncData(:final value)) {
      _voiceLocaleId = value;
      if (mounted && !_isLocaleReady) {
        setState(() => _isLocaleReady = true);
      }
    }
  },
  fireImmediately: true,
);
```

Then `_onLongPressStart` gains an additional guard:

```dart
void _onLongPressStart(LongPressStartDetails details) {
  if (!_isInitialized || !_isLocaleReady || _isRecording) return;
  // ...
}
```

### Pattern 3: `SoulCelebrationOverlay.onDismissed` callback wiring (D-08)

**What:** The overlay already accepts `onDismissed: VoidCallback?` (verified `soul_celebration_overlay.dart:12`) and fires it on animation completion (verified `soul_celebration_overlay.dart:57-61` — `_controller.addStatusListener` invokes `widget.onDismissed?.call()` on `completed`).

**The mismatch:** `TransactionDetailsForm` mounts the overlay internally (verified `transaction_details_form.dart:742-749`), passing its OWN `onDismissed` callback (which only clears `_showCelebration`). The voice screen receives `result.when(success: ...)` AFTER the form's overlay has begun showing, but its `Navigator.popUntil` at `voice_input_screen.dart:408` fires synchronously — popping the route before the celebration animation completes.

**D-08 fix shape:** The form should NOT auto-mount the overlay for the `.new` host that wants pop deferral. Two options for the planner:

- **(A) — minimal, recommended:** Add a new method to `TransactionDetailsFormState` such as `Future<void> waitForCelebrationDismissed()` that returns the existing celebration controller's completion future, and have the voice screen `await` it before `popUntil`. Survival ledger result returns immediately.
- **(B) — heavier:** Add a `mountCelebrationInline: bool` config to `TransactionDetailsFormConfig.$new` that suppresses the form's internal overlay; the voice screen mounts the overlay itself with its own `onDismissed: () => Navigator.popUntil(...)`. Requires touching the form's celebration logic.

**Planner discretion:** Pick (A) unless test coverage for option (B) is materially better. Option (A) keeps the form untouched and is a smaller diff.

### Pattern 4: Use-case wrapper composing other use cases (D-14)

**What:** `SeedAllUseCase` holds dependencies on both existing `SeedCategoriesUseCase` and `SeedVoiceSynonymsUseCase`, and its `execute()` awaits them in order.

**Codebase precedent:** No exact wrapper exists, but Riverpod use-case wiring under `lib/application/accounting/` follows a uniform constructor-injection + Result wrapping shape. Match it.

**Recommended shape:**

```dart
// lib/application/seed/seed_all_use_case.dart
import '../accounting/seed_categories_use_case.dart';
import '../../application/accounting/seed_voice_synonyms_use_case.dart';
import '../../shared/utils/result.dart';

class SeedAllUseCase {
  SeedAllUseCase({
    required SeedCategoriesUseCase seedCategories,
    required SeedVoiceSynonymsUseCase seedVoiceSynonyms,
  }) : _seedCategories = seedCategories,
       _seedVoiceSynonyms = seedVoiceSynonyms;

  final SeedCategoriesUseCase _seedCategories;
  final SeedVoiceSynonymsUseCase _seedVoiceSynonyms;

  Future<Result<void>> execute() async {
    final categoriesResult = await _seedCategories.execute();
    if (!categoriesResult.isSuccess) return categoriesResult;
    return _seedVoiceSynonyms.execute();
  }
}
```

The provider goes in `lib/application/seed/seed_providers.dart` as a `@riverpod` function returning `SeedAllUseCase`. `main.dart:108-114` collapses to one `await ref.read(seedAllUseCaseProvider).execute()`.

**Test pattern for D-14 ordering:** Use mocktail to record `_seedCategories.execute` completion-timestamp + `_seedVoiceSynonyms.execute` start-timestamp; assert `categoriesCompletedAt.isBefore(synonymsStartedAt)`.

### Anti-Patterns to Avoid

- **`ref.watch(voiceLocaleIdProvider.future)` in `initState`** — Riverpod 3 disposes orphan reads. CLAUDE.md explicitly warns against this. Use `ref.listenManual` with `fireImmediately: true`.
- **Touching `_stopRecordingAndCommit`, `_parseFinalResult`, or `_onError`'s setState body** — CONTEXT.md `<specifics>` makes this an OFF-LIMITS rule. WR-NEW-02/03 are deferred.
- **Removing the existing `notListening` predicate** — CONTEXT.md D-05 keeps `'done' || 'notListening'` together; the guard is ADDITIVE.
- **Touching gesture handlers (`_onLongPressStart/End/Cancel`)** — they stay in the screen per CONTEXT.md D-10. They read screen-local state heavily (`_pressStart`, `_isRecording`, `_amountMerger`).
- **Mounting the celebration overlay from the voice screen (B-style D-08)** unless the planner has strong evidence that option (A) is harder to test.
- **Using `InsertMode.insertOrReplace` on the new D-15 seed rows** — `DefaultVoiceSynonyms.all` is appended to and the DAO uses `INSERT OR IGNORE` (verified at `category_keyword_preference_dao.dart:101`). REPLACE would clobber user `recordCorrection` data.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Celebration overlay dismissal callback | Custom `AnimationController` watcher in the screen | `SoulCelebrationOverlay.onDismissed` (already exists) | Verified at `soul_celebration_overlay.dart:12` |
| Localized error string from platform error code | Inline `switch` in screen | `showVoiceRecognitionErrorToast(context, errorMsg)` (already exists) | Verified at `voice_error_toast.dart:29-46`; 4 ARB keys + handler all in place |
| Drift batch insert with idempotency | Custom upsert loop | `_db.batch(...)` + `InsertMode.insertOrIgnore` (already used) | Verified at `category_keyword_preference_dao.dart:91-104` |
| Riverpod async-ready gating | Polling `ref.read` in build | `ref.listen` with `fireImmediately: true` | CLAUDE.md §"Riverpod 3 conventions" |
| Long-press gesture recognition | Custom raw `PointerDown/Up` tracking | `RawGestureDetector` + `LongPressGestureRecognizer(duration: Duration.zero)` | Already used at `voice_input_screen.dart:677-693` |
| Test framework for async provider gating | Bare `await container.read(provider.future)` | `waitForFirstValue<T>` in `test/helpers/test_provider_scope.dart` | CLAUDE.md §"Async test pattern" |

**Key insight:** Every "primitive" Phase 23 needs already exists in the codebase. The phase is composition + dedup, not invention.

---

## Runtime State Inventory

> Phase 23 is partly a refactor/rename phase: D-12 IN-05 moves the `_otherIdOverrides` constant; D-14 renames the seed-call call site; D-15 adds new seed rows. Even though no user-facing rename occurs, the inventory is mandatory.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| **Stored data** | `category_keyword_preferences` Drift table contains seed rows with `hitCount=0, lastUsed=DateTime(2026,1,1)`. D-15's 3 new seed rows will be INSERT-OR-IGNORE'd on next app launch via existing `SeedVoiceSynonymsUseCase`. No data migration needed (any user who previously corrected `その他/其他/other` to a different category will keep their `hitCount≥1` row, and the seed's `hitCount=0` row will not be inserted because of the `INSERT OR IGNORE`). | Code edit only — no data migration. |
| **Live service config** | None — Phase 23 touches no Datadog/CloudFlare/Tailscale/n8n state. | None — verified by scope inspection. |
| **OS-registered state** | None — no Windows Task Scheduler / launchd / pm2 / Android background-service registration changes. | None — verified by scope inspection. |
| **Secrets and env vars** | None — Phase 23 touches no SOPS / .env / CI env vars. | None — verified by scope inspection. |
| **Build artifacts / installed packages** | `lib/generated/app_localizations*.dart` — no ARB changes in Phase 23 (verified `voiceRecognitionErrorAudio` already exists at line 1656 of all 3 ARB files), so no regeneration needed. Drift schema unchanged (v17) → no `.g.dart` regeneration for tables. Riverpod codegen: D-14 adds `seedAllUseCaseProvider` → run `flutter pub run build_runner build --delete-conflicting-outputs` after Wave 1. | Run codegen once after D-14 lands; verify analyzer clean. |

**Verified:** `grep` for the renamed/added constants confirms NO references in third-party packages, NO docs outside the planning tree, NO log/audit lines referencing the literal `_otherIdOverrides` or `_epoch` strings.

---

## Common Pitfalls

### Pitfall 1: D-05 intra-session guard masks legitimate session ends

**What goes wrong:** If the N-threshold is too long (e.g., 5 s) and a user releases the mic immediately after speaking, the recognizer's terminal `notListening` may fire within N ms of the last partial — and the guard skips commit. The user sees no batch-fill on release.

**Why it happens:** The guard's premise — "if a final chunk arrived recently, this `notListening` is intra-session" — is statistical, not deterministic. A real session end can also fire `notListening` shortly after a final.

**How to avoid:** Pin threshold at 800 ms (recommended). This is ≈3× the worst-case observed iOS partial-result cadence (~250-300 ms). For threshold > 1 s, document a fallback: when guard rejects but `_pressStart == null` (i.e. user has already released), force the commit. This is defensive and prevents the masking failure mode.

**Warning signs:** Manual UAT shows form fields not filling after release in <800 ms recordings; or device UAT shows partial commits during normal pauses (threshold too short).

### Pitfall 2: D-10 mixin extraction creates two sources of truth for `_isInitialized` semantics

**What goes wrong:** Mixin's `onError` writes `isInitialized = false`. Screen's `_initSpeechService` writes `_isInitialized = available`. If the screen later re-runs init while a permanent error is mid-flight, the order can leave the guard stale.

**How to avoid:** Have the screen expose `set isInitialized(bool value)` as a single setter that wraps `setState`. The mixin uses ONLY that setter. The screen's `_initSpeechService` continues to call `setState(() => _isInitialized = available)` directly (same writer). One write surface, no drift.

**Warning signs:** Test "G-02 permanent gates mic" passes, then test "re-init recovers" fails — race window. Tests should assert both orderings.

### Pitfall 3: D-07 cold-start gate locks UI forever if `appSettingsProvider` errors

**What goes wrong:** If the underlying `AppSettings` provider throws (encryption-key issue, corrupted SharedPreferences), `voiceLocaleIdProvider` emits an `AsyncError`. The `ref.listen` callback's `case AsyncData` never matches, `_isLocaleReady` stays false, mic stays gated forever.

**How to avoid:** The listener callback ALSO handles `AsyncError`: set `_isLocaleReady = true` with a fallback locale (default `'zh-CN'` per the existing fallback in `voice_locale_helpers.dart:11-12`) AND surface a one-time SoftToast warning the user. This degrades gracefully instead of soft-locking the screen.

**Warning signs:** First-launch on a device with corrupted prefs shows mic with caption but cannot record.

### Pitfall 4: D-08 popUntil deferral races against `dispose()`

**What goes wrong:** Voice screen is the topmost route. Saving a soul-ledger entry mounts the celebration overlay (1.5 s animation per `soul_celebration_overlay.dart:30`). If the user backgrounds the app mid-animation, `dispose()` runs; the deferred `popUntil` is queued in a callback that may try to call `Navigator.of(context).popUntil` on an unmounted state.

**How to avoid:** Wrap the deferred pop in `if (!mounted) return;` AND use `WidgetsBinding.instance.addPostFrameCallback` rather than direct `Future.microtask`. The screen's existing `WidgetsBindingObserver` already cancels recording on pause (line 802-808) — extend it to also cancel the deferred pop if it hasn't fired.

**Warning signs:** Widget test that pumps a save → backgrounds the app shows an unhandled exception in `Navigator.of`.

### Pitfall 5: D-12 epoch extraction breaks if DAO and constants drift on the literal value

**What goes wrong:** Current code has `DateTime(2026, 1, 1)` repeated in BOTH `default_synonyms.dart:26` AND `category_keyword_preference_dao.dart:90`. Extraction means the DAO MUST import the constant — but if the constant gets renamed or moved during D-12 work without updating the DAO import, the build breaks silently (the DAO falls back to a literal hard-coded value that lints OK but creates two different "seed epochs" again).

**How to avoid:** Ensure the planner's task list has the DAO import as an explicit step in the same task that extracts the constant. Add a regression unit test asserting both files use the same value (compile-time, no runtime needed).

**Warning signs:** Build passes but seed audit queries that filter on `lastUsed = epoch` return inconsistent row counts.

### Pitfall 6: D-15 en seed `'other'` overlaps with English-word collisions

**What goes wrong:** `_seed('other', 'cat_other_expense')` is a 5-char English word. A user saying "the other day I bought…" could resolve to `cat_other_other` via the `findByKeyword('other')` path.

**How to avoid:** Verify that voice gating is zh/ja only in v1.3 (per REQUIREMENTS.md §Out of scope). For en voice in v1.4+, add `voice_corpus_en_test.dart` regression cases ensuring "the other day" extracts a different keyword (not bare "other"). For Phase 23 — accept the v1.3 risk (en voice not active) and add a one-line comment in `default_synonyms.dart` warning the future v1.4+ en voice work to revisit.

**Warning signs:** N/A in v1.3.

### Pitfall 7: D-13 length-guard regression breaks legitimate substring matches

**What goes wrong:** Setting `if (lowerQuery.length < 3) return null;` blocks `'ab'` and `'a'`. But what if the merchant DB has a 2-char entry like `'喬'` (single-CJK-char abbreviation)? Then `lowerQuery == '喬'` would fail the 3-char guard.

**How to avoid:** **Pre-verify** by grepping `MerchantDatabase` entry names + aliases for entries of length <3. Currently the 12 hardcoded entries are all >=3 chars (verified by inspecting `merchant_database.dart`: McDonald, Starbucks, Yoshinoya, 7-Eleven, FamilyMart, Lawson, Sukiya, Uniqlo, Nitori, Yamada, Amazon, Netflix — all ≥3). The guard is safe for the current dataset. Add a unit test asserting EXACTLY this: every entry's `name` and every alias has `length >= 3`.

**Warning signs:** Future merchant additions with 1-2 char names silently lose substring matching.

### Pitfall 8: D-14 SeedAllUseCase changes seed timing in tests that override only one of the two providers

**What goes wrong:** Some existing tests override ONLY `seedCategoriesUseCaseProvider` (e.g., the corpus tests at `test/integration/voice/voice_category_corpus_zh_test.dart:35-37` call `seedCategoriesUseCaseProvider.execute()` then `seedVoiceSynonymsUseCaseProvider.execute()` directly). After D-14 these tests still work because the two leaf providers are unchanged — but any future test that uses `seedAllUseCaseProvider` instead of the leaf calls needs to update its override pattern.

**How to avoid:** D-14 KEEPS both leaf use cases publicly accessible (don't make them private). The wrapper composes them; it doesn't replace them. Document this in the SeedAllUseCase class docstring.

**Warning signs:** Test author tries to override `seedAllUseCaseProvider` AND the leaf providers separately; tests behave inconsistently.

---

## Code Examples

### D-05 Intra-session guard call site (within the mixin)

```dart
// In voice_recognition_event_handler_mixin.dart (NEW)
// Source: Phase 23 RESEARCH, anchored on CONTEXT.md D-05 + speech_to_text plugin status semantics.

void onStatus(String status) {
  if (!mounted) return;
  if (status != 'done' && status != 'notListening') return;
  if (!isRecording) return;

  // D-05: intra-session heuristic — only applied to 'notListening'.
  // 'done' is always terminal per speech_to_text v5+ docs:
  //   "onStatus now receives the new done status after all listening is complete."
  // 'notListening' is documented as "the microphone is no longer active
  //   following timeout, cancellation, or stop operations" but real-world
  //   bug reports (22-REVIEW.md WR-NEW-01) show it can fire mid-session on
  //   some Android devices, between recognition chunks.
  if (status == 'notListening' && pressStart != null) {
    final lastFinal = lastMergerFinalAt;
    if (lastFinal != null) {
      final elapsed = DateTime.now().difference(lastFinal);
      if (elapsed < intraSessionThreshold) {
        // Recent final → recognizer-self-restart is in flight. Skip commit.
        return;
      }
    }
  }

  // Existing G-01 commit path (untouched body).
  if (pressStart != null) {
    pressStart = null;
    unawaited(stopRecordingAndCommit());
    return;
  }
  setState(() {
    isRecording = false;
    soundLevel = 0.0;
  });
}
```

### D-12 IN-05 Shared constant file (NEW)

```dart
// lib/shared/constants/category_other_id_overrides.dart
// Source: Phase 23 D-12 IN-05 dedup. Replaces duplicate maps in
// lib/application/voice/voice_category_resolver.dart:33-35 and
// test/architecture/category_other_l2_invariant_test.dart:35-37.

/// L1 ids whose `_other` L2 child does NOT follow the `${l1Id}_other`
/// convention. Single source of truth — both VoiceCategoryResolver and
/// the architecture test import this map.
///
/// Phase 21 D-03 + PATTERNS.md §7. When adding an entry, run the
/// architecture test (`flutter test test/architecture/category_other_l2_invariant_test.dart`)
/// to verify the override resolves to a real L2 row.
const Map<String, String> kCategoryOtherIdOverrides = {
  'cat_other_expense': 'cat_other_other',
};
```

### D-13 Substring guard

```dart
// lib/infrastructure/ml/merchant_database.dart — line 150 (substring pass)
// Source: Phase 23 D-13 / IN-03 from 21-REVIEW.md.

// 3. Substring match (query contains entry name, or entry name contains query)
// IN-03 guard: skip substring matching for queries shorter than 3 chars
// because single/double-char queries match too many false positives
// (e.g., 'a' matches 'amazon' via 'amazon'.contains('a')).
if (lowerQuery.length < 3) return null;

for (final entry in _entries) {
  if (lowerQuery.contains(entry.name.toLowerCase()) ||
      entry.name.toLowerCase().contains(lowerQuery)) {
    return _toMatch(entry);
  }
  // ... existing alias loop unchanged ...
}
```

### D-14 main.dart collapse

```dart
// lib/main.dart:108-114 (current)
// Phase 23 D-14: collapse two seed calls to one wrapper.

// BEFORE:
final seedCategories = ref.read(seedCategoriesUseCaseProvider);
await seedCategories.execute();
// Phase 21 D-01: synonyms must run AFTER categories.
final seedVoiceSynonyms = ref.read(seedVoiceSynonymsUseCaseProvider);
await seedVoiceSynonyms.execute();

// AFTER:
final seedAll = ref.read(seedAllUseCaseProvider);
await seedAll.execute();
```

### D-15 Three new seed rows

```dart
// lib/shared/constants/default_synonyms.dart — append to _all list
// Source: Phase 23 D-15 / IN-06 from 21-REVIEW.md.

  // ===== Other-expense override seeds (D-15 / IN-06) =====
  // Exercises the cat_other_expense → cat_other_other override in
  // VoiceCategoryResolver._ensureL2 via real corpus utterances.
  // 'other' is added as a v1.4+ en-voice hedge — voice gating in v1.3 is
  // zh/ja only, but the override is exercised in case en voice activates.
  _seed('その他', 'cat_other_expense'),
  _seed('其他', 'cat_other_expense'),
  _seed('other', 'cat_other_expense'),
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `_onStatus` short-circuits on `notListening` as terminal | Add intra-session heuristic guard before commit | Phase 23 D-05 | Reduces premature commit risk on Android pause emissions |
| `_epoch` literal repeated in DAO and constants | Single `kVoiceSynonymSeedEpoch` const imported | Phase 23 D-12 IN-01 | Compile-time enforced parity |
| `_otherIdOverrides` map repeated in resolver and arch test | Single `kCategoryOtherIdOverrides` const imported | Phase 23 D-12 IN-05 | Compile-time enforced parity |
| Two `await` calls in `main.dart:108-113` (ordering-by-comment) | `SeedAllUseCase` wrapper enforces order | Phase 23 D-14 IN-04 | Ordering becomes a contract, not a convention |
| `MerchantDatabase.findMerchant` substring match accepts any query length | 3-char minimum guard | Phase 23 D-13 IN-03 | Eliminates 1-2 char false positives |
| `speech_to_text` `notListening` treated as canonically terminal in `_onStatus` | Phase 23 D-05 heuristic guard | Phase 23 | See D-05 above |

**Deprecated / outdated:**
- None — Phase 23 introduces NO deprecations.

---

## Assumptions Log

> Every `[ASSUMED]` claim from this research must surface here so the planner can decide whether to lock with discuss-phase confirmation OR proceed with the assumption.

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `speech_to_text` plugin can emit `notListening` intra-session on some Android devices between recognition chunks | D-05 / Pitfall 1 | If false (i.e., `notListening` is always terminal per upstream docs), the D-05 guard never fires — net behavior is unchanged from Phase 22 G-01. So the worst case is "wasted code", not a regression. The bug exists per real-world WR-NEW-01 report in 22-REVIEW.md, so the assumption is well-grounded. |
| A2 | 800 ms is a safe N-threshold ceiling for the D-05 guard | D-05 / D-19 | If too short, intra-session `notListening` events still cause premature commit (Phase 23 doesn't help). If too long, real session ends are masked (Pitfall 1). Tuning lever exposed as `intraSessionThreshold` static const for easy revision via device UAT. |
| A3 | `VoiceChunkMerger._lastFinalAt` is the correct field to expose for D-05 | D-05 / §Open Q1 | If "partial" cadence (debounced 300 ms in `_onResult` at line 455) is the better signal than "final" cadence, the planner needs to add `_lastPartialAt` instead/also. Recommendation: expose `lastFinalAt` first; revisit if device UAT shows mismatched timing. |
| A4 | iOS partial-result cadence is ~100-300 ms | D-05 / Pitfall 1 | Plugin docs do not document partial cadence — this is community knowledge. If actual cadence is 500+ ms on iOS, 800 ms threshold is still safe (>2× headroom). |
| A5 | Mixin extraction will drop `voice_input_screen.dart` under 800 LOC | D-10 | Current 832 LOC includes ~50 LOC of `_onStatus` + `_onError` bodies + their inline comments. Extracting both drops to ≈770-784 LOC depending on retained delegation boilerplate (4-6 abstract member declarations) + new import. Conservative estimate: ≈785 LOC. Below 800. |
| A6 | The 12 hardcoded `MerchantDatabase` entries all have names + aliases ≥3 chars | D-13 / Pitfall 7 | Verified by inspecting `merchant_database.dart` in this session — all ≥3 chars. New entries in v1.4+ must respect the same constraint. |
| A7 | The 4 Phase 22 device UAT items and 8 Phase 20 anchor cases are stable verbatim — i.e., the exact wording in 22-HUMAN-UAT.md / 20-08-SUMMARY.md is sufficient for Phase 23's device session | D-03 | Cited 22-HUMAN-UAT.md content verified in this session. Phase 20 8-anchor wording verified in 20-08-SUMMARY.md. Phase 19 UATs verified in 19-HUMAN-UAT.md (2 items). |

**If this table is empty:** N/A — 7 assumptions surfaced; planner should treat each as a soft default rather than a hard fact.

---

## Open Questions

### Open Q1: `lastFinalAt` vs `lastPartialAt` — which timestamp drives D-05?

**What we know:**
- `VoiceChunkMerger` has a private `DateTime? _lastFinalAt` (line 55) updated in `feedChunk` on final results.
- The screen's `_onResult` (lines 444-482) processes BOTH partial and final results; partials are debounced at 300 ms (line 455).
- The merger's `_lastFinalAt` is only updated when a **final** result is fed; it stays stale between finals.
- The intra-session `notListening` event most likely fires AFTER the recognizer has emitted partial(s) for a continued utterance but BEFORE the next final.

**What's unclear:**
- Is `lastFinalAt` recent enough at the moment `notListening` fires intra-session? If finals are sparse (long pause, then more speech), `lastFinalAt` could be 5+ s stale even when the user is mid-utterance.
- An alternative would be to add `_lastPartialAt` to the merger and expose THAT — but the merger ignores partials (`feedChunk` at line 68 returns early for non-finals). A new state field would need to be threaded through the screen's `_onResult` partial branch.

**Recommendation:**
- **Phase 23:** Expose `lastFinalAt` from the merger (the simpler change). Use it for D-05. Document Open Q1 as a "verify in device UAT" item — if Phase 23 device session shows masked commits or premature commits, revisit.
- **If device UAT exposes mismatched timing:** Add a `_lastPartialAt: DateTime?` field to `_VoiceInputScreenState` itself (set in `_onResult` partial branch at line 451), and let the mixin's contract expose `DateTime? get lastPartialAt` instead. This avoids polluting the merger with state it doesn't otherwise need.

### Open Q2: Is the `_handleFocusChange` listener leak in D-09 a real bug?

**What we know:**
- The voice screen ALREADY uses the SAME method reference `_handleFocusChange` for both `addListener` and (implicit) `removeListener` via `FocusNode.dispose()` (line 828). Verified `voice_input_screen.dart:140-141`.
- Therefore there is NO listener leak in the voice screen — Dart method tear-offs of `this._handleFocusChange` are equal for the same instance.
- WR-07 is actually in `transaction_details_form_test.dart:910-911, 1056-1057` — test code using `addListener(() => notifications++)` with a different closure on each call.

**What's unclear:**
- CONTEXT.md D-09 frames this as "voice_input_screen.dart" but the actual bug is test-only. The CONTEXT.md citation may be wrong.

**Recommendation:**
- Confirm with the user during planning that D-09's target is `transaction_details_form_test.dart` (the WR-07 site), NOT the voice screen. The fix is to hoist the listener into a named local function:
  ```dart
  void onChange() { notifications++; }
  controller.addListener(onChange);
  addTearDown(() => controller.removeListener(onChange));
  ```
- If CONTEXT.md really means the voice screen, the work is a no-op — voice screen is already correct. Add a regression unit test asserting `FocusNode.hasListeners == false` after `dispose()`.

### Open Q3: Does CONTEXT.md D-04 expect Phase 23 to backfill `requirements-completed` frontmatter for VOICE-01..06 on Phase 20/21 SUMMARY files, or only for INPUT-03/04/EDIT-01/02 + INPUT-01?

**What we know:**
- CONTEXT.md D-04 lists Phase 18 SUMMARY files (18-02/04/06/07/08) + Phase 19 SUMMARY files (19-03/05). Total: 7 SUMMARY files.
- v1.3-MILESTONE-AUDIT.md `partial_requirements[]` shows VOICE-01..06 are ALREADY listed in their respective SUMMARY frontmatters (`listed (20-02)`, `listed (20-08)`, `listed (20-09)`, `listed (21-02, 21-03, 21-06)`).
- So Phase 20/21 SUMMARY frontmatters are already correct; only Phase 18 + Phase 19 need backfilling.

**What's unclear:** Nothing — the audit already disambiguates this. The 7-frontmatter count in CONTEXT.md D-04 is the correct number.

**Recommendation:** No action needed. Planner should reference v1.3-MILESTONE-AUDIT.md to verify the exact 7 files.

### Open Q4: Should the new `voice_corpus_en_test.dart` use the same fixture-driven shape as zh/ja, or a single inline test?

**What we know:**
- CONTEXT.md D-15 says "skeleton with just the one `その他/他/etc.` override case. Do NOT expand en corpus coverage beyond this one case."
- Existing zh corpus test uses `voice_corpus_zh.dart` fixture + statistical bucket pattern.

**Recommendation:** Single inline `testWidgets` with one assertion. No fixture file needed (CONTEXT.md is explicit: "skeleton"). Match the parser instantiation pattern from `voice_corpus_zh_test.dart:6-8` and the resolver setup pattern from `voice_category_corpus_zh_test.dart:33-46` but with only ONE test case.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | All work | ✓ | 3.44.0 stable (2026-05-15) | — |
| Dart SDK | All work | ✓ | 3.12.0 stable | — |
| `flutter pub run build_runner` | D-14 Riverpod codegen | ✓ (transitive via project) | — | — |
| `flutter gen-l10n` | D-11 / D-04 doc parity | ✓ | — | None needed — no ARB changes |
| `flutter analyze` | All commits | ✓ | — | — |
| `flutter test` | All test verification | ✓ | — | — |
| Physical iOS device (≥iPhone 12) | D-03 device UATs | UNKNOWN (depends on user) | — | If absent, defer device UAT per Phase 11/13/17 precedent (accept as documentation-grade debt) |
| Physical Android device (≥Pixel 6) | D-03 device UATs | UNKNOWN | — | Same as iOS |
| `slopcheck` | (RESEARCH protocol) | ✗ | — | N/A — no packages added |
| Context7 MCP | RESEARCH library lookups | ✗ (`ctx7` CLI not available) | — | Used WebFetch + WebSearch fallback for `speech_to_text` plugin docs |

**Missing dependencies with no fallback:** Physical iOS/Android devices for D-03 — per CONTEXT.md `<specifics>` "Device UAT plan accepts deferral", the phase still passes if the device session ran and produced a result (pass / accepted-with-debt). No hard blocker.

**Missing dependencies with fallback:** `ctx7` CLI / Context7 MCP — fell back to WebFetch + WebSearch and got sufficient docs from pub.dev + GitHub source code links. The plugin docs are silent on intra-session `notListening` semantics but the constant docstrings + changelog entries provide enough signal (see A1, A2 in Assumptions Log).

---

## Validation Architecture

> nyquist_validation is enabled (`.planning/config.json` line: `"nyquist_validation": true`).

### Test Framework

| Property | Value |
|----------|-------|
| Framework | `flutter_test` (SDK) + `mocktail` (project-pinned) |
| Config file | none (Flutter defaults; project lints via `analysis_options.yaml` at repo root) |
| Quick run command | `flutter test test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart -j 1` (≈30 s) |
| Full suite command | `flutter test` (≈3-5 min on typical machine) |

### Phase Requirements → Test Map

> Phase 23 has no `phase_req_ids` — the requirements list here maps D-NN decisions to concrete test cases.

| Decision | Behavior | Test Type | Automated Command | File Exists? |
|----------|----------|-----------|-------------------|-------------|
| D-05 intra-session guard | `_onStatus('notListening')` with `lastFinalAt = now - 100ms` AND `_pressStart != null` → assert `_stopRecordingAndCommit` NOT called | unit (mixin in isolation) | `flutter test test/unit/features/accounting/presentation/voice_recognition_event_handler_mixin_test.dart` | ❌ Wave 0 (new file) |
| D-05 intra-session guard | Same with `lastFinalAt = now - 2000ms` → assert commit path fires | unit | same as above | ❌ Wave 0 |
| D-07 cold-start gate | Mount screen with `voiceLocaleIdProvider` overridden to `AsyncValue.loading()`, simulate long-press → assert `_startRecording` NOT called | widget | `flutter test test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart --plain-name "D-07"` | ⚠️ Extend existing file |
| D-07 cold-start gate | Resolve provider → second long-press → asserts commit path fires | widget | same | ⚠️ Extend existing file |
| D-08 popUntil deferral | Simulate soul-ledger save → assert `SoulCelebrationOverlay` is in tree AND `Navigator` route NOT popped; trigger `onDismissed` → assert pop fires | widget | `flutter test test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart --plain-name "D-08"` | ⚠️ Extend existing file |
| D-08 popUntil deferral | Survival-ledger save → assert pop fires immediately (no overlay) | widget | same | ⚠️ Extend existing file |
| D-09 listener removal | Pump form, dispose → assert `FocusNode.hasListeners == false` post-dispose | widget | `flutter test test/widget/features/accounting/presentation/widgets/transaction_details_form_test.dart --plain-name "WR-07"` | ⚠️ Extend existing file (fix WR-07 sites) |
| D-10 mixin extraction | Existing G-01 + G-02 widget tests continue passing | widget | `flutter test test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart` | ✅ |
| D-10 mixin extraction | Per-mixin unit test that exercises the abstract contract in isolation | unit | `flutter test test/unit/features/accounting/presentation/voice_recognition_event_handler_mixin_test.dart` | ❌ Wave 0 (new file) |
| D-11 G-02 localized assert | Existing permanent test passes with new `expect(find.text(l10n.voiceRecognitionErrorAudio), findsOneWidget)` | widget | `flutter test test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart --plain-name "G-02 permanent"` | ✅ (line 946-1004; extend) |
| D-12 IN-01 epoch | DAO + DefaultVoiceSynonyms use identical `kVoiceSynonymSeedEpoch` value | unit | `flutter test test/unit/shared/constants/default_synonyms_test.dart` (or extend existing) | ⚠️ May need new file |
| D-12 IN-05 overrides | Architecture test still passes after constant moved | architecture | `flutter test test/architecture/category_other_l2_invariant_test.dart` | ✅ |
| D-13 substring guard | `findMerchant('a')` → null; `findMerchant('ab')` → null; `findMerchant('mac')` → McDonald | unit | `flutter test test/unit/infrastructure/ml/merchant_database_test.dart --plain-name "D-13 substring guard"` | ✅ (extend) |
| D-13 substring guard | No entry has `name.length < 3` (regression for Pitfall 7) | unit | same | ❌ Wave 0 |
| D-14 SeedAllUseCase ordering | Mock seeds record completion + start timestamps; assert categories complete before synonyms start | unit | `flutter test test/unit/application/seed/seed_all_use_case_test.dart` | ❌ Wave 0 (new file) |
| D-15 `その他` corpus | zh `"其他"` → resolves to `cat_other_other` | integration | `flutter test test/integration/voice/voice_corpus_zh_test.dart --plain-name "D-15"` | ⚠️ Extend existing (or add to voice_category_corpus_zh_test.dart) |
| D-15 `その他` corpus | ja `"その他"` → `cat_other_other` | integration | `flutter test test/integration/voice/voice_corpus_ja_test.dart --plain-name "D-15"` | ⚠️ Extend existing |
| D-15 `other` en hedge | en `"other"` → `cat_other_other` | integration | `flutter test test/integration/voice/voice_corpus_en_test.dart` | ❌ Wave 0 (NEW file) |

### Sampling Rate

- **Per task commit:** `flutter test test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart -j 1` (and the specific file for the task being committed)
- **Per wave merge:** `flutter test` (full suite) + `flutter analyze`
- **Phase gate:** Full suite green before `/gsd:verify-work`; D-03 device UATs documented in 23-HUMAN-UAT.md

### Wave 0 Gaps

- [ ] `test/unit/features/accounting/presentation/voice_recognition_event_handler_mixin_test.dart` — covers D-05 + D-10 abstract contract
- [ ] `test/unit/application/seed/seed_all_use_case_test.dart` — covers D-14 ordering
- [ ] `test/integration/voice/voice_corpus_en_test.dart` — covers D-15 en hedge
- [ ] `test/unit/shared/constants/default_synonyms_test.dart` (or extend) — covers D-12 IN-01 epoch parity
- [ ] D-13 length-precondition regression test (extend `merchant_database_test.dart`)
- [ ] D-09 closure-hoist fix at `transaction_details_form_test.dart:910-911, 1056-1057` (modify existing)

Framework install: not needed — flutter_test + mocktail already in project.

---

## Security Domain

> `security_enforcement` is not explicitly disabled in config; treat as enabled per default.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Phase 23 touches no auth surface |
| V3 Session Management | no | No session work |
| V4 Access Control | no | No access control changes |
| V5 Input Validation | yes (minor) | D-13 length guard is a defensive input-validation tightening. D-15 seed inputs are constants — not user input. |
| V6 Cryptography | no | NO crypto changes; SQLCipher / KeyManager untouched |
| V8 Data Protection | no | No PII handling changes |
| V12 Files & Resources | no | No file I/O changes |

### Known Threat Patterns for Flutter / Riverpod / Drift stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Voice transcript injection into form fields | Tampering | Already mitigated: form's `submit()` reads from Drift use case, no string interpolation into SQL (Drift companions are parameterized). Phase 23 doesn't alter this. |
| Permanent error gate bypass | Spoofing (mic-state) | Phase 22 G-02 already sets `_isInitialized = false` on permanent error; D-10 mixin extraction preserves the same semantic via the abstract setter (Pitfall 2). |
| Listener leak post-dispose (D-09) | Memory exhaustion DoS | D-09 hoist + regression test ensures dispose cleans up. Mitigation is the fix itself. |
| Locale-flip race exploit (D-07) | Tampering (wrong-locale parsing) | D-07 cold-start gate prevents the recognizer from running with the wrong locale during the first ms after boot. |

**Phase 23 SECURITY.md scope:** A new SECURITY.md should be produced confirming D-07 closes the locale-flip race (low-severity but real) and confirming D-10 mixin extraction preserves the Phase 22 G-02 permanent-error gate (no regression).

---

## Sources

### Primary (HIGH confidence)
- `lib/features/accounting/presentation/screens/voice_input_screen.dart` (full file read, 832 LOC) — gesture handlers, `_onStatus`/`_onError` bodies, mixin extraction targets, line refs verified
- `lib/application/voice/voice_chunk_merger.dart` (full file read, 202 LOC) — `_lastFinalAt` field at line 55, `feedChunk` semantics, no public last-final accessor (D-05 needs to add one)
- `lib/shared/constants/default_synonyms.dart` (full file read, 118 LOC) — `_epoch` at line 26, seed list pattern for D-15
- `lib/data/daos/category_keyword_preference_dao.dart` (full file read, 146 LOC) — `_epoch` at line 90, `insertSeedBatch` INSERT OR IGNORE at line 101
- `lib/application/voice/voice_category_resolver.dart` (full file read, 146 LOC) — `_otherIdOverrides` at line 33
- `lib/infrastructure/ml/merchant_database.dart` (partial read, substring pass at lines 130-165) — D-13 target
- `lib/main.dart` (full file read) — seed call ordering at lines 108-114
- `lib/infrastructure/speech/speech_recognition_service.dart` (full file read) — `initialize` signature at line 35, `restartListen` semantics at line 104
- `lib/features/settings/presentation/providers/state_settings.dart` + `utils/voice_locale_helpers.dart` — `voiceLocaleIdProvider` chain
- `lib/features/dual_ledger/presentation/widgets/soul_celebration_overlay.dart` (full file read) — `onDismissed` callback at line 12, `_controller.addStatusListener` at line 57
- `lib/features/accounting/presentation/widgets/transaction_details_form.dart` (relevant ranges 330-450, 720-754) — celebration mount at 742-749
- `test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart` (1006 LOC; relevant ranges 300-400, 940-1004) — G-02 permanent test at 946-1004
- `test/architecture/category_other_l2_invariant_test.dart` — `_otherIdOverrides` at line 35
- `.planning/REQUIREMENTS.md` — checkbox states and traceability table verified by grep
- `.planning/milestones/v1.3-MILESTONE-AUDIT.md` — `partial_requirements[]` + `tech_debt[]` definitive list
- `.planning/phases/22-voice-one-step-integration-record-button-ux/22-{CONTEXT,REVIEW,VERIFICATION,HUMAN-UAT}.md` — all read in full
- `.planning/phases/21-voice-category-resolver-level-2-enforcement/21-{CONTEXT,REVIEW}.md` — all read in full
- `.planning/phases/19-manual-one-step-keypad-polish/19-HUMAN-UAT.md` — read in full
- `.planning/phases/20-voice-number-parser-zh-ja/20-08-SUMMARY.md` (partial) — 8 anchor cases verified
- `.planning/phases/23-v1-3-cleanup-scanner-allow-lists-voice-flow-polish/23-CONTEXT.md` — read in full
- `pubspec.yaml:41` — `speech_to_text: ^7.0.0` pinned
- `.planning/config.json` — `nyquist_validation: true` verified

### Secondary (MEDIUM confidence)
- `https://pub.dev/documentation/speech_to_text/latest/speech_to_text/SpeechToText/notListeningStatus-constant.html` — constant declaration verified; no docstring
- `https://pub.dev/packages/speech_to_text/changelog` v5.0.0 "onStatus now receives the new done status after all listening is complete" — confirms `done` is canonically terminal
- `https://github.com/csdcorp/speech_to_text/blob/main/speech_to_text/lib/speech_to_text.dart` constant declarations — `listeningStatus`, `notListeningStatus`, `doneStatus`, internal `_doneNoResultStatus`
- `https://pub.dev/packages/speech_to_text` — Android pause auto-stop varies by device/OS version, ~5 s typical
- `https://github.com/csdcorp/speech_to_text/issues/253` — community discussion of continuous listening recovery (no direct intra-session `notListening` confirmation)

### Tertiary (LOW confidence — ASSUMED)
- iOS partial-result cadence ~100-300 ms (no upstream documentation; community knowledge; assumption A4)
- Whether real-world Android devices emit intra-session `notListening` between recognition chunks (assumption A1, anchored on WR-NEW-01 bug report from 22-REVIEW.md but not on upstream docs)
- 800 ms threshold ceiling correctness (A2 — design decision pending device UAT confirmation)

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — every line ref verified in local repo
- Architecture patterns: HIGH for D-07/D-08/D-12-D-15 (verified codebase precedents); MEDIUM for D-10 (no in-house mixin precedent; pattern is standard Flutter idiom)
- Pitfalls: HIGH — most pitfalls are verifiable from code inspection; Pitfall 1 is the only one anchored on an `[ASSUMED]` upstream behavior
- D-05 threshold value: LOW — `[ASSUMED]` against upstream plugin behavior; tuning lever exposed for device-UAT-driven revision

**Research date:** 2026-05-25
**Valid until:** 2026-06-25 (30 days — stable codebase, no anticipated `speech_to_text` upstream changes that affect Phase 23 scope)
