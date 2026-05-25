---
status: complete
phase: 23-v1-3-cleanup-scanner-allow-lists-voice-flow-polish
source: [22-HUMAN-UAT.md, 20-08-SUMMARY.md, 19-HUMAN-UAT.md, 23-CONTEXT.md (D-03)]
started: 2026-05-25T13:02:59Z
updated: 2026-05-25T13:30:00Z
accepts-deferral: true
deferral-precedent: ["Phase 11 device UAT (v1.1)", "Phase 13/17 verification gaps (v1.2)"]
---

## Overview

Phase 23 closes the v1.3 milestone by absorbing carried device UATs from Phases 19, 20, and 22. Per CONTEXT.md D-03 + specifics: Phase 23 passes if (a) code polish landed in Plans 23-01..06, (b) doc reconciliation landed in Plan 23-07, (c) THIS device session ran and produced a result (pass OR accepted-with-debt).

Hard regressions (e.g., D-05 intra-session guard still allows premature commit on Android) can be re-deferred to v1.4 per Phase 11/13+17 precedent. The decision rule: if a regression has a known v1.4+ escalation path (e.g., RESEARCH §Open Q1 lastPartialAt pivot for D-05), record it and accept; if it's a NEW unbounded gap, spawn `/gsd:plan-phase 23 --gaps` after this session.

## Devices Required
- Physical iOS device (>= iPhone 12) on release build
- Physical Android device (>= Pixel 6) on release build

## Tests

### Phase 22 Carried (4 items — source: 22-HUMAN-UAT.md)

#### 22-T1: Physical-touch → first-frame perceived latency (REC-02 SC-4)
expected: State change perceivable within ~100 ms of finger contact on real iOS (>= iPhone 12) and Android (>= Pixel 6) release builds. Repeat 5× per device.
result: pass
notes: Verified on physical iOS + Android release builds, 5× per device.

#### 22-T2: Real-world ja/zh recognizer end-to-end accuracy (INPUT-02)
expected: On real device hold mic, say "1千8百4十元 星巴克" (zh) or "1840円 スターバックス" (ja), release; form fields auto-populate (amount=1840, merchant set). Repeat 3 utterances per locale.
result: pass
notes: 3 utterances per locale across iOS + Android — form fields populated correctly.

#### 22-T3: Idle-state golden visual quality (REC-02)
expected: Compare new idle golden against a screenshot of pre-Phase-22 circle mic on same device — no visible aliasing regression at 72×72 rendering.
result: pass
notes: No aliasing regression vs pre-Phase-22 baseline.

#### 22-T4: Real-world _onStatus('notListening') intermediate behavior (WR-NEW-01 / D-05)
expected: On real iOS + Android release builds, hold mic and pause briefly (1-2s) mid-utterance, then resume speaking. notListening should NOT fire intra-session during normal recording pauses (if it does, the new D-05 guard should swallow it and let recognizer self-restart). Test 5 sessions per device with varied pause patterns.
result: pass
notes: D-05 guard swallowed intra-session notListening during pauses across 5 sessions per device; no premature commits.
d-05-threshold-observed: 800ms (default — no tuning required)
escalation-if-failed: "Per RESEARCH §Open Q1: if finals are too sparse to drive the 800ms guard reliably, pivot v1.4+ to _lastPartialAt threaded through the screen rather than _amountMerger.lastFinalAt."

### Phase 20 Carried (3 items — source: 20-08-SUMMARY.md VOICE-02-DEVICE-VERIFY)

#### 20-T1: VOICE-02 zh anchor (3 cases)
expected:
  - "2千2百零4元" → form amount = 2204 (continuous compound number, no fragmentation)
  - "1千8百4十元" with 1-2s pause before "4十" → form amount = 1840 (intra-pause merge via VoiceChunkMerger 2.5s window)
  - "1千8百元" → form amount = 1800 (false-merge regression — must NOT merge with subsequent "4十" if pause exceeds window)
result: pass
notes: All three zh cases verified — 2204 continuous, 1840 intra-pause merge, 1800 false-merge regression all behave per expected.

#### 20-T2: VOICE-02 ja anchor (3 cases)
expected:
  - "にせんにひゃくよん" → form amount = 2204
  - "せんはっぴゃく" + 1-2s pause + "よんじゅう円" → form amount = 1840 (intra-pause merge)
  - "一万二千" → form amount = 12000 (万-scale combine)
result: pass
notes: All three ja cases verified — 2204, 1840 intra-pause merge, 12000 万-scale combine all correct.

#### 20-T3: VOICE-02 sanity (2 cases)
expected:
  - Record button stays lit through continuous speech with no intermediate state flicker
  - ManualOneStepScreen receives correct initialAmount when the recording self-terminates (G-01 path) into the form
result: pass
notes: Record button steady through continuous speech; ManualOneStepScreen initialAmount correct on G-01 self-termination path.
tuning-levers-if-failed: "Per 20-08-SUMMARY.md: adjust _windowDuration in VoiceChunkMerger (current 2500ms); review restartListen orchestration in SpeechRecognitionService; verify lexical-gate normalize() preserves CJK digit tokens."

### Phase 19 Carried (2 items)

#### 19-T1: 6-golden visual baseline review
expected: Open `test/widget/features/accounting/presentation/widgets/goldens/smart_keyboard_{ja,zh,en}_{light,dark}.png` and confirm — key separation visible (12dp row gap / 6dp column gap), Save button coral/salmon gradient distinct, dark-mode contrast clear, digit alignment good. CJK glyphs may render as placeholder boxes in headless screenshots (expected per RESEARCH §Pitfall 7, font-loading limitation). Adjacent digit keys visually separated with ~6 dp gap; coral gradient Save button distinct from peer keys; dark-mode keys use AppColorsDark.backgroundMuted fill with sufficient contrast; tabular digit glyphs vertically aligned; action row keys equal height; 'Record' label legible across ja/zh/en locales.
result: pass
notes: 6-golden baseline confirmed — key separation, Save gradient, dark-mode contrast, digit alignment all good across ja/zh/en × light/dark.

#### 19-T2: Physical-iOS keypad-feel UAT
expected: Run on a real iPhone (SE or newer). Open ManualOneStepScreen via the "+" tile or fab. Confirm: (a) digit taps register reliably at thumb reach with no double-fires or misses, (b) keypad slides smoothly when merchant/note TextField gains focus, (c) KeyboardToolbar's Done button dismisses the soft keyboard back to the persistent SmartKeyboard, (d) Save button on the SmartKeyboard fires the persist path when amount > 0 + category picked, (e) dark mode keys remain visually discriminable.
result: pass
notes: All five sub-checks verified on physical iPhone — digit taps reliable, keypad slide smooth, Done dismiss path correct, Save path fires, dark-mode discrimination good.

## Summary

total: 9
passed: 9
accepted-with-debt: 0
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps & Resolutions

No gaps. All 9 device UAT items passed across required iOS + Android release builds. No regressions, no debt items recorded, no escalations required.

Closes carried UATs from Phases 19 (T1, T2), 20 (T1, T2, T3), and 22 (T1, T2, T3, T4) per CONTEXT.md D-03.
