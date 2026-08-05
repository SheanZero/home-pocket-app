# Home Pocket bilingual introduction kit

This directory contains Japanese and English product-introduction copy plus matching feature visuals.

## Deliverables

| Locale | Introduction document | Feature visuals |
|---|---|---|
| Japanese | [`ja/app-introduction.md`](ja/app-introduction.md) | [`images/ja/`](images/ja/) |
| English | [`en/app-introduction.md`](en/app-introduction.md) | [`images/en/`](images/en/) |

Each language includes five 1600 × 1000 PNG visuals:

1. Daily / Joy dual ledger
2. Monthly trends and category reflection
3. Satisfaction and Joy reflection
4. Family sharing and privacy
5. Shopping lists and multiple currencies

## Intended use

These are product-introduction visuals for a website, press kit, social preview, internal review, or presentation. They combine verified project artwork and tested UI component goldens with deterministic marketing copy.

They are **not final App Store device screenshots**. Flutter golden files use a test font, so the visuals preserve their charts and interface structure while keeping the explanatory copy outside the UI. Before App Store submission, capture clean screenshots from a signed Release build and follow [`../screenshots/README.md`](../screenshots/README.md).

## Rebuild

The outputs are deterministic and can be rebuilt with Pillow:

```bash
python3 publish/ios/intro/scripts/build_intro_assets.py
```

The script also writes [`manifest.json`](manifest.json), including dimensions, SHA-256 checksums, localized copy, and source files.

## Content guardrails

- Product terms follow ADR-015 and ADR-016: Japanese uses 「ときめき」 and English uses “Joy”.
- The current Joy expression is cumulative Joy contribution; the kit does not use Joy-per-yen, density, ROI, streaks, or celebration claims.
- Privacy copy says shared content is encrypted on device and delivered through a zero-knowledge relay. It does not claim that no data leaves the device.
- Private ledgers and private shopping items are described as outside the family-sharing flow.
