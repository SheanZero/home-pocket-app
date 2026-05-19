---
phase: 12-ui-copy-rename-pass-arb-values-ja-zh-en
plan: 02
type: execute
wave: 2
depends_on:
  - 12-ui-copy-rename-pass-arb-values-ja-zh-en/01
files_modified:
  - lib/features/accounting/presentation/widgets/satisfaction_emoji_picker.dart
  - test/widget/features/accounting/presentation/widgets/satisfaction_emoji_picker_test.dart
autonomous: true
requirements:
  - RENAME-05
  - RENAME-06
user_setup: []

must_haves:
  truths:
    - "Picker `_icons` const array equals D-01 sentiment-positive ladder: [sentiment_neutral_outlined, sentiment_satisfied_outlined, sentiment_satisfied_alt_outlined, sentiment_very_satisfied_outlined, favorite_border]"
    - "All 5 IconData identifiers exist in Flutter Material Icons (verified at planner time: 5/5 present in flutter@3.41.8 icons.dart)"
    - "satisfaction_emoji_picker_test.dart asserts the new JP labels (無難 / 快適 / 順調 / 満足 / 至福 + 至福！ bottom hint) and still pins the post-v16 unipolar value mapping {2,4,6,8,10}"
    - "Forbidden patterns NOT introduced: zero references to sentiment_dissatisfied / sentiment_very_dissatisfied in lib/ (ADR-014 + Phase 12 binding — picker may never re-introduce negative-emotion icons)"
    - "_faceValues constant unchanged ([2, 4, 6, 8, 10]); _selectedIndex mapping logic unchanged; bottomLabels consumer at transaction_confirm_screen.dart lines 670-674 unchanged"
  artifacts:
    - path: "lib/features/accounting/presentation/widgets/satisfaction_emoji_picker.dart"
      provides: "Updated 5-icon sentiment-positive ladder"
      contains: "Icons.sentiment_neutral_outlined,\n    Icons.sentiment_satisfied_outlined,\n    Icons.sentiment_satisfied_alt_outlined,\n    Icons.sentiment_very_satisfied_outlined,\n    Icons.favorite_border,"
    - path: "test/widget/features/accounting/presentation/widgets/satisfaction_emoji_picker_test.dart"
      provides: "Updated JP-context assertions for new labels"
      contains: "'無難', '快適', '順調', '満足', '至福'"
  key_links:
    - from: "lib/features/accounting/presentation/widgets/satisfaction_emoji_picker.dart#_icons"
      to: "Material Icons font glyphs"
      via: "IconData lookup in Flutter framework"
      pattern: "Icons.sentiment_satisfied_outlined renders without glyph fallback"
    - from: "test/widget/.../satisfaction_emoji_picker_test.dart"
      to: "lib/features/.../satisfaction_emoji_picker.dart"
      via: "Widget test asserts label text + value mapping"
      pattern: "expect(find.text('無難'), findsOneWidget); expect(selectedValues, [2, 4, 6, 8, 10]);"
---

<objective>
Replace the 5-element `_icons` const in `satisfaction_emoji_picker.dart` from the legacy mixed-polarity sequence (very_dissatisfied / dissatisfied / neutral / satisfied_alt / favorite_border) to the D-01 locked sentiment-positive ladder (neutral / satisfied / satisfied_alt / very_satisfied / favorite_border). Update the matching widget test's hardcoded JP-context label assertions to the new D-03 / D-05 strings (無難 / 快適 / 順調 / 満足 / 至福 + bottomLabels [無難, 順調, 至福！]). Preserve `_faceValues = [2, 4, 6, 8, 10]` and `_selectedIndex` mapping verbatim — HAPPY-08 value-mapping test (lines 56-70) must still pass without modification.

Purpose: Land the picker visual upgrade required by ADR-014 unipolar-positive scale (emoji-1 must never again be a negative face) and bring the test fixture into alignment with the new ARB values landed in Plan 01. This is the only Dart-code edit in Phase 12.

Output: 1 widget file edit (icons array), 1 test file edit (label-string assertions), 1 atomic commit.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@.planning/REQUIREMENTS.md
@.planning/phases/12-ui-copy-rename-pass-arb-values-ja-zh-en/12-CONTEXT.md
@.planning/phases/12-ui-copy-rename-pass-arb-values-ja-zh-en/12-01-arb-value-rewrites-PLAN.md
@CLAUDE.md
@.claude/rules/coding-style.md

<interfaces>
<!-- Current picker state (verified at planner read time) -->

lib/features/accounting/presentation/widgets/satisfaction_emoji_picker.dart lines 16-23:
```dart
  static const _faceValues = [2, 4, 6, 8, 10];
  static const _icons = [
    Icons.sentiment_very_dissatisfied_outlined,    // line 18 — REPLACE
    Icons.sentiment_dissatisfied_outlined,         // line 19 — REPLACE
    Icons.sentiment_neutral_outlined,              // line 20 — REPLACE
    Icons.sentiment_satisfied_alt_outlined,        // line 21 — REPLACE
    Icons.favorite_border,                         // line 22 — KEEP
  ];
```

After D-01 swap (target):
```dart
  static const _faceValues = [2, 4, 6, 8, 10];                       // unchanged
  static const _icons = [
    Icons.sentiment_neutral_outlined,                                 // val=2  was sentiment_very_dissatisfied
    Icons.sentiment_satisfied_outlined,                               // val=4  was sentiment_dissatisfied
    Icons.sentiment_satisfied_alt_outlined,                           // val=6  was sentiment_neutral
    Icons.sentiment_very_satisfied_outlined,                          // val=8  was sentiment_satisfied_alt
    Icons.favorite_border,                                            // val=10 unchanged
  ];
```

Planner-time verification: Flutter 3.41.8 icons.dart contains all 5 — `sentiment_neutral_outlined`, `sentiment_satisfied_outlined`, `sentiment_satisfied_alt_outlined`, `sentiment_very_satisfied_outlined`, `favorite_border` — confirmed via `grep -cE "(sentiment_neutral_outlined|sentiment_satisfied_outlined|sentiment_satisfied_alt_outlined|sentiment_very_satisfied_outlined|favorite_border)\s*=" $FLUTTER_ROOT/packages/flutter/lib/src/material/icons.dart` → returns 5. D-01 fallback clause is NOT needed.

test/widget/features/accounting/presentation/widgets/satisfaction_emoji_picker_test.dart current content (lines 19-20, 37-39):
```dart
  // line 19
  levelLabels: const ['不満', 'やや不満', '普通', '良い', 'とても良い'],
  // line 20
  bottomLabels: const ['不満', '普通', '最高！'],
  ...
  // lines 37-39 (in 'renders satisfaction labels' test)
  expect(find.text('不満'), findsOneWidget);
  expect(find.text('普通'), findsOneWidget);
  expect(find.text('最高！'), findsOneWidget);
```

After update (target):
```dart
  // line 19
  levelLabels: const ['無難', '快適', '順調', '満足', '至福'],
  // line 20
  bottomLabels: const ['無難', '順調', '至福！'],
  ...
  // lines 37-39
  expect(find.text('無難'), findsOneWidget);
  expect(find.text('順調'), findsOneWidget);
  expect(find.text('至福！'), findsOneWidget);
```

Lines 26-32 ('renders 5 face buttons'), lines 42-54 ('tapping a face calls onChanged with mapped value'), lines 56-70 ('pins all five face values to the v1.1 unipolar scale'), and lines 72+ ('shows header with satisfaction label text') remain UNCHANGED — they test value mapping and key-based lookups, not labels.
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Swap picker `_icons` const array to D-01 sentiment-positive ladder</name>
  <files>lib/features/accounting/presentation/widgets/satisfaction_emoji_picker.dart</files>
  <read_first>
    - lib/features/accounting/presentation/widgets/satisfaction_emoji_picker.dart lines 1-40 (full top of file — `_faceValues` and `_icons` consts)
    - .planning/phases/12-ui-copy-rename-pass-arb-values-ja-zh-en/12-CONTEXT.md D-01 (locked sequence + Flutter Material Icons existence proof)
  </read_first>
  <action>
    Use a single Edit tool call to replace the `_icons` block (lines 17-23). Preserve the surrounding `_faceValues` const above and the `final int value;` field below.

    Replace:
    ```
      static const _icons = [
        Icons.sentiment_very_dissatisfied_outlined,
        Icons.sentiment_dissatisfied_outlined,
        Icons.sentiment_neutral_outlined,
        Icons.sentiment_satisfied_alt_outlined,
        Icons.favorite_border,
      ];
    ```

    With:
    ```
      static const _icons = [
        Icons.sentiment_neutral_outlined,
        Icons.sentiment_satisfied_outlined,
        Icons.sentiment_satisfied_alt_outlined,
        Icons.sentiment_very_satisfied_outlined,
        Icons.favorite_border,
      ];
    ```

    DO NOT touch:
    - `_faceValues = [2, 4, 6, 8, 10]` (HAPPY-08 / ADR-014 binding)
    - `_selectedIndex` getter (lines 31-37)
    - any color logic, dark-mode token use, or `build()` method
    - any other Dart file (no consumer changes per D-05)

    The 4 forbidden negative-sentiment icons (`sentiment_very_dissatisfied_outlined`, `sentiment_dissatisfied_outlined`) MUST disappear from `lib/` after this edit (verified by grep below).
  </action>
  <verify>
    <automated>grep -F "Icons.sentiment_neutral_outlined,\n    Icons.sentiment_satisfied_outlined,\n    Icons.sentiment_satisfied_alt_outlined,\n    Icons.sentiment_very_satisfied_outlined,\n    Icons.favorite_border," lib/features/accounting/presentation/widgets/satisfaction_emoji_picker.dart >/dev/null 2>&1; printf '%d\n' $?</automated>
  </verify>
  <acceptance_criteria>
    - `grep -c "Icons.sentiment_neutral_outlined" lib/features/accounting/presentation/widgets/satisfaction_emoji_picker.dart` returns exactly 1
    - `grep -c "Icons.sentiment_satisfied_outlined" lib/features/accounting/presentation/widgets/satisfaction_emoji_picker.dart` returns exactly 1
    - `grep -c "Icons.sentiment_satisfied_alt_outlined" lib/features/accounting/presentation/widgets/satisfaction_emoji_picker.dart` returns exactly 1
    - `grep -c "Icons.sentiment_very_satisfied_outlined" lib/features/accounting/presentation/widgets/satisfaction_emoji_picker.dart` returns exactly 1
    - `grep -c "Icons.favorite_border" lib/features/accounting/presentation/widgets/satisfaction_emoji_picker.dart` returns exactly 1
    - `grep -rE "Icons\\.sentiment_(very_)?dissatisfied" lib/` returns ZERO matches (forbidden negative-sentiment icons gone from lib/)
    - `grep -c "static const _faceValues = \\[2, 4, 6, 8, 10\\];" lib/features/accounting/presentation/widgets/satisfaction_emoji_picker.dart` returns exactly 1 (unchanged)
    - `flutter analyze lib/features/accounting/` reports 0 issues
  </acceptance_criteria>
  <done>Picker icons array updated to D-01 sequence; 4 negative-sentiment icons gone from lib/; analyzer clean.</done>
</task>

<task type="auto">
  <name>Task 2: Update widget test JP-context label assertions to new ARB values</name>
  <files>test/widget/features/accounting/presentation/widgets/satisfaction_emoji_picker_test.dart</files>
  <read_first>
    - test/widget/features/accounting/presentation/widgets/satisfaction_emoji_picker_test.dart lines 1-100 (full file — verify line offsets and assertion-only changes)
    - .planning/phases/12-ui-copy-rename-pass-arb-values-ja-zh-en/12-CONTEXT.md D-03 + D-05 locked JP labels
  </read_first>
  <action>
    Three Edit tool calls, each replacing one literal-string list/expectation. DO NOT modify any test logic, structure, or value-mapping assertions.

    **Edit 1 (line 19):**
    Replace `levelLabels: const ['不満', 'やや不満', '普通', '良い', 'とても良い'],`
    With `levelLabels: const ['無難', '快適', '順調', '満足', '至福'],`

    **Edit 2 (line 20):**
    Replace `bottomLabels: const ['不満', '普通', '最高！'],`
    With `bottomLabels: const ['無難', '順調', '至福！'],`

    **Edit 3 (lines 37-39 inside the `renders satisfaction labels` test):**
    Replace:
    ```
      expect(find.text('不満'), findsOneWidget);
      expect(find.text('普通'), findsOneWidget);
      expect(find.text('最高！'), findsOneWidget);
    ```
    With:
    ```
      expect(find.text('無難'), findsOneWidget);
      expect(find.text('順調'), findsOneWidget);
      expect(find.text('至福！'), findsOneWidget);
    ```

    DO NOT modify:
    - `title: '満足度'` on line 18 (`satisfactionLevel` ARB value is 「満足度」 in ja — unchanged in Plan 01)
    - lines 26-32 `renders 5 face buttons` (uses ValueKey not text)
    - lines 42-54 `tapping a face calls onChanged with mapped value` (no label assertions)
    - lines 56-70 `pins all five face values to the v1.1 unipolar scale` (HAPPY-08 binding — pins {2,4,6,8,10} mapping; NEVER edit)
    - line 75+ `shows header with satisfaction label text` (asserts '満足度' which is unchanged)

    The full-width Japanese exclamation 「！」 (U+FF01) must be preserved — DO NOT use ASCII `!`.
  </action>
  <verify>
    <automated>flutter test test/widget/features/accounting/presentation/widgets/satisfaction_emoji_picker_test.dart 2>&1 | tail -20</automated>
  </verify>
  <acceptance_criteria>
    - `grep -c "'無難', '快適', '順調', '満足', '至福'" test/widget/features/accounting/presentation/widgets/satisfaction_emoji_picker_test.dart` returns exactly 1
    - `grep -c "'無難', '順調', '至福！'" test/widget/features/accounting/presentation/widgets/satisfaction_emoji_picker_test.dart` returns exactly 1
    - `grep -c "find.text('無難')" test/widget/features/accounting/presentation/widgets/satisfaction_emoji_picker_test.dart` returns exactly 1
    - `grep -c "find.text('順調')" test/widget/features/accounting/presentation/widgets/satisfaction_emoji_picker_test.dart` returns exactly 1
    - `grep -c "find.text('至福！')" test/widget/features/accounting/presentation/widgets/satisfaction_emoji_picker_test.dart` returns exactly 1
    - Forbidden old labels gone — `grep -E "'(不満|やや不満|普通|良い|とても良い|最高！)'" test/widget/features/accounting/presentation/widgets/satisfaction_emoji_picker_test.dart` returns ZERO matches
    - `grep -c "selectedValues, \\[2, 4, 6, 8, 10\\]" test/widget/features/accounting/presentation/widgets/satisfaction_emoji_picker_test.dart` returns exactly 1 (HAPPY-08 mapping test untouched)
    - `flutter test test/widget/features/accounting/presentation/widgets/satisfaction_emoji_picker_test.dart` reports all tests pass (5 tests in this file)
  </acceptance_criteria>
  <done>Test labels updated, all picker tests pass including HAPPY-08 value-mapping test (which was never touched).</done>
</task>

<task type="auto">
  <name>Task 3: Commit picker icon swap + test label update</name>
  <files>(git commit only)</files>
  <read_first>
    - .claude/rules/git-workflow.md (commit message format)
  </read_first>
  <action>
    Stage the 2 modified files (`lib/features/accounting/presentation/widgets/satisfaction_emoji_picker.dart` + the test file) and create a single commit:

    ```
    feat(12): swap picker icons to sentiment-positive ladder + update test labels

    Phase 12 picker upgrade per D-01 (icon ladder) and D-03/D-05 (test labels).

    satisfaction_emoji_picker.dart:
    - val=2 icon: sentiment_very_dissatisfied → sentiment_neutral
    - val=4 icon: sentiment_dissatisfied → sentiment_satisfied
    - val=6 icon: sentiment_neutral → sentiment_satisfied_alt
    - val=8 icon: sentiment_satisfied_alt → sentiment_very_satisfied
    - val=10 icon: favorite_border (unchanged)
    - _faceValues / _selectedIndex / build() / colors UNTOUCHED

    satisfaction_emoji_picker_test.dart:
    - levelLabels: ['不満', 'やや不満', '普通', '良い', 'とても良い']
              → ['無難', '快適', '順調', '満足', '至福']
    - bottomLabels: ['不満', '普通', '最高！']
              → ['無難', '順調', '至福！']
    - 'renders satisfaction labels' assertions updated
    - HAPPY-08 value-mapping test (lines 56-70) UNTOUCHED — pins {2,4,6,8,10}

    Picker UX identity preserved: 5 sentiment-faces, no negative-emotion icons
    re-introduced. ADR-014 + Phase 12 ADR-015 binding.

    Tests:
    - flutter test satisfaction_emoji_picker_test.dart: 5/5 PASS
    - flutter analyze lib/features/accounting/: 0 issues

    Refs: D-01, D-03, D-05; RENAME-05, RENAME-06; ADR-014
    ```

    Stage exactly the 2 files. DO NOT use `git add -A`.
  </action>
  <verify>
    <automated>git diff HEAD~1 --stat | grep -E "(satisfaction_emoji_picker\.dart|satisfaction_emoji_picker_test\.dart)" | wc -l | grep -q 2 && git log -1 --pretty=format:"%s" | grep -q "feat(12).*sentiment-positive ladder" && echo PASS || echo FAIL</automated>
  </verify>
  <acceptance_criteria>
    - Commit subject: `feat(12): swap picker icons to sentiment-positive ladder + update test labels`
    - `git diff HEAD~1 --stat` shows exactly 2 files: the picker .dart and its test .dart
    - Commit body references D-01, D-03, D-05, RENAME-05, RENAME-06, ADR-014
    - `git status` clean post-commit
  </acceptance_criteria>
  <done>Atomic commit on main with picker icon ladder + test label updates.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Picker → DB | User-selected satisfaction value (2/4/6/8/10) writes to `transactions.soul_satisfaction`. Value mapping is invariant; this plan only changes icons + label test fixtures. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-12-04 | Tampering | `_faceValues` constant accidentally edited | mitigate | Task 1 acceptance criterion explicitly greps for `[2, 4, 6, 8, 10]` after edit; HAPPY-08 mapping test in Task 2 verifies. |
| T-12-05 | Tampering | Negative-sentiment icon re-introduced via copy-paste error | mitigate | Task 1 acceptance criterion `grep -rE "Icons\.sentiment_(very_)?dissatisfied" lib/` MUST return zero. |
| T-12-06 | Repudiation | Picker UX semantic drifts (no negative emoji binding lost) | mitigate | ADR-015 (Plan 04) records the binding; Phase 12 close + INDEX status flip ratifies it. |
</threat_model>

<verification>
- `_icons` const matches D-01 sequence (Task 1 acceptance)
- 4 forbidden negative-sentiment icon identifiers gone from `lib/` (grep returns 0)
- `_faceValues = [2, 4, 6, 8, 10]` and `_selectedIndex` mapping unchanged
- All 5 widget tests pass; HAPPY-08 mapping test untouched
- `flutter analyze lib/features/accounting/` reports 0 issues
- Single atomic commit with subject `feat(12): swap picker icons to sentiment-positive ladder + update test labels`
</verification>

<success_criteria>
- 1 widget file edit (5-line `_icons` block)
- 1 test file edit (3 literal-string changes)
- 4 negative-sentiment icon names gone from lib/
- All picker tests green
</success_criteria>

<output>
After completion, create `.planning/phases/12-ui-copy-rename-pass-arb-values-ja-zh-en/12-02-SUMMARY.md` summarizing:
- The 5-icon swap (before/after table)
- The 3 test-string updates
- Commit hash + analyzer/test results
</output>
