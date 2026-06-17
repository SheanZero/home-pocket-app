# Phase 45: Presentation Shell Rebuild - Pattern Map

**Mapped:** 2026-06-17
**Files analyzed:** 12 (8 new card files + 1 registry + 1 shell rewrite + 1 new test + 1 ADR append)
**Analogs found:** 12 / 12

> Phase 45 is a **pure structural, behavior-preserving** extraction. For the 7 inline `_*Card` widgets, the closest analog for each new `cards/*.dart` file **IS the inline widget itself** inside `analytics_screen.dart`. Move the body verbatim; rename `_KpiHero` → `KpiHeroCard` and add `super.key`. The leaf widgets they render (`KpiMiniHeroStrip`, etc.) are untouched. `lib/features/analytics/presentation/widgets/daily_vs_joy_card.dart` is the analog for the **target file shape** (public `ConsumerWidget`, import block, one watched provider family). `home_screen_isolation_test.dart` is the analog for the new D-B3 structural test.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `presentation/screens/analytics_screen.dart` (rewrite → thin shell) | screen (shell) | request-response (pull-to-refresh + map) | itself (current shell body, lines 42–212) | self / exact |
| `presentation/analytics_card_registry.dart` (NEW) | registry/config | transform (ctx → specs → union) | RESEARCH Pattern 1 (no existing registry — derived from inline cards) | no analog (use RESEARCH) |
| `widgets/cards/analytics_data_card.dart` (NEW) | widget (shared shell) | none (StatelessWidget chrome) | `_AnalyticsDataCard` (lines 710–739) | self / exact |
| `widgets/cards/kpi_hero_card.dart` (NEW) | widget (ConsumerWidget) | CRUD-read + `.when` | `_KpiHero` (lines 325–399) | self / exact |
| `widgets/cards/total_six_month_card.dart` (NEW) | widget (ConsumerWidget) | CRUD-read + `.when` | `_TotalSixMonthCard` (lines 401–446) | self / exact |
| `widgets/cards/category_donut_card.dart` (NEW) | widget (ConsumerWidget) | CRUD-read + `.when` | `_CategoryDonutCard` (lines 448–490) | self / exact |
| `widgets/cards/satisfaction_histogram_card.dart` (NEW) | widget (ConsumerWidget) | CRUD-read + nested `.when` + self-hide | `_SatisfactionHistogramOrFallback` (lines 492–565) | self / exact |
| `widgets/cards/largest_expense_card.dart` (NEW) | widget (ConsumerWidget) | CRUD-read + `.when` | `_LargestExpenseCard` (lines 567–613) | self / exact |
| `widgets/cards/best_joy_card.dart` (NEW) | widget (ConsumerWidget) | CRUD-read + `.when` | `_BestJoyCard` (lines 615–661) | self / exact |
| `widgets/cards/family_insight_data_card.dart` (NEW) | widget (ConsumerWidget) | CRUD-read + `.when` | `_FamilyCard` (lines 663–708) | self / exact |
| `test/.../analytics_card_registry_test.dart` (NEW) | test (structural/unit) | assertion | `home_screen_isolation_test.dart` (source-grep + union tests) | role-match (structural-assertion style) |
| `docs/arch/03-adr/ADR-012_No_Gamification_v1_1.md` (append) | doc (ADR) | append-only | `.claude/rules/arch.md` append-only rule | rule-match |

**Public-shape analog for ALL new `cards/*.dart`:** `widgets/daily_vs_joy_card.dart` (lines 1–57) — already-public `ConsumerWidget` that watches one provider family. Copy its file skeleton (import block ordering, `const … ({super.key, required …})`, `build` → `ref.watch(family(...))` → render).

---

## Pattern Assignments

### Shared file skeleton for every `cards/*.dart` (ConsumerWidget)

**Analog:** `lib/features/analytics/presentation/widgets/daily_vs_joy_card.dart` lines 1–57.

Import block convention (relative imports, `flutter_riverpod/flutter_riverpod.dart`, then `../../domain/...`, `../providers/...`, sibling widgets). Constructor takes `super.key` + the same `(bookId, startDate, endDate, currencyCode, locale, joyMetricVariant)` field subset each card already declares. `build` does exactly one `ref.watch(<family>(...))` then `.when(...)`. **Add `super.key`** (the private inline ctors omit it — see `_KpiHero` line 326 `const _KpiHero({ required ... })` with no key).

### `widgets/cards/kpi_hero_card.dart` (ConsumerWidget, CRUD-read)

**Analog:** `_KpiHero` (`analytics_screen.dart` lines 325–399). **Move verbatim**, rename to `KpiHeroCard`, add `super.key`.

- Watches TWO providers: `monthlyReportProvider(bookId,startDate,endDate,joyMetricVariant)` + `happinessReportProvider(bookId,startDate,endDate,currencyCode,joyMetricVariant)` (lines 344–360).
- Nested `.when`: outer `monthlyAsync.when` → inner `happinessAsync.when` (lines 362–397). Each `data` wraps `KpiMiniHeroStrip` in `SizedBox(height:120)`; `loading` → `SizedBox(height:120)`; `error` → `AnalyticsCardErrorState(onRetry: () => ref.invalidate(<that same provider>))`.
- **refreshTargets** (D-B2): `[monthlyReport(...), happinessReport(...)]` — same two key tuples build watches.

### `widgets/cards/total_six_month_card.dart` (ConsumerWidget, CRUD-read)

**Analog:** `_TotalSixMonthCard` (lines 401–446). Watches `expenseTrendProvider(bookId, anchor, joyMetricVariant)` (lines 416–422). `data` → `_AnalyticsDataCard(title:…analyticsCardTitleTotalSixMonth, caption:…, child: MonthlySpendTrendBarChart(...))`; `loading` → `SizedBox(height:260)`; `error` retry invalidates `expenseTrendProvider(...)`. **refreshTargets:** `[expenseTrend(bookId,anchor,variant)]`. Note: keyed on `anchor` (`DateTime(endDate.year, endDate.month)`), NOT start/end.

### `widgets/cards/category_donut_card.dart` (ConsumerWidget, CRUD-read)

**Analog:** `_CategoryDonutCard` (lines 448–490). Watches `monthlyReportProvider(bookId,startDate,endDate,joyMetricVariant)` (lines 463–470) — **SAME key tuple as KpiHero's monthlyReport** → dedupe with `.toSet()` in `_refresh` union (RESEARCH Pitfall/dedup note). `data` → `_AnalyticsDataCard(..., child: CategorySpendDonutChart(breakdowns: monthly.categoryBreakdowns))`. **refreshTargets:** `[monthlyReport(bookId,start,end,variant)]`.

### `widgets/cards/satisfaction_histogram_card.dart` (ConsumerWidget, nested `.when` + async self-hide — D-B5)

**Analog:** `_SatisfactionHistogramOrFallback` (lines 492–565). Watches `happinessReportProvider(...)` + `satisfactionDistributionProvider(bookId,start,end,variant)` (around lines 510–525). **Critical self-hide stays in card** (lines 528–531):

```dart
return happinessAsync.when(
  data: (report) {
    if (report.totalJoyTx < 5) {
      return const SizedBox.shrink();   // D-B5: depends on FETCHED data, NOT ctx
    }
    return distributionAsync.when(
      data: (buckets) => _AnalyticsDataCard(... child: SatisfactionDistributionHistogram(buckets: buckets)),
      loading: () => const SizedBox(height: 260),
      error: (_, _) => AnalyticsCardErrorState(onRetry: () => ref.invalidate(satisfactionDistributionProvider(...))),
    );
  },
  loading: () => const SizedBox(height: 260),
  error: (_, _) => AnalyticsCardErrorState(onRetry: () => ref.invalidate(happinessReportProvider(...))),
);
```

Registry `isVisible` for this card = `_always`. **refreshTargets:** `[happinessReport(...), satisfactionDistribution(...)]` (always both).

### `widgets/cards/largest_expense_card.dart` (ConsumerWidget, CRUD-read)

**Analog:** `_LargestExpenseCard` (lines 567–613). Watches `largestMonthlyExpenseProvider(bookId,start,end,variant)`. `data` → `LargestExpenseStoryCard(expense, currencyCode, locale)` (note: NO `_AnalyticsDataCard` shell — renders leaf directly); `loading` → `SizedBox(height:110)`. **refreshTargets:** `[largestMonthlyExpense(...)]`.

### `widgets/cards/best_joy_card.dart` (ConsumerWidget, CRUD-read)

**Analog:** `_BestJoyCard` (lines 615–661). Watches `bestJoyMomentProvider(bookId,start,end,variant)`. `data` → `BestJoyStoryStrip(bestJoy, currencyCode, locale)`; `loading` → `SizedBox(height:120)`. **refreshTargets:** `[bestJoyMoment(...)]`.

### `widgets/cards/family_insight_data_card.dart` (ConsumerWidget, CRUD-read — isGroupMode-gated)

**Analog:** `_FamilyCard` (lines 663–708). Watches `familyHappinessProvider(startDate,endDate,joyMetricVariant)` (NO bookId — derives ids internally, lines 682–688). Takes `shadowBooksAsync` as a constructor prop (resolved in shell, lines 63–67) and passes `shadowBooksAsync.value` to `FamilyInsightCard`. **registry `isVisible: (ctx) => ctx.isGroupMode`** (D-B4). **refreshTargets:** `[familyHappiness(start,end,variant)]` — **drop direct `shadowBooksProvider` invalidate** (Option A, see Shared Patterns / D-B3).

### `widgets/cards/analytics_data_card.dart` (shared shell — StatelessWidget)

**Analog:** `_AnalyticsDataCard` (lines 710–739). Move verbatim, rename `AnalyticsDataCard`, add `super.key`. `Card` → `Padding(14)` → `Column(start)` with `title` (titleMedium), `caption` (bodySmall), `child`. Consumed by total_six_month / category_donut / satisfaction_histogram cards.

### `presentation/screens/analytics_screen.dart` (thin shell rewrite)

**Analog:** itself, lines 42–212 (current `build`) + 214–322 (current `_refresh`).

- **Keep public ctor unchanged:** `const AnalyticsScreen({super.key, required this.bookId})` (line 37) — called at `home_screen.dart:225` and `main_shell_screen.dart:180`.
- **Keep tree shape:** `Scaffold(appBar: AppBar(title, actions:[TimeWindowChip, JoyMetricVariantChip]))` → `RefreshIndicator(onRefresh: _refresh)` → `SingleChildScrollView(physics: AlwaysScrollableScrollPhysics, padding: EdgeInsets.fromLTRB(16,16,16,24))` → `Column(crossAxisAlignment: stretch)` (lines 69–93). RESEARCH Pattern 3: keep this exact container — `analytics_screen_test.dart` does `find.byType(SingleChildScrollView)`.
- **Context build (feeds BOTH build map and `_refresh`):** lines 42–62 → factor into one `AnalyticsCardContext`/`_buildContext` (RESEARCH Code Example). Carries `(bookId, startDate, endDate, trendAnchor=DateTime(endDate.year,endDate.month), currencyCode=book.value?.currency ?? 'JPY', joyMetricVariant, isGroupMode, locale)`.
- **Section/gap interleave to preserve verbatim** (lines 94–206): KpiHero → `SizedBox(32)` → SectionHeader(Time) → `SizedBox(8)` → TotalSixMonth → `SizedBox(32)` → SectionHeader(Distribution) → `SizedBox(8)` → CategoryDonut → `SizedBox(8)` → DailyVsJoyCard (leaf, public) → `SizedBox(8)` → SatisfactionHistogram → `SizedBox(8)` → PerCategoryBreakdownCard(scope: you/solo) → `if(isGroupMode)` second PerCategoryBreakdownCard(scope: family) → `SizedBox(32)` → SectionHeader(Stories) → `SizedBox(8)` → LargestExpense → `SizedBox(8)` → BestJoy → `if(isGroupMode)` FamilyCard → `SizedBox(64)`. Registry `sectionHeaderKey` + spacer mapping must reproduce this 1:1.

### `_refresh()` derived from registry (D-B2)

**Analog:** current hand-written `_refresh` (lines 214–322), 13 invalidations.

```dart
Future<void> _refresh(WidgetRef ref, AnalyticsCardContext ctx) async {
  final targets = analyticsCardRegistry
      .where((spec) => spec.isVisible(ctx))     // D-B4 gates family specs
      .expand((spec) => spec.refreshTargets(ctx))
      .toSet();                                  // dedupe shared monthlyReport/happinessReport
  for (final p in targets) { ref.invalidate(p); }
  for (final p in shellRefreshTargets(ctx)) { ref.invalidate(p); }  // earliestTransactionMonth
}
```

The current `_refresh` reads `variant = ref.read(selectedJoyMetricVariantProvider)` at refresh time (line 227); the new ctx must carry that same variant so build/refresh keys match (RESEARCH Pitfall 2).

### `test/.../analytics_card_registry_test.dart` (NEW structural test — D-B3)

**Analog:** `home_screen_isolation_test.dart`. Reuse two patterns from it:
1. **Source-grep assertions** (lines 368–388): `File('lib/.../cards/<x>.dart').readAsStringSync()` then `expect(source.contains('home/'), isFalse)` per card file — the physical "cannot import home/*" guarantee.
2. **Provider-union enumeration:** iterate `for (final spec in analyticsCardRegistry) spec.refreshTargets(synthCtx)` over solo + group `AnalyticsCardContext`, assert (a) union ⊆ analytics families, (b) 0 `home/*`, (c) render order non-empty/ordered, (d) family specs absent in solo ctx. RESEARCH A3: with the spec-list shape (closures over plain ctx) this needs **no widget pump** — pass a synthetic ctx directly. The isolation test's `verifyNever(...)` HomeHero-untouched style is the behavioral complement (must stay green — GUARD-01).

---

## Shared Patterns

### Per-card error retry == refreshTargets (single source — D-B2 / "卡就是契约")
**Source:** every inline card's `error` branch (e.g. `_KpiHero` lines 374–384 & 387–396; `_TotalSixMonthCard` 435–443).
**Apply to:** all 7 cards.
Each `error: (_, _) => AnalyticsCardErrorState(onRetry: () => ref.invalidate(<sameProviderKeyedFromBuild>))`. Make the spec's `refreshTargets(ctx)` and the card's retry call ONE top-level `xRefreshTargets(ctx)` function so build/retry/`_refresh` cannot drift (RESEARCH Code Example `categoryDonutRefreshTargets`).

### `AnalyticsCardErrorState` reuse (Don't Hand-Roll)
**Source:** `widgets/analytics_card_error_state.dart` (already imported, line 17). **Apply to:** all card error branches — do not build a new retry widget.

### `_refresh` MUST NOT invalidate any `home/*` provider — promote comment to test (D-B3)
**Source:** comment at lines 222 + `shadowBooksProvider` invalidate at line 304 (the one `home/*` provider in today's union, imported line 7).
**Apply to:** registry union + new test.
**Option A (RESEARCH-recommended):** DROP the direct `ref.invalidate(shadowBooksProvider)`; invalidating `familyHappinessProvider`/`*FamilyProvider` transitively re-reads `shadowBooksProvider.future`. Makes "union ⊆ analytics" literally true. **MUST verify with a group-mode pull-to-refresh test** (Assumption A1) before finalizing.

### Conditional cards via registry `isVisible(ctx)` (D-B4)
**Source:** `if (isGroupMode) ...[ ]` blocks in body (lines 159–172 second PerCategoryBreakdownCard scope:family; 195–205 `_FamilyCard`) and the `if (isGroupMode)` invalidate block in `_refresh` (lines 296–321).
**Apply to:** `family_insight_data_card` spec + the 2nd `PerCategoryBreakdownCard(scope: family)` spec → `isVisible: (ctx) => ctx.isGroupMode`. `_refresh` filters `where(isVisible)` BEFORE `expand(refreshTargets)` so solo mode never invalidates family variants.

### i18n via `S.of(context)` (CLAUDE.md)
**Source:** every card title/caption (e.g. `S.of(context).analyticsCardTitleTotalSixMonth`, line 425). **Apply to:** all moved cards — already compliant; preserve verbatim, no new strings (anti-toxicity gate stays green).

### ADR-012 append-only (D-D1)
**Source rule:** `.claude/rules/arch.md` (append-only after acceptance). **Apply to:** `docs/arch/03-adr/ADR-012_No_Gamification_v1_1.md` — append one `## Update 2026-06-XX:` section after line 127 recording the expense-side 本月vs上月 §4 carve-out; **do NOT edit the decision body, the §🚫 Forbidden list, or the `状态:` header line**.

---

## No Analog Found

| File | Role | Data Flow | Reason / Source to use |
|------|------|-----------|------------------------|
| `presentation/analytics_card_registry.dart` | registry/config | transform | No registry exists in codebase. Use RESEARCH Pattern 1 (`AnalyticsCardSpec` spec-list + `AnalyticsCardContext`). Planner picks spec-list (recommended) vs abstract base. Field set + `shellRefreshTargets` (for `earliestTransactionMonth`) per RESEARCH Open Questions. |

---

## Metadata

**Analog search scope:** `lib/features/analytics/presentation/{screens,widgets,providers}/`, `test/widget/features/home/.../home_screen_isolation_test.dart`, `.claude/rules/arch.md`.
**Files scanned:** `analytics_screen.dart` (full 739 LOC), `daily_vs_joy_card.dart` (header), `home_screen_isolation_test.dart` (full).
**Pattern extraction date:** 2026-06-17
