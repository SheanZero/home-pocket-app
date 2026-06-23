---
phase: 49-merchant-data-foundation
plan: 02
subsystem: infra
tags: [dart, unicode, kana-normalization, nfkc, merchant-matching, tdd]

# Dependency graph
requires:
  - phase: 49-01
    provides: merchants + merchant_match_keys schema (v22) whose match_key column this fills
provides:
  - "normalizeMerchantKey(String) — single shared seed-time + query-time merchant match-key normalizer"
  - "MerchantNameNormalizer.key() typed wrapper around the top-level function"
  - "Hand-written NFKC-lite + kana fold (zero new deps): fullwidth→halfwidth, full+half-width katakana→hiragana, combining dakuten/handakuten compose, lowercase, 中黒/space strip; keeps ー and small kana"
affects: [49-05 SeedMerchantsUseCase, phase-50 MerchantRecognizer query-time matching]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Rune-pass fold with const lookup tables for half-width-katakana expansion + dakuten/handakuten composition"
    - "Property-style held-out test (table of input/expected pairs) + idempotency invariant group"

key-files:
  created:
    - lib/infrastructure/ml/merchant_name_normalizer.dart
    - test/unit/infrastructure/ml/merchant_name_normalizer_test.dart
  modified: []

key-decisions:
  - "Top-level function normalizeMerchantKey is the canonical API; MerchantNameNormalizer.key() is a thin typed wrapper (callers may use either)"
  - "All folds land in the HIRAGANA namespace so half-width katakana, standard katakana, and combining-mark composition share one set of compose tables"
  - "Orphan combining/voicing marks with no composable base are dropped (cannot corrupt the key) rather than passed through"
  - "ASCII hyphen is kept (7-Eleven → 7-eleven); only 中黒 ・ and whitespace are stripped"

patterns-established:
  - "Single normalizer reused unchanged across seed-time and query-time (build-complete-now to avoid Phase 50 fork)"
  - "Unicode block offsets (fullwidth −0xFEE0, katakana→hiragana −0x60) + explicit voicing/half-width tables instead of any package"

requirements-completed: [MERCH-02]

# Metrics
duration: 3min
completed: 2026-06-23
status: complete
---

# Phase 49 Plan 02: Merchant Name Normalizer Summary

**Hand-written zero-dependency `normalizeMerchantKey` folding fullwidth→halfwidth, full + half-width katakana→hiragana with combining dakuten/handakuten composition, lowercase, and 中黒/whitespace strip — the single seed-time AND Phase-50 query-time merchant match-key function, verified by a 66-assertion property-style + idempotency test.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-06-23T05:42:45Z
- **Completed:** 2026-06-23T05:45:46Z
- **Tasks:** 2 (TDD: RED + GREEN)
- **Files modified:** 2 (both created)

## Accomplishments
- `normalizeMerchantKey(String)` implements the complete D-03 / RESEARCH #2 pipeline in one rune pass over `input.runes`, with zero new package dependencies.
- Half-width katakana (U+FF61..FF9F) is expanded to standard kana and folded to hiragana, composing a trailing half-width dakuten (ﾞ) / handakuten (ﾟ) onto the base (`ｾﾌﾞﾝ → せぶん`, `ﾊﾟﾝ → ぱん`, `ｶﾞ → が`).
- Combining dakuten/handakuten (U+3099/309A) after a base hiragana compose so `か`+◌゙ == precomposed `が`; katakana `ガ`+◌゙ folds to `が`.
- 長音符 ー (U+30FC) and small kana (ァィゥェォッ) are KEPT (no over-merge); 中黒 ・ and whitespace stripped; output lowercased.
- Function is idempotent — `normalize(normalize(x)) == normalize(x)` proven over every test input.

## Task Commits

Each task was committed atomically:

1. **Task 1: Property-style normalizer test (RED)** - `b7d4d87e` (test)
2. **Task 2: Implement merchant_name_normalizer (GREEN)** - `d88ee079` (feat)

_TDD: RED test commit precedes GREEN implementation commit. No REFACTOR commit needed — implementation was clean on first pass._

## Files Created/Modified
- `lib/infrastructure/ml/merchant_name_normalizer.dart` - Top-level `normalizeMerchantKey(String)` + `MerchantNameNormalizer.key()` wrapper; const lookup tables for half-width-katakana→hiragana and dakuten/handakuten composition. Zero package imports.
- `test/unit/infrastructure/ml/merchant_name_normalizer_test.dart` - 33-row `const expectedPairs` property table across width/kana/case/combining + half-width + strip/keep cases, plus an idempotency invariant group over all inputs (66 assertions total).

## Decisions Made
- **Hiragana as the single target namespace:** half-width katakana, standard katakana, and combining-mark composition all resolve to hiragana codepoints, so one pair of compose tables (`_composeDakuten` / `_composeHandakuten`) serves both the half-width path and the combining-mark path. Rationale: avoids duplicate katakana+hiragana voicing tables.
- **Drop orphan combining/voicing marks:** a U+3099/U+309A or standalone half-width ﾞ/ﾟ with no composable preceding base is dropped, not emitted — keeps the match-key clean and preserves idempotency.
- **Keep ASCII hyphen:** only 中黒 ・ and whitespace are stripped (per D-03); ASCII `-` is meaningful in surfaces like `7-Eleven` and is retained.

## Deviations from Plan

None - plan executed exactly as written. Both tasks followed the TDD RED→GREEN flow specified; the normalizer was built complete (incl. half-width katakana + combining marks) as the plan and RESEARCH directed, so Phase 50 reuses it unchanged.

## Issues Encountered
None. The combining-dakuten test inputs are genuine base+combining sequences (verified via `od -c`: か + U+3099, は + U+309A, カ + U+3099), so the compose path is exercised authentically rather than testing precomposed-to-precomposed passthrough.

## User Setup Required
None - pure in-memory string utility; no external service configuration required.

## Next Phase Readiness
- `normalizeMerchantKey` is ready for Plan 49-05 (`SeedMerchantsUseCase`) to compute each `merchant_match_keys.match_key` at seed time.
- The same function is the Phase-50 query-time match-key entry point — no fork or re-implementation required.
- No blockers.

## Self-Check: PASSED

- `lib/infrastructure/ml/merchant_name_normalizer.dart` — FOUND
- `test/unit/infrastructure/ml/merchant_name_normalizer_test.dart` — FOUND
- Commit `b7d4d87e` (RED test) — FOUND
- Commit `d88ee079` (GREEN impl) — FOUND
- `flutter test` on the normalizer → 66/66 passed
- `flutter analyze` on both files → No issues found
- Package imports in normalizer → 0

---
*Phase: 49-merchant-data-foundation*
*Completed: 2026-06-23*
