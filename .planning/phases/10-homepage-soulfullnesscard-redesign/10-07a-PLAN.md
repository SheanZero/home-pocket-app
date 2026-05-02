---
phase: 10-homepage-soulfullnesscard-redesign
plan: 07a
type: execute
wave: 4
depends_on: [04, 05, 06]
files_modified:
  - lib/features/home/presentation/widgets/home_hero_card.dart
autonomous: true
requirements: [HOMEUI-01, HOMEUI-03, HOMEUI-04]
tags: [widget, composition, home-hero-card, scaffold]

must_haves:
  truths:
    - "`HomeHeroCard` exists at `lib/features/home/presentation/widgets/home_hero_card.dart`"
    - "Pure StatelessWidget — no Riverpod refs inside; constructor accepts resolved Freezed aggregates + currencyCode + locale + isGroupMode + onTap (D-12 + UI-SPEC line 277)"
    - "Renders Regions 1-5 of the D-02 vertical structure: hero header → split bar → divider → ring section (rings + legend) → divider"
    - "Best Joy strip and members section are stub `SizedBox.shrink()` placeholders pending Plan 10-07b"
    - "All ¥ amounts use `AppTextStyles.amountLarge/Medium/Small` (CLAUDE.md Amount Display Style)"
    - "Currency formatted via `FormatterService().formatCurrency(amount, currencyCode, locale)` — no hardcoded `'JPY'` (CLAUDE.md Pitfall #9 — strict guard per B4)"
    - "Sealed `MetricResult<T>` consumed via `switch` pattern matching at every site (no `as Value` casts)"
    - "Single root `GestureDetector(onTap: onTap)` wraps the entire card"
    - "`flutter analyze lib/features/home/` reports 0 issues"
    - "File ≤ 280 lines after this plan (room for Plan 10-07b additions)"
  artifacts:
    - path: "lib/features/home/presentation/widgets/home_hero_card.dart"
      provides: "HomeHeroCard StatelessWidget — Regions 1-5 (hero header through ring section)"
      min_lines: 200
      contains: "class HomeHeroCard extends StatelessWidget"
  key_links:
    - from: "lib/features/home/presentation/widgets/home_hero_card.dart"
      to: "lib/features/home/presentation/widgets/painter/happiness_rings_painter.dart"
      via: "CustomPaint(painter: HappinessRingsPainter(...))"
      pattern: "HappinessRingsPainter"
    - from: "lib/features/home/presentation/widgets/home_hero_card.dart"
      to: "lib/features/analytics/domain/models/metric_result.dart"
      via: "switch pattern matching on MetricResult<T>"
      pattern: "switch.*Empty\\(\\)\\|Value\\("
---

<objective>
Build the **first half** of `HomeHeroCard` — the structural scaffold + Regions 1-5 of the D-02 vertical layout: hero header + 魂/生存 split bar + divider + ring section (rings + legend) + divider. Plan 10-07b builds Region 6 (Best Joy strip), Region 8 (members section), and the private `_InfoIcon` helper.

This plan is split from the original Plan 10-07 single-task megaplan (450-line widget, 9 build methods) per the checker's blocker B3 — single-task plans of this size historically trigger quality regression. Splitting at the natural divider between "ring section" and "Best Joy strip" keeps each plan within ~25-30% context budget.

The widget here is **structurally complete** for Regions 1-5 but stubs Region 6 (Best Joy) and Region 8 (members) as `SizedBox.shrink()` until Plan 10-07b lands. The widget compiles, `flutter analyze` is clean, and the constructor signature is locked (Plan 10-07b adds NO new parameters; it only fills the stubbed regions in-place).

The widget is **pure** — no Riverpod ref watches, no provider reads. All inputs flow through the constructor (Container Widget With Async Provider pattern; UI-SPEC line 277 mandates pure StatelessWidget for testability).

Output: 1 file (~200-280 lines) implementing the master class + Regions 1-5 build methods.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/phases/10-homepage-soulfullnesscard-redesign/10-CONTEXT.md
@.planning/phases/10-homepage-soulfullnesscard-redesign/10-UI-SPEC.md
@.planning/phases/10-homepage-soulfullnesscard-redesign/10-PATTERNS.md
@.planning/phases/10-homepage-soulfullnesscard-redesign/10-RESEARCH.md
@lib/features/home/presentation/widgets/soul_fullness_card.dart
@lib/features/home/presentation/widgets/month_overview_card.dart
@lib/features/home/presentation/widgets/ledger_comparison_section.dart
@lib/features/analytics/domain/models/happiness_report.dart
@lib/features/analytics/domain/models/family_happiness.dart
@lib/features/analytics/domain/models/best_joy_moment_row.dart
@lib/features/analytics/domain/models/metric_result.dart
@lib/features/analytics/domain/models/shared_joy_insight.dart
@lib/features/analytics/domain/models/monthly_report.dart
@lib/features/home/presentation/providers/state_shadow_books.dart
@lib/core/theme/app_colors.dart
@lib/core/theme/app_theme_colors.dart
@lib/core/theme/app_text_styles.dart
@lib/application/i18n/formatter_service.dart
@lib/infrastructure/i18n/formatters/joy_density_formatter.dart
@lib/features/home/presentation/widgets/painter/happiness_rings_painter.dart
</context>

<tasks>

<task type="auto" tdd="false">
  <name>Task 7a.1: Implement HomeHeroCard scaffold + Regions 1-5</name>
  <files>lib/features/home/presentation/widgets/home_hero_card.dart</files>
  <read_first>
    - .planning/phases/10-homepage-soulfullnesscard-redesign/10-CONTEXT.md (D-01 through D-13 — full decisions section)
    - .planning/phases/10-homepage-soulfullnesscard-redesign/10-UI-SPEC.md (read in full — visual contract source of truth)
    - .planning/phases/10-homepage-soulfullnesscard-redesign/10-PATTERNS.md (lines 60-185 — verbatim composition pattern from soul_fullness_card.dart + month_overview_card.dart)
    - lib/features/home/presentation/widgets/soul_fullness_card.dart (full file — outer scaffold pattern, GestureDetector wrap, container decoration)
    - lib/features/home/presentation/widgets/month_overview_card.dart (full file — trend chip arithmetic + pill at lines 36-40, 79-104)
    - lib/features/analytics/domain/models/happiness_report.dart (Freezed model — exact field names: avgSatisfaction / medianSatisfaction / joyPerYen / highlightsCount / topJoy / totalSoulTx)
    - lib/features/analytics/domain/models/family_happiness.dart (Freezed model — exact field names: familyHighlightsSum / sharedJoyInsight / medianSatisfaction)
    - lib/features/analytics/domain/models/metric_result.dart (sealed Empty / Value(data, sampleSize))
    - lib/features/home/presentation/providers/state_shadow_books.dart (lines 13-70 for ShadowBookInfo + ShadowAggregate exact field names)
    - lib/core/theme/app_colors.dart (confirm: soul, survival, accentPrimary, olive, oliveLight, shared)
    - lib/core/theme/app_theme_colors.dart (confirm: wmCard, wmBorderDefault, wmBackgroundDivider, wmTextPrimary, wmTextSecondary, wmTextTertiary, wmBackgroundSubtle)
    - lib/core/theme/app_text_styles.dart (confirm: amountLarge, amountMedium, amountSmall, bodyLarge, bodyMedium, bodySmall, caption — all with .copyWith helpers)
    - lib/application/i18n/formatter_service.dart (confirm: formatCurrency(amount, currencyCode, locale) signature)
    - lib/infrastructure/i18n/formatters/joy_density_formatter.dart (confirm: formatJoyDensity(rawDensity, currencyCode))
  </read_first>
  <action>
Create `lib/features/home/presentation/widgets/home_hero_card.dart`. This plan builds the **scaffold + Regions 1-5**. Regions 6 (Best Joy) and 8 (members) are intentionally stubbed as `SizedBox.shrink()` — Plan 10-07b fills them. The constructor signature is locked here; Plan 10-07b adds no new parameters.

**1. Imports (in order: dart, package, project relative):**

```dart
import 'dart:math' show pi;

import 'package:flutter/material.dart';

import '../../../../application/i18n/formatter_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../infrastructure/i18n/formatters/joy_density_formatter.dart';
import '../../../analytics/domain/models/best_joy_moment_row.dart';
import '../../../analytics/domain/models/family_happiness.dart';
import '../../../analytics/domain/models/happiness_report.dart';
import '../../../analytics/domain/models/metric_result.dart';
import '../../../analytics/domain/models/monthly_report.dart';
import '../providers/state_shadow_books.dart';   // ShadowBookInfo + ShadowAggregate
import 'painter/happiness_rings_painter.dart';
```

(Verify each path against the codebase — adjust if imports differ. CategoryLocalizationService is NOT imported here; Plan 10-07b adds it.)

**2. The master class:**

```dart
/// Integrated hero card on the HomePage replacing MonthOverviewCard + LedgerComparisonSection + SoulFullnessCard (Phase 10).
///
/// **Pure StatelessWidget** — no Riverpod refs inside; parent (`home_screen.dart`)
/// resolves all `AsyncValue.when()` and passes resolved Freezed aggregates.
/// (UI-SPEC line 277; CLAUDE.md Widget Parameter Pattern.)
///
/// Mode discrimination is a top-level branch via `isGroupMode`:
///   - single mode: rings encode [HappinessReport]; family region is `SizedBox.shrink()`
///   - group mode + non-empty `shadowBooks`: rings encode [FamilyHappiness]; member rows render
///   - group mode + empty `shadowBooks`: rings still render group-mode metrics; member section collapses (D-08)
///
/// Hard contracts (CONTEXT.md D-01..D-13, RESEARCH §"Pitfalls"):
///   - All ¥ amounts use `AppTextStyles.amount*` (tabular figures); never hardcode `'JPY'`.
///   - Sealed `MetricResult<T>` consumed via `switch` only — never `as Value` casts.
///   - Exactly 2 `Icons.info_outline` instances total (HOMEUI-04).
///   - Whole-card single `onTap`; sub-widget taps bubble up; ⓘ icons absorb taps (Pitfall #3).
///   - 魂/生存 split bar shows ABSOLUTE amounts; never frame as joy ROI / share / ratio (D-02).
///   - No streak / badge / target / cross-period happiness chips (ADR-012 binding).
class HomeHeroCard extends StatelessWidget {
  const HomeHeroCard({
    required this.report,
    required this.happiness,
    required this.bestJoy,
    required this.family,
    required this.shadowBooks,
    required this.shadowAggregate,
    required this.currencyCode,
    required this.locale,
    required this.isGroupMode,
    required this.onTap,
    super.key,
  });

  final MonthlyReport report;
  final HappinessReport happiness;
  final MetricResult<BestJoyMomentRow> bestJoy;
  final FamilyHappiness? family;          // null in single mode
  final List<ShadowBookInfo>? shadowBooks; // null in single mode
  final ShadowAggregate? shadowAggregate;  // null in single mode
  final String currencyCode;               // from Book.currency via bookByIdProvider; never literal 'JPY' here
  final Locale locale;
  final bool isGroupMode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(18),    // UI-SPEC OQ #1 — 18 picked for hero weight
        decoration: BoxDecoration(
          color: context.wmCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.wmBorderDefault),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroHeader(context, l10n),
            const SizedBox(height: 16),
            _buildSplitBar(context, l10n),
            const SizedBox(height: 12),
            _buildDivider(context),
            const SizedBox(height: 12),
            _buildRingSection(context, l10n),
            const SizedBox(height: 12),
            _buildDivider(context),
            const SizedBox(height: 12),
            // Region 6: Best Joy strip — Plan 10-07b fills this
            _buildBestJoyStripPlaceholder(context, l10n),
            // Region 7+8: Members section — Plan 10-07b fills this
            if (isGroupMode && (shadowBooks?.isNotEmpty ?? false)) ...[
              const SizedBox(height: 12),
              _buildDivider(context),
              const SizedBox(height: 12),
              _buildMembersSectionPlaceholder(context, l10n),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Region 1: Hero header ─────────────────────────────────────────────────
  // (Implementation: copy verbatim from original Plan 10-07 Task 7.1 _buildHeroHeader.)
  // Computes totalForDisplay (group adds shadowAggregate.totalExpenses).
  // Computes prevForDisplay similarly.
  // Renders label + total + sub-line + trend chip (hidden when total + prev both 0).

  // ─── Region 2: 魂/生存 split bar ────────────────────────────────────────────
  // (Implementation: copy verbatim from original Plan 10-07 Task 7.1 _buildSplitBar.)
  // ABSOLUTE amounts in labels; no % glyph; gradient soul-portion + neutral-gray track.

  // ─── Region 3+5+7: Divider ────────────────────────────────────────────────
  // _buildDivider returns Container(height: 1, color: context.wmBackgroundDivider).

  // ─── Region 4: Ring section ───────────────────────────────────────────────
  // (Implementation: copy verbatim from original Plan 10-07 Task 7.1 _buildRingSection.)
  // Title row (icon + text + tooltip ⓘ) + rings (CustomPaint + RepaintBoundary + center text)
  // + legend (3 rows + coverage caption when totalSoulTx > 0).

  // ─── Region 6: Best Joy strip — STUB (Plan 10-07b owns this) ──────────────
  Widget _buildBestJoyStripPlaceholder(BuildContext context, S l10n) {
    // TODO(plan-10-07b): replace with full Best Joy strip including Empty / Value / all-neutral CTAs
    return const SizedBox.shrink();
  }

  // ─── Region 8: Members section — STUB (Plan 10-07b owns this) ─────────────
  Widget _buildMembersSectionPlaceholder(BuildContext context, S l10n) {
    // TODO(plan-10-07b): replace with full members list rendering ShadowBookInfo rows
    return const SizedBox.shrink();
  }
}
```

**3. Region 1 (Hero header) — copy verbatim from original 10-07 Task 7.1:**

`_buildHeroHeader(context, l10n)` — computes totalForDisplay, prevForDisplay, trend chip visibility (hidden when both 0). Uses `AppTextStyles.amountLarge` for the total. Trend chip uses `Icons.trending_up`/`down`, `AppColors.olive`/`oliveLight`. Renders `homeHeroCardLabelSingle` or `homeHeroCardLabelGroup` per `isGroupMode`. Renders `l10n.homeHeroPreviousMonthSubline(prevText)` for the sub-line.

`_buildTrendChip(context, trendPercent)` — pill container with trending icon + percentage label.

**4. Region 2 (Split bar) — copy verbatim from original 10-07 Task 7.1:**

`_buildSplitBar(context, l10n)` — Row with: 魂帳 dot + label + amount on left, 生存帳 amount + label + dot on right. Below: ClipRRect + Container with horizontal gradient bar. Uses `AppColors.soul.withValues(alpha: 0.6)` to `AppColors.soul` for soul portion gradient; track is `context.wmBackgroundDivider`. soulRatio computed as soulTotal/(soulTotal+survivalTotal); 0.0 when total is 0.

**5. Region 3+5: Divider** — `_buildDivider(context)` returns 1-pixel Container with `context.wmBackgroundDivider`.

**6. Region 4 (Ring section) — copy verbatim from original 10-07 Task 7.1:**

`_buildRingSection(context, l10n)` — Column with title row (Icon + Text + `Icons.info_outline` placeholder — see note below) + Row with [SizedBox 120×120 containing RepaintBoundary + CustomPaint + center text Stack] + [Expanded legend column].

`_buildRingsPainter(context)` — branches on isGroupMode. Single mode: outer = soul gradient, middle = olive, inner = accentPrimary. Group mode: outer = shared, middle = accentPrimary, inner = olive. Track = `context.wmBackgroundDivider`. Sweep ratios computed by helper functions:

`_outerSweepRatioSingle(joyPerYen)` — switch over MetricResult, Empty → null, Value → (data/2.0).clamp(0,1).
`_middleSweepRatioSingle(avgSat)` — Empty → null, Value → (data/10.0).clamp(0,1).
`_innerSweepRatioSingle(highlights, totalSoulTx)` — Empty → null, Value → totalSoulTx > 0 ? (data/totalSoulTx).clamp(0,1) : null.
`_outerSweepRatioGroup(familyHighlightsSum)` — Empty → null, Value → (data/30.0).clamp(0,1).
`_middleSweepRatioGroup(sharedJoyInsight)` — Empty → null, Value → 1.0 (binary).
`_innerSweepRatioGroup(medianSat)` — Empty → null, Value → (data/10.0).clamp(0,1).

`_buildCenterText()` — single: avgSatisfaction Value(data) → data.toStringAsFixed(1), Empty → '—'. Group: familyHighlightsSum Value → '$data', Empty → '—'.

`_buildRingLegend(context, l10n)` — branches on isGroupMode. Single: 3 legend rows for Joy/¥, AvgSatisfaction, HighlightsCount + coverage caption when totalSoulTx > 0. Group: 3 legend rows for FamilyHighlights, SharedJoy (binary ✓), MedianSatisfaction.

`_ratedCount(HappinessReport h)` — switch over avgSatisfaction; Value → sampleSize, Empty → 0.

`_buildLegendRow({context, dotColor, label, value, trailingInfoIcon})` — Row with dot + Expanded label + value + optional trailing widget.

**7. Tooltip ⓘ icon — INLINE STUB ONLY:**

Plan 10-07b will implement the private `_InfoIcon` widget. For Plan 10-07a, **inline the icon directly** as a placeholder — `Icon(Icons.info_outline, size: 16, color: context.wmTextSecondary)` without GestureDetector wrapping. This is intentional: Plan 10-07a establishes the structural skeleton + visual placement; Plan 10-07b promotes both icons to full `_InfoIcon` widgets with tap-to-show-dialog behavior + `behavior: HitTestBehavior.opaque` (Pitfall #3).

There MUST be exactly 2 `Icons.info_outline` instances in this plan (one in ring section title, one in Joy/¥ legend row). Plan 10-07b promotes them to `_InfoIcon` private widgets without changing the count.

**8. CategoryLocalizationService import:** OMIT for Plan 10-07a — only the Best Joy strip uses it. Plan 10-07b adds the import.

**9. JoyDensityFormatter:** Used in single-mode Joy/¥ legend value rendering. Import included. `formatJoyDensity(data, currencyCode)`.

**Forbidden:**
- DO NOT import `package:flutter_riverpod/...` — this is a pure StatelessWidget.
- DO NOT add `Icons.info_outline` outside the 2 sanctioned positions (ring section title, Joy/¥ legend).
- DO NOT write a percentage label ("21%", "Joy %", "share") on the split bar.
- DO NOT write any cross-period happiness chip ("vs 4月", "比上月").
- DO NOT use raw `'JPY'` literals in this file (the constructor's `currencyCode` is the only currency source). Strict guard per B4.
- DO NOT cast `MetricResult` via `as Value` — use `switch` exhaustively.
- DO NOT add `_computeHappinessROI` / `_computeSatisfaction` / `_buildLedgerRows` helpers — those are deleted in Plan 10-08b.
- DO NOT implement `_InfoIcon` private widget here (Plan 10-07b owns it).
- DO NOT implement Best Joy strip or member rows here (Plan 10-07b owns them).

**File budget for this plan:** target 200-280 lines. Plan 10-07b will add another 100-150 lines (Best Joy + members + _InfoIcon).
  </action>
  <verify>
    <automated>flutter analyze lib/features/home/presentation/widgets/home_hero_card.dart 2>&1 | grep -q "No issues found"</automated>
  </verify>
  <acceptance_criteria>
    - File `lib/features/home/presentation/widgets/home_hero_card.dart` exists
    - `grep -q "class HomeHeroCard extends StatelessWidget" lib/features/home/presentation/widgets/home_hero_card.dart` returns exit code 0
    - `grep -c "Icons.info_outline" lib/features/home/presentation/widgets/home_hero_card.dart` returns exactly 2 (one in ring section title, one in Joy/¥ legend)
    - `grep -c "'JPY'" lib/features/home/presentation/widgets/home_hero_card.dart` returns exactly 0 (NO hardcoded JPY literal anywhere — strict guard per B4 + D-12; Pitfall #9). Repo-wide cap also applies if planner splits widget into companion files: `grep -rc "'JPY'" lib/features/home/presentation/widgets/home_hero_card*.dart | awk -F: '{sum+=$2} END {print sum}'` returns 0.
    - `grep -q "AppTextStyles.amountLarge" lib/features/home/presentation/widgets/home_hero_card.dart` returns exit code 0
    - `grep -q "AppTextStyles.amountMedium" lib/features/home/presentation/widgets/home_hero_card.dart` returns exit code 0
    - `grep -q "switch (.*MetricResult\|case Empty\|case Value\|Empty()\|Value(" lib/features/home/presentation/widgets/home_hero_card.dart` returns exit code 0 (sealed pattern matching)
    - `grep -E "Joy ROI|happiness share|joy ratio|soul %|魂 [0-9]+%|生存 [0-9]+%" lib/features/home/presentation/widgets/home_hero_card.dart` returns NO matches (split-bar anti-pattern guard, Pitfall #2)
    - `grep -E "streak|badge|target|连续|挑战" lib/features/home/presentation/widgets/home_hero_card.dart` returns NO matches (ADR-012 binding)
    - `grep -q "S.of(context)" lib/features/home/presentation/widgets/home_hero_card.dart` returns exit code 0 (no hardcoded UI strings)
    - `grep -q "HappinessRingsPainter" lib/features/home/presentation/widgets/home_hero_card.dart` returns exit code 0 (uses the painter)
    - `grep -q "SizedBox.shrink" lib/features/home/presentation/widgets/home_hero_card.dart` returns exit code 0 (Best Joy + members stubs)
    - `grep -q "_buildBestJoyStripPlaceholder\|TODO(plan-10-07b)" lib/features/home/presentation/widgets/home_hero_card.dart` returns exit code 0 (stub markers visible)
    - `flutter analyze lib/features/home/presentation/widgets/home_hero_card.dart` reports "No issues found"
    - File line count between 200 and 280: `wc -l lib/features/home/presentation/widgets/home_hero_card.dart` returns 200-280
  </acceptance_criteria>
  <done>
HomeHeroCard scaffold + Regions 1-5 implemented; Regions 6 + 8 are SizedBox.shrink stubs with TODO(plan-10-07b) markers; constructor signature locked (no parameters added in 10-07b); `flutter analyze` clean; 2 Icons.info_outline placeholders in correct positions; zero hardcoded 'JPY' literals; ready for Plan 10-07b to fill stubs.
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Phase 9 contracts → HomeHeroCard | Sealed `MetricResult<T>` flows from use cases into widget; widget must consume safely without exposing raw values |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-10-03 | Information Disclosure | Pattern-match exhaustiveness | mitigate | Sealed `MetricResult<T>` with Dart-3 exhaustive switch — UI cannot accidentally read `data` from `Empty<T>` (compile-time enforced); zero NaN/infinity risk |
| T-10-05 | Tampering | hardcoded `'JPY'` resurfacing | mitigate | Acceptance criterion: `grep -c "'JPY'" lib/features/home/presentation/widgets/home_hero_card.dart` returns exactly 0 (no match); CLAUDE.md Pitfall #9 enforced via plan check (B4) |
| T-10-04 | Spoofing | onTap callback navigation | accept | `onTap` is invoked locally; no URL/intent/external handler; navigation is in-app only — biometric lock at app launch is the auth surface |
</threat_model>

<verification>
- `flutter analyze lib/features/home/presentation/widgets/home_hero_card.dart` returns 0 issues
- `grep -c "Icons.info_outline" lib/features/home/presentation/widgets/home_hero_card.dart` returns exactly 2
- `grep -c "'JPY'" lib/features/home/presentation/widgets/home_hero_card.dart` returns exactly 0 (hard guard per B4)
- File compiles with all imports resolving
- `grep -q "_buildBestJoyStripPlaceholder" lib/features/home/presentation/widgets/home_hero_card.dart` succeeds (stub present)
</verification>

<success_criteria>
- HomeHeroCard scaffold + Regions 1-5 ready for Plan 10-07b to extend
- Constructor signature locked
- All critical pitfalls (Pitfall #1 hardcoded JPY, #2 split-bar anti-pattern, #4 ⓘ count, #6 sealed match, #7 "0.0", #10 tabular figures) avoided
- Pure StatelessWidget — no Riverpod refs inside
</success_criteria>

<output>
After completion, create `.planning/phases/10-homepage-soulfullnesscard-redesign/10-07a-SUMMARY.md` recording: file line count, the 5 region build methods + their line ranges, the 2 `Icons.info_outline` placement positions, the painter call site, and the 2 stub method names (Plan 10-07b targets).
</output>
