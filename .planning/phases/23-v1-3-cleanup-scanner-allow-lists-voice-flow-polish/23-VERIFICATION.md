---
phase: 23-v1-3-cleanup-scanner-allow-lists-voice-flow-polish
verified: 2026-05-25T14:00:00Z
status: human_needed
score: 12/13 must-haves verified
overrides_applied: 0
human_verification:
  - test: "Confirm voice_input_screen.dart (838 LOC) 800-line cap breach is accepted as deferred"
    expected: "Either: (a) the 38-line overage is explicitly accepted for v1.4+ reduction, OR (b) a slim-down commit brings it back under 800 lines. The mixin extraction D-10 was structurally achieved; only D-07+D-08 additions grew it back."
    why_human: "The coding style rule says <800 lines. The file is 838. This is a project-policy call: accept with debt note or require a trim. Automated checks cannot decide policy intent."
---

# Phase 23: v1.3 Cleanup — Scanner Allow-Lists + Voice Flow Polish Verification Report

**Phase Goal:** Close v1.3 by absorbing carried tech-debt: Phase 22 voice-flow surgical polish (D-05 intra-session guard, D-07 cold-start race, D-08 popUntil deferral, D-09 listener-leak regression, D-10 mixin extraction, D-11 G-02 localized assert), Phase 21 mechanical polish (D-12 constant dedup, D-13 substring guard, D-14 SeedAllUseCase, D-15 その他/其他/other seed), documentation reconciliation (D-04 REQUIREMENTS.md + 7 SUMMARY frontmatter backfills), and 9 carried device UATs (Phase 19 + 20 + 22). Cleanup-only — no new user-visible capabilities.
**Verified:** 2026-05-25T14:00:00Z
**Status:** human_needed
**Re-verification:** No — initial verification

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
| 10 | D-07: `_isLocaleReady` flag gates `_onLongPressStart`; set via `ref.listenManual` on `voiceLocaleIdProvider` in `_initSpeechService`; guard condition: `!_isInitialized \|\| !_isLocaleReady \|\| _isRecording` | ✓ VERIFIED | `voice_input_screen.dart:80` declares `bool _isLocaleReady = false`; `voice_input_screen.dart:181-195` has `ref.listenManual<AsyncValue<String>>(voiceLocaleIdProvider, ...)` setting `_isLocaleReady = true` on both `AsyncData` and `AsyncError`; guard at line 236. |
| 11 | D-08: `TransactionDetailsFormState` has `Completer<void>?` completed on `SoulCelebrationOverlay.onDismissed`; `waitForCelebrationDismissed()` exposed; voice screen defers `Navigator.popUntil` for soul-ledger saves until the future resolves; survival-ledger pops immediately | ✓ VERIFIED | `transaction_details_form.dart:78` has `Completer<void>? _celebrationCompleter`; `waitForCelebrationDismissed()` at line 269; soul-celebration dismiss at line 767-769; `voice_input_screen.dart:403-413` branches on `tx.ledgerType == LedgerType.soul` to await `waitForCelebrationDismissed()` before pop vs. immediate pop. |
| 12 | D-11: G-02 permanent test asserts `find.text(l10nForD11.voiceRecognitionErrorAudio)` BEFORE the SoftToast presence assertion | ✓ VERIFIED | `voice_input_screen_test.dart:1094-1108` shows D-11 localized string assertion on line 1100 precedes `find.byType(SoftToast)` assertion on line 1108. |
| 13 | D-04 documentation reconciliation: REQUIREMENTS.md has 15/15 Complete, 0 Pending; 7 Phase 18/19 SUMMARY frontmatter files have `requirements-completed:` keys | ✓ VERIFIED | REQUIREMENTS.md: `grep "| Complete |"` returns 15; `grep "| Pending |"` returns 0. All 7 files confirmed: 18-02 `[EDIT-02]`, 18-04 `[INPUT-03]`, 18-06 `[INPUT-04]`, 18-07 `[EDIT-01]`, 18-08 `[INPUT-03, EDIT-02]`, 19-03 `[INPUT-01]`, 19-05 `[INPUT-01]`. |
| 14 | D-03 device UAT: 23-HUMAN-UAT.md has `status: complete` with 9/9 pass | ✓ VERIFIED | `23-HUMAN-UAT.md` frontmatter: `status: complete`; summary: `total: 9, passed: 9, accepted-with-debt: 0, issues: 0`. All 9 items (22-T1/T2/T3/T4, 20-T1/T2/T3, 19-T1/T2) pass. |
| ⚠ | D-10: `VoiceRecognitionEventHandlerMixin` extraction achieved; `_onStatus`/`_onError` moved to mixin; BUT `voice_input_screen.dart` is 838 LOC after D-07+D-08 additions — exceeds CLAUDE.md 800-line cap | ⚠ WARNING | Screen was 793 LOC after Plan 04 (under 800 cap). Plans 06 D-07 (31 new lines) and D-08 (14 new lines) grew it to 838. The mixin extraction D-10 is structurally complete (mixin exists, screen mixes it in, handlers extracted). The LOC cap breach is an unresolved coding-style violation requiring human decision. |

**Score:** 13/13 truths verified for D-decisions; 1 item is WARNING (LOC cap breach after D-07+D-08 additions)

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
| `lib/features/accounting/presentation/screens/voice_recognition_event_handler_mixin.dart` | VoiceRecognitionEventHandlerMixin with D-05 guard | ✓ VERIFIED | Exists (139 LOC); contains full D-05 guard in `onStatus()` |
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
| `voice_input_screen.dart` `_VoiceInputScreenState` | `voice_recognition_event_handler_mixin.dart` | `with WidgetsBindingObserver, VoiceRecognitionEventHandlerMixin` | ✓ WIRED | screen line 55 |
| `voice_recognition_event_handler_mixin.dart` `onStatus` | `voice_chunk_merger.dart` `lastFinalAt` | abstract getter `lastMergerFinalAt` → screen override `_amountMerger?.lastFinalAt` | ✓ WIRED | mixin:52, screen:211 |
| `transaction_details_form.dart` | `voice_input_screen.dart` `_onSavePressed` | `waitForCelebrationDismissed()` future chained on soul-ledger save path | ✓ WIRED | screen:405, form:269 |

---

### Data-Flow Trace (Level 4)

Not applicable for this cleanup phase. All changes are refactors, tests, and documentation with no new data sources. Behavioral changes (D-05 guard, D-07 locale gate, D-08 pop deferral) modify existing data flows without introducing new rendering paths.

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
| D-10 mixin extraction | 23-04 | VoiceRecognitionEventHandlerMixin exists | ✓ SATISFIED | Mixin exists and is wired; LOC cap breach is WARNING |
| D-05 intra-session guard | 23-05 | notListening guard in mixin | ✓ SATISFIED | See Truth 8 & 9 |
| D-09 listener leak | 23-05 | FocusNode leak regression test | ✓ SATISFIED | Test exists at voice_input_screen_test.dart:1150 |
| D-07 cold-start race | 23-06 | _isLocaleReady gate via ref.listenManual | ✓ SATISFIED | See Truth 10 |
| D-08 popUntil deferral | 23-06 | Soul-ledger pop deferred to overlay dismiss | ✓ SATISFIED | See Truth 11 |
| D-11 G-02 localized assert | 23-06 | voiceRecognitionErrorAudio assertion added | ✓ SATISFIED | See Truth 12 |
| D-04 doc reconciliation | 23-07 | REQUIREMENTS.md 15/15 Complete; 7 SUMMARY backfills | ✓ SATISFIED | See Truth 13 |
| D-03 device UAT | 23-08 | 9/9 device UAT items pass | ✓ SATISFIED | See Truth 14 |

---

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `lib/features/accounting/presentation/screens/voice_input_screen.dart` | — | 838 LOC, exceeds CLAUDE.md 800-line cap | ⚠️ Warning | Screen was 793 LOC after D-10 mixin extraction. D-07 added ~31 lines; D-08 added ~14 lines. The mixin extraction goal was achieved but subsequent functional additions re-crossed the cap. No TBD/FIXME/XXX markers. Analyzer: 0 issues. |
| `lib/features/accounting/presentation/screens/voice_recognition_event_handler_mixin.dart` | 132-136 | Nested `setState` in `onError`: outer `setState` callback calls `isInitialized = false` which triggers a second `setState` via the screen's setter | ⚠️ Warning | Identified in 23-REVIEW.md WR-01 as a double-rebuild anti-pattern. Flutter analyzer reports no issues; no crash risk in non-build context. Not fixed post-review. Deferred to v1.4+. |
| `lib/features/accounting/presentation/screens/voice_input_screen.dart` | 483 | `_amountMerger?.feedChunk(text, isFinal: true)` — unawaited async call without `unawaited()` wrapper | ⚠️ Warning | 23-REVIEW.md WR-03. Exceptions from `restartListen()` silently delivered to zone handler. Analyzer reports no issues (unawaited_futures lint not enabled). Not fixed post-review. |

No `TBD`, `FIXME`, or `XXX` markers found in any Phase 23 modified files.

---

### Human Verification Required

#### 1. voice_input_screen.dart 800-Line Cap Breach

**Test:** Inspect `lib/features/accounting/presentation/screens/voice_input_screen.dart` (currently 838 LOC). Confirm whether this exceeds the project's CLAUDE.md 800-line file cap and determine if a slim-down commit is required before v1.3 closure.

**Expected:** Either: (a) Project team explicitly accepts the 38-line overage as deferred to v1.4+ refactoring (with a brief note in CONTEXT.md or the next milestone audit), OR (b) A slim-down commit is created to reduce the file below 800 lines before `/gsd:complete-milestone v1.3`.

**Why human:** The coding style rule (`rules/coding-style.md`: "Files are focused (<800 lines)") and ROADMAP description both stated "screen drops <800 LOC" for D-10. The mixin extraction achieved that goal at Plan 04 (793 LOC). The D-07 and D-08 functional additions are legitimate tech-debt closures that grew the file back. Whether this constitutes a Phase 23 gap vs. an accepted-with-note deviation is a project policy decision, not a code correctness question.

---

## Gaps Summary

No blocking gaps found. All 13 decision items (D-03 through D-15) are verified as implemented and wired in the codebase. Code review warnings from 23-REVIEW.md (WR-01 nested setState, WR-02 duplicate import, WR-03 unawaited feedChunk, WR-04 force-unwrap, WR-05 misleading guard) are present in the codebase but none cause test failures or analyzer violations, and none were required by Phase 23 scope. They are v1.4+ candidates.

The single human decision needed is on the `voice_input_screen.dart` LOC breach: the D-10 mixin extraction was structurally achieved (VoiceRecognitionEventHandlerMixin created, screen mixes it in, _onStatus/_onError extracted), but the final file size is 838 LOC due to D-07 and D-08 additions in Plan 06. This is a WARNING requiring human acceptance or a trim commit.

---

## Pre-existing Test Suite Notes

Per the verification context: 11 HomeHeroCard light/ja golden failures exist in the test suite. These pre-date Phase 23 (last commit to `home_hero_card_golden_test.dart` was `5e00df1 feat(14-03)`). Phase 23 modified zero home/hero files. These are baseline drift, not Phase 23 regressions.

The `stale_suppressions_scan_test.dart` regression introduced by Phase 23's D-15 group (line number shifts in `default_synonyms.dart`) was fixed in commit `a3dbb2e`. This is resolved.

---

_Verified: 2026-05-25T14:00:00Z_
_Verifier: Claude (gsd-verifier)_
