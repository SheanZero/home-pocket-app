---
status: partial
phase: 22-voice-one-step-integration-record-button-ux
source: [22-VERIFICATION.md]
started: 2026-05-25T18:14:00Z
updated: 2026-05-25T18:14:00Z
---

## Current Test

[awaiting human testing]

## Tests

### 1. Physical-touch → first-frame perceived latency (REC-02 SC-4)
expected: State change perceivable within ~100 ms of finger contact on real iOS (≥ iPhone 12) and Android (≥ Pixel 6) release builds. Repeat 5× per device.
result: [pending]

### 2. Real-world ja/zh recognizer end-to-end accuracy (INPUT-02)
expected: On real device hold mic, say "1千8百4十元 星巴克" (zh) or「1840円 スターバックス」(ja), release; form fields auto-populate (amount=1840, merchant set). Repeat 3 utterances per locale.
result: [pending]

### 3. Idle-state golden visual quality (REC-02)
expected: Compare new idle golden against a screenshot of pre-Phase-22 circle mic on same device — no visible aliasing regression at 72×72 rendering.
result: [pending]

### 4. Real-world `_onStatus('notListening')` intermediate behavior (NEW from WR-NEW-01)
expected: On real iOS + Android release builds, hold mic and pause briefly (1-2s) mid-utterance, then resume speaking. `notListening` should NOT fire intra-session during normal recording pauses (if it does, the new G-01 path will prematurely commit a partial transcript). Test 5 sessions per device with varied pause patterns.
result: [pending]

## Summary

total: 4
passed: 0
issues: 0
pending: 4
skipped: 0
blocked: 0

## Gaps
