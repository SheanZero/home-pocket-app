---
phase: 23-v1-3-cleanup-scanner-allow-lists-voice-flow-polish
plan: 03
subsystem: voice-category-resolver, seed-corpus, integration-tests
tags: [phase-21-polish, seed-corpus, voice-category-resolver, cleanup]
requirements: []
requirements-completed: []
decisions-implemented: [D-15]
decision-divergences:
  - "D-15 test location: planned in voice_corpus_*_test.dart per CONTEXT.md but landed in voice_category_corpus_*_test.dart per PATTERNS.md Option 1 — resolver tests, not parser tests. en file at voice_corpus_en_test.dart path per CONTEXT.md verbatim (no voice_category_corpus_en file exists)."
  - "Task 3.1 (seed rows) was pre-completed by Plan 01 (commit d779bc6). The three D-15 seed rows (その他/其他/other → cat_other_expense) were committed atomically with the Phase 23 D-12 constant extraction work per RESEARCH Pitfall 5. No duplicate commit was made; acceptance criteria verified in-place."
dependency-graph:
  requires: [23-01]
  provides: [D-15-corpus-coverage, en-hedge-skeleton]
  affects: [voice-category-resolver, category-keyword-preference-dao]
tech-stack:
  added: []
  patterns: [resolver-driven-corpus-test, single-case-hedge-skeleton]
key-files:
  created:
    - test/integration/voice/voice_corpus_en_test.dart
  modified:
    - test/integration/voice/voice_category_corpus_zh_test.dart
    - test/integration/voice/voice_category_corpus_ja_test.dart
decisions:
  - "D-15 resolver anchors land in voice_category_corpus_zh/ja_test.dart (resolver semantics) not voice_corpus_zh/ja_test.dart (parser semantics) per PATTERNS.md Option 1"
  - "en hedge file placed at voice_corpus_en_test.dart per CONTEXT.md D-15 verbatim (no voice_category_corpus_en counterpart exists)"
  - "Task 3.1 seed rows already committed in Plan 01 (d779bc6) — no duplicate commit; plan executed in logical order"
metrics:
  duration: "~10 minutes"
  completed_date: "2026-05-25"
  tasks_completed: 2
  tasks_total: 2
  files_changed: 3
---

# Phase 23 Plan 03: Phase 21 IN-06 Corpus Anchors + en Hedge Skeleton Summary

D-15 end-to-end override coverage via real corpus utterances: zh/ja resolver anchor cases in `voice_category_corpus_*_test.dart` + single-case en hedge skeleton `voice_corpus_en_test.dart`, exercising the `cat_other_expense → cat_other_other` override path in `VoiceCategoryResolver._ensureL2`.

## What Was Built

### Task 3.1: Three Override-Trigger Seed Rows (Pre-completed by Plan 01)

The three D-15 seed rows were already committed in Plan 01 (commit d779bc6) as part of the atomic constant dedup work per RESEARCH Pitfall 5. Verified in-place:

- `_seed('その他', 'cat_other_expense')` — Japanese "other"
- `_seed('其他', 'cat_other_expense')` — Chinese "other"
- `_seed('other', 'cat_other_expense')` — English "other" (v1.4+ hedge)

Section header with "Phase 23 D-15" comment block is present at line 109 of `default_synonyms.dart`.

### Task 3.2: Corpus Test Extensions + en Hedge Skeleton

**Extended `test/integration/voice/voice_category_corpus_zh_test.dart`:**

Added a new group `'D-15 other-expense override (Phase 23 / IN-06)'` with:
```dart
test('D-15: "其他" -> cat_other_other override (Phase 23)', () async {
  final result = await resolver.resolve('其他');
  expect(result, isNotNull, reason: '...');
  expect(result!.categoryId, 'cat_other_other');
});
```
All existing tests continue to pass (32/32 total, 100%).

**Extended `test/integration/voice/voice_category_corpus_ja_test.dart`:**

Parallel D-15 group with:
```dart
test('D-15: "その他" -> cat_other_other override (Phase 23)', () async {
  final result = await resolver.resolve('その他');
  expect(result, isNotNull, reason: '...');
  expect(result!.categoryId, 'cat_other_other');
});
```
All existing tests continue to pass (33/33 total, 100%).

**Created `test/integration/voice/voice_corpus_en_test.dart` (NEW):**

Single-case resolver-driven hedge skeleton per CONTEXT.md D-15 and RESEARCH Open Q4. Uses the same provider-scope + direct `VoiceCategoryResolver` construction pattern as `voice_category_corpus_zh_test.dart`:
- `setUpAll`: seeds categories + voice synonyms via leaf use case providers
- Constructs `VoiceCategoryResolver` directly (RESEARCH Pitfall 8 — leaf providers)
- Single test: `'other' → cat_other_other` via `cat_other_expense` override path
- File-header docstring documents the v1.3 scope boundary and Pitfall 6 warning

## Verification Results

| Check | Result |
|-------|--------|
| `flutter analyze` (3 test files) | 0 issues |
| `flutter analyze` (default_synonyms.dart) | 0 issues |
| `flutter test voice_category_corpus_zh_test.dart` | PASS (32/32) |
| `flutter test voice_category_corpus_ja_test.dart` | PASS (33/33) |
| `flutter test voice_corpus_en_test.dart` | PASS (1/1) |
| `grep -c "_seed('その他'"` in default_synonyms.dart | 1 |
| `grep -c "_seed('其他'"` in default_synonyms.dart | 1 |
| `grep -c "_seed('other'"` in default_synonyms.dart | 1 |
| `grep -c "Phase 23 D-15"` in default_synonyms.dart | 1 |
| `grep -c "D-15"` in voice_category_corpus_zh_test.dart | 4 |
| `grep -c "D-15"` in voice_category_corpus_ja_test.dart | 4 |
| `grep -c "D-15"` in voice_corpus_en_test.dart | 6 |

## Deviations from Plan

### Task 3.1 Pre-completed by Plan 01

**[No Rule needed — clean pre-completion]**
- **Found during:** Worktree startup (reading default_synonyms.dart after resetting to wave 1 base)
- **Issue:** The 23-01 SUMMARY noted D-15 seed rows were added in Plan 01 commit d779bc6 per RESEARCH Pitfall 5 (atomic constant work). Task 3.1 was therefore complete before Plan 03 started.
- **Action:** Verified acceptance criteria in-place (grep checks all pass); no duplicate commit made.

### Test Location: PATTERNS.md Option 1 over CONTEXT.md

**[Planned divergence — recorded per quality_gate item]**
- CONTEXT.md D-15 specified anchors in `voice_corpus_zh/ja_test.dart` (parser files)
- PATTERNS.md notes those files exercise the number parser, not the resolver
- This plan explicitly follows PATTERNS Option 1: resolver assertions in `voice_category_corpus_zh/ja_test.dart`
- The en file uses the CONTEXT.md path verbatim (`voice_corpus_en_test.dart`) since no `voice_category_corpus_en_test.dart` counterpart exists

## Known Stubs

None — the D-15 override path resolves end-to-end via real seed data. The en hedge is intentionally a single case per CONTEXT.md D-15 ("Do NOT expand en corpus coverage beyond this one case").

## Threat Flags

No new network endpoints, auth paths, file access patterns, or schema changes introduced. Seed insertion mode (INSERT OR IGNORE) is unchanged. The `other` synonym collision risk (T-23-03-03) is documented in the seed comment block and deferred to v1.4+ per threat register disposition.

## Self-Check

- [x] `test/integration/voice/voice_category_corpus_zh_test.dart` — FOUND (modified)
- [x] `test/integration/voice/voice_category_corpus_ja_test.dart` — FOUND (modified)
- [x] `test/integration/voice/voice_corpus_en_test.dart` — FOUND (created)
- [x] `lib/shared/constants/default_synonyms.dart` — FOUND (seed rows present from Plan 01)
- [x] Commit 0b6bbdd — FOUND (Task 3.2: D-15 corpus anchors + en hedge)

## Self-Check: PASSED

All files exist, commit verified in git log.
