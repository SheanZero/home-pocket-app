# Shopping Quantity & Unit — Flutter Implementation (2026-08-04)

## Scope and evidence

- Selected direction: scheme 3 from `/Users/xinz/.codex/generated_images/019fcc2c-9422-7540-b11e-87c2e935c407/exec-1c26af70-72db-43d8-8647-133c0c5e3bc5.png`, refined by the approved v16 mockup at `/Users/xinz/Development/home-pocket-app/docs/mockup/v16/index.html` (no caption, 76 px centered unit selector, no initial suggestion chips, custom entry inside the picker, and no shopping voice entry for MVP).
- Refined source capture: `/Users/xinz/.codex/visualizations/2026/08/04/019fcc2c-9422-7540-b11e-87c2e935c407/shopping-units-mockup-focus.png`, 390×844 logical pixels, Japanese, light theme, Sugar, `200 g`, no learned suggestions.
- MVP no-voice browser capture: `/Users/xinz/.codex/visualizations/2026/08/04/019fcc2c-9422-7540-b11e-87c2e935c407/shopping-form-mvp-no-voice-browser.png`, 1265×712 px; the central 390 px phone shows the name field followed directly by the quantity card with no voice panel or reserved gap.
- Pre-fix device evidence: `/Users/xinz/Downloads/截屏 2026-08-04 20.45.10.png` (945×2048 px), normalized to 390×844 for the focused comparison; Simplified Chinese, light theme, default `1 piece`, keyboard open.
- Flutter implementation capture: `/Users/xinz/Development/home-pocket-app/test/golden/goldens/shopping_item_form_units_light_ja.png`, 390×844 logical pixels at DPR 1, Japanese, light theme, Sugar, `200 g`, no learned suggestions.
- Full MVP comparison: `/Users/xinz/.codex/visualizations/2026/08/04/019fcc2c-9422-7540-b11e-87c2e935c407/shopping-form-mvp-no-voice-comparison.png`; current mockup is left and corrected Flutter is right, both with the shopping voice entry absent.
- Focused quantity comparison: `/Users/xinz/.codex/visualizations/2026/08/04/019fcc2c-9422-7540-b11e-87c2e935c407/shopping-units-quantity-layout-before-target-after.png`; pre-fix device capture, refined mockup, and corrected Flutter appear from left to right.
- Custom-unit state: `/Users/xinz/Development/home-pocket-app/test/golden/goldens/shopping_unit_custom_sheet_light_ja.png`, 390×844 logical pixels at DPR 1, picker open with the custom-unit field and actions visible.

## Findings

- No actionable P0, P1, or P2 mismatch remains.
- Layout and spacing: the 390 px form now uses a 68 px label slot, 10 px gap, 164 px amount box, 8 px inter-control gap, and 76 px unit control. The amount and unit centers share the same vertical axis; the initial form does not reserve space for suggestion chips.
- Typography: the amount now uses the 24 px / 30 px production `amountLarge` tabular-numeral token instead of the undersized 15 px item-title token. Flutter's deterministic golden font renders unsupported Japanese glyphs as squares; the browser capture confirms the intended native Japanese typography, while the golden remains valid for geometry and numerals.
- Colors and visual tokens: the implementation reuses the existing paper surface, warm borders, green accent, and form-divider tokens without introducing a parallel palette.
- Content and localization: quantity and unit are edited separately; built-in and custom unit copy is supplied for Japanese, Simplified Chinese, and English. No fixed suggestion copy appears before learning has enough evidence.
- Interaction states: the default is `1 piece`; built-in and custom pickers, decimal input, learned suggestion selection, save arguments, list formatting, and empty learned state are covered by focused tests. The shopping voice entry is absent in production; its parser and draft component remain dormant for post-MVP work.
- Responsiveness and overflow: the 390 px create form and custom-unit bottom sheet render without overflow, with the sheet's apply/cancel actions remaining reachable.

## Verification

- Focused quantity/unit golden, frequency-use-case, DAO, sync-mapper, formatter, form, and list-tile suites: 69 tests passed.
- Additional create, voice-parser, repository, sync, database wipe, and clear-completed focused suites passed during implementation. The obsolete shopping-form voice integration suite is explicitly skipped while the MVP release gate is closed.
- `flutter analyze`: 0 issues.
- `git diff --check`: passed.

## Comparison history

1. The selected scheme initially contained a quantity caption and fixed unit chips; the approved mockup refinements removed the caption and fixed custom option, narrowed the selector, and moved custom entry into the unit picker.
2. The production form's integer stepper was replaced with a centered decimal amount field plus centered compact unit selector; fresh state now shows no suggestion row.
3. The 20:45 device capture exposed a P1 density mismatch missed by the first pass: the amount box expanded to roughly 200 px and the 15 px numeral looked weak and visually high against the unit control.
4. The quantity row was rebuilt with the mockup's fixed 68 px label track, reducing the amount box to 164 px at a 390 px viewport; the numeral moved to the 24 px amount token and a fill-height centered editor. The post-fix full and focused comparisons found no remaining P0/P1/P2 issue. A native-device screenshot remains an optional P3 release check for exact platform CJK glyph rendering.
5. MVP scope removed the shopping voice launch from both Flutter and the v16 mockup. The primary quantity card now follows the name/error slot directly; dormant parser and draft code remain behind a closed release gate.

final result: passed

---

# Mockup A3 Dark Palette Alignment — Design QA (2026-08-04)

## Scope and evidence

- Source visual truth: `docs/mockup/v16/index.html`, A3 personal dark preset.
- Implementation: Flutter dark theme and all screens consuming `AppPalette` / `AppTheme`.
- Change constraint: color-only review; existing layout, spacing, typography, copy, and navigation were intentionally left unchanged.
- Matched viewport/state comparison: 390×600 personal-home composition.
- Source capture: `/Users/xinz/.codex/visualizations/2026/08/04/019fccb5-eb77-7383-9394-b3f3e36e0195/mockup-a3-home-visible.png`.
- Flutter capture: `/Users/xinz/Development/home-pocket-app/test/golden/goldens/home_v16_phone_dark_ja.png`.
- Combined comparison input: `/Users/xinz/.codex/visualizations/2026/08/04/019fccb5-eb77-7383-9394-b3f3e36e0195/a3-dark-390-comparison.png`.

## Findings

- No actionable P0, P1, or P2 color mismatch remains.
- Global surfaces now map to A3 exactly: background `#171C19`, card `#222923`, muted surface `#2B342D`, divider/default border `#354038`, and strong border `#465248`.
- Text hierarchy now maps to `#EEF1EB`, `#A1ADA4`, and `#8B978E`; the distinct A3 primary-text role is `#B4D2BC` for active navigation and text actions.
- Ledger and semantic colors match A3: primary `#99BCA5`, daily `#7DC88D`, Joy `#E89BB0`, shared `#91ADC2` / `#AAC4D7`, success `#89B49C`, warning `#D3A571`, error `#E58C8C`, and info `#8CB1C8`.
- Material controls receive the same explicit dark `ColorScheme`, preventing stock Material dark colors from leaking into dialogs and controls.
- Saturated primary/FAB actions use the A3 dark paper foreground while preserving the established light-mode white foreground.
- The 390×600 comparison confirms the hero blend, border mix, page background, green/pink ledger bar, Joy ring, favorite ticket, and active-action colors track the A3 reference. Content and icon-glyph differences are fixture/font differences and were not layout work.
- No imagery or custom asset treatment changed. Existing icon libraries and interaction behavior remain intact.

## Page and state coverage

- Rebased and re-verified 94 dark golden cases across Home, List, Analytics, Shopping, Family, currency/edit surfaces, empty states, feedback, calendar, and category drill-down components.
- Re-verified three SmartKeyboard locale goldens plus JPY/USD dot-gating dark states.
- Targeted widget coverage passed for onboarding, profile, app lock, OCR review, transaction edit, voice input/listening, keyboard toolbar, shopping empty state, Home hero, and bottom navigation.
- Dark-mode resolution and raw-color architecture scans passed.
- `flutter analyze`: 0 issues.

## Comparison history

1. Before the fix, the Flutter dark theme used a brown-black foundation (`#171210` / `#231E1B`) that visibly diverged from A3's ink-green foundation.
2. The global palette, Material color roles, semantic foregrounds, and dark action ink were aligned to the live A3 tokens without changing layout.
3. The post-fix matched-viewport comparison and dark golden matrix found no remaining P0/P1/P2 color issue.

final result: passed

---

# Home Monthly Favorite — Square Satisfaction Panel (2026-08-04)

## Scope and evidence

- Source visual truth: `/Users/xinz/Downloads/截屏 2026-08-04 19.22.26.png` (1179×2556 px, 393×852 logical viewport at DPR 3), plus the requested square-panel and enlarged-content delta.
- Flutter implementation capture: `/Users/xinz/.codex/visualizations/2026/08/04/019fcc4e-7d93-72f2-b449-1aae7a47aca3/home-favorite-section-implementation-zh.png` (390×477 px, 390 logical width at DPR 1), Simplified Chinese, light theme, August 4, Dining out, ¥768, satisfaction 8.
- Full section comparison: `/Users/xinz/.codex/visualizations/2026/08/04/019fcc4e-7d93-72f2-b449-1aae7a47aca3/home-favorite-section-before-after.png`; source is left and Flutter is right.
- Focused ticket comparison: `/Users/xinz/.codex/visualizations/2026/08/04/019fcc4e-7d93-72f2-b449-1aae7a47aca3/home-favorite-ticket-before-after.png`; source is left and Flutter is right.
- Density normalization: the source section crop was reduced from 1057×351 to 350×117 and its ticket crop from 1057×246 to 350×82. The Flutter capture used equal 350×117 and 350×82 crops at DPR 1.

## Findings

- No actionable P0, P1, or P2 mismatch remains.
- Spacing and layout rhythm: the satisfaction panel changed from 58×80 logical pixels to a true 80×80 square inside the unchanged 82 px outer ticket height. The dashed perforation, paired edge notches, outer border, radius, calendar tile, and section spacing remain aligned.
- Fonts and typography: the tier label moves from the 10 px micro style to the 13 px semantic label style with the same bold weight. The Chinese capture confirms the enlarged label remains centered, legible, and unwrapped.
- Colors and visual tokens: the existing ticket surface, pink border, perforation, and semantic satisfaction foreground are unchanged.
- Image quality and asset fidelity: the existing satisfaction SVG continues to render through `SatisfactionFaceIcon`; it grows from 22×22 to 30×30 without raster scaling or a replacement asset.
- Copy and content: the localized tier wording is unchanged. No ARB key or transaction/category content changed.
- Responsiveness and interaction: the square geometry and the longest English tier label (`Amazing`) pass at the 390 px phone width. The whole favorite section retains its existing tap behavior.

## Verification

- Home hero widget and golden suites: 54 tests passed.
- Full personal/family Home alignment goldens: 2 tests passed.
- `flutter analyze`: 0 issues.
- Direct iOS simulator launch was unavailable because Xcode failed while resolving Swift Package Manager dependencies with a `DVTDeviceOperation` build-number error; Flutter-rendered component and full-Home captures provide the visual evidence for this scoped change.

## Comparison history

1. The source and initial implementation showed a narrow 58×80 satisfaction panel with a 22 px face and 10 px label.
2. The panel was widened to 80×80, the face to 30 px, and the label to 13 px while preserving the ticket height and chrome.
3. Post-fix full-section and focused comparisons found no remaining P0/P1/P2 issue.

final result: passed

---

# V16 Analytics Primary Tabs — Flutter Implementation (2026-08-04)

## Scope and evidence

- Approved source direction: `/Users/xinz/.codex/generated_images/019fca24-b105-7a70-86cb-1e662b812922/exec-b2bd2b20-74f1-4334-a875-58c8cb5054ba.png`, with final ownership copy and responsive rules from `docs/mockup/v16/index.html` and `docs/mockup/v16/README.md`.
- Pre-fix evidence: `/Users/xinz/.codex/visualizations/2026/08/04/019fca24-b105-7a70-86cb-1e662b812922/analytics-tab-title-truncation.png`.
- Flutter personal evidence: `test/golden/goldens/analytics_screen_scroll_smoke_light_ja.png` at 390×844, Joy selected.
- Flutter family evidence: `test/golden/goldens/analytics_screen_family_spending_light_ja.png` at 390×844, Family Spending selected.
- The source, pre-fix crop, and Flutter render were reviewed together in one visual comparison input.

## Findings

- No actionable P0, P1, or P2 mismatch remains.
- Header fidelity: the existing month, calendar, and settings title bar is unchanged.
- State fidelity: the inactive tab remains flat on a borderless warm base; the selected tab uses the approved raised paper surface, soft shadow, semantic tint, and centered top bookmark.
- Ownership copy: personal mode uses `支出 / ときめき`; family mode uses `家族の支出 / 私のときめき`. Chinese and English equivalents are supplied by ARB localizations.
- Content separation: Spending owns trend, category, and the group-only family insight. Joy owns the calendar and satisfaction histogram. Joy is selected by default.
- Data scope: Family Spending aggregates the current book and shadow books. My Joy explicitly stays on the current user's book for the tab summary, calendar, day details, report, and satisfaction distribution.
- Responsive priority: at 375 px, titles retain the 15 px single-line style. The supporting visual is removed when the measured localized title needs its space; the title is never shortened to make room for decoration. Japanese and English family labels were verified without truncation.
- Accessibility and motion: both full tab surfaces expose button and selected semantics, and selection animation respects the platform reduce-motion preference.

## Verification

- Analytics unit/widget suite: 310 tests passed.
- Analytics application + ARB parity + hardcoded-CJK architecture suite: 178 tests passed.
- Updated Analytics screen and satisfaction goldens: 9 tests passed.
- Focused 375 px personal/family, Japanese/English title, tab-switching, card ownership, and refresh tests: 12 tests passed.
- `flutter analyze`: 0 issues.
- `git diff --check`: passed.

final result: passed

---

# Joy Satisfaction Bottom Sheet — Design QA (2026-08-04)

## Scope and evidence

- Source visual: `/Users/xinz/.codex/generated_images/019fcc24-41d0-7fe0-83e5-5d1fd3a923fd/exec-03597618-c89c-4abe-9b6e-797f4ae9c6e3.png`.
- Implementation capture: `test/golden/goldens/satisfaction_bottom_sheet_manual_zh.png`.
- Full comparison: `/Users/xinz/.codex/visualizations/2026/08/04/019fcc24-41d0-7fe0-83e5-5d1fd3a923fd/satisfaction-sheet-full-comparison.png`.
- Focused comparison: `/Users/xinz/.codex/visualizations/2026/08/04/019fcc24-41d0-7fe0-83e5-5d1fd3a923fd/satisfaction-sheet-focused-comparison.png`.
- Viewport/state: 390×844 logical pixels at DPR 1, Simplified Chinese, light theme, manual entry ¥1,236, Food > Dining out, Joy selected, satisfaction 2, sheet open.
- The source was normalized to the implementation viewport before both images were placed in the same comparison input.

## Findings

- No actionable P0, P1, or P2 issue remains. The final sheet top differs from the selected direction by approximately 2 logical pixels.
- Layout and spacing: 28px top radius, grabber, context pill, title hierarchy, five-choice row, footer, and keep action align with the selected visual.
- Typography and copy: implementation uses semantic `AppTextStyles`; category reason, title, current hint, five choices, auto-return hint, and keep action are localized in zh/ja/en. Flutter golden tests render CJK with the Ahem fallback, so exact Chinese copy is asserted separately in widget tests.
- Colors and surfaces: existing palette tokens provide the scrim, paper surface, muted choices, and Joy-pink selected state.
- Icons and imagery: all five existing satisfaction SVG assets are reused; no placeholder, emoji, CSS art, or generated production asset was introduced.
- Responsiveness: choice size adapts to available width, and a 320×568 test confirms no horizontal overflow.
- Accessibility: every face exposes a labeled button semantic and selected state; tap targets are 64px at the reference viewport and shrink only when necessary on narrow screens.

## Interaction and verification

- Manual Daily → Joy selection and category-inferred Joy both open the sheet; category inference shows localized category context.
- Selecting a value closes the sheet, writes the value, and restores the keypad. Keeping the current value closes without changing it. The compact summary reopens the sheet.
- Existing edit, OCR, and voice hosts retain the established inline picker.
- `flutter analyze`: 0 issues.
- Targeted accounting, localization architecture, responsiveness, semantics, and golden checks: 65 passed.
- `flutter test --exclude-tags golden`: 4,179 passed, 11 skipped.
- Full `flutter test`: feature tests passed; 13 unrelated `home_hero_card_golden_test.dart` baselines fail against concurrent dirty Home changes. The new satisfaction golden passes in isolation and in the targeted run.

## Comparison history

1. The initial capture missed the modal because the golden targeted only the screen subtree; the capture was moved to the overlay.
2. The first modal comparison showed a 21–23px vertical offset and undersized choice cards.
3. Sheet rhythm and 64px choice sizing were aligned, then narrow-width adaptation was added. The final full and focused comparisons found no P0/P1/P2 mismatch.

final result: passed

---

# V16 Analytics Tabs — Selected Direction 2 (2026-08-04)

## Scope and evidence

- Source visual truth: `/Users/xinz/.codex/generated_images/019fca24-b105-7a70-86cb-1e662b812922/exec-b2bd2b20-74f1-4334-a875-58c8cb5054ba.png` (the selected second direction).
- Mockup implementation: personal and A2 family branches of `analytics()` in `docs/mockup/v16/index.html`.
- Target states: personal `支出 / ときめき`; A2 family `家族の支出 / 私のときめき`; Joy selected by default to match the source visual.
- Pre-fix rendered evidence supplied by the user: `/Users/xinz/.codex/visualizations/2026/08/04/019fca24-b105-7a70-86cb-1e662b812922/analytics-tab-title-truncation.png` (736×224 focused @2x crop), showing `私のときめき` truncated in A2.
- Post-fix browser-rendered evidence: unavailable because the in-app browser safety policy blocks local-file mockup access in this task.

## Implemented design decisions

- The existing month, calendar, and settings title bar is unchanged.
- The shared warm base has no industrial outline. The inactive tab sits flat on that base; the active tab becomes a softly raised paper surface with a centered color bookmark.
- Both tabs use the established Material Symbols set (`donut_small`, `bar_chart`) instead of introducing a new illustration style.
- The supporting visual track is reduced from 50px to 38px, its symbol from 42px to 34px, and the text gap from 8px to 4px. At 375px the visual track becomes 34px with a 32px symbol, preserving the full 15px title before considering truncation.
- The first two analytics sections render only under spending; the calendar and satisfaction sections render only under Joy.
- A2 uses family totals in the spending tab, while its `私のときめき` tab intentionally renders the current user's Joy calendar and satisfaction data.
- Personal mode omits `私の` from both labels because the screen context already establishes ownership; A2 retains `家族の / 私の` because the two tabs have different data owners.
- Tab buttons expose `tablist` / `tab` / `tabpanel` semantics and support Left, Right, Home, and End keys.

## Verification

- Inline JavaScript syntax: passed.
- Required personal/A2 labels and tab ARIA wiring: present.
- Pre-fix P2 title truncation: addressed in code by yielding horizontal space from the secondary visual to the primary label.
- Post-fix responsive visual comparison, overflow check, and console check: blocked pending manual opening of the local mockup.

final result: blocked

---

# V16 A2 Analytics — Family Joy Calendar Refinement (2026-08-03)

## Scope and evidence

- Source visual truth: `/Users/xinz/.codex/generated_images/019fc7df-2f73-7820-a949-39c2f2c3f5e0/exec-58be5acf-2b7a-41e0-8dcb-ed9b7d6eee8e.png`.
- Mockup implementation: the A2 family branch of `analyticsCalendarCard()` in `docs/mockup/v16/index.html`; the personal A1/A3 branch remains unchanged.
- Browser-rendered evidence: `/private/tmp/a2-family-calendar-viewport.png`, focused to `/private/tmp/a2-family-calendar-focus.png` at the 390 px phone width.
- Same-input comparison: `/private/tmp/a2-family-calendar-qa-composite.png`; the selected visual direction is on the left and the rendered Mockup is on the right.
- State: July 2026, A2 family, light theme, all three members, July 12 selected.

## Findings

- No actionable P0, P1, or P2 visual mismatch remains.
- Calendar meaning: the unfiltered heatmap is derived from the family's per-day total count. July 6 and 21 show two-item intensity, while July 12 uses the strongest three-item intensity and remains selected.
- Member filtering: the three avatar/name controls above the card are real toggle buttons. Selecting a member recalculates the calendar heatmap and selected-day details for that member; pressing the active member again restores the whole-family view.
- Unified composition: calendar, low-to-high legend, selected-day heading, and detail rows share one continuous paper card. The calendar no longer repeats a month selector or a monthly-total sentence.
- Detail simplification: each row keeps the payer avatar, category badge, category, satisfaction, merchant, and amount. Duplicate member names and right-side chevrons are absent, so the row no longer implies a second navigation destination.
- Visual rhythm: the implementation intentionally compresses the isolated concept into the existing 390×844 app shell while preserving its hierarchy, warm paper surface, blush heat scale, selected-day outline, avatar order, and amount alignment.

## Verification

- Default July 12 accessible count: `家族のときめき3件`; selecting あおい changes it to `あおいのときめき1件`, and selecting あおい again restores the family count.
- Selected-member `aria-pressed`: `true`; after reset: `false`.
- Detail member-name nodes: 0; detail `chevron_right` nodes: 0.
- Browser console errors: 0.
- `git diff --check` and inline-script parsing: passed.

final result: passed

---

# V16 A2 Family List Top — Flutter Alignment (2026-08-03)

## Scope and evidence

- Source visual truth: `/var/folders/qs/d64k8pm541nbr7hjj9scdxj00000gn/T/TemporaryItems/NSIRD_screencaptureui_UU5U6I/截屏2026-08-03 21.46.42.png`.
- Flutter implementation: `lib/features/list/presentation/screens/list_screen.dart`, `lib/features/list/presentation/widgets/list_calendar_header.dart`, `lib/features/list/presentation/widgets/list_sort_filter_bar.dart`, and `lib/features/list/presentation/providers/state_calendar_totals.dart`.
- Flutter-rendered evidence: `test/golden/goldens/family_list_top_v16_ja.png` at a 390 px phone width.
- Same-input visual comparison: `.planning/sketches/audits/family-list-v16-2026-08-03/source-vs-flutter-family-list-top.png`; approved Mockup on the left and Flutter on the right.
- State: July 2026, A2 family, light theme, all ledgers, Monday week start, family totals ¥227,620 / Joy ¥53,620 / Daily ¥174,000.

## Findings

- No actionable P0, P1, or P2 issue remains.
- Header: the month title keeps the List information-blue treatment; family mode now displays the compact family badge before the calendar and settings actions.
- Ledger switch: the three full-width pill segments preserve the approved active-all treatment and the existing semantic Daily/Joy states.
- Calendar: day numerals, weekend color, compact amounts, outside-month opacity, 46 dp rows, rounded receipt card, border, and soft shadow align with the Mockup geometry.
- Family receipt footer: family mode now renders a stable family-wide month total followed by Joy and Daily colored-dot breakdowns. The values aggregate the owner book and all locally available shadow books and do not change with search/category/day filters.
- Filter scope: the first version no longer exposes per-member filter chips. The compact row contains sort, category, search, and the existing clear affordance only when another filter is active.
- Refresh behavior: transaction mutations, pull-to-refresh, and full data resets invalidate both calendar daily totals and the new family ledger split, preventing a stale family footer.
- Personal isolation: solo mode retains the existing single-line monthly summary and does not show the family badge or family ledger split.

## Verification

- Same-input visual review confirms matching hierarchy, card width, segment geometry, calendar rhythm, summary hierarchy, and filter controls.
- Family list widget/provider/refresh tests plus the List calendar and new V16 family-list Goldens: 36 tests passed, 0 failed.
- The family ledger provider test confirms owner + shadow-book aggregation for both ledgers.
- Localization is supplied for Japanese, Chinese, and English; generated localization outputs were refreshed.
- `flutter analyze`: 0 issues.

final result: passed

---

# V16 A2 Home + Detail — Shared Payer Attribution (2026-08-03)

## Scope and evidence

- Selected direction: scheme 2 from `/Users/xinz/.codex/generated_images/019fc151-a7da-7953-8152-aee24d5ea2e2/exec-04d78f89-fb1d-4182-89aa-4839939fd5a7.png`, extended from family detail into Home recent spending.
- Mockup implementation: the A2 family Home and List branches in `docs/mockup/v16/index.html`; A1 personal rows remain unchanged.
- Flutter implementation: `lib/shared/widgets/family_transaction_attribution.dart`, `lib/features/home/presentation/widgets/home_transaction_tile.dart`, `lib/features/home/presentation/screens/home_screen.dart`, `lib/features/list/presentation/widgets/list_transaction_tile.dart`, and `lib/features/list/presentation/screens/list_screen.dart`.
- Browser-rendered Mockup evidence: `.planning/sketches/audits/family-list-v16-2026-08-03/a2-v3-home-member-chips-mockup.png` and `.planning/sketches/audits/family-list-v16-2026-08-03/a2-v3-list-member-chips-mockup.png`.
- Flutter-rendered evidence: `test/golden/goldens/home_v16_family_alignment.png` and `test/golden/goldens/family_transaction_attribution_v16_zh.png`.
- Same-input visual comparison: `.planning/sketches/audits/home-v16-flutter-2026-08-03/family-payer-chip-mockup-vs-flutter.png`; Mockup Home/List rows on the left and their shared Flutter row treatment on the right.

## Findings

- No actionable P0, P1, or P2 issue remains.
- Shared structure: Home recent spending and List detail use the same payer avatar, lower-right category badge, title, optional satisfaction face, compact payer color chip, merchant, and neutral amount hierarchy.
- Current-device owner: the owner chip is no longer a profile name. It uses the localized first-person label `我` / `自分` / `Me` and the primary green tone. Other members retain their server profile names and stable Joy/shared color roles.
- Family semantics: family rows do not display the duplicate `悦己` / `日常` text badge. Joy rows retain the existing satisfaction face after the title; daily rows do not show it. The category remains visible through the avatar corner badge.
- Personal isolation: personal Home and List branches keep their original category icon and ledger badge treatment. No payer chip, avatar substitution, or copy change is introduced outside family mode.
- Data wiring: the current book resolves to the local profile avatar; shadow books resolve to each member's display name and avatar path. Amounts remain neutral so member identity and Joy satisfaction are the only row-level semantic accents.
- Layout: both components retain the existing 68 dp minimum row height, bounded payer-chip width, ellipsized merchant copy, and tabular amount alignment.

## Verification

- Family Home/List targeted widget and screen tests plus both V16 Golden suites: 38 tests passed, 0 failed.
- `flutter analyze`: 0 issues.
- Mockup A2 Home recent rows / payer chips / category badges: 3 / 3 / 3; ledger text tags: 0; Joy faces: 1.
- Mockup A2 List family rows use the same color-chip and category-badge classes; the first-version member filter remains absent.
- Browser DOM inspection confirmed the current owner is rendered as `自分` in the Japanese Mockup and other members as `花子` / `太郎`.
- Same-input visual review confirmed matching member-chip hierarchy, avatar-badge placement, smile placement, merchant rhythm, and neutral amount alignment.

final result: passed

---

# V16 A2 Family Detail — Member Color Chips (2026-08-03)

## Scope and evidence

- Selected direction: `/Users/xinz/.codex/generated_images/019fc151-a7da-7953-8152-aee24d5ea2e2/exec-04d78f89-fb1d-4182-89aa-4839939fd5a7.png` (option 2).
- Implementation: the A2 family transaction branch in `docs/mockup/v16/index.html`; A1 personal transaction rows remain unchanged.
- Browser-rendered evidence: `.planning/sketches/audits/family-list-v16-2026-08-03/a2-v2-member-name-chips-final.png`.
- Same-input comparison: `.planning/sketches/audits/family-list-v16-2026-08-03/selected-option2-vs-mockup.png`; selected option on the left, final A2 Mockup on the right.
- State: July 2026, A2 family, light theme, all ledgers, three members, 390 px phone width.

## Findings

- No actionable P0, P1, or P2 issue remains.
- Member identity: family rows replace the `日常` / `ときめき` text tag with a compact payer chip. あおい uses sage green, 花子 uses blush pink, and 太郎 uses slate blue, matching option 2's identity-first direction.
- Category visibility: the existing category icon remains as a small badge at the lower-right of each avatar, as explicitly requested. Its category graphic and Joy/daily color semantics remain intact without adding a second text label.
- Joy semantics: Joy rows retain the satisfaction smile directly after the transaction title. Daily rows do not show the smile.
- Amount hierarchy: family amounts use one neutral ink treatment, so member color and satisfaction are the only row-level semantic accents. Personal A1 rows retain their existing ledger tags and layout.
- Density: the chips fit the existing compact 68 px family rows without pushing merchant, amount, or chevron content outside the phone.

## Verification

- A2 family rows / payer chips / category badges: 5 / 5 / 5.
- Payer chip distribution: あおい 2, 花子 2, 太郎 1.
- A2 family ledger text tags: 0.
- A2 Joy rows / satisfaction faces: 2 / 2.
- A1 personal rows / original ledger tags: 4 / 4; payer chips: 0.
- 375/390/430 px phone widths: `scrollWidth == clientWidth`; no transaction row escapes the app bounds.
- Same-input visual review: member-chip hierarchy, title/smile placement, amount alignment, card grouping, and spacing match the selected direction; the category avatar badge is the intentional user-requested addition.

final result: passed

---

# V16 A1/A2 Joy Rows — Satisfaction Face + V1 Filter Simplification (2026-08-03)

## Scope and evidence

- Source visual truth: `/var/folders/qs/d64k8pm541nbr7hjj9scdxj00000gn/T/TemporaryItems/NSIRD_screencaptureui_GWmx0J/截屏2026-08-03 20.41.20.png`, where a Joy transaction places the satisfaction face directly after its title.
- Implementation: A1/A2 home-recent rows and A1/A2 detail rows in `docs/mockup/v16/index.html`; A2 detail no longer includes a member filter.
- Product asset: `docs/mockup/v16/assets/satisfaction/sat_04.svg`, copied from the existing production asset `assets/satisfaction/sat_04.svg` so the standalone Mockup renders the same smile silhouette.
- Browser-rendered evidence: `.planning/sketches/audits/family-list-v16-2026-08-03/a2-v1-list-satisfaction-final.png`, `.planning/sketches/audits/family-list-v16-2026-08-03/a2-v1-home-recent-satisfaction.png`, and `.planning/sketches/audits/family-list-v16-2026-08-03/a2-v1-no-member-filter-list.png`.
- Same-input comparison: `.planning/sketches/audits/family-list-v16-2026-08-03/satisfaction-source-vs-mockup.png`; user reference on the left, final A2 Joy row on the right.
- State: July 2026, light theme, A2 family detail with all ledgers and payer attribution; A1 personal and A2 family home-recent states were also checked.

## Findings

- No actionable P0, P1, or P2 issue remains.
- Joy semantics: every Joy transaction title now shows the pink satisfaction smile inline. Daily rows do not show a smile, and the existing Joy/daily badge remains unchanged.
- Asset fidelity: the face is the project's real `sat_04.svg`, rendered as a semantic color mask. It is not an emoji, generic Material face, CSS-drawn substitute, or raw asset key.
- V1 scope: the A2 member filter and all of its presentation/state/event logic were removed. Payer avatar and name stay on every family row, preserving attribution without introducing a second filtering dimension.
- Home consistency: A1 personal and A2 family recent-spending lists use the same inline satisfaction treatment as the detail list.
- Layout: the smile shares the title baseline at 17×17 px and preserves truncation, amount alignment, payer metadata, and the existing 44 px+ row target.

## Verification

- A2 member-filter controls: 0.
- A2 Joy detail rows / satisfaction faces: 2 / 2; daily detail faces: 0.
- A1 home Joy rows / satisfaction faces: 1 / 1; daily home faces: 0.
- A2 home Joy rows / satisfaction faces: 1 / 1; daily home faces: 0.
- 375/390/430 px phone widths: `scrollWidth == clientWidth`; no horizontal overflow.
- Browser console errors: 0.
- Same-input comparison confirms the icon follows the title and uses the existing Joy-pink visual language.

## Comparison history

1. The previous family-detail direction added a horizontally scrollable member filter and showed only ledger/category semantics in transaction rows.
2. The user simplified V1 scope by removing member filtering and requested the existing satisfaction face on Joy transactions.
3. The final pass removed the filter end-to-end, added the real satisfaction asset to personal/family home and detail rows, and verified responsive behavior and runtime state.

final result: passed

---

# V16 A2 Family Detail — Family Ledger Redesign (superseded draft, 2026-08-03)

## Scope and evidence

- Problem baseline: `/Users/xinz/Downloads/截屏 2026-08-03 16.31.16.png`, the current dark Flutter family-detail screen with no payer identity, an overflowing filter rail, and raw `icon:cat...` content.
- Visual target: the existing A1 list/calendar language and the accepted A2 family-home payer/avatar language in `docs/mockup/v16/index.html`.
- Redesigned implementation: the A2 family branch of `docs/mockup/v16/index.html`; A1 remains on its existing list implementation.
- Browser-rendered implementation: `.planning/sketches/audits/family-list-v16-2026-08-03/a2-family-list-top-browser.png` and `.planning/sketches/audits/family-list-v16-2026-08-03/a2-family-list-rows-browser.png`.
- Same-input comparisons: `.planning/sketches/audits/family-list-v16-2026-08-03/source-vs-mockup-top.png` and `.planning/sketches/audits/family-list-v16-2026-08-03/source-vs-mockup-rows.png`.
- Viewport and normalization: browser evidence was captured at 1250×704 px with a 390×844 CSS-pixel phone at DPR 1. The 1320×2868 device baseline was normalized to 390 px width; focused source and implementation regions were cropped to equal 390×620 and 390×330 panels before side-by-side comparison.
- State: A2 family, light theme, July 2026, all ledgers, all three members, family calendar summary, and grouped family transactions.

## Findings

- No actionable P0, P1, or P2 issue remains in the redesigned Mockup.
- Typography: A2 reuses A1's month, segmented-control, calendar, amount, date-header, and transaction hierarchy. Payer names use the existing item weight; merchant, ledger, and day-total copy stay in the supporting scale without wrapping.
- Spacing and layout rhythm: the new member rail sits between ledger selection and the calendar, so member identity is visible before data filtering. The calendar remains the dominant region, the family summary stays inside its footer, and the utility filter row remains one compact line without the baseline's clipped `仅自己`/raw-icon controls.
- Colors and tokens: family identity uses the existing primary green, Joy remains pink, daily remains green, and the design keeps the V16 warm paper surfaces, borders, radii, and shadows. No new family-only palette was added.
- Images and icons: the member rail and transaction rows use the existing A2 raster profile assets. Each payer avatar receives a real Material category badge; no emoji, placeholder art, raw icon key, or handcrafted graphic was introduced.
- Copy and content: the footer now says `家族の合計` and exposes the family Joy/daily split. Transaction rows show payer, ledger, merchant, amount, and category; date headers add the day's family total. Other members' transactions are explicitly read-only while the owner's remain editable.
- Responsive behavior: 375, 390, and 430 px phone widths all report `screenScrollWidth == screenClientWidth`, the utility filter row has no overflow, and zero transaction rows clip their content. The member rail remains horizontally scrollable as an intentional compact control.
- Interactions and runtime: member filtering, ledger filtering, date filtering, sort/category/search controls, month selection, and transaction actions remain wired. The member, ledger, and date filters were exercised; family rows filtered to the authoritative state and the browser console reported zero errors.

## Comparison history

1. The baseline used the personal list unchanged in family mode, hid payer identity, duplicated `仅自己` beside other filters, clipped a raw category token, and showed only a single monthly total.
2. The redesign added an avatar member rail, family Joy/daily summary, payer-aware rows, per-day family totals, and read-only semantics for remote transactions while preserving A1's calendar and control hierarchy.
3. The final normalized top and row comparisons found no remaining actionable P0/P1/P2 mismatch; A1 was switched back and visually checked to confirm no regression.

## Verification

- Family member filter: passed; selecting 花子 returns only 花子 rows.
- Ledger filter: passed; selecting 日常 returns only daily rows and `¥174,000`.
- Date filter: passed; selecting July 10 returns only the July 10 family group and `¥11,100` day total.
- 375/390/430 px overflow check: passed.
- Browser console errors: 0.
- `git diff --check -- docs/mockup/v16/index.html design-qa.md`: passed after final report update.

final result: passed

---

# V16 Personal + Family Home — Flutter Implementation (2026-08-03)

## Scope and evidence

- Source visual truth: the A1 personal and A2 family branches in `docs/mockup/v16/index.html`, including the final tear-hero, member-detail, favorite-ticket, and recent-spending compositions.
- Flutter implementation: `lib/features/home/presentation/screens/home_screen.dart`, `lib/features/home/presentation/widgets/home_hero_card.dart`, `lib/features/home/presentation/widgets/family_member_spending_card.dart`, and `lib/features/home/presentation/widgets/home_transaction_tile.dart`.
- Rendered implementation: `test/golden/goldens/home_v16_personal_alignment.png` and `test/golden/goldens/home_v16_family_alignment.png`, both at 390×1180 logical/physical px (DPR 1), light theme, Simplified Chinese, July 2026.
- Same-input focused comparisons: `.planning/sketches/audits/home-v16-flutter-2026-08-03/family-hero-side-by-side.png`, `.planning/sketches/audits/home-v16-flutter-2026-08-03/family-details-side-by-side.png`, and `.planning/sketches/audits/home-v16-flutter-2026-08-03/personal-focus-side-by-side.png`.

## Findings

- No actionable P0, P1, or P2 visual mismatch remains.
- Typography and hierarchy: personal and family modes share the V16 hero hierarchy. `本月最爱`, `成员支出`, and `最近支出` use the same compact section-title scale and icon treatment; currency and invite-style numerals keep the product's monospaced numeral treatment.
- Spacing and layout: family spending and personal Joy remain inside one combined tear-notch hero. The monthly favorite is a separate ticket. Member spending is independently titled outside its card, and each member row follows the mockup's avatar/name/total, Joy/daily split, and proportion-bar structure.
- Colors and surfaces: the implementation reuses existing paper, ink, Joy pink, daily green, borders, notches, and shadows. No parallel palette or one-off card language was introduced.
- Data and copy: the family header aggregates the primary and shadow books; the lower Joy metric remains personal; the monthly favorite appears only when the current user has a Joy expense. Family recent spending merges all family books, identifies the payer, keeps the existing Joy/daily badge semantics, and does not show a Joy score.
- Images and icons: production rows pass the real member avatar image path into the shared `AvatarDisplay` widget. The deterministic widget-golden harness cannot decode the local file-backed profile photos and therefore captures the existing fallback circle; runtime image loading remains wired and covered by the same component. Category and section graphics use the existing product icon libraries.
- Responsive and interaction behavior: all new rows use bounded flex layouts and 44dp avatar/tap targets. Member detail navigation, recent-spending navigation, personal transaction editing, and remote transaction read-only behavior remain wired. Provider tests cover merged, sorted family transactions and refresh invalidation.
- Accepted P3 copy variance: the source sample says `大満足`, while Flutter renders the shared ADR-014 satisfaction label `至福`. The implementation intentionally keeps the product-wide localized terminology rather than introducing a home-only string.

## Comparison history

1. The first Flutter pass matched the overall A1/A2 structure but member rows were optically denser than the mockup and used the longer ledger-book labels.
2. Member row padding was opened to the reference rhythm, ledger copy was switched to the compact localized `悦己`/`日常` labels, and the visual baselines were regenerated.
3. Final same-input comparisons confirmed the combined tear hero, personal favorite, independent member card, member split bars, payer attribution, and recent-spending title treatment with no remaining actionable P0/P1/P2 mismatch.

## Verification

- Targeted home widget/provider suite: 74 tests passed, 0 failed.
- Home isolation and shadow-book characterization: 5 tests passed, 0 failed.
- Existing HomeHero and new A1/A2 Golden suites: 15 tests passed, 0 failed.
- `flutter analyze`: 0 issues after the final unused-import cleanup.
- `git diff --check`: passed for the implementation and QA artifacts.

final result: passed

---

# V16 A2 Family Home — Tear Hero and Spending Detail Refinement (2026-08-03)

## Scope and evidence

- Source visual truth: the combined spending/Joy structure at `/var/folders/qs/d64k8pm541nbr7hjj9scdxj00000gn/T/TemporaryItems/NSIRD_screencaptureui_EDBuwy/截屏2026-08-03 17.23.27.png` and the member-detail reference at `/var/folders/qs/d64k8pm541nbr7hjj9scdxj00000gn/T/TemporaryItems/NSIRD_screencaptureui_4nyq0Y/截屏2026-08-03 17.24.27.png`.
- Implementation: A1 personal and A2 family home branches in `docs/mockup/v16/index.html`.
- Browser-rendered implementation: `/private/tmp/a2-family-final-tear.png`, `/private/tmp/a2-family-final-details.png`, and `/private/tmp/a1-personal-final-recent.png`.
- Viewport and pixels: implementation used a 390×844 CSS-pixel phone viewport at DPR 1 inside 1265×712 browser captures. Source crops are 772×788 px and 926×318 px; they were compared as focused composition references rather than treated as equal-density full screens.
- State: Japanese, light theme, July 2026, A2 family mode with personal Joy records, three family members, and three recent family transactions; A1 personal mode was also checked for title-style regression.

## Findings

- No actionable P0, P1, or P2 issue remains.
- Fonts and typography: `最近の支出` now reuses the same 13 px section-title token and weight as `今月の最愛` in both A1 and A2. Member names, totals, ledger amounts, and chevrons preserve the V16 type hierarchy without wrapping at the supported widths.
- Spacing and layout rhythm: A2 once again uses one continuous hero card. The family aggregate and personal Joy metric are separated by the same centered tear-divider and side notches used by A1, restoring the intended receipt hierarchy. Member rows follow the focused reference: avatar left, name and total on the first line, Joy/daily subtotals on the second, and a full-width proportion bar beneath.
- Colors and visual tokens: the combined hero, tear divider, Joy ring, daily progress, member split bars, and recent ledger labels use existing V16 paper, ink, Joy pink, and daily green tokens. No new palette was introduced.
- Image quality and asset fidelity: member and payer rows retain the existing V16 raster avatars with circular cropping and no placeholder substitutions. Section and navigation icons use the existing Material Symbols Rounded family.
- Copy and content: the family aggregate remains family-wide while the lower metric is explicitly personal. Recent-spending copy stays consistent across A1 and A2, and the member detail continues to show separate Joy and daily totals without adding a Joy score.
- Responsive behavior: 375, 390, and 430 px phone widths all report `scrollWidth == clientWidth`; the combined hero remains a single component, all member rows retain their proportion bars, and no total, chevron, or ledger label is clipped.
- Interactions and runtime: A1/A2 preset switching, viewport controls, and member-row feedback were exercised in the in-app browser. The member row produced its expected status feedback, and the browser console contained zero errors.

## Comparison evidence

- Full-view comparison: the combined A2 hero capture was compared in the same visual input with the provided header reference. The implementation preserves one receipt surface, the central tear, symmetrical side notches, aggregate-first hierarchy, and A1-derived personal Joy block.
- Focused comparison: the A2 member capture was compared in the same visual input with the provided dark member-detail reference. The implementation matches the requested information order and proportional split-bar treatment while intentionally retaining the selected light theme and Japanese sample content.
- A1 regression evidence: `/private/tmp/a1-personal-final-recent.png` confirms `最近の支出` uses the same title scale and leading-icon treatment as `今月の最愛` without changing the A1 hero or favorite ticket.

## Comparison history

1. The prior A2 pass split the family aggregate and personal Joy metric into two independent cards and rendered member subtotals without the reference proportion bars.
2. This refinement merged the header back into one tear-divided receipt, converted member rows to the reference three-line detail structure, and standardized the recent-spending heading across A1 and A2.
3. The final same-input visual comparison and 375/390/430 px responsive pass found no remaining actionable P0/P1/P2 mismatch.

## Verification

- A2 hero count: 1; tear divider present.
- A2 member rows: 3; all include Joy/daily split bars.
- A1 and A2 `今月の最愛`/`最近の支出` section title size: 13 px.
- Browser console errors: 0.
- `git diff --check -- docs/mockup/v16/index.html design-qa.md`: passed.

final result: passed

---

# V16 A2 Family Home — A1 Visual Reuse (2026-08-03)

## Scope and evidence

- Source visual truth: A1 personal home in `docs/mockup/v16/index.html`, captured at `/private/tmp/a1-personal-reference.png`, plus the focused user reference `/var/folders/qs/d64k8pm541nbr7hjj9scdxj00000gn/T/TemporaryItems/NSIRD_screencaptureui_GWG0a5/截屏2026-08-03 17.08.11.png`.
- Implementation: the A2 family-home branch in `docs/mockup/v16/index.html`.
- Rendered implementation: `/private/tmp/a2-family-final-top.png` and `/private/tmp/a2-family-final-lower.png`.
- Viewport and pixels: A1 and A2 were rendered in the same 390×844 CSS-pixel phone frame at DPR 1 inside 1265×712 browser captures. The focused favorite source is 808×314 px and was compared against the same rendered ticket region without density-dependent layout changes.
- State: Japanese, light theme, July 2026, family mode with personal Joy records, three family members, and three recent family transactions.

## Findings

- No actionable P0, P1, or P2 issue remains.
- Fonts and typography: A2 reuses A1's exact `faithful-region-title`, goal, satisfaction, small-win, calendar, amount, and numeral styles. `今月の最愛` and `メンバーの支出` both resolve to the same 13 px section-title token and optical weight.
- Spacing and layout rhythm: the family aggregate and personal Joy metrics are now separate cards. The favorite section has a transparent outer surface, with only the ticket receiving its paper fill. The member heading is outside its content card and uses the same 18 px section gap and 10 px heading-to-card gap as the favorite ticket.
- Colors and tokens: the family summary, personal Joy card, favorite ticket, member rows, ledger dots, and transaction tags use existing V16 semantic tokens; no new palette or one-off surface was introduced.
- Image and icon fidelity: member and payer rows use the three existing V16 raster avatars. `workspace_premium`, `groups`, category badges, and navigation affordances use the existing Material Symbols Rounded icon family; no placeholder avatar, emoji, or custom-drawn icon was added.
- Copy and content: A2 keeps the family aggregate while presenting `自分のときめき` with the same 64/80 goal, 8.2/10 satisfaction average, and 12 small wins as A1. The monthly favorite is unchanged from A1. Recent Joy transactions show only the existing ledger label and never add a numeric satisfaction score.
- Responsive behavior: 375, 390, and 430 px phone widths render with `scrollWidth == clientWidth`; the avatar, ledger split, total amount, and chevron remain visible without horizontal overflow.
- Interactions: A1/A2 preset switching, Joy present/empty switching, member-row feedback, and family-transaction feedback were exercised. The empty personal-Joy state hides the monthly favorite while preserving member spending. No browser execution error surfaced during these interactions.

## Comparison history

1. Before the change, A2 placed the family Joy metric and text-avatar member totals inside the same large hero card.
2. The first implementation separated family spending from the A1-derived personal Joy module, reused the transparent A1 favorite section, moved member spending into an independently titled card with real avatars, and added payer attribution to recent transactions.
3. The 375/390/430 px pass found no overflow or title-size drift. The final full-view and focused-region comparison found no remaining actionable P0/P1/P2 mismatch.

## Verification

- A1 remains visually unchanged and does not render A2-only member or personal-Joy wrapper components.
- A2 favorite outer background: transparent.
- A2 favorite and member heading font size: both 13 px.
- A2 member title is outside the member card and includes the `groups` icon.
- `git diff --check -- docs/mockup/v16/index.html`: passed.

final result: passed

---

# Unified Unable-to-Join Family State — Selected Direction 1 (2026-08-03)

## Scope and evidence

- Source visual truth: `/Users/xinz/.codex/generated_images/019fc151-a7da-7953-8152-aee24d5ea2e2/exec-e163acf9-dcc0-4aa4-a3fd-cba013c4b845.png`, the first copy/layout direction selected by the user, with the explicit follow-up that neither lower action should have its own filled background.
- Flutter implementation: `lib/features/family_sync/presentation/screens/waiting_approval_screen.dart`, shared by terminal join-request states and active-membership/missing-key states.
- Rendered Flutter implementation: `/Users/xinz/Development/home-pocket-app/test/golden/goldens/family_unable_to_join_safe_area_dark_zh.png`.
- Same-state comparison, selected direction left and Flutter right: `/Users/xinz/.codex/visualizations/2026/08/02/019fc151-a7da-7953-8152-aee24d5ea2e2/family-unable-to-join-comparison.png`.
- Viewport/state: Simplified Chinese, dark theme, 393×852 logical px, 47dp top inset, 34dp bottom safe area, and an unavailable family-join flow. The selected image was normalized from 853×1844 px to the same frame.

## Findings

- No actionable P0, P1, or P2 issue remains.
- Hierarchy: the centered house/unavailable mark, 24sp title, calm two-line explanation, section divider, and fixed lower action region preserve the selected layout while remaining safe-area aware.
- Requested action treatment: both actions have the same 62dp geometry, 18dp radius, padding, outline, centered label, leading icon, trailing chevron, and fully transparent enabled/disabled backgrounds. Green and Joy pink distinguish the two choices without placing either on a separate filled surface.
- Copy: recovery, rejection, cancellation, and expiry no longer expose key-recovery or request-lifecycle terminology. All now use the same friendly Chinese, Japanese, and English copy and the two explicit next choices.
- Interaction: `重新输入邀请码` leaves or dissolves an active family when required and opens invite entry; `退出并重新选择家庭` performs the same authoritative cleanup and opens family choice. Terminal server states clear stale local membership best-effort before continuing. Existing confirmation and network-error dialogs remain in the flow.
- Accessibility and resilience: each action exceeds the 44dp minimum target, keeps its label geometrically centered, provides a loading state, honors bottom SafeArea, and allows the explanatory region to scroll on short screens.
- P3 follow-up only: the production illustration intentionally uses the app's existing Lucide icon language instead of importing the generated concept's decorative path artwork. Its enlarged footprint now matches the reference hierarchy without introducing a one-off raster dependency.

## Comparison history and verification

1. The first Flutter pass unified the two states and replaced the technical copy, but the product-native illustration read smaller than the selected visual target.
2. Same-viewport comparison preserved the user-requested transparent action treatment and increased the unavailable-family mark from 116×102dp to a 164×168dp visual slot.
3. The final comparison confirms the central hierarchy, divider, action alignment, transparent backgrounds, safe-area spacing, and green/pink distinction with no remaining P0/P1/P2 mismatch.
- Waiting-approval widget suite: 17 tests passed, 0 failed.
- Family-flow Golden suite: 10 tests passed, including the new dark Chinese unavailable-state baseline.
- Full Flutter suite: 4,371 tests passed, 11 skipped, 0 failed.
- `flutter analyze`: 0 issues.
- `git diff --check`: passed.

final result: passed

---

# Family Waiting Approval Cancel Action — Design QA (2026-08-03)

## Scope and evidence

- Device-UAT source: `/Users/xinz/Downloads/截屏 2026-08-03 14.15.47.png`, with the reported inactive tap target, clipped lower edge, and low-contrast action.
- Flutter implementation: `lib/features/family_sync/presentation/screens/waiting_approval_screen.dart`, with the emphasized shared button variant in `lib/features/family_sync/presentation/widgets/family_flow_components.dart`.
- Rendered Flutter state: `/Users/xinz/Development/home-pocket-app/test/golden/goldens/family_waiting_approval_safe_area_dark_zh.png`.
- Same-state comparison, device capture left and revised Flutter right: `/Users/xinz/Development/home-pocket-app/.planning/sketches/audits/family-waiting-cancel-2026-08-03/comparison.png`.
- Viewport/state: Simplified Chinese, dark theme, pending join request, 393×852 logical px, 47dp top inset, and 34dp bottom safe area. The device source was normalized from 944×2048 px to the same 393×852 frame; system status icons and the debug ribbon remain runtime-owned.

## Findings

- No actionable P0, P1, or P2 issue remains.
- Root cause: the previous scroll column used fixed 198dp and 300dp gaps, placing the 52dp cancel action inside or below the iPhone bottom gesture area. The existing test called `ensureVisible`, so it did not reproduce the real-device tap geometry. Errors were also rendered below the clipped action, making a failed request appear inert.
- Layout: the page header and progress indicator remain fixed, the waiting content now centers responsively in the available body, and the cancel action lives in a dedicated bottom navigation region with explicit SafeArea protection. The entire 58dp control stays above the 34dp gesture inset without requiring a scroll.
- Affordance: the action now uses the existing Joy palette as a low-emphasis withdrawal treatment, with a visible pink-tinted surface, stronger border, heavier label, subtle shadow, and the real Lucide undo icon. It is visually distinct without competing with primary family-flow actions.
- Interaction: tapping directly invokes the existing cancel join request use case, shows its loading state in place, and keeps friendly network or lifecycle feedback visible above the fixed button. No navigation or server contract was changed.
- Responsive behavior: the center content remains scrollable on genuinely short viewports, while the action stays independently reachable and safe-area aligned.

## Comparison history and verification

1. The device capture showed only the upper portion of a neutral outline button at the physical screen edge.
2. The first corrective pass moved the action into a fixed SafeArea region and added a prominent shared secondary-button variant.
3. Visual QA at the matching dark Chinese viewport found the Material rounded icon unavailable in the deterministic golden font, so it was replaced with the product's existing Lucide icon set.
4. The final side-by-side comparison confirms complete button visibility, stronger contrast, balanced bottom spacing, and no overlap with the gesture area.
- Waiting, member approval, and group management widget suites: 27 tests passed, 0 failed.
- Family-flow Golden suite: 9 tests passed, including the new dark Chinese safe-area baseline.
- Full Flutter suite: 4363 tests passed, 11 skipped, 0 failed.
- `flutter analyze`: 0 issues.
- `git diff --check`: passed.

final result: passed

---

# Family Invite Ticket — Selected Direction 3 (2026-08-03)

## Scope and evidence

- Source visual truth: `/Users/xinz/.codex/generated_images/019fc151-a7da-7953-8152-aee24d5ea2e2/exec-0749cd6d-c504-4b4e-850b-91336938d6ab.png`, the third ticket direction selected by the user and refined to a 45sp invite code. Latest device-UAT evidence: `/Users/xinz/Downloads/截屏 2026-08-03 12.07.10.png`, with explicit requests to center the ticket title and both actions and reduce vertical whitespace.
- Flutter implementation: `lib/features/family_sync/presentation/widgets/family_invite_ticket.dart`, integrated by `lib/features/family_sync/presentation/screens/create_group_screen.dart` with the live timer from `lib/features/family_sync/presentation/widgets/invite_expiry_countdown.dart`.
- Rendered Flutter implementation: `/Users/xinz/Development/home-pocket-app/test/golden/goldens/family_create_invite_ticket_light_zh.png`.
- Full correction comparison, device-UAT screenshot left and revised Flutter right: `/Users/xinz/Development/home-pocket-app/.planning/sketches/audits/family-invite-ticket-2026-08-03/alignment-user-screenshot-vs-flutter.png`.
- Focused equal-width before/after ticket comparison: `/Users/xinz/Development/home-pocket-app/.planning/sketches/audits/family-invite-ticket-2026-08-03/alignment-ticket-before-vs-after.png`.
- Viewport and normalization: device-UAT source 1179×2556 px normalized to 390×844 px; Flutter rendered at 390×844 logical and physical px (DPR 1). Focused ticket crops were normalized to 600 px content width on equal 620×590 px canvases. System status-bar and SafeArea offsets are runtime-owned and excluded from component alignment judgments.
- State: Simplified Chinese, light theme, owner `shean`, family `shean的家`, active six-digit invite with approximately ten minutes remaining. Live invite digits differ between evidence captures but use the same layout and interaction state.

## Findings

- No actionable P0, P1, or P2 issue remains.
- Typography: the full six-digit invite uses the explicitly approved 45sp monospaced numeral treatment, remains centered, and scales down only when a genuinely narrower localized viewport requires it; it never substitutes an ellipsis.
- Ticket silhouette: the production clip path contains real 10.5dp scalloped edge perforations, symmetric 20dp semicircular side notches, 14dp top and bottom corner radii, and a one-pixel palette border. The card is not a raster image or approximate rectangular container.
- Shadow: a separate clipped physical layer is shifted 4dp downward at elevation 2, creating the selected low, warm paper lift without turning the perimeter into a heavy floating-card halo.
- Spacing and hierarchy: the ticket is reduced from 316dp to 252dp. Fixed 22dp title-to-code and code-to-progress gaps replace the former expanding spacers. Below the dashed divider, the remaining height is now an explicit action region; both controls are vertically centered in that region, leaving equal visual space above and below instead of accumulating padding at the card bottom.
- Countdown correctness: the progress bar is driven by the real ten-minute lifetime. Therefore 09:44 correctly renders near-full progress rather than reproducing the source mockup's illustrative half-filled bar. Existing invite values longer than ten minutes are safely capped for display, and expiry still transitions to the localized red invalid state.
- Copy and localization: `家庭邀请码`, `Family Invite Code`, and `家族の招待コード` are generated from the three ARB locales. Copy and regenerate controls keep localized labels with single-line overflow protection.
- Alignment: the title now uses a forced symmetric flex track and centers within 0.5dp of the ticket. The Copy and Regenerate controls use the full ticket width and center exactly on the 1/4 and 3/4 axes instead of being pulled inward by the former 27dp shared inset.
- Affordances and accessibility: both actions retain 48dp control height and localized semantics. Copy, regenerate, countdown, expiry, owner recovery, sharing, and friendly-error behavior remain wired to the existing production flow.

## Comparison history and verification

1. The first Flutter pass fixed the truncated code but used a denser edge pattern, a 296dp ticket, and a more ambient physical shadow.
2. The visual comparison identified three P2 refinements: match the `家庭邀请码` title, open the vertical rhythm, and move the shadow downward.
3. The next pass used 10.5dp scallop spacing, a 316dp ticket, and a dedicated 4dp-down shadow layer.
4. Device UAT then identified a P2 alignment and density issue: the loose title track was not geometrically centered, action groups were each pulled 13.25dp toward the middle, and expanding spacers created excessive vertical blank space.
5. The next pass forced the title track to fill symmetrically, removed the action-row horizontal inset, and reduced the ticket to 252dp with fixed vertical gaps.
6. Device follow-up identified one remaining P2: the fixed 48dp action row sat immediately below the divider while unused column height accumulated underneath it.
7. The final pass turns all space below the divider into one action region and centers the 48dp controls inside it. Geometry tests confirm each action center equals the midpoint between the divider and ticket bottom within 0.5dp; the revised focused comparison found no remaining actionable P0/P1/P2 mismatch.
- 320dp widget and full-screen coverage confirms the entire `256 931` code remains visible without horizontal overflow, including when the golden test font is loaded concurrently.
- Targeted widget and Golden set: 23 tests passed, 0 failed.
- `flutter analyze`: 0 issues.
- `git diff --check`: passed.

final result: passed

---

# Unified Toast Status Pill — Selected Direction 3 (2026-08-02)

## Scope and evidence

- Source visual truth: `/Users/xinz/.codex/generated_images/019fc151-a7da-7953-8152-aee24d5ea2e2/exec-6e522b26-b8b8-49a8-bf63-c57d56d0d5ee.png`, the third ideation direction selected by the user.
- Rendered Flutter implementation: `/Users/xinz/Development/home-pocket-app/test/golden/goldens/feedback_toast_status_pill_dark_zh.png`.
- Focused same-input comparison, selected mockup left and Flutter right: `/Users/xinz/Development/home-pocket-app/.planning/sketches/audits/invite-feedback-2026-08-02/status-pill-source-vs-implementation.png`.
- Viewport and normalization: source frame 853×1844 px; source pill crop 420×160 px. Flutter rendered at 390×844 logical and physical px (DPR 1); implementation pill crop 250×100 px. Each crop was scaled to 600 px width, centered on an equal 620×270 px canvas, and placed side by side.
- State: Simplified Chinese success feedback, dark theme, compact top status pill. The underlying Family screen was intentionally excluded because this QA scope is the shared transient-feedback component.

## Findings

- No actionable P0, P1, or P2 issue remains.
- Fonts and typography: message copy uses the shared 15/1.35/600 style with `TextDecoration.none`; action labels also explicitly remove decoration. The deterministic Flutter golden environment renders CJK with Ahem square glyphs, so native-device Chinese glyph appearance remains a device-UAT item rather than a component geometry defect.
- Spacing and layout rhythm: the pill has a 52 px minimum height, intrinsic short-copy width, a 360 px maximum width for localized copy, 10 px insets, a 28 px badge, an 18 px icon, an 8 px icon-to-copy gap, and a 26 px radius. Long messages wrap up to three lines instead of overflowing.
- Colors and visual tokens: the warm card surface, restrained 14 px shadow, light-green success badge, and dark check reproduce the selected calm status treatment. Error and information variants keep the same geometry while changing only their semantic badge and action colors.
- Image quality and asset fidelity: all states use real Material icons (`check_rounded`, `priority_high_rounded`, and `info_outline_rounded`) rendered by Flutter; no raster placeholders, emoji, handcrafted SVG, or custom-drawn substitute was introduced.
- Copy and content: existing localized product copy is preserved. Raw transport errors remain handled by the existing friendly-message layer rather than exposed by the shared component.
- Affordances and accessibility: feedback is an auto-dismiss live region, matching the selected no-close-button direction. Optional Undo or voice actions remain inside the same pill with a minimum 44 px target and no underline.
- Full-view evidence: the production golden records the full viewport and top-safe-area placement.
- Focused evidence: the normalized comparison keeps the pill silhouette, badge polarity, icon scale, text baseline, and shadow legible at equal visual width.

## Comparison history and verification

1. The previous shared toast used a larger emblem, outlined full-width card, close control, and link-like underlined copy.
2. The first Direction 3 pass reduced the card but retained a 32 px dark badge with a bright check; the focused comparison identified a P2 scale and polarity mismatch.
3. The badge was reduced to 28 px, inverted to a light badge with dark check for success, and the shadow was softened. The final equal-width comparison found no remaining P0/P1/P2 issue.
- All production `SnackBar` and `showSnackBar` entry points were migrated to the shared success, error, or information pill; the architecture scan now returns no matches under `lib/`.
- Six affected widget/unit/architecture files: 62 tests passed.
- Full serial suite: 4342 tests passed, 11 skipped, 0 failed.
- `flutter analyze`: 0 issues.
- `git diff --check`: passed.

final result: passed

---

# Family Network Dialog — Selected Direction 1 (2026-08-02)

## Scope and evidence

- Source visual truth: `/Users/xinz/.codex/generated_images/019fc151-a7da-7953-8152-aee24d5ea2e2/exec-b7f85111-8afc-4b3d-bf21-45f6634f1212.png`, the first displayed ideation result selected by the user.
- Rendered Flutter implementation: `/Users/xinz/Development/home-pocket-app/test/golden/goldens/family_network_unavailable_dialog_dark_zh.png`.
- Same-input comparison, selected mockup left and Flutter right: `/Users/xinz/Development/home-pocket-app/.planning/sketches/audits/family-network-dialog-2026-08-02/source-vs-implementation.png`.
- Viewport and normalization: source full frame 852×1846 px; source dialog crop 692×628 px. Flutter rendered at 390×844 logical and physical px (DPR 1); implementation dialog crop 318×299 px. Both crops were scaled to 636 px width and centered on equal 660×640 px canvases before comparison.
- State: Simplified Chinese, dark theme, Create Family flow, network unavailable dialog open.

## Findings

- No actionable P0, P1, or P2 issue remains.
- Fonts and typography: title weight and centered hierarchy follow the selected mockup; body copy remains the production 14/21 token and wraps to two balanced lines at the target viewport. Native-device CJK rendering remains system-owned; the golden loads a deterministic Unicode font for visual regression coverage.
- Spacing and layout rhythm: the 36 px dialog inset, 20 px content inset, 80 px status badge, 40 px glyph, title gap, body gap, and trailing actions closely reproduce the selected component proportions without crowding the message or buttons.
- Colors and visual tokens: the badge uses the production wakaba accent, accent-soft surface, and palette-driven border. The subtle shadow is intentionally restrained compared with the Image Gen halo so the result remains consistent with the app's low-elevation dark surfaces.
- Image quality and asset fidelity: the network mark is the real Material `wifi_off_rounded` icon rendered by Flutter. No raster placeholder, emoji, handcrafted SVG, or custom-drawn substitute was introduced.
- Copy and content: the existing localized title, guidance, Cancel, and Retry labels are unchanged; raw transport errors remain hidden.
- Affordances and accessibility: the larger badge makes the failure state immediately recognizable while the title remains the semantic explanation. Cancel and Retry behavior is unchanged and covered through both Create Family and Family Settings widget paths.
- Full-view evidence: the complete dialog component is visible in both halves of the comparison, including outer radius, emblem, title, body, and actions.
- Focused evidence: no additional crop was needed because the normalized component comparison keeps the 40 px icon, Chinese text, border, and both controls legible.

## Comparison history and verification

1. Before formal QA, the first implementation check used an 88 px badge with default AlertDialog insets; it made the component too tall and forced the body to three lines.
2. The badge was normalized to 80 px with a 40 px icon, the dialog inset to 36 px, and content inset to 20 px. The first formal equal-width comparison found no remaining P0/P1/P2 difference, so no further corrective iteration was required.
- Create Family widget suite: 7 tests passed.
- Family Settings widget suite: 6 tests passed.
- Dark Chinese golden: passed without baseline updates after final capture.
- `flutter analyze`: 0 issues.

final result: passed

---

# V16 Family Entry to Management — Design QA (2026-08-02)

## Scope and evidence

- Source visual truth: `/Users/xinz/Development/home-pocket-app/docs/mockup/v16/index.html`, using the task-oriented family entry and the create, join, approval, waiting, and management states defined by the V16 mockup.
- Flutter golden coverage: `/Users/xinz/Development/home-pocket-app/test/golden/family_flow_v16_golden_test.dart`, rendered in Japanese light mode at 390×810 logical px with realistic group, invite, owner, applicant, and member data.
- Same-input comparison board: `/Users/xinz/.codex/visualizations/2026/08/02/019fbfcf-9e3e-7803-a031-6c9525f40eb7/family-flow-v16-qa-board.png`. Each row places the Mockup on the left and Flutter on the right at the same 390×810 viewport.
- Compared states: family entry, created-family invite, invite-code entry, join confirmation, member approval, applicant waiting, and family management.

## Findings

- No actionable P0, P1, or P2 issue remains.
- Information architecture: the entry is now task-oriented with two direct paths and no shared onboarding stepper. Create follows create → invite → approve; join follows code → confirm → wait. Management intentionally omits onboarding progress.
- Spacing and layout rhythm: the implementation matches the 20 px page inset, centered 44 pt navigation header, compact three-step progress, paper background, 14–18 px radii, card spacing, and first-viewport content density of the Mockup. The management transfer action remains available below the first viewport without leaking into the reference composition.
- Typography and color: hierarchy, muted helper copy, leaf-green states, sakura primary actions, pale verification surfaces, borders, and destructive actions use the existing app tokens while following the V16 visual target.
- Assets and avatars: family-entry illustrations use the four V16 light/dark raster assets. Production member and applicant rows use `AvatarDisplay` with real image paths and emoji fallback. The golden test runner does not decode the fixture `FileImage` paths, so the comparison board shows pale avatar circles in two Flutter states; this is a test-rendering limitation, not the production UI behavior.
- Interaction coverage: create confirmation remains explicit before group creation; invite copy, share, and force-refresh work; join review precedes submission; owners can approve or reject; applicants can cancel; sync settings open a dedicated sheet; ownership transfer, leave, and disband paths remain available.
- Accessibility and responsiveness: primary controls preserve 44–54 pt touch areas and semantic labels. Entry/create/join were exercised at 320×640 and 430×932, and family management at 320×640, with no overflow.
- Localization and privacy: Japanese, Chinese, and English ARB files remain valid and generated output was refreshed. The private-ledger and zero-knowledge helper copy remains visible throughout the flow.

## Verification

- Family-sync presentation widget suite: 55 tests passed.
- V16 family-flow golden suite: 7 tests passed after updating the intentional baselines.
- Full Flutter suite: 4,314 tests passed, 11 skipped.
- `flutter analyze`: 0 issues.
- ARB JSON validation, Dart formatting, and scoped `git diff --check`: passed.

final result: passed

---

# V16 Settings Item Height Correction — Design QA (2026-08-01)

## Audit scope and evidence

- User-reported before state: `/Users/xinz/Downloads/截屏 2026-08-01 14.39.43.png` (1320×2868 px), showing the first-level Chinese settings screen with visibly compressed General and Security rows.
- Source visual truth after the audit: `/Users/xinz/.codex/visualizations/2026/08/01/019fbb2d-1f5d-77c0-b91d-720468b55c19/settings-mockup-72dp-390.png`.
- iOS Simulator implementation: `/Users/xinz/.codex/visualizations/2026/08/01/019fbb2d-1f5d-77c0-b91d-720468b55c19/settings-app-72dp.png`.
- Same-input comparison, updated Mockup left and Flutter right: `/Users/xinz/.codex/visualizations/2026/08/01/019fbb2d-1f5d-77c0-b91d-720468b55c19/settings-row-height-qa-comparison.png`.
- Viewport and normalization: source is 390×844 CSS px at DPR 1. Flutter was rendered on an iPhone simulator at 390×844 logical px, captured at 1170×2532 px (DPR 3), and downsampled to 390×844 for equal-size comparison.
- State: Japanese, personal light, profile `あおい`, family unconfigured, app lock off, Monday week start, Japanese recognition language, and monthly target 80.

## Findings

- No actionable P0, P1, or P2 issue remains.
- Audit finding: the previous `VisualDensity(vertical: -4)` forced General action rows to 48 logical px and Security switch rows to 60 logical px. Although the smaller action rows narrowly met common minimum touch-target guidance, the title/subtitle pair, icon, and divider had insufficient breathing room and looked materially more compressed than standard mobile settings lists.
- Spacing and layout rhythm: all shared settings actions, security switches, biometric switches, notifications, and backup/restore actions now have a 72 logical px minimum height, 8 px minimum vertical content padding, standard visual density, and 42 px icon surfaces. Dividers, 20 px page inset, 18 px card radii, and section spacing remain unchanged.
- Fonts and typography: the existing system-font title/supporting hierarchy, line heights, weights, truncation, and locale behavior are unchanged. The additional height creates separation around the two lines without enlarging text.
- Colors and visual tokens: paper background, card, pine-green foreground, muted supporting copy, border, and switch colors are unchanged. The correction is dimensional, not a new visual theme.
- Image quality and asset fidelity: the real profile avatar renderer and Material icon set remain intact and sharp. No placeholder or approximate asset was introduced.
- Copy and content: the Mockup now uses the app's current `ときめき目標` label and the comparison fixture uses Japanese recognition language so source and implementation represent the same state.
- Accessibility and responsiveness: 375, 390, and 430 px Mockup widths all keep a 72 px minimum row height with `scrollWidth == clientWidth`. The iOS app keeps the whole row tappable, exceeding Apple's 44 pt default control-size baseline and matching Flutter's standard 72 px two-line ListTile contract.
- Focused comparison was not necessary: the full 390×844 comparison keeps every General row, icon, divider, title, and subtitle legible at 1:1 pixels, which is the entire changed region.

## Comparison history and verification

1. The before implementation measured 48 px for General actions and 60 px for Security switches; new regression assertions failed at those exact values.
2. The shared row contract was restored to standard density with a 72 px minimum and 42 px icons. The first simulator comparison found two state/copy drifts unrelated to geometry: recognition language was Chinese and the Mockup retained the older monthly-target label.
3. The deterministic simulator fixture was aligned to Japanese recognition language and the Mockup was aligned to the current product copy. The second equal-viewport comparison found no remaining P0/P1/P2 mismatch in the changed surface.
- Settings widget suite: 51 tests passed.
- V16 settings/profile/backup/legal golden suite: 4 tests passed after updating the intentional settings and backup row-height baselines.
- iOS integration visual capture: passed.
- Browser responsiveness: 375/390/430 px, no horizontal overflow; all 11 Mockup settings actions measured at least 72 px.
- Browser console: 0 errors and 0 warnings.
- `flutter analyze`: 0 issues.

final result: passed

---

# V16 Settings Flutter Implementation — Design QA (2026-08-01)

## Scope and evidence

- Source visual truth: `/Users/xinz/.codex/visualizations/2026/08/01/019fbb2d-1f5d-77c0-b91d-720468b55c19/settings-language-order-final.png`, using the V16 phone content crop at `(436, 82, 826, 926)` for a 390×844 px source viewport.
- iOS Simulator implementation: `/Users/xinz/.codex/visualizations/2026/08/01/019fbb2d-1f5d-77c0-b91d-720468b55c19/settings-flutter-v16-final.png`.
- Same-input comparisons, Mockup left and Flutter right:
  - full 390×844 surface: `/Users/xinz/.codex/visualizations/2026/08/01/019fbb2d-1f5d-77c0-b91d-720468b55c19/settings-mockup-vs-flutter-final.png`
  - focused top hierarchy: `/Users/xinz/.codex/visualizations/2026/08/01/019fbb2d-1f5d-77c0-b91d-720468b55c19/settings-mockup-vs-flutter-focused.png`
- Viewport and normalization: source content is 390×844 px at DPR 1. The implementation was rendered on an iPhone 16e Simulator at 390×844 logical px and captured at 946×2048 px, then downsampled to 390×844 for comparison. Device status-bar rendering is platform-owned and was not treated as app-content drift.
- State: Japanese, personal light, profile `あおい`, family unconfigured, app lock off, Monday week start, Japanese recognition language, monthly target 80, and notifications on.

## Findings

- No actionable P0, P1, or P2 issue remains.
- Information architecture: the main page order is profile, General, Family, Security, Notifications, Data, This App, Data Management, and footer. The former Other Settings navigation is absent. General is exactly `外観 → 言語 → 認識言語 → ときめき目標 → 週の開始日`; recognition language directly follows display language.
- Fonts and typography: the simulator uses the native Japanese system font with the same bold title, item-title, supporting-copy, and section-heading hierarchy as the Mockup. The Flutter copy retains `ときめき目標` as an intentional ADR-015 product-language constraint instead of the Mockup's older `月間 Joy 目標` wording.
- Spacing and layout rhythm: the final 38 px soft icon tiles, compact ListTile density, 20 px page inset, 18 px card radius, 72 px divider inset, section gaps, and profile-card proportions closely match the source. App-owned content reaches the Security row within the same first viewport.
- Colors and visual tokens: paper background, white cards, pine-green text/icons, pale icon surfaces, borders, switches, and muted supporting text map to the existing app palette and remain visually aligned with the Mockup.
- Image quality and asset fidelity: the profile surface uses the real user avatar renderer rather than a placeholder. The leaf avatar in the verification fixture intentionally represents user data; all functional icons use Flutter's Material icon set and remain sharp at simulator density.
- Copy and affordances: device-theme copy now matches `端末の設定に合わせる`; family sync uses `家族同期`; the unconfigured compact family row no longer shows a redundant sync-status badge. All tappable preference rows retain chevrons, and switches retain native iOS affordances.
- Interaction and hierarchy coverage: recognition-language selection persists Japanese/Chinese/English; application-lock deep linking, security states, backup/legal navigation, and destructive-data placement remain covered. The main hierarchy test verifies Notifications, Backup, Legal, and Delete All Data remain first-level even when below the captured fold.

## Comparison history and verification

1. The first Flutter comparison had a P2 density mismatch: two-line rows were roughly 20 px taller than the Mockup, so the app-lock control fell below the first viewport. The compact family row also displayed an extra no-group status badge.
2. Shared settings rows were tightened with compact visual density and 38 px icon tiles; compact family sync now shows only its disclosure chevron. A new same-size simulator capture confirmed the General, Family, Security, and Notifications sequence aligns with the Mockup without cramped text or horizontal overflow.
- Settings widget suite: 51 tests passed.
- V16 settings/profile/backup/legal golden suite: 4 tests passed after updating the settings and backup baselines for the intentional compact row geometry.
- Recognition-language interaction: Japanese, Chinese, and English selector tested; persistence assertion passed.
- `flutter analyze`: 0 issues.
- ARB files regenerated for Japanese, Chinese, and English; scoped `git diff --check`: passed.

final result: passed

---

# V16 Settings Recognition Language Row Order — Design QA (2026-08-01)

## Scope and evidence

- Source visual truth: `/Users/xinz/.codex/visualizations/2026/08/01/019fbb2d-1f5d-77c0-b91d-720468b55c19/settings-voice-language-general-final.png`, the immediately preceding V16 settings state.
- Browser-rendered implementation: `/Users/xinz/.codex/visualizations/2026/08/01/019fbb2d-1f5d-77c0-b91d-720468b55c19/settings-language-order-final.png`.
- Same-input comparisons, source left and implementation right:
  - full board: `/Users/xinz/.codex/visualizations/2026/08/01/019fbb2d-1f5d-77c0-b91d-720468b55c19/settings-language-order-comparison-full.png`
  - focused phone frame: `/Users/xinz/.codex/visualizations/2026/08/01/019fbb2d-1f5d-77c0-b91d-720468b55c19/settings-language-order-comparison-phone.png`
- Viewport and normalization: browser viewport 1400×1200 CSS px at DPR 1; both board captures are 1385×1187 px, and the focused comparison uses equal 424×872 px crops.
- State: Japanese, A1 personal light, family unconfigured, app lock off, Monday week start, Japanese recognition language, and notifications on.

## Findings

- No actionable P0, P1, or P2 issue remains.
- Information architecture: the General card order is exactly `外観 → 言語 → 認識言語 → 月間 Joy 目標 → 週の開始日`; recognition language now follows display language directly.
- Typography, spacing, color, icon, imagery, and copy are unchanged; only the existing row order moved.
- Interaction remains intact: the recognition-language selector still offers Japanese, Chinese, and English, and selecting English updates the row value to `English`.
- Responsive behavior: 375, 390, and 430 px phone widths have no horizontal overflow; `appScrollWidth` equals `appClientWidth` at every checked width.

## Comparison history and verification

1. The source placed recognition language after monthly Joy target and week start.
2. The implementation moved the existing recognition-language row directly below display language. The first same-viewport comparison found no visual regression, so no corrective QA iteration was required.
- Browser runtime log: no messages.
- Inline JavaScript syntax and scoped `git diff --check`: passed.

final result: passed

---

# V16 Settings Recognition Language Simplification — Design QA (2026-08-01)

## Scope and evidence

- User removal reference: `/var/folders/qs/d64k8pm541nbr7hjj9scdxj00000gn/T/TemporaryItems/NSIRD_screencaptureui_3jCeqe/截屏2026-08-01 13.35.24.png`, identifying the on-device recognition and cloud fallback rows to remove.
- Pre-edit visual source: `/Users/xinz/.codex/visualizations/2026/08/01/019fbb2d-1f5d-77c0-b91d-720468b55c19/settings-first-level-final-top.png`.
- Browser-rendered implementation:
  - top: `/Users/xinz/.codex/visualizations/2026/08/01/019fbb2d-1f5d-77c0-b91d-720468b55c19/settings-voice-language-general-final.png`
  - lower sections: `/Users/xinz/.codex/visualizations/2026/08/01/019fbb2d-1f5d-77c0-b91d-720468b55c19/settings-voice-language-general-lower.png`
- Same-input comparisons, source left and final implementation right:
  - full board: `/Users/xinz/.codex/visualizations/2026/08/01/019fbb2d-1f5d-77c0-b91d-720468b55c19/settings-voice-language-general-comparison-full.png`
  - focused phone frame: `/Users/xinz/.codex/visualizations/2026/08/01/019fbb2d-1f5d-77c0-b91d-720468b55c19/settings-voice-language-general-comparison-phone.png`
- Viewport and normalization: browser viewport 1400×1200 CSS px at DPR 1; source and implementation board captures are both 1385×1187 px. The phone is 390×844 CSS px in both states, and the focused comparison uses equal 424×872 px crops. No density normalization was required.
- State: Japanese, A1 personal light, family unconfigured, app lock off, Monday week start, Japanese recognition language, and notifications on.

## Findings

- No actionable P0, P1, or P2 issue remains.
- Information architecture and copy: the separate `音声認識` section is removed. `認識言語` is now the fifth row inside `一般`, directly after week start. `オンデバイス認識` and `クラウドへのフォールバック` are absent from the settings screen, state model, and interaction handlers.
- Fonts and typography: the moved row retains the same Japanese system-font hierarchy, label weight, subtitle size, line height, and truncation behavior as the surrounding General rows.
- Spacing and layout rhythm: the General card expands by one established row without introducing a new component or compressed spacing. The overall settings scroll height decreases from 1462 px to 1286 px, while all later sections preserve their existing order and vertical rhythm.
- Colors and visual tokens: the retained microphone row reuses the established daily-soft icon tile, paper card, border, text, and chevron tokens. No new semantic color was introduced.
- Image quality and asset fidelity: the existing profile avatar is unchanged and the microphone remains from Material Symbols Rounded. No generated, placeholder, CSS-drawn, SVG, or emoji asset was added.
- Copy and affordance: `認識言語 / 日本語` remains a standard navigation row and opens the three-language selector. Removed implementation-policy details are no longer presented as user-facing preferences.
- Responsive behavior: 375, 390, and 430 px phone widths have no horizontal overflow; `appScrollWidth` equals `appClientWidth` at each checked width.

## Comparison history and verification

1. The pre-edit source showed recognition language inside a separate three-row Voice Recognition section together with on-device status and a cloud fallback switch.
2. The requested implementation moved only recognition language into General and removed the other two rows. The first same-viewport comparison found no actionable P0/P1/P2 visual or usability issue.
- Primary interaction tested: recognition language opens Japanese, Chinese, and English choices; selecting English updates the row to `English`.
- Browser console: 0 errors and 0 warnings.
- Inline JavaScript syntax and scoped `git diff --check`: passed.

final result: passed

---

# V16 Settings First-Level Information Architecture — Design QA (2026-08-01)

## Scope and evidence

- Source visual truth: `/Users/xinz/.codex/visualizations/2026/08/01/019fbb2d-1f5d-77c0-b91d-720468b55c19/settings-first-level-source-before.png`, captured from the pre-edit V16 settings screen.
- Browser-rendered implementation:
  - top: `/Users/xinz/.codex/visualizations/2026/08/01/019fbb2d-1f5d-77c0-b91d-720468b55c19/settings-first-level-final-top.png`
  - lower first-level sections: `/Users/xinz/.codex/visualizations/2026/08/01/019fbb2d-1f5d-77c0-b91d-720468b55c19/settings-first-level-final-middle.png`
  - destructive confirmation: `/Users/xinz/.codex/visualizations/2026/08/01/019fbb2d-1f5d-77c0-b91d-720468b55c19/settings-first-level-delete-dialog.png`
  - dark theme: `/Users/xinz/.codex/visualizations/2026/08/01/019fbb2d-1f5d-77c0-b91d-720468b55c19/settings-first-level-dark.png`
- Same-input comparisons, source left and final implementation right:
  - full board: `/Users/xinz/.codex/visualizations/2026/08/01/019fbb2d-1f5d-77c0-b91d-720468b55c19/settings-first-level-comparison-full.png`
  - focused phone frame: `/Users/xinz/.codex/visualizations/2026/08/01/019fbb2d-1f5d-77c0-b91d-720468b55c19/settings-first-level-comparison-phone.png`
- Viewport and normalization: the browser viewport was 1400×1200 CSS px at DPR 1. Source and implementation board captures were both 1385×1187 px; the phone measured 390×844 CSS px in both states. No density normalization was required. The focused comparison uses equal 424×872 px crops including the same phone frame.
- State: Japanese, A1 personal light, profile `あおい`, family unconfigured, application lock off, Monday week start, Japanese recognition language, cloud fallback on, and notifications on. A2 family light and A3 personal dark were also checked.

## Findings

- No actionable P0, P1, or P2 issue remains.
- Information architecture and copy: the former “その他の設定” destination is absent. Week start is grouped with General; Voice Recognition, Notifications, Data, This App, and Data Management are directly available in the main settings scroll. The irreversible delete action is isolated at the bottom and explicitly warns that unbacked-up records will be permanently removed.
- Fonts and typography: the existing Japanese system-font stack, weights, line heights, and truncation behavior are unchanged. New headings, labels, subtitles, and switch rows reuse the established V16 type hierarchy without cramped wrapping at 375, 390, or 430 px.
- Spacing and layout rhythm: the 390×844 phone frame, 20 px page inset, section spacing, row height, icon slots, card radii, dividers, and profile header are retained. The intentional extra rows extend the page to a 1462 px scroll height instead of compressing controls.
- Colors and visual tokens: new rows use existing paper, pine-green, border, muted-text, switch, and error tokens. Destructive data deletion is the only red semantic treatment; light and dark themes retain adequate separation between cards and background.
- Image quality and asset fidelity: the existing profile avatar asset is preserved. All new functional icons come from the same Material Symbols Rounded family; no placeholder, handcrafted SVG, CSS illustration, emoji, or raster substitute was introduced.
- Icons and affordances: navigation rows retain chevrons, switches expose `aria-pressed`, the on-device recognition status is non-interactive, and the danger row opens a two-action confirmation dialog.
- Interaction and accessibility: week start and recognition language selectors update their row values; cloud fallback and notification switches update state while preserving scroll position; delete requires explicit confirmation. Existing minimum row and control sizes remain practical for touch.
- Responsive behavior: at 375, 390, and 430 phone widths, `appScrollWidth` equals `appClientWidth` with no horizontal overflow. A2 family copy and A3 dark tokens remain intact.

## Comparison history

1. The source settings screen preserved the V16 visual system but kept week start, voice recognition, notifications, and delete-all behind a separate Other Settings destination in the Flutter information model.
2. The first redesign surfaced those controls in seven regular groups plus a bottom danger group and preserved the original component language. The first QA pass found a P2 inspector-copy mismatch: it described “8 groups plus a danger area” although the visible structure was seven regular groups plus one danger area.
3. The inspector copy was corrected to `7 个常规分组 + 1 个独立危险区`. The final same-viewport, same-state comparison found no remaining P0/P1/P2 issue.

## Verification

- Primary interactions tested: week start Monday/Sunday, recognition language Japanese/Chinese/English, cloud fallback on/off, notifications on/off, delete confirmation/cancel, A2 family light, and A3 personal dark.
- Responsive checks: 375, 390, and 430 px phone widths; no horizontal overflow.
- Browser console: 0 errors and 0 warnings.
- Inline JavaScript syntax and scoped `git diff --check`: passed.

final result: passed

---

# V16 Home No-Joy C2 Flutter — Design QA (2026-07-29)

## Scope and evidence

- Selected source of visual truth:
  - `/Users/xinz/Development/home-pocket-app/.planning/sketches/audits/home-joy-empty-2026-07-29/refine-c2-light.png`
  - `/Users/xinz/Development/home-pocket-app/.planning/sketches/audits/home-joy-empty-2026-07-29/refine-c2-dark.png`
- Flutter iOS simulator captures:
  - `/Users/xinz/Development/home-pocket-app/.planning/sketches/audits/home-joy-empty-2026-07-29/flutter-c2-ios.png`
  - `/Users/xinz/Development/home-pocket-app/.planning/sketches/audits/home-joy-empty-2026-07-29/flutter-c2-ios-dark.png`
- Same-input focused comparisons, source left and Flutter right:
  - `/Users/xinz/Development/home-pocket-app/.planning/sketches/audits/home-joy-empty-2026-07-29/c2-mockup-vs-flutter.png`
  - `/Users/xinz/Development/home-pocket-app/.planning/sketches/audits/home-joy-empty-2026-07-29/c2-mockup-vs-flutter-dark.png`
- Viewport and density: the source is 390×844 px. Flutter was captured on an iPhone 16e simulator at 390×844 logical px and 3× density (1170×2532), then the common 350×337 HomeHero region was normalized to the same pixel size for direct comparison.
- State: July 2026, Japanese, personal mode, ¥132,800 current spending, ¥146,020 previous spending, ¥132,800 daily spending, and zero Joy-ledger transactions. The focused comparison isolates the user-scoped HomeHero card; complete simulator captures were inspected separately.

## Findings

- No actionable P0, P1, or P2 issue remains.
- Layout and spacing: the implementation matches the 350×337 card crop, 22 px outer radius, 18 px spending-region inset, ticket tear notches, compact 166 px empty-Joy region, and the mockup's staggered journal-note row.
- Monthly spending: the existing amount, comparison, and split bar implementation is reused without content or layout modification, as requested.
- Empty state: Joy rings, Joy metrics, and the monthly favorite are hidden when the current scope has no Joy transactions. The replacement prompt keeps the selected C2 heart marker, short invitation, free-entry action, and three distinct note-style actions.
- Typography and copy: the Japanese source wording is matched, with equivalent ja/zh/en localization and a family-mode title that follows the accepted ADR-015 lexical hierarchy. All three locales fit at 390 logical px without overflow.
- Color and imagery: the C2 region uses existing semantic Joy, accent, and daily palette tokens in light and dark modes. It requires no raster placeholder, custom SVG, ASCII, or emoji; the closest matching Material icon set is used for the heart, drink, book, and rest concepts.
- Dark theme: the C2 empty region remains aligned. The upper monthly-spending surface retains the app's existing dark token rather than adopting the mockup's slightly greener reference color because that region was explicitly out of scope.
- Interaction: all four actions are semantic, tappable controls. Each suggestion opens the existing one-step entry flow in the Joy ledger and preselects the corresponding coffee, book, leisure, or general Joy category without changing later category-ledger inference.
- Accessibility and resilience: controls use `InkWell` and button semantics, labels ellipsize safely, dark mode is covered, and ja/zh/en widget tests confirm no Flutter layout exception at 390 logical px.

## Comparison history

1. The previous empty state still rendered zero-value Joy rings and an empty favorite section, consuming excess space and implying unavailable metrics.
2. The first Flutter pass hid those regions and introduced the selected C2 journal-note invitation while preserving the monthly-spending region.
3. The first same-size paired review showed the note row sitting about 8 px too high. Increasing the header-to-note gap from 12 px to 20 px aligned the row with the mockup; the second light comparison passed.
4. The dark comparison confirmed the new C2 region geometry and hierarchy. The inherited upper-surface dark color difference was retained as an explicit product-token and scope constraint.

## Verification

- `flutter gen-l10n`: completed for ja/zh/en.
- `flutter analyze`: passed with 0 issues.
- Focused HomeHero, entry-form, and golden suite: 59 tests passed.
- Full `flutter test`: 3,873 tests passed, 11 pre-existing skipped tests, 0 failures.
- Light and dark HomeHero C2 goldens regenerated and passed.
- Direct same-state, same-size source-versus-Flutter comparisons: passed.

final result: passed

---

# V16 Settings Surfaces — Design QA (2026-08-01)

## Scope and evidence

- Source visual truth: `docs/mockup/v16/index.html` screens `設定`, `個人資料`, `バックアップと復元`, and `法務与赞助`, plus the user-supplied settings screenshots from 2026-08-01.
- Flutter implementation: settings, profile edit, backup/restore, and legal/support presentation surfaces under `lib/features/`.
- Viewport/state: 390×844 logical pixels, DPR 1, Japanese, A1 personal light, profile `あおい`, monthly Joy target `80`, family unconfigured, and app lock off.
- Golden captures: `test/golden/goldens/settings_v16_light_ja.png`, `profile_edit_v16_light_ja.png`, `backup_restore_v16_light_ja.png`, and `legal_sponsor_v16_light_ja.png`.
- Same-input comparisons: `/Users/xinz/.codex/visualizations/2026/08/01/019fbb2d-1f5d-77c0-b91d-720468b55c19/settings-mockup-flutter-comparison.png`, `profile-mockup-flutter-comparison.png`, `backup-mockup-flutter-comparison.png`, and `legal-mockup-flutter-comparison.png`.
- Full-view evidence was used for all four surfaces; focused crops were unnecessary because every target fits within one 390×844 screen.

## Findings and fixes

- No actionable P0, P1, or P2 issue remains.
- Settings now preserves the mockup hierarchy: profile header, General, Family, Security, Data, and This App. Week start, voice recognition, notifications, and destructive data deletion remain reachable under Other settings without crowding the primary path.
- App-lock copy reflects stored initial state. Enabling requires PIN setup first; after activation, Face ID/fingerprint and PIN controls are available and can be changed independently within the established re-authentication rules.
- Profile edit contains only avatar and display name; the family-display field is absent. The final pass corrected avatar scale, field width, and the solid primary save button against the source.
- Backup and restore exposes only encrypted `.hpb` export/import in the primary flow. CSV and destructive deletion are absent from this destination, and restore warns that current data will be replaced.
- Legal rows open real locale-specific public repository URLs, with bundled offline documents as fallback. The support card opens the operator's real contact page; no unverified donation destination was introduced.
- The headless golden runner does not bundle Japanese glyph outlines, so its screenshots show fallback boxes; layout metrics, spacing, color, borders, radii, and interaction structure remain deterministic. Production uses the platform CJK fonts.

## Comparison history and verification

1. Initial comparison found the Joy target and app-lock rows too verbose, destructive deletion incorrectly attached to backup, and the profile CTA/avatar visually divergent.
2. The primary settings rows were compacted, destructive deletion moved to Other settings, and the profile controls were aligned to the source.
3. Final same-state comparisons found no remaining P0/P1/P2 mismatch.
- `flutter analyze`: 0 issues.
- Targeted settings/profile/backup/legal/family tests: 45 passed.
- Golden suite: 4 passed at 390×844.
- Full `flutter test`: 3,896 passed, 11 skipped.

final result: passed

---

# V16 Initial Setup Title + Avatar Delta — Design QA (2026-07-26)

## Scope and evidence

- User reference: `/Users/xinz/Downloads/截屏 2026-07-26 16.33.16.png`.
- Flutter simulator capture: `/Users/xinz/.codex/visualizations/2026/07/19/019f7881-03db-72f2-a542-5b075d8e3a27/onboarding-setup-title-avatar-impl.png`.
- Same-input focused comparison, reference left and implementation right:
  `/Users/xinz/.codex/visualizations/2026/07/19/019f7881-03db-72f2-a542-5b075d8e3a27/onboarding-setup-title-avatar-comparison.png`.
- State: Chinese, dark theme, security disabled. Both captures were normalized to 390px width and inspected through the common upper 560px region; the complete 390×844 Flutter capture was inspected separately.

## Findings

- No actionable P0, P1, or P2 issue remains.
- The redundant centered top-bar title is removed while the back action, “最后一步” eyebrow, and “基础设置” page heading retain the approved hierarchy.
- The onboarding avatar is now a true circle. Each fresh setup instance randomly selects one of 14 warm Lucide icons rather than presenting a fixed raster or emoji.
- The icon identifier persists through the existing profile string field without a database migration. Shared avatar rendering keeps the chosen icon coherent in profile, family, and analytics surfaces while preserving legacy emoji profiles.
- Image selection remains available; a selected photo clips to the same circular frame. The existing change-image affordance remains visible.
- The focused comparison intentionally omits the reference-only active keyboard state because the requested title/avatar delta is independent of focus; the page layout and avatar region are otherwise compared in the same locale/theme state.

## Verification

- `flutter analyze`: passed with 0 issues.
- Updated V16 onboarding goldens: passed.
- Targeted onboarding, profile-save, and analytics regression tests: 18 tests passed.
- Full `flutter test`: 3,865 tests passed, 11 pre-existing skipped tests, 0 failures.
- `git diff --check`: passed.

final result: passed

---

# V16 Flutter Onboarding + Initial Security — Design QA (2026-07-26)

## Scope and evidence

- Source visual truth: `docs/mockup/v16/index.html`, welcome 1/2, privacy 2/2, and initial setup + security states.
- Browser-rendered source captures:
  - `/Users/xinz/.codex/visualizations/2026/07/19/019f7881-03db-72f2-a542-5b075d8e3a27/onboarding-micro-botanical-welcome.png`
  - `/Users/xinz/.codex/visualizations/2026/07/19/019f7881-03db-72f2-a542-5b075d8e3a27/onboarding-micro-botanical-privacy.png`
  - `/Users/xinz/.codex/visualizations/2026/07/19/019f7881-03db-72f2-a542-5b075d8e3a27/onboarding-micro-botanical-setup.png`
- iOS simulator implementation captures:
  - `/Users/xinz/.codex/visualizations/2026/07/19/019f7881-03db-72f2-a542-5b075d8e3a27/onboarding-impl-welcome.png`
  - `/Users/xinz/.codex/visualizations/2026/07/19/019f7881-03db-72f2-a542-5b075d8e3a27/onboarding-impl-privacy.png`
  - `/Users/xinz/.codex/visualizations/2026/07/19/019f7881-03db-72f2-a542-5b075d8e3a27/onboarding-impl-setup.png`
- Same-input paired comparison, source left and Flutter right:
  `/Users/xinz/.codex/visualizations/2026/07/19/019f7881-03db-72f2-a542-5b075d8e3a27/onboarding-design-qa-combined.png`.
- Viewport and density: source phone frame 390×844 CSS pixels. Flutter was captured on iPhone 16e at 390×844 logical pixels and 3× density (1170×2532), then normalized to 390px width for the paired comparison. The browser source viewport clipped the lower portion of the phone frame, so the paired comparison uses the common 390×626 visible region; the complete Flutter captures were inspected separately to verify the fixed docks and bottom safe area.
- State: Japanese light theme, welcome page, privacy page, and initial setup with security disabled. Security disclosure, biometric-first selection, PIN setup, PIN-complete state, and persistence were additionally exercised in widget tests.

## Findings

- No actionable P0, P1, or P2 issue remains.
- Layout and spacing: the two intro pages now use the mockup's top-led content rhythm, 172×150 hero slot, 390px phone insets, fixed page-dot/CTA dock, and 16–17px surfaces. The privacy page keeps its entire CTA inside the safe area for Japanese copy.
- Typography and copy: hierarchy, wrapping, and ja/zh/en localization remain coherent. The headless golden renderer lacks production CJK fallbacks, so committed visual baselines use a stable English state while Japanese production captures were used for fidelity review.
- Color and imagery: the warm paper background, leaf green, restrained rose accents, micro-botanical edge motifs, existing satisfaction faces, mockup avatar, and privacy artwork remain aligned with V16. No placeholder or approximate raster asset is present.
- Icons: welcome and privacy heroes retain the existing Flutter source geometry and float/drift animation; setup and security use the shared Material icon family plus the approved warm raster assets.
- Interaction and state: intro is exactly two pages; skip and continue both reach setup. Display language, currency, and voice share one row pattern and persist through existing providers/repositories.
- Security behavior: the master switch owns disclosure. Off shows the quiet later-setup message; on reveals mutually exclusive biometrics first and PIN/app-lock second. PIN setup requires double entry and exposes a completed/change state. Biometrics provisions a fallback PIN before arming the master lock so the existing `AppLockService` invariant cannot strand the user after biometric lockout.
- Accessibility and resilience: primary controls retain semantic button/switch/radio behavior, practical tap targets, localized labels, reduced-motion support, scroll fallback, and tight Stack constraints. The English badge now truncates safely instead of overflowing at 390px.

## Comparison history

1. The previous Flutter flow had three intro pages and a separate lock-entry step, while profile, preferences, and security did not match the approved integrated setup mockup.
2. The first implementation pass consolidated the intro to two pages, rebuilt the selected heroes/background, folded security into setup, and wired the existing persistence and PIN flows.
3. The first multilingual golden pass exposed a 120px English badge overflow; constraining the badge and ellipsizing only the longest locale fixed it without changing the Japanese mockup state.
4. The first Japanese simulator comparison exposed loose Stack constraints that pushed the privacy CTA below the viewport. Tight Stack expansion fixed the dock, and the second paired comparison showed matching content order, scale, spacing, surfaces, icons, and safe-area behavior.

## Verification

- `flutter gen-l10n`: completed for ja/zh/en.
- `flutter analyze`: passed with 0 issues.
- Onboarding widget + V16 golden suite: 33 tests passed.
- Full `flutter test`: 3,864 tests passed, 11 pre-existing skipped tests, 0 failures.
- `git diff --check`: passed.

final result: passed

---

# Flutter App-Wide Numeral Typeface — Design QA (2026-07-25)

## Scope and evidence

- Source visual truth: `/Users/xinz/.codex/visualizations/2026/07/25/019f981f-73e9-7f21-92b6-a4eee9452545/v16-numerals-phone.jpg`.
- Combined visual review board: `/Users/xinz/.codex/visualizations/2026/07/25/019f981f-73e9-7f21-92b6-a4eee9452545/app-wide-numeral-qa.png`.
- Flutter captures on the board: Home, amount entry, numeric keypad, analytics trend, list calendar, and shopping list. Light-theme phone captures use 390px width where the production screen owns the viewport; focused component goldens retain their fixed test dimensions.
- Reviewed numeric content includes currency signs, grouped/decimal amounts, percentages, dates, calendar days, chart axes/endpoints, Joy ratios, shopping quantities, and keypad digits.

## Findings

- No actionable P0, P1, or P2 issue remains.
- Typography: every `AppTextStyles` semantic role and both Material text themes now use the `RobotoMonoNumerals` family with tabular (`tnum`) and slashed-zero (`zero`) features. Unstyled `Text` also inherits the same contract from `AppTheme`.
- Glyph isolation: the bundled font is a 17KB numeric subset rather than the full Roboto Mono face. It contains numeric glyphs and numeric punctuation/symbols but omits alphabetic and CJK glyphs, so Japanese, Chinese, and English prose continue through the platform fallback instead of becoming monospaced.
- Coverage: representative real-font goldens confirm the same numeral shape in Home, accounting, analytics, list/calendar, and shopping surfaces. The numeric keypad and calendar visibly retain the diagonal zero treatment.
- Layout and visual tokens: no palette, spacing, radius, surface, icon, copy, or interaction changed. The reviewed captures showed no clipping or overflow caused by the new glyph widths.
- Test-renderer note: Flutter host goldens do not provide production CJK system fonts, so nonnumeric copy may appear as placeholder boxes or blanks in diagnostic captures. The production family intentionally falls through for those missing glyphs.

## Iteration history

1. The initial implementation scoped Roboto Mono directly to selected Home widgets, leaving other app numbers on the platform font. This was a P1 coverage gap.
2. Moving the full Roboto Mono font to the global theme would also have made Latin prose monospaced. The fix instead introduced a numeric-only subset and routed all semantic/theme text roles through it.
3. Two explicit `IBM Plex Sans` toast overrides and the keypad's isolated font-feature declaration bypassed the shared contract. The overrides were removed and keypad features now use `AppTextStyles.numeralFontFeatures`.
4. Initial non-Home golden runs still rendered Flutter's deterministic placeholder font because the production asset had not been explicitly loaded. A shared golden font loader now makes the visual baselines exercise the real bundled numeral face.
5. The source/implementation review board was inspected after updating only the confirmed numeric diffs; no collateral P0/P1/P2 visual issue remained.

## Verification

- `flutter analyze`: passed with 0 issues.
- App-wide theme and architecture contract tests: passed.
- Representative real-font visual/behavior matrix: 34 tests passed,
  including 30 updated golden baselines.
- Full golden-tagged suite: 214 tests passed.
- Full `flutter test`: 3,856 tests passed, 11 pre-existing skipped tests, 0 failures.

final result: passed

---

# V16 Flutter Home + Numeral Typeface — Design QA (2026-07-25)

## Scope and evidence

- Source visual truth: `/Users/xinz/.codex/visualizations/2026/07/25/019f981f-73e9-7f21-92b6-a4eee9452545/v16-numerals-phone.jpg`.
- Flutter implementation screenshot: `/Users/xinz/Development/home-pocket-app/test/golden/goldens/home_v16_phone_light_ja.png`.
- Normalized source crop: `/Users/xinz/.codex/visualizations/2026/07/25/019f981f-73e9-7f21-92b6-a4eee9452545/v16-home-reference-focus.png`.
- Full-view, same-input comparison (source left, implementation right): `/Users/xinz/.codex/visualizations/2026/07/25/019f981f-73e9-7f21-92b6-a4eee9452545/v16-home-flutter-comparison-final.png`.
- Viewport and density: 390px-wide light-theme phone. The 390×844 source was cropped by 39px at the top to remove source-only system status chrome, producing a 390×600 app-content reference. The Flutter golden is 390×600 at device-pixel ratio 1, so no scale or density conversion was required.
- State: personal ledger, July 2026, `¥186,420` total, `¥53,620` Joy, `¥132,800` daily, `64 / 80` Joy target, `8.2 / 10` satisfaction, `12` small wins, and `¥4,800` monthly favorite.
- Focused-region evidence: the implementation capture intentionally contains only the app-owned header, Hero card, and monthly-favorite section. At 1:1 scale all changed typography, ticket perforations, spacing, and values are readable, so a smaller secondary crop was not needed.

## Findings

- No actionable P0, P1, or P2 issue remains.
- Fonts and typography: all numeral-bearing Home surfaces use the bundled `RobotoMono` family with tabular (`tnum`) and slashed-zero (`zero`) features. The amount, month title, comparison amount, trend, ledger totals, Joy target, satisfaction, count, favorite date/amount, member totals, and recent-transaction amounts share the same face. Non-numeric CJK text in Flutter host goldens uses the test renderer's placeholder glyphs; production CJK continues to fall back to the platform font.
- Spacing and layout rhythm: the Hero and Favorite widths are both 350px inside the 20px phone inset. The Hero remains 22px-rounded with 18px padding, its 20px side notches replace the spending/Joy separator, and the Favorite starts 18px below as a transparent section with a 10px title-to-ticket gap.
- Colors and visual tokens: the warm paper background, primary-tinted Hero surface, rose Joy accents, green daily accents, goal ring, mint favorite ticket, border, and shadow tokens remain aligned with the V16 source.
- Image quality and assets: the screen uses the existing Material/shared icon system; no raster illustration was substituted. The only new asset is the official Roboto Mono variable TTF plus its OFL license.
- Copy and content: `詳しく見る` was added to the Favorite header in Japanese, with Chinese and English parity. The calendar tile now uses the source's uppercase `JUL / 06 / MON` treatment. The satisfaction label remains `至福` rather than the mockup's `大満足` because ADR-015 locks the top-tier product lexicon to `至福`.
- Interaction: the Hero and independent Favorite section each preserve the existing tap-to-analytics behavior; the info affordance still absorbs its tap and opens the explanatory dialog.

## Comparison history

1. Initial Flutter state had the monthly favorite nested inside the main Hero surface, horizontal dividers around the Joy region, no outer side tear notches, and platform-default numeral glyphs. These were P2 structural and typography mismatches.
2. The first implementation pass split the Favorite into its own transparent tappable section, added the 20px page-colored Hero notches with no separator line, switched all Home numeral surfaces to the bundled mono face, added the Favorite detail link, and changed ticket cutouts to the page background.
3. The first 390px comparison exposed two remaining P2 details: the calendar rendered localized `7 / 6` instead of `JUL / 06 / MON`, and the ticket seal was 72px with a 32px face rather than the source's 58px column and 22px icon.
4. The second pass adopted the uppercase zero-padded calendar, 58px seal, 22px satisfaction face, 3px internal gap, and micro tier label. The final paired comparison shows matching major geometry and no remaining P0/P1/P2 difference.

## Verification

- `flutter analyze`: passed with 0 issues.
- Targeted Home widget, screen, typography, localization, interaction, and golden suite: 74 tests passed.
- Golden matrix: V16 390px composition plus solo/family, light/dark, target thresholds, thin-data, and all-neutral states passed.
- `flutter gen-l10n`: completed after ja/zh/en copy parity updates.

final result: passed

---

# V16 Whole-App Numeral Typeface — Design QA (2026-07-25)

## Scope and evidence

- Source visual truth: `/var/folders/qs/d64k8pm541nbr7hjj9scdxj00000gn/T/TemporaryItems/NSIRD_screencaptureui_AwdqCY/截屏2026-07-25 16.14.25.png`.
- Browser-rendered implementation: `/Users/xinz/.codex/visualizations/2026/07/25/019f981f-73e9-7f21-92b6-a4eee9452545/v16-numerals-phone.jpg`.
- Full-view combined comparison: `/Users/xinz/.codex/visualizations/2026/07/25/019f981f-73e9-7f21-92b6-a4eee9452545/v16-numerals-full-comparison.jpg`.
- Focused numeral comparison: `/Users/xinz/.codex/visualizations/2026/07/25/019f981f-73e9-7f21-92b6-a4eee9452545/v16-numerals-focused-comparison.jpg`.
- Browser viewport request: 1400×1050. The in-app browser exposed a 1385×1050 visual viewport and returned a 1385×1039 JPEG; the 386×835 phone crop was normalized back to its measured 390×844 CSS size. Browser `devicePixelRatio` was 2 and visual viewport scale was 1.
- Source pixels: 738×1118. The source is a cropped typography reference rather than the same product screen; the full comparison preserves its aspect ratio at 557×844 beside the normalized 390×844 implementation. The focused comparison normalizes the two amount samples to the same glyph height and is the fidelity evidence for this scoped change.
- State: A1 personal ledger, light theme, July 2026 home. Representative numeral surfaces were also checked on details, analytics, shopping-item form, unified entry, family join, and app-lock screens.

## Findings

- No actionable P0, P1, or P2 issue remains.
- Fonts and typography: all numeric glyphs, currency signs, percentages, decimal/grouping punctuation, dates, counts, PIN digits, keypad digits, and chart labels now resolve through the screenshot-matched monospaced numeral face. Tabular and slashed-zero OpenType features are globally active. The focused comparison confirms the reference's monospaced proportions and diagonal zero treatment on `¥186,420`.
- Spacing and layout rhythm: the numeral substitution does not change the existing V16 component structure. At 375px, 390px, and 430px phone widths, both the phone and app scroller had equal client and scroll widths.
- Colors and visual tokens: no palette, surface, border, shadow, or semantic color changed.
- Image quality and assets: no raster, SVG, icon, or illustration asset changed.
- Copy and content: all app copy and numeric values remain unchanged.
- The numeric face uses a Unicode-limited font alias, so Japanese, Chinese, English prose, and display headings continue to use their existing body or Mincho families rather than becoming monospaced.

## Comparison and verification history

1. Before this pass, the screenshot-matched monospaced/slashed-zero treatment was limited to selected home elements; many other numbers inherited body or display fonts.
2. The implementation added one numeral-only face with regular and bold local fallbacks, placed it before both body and display stacks, and enabled tabular/slashed-zero features at the document level.
3. Browser computed-style checks confirmed the numeral alias and `"tnum", "zero"` features across home amounts, dates, percentages, Joy values, details amounts, analytics axes/totals, shopping quantity, entry amount/keypad, family invite digits, and lock keypad.
4. Catalog navigation through the representative screens remained functional. Browser console: 0 errors, 0 warnings.
5. Scoped `git diff --check`: passed.

final result: passed

---

# V16 Home Favorite Without Outer Card — Design QA (2026-07-25)

## Scope and evidence

- Source visual truth: `/Users/xinz/.codex/visualizations/2026/07/25/019f97e9-f261-7490-b09d-5384602cc7d7/home-tear-notches-no-divider-final.jpg`, plus the user delta to remove only the `今月の最愛` outer background card.
- Browser-rendered implementation: `/Users/xinz/.codex/visualizations/2026/07/25/019f97e9-f261-7490-b09d-5384602cc7d7/home-favorite-no-background-final.png`.
- Full-view same-input comparison: `/Users/xinz/.codex/visualizations/2026/07/25/019f97e9-f261-7490-b09d-5384602cc7d7/home-favorite-no-background-full-comparison-final.jpg`.
- Focused changed-region comparison: `/Users/xinz/.codex/visualizations/2026/07/25/019f97e9-f261-7490-b09d-5384602cc7d7/home-favorite-no-background-comparison-final.jpg`.
- Browser viewport: 1400×1050; phone CSS size and implementation crop: 390×844; source and implementation pixels: 390×844; device pixel ratio: 1; no density normalization required.
- State: A1 personal ledger, light theme, July 2026 home.

## Findings

- No actionable P0, P1, or P2 issue remains.
- The Favorite section now resolves to a transparent background, zero border, zero radius, zero shadow, and zero padding. The title and 350px-wide ticket remain intact.
- Fonts and typography are unchanged; the numeric font treatment, title hierarchy, and ticket copy remain consistent with the approved home design.
- Spacing and layout rhythm remain coherent: the section starts 18px below the Hero card and the title sits 10px above the ticket.
- Existing color tokens remain in use. Only the outer surface treatment was removed; the ticket keeps its mint surface, rose accent, border, and perforation treatment.
- No image assets or icons changed. Copy and ticket contents are unchanged.
- The 375px, 390px, and 430px phone frames have no horizontal overflow; light and dark themes both keep the Favorite wrapper transparent.
- The historic source capture contains a black lower-capture artifact below the changed region, so the readable 390×670 focused comparison is the fidelity source for this localized decision.

## Interaction and comparison history

1. Before, `今月の最愛` used a white rounded outer card around its title and ticket.
2. This pass removes only that outer surface and updates its mockup token from `HomeFavoriteCard` to `HomeFavoriteSection`.
3. Keyboard Enter on the section still opens the Statistics screen; no navigation behavior changed.
4. Post-fix computed-style checks, responsive checks, focused comparison, and console inspection found no remaining blocker. Browser console: 0 errors, 0 warnings.

final result: passed

---

# V16 Home Tear Notches Without Separator — Design QA (2026-07-25)

## Scope and evidence

- Previous approved state: `/Users/xinz/.codex/visualizations/2026/07/25/019f97e9-f261-7490-b09d-5384602cc7d7/home-original-style-tear-final.jpg`.
- User delta: retain the left/right tear notches and remove the horizontal separator between them.
- Browser-rendered implementation: `/Users/xinz/.codex/visualizations/2026/07/25/019f97e9-f261-7490-b09d-5384602cc7d7/home-tear-notches-no-divider-final.jpg`.
- Focused same-input comparison: `/Users/xinz/.codex/visualizations/2026/07/25/019f97e9-f261-7490-b09d-5384602cc7d7/home-no-divider-comparison-final.jpg`.
- Viewport/state: 390×844 phone frame, personal ledger, light theme.

## Findings

- No actionable P0, P1, or P2 issue remains.
- The separator resolves to `border-top: none` and zero height.
- Both 20×20px page-colored tear notches remain visible at the card edges.
- Typography, copy, colors, icons, spacing, card contents, and interactions are unchanged.
- The 375px, 390px, and 430px phone frames have no horizontal overflow.
- Light and dark themes both keep the divider at zero height with no border; the browser console reports no warnings or errors.

## Comparison history

1. The approved home card used tear notches plus a horizontal divider between the spending and Joy sections.
2. This pass removes only that divider; the notches remain as the sole visual separation.
3. The focused browser comparison confirms the requested localized change without collateral layout drift.

final result: passed

---

# Welcome Onboarding Micro Botanical + Flutter Hero Motion — Design QA (2026-07-20)

## Scope and evidence

- Revised visual direction: `/Users/xinz/.codex/generated_images/019f7881-03db-72f2-a542-5b075d8e3a27/exec-0a08cf3c-c69b-4ecf-ac56-67761ada126a.png`.
- Existing Flutter reference: `/var/folders/qs/d64k8pm541nbr7hjj9scdxj00000gn/T/TemporaryItems/NSIRD_screencaptureui_yLeGfS/截屏2026-07-20 19.05.24.png`.
- Flutter implementation inspected: `lib/features/onboarding/presentation/screens/onboarding_intro_screen.dart` and `lib/features/onboarding/presentation/widgets/onboarding_float_decor.dart`.
- Browser-rendered welcome page: `/Users/xinz/.codex/visualizations/2026/07/19/019f7881-03db-72f2-a542-5b075d8e3a27/onboarding-micro-botanical-welcome.png`.
- Browser-rendered privacy page: `/Users/xinz/.codex/visualizations/2026/07/19/019f7881-03db-72f2-a542-5b075d8e3a27/onboarding-micro-botanical-privacy.png`.
- Browser-rendered initial setup: `/Users/xinz/.codex/visualizations/2026/07/19/019f7881-03db-72f2-a542-5b075d8e3a27/onboarding-micro-botanical-setup.png`.
- Viewport/state: 390×844 phone frame in the V16 catalog, light theme, both welcome pages and initial setup.
- Full-view comparison opened the revised visual direction together with all three implementation captures; the focused comparison opened the supplied Flutter reference together with the first welcome-page capture.

## Findings

- No actionable P0, P1, or P2 issue remains.
- Typography and copy remain aligned with the selected V16 design system and were not changed by this pass.
- The first hero preserves the existing Flutter 172×150 cluster, 116px house tile, 52px pink satisfaction face, 42px green satisfaction face, and two-petal composition.
- The second hero keeps the existing shield artwork and applies the same layered visual grammar using the product's lock and smartphone icon vocabulary.
- The selected option-2 background uses only small, low-contrast botanical impressions at the screen edges; no large decorative pattern competes with the content.
- Source-derived light/dark house and shield SVGs, real satisfaction assets, and the established Material icon library preserve icon fidelity across themes.
- Motion matches the existing implementation: 7px main/satellite lift, 5–6.5 second staggered loops, and 9px/15° petal drift. `prefers-reduced-motion` disables decorative movement.

## Comparison history

1. Before, the V16 welcome mockup used raster-only hero tiles, omitted the Flutter implementation's layered satellites and animation, and left the background visually plain.
2. The fix replaced both welcome heroes with layered, source-faithful constructions and applied the selected micro-botanical background direction across welcome and initial setup.
3. Post-fix browser captures, focused comparisons, computed-transform checks, and the interaction pass found no visual or functional blocker.

## Interaction, responsive, and code verification

- `次へ` moves from the first welcome page to the privacy page; `はじめる` reaches initial setup.
- Computed transforms changed after approximately 900ms for the main tile, both satellites, and both petals; animation durations resolve to 6s, 5s, and 6.5s as intended.
- All four source-derived onboarding SVGs and both satisfaction SVG dependencies returned HTTP 200.
- Browser console: 0 errors.
- Scoped `git diff --check`: passed.

final result: passed

---

# Continuous Accounting Hit Target QA — 2026-07-18

- Source visual truth: `/Users/xinz/Downloads/截屏 2026-07-18 15.09.22.png`
- Implementation screenshot: `/Users/xinz/.codex/visualizations/2026/07/18/019f7320-13de-7752-a730-71b36a01a307/continuous-hit-target-manual.png`
- Focused paired comparison: `/Users/xinz/.codex/visualizations/2026/07/18/019f7320-13de-7752-a730-71b36a01a307/comparison-continuous-hit-target.png`
- Viewport/state: source mobile frame normalized against a 390px-wide Flutter widget render; manual keypad idle state with continuous accounting disabled. Voice uses the same centered-target contract in every dock state.

## Findings

No actionable P0, P1, or P2 issue remains.

- Fonts and typography: unchanged; the existing summary/action hierarchy and 6px inline spacing remain.
- Spacing and layout rhythm: the manual visual surface still reaches the screen bottom, while its interactive region is centered at 230×43 and excludes the bottom safe-area buffer. Voice uses a centered 230×27 interactive region.
- Colors and visual tokens: unchanged; the summary stays secondary and the mode action stays primary green.
- Image and icon fidelity: no image or icon changes were required.
- Copy and content: localized continuous/non-continuous wording is unchanged.
- Interaction evidence: manual and voice corner taps outside the centered target are ignored; taps inside the padded target toggle once. Semantics remain button/toggled controls on the constrained target.

## Comparison history

1. Before the change, the manual control's full 390px footer toggled the mode, while voice only made the action text tappable.
2. Both paths now use the same centered 230px-wide target. The surrounding footer, dock corners, and manual bottom buffer are non-interactive.
3. Post-fix widget tests pass for both manual keypad and voice dock; the focused capture confirms there is no unintended visual change.

final result: passed

---

# Initial Setup Security + PIN Completion — Design QA (2026-07-20)

## Scope and evidence

- Selected completion-state visual: `docs/mockup/v16/assets/initial-setup-security-complete-zh.png`
- Implementation: `docs/mockup/v16/index.html`, `初始设置＋安全保护` and `设置应用锁 PIN` states.
- Viewport/state: 1400×1000 browser viewport, 390×844 phone frame, light theme, Japanese app copy, security enabled, app lock selected, PIN configured.
- Browser-rendered implementation: `/Users/xinz/.codex/visualizations/2026/07/19/019f7881-03db-72f2-a542-5b075d8e3a27/initial-setup-security-pin-complete-final-phone.png`
- Full-view same-input comparison: `/Users/xinz/.codex/visualizations/2026/07/19/019f7881-03db-72f2-a542-5b075d8e3a27/initial-setup-security-complete-comparison.png`
- Focused security-section comparison: `/Users/xinz/.codex/visualizations/2026/07/19/019f7881-03db-72f2-a542-5b075d8e3a27/initial-setup-security-complete-focus-comparison.png`

## Findings

- No actionable P0, P1, or P2 difference remains against the confirmed combined direction.
- The master switch owns disclosure: when disabled, the unlock-method rows are absent and the quiet later-setup hint is visible; when enabled, the hint disappears and the two mutually exclusive choices are revealed.
- Biometric authentication appears first and carries the restrained recommendation badge. App lock appears second and does not imply completion until a PIN exists.
- The app-lock pending state keeps the user in context with `PINがまだ設定されていません`, explains the two-entry requirement, and disables the final setup action.
- The dedicated PIN step uses a focused four-digit keypad, automatic transition to confirmation, mismatch feedback, and retry without losing the chosen unlock method.
- The completion state adds a clear success mark, `PINを設定しました`, the protection summary, and `PINを変更`; only then is the final action enabled.
- The selected reference is Chinese while the V16 app frame intentionally stays Japanese. Hierarchy, state disclosure, method order, completion affordance, warm paper palette, forest-green structure, and soft mint surfaces are preserved rather than copying localized strings.
- The implementation is denser than the concept because it remains inside the existing scrollable V16 initial-setup form. The focused comparison confirms that the security card, radio hierarchy, completion block, and CTA remain legible and visually integrated.

## Comparison history

1. The completion reference was added after the flow direction was confirmed so the app-lock choice no longer ends in an ambiguous pending state.
2. The browser pass verified all four inspector states and the complete create/confirm/return path. No visual blocker was found in the combined or focused comparison.

## Interaction, responsive, and code verification

- Security off: unlock choices hidden, later-setup hint visible, and setup can complete once the name is present.
- Biometric: biometric selected, app lock unselected, no PIN detail shown, and final action enabled.
- App lock pending: PIN prompt visible and final action disabled.
- PIN success: matching `1234` entries return to setup with the success block and enabled final action.
- PIN mismatch: `1234` then `1235` shows `PINが一致しません` and remains on the confirmation step for retry.
- Final setup action reaches the home state and shows `初期設定が完了しました`.
- At 375, 390, and 430 phone widths, the phone and setup scroller `clientWidth` equal `scrollWidth`; the final action stays inside the phone frame.
- Browser console: 0 errors, 0 warnings.
- Inline JavaScript syntax and scoped `git diff --check`: passed.

final result: passed

---

# Initial Setup Foundation Layout Correction — Design QA (2026-07-20)

## Scope and evidence

- Source visual truth: `docs/mockup/v16/assets/initial-setup-security-complete-zh.png`.
- Reported pre-fix implementation: `/var/folders/qs/d64k8pm541nbr7hjj9scdxj00000gn/T/TemporaryItems/NSIRD_screencaptureui_9OFhfr/截屏2026-07-20 16.20.09.png`.
- Post-fix implementation: `/Users/xinz/.codex/visualizations/2026/07/19/019f7881-03db-72f2-a542-5b075d8e3a27/initial-setup-foundation-pin-complete-updated-phone.png`.
- Viewport/state: 390×844 phone frame, light theme, Japanese app copy, security enabled, app lock selected, PIN configured.
- Full-view same-input comparison: `/Users/xinz/.codex/visualizations/2026/07/19/019f7881-03db-72f2-a542-5b075d8e3a27/initial-setup-foundation-full-comparison.png`.
- Focused source / pre-fix / post-fix comparison: `/Users/xinz/.codex/visualizations/2026/07/19/019f7881-03db-72f2-a542-5b075d8e3a27/initial-setup-foundation-before-after-comparison.png`.

## Findings and comparison history

1. **Resolved P1 — the initial-setup foundation area still used the previous design.** The pre-fix page retained the long introductory headline, separate profile explanation, four-part language segmented control, and individually styled currency and voice pickers. This materially diverged from the confirmed full-page reference and made language inconsistent with currency and voice.
2. The page now uses the compact `基本設定` hierarchy, places avatar and required name input in one row, and groups display language, currency, and voice language into a single three-row selection card with matching icons, values, chevrons, borders, radii, and interaction affordances.
3. Display language now opens the same bottom-sheet selection pattern as currency and voice. Selecting a non-system language continues to update the default voice language until the user explicitly chooses a different voice language.
4. The post-fix full and focused comparisons show no remaining actionable P0, P1, or P2 issue in the corrected region. The persistent V16 status/header chrome and Japanese localization are intentional product-shell adaptations.

## Required fidelity surfaces

- Fonts and typography: the long two-line heading was replaced with the reference's short display heading; label/value weights and line heights now match the compact list hierarchy.
- Spacing and layout rhythm: avatar/name alignment and the single grouped preference card reproduce the reference's major proportions while retaining the 390×844 V16 shell.
- Colors and tokens: warm paper, forest green, mint icon treatment, hairline borders, and restrained radii remain mapped to existing semantic tokens.
- Image quality and assets: the existing generated warm avatar asset is reused at native quality; preference icons come from the existing Material Symbols family.
- Copy and content: Japanese labels preserve the selected Chinese reference's information architecture without leaking design-instruction text into the app UI.

## Interaction and responsive verification

- Display language, currency, and voice language each open and close a working selector; selections are reflected in the grouped rows.
- Language selection was exercised with `中文`, currency with `USD`, and voice with `日本語`; the modal closes after each selection.
- Security-off and PIN-complete states still render after the foundation-layout replacement; the completed PIN state keeps the final action enabled.
- At 375, 390, and 430 widths, the phone and setup scroller `clientWidth` equal `scrollWidth`; the profile editor and grouped preference card stay inside the phone frame.
- Browser console: 0 errors, 0 warnings.
- Inline JavaScript syntax and scoped `git diff --check`: passed.

final result: passed

---

# Initial Setup Avatar Change Hint — Design QA (2026-07-20)

## Scope and evidence

- Source region and requested change: `/var/folders/qs/d64k8pm541nbr7hjj9scdxj00000gn/T/TemporaryItems/NSIRD_screencaptureui_ChrQ4h/截屏2026-07-20 17.37.50.png`, with an explicit affordance that the avatar can be replaced.
- Implementation screenshot: `/Users/xinz/.codex/visualizations/2026/07/19/019f7881-03db-72f2-a542-5b075d8e3a27/initial-setup-avatar-change-hint-final-phone.png`.
- Viewport/state: 390×844 phone frame, light theme, Japanese app copy, security disabled, empty required name.
- Full-view same-input comparison: `/Users/xinz/.codex/visualizations/2026/07/19/019f7881-03db-72f2-a542-5b075d8e3a27/initial-setup-avatar-hint-full-comparison.png`.
- Focused region same-input comparison: `/Users/xinz/.codex/visualizations/2026/07/19/019f7881-03db-72f2-a542-5b075d8e3a27/initial-setup-avatar-hint-focused-comparison.png`.

## Findings

- No actionable P0, P1, or P2 issue remains in the avatar/name region.
- A compact Material Symbols camera mark and `画像を変更` label now sit directly below the avatar tile. The hint avoids the illustration's lower-right heart detail and keeps the required-name label and input aligned.
- The tile and hint form one semantic button rather than two competing controls. Its accessible name is `画像を変更`, and keyboard focus is drawn around the avatar tile using existing primary and focus tokens.
- Fonts and typography: the 10px/16px hint is intentionally subordinate to the name label and input while remaining legible at mobile density.
- Spacing and layout rhythm: the hint adds 21px to the avatar column without changing the 76px tile, 15px column gap, or input dimensions.
- Colors and tokens: the hint reuses `--hp-primary-text`; no new palette or shadow is introduced.
- Image quality and assets: the existing warm avatar raster remains unchanged and unobscured; the camera uses the project's Material Symbols icon family.
- Copy and content: the Japanese label communicates replacement directly without restoring the removed profile-description block.

## Interaction and responsive verification

- Clicking either the avatar image or visible hint opens the existing avatar selector with current-icon and device-photo choices; cancel closes the sheet.
- At 375, 390, and 430 widths, the avatar column and name field remain inside the phone frame, and both phone and setup scroller have equal `clientWidth` and `scrollWidth`.
- Browser console: 0 errors, 0 warnings.
- Inline JavaScript syntax and scoped `git diff --check`: passed.

final result: passed

---

# Welcome Onboarding & Initial Setup — V16 Design QA (2026-07-19)

## Scope and evidence

- Flutter source reviewed:
  - `lib/features/onboarding/presentation/screens/onboarding_intro_screen.dart`
  - `lib/features/onboarding/presentation/screens/onboarding_settings_screen.dart`
  - `lib/features/onboarding/presentation/screens/onboarding_flow_screen.dart`
  - `lib/features/onboarding/presentation/screens/onboarding_lock_entry_screen.dart`
- Mockup implementation: `docs/mockup/v16/index.html`.
- Source context: the previous V16 welcome and setup captures plus the selected warm family-entry icon language.
- Viewport/state: 390×844 phone frame, Japanese app copy, light and dark themes.
- Same-input full-view comparison: `/Users/xinz/.codex/visualizations/2026/07/19/019f7881-03db-72f2-a542-5b075d8e3a27/onboarding-redesign-comparison.png`.
- Focused icon-language comparison: `/Users/xinz/.codex/visualizations/2026/07/19/019f7881-03db-72f2-a542-5b075d8e3a27/onboarding-redesign-icon-style-comparison.png`.
- Final browser captures:
  - `/Users/xinz/.codex/visualizations/2026/07/19/019f7881-03db-72f2-a542-5b075d8e3a27/onboarding-redesign-01-welcome-final.png`
  - `/Users/xinz/.codex/visualizations/2026/07/19/019f7881-03db-72f2-a542-5b075d8e3a27/onboarding-redesign-02-privacy-final.png`
  - `/Users/xinz/.codex/visualizations/2026/07/19/019f7881-03db-72f2-a542-5b075d8e3a27/onboarding-redesign-03-setup-empty-final.png`
  - `/Users/xinz/.codex/visualizations/2026/07/19/019f7881-03db-72f2-a542-5b075d8e3a27/onboarding-redesign-04-lock-final.png`
  - `/Users/xinz/.codex/visualizations/2026/07/19/019f7881-03db-72f2-a542-5b075d8e3a27/onboarding-redesign-dark-final.png`

## Review findings and redesign decisions

- The current Flutter intro is a three-page `PageView` (`Welcome`, `Privacy`, `Joy`), while the requested product target is two welcome pages. V16 now expresses that target as brand/value on page 1 and privacy/local-first trust on page 2 without losing the third page's essential value message.
- The previous V16 mockup had only one welcome page, so it could not demonstrate the intended paging, skip, back, or start behavior. It now has two page indicators and working navigation across both pages.
- The Flutter settings implementation is otherwise complete: name is required, avatar is selectable, display language writes through immediately, currency updates the book, voice language always resolves to a concrete locale, and onboarding completes only after the lock decision.
- The previous V16 setup screen was misleading because it was prefilled and always startable, omitted the real four-option display-language control, and simplified currency/voice behavior. The new setup starts with an empty required name and disabled CTA, then preserves name and selections while language, currency, and voice are changed.
- The post-setup screen now mirrors `OnboardingLockEntryScreen`: it asks whether to enter security settings or skip. It no longer substitutes the unrelated PIN-unlock screen.
- All content-specific onboarding imagery follows the selected option-3 icon language: rounded pine-green monoline, pale leaf green, and a single sakura-pink heart. Dedicated dark-theme assets preserve contrast.

## Comparison history

1. The initial V16 comparison exposed a one-page welcome flow and an implementation-inaccurate setup state. Both were replaced with a two-page welcome path and a faithful setup form.
2. The first end-to-end setup exercise exposed the outer phone preview retaining a programmatic scroll offset after an input-focused setup screen. `render()` and screen navigation now reset the phone container, so the lock-decision hero and actions remain fully visible.
3. The dark-theme pass confirmed that CSS swaps to the dedicated 256×256 dark PNG assets; no forest-green-on-dark contrast regression remains.

## Responsive and interaction verification

- 375, 390, and 430 widths: the phone and app screen report equal `clientWidth` and `scrollWidth`; no horizontal overflow.
- The primary action remains inside the phone bounds on both welcome pages and setup at all three tested widths.
- Empty name keeps the setup CTA disabled; entering `あおい` enables it.
- Display language `中文` updates the still-unconfirmed voice language to `中文`; an explicit voice selection of `English` then remains independent.
- Currency changed from `JPY` to `USD`, with the name, display language, and voice language preserved.
- Setup continues to the lock decision. `スキップ` reaches home, while `今すぐ設定` reaches settings.
- Browser console: 0 errors, 0 warnings.
- Flutter onboarding widget tests: 16 passed.
- Inline JavaScript syntax and scoped `git diff --check`: passed.

final result: passed

---

# Manual Entry UI Design QA

- Source visual truth:
  - `/Users/xinz/Downloads/截屏 2026-07-18 13.55.24.png`
  - `/Users/xinz/Downloads/截屏 2026-07-18 13.56.53.png`
- Implementation captures:
  - `/Users/xinz/.codex/visualizations/2026/07/18/019f7320-13de-7752-a730-71b36a01a307/amount-clear-after-digits.png`
  - `/Users/xinz/.codex/visualizations/2026/07/18/019f7320-13de-7752-a730-71b36a01a307/voice-review-record-action.png`
  - `/Users/xinz/.codex/visualizations/2026/07/18/019f7320-13de-7752-a730-71b36a01a307/note-keyboard-toolbar.png`
- Viewport: 390 × 844 for the form captures; the voice dock is rendered at its exact 390 × 336 component contract inside the Flutter test surface.
- States: non-empty JPY amount; voice review ready to record; note field focused with keyboard accessory toolbar.

## Full-view comparison evidence

The note-focus capture shows the full 390 × 844 entry form. Voice provenance badges and the confidence marker above the purpose card are absent, while the keyboard toolbar remains aligned to the bottom edge. The voice-review capture shows the complete dock and its inset primary action.

## Focused comparison evidence

- Amount: `/Users/xinz/.codex/visualizations/2026/07/18/019f7320-13de-7752-a730-71b36a01a307/comparison-amount.png`
- Voice review action: `/Users/xinz/.codex/visualizations/2026/07/18/019f7320-13de-7752-a730-71b36a01a307/comparison-voice-action.png`
- Note keyboard toolbar: `/Users/xinz/.codex/visualizations/2026/07/18/019f7320-13de-7752-a730-71b36a01a307/comparison-note-toolbar.png`

## Findings

No actionable P0, P1, or P2 differences remain for the requested changes.

- Fonts and typography: existing `AppTextStyles` and the current amount size are preserved. Flutter widget captures use the deterministic test font, so production glyph shapes are verified by widget/icon identifiers rather than judged from the capture raster.
- Spacing and layout rhythm: the clear action follows the amount; the voice record action has 16 px horizontal insets; both keyboard-toolbar actions keep balanced padding.
- Colors and visual tokens: Record uses `accentPrimary`; Done retains the card/outline treatment; existing background and border tokens are unchanged.
- Image and icon fidelity: no new raster assets are needed. The voice and keyboard actions use Material receipt/keyboard icons; the submitting state no longer substitutes the loop icon in the Record action.
- Copy and content: all `Voice filled` provenance badges and the decorative confidence marker are absent. Existing localized Record and Done labels remain.

## Comparison history

1. Source screenshots showed the amount clear action before the amount, a full-width voice Record button with a loop icon, a pink text-only keyboard Record action, and visible voice-source/confidence decorations.
2. Implementation moved the clear action after the amount, inset the voice action, fixed its icon, made the keyboard Record action green, added icons to Record and Done, and hid the two decoration types.
3. Post-fix focused captures confirm the new geometry and visual tokens. Widget tests additionally assert exact icon data, color, width, ordering, and absence of the removed markers.

## Follow-up polish

- P3: a real-device screenshot can be used later for production-font raster comparison; no layout or behavior change depends on it.

final result: passed

---

# Happy Pocket Design QA

## 2026-07-16 — 编辑交易与统一记账视觉收敛

**Comparison target**

- Source visual truth: the shared Flutter form implemented by `TransactionDetailsForm.edit`, `AmountDisplay`, `DetailInfoCard`, `LedgerTypeSelector`, `SatisfactionEmojiPicker`, and the fixed save area in `lib/features/accounting/presentation/screens/transaction_edit_screen.dart`; the V16 unified-entry component language in `docs/mockup/v16/index.html` is the visual sibling to match.
- Implementation: `docs/mockup/v16/index.html`, route `edit`, light theme, Chinese locale.
- Intended viewport: 390×844 CSS px. Required states: JPY daily, JPY Joy, USD foreign-currency linkage, submitting, amount sheet, and delete confirmation.
- Implementation screenshot path: unavailable. The in-app browser local `file://` page cannot be captured through the available browser automation because its URL safety policy rejects the local target.
- Full-view comparison evidence: unavailable for the same blocker; no visual pass is inferred from source inspection or DOM tests.
- Focused-region comparison evidence: unavailable. Header, amount, purpose, satisfaction, note, foreign linkage, save dock, amount sheet, and delete confirmation still require rendered crops.

**Code-grounded findings and fixes**

- [P1] The prior edit route used a separate 9/11px legacy form language (`amount-display`, `flat-card`, and `form-row`) while unified entry used semantic typography and `entry-*` components. The route now uses `accounting-screen`, the same 52px centered `entry-header`, 44px horizontal `entry-amount`, `entry-form`, `entry-purpose-card`, conditional satisfaction, and `entry-note-card`.
- [P1] The previous screen showed two destructive actions: a header icon and a page-bottom delete button. The bottom duplicate is removed; the only delete control is the error-colored header icon, and its dedicated confirmation sheet must complete before navigation.
- [P1] Merchant, purpose, and note were presented as static rows, and Joy satisfaction was absent. Merchant and note are now real editable fields, daily / Joy are accessible pressed-state controls, and Joy alone reveals five values mapped to 2 / 4 / 6 / 8 / 10.
- [P2] The previous edit layout did not represent foreign transactions or the existing amount-sheet behavior. The inspector now exposes a USD state whose headline remains in original currency and whose separate linkage card contains editable rate, read-only derived JPY, and rate date. Tapping the headline opens a bottom keypad while keeping currency immutable.
- [P2] Save previously scrolled with content and used the old page composition. It now sits in a fixed surface dock with the standard primary green, disables during submission, rejects duplicate saves, and returns to the actual home/list origin. Edit intentionally contains no voice entry, persistent keypad, or continuous-accounting control.

**Static and interaction verification**

- TDD contract first failed on the legacy `edit()` structure, then passed after the shared component rebuild: `flutter test test/architecture/main_surface_typography_contract_test.dart` — 5/5 passed.
- Inline JavaScript compiles. `/private/tmp/v16_edit_contract_test.cjs` passes shared structure, independent edit draft, merchant/note editing, daily/Joy switching, satisfaction, foreign linkage, amount confirmation, save double-submit protection, delete confirmation, and source-aware return.
- Existing `/private/tmp/v16_voice_contract_test.cjs` and `/private/tmp/v16_shopping_voice_contract_test.cjs` continue to pass; all 60 rendered `data-action` values have handlers.
- A rendered 390×844 comparison is still required before this section can pass visual QA. The required next pass must capture all four inspector states plus the amount and deletion sheets, check typography, spacing/rhythm, colors/tokens, icon fidelity, and app-specific copy, then fix any visible P0/P1/P2 mismatch.

final result: blocked

---

## 2026-07-16 — V16 统一记账、账目编辑与新增购物项实现验收

本节记录三张生产 Flutter 页面完成后的最终验收，并覆盖本文中同日关于本地页面
无法渲染、因而标记为 blocked 的历史结论。

**Comparison target**

- Source visual truth: `docs/mockup/v16/index.html`.
- Implementation: `ManualOneStepScreen`, `TransactionEditScreen`, and
  `ShoppingItemFormScreen`, together with their shared V16 amount, form,
  keyboard, selector, and voice-draft widgets.
- Viewport/state: 390×844 logical pixels, light theme; Chinese for unified
  entry/edit and Japanese for shopping create. Each final comparison places the
  source reference on the left and the rendered production Flutter widgets on
  the right in the same image.
- Unified entry reference / implementation / comparison:
  - `/Users/xinz/.codex/visualizations/2026/07/16/019f6a6c-74de-7a63-a8bd-fa4d698b4b07/v16-entry-reference.png`
  - `/Users/xinz/.codex/visualizations/2026/07/16/019f6a6c-74de-7a63-a8bd-fa4d698b4b07/v16-entry-implementation.png`
  - `/Users/xinz/.codex/visualizations/2026/07/16/019f6a6c-74de-7a63-a8bd-fa4d698b4b07/v16-entry-comparison-final.png`
- Transaction edit reference / implementation / comparison:
  - `/Users/xinz/.codex/visualizations/2026/07/16/019f6a6c-74de-7a63-a8bd-fa4d698b4b07/v16-transaction-edit-reference.png`
  - `/Users/xinz/.codex/visualizations/2026/07/16/019f6a6c-74de-7a63-a8bd-fa4d698b4b07/v16-transaction-edit-implementation.png`
  - `/Users/xinz/.codex/visualizations/2026/07/16/019f6a6c-74de-7a63-a8bd-fa4d698b4b07/v16-transaction-edit-comparison-final.png`
- Shopping create reference / implementation / comparison:
  - `/Users/xinz/.codex/visualizations/2026/07/16/019f6a6c-74de-7a63-a8bd-fa4d698b4b07/v16-shopping-form-reference.png`
  - `/Users/xinz/.codex/visualizations/2026/07/16/019f6a6c-74de-7a63-a8bd-fa4d698b4b07/v16-shopping-form-implementation.png`
  - `/Users/xinz/.codex/visualizations/2026/07/16/019f6a6c-74de-7a63-a8bd-fa4d698b4b07/v16-shopping-form-comparison-final.png`

**Visible findings and fixes**

- Unified entry now matches the V16 amount hierarchy, compact information
  cards, purpose and satisfaction controls, neutral voice launch, 48dp keypad,
  primary record action, history action, and inline continuous-accounting row.
- Transaction edit reuses the same amount and form language, keeps amount
  editing explicit, presents a single destructive header action, and anchors
  the checked save action above the system bottom inset.
- Shopping create follows the source field order and card rhythm, with the
  compact quantity stepper, shopping-only purpose/privacy selectors, category,
  reference price, memo, right-side save action, and a single in-page voice
  draft surface.
- The first paired pass exposed amount-symbol/currency-chip scale, continuous
  control composition, edit affordances, and shopping card-spacing differences.
  Those were corrected before the final three paired captures above.
- No actionable P0/P1/P2 visual mismatch remains. P3 accepted: the HTML source
  includes a decorative phone frame, browser status bar, and home indicator,
  while the Flutter harness renders the production content with real top/bottom
  safe-area reservations. Native glyph antialiasing also differs slightly from
  the browser capture.

**Interaction and resilience checks**

- Unified voice entry covers idle, listening, processing, review, and
  unavailable states. Save stays disabled during recognition, parsing, and
  re-record cancellation; delayed partial results cannot overwrite a newer
  final result; weak/below-floor categories clear the default and require an
  explicit choice; voice-filled fields expose localized provenance markers.
- Snapshot restore keeps JPY and foreign-currency booked/original units
  consistent, and continuous mode resets atomically for the next entry.
- Shopping voice input recognizes Japanese, Chinese, and English name,
  quantity, purpose, category, and JPY price phrasing without inferring
  privacy. Unsupported foreign prices are ignored safely, re-record and
  keyboard transitions invalidate stale callbacks, and no voice path auto-saves.

**Verification**

- Final 390×844 production-widget render: 3/3 passed and all three paired
  comparisons inspected together.
- Focused V16 accounting/shopping regression set: 108/108 passed.
- ARB parity, hardcoded-CJK scan, and V16 typography/mockup contracts: 8/8
  passed.
- Full `flutter test`: 3,835 passed, 11 skipped.
- `flutter analyze`: 0 issues.
- `flutter gen-l10n` completed; final `git diff --check` passed.
- Existing non-blocking tooling warning: `sqlcipher_flutter_libs` does not yet
  advertise future Flutter Swift Package Manager support.

final result: passed

---

## 2026-07-16 — 购物项表单同步与语音草稿提案

**代码审查结论**

- 当前 Flutter 新增 / 编辑共用 `ShoppingItemFormScreen`，真实顺序是名称、数量、用途（日常 / 悦己）、类型（公开 / 私有）、分类、参考价格和备注；新增默认数量 1、日常、公开，保存位于 AppBar 右侧。
- 公开项目进入同步变更链，私有项目只在本机保存；类型创建后不可更改。购物 Tab 的 FAB 和空态入口目前都以 `public` 打开新增表单，不继承筛选值。
- 原 V16 购物表单静态预填“オリーブオイル”，只展示数量、分类、列表和备注，并把家庭模式错误映射为共享 / 个人，遗漏用途、参考价格、数值步进器、编辑锁定和真实保存校验。
- 现有代码仍有后续实现债务，本次只审查未改动 App：编辑时清空参考价格会被更新用例解释为“不修改”；分类没有清除入口；名称的 200 字数据库上限没有前端校验；现有 36px 保存与 38px 步进按钮小于推荐触控目标。

**Mockup 调整**

- `shopping-form` 已改为当前 App 的七字段结构，新增态为空名称、数量 1、日常、公开；数量使用不低于 1 的 44px 步进器，分类展示完整路径，参考价格直接输入，备注使用多行字段。
- 保存移到右上角并使用普通主绿色；名称为空时留在当前页显示错误，聆听 / 解析和提交期间不可重复保存。公开 / 私有始终独立于家庭模式，新建可切换，编辑禁用。
- “保存后不可更改”已收进公开 / 私有的类型控制区，并直接位于两个选项下方；它不再作为数量、用途和类型三行之后的整卡提示，因此数量与用途明确保持可编辑。新增态使用中性提示，编辑态才使用红色锁定提示。
- Inspector 增加手动、聆听、识别回填、编辑态和麦克风不可用五个入口；长按购物项的编辑动作也进入同一编辑表单。

**语音可行性与边界**

- 结论：可添加。可以复用 `SpeechRecognitionService`、`StartSpeechRecognitionUseCase`、语音语言 / 权限 / 设备端优先设置和 3 秒静音自动结束能力。
- 不可直接复用交易的 `ParseVoiceInputUseCase`、`VoiceParseResult` 或 `VoicePttSessionMixin`；它们绑定金额、商家、交易日期与 `TransactionDetailsFormState`，没有商品名称、数量或参考价格语义。
- Mockup 采用同页草稿：名称下方的中性语音卡片是唯一入口，约 3 秒停顿自动解析，中央按钮可提前结束；解析后直接回填表单，中央麦克风复用为重新录音，右上保存仍是唯一持久化动作，没有取消、独立确认或新路由。
- MVP 一次只处理一个商品。示例“牛乳を2本、日常、参考価格500円”填入名称、数量、用途、分类建议和参考价格；未口述备注保持原值，公开 / 私有始终保持录音前值，不由识别结果推断。
- 录音或解析中切回键盘会恢复快照；回填后切回键盘会保留结果；离页、重录和取消中的旧回调由会话序号拒绝。隐私文案改为“端末内認識を優先”，准确反映当前可配置云端降级。

**静态与交互验证**

- TDD 合同先以缺少 `data-shopping-input="name"` 失败，再完成实现；`flutter test test/architecture/main_surface_typography_contract_test.dart`：4/4 通过。
- 当前 App 的购物表单、新增用例和更新用例定向测试：34/34 通过；`flutter analyze test/architecture/main_surface_typography_contract_test.dart`：0 issues。
- `/private/tmp/v16_shopping_voice_contract_test.cjs` 通过：覆盖七字段默认值与 DOM 顺序、3 秒自动端点、手动停止、同页回填、公开 / 私有保持、未口述字段保持、键盘恢复 / 保留、旧回调失效、重录快照、名称校验、数量下限、提交态和编辑锁定。
- 既有 `/private/tmp/v16_voice_contract_test.cjs` 继续通过；内联 JavaScript 可编译，53 个渲染动作均有处理分支，范围内 `git diff --check` 通过。
- 浏览器自动化仍被本地 `file://` URL 安全策略阻止，因此本节没有新的 390×844 完整截图，不能标记视觉 QA 已通过。

**下一次视觉核验**

- 在 390×844 下刷新购物项目页，分别截取手动、聆听、解析、识别回填、编辑和权限不可用状态。
- 重点检查右上保存、名称与单一语音入口、44px 步进器、两组段控件、语音状态行、长文本换行、表单滚动和浅 / 深色对比度；修正所有 P0 / P1 / P2 后再将本节改为 passed。

final result: blocked

---

## 2026-07-15 — V16 整 App Mockup 同步与收口

**结果**

- 当前唯一整 App 交互基准已迁移到 `docs/mockup/v16/index.html`；`.planning/sketches` 中的 004/005/006 重复稿已由 V16 取代。
- 四个主页面统一到当前 `MainSurfaceHeader`：顶部 11px、左右 20px、46px 标题栏、20/28/700 标题、13px 正文间距、40px 操作区与 24px 图标。购物页补齐右侧设置入口。
- 购物筛选恢复带边框卡片、私有与类目二级筛选；家庭态显示“全部 / 个人”，并保留账簿筛选。类目使用购物专用 L1 多选底部面板，支持清空、取消和应用。
- 当前 mockup 清理只移除 `.planning/sketches` 中竞争性的整 App 重复稿；规划输入 001–003、quick 记录、设计审核、已归档里程碑证据，以及仍被 quick 计划直接引用的 V15 源文件继续保留，避免破坏历史引用。

**浏览器验收**

- 375 / 390 / 430 三档工具宽度均按真实像素生效且主屏横向溢出为 0；修正了 V15 中“430 按钮实际仍收缩到 390”的画布轨道问题。
- 主页、明细、统计、购物四页实测标题栏均为 46px、标题 20/28/700、正文间距 13px；主页/明细/统计各有两个 40×40 操作，购物有一个设置操作，全部图标为 24px。
- 购物设置入口可进入设置页并返回购物页；私有筛选得到“味噌 / コーヒー豆”，再叠加食费类目后仅剩“味噌”，继续切换悦己账簿会显示过滤空态。
- 家庭预设会把账簿、私有与类目恢复初始值；切换“全部 / 个人”范围也会执行同一重置。个人深色与家庭浅色均无横向溢出。
- 类目底部面板完整贴合手机画布底部，操作栏未溢出；浏览器控制台 0 error / warning，内联 JavaScript 语法检查通过。

**自动化验证**

- `flutter test test/architecture/main_surface_typography_contract_test.dart`：3/3 通过，覆盖 Flutter 字体契约、V16 字体令牌以及共享标题栏/购物筛选标记。
- `flutter analyze`：0 issues。
- 范围内 `git diff --check`：通过。

final result: passed

---

## 2026-07-16 — 统一记账方案 1「单页连续输入」

**Comparison target**

- Implementation: `docs/mockup/v16/index.html`, the single unified-entry page across idle, listening, processing, recognized-result, and unavailable states.
- Intended viewport: 390×844 CSS px, light theme, Chinese locale, listening → automatic processing → recognized result → optional continuous idle.
- Earlier references:
  - listening: `/var/folders/qs/d64k8pm541nbr7hjj9scdxj00000gn/T/TemporaryItems/NSIRD_screencaptureui_Tm5WgM/截屏2026-07-16 13.20.36.png`
  - parsed result: `/var/folders/qs/d64k8pm541nbr7hjj9scdxj00000gn/T/TemporaryItems/NSIRD_screencaptureui_fhqPuc/截屏2026-07-16 13.20.45.png`
- Latest user-supplied revision evidence:
  - listening with redundant cancel action: `/var/folders/qs/d64k8pm541nbr7hjj9scdxj00000gn/T/TemporaryItems/NSIRD_screencaptureui_pXZwLD/截屏2026-07-16 14.54.58.png`
  - result with overlapping copy and duplicate rerecord action: `/var/folders/qs/d64k8pm541nbr7hjj9scdxj00000gn/T/TemporaryItems/NSIRD_screencaptureui_QLjlcl/截屏2026-07-16 14.55.56.png`
  - over-accented manual voice launch: `/var/folders/qs/d64k8pm541nbr7hjj9scdxj00000gn/T/TemporaryItems/NSIRD_screencaptureui_ezFcuC/截屏2026-07-16 15.18.39.png`
  - over-accented keyboard switch: `/var/folders/qs/d64k8pm541nbr7hjj9scdxj00000gn/T/TemporaryItems/NSIRD_screencaptureui_lcBZoQ/截屏2026-07-16 15.18.53.png`
  - over-accented record and continuous actions: `/var/folders/qs/d64k8pm541nbr7hjj9scdxj00000gn/T/TemporaryItems/NSIRD_screencaptureui_UjwKrW/截屏2026-07-16 15.18.59.png`
- Approved interaction direction: one page, automatic endpointing with optional immediate stop, a keyboard shortcut fixed at the top-right in every state, one central microphone control, one final record action, and continuous-accounting state inherited throughout the voice flow.
- Cropped implementation evidence is available through the latest user captures, but no screenshot exists after the current palette correction and no complete 390×844 frame is available because the in-app browser refuses automated access to the local `file://` page under its URL safety policy.

**Latest findings and fixes**

- [P1] Result copy overlaps the top status
  - Evidence: the latest result capture places “用语音填写账目” directly over “已填入账目”.
  - Fix applied: the redundant visible title is now screen-reader-only; the empty result-chip row was removed; the dock is fixed at 336px; and the privacy note, centered status, and keyboard action now use a three-column grid instead of overlapping absolute positions.
- [P1] Rerecord appears twice
  - Evidence: the latest result capture shows a central microphone and a separate bottom “重新录音” button for the same action.
  - Fix applied: the central microphone is the sole `entry-voice-rerecord` control. The result action slot contains only one full-width “记录” button, which confirms and saves in one step.
- [P2] Listening cancel action dominates the bottom of the dock
  - Evidence: the latest listening capture gives “取消本次语音” the largest visible footprint despite automatic endpointing and the persistent keyboard escape.
  - Fix applied: no cancel button is rendered in listening or processing. Users can wait for the 3-second endpoint, tap the central stop control to finish immediately, or switch to keyboard from the fixed top-right action.
- [P2] Joy color was applied to ordinary navigation and completion controls
  - Evidence: the three 15:18 captures show the manual voice launch, keyboard switch, final record action, and continuous-accounting link all competing in the same Joy pink as active voice feedback.
  - Impact: Joy reads as a ledger/voice-state accent instead of a focused state signal, while ordinary navigation and save controls drift away from the rest of the app.
  - Fix applied: Joy remains only on status dots, waveform, and the central listening/idle/review control. The manual voice launch is now a neutral surface/border/text card with only its icon using existing primary-soft/primary tokens; the keyboard switch uses neutral surface/border/muted-text; record returns to the standard `--hp-primary` action; and the voice-source marker plus continuous accounting use the ordinary primary family. No token or hex value was added.
- [P1] Continuous accounting was absent from voice entry
  - Impact: the setting visibly changed between manual and voice input, and a continuous voice save returned to the keypad.
  - Fix applied: manual and voice docks call the same continuous-accounting control. All five voice states preserve the same `aria-pressed` value. A continuous voice save clears the completed transaction and stays on the voice dock in a safe `idle` state; the microphone does not restart until the user taps the central control.

**Static implementation checks completed**

- Inline JavaScript compiles; all 44 rendered `data-action` values have handlers.
- All five voice states render the same status, keyboard, transcript, waveform, central-control, action-slot, and continuous-accounting structure in the sole `entry` route.
- Listening contains no rendered cancel action; review contains exactly one central rerecord action and one bottom record action. The visible duplicate voice title is absent.
- Fake-timer state tests cover the exact `2999ms listening → 3000ms processing → 3650ms review` endpoint, immediate stop idempotency, keyboard escape, stale-callback rejection, rerecord restoration, regular save, continuous voice save, safe idle, and explicit next-recording start.
- CSS contracts cover one fixed 336px dock, a 60px central control, a 44px keyboard target, the non-overlapping three-column status line, reduced motion, focused Joy feedback, neutral navigation, and standard primary actions.
- `flutter test test/architecture/main_surface_typography_contract_test.dart`: 3/3 passed.
- A rendered 390×844 same-state comparison is still required before marking visual QA passed.

**Next visual QA pass**

- Capture refreshed listening, review, and continuous-idle states at 390×844.
- Include the manual voice launch plus focused crops of the neutral keyboard switch, standard record action, voice-source marker, and continuous-accounting link.
- Compare the complete frames and verify the status line, transcript, waveform, central control, bottom action slot, keyboard target, and continuous row across states.
- Fix any remaining P0/P1/P2 mismatch and repeat the comparison.

final result: blocked

---

## 2026-07-15 — 购物清单完成勾选状态精确还原

本节是最新完成态视觉验收，并覆盖本节先前“所有账本统一使用主绿色完成圆”的
历史说明。最终规则是：完成圆恢复各自未完成时的账本色，再由整张完成卡片统一
弱化，日常和悦己保持可辨识。

**对照目标与证据**

- 用户完成态参考：`/var/folders/qs/d64k8pm541nbr7hjj9scdxj00000gn/T/TemporaryItems/NSIRD_screencaptureui_sQqc94/截屏2026-07-15 17.02.49.png`
- 最终 iOS 完整购物页（日常与悦己同时完成）：`/Users/xinz/.codex/visualizations/2026/07/15/019f6446-9055-7bd2-b8f7-38a3c2374afe/shopping-ledger-colors-native-final.png`
- 最终聚焦对照（上方用户参考，下方悦己/日常实现）：`/Users/xinz/.codex/visualizations/2026/07/15/019f6446-9055-7bd2-b8f7-38a3c2374afe/shopping-ledger-colors-comparison.png`
- 双账本完整页面 golden：`test/golden/goldens/shopping_list_screen_v15_light_ja.png`
- 状态：简体中文、个人模式、浅色主题；iOS 实现同时包含一个悦己完成项和一个日常完成项。实现保留 68dp 可读行高与现有账本语义；参考中的商品名、分类和“个人”徽标只作为完成态层级与对号位置依据。

**发现与修正历史**

- [P1] 完成态原先分别给正文、账本徽标和右侧字形添加 0.58 透明度，卡片表面、边框和勾选圆没有一起弱化，导致视觉不像同一个完成状态。现在由完成卡片持有唯一的 `AnimatedOpacity(0.58)`，背景、边框和全部内容统一淡化，子区域不再重复叠加透明度。
- [P1] 上一轮把日常和悦己完成圆都改成 `accentPrimary`，虽然柔和，但抹掉了两个账本原有的颜色区分。按最新反馈，完成圆现在直接复用未完成圆环已有的 `ledgerColor`：日常为 `palette.daily`，悦己为 `palette.joy`；唯一的整卡 0.58 透明层让两者在完成后自然稍淡。未增加完成态专用颜色。
- [P2] 彩色账本胶囊在完成态淡化后仍带绿/粉色倾向。完成态保留“日常/悦己”文字语义，但视觉改为现有 `backgroundMuted` + `textSecondary`，合成后的米色底 `#F1EBE0` 与参考一致。
- [P2] 右侧完成字形以次级文字色为基色会比参考图过浅。完成态改用 `textPrimary` 后再随整卡弱化，和划线标题形成同一层级。
- [P1] 首轮实现错误地把 Flutter `Icons.check` 保持在圆心，未还原参考图明显的右下光学位置。重新测得参考圆心 `(60.5, 65.5)`、对号轮廓中心约 `(69, 68.5)`，即右 `8.5px`、下 `3px`；映射到当前 28dp 圆后用 `Offset(5, 2)` 修正。最终真机圆为 84px，对号轮廓相对圆心实测右 `15.5px`、下 `7px`，已经呈现同样的右下关系。
- 当前 V16 HTML mockup 已同步整卡 0.58、日常完成绿、悦己完成粉、中性完成徽标和主文字色手柄；其 Material Symbols 网页字形本身具有参考图的右下光学边界，因此没有叠加 CSS 位移，避免双重偏移。未增加颜色令牌或图标资源。

**五项视觉检查**

- 字体：商品标题继续使用现有 item-title 样式并保留删除线；副标题与徽标继续使用 supporting/compact 层级。真机中文字形完整，没有裁切或溢出。
- 间距与布局：完成卡继续使用当前 68dp 行高、28dp 勾选圆和 44dp 右侧槽位，与待购行保持一致；圆本身仍垂直居中，对号绘制位置单独右移 5dp、下移 2dp，交互命中区不变。
- 颜色：完成圆基色复用现有日常绿 `#5FAE72` 和悦己粉 `#D98CA0`，再通过唯一的整卡 0.58 透明层与页面背景合成。最终真机截图中日常为柔和浅绿、悦己为柔和浅粉，既符合“略淡一些”，也能在不依赖文字的情况下区分账本。
- 图像与图标：没有新增图片、SVG、自绘图标或近似资产；继续使用应用现有 Material 勾选与拖动字形。最终聚焦对照明确显示对号不在圆心，而位于参考要求的右下区域。
- 文案与内容：完成态只改变视觉表达；商品名、数量、账本归属、本地化和完成/恢复行为保持原有业务含义。

**验证**

- RED 阶段先把悦己完成圆的期望改为 `palette.joy`，稳定复现旧实现仍返回统一 `accentPrimary`；随后新增日常完成圆的独立颜色断言。
- 修正后购物项与购物页 widget 测试 40/40 通过；覆盖日常/悦己完成 fill 与 border、唯一整卡 0.58、子区域无二次透明度、中性徽标、主层级手柄，以及对号 `Offset(5, 2)` 的位置契约。
- 购物项三语明暗变体与完整 V15 购物页 golden 共 19/19 通过；完整页面 fixture 同时放入日常与悦己完成项，验证两个基色经过真实 0.58 合成后仍明显不同。更新后的基线已再次无更新参数复跑确认。
- `flutter analyze`：0 issues。
- iPhone 16e 模拟器中真实勾选一个悦己商品后，与已有日常完成项同屏检查；最终聚焦对照把用户参考和两种完成颜色放在同一张输入中。结果显示悦己淡粉、日常淡绿、右下对号、删除线和统一弱化均正确，未发现本次范围内剩余的 P0/P1/P2 问题。

final result: passed

---

## 2026-07-15 — 购物清单单项管理、直接拖动与 V15 完成态

**对照目标与证据**

- 用户标注截图：`/Users/xinz/Downloads/截屏 2026-07-15 14.45.41.png`
- 修改后 iOS 列表渲染：`/Users/xinz/.codex/visualizations/2026/07/15/019f6446-9055-7bd2-b8f7-38a3c2374afe/shopping-after-drag.png`
- 长按正文操作菜单：`/Users/xinz/.codex/visualizations/2026/07/15/019f6446-9055-7bd2-b8f7-38a3c2374afe/shopping-action-sheet-real.png`
- 同高并排对照：`/Users/xinz/.codex/visualizations/2026/07/15/019f6446-9055-7bd2-b8f7-38a3c2374afe/shopping-source-vs-implementation.png`
- 状态：简体中文、个人模式、浅色主题、iPhone 16e；实现截图使用两条待购项和一条完成项。参考图处于旧的批量选择态，而实现图展示本次要求的常规单项管理态。

**发现与修正历史**

- [P1] 整行原先同时承载延迟拖动和批量选择长按，正文长按会进入多选，右侧也没有独立的拖动热区。已拆成两个相邻命中区：正文负责编辑/单项菜单，右侧 44×48dp 手柄独占延迟拖动。
- [P1] 页面保留“排序”按键、批量选择顶栏和批量删除底栏。已从购物页与主壳移除这些入口；旧的 provider 状态即使残留也不会隐藏底部导航或重新显示批量 UI。
- [P1] 正文长按缺少单项管理菜单。待购项现在显示“修改 / 置顶 / 置底 / 删除”，删除复用语义错误色；修改进入原有商品表单，置顶/置底与拖动共同复用连续排序写入。完成项继续遵循既有“按完成时间排列”的数据契约，因此只提供修改与删除，右侧显示 V15 的弱化非交互拖动字形。
- [P2] 完成态曾分别改写文字颜色和透明度，视觉层级与 V15 不一致。现在勾选圆保持全饱和绿色，名称/数量、账本徽标和右侧字形统一使用 0.58 透明度，名称保留删除线。
- 当前 V16 HTML mockup 已同步移除排序按键和批量选择逻辑，加入正文长按菜单、红色删除项及右侧手柄直接拖动；没有新增图标资产，继续使用应用现有 Material 拖动字形和勾选图标。

**五项视觉检查**

- 字体：标题、区段标题、商品名称、数量、徽标和底部菜单均沿用现有 `AppTextStyles` 与原生中文字体；删除项只改变语义色，不改变字号或字重体系。
- 间距与布局：待购项继续组成一个 68dp 行高的列表卡；完成项保持独立卡片。44dp 右侧拖动热区与正文命中区互不重叠，移除排序/批量栏后页面节奏与 V15 常规态一致。
- 颜色：未新增颜色令牌；活动勾选环、完成勾选、日常徽标、弱化完成态和错误红色均复用现有语义色。操作菜单遮罩、卡片和圆角使用主题表面色。
- 图像与图标：未增加图片、SVG 或自绘图标；拖动继续使用现有 `drag_indicator`，完成勾选继续使用现有应用图标体系。
- 文案与内容：新增三语“修改 / 編集 / Edit”键；置顶、置底和删除复用既有三语键。列表不再出现“排序”、取消/全选、已选数量或批量删除文案。

**验证**

- RED 阶段先复现旧批量栏、旧排序入口、缺少正文/手柄分区、缺少四项菜单及完成态透明度不一致。
- 修正后相关 shopping/home widget 测试 40/40 通过；新增覆盖正文四项菜单、删除红色、编辑导航、置顶/置底顺序、右侧延迟拖动、手柄长按不弹菜单、遗留批量状态不显示 UI，以及完成态 0.58 视觉契约。
- 购物项与完整购物页 golden 19/19 通过；三语 ARB 键一致性与硬编码 CJK 扫描 3/3 通过。
- `flutter analyze`：0 issues；范围内 `git diff --check`：通过。
- iOS 模拟器实测确认：正文真实长按显示四项操作且删除为红色；右侧手柄真实长按拖动后 Bread/Milk 顺序成功互换且未弹菜单；完成项的实心勾选、删除线和整体弱化与 V15 对照一致。
- 并排图已按同一高度归一化并检查字体、间距、卡片边界、完成态、手柄和底部导航；未发现本次范围内剩余的 P0/P1/P2 问题。

final result: passed

---

## 2026-07-15 — 统计页“全部”文案与空数据图形骨架

**对照目标与证据**

- 用户标注截图：`/Users/xinz/Downloads/截屏 2026-07-15 14.42.35.png`
- 修改后 iOS 空月份渲染：`/private/tmp/analytics-picker-live.png`
- 圆环与控制区稳定渲染：`/private/tmp/analytics-empty-final.png`
- 全页并排对照：`/Users/xinz/.codex/visualizations/2026/07/15/019f6446-9055-7bd2-b8f7-38a3c2374afe/analytics-empty-source-vs-implementation.png`
- 聚焦并排对照：`/Users/xinz/.codex/visualizations/2026/07/15/019f6446-9055-7bd2-b8f7-38a3c2374afe/analytics-empty-focused-comparison.png`
- 状态：简体中文、个人模式、浅色主题、全部账本、无交易月份。参考截图为 2026 年 5 月、440×956；实现验收为 2026 年 2 月、390×844。两者都是同一业务空态；并排图按实现视口归一化，2 月日期轴按实际 28 天显示 6/12/18 日。

**发现与修正历史**

- [P2] 趋势首项复用了 KPI 专用“支出合计”文案。已新增趋势专用三语键：中文“全部”、日文“すべて”、英文“All”；KPI 卡原有“支出合计”不受影响。
- [P1] 空数据时趋势组件提前返回固定高度空盒，导致网格和日期轴一起消失。已让同一个 `LineChart` 始终构建；空态仅不给折线数据，并保留 0 基线、横向网格和日期轴，不伪造一条零值曲线。
- [P1] 分类/成员为空时 `DonutHero` 完全跳过 `PieChart`。已在原有 `PieChart` 内使用一个无标题的中性 track section，维持 63px 环宽和 58px 中心孔；分类与成员两种维度行为一致。
- 当前 V16 mockup 已同步首项文案，并支持 `?analytics-empty=1`：空态保留坐标轴、隐藏数据曲线/端点、显示 ¥0 提示和中性圆环，不回退到默认彩色 fixture。

**五项视觉检查**

- 字体：分段文案沿用现有 segmented-control label token；坐标轴、中心金额和笔数继续使用现有 compact/amount 样式，没有新增字号。
- 间距与布局：趋势卡高度、四条网格线、日期刻度、圆环 63/58 几何和下方控制区均保持原 V15 尺寸；空态与有数据状态不会发生布局跳变。
- 颜色：坐标网格继续使用 `backgroundDivider`；空圆环复用同一个中性 token，浅色截图中清晰可见且不暗示任何分类占比。
- 图像与图标：本次没有新增图片、图标或自绘资产；空圆环继续复用现有 `fl_chart`。
- 文案与内容：首项只在趋势分段改为“全部”；提示仍为“本月 ¥0”，圆环中心仍为“本月支出 / ¥0 / 0笔”。

**验证**

- RED 阶段三个回归分别复现：找不到“全部”、空态没有 `LineChart`、空态没有 `PieChart`。
- 修正后 34 项相关 widget 测试全部通过，覆盖空趋势的轴/网格/无折线、三语趋势专用文案和空圆环的中性色、半径、中心孔及无图例。
- ARB 键一致性与硬编码 CJK 扫描共 3 项架构测试通过。
- `flutter gen-l10n` 已更新三语生成文件；两份 HTML 内联脚本均通过 JavaScript 语法检查。
- `flutter analyze`：0 issues；`git diff --check`：通过。
- iOS 原生字体空月份对照确认：首项为“全部”，趋势空态仍有横向网格、0 基线和日期轴，分类卡仍有完整中性圆环；未发现本次范围内剩余的 P0/P1/P2 问题。

final result: passed

---

## 2026-07-15 — 列表页月历日期字号与金额裁切修正

**对照目标与证据**

- 用户标注截图：`/Users/xinz/Downloads/截屏 2026-07-15 14.39.41.png`
- 修改后 iOS 实机渲染：`/private/tmp/list-calendar-after-fix-stable.png`
- 全页并排对照：`/private/tmp/list-calendar-reference-vs-implementation.png`
- 月历聚焦对照：`/private/tmp/list-calendar-focused-comparison.png`
- 状态：简体中文、个人模式、浅色主题、全部账本、2026 年 7 月、15 日有金额。参考截图为 440×956，实机验收为更窄的 390×844；并排图按高度归一化，聚焦图裁切到相同月历区域。模拟器包含两笔当日交易，因此金额为 13.3千而非参考图的 1.2千，布局与显示规则一致。

**发现与修正历史**

- [P2] 非本月日期字号偏大：`enabledDayPredicate` 先将外月日期判为 disabled，第三方月历优先走默认 disabled 样式，绕过应用的 11px 日期样式。已增加 `disabledBuilder`，让外月日期复用同一日期单元格，同时保留灰色透明度和不可点击行为。
- [P1] 日金额下半部被裁切：金额使用 15px compact 行高，但容器仅 10px 高。已将金额槽位改为 `AppTypography.compactLineHeight`，保留当前字号并完整显示文字。
- 修正后的聚焦对照中，外月 29/30 与本月 1/2 的字面尺寸一致；13.3千的所有笔画完整可见，没有裁切或挤压。

**五项视觉检查**

- 字体：所有日期继续使用现有原生字体栈与 11/15 compact token；外月仅改变透明度，不再改变字面尺寸。
- 间距与布局：44dp 日历行高、日期网格、卡片圆角、汇总行及页面节奏保持不变；15dp 金额槽位仍可容纳在现有行高内。
- 颜色：工作日、周末、今日和外月日期继续复用现有语义色；未增加颜色令牌。
- 图像与图标：本次不涉及图像或图标资产，没有新增或替换资源。
- 文案与内容：日期、紧凑金额格式和本地化文案均未改变。

**验证**

- 初始回归测试同时复现：外月日期 `fontSize` 未使用 compact，以及 1.2千渲染高度只有 10px。
- 修正后 `list_calendar_header_test.dart` 5/5 通过；覆盖同一个“30”在外月/本月均为 11px、1.2千使用 compact 字号且渲染高度至少 15px，以及外月日期不可选择。
- 列表功能相关 widget 测试 40/40 通过。
- `flutter analyze`：0 issues。
- 现有六张列表月历 golden 已包含同一工作区更早的全局字体改版且在本次修复前已经失配，因此未批量覆盖；本次以精确几何断言、完整列表测试和 iOS 原生字体实机截图完成视觉闭环。
- 没有剩余可执行的 P0/P1/P2 问题。

final result: passed

---

## 2026-07-15 — Four-page typography/readability refresh

This section supersedes the older compact 7–12px typography and 60px row
measurements retained below as historical comparison notes.

**Global type contract**

- Flutter source of truth: `lib/core/theme/app_text_styles.dart`
- Canonical HTML mirror: `docs/mockup/v16/index.html`
- Semantic scale: page title 20/28, section 16/22, item 15/21, body 14/21,
  label 13/18, supporting 12/17, compact 11/15, navigation 11/14, button
  14/20; amounts 34/38, 24/30, 18/24, and 15/20. Micro 10/14 is
  compatibility-only and limited to decorative ticket metadata.
- `test/architecture/main_surface_typography_contract_test.dart` prevents the
  four main Flutter surfaces from reintroducing numeric content font sizes and
  verifies the canonical V16 HTML file mirrors `AppTypography` exactly.

**Same-viewport comparison evidence**

- Home: `/private/tmp/typography-audit/compare-home.png`
- Detail/list: `/private/tmp/typography-audit/compare-list.png`
- Analytics: `/private/tmp/typography-audit/compare-analytics.png`
- Shopping: `/private/tmp/typography-audit/compare-shopping.png`
- Each combined input uses the updated 390×844 HTML mockup on the left and the
  Flutter implementation at the same logical viewport on the right. Native iOS
  captures were used for Home, List, and Shopping; Analytics uses a freshly
  rendered deterministic full-page Flutter fixture.

**Readability and layout findings**

- Main content no longer uses 7/8/9px text. List, Analytics, and Shopping have
  an 11px minimum; Home retains only three 10px decorative ticket labels.
- Home rows/cards were expanded around the larger copy: 108px metric region,
  82px ticket, 124–132px invite surface, and 68px transaction rows.
- List uses 46px calendar day rows and 68px transaction rows. Shopping uses a
  44px segmented control, 68px items, and a 28px completion control.
- Analytics expands the trend plot, chart axes/legends, donut center/rows,
  calendar details, drawer rows, and histogram so 11–16px text has sufficient
  room.
- The canonical V16 HTML file was tested at 320, 375, and 390px across all four pages:
  zero horizontal overflow, escaping elements, or clipped text. The phone frame
  now preserves the exact requested client width.
- No actionable P0/P1/P2 visual issue remains in the four refreshed surfaces.
- P3 accepted: the host golden renderer shows placeholder boxes for the native
  Japanese font stack; native iOS captures resolve Hiragino correctly.

**Verification**

- `flutter analyze`: 0 issues.
- Global typography/theme tests, four-page widget/screen tests, typography
  architecture tests, and the temporary on-device four-page navigation/capture
  test all pass.
- Full non-golden suite: 3,527 passed, 11 skipped.
- The existing golden suite reports 194 intended visual deltas from the global
  font/line-height change. Those pre-existing dirty baselines were deliberately
  not bulk-overwritten before user review; the only layout exception found in
  that run (a stale 60px list-row harness causing 2px overflow) was corrected to
  the new 68px row contract.
- `git diff --check`: passes for the scoped implementation and mockup changes.

final result: passed

---

## 2026-07-15 — 首页对齐与“本月最爱”等级区修正

本节是本次首页三处反馈的最新验收记录，并覆盖下文保留的关于“本月最爱”仍使用
22px Material 图标的历史说明。

**对照证据**

- 用户标注截图：`/Users/xinz/Downloads/截屏 2026-07-15 14.33.54.png`
- 修改后 iOS 实机渲染：`/private/tmp/home-pocket-returned-home.png`
- 并排对照：`/private/tmp/home-pocket-reference-vs-implementation.png`
- 对照均为简体中文、个人模式、浅色主题和 2026 年 7 月有数据状态；并排图按同一高度归一化，原始参考视口为 440×956，实机验收视口为 390×844。

**验收结果**

- “查看本月分析”现在占据悦己充盈标题行的最后一个固定区域，箭头右边缘与指标区右边缘一致；几何回归测试直接比较两个边缘坐标。
- 满足度均值和小确幸继续使用两个等高 `Center` 槽位；回归测试验证每项内容中心与其槽位中心的偏差小于 0.01 logical pixel。
- “本月最爱”右侧易撕等级区由 58dp 增至 72dp；等级图标增至 32dp，文案使用 12px supporting 样式。
- 等级图标改为现有 `SatisfactionFaceIcon`，按交易的 `joyFullness` 选择应用内 `assets/satisfaction/sat_01.svg` 至 `sat_05.svg`；未增加任何新图标或资源。
- 原有票券颜色、虚线、上下缺口、文案和本地化键均保持不变。

**验证**

- `home_hero_card_test.dart`：32 项通过，覆盖右对齐、上下居中、72dp 等级区、既有等级图标及 400dp 中文窄宽度无溢出。
- `home_screen_test.dart`：15 项通过。
- `flutter analyze`：0 issues。
- 原有 HomeHero golden 基线已包含同一工作区中更早的全局字体改版，因此未在本次局部修改中批量覆盖；本次使用几何断言与 iOS 原生字体实机截图完成视觉闭环。
- 未发现本次范围内的 P0/P1/P2 视觉问题。

final result: passed

### Detailed comparison evidence

**Comparison target**

- Source visual truth: `docs/mockup/v16/index.html`
- Focused user references:
  - Metrics alignment: `/var/folders/qs/d64k8pm541nbr7hjj9scdxj00000gn/T/TemporaryItems/NSIRD_screencaptureui_7pfjXb/截屏2026-07-15 11.18.12.png`
  - Ticket tear interruption: `/var/folders/qs/d64k8pm541nbr7hjj9scdxj00000gn/T/TemporaryItems/NSIRD_screencaptureui_T3v38X/截屏2026-07-15 11.20.11.png`
- Source capture: `/tmp/v15-home-source.png`
- Rendered implementation capture: `/tmp/v15-home-implementation-ios-final.png`
- Post-change rendered regression capture: `test/golden/goldens/home_hero_card_single_light_ja.png`
- Focused post-change ticket capture: `/private/tmp/home_ticket_notch_after.png`
- Combined comparison: `/tmp/v15-home-comparison-final.png`
- Viewport/state: 390×844 logical pixels, personal mode, Japanese, light theme. The implementation was captured from the production widgets on an iPhone 16e simulator using the native Hiragino system font.

**Full-view comparison evidence**

The combined capture places the V15 phone on the left and the iOS implementation on the right. After accounting for the mockup's 8px decorative phone frame, both use the same 20px content inset, header rhythm, hero proportions, 100px metric ring, 74px Best Joy ticket, invite-card placement, and detached navigation treatment.

**Focused region comparison evidence**

- Header: month title has no extra arrow; the compact `個人` badge and both 40px icon hit areas match V15.
- Hero density: the 10px label, 8px trend, 9px previous-month line, 8/10px ledger split, 11px region title, and 8px analysis link reproduce the denser hierarchy.
- Metrics: goal progress/track/value, satisfaction fill/text/track, small-win amber, and the olive divider use the exact V15 dedicated color set. The focused user crop was inspected separately for the requested alignment: the right column is now implemented as two explicit equal-height slots, and both content centers equal their slot centers within 0.01 logical pixels.
- Best Joy ticket: the final capture shows the 48px calendar, pale-green ticket surface, dedicated pink border/accent, dashed seal, top and bottom tear notches, 22px Material satisfaction icon, and no category icon. The focused post-change crop confirms that the outer horizontal border is absent across both notch openings, while the curved inner notch edges and vertical dashed tear line remain intact.
- Family invite: the primary-tinted border and soft 0/8/30 shadow are visible; the close target and CTA occupy the top/bottom action alignment from V15.
- Transactions: the component contract verifies a 60px row, 9×12 padding, 25px icon, 11px title, 8px metadata and 12px amount. Joy satisfaction and foreign secondary amount remain present by explicit product decision.

**List detail-page comparison evidence (L1–L7)**

- Source measurements were taken directly from the V15 list-page DOM/CSS in the comparison target: 46px header, 20px baseline, 40px header actions, 40px calendar rows, 16px weekday band, 10px/9px day typography, 14×10px summary padding, 14px blur filter material, 60px transaction rows, and 10px day-group spacing.
- Header: the Material `AppBar` is removed. The custom header uses the V15 46px height, information-blue month title, 20px page inset, and two 40px action targets.
- Calendar: the card now has the V15 warm shadow and compact grid/summary typography. The current-month predicate disables adjacent-month dates, and a behavioral test verifies that tapping the visible December 30 cell in January does not change the selected day or month.
- Compact amounts: Japanese and Chinese display values from 1000 as a fixed thousand unit (`1千`, `1.5千`, `10千`, `12.3千`) instead of locale-dependent compact notation. The analytics and calendar goldens affected by this shared formatter were refreshed and inspected.
- Filter material: the bar is edge-to-edge, 96% background opacity, 14px backdrop blur, and 20px internal content inset, matching the V15 full-width glass strip.
- Transactions: component goldens verify 60px minimum height, 9×12px padding, 25px icon, 11px title, 8px metadata, and 12px amount. The Joy satisfaction face remains visible, and foreign rows retain their second amount by explicit product decision.
- Visual regression evidence inspected after implementation: `test/golden/goldens/list_calendar_header_ja.png`, `test/golden/goldens/list_sort_filter_bar_ja.png`, `test/golden/goldens/list_transaction_tile_ja.png`, `test/golden/goldens/list_transaction_tile_foreign_ja.png`, `test/golden/goldens/category_drill_down_screen_light_ja.png`, `test/golden/goldens/within_month_trend_card_light_ja.png`, and `test/golden/goldens/joy_calendar_card_expand_light_ja.png`.

**Findings**

- No actionable P0/P1/P2 mismatch remains for H1–H6 or H8.
- No actionable P0/P1/P2 mismatch remains for L1–L7.
- P3 accepted: calendar month/day/weekday strings remain locale-formatted by the production date formatter instead of the mockup's fixed English abbreviations; this preserves the app's i18n contract.
- P3 accepted: the iOS status bar and native glyph antialiasing differ from the browser-rendered mockup as expected.

**Comparison history**

- Initial implementation review found 28dp page margins, a redundant month arrow, long mode labels, oversized hero copy, generic metric colors, an oversized ticket without tear notches, a custom satisfaction face, flat invite styling, and oversized transaction rows.
- First iOS comparison confirmed layout and colors but exposed the ticket's custom heart-face icon as a visible P2 mismatch.
- The ticket now uses the V15 Material `sentiment_very_satisfied` icon and a valid localized hobby category fixture.
- Post-fix combined evidence shows no remaining P0/P1/P2 mismatch.
- The latest focused feedback identified that `満足度の平均` and `小確幸` needed an explicit vertical-centering contract. The generic `Align` wrappers were replaced with named top/bottom `Center` slots. A widget-coordinate regression test verifies equal slot heights and exact vertical-center alignment; the HomeHero golden suite confirms no overflow or layout regression.
- The ticket follow-up identified a solid flat edge across each semicircular notch. The top notch now omits its top border and the bottom notch omits its bottom border, producing a true interruption in the ticket outline. The revised focused crop shows the break clearly, and a widget test asserts the asymmetric border sides directly.

**Implementation checklist**

- [x] 20px page margins and 13px header-to-hero spacing
- [x] Compact header labels and 40px calendar/settings targets
- [x] V15 hero typography and information density
- [x] Dedicated metric composition colors
- [x] Equal-height metric support slots with independently centered content
- [x] Ticket dimensions, colors, tear notches, icon, and copy density
- [x] Ticket outline interrupted at both tear-notch openings
- [x] Invite border, shadow, and action alignment
- [x] Compact transaction row while preserving Joy/foreign extensions
- [x] V15 list header, 20px baseline, and 40px header targets
- [x] Compact calendar styling, shadow, summary, and disabled outside dates
- [x] Fixed thousand-unit amount abbreviation from 1000
- [x] Full-width translucent blurred list filter material
- [x] Compact list transaction rows while preserving Joy/foreign extensions
- [x] 10px day-group spacing
- [x] Static analysis, focused tests, golden refresh, and native-font visual capture

**Follow-up polish**

- None required for the requested scope.

**Analytics-page comparison evidence (A1–A10)**

- Source visual truth: V16 analytics DOM/CSS in `docs/mockup/v16/index.html`, including the 16px card radius, 190px trend plot, 242px donut, 164/88px controls, 52px legend rows, 1px calendar grid, 44px day rows, and single pink histogram narrative.
- Source capture: `/private/tmp/v15-analytics-reference.png`.
- Rendered implementation captures inspected at original resolution: `test/golden/goldens/analytics_screen_scroll_smoke_light_ja.png`, `test/golden/goldens/within_month_trend_card_light_ja.png`, `test/golden/goldens/category_donut_card_light_ja.png`, `test/golden/goldens/joy_calendar_card_expand_light_ja.png`, and `test/golden/goldens/satisfaction_histogram_card_light_ja.png`.
- Focused same-state donut comparison: `/private/tmp/v15-analytics-category-comparison.png` (V15 source left, production golden right). The comparison confirms the 242px outer diameter, 116px center opening, thicker 63px ring, smaller center total, and enlarged on-ring labels.
- Cards use 16px corners and the V15 0/3/14 warm shadow; category content alone uses the 18px inset.
- Trend plot height is 190px and both endpoint annotations are single-line (`M/d ¥…` and localized `先月 ¥…`).
- Category and member controls are fixed to 164×42 and 88×42; legend rows are 52px high with compact 11.5/11px typography.
- The Joy drawer no longer has the extra divider or 30px dead space; its 44px toggle and detail spacing match V15.
- Calendar cells use a 1px grid, 10px dates, non-zero count dots, 8px card inset, and second-tap collapse. Expanded content has the inset top border and 44px compact transaction rows.
- Satisfaction distribution now ends in one localized pink narrative; the split count/median-pill layout is absent.

**Analytics findings**

- No actionable P0/P1/P2 mismatch remains for A1–A10.
- P3 accepted: Flutter golden rendering in the test environment uses placeholder glyph boxes for the newly adopted native Japanese font stack; native iOS rendering uses Hiragino and is covered by the system-font theme contract.
- Verification passed: focused analytics widget tests, the complete golden suite, `flutter analyze`, and the full 3,736-test Flutter suite (11 skipped).

final result: passed

**Shopping-page comparison evidence (S1–S5)**

- Source visual truth: the current V16 shopping DOM/CSS in `docs/mockup/v16/index.html`.
- Current V15 source capture: `/private/tmp/v15-shopping-current-full.png`; 390×844 phone crop: `/private/tmp/v15-shopping-reference-current.png`.
- Rendered production-widget capture: `test/golden/goldens/shopping_list_screen_v15_light_ja.png`.
- Same-state combined comparison: `/private/tmp/v15-shopping-comparison.png` (V15 source left, Flutter production widgets right), 390×844 logical pixels, personal mode, Japanese, light theme.
- Header: the shared 46px main-surface header keeps the title on the left and adds the 40px settings action on the right.
- Personal filter: the bordered 18px-radius surface contains the three-way ledger segment plus the always-visible 私有 / カテゴリ row.
- Family filter: 全部 / 個人 scope stacks above the ledger segment; switching scope resets ledger, private, and category filters.
- Secondary filters: 私有 filters private items immediately; カテゴリ opens the shopping-only L1 multi-select bottom sheet with clear, cancel, and apply actions. Both combine with the ledger filter.
- Segmented control: the track is the V15 54% muted-surface mix with the warm 0/3/12 shadow; labels are 10.5px, unselected text uses the primary text token, and the selected option uses the V15 tone-specific fill/ring/shadow.
- Page/list geometry: list cards use the 20px page baseline and section titles use the 21px source offset.
- Active rows: the combined capture confirms 60px rows, 10×12px row padding, 23px ledger-colored completion rings, 11px names, 9px metadata, 8px badges, and a permanently visible 20px drag indicator. The completion control no longer reserves the old 44px horizontal lane.
- Checked state: completed rows use the ledger color as the 23px circle fill with a 15px white check; row copy, badge, and drag affordance fade to 58%, and the name receives a line-through. A focused widget test asserts the exact fill, icon color, and icon size.
- Completed rows: every completed item owns a separate 14px rounded bordered card with an 8px inter-card gap; no shared container or divider remains.

**Shopping findings**

- No actionable P0/P1/P2 mismatch remains for S1–S5.
- P3 accepted: Flutter's headless golden renderer uses placeholder glyph boxes for the platform font stack and Material icons; geometry and colors are deterministic, while native builds resolve the system Japanese and Material glyphs.
- Verification passed: 48 focused widget tests, 61 shopping golden tests, the new 390×844 personal-screen golden, `flutter analyze` with zero issues, and the complete Flutter test suite.

final result: passed

---

## Current result — 2026-07-16 unified entry option 1

The latest QA report is the 2026-07-16 “统一记账方案 1「单页连续输入」” section above. Its rendered same-state comparison remains blocked because the approved in-app browser surface cannot capture the local `file://` implementation.

final result: blocked

---

## Current result — 2026-07-16 V16 Flutter implementation

The completed production implementation and its final 390×844 paired visual
evidence are recorded in “V16 统一记账、账目编辑与新增购物项实现验收” above.
That rendered pass supersedes the earlier mockup-only blocked notes.

final result: passed

---

# Category Selection V16 — Design QA (2026-07-19)

## Scope

- Reference: `docs/mockup/v16/index.html` (`CategorySelectionScreen`, 390×844)
- Flutter implementation: `lib/features/accounting/presentation/screens/category_selection_screen.dart`
- Captured states:
  - `test/golden/goldens/category_selection_v16_light_ja.png`
  - `test/golden/goldens/category_creation_l1_v16_light_ja.png`

## Visual contract check

| Area | v16 contract | Flutter result |
| --- | --- | --- |
| Header | 56px paper surface, centered title, close and reorder actions, bottom divider | Pass |
| Search | 20px horizontal shell padding, 48px muted input, 12px radius | Pass |
| Category list | 16px horizontal / 12px top padding, 8px group gap | Pass |
| L1 group | 14px radius, 36px icon tile, category-color expanded border and soft shadow | Pass |
| L2 chips | Compact 36px minimum-height wrap, selected solid fill, 8px spacing | Pass |
| Add dock | Fixed 48px action above the bottom safe area with warm fade | Pass |
| Empty search | Quiet `search_off` icon and localized no-match copy | Pass |
| Creation sheet | Existing paper palette, 24px top radius, 48px actions, keyboard-safe inset | Pass |
| Dark mode | Uses `AppPalette.dark` through semantic tokens; no light-only literals in presentation | Pass |

## Interaction and accessibility

- L1 headers, L2 chips, add actions, reorder action, ledger choices, and sheet actions are tappable Material controls.
- Existing preselection expansion and one-shot scroll behavior remains intact.
- Search, reorder, discard confirmation, L1 creation, and L2 creation are covered by widget tests.
- L1 ledger choices expose selected semantics; icon actions include tooltips.
- All new user-facing copy is present in `ja`, `zh`, and `en` ARB files.

## Defects found and resolved

1. The original add controls had empty callbacks. Replaced with complete creation flows.
2. The first visual capture exposed L2 chips expanding to the full row width. Removed the expanding alignment so chips match the compact v16 wrap geometry.
3. New L1 creation could have violated the mandatory ledger-config invariant. Category and ledger config now write in one Drift transaction with rollback coverage.

## Verification

- `flutter analyze`: 0 issues
- Targeted category/use-case/caller tests: passed
- Golden tests at 390×844: 2 passed
- Full `flutter test`: 3849 passed, 11 skipped
- `git diff --check`: passed

final result: passed

---

# Family Flow V16 — Design QA (2026-07-19)

## Scope and evidence

- Selected visual direction: `/Users/xinz/.codex/generated_images/019f7881-03db-72f2-a542-5b075d8e3a27/exec-b3e558ca-ede3-4de3-a938-04efa90bf57a.png`
- Implementation: `docs/mockup/v16/index.html`
- Viewport/state: 390×844 phone frame, light theme, Japanese app copy.
- Same-input visual comparison board: `/Users/xinz/.codex/visualizations/2026/07/19/019f7881-03db-72f2-a542-5b075d8e3a27/family-implementation-board.png`
- Full mockup captures:
  - `/Users/xinz/.codex/visualizations/2026/07/19/019f7881-03db-72f2-a542-5b075d8e3a27/family-entry-full.png`
  - `/Users/xinz/.codex/visualizations/2026/07/19/019f7881-03db-72f2-a542-5b075d8e3a27/family-create-full.png`
  - `/Users/xinz/.codex/visualizations/2026/07/19/019f7881-03db-72f2-a542-5b075d8e3a27/family-join-full.png`
  - `/Users/xinz/.codex/visualizations/2026/07/19/019f7881-03db-72f2-a542-5b075d8e3a27/family-join-confirm-full.png`
  - `/Users/xinz/.codex/visualizations/2026/07/19/019f7881-03db-72f2-a542-5b075d8e3a27/family-join-waiting-full.png`
  - `/Users/xinz/.codex/visualizations/2026/07/19/019f7881-03db-72f2-a542-5b075d8e3a27/family-group-full.png`

## Visual and flow findings

- No actionable P0, P1, or P2 difference remains against the selected option 2 direction.
- Entry is a neutral branch selector and does not borrow either path's progress indicator.
- Owner creation uses its own three steps: 家族作成 → 招待共有 → メンバー承認. The invite code, expiry, regenerate, share, and incoming-request approval states are interactive.
- Invite-code joining uses a different three-step sequence: コード入力 → 家族確認 → 承認待ち. Six individual code inputs, target-family verification, request submission, and the waiting state are interactive.
- The waiting state shows no syncing status; it explains that sync starts only after owner approval. Private-ledger copy stays visible throughout the join path.
- Family management is the shared post-approval destination and deliberately has no onboarding stepper. It includes sync status, one pending request, real member avatars, invite-code actions, sync settings, and the destructive dissolve action.
- The implementation keeps the selected warm paper palette, green structural accents, pink primary actions, compact outlined cards, modest radii, and restrained shadows while reusing the V16 mockup's existing shell and inspector.

## Responsive and interaction verification

- 375, 390, and 430 phone widths all report equal `clientWidth` and `scrollWidth` for the phone and family screen; no horizontal overflow remains.
- At 375px, both progress rails fit their 335px content width and the six invite-code inputs fit the same width without scrolling.
- Creation was exercised from entry through invite sharing, owner approval, and family management.
- Joining was exercised from code input through family confirmation and approval waiting; owner approval was then simulated through the inspector to reach family management.
- Entry and management contain zero progress rails; creation and joining activate only their own expected steps.
- Browser console: 0 errors, 0 warnings.
- Inline JavaScript syntax and scoped `git diff --check` pass.

final result: passed

---

# Family Entry Icons — Option 3 Design QA (2026-07-19)

## Scope and evidence

- Source visual truth: `/Users/xinz/.codex/generated_images/019f7881-03db-72f2-a542-5b075d8e3a27/exec-d52d6580-5428-42b0-99a6-da711ef58176.png`
- Implementation: `docs/mockup/v16/index.html`, family entry state.
- Viewport/state: 390×844 phone frame, Japanese copy, light and dark themes.
- Browser-rendered implementation: `/Users/xinz/.codex/visualizations/2026/07/19/019f7881-03db-72f2-a542-5b075d8e3a27/family-icons-option3-final.png`
- Full-view combined comparison: `/Users/xinz/.codex/visualizations/2026/07/19/019f7881-03db-72f2-a542-5b075d8e3a27/family-icons-option3-full-comparison.png`
- Focused icon comparison: `/Users/xinz/.codex/visualizations/2026/07/19/019f7881-03db-72f2-a542-5b075d8e3a27/family-icons-option3-focused-comparison.png`
- Dark-theme evidence: `/Users/xinz/.codex/visualizations/2026/07/19/019f7881-03db-72f2-a542-5b075d8e3a27/family-icons-option3-dark.png`

## Findings

- No actionable P0, P1, or P2 difference remains against the selected icon concept.
- Fonts and typography: unchanged from the existing V16 family entry; the icon replacement does not alter title wrapping, weights, or line heights.
- Spacing and layout rhythm: the 50×50 tile, 14px radius, card padding, text column, and chevron alignment remain unchanged. Both transparent marks render at 48×48 with their own internal padding.
- Colors and visual tokens: light assets use the selected forest green and rose heart on the existing mint tile. Theme-specific assets use light sage and rose on the dark mint tile instead of reducing contrast.
- Image quality and asset fidelity: both marks are independent 128×128 transparent PNG assets with clean alpha edges. No inline SVG, CSS drawing, emoji, screenshot crop, or placeholder is used.
- Copy and content: all Japanese labels and descriptions are unchanged. Decorative images remain hidden from accessibility APIs, so each card retains one concise button name.

## Comparison history

1. The first browser pass rendered the generated assets at 38×38, making both marks visibly smaller than the selected concept. The image slot was increased to 48×48 while preserving the 50×50 tile.
2. The first dark-theme pass reused the light forest-green pixels and had insufficient contrast on the dark tile. Dedicated dark-theme PNG variants were added with semantic light-sage and rose colors.
3. The final full-view, focused, and dark-theme captures show the selected open-door sprout and heart invitation-door concepts at the intended scale with no halo or clipping.

## Verification

- 375, 390, and 430 widths: phone and family screen `clientWidth` equal `scrollWidth`; no horizontal overflow.
- Light and dark assets load successfully and stay 48×48 in the 50×50 tiles.
- Family entry buttons still navigate through the existing create and join actions.
- Browser console: 0 errors, 0 warnings.
- Inline JavaScript syntax and scoped `git diff --check`: passed.

final result: passed
# V16 Home Original Summary Style + Tear Notches — Design QA (2026-07-25)

## Scope and evidence

- Source visual truth: `/var/folders/qs/d64k8pm541nbr7hjj9scdxj00000gn/T/TemporaryItems/NSIRD_screencaptureui_w9uv2S/截屏2026-07-25 15.54.48.png`, with the explicit instruction to retain the tear notches.
- Implementation: `docs/mockup/v16/index.html`, `主页`.
- State: A1 personal light, 390×844 phone frame.
- Source pixels: 756×732 at 144 dpi. Implementation phone capture: 390×844; focused hero comparison normalized to 680px panel width.
- Final browser-rendered home: `/Users/xinz/.codex/visualizations/2026/07/25/019f97e9-f261-7490-b09d-5384602cc7d7/home-original-style-tear-final.jpg`.
- Focused same-input comparison: `/Users/xinz/.codex/visualizations/2026/07/25/019f97e9-f261-7490-b09d-5384602cc7d7/home-original-style-tear-comparison-final.jpg`.
- Dark-state capture: `/Users/xinz/.codex/visualizations/2026/07/25/019f97e9-f261-7490-b09d-5384602cc7d7/home-original-style-tear-dark.jpg`.

## Findings

- No actionable P0, P1, or P2 issue remains.
- The expense section now matches the supplied original Home style: Japanese section label, large system-sans amount, green trend capsule, Japanese previous-period copy, inline Joy/daily ledger values, colored endpoint dots, and the pink/green split bar.
- The original Joy hierarchy remains directly below it, while the retained left/right 20px tear notches sit precisely on the section divider.
- `今月の最愛` remains an independent card as established by the earlier approved Home structure.
- Fonts and typography: the summary amount, trend, comparison, and ledger figures use the original body font and weights; Joy, favorite, member, and transaction number treatments remain unchanged.
- Spacing and layout rhythm: the restored summary uses the original 18px card padding, 34px ledger area, and 22px outer radius. The notches add no vertical height.
- Colors and tokens: the original blended Hero surface, green trend surface, Joy/daily colors, and split-bar proportions are restored in both light and dark themes.
- Image quality: no raster assets changed, and all icons continue to use the existing Material Symbols library.
- Copy and content: original Japanese Home labels and dynamic family values are restored without reintroducing the favorite section into the Hero.

## Comparison history and verification

1. The previous iteration used the English receipt header and two tinted ledger blocks.
2. This iteration replaced that upper section with the supplied original Home summary while preserving the approved tear-notch divider and standalone favorite card.
3. The post-fix focused comparison found no remaining P0/P1/P2 mismatch.
- At 375, 390, and 430 widths, the phone and ledger row report no horizontal overflow.
- A2 family mode updates the section label, total, and daily-ledger value while retaining one tear divider.
- A3 dark mode preserves the Hero surface, trend capsule, notch contrast, and amount readability.
- Enter on the Hero still opens the statistics view.
- Browser console: 0 errors and 0 warnings.
- Inline JavaScript syntax and scoped `git diff --check`: passed.

final result: passed

---

# V16 Home Joy Restoration + Tear Notches — Design QA (2026-07-25)

## Scope and evidence

- Source visual truth: `/var/folders/qs/d64k8pm541nbr7hjj9scdxj00000gn/T/TemporaryItems/NSIRD_screencaptureui_q9xzp5/截屏2026-07-25 15.47.05.png`, plus the explicit request to restore the original Joy design and add left/right tear notches.
- Implementation: `docs/mockup/v16/index.html`, `主页`.
- State: A1 personal light, 390×844 phone frame.
- Source pixels: 718×886 at 144 dpi. Implementation phone capture: 390×844; focused hero crop normalized to the same 680px comparison width.
- Final browser-rendered home: `/Users/xinz/.codex/visualizations/2026/07/25/019f97e9-f261-7490-b09d-5384602cc7d7/home-receipt-tear-notches-final.jpg`.
- Focused same-input comparison: `/Users/xinz/.codex/visualizations/2026/07/25/019f97e9-f261-7490-b09d-5384602cc7d7/home-receipt-tear-notches-comparison-final.jpg`.
- Dark-state capture: `/Users/xinz/.codex/visualizations/2026/07/25/019f97e9-f261-7490-b09d-5384602cc7d7/home-receipt-tear-notches-dark.jpg`.

## Findings

- No actionable P0, P1, or P2 issue remains.
- The upper expense receipt remains unchanged from the selected direction.
- The lower Joy region restores the original subtly tinted card surface and the original ring interior treatment while preserving its established title, goal, satisfaction, and small-win layout.
- A dashed perforation now spans the boundary, with matching 20px left and right inward semicircular notches cut in the page background color. The notches preserve the outer card border curve in both light and dark themes.
- Fonts and typography: the existing receipt number stack and original Joy hierarchy remain unchanged.
- Spacing and layout rhythm: the original 108px Joy metric grid and support stack are preserved; the new perforation does not add visible vertical bloat.
- Colors and tokens: the restored Joy surface uses the pre-redesign `surface` / `primary-soft` blend, and the notch fill follows the page background token.
- Image quality: no raster or icon assets were changed; the existing Material Symbols remain sharp.
- Copy and content: all Japanese labels and values remain unchanged.

## Comparison history and verification

1. The prior combined card used a plain surface across both regions and only a dashed divider.
2. The fix restored the Joy region's original tinted surface and ring interior, then added symmetric side notches aligned to the divider.
3. The post-fix focused comparison found no remaining P0/P1/P2 mismatch.
- At 375, 390, and 430 widths, the phone reports no horizontal overflow and the Joy region stays within the card.
- A2 family mode keeps one perforation and updates its dynamic values correctly.
- A3 dark mode maps the Joy surface, notch fill, and notch edge to dark semantic tokens.
- Enter on the receipt card still opens the statistics view.
- Browser console: 0 errors and 0 warnings.
- Inline JavaScript syntax and scoped `git diff --check`: passed.

final result: passed

---

# V16 Home Receipt Card Redesign — Design QA (2026-07-25)

## Scope and evidence

- Source visual truth: `/Users/xinz/Desktop/截屏2026-07-25 15.34.43.png`.
- Implementation: `docs/mockup/v16/index.html`, `主页`.
- Viewport/state: 390×844 phone frame, A1 personal light preset.
- Final browser-rendered home: `/Users/xinz/.codex/visualizations/2026/07/25/019f97e9-f261-7490-b09d-5384602cc7d7/home-receipt-redesign-final.jpg`.
- Focused same-input comparison: `/Users/xinz/.codex/visualizations/2026/07/25/019f97e9-f261-7490-b09d-5384602cc7d7/home-receipt-comparison-final.jpg`.
- Dark-state capture: `/Users/xinz/.codex/visualizations/2026/07/25/019f97e9-f261-7490-b09d-5384602cc7d7/home-receipt-dark-state.jpg`.

## Findings

- No actionable P0, P1, or P2 issue remains.
- The expense overview now follows the supplied receipt language: rounded paper card, restrained border and shadow, uppercase receipt metadata, dashed rules, large total, previous-month comparison, and two tinted ledger blocks.
- `今月の最愛` is no longer embedded inside the overview. It is a separate bordered card with its own title row and retained ticket detail.
- The Joy goal, average satisfaction, and small-win metrics remain inside the overview card below a second dashed separator, so the redesign preserves the existing Home information model.
- All Home dates, amounts, percentages, Joy values, member values, and recent-transaction amounts use the same tabular monospaced number stack with slashed-zero support.
- Warm light tokens and the existing dark semantic tokens both preserve readable borders, surfaces, and ledger contrast.

## Interaction, responsive, and code verification

- Clicking the standalone favorite card opens the statistics view.
- Pressing Enter on the receipt overview card also opens the statistics view.
- At 375, 390, and 430 phone widths, the phone, receipt card, ledger blocks, and favorite card report no horizontal overflow.
- A2 family mode updates the total, previous value, and daily-ledger amount without changing the card hierarchy.
- A3 dark mode preserves the receipt/favorite borders and the numeric font.
- Browser console: 0 errors and 0 warnings.
- Inline JavaScript syntax and scoped `git diff --check`: passed.

final result: passed

---
