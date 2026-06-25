---
quick: 260526-l0o
type: summary
parent: 260526-k92
status: complete
resolution: superseded-by-v1.9
status_reason: "Task 6 device checkpoint moot — voice_category_resolver.dart (the substring-fallback this modified) was deleted in Phase 50 (D-05) and the amount parser rewritten (260622-nhs R6 + Phase 50/52). Comma-tolerant amount + transport keywords are covered by the v1.9 corpus. Marked complete at v1.9 close (2026-06-25)."
commits:
  - dc5e37a  # Issue 1 — comma + 日元
  - 342d576  # Issue 2 — transport synonyms + substring fallback
  - 9276b23  # Issues 3+5 — save always clickable, drop _hostCategory
  - 620d366  # Issue 4 — transcript shrink + golden rebase
  - 5f94743  # Rule 2 hygiene — gitignore **/failures/ for golden diffs
files_modified:
  - lib/application/voice/voice_text_parser.dart
  - lib/application/voice/voice_category_resolver.dart
  - lib/data/daos/category_keyword_preference_dao.dart
  - lib/data/repositories/category_keyword_preference_repository_impl.dart
  - lib/features/accounting/domain/repositories/category_keyword_preference_repository.dart
  - lib/features/accounting/presentation/screens/voice_input_screen.dart
  - lib/shared/constants/default_synonyms.dart
  - lib/shared/constants/voice_currency_suffixes.dart
  - test/fixtures/voice_corpus_zh.dart
  - test/fixtures/voice_corpus_ja.dart
  - test/fixtures/voice_category_corpus_zh.dart
  - test/fixtures/voice_category_corpus_ja.dart
  - test/unit/application/voice/voice_category_resolver_test.dart
  - test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart
  - test/widget/features/accounting/presentation/screens/goldens/voice_input_screen_mic_button_idle.png
files_created:
  - docs/worklog/20260526_1530_voice_followup_fixes.md
---

# Quick task 260526-l0o — Voice follow-up summary

Follow-up to 260526-k92 device test. Five issues from a single reproducer (`昨天做新干线用了12,450日元`) shipped as one logical change in 4 atomic commits.

## One-liner

Fix voice 金额 comma-loss (`12,450日元 → 450`), add Shinkansen + extended transport synonyms with resolver substring fallback, reverse k92's voice-tab default-category gate (save always clickable + submit-time snackbar), and shrink the transcript readout to caption/28dp.

## Per-issue resolution

| # | Issue | Fix | Commit |
|---|-------|-----|--------|
| 1 | `12,450日元 → 450` | Add `日元` to currency suffix set; new comma-tolerant arabic patterns; full-width comma support; digit cap 7→9 | `dc5e37a` |
| 2 | `新干线 → cat_social_drinks` | 13 new transport seeds (新干线/新幹線/Shinkansen/飞机/etc); resolver step 2.5 substring scan over seed rows only (length ≥ 2, longest-wins, conf 0.80) | `342d576` |
| 3 | Voice tab no default category | Drop `_initializeDefaultCategory` + postFrame call; `_canSave = !_isSubmitting` | `9276b23` |
| 5 | Save still gray after voice miss | Remove `_hostCategory` mirror entirely; commit-flow only writes `_hostAmount`; form's internal `_category` is save-time source of truth | `9276b23` |
| 4 | Transcript visual obtrusiveness | `SizedBox` 40→28dp; style `bodyMedium`→`caption`; `maxLines` 2→1; overflow `fade`→`ellipsis`; mic golden re-baselined | `620d366` |

## Test coverage delta

| Test surface | Before | After |
|---|---|---|
| zh number corpus | 50 cases | 55 cases (+5, all pass) |
| ja number corpus | 50 cases | 53 cases (+3, all pass) |
| zh category corpus | 30 cases | 35 cases (+5, all pass) |
| ja category corpus | 30 cases | 34 cases (+3 ja-only; 1 case overlap) — actually +3 new |
| voice screen widget | 18 tests (k92 group of 2) | 22 tests (l0o group of 4) |
| voice mic golden | 1 baseline | 1 re-baselined |
| Manual screen widget | unchanged | unchanged (verified) |

zh corpus accuracy: 96.4% (was 96%). ja corpus accuracy: 100% (was 100%). Both well above 95% gate.

## Verification

- [x] `flutter analyze` 0 issues on touched files
- [x] `flutter analyze` repo-wide: 4 pre-existing infos (k92 baseline, no regression)
- [x] All voice unit + integration + widget tests green (335 tests in focused sweep)
- [x] Mic golden re-baselined and re-verified
- [ ] **Device UAT (Task 6 checkpoint:human-verify)** — 10 verification steps per PLAN.md

## Deferred items (surfaced to user post-checkpoint)

| Item | Status | Rationale |
|------|--------|-----------|
| Orphaned long-text rows in `category_keyword_preferences` from prior `recordCorrection` writes (k92 test polluted user DB) | DEFER, surface to user | Auto-purge is too aggressive. User can either (a) manually re-correct the next 新干线 utterance — DAO upsert bumps the correct row's hitCount above the polluted one over time, or (b) reset app data for a clean slate. A future "Settings → reset voice learning" affordance is candidate for v1.4+ VOICE-POLISH-V2. |
| Audit `category_keyword_preferences` for keys with `length > 20` or punctuation (likely `extractVoiceKeyword` whole-utterance writes that never replay verbatim) | v1.4+ backlog | Cleanup job; out of scope for quick task. |
| Restructure `_extractKeyword` to emit token list (real fix for "exact-match misses long extracted keyword" gap; substring scan is the pragmatic workaround) | v1.4+ backlog | Resolver architectural refactor; out of scope. |
| English transportation synonyms | v1.4+ per REQUIREMENTS.md §Out of scope | `train`/`subway`/`bus`/`taxi`/`flight`/`shinkansen` etc, depends on VOICE-EN-V2-01. |

## Risks (kept in mind for human verify)

- **Pre-existing pollution**: user's local `category_keyword_preferences` may carry hitCount≥1 rows from prior k92 testing that exact-match long utterances → wrong categories. New seeds (hitCount=0) lose the ordering race. Surface to user — manual re-correction recovers over time, or wipe app data for a clean slate.
- **Substring scan false positives**: 2+ char seed inside merchant name (e.g. `飞机楼咖啡店` containing `飞机`) would now miscategorize. Mitigated by length filter + longest-wins. User can recover via `recordCorrection`.

## CLAUDE.md compliance verified

- Immutability: no field mutation; `_hostCategory` removed cleanly (no leftover mutation hazard).
- File organization: no file > 800 lines touched.
- Error handling: existing `Result<…>` patterns preserved; new substring fallback returns `null` on miss like step 2.
- No hardcoded values: `caption` style token reused; suffix set centralized in `VoiceCurrencySuffixes`.
- Zero analyzer warnings on touched files (verified).
- Riverpod 3 conventions: no new providers added; existing patterns preserved.
- DAO/repository pattern: `findAllSeeds()` follows existing `findByKeyword` shape.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical hygiene] Generalize gitignore for golden failure artifacts**

- **Found during:** Task 4 golden re-baseline
- **Issue:** `.gitignore` rule was `test/golden/failures/`, but Flutter writes diff PNGs to `<test-dir>/failures/` next to each golden file. After re-baselining `voice_input_screen_mic_button_idle.png`, 4 stale `*_isolatedDiff.png` / `*_maskedDiff.png` / `*_masterImage.png` / `*_testImage.png` artifacts showed as untracked.
- **Fix:** Added `**/failures/` glob to `.gitignore`. This is hygiene critical because (a) the diff PNGs are regenerated per failed run with potentially-sensitive screen content, and (b) leaving them untracked invites accidental `git add .` from a teammate.
- **Files modified:** `.gitignore`
- **Commit:** `5f94743`

### Plan-vs-implementation differences

| Plan said | Actual | Why |
|---|---|---|
| Add new `VoiceCategoryCase` typedef in fixtures | Reused existing `VoiceCategoryCorpusCase` (already in `voice_category_corpus_zh.dart` / `voice_category_corpus_ja.dart`) | Fixture files already existed with the typedef. Adding a parallel one would be inconsistent. |
| Plan listed `打车回家 → cat_transport_taxi` as a new corpus case | Skipped — already in existing fixture (line 138-142) | Avoid duplicate test cases. |
| Plan said "keep `_hostCategory` field for future use" | Field removed entirely | CLAUDE.md zero-analyzer-warnings hard constraint conflicts with leaving an unused field. The field genuinely had no reader after `_canSave` change. Form's internal `_category` is save-time authority anyway. |

## Self-Check: PASSED

All 5 commit hashes resolve in git log:

- `dc5e37a` FOUND
- `342d576` FOUND
- `9276b23` FOUND
- `620d366` FOUND
- `5f94743` FOUND

All modified production files exist on disk and analyze clean. All test files compile and pass. Worklog file created.
