# Phase 45: 展示外壳重建 (Presentation Shell Rebuild) - Research

**Researched:** 2026-06-17
**Domain:** Flutter presentation-layer structural refactor (Riverpod 3, behavior-preserving widget extraction + registry-driven invalidation)
**Confidence:** HIGH (entire phase is code-grounded against the live repo; no external packages, no network research needed)

## Summary

Phase 45 is a **pure structural, behavior-preserving refactor** of one 739-LOC file (`lib/features/analytics/presentation/screens/analytics_screen.dart`). The file today is a `ConsumerWidget` shell (`AnalyticsScreen`) holding: the AppBar + `TimeWindowChip` + `JoyMetricVariantChip`, a `RefreshIndicator` → `SingleChildScrollView` → `Column` body built inline, a hand-written ~108-line `_refresh()` that invalidates 13 providers (10 unconditional + 3 conditional under `isGroupMode`), and **7 inline private `_*Card` ConsumerWidgets** plus one shared `_AnalyticsDataCard` (StatelessWidget title/caption shell). Each inline card already satisfies the target contract — it is a `ConsumerWidget`, watches exactly one provider family keyed on a subset of `(bookId, startDate, endDate, joyMetricVariant, currencyCode, anchor)`, does a local `.when(data/loading/error)`, and the error branch already calls `ref.invalidate(sameProvider)`. The real work is **move-to-file + build a registry + derive `_refresh()` from it**, NOT rewrite card logic.

The decisive structural fact for the planner: each `cards/*.dart` will import only analytics providers + analytics leaf widgets. That import-graph isolation is the *physical* source of "the registry structurally cannot contain `home/*` providers" (D-B3). The new D-B3 unit test promotes today's implicit guarantee (comment on line 222 + the indirect `home_screen_isolation_test`) into a direct assertion: the registry-derived invalidation union ⊆ analytics providers, contains 0 `home/*` providers.

**Primary recommendation:** Use the **`List<AnalyticsCardSpec>` data-entry registry** (builder + `refreshTargets(ctx)` + `isVisible(ctx)` closures) over an abstract-base class, keep cards as dumb `ConsumerWidget`s, and use **`SingleChildScrollView` + `Column` built by mapping the registry** (NOT `ListView.builder`) so the section-header IA and conditional cards stay trivially behavior-identical. Make each card's watched-provider set and its `refreshTargets` come from **one shared source** (a top-level `…RefreshTargets(ctx)` function the card's error-retry also calls) so build / refresh / retry cannot drift. The golden suite has **no screen-level golden** — only leaf-widget goldens (daily_vs_joy, per_category, home_hero) — so a mechanical extraction that preserves the widget tree keeps every golden green by construction.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| AppBar + time/joy chips + scroll container | Presentation (feature shell) | — | Pure layout; `AnalyticsScreen` stays the shell |
| Per-card data fetch + `.when` render | Presentation (feature `widgets/cards/`) | Application (use cases via providers) | Each card is a `ConsumerWidget` watching ONE analytics provider family |
| Card layout order + visibility | Presentation (registry) | — | D-B1: registry is the single source of render order + refresh union |
| Pull-to-refresh invalidation | Presentation (`_refresh` derived from registry) | — | D-B2: `registry.where(isVisible).expand(refreshTargets)` |
| Provider definitions (auto-dispose, keyed) | Presentation providers (`state_*`) | Application/Data (use cases, repos) | Unchanged this phase — Phase 44 locked them |
| HomeHero isolation guarantee | Presentation (import graph + D-B3 test) | — | `cards/*` import only analytics providers → home/* impossible in union |

## Standard Stack

No new packages. This phase touches only existing project dependencies. All claims `[VERIFIED: repo grep + file read]`.

### Core (already in pubspec, unchanged)
| Library | Version (pinned) | Purpose | Why Standard |
|---------|------------------|---------|--------------|
| `flutter_riverpod` | 3.x (project convention) | `ConsumerWidget`, `ref.watch`, `ref.invalidate`, `AsyncValue.when` | Project's mandated state layer (CLAUDE.md Riverpod 3 conventions) |
| `riverpod_annotation` / `riverpod_generator` | gen 4.x | `@riverpod` codegen for the analytics provider families | Existing `state_analytics.dart` / `state_happiness.dart` / `state_ledger_snapshot.dart` are all generated |
| `flutter_localizations` + generated `S` | intl 0.20.2 (pinned) | All card titles/captions via `S.of(context)` | CLAUDE.md i18n rule; cards already use it |

**Installation:** none. `flutter pub get` only if a merge changed pubspec. Run `flutter pub run build_runner build --delete-conflicting-outputs` only if any `@riverpod`/`@freezed` annotation changes — **this phase should add zero new annotated providers** (it consumes existing ones), so build_runner is a no-op unless the registry introduces a generated provider (not recommended — see Pattern 1).

## Package Legitimacy Audit

> Not applicable. Phase 45 installs **zero** external packages — it is a within-file structural refactor consuming the project's already-vendored dependencies. No registry verification needed.

**Packages removed due to SLOP verdict:** none
**Packages flagged as suspicious:** none

## Architecture Patterns

### System Architecture Diagram

```
                       AnalyticsScreen (thin shell, ConsumerWidget)
                                  │
          ┌───────────────────────┼────────────────────────────┐
          │ build()               │ _refresh() (pull-to-refresh)│
          ▼                       ▼                             │
   reads ctx providers     buildAnalyticsCardContext(ref,ctx)   │
   (selectedTimeWindow,          │                              │
    selectedJoyMetricVariant,    ▼                              │
    bookById.currency,    ┌──────────────────────────┐          │
    isGroupMode, ...)     │  analyticsCardRegistry    │◄─────────┘
          │               │  List<AnalyticsCardSpec>  │  (SINGLE SOURCE — D-B1)
          ▼               └──────────────────────────┘
   registry                      │            │
   .where(isVisible)             │ build      │ refreshTargets(ctx)
   .map(buildSectioned)          ▼            ▼
          │             cards/<x>_card.dart   ref.invalidate(each)
          ▼             (ConsumerWidget,      (union over visible cards;
   SingleChildScrollView  watches ONE          structurally ⊆ analytics,
   + Column (+ section     provider family,    0 home/* — D-B3 test asserts)
   headers, behavior       local .when,
   identical to today)     retry == refreshTargets)
                                  │
                                  ▼
                  analytics providers (state_analytics /
                  state_happiness / state_ledger_snapshot)
                  — ALL auto-dispose, ZERO home/* sharing
```

Data flow to trace the primary use case (pull-to-refresh in group mode): `RefreshIndicator.onRefresh` → `_refresh(ref)` builds `ctx` from the same providers `build()` reads → `registry.where((c)=>c.isVisible(ctx)).expand((c)=>c.refreshTargets(ctx))` → `ref.invalidate(each)`. Because the registry only ever references analytics provider families, the union physically cannot include a `home/*` provider.

### Recommended Project Structure

```
lib/features/analytics/presentation/
├── screens/
│   └── analytics_screen.dart        # SHELL ONLY (~120-160 LOC): AppBar+chips,
│                                     #   RefreshIndicator+scroll, maps registry,
│                                     #   _refresh() derives union from registry
├── analytics_card_registry.dart     # NEW: List<AnalyticsCardSpec> + AnalyticsCardContext
│                                     #   + buildAnalyticsCardContext(ref) helper
└── widgets/
    ├── cards/                        # NEW dir
    │   ├── analytics_data_card.dart  # _AnalyticsDataCard promoted (shared shell)
    │   ├── kpi_hero_card.dart        # _KpiHero -> KpiHeroCard
    │   ├── total_six_month_card.dart # _TotalSixMonthCard -> TotalSixMonthCard
    │   ├── category_donut_card.dart  # _CategoryDonutCard -> CategoryDonutCard
    │   ├── satisfaction_histogram_card.dart   # _SatisfactionHistogramOrFallback
    │   ├── largest_expense_card.dart # _LargestExpenseCard -> LargestExpenseCard
    │   ├── best_joy_card.dart        # _BestJoyCard -> BestJoyCard
    │   └── family_insight_data_card.dart      # _FamilyCard -> FamilyInsightDataCard
    └── (existing leaf widgets unchanged: kpi_mini_hero_strip, monthly_spend_trend_bar_chart,
         category_spend_donut_chart, satisfaction_distribution_histogram,
         largest_expense_story_card, best_joy_story_strip, family_insight_card,
         daily_vs_joy_card, per_category_breakdown_card, time_window_chip,
         joy_metric_variant_chip, analytics_screen_section_header, analytics_card_error_state)
```

`[VERIFIED: file read]` Naming note: the leaf widgets `DailyVsJoyCard` and `PerCategoryBreakdownCard` are **already public** — they are not inline in the shell, they are imported. Their registry entries wrap them directly (no new file needed for those two, just a spec + `refreshTargets`). The 7 inline `_*Card` wrappers are what get promoted to `cards/`.

### Pattern 1: Spec-list registry (RECOMMENDED over abstract base) — D-B1

```dart
// Source: derived from existing inline-card structure in analytics_screen.dart
// lib/features/analytics/presentation/analytics_card_registry.dart

/// Snapshot of everything a card needs to (a) be built and (b) decide visibility
/// and (c) compute its refresh targets — all from the SAME providers build reads,
/// so build-vs-invalidation cannot drift (D-B2).
class AnalyticsCardContext {
  const AnalyticsCardContext({
    required this.bookId,
    required this.startDate,
    required this.endDate,
    required this.trendAnchor,
    required this.currencyCode,
    required this.joyMetricVariant,
    required this.isGroupMode,
    required this.locale,
  });
  final String bookId;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime trendAnchor;     // DateTime(endDate.year, endDate.month)
  final String currencyCode;      // bookByIdProvider.value?.currency ?? 'JPY'
  final JoyMetricVariant joyMetricVariant;
  final bool isGroupMode;
  final Locale locale;
}

class AnalyticsCardSpec {
  const AnalyticsCardSpec({
    required this.build,
    required this.refreshTargets,
    this.isVisible = _always,
    this.sectionHeaderKey, // optional: which IA section this card opens
  });
  final Widget Function(AnalyticsCardContext ctx) build;
  /// The keyed provider instances this card watches. Used for _refresh union
  /// AND (reused) for the card's own error-retry — single source (D-B2).
  final List<ProviderBase<Object?>> Function(AnalyticsCardContext ctx) refreshTargets;
  final bool Function(AnalyticsCardContext ctx) isVisible;
  final String? sectionHeaderKey;
  static bool _always(AnalyticsCardContext _) => true;
}
```

**What:** A const top-level `List<AnalyticsCardSpec>` (declaration order == render order).
**When to use:** Always (this phase). Cards stay dumb `ConsumerWidget`s; the registry owns layout order, visibility predicate, and refresh targets in one place.
**Why over abstract `AnalyticsCard` base class:**
- Cards remain plain `ConsumerWidget`s — no need to retrofit a base class onto 7 widgets that already work. Minimizes the diff (D-A1 mechanical-extraction goal).
- `refreshTargets` is the same closure the D-B3 test enumerates; trivial to iterate `for (final spec in registry) spec.refreshTargets(ctx)` in a test without instantiating widgets.
- `isVisible` lives next to the card it gates, readable inline (`isVisible: (ctx) => ctx.isGroupMode`).
- Error-retry reuse: have each card take its `refreshTargets` list (or call a shared top-level `xRefreshTargets(ctx)`); the spec's `refreshTargets` calls the same function → build, retry, and `_refresh` are one source.

The abstract-base alternative (build + refreshTargets + isVisible as methods on an `AnalyticsCard` subclass) is also D-B1/B2/B3-compliant but forces converting cards from `ConsumerWidget` into registry objects that *return* widgets — more churn, larger diff, no testability gain. Not recommended for a behavior-preserving phase.

### Pattern 2: `_refresh()` derived from the registry — D-B2

```dart
// In AnalyticsScreen
Future<void> _refresh(WidgetRef ref, AnalyticsCardContext ctx) async {
  final targets = analyticsCardRegistry
      .where((spec) => spec.isVisible(ctx))      // D-B4: only visible cards
      .expand((spec) => spec.refreshTargets(ctx))
      .toSet();                                   // dedupe shared providers
  for (final p in targets) {
    ref.invalidate(p);
  }
}
```
**Dedup note** `[VERIFIED: file read analytics_screen.dart:344-490]`: `monthlyReportProvider(...)` is watched by BOTH `_KpiHero` and `_CategoryDonutCard` with the **same key tuple** — so today it is effectively invalidated once (Riverpod dedupes by key) but appears in two cards' targets. The `.toSet()` (or just relying on Riverpod's idempotent invalidate) preserves today's behavior. `happinessReportProvider` is likewise shared by `_KpiHero` + `_SatisfactionHistogramOrFallback`.

### Pattern 3: Scroll container — `SingleChildScrollView` + `Column` (RECOMMENDED over ListView.builder) — D-A1

**What:** Keep the existing `RefreshIndicator` → `SingleChildScrollView(physics: AlwaysScrollableScrollPhysics, padding: EdgeInsets.fromLTRB(16,16,16,24))` → `Column(crossAxisAlignment: stretch, children: [...registry mapped...])`.
**Why over `ListView.builder`:**
- The current body is exactly this `[VERIFIED: lines 80-209]`. A `Column` built by mapping `registry.where(isVisible)` and interleaving `AnalyticsScreenSectionHeader` + `SizedBox` spacers is a near-identical tree → goldens/structure tests unchanged.
- Conditional cards (D-B4 `isVisible`) and per-section headers + variable `SizedBox` gaps map cleanly to filter+expand on a Column; a flat `ListView.builder` index would have to encode headers and spacers as pseudo-items, complicating the 1:1 behavior mapping with zero benefit at this list length (~9 cards).
- The existing `analytics_screen_test.dart` does `find.byType(SingleChildScrollView)` and flings it `[VERIFIED: test lines 265, 226]` — keeping `SingleChildScrollView` keeps that test green without edits.

### Anti-Patterns to Avoid
- **Rewriting card `.when` logic during extraction.** D-A1 forbids behavior change. Move bodies verbatim; only rename `_KpiHero` → `KpiHeroCard` and update imports.
- **Letting `_refresh` and `build` read different providers.** Build the `AnalyticsCardContext` once via a shared helper and pass it to both the registry-map (build) and `_refresh`.
- **Introducing a new shared provider between Home and Analytics.** GUARD-01 forbids any new Home↔Analytics shared provider. The registry must reference only `state_analytics` / `state_happiness` / `state_ledger_snapshot` families.
- **Making registry entries a generated `@riverpod` provider.** Unnecessary; a plain `const List<AnalyticsCardSpec>` is simpler and keeps build_runner a no-op.
- **Changing `AnalyticsScreen`'s public constructor.** `[VERIFIED: grep]` It is instantiated as `AnalyticsScreen(bookId: bookId)` in `home_screen.dart:225` and `main_shell_screen.dart:180`. Keep `const AnalyticsScreen({super.key, required this.bookId})`.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Per-card error retry | A new retry widget | Existing `AnalyticsCardErrorState(onRetry: …)` | Already the per-card error widget; retry list == `refreshTargets` |
| Card title/caption chrome | New Card layout | Promote `_AnalyticsDataCard` to `cards/analytics_data_card.dart` (shared shell) | Already the shared shell for 3 cards (trend/donut/histogram) |
| Section headers | New header widget | Existing `AnalyticsScreenSectionHeader` | Already renders Time/Distribution/Stories headers |
| Window normalization for family keys | Manual date math | `DateBoundaries`/`TimeWindow` (already in providers) | Phase 44 locked this; cards already get normalized bounds |
| Provider invalidation dedup | Manual seen-set | `Set<ProviderBase>` + idempotent `ref.invalidate` | Riverpod invalidate is idempotent by key |

**Key insight:** Phase 45 is 95% *move code that already works* + 5% *wire a registry*. The temptation to "improve" cards while extracting is the single biggest risk to D-A1 (golden-green, mechanical diff).

## Runtime State Inventory

> Rename/refactor phase — inventory required.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — no DB schema, collection, key, or user_id strings touched. Pure presentation-layer file moves. | none |
| Live service config | None — no external service, n8n, Datadog, etc. | none |
| OS-registered state | None — no Task Scheduler / pm2 / launchd. | none |
| Secrets/env vars | None — no secret/env names referenced. | none |
| Build artifacts | New `cards/*.dart` are plain `ConsumerWidget`s (no `@riverpod`/`@freezed`) → **no new `.g.dart`/`.freezed.dart`**. If the planner adds any annotated symbol (NOT recommended), `flutter pub run build_runner build --delete-conflicting-outputs` is required. Otherwise build_runner is a no-op. | run build_runner only if annotations added |

**Symbol-rename surface** `[VERIFIED: grep]`: The 7 inline cards are **private** (`_KpiHero` etc.) — referenced only within `analytics_screen.dart`. No test references `_KpiHero`/`_TotalSixMonthCard`/etc. (grep returned zero). Promoting them to public classes in new files breaks **nothing external**. Tests target the *leaf* widgets (`KpiMiniHeroStrip`, `MonthlySpendTrendBarChart`, …) via `find.byType`, which are untouched.

## Common Pitfalls

### Pitfall 1: Breaking the existing `find.byType` widget assertions
**What goes wrong:** Renaming a leaf widget or changing the tree depth makes `analytics_screen_test.dart` (`find.byType(KpiMiniHeroStrip)`, `findsNWidgets(3)` section headers, etc.) fail.
**Why it happens:** Confusing the inline `_*Card` *wrapper* (private, safe to rename) with the *leaf* widget it renders (public, asserted by tests).
**How to avoid:** Only rename/move the `_*Card` wrappers. Leave every leaf widget (`KpiMiniHeroStrip`, `MonthlySpendTrendBarChart`, `CategorySpendDonutChart`, `SatisfactionDistributionHistogram`, `LargestExpenseStoryCard`, `BestJoyStoryStrip`, `FamilyInsightCard`, `DailyVsJoyCard`, `PerCategoryBreakdownCard`) and the chrome widgets (`AnalyticsScreenSectionHeader` ×3, `TimeWindowChip`, `AnalyticsCardErrorState`) exactly where they are in the tree.
**Warning signs:** Any edit to a file under `widgets/` other than the 8 promoted ones.

### Pitfall 2: `_refresh` union drifts from build (silent over/under-invalidation)
**What goes wrong:** A card watches provider X in `build` but its `refreshTargets` lists a different key tuple (e.g., forgets `joyMetricVariant`, or uses raw `DateTime.now()`), so pull-to-refresh invalidates the wrong cache key → stale card or rebuild storm.
**Why it happens:** Two hand-maintained lists of the same providers.
**How to avoid:** D-B2 single-source. Define one `xRefreshTargets(AnalyticsCardContext ctx)` per card; the card's `build` constructs the provider from `ctx`, the spec's `refreshTargets` calls `xRefreshTargets`, and the error-retry calls the same. The current keys to preserve `[VERIFIED: analytics_screen.dart:228-321]`: every analytics provider is keyed on the **current** `selectedJoyMetricVariantProvider` value (`_refresh` reads `variant = ref.read(selectedJoyMetricVariantProvider)` at refresh time, line 227) — the ctx must carry the same variant.

### Pitfall 3: Conditional family card invalidation in solo mode (D-B4)
**What goes wrong:** `_refresh` invalidates `familyHappinessProvider` / `perCategoryJoyBreakdownFamilyProvider` / `dailyVsJoySnapshotFamilyProvider` / `shadowBooksProvider` even in solo mode.
**Why it happens:** Today the conditional block is gated by `if (isGroupMode)` `[VERIFIED: lines 296-321]`. If the registry doesn't gate the family card's `refreshTargets` behind `isVisible: (ctx)=>ctx.isGroupMode`, the union will over-invalidate.
**How to avoid:** D-B4 — the family card spec carries `isVisible: (ctx) => ctx.isGroupMode`, and `_refresh` filters `where(isVisible)` *before* `expand(refreshTargets)`. This both renders only visible cards AND only invalidates visible cards (a behavior *improvement* that is still within "preserve observable behavior" because hidden cards have no visible state — confirm in VALIDATION that solo-mode visible output is unchanged).

### Pitfall 4: `_SatisfactionHistogramOrFallback` async self-hide (D-B5)
**What goes wrong:** Trying to move the `report.totalJoyTx < 5 → SizedBox.shrink()` decision into the registry `isVisible(ctx)`.
**Why it happens:** It looks like a visibility predicate.
**How to avoid:** D-B5 — that decision depends on *fetched* `happinessReport` data, which `ctx` cannot hold (ctx has only the keys, not the resolved AsyncValue). Keep the self-hide **inside the card's `.when` data branch** `[VERIFIED: lines 528-531]`. The registry `isVisible` for this card is `_always` (it always participates), and its `refreshTargets` always includes both `happinessReportProvider` + `satisfactionDistributionProvider`.

### Pitfall 5: ADR-012 edit beyond append-only
**What goes wrong:** Editing the ADR-012 decision body, or changing its status line, instead of appending.
**Why it happens:** The header still reads `状态: 📝 草稿` (line 7) even though the implementation plan says it was to be ratified `✅ 已接受` at Phase 12 close — and no `## Update` was ever appended `[VERIFIED: grep "## Update" → NONE]`. Tempting to "fix" the status inline.
**How to avoid:** `.claude/rules/arch.md` mandates append-only after acceptance: only append `## Update YYYY-MM-DD: <topic>` at the file end; do not touch the decision body or the forbidden-features list. See D-D1 section below.

## Code Examples

### Building the context once, feeding both build and refresh

```dart
// Source: distilled from analytics_screen.dart build() lines 42-67 + _refresh 227
AnalyticsCardContext _buildContext(BuildContext context, WidgetRef ref) {
  final window = ref.watch(selectedTimeWindowProvider);
  final range = window.range;
  final endDate = range.end;
  final book = ref.watch(accounting_providers.bookByIdProvider(bookId: bookId));
  return AnalyticsCardContext(
    bookId: bookId,
    startDate: range.start,
    endDate: endDate,
    trendAnchor: DateTime(endDate.year, endDate.month),
    currencyCode: book.value?.currency ?? 'JPY',
    joyMetricVariant: ref.watch(selectedJoyMetricVariantProvider),
    isGroupMode: ref.watch(isGroupModeProvider),
    locale: ref.watch(locale_providers.currentLocaleProvider).value
        ?? Localizations.localeOf(context),
  );
}
```

### Single-source refreshTargets reused by card build + retry + registry

```dart
// Source: derived from _CategoryDonutCard lines 462-489
List<ProviderBase<Object?>> categoryDonutRefreshTargets(AnalyticsCardContext c) => [
  monthlyReportProvider(
    bookId: c.bookId, startDate: c.startDate, endDate: c.endDate,
    joyMetricVariant: c.joyMetricVariant,
  ),
];
// card error-retry: ref.invalidate(categoryDonutRefreshTargets(c).single)
// registry spec:    refreshTargets: categoryDonutRefreshTargets
```

## Provider → Card Mapping (source of truth for the registry union)

`[VERIFIED: analytics_screen.dart full read + state_analytics/state_happiness/state_ledger_snapshot]`

| Card (inline → new) | Section | Provider family watched (key tuple) | isVisible | LOC (inline) |
|---------------------|---------|--------------------------------------|-----------|--------------|
| `_KpiHero` → `KpiHeroCard` | (above headers) | `monthlyReport(bookId,start,end,variant)` + `happinessReport(bookId,start,end,currency,variant)` | always | ~75 (325-399) |
| `_TotalSixMonthCard` → `TotalSixMonthCard` | Time | `expenseTrend(bookId,anchor,variant)` | always | ~46 (401-446) |
| `_CategoryDonutCard` → `CategoryDonutCard` | Distribution | `monthlyReport(bookId,start,end,variant)` | always | ~43 (448-490) |
| `DailyVsJoyCard` (already public) | Distribution | `dailyVsJoySnapshot(bookId,start,end,variant)` (+ `dailyVsJoySnapshotFamily` when group) | always | leaf 471 |
| `_SatisfactionHistogramOrFallback` → `SatisfactionHistogramCard` | Distribution | `happinessReport(...)` + `satisfactionDistribution(bookId,start,end,variant)` | always (self-hide D-B5) | ~74 (492-565) |
| `PerCategoryBreakdownCard(scope:you/solo)` (public) | Distribution | `perCategoryJoyBreakdown(bookId,start,end,variant)` | always | leaf 260 |
| `PerCategoryBreakdownCard(scope:family)` (public, 2nd) | Distribution | `perCategoryJoyBreakdownFamily(start,end,variant)` | **isGroupMode** | leaf (reused) |
| `_LargestExpenseCard` → `LargestExpenseCard` | Stories | `largestMonthlyExpense(bookId,start,end,variant)` | always | ~47 (567-613) |
| `_BestJoyCard` → `BestJoyCard` | Stories | `bestJoyMoment(bookId,start,end,variant)` | always | ~47 (615-661) |
| `_FamilyCard` → `FamilyInsightDataCard` | Stories | `familyHappiness(start,end,variant)` (+ shell also invalidates `shadowBooksProvider`) | **isGroupMode** | ~46 (663-708) |
| `_AnalyticsDataCard` → `analytics_data_card.dart` | (shared shell, StatelessWidget) | none | n/a | ~30 (710-739) |

**`_refresh` today invalidates 13 providers** `[VERIFIED: lines 228-320]`: unconditional (10): `monthlyReport`, `expenseTrend`, `earliestTransactionMonth`, `happinessReport`, `satisfactionDistribution`, `bestJoyMoment`, `largestMonthlyExpense`, `perCategoryJoyBreakdown`, `dailyVsJoySnapshot`; conditional under `isGroupMode` (4): `familyHappiness`, `shadowBooksProvider`, `perCategoryJoyBreakdownFamily`, `dailyVsJoySnapshotFamily`.

**Two providers in `_refresh` that no single card cleanly owns:**
- `earliestTransactionMonth(bookId)` — read in the **shell** (`build` line 57, feeds `TimeWindowChip.earliestData`), not a card. The registry union won't naturally include it. **Recommendation:** keep it as an explicit shell-level refresh target (a small `shellRefreshTargets(ctx)` appended to the union) OR attach it to the `TimeWindowChip`'s notional spec. Document it so D-B3's union assertion accounts for it (it IS an analytics provider — passes the ⊆-analytics test).
- `shadowBooksProvider` — `[VERIFIED]` this is a **`home/*` provider**: `import '../../../home/presentation/providers/state_shadow_books.dart'` (analytics_screen.dart line 7). **CRITICAL for D-B3:** today `_refresh` *does* invalidate `shadowBooksProvider` (line 304) under group mode. This is the one provider in the current union that is NOT under `lib/features/analytics/`. The D-B3 test asserting "0 home/* providers in the union" must reconcile this:
  - Option A (recommended): the family analytics providers (`familyHappiness`, `*Family`) already `ref.watch(shadowBooksProvider.future)` internally, so invalidating *them* re-reads shadow books transitively; **drop the direct `shadowBooksProvider` invalidate** from the registry union. This is the cleanest way to make "union ⊆ analytics" literally true. Verify in VALIDATION that group-mode pull-to-refresh still refreshes family cards (it will, because invalidating `familyHappiness` re-runs its `ref.watch(shadowBooksProvider.future)`).
  - Option B: keep `shadowBooksProvider` and scope the D-B3 assertion to "0 `home/*` providers **read by analytics cards**" (the cards never read it; only the shell does for the family card's `shadowBooksAsync` prop). This is weaker and muddier — prefer A.
  - **This is a genuine planner decision and a behavior-preservation subtlety. Flag it.** `[ASSUMED]` that Option A preserves behavior (transitive re-read) — **must be verified by a group-mode refresh test**, listed in Assumptions Log.

## State of the Art

Not applicable — no library-version migration. The relevant "state of the art" is the project's own Riverpod 3 conventions (CLAUDE.md): provider names strip `Notifier` suffix, `AsyncValue.value` is nullable, errors wrapped in `ProviderException`, side-effects in `ref.listen`. None of these change card behavior here.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Dropping the direct `shadowBooksProvider.invalidate` (Option A) preserves group-mode refresh because `familyHappiness`/`*Family` providers re-`watch(shadowBooksProvider.future)` on invalidation | Provider→Card Mapping | If Riverpod does not re-read the upstream on downstream invalidate (it should, since the dependency is re-established on rebuild), group-mode pull-to-refresh would show stale shadow data. **Verify with a group-mode refresh widget test before finalizing.** |
| A2 | `DailyVsJoyCard` (471 LOC) and `PerCategoryBreakdownCard` (260 LOC) need NOT be split to satisfy "<400 LOC per card" because they are pre-existing leaf widgets, not the newly-extracted card wrappers, and D-A1 forbids behavior change | Standard Stack / Structure | If the planner/checker reads SC-1 "<400 LOC per card" as applying to `DailyVsJoyCard`, they may attempt an out-of-scope split. The <400 target applies to the **newly extracted `cards/` wrappers** (all <100 LOC). Confirm interpretation with the planner. |
| A3 | The D-B3 "union ⊆ analytics providers" assertion can be written without instantiating widgets, by iterating `registry.expand((s)=>s.refreshTargets(ctx))` with a synthetic ctx | Validation Architecture | If specs require widget context to compute targets, the test needs a `ProviderContainer.test()` pump. The recommended spec shape (closures over a plain ctx) avoids this. |

## Open Questions (RESOLVED)

1. **Where does `earliestTransactionMonth` invalidation live in the registry model?**
   - What we know: it's a shell-level read feeding `TimeWindowChip`, not a card.
   - **RESOLVED:** append a tiny `shellRefreshTargets(ctx) => [earliestTransactionMonth(bookId: ctx.bookId)]` to the union; it's an analytics provider so D-B3 passes. Adopted in Plan 45-03 Task 1 (`shellRefreshTargets`).

2. **D-B3 assertion strength re `shadowBooksProvider` (home/*).**
   - What we know: today's `_refresh` invalidates it (a `home/*` provider).
   - **RESOLVED:** Option A — drop the direct invalidate, rely on transitive re-read via `familyHappinessProvider`'s internal `watch(shadowBooksProvider.future)`. Adopted in Plan 45-02 Task 2 (`familyInsightRefreshTargets` excludes shadowBooksProvider) and gated by the group-mode refresh test (Assumption A1) in Plan 45-07.

> **Post-planning addendum (Blocker-1, found in plan review):** A third resolution — the single `DailyVsJoyCard` watches BOTH `dailyVsJoySnapshotProvider` (always) and `dailyVsJoySnapshotFamilyProvider` (when group, daily_vs_joy_card.dart:50-61), and today's `_refresh:314` invalidates the family snapshot under group mode. **RESOLVED:** the DailyVsJoy registry spec's `dailyVsJoyRefreshTargets(ctx)` is GROUP-AWARE — `[dailyVsJoySnapshotProvider(...), if (ctx.isGroupMode) dailyVsJoySnapshotFamilyProvider(...)]` — so the group-mode union stays byte-equivalent to today's invalidate set (minus the dropped shadowBooksProvider). Adopted in Plan 45-03 spec #4; asserted (∈ group ∧ ∉ solo) in Plan 45-05.

## Environment Availability

> Skipped — no external tools/services. Pure Dart/Flutter source edits using the existing toolchain (`flutter analyze`, `flutter test`, `dart format`, `build_runner` only if annotations added).

## Validation Architecture

> nyquist_validation is ENABLED (`.planning/config.json: "nyquist_validation": true`). `[VERIFIED: config grep]`

### Test Framework
| Property | Value |
|----------|-------|
| Framework | `flutter_test` + `flutter_riverpod` test helpers + `mocktail` |
| Config file | `test/flutter_test_config.dart` (golden platform gate: off-macOS swaps in `BaselineExistenceGoldenComparator`) `[VERIFIED]` |
| Quick run command | `flutter test test/widget/features/analytics/ test/widget/features/home/presentation/screens/home_screen_isolation_test.dart` |
| Full suite command | `flutter test` |
| Static gate | `flutter analyze` (MUST be 0 issues) + `dart format` (do NOT format whole test/ — repo not format-clean; format only edited files) |

### Phase Requirements → Test Map
| Req ID | Behavior / Invariant | Test Type | Automated Command | File Exists? |
|--------|----------------------|-----------|-------------------|-------------|
| REDES-01 | `analytics_screen.dart` is a thin shell; 7 cards moved to `widgets/cards/`, each a `ConsumerWidget` watching one provider family with local `.when` | structure/widget | `flutter test test/widget/features/analytics/presentation/screens/analytics_screen_test.dart` | ✅ (extend) |
| REDES-01 | Per-card LOC < 400 for newly extracted wrappers | source assertion | new test reads each `cards/*.dart` file length, asserts `< 400` | ❌ Wave 0 |
| REDES-01 | `_refresh()` invalidation union is **registry-derived** (registry drives both render order and refresh) | unit | new `analytics_card_registry_test.dart`: assert union == expected provider set for solo & group ctx | ❌ Wave 0 |
| GUARD-01 / D-B3 | Registry-derived union ⊆ analytics providers, contains **0 `home/*` providers** | unit | new test iterates `registry.expand(refreshTargets)` over solo+group ctx, asserts every provider's runtime origin is an analytics `state_*` family | ❌ Wave 0 |
| GUARD-01 | `home_screen_isolation_test.dart` stays green (HomeScreen doesn't import `state_time_window`/`selectedTimeWindowProvider`/`state_ledger_snapshot`; variant toggle doesn't touch HomeHero) | widget + source | `flutter test test/widget/features/home/presentation/screens/home_screen_isolation_test.dart` | ✅ (keep green) |
| GUARD-01 | analytics card providers stay **auto-dispose**; no new Home↔Analytics shared provider | structure | `analytics_card_registry_test` asserts none of the union providers is keepAlive; grep test that `cards/*` import no `home/*` except none | ❌ Wave 0 (partial) |
| REDES-01 (behavior) | No visible change — goldens stay green | golden | `flutter test test/golden/daily_vs_joy_card_golden_test.dart test/golden/per_category_breakdown_card_golden_test.dart test/golden/home_hero_card_golden_test.dart` | ✅ (no edit) |
| REDES-01 (no toxicity regression) | No new forbidden copy introduced | widget | `flutter test test/widget/features/analytics/presentation/widgets/anti_toxicity_phase16_test.dart test/widget/features/analytics/presentation/widgets/anti_toxicity_phase17_test.dart` | ✅ (keep green) |
| REDES-01 (no delta UI) | No cross-period delta UI leaks | widget | `flutter test test/widget/features/analytics/presentation/screens/analytics_no_delta_ui_test.dart` | ✅ (keep green) |
| D-D1 | ADR-012 has an appended `## Update YYYY-MM-DD` recording the expense-side 本月vs上月 §4 carve-out | doc/source | optional: a test asserting `ADR-012….md` contains `## Update` + the carve-out phrase (or manual check) | ❌ optional |

### Sampling Rate
- **Per task commit:** `flutter analyze` (0 issues) + the quick analytics+isolation test subset above.
- **Per wave merge:** full `flutter test` (catches architecture tests like `home_screen_isolation`, `anti_toxicity_*`, `domain_import_rules`, `provider_graph_hygiene`, and the golden suite). Per project memory, scoped tests miss architecture tests — run the FULL suite at wave merge.
- **Phase gate:** full `flutter test` green + `flutter analyze` 0 + every golden green (no re-baseline this phase) before `/gsd-verify-work`.

### Wave 0 Gaps
- [ ] `test/.../analytics_card_registry_test.dart` — the **new D-B3 unit test**: derive union over solo & group `AnalyticsCardContext`, assert (a) union ⊆ analytics provider families, (b) 0 `home/*` providers, (c) render-order list non-empty and matches registry order, (d) family-scoped specs only present under `isGroupMode`. (covers REDES-01 + GUARD-01/D-B3)
- [ ] Per-card LOC + `ConsumerWidget` structure assertion (covers REDES-01 SC-1) — a source-reading test over `lib/features/analytics/presentation/widgets/cards/*.dart`.
- [ ] Extend `analytics_screen_test.dart` to confirm the shell still renders all leaf widgets after extraction (the existing `find.byType` assertions should pass unchanged — verify, don't rewrite).
- [ ] (optional) ADR-012 `## Update` presence test for D-D1.
- Framework install: none — `flutter_test`/`mocktail`/riverpod helpers already present.

## D-D1: ADR-012 Append-Only Update

`[VERIFIED: file read docs/arch/03-adr/ADR-012_No_Gamification_v1_1.md]`

- **File:** `docs/arch/03-adr/ADR-012_No_Gamification_v1_1.md` (127 lines).
- **Status reality:** Header line 7 still reads `状态: 📝 草稿`. The implementation-plan table (line 122) says it was to flip to `✅ 已接受` at Phase 12 close with an `## Update YYYY-MM-DD: ratified at v1.1 close` appended. **Grep confirms NO `## Update` section exists yet** (the ratification append was also never done). Per `.claude/rules/arch.md`, once accepted the file is append-only: only `## Update YYYY-MM-DD: <topic>` sections at the end, never editing the decision body.
- **What to append (D-D1):** A new `## Update 2026-06-XX: 支出侧 本月vs上月 趋势 — §4 记录在案例外` section at the **end of the file** documenting that the expense-side 本月vs上月 trend (总支出/日常 tabs, matching the Home 支出趋势, neutral labels) is a **user-approved carve-out from the §4 "Cross-period delta on home tile" forbidden item** — while the **joy-side cross-period prohibition stays ABSOLUTE** (悦己侧跨期仍绝对禁止). Source of the approval: GATE-04 (`43-html-design-gate-no-production-code/GATE-04-adr-go-no-go.md`) and STATE.md line 192.
- **Anchor/where:** append after line 127 (`*下次审查触发: v1.2 milestone start*`). Do not modify §🚫 Forbidden Features list, the decision body, or the status header line — append-only.
- **Coupling:** **zero functional coupling.** Under D-A1, Phase 45 does NOT render the expense-trend cross-period callout (that's Phase 46). D-D1 is doc-only, near-zero cost, discharges a recorded obligation, and pulls the red-line forward. Per arch.md it should be one `## Update` section + (optionally) flipping status to `✅ 已接受` via an Update note rather than editing line 7 — **planner decides whether to also record the long-overdue ratification in the same Update**; the in-scope deliverable is the §4 carve-out record.
- **Recommendation:** Single `## Update` section covering the §4 carve-out. If the planner wants to also reconcile the never-recorded ratification, do it in the same append-only Update (note status is effectively `✅ 已接受` since Phase 12) — but do NOT hand-edit the `状态:` header line, to stay strictly append-only.

## Project Constraints (from CLAUDE.md + .claude/rules)

- **Clean Architecture 5-layer + Thin Feature:** new `cards/` live in `lib/features/analytics/presentation/widgets/cards/` (presentation). No `application/`, `data/`, `infrastructure/` inside the feature. ✅ compatible.
- **Riverpod 3 conventions:** cards stay `ConsumerWidget`; use `flutter_riverpod/flutter_riverpod.dart` for `ConsumerWidget`/`WidgetRef`/`ProviderBase`; `misc.dart` for `ProviderBase`/`ProviderListenable` if the registry type signature needs it (anti_toxicity_phase16_test already imports `flutter_riverpod/misc.dart`). `AsyncValue.value` is nullable. Side-effects in `ref.listen` (n/a here).
- **Immutability:** `AnalyticsCardContext` and `AnalyticsCardSpec` are `const`/immutable with final fields — use `copyWith`-style construction, never mutate.
- **i18n:** all card titles/captions via `S.of(context)`; no hardcoded strings. Cards already comply.
- **ADR-017 生存/灵魂 grep-ban:** new file + symbol names must avoid the banned terminology — use neutral English class names (`KpiHeroCard`, `TotalSixMonthCard`, etc.), not 生存/灵魂.
- **ADR-016 §3:** HomeHero owns the target ring exclusively; analytics must not replicate it. This phase touches no ring code. ✅.
- **ADR-019 palette:** behavior-preserving phase → **no color changes**. Cards keep existing theme tokens.
- **File size:** 200-400 typical, 800 max (coding-style). New card wrappers all < 100 LOC. ✅.
- **Zero analyzer warnings** before commit; don't suppress with `// ignore:`; don't hand-edit `.g.dart`.
- **Tests are first-class** (80% coverage standard); the new registry + D-B3 test are required deliverables, not optional.
- **arch.md append-only ADR rule** governs D-D1 (see above).

## Sources

### Primary (HIGH confidence) — direct repo reads
- `lib/features/analytics/presentation/screens/analytics_screen.dart` (739 LOC, full read) — shell, `_refresh`, 7 inline cards, `_AnalyticsDataCard`
- `lib/features/analytics/presentation/providers/state_analytics.dart`, `state_happiness.dart`, `state_ledger_snapshot.dart` — provider families + key tuples + auto-dispose confirmation
- `test/widget/features/home/presentation/screens/home_screen_isolation_test.dart` — GUARD-01 assertion style (verifyNever + source-import grep)
- `test/widget/features/analytics/presentation/screens/analytics_screen_test.dart` — `find.byType` targets leaf widgets, `SingleChildScrollView` fling
- `test/widget/features/analytics/presentation/screens/analytics_no_delta_ui_test.dart`, `anti_toxicity_phase16_test.dart` — no-delta + anti-toxicity gates
- `docs/arch/03-adr/ADR-012_No_Gamification_v1_1.md` (full) + `.claude/rules/arch.md` (append-only) — D-D1
- `test/flutter_test_config.dart` — golden platform gate; `test/golden/{daily_vs_joy,per_category_breakdown,home_hero}_card_golden_test.dart` — golden coverage scope
- `.planning/config.json` — `nyquist_validation: true`
- grep: `AnalyticsScreen(` call sites (home_screen.dart:225, main_shell_screen.dart:180); `_KpiHero` etc. → 0 test references; `shadowBooksProvider` import origin = `home/*`

### Secondary (MEDIUM)
- `.planning/phases/45-presentation-shell-rebuild/45-CONTEXT.md` (decisions D-A1..D-D1)
- STATE.md (lines 188-196) — GATE-04 §4 carve-out + ADR-012 punt history

### Tertiary (LOW)
- none — no web research required for a self-contained structural refactor.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new packages; all libraries verified present in the live files.
- Architecture (registry/scroll/refresh patterns): HIGH — patterns derived directly from the existing inline-card structure; recommendations are the minimal-diff path.
- Pitfalls: HIGH — each grounded in a verified line range or grep result.
- `shadowBooksProvider` home/* resolution (Option A): MEDIUM — recommendation is sound but transitive-re-read must be confirmed by a group-mode refresh test (Assumption A1).

**Research date:** 2026-06-17
**Valid until:** 2026-07-17 (stable — internal refactor; only invalidated if Phase 44 providers or the isolation test change before planning)
