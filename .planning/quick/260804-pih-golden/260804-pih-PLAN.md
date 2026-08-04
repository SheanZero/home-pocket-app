---
phase: quick-260804-pih-golden
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/features/home/presentation/widgets/home_joy_empty_state.dart
  - test/widget/features/home/presentation/widgets/home_hero_card_test.dart
  - test/golden/goldens/home_hero_card_no_joy_c2_light_ja.png
  - test/golden/goldens/home_hero_card_no_joy_c2_dark_ja.png
autonomous: true
requirements: [QUICK-PIH-01]
must_haves:
  truths:
    - "The no-Joy HomeHeroCard reads as one continuous surface in light and dark themes: the upper spending area and lower empty-state area have no background-color seam."
    - "The card retains its existing single outer shadow, outer border/radius, and tear-notch geometry, with no divider, border, or other internal separator added between the two regions."
    - "The empty-state copy, three preset prompts, free-entry action, sizing, and tap forwarding remain unchanged."
    - "Both checked-in no-Joy golden baselines match the integrated surface."
  artifacts:
    - path: "lib/features/home/presentation/widgets/home_joy_empty_state.dart"
      provides: "Transparent empty-state wrapper that lets the parent hero surface paint both regions"
      contains: "home-joy-empty-state"
    - path: "test/widget/features/home/presentation/widgets/home_hero_card_test.dart"
      provides: "Regression assertion that the parent is the sole card surface and still owns one shadow"
      contains: "sole card surface"
    - path: "test/golden/goldens/home_hero_card_no_joy_c2_light_ja.png"
      provides: "Light-theme no-Joy integrated-surface baseline"
    - path: "test/golden/goldens/home_hero_card_no_joy_c2_dark_ja.png"
      provides: "Dark-theme no-Joy integrated-surface baseline"
  key_links:
    - from: "lib/features/home/presentation/widgets/home_hero_card.dart"
      to: "lib/features/home/presentation/widgets/home_joy_empty_state.dart"
      via: "_buildEmptySurface mounts HomeJoyEmptyState inside home-hero-main-surface; a transparent child exposes the parent's surface color"
      pattern: "HomeJoyEmptyState\\("
    - from: "test/golden/home_hero_card_golden_test.dart"
      to: "test/golden/goldens/home_hero_card_no_joy_c2_light_ja.png"
      via: "the light no-Joy golden case"
      pattern: "home_hero_card_no_joy_c2_light_ja\\.png"
    - from: "test/golden/home_hero_card_golden_test.dart"
      to: "test/golden/goldens/home_hero_card_no_joy_c2_dark_ja.png"
      via: "the dark no-Joy golden case"
      pattern: "home_hero_card_no_joy_c2_dark_ja\\.png"
---

<objective>
统一首页无悦己记录时 HomeHeroCard 的上下区域，让 HomeJoyEmptyState 透出父卡片的同一表面色，并同步浅色、深色两个既有 golden。

Purpose: 消除已确认由 HomeJoyEmptyState 独立混色填充产生的横向色差，同时保持卡片唯一外层阴影、票根缺口、布局与交互完全不变。

Output: 一个由 widget 回归测试锁定的透明空状态包装层，以及更新后的浅色和深色 no-Joy golden 基线。
</objective>

<execution_context>
@/Users/xinz/.codex/gsd-core/workflows/execute-plan.md
@/Users/xinz/.codex/gsd-core/templates/summary.md
</execution_context>

<context>
@AGENTS.md
@.planning/STATE.md
@lib/features/home/presentation/widgets/home_hero_card.dart
@lib/features/home/presentation/widgets/home_joy_empty_state.dart
@test/widget/features/home/presentation/widgets/home_hero_card_test.dart
@test/golden/home_hero_card_golden_test.dart
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Lock sole-surface behavior, then remove the empty wrapper fill</name>
  <files>test/widget/features/home/presentation/widgets/home_hero_card_test.dart, lib/features/home/presentation/widgets/home_joy_empty_state.dart</files>
  <behavior>
    - RED: the no-Joy fixture exposes `home-hero-main-surface` as the only themed card surface; its `BoxDecoration` retains exactly one `boxShadow`, while the keyed `home-joy-empty-state` wrapper contributes neither a `color` nor a `decoration`.
    - GREEN: the lower empty-state region is painted by the same parent surface as the upper spending region, so there is no independently mixed background color at their boundary.
    - Existing empty-state constraints, padding, bottom geometry, prompt sub-card colors/shadows, localized copy, keys, and `onPromptTap` forwarding remain unchanged.
    - `HomeHeroCard._surfaceDecoration`, both tear notches, and the parent card border/radius/shadow stay untouched; no divider or border is added between regions.
  </behavior>
  <action>In the `HomeHeroCard — empty states` group, add a focused widget test named around the parent being the sole card surface. Pump `_singleNoJoyWithDailySpend()`, inspect the keyed parent and child `Container` widgets, assert the parent decoration still owns exactly one shadow, and assert the child wrapper has no independent color or decoration. Run that single test before changing production code and confirm it fails because the child currently owns a mixed fill. Then edit only the outer `Container` of `HomeJoyEmptyState`: remove its wrapper-level `BoxDecoration` so the parent's `_surfaceDecoration` paints continuously behind it. Preserve the key, constraints, padding, column contents, prompt-specific decorations, bottom spacing, and tap callbacks. Do not modify `home_hero_card.dart`; specifically preserve its one-shadow surface decoration and tear-notch stack, and add no separator construct.</action>
  <verify>
    <automated>flutter test test/widget/features/home/presentation/widgets/home_hero_card_test.dart</automated>
  </verify>
  <done>The new test is observed RED before the source edit and GREEN afterward; the no-Joy child wrapper supplies no surface paint, the parent still owns exactly one shadow, and the complete HomeHeroCard widget test file passes with empty-state content and prompt behavior intact.</done>
</task>

<task type="auto">
  <name>Task 2: Re-baseline both no-Joy themes and run scoped quality gates</name>
  <files>test/golden/goldens/home_hero_card_no_joy_c2_light_ja.png, test/golden/goldens/home_hero_card_no_joy_c2_dark_ja.png</files>
  <action>On the repository's supported macOS golden environment, run `flutter test --update-goldens test/golden/home_hero_card_golden_test.dart --plain-name 'no Joy C2'` so the existing light and dark no-Joy cases update together. Inspect both regenerated images: the upper and lower backgrounds must be continuous, while the outer shadow, outer border/radius, tear notches, text, prompt cards, spacing, and dimensions remain unchanged. Confirm the golden update changes exactly the two named PNG baselines and does not re-baseline filled-state images. Re-run the two golden cases without the update flag, the complete targeted HomeHeroCard widget test file, and scoped analysis for the home widget directory.</action>
  <verify>
    <automated>flutter test test/widget/features/home/presentation/widgets/home_hero_card_test.dart && flutter test test/golden/home_hero_card_golden_test.dart --plain-name 'no Joy C2' && flutter analyze lib/features/home/presentation/widgets</automated>
  </verify>
  <done>Both no-Joy PNG baselines are regenerated and committed, both light/dark golden comparisons pass without the update flag, the targeted widget suite passes, scoped analysis reports zero issues, and no unrelated golden baseline changes are present.</done>
</task>

</tasks>

<source_audit>

| Source | ID | Feature / constraint | Task | Status | Notes |
|--------|----|----------------------|------|--------|-------|
| GOAL | — | One integrated surface for the no-Joy hero card | 1, 2 | COVERED | Structural regression assertion plus light/dark visual baselines |
| REQ | QUICK-PIH-01 | Remove the empty-state region's internal color difference and synchronize both no-Joy goldens | 1, 2 | COVERED | Atomic quick-task requirement |
| RESEARCH | — | No research artifact supplied | — | EXCLUDED | Level 0: confirmed local widget cause, no dependency or external API decision |
| CONTEXT | — | Preserve the single outer shadow and add no internal separator | 1, 2 | COVERED | Explicit source invariant and golden inspection criteria |

</source_audit>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| App theme palette → HomeHeroCard presentation | Trusted in-process palette colors are composed into the visible no-Joy card surface. |
| Widget fixture → checked-in golden PNG | Deterministic light/dark fixtures produce reviewable visual regression artifacts. |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-QPIH-01 | Tampering | HomeJoyEmptyState surface composition | low | mitigate | Task 1 asserts that the child contributes no fill while the parent retains its one-shadow decoration. |
| T-QPIH-02 | Denial of Service | Empty-state layout and prompt interaction | low | mitigate | Task 1 preserves geometry/callbacks and runs the complete targeted widget test; Task 2 verifies both rendered themes. |

</threat_model>

<verification>
- `flutter test test/widget/features/home/presentation/widgets/home_hero_card_test.dart` passes, including the new sole-surface assertion and existing prompt forwarding/layout coverage.
- `flutter test test/golden/home_hero_card_golden_test.dart --plain-name 'no Joy C2'` passes against the updated light and dark baselines.
- `flutter analyze lib/features/home/presentation/widgets` reports zero issues.
- Git diff contains the focused Dart change, its widget regression test, and exactly the two named no-Joy PNG baseline updates; `home_hero_card.dart` and filled-state goldens remain unchanged.
</verification>

<success_criteria>
- The light and dark no-Joy card each show one continuous surface with no horizontal background-color seam.
- HomeJoyEmptyState has no wrapper-level fill; its prompt controls retain their own intended styling.
- HomeHeroCard still owns one outer shadow and its existing border, radius, and tear notches, with no internal divider introduced.
- Empty-state copy, layout, keys, and all four prompt intents remain behaviorally unchanged.
- Targeted widget tests, both no-Joy golden comparisons, and scoped analysis pass.
</success_criteria>

<output>
Create `.planning/quick/260804-pih-golden/260804-pih-SUMMARY.md` when done.
</output>
