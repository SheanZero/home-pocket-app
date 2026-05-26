---
phase: 20-voice-number-parser-zh-ja
verified: 2026-05-24T01:43:24Z
status: human_needed
verdict: PASS_WITH_DEBT
score: 5/5 success criteria verified (1 deferred device-UAT + 2 phase-introduced architecture-scanner regressions)
requirements_covered: [VOICE-01, VOICE-02, VOICE-03]
re_verification: null
human_verification:
  - test: "Real-device 8 anchor cases (VOICE-02-DEVICE-VERIFY)"
    expected: "Plan 20-08 Task 2 — physical iPhone/Android speech_to_text plugin exercise"
    why_human: "speech_to_text fragmentation behaviour cannot be reproduced under flutter_test; only physical recognizer surfaces real-world final-result chunking"
gaps:
  - truth: "Architecture scanner clean (no new ignore directives, no new flagged CJK literals)"
    status: partial
    reason: "Phase 20 introduced 2 scanner regressions (NOT baseline-identical as 20-08-SUMMARY claims). New failures: (a) hardcoded_cjk_ui_scan flags NLP lexicon entries in 3 infra files; (b) stale_suppressions_scan flags 8 `// ignore: avoid_print` directives in the 2 corpus test files for the per-locale accuracy summary print()."
    artifacts:
      - path: "test/architecture/hardcoded_cjk_ui_scan_test.dart"
        issue: "Scanner does not exempt lib/infrastructure/voice/{japanese_numeral_dictionary,japanese_numeral_state_machine,chinese_numeral_state_machine}.dart — these are NLP lexicons, not UI text"
      - path: "test/architecture/stale_suppressions_scan_test.dart"
        issue: "Scanner does not allow-list test/integration/voice/voice_corpus_{zh,ja}_test.dart for `avoid_print` (used for the corpus accuracy summary printer)"
    missing:
      - "Add infrastructure/voice/ NLP files to hardcoded_cjk_ui_scan allow-list (these are lexicon data, semantically required to remain in CJK)"
      - "Add test/integration/voice/voice_corpus_{zh,ja}_test.dart to stale_suppressions_scan allow-list (or wrap print() in a logger that does not need avoid_print suppression)"
deferred:
  - truth: "VOICE-02 anchor cases verified on physical iOS + Android speech recognizer"
    addressed_in: "Phase 22 close OR milestone close (whichever comes first)"
    evidence: "STATE.md `v1.3 verification debt: Phase 20 Plan 20-08 device verification deferred (VOICE-02-DEVICE-VERIFY)`; 20-08-SUMMARY §Deferred Verification carries the 8 anchor case script verbatim"
overrides_applied: 0
overrides: []
---

# Phase 20: Voice Number Parser (zh + ja) — Verification Report

**Phase Goal:** Rebuild voice number recognition state machine so compound numbers across 千/百/十/零/万 combine correctly without digit dropping; handle intra-number pauses via continued-listening window; reach ≥95% accuracy on per-locale committed corpora.

**Requirements:** VOICE-01, VOICE-02, VOICE-03

**Verified:** 2026-05-24T01:43:24Z
**Verdict:** **PASS_WITH_DEBT**
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths (5 Roadmap Success Criteria)

| #   | Success Criterion | Status | Evidence |
| --- | ----------------- | ------ | -------- |
| 1   | zh corpus accuracy ≥95% with per-case results emitted | ✓ VERIFIED | `flutter test test/integration/voice/voice_corpus_zh_test.dart` → **48/50 (96.0%)**, gate passes; per-case results emitted via expanded reporter (see `00:00 +1..+49` lines) |
| 2   | ja corpus accuracy ≥95% including 万-scale (一万二千 → 12000) | ✓ VERIFIED | `flutter test test/integration/voice/voice_corpus_ja_test.dart` → **50/50 (100.0%)**, gate passes; ja anchor `一万二千 -> 12000` listed at fixture index 5 |
| 3   | 4 anchor cases as **named** tests (zh 2204, zh 1840 with pause, ja 2204, ja 1840 with pause) | ✓ VERIFIED | Anchors in 3 distinct surfaces — see breakdown below |
| 4   | Locale-aware numeral combining state machine + continued-listening window in `lib/infrastructure/` (Thin Feature) consumed via Application use case | ✓ VERIFIED | Infrastructure: `lib/infrastructure/voice/{numeral_state_machine,chinese_numeral_state_machine,japanese_numeral_state_machine,japanese_numeral_dictionary}.dart`. Application: `lib/application/voice/{voice_chunk_merger,voice_text_parser,parse_voice_input_use_case}.dart`. Screen consumes merger via `_amountMerger` field (`voice_input_screen.dart:85,196,276,395`) |
| 5   | `flutter analyze` 0 issues on new Phase 20 files; per-file coverage ≥70% on new parser files; no Drift schema change | ⚠ PARTIAL (see below) | Phase-20-file `flutter analyze`: **0 issues**. Per-file coverage: all parser files ≥87% (range 87.2%–100%). No Drift schema/migration touched. BUT 2 architecture-scanner tests regressed (see Gaps). |

**Score:** 5/5 truths verified at the parser/corpus level; 1 truth (SC-5) is partially passing because of 2 architecture-scanner regressions that block "all green" but do not block any user-observable VOICE-01/02/03 capability.

### SC-3 Anchor Cases — Named-Test Surface Inventory

The roadmap requires each anchor case to exist as **a named test, not just corpus aggregate**. Phase 20 implements them in three layers:

| Anchor Case | Named Test Surface | Status |
| ----------- | ------------------ | ------ |
| zh "2千2百零4元" → 2204 (零-placeholder, single-pass) | `voice_corpus_zh_test.dart:29` group "zh anchor cases (VOICE-01/02/03)" — anchor named with note "anchor: 零-placeholder VOICE-01" | ✓ PASS |
| zh "1千8百" + pause + "4十元" → 1840 (intra-pause merge) | `voice_chunk_merger_test.dart:29` `test('anchor zh: 1千8百 + 1.2s pause + 4十元 -> 1840 (VOICE-02 anchor)')` — `fakeAsync` simulates 1.2s pause between two `feedChunk(isFinal:true)` calls and asserts single commit of 1840 | ✓ PASS |
| ja「にせんにひゃくよん」→ 2204 | `voice_corpus_ja_test.dart` anchor + `japanese_numeral_state_machine_test.dart` "にせんにひゃくよん -> 2204 (pure hiragana VOICE-01 anchor)" | ✓ PASS |
| ja「せんはっぴゃく」+ pause +「よんじゅう円」→ 1840 | `voice_chunk_merger_test.dart:56` `test('anchor ja: せんはっぴゃく + 1.5s pause + よんじゅう円 -> 1840 (VOICE-02 anchor)')` — fakeAsync simulates 1.5s pause | ✓ PASS |
| ja「一万二千」→ 12000 (万-scale regression guard) | `voice_corpus_ja_test.dart` anchor "一万二千 -> 12000" + `japanese_numeral_state_machine_test.dart` "一万二千 -> 12000 (万-scale regression guard VOICE-03)" | ✓ PASS |

Additionally `voice_chunk_merger_test.dart` carries the false-merge regression `'1千8百' + '现金' commits 1800 and drops 现金` (lexical gate negative test).

---

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `lib/infrastructure/voice/numeral_state_machine.dart` | abstract base (D-01/D-03) | ✓ VERIFIED | 139 lines; defines `NumeralStateMachine` abstract class + tokens |
| `lib/infrastructure/voice/chinese_numeral_state_machine.dart` | zh concrete (D-02, D-08) | ✓ VERIFIED | 98 lines; includes `两` digit (commit 21e6890 fix from corpus-gate cascade) |
| `lib/infrastructure/voice/japanese_numeral_state_machine.dart` | ja concrete | ✓ VERIFIED | 129 lines; sokuon/voicing handled via dictionary longest-match |
| `lib/infrastructure/voice/japanese_numeral_dictionary.dart` | const `Map<String, NumeralToken>` (D-06) | ✓ VERIFIED | 64 lines; 28 entries covering D-05 readings |
| `lib/application/voice/voice_chunk_merger.dart` | stateful 2.5s window + double-gate (D-09/D-10/D-11/D-12) | ✓ VERIFIED | 201 lines; `_windowDuration = Duration(milliseconds: 2500)` const; calls `_speechService.restartListen()` |
| `lib/application/voice/voice_text_parser.dart` | thin transfer station; `_extractKanjiAmount` deleted | ✓ VERIFIED | 467 lines; `_extractKanjiAmount` absent (grep miss); replaced with `_runStateMachine(text, localeId)` that branches on `ja*`/`zh*` |
| `lib/application/voice/parse_voice_input_use_case.dart` | accepts `localeId` parameter | ✓ VERIFIED | 114 lines; `execute(String text, {String? localeId})` |
| `lib/infrastructure/speech/speech_recognition_service.dart` | exposes `restartListen()` (D-12) | ✓ VERIFIED | line 104: `Future<bool> restartListen() async {…}` |
| `lib/features/accounting/presentation/screens/voice_input_screen.dart` | wired to merger | ✓ VERIFIED | 8 surgical edits present: `_amountMerger` field (line 85), `_mergedAmount` field (line 90), merger built in `_startRecording` (196), `feedChunk` in final branch (276), `localeId:` forwarded to use case (286, 299), `stop()` in `_stopRecording` (217), `_mergedAmount ??` at navigate site (395), dispose chain (636-637) |
| `test/fixtures/voice_corpus_zh.dart` | ~50 cases including 5 anchors | ✓ VERIFIED | 99 lines; 50 case records; 5 with `note: 'anchor:…'` |
| `test/fixtures/voice_corpus_ja.dart` | ~50 cases including 5 anchors | ✓ VERIFIED | 99 lines; 50 case records; 5 with `note: 'anchor:…'` |
| `test/integration/voice/voice_corpus_zh_test.dart` | per-case + ≥95% gate | ✓ VERIFIED | 89 lines; 5 named anchor tests + 44 statistical + `tearDownAll` 95% gate |
| `test/integration/voice/voice_corpus_ja_test.dart` | per-case + ≥95% gate | ✓ VERIFIED | 89 lines; 5 named anchor tests + 45 statistical + `tearDownAll` 95% gate |

### Key Link Verification

| From | To | Via | Status |
| ---- | -- | --- | ------ |
| `voice_input_screen._onResult` (final branch) | `VoiceChunkMerger.feedChunk` | direct call line 276 with `isFinal: true` | ✓ WIRED |
| `voice_input_screen._startRecording` | `VoiceChunkMerger` | constructor at line 196 with locale-routed parser (`localeId.startsWith('ja')` → JP machine, else ZH machine) | ✓ WIRED |
| `VoiceChunkMerger.feedChunk` (window-close) | `NumeralStateMachine.parse` | line 47 `_windowDuration` triggers commit through `_parser.parse(_buffer)` (verified in voice_chunk_merger.dart implementation) | ✓ WIRED |
| `VoiceChunkMerger` (window open) | `SpeechRecognitionService.restartListen` | `_speechService.restartListen()` after each final | ✓ WIRED |
| `voice_input_screen._navigateToConfirm` | `ManualOneStepScreen.initialAmount` | line 395 `initialAmount: _mergedAmount ?? result.amount ?? 0` — merger's commit wins | ✓ WIRED |
| `parse_voice_input_use_case.execute` | `VoiceTextParser.extractAmount(text, localeId:)` | localeId passed through (line 286 + 299 from screen) | ✓ WIRED |
| `VoiceTextParser._runStateMachine` | `{ChineseNumeralStateMachine, JapaneseNumeralStateMachine}.parse` | branches on `localeId.startsWith('ja')`/`startsWith('zh')` (voice_text_parser.dart:58-62) | ✓ WIRED |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| -------- | ------------- | ------ | ------------------ | ------ |
| `voice_input_screen._navigateToConfirm` | `_mergedAmount` | merger's `onAmountResolved` callback writes via setState (line 201) | Yes — corpus tests prove parser emits real ints | ✓ FLOWING |
| `ManualOneStepScreen` (downstream) | `initialAmount` | `_mergedAmount ?? result.amount ?? 0` | Yes — concrete value lands as int | ✓ FLOWING |

No HOLLOW_PROP or STATIC fallback gaps detected on the voice-amount path.

---

## Architecture Check — Thin Feature Rule

Voice code under `lib/features/`:

```
lib/features/accounting/domain/models/voice_parse_result.dart        # domain model — allowed
lib/features/accounting/domain/models/voice_parse_result.freezed.dart # generated  — allowed
lib/features/accounting/presentation/screens/voice_input_screen.dart # presentation — allowed
lib/features/accounting/presentation/widgets/voice_waveform.dart     # presentation — allowed
lib/features/settings/presentation/utils/voice_locale_helpers.dart   # presentation utility — allowed
lib/features/settings/presentation/widgets/voice_section.dart        # presentation — allowed
```

Zero `application/`, `infrastructure/`, `data/tables/`, `data/daos/` directories inside `lib/features/voice*` or `lib/features/accounting/voice*`. State machine + dictionary are in `lib/infrastructure/voice/`; merger + use case + parser are in `lib/application/voice/`. **Thin Feature rule honored.**

---

## Quality Gates

### `flutter analyze` (project-wide)

```
4 issues found (all pre-existing / external):
- 1 warning: build/ios/SourcePackages/firebase_messaging-16.2.2 (external SPM artifact)
- 1 info:  build/ios/SourcePackages/firebase_messaging-16.2.2/lib/src/messaging.dart (external)
- 2 info:  lib/features/accounting/presentation/screens/category_selection_screen.dart:386,502 — deprecated_member_use (onReorder, NOT touched by Phase 20)
```

### `flutter analyze` (Phase 20 files only)

```
flutter analyze \
  lib/infrastructure/voice/ \
  lib/application/voice/voice_chunk_merger.dart \
  lib/application/voice/voice_text_parser.dart \
  lib/application/voice/parse_voice_input_use_case.dart \
  lib/features/accounting/presentation/screens/voice_input_screen.dart \
  test/integration/voice/ \
  test/fixtures/voice_corpus_*.dart
→ "No issues found! (ran in 1.2s)"
```

**SC-5 analyze sub-clause: PASS.**

### Per-file Coverage (Phase 20 parser files)

| File | Hit/Total | % | ≥70% Gate |
| ---- | --------- | - | --------- |
| `lib/infrastructure/voice/numeral_state_machine.dart` | 23/25 | 92.0% | ✓ |
| `lib/infrastructure/voice/chinese_numeral_state_machine.dart` | 15/15 | 100.0% | ✓ |
| `lib/infrastructure/voice/japanese_numeral_state_machine.dart` | 25/25 | 100.0% | ✓ |
| `lib/infrastructure/voice/japanese_numeral_dictionary.dart` | const data (no executable lines) | n/a | ✓ trivially |
| `lib/application/voice/voice_chunk_merger.dart` | 57/60 | 95.0% | ✓ |
| `lib/application/voice/voice_text_parser.dart` | 150/172 | 87.2% | ✓ |

**SC-5 coverage sub-clause: PASS.**

### Drift schema

```
git diff fa7b3f8..HEAD -- 'lib/data/**' '**/migration*.dart' '**/schema*.dart'
→ (no schema/migration diffs)
```

**SC-5 schema sub-clause: PASS.**

### Full Test Suite Baseline Comparison

| Run | Pass | Fail | Notes |
| --- | ---- | ---- | ----- |
| Pre-Phase-20 baseline (commit `fa7b3f8`) | (sampled) | **11** | 4 `home_hero_card` widget tests + 7 `home_hero_card_golden` tests — all "single mode" / "thin sample" / "all-neutral CTA" ja-locale (golden render drift from earlier phase) |
| Post-Phase-20 (current `HEAD`) | 1930 | **13** | Same 11 baseline + **2 new Phase-20-introduced** (`hardcoded_cjk_ui_scan` + `stale_suppressions_scan`) |

**SUMMARY 20-08 claim "baseline-identical 13 failures" is INACCURATE.** Verified actual delta = +2 Phase-20-introduced architecture-scanner failures. Both are scanner/allow-list issues, not behavioural regressions — they are surfaced as gaps below.

### Architecture-scanner Regressions (Phase-20-introduced)

#### 1. `hardcoded_cjk_ui_scan_test.dart`

The scanner flags NLP lexicon entries as "user-visible hardcoded CJK string literals". Affected files (all new in Phase 20):

```
lib/infrastructure/voice/japanese_numeral_dictionary.dart: 28 hiragana/katakana keys
  (いち, ひと, に, ふた, さん, よん, し, ご, ろく, なな, しち, はち, きゅう, く,
   ゼロ, れい, まる, せん, ひゃく, じゅう, まん, いっせん, さんぜん, はっせん,
   さんびゃく, ろっぴゃく, はっぴゃく, いちまん)
lib/infrastructure/voice/japanese_numeral_state_machine.dart: 15 kanji (一..九, 零, 十百千万萬)
lib/infrastructure/voice/chinese_numeral_state_machine.dart: 25 kanji (incl. 壱壹弐贰参叁伍仟萬)
```

These are NLP lexicon data; semantically they MUST remain in CJK form (the recognizer outputs them). The scanner needs an allow-list entry for `lib/infrastructure/voice/`.

#### 2. `stale_suppressions_scan_test.dart`

8 `// ignore: avoid_print` directives in the new corpus test files for the per-locale summary printer:

```
test/integration/voice/voice_corpus_zh_test.dart:64,76,78,80
test/integration/voice/voice_corpus_ja_test.dart:64,76,78,80
```

Either allow-list the corpus tests in the scanner, or replace the `print()` summary with `printOnFailure()` / a logger that does not require `avoid_print` suppression.

Neither regression blocks any user-observable voice capability; both are scanner-config cleanups. Logged as a GAP for the orchestrator/planner to schedule, not as a phase failure.

---

## Requirements Coverage

| Requirement | Description | Status | Evidence |
| ----------- | ----------- | ------ | -------- |
| VOICE-01 | Voice parser correctly converts compound numbers without digit dropping (zh 2千2百零4元 → 2204; ja にせんにひゃくよん → 2204) | ✓ SATISFIED | Anchor tests in `voice_corpus_zh_test.dart` + `voice_corpus_ja_test.dart` + state-machine unit tests pass |
| VOICE-02 | Voice parser correctly combines intra-number pauses via continued-listening window + locale-aware numeral combining state machine (zh 1千8百…4十 → 1840; ja せんはっぴゃく…よんじゅう → 1840) | ⚠ SATISFIED (with DEFERRED device verification) | `voice_chunk_merger_test.dart:29,56` — fakeAsync simulates pause; commit single 1840 verified. Real-device 8-case run deferred as VOICE-02-DEVICE-VERIFY |
| VOICE-03 | Per-locale corpora ≥95% accuracy with both committed as test fixtures | ✓ SATISFIED | zh: 48/50 (96.0%); ja: 50/50 (100.0%) — fixtures `test/fixtures/voice_corpus_{zh,ja}.dart` committed |

---

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| zh corpus accuracy gate ≥95% | `flutter test test/integration/voice/voice_corpus_zh_test.dart` | "zh corpus: 48/50 (96.0%)" + "All tests passed!" | ✓ PASS |
| ja corpus accuracy gate ≥95% | `flutter test test/integration/voice/voice_corpus_ja_test.dart` | "ja corpus: 50/50 (100.0%)" + "All tests passed!" | ✓ PASS |
| VOICE-02 zh pause-merge anchor | `flutter test test/unit/application/voice/voice_chunk_merger_test.dart -n "anchor zh"` (covered in full merger suite run) | All 8 merger tests pass | ✓ PASS |
| VOICE-02 ja pause-merge anchor | `flutter test test/unit/application/voice/voice_chunk_merger_test.dart -n "anchor ja"` (covered in full merger suite run) | All 8 merger tests pass | ✓ PASS |
| State-machine unit suite | `flutter test test/unit/infrastructure/voice/` | 84/84 tests pass | ✓ PASS |
| Phase 20 file analyze | `flutter analyze <phase-20-files>` | "No issues found!" | ✓ PASS |
| Real-device 8-case anchor verification (Plan 20-08 Task 2) | physical iPhone/Android speech_to_text | — | ? SKIP (deferred to VOICE-02-DEVICE-VERIFY) |

---

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| `test/integration/voice/voice_corpus_{zh,ja}_test.dart` | 64, 76, 78, 80 | `// ignore: avoid_print` (8 instances) | ⚠ Warning (scanner regression — see Quality Gates §Architecture-scanner Regressions) | Triggers `stale_suppressions_scan_test.dart` failure; consider switching to `printOnFailure` or allow-listing |
| `lib/infrastructure/voice/*.dart` (3 files) | various | Hardcoded CJK kana/kanji in NLP lexicon | ℹ Info (false-positive scanner hit) | NLP-required, not UI text; needs scanner allow-list |

No `TBD`, `FIXME`, `XXX` debt markers introduced in Phase 20 source files.

---

## Deferred Verification Debt

### VOICE-02-DEVICE-VERIFY (Plan 20-08 Task 2)

**Status:** DEFERRED at orchestrator checkpoint (per STATE.md "Blockers / Concerns").
**Reason:** `speech_to_text` plugin fragmentation behaviour is not reproducible under `flutter_test`. Cross-final continuation, restart-listen race conditions, and 2.5s window calibration can only be exercised against the real iOS / Android recognizer.
**Resolution path:** Run the 8 cases on a physical iPhone + Android handset; record results; resolve via `/gsd:verify-work 20` re-run OR carry into Phase 22 verification scope if not exercised by then. Either outcome is acceptable per the v1.1 Phase 11 / v1.2 Phase 13+17 precedent.

#### The 8 anchor cases (verbatim from `20-08-SUMMARY.md`, for the future operator)

**zh cases — set voice locale to `zh-CN` first:**

1. Tap record → speak **「二千二百零四元」** continuous (no pause) → expect commit = **2204** (NOT 24, NOT 224, NOT null).
2. Tap record → speak **「一千八百」** → pause ~1.5s → speak **「四十元」** → expect commit = **1840** (NOT 1800 + 40 as separate amounts; NOT 1800 alone with "4十元" lost).
3. **False-merge regression:** Tap record → speak **「一千八百」** → pause ~1.5s → speak **「现金」** → expect commit = **1800**, and "现金" SHOULD NOT be concatenated into the amount. (现金 may still affect merchant/category/note paths via `_parseFinalResult` — expected; only the amount path is merger-gated.)

**ja cases — switch voice locale to `ja-JP` first:**

4. Tap record → speak **「にせんにひゃくよん」** continuous → expect commit = **2204**.
5. Tap record → speak **「せんはっぴゃく」** → pause ~1.5s → speak **「よんじゅう円」** → expect commit = **1840**.
6. Tap record → speak **「一万二千」** → expect commit = **12000** (regression guard: 万-scale still works post-refactor).

**Sanity checks:**

7. Verify `_isRecording` stays `true` between finals during cases 1-2 and 4-5 (the record button should NOT flash off after the first final — the merger keeps the session alive). If it flashes off, `_isRecording = false` was not properly removed from the final branch in Plan 20-08 Edit 4.
8. Verify navigating to `ManualOneStepScreen` after each test shows the correct `initialAmount` field value.

#### Tuning levers if cases fail

Documented in `20-08-SUMMARY.md` §"Tuning Levers If Cases Fail":

- **Timed out before user finished:** increase `_windowDuration` const in `voice_chunk_merger.dart` (D-11 explicitly allows tweak)
- **Continued speech lost after first final:** investigate `speech_to_text` error surfaced by `restartListen()`
- **"现金" concatenated into amount:** fix `_chunkStartsNumeric` predicate or `ChineseNumeralStateMachine.normalize('现金')` output

---

## Gaps Summary

Phase 20 successfully meets all 5 roadmap Success Criteria at the parser/corpus level. Two ancillary gaps exist:

1. **VOICE-02-DEVICE-VERIFY** (intentional deferral) — 8 real-device anchor cases not yet exercised; tracked under v1.3 verification debt; resolution path is either device run or carry-into-Phase-22.

2. **2 architecture-scanner regressions introduced by Phase 20** (not previously documented in 20-08-SUMMARY's "baseline-identical" claim):
   - `hardcoded_cjk_ui_scan_test.dart` flags 3 new NLP lexicon files (`japanese_numeral_dictionary.dart`, `japanese_numeral_state_machine.dart`, `chinese_numeral_state_machine.dart`). These are NOT UI text — NLP lexicons must remain in CJK form. Scanner needs an allow-list entry for `lib/infrastructure/voice/`.
   - `stale_suppressions_scan_test.dart` flags 8 `// ignore: avoid_print` directives in `voice_corpus_{zh,ja}_test.dart` used for per-locale accuracy summary printing. Either allow-list the corpus tests or replace `print()` with `printOnFailure()` / a logger that does not need the suppression.

Neither regression blocks user-observable VOICE-01/02/03 capability. Both should be scheduled as a small follow-up cleanup commit (likely <30 min) before milestone close.

---

## Final Verdict

**PASS_WITH_DEBT** — Phase 20 functional goal achieved; VOICE-01 + VOICE-03 fully verified; VOICE-02 verified end-to-end at code + unit + fakeAsync integration layer with real-device confirmation explicitly deferred to `VOICE-02-DEVICE-VERIFY` per the established v1.1 Phase 11 / v1.2 Phase 13+17 precedent.

Two phase-introduced architecture-scanner regressions are surfaced as `gaps` for the orchestrator to schedule. They are scanner-config issues (NLP lexicon mis-classified as UI text + reasonable `avoid_print` use in test summaries), not behavioural regressions, and do not affect any user-observable voice flow.

### Recommendation

- **Accept the phase** and advance to Phase 21 (Voice Category Resolver Level-2 Enforcement). Phase 21 inherits the strengthened voice parser pipeline and can proceed in parallel with the device-verification follow-up.
- **Schedule a follow-up** (quick task or first plan of a small fix wave) to either:
  - Add `lib/infrastructure/voice/` to the `hardcoded_cjk_ui_scan` allow-list AND allow-list `test/integration/voice/voice_corpus_*.dart` in the `stale_suppressions_scan`, OR
  - Replace the 8 `print()` summary calls with `printOnFailure(...)` and add the 3 infra files to the CJK allow-list with rationale comment "NLP lexicon data — recognizer output form".
- **Carry VOICE-02-DEVICE-VERIFY forward** — either resolve via device run before Phase 22 close, or accept at v1.3 milestone close (mirroring Phase 11 / 13 / 17 precedent).

---

*Verified: 2026-05-24T01:43:24Z*
*Verifier: Claude Opus 4.7 (1M context) — gsd-verifier (goal-backward)*
