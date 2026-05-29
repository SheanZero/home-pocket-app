---
quick_id: 260529-gbp
description: 语音选中灵魂支出 category 时满足度默认应为 2(估算器中性基线修正)
date: 2026-05-29
status: complete
commit: 11120ca
---

# Quick Task 260529-gbp — Summary

## Bug & root cause

Voice soul-ledger entries pre-filled the satisfaction picker to the middle
faces (~5–6) instead of the form default `2`. The voice flow estimates
satisfaction from audio/text (`VoiceSatisfactionEstimator`) and pushes it into
the form (`voice_input_screen.dart:365`). The estimator's `_mapToSatisfaction`
used `0.3 + score*0.7`, whose 0.3 floor mapped a neutral weighted-score (~0.3)
to ~5.

## Fix (owner decision: keep estimator, neutral → 2)

`voice_satisfaction_estimator.dart` `_mapToSatisfaction`: floor-based map →
linear fit anchored on the estimator's own band:

- neutral utterance score ≈ 0.26 → **2**
- excited + positive ≈ 0.56 → **7**
- `sat = round(-2.4 + 16.7·score)`, clamped 1..10

Steep slope is required because the upstream sub-scores compress the neutral
and excited bands close together; a gentler curve could not keep neutral at 2
**and** excited ≥ 7 **and** negative < neutral simultaneously. The clamp keeps
strong positives at 10 and negatives at 1.

When the estimator returns 2 it equals the form default, so
`updateSatisfaction` no-ops and the picker stays on the default left face.

## Verification

- `flutter analyze`: **0 issues**
- `voice_satisfaction_estimator_test.dart`: updated neutral expectations
  (calm 4-6 → 1-3; empty 3-5 → 1-4); excited 7-10 / negative<neutral / range
  1-10 unchanged — **all pass**
- `voice_input_screen_test.dart` (uses `FakeVoiceSatisfactionEstimator`=9):
  **28 pass**
- Device visual check: pending (owner) — re-record a neutral soul entry; picker
  should rest at the default left face (~2).

## Behavior note

With the current sub-scoring, clearly-neutral speech maps to ~2 and speech with
some energy/length to ~3–4 (down from the old 5–6). If the owner wants even
energetic-neutral speech pinned hard at 2, the next step is de-biasing the
sub-score aggregation (wider neutral plateau) — flagged, not done here.

## Out of scope (pre-existing)

`VoiceParseResult.estimatedSatisfaction` `@Default(5)` + vacuous `!= null`
apply guard (L364) — tracked Phase 22 advisory; untouched (needs freezed regen,
unrelated to the soul-default bug).
</content>
