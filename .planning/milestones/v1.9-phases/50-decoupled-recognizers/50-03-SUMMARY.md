---
phase: 50-decoupled-recognizers
plan: 03
subsystem: voice-recognition
status: complete
tags: [recognizer, merchant, scoring, tdd, decoup-03, sc2, sc3]
requirements_completed: [DECOUP-03]
dependency_graph:
  requires:
    - "50-01: MerchantCandidate / MerchantMatchEntry models + MerchantRepository.loadAllForMatching()"
    - "49: normalizeMerchantKey seed-side normalizer + ~400-merchant seed (DefaultMerchants)"
  provides:
    - "MerchantRecognizer — anchored normalized scorer over merchant_match_keys (recall-first ranked candidates)"
    - "merchant_false_positive_corpus — ~39 adversarial entries (the SC2 gate fixture)"
  affects:
    - "50-05 orchestrator (consumes recognize() + applies the 0.85 auto-fill floor)"
tech_stack:
  added: []
  patterns:
    - "load-once warm cache (_cache ??= await loadAllForMatching()) mirroring voice_category_resolver _seedCache"
    - "anchored scoring tiers replacing bidirectional substring (exact/prefix/containment/reverse)"
    - "per-script min-length guard + > 50% prefix-coverage guard (A1/A2)"
key_files:
  created:
    - lib/application/voice/recognition/merchant_recognizer.dart
    - test/fixtures/merchant_false_positive_corpus.dart
    - test/unit/application/voice/recognition/merchant_recognizer_test.dart
    - test/unit/application/voice/recognition/merchant_false_positive_test.dart
  modified: []
decisions:
  - "Prefix tier gets BOTH a per-script min-length guard AND a strict > 50% rune-coverage guard — min-length alone let 大阪/the/cafe prefix-fill medium brand surfaces (real SC2 false positives caught by the full-seed gate)."
  - "モス removed from the adversarial corpus — it is a genuine seeded MOS Burger alias (exact 1.00), not adversarial."
  - "recognize() is async (awaits the one-time warm-up) and returns [] for empty/blank normalized query to avoid startsWith('') matching every row."
metrics:
  tasks_completed: 2
  files_created: 4
  files_modified: 0
  tests_added: 18
  corpus_entries: 39
  engine_lines: 169
  completed_date: 2026-06-24
---

# Phase 50 Plan 03: MerchantRecognizer Anchored Scorer Summary

Built `MerchantRecognizer` — the only genuinely new logic in Phase 50: a pure-Dart, recall-first anchored normalized scorer over Phase-49's `merchant_match_keys`, replacing the retired bidirectional-substring lookup. Validated TDD with a scoring-tier test plus a ~39-entry adversarial false-positive corpus proving SC2 (no false auto-fills) and SC3 (bare スタバ and its surface variants resolve at ≥0.85).

## What was built

- **`MerchantRecognizer`** (`lib/application/voice/recognition/merchant_recognizer.dart`, 169 lines): takes ONLY a `MerchantRepository` (constructionally independent of the keyword recognizer — DECOUP-01), warms a nullable `_cache` once via `loadAllForMatching()`, and exposes `Future<List<MerchantCandidate>> recognize(String query)`. Reuses `normalizeMerchantKey` verbatim on the query side (Pitfall 1) so query and seed keys live in one space. Never logs the query or candidate names (V7).
- **Scoring tiers** (`_scoreOf(nq, mk)`): exact `1.00`, anchored-prefix `0.85`, containment `0.60`, reverse-containment `0.55`. Every non-exact tier is gated by `_passesScriptMinLength` on the shorter string (kanji-containing ≥2 runes via a CJK-ideograph range check; kana/latin ≥3 runes). The prefix tier carries an additional strict `> 50%` rune-coverage guard.
- **Ranking/dedupe**: score-DESC then longer-matchKey-first; one `MerchantCandidate` per `merchantId` (best-scoring surface kept).
- **`merchant_false_positive_corpus.dart`**: 39 adversarial entries (お米/杉並区/place-names/comment-words/chain-substring fragments/generic latin words).
- **Two tests**: `merchant_recognizer_test.dart` (16 cases — tiers, four SC3 surface forms, ranking/dedupe, normalize-equality, empty/no-match) and `merchant_false_positive_test.dart` (2 cases — corpus shape + the SC2 gate run against the FULL ~400-merchant seed expanded into match entries).

## Success criteria

- `MerchantRecognizer` scores anchored tiers + script-min-length, reusing `normalizeMerchantKey` verbatim — DONE.
- Bare スタバ / ｽﾀﾊﾞ / マクド / Starbucks each resolve at ≥0.85 (SC3) — DONE (all hit exact 1.00 against their seeded alias surfaces).
- ~39 adversarial entries all stay below the 0.85 floor (SC2) — DONE, verified against the full seed.
- Engine constructionally independent of the keyword recognizer (DECOUP-01) and logs nothing — DONE (grep gates clean).

## Verification

- `flutter test` (both new files): 18/18 GREEN.
- `flutter analyze` (whole project): No issues found.
- `grep -E "import.*category_recognizer|CategoryRecognizer" lib/application/voice/recognition/merchant_recognizer.dart` → clean (no match).
- `grep -nE "print\(|developer.log|\.log\(" …merchant_recognizer.dart` → clean (no match).
- `grep normalizeMerchantKey …merchant_recognizer.dart` → present (reused, no second normalizer).
- `grep loadAllForMatching …merchant_recognizer.dart` → present.

## TDD Gate Compliance

- RED commit `896d18aa` (`test(50-03):`) — the scoring-tier test, adversarial corpus, and SC2 gate written first; failed to compile against the missing engine.
- GREEN commit `74f9011d` (`feat(50-03):`) — engine implemented; both tests pass.
- No separate REFACTOR commit: `_scoreOf` was extracted as a pure helper inside the GREEN implementation (no behavior-only cleanup pass was needed).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical guard] Prefix tier needed a coverage guard, not just min-length**
- **Found during:** Task 2 GREEN (the SC2 gate against the full ~400-merchant seed).
- **Issue:** The plan's anchored-prefix tier (`mk.startsWith(nq) || nq.startsWith(mk)` → 0.85) with only a per-script min-length guard let real generic words and place names prefix-fill medium-length brand surfaces at the 0.85 floor: `米`→米屋本舗 (1 kanji prefix), then `大阪`→大阪王将 (2/4), `the`→thebig (3/6), `cafe`→caferenoir (4/10). These are exactly the SC2 false positives the corpus exists to catch.
- **Fix:** Extended the prefix tier with (a) the same `_passesScriptMinLength` guard applied to the shorter string, and (b) a strict `shorterRunes * 2 > longerRunes` (> 50% rune coverage) requirement. Exact key equality (seeded short aliases like スタバ) bypasses both guards, so SC3 is unaffected. Substantial prefixes (まくどな ⊂ まくどなるど, 4/6) still score 0.85.
- **Files modified:** `lib/application/voice/recognition/merchant_recognizer.dart`.
- **Commit:** `74f9011d`.

**2. [Rule 1 - Test correctness] モス is a real alias, not adversarial**
- **Found during:** Task 2 GREEN. The corpus included `モス` as a "short fragment"; the full seed has `モス` as an authored MOS Burger alias, so it correctly resolves exact (1.00).
- **Fix:** Removed `モス` from the corpus (with a comment explaining why) and replaced the original `モス ⊂ モスバーガー` prefix-tier test with a min-length-passing genuine prefix (`まくどな ⊂ マクドナルド`) plus a below-guard `モス`-does-not-fill assertion.
- **Files modified:** `test/fixtures/merchant_false_positive_corpus.dart`, `test/unit/application/voice/recognition/merchant_recognizer_test.dart`.
- **Commit:** `74f9011d`.

## Threat surface

No new security-relevant surface beyond the plan's `<threat_model>`. T-50-04 (no query/candidate logging) and T-50-05 (substring false positives) are both mitigated and gated by tests/greps. The engine reads only the warm in-memory cache — no SQL is built from the transcript (T-50-01).

## Known Stubs

None. The engine is fully wired to the real `MerchantRepository.loadAllForMatching()` contract; provider wiring + orchestrator consumption is Plan 05's scope (per the phase decomposition), not a stub in this plan.

## Self-Check: PASSED
