# Phase 47: i18n + 反毒性 + macOS golden + 全量门禁 + UAT - Pattern Map

**Mapped:** 2026-06-17
**Files analyzed:** 18 (4 WR-fix source edits, 3 ARB edits + generated, 8 new golden tests, 1 new anti-toxicity test, 2 unit-test updates)
**Analogs found:** 18 / 18 (every paradigm exists in-tree — this is a reuse-fidelity phase, zero net-new patterns)

> **Phase nature:** validation/hardening of the Phase-46 round-5 B analytics page. NO new screens, cards, or data paths. Each new file copies an existing analog **verbatim**; each modified file is a surgical edit at an identified line. The risk this phase guards against is *divergence from the locked pattern*, not novel design.

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `test/widget/.../anti_toxicity_phase47_test.dart` (NEW) | test (widget sweep) | transform/assert | `anti_toxicity_phase16_test.dart` | exact |
| `test/golden/category_donut_card_golden_test.dart` (NEW) | test (golden) | render-assert | `per_category_breakdown_card_golden_test.dart` | exact |
| `test/golden/joy_spend_card_golden_test.dart` (NEW) | test (golden) | render-assert | `per_category_breakdown_card_golden_test.dart` | exact |
| `test/golden/joy_calendar_card_golden_test.dart` (NEW, +inline-expand) | test (golden) | render-assert | `per_category_breakdown_card_golden_test.dart` | exact |
| `test/golden/satisfaction_histogram_card_golden_test.dart` (NEW) | test (golden) | render-assert | `per_category_breakdown_card_golden_test.dart` | exact |
| `test/golden/within_month_trend_card_golden_test.dart` (NEW) | test (golden) | render-assert | `per_category_breakdown_card_golden_test.dart` | exact |
| `test/golden/family_insight_data_card_golden_test.dart` (NEW, group-mode) | test (golden) | render-assert | `daily_vs_joy_card_golden_test.dart` (group variant) | role+flow |
| `test/golden/category_drill_down_screen_golden_test.dart` (NEW) | test (golden, screen) | render-assert | `per_category_breakdown_card_golden_test.dart` | role-match |
| `test/golden/analytics_screen_scroll_smoke_golden_test.dart` (NEW, full-page) | test (golden, screen) | render-assert | `home_hero_card_golden_test.dart` (full theme wrap) | role-match |
| `test/golden/goldens/*.png` (≈30+ NEW) | test fixture (baseline) | — | `test/golden/goldens/per_category_breakdown_card_*.png` | exact |
| `lib/.../cards/category_donut_card.dart` (MODIFY, WR-01/02) | component (card) | transform/render | self (Phase-46 surgical edit at lines 200-211) | self |
| `lib/.../analytics_card_registry.dart` (MODIFY, WR-01) | provider/registry | wiring | self (delete `currencyCode` lines 39/54/114-118/131) | self |
| `lib/application/analytics/get_joy_category_amounts_use_case.dart` (MODIFY, WR-03) | service (use case) | batch/transform | self (rewrite loop lines 74-92) | self |
| `lib/.../cards/joy_calendar_card.dart` (MODIFY, WR-04) | component (card) | event-driven (refresh) | self (`joyCalendarRefreshTargets` line 99) | self |
| `lib/.../cards/joy_spend_card.dart` + `satisfaction_histogram_card.dart` (MODIFY, WR-01) | component (card) | render | self (drop `ctx.currencyCode` arg) | self |
| `lib/l10n/app_{en,ja,zh}.arb` (MODIFY, D-15) | config (i18n) | — | self (delete lines 1955-1957 symmetric ×3) | self |
| `lib/generated/*.dart` (REGENERATE) | build artifact | — | `flutter gen-l10n` output | tooling |
| `test/.../analytics_card_registry_test.dart` + `get_joy_category_amounts_use_case_test.dart` (MODIFY) | test (unit) | assert | self (existing tests, update for WR-01/03) | self |

---

## Pattern Assignments

### `anti_toxicity_phase47_test.dart` (test, sweep) — D-14

**Analog:** `test/widget/features/analytics/presentation/widgets/anti_toxicity_phase16_test.dart` — **copy verbatim**, swap in the 5 round-5 B cards.

**LOCKED forbidden lists** (phase16 lines 33-78) — **REUSE, never relax** (D-13). Copy `forbiddenEn`/`forbiddenJa`/`forbiddenZh` and the `_forbiddenFor(locale)` switch (lines 82-92) byte-for-byte.

**Harness + local-override discipline** (phase16 lines 184-261) — the load-bearing nuance: keep each state's `overrideWith` list **LOCAL and complete** so an unoverridden auto-dispose provider throws loudly instead of silently passing the sweep (RESEARCH Pitfall 1). Example shape:
```dart
List<Override> _perCategoryValueSoloOverrides() => [
      perCategoryJoyBreakdownProvider(bookId: _bookId, startDate: _startDate, endDate: _endDate)
        .overrideWith((_) async => Value(_breakdownValue(), 12)),
    ];
```

**Sweep helper** (phase16 lines 269-285) — copy `_sweepForbiddenSubstrings`; it uses `find.textContaining(substring, findRichText: true)` → `findsNothing` with a triage-friendly `reason`. Always `await tester.pumpAndSettle()` before sweeping.

**Localized harness:** `createLocalizedWidget(card, locale:, overrides:)` from `test/helpers/test_localizations.dart` (phase16 line 11 import).

**New coverage required:** 5 cards × `[en, ja, zh]` × states. The WR-02 ">10-L1-category" donut fixture state MUST be present so the `analyticsCategoryDonutOther` ("その他"/"其他"/"Other") label is exercised and sweeps clean (D-03 / UI-SPEC Copywriting).

---

### `*_card_golden_test.dart` (test, golden) — GUARD-04 / D-06..D-09

**Analog:** `test/golden/per_category_breakdown_card_golden_test.dart` — the canonical per-card golden harness.

**Library tag + imports** (lines 1-13):
```dart
@Tags(['golden'])
library;
// flutter_localizations, flutter_riverpod (+ misc), flutter_test,
// the card + its providers, home_pocket/generated/app_localizations.dart
```

**`_wrap` harness** (lines 54-92): `ProviderScope(overrides:[...], child: MaterialApp(locale:, localizationsDelegates: [S.delegate, GlobalMaterial/Widgets/Cupertino...], supportedLocales: S.supportedLocales, theme:, home: Scaffold(body: Center(child: SizedBox(w, h, child: SingleChildScrollView(card))))))`.

**Deterministic fixture** (lines 38-52): seed from the 43-01 sample-data numbers as a Dart fixture (the source is `.md`, not a Dart symbol — RESEARCH A1). Pattern: `_fixtureFiveWithOther()`.

**Settled count-up + assertion** (lines 96-116):
```dart
await tester.pumpAndSettle();   // drains TweenAnimationBuilder count-up to IntTween.end (D-09)
await expectLater(find.byType(CategoryDonutCard),
  matchesGoldenFile('goldens/category_donut_card_light_ja.png'));
```

**Theme fidelity (DIVERGE from base analog — resolves Open-Q1/A4):** `per_category_breakdown_card` uses bare `ThemeData.light()/.dark()`, which does NOT resolve `context.palette` (ADR-019 `AppPalette`). The new analytics goldens SHOULD wrap the **production `AppTheme`** so the goldens are real palette-regression detectors (critical for the WR-02 neutral "Other" swatch). Confirm the wrap against `home_hero_card_golden_test.dart` lines 99-100 (`theme: ...`, `darkTheme: ...`). **Planner decision point** — UI-SPEC §Theme Fidelity directs production-theme wrapping.

**macOS-only baselining** (RESEARCH): `flutter test --update-goldens --tags golden` on macOS → commit `goldens/*.png`. NEVER re-baseline on CI/ubuntu (`test/flutter_test_config.dart` + `BaselineExistenceGoldenComparator` reduce off-macOS to existence-only).

**Naming convention** (from existing baselines): `<card>_<theme>_<locale>.png` and `<card>_<state>_<theme>_<locale>.png` (e.g. `per_category_breakdown_card_group_light_ja.png`).

**Group-mode card** (`family_insight_data_card_golden_test.dart`, D-08③): mirror the `daily_vs_joy_card` group goldens — override the `*FamilyProvider` variant (see phase16 lines 214-218, 243-248 for the family-provider override shape).

**Full-page smoke** (`analytics_screen_scroll_smoke_golden_test.dart`, D-07): single ja/light master of `AnalyticsScreen` verifying card ORDER; wrap in production `AppTheme` like `home_hero_card_golden_test.dart`.

---

### `category_donut_card.dart` (component, MODIFY) — WR-01 + WR-02

**Self-edit** at the legend-build block (lines 200-219). Current code divides percent by the truncated `donutTotal`:
```dart
amount: NumberFormatter.formatCurrency(entry.value.amount, 'JPY', locale),
percent: donutTotal > 0 ? (entry.value.amount / donutTotal * 100).round() : 0,
```
**WR-01 (D-02):** the `'JPY'` literal STAYS literal — just stop reading `ctx.currencyCode` (field is being deleted). **WR-02 (D-03):** change the percent divisor from `donutTotal` to the **true** `total` (= `monthly.totalExpenses`); append a synthetic "Other" slice of `total - donutTotal` when positive; center count-up keeps `end: total`. The "Other" label REUSES `S.of(context).analyticsCategoryDonutOther` (existing, trilingual — RESEARCH line 96). The "Other" legend row is **non-tappable** (no `onTap` Navigator.push) and uses a neutral grey-family swatch from `context.palette` (UI-SPEC §WR-02 color), NOT the `_colorFor` daily→joy lerp (lines 224-229). Rollup stays via `rollupCategoryBreakdownsToL1(topN: 10)` (D-11 single source — `category_l1_rollup.dart`).

---

### `analytics_card_registry.dart` (registry, MODIFY) — WR-01 / D-02

**Self-edit** — DELETE the dead `currencyCode` plumbing (not wire it):
- field declaration line 54 (`final String currencyCode;`) + constructor param line 39
- the `final currencyCode = ref.watch(bookByIdProvider...).value?.currency ?? 'JPY';` block (lines 114-118)
- the `currencyCode: currencyCode,` ctx assignment (line 131)
- the `currencyCode: ctx.currencyCode,` card-arg pass-throughs (line 217 + joy_spend/satisfaction_histogram call sites)

`joyCalendarRefreshTargets` (referenced line 208) stays as the single-source refresh union.

---

### `get_joy_category_amounts_use_case.dart` (service, MODIFY) — WR-03 / D-04

**Self-edit** — replace the O(n·k) two-loop (lines 74-92: collect distinct `l1Ids` set, then call `l1RollupFromTransactions` per L1) with a single-pass accumulate, and **fix the lying docstring** (lines 18-20 claim "There is NO second rollup loop here" — false today). Pattern (RESEARCH §Pattern 4, mirrors the rollup helper):
```dart
final acc = <String, int>{};
for (final tx in expenseTxns) {
  final l1 = l1AncestorOf(tx.categoryId, categoryMap) ?? tx.categoryId;  // D-11 single source intact
  acc[l1] = (acc[l1] ?? 0) + tx.amount;
}
final buckets = [
  for (final e in acc.entries) if (e.value > 0)
    JoyCategoryAmount(categoryId: e.key, amount: e.value),
]..sort((a, b) => b.amount.compareTo(a.amount));
```
Security carry-over (RESEARCH V7): keep aggregate-only ints, no per-tx logging, do NOT widen the `findByBookIds([bookId], joy)` set.

---

### `joy_calendar_card.dart` (component, MODIFY) — WR-04 / D-05

**Self-edit** at `joyCalendarRefreshTargets` (line 99) and `_InlineDayPanel`/`_JoyCalendarBodyState`. Currently the union returns only `perDayJoyCountsProvider` (line 102). 46-REVIEW option (a): have the expanded-day panel invalidate its own `joyDayTransactionsProvider(bookId, selectedDay, joyMetricVariant)` (read at line 193) on the refresh signal, so pull-to-refresh re-fetches the expanded day's inline list alongside the heatmap count. `selectedDay` is local `_JoyCalendarBodyState` state (NOT in `AnalyticsCardContext`) — invalidate from the panel, not the registry union. **Constraint:** must NOT add any `home/*` provider to the union (ADR-016 / GUARD-01); `joyDayTransactionsProvider` is an analytics provider so union ⊆ analytics holds.

---

### `app_{en,ja,zh}.arb` + `lib/generated/` (config, MODIFY) — D-15

**Self-edit** — delete the 3 orphan section-header keys **symmetrically from all 3 files** (verified `app_ja.arb:1955-1957`; same in en/zh + any `@`-metadata twins):
```
"analyticsGroupHeaderTime" / "analyticsGroupHeaderDistribution" / "analyticsGroupHeaderStories"
```
Then: `flutter gen-l10n` → **`git add -f lib/generated/`** (gitignored-yet-tracked gotcha, MEMORY Phase 46 — plain add is rejected, leaving stale generated Dart → analyze fails from clean tree). Verify with `arb_key_parity_test.dart` + `flutter analyze`. Do NOT touch `analyticsCategoryDonutOther` (line 2006 — needed by WR-02).

---

## Shared Patterns

### Anti-toxicity sweep (GUARD-02-wording / GUARD-03)
**Source:** `anti_toxicity_phase16_test.dart` lines 33-92 (LOCKED lists) + 269-285 (sweep helper).
**Apply to:** the new `anti_toxicity_phase47_test.dart`. Reuse the locked lists verbatim; never relax (ADR sign-off required). Fix offending COPY, not the list.

### Golden harness + macOS baselining (GUARD-04)
**Source:** `per_category_breakdown_card_golden_test.dart` lines 1-13, 54-116 + `home_hero_card_golden_test.dart` lines 99-100 (production-theme wrap).
**Apply to:** all 8 new golden test files. `@Tags(['golden'])` + `pumpAndSettle()` before `expectLater` (count-up settling, RESEARCH Pitfall 2). Baseline on macOS only.

### Off-macOS golden gate (auto-applied)
**Source:** `test/flutter_test_config.dart` + `test/helpers/ci_golden_comparator.dart` (`BaselineExistenceGoldenComparator`).
**Apply to:** every golden test automatically — NO per-test config needed (RESEARCH "Don't Hand-Roll").

### L1 rollup single source (D-11)
**Source:** `lib/features/analytics/domain/category_l1_rollup.dart` (`l1AncestorOf`, `rollupCategoryBreakdownsToL1`, `l1RollupFromTransactions`).
**Apply to:** WR-02 (donut display) + WR-03 (joy use case). Both route through `l1AncestorOf`; donut==drill math must not diverge.

### Localized widget harness
**Source:** `createLocalizedWidget` in `test/helpers/test_localizations.dart`.
**Apply to:** every anti-toxicity sweep state.

### Neutral "Other" label (zero new ARB surface)
**Source:** existing trilingual key `analyticsCategoryDonutOther` (`app_*.arb:2006`).
**Apply to:** WR-02 "Other" rollup slice/legend. No new key.

### Full-suite wave gate (non-negotiable)
**Source:** project convention + MEMORY Phase 38.
**Apply to:** every wave merge — `flutter test` FULL (never a subset), must include `home_screen_isolation_test`, all 3 anti-toxicity sweeps (16/17/47), `arb_key_parity_test`, `hardcoded_cjk_ui_scan`, `color_literal_scan`, `stale_suppressions_scan` + `flutter analyze` 0 issues + `--coverage` ≥80%.

---

## No Analog Found

| File | Role | Reason |
|------|------|--------|
| (none) | — | Every surface has an in-tree analog. The on-device UAT (GUARD-05) is a manual `checkpoint:human-verify` step with no code artifact — see UI-SPEC §UAT Visual Checklist (D-10), blocking per D-12. |

---

## Metadata

**Analog search scope:** `test/widget/features/analytics/`, `test/golden/` (+ `goldens/`), `test/helpers/`, `lib/features/analytics/presentation/` (cards/, screens/, registry), `lib/application/analytics/`, `lib/features/analytics/domain/`, `lib/l10n/`.
**Files scanned:** ~20 (read: phase16 sweep, per-category golden harness, donut card, registry, joy use case, calendar card, drill screen, ARB ja; grepped: home_hero golden theme wrap, golden baseline naming, refresh-target wiring).
**Pattern extraction date:** 2026-06-17
