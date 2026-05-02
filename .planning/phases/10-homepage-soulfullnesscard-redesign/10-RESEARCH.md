# Phase 10: HomePage SoulFullnessCard Redesign — Research

**Researched:** 2026-05-02
**Domain:** Flutter widget composition + custom-painted concentric ring chart + Riverpod async aggregation + Phase 9 contract consumption
**Confidence:** HIGH

## Summary

Phase 10 replaces three discrete Home-tab widgets (`MonthOverviewCard`, `LedgerComparisonSection`, `SoulFullnessCard`) with a single integrated `HomeHeroCard` whose visual centerpiece is a 3-ring concentric gradient chart. The phase consumes Phase 9's stable, Freezed-modeled contracts (`HappinessReport` / `FamilyHappiness` / `BestJoyMomentRow` / sealed `MetricResult<T>`) via existing Riverpod providers. Zero new dependencies, zero schema migrations, zero new repository providers.

The dominant technical risks are not novel — they are codified anti-patterns inherited from Phase 9's milestone defenses (no Joy ROI framing, no leaderboards, ≤2 ⓘ icons, no streak/badge/cross-period copy) and a CLAUDE.md pitfall (hardcoded `'JPY'`). The dominant *new* technical work is a `CustomPainter` for the rings with mode-aware encoding (single → `HappinessReport`; group → `FamilyHappiness`) and an explicit sealed-pattern-match branch on `MetricResult` for empty-state rendering. The Container Widget With Async Provider pattern is already established in `home_screen.dart` — Phase 10 follows it verbatim, simply collapsing more `.when()` calls into one branch.

**Primary recommendation:** Build `HomeHeroCard` as a **pure StatelessWidget** that takes resolved Freezed aggregates + `currencyCode` (no Riverpod refs inside); perform all `AsyncValue.when()` resolution in `home_screen.dart`; render rings with a single `CustomPainter` that takes a discriminated mode + 3 sweep ratios + theme-aware track color; route `MetricResult` through Dart-3 sealed pattern matching at every consumption site; and allocate **2 spec-amendment plan units** before implementation (REQUIREMENTS.md + ROADMAP.md amendments per CONTEXT.md D-06/D-07) to avoid documentation/code drift that the v1.0 audit cycle proved expensive to retire.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Display monthly total + month-over-month chip + previous-month sub-line | Presentation (`features/home/presentation/widgets`) | Application (existing `monthlyReportProvider` provides `totalExpenses` + `previousMonthComparison`) | Reads aggregated data; no business logic. |
| Render 魂/生存 absolute amount split bar | Presentation | Application (`monthlyReportProvider.soulTotal/survivalTotal`) | Pure visual composition over existing aggregate fields. |
| Compute happiness metrics (Joy/¥, avg sat, highlights, top joy) | Application (`GetHappinessReportUseCase` — Phase 9, already shipped) | Data (DAO Phase 9) | Phase 10 does NOT touch this tier — consumes-only. |
| Compute family happiness (FAMILY-01 sum + FAMILY-02 insight + median) | Application (`GetFamilyHappinessUseCase` — Phase 9) | Data | Consumes-only. Phase 10 must NOT add per-member breakdown. |
| Resolve currency code from book | Application (`BookRepository.findById`) → Presentation (new `bookCurrencyProvider` or `bookByIdProvider`) | Data (`books_table.currency` column at line 8) | Eliminates hardcoded `'JPY'` in widget bodies (CLAUDE.md Pitfall #9). |
| Render 3 concentric gradient rings | Presentation (`CustomPainter` subclass private to `HomeHeroCard`) | — | Pure rendering; no business logic. Painter is mode-aware via constructor input. |
| Determine empty/value state branching for metrics | Presentation (Dart-3 sealed pattern match on `MetricResult<T>`) | Application (Phase 9 sets `Empty<T>()` vs `Value<T>(data, sampleSize)`) | UI never inspects raw NaN/0; pattern match drives render path. |
| Group-mode visibility gating | Presentation (`isGroupModeProvider` + `shadowBooksProvider.isNotEmpty` check) | Application (group repo + shadow book provider) | D-08 minimum gate — no consent infrastructure built in Phase 10. |
| Whole-card tap navigation | Presentation (`GestureDetector` at card root, `Navigator.push`) | Routing (existing `MaterialPageRoute` pattern) | D-11 single onTap; AnalyticsRegion enum is Phase 11 work. |
| i18n / locale-aware date + currency | Infrastructure (`DateFormatter`, `NumberFormatter` already exist) | Presentation (consumes via `currentLocaleProvider`) | Existing infra; widget just calls `DateFormatter.formatDate(...)` short-month form. |

**Tier sanity check:** Every responsibility above lives in either presentation or application — no `lib/features/home/application/`, `lib/features/home/data/`, or `lib/features/home/infrastructure/` is added (Thin Feature rule, CLAUDE.md). Cross-feature presentation reads (e.g., `home_screen.dart` importing from `features/analytics/presentation/providers/`) are precedented at `home_screen.dart:12` and not violations.

## User Constraints (from CONTEXT.md)

### Locked Decisions

> Verbatim copy of CONTEXT.md `<decisions>` section. Planner MUST honor these — no alternatives.

**D-01: Single integrated Hero Card replaces three sections.** `HomeHeroCard` (new widget) absorbs the responsibilities of `MonthOverviewCard`, `LedgerComparisonSection`, and the existing `SoulFullnessCard`. The latter three existing widgets are deleted from `lib/features/home/presentation/widgets/`. `home_screen.dart` simplifies — one async widget consuming `monthlyReportProvider` + `happinessReportProvider` + `familyHappinessProvider` (group mode only) + `bestJoyMomentProvider`. Visual reference: `/Users/xinz/Documents/0502.pen` cards `HmvHU` / `NMHwT` / `VKoU4`.

**D-02: Hero card vertical structure** (top → bottom):
1. Hero header: label `今月の支出` (single) or `家族の支出` (group mode) + ¥-formatted total + +X% trend chip (right) + 先月 ¥amount sub-line. **NO month label** — month picker lives in HomeHeader, not duplicated in card.
2. Split bar: 魂/生存 absolute amounts (left + right text labels with color dots) + horizontal proportional gradient bar (魂 portion = soul-green; track = neutral gray). Labels show ABSOLUTE amounts; this is **factual category split**, NOT a happiness-ROI metric. Labeled "魂帳" / "生存帳", never "Joy ROI" or "happiness share".
3. Divider.
4. Ring section title row: heart icon + "悦己充盈 / Joy Index" (single) or groups icon + "家族の小確幸 / Family Joy" (group) + ⓘ tooltip icon. **No right-side month tag.**
5. 3 concentric gradient rings + detailed legend (color dot + label + bold value + sub-text per row).
6. Divider.
7. Best Joy story strip (see D-04).
8. (Group mode only) Divider + 群组成员 subheader + N member rows (avatar circle + member name + flex spacer + ¥amount).

**D-03: Single-mode rings encode `HappinessReport` (Phase 9 contract).** Outer ring (gradient soul-green) = `joyPerYen` MetricResult; middle (amber gradient) = `avgSatisfaction`; inner (blue-purple gradient) = `highlightsCount`. Center text = `avgSatisfaction.value`. `medianSatisfaction` reserved for Phase 11; `topJoy` consumed by Best Joy strip not rings.

**D-04: Family-mode rings encode `FamilyHappiness` (Phase 9 contract).** Outer = `familyHighlightsSum`; middle = `sharedJoyInsight` (binary: present/empty — full sweep on present, gray on min-N=3 not met); inner = `medianSatisfaction`. Center text = familyHighlightsSum aggregate. Best Joy strip in group mode shows the **current user's** Best Joy (`FamilyHappiness` deliberately omits a `topJoy` field per Phase 9 D-08).

**D-05: Best Joy story strip layout — "what + when" emphasized, "amount" de-emphasized.** Three text levels stacked:
1. Tag (small accent, fontSize 9, fontWeight 600, letterSpacing 1, fill warm-orange `#A86238`): `本月最爱` (single) / `今月の最爱` (group/family).
2. BIG (fontSize 14, fontWeight 700, fill primary): `category · date`.
3. Small (fontSize 9, fontWeight 500, fill warm-orange): `¥X,XXX · 满足 X/10 ✨`.
4. Trailing chevron is decorative (whole-card tap target per D-08/D-11).

**D-06: REQUIREMENTS.md additions** (planner adds at plan time): HOMEUI-05 (hero absorbs total), HOMEUI-06 (魂/生存 split bar), HOMEUI-07 (group-mode member rows). v1.1 active REQ count: 25 → 28.

**D-07: ROADMAP.md Phase 10 amendments** (planner adds at plan time): goal updated to "1 integrated `HomeHeroCard`"; requirements FAMILY-03 + HOMEUI-01..07; complexity M → M-L; critical pitfalls expanded.

**D-08: Consent gate = minimum.** Family card region renders iff `isGroupModeProvider == true` AND `shadowBooks.isNotEmpty`. **No new schema field, no consent provider, no consent ADR in Phase 10.** FAMILY-03's strict semantic deferred to v1.2.

**D-09: Empty-state strategy = always render the card.**
- `monthlyReport.totalExpenses == 0`: hero header still renders ("今月の支出 ¥0"), split bar 100% gray, trend chip hidden, rings `Empty()` styling.
- `totalSoulTx == 0`: rings render in `Empty()` styling; legend rows render text "尚未记录" / "まだ記録なし" / "No data yet"; Best Joy strip renders D-17 (Phase 9) CTA variant.
- `0 < totalSoulTx < 5` (thin sample): rings render normally with Value(); legend caption "n=k/N rated"; **NO 'thin sample' visual treatment** beyond caption.
- `topJoy.data.soulSatisfaction <= 2` ("all-neutral"): Best Joy strip renders CTA variant: tag "本月最爱" + BIG "回去给最大那笔评个分" + small "让它变成你的本月最爱".

**D-10: ⓘ tooltips — exactly 2.** (1) Ring section title ⓘ explains the 3-ring system. (2) Joy/¥ legend ⓘ explains PTVF + hedonic adaptation. **Voice estimator bias is NOT mentioned.** New ARB strings required: `homeJoyIndexTooltip` + `homeJoyPerYenTooltip` (ja/zh/en).

**D-11: Tap navigation — whole card → AnalyticsScreen 「悦己账本」 sub-region.** Single `onTap` callback at card level. Internal sub-tap targets all bubble to same destination in Phase 10. `AnalyticsRegion` enum may need to be introduced if it doesn't exist (Phase 11 work). Phase 10 may use a placeholder route OR snackbar.

**D-12: Currency code resolution.** New helper `bookCurrencyProvider(bookId)` (or read existing `book` providers) returns `Book.currency` (default `JPY`). Hero card calls `happinessReportProvider(bookId, year, month, currencyCode: book.currency)`. Family mode reuses existing `familyHappinessProvider` which doesn't take `currencyCode`. Existing hardcoded `'JPY'` in current `SoulFullnessCard.recentSoulAmount` formatter call gets eliminated.

**D-13: Color polish deferred to final execution stage.** All color tokens used in mockups are tentative. Last plan unit reviews against `lib/core/theme/app_colors.dart` and `app_theme_colors.dart` extension. Final color tokens come from existing app theme, not hex literals.

### Claude's Discretion

> Verbatim copy of CONTEXT.md `### Claude's Discretion`. Planner has flexibility here — recommendations from this research provided in respective sections below.

- Widget naming (`HomeHeroCard` vs `HappinessHeroCard` vs other) — planner picks per project widget naming convention (`*Card`, `*Section`).
- File split: `home_hero_card.dart` (master) vs splitting into `home_hero_card.dart` + `home_hero_card_rings.dart` + `home_hero_card_member_rows.dart` — planner decides per file-size targets.
- Empty-state copy exact wording — planner drafts; reviewer/UAT checks.
- ⓘ tooltip implementation — `Tooltip` widget vs custom `showDialog` modal — planner decides per app convention. Recommend a project-level `InfoIconButton` for consistency if multiple Phase 10/11 surfaces need tooltips.
- Ring sweep angles for `Empty()` state — visually empty ring (sweepAngle 0) vs full subdued track — planner decides; recommend full subdued track for visual consistency.
- Member row avatar color cycle (group mode) — derived from member device ID hash to a 5-color palette; planner picks.
- 30-day vs MTD trend chip basis — Phase 10 uses month-over-month per existing `MonthOverviewCard` semantic; planner verifies.

### Deferred Ideas (OUT OF SCOPE)

> Verbatim copy of CONTEXT.md `<deferred>` section. These MUST NOT appear in plans.

**Out-of-Phase-10 — comes back in Phase 11/12 (still v1.1):**
- AnalyticsScreen 「悦己账本」 sub-region itself → Phase 11 (STATSUI-01..04).
- HAPPY-06 thin-sample dim treatment in charts → Phase 11.
- ARB value rename for `homeSoulFullness` / `homeHappinessROI` → Phase 12 (RENAME-03/04).

**Out-of-v1.1 — v2 / future milestones:**
- Strict FAMILY-03 consent gate (any-member-not-opted-in collapses card) — deferred to v1.2.
- Voice estimator output range realignment + voice-bias tooltip mention — deferred to v1.2.
- Differentiated tap targets per card section.
- Currency code awareness in family aggregator.
- Color polish framework / theme-token unification.
- `InfoIconButton` reusable widget (if Phase 11 also needs same pattern).

**Forbidden anti-features (binding through milestone close per ADR-012):**
- "Joy ROI" / "happiness share" / "soul %" framing on the 魂/生存 split bar.
- Per-member happiness leaderboard in group-mode member rows.
- Cross-period happiness comparison chip ("vs 4月 Joy: -3%").
- Streaks / badges / daily-target / cross-period happiness chips.
- AI-generated interpretation of joy data.
- Public sharing of happiness metrics.
- Editable Best Joy ("promote a different transaction").

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FAMILY-03 | Family card consent gate — if any family member has not opted into shared analytics, the family card collapses entirely (per REQUIREMENTS.md). **Phase 10 acceptance criterion relaxed per D-08** to "respects group-mode + shadow-book existence gate"; strict semantic deferred to v1.2. | D-08 minimum-gate strategy. Existing `isGroupModeProvider` + `shadowBooksProvider` provide the gate. Code-comment TODO at gate site references v1.2 expansion. |
| HOMEUI-01 | `SoulFullnessCard` rebuilt to render the 4 personal happiness metrics + Best Joy story card | Consumes `happinessReportProvider` (HappinessReport: avgSat / joyPerYen / median / highlightsCount / topJoy) + `bestJoyMomentProvider` (standalone HAPPY-04) — both Phase 9 deliverables, already wired in `state_happiness.dart`. |
| HOMEUI-02 | Inline helpers `_computeHappinessROI` + `_computeSatisfaction` deleted from `home_screen.dart`; responsibilities now live in `GetHappinessReportUseCase` | Verified by grep: only callers are inside `home_screen.dart` itself (lines ~345 & ~362). `_buildLedgerRows` (line ~258) ALSO deleted (no longer needed since `HomeHeroCard` consumes `monthlyReport.soulTotal/survivalTotal` directly). No external callers of the helpers exist in `lib/`. |
| HOMEUI-03 | Family card conditionally rendered when `isGroupModeProvider == true`; respects FAMILY-03 consent gate | D-08 minimum gate: render family-mode rings when `isGroupMode == true`; render member rows when `shadowBooks.isNotEmpty`. `familyHappinessProvider` (state_happiness.dart:50) already short-circuits internally to empty when `activeGroup == null` (lines 56-58). |
| HOMEUI-04 | At most 2 `ⓘ` info icons explain voice estimator bias and hedonic adaptation; coverage caption visible on the headline metric tile; no daily-target / streak / badge copy anywhere | D-10 explicitly enumerates the 2 tooltips; voice-bias mention REMOVED per D-10 (replaced with PTVF + hedonic adaptation only). Coverage caption "n=k/N rated" sources from `MetricResult.Value.sampleSize` + `HappinessReport.totalSoulTx`. |

**v1.1 traceability addition (per D-06, planner adds at spec-amendment plan unit):**

| ID | Description | Research Support |
|----|-------------|------------------|
| HOMEUI-05 | HomePage hero card absorbs total monthly spending (`monthlyReport.totalExpenses`) + month-over-month delta chip + previous-month amount; replaces `MonthOverviewCard` widget | `monthlyReport.totalExpenses` + `monthlyReport.previousMonthComparison?.previousExpenses` already provided by Phase 9; existing `MonthOverviewCard` arithmetic at lines 36-40 (current-vs-prev `((current - prev) / prev * 100).round()`) reused verbatim. |
| HOMEUI-06 | HomePage hero card displays 魂/生存 absolute amount split via inline horizontal split bar; labels are absolute Yen amounts, NOT percentages or ratio framing | `monthlyReport.soulTotal` + `monthlyReport.survivalTotal` already provided. **Critical gate** (D-02): bar visualizes proportion VISUALLY but labels show ABSOLUTE amounts; never framed as ROI/share/ratio. |
| HOMEUI-07 | In group mode, hero card appends per-member monthly spending rows after Best Joy strip; replaces `LedgerComparisonSection`'s shadow-book rows | Existing `shadowBooksProvider` (state_shadow_books.dart:13) returns `List<ShadowBookInfo>` with `book` + `memberDisplayName` + `memberAvatarEmoji`; `shadowAggregateProvider.perBookReports[shadow.book.id]` returns per-book monthly report. Member rows show ABSOLUTE ¥ spending only (FAMILY-01/02 anti-leaderboard). |

## Project Constraints (from CLAUDE.md)

The planner MUST verify compliance with all of these. Most have automated enforcement; manually-checked items get flagged in Common Pitfalls below.

| Constraint | Source | Enforcement |
|------------|--------|-------------|
| Thin Feature rule: features NEVER contain `application/`, `infrastructure/`, `data/tables/`, or `data/daos/` | CLAUDE.md "Thin Feature Rule" + `arch.md` | Structural — `import_guard` custom_lint + arch test `domain_import_rules_test.dart` |
| All UI text via `S.of(context)` — never hardcode strings | CLAUDE.md "i18n Rules" | Manual review |
| All ¥ amounts via `AppTextStyles.amountLarge/amountMedium/amountSmall` (`FontFeature.tabularFigures()`) | CLAUDE.md "Amount Display Style" | Manual review (CRITICAL — code reviewer's gate) |
| Currency formatting via `FormatterService().formatCurrency(amount, currencyCode, locale)`; **never hardcode `'JPY'`** | CLAUDE.md Common Pitfall #9 ("Don't hardcode widget parameter defaults") | Manual review — `SoulFullnessCard:163` currently violates this; Phase 10 eliminates the violation |
| Date formatting via `DateFormatter` from `lib/infrastructure/i18n/formatters/`; locale from `currentLocaleProvider` | CLAUDE.md "i18n Rules" | Manual review |
| Update ALL 3 ARB files (ja/zh/en) when adding translations, then run `flutter gen-l10n` | CLAUDE.md "i18n Rules" | ARB-parity CI guardrail |
| Riverpod: ONE `repository_providers.dart` per feature/domain; never throw `UnimplementedError` in providers | CLAUDE.md "Riverpod Provider Rules" | Structural — `provider_graph_hygiene_test.dart` |
| Widget Parameter Pattern: nullable parameters with provider fallback — never hardcode defaults | CLAUDE.md Pitfall #9 | Manual review |
| Use `intl: 0.20.2` (pinned by flutter_localizations) | CLAUDE.md Pitfall #5 | Structural — exact pin in `pubspec.yaml` line 18 |
| Domain layer must NOT import from data layer | CLAUDE.md Pitfall #2 | Structural — `import_guard` custom_lint + arch test |
| Don't use `sqlite3_flutter_libs` (use only `sqlcipher_flutter_libs`) | CLAUDE.md Pitfall #6 | Structural — `import_guard` deny rule + AUDIT-09 CI guardrail |
| `flutter analyze` must report 0 issues before commit | CLAUDE.md "Code Quality" + Pitfall #8 | Structural — `audit.yml` line 34 |
| Don't modify generated files (`.g.dart`, `.freezed.dart`); regenerate code after merge/pull | CLAUDE.md Pitfall #1, #13 | Structural — AUDIT-10 CI guardrail |
| Files <800 lines, functions <50 lines | `coding-style.md` | Manual review |
| TDD workflow + 70-80% coverage | `testing.md` (project) / `.claude/rules/testing.md` | Manual review + coverage report |
| Worklog generation after task completion | `worklog.md` | Manual review |

## Standard Stack

### Core (already installed — Phase 10 adds NOTHING)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Flutter SDK | 3.41.8 (stable, 2026-04-24) [VERIFIED: `flutter --version`] | UI toolkit | Project-locked |
| `flutter_riverpod` | ^2.6.1 [VERIFIED: pubspec.yaml] | State management with `@riverpod` codegen | Project's mandatory state pattern (CLAUDE.md) |
| `riverpod_annotation` | ^2.6.1 [VERIFIED: pubspec.yaml] | Codegen annotations for providers | Required by riverpod codegen toolchain |
| `riverpod_generator` | ^2.6.4 [VERIFIED: pubspec.yaml] | Build runner adapter | — |
| `freezed_annotation` | ^3.0.0 [VERIFIED: pubspec.yaml] | Immutable model annotations | Required by all data models |
| `intl` | 0.20.2 (exact pin) [VERIFIED: pubspec.yaml; CLAUDE.md Pitfall #5] | Locale-aware number/date formatting | Pinned by `flutter_localizations` — bumping breaks gen-l10n |
| `flutter_localizations` | (Flutter SDK) | i18n delegates for ja/zh/en | Required for ARB consumption |

**Version verification:** All four dependencies above were checked against the running `pubspec.yaml`; values match. No `npm view` equivalent — Flutter ecosystem version verification is via `pub.dev` and the local `pubspec.lock`. [VERIFIED: bash inspection 2026-05-02]

### Supporting (already in project — Phase 10 reuses)

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `package:flutter/material.dart` | (SDK) | Material 3 widgets, `CustomPaint`, `CustomPainter`, `Tooltip`, `GestureDetector`, `Icons.*` | Hero card composition, ring rendering, tap target |
| `lib/core/theme/app_colors.dart` | (project) | Light + dark color tokens (`AppColors.soul/survival/accentPrimary/olive/shared`/`oliveLight`/`sharedBorder`/`sharedChevron`) | All accent colors in card |
| `lib/core/theme/app_theme_colors.dart` extension | (project) | Light/dark theme-aware tokens (`context.wmCard`, `wmBackgroundDivider`, `wmTextPrimary`, etc.) | Card surface, dividers, text colors |
| `lib/core/theme/app_text_styles.dart` | (project) | Typography incl. `amountLarge/Medium/Small` with `FontFeature.tabularFigures()` | All ¥ amounts (mandatory per CLAUDE.md) |
| `lib/application/i18n/formatter_service.dart` | (project) | `FormatterService().formatCurrency(amount, currencyCode, locale)` | Currency-formatted display |
| `lib/infrastructure/i18n/formatters/date_formatter.dart` | (project) | `DateFormatter.formatDate(date, locale)` short-month form | Best Joy strip date |
| `lib/infrastructure/i18n/formatters/joy_density_formatter.dart` | (project) | `formatJoyDensity(rawDensity, currencyCode)` (Phase 9 D-20 — currency-aware unit `/¥1k` etc.) | Joy/¥ legend value display |
| `lib/application/accounting/category_localization_service.dart` | (project) | `CategoryLocalizationService.resolveFromId(categoryId, locale)` | Best Joy `category` text |
| `lib/generated/app_localizations.dart` (codegen) | (project) | `S.of(context)` ARB-driven strings | All UI text |

### Alternatives Considered (and rejected — already documented in CONTEXT.md)

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `CustomPainter` 3-ring chart | `fl_chart` `RadialBarChart` (already in project; used in `daily_expense_chart.dart`) | `fl_chart` lacks SweepGradient with stop-control on a stroked arc; Phase 10 needs gradient endpoints + custom track + 3 nested concentric rings — `CustomPainter` is the simpler/more-flexible path. **Project policy in CONTEXT.md "Stack" guarantees zero new dependencies in Phase 10.** [CITED: CONTEXT.md `<canonical_refs>` "Phase 10 → no new dependencies"] |
| `CustomPainter` ring chart | Stack of `Container` + `BoxDecoration` with `BorderRadius.circular(999)` | Cannot render gradient sweep arcs with partial sweep angles; would degrade to solid-color rings. |
| Inline ring widget for both modes | Mode-aware painter (single mode reads `HappinessReport`, group reads `FamilyHappiness`) | Mode-switch mid-card forbidden per D-03/D-04. Use a discriminated union (Dart sealed class or constructor-level branch) to encode mode at painter input time. |
| `showDialog` for ⓘ tooltips | `Tooltip` widget | `Tooltip` is on-hover/long-press — works on mobile via long-press but is less discoverable. `showDialog` is more explicit on tap. **Planner picks per existing app convention; recommendation: project lacks an established info-tooltip pattern (grep returned only `Tooltip` on FAB-style icons), so a custom `showDialog`-based `_InfoIconButton` private widget is recommended.** |

**Installation:** None — zero new pub dependencies. Phase 10 ships entirely on existing project deps. [VERIFIED: CONTEXT.md "Stack guarantee"]

## Architecture Patterns

### System Architecture Diagram

```
                    ┌─────────────────────────────────────┐
                    │  HomeScreen (ConsumerWidget)        │
                    │  features/home/presentation/screens │
                    │                                      │
                    │  ref.watch:                          │
                    │  - monthlyReportProvider             │
                    │  - happinessReportProvider           │
                    │  - bestJoyMomentProvider             │
                    │  - familyHappinessProvider (cond.)   │
                    │  - shadowBooksProvider (cond.)       │
                    │  - shadowAggregateProvider (cond.)   │
                    │  - isGroupModeProvider               │
                    │  - currentLocaleProvider             │
                    │  - bookByIdProvider (NEW, D-12)      │
                    └────┬────────────────────────────────┘
                         │ AsyncValue.when() — collapse
                         │ all to resolved Freezed values
                         ▼
                    ┌─────────────────────────────────────┐
                    │  HomeHeroCard (StatelessWidget)     │
                    │  features/home/presentation/widgets │
                    │  takes resolved aggregates +        │
                    │  currencyCode + locale + onTap      │
                    └────┬────────────────────────────────┘
                         │ composes (private sub-widgets)
                         ▼
        ┌──────────┬──────────┬──────────┬──────────┬─────────────┐
        │ _Hero    │ _Soul    │ _Ring    │ _BestJoy │ _Members    │
        │ Header   │ Survival │ Section  │ Strip    │ Section     │
        │          │ SplitBar │          │          │ (group only)│
        └──────────┴──────────┴────┬─────┴──────────┴─────────────┘
                                   │ CustomPaint
                                   ▼
                       ┌────────────────────────────┐
                       │ _HappinessRingsPainter     │
                       │ extends CustomPainter      │
                       │                            │
                       │ Mode-aware:                │
                       │  - Single → HappinessReport│
                       │  - Group  → FamilyHappiness│
                       │                            │
                       │ Sealed-pattern-match on    │
                       │ MetricResult<T>:           │
                       │  - Empty<T>(): track only  │
                       │  - Value<T>(data, n):      │
                       │      sweep ratio from data │
                       └────────────────────────────┘

Provider graph upstream (already shipped, Phase 9):
  monthlyReportProvider     ──→ GetMonthlyReportUseCase    ──→ MonthlyReport
  happinessReportProvider   ──→ GetHappinessReportUseCase  ──→ HappinessReport
  bestJoyMomentProvider     ──→ GetBestJoyMomentUseCase    ──→ MetricResult<BestJoyMomentRow>
  familyHappinessProvider   ──→ GetFamilyHappinessUseCase  ──→ FamilyHappiness
  shadowBooksProvider       ──→ BookRepository.findShadowBooksByGroupId
  shadowAggregateProvider   ──→ GetMonthlyReportUseCase × N (per shadow book)
  isGroupModeProvider       ──→ activeGroupProvider != null
  currentLocaleProvider     ──→ existing locale provider (settings feature)
  bookByIdProvider (NEW)    ──→ BookRepository.findById(bookId).currency
```

### Recommended Project Structure

```
lib/features/home/presentation/widgets/
├── home_hero_card.dart                   # Master StatelessWidget — 250-400 lines
├── home_hero_card_rings.dart             # Ring section + _HappinessRingsPainter — IF master > 400 lines
├── home_hero_card_member_rows.dart       # Group-mode member rows — IF master > 400 lines
├── (DELETE) month_overview_card.dart     # Folded into home_hero_card hero header
├── (DELETE) ledger_comparison_section.dart  # Folded into split bar (single) + member rows (group)
├── (DELETE) soul_fullness_card.dart      # Replaced wholesale
├── hero_header.dart                      # Existing — UNTOUCHED (month picker only)
├── family_invite_banner.dart             # Existing — UNTOUCHED
├── home_transaction_tile.dart            # Existing — UNTOUCHED
├── transaction_list_card.dart            # Existing — UNTOUCHED
└── section_divider.dart                  # Existing — UNTOUCHED

lib/features/home/presentation/screens/
└── home_screen.dart                      # SIMPLIFIED — replaces 3 widget calls with 1; deletes _computeHappinessROI / _computeSatisfaction / _buildLedgerRows; net file size DECREASES

lib/features/accounting/presentation/providers/
└── repository_providers.dart             # NEW provider added: bookByIdProvider(bookId) → AsyncValue<Book?>; OR alternative: bookCurrencyProvider(bookId) → String

lib/l10n/
├── app_ja.arb                            # NEW keys added (D-10 tooltips + D-09 empty states + ring legend labels + member section header — see "i18n Strategy" section below)
├── app_zh.arb                            # SAME keys, zh translations
└── app_en.arb                            # SAME keys, en translations

test/
├── widget/features/home/presentation/widgets/
│   ├── home_hero_card_test.dart          # NEW — single mode + group mode + 4 empty states + tap target (≥6 test groups)
│   ├── (DELETE) month_overview_card_test.dart
│   ├── (DELETE) soul_fullness_card_test.dart
│   └── home_hero_card_rings_painter_test.dart  # NEW — painter math: sweep angles per Value/Empty
├── golden/
│   ├── home_hero_card_golden_test.dart   # NEW — single light + family light + family dark + thin-sample + all-neutral CTA = 5 goldens minimum
│   ├── (DELETE) soul_fullness_card_golden_test.dart
│   └── (DELETE) summary_cards_golden_test.dart  # IF still relevant after the redesign
└── widget/features/home/presentation/screens/
    └── home_screen_test.dart             # UPDATED — replaces MonthOverviewCard / LedgerComparisonSection / SoulFullnessCard finders with HomeHeroCard finder
```

### Pattern 1: Container Widget With Async Provider

**What:** Parent ConsumerWidget resolves providers via `AsyncValue.when()`; inner StatelessWidget receives ONLY resolved Freezed aggregates. **Why:** Keeps the leaf widget pure (testable without ProviderScope); parent screen owns loading/error rendering.
**When to use:** Universally for Phase 10 — already established at `home_screen.dart` lines 88-105 / 113-128 / 132-143.
**Example:**
```dart
// In home_screen.dart (parent)
reportAsync.when(
  data: (report) {
    final happiness = ref.watch(happinessReportProvider(
      bookId: bookId, year: year, month: month, currencyCode: book.currency,
    ));
    final bestJoy = ref.watch(bestJoyMomentProvider(
      bookId: bookId, year: year, month: month,
    ));
    final family = isGroupMode
      ? ref.watch(familyHappinessProvider(year: year, month: month))
      : const AsyncData(null);
    // ... collapse all to .when(data: (...) => HomeHeroCard(...))
  },
  loading: () => const SizedBox(height: 320, child: Center(child: CircularProgressIndicator())),
  error: (error, _) => _ErrorText(message: '$error'),
);

// In home_hero_card.dart (leaf)
class HomeHeroCard extends StatelessWidget {
  const HomeHeroCard({
    required this.report,
    required this.happiness,
    required this.bestJoy,
    required this.family,            // null in single mode
    required this.shadowBooks,        // null/empty in single mode
    required this.shadowAggregate,    // null in single mode
    required this.currencyCode,
    required this.locale,
    required this.isGroupMode,
    required this.onTap,
    super.key,
  });
  // ... pure render, no ref
}
```
**Source:** Existing pattern at `lib/features/home/presentation/screens/home_screen.dart:88-143`. [VERIFIED: codebase grep]

### Pattern 2: Sealed-class Pattern Matching for `MetricResult<T>`

**What:** Dart-3 exhaustive `switch` over the sealed `MetricResult<T>` type to drive Empty-vs-Value rendering.
**When to use:** Every consumption site of a `MetricResult<T>` field (rings, legend rows, Best Joy strip).
**Example:**
```dart
Widget _buildJoyPerYenLegend(BuildContext context, MetricResult<double> joyPerYen, String currencyCode) {
  return switch (joyPerYen) {
    Empty() => Text(
        S.of(context).homeNoSoulDataLegend,
        style: AppTextStyles.bodyMedium.copyWith(color: context.wmTextSecondary),
      ),
    Value(:final data, sampleSize: _) => Text(
        formatJoyDensity(data, currencyCode),     // "1.2 / ¥1k"
        style: AppTextStyles.amountSmall.copyWith(color: AppColors.soul),
      ),
  };
}
```
**Source:** `lib/features/analytics/domain/models/metric_result.dart:6-14` documents the pattern; existing project use is sparse — Phase 10 establishes the consumer-side precedent.

### Pattern 3: CustomPainter for Concentric Gradient Rings

**What:** Subclass `CustomPainter` and use `Canvas.drawArc(rect, startAngle, sweepAngle, useCenter, paint)` per ring with `Paint().shader = SweepGradient(...).createShader(rect)`. **When to use:** Once for the entire 3-ring chart. **Performance:** `shouldRepaint` returns `false` when input Freezed aggregates haven't changed (Freezed's value equality makes this trivial).
**Example:**
```dart
// Source: Flutter docs (api.flutter.dev) — shouldRepaint pattern + Canvas.drawArc
// [CITED: docs.flutter.dev/flutter-for/uikit-devs — CustomPainter signature painter pattern]

class _HappinessRingsPainter extends CustomPainter {
  const _HappinessRingsPainter({
    required this.outerSweepRatio,      // 0..1; null = Empty (track only)
    required this.middleSweepRatio,
    required this.innerSweepRatio,
    required this.outerGradient,        // SweepGradient
    required this.middleGradient,
    required this.innerGradient,
    required this.trackColor,
    required this.strokeWidth,           // 8px per CONTEXT spec
    required this.ringGap,               // 4px per CONTEXT spec
  });

  final double? outerSweepRatio;   // null encodes Empty
  final double? middleSweepRatio;
  final double? innerSweepRatio;
  final SweepGradient outerGradient;
  final SweepGradient middleGradient;
  final SweepGradient innerGradient;
  final Color trackColor;
  final double strokeWidth;
  final double ringGap;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radii = [
      size.width / 2 - strokeWidth / 2,                                  // outer
      size.width / 2 - strokeWidth / 2 - (strokeWidth + ringGap),         // middle
      size.width / 2 - strokeWidth / 2 - 2 * (strokeWidth + ringGap),     // inner
    ];
    final ratios = [outerSweepRatio, middleSweepRatio, innerSweepRatio];
    final gradients = [outerGradient, middleGradient, innerGradient];

    for (var i = 0; i < 3; i++) {
      final r = radii[i];
      final rect = Rect.fromCircle(center: center, radius: r);

      // Track (always rendered behind fill)
      final trackPaint = Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, 0, 2 * pi, false, trackPaint);

      // Fill arc (only if Value, not Empty)
      final ratio = ratios[i];
      if (ratio != null && ratio > 0) {
        final fillPaint = Paint()
          ..shader = gradients[i].createShader(rect)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;
        const startAngle = -pi / 2;       // 12 o'clock
        final sweepAngle = (ratio.clamp(0.0, 1.0)) * 2 * pi;
        canvas.drawArc(rect, startAngle, sweepAngle, false, fillPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_HappinessRingsPainter oldDelegate) =>
      outerSweepRatio != oldDelegate.outerSweepRatio
      || middleSweepRatio != oldDelegate.middleSweepRatio
      || innerSweepRatio != oldDelegate.innerSweepRatio
      || trackColor != oldDelegate.trackColor;
  // gradients are const SweepGradients; their identity won't change unless theme switches.
}
```
**Source:** Flutter API docs `api.flutter.dev` `Canvas.drawArc` + `SweepGradient`; `docs.flutter.dev/flutter-for/uikit-devs` CustomPainter pattern. [CITED: Context7 fetch 2026-05-02]

**Performance considerations:**
- Wrap the `CustomPaint` widget in `RepaintBoundary` to isolate the rings from rebuilds in the rest of the card. Cost: one extra layer in the compositor; benefit: avoids re-rasterizing rings on Best Joy strip rebuild. Recommended given the rings are visually expensive (3 stroked arcs + 3 gradients).
- `shouldRepaint` should return `false` when sweep ratios + track color are equal — Freezed aggregates have value equality so this works trivially.
- `SweepGradient` instances should be `const` where possible (gradient stops are constants). The shader is created lazily via `createShader(rect)` per paint call; Flutter caches shaders internally per Skia.
- For `Empty<T>()` rings: pass `null` ratio → painter draws ONLY the track (per D-09 + Claude's-Discretion recommendation: "full subdued track for visual consistency").

### Pattern 4: Sweep-ratio normalization (Joy/¥ outer ring — single mode)

**What:** Outer ring sweep represents "Joy/¥ density" but density is unbounded. CONTEXT.md D-03 says sweep = "% toward last month's value". **Recommendation per UI-SPEC Open Question #5 + research:** clamp at last-month value = 100% sweep; if no last-month value (first month), use a normalized scale (e.g., 0..2.0 mapping to 0..360°); overflow shows full sweep + small "+X%" inline label.

**Implementation:**
```dart
double? _outerSweepRatio({
  required MetricResult<double> joyPerYen,
  required MetricResult<double>? lastMonthJoyPerYen,    // optional — Phase 10 may not have prev month happiness
}) {
  return switch (joyPerYen) {
    Empty() => null,    // → Empty branch in painter
    Value(:final data) => switch (lastMonthJoyPerYen) {
      Value(data: final prev) when prev > 0 => (data / prev).clamp(0.0, 1.0),
      _ => (data / 2.0).clamp(0.0, 1.0),    // fallback: 0..2.0 scale
    },
  };
}
```
**Open question:** Phase 10 may not need to compute previous-month `joyPerYen` (that requires a second `happinessReportProvider` call with year/month set to previous month). **Recommendation:** Phase 10 ships with the fallback scale only (0..2.0 normalized) — adding the prev-month query introduces a dependency on `monthlyReport.previousMonthComparison`-style support in `happinessReportProvider` which doesn't exist. This keeps Phase 10 scope tight and matches D-03's "% toward last month's value" only when the data is available, falling back gracefully when not. Planner verifies and decides.

### Anti-Patterns to Avoid

- **Anti-pattern: Hardcoded `'JPY'` in widget body.** Bad because it breaks multi-currency support. **What to do instead:** Resolve `Book.currency` via a new `bookByIdProvider(bookId)` consumer at the parent screen, pass `currencyCode: book.currency` into `HomeHeroCard`. Existing offence at `soul_fullness_card.dart:163` is eliminated by this rebuild. [VERIFIED: codebase grep]

- **Anti-pattern: Recreating `_computeHappinessROI`-style budget-share metric** as a UI label on the split bar (e.g., "Joy %", "happiness share", "joy ratio", "soul %"). This resurrects the deleted anti-pattern; reverts the milestone's anti-Goodhart stance. **What to do instead:** D-02 split bar shows ABSOLUTE Yen amounts only; bar's gradient extent is purely a CATEGORY DISTRIBUTION visualization. Labels MUST stay "魂帳" / "生存帳". [CITED: research/FEATURES.md lines 81-82]

- **Anti-pattern: Per-member happiness scores in member rows** (group mode). FAMILY-01/02 contract bans this. **What to do instead:** Member rows show only `(avatar, displayName, ¥amount)` — `¥amount` is `shadowAggregate.perBookReports[shadow.book.id].totalExpenses`. No satisfaction/joy/highlights columns per member. [CITED: research/FEATURES.md anti-features inventory]

- **Anti-pattern: Streak / badge / target / cross-period happiness chips.** ADR-012 binding. **What to do instead:** The `+X%` trend chip is for SPENDING (absolute Yen), not happiness. Never add a "vs 4月 Joy" chip.

- **Anti-pattern: Reading raw `MetricResult` data without sealed-pattern matching.** UI may emit NaN/infinity. **What to do instead:** Always `switch (result) { case Empty(): ...; case Value(:final data, :final sampleSize): ...; }` — exhaustive sealed match.

- **Anti-pattern: Rendering ¥ amounts with generic `bodyMedium` or `titleSmall`.** Loses tabular figure alignment, columns wobble. **What to do instead:** All ¥ amounts via `AppTextStyles.amountLarge / amountMedium / amountSmall` (CLAUDE.md Amount Display Style; code reviewer's gate). [CITED: CLAUDE.md "Amount Display Style"]

- **Anti-pattern: Mode-mid-card switch (rendering single-mode rings + group-mode member rows simultaneously, OR computing both ring sets and choosing).** D-03/D-04 forbid this. **What to do instead:** Provider selection is a top-level branch — `if (isGroupMode) renderGroupVariant() else renderSingleVariant()` at the parent screen, NOT inside the painter or sub-widget.

- **Anti-pattern: AnalyticsRegion-enum coupling Phase 10 ↔ Phase 11.** Phase 11 hasn't built the sub-region. **What to do instead:** Phase 10 ships with a TODO route OR placeholder `SnackBar('TODO: route to Phase 11 sub-region')` — D-11 explicitly permits this. Don't introduce a half-baked enum that Phase 11 then has to refactor.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Currency formatting | Custom `'¥' + NumberFormat('#,##0').format(...)` everywhere | `FormatterService().formatCurrency(amount, currencyCode, locale)` (`lib/application/i18n/formatter_service.dart:56`) | Locale + currency-symbol consistency; eliminates hardcoded `'JPY'`. |
| Joy density value display ("1.2 / ¥1k") | Custom multiplication + concat | `formatJoyDensity(rawDensity, currencyCode)` (`lib/infrastructure/i18n/formatters/joy_density_formatter.dart:30`) | Phase 9 D-20 single source of truth for PTVF base + display unit per currency. |
| Date formatting (Best Joy strip) | Manual `${date.month}月${date.day}日` | `DateFormatter.formatDate(date, locale)` (use `formatMonthYear` / `formatRelative` if better fit, OR introduce `formatShortMonthDay`) | Locale handling for ja/zh/en differences (e.g., en: `Apr 15` vs ja: `4月15日`). **Open question:** existing `DateFormatter` only has full-date and month-year — Phase 10 may need to add a short-form helper (planner decides whether to extend `DateFormatter` or use inline `DateFormat` from `intl`). Recommend extending `DateFormatter` with `formatShortMonthDay(date, locale)` since the spec uses "4月15日" / "Apr 15" specifically. |
| Category text from category ID | Manual category lookup | `CategoryLocalizationService.resolveFromId(categoryId, locale)` | Already used in `home_screen.dart:225-228`; keeps category name resolution centralized. |
| Trend chip arithmetic | Custom percentage formula | Reuse `((current - previous) / previous * 100).round()` from existing `MonthOverviewCard:36-40` | Existing tested arithmetic; planner copies, doesn't reinvent. |
| Empty / Value branching | Custom null/zero checks | `switch (metricResult) { case Empty(): ...; case Value(:final data): ...; }` (Dart 3 sealed) | Type-safety; compile-time exhaustiveness. |
| Group-mode gate | Custom flag | `isGroupModeProvider` (Phase 9-shipped) | Already wired across the app. |
| Avatar circle rendering | Hand-painted `CustomPaint` | `Container` + `BoxDecoration(shape: BoxShape.circle, color: ...)` with a `Text(initial)` child | 12-line standard pattern; no canvas needed. |
| Ring color theming | Hex literals | `AppColors.soul / survival / accentPrimary / olive / shared` + `context.wm*` for theme-aware values | D-13 deferral; final tokens come from existing theme. |
| ARB key VALUE renames | Inline strings | New ARB keys (D-10 + D-09 + ring legend labels) | Phase 12 owns existing-key VALUE renames; Phase 10 only ADDS keys. |
| Provider for `Book.currency` | Inline `BookRepository.findById(bookId)` calls in widget | NEW `bookByIdProvider(bookId)` in `lib/features/accounting/presentation/providers/repository_providers.dart` | Riverpod-canonical; testable; cacheable. Verified `BookRepository.findById` exists at line 6 of repo interface. |

**Key insight:** Phase 10 adds zero pure-business-logic helpers. Every "operation" already has a project-internal helper or Phase 9 deliverable. The work is purely composition + layout + styling + sealed-pattern-match wiring. If a sub-task feels like it needs a new helper, the helper probably exists already — grep first.

## Runtime State Inventory

> **Skipped:** Phase 10 is a UI rebuild (replace 3 widgets with 1, delete 2 helper methods). No rename, refactor, or migration of stored / live-service / OS-registered / secrets / build-artifact state. The closest "rename" event is the Phase 12 ARB *value* rename — that's a separate phase.

**Stored data:** None — no DB writes in Phase 10. Schema v16 unchanged (CONTEXT.md D-08 + D-12 explicit).
**Live service config:** None — no external service touched.
**OS-registered state:** None — no scheduler, daemon, or platform registration.
**Secrets / env vars:** None — no new secrets, no env consumption.
**Build artifacts:** Generated files (`*.g.dart`, `*.freezed.dart`) regenerate via `build_runner` after ARB additions. CLAUDE.md Pitfall #13 ("regenerate after merge") applies — planner adds a build_runner step in plans that touch ARB or providers.

## Common Pitfalls

### Pitfall 1: Hardcoded `'JPY'` Resurfaces

**What goes wrong:** Developer copies the existing `SoulFullnessCard:163` pattern (`FormatterService().formatCurrency(amount, 'JPY', locale)`) into `HomeHeroCard` because it "looks similar". Multi-currency support breaks silently for non-JPY books.
**Why it happens:** Existing code has the violation; it's the path of least resistance.
**How to avoid:** Phase 10 plan must include a CHECK step: `grep -n "'JPY'" lib/features/home/presentation/widgets/home_hero_card.dart` returns 0. Code reviewer enforces. **CLAUDE.md Pitfall #9 is manually-checked only — no automated detection.**
**Warning signs:** A literal `'JPY'` (or any currency code) appears anywhere in `home_hero_card.dart`. The widget should accept `currencyCode: String` from its constructor.

### Pitfall 2: Anti-pattern label leaks onto the split bar

**What goes wrong:** Developer (or AI assistant) writes a label "魂 21%" or "Joy share: 21%" on the split bar because percentages "feel informative". This resurrects `_computeHappinessROI`.
**Why it happens:** Labels naturally suggest themselves when bar is proportional; without conscious gate, percentages creep in.
**How to avoid:** Plan unit explicitly states: "魂帳 / 生存帳 labels show ABSOLUTE ¥ amounts; bar VISUALIZES proportion; NO percentage text anywhere on/under the bar". Code reviewer is the final gate. Forbidden phrases to grep for: `'%' adjacent to '魂'`, `'Joy ROI'`, `'happiness share'`, `'joy ratio'`, `'soul %'`. [CITED: CONTEXT.md D-02 + research/FEATURES.md lines 81-82]
**Warning signs:** Any percentage glyph (`%`) inside the split bar render code; label text mentioning "share", "ratio", "ROI", "%".

### Pitfall 3: GestureDetector tap region doesn't cover the entire card

**What goes wrong:** Inner widgets (Best Joy strip, member rows) have their own `GestureDetector` that "absorbs" the tap, so the whole-card-tap (D-11) doesn't fire on those regions.
**Why it happens:** The existing `LedgerComparisonSection._LedgerRow` uses `GestureDetector(onTap: ...)`. Carrying that pattern forward without disabling sub-taps breaks D-11.
**How to avoid:** `HomeHeroCard` wraps its entire content in ONE root `GestureDetector(onTap: onTap)` and inner sub-widgets use `behavior: HitTestBehavior.translucent` (or omit GestureDetector entirely). For ⓘ icons, use `IgnorePointer` / `Tooltip` widgets carefully — the ⓘ tooltip tap should NOT bubble to the card-tap (use `GestureDetector(behavior: HitTestBehavior.opaque)` on the icon to absorb the tap and stop propagation). **Planner allocates an explicit "tap-target verification" sub-task in the test plan unit.**
**Warning signs:** Tapping the Best Joy strip doesn't navigate; tapping a member row navigates twice; tapping ⓘ navigates to AnalyticsScreen instead of showing the tooltip.

### Pitfall 4: ⓘ tooltip count drift (>2)

**What goes wrong:** Developer adds a third ⓘ tooltip "to explain the trend chip" or "to clarify the median". HOMEUI-04 caps at 2.
**Why it happens:** Tooltips feel cheap to add; "clarification" pressure mounts on review.
**How to avoid:** Plan unit asserts: "exactly 2 `Icons.info_outline` instances in `home_hero_card.dart`". Test asserts `find.byIcon(Icons.info_outline)` length == 2 in any rendered card variant. Reviewer rejects PRs with >2.
**Warning signs:** Any `Icons.info_outline` / `Icons.help_outline` / `Icons.info_outlined` in the card beyond the 2 sanctioned (ring section title + Joy/¥ legend).

### Pitfall 5: ARB-parity CI failure — adding a key to one locale only

**What goes wrong:** Developer adds `homeJoyIndexTooltip` to `app_ja.arb` but forgets `app_en.arb` and `app_zh.arb`. `flutter gen-l10n` fails OR ARB-parity CI guardrail fails.
**Why it happens:** 3 files, 1 reasonable forgetting.
**How to avoid:** Plan unit checklist: "Updated keys in ALL 3 ARB files" with the exact keys listed. CLAUDE.md i18n rule mandates triple-update. CI guardrail catches. Recommend a single plan unit dedicated to ARB additions (atomically updates all 3 files).
**Warning signs:** Build fails post-merge; `flutter gen-l10n` warnings about missing keys.

### Pitfall 6: `MetricResult.Empty` causing NaN division when sweep ratio is computed

**What goes wrong:** Developer writes `final sweep = (joyPerYen.data / lastMonth.data) * 360` without checking `Empty` first; runtime emits NaN; canvas paints garbage.
**Why it happens:** `MetricResult.data` access on `Empty` throws (sealed class); but a developer who casts via `(result as Value).data` skips the check.
**How to avoid:** Always sealed-pattern-match BEFORE accessing `data`. Plan unit's painter test fixture must include an `Empty<double>()` case for each ring.
**Warning signs:** `(... as Value)` casts in the painter or its callers. `Cannot access data on Empty<T>` runtime exceptions in widget tests.

### Pitfall 7: Ring center text shows "0" or "-" for `Empty<double>` average satisfaction

**What goes wrong:** Center text shows "0.0" because developer wrote `happiness.avgSatisfaction.data?.toStringAsFixed(1) ?? "0.0"` instead of branching on Empty.
**Why it happens:** `MetricResult.data` is non-nullable on `Value`; Empty has no `data`. Developer overcompensates with `?? "0.0"`.
**How to avoid:** Empty state uses dedicated empty copy (`homeNoSoulDataLegend` / "—") — NEVER "0.0". Sealed pattern match enforces this.
**Warning signs:** Ring center reads "0.0" when `totalSoulTx == 0`. Reviewer + golden test reject.

### Pitfall 8: Member row order is non-deterministic

**What goes wrong:** Group-mode member rows come from `shadowBooksProvider` which queries DB. Without an explicit sort, row order may differ across runs (especially after sync) — golden tests flake.
**Why it happens:** SQL queries without `ORDER BY` return implementation-defined order.
**How to avoid:** Sort `shadowBooks` by `memberDisplayName` (stable, locale-aware) OR `book.id` (always-stable) at the consumer site (`HomeHeroCard` or pre-passed in `home_screen.dart`). Plan unit specifies the sort key explicitly. Verify with widget-test fixture having ≥3 members.
**Warning signs:** Golden tests flake on rerun; visual inspection shows row order changed without code changes.

### Pitfall 9: AnalyticsRegion enum half-built then orphaned

**What goes wrong:** Phase 10 introduces `enum AnalyticsRegion { joyLedger }` to make D-11 nav explicit; Phase 11 then builds the sub-region differently and the enum becomes vestigial.
**Why it happens:** Premature contract design across phase boundaries.
**How to avoid:** Phase 10 uses the simplest viable nav (D-11 Option B): `Navigator.push(MaterialPageRoute(builder: (_) => AnalyticsScreen(bookId: bookId)))` with NO enum, OR a SnackBar if `AnalyticsScreen` doesn't accept an initial-region param yet. **Phase 11's planner introduces `AnalyticsRegion` and refactors Phase 10's call site.** [CITED: CONTEXT.md D-11]
**Warning signs:** A new enum file `analytics_region.dart` with one variant; comments saying "Phase 11 will populate".

### Pitfall 10: Tabular figures lost on Best Joy small-line amount

**What goes wrong:** Best Joy small line is `'¥3,000 · 满足 10/10 ✨'` — a single inline `Text` widget without `AppTextStyles.amount*`, so the ¥3,000 doesn't get tabular figure alignment. Adjacent rows wobble.
**Why it happens:** D-04 specifies fontSize 9, fontWeight 500 — outside `AppTextStyles.amount*` scale. Tempting to use plain `TextStyle()`.
**How to avoid:** Inline TextStyle MUST add `fontFeatures: const [FontFeature.tabularFigures()]` per UI-SPEC "Tabular figures gate". Plan unit's typography review verifies all numeric inline styles include this.
**Warning signs:** Inline `TextStyle(fontSize: 9, fontWeight: FontWeight.w500)` without `fontFeatures` field.

### Pitfall 11: `home_screen.dart` net-DECREASE expectation isn't enforced

**What goes wrong:** Net-line-count of `home_screen.dart` increases instead of decreases (per CONTEXT.md "Existing Code Insights"), because the developer adds wiring code without removing the deleted helpers (`_computeHappinessROI`, `_computeSatisfaction`, `_buildLedgerRows`).
**Why it happens:** Refactor in flight; deletions left until "after it works".
**How to avoid:** Plan unit explicitly asserts: "After Phase 10, `wc -l home_screen.dart` returns < (current count: ~387 lines)". Pre-commit grep verifies `_computeHappinessROI`, `_computeSatisfaction`, `_buildLedgerRows` return 0 matches. [VERIFIED: existing `home_screen.dart:387` lines]
**Warning signs:** PR diff shows new code in `home_screen.dart` but no deletions; line count up.

### Pitfall 12: Voice-bias mention sneaks back into the Joy/¥ tooltip

**What goes wrong:** Developer (or AI) writes the tooltip from training memory and includes "Voice estimator may bias scores" — D-10 explicitly removed this for v1.1.
**Why it happens:** ADR-014 + Phase 9 D-12 mention voice-bias; tooltips "feel like" the right place to disclose.
**How to avoid:** ARB key `homeJoyPerYenTooltip` value is locked verbatim per UI-SPEC table. Reviewer verifies copy matches the locked value. Phase 12 may revisit for v1.2 voice realignment.
**Warning signs:** Tooltip text containing 「音声」 / 「voice」 / 「语音」 in any locale.

## Code Examples

Verified patterns from official sources + project internals:

### Example 1: Currency formatting (D-12 — eliminates hardcoded JPY)

```dart
// Source: lib/application/i18n/formatter_service.dart:56 [VERIFIED via codebase grep]
const formatter = FormatterService();
final formatted = formatter.formatCurrency(
  monthlyReport.totalExpenses,
  currencyCode,                   // <- from bookByIdProvider, NOT 'JPY' literal
  locale,                          // <- from currentLocaleProvider
);
// Renders: ¥123,456 (JPY) / ¥1,234.56 (CNY) / $1,234.56 (USD)
```

### Example 2: Joy density display (Phase 9 D-20)

```dart
// Source: lib/infrastructure/i18n/formatters/joy_density_formatter.dart:30 [VERIFIED]
final displayText = formatJoyDensity(rawDensity, currencyCode);
// JPY: "1.2 / ¥1k"   CNY: "1.2 / ¥100"   USD: "1.2 / $1"   Unknown: falls back to JPY semantics
```

### Example 3: Sealed MetricResult pattern matching

```dart
// Source: lib/features/analytics/domain/models/metric_result.dart:6 [VERIFIED]
Widget _buildAvgSatLegend(MetricResult<double> avgSat) {
  return switch (avgSat) {
    Empty() => Text(
        S.of(context).homeNoSoulDataLegend,
        style: AppTextStyles.bodyMedium.copyWith(color: context.wmTextSecondary),
      ),
    Value(:final data, sampleSize: _) => Text(
        data.toStringAsFixed(1),
        style: AppTextStyles.amountSmall.copyWith(color: AppColors.olive),
      ),
  };
}
```

### Example 4: Provider wiring at parent screen (proposed)

```dart
// Inside home_screen.dart's build method (REPLACES current 3 separate .when() calls)
final bookAsync = ref.watch(bookByIdProvider(bookId: bookId));      // NEW provider
final reportAsync = ref.watch(monthlyReportProvider(...));
final happinessAsync = bookAsync.maybeWhen(
  data: (book) => ref.watch(happinessReportProvider(
    bookId: bookId, year: year, month: month,
    currencyCode: book?.currency ?? 'JPY',                          // fallback only if book is missing — book SHOULD always exist
  )),
  orElse: () => const AsyncLoading<HappinessReport>(),
);
final bestJoyAsync = ref.watch(bestJoyMomentProvider(...));
final familyAsync = isGroupMode
  ? ref.watch(familyHappinessProvider(year: year, month: month))
  : const AsyncData<FamilyHappiness?>(null);
final shadowAsync = isGroupMode ? ref.watch(shadowAggregateProvider(...)) : const AsyncData<ShadowAggregate?>(null);
final shadowBooksAsync = isGroupMode ? ref.watch(shadowBooksProvider) : const AsyncData<List<ShadowBookInfo>>([]);

// Collapse — recommend a multi-AsyncValue helper OR sequential .when() with a single skeleton fallback
return reportAsync.when(
  data: (report) => happinessAsync.when(
    data: (happiness) => bestJoyAsync.when(
      data: (bestJoy) => familyAsync.when(
        data: (family) => shadowAsync.when(
          data: (shadow) => shadowBooksAsync.when(
            data: (shadowBooks) => HomeHeroCard(
              report: report,
              happiness: happiness,
              bestJoy: bestJoy,
              family: family,
              shadowBooks: shadowBooks,
              shadowAggregate: shadow,
              currencyCode: bookAsync.valueOrNull?.currency ?? 'JPY',
              locale: locale,
              isGroupMode: isGroupMode,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => AnalyticsScreen(bookId: bookId),
                ),
              ),
            ),
            // ... loading + error
          ),
          // ... loading + error
        ),
        // ... loading + error
      ),
      // ... loading + error
    ),
    // ... loading + error
  ),
  // ... loading + error
);
```

**Refactor opportunity (planner discretion):** The deeply nested `.when()` chain is hostile. Recommend extracting into a private helper `_buildHomeHeroCardSection(...)` that takes a tuple of AsyncValues and renders skeleton on any loading, error on any error, card on all data. **Or** use a tiny utility like `AsyncValue.combine(...)` (custom). **Note:** Project does NOT currently have an `AsyncValueX.combine` extension — Phase 10 may add one to `lib/shared/extensions/` or use the nested form.

### Example 5: i18n keys mandatory in all 3 locales

```jsonc
// app_ja.arb  (NEW key added)
"homeJoyIndexTooltip": "外輪は Joy/¥ 密度・中輪は満足度の平均・内輪は小確幸の回数（満足度6以上）。",
"@homeJoyIndexTooltip": {
  "description": "Tooltip explaining the 3-ring system on the HomeHeroCard"
}

// app_zh.arb  (SAME key, zh translation)
"homeJoyIndexTooltip": "外环是 Joy/¥ 密度 · 中环是满足度均值 · 内环是小確幸数（满足度 ≥ 6 的次数）。",

// app_en.arb  (SAME key, en translation)
"homeJoyIndexTooltip": "Outer ring is Joy/¥ density · middle is average satisfaction · inner is highlights count (satisfaction ≥ 6).",
```

After ARB additions, run: `flutter gen-l10n` (regenerates `lib/generated/app_localizations.dart`). [CITED: CLAUDE.md "i18n Rules"]

## i18n Strategy

### New ARB keys to introduce in Phase 10

Per UI-SPEC, Phase 10 adds the following NEW keys to `app_ja.arb` + `app_zh.arb` + `app_en.arb`. **All three files MUST be updated atomically.** Phase 12 owns existing-key VALUE renames; Phase 10 only ADDS keys.

| New ARB Key | Purpose | Sourced from |
|-------------|---------|--------------|
| `homeJoyIndexTooltip` | D-10 tooltip 1 (3-ring system explainer) | UI-SPEC Copywriting + D-10 |
| `homeJoyPerYenTooltip` | D-10 tooltip 2 (PTVF + hedonic adaptation) | UI-SPEC + D-10 |
| `homeHeroCardLabelSingle` | Hero label "今月の支出" (single mode) | D-02 |
| `homeHeroCardLabelGroup` | Hero label "家族の支出" (group mode) | D-02 |
| `homeRingSectionTitleGroup` | Group-mode ring title "家族の小確幸 / Family Joy" | D-02 |
| `homeBestJoyTagSingle` | Best Joy tag "本月最爱 / 今月の最愛" (single) | D-04 |
| `homeBestJoyTagGroup` | Best Joy tag (group — same copy per D-04 because group still shows current-user's Best Joy) | D-04 |
| `homeBestJoyAmountSat` | Best Joy small line `{amount} · 满足 {sat}/10 ✨` (placeholder format) | D-04 |
| `homeMembersSectionTitle` | "群组成员 / メンバー / Members" | D-02 + HOMEUI-07 |
| `homeNoSoulDataLegend` | Legend "No data yet" when totalSoulTx == 0 | D-09 |
| `homeBestJoyEmptyBig` | Best Joy CTA BIG line — totalSoulTx==0 | D-09 |
| `homeBestJoyEmptySmall` | Best Joy CTA small line — totalSoulTx==0 | D-09 |
| `homeBestJoyAllNeutralBig` | Best Joy CTA BIG line — all-neutral case | D-09 |
| `homeBestJoyAllNeutralSmall` | Best Joy CTA small line — all-neutral case | D-09 |
| `homeCoverageCaption` | "n={rated}/{total} rated" coverage caption (HAPPY-06) | D-09 + HOMEUI-04 |
| `homeAvgSatisfactionLegend` | Single-mode mid-ring legend label | UI-SPEC |
| `homeJoyPerYenLegend` | Single-mode outer-ring legend label "Joy/¥" | UI-SPEC |
| `homeHighlightsCountLegend` | Single-mode inner-ring legend label "小確幸 ({count})" | UI-SPEC |
| `homeFamilyHighlightsLegend` | Group-mode outer-ring legend label | UI-SPEC |
| `homeSharedJoyLegend` | Group-mode mid-ring legend label "共爱品类 / Shared joy" | UI-SPEC |
| `homeMedianSatisfactionLegend` | Group-mode inner-ring legend label "满足度中位数 / Median satisfaction" | UI-SPEC |

**Existing keys reused (no value changes in Phase 10; Phase 12 may rename values):**

- `homeSoulFullness` — single-mode ring section title (Phase 12 RENAME-04 changes the value to "Joy Index" / "ときめき度" / "悦己充盈")
- `homeSurvivalLedgerTag` / `homeSoulLedgerTag` — split bar tag glyphs
- `survivalLedger` / `soulLedger` — split bar labels (Phase 12 RENAME-01/02 changes values)
- `homePreviousMonthAmount` — "先月 ¥amount" sub-line

### Locale-specific copy nuances

| Locale | Notes | Source |
|--------|-------|--------|
| ja (default) | "今月の支出" / "家族の支出" / "メンバー" / "ときめき度" (Phase 12 only) / "今月の最愛" / "まだ記録なし" — register: warm, soft. Avoid 幸福 (philosophical) — use 小確幸 / ときめき per ADR (Phase 12 to draft). | CONTEXT.md / RENAME-05 / ADR-013 D-20 |
| zh | "本月支出" / "家庭支出" / "群组成员" / "悦己充盈" / "本月最爱" / "尚未记录" — CN family-mode MUST NOT use 「家族悦己」 (collision with personal account name post-Phase-12 rename). Use "家族的小确幸" / "家族小確幸" instead. | CONTEXT.md + RENAME-05 |
| en | "This Month" / "Family This Month" / "Members" / "Joy Index" / "Top of the Month" / "No data yet" — register: minimal, no flowery copy. | UI-SPEC |

**Glyph handling per locale:**
- `✨` glyph in `homeBestJoyAmountSat` template is a Unicode character — renders identically in all locales (no fallback font needed on iOS 14+/Android 7+; verified part of Unicode 6.0 / Emoji 1.0 baseline).
- ¥ symbol in formatted amounts: handled by `FormatterService.formatCurrency` per locale (zh/ja use `¥`, en uses `¥` with `JPY` currency code per `intl` `NumberFormat.currency`).
- `·` (middle dot) used in Best Joy BIG line: renders consistently; locale-neutral.
- `→` arrow in empty-state small line: locale-neutral.

### ARB workflow checklist

1. Add new key to `app_ja.arb` (default — write Japanese copy first per project precedent).
2. Add SAME key to `app_zh.arb` with Chinese translation.
3. Add SAME key to `app_en.arb` with English translation.
4. Add `@key` description block to `app_en.arb` (template per `@homeMonthlyExpense` precedent at line 508).
5. Run `flutter gen-l10n` — regenerates `lib/generated/app_localizations.dart`.
6. Run `flutter analyze` — verifies no missing keys; ARB-parity CI guardrail catches drift.
7. Commit ARB triplet + regenerated `app_localizations.dart` together (avoid stale-generated-files audit failure).

## State of the Art

| Old Approach (current `lib/`) | New Approach (Phase 10) | When Changed | Impact |
|-------------------------------|--------------------------|--------------|--------|
| 3 separate widgets (`MonthOverviewCard` / `LedgerComparisonSection` / `SoulFullnessCard`) on Home tab | 1 integrated `HomeHeroCard` | Phase 10 | Visual hierarchy unified; tap target consolidated; line count drops |
| `_computeHappinessROI(report)` (misleading "soul/total" ratio framed as ROI) | Phase 9 `GetHappinessReportUseCase` (real metrics) | Phase 9 done; Phase 10 retires the inline | Anti-Goodhart: removes a meaningless chart-ready metric |
| `_computeSatisfaction(todayTxAsync)` (intraday-only, ignores month) | `HappinessReport.avgSatisfaction` (month-to-date, soul-only) | Phase 9 done; Phase 10 retires | Correctness: avg now month-scope per HAPPY-01 |
| `'JPY'` hardcoded in `SoulFullnessCard:163` | `currencyCode: book.currency` resolved at parent | Phase 10 | Multi-currency support; CLAUDE.md Pitfall #9 closed for this surface |
| Ring chart absent | 3 concentric gradient rings via `CustomPainter` | Phase 10 | New visual primitive; planner allocates testing for painter math |
| Best Joy never displayed on Home | Best Joy story strip with `本月最爱` tag + emphasis on category+date | Phase 10 (sources from Phase 9 `bestJoyMomentProvider`) | Anti-`¥10 candy` framing: amount visible but de-emphasized |
| Per-member shadow-book rendering as `LedgerComparisonSection` rows (4 lines, with subtitle "先月 ¥X") | Lean member rows (avatar + name + ¥) appended after Best Joy in group mode | Phase 10 | Anti-leaderboard: removes per-member trend metric |

**Deprecated / outdated:**
- `_computeHappinessROI` and `_computeSatisfaction` helpers in `home_screen.dart` (Phase 9 obsoleted them; Phase 10 deletes them).
- `MonthOverviewCard.totalExpense` parameter that aggregates own + shadow totals (`totalExpense: report.totalExpenses + (shadowData?.totalExpenses ?? 0)` at home_screen.dart:92-93) — Phase 10 hero card hero header in group mode shows the FAMILY total via the same computation, so the math is preserved; the widget that displays it is replaced.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `bookByIdProvider` (or equivalent currency lookup) does NOT yet exist in `lib/features/accounting/presentation/providers/repository_providers.dart` (only `bookRepository` provider exists) | Stack / Provider wiring | LOW — code grep verified only `bookRepository` and `findById(id)` interface; widget would receive `bookId` and parent screen needs to look up `Book.currency`. If a `bookByIdProvider` already exists, planner reuses; if not, planner creates one. [VERIFIED: codebase grep returned 0 matches for `bookByIdProvider` / `currentBookId` / `primaryBook` / `defaultBook`] |
| A2 | The current user's `bookId` is already known at HomeScreen level (passed via constructor) | Provider wiring | LOW — verified `home_screen.dart:34` declares `final String bookId;` constructor parameter. |
| A3 | `AnalyticsRegion` enum does NOT exist; `AnalyticsScreen` constructor takes only `bookId` (no initial-region param) | Tap navigation (D-11) | LOW — verified `analytics_screen.dart:25` constructor signature. Phase 10 ships with `Navigator.push(MaterialPageRoute(builder: (_) => AnalyticsScreen(bookId: bookId)))` OR snackbar fallback. |
| A4 | `DateFormatter` does NOT have a `formatShortMonthDay(date, locale)` helper; only `formatDate` (full date) and `formatMonthYear` | Don't Hand-Roll table | LOW — verified `date_formatter.dart` API. Planner extends `DateFormatter` with the helper OR uses inline `DateFormat('M月d日')` per locale. Recommend extension to keep formatter centralized. |
| A5 | Project lacks an established `_InfoIconButton` / `InfoIconButton` reusable widget; no Phase 11 commitment exists for one | Tooltip implementation | LOW — verified codebase grep returned only `Tooltip` on FAB-level icons + `BarTooltipItem` in fl_chart. Phase 10 introduces a private `_InfoIcon` inside `home_hero_card.dart` (or `_show...Dialog` helper); deferred to v1.2 for shared `InfoIconButton`. |
| A6 | Member row sort key should be `memberDisplayName` (locale-aware) for stable golden tests | Pitfall 8 prevention | LOW — recommendation only; planner picks. Either name-sort or `book.id`-sort works; the key is stability. |
| A7 | The outer ring's "% toward last month's value" denominator strategy can use a 0..2.0 fallback in Phase 10 (not querying previous month's `joyPerYen`) | CustomPainter sweep ratio (Pattern 4) | MEDIUM — D-03 says "% toward last month's value" but `happinessReportProvider` doesn't currently take a "previousMonth" call; querying it doubles the call count. **Recommendation:** ship with 0..2.0 fallback; planner verifies with user/UAT whether the denominator strategy needs prev-month support before implementation. |
| A8 | The tooltip's exact wording in `homeJoyPerYenTooltip` does NOT need to mention voice estimator bias for v1.1 | Copywriting / D-10 | LOW — explicitly locked in CONTEXT.md D-10 + Discussion-Log Q13c. v1.2 may revisit. |
| A9 | The `5`-color member avatar palette `[soul, survival, accentPrimary, olive, shared]` is acceptable visual variety | Claude's Discretion | LOW — recommendation only; planner picks. |

**No claim is `[ASSUMED]` without verification — all are either `[VERIFIED]` via grep / codebase inspection or marked as recommendations for planner discretion.**

## Open Questions

These need user/planner judgement before implementation begins. Most are tracked in the UI-SPEC's "Open Questions for Planner" section (lines 402-414 of UI-SPEC).

1. **Outer ring sweep-ratio denominator (Joy/¥)** — A7 above. Use 0..2.0 normalized fallback (Phase 10 minimal scope) OR query previous month's `joyPerYen` for the "% toward last month's value" semantic? **Recommendation:** Phase 10 fallback; revisit in Phase 11 (charts have time-series).
   - What we know: D-03 prescribes "sweep = % toward last month's value" but the data path isn't trivially available; `happinessReportProvider` is per-month, so two queries needed.
   - What's unclear: Whether shipping the fallback is acceptable to user given mockup intent.
   - Recommendation: Plan unit's CustomPainter sub-task drafts with 0..2.0 fallback; UAT flags if it needs upgrade.

2. **`AnalyticsRegion` enum: introduce in Phase 10 or Phase 11?** D-11 explicitly permits a placeholder route OR snackbar in Phase 10.
   - Recommendation: Phase 11 introduces. Phase 10 ships with `Navigator.push(MaterialPageRoute(builder: (_) => AnalyticsScreen(bookId: bookId)))` — minimal viable.

3. **Outer card padding 16 vs 18** (UI-SPEC Open Question #1) — recommend 18 for hero weight given expanded scope.

4. **Tooltip implementation: `Tooltip` widget vs `showDialog`** (UI-SPEC Open Question #6) — recommend `showDialog` for tap-to-explain UX (matches user intent of "点击后弹窗" from Discussion-Log Q9).

5. **CustomPainter test strategy: golden tests + painter math unit tests** (UI-SPEC Open Question #7) — recommend BOTH:
   - Unit test on `_HappinessRingsPainter` math: given input ratios, verify `paint()` calls `drawArc` N times with expected sweep angles (mock `Canvas` via `mocktail`).
   - Golden tests on `HomeHeroCard` rendered output: 5+ goldens covering single-light / family-light / family-dark / thin-sample / all-neutral CTA.

6. **Should `HomeHeroCard` be a `ConsumerWidget` (read providers internally) OR pure `StatelessWidget` (parent resolves)?** UI-SPEC line 277 explicitly says "pure StatelessWidget". Recommendation: **pure StatelessWidget** — testability is the dominant factor (no `ProviderScope` needed for widget tests).

7. **Spec amendment plan unit count: 1 or 2?** CONTEXT.md D-06 (REQUIREMENTS.md) and D-07 (ROADMAP.md) are 2 separate documents. Discussion-Log line 269 recommends **2 explicit plan units** (mirroring Phase 9 plan 09-13).

## Environment Availability

> Skipped — Phase 10 has zero external dependencies beyond what's already installed in the project. No new tools, no new pub packages, no services. CONTEXT.md "Stack" guarantee + verified by `pubspec.yaml` inspection.

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | All | ✓ | 3.41.8 | — |
| `flutter_riverpod` | Provider wiring | ✓ | 2.6.1 | — |
| `freezed_annotation` | Phase 9 model consumption | ✓ | 3.0.0 | — |
| `intl` | Number/date formatting | ✓ | 0.20.2 (exact pin) | — |
| `flutter_localizations` | i18n | ✓ | (Flutter SDK) | — |
| `build_runner` (dev) | Codegen for ARB + providers | ✓ | (existing) | — |
| `mocktail` (dev) | Widget tests | ✓ | (existing — used in `home_screen_test.dart:20`) | — |
| Existing Phase 9 providers (`happinessReportProvider`, etc.) | Data plumbing | ✓ | — | — |

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | `flutter_test` (Flutter SDK) + `mocktail ^1.0.x` for mocks |
| Config file | `pubspec.yaml` (`flutter_test:` section under dev_dependencies) |
| Quick run command | `flutter test test/widget/features/home/presentation/widgets/home_hero_card_test.dart -r expanded` |
| Full suite command | `flutter test --coverage` |

Project already has full Flutter test infrastructure (verified — `test/golden/`, `test/widget/`, `test/features/`, `test_helpers.dart` paths exist). No Wave 0 framework install needed.

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| HOMEUI-01 | `HomeHeroCard` renders 4 personal metrics from `HappinessReport` | widget | `flutter test test/widget/features/home/presentation/widgets/home_hero_card_test.dart -p "renders all 4 metrics in single mode"` | ❌ Wave 0 — new test file |
| HOMEUI-02 | `_computeHappinessROI` + `_computeSatisfaction` deleted from `home_screen.dart` | grep / unit | `! grep -q "_computeHappinessROI\\|_computeSatisfaction" lib/features/home/presentation/screens/home_screen.dart` | ✅ via grep at commit time |
| HOMEUI-03 | Family card visible only when `isGroupMode == true` AND `shadowBooks.isNotEmpty` | widget | `flutter test ... -p "single mode hides family card"` + `... -p "group mode + 0 shadow books hides member rows"` + `... -p "group mode + 3 shadow books shows member rows"` | ❌ Wave 0 |
| HOMEUI-04 | ≤2 ⓘ icons total; coverage caption present when totalSoulTx > 0; no streak/badge/target/cross-period copy | widget | `flutter test ... -p "exactly 2 info icons"` + `... -p "coverage caption visible with thin sample"` + grep guard at commit time for forbidden phrases | ❌ Wave 0 |
| HOMEUI-05 (planner-added per D-06) | Hero card absorbs total monthly + month-over-month delta + previous-month amount | widget + golden | `flutter test ... -p "hero header renders total + trend + prev month"` + golden test | ❌ Wave 0 |
| HOMEUI-06 (planner-added per D-06) | 魂/生存 split bar uses absolute amounts; bar visualizes proportion; no percentage labels | widget + grep guard | `flutter test ... -p "split bar absolute amounts"` + grep guard for "%" near "魂"/"生存" labels | ❌ Wave 0 |
| HOMEUI-07 (planner-added per D-06) | Group mode appends member rows after Best Joy with avatar + name + ¥amount | widget | `flutter test ... -p "group mode renders N member rows"` | ❌ Wave 0 |
| FAMILY-03 | Family card respects group-mode + shadow-book gate (Phase 10 minimum gate per D-08) | widget | Same as HOMEUI-03 | ❌ Wave 0 (covered) |
| (D-09) | Empty states render correctly for: totalExpenses=0; totalSoulTx=0; thin sample (n<5); all-neutral Best Joy | widget + golden | 4 widget tests + 4 goldens covering each empty branch | ❌ Wave 0 |
| (Painter math) | `_HappinessRingsPainter` draws correct sweep angles per Empty/Value | unit (painter math via mock Canvas) | `flutter test test/widget/features/home/presentation/widgets/home_hero_card_rings_painter_test.dart` | ❌ Wave 0 |
| (D-11 tap nav) | Whole card single tap fires `onTap` callback exactly once | widget | `flutter test ... -p "tapping any region of the card fires onTap once"` | ❌ Wave 0 |
| (D-10 tooltip) | Tapping ⓘ icon shows tooltip text; does NOT bubble to card-tap | widget | `flutter test ... -p "info icon tap shows tooltip without firing card onTap"` | ❌ Wave 0 |
| (Theme parity) | Card renders correctly in both light + dark theme | golden | 2 goldens per mode (single-light, single-dark, family-light, family-dark) — 4-6 total | ❌ Wave 0 |
| (i18n parity) | Card renders correctly in ja, zh, en | golden | 3 goldens (single mode, ja+zh+en) — minimum | ❌ Wave 0 |

**Total new test files (Wave 0 gaps):** 2 production test files + ~5-8 goldens.

### Sampling Rate

- **Per task commit:** `flutter test test/widget/features/home/presentation/widgets/home_hero_card_test.dart` + `flutter analyze` (must be 0 issues per CLAUDE.md)
- **Per wave merge:** `flutter test --coverage` (full suite) + `flutter analyze`
- **Phase gate:** `flutter test --coverage` returns ≥70% (project standard) — `home_hero_card.dart` ≥70% per-file before `/gsd-verify-work`. Plus golden tests green; plus grep guards for deleted helpers + forbidden phrases.

### Wave 0 Gaps

- [ ] `test/widget/features/home/presentation/widgets/home_hero_card_test.dart` — covers HOMEUI-01..07 + FAMILY-03 + D-09 empty states + D-11 tap target + D-10 tooltip behavior
- [ ] `test/widget/features/home/presentation/widgets/home_hero_card_rings_painter_test.dart` — painter math unit tests (mock `Canvas` via `mocktail`)
- [ ] `test/golden/home_hero_card_golden_test.dart` — covers 5+ visual states (single-light, family-light, family-dark, thin-sample, all-neutral CTA — minimum)
- [ ] Update `test/widget/features/home/presentation/screens/home_screen_test.dart` — remove finders for deleted widgets, add finder for `HomeHeroCard`
- [ ] Delete `test/widget/features/home/presentation/widgets/month_overview_card_test.dart` (or move relevant assertions into HomeHeroCard test)
- [ ] Delete `test/features/home/presentation/widgets/ledger_comparison_section_test.dart` + `test/features/home/presentation/widgets/soul_fullness_card_test.dart` + their `test/widget/...` mirrors
- [ ] Delete `test/golden/soul_fullness_card_golden_test.dart` + its golden file `test/golden/goldens/soul_fullness_card_ja.png`
- [ ] Add ARB-parity sanity-check (lint runs already; planner verifies no NEW key is missing from any of 3 ARBs at commit time)

**Framework install:** None — `flutter_test` + `mocktail` already in `dev_dependencies`. Verified.

## Security Domain

Per `security_enforcement` (default-enabled when key absent in `.planning/config.json`; absent in this project), include security domain. **Phase 10 is a UI-only refactor — security surface is minimal but the following ASVS categories DO apply.**

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no | Phase 10 doesn't touch auth — biometric lock + key derivation are infrastructure (`lib/infrastructure/security/`), unchanged |
| V3 Session Management | no | No sessions in this scope |
| V4 Access Control | yes | D-08 minimum consent gate is an access-control surface (group-mode + shadow-book existence gates family card visibility). **Standard control:** `isGroupModeProvider` + `shadowBooks.isNotEmpty` checks at the parent screen. Code-comment TODO documents v1.2 expansion. |
| V5 Input Validation | partial | Phase 10 has no user input forms. The only "input" is the ARB tooltip strings — those go through ARB validation (key parity + JSON validity at gen-l10n time). No user-supplied data flows into the painter or ring math. |
| V6 Cryptography | no | No crypto in this scope (CONTEXT.md "Phase 10 → no new schema migrations" + "Existing Code Insights" confirms zero crypto touches) |
| V7 Error Handling | yes | AsyncValue.error states render via existing `_ErrorText` widget; `'$error'` interpolation could leak stack-trace details. **Standard control:** existing pattern at `home_screen.dart:104` is to render `'Error: $message'`. No fix needed unless reviewer flags PII concern. |
| V14 Configuration | no | No build-time configuration changes |

### Known Threat Patterns for Flutter UI Layer

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Information disclosure via error message ("Error: $error" exposes raw exception) | Information Disclosure | Existing `_ErrorText` already does this in `home_screen.dart`; project precedent — Phase 10 follows same. If user-PII leak is a concern, reviewer may request a sanitized fallback. **No change in Phase 10.** |
| Encrypted note display in Best Joy strip (BestJoyMomentRow deliberately omits `note` field per Phase 9 D-08) | Information Disclosure | Phase 9 already mitigated by omitting `note` from the Freezed model — Phase 10 cannot leak it because the field isn't there. **No new control needed.** [VERIFIED: `best_joy_moment_row.dart:9-15` — fields are `transactionId, amount, soulSatisfaction, categoryId, timestamp` ONLY] |
| Member display name leakage in golden tests / screenshots | Information Disclosure | Widget tests use synthetic `ShadowBookInfo` fixtures with mock display names (`memberDisplayName: "Alice"` etc.) — no real data ever in goldens. **Standard control:** test fixtures use `memberDisplayName: 'TestMember1'` and similar synthetic values. |
| Shadow book ID leakage in URL / Navigator route | Information Disclosure | `Navigator.push(... AnalyticsScreen(bookId: bookId))` passes the CURRENT user's bookId, not shadow-book IDs. Member row tap (D-11 bubbles to whole-card tap) does NOT navigate to a shadow book detail in Phase 10. **No leak possible.** |
| Tap-to-navigate creates no-auth deep link | Spoofing | Whole-card tap pushes `AnalyticsScreen(bookId: bookId)` via `MaterialPageRoute` — same in-app navigation pattern used elsewhere. Biometric lock at app-launch is the auth surface, not the route layer. **No new control needed.** |

**Security review checklist for plan-checker / code-reviewer:**

- [ ] No raw exception text rendered without sanitization (existing pattern OK)
- [ ] No member-PII data in goldens (synthetic fixtures only)
- [ ] No new direct DB / repository calls inside widgets (Thin Feature rule)
- [ ] No new IPC / network surfaces introduced (CONTEXT.md guarantee)
- [ ] D-08 minimum gate has a code-comment TODO referencing v1.2 expansion (FAMILY-V2 strict gate)
- [ ] `BestJoyMomentRow` consumed without accessing any non-existent `note` field

## Sources

### Primary (HIGH confidence)

- Context7 `/websites/flutter_dev` — `CustomPainter` signature painter pattern + `shouldRepaint` semantics — fetched 2026-05-02
- Context7 `/websites/api_flutter_dev` — `paintImage`, `paintBorder`, Canvas APIs — fetched 2026-05-02
- Local codebase grep — Phase 9 contracts (`happiness_report.dart`, `family_happiness.dart`, `metric_result.dart`, `best_joy_moment_row.dart`, `shared_joy_insight.dart`) — verified against running `lib/`
- Local codebase grep — `state_happiness.dart`, `state_analytics.dart`, `state_shadow_books.dart`, `state_active_group.dart` — verified provider signatures
- Local codebase grep — `home_screen.dart`, `soul_fullness_card.dart`, `month_overview_card.dart`, `ledger_comparison_section.dart` — verified deletion targets and helpers
- Local codebase grep — `app_text_styles.dart`, `app_colors.dart`, `app_theme_colors.dart` — verified theme tokens
- Local codebase grep — `pubspec.yaml`, `flutter --version` — verified tooling versions
- Project artifacts — `CONTEXT.md`, `UI-SPEC.md`, `DISCUSSION-LOG.md`, `REQUIREMENTS.md`, `ROADMAP.md`, `STATE.md`, `CLAUDE.md`, `.claude/rules/*.md`

### Secondary (MEDIUM confidence)

- Phase 9 `09-CONTEXT.md` decisions D-13 / D-15 / D-17 / D-19 / D-20 — referenced indirectly via CONTEXT.md (not re-fetched)
- ADR-012 / ADR-013 / ADR-014 — referenced via CONTEXT.md citations (not opened in this research session; titles + binding scope confirmed)
- `research/FEATURES.md` lines 47, 79-86, 81-82, 190 — referenced via CONTEXT.md citations

### Tertiary (LOW confidence)

- None. All claims either verified via codebase / Context7 / explicit CONTEXT.md citation.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — every dependency was verified against `pubspec.yaml` + `flutter --version`; zero new packages introduced.
- Architecture: HIGH — pattern Container Widget With Async Provider is precedented in `home_screen.dart`; sealed `MetricResult` matching is documented in Phase 9 model file's docstring; CustomPainter pattern is canonical Flutter (Context7-verified).
- CustomPainter ring sweep semantics: MEDIUM-HIGH — A7 flagged: outer-ring "% toward last month" denominator open question (planner picks fallback strategy).
- Pitfalls: HIGH — every pitfall traces to a CONTEXT.md decision, ADR, CLAUDE.md rule, or codebase-verified anti-pattern resurrected from Phase 9.
- i18n strategy: HIGH — ARB key list cross-checked against UI-SPEC; existing-key reuse verified via grep on `app_ja.arb` (key `homeSoulFullness` confirmed at line 553, `homeHappinessROI` at line 561, `homePreviousMonthAmount` at line 523).
- Provider wiring: HIGH — verified all consumed providers exist (Phase 9 deliverables shipped) + their parameter signatures match what `HomeHeroCard` needs.
- Security: HIGH — surface is intentionally narrow (UI refactor); known threats addressed by Phase 9's contract design (`BestJoyMomentRow` omits `note`).
- Test strategy: HIGH — flutter_test + mocktail in dev_dependencies; existing golden tests demonstrate the pattern; coverage threshold (70%) is project-current.

**Research date:** 2026-05-02
**Valid until:** 2026-06-01 (30 days for stable Flutter ecosystem; if Phase 9 contracts shift before Phase 10 starts, re-validate the consumer signatures).
