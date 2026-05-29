---
quick_id: 260529-gbp
description: 语音选中灵魂支出 category 时满足度默认应为 2(估算器中性基线修正)
date: 2026-05-29
mode: quick
---

# Quick Task 260529-gbp — Voice soul satisfaction default = 2

## Bug

When voice input resolves a soul-expense category, the satisfaction picker
pre-filled to the **middle** faces (~value 5–6) instead of the form default
`2`. Reproduced with a neutral utterance ("购买一个高达手板，用了4220日元").

### Root cause

`voice_input_screen.dart` runs `VoiceSatisfactionEstimator.estimate()` for soul
ledger on parse (`~L526`) and pushes the result into the form via
`state.updateSatisfaction(...)` (`L365`). `VoiceSatisfactionEstimator
._mapToSatisfaction` used `0.3 + score*0.7` — a high floor that mapped a
neutral weighted-score (~0.3) to ~5, i.e. the middle emoji.

## Decision

Per owner: **keep** the audio/text estimator, but re-anchor its mapping so
neutral / weak signal rests at **2** and only clear positive signal climbs
toward 10 (negative sentiment dips to 1).

## Task

- **files:** `lib/application/voice/voice_satisfaction_estimator.dart`
- **action:** Replace `_mapToSatisfaction` floor-based map with a linear fit
  anchored on the estimator's own signal band — neutral score ≈0.26 → 2,
  excited+positive ≈0.56 → 7 (`slope 16.7`, `offset -2.4`, clamp 1..10). Steep
  by necessity: upstream sub-scores compress the neutral and excited bands
  close together.
- **tests:** `test/unit/application/voice/voice_satisfaction_estimator_test.dart`
  — update the two neutral expectations (calm 4-6 → 1-3, empty 3-5 → 1-4) to
  the new resting contract. Excited 7-10, negative<neutral, range 1-10 unchanged.
- **verify:** `flutter analyze` 0; estimator unit test + voice screen widget
  test green; device visual check.
- **done:** Neutral soul voice entries default to ~2; positive speech still
  raises satisfaction.

## Notes / out of scope

- `VoiceParseResult.estimatedSatisfaction` is `@Default(5)` and the apply guard
  `if (... != null)` (L364) is vacuous (non-nullable int). For survival voice
  this pushes 5 into `_soulSatisfaction` (unused while survival). Pre-existing
  Phase 22 advisory (vacuous-null-check WR); left untouched — fixing needs a
  freezed regen and is not the reported soul-default bug.
- Widget tests use `FakeVoiceSatisfactionEstimator` (returns 9), so they are
  insulated from the real mapping change.
</content>
