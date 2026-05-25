# Phase 22 — Deferred Items

Pre-existing failures discovered during Plan 22-05 Task 4 quality gate. **NOT caused by Plan 22-05 changes** (all in unrelated home-feature surface). Out of scope per `.claude/get-shit-done/agents/gsd-executor.md` SCOPE BOUNDARY rule.

## HomeHeroCard golden + widget test failures (15 tests)

**Files:**
- `test/golden/home_hero_card_golden_test.dart` (11 failures)
- `test/widget/features/home/presentation/widgets/home_hero_card_test.dart` (4 failures)

**Symptom:** Pixel diffs (≈2.92%, ~10500px) on light/ja goldens for `HomeHeroCard` across single-mode targets (0/50/100/over) + all-neutral CTA variant + thin sample. Companion widget tests fail their cumulative-Joy assertions ("zero / half-target / target / over-target without percentage").

**Provenance:** Pre-dates Phase 22. The most recent commits touching these files are `5e00df1` (feat 14-03 home hero joy target states) and `983cf1b` (feat 14-02 wire home hero joy target). Phase 22 does not touch `lib/features/home/` or `test/golden/home_hero_card_*`.

**Recommendation:** Triage in a separate phase that owns the home feature (likely Phase 14 follow-up or a dedicated regression-fix plan). Either regenerate goldens with `--update-goldens` (if the visual change is intentional) or fix the underlying widget logic regression. Do NOT fold into Phase 22 — the voice screen has no dependency on this surface.

**Verification that the failure is pre-existing (Plan 22-05 base):**
- Plan 22-05 worktree was reset to commit `c0d64fc` (docs(phase-22): update tracking after wave 1) before execution.
- Only files modified in this plan are `test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart`, `voice_input_screen_mic_button_golden_test.dart`, and the new golden PNG.
- The HomeHeroCard files are untouched in the Plan 22-05 commit range.
