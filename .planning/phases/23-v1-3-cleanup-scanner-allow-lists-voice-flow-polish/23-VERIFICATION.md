---
phase: 23-v1-3-cleanup-scanner-allow-lists-voice-flow-polish
verified: 2026-05-25T14:00:00Z
updated: 2026-05-26
status: passed
score: 13/13 must-haves verified
overrides_applied: 0
re_verification:
  previous_status: human_needed
  previous_score: 12/13
  gaps_closed:
    - "D-10 / LOC-cap WARNING: voice_input_screen.dart slimmed 838 → 776 LOC by Plan 23-09 (extracted VoiceLocaleReadinessMixin + 3 pure helpers)"
  gaps_remaining: []
  regressions: []
  soft_recommendations:
    - id: WR-06
      summary: "build-side `_voiceLocaleId = value` reassignment at voice_input_screen.dart:519-522 is now functionally dead (mixin listener with fireImmediately:true is canonical writer)"
      classification: "soft — Flutter build-purity anti-pattern; assignment is benign because mixin listener runs first; functionally equivalent. Not a verification gap; queued for v1.4+ cleanup."
    - id: IN-03
      summary: "VoiceLocaleReadinessMixin.onVoiceLocaleResolved dartdoc lacks 'do not call setState / must be sync' contract notes"
      classification: "info — documentation gap for future maintainers; no correctness impact today."
---

# Phase 23: v1.3 Cleanup — Scanner Allow-Lists + Voice Flow Polish Verification Report

**Phase Goal:** Close v1.3 by absorbing carried tech-debt: Phase 22 voice-flow surgical polish (D-05 intra-session guard, D-07 cold-start race, D-08 popUntil deferral, D-09 listener-leak regression, D-10 mixin extraction, D-11 G-02 localized assert), Phase 21 mechanical polish (D-12 constant dedup, D-13 substring guard, D-14 SeedAllUseCase, D-15 その他/其他/other seed), documentation reconciliation (D-04 REQUIREMENTS.md + 7 SUMMARY frontmatter backfills), and 9 carried device UATs (Phase 19 + 20 + 22). Cleanup-only — no new user-visible capabilities.
**Verified:** 2026-05-25T14:00:00Z
**Re-verified:** 2026-05-26 (after Plan 23-09 gap-closure)
**Status:** passed
**Re-verification:** Yes — after gap closure

---

## Re-verification After Plan 23-09

**Trigger:** The 2026-05-25 verification flagged a single WARNING — `voice_input_screen.dart` at 838 LOC exceeded the CLAUDE.md `<800` line cap. Plan 23-09 was authored specifically to close that gap.

### LOC-Cap Gap: RESOLVED

```
$ wc -l lib/features/accounting/presentation/screens/voice_input_screen.dart
     776 lib/features/accounting/presentation/screens/voice_input_screen.dart
```

**838 → 776 LOC** — under the `<800` cap with **24 lines of headroom**.

**How:** Plan 23-09 extracted two new files (commits `26e2fa8`, `e1dd6c3`):

| New file | LOC | Owns |
|---|---|---|
| `lib/features/accounting/presentation/screens/voice_locale_readiness_mixin.dart` | 99 | D-07 cold-start gate (`_isLocaleReady`, `ref.listenManual` on `voiceLocaleIdProvider`, `dispose` subscription cleanup, abstract `onVoiceLocaleResolved` hook) — `mixin VoiceLocaleReadinessMixin<W extends ConsumerStatefulWidget> on ConsumerState<W>` |
| `lib/features/accounting/presentation/screens/voice_input_screen_helpers.dart` | 73 | 3 pure top-level helpers: `buildVoiceAudioFeatures(...)`, `countVoiceWords(text)`, `extractVoiceKeyword(result)` |

### D-07 Verbatim Preservation Confirmed

The D-07 `ref.listenManual<AsyncValue<String>>(voiceLocaleIdProvider, ...)` block is now owned by the new mixin (lines 67-92), with `fireImmediately: true` preserved and both `AsyncData`+`AsyncError` flipping `_isLocaleReady = true` (graceful degradation per RESEARCH Pitfall 3). The screen's `_onLongPressStart` guard now reads `!isLocaleReady` (mixin getter, line 214) — semantics unchanged.

### Invariant Preservation (grep evidence)

```
$ grep -n "with WidgetsBindingObserver\|VoiceRecognitionEventHandlerMixin\|VoiceLocaleReadinessMixin\|isLocaleReady\|initLocaleReadiness\|onVoiceLocaleResolved\|waitForCelebrationDismissed\|_merchantFocus\.dispose\|_noteFocus\.dispose\|countVoiceWords\|buildVoiceAudioFeatures\|extractVoiceKeyword" lib/features/accounting/presentation/screens/voice_input_screen.dart
 59:        VoiceRecognitionEventHandlerMixin,       # D-10 mixin still in chain
 60:        VoiceLocaleReadinessMixin {              # new D-07 owner mixin
176:    // Phase 23 D-07 (WR-01) cold-start gate — owned by VoiceLocaleReadinessMixin.
177:    initLocaleReadiness();                        # D-07 listener registration
190:    @override void onVoiceLocaleResolved(String localeId) => _voiceLocaleId = localeId;
214:    if (!_isInitialized || !isLocaleReady || _isRecording) return;   # D-07 guard
383:                ?.waitForCelebrationDismissed()   # D-08 popUntil deferral intact
433:      _lastWordCount = countVoiceWords(result.recognizedWords);
491:      final features = buildVoiceAudioFeatures(
530:        ? extractVoiceKeyword(_parseResult!)
771:    _merchantFocus.dispose();                     # D-09 cleanup intact
772:    _noteFocus.dispose();                         # D-09 cleanup intact

$ grep -rn "_isLocaleReady\b" lib/ | grep -v voice_locale_readiness_mixin.dart | wc -l
0                                                    # private flag lives only in new mixin

$ git log --oneline -- lib/features/accounting/presentation/screens/voice_recognition_event_handler_mixin.dart
4cdb301 feat(23-05): add D-05 intra-session guard to VoiceRecognitionEventHandlerMixin.onStatus
ba93454 refactor(23-04): extract _onStatus/_onError into VoiceRecognitionEventHandlerMixin
                                                     # D-05/D-10 mixin file untouched by Plan 23-09
```

**Result:** D-05, D-07, D-08, D-09, D-10, D-11 invariants all preserved post-refactor.

### Plan 23-09 Test Evidence

- Targeted tests: 18/18 voice_input_screen widget tests pass (incl. D-07 cold-start race, D-08 popUntil, D-09 FocusNode cleanup, D-11 G-02 localized assert)
- D-05 mixin tests: 4/4 pass (mixin file untouched)
- Full suite: `+2026 passed, −11 failed`. The 11 failures are the documented pre-existing HomeHeroCard light/ja golden baseline drift (matched verbatim against the prior verification's "Pre-existing Test Suite Notes" section). **Zero new failures.**
- `flutter analyze` on the 3 Phase 23-touched files in Plan 09 → 0 issues.

### Code Review Findings From Wave 6 (23-REVIEW.md)

The wave-6 code review surfaced 1 Warning + 1 Info, neither of which is a verification gap:

| ID | File | Classification | Disposition |
|---|---|---|---|
| **WR-06** | `voice_input_screen.dart:519-522` — `_voiceLocaleId = value` reassignment in `build()` is now dead-by-refactor | **Soft recommendation, not a gap** | The mixin's `ref.listenManual` with `fireImmediately: true` runs synchronously before the first `build()` completes, so the build-side assignment is functionally equivalent (assigns the same value, both paths see the same `AsyncValue`). The mutation in `build()` violates Flutter's build-purity contract but is benign at runtime. Queued for v1.4+ cleanup; explicitly NOT a Phase 23 closure blocker. |
| **IN-03** | `voice_locale_readiness_mixin.dart:52-58` — `onVoiceLocaleResolved` dartdoc lacks "do not call setState / must be sync" contract notes | Info, not a gap | Documentation guidance for future implementers. No correctness bug today (single host implementation is a bare field assignment, no setState involved). |

### Final Status: PASSED

- 13/13 must_haves VERIFIED
- 0 BLOCKERS, 0 unresolved gaps, 0 regressions
- LOC cap satisfied with 24-line headroom
- HUMAN-UAT.md from Plan 23-08 already `status: complete` with 9/9 pass — **no new human verification surface introduced by Plan 23-09**, so re-verification does not re-emit a `human_needed` status

### Updated Must-Haves Table (Truth #15 / D-10 LOC row flipped to PASS)

| # | Truth | Status (initial) | Status (after 23-09) |
|---|-------|------------------|----------------------|
| 1 | D-12 IN-01 kVoiceSynonymSeedEpoch dedup | ✓ VERIFIED | ✓ VERIFIED |
| 2 | D-12 IN-05 kCategoryOtherIdOverrides dedup | ✓ VERIFIED | ✓ VERIFIED |
| 3 | D-13 substring 3-char min-length guard | ✓ VERIFIED | ✓ VERIFIED |
| 4 | D-13 tests (3 cases) | ✓ VERIFIED | ✓ VERIFIED |
| 5 | D-14 SeedAllUseCase ordering contract | ✓ VERIFIED | ✓ VERIFIED |
| 6 | D-14 tests (ordering + short-circuit) | ✓ VERIFIED | ✓ VERIFIED |
| 7 | D-15 その他/其他/other seed coverage | ✓ VERIFIED | ✓ VERIFIED |
| 8 | D-05 intra-session guard | ✓ VERIFIED | ✓ VERIFIED |
| 9 | D-05 + D-09 tests | ✓ VERIFIED | ✓ VERIFIED |
| 10 | D-07 _isLocaleReady gate (now mixin-owned) | ✓ VERIFIED | ✓ VERIFIED |
| 11 | D-08 popUntil deferral on soul-ledger | ✓ VERIFIED | ✓ VERIFIED |
| 12 | D-11 G-02 localized assert | ✓ VERIFIED | ✓ VERIFIED |
| 13 | D-04 doc reconciliation + 7 SUMMARY backfills | ✓ VERIFIED | ✓ VERIFIED |
| 14 | D-03 device UAT 9/9 pass | ✓ VERIFIED | ✓ VERIFIED |
| 15 | **D-10 mixin extraction + screen LOC <800** | ⚠ WARNING (838 LOC) | **✓ VERIFIED (776 LOC)** |

**Score: 13/13 D-decisions verified + LOC cap satisfied.** Status flips from `human_needed` → `passed`.

---

## Step 0: Previous Verification Check

No previous VERIFICATION.md found. Initial verification mode.

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | D-12 IN-01: `kVoiceSynonymSeedEpoch` is the single `DateTime(2026, 1, 1)` source for voice synonym seeding in production code; DAO imports it, no local literal | ✓ VERIFIED | `lib/shared/constants/default_synonyms.dart:9` declares it; `lib/data/daos/category_keyword_preference_dao.dart:3` imports via `show kVoiceSynonymSeedEpoch`; no local literal at line 90. `default_categories.dart` has a separate pre-existing `_epoch` for category seeding — acknowledged as out-of-scope deviation in 23-01-SUMMARY. |
| 2 | D-12 IN-05: `kCategoryOtherIdOverrides` in new `lib/shared/constants/category_other_id_overrides.dart` is the single map source; resolver and architecture test both import it; `_otherIdOverrides` eliminated | ✓ VERIFIED | `category_other_id_overrides.dart` exists; `grep -rn '_otherIdOverrides' lib/ test/` returns 0 matches; `voice_category_resolver.dart:127` and `category_other_l2_invariant_test.dart:61` both use `kCategoryOtherIdOverrides`. |
| 3 | D-13: `MerchantDatabase.findMerchant` returns null for any query with `lowerQuery.length < 3` in the substring pass; exact-match passes unaffected | ✓ VERIFIED | `lib/infrastructure/ml/merchant_database.dart:155` has guard `if (lowerQuery.length < 3) return null;` placed before the substring for-loop; guard does not affect passes 1 and 2. |
| 4 | D-13 tests: `findMerchant('a')` and `findMerchant('ab')` return null; `findMerchant('mac')` still returns McDonald entry; all 12 entry names have length >= 3 | ✓ VERIFIED | `test/unit/infrastructure/ml/merchant_database_test.dart` contains 3 D-13 tests: null for 1-2 char queries, substring match at 3 chars, Pitfall 7 regression for all 12 entry names. |
| 5 | D-14: `SeedAllUseCase` owns ordering contract (categories before synonyms); `main.dart` reads only `seedAllUseCaseProvider`; leaf providers remain public | ✓ VERIFIED | `lib/application/seed/seed_all_use_case.dart` exists with `execute()` awaiting categories first then short-circuiting on failure; `lib/main.dart:107` reads `seedAllUseCaseProvider`; 0 references to leaf seed providers in main.dart; `seed_providers.g.dart` exports `seedAllUseCaseProvider`. |
| 6 | D-14 tests: ordering asserted via mocktail timestamp capture; short-circuit verified via `verifyNever` | ✓ VERIFIED | `test/unit/application/seed/seed_all_use_case_test.dart` contains both `D-14: seeds categories before synonyms` (timestamp capture) and `D-14: synonyms not invoked when categories fails` (verifyNever). |
| 7 | D-15: seed rows for `その他`, `其他`, `other` → `cat_other_expense` present in `DefaultVoiceSynonyms.all`; zh/ja corpus anchor tests + en hedge skeleton pass | ✓ VERIFIED | `lib/shared/constants/default_synonyms.dart:117-119` has all three `_seed()` calls; zh corpus `voice_category_corpus_zh_test.dart` has D-15 group asserting `其他` → `cat_other_other`; ja corpus has D-15 group asserting `その他` → `cat_other_other`; `test/integration/voice/voice_corpus_en_test.dart` exists asserting `'other'` → `cat_other_other`. |
| 8 | D-05: intra-session `notListening` guard active in `VoiceRecognitionEventHandlerMixin.onStatus`; threshold 800ms; `done` bypasses guard; `lastMergerFinalAt` abstract getter wired to `VoiceChunkMerger.lastFinalAt` | ✓ VERIFIED | `voice_recognition_event_handler_mixin.dart:102-108` implements guard: `if (status == 'notListening' && pressStart != null) { final lastFinal = lastMergerFinalAt; if (lastFinal != null && DateTime.now().difference(lastFinal) < intraSessionThreshold) { return; } }`; `voice_chunk_merger.dart:68` has `DateTime? get lastFinalAt`; screen wires `lastMergerFinalAt` → `_amountMerger?.lastFinalAt`. |
| 9 | D-05 tests: 4-case mixin unit test (intra-session block, end-of-session commit, done bypass, null-finals fallback); D-09 FocusNode listener-leak regression test | ✓ VERIFIED | `test/unit/features/accounting/presentation/voice_recognition_event_handler_mixin_test.dart` exists with 4 `D-05` testWidgets blocks; `voice_input_screen_test.dart:1150` has `D-09 (Open Q2 regression): FocusNode listeners cleaned up on dispose`. |
| 10 | D-07: `_isLocaleReady` flag gates `_onLongPressStart`; set via `ref.listenManual` on `voiceLocaleIdProvider` in `_initSpeechService`; guard condition: `!_isInitialized \|\| !_isLocaleReady \|\| _isRecording` | ✓ VERIFIED (re-verified) | After Plan 23-09: D-07 logic moved verbatim into `VoiceLocaleReadinessMixin` (`voice_locale_readiness_mixin.dart`). Host screen reads `isLocaleReady` getter at line 214 (`!_isInitialized || !isLocaleReady || _isRecording`); mixin's `initLocaleReadiness()` invoked at screen line 177. `ref.listenManual<AsyncValue<String>>(voiceLocaleIdProvider, ..., fireImmediately: true)` lives at mixin lines 72-91. Subscription disposed via `_localeSubscription?.close()` at mixin line 96. |
| 11 | D-08: `TransactionDetailsFormState` has `Completer<void>?` completed on `SoulCelebrationOverlay.onDismissed`; `waitForCelebrationDismissed()` exposed; voice screen defers `Navigator.popUntil` for soul-ledger saves until the future resolves; survival-ledger pops immediately | ✓ VERIFIED | `transaction_details_form.dart:78` has `Completer<void>? _celebrationCompleter`; `waitForCelebrationDismissed()` at line 269; soul-celebration dismiss at line 767-769; `voice_input_screen.dart:403-413` branches on `tx.ledgerType == LedgerType.soul` to await `waitForCelebrationDismissed()` before pop vs. immediate pop. |
| 12 | D-11: G-02 permanent test asserts `find.text(l10nForD11.voiceRecognitionErrorAudio)` BEFORE the SoftToast presence assertion | ✓ VERIFIED | `voice_input_screen_test.dart:1094-1108` shows D-11 localized string assertion on line 1100 precedes `find.byType(SoftToast)` assertion on line 1108. |
| 13 | D-04 documentation reconciliation: REQUIREMENTS.md has 15/15 Complete, 0 Pending; 7 Phase 18/19 SUMMARY frontmatter files have `requirements-completed:` keys | ✓ VERIFIED | REQUIREMENTS.md: `grep "| Complete |"` returns 15; `grep "| Pending |"` returns 0. All 7 files confirmed: 18-02 `[EDIT-02]`, 18-04 `[INPUT-03]`, 18-06 `[INPUT-04]`, 18-07 `[EDIT-01]`, 18-08 `[INPUT-03, EDIT-02]`, 19-03 `[INPUT-01]`, 19-05 `[INPUT-01]`. |
| 14 | D-03 device UAT: 23-HUMAN-UAT.md has `status: complete` with 9/9 pass | ✓ VERIFIED | `23-HUMAN-UAT.md` frontmatter: `status: complete`; summary: `total: 9, passed: 9, accepted-with-debt: 0, issues: 0`. All 9 items (22-T1/T2/T3/T4, 20-T1/T2/T3, 19-T1/T2) pass. |
| 15 | D-10: `VoiceRecognitionEventHandlerMixin` extraction achieved; `_onStatus`/`_onError` moved to mixin; `voice_input_screen.dart` under CLAUDE.md 800-line cap | ✓ VERIFIED (re-verified) | After Plan 23-09 slim-down: screen is **776 LOC** (24-line headroom). Mixin extraction structurally complete (mixin exists, screen mixes it in, handlers extracted); D-05/D-10 mixin file untouched by Plan 23-09. Initial verification showed 838 LOC WARNING; gap closed via path (b) commit `26e2fa8` (mixin extraction) + `e1dd6c3` (helper extraction). |

**Score:** 15/15 truths verified. The original WARNING at row 15 is RESOLVED.

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/shared/constants/category_other_id_overrides.dart` | kCategoryOtherIdOverrides map | ✓ VERIFIED | Exists; contains `const Map<String, String> kCategoryOtherIdOverrides = {'cat_other_expense': 'cat_other_other'}` |
| `lib/shared/constants/default_synonyms.dart` | kVoiceSynonymSeedEpoch top-level final | ✓ VERIFIED | Line 9: `final DateTime kVoiceSynonymSeedEpoch = DateTime(2026, 1, 1)` |
| `lib/data/daos/category_keyword_preference_dao.dart` | Imports kVoiceSynonymSeedEpoch; no local DateTime literal | ✓ VERIFIED | Line 3: import with `show kVoiceSynonymSeedEpoch`; line 99: uses constant |
| `lib/application/voice/voice_category_resolver.dart` | Imports kCategoryOtherIdOverrides; no local _otherIdOverrides | ✓ VERIFIED | Line 127: `kCategoryOtherIdOverrides[cat.id]`; 0 occurrences of `_otherIdOverrides` |
| `lib/infrastructure/ml/merchant_database.dart` | 3-char min-length guard in substring pass | ✓ VERIFIED | Line 155: `if (lowerQuery.length < 3) return null;` |
| `lib/application/seed/seed_all_use_case.dart` | SeedAllUseCase with ordered execute + short-circuit | ✓ VERIFIED | Exists; execute() awaits categories first, short-circuits on failure |
| `lib/application/seed/seed_providers.dart` | @riverpod seedAllUseCase function | ✓ VERIFIED | Exists with `@riverpod SeedAllUseCase seedAllUseCase(Ref ref)` |
| `lib/application/seed/seed_providers.g.dart` | Generated seedAllUseCaseProvider | ✓ VERIFIED | Exists; `seedAllUseCaseProvider` declared at line 17 |
| `lib/features/accounting/presentation/screens/voice_recognition_event_handler_mixin.dart` | VoiceRecognitionEventHandlerMixin with D-05 guard | ✓ VERIFIED | Exists (139 LOC); contains full D-05 guard in `onStatus()`. Untouched by Plan 23-09. |
| `lib/features/accounting/presentation/screens/voice_locale_readiness_mixin.dart` | (new in 23-09) VoiceLocaleReadinessMixin owning D-07 cold-start gate | ✓ VERIFIED | Exists (99 LOC); D-07 logic verbatim; `ref.listenManual` + `fireImmediately: true` + dispose cleanup. |
| `lib/features/accounting/presentation/screens/voice_input_screen_helpers.dart` | (new in 23-09) 3 pure helpers extracted | ✓ VERIFIED | Exists (73 LOC); `buildVoiceAudioFeatures`, `countVoiceWords`, `extractVoiceKeyword` all top-level pure functions. |
| `lib/application/voice/voice_chunk_merger.dart` | lastFinalAt public getter | ✓ VERIFIED | Line 68: `DateTime? get lastFinalAt => _lastFinalAt;` |
| `test/unit/infrastructure/ml/merchant_database_test.dart` | 3 D-13 tests | ✓ VERIFIED | Contains `D-13: findMerchant returns null for queries shorter than 3 chars`, `D-13: ...continues to substring-match at 3 chars`, `D-13: Pitfall 7 regression` |
| `test/unit/application/seed/seed_all_use_case_test.dart` | 2 D-14 tests (ordering + short-circuit) | ✓ VERIFIED | Contains `D-14: seeds categories before synonyms` (timestamp capture) and `D-14: synonyms not invoked when categories fails` (verifyNever) |
| `test/unit/features/accounting/presentation/voice_recognition_event_handler_mixin_test.dart` | 4 D-05 mixin unit tests | ✓ VERIFIED | Exists with 4 testWidgets blocks (cases a/b/c/d) |
| `test/integration/voice/voice_corpus_en_test.dart` | en hedge skeleton (1 case) | ✓ VERIFIED | Exists; asserts `'other'` → `cat_other_other` |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `lib/main.dart` | `lib/application/seed/seed_all_use_case.dart` | `ref.read(seedAllUseCaseProvider).execute()` | ✓ WIRED | main.dart:107; 0 references to leaf seed providers in main.dart |
| `lib/application/seed/seed_providers.dart` | `lib/features/accounting/presentation/providers/repository_providers.dart` | `ref.watch(seedCategoriesUseCaseProvider)` + `ref.watch(seedVoiceSynonymsUseCaseProvider)` | ✓ WIRED | seed_providers.dart imports from repository_providers.dart |
| `lib/data/daos/category_keyword_preference_dao.dart` | `lib/shared/constants/default_synonyms.dart` | `import ... show kVoiceSynonymSeedEpoch` + use in `insertSeedBatch` | ✓ WIRED | DAO line 3 (import) + line 99 (use) |
| `lib/application/voice/voice_category_resolver.dart` | `lib/shared/constants/category_other_id_overrides.dart` | `kCategoryOtherIdOverrides[cat.id]` in `_ensureL2` | ✓ WIRED | resolver line 127 |
| `test/architecture/category_other_l2_invariant_test.dart` | `lib/shared/constants/category_other_id_overrides.dart` | `import` + `kCategoryOtherIdOverrides[l1Id]` | ✓ WIRED | arch test line 61 |
| `voice_input_screen.dart` `_VoiceInputScreenState` | `voice_recognition_event_handler_mixin.dart` | `with WidgetsBindingObserver, VoiceRecognitionEventHandlerMixin, VoiceLocaleReadinessMixin` | ✓ WIRED | screen lines 58-60 |
| `voice_input_screen.dart` `_VoiceInputScreenState` | `voice_locale_readiness_mixin.dart` (new) | `with ... VoiceLocaleReadinessMixin`; `initLocaleReadiness()` call + `onVoiceLocaleResolved` override | ✓ WIRED | screen line 60 (with), line 177 (init), line 190 (override) |
| `voice_input_screen.dart` `_VoiceInputScreenState` | `voice_input_screen_helpers.dart` (new) | top-level fn calls `countVoiceWords`, `buildVoiceAudioFeatures`, `extractVoiceKeyword` | ✓ WIRED | screen lines 433, 491, 530 |
| `voice_recognition_event_handler_mixin.dart` `onStatus` | `voice_chunk_merger.dart` `lastFinalAt` | abstract getter `lastMergerFinalAt` → screen override `_amountMerger?.lastFinalAt` | ✓ WIRED | mixin:52, screen unchanged by 23-09 |
| `transaction_details_form.dart` | `voice_input_screen.dart` `_onSavePressed` | `waitForCelebrationDismissed()` future chained on soul-ledger save path | ✓ WIRED | screen:383, form:269 |

---

### Data-Flow Trace (Level 4)

Not applicable for this cleanup phase. All changes are refactors, tests, and documentation with no new data sources. Behavioral changes (D-05 guard, D-07 locale gate, D-08 pop deferral) modify existing data flows without introducing new rendering paths. Plan 23-09's mixin/helper extraction is a structural slim-down — same inputs, same outputs, behavior byte-identical.

---

### Behavioral Spot-Checks

| Behavior | Evidence | Status |
|----------|----------|--------|
| `findMerchant('a')` → null | Guard at merchant_database.dart:155; D-13 test passes per 23-01-SUMMARY | ✓ VERIFIED |
| `findMerchant('mac')` → McDonald entry | D-13 test in merchant_database_test.dart; 3-char threshold allows it | ✓ VERIFIED |
| `SeedAllUseCase.execute()` — categories complete before synonyms start | D-14 timestamp-capture test in seed_all_use_case_test.dart | ✓ VERIFIED |
| `onStatus('notListening')` with lastFinalAt 100ms ago → no commit | D-05 mixin unit test case (a) | ✓ VERIFIED |
| `onStatus('notListening')` with lastFinalAt 2000ms ago → commit | D-05 mixin unit test case (b) | ✓ VERIFIED |
| `voiceRecognitionErrorAudio` string appears before SoftToast in G-02 test | D-11 localized assert at voice_input_screen_test.dart:1100 | ✓ VERIFIED |
| `voice_input_screen.dart` line count < 800 | `wc -l` = 776 (post-23-09) | ✓ VERIFIED |
| D-07 cold-start gate still gates `_onLongPressStart` after refactor | screen line 214 reads mixin getter `isLocaleReady` | ✓ VERIFIED |

---

### Probe Execution

Step 7c: SKIPPED — Phase 23 has no conventional `scripts/*/tests/probe-*.sh` probes. The phase is purely code-cleanup and documentation with test coverage.

---

### Requirements Coverage

**Phase 23 has phase_req_ids = null.** CONTEXT.md D-01..D-20 are the authoritative scope record. The 10 v1.3 REQ-IDs flipped in D-04 belong to Phases 18/20/21 functionally; Phase 23 only reconciles documentation metadata. No REQUIREMENTS.md requirements are formally assigned to Phase 23.

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| D-12 IN-01 constant dedup | 23-01 | kVoiceSynonymSeedEpoch single source | ✓ SATISFIED | See Truth 1 |
| D-12 IN-05 constant dedup | 23-01 | kCategoryOtherIdOverrides single source | ✓ SATISFIED | See Truth 2 |
| D-13 substring guard | 23-01 | MerchantDatabase 3-char min-length | ✓ SATISFIED | See Truth 3 & 4 |
| D-14 SeedAllUseCase | 23-02 | Ordering contract structurally encoded | ✓ SATISFIED | See Truth 5 & 6 |
| D-15 seed expansion | 23-03 | その他/其他/other corpus coverage | ✓ SATISFIED | See Truth 7 |
| D-10 mixin extraction + LOC cap | 23-04 + 23-09 | VoiceRecognitionEventHandlerMixin exists + screen < 800 LOC | ✓ SATISFIED | Mixin exists and is wired; LOC cap satisfied at 776 after Plan 23-09 |
| D-05 intra-session guard | 23-05 | notListening guard in mixin | ✓ SATISFIED | See Truth 8 & 9 |
| D-09 listener leak | 23-05 | FocusNode leak regression test | ✓ SATISFIED | Test exists at voice_input_screen_test.dart:1150 |
| D-07 cold-start race | 23-06 → 23-09 | _isLocaleReady gate via ref.listenManual, now mixin-owned | ✓ SATISFIED | See Truth 10 |
| D-08 popUntil deferral | 23-06 | Soul-ledger pop deferred to overlay dismiss | ✓ SATISFIED | See Truth 11 |
| D-11 G-02 localized assert | 23-06 | voiceRecognitionErrorAudio assertion added | ✓ SATISFIED | See Truth 12 |
| D-04 doc reconciliation | 23-07 | REQUIREMENTS.md 15/15 Complete; 7 SUMMARY backfills | ✓ SATISFIED | See Truth 13 |
| D-03 device UAT | 23-08 | 9/9 device UAT items pass | ✓ SATISFIED | See Truth 14 |

---

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `lib/features/accounting/presentation/screens/voice_input_screen.dart` | 519-522 | `_voiceLocaleId = value` reassignment inside `build()` is now dead-by-refactor (WR-06) | ⚠️ Warning (soft) | Wave-6 code review finding. Functionally benign — the new mixin's `ref.listenManual` with `fireImmediately: true` runs synchronously before the first `build()` completes; both paths assign the same value from the same `AsyncValue<String>`. Mutation in `build()` violates Flutter build-purity but does not affect correctness. **Soft recommendation, not a verification gap.** Queued for v1.4+ cleanup. |
| `lib/features/accounting/presentation/screens/voice_recognition_event_handler_mixin.dart` | 132-136 | Nested `setState` in `onError`: outer `setState` callback calls `isInitialized = false` which triggers a second `setState` via the screen's setter | ⚠️ Warning (pre-existing) | Identified in earlier 23-REVIEW.md as WR-01 (double-rebuild anti-pattern). Flutter analyzer reports no issues; no crash risk in non-build context. Untouched by Plan 23-09. Deferred to v1.4+. |
| `lib/features/accounting/presentation/screens/voice_input_screen.dart` | 463 | `_amountMerger?.feedChunk(text, isFinal: true)` — unawaited async call without `unawaited()` wrapper | ⚠️ Warning (pre-existing) | 23-REVIEW.md WR-03. Exceptions from `restartListen()` silently delivered to zone handler. Analyzer reports no issues (unawaited_futures lint not enabled). Not fixed post-review. |

No `TBD`, `FIXME`, or `XXX` markers found in any Phase 23 modified files (verified across all 9 plans incl. 23-09's new files).

---

### Human Verification Required

**None new.** Plan 23-09's slim-down is structural refactor — no new user-visible behavior, so no new UAT items required. The pre-existing `23-HUMAN-UAT.md` from Plan 23-08 is already `status: complete` with 9/9 pass; it is **not** a new human-verification surface.

The original 2026-05-25 human-verification item (path-(a) "accept 38-line overage" vs. path-(b) "slim-down commit") was answered by path (b): Plan 23-09 shipped the slim-down, bringing the file to 776 LOC. Item resolved.

---

## Gaps Summary

**No blocking gaps. No remaining gaps. No regressions.**

All 13 D-decision items (D-03 through D-15) are verified as implemented and wired in the codebase. The single WARNING from the 2026-05-25 verification (voice_input_screen.dart 838 LOC > 800 cap) was closed by Plan 23-09 via mixin + helper extraction; file is now 776 LOC.

Wave-6 code review surfaced 1 Warning (WR-06: build-side dead assignment) + 1 Info (IN-03: dartdoc contract notes). Neither is a verification gap — WR-06 is functionally equivalent to a no-op (mixin listener with `fireImmediately: true` is the canonical writer; build-side assignment writes the same value second), and IN-03 is purely documentation guidance. Both are queued for v1.4+ cleanup at the user's discretion.

Earlier code-review warnings from 23-REVIEW.md (WR-01 nested setState, WR-02 duplicate import, WR-03 unawaited feedChunk, WR-04 force-unwrap, WR-05 misleading guard) remain present and out-of-scope for Phase 23. They are v1.4+ candidates.

---

## Pre-existing Test Suite Notes

Per the verification context: 11 HomeHeroCard light/ja golden failures exist in the test suite. These pre-date Phase 23 (last commit to `home_hero_card_golden_test.dart` was `5e00df1 feat(14-03)`). Phase 23 modified zero home/hero files. These are baseline drift, not Phase 23 regressions. Plan 23-09's full `flutter test` run confirmed exactly the same 11 failures with zero new test failures introduced.

The `stale_suppressions_scan_test.dart` regression introduced by Phase 23's D-15 group (line number shifts in `default_synonyms.dart`) was fixed in commit `a3dbb2e`. This is resolved.

---

_Verified: 2026-05-25T14:00:00Z_
_Re-verified: 2026-05-26 (after Plan 23-09 gap closure)_
_Verifier: Claude (gsd-verifier)_
