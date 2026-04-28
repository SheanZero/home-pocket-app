## Plan 08-04 finding (2026-04-28)

**Issue:** `lib/features/accounting/presentation/widgets/amount_display.dart` is NOT in `.planning/audit/cleanup-touched-files.txt` (Phase 3-6 union). Plan 08-04 verification expected all three production widgets under test (amount_display.dart, summary_cards.dart, soul_fullness_card.dart) to be tracked there, but only the latter two are.

**Root cause:** Phase 3-6 plan `files_modified` frontmatter did not include `amount_display.dart` for any plan, so the generator script (Plan 08-02 deliverable) emitted it absent. This is a Phase 3-6 frontmatter completeness issue, not a Plan 08-04 issue.

**Impact:** Coverage from `test/golden/amount_display_golden_test.dart` will not flow into the `cleanup-touched-files.txt` 80% gate for `amount_display.dart` specifically. The other two surfaces (summary_cards, soul_fullness_card) are correctly tracked.

**Disposition:** Out of Plan 08-04 scope (would require re-running Phase 3-6 plan-frontmatter audit + regenerating cleanup-touched-files.txt). Plan 08-06 (coverage baseline regen) is the natural place to revisit this — if amount_display.dart was indeed touched in Phases 3-5 (e.g., AppTextStyles.amountLarge enforcement per Phase 5 D-17..D-20), the Phase 3-6 plan frontmatter should be amended and the cleanup-touched-files.txt regenerated. Tracked here so Plan 08-06 catches it.

