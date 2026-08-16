# Happy Pocket website

The official Happy Pocket marketing site is a dependency-free, multi-page Hugo project with native Japanese, Simplified Chinese, and English routes at `https://happypocket.app/`.

## Local preview

```bash
hugo server --source website --disableFastRender
```

Open the local URL printed by Hugo. Japanese uses the root routes, Simplified Chinese uses `/zh/`, and English uses `/en/`.

## Production build

```bash
hugo --source website --minify
```

The generated static site is written to `website/public/` by default. Product screens under `website/static/images/` are first-party captures from the iOS Simulator, with separate Japanese and English variants; refresh those captures when the app UI changes materially. The family and still-life photographs are generated project assets with no embedded copy, logos, or financial documents.

The App Store and Google Play destinations are configured in `[params]` inside `website/hugo.toml`. The iOS button points to the official Happy Pocket product page; the localized release-status note remains visible while the Android listing is being prepared. Marketing, privacy, legal, and support metadata use root routes for Japanese and matching `/zh/` and `/en/` routes for the other languages.

For the private Sites preview, Hugo output is staged under `website/dist/client/` and the minimal worker in `website/worker/index.js` serves those static files. This hosting adapter does not replace Hugo or add an application runtime to the site.

## Structure

- `content/ja/`, `content/zh/`, and `content/en/` contain the localized home, philosophy, features, family, privacy, roadmap, terms, Tokusho, FAQ, and support pages.
- `i18n/` contains the shared interface and component copy.
- `layouts/` contains the Hugo templates and partials.
- `assets/css/main.css` contains the responsive visual system.
- `static/images/` contains the first-party product imagery used by the site.
- `docs/SITE_RESEARCH.md` records the market-structure research and resulting information architecture.
