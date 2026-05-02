# Phase 10: HomePage SoulFullnessCard Redesign - Context

**Gathered:** 2026-05-02
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 10 rebuilds the upper area of the HomePage as a single integrated **Hero Card** that merges three previously-separate sections (`MonthOverviewCard` + `LedgerComparisonSection` + `SoulFullnessCard`) into one visual unit, anchored by a 3-ring concentric chart that encodes Phase 9 happiness contracts.

**Phase 10 scope expanded during discussion** (originally only `SoulFullnessCard`). The user's "everything in one card" decision absorbs MonthOverview + LedgerComparison into the same widget. ROADMAP.md and REQUIREMENTS.md need amending in Phase 10's plan unit (see Spec Amendments below). Complexity assessment shifts M → M-L.

**Delivered surface:**
- Single `HomeHeroCard` widget (replaces `MonthOverviewCard`, `LedgerComparisonSection`, `SoulFullnessCard`)
- Hero header: total monthly + month-over-month +X% chip + previous-month sub-text
- Inline 魂/生存 split bar (proportional gradient bar with absolute amount labels)
- 3 concentric gradient rings encoding Phase 9 contracts:
  - Single mode: `HappinessReport` → Joy/¥ (outer) / 均值 (middle) / 小確幸 (inner)
  - Family mode: `FamilyHappiness` → 家族小確幸 (outer) / 共爱品类 (middle) / 中位数 (inner)
- Detailed legend (label + value + sub-text per ring)
- Best Joy story strip with `本月最爱` tag, BIG `category · date`, de-emphasized `¥amount · 满足 X/10 ✨`
- Group mode appendix: per-member spending rows after Best Joy
- Whole-card tap target → AnalyticsScreen 「悦己账本」 sub-region (Phase 11 deliver)
- Visual contract source-of-truth: `/Users/xinz/Documents/0502.pen` v8 (cards `HmvHU` single light, `NMHwT` family light, `VKoU4` family dark)

**Not delivered (downstream / deferred):**
- `recoverFromSeed()` security fix (out of scope — FUTURE-ARCH-04)
- Strict `FAMILY-03` consent gate with opt-in field (deferred to v1.2 — see D-05)
- Final color/typography polish (D-09, deferred to last execution stage)
- AnalyticsScreen 「悦己账本」 sub-region itself (Phase 11)
- Voice estimator alignment (already deferred to v1.2 per Phase 9 D-12)
- ARB key/value renames (Phase 12)

</domain>

<decisions>
## Implementation Decisions

### Visual Contract (locked v8)

- **D-01: Single integrated Hero Card replaces three sections.** `HomeHeroCard` (new widget) absorbs the responsibilities of `MonthOverviewCard`, `LedgerComparisonSection`, and the existing `SoulFullnessCard`. The latter two existing widgets are deleted from `lib/features/home/presentation/widgets/`. `home_screen.dart` simplifies — one async widget consuming `monthlyReportProvider` + `happinessReportProvider` + `familyHappinessProvider` (group mode only) + `bestJoyMomentProvider`. Visual reference: `/Users/xinz/Documents/0502.pen` cards `HmvHU` / `NMHwT` / `VKoU4`.

- **D-02: Hero card vertical structure** (top → bottom):
  1. Hero header: label `今月の支出` (single) or `家族の支出` (group mode) + ¥-formatted total + +X% trend chip (right) + 先月 ¥amount sub-line. **NO month label** — month picker lives in HomeHeader, not duplicated in card.
  2. Split bar: 魂/生存 absolute amounts (left + right text labels with color dots) + horizontal proportional gradient bar (魂 portion = soul-green; track = neutral gray). The bar visualizes proportion VISUALLY but the labels show ABSOLUTE amounts; this is **factual category split**, NOT a happiness-ROI metric. Labeled "魂帳" / "生存帳", never "Joy ROI" or "happiness share".
  3. Divider.
  4. Ring section title row: heart icon + "悦己充盈 / Joy Index" (single) or groups icon + "家族の小確幸 / Family Joy" (group) + ⓘ tooltip icon. **No right-side month tag.**
  5. 3 concentric gradient rings + detailed legend (color dot + label + bold value + sub-text per row, mirroring v8a/v8b legend layout).
  6. Divider.
  7. Best Joy story strip (see D-04).
  8. (Group mode only) Divider + 群组成员 subheader + N member rows (avatar circle + member name + flex spacer + ¥amount).

- **D-03: Single-mode rings encode `HappinessReport` (Phase 9 contract).** Outer ring (gradient soul-green) = `joyPerYen` MetricResult, sweep = % toward last month's value; middle (amber gradient) = `avgSatisfaction`, sweep = avg/10 × 360°; inner (blue-purple gradient) = `highlightsCount`, sweep = highlights/totalSoulTx × 360°. Center text = `avgSatisfaction.value` (e.g., "7.8"). `medianSatisfaction` reserved for Phase 11 tooltip per HAPPY-06; `topJoy` consumed by Best Joy strip not rings.

- **D-04: Family-mode rings encode `FamilyHappiness` (Phase 9 contract).** Outer = `familyHighlightsSum` (sweep proportional to reasonable max — planner picks; recommend 30 or per-month-historical max); middle = `sharedJoyInsight` (binary: present/empty — full sweep on present, gray on min-N=3 not met); inner = `medianSatisfaction`. Center text = familyHighlightsSum aggregate value (e.g., "27"). Best Joy strip in group mode shows the **current user's** Best Joy (not family aggregate, since `FamilyHappiness` does NOT contain a `topJoy` field per Phase 9 D-08; the contract is anti-leaderboard).

- **D-05: Best Joy story strip layout — "what + when" emphasized, "amount" de-emphasized.** Three text levels stacked in `storyXmid`:
  1. Tag (small accent, fontSize 9, fontWeight 600, letterSpacing 1, fill warm-orange `#A86238`): `本月最爱` (single) / `今月の最爱` (group/family). Translated per locale.
  2. BIG (fontSize 14, fontWeight 700, fill primary): `category · date` — e.g., `咖啡店 · 4月15日`. Category resolved via `CategoryLocalizationService.resolveFromId(...)`. Date formatted via `DateFormatter` short-month form per locale.
  3. Small (fontSize 9, fontWeight 500, fill warm-orange): `¥X,XXX · 满足 X/10 ✨` — amount and satisfaction de-emphasized. The `✨` glyph is intentional (research line 81-82: amount must be VISIBLE not hidden — anti-`¥10 candy` framing — but visual prominence stays on the experience, not the spend).
  4. Trailing chevron in storyX strip is decorative (whole-card tap target per D-08).

### Scope-expansion Spec Amendments (Phase 10's plan unit must execute)

- **D-06: REQUIREMENTS.md additions** (Phase 10 planner adds at plan time):
  - `HOMEUI-05`: HomePage hero card absorbs total monthly spending (`monthlyReport.totalExpenses`) + month-over-month delta chip + previous-month amount; replaces `MonthOverviewCard` widget.
  - `HOMEUI-06`: HomePage hero card displays 魂/生存 absolute amount split via inline horizontal split bar (魂 portion gradient soul-green, track neutral gray); labels are absolute Yen amounts, NOT percentages or ratio framing; replaces `LedgerComparisonSection` survival/soul rows in single mode.
  - `HOMEUI-07`: In group mode, hero card appends per-member monthly spending rows after Best Joy strip (avatar + member name + ¥amount per row); replaces `LedgerComparisonSection`'s shadow-book rows.
  - Traceability table updated: HOMEUI-05/06/07 → Phase 10.
  - v1.1 active REQ count: 25 → 28.

- **D-07: ROADMAP.md Phase 10 amendments** (Phase 10 planner adds at plan time):
  - **Goal updated**: replace 3 separate sections (`MonthOverviewCard` + `LedgerComparisonSection` + `SoulFullnessCard`) with 1 integrated `HomeHeroCard`; encode Phase 9 happiness contracts as 3 concentric gradient rings with mode-specific metric mapping (single → `HappinessReport`; group → `FamilyHappiness`).
  - **Requirements updated**: FAMILY-03 + HOMEUI-01..07 (was HOMEUI-01..04).
  - **Complexity**: M → M-L.
  - **Critical pitfalls** add:
    - Hero card single-mode rings encode `HappinessReport` (Phase 9 personal contract); group-mode rings encode `FamilyHappiness` (Phase 9 family contract). Switching mid-card is forbidden — provider selection is a top-level branch.
    - Currency code MUST resolve from `Book.currency` via `bookProvider`-style lookup (not hardcoded JPY); existing `FormatterService().formatCurrency(amount, 'JPY', locale)` hardcoded usage must be eliminated for the hero card (HOMEUI-05).
    - 魂/生存 split bar is a CATEGORY DISTRIBUTION (factual), not a happiness metric. Labels MUST stay "魂帳" / "生存帳" — NEVER "Joy ROI", "Joy %", "happiness share". Resurrecting joy-share framing reverts the milestone's anti-pattern stance (research line 81-82). Code reviewer is the final gate.
    - Strict FAMILY-03 consent (any-member-not-opted-in collapses card) is **DEFERRED to v1.2** per D-08; Phase 10 ships with minimum gate only.
  - **UI hint**: yes (already set).

### Functional Decisions

- **D-08: Consent gate = minimum.** Family card region renders iff `isGroupModeProvider == true` AND `shadowBooks.isNotEmpty`. **No new schema field, no consent provider, no consent ADR in Phase 10.** FAMILY-03's strict "any-member-not-opted-in collapses card" semantic is **DEFERRED to v1.2** as a new REQ (see Deferred Ideas). REQUIREMENTS.md's existing FAMILY-03 entry stays in scope but its acceptance criterion relaxes to "respects group-mode + shadow-book existence gate"; planner adds a code-comment TODO at the gate site referencing v1.2 expansion. Decision rationale: 0 consent infrastructure exists in lib/ today; introducing schema migration v16→v17, consent provider, settings UI, and an ADR for a single Phase 10 acceptance criterion is disproportionate. The minimum gate ships honest behavior in single mode (no family card) and group mode (renders family analytics, which all members can see by virtue of being in the group). Code reviewer flags any drift toward "ship 21% Joy ROI label" as the pre-existing anti-pattern.

- **D-09: Empty-state strategy = always render the card.**
  - `monthlyReport.totalExpenses == 0` (brand-new): hero header still renders ("今月の支出 ¥0"), split bar shows 100% gray track (no soul/survival yet), trend chip is hidden (no prev-month basis), rings render with all metrics in `Empty()` state per Phase 9 sealed `MetricResult` contract.
  - `totalSoulTx == 0`: rings render in their `Empty()` styling (background tracks visible, no fill arcs); legend rows render text "尚未记录" / "まだ記録なし" / "No data yet" instead of digits; Best Joy strip renders the D-17 (Phase 9) CTA variant: tag "本月最爱" + BIG "记录第一笔魂账" + small "你的本月最爱会出现在这里 →".
  - `0 < totalSoulTx < 5` (thin sample): rings render normally with Value(); legend caption "n=k/N rated" makes sample size visible; **NO 'thin sample' visual treatment** beyond caption (HAPPY-06 thin-sample dim treatment lives in Phase 11 charts where samples can be plotted).
  - `topJoy.data.soulSatisfaction <= 2` (D-17 Phase 9 — "all-neutral" case): Best Joy strip renders CTA variant: tag "本月最爱" + BIG "回去给最大那笔评个分" + small "让它变成你的本月最爱". Tap navigates to that transaction.

- **D-10: ⓘ tooltips — exactly 2.** (1) Ring section title ⓘ explains the 3-ring system semantically: "外环 Joy/¥ 是花钱的幸福密度 · 中环是满足度均值 · 内环是小確幸数 (满足度 ≥ 6 的次数)". (2) Joy/¥ legend ⓘ explains PTVF + hedonic adaptation: "幸福密度 = Σ(满足度 × (金额/base)^0.88) / Σ金额 (Kahneman-Tversky 1979 价值函数). 同样金额带来的快乐会随次数减弱 (享乐适应), 公式按¥1k基线归一化". **Voice estimator bias is NOT mentioned in Phase 10 tooltips** — voice scoring's UI integration is being held back from v1.1 in user copy until v1.2 voice realignment. New ARB strings required: `homeJoyIndexTooltip` + `homeJoyPerYenTooltip` (and ja/zh/en variants). NO new keys for tooltip 1 vs 2 — keep ARB key count low.

- **D-11: Tap navigation — whole card → AnalyticsScreen 「悦己账本」 sub-region.** Single `onTap` callback at the card level (passed from `home_screen.dart` to `HomeHeroCard`). Internal sub-tap targets (Best Joy strip, member rows, etc.) all bubble to the same destination in Phase 10 — Phase 11 may differentiate when AnalyticsScreen sub-region exists. Phase 10 implementation: `Navigator.push(... AnalyticsScreen(initialRegion: AnalyticsRegion.joyLedger))` — `AnalyticsRegion` enum may need to be introduced if it doesn't exist. If `AnalyticsRegion.joyLedger` doesn't exist yet (Phase 11 work), Phase 10 may use a placeholder route OR a `TODO: route to Phase 11 sub-region` snackbar. Planner picks minimal viable.

- **D-12: Currency code resolution.** `monthlyReportProvider`-keyed `bookId` is already in scope. New helper `bookCurrencyProvider(bookId)` (or read existing `book` providers) returns `Book.currency` (default `JPY`). The hero card calls `happinessReportProvider(bookId, year, month, currencyCode: book.currency)`. Family mode reuses existing `state_happiness.dart` `familyHappinessProvider` which doesn't take `currencyCode` (group aggregate is Yen-display anyway in v1.1; multi-currency family handling is v2). Existing hardcoded `'JPY'` in current `SoulFullnessCard.recentSoulAmount` formatter call gets eliminated.

- **D-13: Color polish deferred to final execution stage.** All color tokens used in mockups (e.g., `#47B88A` soul, `#5A9CC8` survival, `#F0B14B` warm amber, `#7188C1` cool indigo, `#FFFFFF→#F0FAF5` light gradient, `#1A2129→#0F1A14` dark gradient) are tentative. Last plan unit of Phase 10 reviews against `lib/core/theme/app_colors.dart` and `app_theme_colors.dart` extension methods — final color tokens come from the existing app theme, not hex literals. Dark-mode variant keys exist in app theme; planner picks the right keys.

### Claude's Discretion (planner allocates)

- Widget naming (`HomeHeroCard` vs `HappinessHeroCard` vs other) — planner picks per project widget naming convention (`*Card`, `*Section`).
- File split: `home_hero_card.dart` (master) vs splitting into `home_hero_card.dart` + `home_hero_card_rings.dart` + `home_hero_card_member_rows.dart` — planner decides per file-size targets.
- Empty-state copy exact wording — planner drafts; reviewer/UAT checks.
- ⓘ tooltip implementation — `Tooltip` widget vs custom `showDialog` modal — planner decides per app convention. Recommend a project-level `InfoIconButton` for consistency if multiple Phase 10/11 surfaces need tooltips.
- Ring sweep angles for `Empty()` state — visually empty ring (sweepAngle 0) vs full subdued track — planner decides; recommend full subdued track for visual consistency.
- Member row avatar color cycle (group mode) — derived from member device ID hash to a 5-color palette; planner picks.
- 30-day vs MTD trend chip basis — Phase 10 uses month-over-month (current-month-to-date vs previous-full-month-to-same-day) per existing `MonthOverviewCard` semantic; planner verifies.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project planning (always)
- `.planning/PROJECT.md` — v1.1 milestone vision, locked constraints (no theme color changes, no enum rename), milestone insight ("10元小確幸 vs 1000元购物")
- `.planning/REQUIREMENTS.md` — FAMILY-03, HOMEUI-01..04 active for Phase 10; HOMEUI-05/06/07 to be added per D-06
- `.planning/ROADMAP.md` — Phase 10 entry; goal/critical-pitfalls to be amended per D-07
- `.planning/STATE.md` — Phase 9 complete, Phase 10 ready to plan
- `.planning/phases/09-happiness-domain-formula-layer/09-CONTEXT.md` — Phase 9 decisions D-13 (sealed `MetricResult`), D-15 (`HappinessReport` / `FamilyHappiness` shapes), D-17 (all-neutral CTA contract), D-19/20 (Joy density formatter + display unit), D-21 (headline metric deferral closed by Phase 10 D-03)

### Phase 9 deliverables consumed by Phase 10 (read before planning)
- `lib/features/analytics/domain/models/happiness_report.dart` — `HappinessReport` Freezed model (year/month/bookId/totalSoulTx + 5 MetricResult fields)
- `lib/features/analytics/domain/models/family_happiness.dart` — `FamilyHappiness` Freezed model (anti-leaderboard contract; 3 MetricResult fields)
- `lib/features/analytics/domain/models/best_joy_moment_row.dart` — `BestJoyMomentRow` (transactionId, amount, soulSatisfaction, categoryId, timestamp; deliberately omits encrypted note)
- `lib/features/analytics/domain/models/metric_result.dart` — sealed `MetricResult<T>` with `Empty<T>` / `Value<T>(data, sampleSize)` variants
- `lib/features/analytics/domain/models/shared_joy_insight.dart` — `SharedJoyInsight(categoryId, avgSatisfaction, totalCount)` anti-leaderboard tuple
- `lib/features/analytics/presentation/providers/state_happiness.dart` — `happinessReportProvider`, `bestJoyMomentProvider`, `familyHappinessProvider` (HOMEUI-01 wiring path)
- `lib/application/analytics/get_happiness_report_use_case.dart` — use case template
- `lib/infrastructure/i18n/formatters/joy_density_formatter.dart` — Phase 9 D-20 helper (PTVF base + display unit per currency)

### Phase 10 source files (must read for replacement decisions)
- `lib/features/home/presentation/screens/home_screen.dart` — current `_computeHappinessROI` (lines ~362) and `_computeSatisfaction` (lines ~345) helpers to delete; current widget composition driving the 3 sections to merge
- `lib/features/home/presentation/widgets/soul_fullness_card.dart` — current `SoulFullnessCard` (deleted/replaced by `HomeHeroCard`)
- `lib/features/home/presentation/widgets/month_overview_card.dart` — DELETE per D-06 (HOMEUI-05)
- `lib/features/home/presentation/widgets/ledger_comparison_section.dart` — DELETE per D-06 (HOMEUI-06/07)
- `lib/features/home/presentation/providers/state_shadow_books.dart` — `shadowBooksProvider` for group-mode member rows (HOMEUI-07)
- `lib/features/home/presentation/widgets/hero_header.dart` — existing month picker location (clarifies why Phase 10 cards drop "5月" inline labels)
- `lib/features/family_sync/presentation/providers/state_active_group.dart` — `isGroupModeProvider`, `activeGroupProvider` for D-08 minimum consent gate
- `lib/features/analytics/presentation/providers/state_analytics.dart` — `monthlyReportProvider` for HOMEUI-05/06 data source
- `lib/features/settings/presentation/providers/state_locale.dart` — `currentLocaleProvider` for date/currency formatting
- `lib/data/tables/books_table.dart:8` — `currency` column source (D-12 currency code resolution)

### Architecture / spec docs
- `docs/arch/01-core-architecture/ARCH-001_Complete_Guide.md` — 5-layer architecture, Thin Feature rule
- `docs/arch/01-core-architecture/ARCH-004_State_Management.md` — Riverpod conventions
- `docs/arch/03-adr/ADR-012_No_Gamification_v1_1.md` — Goodhart's-Law defense, anti-feature inventory (binding through milestone close)
- `docs/arch/03-adr/ADR-013_Joy_Density_PTVF_Scaling.md` — PTVF formula rationale (referenced in D-10 tooltip copy)
- `docs/arch/03-adr/ADR-014_Soul_Satisfaction_Unipolar_Positive_Scale.md` — default-2 semantic (informs Phase 10 ring "always-positive" treatment)
- `.planning/research/FEATURES.md` — JP/CN/EN competitor analysis. Critical sections:
  - Lines 81-82: Joy ROI / soul-share anti-pattern (D-02 split bar must NEVER frame as ROI; code reviewer's gate)
  - Line 190: Best Joy per ¥ as emotional centerpiece ("spend UI polish budget here") — drove D-04 Best Joy story design
  - Line 47: Spotify Wrapped argmax pattern — informed D-04 typography emphasis on what+when
  - Lines 79-86: Anti-features inventory (per-member leaderboard, year-over-year comparison, AI interpretation, public sharing)
- `.planning/research/PITFALLS.md` — survival-row contamination guard (Phase 9 closed via `_soulOnly()` SQL fragment; Phase 10 is downstream-safe by design)
- `.planning/codebase/ARCHITECTURE.md`, `STRUCTURE.md`, `CONVENTIONS.md` — codebase patterns (note: predates v1.0 cleanup; refresh recommended pre-execution but not blocking)

### Project rules
- `CLAUDE.md` — Thin Feature rule, Drift TableIndex syntax (no Drift in Phase 10), Riverpod provider rules, Common Pitfalls list, **Amount Display Style** (`AppTextStyles.amountLarge/Medium/Small` with `FontFeature.tabularFigures()` — applies to all monetary text in v8 mockups)
- `.claude/rules/coding-style.md` — Immutability (Freezed `copyWith`), file size targets (<800 lines)
- `.claude/rules/testing.md` — TDD workflow, ≥70% per-file coverage with `--deferred` mechanism
- `.claude/rules/arch.md` — ADR numbering protocol (no new Phase 10 ADRs per D-08)

### Visual contract (source-of-truth)
- `/Users/xinz/Documents/0502.pen` (Pencil document) — v8 mockup. Reference cards:
  - `HmvHU` — v8a single mode (light) — primary visual contract
  - `NMHwT` — v8b family/group mode (light) — group-mode contract
  - `VKoU4` — v8c family mode (dark theme variant)
  - Predecessor exploration cards in same document: v5/v6/v7 rows show alternative directions considered and rejected (kept for retrospective traceability)

### External / academic sources (for tooltip + ADR refs)
- Kahneman & Tversky (1979). "Prospect Theory: An Analysis of Decision under Risk." *Econometrica*, 47(2), 263–292. — α=0.88 PTVF empirical fit (D-10 tooltip 2 attribution)
- Frederick & Loewenstein (1999). "Hedonic Adaptation." (in *Well-Being: The Foundations of Hedonic Psychology*) — basis for D-10 tooltip 2 hedonic adaptation explainer
- Goodhart's Law (Goodhart, 1975) — already cited in ADR-012; informs Phase 10's anti-gamification UI guardrails

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **`happinessReportProvider` / `bestJoyMomentProvider` / `familyHappinessProvider`** (`lib/features/analytics/presentation/providers/state_happiness.dart`) — Phase 9 deliverables; Phase 10 consumes directly. `familyHappinessProvider` already does internal short-circuit if `activeGroup == null` returning `_emptyFamilyHappiness(...)` (per Phase 9 D-09).
- **`monthlyReportProvider`** (`lib/features/analytics/presentation/providers/state_analytics.dart`) — supplies `MonthlyReport` with `totalExpenses`, `survivalTotal`, `soulTotal`, `previousMonthComparison.previousExpenses` — covers HOMEUI-05/06 hero header + split bar.
- **`shadowBooksProvider`** (`lib/features/home/presentation/providers/state_shadow_books.dart:13`) + **`shadowAggregateProvider`** — supply per-member `(memberDisplayName, totalExpenses)` for HOMEUI-07 group-mode member rows.
- **`isGroupModeProvider`** / **`activeGroupProvider`** (`lib/features/family_sync/presentation/providers/state_active_group.dart`) — D-08 gate.
- **`AppTextStyles.amountLarge/Medium/Small`** (`lib/core/theme/app_text_styles.dart`) — `FontFeature.tabularFigures()` for monetary alignment; reuse for all ¥ amounts in hero card.
- **`FormatterService` / `NumberFormatter` / `DateFormatter`** (`lib/infrastructure/i18n/formatters/`) — locale-aware currency + date.
- **`CategoryLocalizationService.resolveFromId(categoryId, locale)`** — Best Joy strip's `category` text (mirrors existing `home_screen.dart` `_buildLedgerRows` usage).
- **`AppColors.soul` (#47B88A) / `AppColors.survival` (#5A9CC8) / `AppColors.accentPrimary` (#8AB8DA) / `AppColors.olive` / `AppColors.shared`** — locked tokens; D-13 deferral means hex literals from mockup map back to these.
- **`app_theme_colors.dart` extension methods** (`context.wmCard`, `context.wmTextPrimary`, `context.wmBorderDefault`, `context.wmBackgroundDivider`, etc.) — used by existing `SoulFullnessCard`; D-13 maps mockup tokens here for light/dark switching.
- **`HeroHeader`** (`lib/features/home/presentation/widgets/hero_header.dart`) — existing month picker entrypoint; clarifies why hero card MUST NOT display "5月" inline labels (already in HeroHeader).

### Established Patterns

- **Container Widget With Async Provider** — widget receives Freezed aggregate directly, wrapped in `AsyncValue.when` from parent screen. `HomeHeroCard` follows this: takes `MonthlyReport report`, `HappinessReport happiness`, `FamilyHappiness? family` (null in single mode), `MetricResult<BestJoyMomentRow> bestJoy`. Parent (`home_screen.dart`) does `.when()` per provider.
- **One repository_providers.dart per feature/domain** — no new repository providers in Phase 10 (all consumption from Phase 9's `lib/application/analytics/repository_providers.dart`).
- **Riverpod provider naming `state_<aggregate>.dart`** — no new state providers in Phase 10 (consumes existing `state_happiness.dart`, `state_analytics.dart`, `state_shadow_books.dart`, `state_active_group.dart`).
- **Sealed class pattern matching for `MetricResult<T>`** — UI consumes via `switch (result) { case Empty(): renderEmpty; case Value(:final data, :final sampleSize): renderValue(data, sampleSize); }`. Apply per ring + per legend row.
- **Widget Parameter Pattern (CLAUDE.md Pitfall #9)** — `HomeHeroCard` takes nullable widget params with provider fallback at parent screen level. No hardcoded JPY in widget itself.

### Integration Points

- **Phase 10 → home_screen.dart**: 3 widgets deleted (`MonthOverviewCard`, `LedgerComparisonSection`, `SoulFullnessCard`), helper methods deleted (`_computeHappinessROI`, `_computeSatisfaction`, `_buildLedgerRows`), 1 new widget added (`HomeHeroCard`). Net file size of `home_screen.dart` should decrease.
- **Phase 10 → Phase 11**: D-11 tap navigation requires AnalyticsScreen 「悦己账本」 sub-region. Phase 11 must verify the navigation contract (AnalyticsRegion enum or initialRegion param) supplied by Phase 10's plan.
- **Phase 10 → Phase 12**: Phase 12 ARB rename pass updates VALUE of `homeSoulFullness` (悦己充盈 / ときめき度 / Joy Index). Phase 10's ring section title uses `S.of(context).homeSoulFullness` — Phase 12 rename surfaces the new copy automatically; KEY unchanged.
- **Phase 10 → no new schema migrations** (D-08 minimum consent; D-12 currency from existing `Book.currency`).

### Known forbidden patterns (CI-enforced or project policy)

- ❌ Hardcoding `'JPY'` in widget bodies (CLAUDE.md Pitfall #9; eliminate from `recentSoulAmount` rendering).
- ❌ Resurrecting `_computeHappinessROI`-style budget-share metric — including via UI labels like "Joy %", "happiness share", "joy ratio" on the split bar (D-02 / research line 81-82).
- ❌ Per-member happiness leaderboard surfaces (FAMILY-01/02 contract; group-mode member rows show ABSOLUTE spending only — same as existing `LedgerComparisonSection` shadow-book rows; this is NOT a leaderboard because it shows **spending**, not **happiness scores**).
- ❌ Streaks / badges / daily targets / cross-period happiness comparisons (ADR-012 binding).
- ❌ AI-generated interpretation of joy data (research lines 84).
- ❌ Public sharing of happiness metrics (research line 86).
- ❌ Adding `application/` or `data/` inside `features/home/` (Thin Feature rule; `import_guard` rejects).
- ❌ ARB key renames in Phase 10 (Phase 12 only renames VALUES; Phase 10 introduces new keys for tooltips and empty-state copy as needed).

</code_context>

<specifics>
## Specific Ideas

These are particular references and product-philosophy moments from the discussion that anchor downstream judgment calls:

- **"3 个分离区域合并成一张大卡, rings 作为统一的视觉骨架"** — drove the v4→v5→v6→v7→v8 iteration toward a single integrated `HomeHeroCard`. The user pushed past Claude's initial recommendation of "small SoulFullnessCard only" twice; the final v8 reflects user's vision of fewer-cards-with-richer-information density on home screen.

- **"5月文字去掉, Home 头部有月份选择, 不需要重复"** — drove removal of all "5月" labels inside the hero card. Month context is a HomeHeader concern; hero card is month-agnostic copy. (Locale-aware date renders only inside Best Joy strip's date field.)

- **"本月最爱微调, 突出做了什么和日期, 弱化价钱"** — drove D-04 typography hierarchy where category+date is bold/large and amount+sat is small. Aligns with research line 47 (Spotify Wrapped argmax → emotional centerpiece, not a price tag).

- **"现在还不支持语音打分功能, 所以去掉相关文字"** — drove D-10 Joy/¥ tooltip to remove voice-bias mention. Voice estimator IS implemented (`voice_satisfaction_estimator.dart`), but its UI integration story is being held back from v1.1 user copy until v1.2 voice realignment (Phase 9 D-12). Tooltip stays focused on PTVF math + hedonic adaptation.

- **"颜色先这样, 留到最后统一修改"** — drove D-13: color polish is the last plan unit. All hex literals in mockup are tentative; final tokens come from `app_colors.dart` + `app_theme_colors.dart` extension. Don't burn cycles tweaking hex values during widget structure work.

- **Iterations rejected** (preserved in Pencil for retrospective):
  - v3 row (β2/β3 modernized rings) — color-tuning experiments before integration scope was decided
  - v4 (initial integration) — kept the LedgerComparisonSection rows as-is, user wanted them simplified
  - v5 (3-rings + inline 魂/生存 text) — text inline was "too weak"; user pushed for stronger visualization
  - v6 (4 rings with 魂/生存 outer ring) — visualizes soul/total ratio; rejected as anti-pattern revival
  - v7 W1/W3/W4/W5 — alternative ledger amount displays not chosen; W2 split bar won

- **The v8 visual is locked in `/Users/xinz/Documents/0502.pen`** as source-of-truth for Phase 10 implementation. Planner allocates a `pencil-to-flutter` plan unit OR a designer-handoff plan unit explicitly referencing the Pencil cards by ID. Pixel-precise replication is NOT required; structural and proportional fidelity IS.

- **"不动 schema"** (PROJECT.md milestone constraint) — confirmed binding through D-08 (no new consent field) and D-12 (currency from existing Book.currency). Phase 10 ships with v16 schema unchanged.

- **Best Joy per ¥ "amount visible alongside satisfaction"** (REQUIREMENTS HOMEUI-04) — D-04 honors this: amount IS visible (small text), but de-emphasized typographically vs the experience+date. The "¥10 candy" anti-framing concern is addressed by both (a) Phase 9 D-06 pure-sat-DESC ordering with amount-DESC tiebreak, AND (b) Phase 10 D-04 typographic placement of `category · date` over `¥amount · sat`.

</specifics>

<deferred>
## Deferred Ideas

### Out-of-Phase-10 — comes back in Phase 11/12 (still v1.1)

- **AnalyticsScreen 「悦己账本」 sub-region itself** → Phase 11 (STATSUI-01..04). Phase 10 D-11 tap navigation requires this destination; Phase 11 builds it.
- **HAPPY-06 thin-sample dim treatment in charts** → Phase 11. Phase 10 ships caption-only thin-sample treatment per D-09; visual dimming/no-render-below-N=5 lives in chart widgets.
- **ARB value rename for `homeSoulFullness` / `homeHappinessROI`** → Phase 12 (RENAME-03/04). Phase 10 introduces NEW ARB keys for tooltips + empty states; doesn't touch existing ones.

### Out-of-v1.1 — v2 / future milestones

- **Strict FAMILY-03 consent gate** (any-member-not-opted-in collapses card) — deferred to v1.2 per D-08. New REQ in v2 backlog: "FAMILY-03-V2: introduce `family_members.shared_analytics_opt_in` BOOLEAN field + `familyConsentProvider` + group settings UI; family card collapses if any member opt_in==false". Schema bump v16→v17. New ADR (Privacy Consent Gate v1.2).
- **Voice estimator output range realignment** + voice-bias tooltip mention — already deferred to v1.2 per Phase 9 D-12. Phase 10 tooltip text stays voice-free.
- **Differentiated tap targets per card section** — Phase 10 ships whole-card-tap. v1.2+ may differentiate (Best Joy strip → transaction detail; member row → that member's shadow book detail).
- **Currency code awareness in family aggregator** — `familyHappinessProvider` is currency-agnostic in v1.1; multi-currency family handling deferred to v2.
- **Color polish framework / theme-token unification** for hero card — incremental refactor opportunity if app theme system is overhauled in v1.2.
- **Tooltip implementation framework** (`InfoIconButton` reusable widget) — if Phase 10 uses one-off `Tooltip` widgets and Phase 11 needs the same, refactor to shared component in v1.2.

### Forbidden anti-features (never to be added — captured for boundary-defense)

- ❌ **"Joy ROI" / "happiness share" / "soul %" framing on the 魂/生存 split bar** — would resurrect the deleted `_computeHappinessROI` anti-pattern. Code reviewer's hard gate.
- ❌ **Per-member happiness leaderboard** in group mode member rows — member rows show SPENDING (absolute Yen), not happiness scores. Adding any per-member sat/joy column violates FAMILY-01/02 anti-leaderboard contract.
- ❌ **Cross-period happiness comparison chip** ("vs 4月 Joy: -3%") — ADR-012 binding ban; the +21% trend chip on Hero header is for SPENDING (absolute), which is not gamified.
- ❌ **Streaks/badges/targets** on rings — ADR-012 binding.
- ❌ **AI-generated interpretation** of the user's joy data — local-first/zero-knowledge architecture conflict.
- ❌ **Editable Best Joy** ("promote a different transaction") — research line 85; argmax stays algorithmic.

### Reviewed but not folded — none

`cross_reference_todos` step found 0 matching todos. STATE.md "Pending Todos" entries are all Phase 9 / Phase 11 scoped, not Phase 10.

</deferred>

---

*Phase: 10-HomePage SoulFullnessCard Redesign*
*Context gathered: 2026-05-02*
