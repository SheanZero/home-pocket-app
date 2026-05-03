---
phase: 10-homepage-soulfullnesscard-redesign
verified: 2026-05-02T00:00:00Z
status: passed
score: 11/11 must-haves verified
overrides_applied: 0
human_verification:
  - test: "Visual fidelity vs Pencil v8 mockups (cards HmvHU single light / NMHwT family light / VKoU4 family dark)"
    expected: "Rendered HomeHeroCard matches structural and proportional fidelity of the source-of-truth Pencil cards (pixel-precise replication NOT required, per CONTEXT line 247)"
    why_human: "Already approved by user as Plan 10-11 Task 11.3 (human-verify checkpoint). Treated as PASSED per verifier instructions."
---

# Phase 10: HomePage SoulFullnessCard Redesign Verification Report

**Phase Goal:** Build single integrated HomeHeroCard absorbing MonthOverviewCard + LedgerComparisonSection + SoulFullnessCard. Render 4 personal metrics + Best Joy story strip + family group-mode members section with consent gate. Replace misleading "Happiness ROI".

**Verified:** 2026-05-02
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (ROADMAP.md Success Criteria)

| #   | Truth | Status | Evidence |
| --- | ----- | ------ | -------- |
| 1 | HomePage renders a single `HomeHeroCard` widget (no `MonthOverviewCard`, `LedgerComparisonSection`, or `SoulFullnessCard` widgets exist in `lib/features/home/presentation/widgets/`) | ✓ VERIFIED | `ls lib/features/home/presentation/widgets/` shows only `home_hero_card.dart` (no legacy 3 widgets). `grep -rn "MonthOverviewCard\|LedgerComparisonSection\|SoulFullnessCard" lib/` returns 0 matches. `home_screen.dart:161` instantiates exactly one `HomeHeroCard`. |
| 2 | `HomeHeroCard` renders all 4 personal metrics (Avg Satisfaction, Joy per ¥, Highlights count, Best Joy per ¥) with values sourced exclusively from Phase 9 use cases | ✓ VERIFIED | `home_hero_card.dart:380-403` reads `happiness.joyPerYen`, `happiness.avgSatisfaction`, `happiness.highlightsCount` (rings) + `bestJoy: MetricResult<BestJoyMomentRow>` (Best Joy strip). All 4 sourced from Phase 9 providers `happinessReportProvider` + `bestJoyMomentProvider` (`home_screen.dart:98-112`). Widget test "renders all 4 personal metrics from HappinessReport" passes. |
| 3 | `HomeHeroCard` displays 3 concentric gradient rings encoding `HappinessReport` in single mode and `FamilyHappiness` in group mode | ✓ VERIFIED | `happiness_rings_painter.dart` paints 3 concentric arcs at radii `r - 0`, `r - (strokeWidth+gap)`, `r - 2*(strokeWidth+gap)` with `SweepGradient` per ring. `_painter()` in `home_hero_card.dart:340-378` switches between `HappinessReport` (single) and `FamilyHappiness` (group). 9 painter tests pass; widget test "renders FamilyHappiness rings when isGroupMode" passes. |
| 4 | Best Joy story strip renders the single argmax transaction with `category · date` BIG (fontSize 14) and `¥amount · 满足 X/10 ✨` small (fontSize 9) — anti-`¥10 candy` framing per D-04 | ✓ VERIFIED | `_bestJoyValue()` (line 620-673) renders 3 stacked Text widgets: tag (fontSize 9, AppColors.shared), big (`'$category · $dateLabel'`, fontSize 14, FontWeight.w700), small (l10n `homeBestJoyAmountSat({amount}, {sat})` fontSize 9, tabularFigures). ARB key resolves to `'{amount} · 满足 {sat}/10 ✨'` (zh) / `'{amount}・満足 {sat}/10 ✨'` (ja). Widget tests pass. |
| 5 | Family card region (rings + member rows) visible only when `isGroupModeProvider == true` AND `shadowBooks.isNotEmpty`; collapses entirely otherwise (D-08 minimum gate) | ✓ VERIFIED | `home_hero_card.dart:66`: `final showMembers = isGroupMode && (shadowBooks?.isNotEmpty ?? false);` Members section gated at line 92 (`if (showMembers)`). `_buildMembersSection()` (line 676-699) double-checks the gate. Group rings only chosen when `isGroupMode == true` (line 342). Tests "hides member rows section when shadowBooks.isEmpty" + "hides family region entirely when isGroupMode == false" pass. |
| 6 | Coverage caption visible on headline metric tile when `0 < totalSoulTx`; ≤2 `ⓘ` icons in the entire card | ✓ VERIFIED | Coverage caption: `home_hero_card.dart:500-508`: `if (happiness.totalSoulTx > 0) ... l10n.homeCoverageCaption(_rated(happiness), happiness.totalSoulTx)`. Info icons: `grep -c "_InfoIcon(\|_InfoIcon  *("` returns **2** (lines 305 + 481). Widget test "exactly 2 Icons.info_outline instances total" passes. |
| 7 | `_computeHappinessROI`, `_computeSatisfaction`, `_buildLedgerRows` are gone from `home_screen.dart` (`grep` returns zero matches in `lib/`) | ✓ VERIFIED | `grep -rn "_computeHappinessROI\|_computeSatisfaction\|_buildLedgerRows" lib/` → **0 matches**. |
| 8 | `home_screen.dart` net line count DECREASES (currently 386 lines; post-Phase-10 must be < 386) | ✓ VERIFIED | `wc -l lib/features/home/presentation/screens/home_screen.dart` → **331 lines** (was 386, decrease of 55 lines). |
| 9 | All ¥ amounts use `AppTextStyles.amountLarge/Medium/Small` (`FontFeature.tabularFigures()`); zero hardcoded `'JPY'` in `home_hero_card.dart` | ✓ VERIFIED | `home_hero_card.dart` uses `AppTextStyles.amountLarge` (hero total, line 134), `amountMedium` (ring center, line 324), `amountSmall` (split labels line 261, member rows line 744). `grep "'JPY'" home_hero_card.dart` → **0 matches**. The single `'JPY'` literal is in `home_screen.dart:96` as a fallback when Book is null (legitimate per CLAUDE.md Pitfall #9). Best Joy small line includes explicit `FontFeature.tabularFigures()` (line 667). |
| 10 | All UI strings via `S.of(context)`; ARB keys added to all 3 locales (ja/zh/en); `flutter gen-l10n` regenerates without warnings; ARB-parity CI guardrail green | ✓ VERIFIED | All visible text in `home_hero_card.dart` references `l10n.<key>` (no hardcoded user-facing strings detected). 24+ Phase 10 ARB keys present in all 3 locales: `homeHeroCardLabelSingle/Group`, `homeHeroPreviousMonthSubline`, `homeRingSectionTitleSingle/Group`, `homeJoyIndexTooltip`, `homeJoyPerYenTooltip`, `homeBestJoyTagSingle/Group`, `homeBestJoyAmountSat`, `homeBestJoyEmptyTagPrimary/Big/Small`, `homeBestJoyAllNeutralBig/Small`, `homeMembersSectionTitle`, `homeNoSoulDataLegend`, `homeCoverageCaption`, `homeAvgSatisfactionLegend`, `homeJoyPerYenLegend`, `homeHighlightsCountLegend`, `homeFamilyHighlightsLegend`, `homeSharedJoyLegend`, `homeMedianSatisfactionLegend`. ARB key parity: 391 keys in each of `app_ja.arb` / `app_zh.arb` / `app_en.arb`. |
| 11 | `flutter analyze lib/features/home/` reports 0 issues | ✓ VERIFIED | `flutter analyze lib/features/home/` → "No issues found! (ran in 1.1s)". Full project `flutter analyze` → "No issues found! (ran in 2.1s)". |

**Score:** 11/11 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `lib/features/home/presentation/widgets/home_hero_card.dart` | New integrated hero card; renders 4 metrics, rings, Best Joy strip, member rows | ✓ VERIFIED | 802 lines; `StatelessWidget`; consumes Freezed aggregates (Container Widget With Async Provider pattern). Imported + instantiated by `home_screen.dart:24,161`. |
| `lib/features/home/presentation/widgets/painter/happiness_rings_painter.dart` | Custom painter for 3 concentric gradient rings with `Empty/Value` semantics | ✓ VERIFIED | 118 lines; pure `CustomPainter`; `Empty()` → null ratio → track only; `Value()` → ratio + fill arc. Used inside `home_hero_card.dart:318-321`. 9 painter tests pass. |
| `lib/features/home/presentation/screens/home_screen.dart` | Wires providers to `HomeHeroCard`; deletes 3 old widgets + 3 helper methods | ✓ VERIFIED | 331 lines (was 386, -55 lines); calls `monthlyReportProvider`, `bookByIdProvider`, `happinessReportProvider`, `bestJoyMomentProvider`, `familyHappinessProvider`, `shadowBooksProvider`, `shadowAggregateProvider`, `currentLocaleProvider`, `isGroupModeProvider`. Tap navigation: `AnalyticsScreen(bookId: bookId)` (line 174 — `AnalyticsRegion` deferred to Phase 11 per D-11). |
| `lib/features/accounting/presentation/providers/repository_providers.dart` | `bookByIdProvider` for currency-code resolution (D-12) | ✓ VERIFIED | Line 62: `Future<Book?> bookById(Ref ref, {required String bookId})`. Generated provider used at `home_screen.dart:88`. |
| `test/widget/features/home/presentation/widgets/home_hero_card_test.dart` | Widget tests covering all SCs | ✓ VERIFIED | **20 tests pass**: single-mode metrics (HOMEUI-01/05/06), group-mode rings + members (HOMEUI-03/07, FAMILY-03), empty states (D-09 — 4 variants), info icons (HOMEUI-04 — exactly 2), tap target (D-11), typography (Pitfall #10), currency resolution (Pitfall #9), i18n parity (ja/zh/en). |
| `test/golden/home_hero_card_golden_test.dart` + 5 PNGs | Golden tests for all card variants | ✓ VERIFIED | 5 tests pass; 5 PNGs present: `home_hero_card_single_light_ja.png`, `home_hero_card_family_light_ja.png`, `home_hero_card_family_dark_ja.png`, `home_hero_card_thin_sample_ja.png`, `home_hero_card_all_neutral_cta_ja.png`. |
| `test/widget/features/home/presentation/widgets/painter/happiness_rings_painter_test.dart` | Painter unit tests | ✓ VERIFIED | 8 tests pass: track always renders, mixed Empty/Value, all-Value, sweep ratios (0.5 → π, 1.5 clamps to 2π, 0 skips fill), `shouldRepaint` correctness. |
| `lib/l10n/app_{ja,zh,en}.arb` | 24+ new ARB keys, parity across 3 locales | ✓ VERIFIED | 391 keys in each ARB file. All Phase 10 keys present in all 3 locales. |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | -- | --- | ------ | ------- |
| `HomeScreen` → `HomeHeroCard` | rendering | `home_screen.dart:161` constructor | ✓ WIRED | Constructor receives all 10 required params: `report`, `happiness`, `bestJoy`, `family`, `shadowBooks`, `shadowAggregate`, `currencyCode`, `locale`, `isGroupMode`, `onTap`. |
| `HomeScreen` → `bookByIdProvider` | currency code | `ref.watch(bookByIdProvider(bookId: bookId))` | ✓ WIRED | Line 87-89; `bookAsync.valueOrNull?.currency ?? 'JPY'` at line 96 (fallback only). |
| `HomeScreen` → Phase 9 providers | data | `ref.watch(happinessReportProvider/bestJoyMomentProvider/familyHappinessProvider)` | ✓ WIRED | Lines 98-128. Group-mode providers short-circuit to `AsyncData(null/[])` via `isGroupMode ? ref.watch(...) : AsyncData(null)`. |
| `HomeScreen` → `AnalyticsScreen` | tap navigation | `Navigator.push` `MaterialPageRoute` | ⚠️ PARTIAL | Lines 171-176: navigates to `AnalyticsScreen(bookId: bookId)` without `AnalyticsRegion.joyLedger` param. Per CONTEXT D-11, this is acceptable: "If `AnalyticsRegion.joyLedger` doesn't exist yet (Phase 11 work), Phase 10 may use a placeholder route". The Phase 11 sub-region itself is a deferred deliverable. |
| `HomeHeroCard` → `HappinessRingsPainter` | rings rendering | `CustomPaint(painter: _painter(context))` | ✓ WIRED | Line 318-321; `_painter()` switches on `isGroupMode` to select gradient + ratio source. |
| `HomeHeroCard` → `FormatterService` | currency formatting | `_fmt.formatCurrency(amount, currencyCode, locale)` | ✓ WIRED | Lines 133, 145, 190, 191, 631, 707. No hardcoded JPY. |
| `HomeHeroCard` → `MetricResult` sealed pattern matching | empty/value branching | `switch (result) { Empty() ... Value(:final data) ... }` | ✓ WIRED | Lines 380-403 (rings), 435-459 (legend group), 466-499 (legend single), 513-516 (rated count), 560-575 (Best Joy strip). |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| -------- | ------------- | ------ | ------------------ | ------ |
| `HomeHeroCard.report` (`MonthlyReport`) | `report.totalExpenses`, `report.soulTotal`, `report.survivalTotal`, `report.previousMonthComparison?.previousExpenses` | `monthlyReportProvider` (Phase 9 use case → DAO) | Yes (DB-backed Drift query in `lib/data/daos/transactions_dao.dart` via `getMonthlyReport`) | ✓ FLOWING |
| `HomeHeroCard.happiness` (`HappinessReport`) | `happiness.joyPerYen`, `happiness.avgSatisfaction`, `happiness.highlightsCount`, `happiness.totalSoulTx` | `happinessReportProvider` (Phase 9 `GetHappinessReportUseCase` → DAO) | Yes (DB-backed; Phase 9-verified flow) | ✓ FLOWING |
| `HomeHeroCard.bestJoy` (`MetricResult<BestJoyMomentRow>`) | `bestJoy.data` (transactionId, amount, soulSatisfaction, categoryId, timestamp) | `bestJoyMomentProvider` (Phase 9 use case → DAO with `_soulOnly()` guard) | Yes (DB-backed argmax query) | ✓ FLOWING |
| `HomeHeroCard.family` (`FamilyHappiness?`) | `family.familyHighlightsSum`, `family.sharedJoyInsight`, `family.medianSatisfaction` | `familyHappinessProvider` (Phase 9 use case + group aggregation) | Yes when group mode + shadowBooks present | ✓ FLOWING |
| `HomeHeroCard.shadowBooks` + `shadowAggregate` | per-member name, avatar, monthly expenses | `shadowBooksProvider` + `shadowAggregateProvider` (`state_shadow_books.dart`) | Yes (loops over registered shadow books with per-book monthly aggregation) | ✓ FLOWING |
| `HomeHeroCard.currencyCode` | `Book.currency` string | `bookByIdProvider` → DB Book row | Yes (with safe `'JPY'` fallback when book absent) | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| All 1355 project tests pass | `flutter test` | "All tests passed!" (1355/1355) | ✓ PASS |
| HomeHeroCard widget tests pass | `flutter test test/widget/features/home/presentation/widgets/home_hero_card_test.dart` | 20/20 passed | ✓ PASS |
| Painter tests pass | `flutter test test/widget/features/home/presentation/widgets/painter/happiness_rings_painter_test.dart` | 8/8 passed | ✓ PASS |
| Golden tests pass | `flutter test test/golden/home_hero_card_golden_test.dart` | 5/5 passed | ✓ PASS |
| `flutter analyze` clean | `flutter analyze` | "No issues found!" | ✓ PASS |
| `flutter analyze lib/features/home/` clean | `flutter analyze lib/features/home/` | "No issues found!" | ✓ PASS |
| Forbidden helpers removed | `grep -rn "_computeHappinessROI\|_computeSatisfaction\|_buildLedgerRows" lib/` | 0 matches | ✓ PASS |
| Old widgets removed | `grep -rn "MonthOverviewCard\|LedgerComparisonSection\|SoulFullnessCard" lib/` | 0 matches | ✓ PASS |
| `home_screen.dart` line decrease | `wc -l lib/features/home/presentation/screens/home_screen.dart` | 331 lines (< 386 baseline) | ✓ PASS |
| `'JPY'` literal removed from card body | `grep "'JPY'" lib/features/home/presentation/widgets/home_hero_card.dart` | 0 matches | ✓ PASS |
| Exactly 2 info icons | `grep -c "_InfoIcon(" home_hero_card.dart` | 2 | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ----------- | ----------- | ------ | -------- |
| FAMILY-03 | Plan 10-07a/b | Family card consent gate (minimum-gate per D-08): renders iff `isGroupModeProvider == true && shadowBooks.isNotEmpty` | ✓ SATISFIED | `home_hero_card.dart:66,92,679`. Strict per-member opt-in semantic explicitly DEFERRED to v1.2 (`FAMILY-V2-03`) per CONTEXT D-08 / REQUIREMENTS.md. Widget test "hides family region entirely when isGroupMode == false" passes. |
| HOMEUI-01 | Plan 10-07a/b | `SoulFullnessCard` rebuilt to render the 4 personal happiness metrics (Avg Satisfaction, Joy per ¥, Highlights count, Best Joy per ¥ story card) | ✓ SATISFIED | All 4 metrics rendered (rings + legend + Best Joy strip). Widget test "renders all 4 personal metrics from HappinessReport" passes. |
| HOMEUI-02 | Phase 9 + Plan 10-04/05 | `_computeHappinessROI` and `_computeSatisfaction` deleted from `home_screen.dart`; responsibilities now in `GetHappinessReportUseCase` | ✓ SATISFIED | `grep` returns 0 matches in `lib/`. Phase 9 `GetHappinessReportUseCase` owns these computations. |
| HOMEUI-03 | Plan 10-07a/b | Family card (FAMILY-01 + FAMILY-02) conditionally rendered when `isGroupModeProvider == true`; respects FAMILY-03 consent gate | ✓ SATISFIED | Group-mode rings + member section conditionally rendered (lines 92, 342). |
| HOMEUI-04 | Plan 10-07b | At most 2 `ⓘ` info icons; coverage caption visible on headline metric tile; no daily-target / streak / badge copy | ✓ SATISFIED | Exactly 2 `_InfoIcon` usages (lines 305, 481). Coverage caption at line 500-508. `grep "streak\|badge\|daily.target"` only matches `hero_header.dart` mode badge (NOT gamification). Voice estimator copy explicitly removed per D-10. |
| HOMEUI-05 | Plan 10-07a/b | Hero card absorbs total monthly spending + month-over-month delta chip + previous-month amount; replaces `MonthOverviewCard` | ✓ SATISFIED | `_hero()` (lines 106-153): total + trend chip + previous-month sub-line. Widget test "hero header renders total + +X% trend chip + previous-month sub-line" passes. |
| HOMEUI-06 | Plan 10-07a/b | 魂/生存 absolute amount split via inline horizontal split bar; ABSOLUTE Yen labels (NOT percentages); replaces `LedgerComparisonSection` | ✓ SATISFIED | `_splitBar()` (lines 185-241): renders absolute soul/survival amounts via `_fmt.formatCurrency(soul, ...)`. Widget test "split bar renders 魂帳 / 生存帳 absolute amounts (no % glyph)" passes. |
| HOMEUI-07 | Plan 10-07b | In group mode, hero card appends per-member monthly spending rows after Best Joy strip (avatar + member name + ¥amount per row) | ✓ SATISFIED | `_buildMembersSection()` (lines 676-699) + `_memberRow()` (lines 701-751). Widget test "renders 3 member rows after Best Joy strip with avatar + name + ¥amount" passes. |

**No orphaned requirements:** All 8 IDs (FAMILY-03, HOMEUI-01..07) are mapped to Phase 10 in REQUIREMENTS.md and accounted for in plan SUMMARYs.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| `home_screen.dart` | 96 | `bookAsync.valueOrNull?.currency ?? 'JPY'` | ℹ️ INFO | Documented legitimate fallback per CLAUDE.md Pitfall #9 (line-comment explains it is "the SOLE legitimate JPY currency-code literal"). NOT in `home_hero_card.dart` (where SC#9 forbids it). |
| `home_screen.dart` | 219 | `// TODO: Navigate to full transaction list` | ℹ️ INFO | Pre-existing TODO unrelated to Phase 10 (transaction list view-all is out of scope). |
| `home_screen.dart` | 190 | `// TODO: Wire GroupBar with actual group data when available` | ℹ️ INFO | Pre-existing TODO unrelated to Phase 10. |
| `home_screen.dart` | 174 | `AnalyticsScreen(bookId: bookId)` (no `initialRegion: AnalyticsRegion.joyLedger`) | ℹ️ INFO | Per CONTEXT D-11, `AnalyticsRegion` enum is Phase 11 work; placeholder route is allowed. Tap navigation to AnalyticsScreen IS wired and functional. |

**No blockers detected.** All anti-patterns are either documented exceptions or pre-existing TODOs outside Phase 10 scope.

### Human Verification Required

The Phase 10 plan included a mandatory human-verify checkpoint (Plan 10-11 Task 11.3) to compare the rendered card against Pencil v8 mockups (`HmvHU` / `NMHwT` / `VKoU4`). Per the verifier instructions, this checkpoint was approved by the user — treated as PASSED.

### Notable Reconciliations

- **UI-SPEC §84 vs Plan must-have on member-row amount style:** Member-row amount uses `AppTextStyles.amountSmall` (per Plan 10-07b must-have, line 744 of `home_hero_card.dart`); UI-SPEC §84 specifies `amountMedium`. Plan wins (per verifier note). Possible future reconciliation but not a Phase 10 blocker.
- **Rule 3 auto-fix deviations** (8 documented in 10-07a/b SUMMARYs): codebase-API drift adjustments (e.g., `bestJoy` is `MetricResult` not nullable, `homeBestJoyAmountSat` ARB-key choice, `ShadowBookInfo.memberDisplayName/memberAvatarEmoji` field names). All documented and verified to match shipped APIs.
- **Plan 10-08b orchestrator finalization:** Plan stalled at watchdog after work was complete on disk; orchestrator finalized without rerunning. Code state on disk reflects completed work; tests + analyze green confirm.
- **Plan 10-11 reduced to no-op audit + human-verify checkpoint:** Plans 10-07a/b already used theme tokens correctly, so the color-polish plan reduced to verification (0 source files modified, all golden + widget tests pass).
- **Architecture-test regressions caught by post-execution gate** (hardcoded CJK, stale suppressions): both fixed in commit extracting `DateFormatter.formatShortMonthDay` helper + removing `ignore_for_file` directives. Confirmed clean: `flutter analyze` reports 0 issues.

### Gaps Summary

**No gaps detected.** All 11 ROADMAP.md success criteria are verified, all 8 requirements are satisfied, all artifacts pass three-level verification (exists, substantive, wired) and Level 4 data-flow trace, and all behavioral spot-checks pass.

The phase goal — "Build single integrated HomeHeroCard absorbing MonthOverviewCard + LedgerComparisonSection + SoulFullnessCard. Render 4 personal metrics + Best Joy story strip + family group-mode members section with consent gate. Replace misleading 'Happiness ROI'." — is achieved.

The deferred items (`FAMILY-V2-03` strict consent gate, voice-bias tooltip mention, AnalyticsScreen joyLedger sub-region, ARB value renames) are explicitly scoped out per CONTEXT D-08/D-10/D-11 and REQUIREMENTS.md, and addressed in Phase 11/12 or v1.2 backlog — none are actionable Phase 10 gaps.

---

_Verified: 2026-05-02_
_Verifier: Claude (gsd-verifier)_
