# V16 方案 3 · 数量与单位 Design QA

## Comparison Target

- Source visual truth: `/Users/xinz/.codex/generated_images/019fcc2c-9422-7540-b11e-87c2e935c407/exec-1c26af70-72db-43d8-8647-133c0c5e3bc5.png`, refined by the 2026-08-04 user review: remove `今回の量`, narrow the unit selector, keep only three quick units, and expose custom units only inside the selector sheet.
- Implementation URL: `http://127.0.0.1:4173/docs/mockup/v16/?screen=shopping-form&shopping-quantity-demo=standard`
- Implementation screenshot: `/private/tmp/home-pocket-v16-scheme3-final.png`
- Custom-unit screenshots: `/private/tmp/home-pocket-v16-custom-unit-panel-final.png`, `/private/tmp/home-pocket-v16-custom-unit-applied-final.png`
- State: light theme, personal mode, add shopping item, sugar, quantity 200, unit g; custom-unit flow additionally tested with `ひとつまみ`.

## Viewport And Normalization

- Source pixels: 853 × 1844; normalized to 390 × 844 for comparison.
- Prototype phone CSS size: 390 × 844; browser viewport: 738 × 908; device pixel ratio: 2.
- The in-app Browser returns a 1× normalized screenshot. The visible app-owned region was cropped to 390 × 728 for like-for-like comparison.
- Full-view comparison: `/private/tmp/home-pocket-v16-scheme3-centered-comparison.png`
- Focused quantity comparison: `/private/tmp/home-pocket-v16-scheme3-centered-quantity-comparison.png`

## Findings

- No actionable P0, P1, or P2 issues remain.
- Fonts and typography: V16 retains its existing Japanese UI font stack and numeric display weight. The quantity value remains the strongest element in the control, matching the source hierarchy.
- Spacing and layout rhythm: the number field and 76px unit selector form one compact row. The unit label is optically centered while the dropdown arrow is independently anchored at the right edge. The user-refined state intentionally removes the source caption and the fourth quick chip; g, kg, and 袋 now share the full quick-unit row.
- Colors and tokens: all new states use existing V16 surface, border, primary, daily, and muted tokens; no new palette was introduced.
- Image and icon fidelity: the selected quantity design contains no raster illustration or branded asset. Existing Material Symbols are reused for dropdown, close, edit, and check affordances.
- Copy and content: Japanese copy follows the current V16 locale while preserving the source meaning. Custom units explicitly say that the entered label is saved as-is and units are not converted automatically.
- Accessibility and responsiveness: interactive targets are at least 44px high, selection state is exposed with `aria-pressed`, inputs have labels, and 375 / 390 / 430px checks showed zero horizontal overflow. The 76px unit button and its label share the exact same horizontal center (`centerDelta: 0`).

## Comparison History

1. First custom-panel review found a P2 reachability issue: the apply action sat too low in the original 78% sheet. The unit sheet was raised to 88% and its actions made sticky. Post-fix evidence: `/private/tmp/home-pocket-v16-custom-unit-panel-final.png`.
2. User review removed the caption and lower custom shortcut, then reduced the unit selector from 112px to 88px and finally to 76px. The label now stays centered independently of the right-edge arrow. Post-fix evidence confirms exactly three quick units, zero custom shortcuts below the input, and zero horizontal overflow.
3. Final source/implementation comparison found no remaining P0/P1/P2 mismatch after applying the explicit user overrides. Evidence: `/private/tmp/home-pocket-v16-scheme3-centered-comparison.png` and `/private/tmp/home-pocket-v16-scheme3-centered-quantity-comparison.png`.

## Primary Interactions Tested

- Change quick units between g and kg.
- Open the full selector and apply ml.
- Open custom unit from the full selector, verify empty input disables apply, enter a custom label, apply it, and confirm it回显 only in the unit button.
- Verify number and unit remain separate values and decimal input is accepted.
- Verify 375 / 390 / 430px phone widths have no horizontal overflow.
- Browser interaction produced no uncaught task error. The in-app Browser does not expose console events; inline JavaScript was separately parsed with `vm.Script` and all tested interaction paths completed without exceptions.

## Follow-up Polish

- P3: production Flutter localization should add equivalent zh / ja / en unit labels and helper copy when this direction moves beyond the mockup.

final result: passed
