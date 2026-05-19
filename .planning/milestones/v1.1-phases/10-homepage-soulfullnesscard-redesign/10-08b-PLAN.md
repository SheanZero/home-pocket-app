---
phase: 10-homepage-soulfullnesscard-redesign
plan: 08b
type: execute
wave: 5
depends_on: [08a]
files_modified:
  - lib/features/home/presentation/screens/home_screen.dart
autonomous: true
requirements: [HOMEUI-02]
tags: [home-screen, deletion, cleanup]

must_haves:
  truths:
    - "`_computeHappinessROI`, `_computeSatisfaction`, `_buildLedgerRows` private methods are deleted from `home_screen.dart` — grep returns 0 matches across `lib/`"
    - "Now-unused import `'../models/ledger_row_data.dart'` is removed (since `_buildLedgerRows` referenced `LedgerRowData`)"
    - "Net line count of `home_screen.dart` STRICTLY DECREASES — target < 350 lines (≥36-line net reduction from the original 386 baseline; W7 tightening)"
    - "All `// ignore: unused_element` and `// TODO(plan-10-08b)` markers added by 10-08a are removed (the comment markers were placeholders awaiting deletion)"
    - "`_ErrorText` private widget is preserved (still used by the consolidated `.when()` chain in 10-08a)"
    - "`flutter analyze lib/features/home/` reports 0 issues — including 0 `unused_element` hints"
    - "`flutter analyze lib/` reports 0 issues (whole-project compile)"
    - "Existing `home_screen_test.dart` may still have failing assertions referencing deleted widgets — that's owned by Plan 10-09 + 10-10, NOT this plan"
  artifacts:
    - path: "lib/features/home/presentation/screens/home_screen.dart"
      provides: "home_screen.dart fully cleaned: 3 dead-code helpers gone, unused imports gone, line count below 350"
      max_lines: 349
      contains: "_ErrorText"
  key_links:
    - from: "lib/features/home/presentation/screens/home_screen.dart"
      to: "lib/features/home/presentation/widgets/home_hero_card.dart"
      via: "import + constructor call (still present from 10-08a)"
      pattern: "HomeHeroCard\\("
---

<objective>
Delete the 3 dead-code helpers (`_computeHappinessROI`, `_computeSatisfaction`, `_buildLedgerRows`) that Plan 10-08a left behind, plus their now-unused imports and any `// ignore: unused_element` markers added in 10-08a. Enforce a tight line-count target (< 350) so the rebuild's net line reduction is visible.

This plan is the cleanup half of the 10-08 split per checker blocker B3. It is intentionally a separate plan from 10-08a (the wire-up) so the executor has a checkpoint between "HomeHeroCard renders" and "old code is fully removed". Each half is small and verifiable on its own.

This plan also owns HOMEUI-02 (the helper-deletion success criterion from ROADMAP Phase 10), and applies the W7 tightened line-count threshold (< 350 vs the original 10-08 plan's < 386, which would have allowed a 2-line net reduction to pass).

Output: `home_screen.dart` shrinks from ~386 → ≤349 lines; `flutter analyze` reports 0 hints/warnings/issues across the home feature; grep guards confirm zero remaining references to the 3 deleted helpers anywhere in `lib/`.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@lib/features/home/presentation/screens/home_screen.dart
@lib/features/home/presentation/models/ledger_row_data.dart
</context>

<tasks>

<task type="auto" tdd="false">
  <name>Task 8b.1: Delete the 3 dead-code helpers + unused imports + line-count enforcement</name>
  <files>lib/features/home/presentation/screens/home_screen.dart</files>
  <read_first>
    - lib/features/home/presentation/screens/home_screen.dart (FULL FILE — locate the 3 dead-code helpers + the `'../models/ledger_row_data.dart'` import + any `// TODO(plan-10-08b)` or `// ignore: unused_element` markers added by 10-08a)
    - lib/features/home/presentation/models/ledger_row_data.dart (confirm this file is referenced ONLY by `_buildLedgerRows`; if any other consumer exists in `lib/features/home/`, flag it before deleting the import — but the model file itself stays on disk pending Plan 10-09's broader cleanup)
  </read_first>
  <action>
Edit `lib/features/home/presentation/screens/home_screen.dart` per the following plan.

**Step 1: Delete the 3 helper methods.**

Locate and delete (via reading exact line ranges from the current file — line numbers shifted after 10-08a; do NOT trust the original 386-line ranges):
- `int _computeSatisfaction(AsyncValue<List<Transaction>> txAsync) { ... }` (~14 lines)
- `double _computeHappinessROI(MonthlyReport report) { ... }` (~5 lines)
- `List<LedgerRowData> _buildLedgerRows(...) { ... }` (~66 lines)

Also delete any `// TODO(plan-10-08b): delete this helper` comment markers above each helper (added by 10-08a) and any `// ignore: unused_element` directives above the helpers.

**Step 2: Delete unused imports.**

After Step 1, run a manual scan of the file's import block:
- Remove `import '../models/ledger_row_data.dart';` (only `_buildLedgerRows` referenced `LedgerRowData`).
- Remove any `Transaction` import if `_computeSatisfaction` was the sole consumer in `home_screen.dart` — check by grepping `Transaction` in the file BEFORE deleting the import. If any other code references `Transaction` (e.g., `todayTransactionsProvider` typing), keep the import.
- Remove any `MonthlyReport` import IF `_computeHappinessROI` was the sole consumer — same check applies; the consolidated `.when()` chain in 10-08a likely uses `MonthlyReport` directly, in which case the import stays.

DO NOT delete:
- `'../widgets/home_hero_card.dart'` (10-08a added it, still needed)
- `'../../../analytics/presentation/screens/analytics_screen.dart'` (used by Navigator route from 10-08a)
- Any provider-related imports

**Step 3: Delete any private helper functions/widgets that ONLY existed for the 3 deleted helpers.**

For example, if `_buildLedgerRows` called a private `_buildLedgerRow` helper that nothing else uses, that becomes dead code too — delete it.

Cross-check by running these greps after deletion:
- `grep -E "_buildLedgerRow[^s]|_LedgerRow" lib/features/home/presentation/screens/home_screen.dart` returns 0 matches.

DO NOT delete `_ErrorText` (still used by 10-08a's consolidated `.when()` chain).
DO NOT delete the `todayTransactionsProvider` watch (may be used by `TransactionListCard`).

**Step 4: Run analyzer + verify line count.**

```bash
flutter analyze lib/features/home/
flutter analyze lib/
wc -l lib/features/home/presentation/screens/home_screen.dart
```

Expected:
- `flutter analyze lib/features/home/` reports "No issues found" — including ZERO `unused_element` or `unused_import` hints.
- `flutter analyze lib/` reports "No issues found" (whole-project — no external file referenced the 3 deleted helpers).
- `wc -l` returns ≤ 349 (W7 target — strict 36-line reduction floor from original 386).

If `wc -l` returns > 349, INVESTIGATE:
- Did 10-08a's consolidated `.when()` chain bloat past expectations? Refactor by extracting a `_buildHomeHeroCardSection(...)` private method to consolidate the chain. (This is BUDGET-saving refactor, NOT scope creep — keeps the line count goal honest.)
- Are there comments left from 10-08a's TODO markers? Strip them.
- Are imports sorted with extra blank lines? Compact them.

If after 30 minutes of legitimate refactor the file still cannot fit ≤ 349 lines, document the actual minimum achieved (e.g., 358) in the SUMMARY and flag for human review — DO NOT exceed scope by introducing new abstractions.

**Step 5: Final grep guards.**

```bash
grep -q "_computeHappinessROI\|_computeSatisfaction\|_buildLedgerRows" lib/  # exit code 1
grep -q "import '../models/ledger_row_data.dart'" lib/features/home/presentation/screens/home_screen.dart  # exit code 1
grep -q "TODO(plan-10-08b)\|ignore: unused_element" lib/features/home/presentation/screens/home_screen.dart  # exit code 1
```

All three must return exit code 1 (no matches).

**Forbidden:**
- DO NOT modify the consolidated `.when()` chain or HomeHeroCard call from 10-08a (except to extract it into a private builder helper IF needed for line-count compliance — see Step 4 escape hatch).
- DO NOT delete `'../models/ledger_row_data.dart'` THE FILE itself — only its import from `home_screen.dart`. Other deletions are owned by Plan 10-09.
- DO NOT touch `home_screen_test.dart` — Plan 10-09 + 10-10 own the test updates.
- DO NOT add new abstractions (e.g., `combineAsyncValues` extension); the .when() chain stays as-is.
- DO NOT re-introduce hardcoded `'JPY'`. The single `'JPY'` literal from 10-08a's currency fallback must remain — Pitfall #9 comment marker is the only legitimate site.
  </action>
  <verify>
    <automated>flutter analyze lib/features/home/ 2>&1 | grep -q "No issues found" && wc -l lib/features/home/presentation/screens/home_screen.dart | awk '{print ($1 < 350) ? "OK" : "FAIL"}' | grep -q OK</automated>
  </verify>
  <acceptance_criteria>
    - `grep -q "_computeHappinessROI\|_computeSatisfaction\|_buildLedgerRows" lib/` returns exit code 1 (NO matches across the entire `lib/`)
    - `grep -q "import '../models/ledger_row_data.dart'" lib/features/home/presentation/screens/home_screen.dart` returns exit code 1 (import removed)
    - `grep -q "TODO(plan-10-08b)" lib/features/home/presentation/screens/home_screen.dart` returns exit code 1 (no TODO markers remain)
    - `grep -q "ignore: unused_element" lib/features/home/presentation/screens/home_screen.dart` returns exit code 1 (no ignore directives for the deleted helpers)
    - `wc -l lib/features/home/presentation/screens/home_screen.dart | awk '{print ($1 < 350)}'` returns 1 (line count < 350 — W7 tightening)
    - `wc -l lib/features/home/presentation/screens/home_screen.dart | awk '{print ($1 > 250)}'` returns 1 (sanity floor — file should not collapse below 250 lines; that would mean accidental deletion)
    - `grep -q "_ErrorText" lib/features/home/presentation/screens/home_screen.dart` returns exit code 0 (preserved)
    - `grep -q "Pitfall #9\|fallback only when Book is missing" lib/features/home/presentation/screens/home_screen.dart` returns exit code 0 (B4 comment marker from 10-08a preserved)
    - `grep -c "'JPY'" lib/features/home/presentation/screens/home_screen.dart` returns exactly 1 (only the documented fallback)
    - `grep -q "HomeHeroCard(" lib/features/home/presentation/screens/home_screen.dart` returns exit code 0 (10-08a's wire-up preserved)
    - `flutter analyze lib/features/home/` reports "No issues found"
    - `flutter analyze lib/` reports "No issues found"
  </acceptance_criteria>
  <done>
home_screen.dart no longer contains _computeHappinessROI, _computeSatisfaction, _buildLedgerRows, or the LedgerRowData import; all TODO/ignore markers from 10-08a are removed; line count is < 350 (W7 tightening); flutter analyze is clean across the whole home feature AND across `lib/`; all 10-08a artifacts (HomeHeroCard wire-up, _ErrorText, Pitfall #9 comment marker) are preserved.
  </done>
</task>

</tasks>

<verification>
- `grep -c "_computeHappinessROI\|_computeSatisfaction\|_buildLedgerRows" lib/` returns 0
- `wc -l lib/features/home/presentation/screens/home_screen.dart` returns < 350 (W7 target)
- `flutter analyze lib/features/home/` 0 issues, 0 hints, 0 warnings
- 10-08a artifacts (HomeHeroCard wire-up, currency fallback comment marker) preserved
</verification>

<success_criteria>
- 3 obsolete helpers gone from `lib/` entirely
- File line count below 350 (W7-tightened threshold; ≥36-line net reduction from 386 baseline)
- `flutter analyze` clean across the whole project
- HomeHeroCard wire-up from 10-08a unchanged
</success_criteria>

<output>
After completion, create `.planning/phases/10-homepage-soulfullnesscard-redesign/10-08b-SUMMARY.md` recording: pre/post line counts (10-08a delivered → 10-08b delivered), the 3 deleted helper line ranges, the deleted imports, and any extracted private builders (Step 4 escape hatch) if used.
</output>
