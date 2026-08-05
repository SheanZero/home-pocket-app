# Home Pocket website — Design QA

Date: 2026-08-05

Scope: Japanese and English multi-page Hugo website, concise homepage, philosophy/features/family/privacy/FAQ routes, shared navigation/footer, mobile navigation, store entry points, and responsive behavior.

## Visual target and evidence

- Approved direction: `/Users/xinz/.codex/generated_images/019fcd09-a0ef-7321-8ad2-8cf89cb3ed86/exec-a0b541e8-203c-484e-baff-a5740e4ea5d5.png`
- Matched desktop comparison: `docs/qa/home-reference-vs-implementation.png`
- Final Japanese desktop hero: `docs/qa/home-ja-hero-final.png`
- Final English desktop hero: `docs/qa/home-en-hero-final.png`
- Final Japanese mobile hero: `docs/qa/home-ja-mobile-final.png`
- Mobile menu: `docs/qa/home-ja-mobile-menu.png`
- Desktop feature section: `docs/qa/home-ja-lower.png`
- Mobile feature flow: `docs/qa/home-ja-mobile-features-final.png`
- Privacy page: `docs/qa/privacy-ja-desktop.png` and `docs/qa/privacy-ja-mobile.png`
- Store-button source truth: `/var/folders/qs/d64k8pm541nbr7hjj9scdxj00000gn/T/TemporaryItems/NSIRD_screencaptureui_PWqcuj/截屏2026-08-05 10.25.42.png`
- Store-button focused comparison: `docs/qa/store-buttons-reference-comparison.png`
- Store-button desktop implementation: `docs/qa/store-buttons-desktop-focused.png`
- Store-button mobile implementation and context: `docs/qa/store-buttons-mobile-focused.png` and `docs/qa/store-buttons-mobile-context.png`
- Multi-page source truth: `docs/qa/home-ja-hero-final.png` (approved single-page visual system before the information-architecture split)
- Multi-page homepage implementation: `docs/qa/multipage-home-ja-desktop.png`, `docs/qa/multipage-home-ja-routes.png`, and `docs/qa/multipage-home-ja-mobile.png`
- Same-viewport homepage comparison: `docs/qa/multipage-home-reference-comparison.png`
- Japanese route evidence: `docs/qa/multipage-philosophy-ja-desktop.png`, `docs/qa/multipage-features-ja-desktop.png`, `docs/qa/multipage-family-ja-desktop.png`, `docs/qa/multipage-privacy-ja-desktop.png`, and `docs/qa/multipage-faq-ja-desktop.png`
- English and mobile route evidence: `docs/qa/multipage-features-en-desktop.png`, `docs/qa/multipage-features-ja-mobile.png`, and `docs/qa/multipage-family-ja-mobile.png`

## Findings and fixes

### P1 — Mobile lifestyle images forced horizontal overflow — fixed

- Evidence: at the 390 px requested viewport, the 375 px content viewport initially reported a 440 px document width. The `aspect-ratio` plus a 330 px minimum height forced the family and still-life figures to 440 px wide.
- Impact: a visible horizontal scrollbar and clipped photography on phone screens.
- Fix: mobile/tablet figures now use an explicit responsive width and height with no ratio-derived minimum width. Re-test reports `scrollWidth = clientWidth` at 390, 768, 945, and 1440 px requested viewports.

### P2 — Mobile menu remained open after in-page navigation — fixed

- Evidence: selecting the FAQ link changed the hash but left the native `<details>` menu open over the destination.
- Impact: the menu obscured the content a user had just selected.
- Fix: a small deferred script closes the containing menu after any menu link is activated. Browser verification reports `hash = #features` and `open = false` after navigation.

### P2 — Japanese hero emphasis broke inside 「うれしい」 — fixed

- Evidence: the first desktop pass wrapped the highlighted word between `うれ` and `しい`, weakening the selected headline treatment.
- Impact: the core emotional phrase read as visually broken.
- Fix: the desktop Japanese hero uses a localized display scale and keeps the complete second line together; phone layouts intentionally return to natural wrapping without overflow.

### P2 — Store links lacked recognizable platform icons — fixed

- Evidence: the supplied store-button capture showed text-only black badges, so neither platform could be recognized at a glance.
- Impact: the primary download choices looked unfinished and required more reading than familiar store badges.
- Fix: both homepage locations now use the real Apple and Google Play marks from the Simple Icons library. The assets are linked as external SVG image files, not custom-drawn or inline approximations, and remain decorative so the link names stay concise for assistive technology.

### P2 — Phone store links stacked vertically — fixed

- Evidence: the previous `max-width: 600px` rule collapsed the two store links to one column.
- Impact: the two oversized rows interrupted the hero rhythm and made the platform choice feel heavier than the rest of the warm editorial layout.
- Fix: phone layouts now keep the links in a compact two-column grid with 8 px spacing, 58 px tap-target height, 22 px icons, and responsive text tracks. Browser checks at 320 px and 375 px show both labels unwrapped and no horizontal overflow.

### P1 — All product information lived on one long homepage — fixed

- Evidence: the approved visual implementation placed philosophy, trust, Joy framing, features, family sharing, privacy, FAQ, and download content in one scrolling document.
- Impact: users could not directly share or revisit a specific topic, and the homepage asked every visitor to move through all product detail in one sequence.
- Fix: the homepage now contains only the core promise, store links, five concise destination cards, and the download panel. Dedicated Japanese and English routes now own philosophy, features, family sharing, privacy architecture, and FAQ content. Header, mobile menu, footer, language switcher, canonical metadata, and alternate-language links all point to the matching route.

### P2 — Mobile destination cards made the new homepage unnecessarily long — fixed

- Evidence: the first multi-page mobile pass kept full screenshots and descriptions in all five destination cards, producing a `5775 px` document and cards up to `642 px` high.
- Impact: the homepage still felt like a content catalogue rather than a calm set of page choices.
- Fix: at phone widths the cards become compact text-led links; supporting screenshots and descriptions remain available on the destination pages. The revised cards are consistently `249 px` high, while the hero and store links retain their full presentation.

### P2 — Page hero grids and Japanese title wrapping were unstable at breakpoints — fixed

- Evidence: the first content-page pass allowed Japanese particles to wrap alone at the 945 px desktop viewport, and a later desktop grid override risked restoring two columns below the mobile breakpoint on the features page.
- Impact: awkward title fragments weakened the editorial tone, while a two-column mobile hero could crowd product screenshots against copy.
- Fix: localized hero titles now use intentional two-line fields, desktop hero columns allocate more room to copy, and explicit mobile overrides force every content-page hero to one column. Browser checks show `scrollWidth = clientWidth` for every Japanese and English route at 375 px and 945 px.

## Store-button refinement comparison history

- Initial finding: missing platform marks and one-column phone stacking were actionable P2 differences from the requested refinement.
- Fix made: added library-sourced Apple/Google Play assets, rebuilt each badge as icon plus two-line copy, and changed the phone breakpoint to a compact two-column grid.
- Post-fix evidence: `docs/qa/store-buttons-reference-comparison.png` places the supplied desktop reference and rendered implementation in one normalized image; `docs/qa/store-buttons-mobile-context.png` confirms the two phone badges remain side by side in the actual hero.
- Normalization: source pixels `966 × 232` (retina capture, normalized to `483 × 116` CSS-sized pixels); desktop implementation pixels `426 × 117` at `deviceScaleFactor = 1`; both were padded to `484 × 118` before the side-by-side comparison. Mobile implementation was checked at a requested `375 × 900` viewport (`360 × 900` content viewport due to browser scrollbar) and captured at `deviceScaleFactor = 1`.
- State: Japanese homepage, light theme, initial hero state. English copy was separately checked at 375 px and did not wrap or overflow.
- Focused comparison was required because icons, copy alignment, and badge spacing are too small to judge reliably in the full homepage view. The mobile context capture supplies the full-view responsive evidence.

## Multi-page comparison history

- Initial finding: the visual system was approved, but the single-page information architecture was no longer acceptable.
- Fix made: preserved the hero, typography, palette, photography, app screenshots, store buttons, radii, and spacing system while moving detailed content into five localized routes and replacing the old second homepage section with destination cards.
- Post-fix evidence: `docs/qa/multipage-home-reference-comparison.png` places the original and multi-page homepage at the same viewport in one image. It shows an unchanged hero treatment and the intentional transition from long-form product proof to page navigation below the fold.
- Normalization: source and implementation are both `930 × 1083` pixels from the same requested `945 × 1100` browser viewport at `deviceScaleFactor = 1`; no scaling or density normalization was required before horizontal stacking.
- State: Japanese homepage, light theme, initial scroll position. Page-level screenshots additionally cover all five Japanese routes, the English features route, and phone layouts.
- Focused comparison: the existing store-button focused comparison remains applicable because that component was preserved. For the new information architecture, separate full viewport captures were more useful than a crop because route identity, navigation state, hero hierarchy, and first-section handoff must be judged together.

## Final comparison assessment

- Layout and spacing: the implementation preserves the approved sequence and two-column hero/proof compositions. It uses a strict grid rather than allowing copy to overlap the photograph, which keeps every section collision-free while retaining the target’s balance.
- Information architecture: the homepage now functions as a clear orientation layer rather than containing every story. Five destination pages have stable localized URLs, matching active navigation, and topic-specific first screens.
- Typography: Mincho-style display type, restrained sans-serif body copy, green eyebrow labels, and sakura emphasis match the approved warm Japanese editorial direction. Japanese and English use separate real copy and maintain clear hierarchy.
- Colors and surfaces: warm paper, near-white cards, deep leaf green, and sakura rose map directly to the selected design and the app palette. Shadows and borders stay quiet and tactile.
- Imagery: the family and still-life assets match the selected subject, lighting, crop, and domestic mood. They contain no text, logos, or financial documents. Product UI evidence uses only first-party iOS Simulator screenshots.
- Screenshot placement: every product screenshot participates in normal document flow with bounded width and `object-fit: contain`; route-card previews are height-bounded without clipping the underlying product capture, and there are no rotated, absolute, or overlapping phone frames.
- Icons: store buttons use library-sourced Apple and Google Play SVG files with consistent white treatment, 28 px desktop size, and 22 px mobile size. No custom SVG, inline SVG, emoji, text-glyph, or CSS-drawn replacement is present.
- Copy and content: spending is framed as everyday support and personal Joy, never shame, competition, or a score. Family sharing boundaries and release status are stated explicitly.
- Responsiveness: checked at requested widths 320, 375, 390, 768, 945, and 1440 px. No horizontal overflow remains. Content-page heroes and detail grids become one-column flows on tablet/mobile, homepage destination cards become compact links on phones, paired store buttons remain side by side, and screenshots never cover text.
- Interaction states: desktop and mobile navigation reach independent routes, active-page indicators update, the language switcher preserves the current page, mobile navigation closes after a route change, FAQ items expand, and both store links expose their intended external destinations.
- Accessibility: semantic landmarks/headings, native details/summary controls, visible link text, image alt text, a skip link, reduced-motion handling, practical mobile tap targets, and default keyboard focus behavior are present.
- Browser console: no errors or warnings in the final local preview.

## Verification

- `hugo --source website --minify`: passed for Japanese and English.
- Japanese/English translation-key parity: 113 / 113 keys.
- `node --check website/assets/js/main.js`: passed.
- `git diff --check -- website`: passed.
- Responsive browser checks: passed with no horizontal overflow; both store rows report two columns at 375 px, all four icons load, and Japanese/English labels remain unwrapped at 320/375 px.
- Multi-page build: Japanese and English each generate home, philosophy, features, family, privacy, and FAQ routes; translation-key parity is 164 / 164.
- Route checks: every Japanese and English content page reports the expected H1, active navigation item, canonical route, alternate-language counterpart, and `scrollWidth = clientWidth` at desktop. All five Japanese routes also pass the 375 px one-column hero check.
- Primary interactions: desktop navigation, mobile navigation, page-preserving language switch, FAQ disclosure, and store buttons verified in the browser.
- Browser console after the store-button refinement: no errors or warnings.
- Final combined reference comparison inspected after the last layout pass.

The App Store listing is not yet live, so the iOS button currently opens a localized App Store search and is accompanied by a release-preparation note. The direct URL remains configurable in `hugo.toml` and should be replaced after App Store Connect assigns the public product page.

final result: passed
