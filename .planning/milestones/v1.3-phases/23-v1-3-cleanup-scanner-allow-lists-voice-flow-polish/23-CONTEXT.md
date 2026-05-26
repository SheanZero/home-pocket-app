# Phase 23: v1.3 cleanup — scanner allow-lists + voice flow polish - Context

**Gathered:** 2026-05-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 23 closes the v1.3 milestone by absorbing carried tech-debt before `/gsd:complete-milestone v1.3`. It is a **cleanup-only** phase — no new user-visible capabilities; new capabilities go to v1.4+.

**In scope:**
- Voice-flow polish in `voice_input_screen.dart` — selective fixes (NOT a commit-path rewrite)
  - WR-NEW-01 (`_onStatus` intra-session `notListening` premature commit risk)
  - WR-01 (`voiceLocaleId` cold-start race), WR-04 (popUntil pre-`SoulCelebrationOverlay`), WR-07 (listener leak via distinct closures)
  - IN-02 (832-line screen — extract `_onStatus`/`_onError` to mixin)
  - IN-03 (G-02 permanent test: assert localized `error_audio` string)
- Phase 21 polish — five of six IN items (IN-01+05 constant dedup, IN-03 substring guard, IN-04 seed-order via `SeedAllUseCase`, IN-06 expanded `その他/其他/other` seed + corpus)
- Documentation reconciliation — REQUIREMENTS.md 10 checkbox flips + 7 SUMMARY frontmatter backfills
- Carried human UATs — Phase 19 (keypad-feel + 6-golden), Phase 20 (VOICE-02 8-anchor), Phase 22 (4 device UATs incl. `notListening` intermediate behavior)

**Out of scope (deferred to v1.4+):**
- Commit-path mutation (`_stopRecordingAndCommit`, `_parseResult` lifecycle, `_onError` flag suppression) — WR-NEW-02/03 deferred
- Cosmetic voice items: WR-02 vacuous null, WR-03 microtask race, WR-06 mocktail stub override, IN-01 retry affordance
- Phase 21 IN-02 (`CategoryKeywordPreference` SeedSpec signature change) — defers to v1.4+
- VALIDATION.md retrofits for phases 18/19/20/21/22 (Nyquist) — accept as documentation-grade debt at v1.3 close per Phase 11/13/17 precedent
- All v1.2/v1.3 deferred items remain v1.4+ (FAMILY-V2, MOD-005 OCR writer, FUTURE-DOC-01..06, fl_chart 1.x)

**Scanner allow-lists** (per phase title): **already cleared** in Phase 21 commits `117be50` (corpus-test allow-list) and `a570dfc` (`default_synonyms.dart` allow-list). Phase 23 does **not** re-do this work. The ROADMAP title is kept as-is for historical record.

</domain>

<decisions>
## Implementation Decisions

### Scope & Phase Identity

- **D-01 [informational]:** Intent is **full voice-flow polish** — Phase 22 voice items (selective per below) + Phase 21 IN-01..06 (selective per below). Cleanup-only; no new capabilities. *Framing decision; honored implicitly by the absence of any new-capability tasks across all plans.*
- **D-02 [informational]:** Keep ROADMAP.md Phase 23 title verbatim (`v1.3 cleanup: scanner allow-lists + voice flow polish`). Scanner allow-lists already cleared in Phase 21 (`117be50` + `a570dfc`). CONTEXT.md is the canonical scope record. *Framing decision; no plan modifies the title.*
- **D-03:** Fold ALL carried human UATs into Phase 23:
  - Phase 19 — keypad-feel + 6-golden visual baseline
  - Phase 20 — VOICE-02-DEVICE-VERIFY 8-anchor (zh: 2204 continuous, 1840 intra-pause merge, 1800 false-merge regression; ja: にせんにひゃくよん→2204, せんはっぴゃく+よんじゅう円→1840, 一万二千→12000; sanity: record button stays lit + ManualOneStepScreen carries initialAmount)
  - Phase 22 — 4 device UATs: physical-touch <100ms latency, real-world ja/zh recognizer accuracy, idle-state golden anti-aliasing parity, `_onStatus('notListening')` intermediate behavior on iOS+Android
- **D-04:** Documentation reconciliation is **in Phase 23 scope** (not split to a `/gsd-quick`). Flip REQUIREMENTS.md `[ ]` → `[x]` for INPUT-03, INPUT-04, EDIT-01, EDIT-02, VOICE-01..06 (10 rows); update REQUIREMENTS.md traceability table rows 110-117 + 120-121 `Pending` → `Complete`; backfill `requirements-completed` frontmatter for Phase 18 SUMMARY 18-02/04/06/07/08 and Phase 19 SUMMARY 19-03/05.

### Voice Flow Polish — `voice_input_screen.dart` (832 LOC)

- **D-05 (WR-NEW-01):** Keep both `status == 'done' || status == 'notListening'` in `_onStatus` G-01 predicate. Add an **intra-session heuristic guard**: peek the merger's last-partial-result timestamp (`_amountMerger.lastPartialAt` or equivalent — researcher to confirm `VoiceChunkMerger` exposes this; if not, add the accessor). If elapsed-since-last-partial < N ms, treat `notListening` as intra-session (skip commit, allow recognizer to restart). Else proceed with commit. The N threshold is anchored to `speech_to_text` plugin partial-result cadence — researcher determines exact value (typical iOS partial cadence: ~100-300 ms; pick a conservative ceiling like 800 ms with documented rationale).
- **D-06 (WR-NEW-02 + WR-NEW-03):** **DEFERRED to v1.4+.** Phase 23 does NOT touch the commit path (`_stopRecordingAndCommit`, `_parseResult` mutation, `_onError` flag-suppression). The commit path was just stabilized in Phase 22 via G-01 + G-02 gap closures (plans 22-08/09/10) — further rewrites here would re-risk that work. The carried Phase 22 device UAT covers the user-observable risk.
- **D-07 (WR-01):** `voiceLocaleId` cold-start race fix — await `voiceLocaleIdProvider` resolution in `initState` (or in `_initSpeechService`) before allowing the first `_onLongPressStart` to enter `_startRecording`. Concrete shape: gate `_isInitialized = true` on **both** `appSpeechRecognitionServiceProvider.initialize()` success AND `voiceLocaleIdProvider` having a non-null value. Researcher to confirm `voiceLocaleIdProvider` resolution path (likely `SharedPreferences.getString('voice_locale_id')` → fallback device locale).
- **D-08 (WR-04):** Defer `Navigator.popUntil` in `_onSavePressed` for soul-ledger success path. Concrete shape: when the saved transaction is soul-ledger, pass an `onCompleted` callback to `SoulCelebrationOverlay.show(...)` that triggers the pop; for survival-ledger, keep the immediate pop. Test: widget test pumps a soul-ledger save, asserts `SoulCelebrationOverlay` is in the tree, then asserts pop happens only after overlay's onCompleted fires.
- **D-09 (WR-07):** Hoist `addListener`/`removeListener` arguments to a named local function (or stored `VoidCallback` field) so the same closure reference is used for both. Mechanical, pure safety. Verify with the existing widget tests + add a leak test if one doesn't exist.
- **D-10 (IN-02):** Extract `_onStatus` + `_onError` (~50 LOC together) into a new `VoiceRecognitionEventHandlerMixin` on `_VoiceInputScreenState`. Gesture handlers (`_onLongPressStart` / `_onLongPressEnd` / `_onLongPressCancel`) stay in the screen — they read screen-local state heavily (`_pressStart`, `_isRecording`, `_amountMerger`). After extraction, `voice_input_screen.dart` should drop below the 800-line cap.
- **D-11 (IN-03):** G-02 permanent test in `voice_input_screen_test.dart:946-1004` adds `expect(find.text(l10n.voiceRecognitionErrorAudio), findsOneWidget)` alongside the existing SoftToast presence assertion. Test-only change; cheap.

### Phase 21 Polish — voice category resolver / merchant DB / seed

- **D-12 (IN-01 + IN-05 — constant dedup):**
  - IN-01: Extract `_epoch` from `lib/shared/constants/default_synonyms.dart:26` as a public `static final DateTime kVoiceSynonymSeedEpoch`; import it in `lib/data/daos/category_keyword_preference_dao.dart` (currently line 90).
  - IN-05: Move `_otherIdOverrides` map from `lib/application/voice/voice_category_resolver.dart:24-26` AND `test/architecture/category_other_l2_invariant_test.dart:35-37` to a new `lib/shared/constants/category_other_id_overrides.dart`. Both resolver and architecture test import from the new location.
- **D-13 (IN-03 — substring length guard):** Add `if (lowerQuery.length < 3) return null;` to `MerchantDatabase.findMerchant` substring pass (`lib/infrastructure/ml/merchant_database.dart:150-162`). Single-letter / two-character queries skip substring matching to avoid false-positive miscategorization (e.g., `'a'` matching `'amazon'`). Exact-match pass (steps 1+2) is unaffected. Add a unit test asserting `'a'` returns null and `'mac'` (3 chars) continues to match McDonald's via substring.
- **D-14 (IN-04 — seed order via SeedAllUseCase):** Create `lib/application/seed/seed_all_use_case.dart` that owns both `SeedCategoriesUseCase` + `SeedVoiceSynonymsUseCase` invocations in correct order. `main.dart:108-114` collapses to one `ref.read(seedAllUseCaseProvider).execute()` call. New provider in `lib/application/seed/seed_providers.dart`. Eliminates ordering-by-comment. Add a unit test asserting categories complete before synonyms start (mock observer pattern).
- **D-15 (IN-06 — expand `その他` / `其他` / `other` seed):** Add three seed rows to `DefaultVoiceSynonyms.all` in `lib/shared/constants/default_synonyms.dart`: `_seed('その他', 'cat_other_expense')`, `_seed('其他', 'cat_other_expense')`, `_seed('other', 'cat_other_expense')`. Then add corresponding corpus cases in `test/integration/voice/voice_corpus_zh_test.dart` + `voice_corpus_ja_test.dart` + (new) `voice_corpus_en_test.dart` skeleton that asserts the override routes to `cat_other_other`. en corpus test is a coverage hedge — voice gating in v1.3 is zh/ja only, but if v1.4 enables en voice the override is already exercised.

### Phase 21 — Deferred (v1.4+)

- **D-16 [informational]:** **IN-02 (`CategoryKeywordPreference` SeedSpec signature change) DEFERRED.** The repo's `insertSeedBatch` parameter-type lie is real but signature changes ripple through callers; risk/effort doesn't justify in a cleanup phase. v1.4+ candidate when a related repo touch happens organically. *Deferral decision; correctly excluded from all Phase 23 plans.*

### Documentation Reconciliation

- **D-17 [informational]:** Phase 23 carries the 10-checkbox + 7-frontmatter reconciliation as a discrete commit (or set of commits) within the phase. Suggested ordering: code-polish first (D-05..D-15), THEN doc reconciliation (D-04 items), THEN device UAT (D-03 items). Doc reconciliation comes after code so the SUMMARY frontmatter accurately reflects what shipped. *Ordering hint; honored by wave assignment — 23-07 (D-04) lands in Wave 4 after all code plans, 23-08 (D-03) lands in Wave 5.*

### Claude's Discretion

- **D-18:** Plan ordering within Phase 23 — Claude decides plan count and dependency graph during `/gsd:plan-phase 23`. Likely buckets: (a) Phase 21 mechanical fixes (D-12+D-13+D-14+D-15) parallel-safe; (b) Voice-flow surgical fixes (D-07+D-09+D-11) parallel-safe; (c) IN-02 extraction (D-10) before WR-NEW-01 guard (D-05) so the guard lands in the new mixin; (d) WR-04 (D-08) independent; (e) Doc reconciliation (D-04, D-17) standalone; (f) Device UATs (D-03) post-code.
- **D-19:** N threshold for WR-NEW-01 intra-session guard — researcher to anchor against `speech_to_text` plugin partial-result cadence. Recommended ceiling 800 ms (≈3× typical iOS partial cadence) but Claude may adjust based on plugin docs. Document rationale inline.
- **D-20:** Test strategy across the bundle — Claude decides whether each fix gets a dedicated test file or whether existing test files grow (e.g., `voice_input_screen_test.dart` already 1000+ LOC). Default: extend existing files unless the new test bucket has natural file boundary.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### v1.3 audit + scope source
- `.planning/milestones/v1.3-MILESTONE-AUDIT.md` — authoritative tech-debt inventory; tech-debt classification + recommendations (the "Optional follow-up" #7 is what Phase 23 absorbs).
- `.planning/REQUIREMENTS.md` — v1.3 requirements + traceability table; the 10 stale checkbox rows live at lines 107-121 (D-04 target).
- `.planning/ROADMAP.md` §"Phase 23" line 184 — phase title kept verbatim.
- `.planning/STATE.md` — milestone status (`completed`), strikethrough scanner-cleared notice at line 91 (`f04b978`).

### Phase 22 — voice integration (primary surface for Phase 23 polish)
- `.planning/phases/22-voice-one-step-integration-record-button-ux/22-VERIFICATION.md` — `follow_up_recommendations` lists WR-01..07 + WR-NEW-01..03 + IN-01..03 with line refs.
- `.planning/phases/22-voice-one-step-integration-record-button-ux/22-REVIEW.md` — initial review + post-closure re-review producing WR-NEW-01..03.
- `.planning/phases/22-voice-one-step-integration-record-button-ux/22-HUMAN-UAT.md` — 4 carried device UAT items (Test #1 latency, #2 recognizer accuracy, #3 idle golden, #4 `notListening` intra-session).
- `.planning/phases/22-voice-one-step-integration-record-button-ux/22-SECURITY.md` — security threat verification baseline; Phase 23 changes must not regress.
- `.planning/phases/22-voice-one-step-integration-record-button-ux/22-CONTEXT.md` — Phase 22 D-03 hold-to-record + D-04 mic shape morph (preserve invariants in Phase 23 polish).
- `lib/features/accounting/presentation/screens/voice_input_screen.dart` — 832 LOC; `_onStatus` 172-196, `_onError` 198-220, `_onLongPressStart/End/Cancel` 243-269, `_onSavePressed` (search for popUntil).
- `lib/features/accounting/presentation/widgets/voice_error_toast.dart` — G-02 ARB-backed toast helper (`showVoiceRecognitionErrorToast`).
- `test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart:946-1004` — G-02 permanent test (D-11 target).

### Phase 21 — voice category resolver (Phase 23 polish target)
- `.planning/phases/21-voice-category-resolver-level-2-enforcement/21-REVIEW.md` §IN-01..06 (lines 300-388) — IN-01 epoch dup, IN-02 SeedSpec (DEFERRED per D-16), IN-03 substring guard, IN-04 seed order, IN-05 _otherIdOverrides dup, IN-06 missing `その他` seed.
- `.planning/phases/21-voice-category-resolver-level-2-enforcement/21-CONTEXT.md` — Phase 21 always-L2 contract + `_ensureL2` 3-stage fallback (must preserve).
- `lib/shared/constants/default_synonyms.dart:26` — `_epoch` constant (D-12 source).
- `lib/data/daos/category_keyword_preference_dao.dart:90` — `_epoch` constant (D-12 target).
- `lib/application/voice/voice_category_resolver.dart:24-26` — `_otherIdOverrides` map (D-12 source).
- `test/architecture/category_other_l2_invariant_test.dart:35-37` — `_otherIdOverrides` dup (D-12 target).
- `lib/infrastructure/ml/merchant_database.dart:150-162` — substring match (D-13 target).
- `lib/main.dart:108-114` — seed ordering (D-14 collapse target).

### Phase 20 — voice number parser (carried VOICE-02 device UAT)
- `.planning/phases/20-voice-number-parser-zh-ja/20-08-SUMMARY.md` — 8 anchor cases + tuning levers (`_windowDuration`, `restartListen`, lexical-gate normalize) if device UAT cases fail.
- `lib/infrastructure/voice/voice_chunk_merger.dart` — `VoiceChunkMerger` API (D-05 may need to add `lastPartialAt` accessor if not already public).

### Phase 18 + 19 — doc reconciliation targets
- `.planning/phases/18-shared-details-form-foundation/18-02-SUMMARY.md` through `18-08-SUMMARY.md` — backfill `requirements-completed` frontmatter for INPUT-03 / INPUT-04 / EDIT-01 / EDIT-02 per audit (D-04).
- `.planning/phases/19-manual-one-step-keypad-polish/19-03-SUMMARY.md` + `19-05-SUMMARY.md` — backfill INPUT-01 frontmatter (D-04).

### Project standards
- `CLAUDE.md` — 800-line file cap (D-10 IN-02 target); architecture invariants; intl/sqlcipher pins; Riverpod 3 conventions.
- `docs/arch/01-core-architecture/ARCH-001_Complete_Guide.md` — 5-layer architecture (no application/ inside features/); Phase 23 fixes must respect.
- `docs/arch/01-core-architecture/ARCH-004_State_Management.md` — Riverpod 3 patterns; D-07 cold-start race fix must use `ref.listen` pattern not `ref.watch` for side effects.

### Closed Phase 22 gap context (do NOT undo)
- Phase 22 plans 22-08 / 22-09 / 22-10 SUMMARY files — G-01 `_onStatus` self-termination + G-02 error surface + permanent-error mic gate. Phase 23 polish must not regress these closures. The D-05 intra-session guard is **additive** to the existing G-01 predicate.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`SoftToast`** (`lib/shared/widgets/soft_toast.dart`) + **`showVoiceRecognitionErrorToast`** (`voice_error_toast.dart`) — existing G-02 plumbing; D-11 test extension uses them as-is.
- **`VoiceChunkMerger`** (`lib/infrastructure/voice/voice_chunk_merger.dart`) — owns partial-result timing; D-05 intra-session guard reads its last-partial timestamp. May need to expose `lastPartialAt` getter if not already public.
- **`voiceLocaleIdProvider`** + **`currentLocaleProvider`** — D-07 cold-start race fix uses these directly.
- **`SoulCelebrationOverlay`** — D-08 popUntil deferral wires its `onCompleted` callback.
- **`appSpeechRecognitionServiceProvider`** — D-07 initialization sequencing target.
- **`SeedCategoriesUseCase`** + **`SeedVoiceSynonymsUseCase`** — D-14 wraps both behind `SeedAllUseCase`.
- **`MerchantDatabase`** — D-13 substring guard; existing tests at `test/unit/infrastructure/ml/merchant_database_test.dart`.

### Established Patterns
- **Mixin-on-State for cross-cutting handlers** — Flutter idiom; D-10 follows pattern in (look for existing mixins under `lib/features/.../presentation/`).
- **Constant export from `lib/shared/constants/`** — D-12 pattern matches `default_synonyms.dart`, `app_routes.dart`, etc.
- **Use-case wrapper composes other use cases** — D-14 SeedAllUseCase pattern; Riverpod use-case wrappers across `lib/application/` (look for examples in `lib/application/accounting/` use cases).
- **Min-length guard before substring** — D-13 mirrors existing input-validation pattern in keyboard handling.
- **Provider-aware initState** — D-07 pattern: read provider in initState, listen for value, then `setState` to enable UI. Avoid `ref.watch` in initState (Riverpod 3 rejects).
- **`ref.listen` for side effects** — Riverpod 3 rule (per CLAUDE.md); D-07 + D-08 must follow.

### Integration Points
- **`voice_input_screen.dart` ↔ `VoiceRecognitionEventHandlerMixin` (NEW)** — D-10 extraction boundary. State class continues to mix-in; gesture handlers remain in main class.
- **`main.dart:108-114` ↔ `seedAllUseCaseProvider` (NEW)** — D-14 single-call replacement.
- **`category_other_id_overrides.dart` (NEW) ↔ resolver + architecture test** — D-12 single source of truth.
- **`DefaultVoiceSynonyms.all` (extended) ↔ voice corpus tests (zh/ja/new en)** — D-15 seed-to-corpus chain.
- **REQUIREMENTS.md ↔ SUMMARY frontmatter (Phase 18/19)** — D-04 cross-file consistency.

</code_context>

<specifics>
## Specific Ideas

Downstream agents MUST honor these specifics verbatim:

- **Commit-path is OFF LIMITS in Phase 23.** Do NOT modify `_stopRecordingAndCommit`, `_parseResult` lifecycle, or `_onError`'s flag-suppression. WR-NEW-02/03 are explicitly deferred to v1.4+. The intra-session guard (D-05) adds a peek-only read of the merger's timing state — it does NOT mutate commit logic, does NOT change the predicate's commit-path invocation, and does NOT alter `_onError`. If the guard rejects a `notListening` event, the existing recognizer-self-restart behavior (already in place) handles continuation.
- **Phase 22 D-03 (hold-to-record) + D-04 (mic shape morph) are inviolable.** Phase 23 polish must not weaken these. WR-04 (D-08) defers the pop but does NOT alter the hold/release gesture model. IN-02 extraction (D-10) moves `_onStatus`/`_onError` only — gesture handlers stay in the main screen class.
- **Phase 22 G-01 + G-02 gap closures are inviolable.** Phase 23 changes are additive (D-05 adds a guard within G-01; D-11 adds a localized-string assertion to G-02's test). The 4 ARB error keys (`voiceRecognitionErrorNetwork/NoMatch/Audio/Unknown`) remain. `showVoiceRecognitionErrorToast` remains the sole error UI surface.
- **Phase 21 `_ensureL2` always-L2 contract is inviolable.** D-12..D-15 (Phase 21 polish) do not touch the resolver's 3-stage fallback (override → convention → findByParent.first). D-15 expands seed coverage; the override path itself is unchanged.
- **No new schema migration.** Phase 23 stays on Drift schema v17. Any seed change (D-15) writes through existing `category_keyword_preferences` table.
- **No new ARB keys for code-polish work.** D-15 corpus tests assert resolver routing, not UI strings. D-11 reuses existing `voiceRecognitionErrorAudio` ARB key.
- **WR-NEW-01 N-threshold default ceiling: 800 ms** (≈3× typical iOS partial cadence). Researcher may revise based on `speech_to_text` plugin docs; document inline rationale.
- **Device UAT plan accepts deferral** — if Phase 23 device session reveals a hard regression (e.g., WR-NEW-01 guard still allows premature commit on Android), the regression itself can be re-deferred to v1.4 per Phase 11/13/17 precedent. The phase passes if (a) code polish lands, (b) doc reconciliation lands, (c) device session ran and produced a result (pass / accepted-with-debt).
- **`other` corpus test (D-15)** — if no en voice corpus file exists at `test/integration/voice/voice_corpus_en_test.dart`, create a skeleton with just the one `その他/他/etc.` override case. Do NOT expand en corpus coverage beyond this one case — v1.4+ owns full en voice.

Anchor scenarios that downstream agents MUST encode as named `test()` blocks:

- **D-05 intra-session guard:** `_onStatus('notListening')` with `lastPartialAt = now - 100ms` AND `_pressStart != null` → assert `_stopRecordingAndCommit` NOT called, `_pressStart` unchanged, `_isRecording` unchanged. With `lastPartialAt = now - 2000ms` → assert commit path fires as today.
- **D-07 cold-start guard:** Mount screen with `voiceLocaleIdProvider` overridden to pending (AsyncValue.loading), simulate immediate long-press → assert `_startRecording` NOT called, no commit. Then resolve provider → second long-press → asserts commit path fires.
- **D-08 popUntil deferral:** Pump voice screen, simulate soul-ledger save → assert `SoulCelebrationOverlay` is in widget tree AND `Navigator` route has not popped. Trigger overlay's `onCompleted` → assert pop fires. Repeat for survival-ledger → assert pop fires immediately (no overlay).
- **D-09 listener removal:** Pump screen, dispose → assert no leaked listener (use `addListener` mock or check `hasListeners == false` post-dispose if `ChangeNotifier`).
- **D-10 mixin extraction:** Existing `voice_input_screen_test.dart` G-01 + G-02 tests continue to pass against the mixed-in handlers. Add a per-mixin unit test if the mixin can be tested in isolation.
- **D-11 G-02 localized assert:** Existing permanent test gets `expect(find.text(l10n.voiceRecognitionErrorAudio), findsOneWidget)` added; assert it before the SoftToast presence assertion (so failure points at the missed string, not the toast).
- **D-13 substring length guard:** `MerchantDatabase.findMerchant('a')` → returns null. `findMerchant('ab')` → returns null. `findMerchant('mac')` → returns McDonald entry (existing behavior preserved). Confirms guard threshold = 3.
- **D-14 SeedAllUseCase ordering:** Mock `SeedCategoriesUseCase.execute` to record completion timestamp; mock `SeedVoiceSynonymsUseCase.execute` to record start timestamp; invoke `SeedAllUseCase.execute()` → assert categories' completion < synonyms' start.
- **D-15 `その他` corpus:** `voice_corpus_zh_test.dart` — utterance `"其他"` → asserts category id resolves to `cat_other_other`. `voice_corpus_ja_test.dart` — utterance `"その他"` → same. `voice_corpus_en_test.dart` (new skeleton) — utterance `"other"` → same.

</specifics>

<deferred>
## Deferred Ideas

### Beyond Phase 23 — v1.4+ candidates

- **WR-NEW-02 (spurious toast post-success)** — `_committedRecently` flag to suppress transient toasts within ~500 ms of successful commit. Defers because Phase 23 does not touch the commit path.
- **WR-NEW-03 (double-parse of final transcript)** — reuse already-populated `_parseResult` in `_stopRecordingAndCommit` instead of re-running `parseVoiceInputUseCase`. Defers for same reason; pure waste + stale-read risk, no user-visible bug.
- **WR-02 (vacuous null check)** — `@Default(5) int estimatedSatisfaction` cannot be null per Freezed contract; the null-check is dead code. Cosmetic.
- **WR-03 (microtask race on `_parseResult`)** — two async pipelines (`_onResult` + the satisfaction estimator branch) both `setState(_parseResult = ...)`. Microtask scheduling is the only ordering guarantee. v1.4+ should pick a single owner.
- **WR-06 (mocktail catch-all stub override)** — test-only; `when(repo.findById(any()))` overrides specific stubs in the same test. Cosmetic test cleanup.
- **IN-01 (toast retry affordance)** — `voice_error_toast.dart` lacks a retry action or grayed-out mic indicator after permanent error. UX polish; v1.4+ when in-screen retry flow is designed.
- **IN-02 Phase 21 (`CategoryKeywordPreference` SeedSpec signature)** — change `insertSeedBatch` parameter to `List<({String keyword, String categoryId})>` instead of full model objects. Surface-area ripple; defers to v1.4+ when a related repo touch lands organically.
- **MOD-005 OCR writer** — `EntrySource.ocr` schema slot ready since Phase 17 D-06; Phase 18 D-12 reserves architectural slot. v1.4+ owns writer.
- **English voice input quality (corpus + synonyms)** — v1.4+ per Phase 22 deferred-ideas. D-15 adds one en corpus skeleton entry as a hedge; full en voice support remains v1.4+.
- **VALIDATION.md (Nyquist) retrofits** for Phase 18 (missing), 19 (draft → compliant), 20 (draft → compliant), 21 (missing), 22 (draft → compliant). Per milestone audit: documentation-grade; pattern matches v1.0 FUTURE-DOC-06 + v1.2 Phase 13/17. Accept at v1.3 close as documentation-grade debt.

### Beyond v1.3 — carried-forward themes (per PROJECT.md)

- **FAMILY-V2-01/02/03 family privacy hardening** — v1.4+ candidate.
- **FUTURE-QA-01 release-readiness smoke tests** — v1 release gate.
- **FUTURE-DOC-01..06 doc drift cleanup** — v1.4+.
- **FUTURE-TOOL-03 coverage threshold review** (currently 70% post-v1.0) — v1.4+.
- **TOOL-V2-01 fl_chart 1.x upgrade** — bundle with future analytics chart work.
- **FUTURE-ARCH-04 `recoverFromSeed()` key-overwrite bug** — security-architecture out of scope per long-term project rule.

### Reviewed Todos (not folded)

`cross_reference_todos` returned no matches for Phase 23 — STATE.md "Pending Todos" section was empty.

</deferred>

---

*Phase: 23-v1-3-cleanup-scanner-allow-lists-voice-flow-polish*
*Context gathered: 2026-05-25*
