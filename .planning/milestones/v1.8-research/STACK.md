# Stack Research — v1.8 Analytics Page Redesign (Charting & Supporting Libraries)

**Domain:** Local-first, privacy-first Flutter accounting app — analytics/statistics page full redesign (实用化 × 悦己情感化)
**Researched:** 2026-06-15
**Confidence:** HIGH

> Scope: ONLY stack additions/changes for the NEW analytics redesign. The core stack (Flutter, Riverpod 3.x, Freezed, Drift+SQLCipher, GoRouter, flutter_localizations/intl 0.20.2 PINNED, Mocktail) is already validated and out of scope. Charting today: `fl_chart: ^1.2.0` (bar, pie/donut, histogram-via-Stack-workaround).

---

## TL;DR — Headline Findings

1. **fl_chart 2.x does not exist.** Latest published version is **1.2.0** (the project's current pin). The "TOOL-V2-01: fl_chart 1.x→2.x upgrade" backlog item rests on a faulty premise — the real migration it tracked was the historical **0.x→1.x** jump, which the project has **already completed** (it's on 1.2.0). **No charting-library upgrade or swap is needed.** Close TOOL-V2-01 as "already satisfied / N/A" or re-scope it.
2. **The two fl_chart features the redesign wants already shipped in 1.2.0** — per-rod `label` on `BarChartRodData` and `cornerRadius` on `PieChartSectionData`. They are available **right now, no version bump**. The histogram's `Stack`+manually-positioned `DecoratedBox` annotation (the "known per-rod-label API limitation") can be **deleted and replaced with the native `label` property**.
3. **No new charting dependency is recommended.** `graphic`, `syncfusion_flutter_charts`, and `community_charts_flutter` are all worse fits (see comparison). Stay on fl_chart 1.2.0.
4. **For the 悦己 warm/celebratory surfaces: add nothing heavy.** Prefer Flutter's built-in implicit/explicit animations (`AnimatedContainer`, `TweenAnimationBuilder`, `AnimatedSwitcher` — already the app's idiom, see `RecordButton`/HomeHero ring). If a one-shot vector flourish is wanted, `lottie` (asset-only) is the single defensible optional add. **`confetti` is a deliberate maybe-not** — it reads as a gamification reward; gate it behind the design-exploration decision under ADR-012.
5. **Reorderable dashboard cards** need **zero new deps** — Flutter ships `ReorderableListView`/`ReorderableListView.builder`. Sparklines are just a minimal `LineChart` from the fl_chart you already have.
6. **Hard NO list is unchanged and reinforced:** no analytics/telemetry SDK (zero-knowledge app), no `Lottie.network`, no charting lib that phones home, no syncfusion (commercial license), and do not touch the win32-pinned trio (`file_picker`/`package_info_plus`/`share_plus`) or the `intl 0.20.2` pin.

---

## Recommended Stack

### Core Technologies (charting)

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| **fl_chart** | **`^1.2.0` (keep current pin)** | Bar / pie-donut / line / sparkline / histogram for the redesigned analytics page | Already integrated across 3 analytics widgets + goldens; 1.2.0 is the latest version (no 2.x exists); pure-Dart, zero network, MIT-licensed, no telemetry — perfect for a zero-knowledge offline app. The two features the redesign needs (per-rod bar labels, rounded pie sections) landed in exactly this version. Switching libraries would re-baseline all chart goldens for no gain. |

### Supporting Libraries (use what's already in the tree — additions are optional)

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| **Flutter SDK animations** (built-in) | n/a | Warm 悦己 micro-interactions: glow/scale/fade-in on the joy total, count-up amounts, smooth view-switch transitions | DEFAULT for all celebratory-but-not-gamified motion. `TweenAnimationBuilder` for count-up/glow, `AnimatedSwitcher` for view toggles, `AnimatedContainer` for card emphasis. This is already the app idiom (RecordButton 180ms morph, HomeHero ring fill). No dependency, no privacy surface, fully testable. |
| **Flutter SDK `ReorderableListView`** (built-in) | n/a | Customizable dashboard — drag-to-reorder analytics cards | If the redesign chooses user-reorderable cards. No package needed; persist order in `shared_preferences` (already a dep). |
| **fl_chart `LineChart`** (already present) | `^1.2.0` | Sparklines / mini-trend lines inside category drill-down rows | A `LineChart` with axes/grid/titles hidden + `dotData: FlDotData(show:false)` is a sparkline. No new dep. |
| **lottie** (OPTIONAL, design-gated) | `^3.3.x` (verify latest at install) | One-shot vector flourish for a 悦己 moment IF the design exploration calls for richer-than-built-in motion | ONLY if Phase 43 design selection explicitly wants a vector animation built-in tweens can't express. **MUST use `Lottie.asset` only** (bundle the JSON in `assets/`), NEVER `Lottie.network`. Adds ~ a manageable pure-Dart renderer. Treat as last resort, not default. |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| Existing golden-test pipeline | Re-baseline analytics chart goldens after redesign | Goldens are macOS-baselined (MEMORY: golden CI platform gate); re-baseline on macOS only. Expect a large re-baseline regardless of library choice — this is a "全面大改". |
| `flutter analyze` + `custom_lint` + `import_guard` | Same permanent gates | Any chart widget lives in `lib/features/analytics/presentation/widgets/` (Thin Feature); no new layer-violation risk from staying on fl_chart. |

---

## fl_chart: Stay vs Upgrade vs Replace (the central question)

### Verdict: **STAY on `fl_chart ^1.2.0`. Do not upgrade, do not replace.**

**Why upgrade is a non-question:** Verified against pub.dev versions page and the GitHub `CHANGELOG.md` — the version ladder is `… 0.71.0 → 1.0.0 → 1.1.0 → 1.1.1 → 1.2.0`. **There is no 2.0.0 or any 2.x.** 1.2.0 is the newest (published ~3 months before this research). The deferred "TOOL-V2-01 fl_chart 1.x→2.x upgrade" item is mislabeled — the breaking migration that historically existed was `colors→color` / `y→toY` / widget-based `FlTitlesData` (the **0.x→1.x** era, see Alternatives-Considered notes). The current code already uses the 1.x idioms (`toY:`, widget `getTitlesWidget`, `BarChartRodData(color:)`), so that migration is **already done**.

**What 1.2.0 gives the redesign for free (already on disk):**

| 1.2.0 feature | Redesign use | Replaces today's workaround |
|---|---|---|
| `BarChartRodData(label: ...)` — per-rod label on top of each bar | Label the bar(s) directly (e.g. the joy-5 callout, current-month value) | **Deletes** the `Stack` + `Align(Alignment(-0.12,-1))` + `DecoratedBox` hack in `satisfaction_distribution_histogram.dart` (lines 35–139) — the exact "known per-rod-label API limitation" called out in the brief. The manual pixel-aligned annotation is fragile (hardcoded `-0.12` x-offset) and the native API is cleaner + locale-safe. |
| `PieChartSectionData(cornerRadius: ...)` — rounded donut sections | Softer, warmer donut for category distribution | Improves `category_spend_donut_chart.dart` aesthetics with one parameter; no structural change. |
| `LabelDirection` `horizontalMirrored`/`verticalMirrored` | Flexible label placement for drill-down bars | New positioning control for trend/drill-down bars. |

**Migration cost of "upgrading": ZERO** — there is nothing to upgrade to. **Migration cost of adopting the new 1.2.0 APIs already available: LOW** — localized to the histogram (remove Stack workaround → native `label`) and an optional one-line donut polish; both are golden re-baselines you're doing anyway for the redesign.

### Comparison matrix — fl_chart vs alternatives

| Criterion | **fl_chart 1.2.0** (current) | graphic | syncfusion_flutter_charts | community_charts_flutter |
|---|---|---|---|---|
| Latest version | 1.2.0 (active, ~1.5M downloads, 7k+ likes) | actively maintained | actively maintained | community fork of dead google/charts |
| License | **MIT** ✓ | MIT/Apache ✓ | **⚠️ COMMERCIAL — Syncfusion Community/Commercial license required** (free only if <$1M revenue AND <5 devs) | Apache-2.0, but **maintenance-grade fork of an abandoned lib** |
| Network/telemetry | None ✓ | None ✓ | None at runtime, but license-gated commercial product | None, but stale |
| Already integrated | **Yes — 3 widgets + goldens** ✓ | No (full rewrite) | No (full rewrite) | No (full rewrite) |
| Bar/pie/line/sparkline | All present ✓ | Grammar-of-graphics (powerful, steeper) | All + many exotic types | Basic, dated |
| Per-rod bar label | **Yes (1.2.0)** ✓ | Via layered geoms | Yes | Limited |
| Custom warm theming via `AppPalette` | Already wired (`context.palette.*`) ✓ | Possible | Possible | Possible |
| Migration cost from current | **~0 (stay)** | HIGH (rewrite all 3 + goldens) | HIGH + license risk | HIGH + tech-debt risk |
| Fit for this app | **Best** | Overkill | License flag = no | No (stale) |

**Recommendation rationale:** fl_chart 1.2.0 already covers every chart the brief lists (income/expense overview bars, 6-month trend, category donut + drill-down, satisfaction histogram, optional sparklines), is MIT + offline + telemetry-free (mandatory for a zero-knowledge app), and is **already in the codebase with golden coverage**. None of the alternatives clear the bar: `graphic` is a grammar-of-graphics rewrite for power the app doesn't need; `syncfusion_flutter_charts` is a **commercial-licensed** product (auto-FLAG — even under the free Community tier it imposes eligibility constraints + license terms unsuitable to bake into a shipping product without legal review); `community_charts_flutter` is a maintenance fork of Google's abandoned `charts_flutter` (adopting it is signing up for tech debt).

---

## Animation / Micro-interaction stack for 悦己 (warm, celebratory, NOT gamified)

The central design tension (per PROJECT.md / ADR-012): make "为自己花钱而开心" feel emotionally warm **without** crossing into gamification (no badges/streaks/targets-as-achievement/cross-period-delta/leaderboards, structurally locked by `anti_toxicity_*_test` + `home_screen_isolation_test`).

### Recommended: built-in Flutter animations (add nothing)

| Effect | Built-in tool | Why it's the right call |
|---|---|---|
| Count-up of "已花悦己" total | `TweenAnimationBuilder<double>` | Warm, satisfying, value-focused — celebrates the *amount you invested in yourself*, not a score. No dep. Matches existing HomeHero ring fill idiom. |
| Soft glow / scale emphasis on the joy card | `AnimatedContainer` / `AnimatedScale` + `BoxShadow` in `AppPalette` joy tones (sakura/amber) | Color + gentle motion conveys warmth; already the app's visual language (ADR-019 palette). |
| View toggle (trend ⇄ drill-down) | `AnimatedSwitcher` | Smooth, non-jarring; consistent with v1.3 caption-swap pattern. |
| Donut/bar grow-in on first paint | fl_chart built-in `swapAnimationDuration`/`swapAnimationCurve` | fl_chart animates data changes natively — free polish. |

These satisfy "warm and celebratory" while staying **value-affirming, not achievement-rewarding** — the ADR-012-safe framing.

### Optional, design-gated: `lottie` (asset-only)

- **When:** ONLY if Phase 43 design exploration selects a vector flourish (e.g. a gentle sakura-petal drift on opening the joy section) that built-in tweens genuinely can't express.
- **Constraint:** `Lottie.asset` exclusively; JSON bundled in `assets/`. **Never** `Lottie.network` (privacy). Pure-Dart renderer, no telemetry.
- **Treat as last resort.** Adds maintenance + asset weight + a golden-stability question (animated frames).

### AVOID for joy surfaces

| Avoid | Why | Instead |
|---|---|---|
| **`confetti`** (and any burst/reward animation) | Confetti is the canonical *gamification reward* gesture — it reads as "you unlocked something / hit a target." High risk of tripping the spirit (and possibly the letter) of ADR-012's no-achievement constraint. The app's whole differentiator is honest, non-toxic money emotion. | Warm count-up + soft glow (built-in). If a celebratory beat is truly wanted, raise it as an explicit ADR-012 design question in Phase 43 — do not adopt by default. |
| **`flutter_animate`** as a base dependency | Convenient but unnecessary surface for what built-ins already do; encourages scattered ad-hoc flourishes that are hard to keep ADR-012-consistent. | Built-in implicit/explicit animations, centralized. |
| Any animation triggered by **crossing a target / streak / milestone** | Directly violates ADR-012 §2/§5 + ADR-016 §3/§5 (no achievement events, HomeHero isolation). | Animate on *view/data presence*, never on *threshold crossing*. |

---

## Category drill-down / interactive charts / customizable dashboard

| Need | Solution | New dep? |
|---|---|---|
| Tap a donut slice / bar → drill into category | fl_chart `PieTouchData` / `BarTouchData` callbacks (already used for tooltips in current widgets) → drive a Riverpod `selectedCategoryProvider` → re-render sub-view | **No** |
| 6-month trend ⇄ category-composition view switch | `AnimatedSwitcher` over two fl_chart configs + a `SegmentedButton`/chip (existing `TimeWindowChip` pattern) | **No** |
| Sparklines in drill-down rows | Minimal `LineChart` (axes/grid/dots/border hidden) | **No** (fl_chart) |
| Reorderable dashboard cards | `ReorderableListView.builder`; persist order in `shared_preferences` | **No** (both built-in/present) |
| Income/expense + savings-rate overview | fl_chart bars + computed values in domain layer; savings-rate is a derived number, not a new chart type | **No** |

All four drill-down/interactivity needs are satisfiable with the **current dependency set**.

---

## Installation

```yaml
# pubspec.yaml — NO CHANGES required for the core redesign.
# fl_chart stays exactly as-is:
#   fl_chart: ^1.2.0    # already present; latest version; do not bump (no 2.x exists)

# OPTIONAL — only if Phase 43 design selection explicitly requires a vector flourish
# that built-in animations cannot express. Verify latest at install time.
#   lottie: ^3.3.0      # ASSET-ONLY usage; never Lottie.network
```

```bash
# If (and only if) lottie is approved in design exploration:
flutter pub add lottie
# then bundle JSON under assets/ and register in pubspec flutter.assets
```

For the baseline redesign: **`flutter pub get` is unnecessary — no dependency change.**

---

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| Stay on fl_chart 1.2.0 | `graphic` | Only if the app needed true grammar-of-graphics composability (layered geoms, complex statistical transforms). It doesn't — the chart set is standard. Not worth a full rewrite + golden re-baseline. |
| Stay on fl_chart 1.2.0 | `syncfusion_flutter_charts` | Only if you needed exotic chart types (gauges, candle, treemap) AND your org qualifies for the Community license (<$1M revenue, <5 devs) AND you accept baking a commercial-license dependency into a shipping product. **FLAG: commercial license** — recommend legal review before any adoption. Not justified here. |
| Stay on fl_chart 1.2.0 | `community_charts_flutter` | Essentially never — it's a maintenance fork of Google's abandoned `charts_flutter`. Adopting it imports tech debt. |
| Built-in animations | `lottie` (asset-only) | A specific, design-selected vector moment built-in tweens can't render. Asset-only, treat as last resort. |
| Built-in animations | `flutter_animate` | A team preference for declarative chained animations on a large surface. Unnecessary for this scope; risks ADR-012-inconsistent ad-hoc flourishes. |

---

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| **Any analytics/telemetry/crash SDK** (Firebase Analytics, Sentry, Amplitude, Mixpanel, etc.) | **HARD NO.** Zero-knowledge / local-first app — sending any usage or chart-interaction data off-device violates the core privacy guarantee. (Note: `firebase_core`/`firebase_messaging` already present are for P2P-sync push only — do **not** extend into analytics.) | On-device only; never instrument the analytics page. |
| **`syncfusion_flutter_charts`** | Commercial-licensed; eligibility-gated even on the free Community tier; legal/maintenance surface unsuitable for a shipping privacy product | fl_chart 1.2.0 (MIT) |
| **`confetti`** for joy surfaces (by default) | Reads as a gamification reward; ADR-012 risk | Warm count-up + glow (built-in); escalate to a design decision if truly wanted |
| **`Lottie.network`** (if lottie is ever added) | Fetches animation JSON over the network = privacy leak + offline-break | `Lottie.asset` only |
| **Upgrading/replacing fl_chart** | No 2.x exists; replacing costs a full rewrite + golden re-baseline for zero benefit | Keep `^1.2.0`; adopt its already-shipped `label`/`cornerRadius` APIs |
| **Touching the win32-pinned trio** (`file_picker ^11.0.2`, `package_info_plus ^9.0.1`, `share_plus ^12.0.2`) | Bumping any one in isolation breaks `flutter pub get` / iOS native build (CLAUDE.md) — and the redesign has no reason to touch them | Leave untouched |
| **Bumping `intl` off 0.20.2** | Hard-pinned by `flutter_localizations` | Leave at 0.20.2 |
| Heavyweight dashboard/grid packages (e.g. drag-grid layout libs) | Unnecessary weight; built-in `ReorderableListView` covers reorderable cards | `ReorderableListView` + `shared_preferences` |

---

## Stack Patterns by Variant

**If the redesign keeps the current chart set (bar / donut / histogram / + trend + sparkline):**
- Use fl_chart 1.2.0 as-is; adopt `BarChartRodData.label` (kill the histogram Stack hack) + `PieChartSectionData.cornerRadius`.
- Animation = built-in only.

**If the design exploration selects a richer celebratory 悦己 moment:**
- First try `TweenAnimationBuilder` + glow/scale (built-in).
- Escalate to `lottie` (asset-only) **only** if vector art is the chosen direction — and re-confirm it does not encode an achievement/threshold trigger (ADR-012).

**If reorderable/customizable dashboard cards are selected:**
- `ReorderableListView.builder` + persist order in `shared_preferences`. No new dep.

---

## Version Compatibility

| Package | Compatible With | Notes |
|---|---|---|
| `fl_chart 1.2.0` | Flutter ≥ 3.27.4 (1.0.0 raised the floor); current Dart SDK `^3.10.8` | Already satisfied by the project's environment. Pure-Dart; no native pods → no iOS Podfile interaction (unlike the sqlite/win32 constraints). |
| `lottie ^3.3.x` (if added) | Current Flutter/Dart | Pure-Dart renderer; no native pods. Adds asset weight only. Verify exact latest at install. |
| `intl 0.20.2` (PINNED) | `flutter_localizations` | Unaffected by any charting work. Do not bump. |
| win32 trio (PINNED) | each other | Unaffected by charting work. Do not touch. |

---

## Sources

- pub.dev `fl_chart` package page + versions page — **verified: latest is 1.2.0; no 2.x exists** (HIGH)
  - https://pub.dev/packages/fl_chart
  - https://pub.dev/packages/fl_chart/versions
- GitHub `imaNNeo/fl_chart` CHANGELOG.md — 1.0.0/1.1.0/1.2.0 changes; 1.0.0 Flutter ≥3.27.4 floor; `tooltipRoundedRadius`→`tooltipBorderRadius` (the only 1.0.0 breaking change) (HIGH)
  - https://github.com/imaNNeo/fl_chart/blob/main/CHANGELOG.md
- pub.dev `fl_chart` 1.2.0 changelog — **`BarChartRodData.label` (per-rod label) + `PieChartSectionData.cornerRadius` confirmed shipped in 1.2.0** (HIGH)
  - https://pub.dev/packages/fl_chart/versions/1.2.0/changelog
- pub.dev `syncfusion_flutter_charts` license — **commercial / Community-license-gated (<$1M revenue, <5 devs)** (HIGH)
  - https://pub.dev/packages/syncfusion_flutter_charts/license
- pub.dev `lottie` — asset/network/memory constructors; `Lottie.asset` for offline (HIGH)
  - https://pub.dev/packages/lottie
- Project files read: `pubspec.yaml` (current `fl_chart ^1.2.0` + win32 trio + intl pin), `CLAUDE.md` (pins/iOS constraints), `.planning/PROJECT.md` (TOOL-V2-01 deferral, ADR-012 constraints, v1.8 goal), and the three current analytics widgets — confirmed histogram uses a `Stack`+`DecoratedBox` per-rod-label workaround that 1.2.0's `label` API obsoletes (HIGH)
- Note on a stale web result: a WebSearch surfaced "fl_chart 2.0 migration: colors→color, y→toY, widget-based FlTitlesData" — these are the **0.x→1.x-era** breaking changes mislabeled as "2.0"; the project's code already uses the 1.x idioms, confirming that migration is complete. (corrected via primary sources above)

---
*Stack research for: v1.8 analytics page redesign — charting & supporting libraries*
*Researched: 2026-06-15*
