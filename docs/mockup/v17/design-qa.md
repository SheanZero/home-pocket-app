# Happy Pocket V17 Whole-App Mockup Design QA

## Evidence

- Source visual truth: current Flutter implementation plus fresh golden captures:
  - `/Users/xinz/Development/home-pocket-app/test/golden/goldens/onboarding_value_capsules_dark_zh.png`
  - `/Users/xinz/Development/home-pocket-app/test/golden/goldens/satisfaction_bottom_sheet_manual_zh.png`
  - `/Users/xinz/Development/home-pocket-app/test/golden/goldens/category_selection_v16_dark_ja.png`
  - `/Users/xinz/Development/home-pocket-app/test/golden/goldens/family_transaction_attribution_v16_dark_zh.png`
- Rendered implementation: `http://127.0.0.1:4173/v17/?screen=home`
- Implementation screenshots: `/Users/xinz/.codex/visualizations/2026/08/12/019ff3ed-a3f4-7f53-8641-70e19c08cc7f/v17-audit/00-foundation.png` through `29-legal-doc.png`.
- Full-view evidence:
  - `/Users/xinz/.codex/visualizations/2026/08/12/019ff3ed-a3f4-7f53-8641-70e19c08cc7f/v17-audit/contact-sheet-1.png`
  - `/Users/xinz/.codex/visualizations/2026/08/12/019ff3ed-a3f4-7f53-8641-70e19c08cc7f/v17-audit/contact-sheet-2.png`
  - `/Users/xinz/.codex/visualizations/2026/08/12/019ff3ed-a3f4-7f53-8641-70e19c08cc7f/v17-audit/contact-sheet-3.png`
- Focused comparison evidence:
  - `/Users/xinz/.codex/visualizations/2026/08/12/019ff3ed-a3f4-7f53-8641-70e19c08cc7f/v17-audit/comparison-onboarding-dark.png`
  - `/Users/xinz/.codex/visualizations/2026/08/12/019ff3ed-a3f4-7f53-8641-70e19c08cc7f/v17-audit/comparison-satisfaction-sheet.png`
  - `/Users/xinz/.codex/visualizations/2026/08/12/019ff3ed-a3f4-7f53-8641-70e19c08cc7f/v17-audit/comparison-category-dark.png`
  - `/Users/xinz/.codex/visualizations/2026/08/12/019ff3ed-a3f4-7f53-8641-70e19c08cc7f/v17-audit/comparison-family-attribution-dark.png`
- Structural metrics: `metrics-390.json` and `metrics-375-430.json` in the same audit directory.

## Viewport and normalization

- V17 phone CSS size: 390 × 844; browser viewport: 1440 × 1100; device pixel ratio: 1.
- All 30 routes were captured at 390 × 844. Every route was additionally measured at 375 and 430 CSS px through the visible mockup width controls.
- Flutter reference pixels: onboarding 393 × 852, satisfaction 390 × 844, category 390 × 844, family attribution 390 × 390.
- Onboarding reference was normalized to 390 × 844. Satisfaction and category were compared 1:1. Family attribution used a 390 × 390 focused crop from the family dark list.
- State coverage: A1 personal light, A2 family light, A3 personal dark, Joy satisfaction sheet, dark category palette, family payer attribution, family approval-to-key-transfer transition, join key recovery, settings without notification controls, and family analytics empty state.

## Findings

- No actionable P0, P1, or P2 issues remain.
- Fonts and typography: the mockup keeps the existing Japanese/system sans-serif hierarchy, tabular numeric treatment, Material Symbols weight, and established title/body scales. All 30 pages passed 375 / 390 / 430 width checks without horizontal overflow or title truncation.
- Spacing and layout rhythm: the 390 × 844 phone frame, safe-area rhythm, 20–28px page gutters, card radii, bottom navigation and fixed actions remain aligned with the existing whole-app system. Independent production screens now have direct catalog entries instead of being represented only by modal approximations.
- Colors and visual tokens: V17 reuses the current background, surface, primary, Daily, Joy, family and semantic-state tokens. Dark category colors and the stable eight-slot payer palette match the current Flutter implementation; no new product palette was introduced.
- Image quality and asset fidelity: family portraits and onboarding imagery remain local repository assets. All five satisfaction faces use the existing production SVG sources. Avatar emoji use is intentional because the Flutter source screen itself exposes the same `warmEmojis` set; it is not a replacement for a missing image asset.
- Copy and content: notification settings are absent from the first-release settings page; the family empty-state insight appears once; legal text is presented as an offline long-form reader; approval and key-recovery copy accurately distinguishes approved, joining and active members.
- Accessibility and responsiveness: buttons retain practical tap targets, primary controls have accessible labels or roles, satisfaction uses a radio group, the family joining notice uses live status semantics, and every tested width reported zero horizontal overflow and zero broken images.

## Comparison history

1. Initial whole-app pass found one P2 issue on `avatar-picker`: the selected avatar rendered as a small unframed character and the cancel label wrapped at 375px. The picker preview was rebuilt as a 110px circular avatar, the profile preview as 88px, and the header side columns widened. Post-fix evidence: `26-avatar-picker.png` and `contact-sheet-3.png`; measured preview 110 × 110, cancel target 82 × 44, no wrap and zero horizontal overflow at 375px.
2. The family approval interaction initially appeared unchanged because its intentional 450ms transition had not completed before capture. The test was corrected to wait for the real transition; the resulting group screen shows “花子さんが家族に参加しています” while omitting 花子 from the active member list. Evidence: `state-family-approved-joining.png`.
3. Post-fix comparisons found no remaining P0/P1/P2 drift across typography, spacing, tokens, imagery, copy, behavior or responsiveness.

## Primary interactions tested

- All 30 catalog routes render and map to a renderer.
- 30 pages × 375 / 390 / 430px: zero horizontal overflow and zero broken images.
- Analytics spending tab → category legend row → read-only category drill-down.
- Profile → avatar picker → emoji selection → save back to profile; photo tab affordance remains a system-picker simulation.
- Legal list → offline legal document reader.
- Daily → Joy entry → satisfaction summary → five-level bottom sheet → selection returns to entry.
- Family approval → approved/joining transition; join waiting → key recovery; family empty analytics insight deduplicated.
- Settings contains no notification control.
- Browser console errors: none. Inline JavaScript parses successfully with `vm.Script`.
- Flutter verification: targeted golden suite passed (8 tests); `flutter analyze` completed with no issues.

## Follow-up polish

- None required for the V17 handoff.

final result: passed
