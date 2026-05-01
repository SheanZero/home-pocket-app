# Stack Research

**Domain:** Flutter app — happiness metric domain + Riverpod/Drift/fl_chart wiring (v1.1 milestone)
**Researched:** 2026-05-01
**Confidence:** HIGH — versions verified against pub.dev (May 2026); existing pubspec.yaml inspected; fl_chart 0.69 → 1.x changelog reviewed; intl/Drift/Riverpod feature surface already in active use in v1.0.

---

## TL;DR (read this first)

**The recommendation for v1.1 is: add NOTHING.**

Every capability v1.1 needs is already in the project's locked stack. The schema is frozen, the chart library is already wired, the formatting helpers exist, and the math (means, ratios, counts, max-by) is plain Dart `Iterable` work over a `List<TransactionRow>`. Introducing any new dependency at this milestone would buy zero capability and add review surface, lockfile churn, and CI guardrail risk.

The only stack-level **change** worth considering is an optional fl_chart minor question (do we stay on `^0.69.0` or upgrade to `1.1.1`?), and the answer is **stay on 0.69 for v1.1** — see "fl_chart upgrade decision" below.

This file therefore reads more like a **"do not add"** rationale than a recommendations list. That is intentional and matches the milestone's locked scope.

---

## Context: What Is Already Installed (relevant to v1.1)

From `pubspec.yaml` (verified 2026-05-01):

| Locked Dependency | Version | Used by v1.1 for |
|-------------------|---------|-------------------|
| `flutter_riverpod` | `^2.6.1` | Provider wiring for new use cases (HappinessMetricsProvider, family-metrics provider) |
| `riverpod_annotation` | `^2.6.1` | `@riverpod` code-gen on the new providers |
| `freezed_annotation` | `^3.0.0` | Immutable result models (`HappinessMetrics`, `FamilyHappinessMetrics`, `BestJoyHighlight`) |
| `json_annotation` | `^4.9.0` | Optional — only if metric models need serialization (likely NOT for v1.1; pure in-memory) |
| `drift` | `^2.25.0` | The 3 dormant DAO methods already exist; they return existing column projections |
| `sqlcipher_flutter_libs` | `^0.6.7` | Encrypted DB — unchanged; v1.1 does NO schema work |
| `fl_chart` | `^0.69.0` | Joy-per-¥ trend line + satisfaction distribution histogram (both BarChart/LineChart — already supported) |
| `intl` | `0.20.2` (pinned) | `NumberFormat` for Joy/¥ ratio rendering; already pinned by `flutter_localizations` |
| `flutter_localizations` | sdk | ARB-based ja/zh/en rename pass for `soulLedger`/`survivalLedger`/`homeHappinessROI`/`homeSoulFullness` |
| `collection` | `^1.19.1` | `IterableExtension` (`maxBy`, `groupBy`) — needed for "Best Joy per ¥" highlight pick and family `category × avg satisfaction` aggregation |

Dev-side, already locked: `mocktail ^1.0.4` for tests, `build_runner ^2.4.14` + `freezed ^3.0.0` + `riverpod_generator ^2.6.4` + `drift_dev ^2.25.0` + `json_serializable ^6.9.4` for code-gen, `custom_lint ^0.7.5` + `riverpod_lint ^2.6.4` + `import_guard_custom_lint ^1.0.0` + `dart_code_linter ^3.0.0` for the v1.0 guardrails (still active).

**Implication:** every layer of v1.1 (compute → store-access → expose-as-provider → consume-in-widget → render-as-chart → localize) maps to an already-installed package.

---

## Recommended Stack by v1.1 Capability

For each new v1.1 deliverable, this section names the existing technology that handles it and explicitly states "no addition required."

### Capability 1 — Compute the 4 personal happiness indicators

**Inputs:** A `List<TransactionRow>` filtered to `ledger_type='soul'` over month-to-date, with `soul_satisfaction` (1-10 int) and `amount_sub_unit` (int, JPY=yen, others=cents).

**Operations needed:**
- `avgSatisfaction = mean(soul_satisfaction)` — reduce/`average` on a `List<int>`
- `joyPerYen = Σ soul_satisfaction / Σ amount_sub_unit` (with safe div by zero) — single fold
- `highlightsCount = count where soul_satisfaction >= 8` — `where(...).length`
- `bestJoyPerYen = transaction with max(soul_satisfaction / amount_sub_unit)` — `collection.IterableExtension.maxBy`

**Stack assignment:** Pure Dart + `package:collection` (already installed).
**No addition.** A "statistics helper" library would be net-negative — the code is 4-6 expressions of plain Dart, and pulling a stats package would obscure the math behind a learning curve no one needs.

### Capability 2 — Compute the 2 family cooperative indicators

**Family Highlights Sum:** Same `where(satisfaction >= 8).length`, but over the merged `shadow_books` join (already exposed by existing `getSoulSatisfactionOverview` once filtered).

**Shared Joy Insight (`category × avg satisfaction`):** `groupBy(category)` → `mapValues(average)` → `entries.sortedBy(.value).last` (or top-N for storytelling).

**Stack assignment:** `package:collection`'s `groupBy` + Dart `Iterable.average` (extension on `Iterable<num>` from `package:collection`).
**No addition.** `groupBy` and `IterableExtension.average` already cover this idiom. If we ever want SQL-side aggregation later, Drift handles it via `selectOnly()` with `avg()` and `groupBy()` — but the existing dormant DAO methods are what v1.1 uses, so this is moot for now.

### Capability 3 — Render Joy-per-¥ trend line

**fl_chart `LineChart`** with one `LineChartBarData` series, x = day index of month, y = daily Joy/¥. Both v0.69 and v1.x support this with identical surface; the existing AnalyticsScreen already uses `LineChart` for expense trends (see `features/analytics/presentation/widgets/`).

**Stack assignment:** `fl_chart: ^0.69.0` (existing).
**No addition.** No combo-chart need (joy line is its own chart, separate from histogram), so the open issue [imaNNeo/fl_chart#1140 (line on bar chart)](https://github.com/imaNNeo/fl_chart/issues/1140) does not block us.

### Capability 4 — Render satisfaction distribution histogram

A histogram in fl_chart is a `BarChart` with one `BarChartGroupData` per bin (here: 10 bars for satisfaction 1-10), each holding a `BarChartRodData` whose `toY` is the bin count. There is no dedicated `HistogramChart` widget in fl_chart — there doesn't need to be; this is the standard fl_chart histogram recipe used widely in the community.

**Stack assignment:** `fl_chart: ^0.69.0` (existing).
**No addition.** Histograms are a UI-side reshape of `Map<int, int>` → `List<BarChartGroupData>`; no new library.

### Capability 5 — Format "Joy per ¥" ratio for display

The ratio is small and fractional (e.g., `8.4 satisfaction-points / 12,500 yen ≈ 0.000672`). The display target is something like `0.67 / 100¥` or `6.72 / ¥1000` — i.e., we scale to a readable denominator and use `NumberFormat` for the locale-aware decimal separator.

**Stack assignment:** `intl: 0.20.2` (already pinned by `flutter_localizations`) via the existing `lib/infrastructure/i18n/formatters/number_formatter.dart`.

The existing `NumberFormatter` already handles `JPY 0-decimal` and `USD/CNY/EUR/GBP 2-decimal` per CLAUDE.md. v1.1 adds **one new method** to it (e.g., `formatJoyDensity(double ratio, Locale locale)`) that picks the per-locale "Joy / ¥1000" or "Joy / $10" framing. **No new package** — `intl.NumberFormat` covers fixed-decimal, percent, and arbitrary-pattern formatting natively.

**No addition.** Specifically, we do **not** need `decimal: ^4.x`. See "What NOT to add" below for the reasoning.

### Capability 6 — Wire metric computation into the Riverpod graph

New providers (`@riverpod`-annotated) for `personalHappinessMetrics(monthStart)`, `familyHappinessMetrics(monthStart, groupId)`, `joyDensityTrend(monthStart)`, `satisfactionHistogram(monthStart)`. Each composes on top of the dormant DAO methods.

**Stack assignment:** `riverpod_annotation` + `riverpod_generator` (both already installed). The existing `repository_providers.dart`-per-feature convention applies — all four new providers live in `lib/features/{home,analytics}/presentation/providers/` (as use-case providers, per CLAUDE.md). The use case classes themselves live in `lib/application/analytics/` (or a new `lib/application/happiness/` directory if the surface justifies the split — that's a design decision for ARCHITECTURE.md, not stack).

**No addition.**

### Capability 7 — UI rename pass

ARB-only changes to `lib/l10n/app_{ja,zh,en}.arb`, then `flutter gen-l10n`. Keys: `soulLedger`, `survivalLedger`, `homeHappinessROI`, `homeSoulFullness` (4 keys × 3 locales = 12 string changes). Enum names (`LedgerType.survival`, `LedgerType.soul`) and theme colors are explicitly locked to NOT change.

**Stack assignment:** `flutter_localizations` + `intl` (existing pipeline).
**No addition.**

---

## fl_chart upgrade decision: stay on 0.69.0 for v1.1

**Available:** `fl_chart: 1.1.1` (latest on pub.dev as of 2026-02-04).

**Breaking changes between 0.69 and 1.1.1** (verified against [pub.dev/packages/fl_chart/changelog](https://pub.dev/packages/fl_chart/changelog)):
- v1.0.0: removed deprecated `tooltipRoundedRadius` (use `tooltipBorderRadius`); minimum Flutter bumped to 3.27.4; `BarChart` is no longer `const`.
- v1.0.0: introduced `CandlestickChart` (irrelevant to v1.1).
- v1.1.0: `borderSide` in `BarChartRodStackItem` constructor changed from positional to named.
- Various rendering/gradient improvements.

**Decision: stay on `^0.69.0` for v1.1.**

**Rationale:**
1. **Zero new capability needed.** Joy-per-¥ trend line and satisfaction histogram are vanilla LineChart/BarChart calls — both have been stable across the 0.69→1.x range. The new features in 1.x (CandlestickChart, BarChartRodStackItem labels/gradients, sideTitleAlignment) are not on v1.1's deliverable list.
2. **Existing AnalyticsScreen is already on 0.69.** Upgrading the dep would force a sweep of all existing chart call sites (expense trend chart, budget progress chart, etc.) for the `tooltipRoundedRadius` rename and `BarChart` const-removal; that's incidental migration work that grows v1.1 scope outside its goal.
3. **Flutter SDK floor.** 1.0.0 raised the minimum Flutter to 3.27.4. The project's `environment: sdk: ^3.10.8` (Dart) corresponds to a Flutter version that is fine here, but the version-bump rationale is "we want the new chart" — and we don't.
4. **Upgrade defer is safe.** When a future milestone (e.g., a redesign or a new chart type like a candlestick / radar / box-plot) actually needs 1.x features, that milestone owns the migration — it's a well-bounded change with a clear changelog.

**Recommendation:** create a deferred-tech entry (`FUTURE-TOOL-fl_chart-1x`) in PROJECT.md if it doesn't already exist, so the upgrade question is tracked but not v1.1-blocking.

---

## What NOT to Add

This section is the bulk of the recommendation. Each row names a real package the assistant might be tempted to suggest, and the reason it must not enter v1.1.

| Avoid | Why It's Tempting | Why It's Wrong For v1.1 | Use Instead |
|-------|-------------------|--------------------------|-------------|
| `decimal: ^4.x` | "Joy / ¥ is a financial ratio; doubles lose precision." | The ratio is **never compared for equality** and **never persisted as a precise value** — it's computed on-the-fly for display only. Floating-point error in the 16th decimal does not change the rendered "0.67 / 100¥". Adding `decimal` would force every aggregation through `Decimal.parse(...)` and pollute use-case signatures with a non-Dart-core type. | Use plain `double` math; round at the display boundary via `NumberFormat`. |
| `equatable: ^2.x` | "We're adding new immutable models; equatable simplifies `==`/`hashCode`." | The project standardized on **Freezed** for immutability (CLAUDE.md "Models: Freezed with `@freezed` for immutability"). Freezed generates `==`/`hashCode`/`copyWith`/`toString` and is already in the dev-deps. Mixing `equatable` and Freezed creates two equality conventions in the same codebase and would break the `import_guard` / arch-test mental model. | `@freezed` with `freezed: ^3.0.0` (already installed). |
| `meta: ^1.x` (explicit add) | "Tag use cases as `@immutable`." | `meta` already comes transitively via Flutter SDK; an explicit pin is unnecessary. Freezed-generated classes are structurally immutable without needing the annotation. | Don't add. Use Freezed's generated `@immutable` propagation. |
| `dartx: ^1.x` / `darq: ^x.y` (LINQ-style) | "We need `groupBy`, `maxBy`, `average` for the family aggregation." | `package:collection` already provides `groupBy` (top-level function) and `IterableExtension.maxBy` / `IterableExtension.average`. It is already in `pubspec.yaml` at `^1.19.1`. Pulling a second collection-extensions package creates two competing idioms in the codebase. | `package:collection` (already installed). |
| `statistical: ^x.y` / `stats: ^x.y` / `simple_stats` (or any "stats helper") | "We're computing means, distributions, percentiles." | The v1.1 stat ops are: 1 mean, 1 ratio, 1 count-where, 1 max-by, 1 group-and-average. Total: ~12 lines of plain Dart. Any third-party stats package is heavier than the code it would replace, and pub.dev's stats packages are mostly low-traffic / single-maintainer — adding one would expand the supply-chain surface for negative net code reduction. | Plain Dart `Iterable` ops + `package:collection`. |
| `syncfusion_flutter_charts` (commercial chart lib) | "Has a dedicated `HistogramChart` widget; might be cleaner than building histogram from BarChart." | (1) Commercial license model conflicts with the project's open posture. (2) fl_chart is already wired into AnalyticsScreen — adopting Syncfusion would require a cross-codebase chart migration outside v1.1 scope. (3) "Dedicated histogram widget" is cosmetic; fl_chart's BarChart-as-histogram is a 30-line render function. | `fl_chart` BarChart for histogram. |
| `charts_flutter` (Google) | "Official-looking alternative to fl_chart." | Discontinued / unmaintained; pub.dev score has decayed. fl_chart is the de-facto Flutter chart library in 2026 and is what the project already uses. Switching would be a net regression. | `fl_chart` (existing). |
| `riverpod: 3.x` | "Latest major version; cleaner API." | Per PROJECT.md (Out of Scope, "Riverpod 3.x upgrade"): `analyzer` version conflict with `json_serializable` (deferred to FUTURE-TOOL-01). v1.1 must NOT touch this. | `flutter_riverpod ^2.6.1` (existing). |
| `sqlite3_flutter_libs` | "Smaller alternative to sqlcipher." | Actively rejected by a permanent CI guardrail (CLAUDE.md pitfall #6, AUDIT-09). Conflicts with SQLCipher. **Do not even mention this in PRs.** | `sqlcipher_flutter_libs ^0.6.7` (existing). |
| `intl_utils` / `intl_translation` | "Useful for ARB management." | The project uses `flutter_localizations` + `flutter gen-l10n` (`l10n.yaml` config, output class `S`, dir `lib/generated`). Adding a parallel ARB pipeline is destructive. | Existing `flutter gen-l10n` flow. |
| `pretty_charts` / `mp_chart` / `flutter_echarts` | "Eye-candy alternatives." | Same reasons as Syncfusion — cosmetic upside, real migration cost, outside v1.1 scope. | `fl_chart` (existing). |
| `tuple: ^x.y` | "Returning multi-value results from use cases." | Use Freezed records (`@freezed` data class) for any multi-value returns. Idiomatic Dart 3+ also has built-in record types `(double, int)` for ad-hoc cases. | Freezed model OR Dart 3 records. |

---

## Alternatives Considered (and rejected) for new computation patterns

| If we wanted to do… | Could use… | We are choosing… | Because |
|----------------------|------------|-------------------|---------|
| Aggregate metrics in SQL (vs. in-Dart fold) | Drift `selectOnly` + `avg()` + `groupBy()` (we already have this in dormant DAO methods) | **In-Dart fold over the existing dormant-DAO row stream** | The dormant DAO methods already exist and are what the milestone says to wire up. SQL-side aggregation is a future optimization if the ~100-row per-month soul-ledger working set ever becomes a bottleneck (it won't for the foreseeable user count). |
| Cache metric results | `riverpod`'s `keepAlive` + manual invalidation, or a memoization helper | **Compute fresh on `ref.watch` (no cache)** | Soul ledger entries change on every transaction; cache invalidation is its own bug class. The compute is O(n) over <1000 rows. Riverpod's recompute-on-dependency-change is the right primitive. |
| Render histogram with smoothing/density curve | `fl_chart` `LineChart` overlaid on `BarChart` (combo chart) | **Plain `BarChart` histogram** | Combo charts are blocked in fl_chart 0.69 (and partially in 1.x — see issue #1140). v1.1 spec is a histogram, not a density estimate. Don't escalate scope. |

---

## Version Compatibility (for the locked stack v1.1 leaves alone)

| Package | Compatible With | Notes |
|---------|------------------|-------|
| `intl: 0.20.2` | `flutter_localizations` (sdk) | EXACT pin required (CLAUDE.md pitfall #5). Any change here is a migration project, not a v1.1 task. |
| `sqlcipher_flutter_libs: ^0.6.7` | `sqlite3: ^2.7.5`, `drift: ^2.25.0` | Stable triple — do not touch. CI guardrail rejects `sqlite3_flutter_libs`. |
| `fl_chart: ^0.69.0` | Flutter SDK ≥ 3.10 | Compatible with current Dart `sdk: ^3.10.8`. Upgrading to 1.x raises the floor — see "fl_chart upgrade decision". |
| `flutter_riverpod: ^2.6.1` + `riverpod_annotation: ^2.6.1` + `riverpod_generator: ^2.6.4` + `riverpod_lint: ^2.6.4` | All four pinned to the 2.6.x line | These four versions move together. Riverpod 3.x is blocked (FUTURE-TOOL-01). |
| `freezed: ^3.0.0` + `freezed_annotation: ^3.0.0` + `json_annotation: ^4.9.0` + `json_serializable: ^6.9.4` | Mutually compatible | Code-gen pipeline; do not touch in v1.1. |
| `mocktail: ^1.0.4` | Test-only | Mockito was removed in v1.0 (HIGH-07). Do not reintroduce mockito. |

---

## Installation

**No `pub add` commands. No `pubspec.yaml` edits.** v1.1 is a pure feature-build on the existing locked dep set.

```bash
# After ARB key changes (capability 7), regenerate localizations
flutter gen-l10n

# After adding @freezed / @riverpod-annotated classes (capabilities 1, 2, 6),
# regenerate code (already CI-enforced via build_runner clean-diff guardrail)
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## Stack Patterns by v1.1 Scenario

**If the family-cooperative aggregation turns out to need SQL-side `groupBy(category)`:**
- Add a 4th DAO method (`getCategoryAvgSatisfaction`) using Drift's `selectOnly()` + `avg()` + `groupBy()`.
- This stays inside the locked stack — no new packages.
- Stretch consideration only; for v1.1 the in-Dart `groupBy` from `package:collection` is sufficient at expected data volumes.

**If the histogram needs to be interactive (tap a bar to filter the transaction list):**
- fl_chart 0.69 supports `barTouchData` with a callback already.
- No new package; this is a UI wiring detail, not a stack decision.

**If the "Best Joy per ¥" highlight needs a story-mode card (image, transition):**
- Use existing Flutter `Hero` / `AnimatedSwitcher` widgets.
- No new animation package (no `flutter_animate`, no `rive`).

---

## Sources

- `pubspec.yaml` (read 2026-05-01) — verified all currently-locked dependencies and dev-dependencies.
- `CLAUDE.md` — verified project's stack constraints, pitfalls, and i18n/Drift/crypto rules. HIGH confidence.
- `.planning/PROJECT.md` (read 2026-05-01) — verified v1.1 milestone scope, locked constraints, and out-of-scope items.
- [pub.dev/packages/fl_chart](https://pub.dev/packages/fl_chart) — verified latest version is 1.1.1 (analyzed 2026-02-04). HIGH confidence.
- [pub.dev/packages/fl_chart/changelog](https://pub.dev/packages/fl_chart/changelog) — verified breaking changes between 0.69 and 1.1.1 (tooltipRoundedRadius removal, Flutter ≥3.27.4, BarChart non-const, BarChartRodStackItem.borderSide named param). HIGH confidence.
- [imaNNeo/fl_chart#1140](https://github.com/imaNNeo/fl_chart/issues/1140) — confirmed combo-chart (line-over-bars) is still a feature request, not a built-in. Not blocking for v1.1 since trend and histogram are separate widgets. MEDIUM confidence.
- [pub.dev/packages/decimal](https://pub.dev/packages/decimal) — confirmed `decimal` is the standard precision package; rejected for v1.1 because the Joy/¥ ratio is display-only and never compared/persisted with precision sensitivity. HIGH confidence.
- [pub.dev/packages/intl - NumberFormat](https://pub.dev/documentation/intl/latest/intl/NumberFormat-class.html) — confirmed `NumberFormat` covers fixed-decimal, percent, and pattern formatting locale-aware. HIGH confidence.
- `package:collection` ^1.19.1 (already in pubspec) — `groupBy` (top-level function) and `IterableExtension` (`maxBy`, `average`) are part of its standard surface as of 1.18+. HIGH confidence.

---

*Stack research for: v1.1 Happiness Metric & Display milestone — Flutter / Dart / Riverpod / Drift+SQLCipher / fl_chart*
*Researched: 2026-05-01*
