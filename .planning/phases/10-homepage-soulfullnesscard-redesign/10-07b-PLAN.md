---
phase: 10-homepage-soulfullnesscard-redesign
plan: 07b
type: execute
wave: 4
depends_on: [07a]
files_modified:
  - lib/features/home/presentation/widgets/home_hero_card.dart
autonomous: true
requirements: [HOMEUI-01, HOMEUI-03, HOMEUI-04, FAMILY-03]
tags: [widget, composition, home-hero-card, best-joy, members]

must_haves:
  truths:
    - "`home_hero_card.dart` from Plan 10-07a is extended in-place — NO new top-level files; NO new constructor parameters"
    - "Region 6 (Best Joy strip) replaces the `_buildBestJoyStripPlaceholder` stub with the 3-level typography composition per D-05 (tag fontSize 9 / BIG fontSize 14 / small fontSize 9 with tabular figures)"
    - "Region 8 (group-mode members section) replaces the `_buildMembersSectionPlaceholder` stub with N member rows when `isGroupMode && shadowBooks.isNotEmpty`; returns `SizedBox.shrink()` otherwise (FAMILY-03 minimum gate)"
    - "Private `_InfoIcon` widget replaces both inline `Icons.info_outline` placeholders from 10-07a — 2 instances total (HOMEUI-04 hard cap unchanged)"
    - "`_InfoIcon` uses `behavior: HitTestBehavior.opaque` to absorb its tap (Pitfall #3 — does not propagate to whole-card GestureDetector)"
    - "`_InfoIcon` opens an explanation dialog via `showDialog<void>` with the appropriate ARB key (`homeJoyIndexTooltip` or `homeJoyPerYenTooltip`)"
    - "Best Joy small line uses inline `TextStyle(fontSize: 9, fontFeatures: [FontFeature.tabularFigures()])` per Pitfall #10 (no use of generic textTheme for ¥ amount or X/10 satisfaction)"
    - "Category resolution via `CategoryLocalizationService.resolveFromId(categoryId, locale)`"
    - "Date formatting via `DateFormatter.formatShortMonthDay(date, locale)` (or inline `DateFormat('M月d日').format(date)` per locale if formatter doesn't exist)"
    - "Empty Best Joy state (when `bestJoy == null`) renders empty-state copy per ARB `homeBestJoyEmptyTagPrimary` + secondary description; never crashes"
    - "Members section uses `AppTextStyles.amountSmall` for per-member ¥ amounts (Pitfall #10)"
    - "All UI strings via `S.of(context).<key>` — no hardcoded ja/zh/en literals; no hardcoded `'JPY'` literal"
    - "`flutter analyze lib/features/home/` reports 0 issues"
    - "File ≤ 450 lines after this plan (10-07a budget 200-280 + 10-07b budget +120-170)"
  artifacts:
    - path: "lib/features/home/presentation/widgets/home_hero_card.dart"
      provides: "HomeHeroCard StatelessWidget — Regions 6 + 8 + private _InfoIcon helper added in-place"
      max_lines: 450
      contains: "class _InfoIcon extends StatelessWidget"
  key_links:
    - from: "lib/features/home/presentation/widgets/home_hero_card.dart"
      to: "lib/application/accounting/category_localization_service.dart"
      via: "CategoryLocalizationService().resolveFromId(...)"
      pattern: "CategoryLocalizationService"
    - from: "lib/features/home/presentation/widgets/home_hero_card.dart"
      to: "lib/infrastructure/i18n/formatters/date_formatter.dart"
      via: "DateFormatter.formatShortMonthDay(...)"
      pattern: "DateFormatter"
---

<objective>
Build the **second half** of `HomeHeroCard` — Region 6 (Best Joy story strip) + Region 8 (group-mode members section) + private `_InfoIcon` widget. This plan extends the file produced by Plan 10-07a in-place; no new files, no new constructor parameters.

This plan is split from the original Plan 10-07 single-task megaplan per the checker's blocker B3 — splitting at the natural divider between "ring section" and "Best Joy strip" gives the executor a checkpoint between structurally-different concerns.

Plan 10-07a left two stubbed builders (`_buildBestJoyStripPlaceholder()` returning `SizedBox.shrink()` and `_buildMembersSectionPlaceholder()` returning `SizedBox.shrink()`) plus two inline `Icons.info_outline` placeholders. This plan replaces all four placeholders with their final implementations.

Output: `home_hero_card.dart` reaches ~350-450 lines, all 8 regions of the D-02 vertical structure rendered, and the private `_InfoIcon` widget owns tap-to-explain dialog behavior.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/phases/10-homepage-soulfullnesscard-redesign/10-CONTEXT.md
@.planning/phases/10-homepage-soulfullnesscard-redesign/10-RESEARCH.md
@.planning/phases/10-homepage-soulfullnesscard-redesign/10-PATTERNS.md
@.planning/phases/10-homepage-soulfullnesscard-redesign/10-UI-SPEC.md
@lib/features/home/presentation/widgets/home_hero_card.dart
@lib/features/home/presentation/widgets/ledger_comparison_section.dart
@lib/features/analytics/domain/models/best_joy_moment_row.dart
@lib/application/accounting/category_localization_service.dart
@lib/infrastructure/i18n/formatters/date_formatter.dart
@lib/core/theme/app_text_styles.dart
@lib/core/theme/app_colors.dart
</context>

<tasks>

<task type="auto" tdd="false">
  <name>Task 7b.1: Implement Region 6 (Best Joy strip), Region 8 (members section), and _InfoIcon helper</name>
  <files>lib/features/home/presentation/widgets/home_hero_card.dart</files>
  <read_first>
    - .planning/phases/10-homepage-soulfullnesscard-redesign/10-CONTEXT.md (D-04 Best Joy story strip, D-05 family-mode rings + members appendix, D-08 minimum-gate)
    - .planning/phases/10-homepage-soulfullnesscard-redesign/10-UI-SPEC.md (Best Joy strip layout, member-row layout, tooltip dialog copy)
    - .planning/phases/10-homepage-soulfullnesscard-redesign/10-PATTERNS.md (lines 60-185 — `_LedgerRow` pattern from ledger_comparison_section.dart for member-row layout; mocktail showDialog patterns)
    - lib/features/home/presentation/widgets/home_hero_card.dart (FULL FILE — current state from Plan 10-07a; locate _buildBestJoyStripPlaceholder, _buildMembersSectionPlaceholder, both inline Icons.info_outline TODO markers)
    - lib/features/home/presentation/widgets/ledger_comparison_section.dart (member-row scaffold pattern: avatar circle + name + flex spacer + ¥amount; ROW heights, padding values, color tokens)
    - lib/features/analytics/domain/models/best_joy_moment_row.dart (exact fields: transactionId / amount / soulSatisfaction / categoryId / timestamp — NO note field per Phase 9 D-08)
    - lib/application/accounting/category_localization_service.dart (signature: resolveFromId(categoryId, locale) returns String)
    - lib/infrastructure/i18n/formatters/date_formatter.dart (verify formatShortMonthDay exists; if not, fall back to inline DateFormat per locale and document it)
    - lib/features/home/presentation/providers/state_shadow_books.dart (lines 13-72 — confirm ShadowBookInfo fields: bookId, displayName, totalAmount; ShadowAggregate fields)
    - lib/core/theme/app_colors.dart (warm-orange `#A86238` token name — likely `AppColors.accentWarm` or similar; if not present, document the exact hex literal in inline TextStyle)
    - lib/core/theme/app_text_styles.dart (confirm bodyLarge/Medium/Small + caption + amountSmall signatures with .copyWith helpers)
    - lib/l10n/app_en.arb (verify keys added by Plan 10-04: homeBestJoyTagSingle/Group, homeBestJoyEmptyTagPrimary, homeBestJoyEmptyDescription, homeMembersSectionTitle, homeMemberAvatarPlaceholder, homeJoyIndexTooltip, homeJoyPerYenTooltip)
  </read_first>
  <action>
Edit `lib/features/home/presentation/widgets/home_hero_card.dart` in-place. The file currently ends at ~200-280 lines with two stubbed builders and two inline `Icons.info_outline` placeholders. This task replaces all four placeholders with their final implementations and adds one new private widget.

**Step 1: Replace `_buildBestJoyStripPlaceholder()` with `_buildBestJoyStrip(context, l10n)`.**

Locate the stub method (it returns `SizedBox.shrink()` and contains the comment `// TODO(plan-10-07b): Best Joy strip`). Rename to `_buildBestJoyStrip` and implement per D-05.

Layout (single Column, 3 stacked Text widgets with explicit fontSize/fontWeight/letterSpacing):

```dart
Widget _buildBestJoyStrip(BuildContext context, S l10n) {
  final bestJoy = this.bestJoy;
  if (bestJoy == null) {
    // Empty state — bestJoy unavailable (e.g., no soul-bucket transactions this month)
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.homeBestJoyEmptyTagPrimary,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              color: Color(0xFFA86238), // warm-orange — see token note
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.homeBestJoyEmptyDescription,
            style: AppTextStyles.bodySmall.copyWith(color: context.wmTextSecondary),
          ),
        ],
      ),
    );
  }

  // Resolve category + date
  final category = CategoryLocalizationService().resolveFromId(bestJoy.categoryId, locale);
  final dateLabel = DateFormatter.formatShortMonthDay(bestJoy.timestamp, locale);
  // (If DateFormatter.formatShortMonthDay does not exist, use inline DateFormat per locale:
  //   ja: DateFormat('M月d日', 'ja').format(...) → "4月15日"
  //   zh: DateFormat('M月d日', 'zh').format(...) → "4月15日"
  //   en: DateFormat('MMM d', 'en').format(...) → "Apr 15"
  // Document the choice with a comment.)

  // Currency-formatted amount
  final amountText = FormatterService().formatCurrency(bestJoy.amount, currencyCode, locale);
  final satisfactionText = '${bestJoy.soulSatisfaction.toStringAsFixed(0)}/10';

  // Tag copy depends on isGroupMode (D-05): "本月最爱" (single) vs "今月の最爱" (group/family)
  final tagText = isGroupMode ? l10n.homeBestJoyTagGroup : l10n.homeBestJoyTagSingle;

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tag (small accent, fontSize 9, fontWeight 600, letterSpacing 1, warm-orange)
        Text(
          tagText,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
            color: Color(0xFFA86238),
          ),
        ),
        const SizedBox(height: 4),
        // BIG: category · date (fontSize 14, fontWeight 700, primary color)
        Text(
          '$category · $dateLabel',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: context.wmTextPrimary,
          ),
        ),
        const SizedBox(height: 2),
        // Small: ¥amount · 满足 X/10 ✨ (fontSize 9, fontWeight 500, warm-orange, tabular figures per Pitfall #10)
        Text(
          '$amountText · ${l10n.homeBestJoySatisfactionLabel(satisfactionText)} ✨',
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w500,
            color: Color(0xFFA86238),
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    ),
  );
}
```

Notes:
- Use `Color(0xFFA86238)` as inline literal IF `AppColors` has no semantic token for it. Document this with a comment `// warm-orange #A86238 — Best Joy accent (see UI-SPEC.md)`.
- The `homeBestJoySatisfactionLabel` ARB key must accept the `X/10` placeholder: `"homeBestJoySatisfactionLabel": "满足 {value}"` (zh) / `"満足 {value}"` (ja) / `"satisfaction {value}"` (en). If Plan 10-04 named this key differently, use that name.
- `bestJoy.amount` is in cents; `FormatterService.formatCurrency` handles cent-to-locale conversion.

**Step 2: Replace `_buildMembersSectionPlaceholder()` with `_buildMembersSection(context, l10n)`.**

Locate the stub method (returns `SizedBox.shrink()` with `// TODO(plan-10-07b): members section`). Rename to `_buildMembersSection` and implement per D-04 + FAMILY-03 minimum gate (group mode + non-empty shadowBooks).

Layout: divider + section title + N member rows.

```dart
Widget _buildMembersSection(BuildContext context, S l10n) {
  // FAMILY-03 minimum gate: group mode + at least one shadow book
  if (!isGroupMode || shadowBooks == null || shadowBooks!.isEmpty) {
    return const SizedBox.shrink();
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Divider(height: 1),
      ),
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          l10n.homeMembersSectionTitle,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: context.wmTextPrimary,
          ),
        ),
      ),
      // Member rows — one per ShadowBookInfo
      ...shadowBooks!.map((member) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              // Avatar circle — placeholder (24×24, neutral background, first character of displayName)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.wmCardBorder,
                ),
                alignment: Alignment.center,
                child: Text(
                  member.displayName.isNotEmpty ? member.displayName[0] : '?',
                  style: AppTextStyles.bodySmall.copyWith(color: context.wmTextSecondary),
                ),
              ),
              const SizedBox(width: 8),
              // Name (flex 1)
              Expanded(
                child: Text(
                  member.displayName,
                  style: AppTextStyles.bodyMedium.copyWith(color: context.wmTextPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Amount — tabular figures per Pitfall #10
              Text(
                FormatterService().formatCurrency(member.totalAmount, currencyCode, locale),
                style: AppTextStyles.amountSmall.copyWith(color: context.wmTextPrimary),
              ),
            ],
          ),
        );
      }),
    ],
  );
}
```

Notes:
- `shadowBooks` is `List<ShadowBookInfo>?` per the constructor (10-07a locked). The `!= null` + `isNotEmpty` check is the gate.
- FAMILY-03 reads as "show only when group mode + opted in". Phase 10's deferred-to-v1.2 contract per D-08 means group mode alone gates the family card; opt-in field landing in v1.2 will tighten the predicate. No code change needed for v1.0 release.
- Use `member.displayName` (NOT `member.name`); verify exact field via the read_first ShadowBookInfo file.
- Use `member.totalAmount` (NOT `member.amount`); verify exact field. Both are in cents.

**Step 3: Replace both inline `Icons.info_outline` placeholders with `_InfoIcon(...)` instances.**

Locate the two inline `Icon(Icons.info_outline, size: 16, color: context.wmTextSecondary)` placeholders from 10-07a (one in ring section title row, one in Joy/¥ legend row, marked with `// TODO(plan-10-07b): promote to _InfoIcon`).

Replace each with:
```dart
_InfoIcon(tooltipKey: _TooltipKey.joyIndex)   // ring section title
_InfoIcon(tooltipKey: _TooltipKey.joyPerYen)  // Joy/¥ legend
```

**Step 4: Add the `_TooltipKey` enum + `_InfoIcon` private widget at the end of the file (after the public class).**

```dart
enum _TooltipKey { joyIndex, joyPerYen }

class _InfoIcon extends StatelessWidget {
  const _InfoIcon({required this.tooltipKey});
  final _TooltipKey tooltipKey;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque, // Pitfall #3 — absorb tap, don't propagate to whole-card onTap
      onTap: () {
        final l10n = S.of(context);
        final body = switch (tooltipKey) {
          _TooltipKey.joyIndex => l10n.homeJoyIndexTooltip,
          _TooltipKey.joyPerYen => l10n.homeJoyPerYenTooltip,
        };
        showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            content: Text(body, style: AppTextStyles.bodyMedium),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.commonClose),
              ),
            ],
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(4), // expand tap target without changing visual size
        child: Icon(
          Icons.info_outline,
          size: 16,
          color: context.wmTextSecondary,
        ),
      ),
    );
  }
}
```

Notes:
- The `GestureDetector` wraps `Icons.info_outline` — Phase 10's master `GestureDetector` is at the root of `build()`; this nested one absorbs the tap via `HitTestBehavior.opaque` per Pitfall #3.
- Use `showDialog<void>` (typed) — DO NOT use untyped `showDialog`.
- The dialog has a single Close button; copy from `l10n.commonClose` (existing key).
- The `_TooltipKey` enum is private (underscore prefix) — kept internal to this file.

**Step 5: Verify and clean up.**

- Confirm exactly 2 `_InfoIcon(...)` instances exist in the file (one in ring section title, one in Joy/¥ legend).
- Confirm exactly 2 `Icons.info_outline` references (only inside `_InfoIcon`).
- Confirm zero `// TODO(plan-10-07b)` comments remain.
- Run `flutter analyze lib/features/home/presentation/widgets/home_hero_card.dart` — must report 0 issues.

**Forbidden:**
- DO NOT add any new constructor parameters to `HomeHeroCard` (signature locked in 10-07a).
- DO NOT add `_buildLedgerRows` / `_computeHappinessROI` / `_computeSatisfaction` helpers — those are deleted in 10-08b.
- DO NOT introduce a `Tooltip` widget (the design choice per RESEARCH §A4 is `showDialog`; Tooltip's hover-only UX is iOS-unfriendly).
- DO NOT add `Icons.info_outline` outside the 2 sanctioned positions; the count is HOMEUI-04's hard cap.
- DO NOT hardcode `'JPY'` literal anywhere in the file (B4 strict guard from 10-07a still applies).
- DO NOT promote `_InfoIcon` or `_TooltipKey` to public — they stay private.
  </action>
  <verify>
    <automated>flutter analyze lib/features/home/presentation/widgets/home_hero_card.dart 2>&1 | grep -q "No issues found"</automated>
  </verify>
  <acceptance_criteria>
    - `grep -c "_InfoIcon(" lib/features/home/presentation/widgets/home_hero_card.dart` returns exactly 2
    - `grep -c "Icons.info_outline" lib/features/home/presentation/widgets/home_hero_card.dart` returns exactly 1 (only inside the `_InfoIcon` build method)
    - Repo-wide ⓘ cap (W6 fix): `grep -rc "Icons.info_outline" lib/features/home/presentation/widgets/home_hero_card*.dart 2>/dev/null | awk -F: '{sum+=$2} END {print sum}'` returns exactly 1
    - `grep -q "class _InfoIcon extends StatelessWidget" lib/features/home/presentation/widgets/home_hero_card.dart` returns exit code 0
    - `grep -q "enum _TooltipKey" lib/features/home/presentation/widgets/home_hero_card.dart` returns exit code 0
    - `grep -q "behavior: HitTestBehavior.opaque" lib/features/home/presentation/widgets/home_hero_card.dart` returns exit code 0 (Pitfall #3)
    - `grep -q "showDialog<void>" lib/features/home/presentation/widgets/home_hero_card.dart` returns exit code 0
    - `grep -q "TODO(plan-10-07b)" lib/features/home/presentation/widgets/home_hero_card.dart` returns exit code 1 (NO matches — all stubs filled)
    - `grep -q "_buildBestJoyStripPlaceholder\|_buildMembersSectionPlaceholder" lib/features/home/presentation/widgets/home_hero_card.dart` returns exit code 1 (NO placeholder method names remain)
    - `grep -q "fontFeatures: \[FontFeature.tabularFigures()\]" lib/features/home/presentation/widgets/home_hero_card.dart` returns exit code 0 (Best Joy small line tabular figures per Pitfall #10)
    - `grep -q "CategoryLocalizationService" lib/features/home/presentation/widgets/home_hero_card.dart` returns exit code 0
    - `grep -c "'JPY'" lib/features/home/presentation/widgets/home_hero_card.dart` returns exactly 0 (Pitfall #9 strict guard from 10-07a unchanged)
    - `grep -E "Joy ROI|happiness share|joy ratio|streak|badge|target|连续|挑战" lib/features/home/presentation/widgets/home_hero_card.dart` returns NO matches (anti-gamification + anti-percentage guards still hold)
    - `wc -l lib/features/home/presentation/widgets/home_hero_card.dart` returns ≤ 450
    - `flutter analyze lib/features/home/presentation/widgets/home_hero_card.dart` reports "No issues found"
    - `flutter analyze lib/features/home/` reports "No issues found" (whole feature compiles)
  </acceptance_criteria>
  <done>
HomeHeroCard fully composed: all 8 D-02 regions rendered; private `_InfoIcon` widget with showDialog<void> tap-to-explain; `_TooltipKey` enum scoped private; FAMILY-03 minimum gate (group + non-empty shadowBooks) enforced for members section; Best Joy strip handles empty state; tabular figures honored on the ¥/satisfaction line; flutter analyze clean; line count ≤ 450; no placeholder methods or TODO markers remain; ready for Plan 10-08a wire-up into home_screen.dart.
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| BestJoyMomentRow → UI | `BestJoyMomentRow` carries `categoryId` + `amount` + `soulSatisfaction` + `timestamp` — explicitly omits `note` per Phase 9 D-08 (no leakage of private memo content) |
| ShadowBookInfo → UI | `ShadowBookInfo.displayName` is opt-in-controlled by Phase 9 family consent; Phase 10 widget consumes the already-gated data |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-10-06 | Information Disclosure | Best Joy strip displays `categoryId` + `amount` | accept | Phase 9 D-08 design contract: `BestJoyMomentRow` includes only fields that are safe to surface (no `note`); widget is a passive consumer |
| T-10-07 | Information Disclosure | Members section displays per-member `displayName` + `totalAmount` | mitigate | Plan 10-07a + 10-07b enforce `isGroupMode && shadowBooks.isNotEmpty` gate; Phase 9 enforces opt-in via consent table; UI is a downstream consumer of already-gated data |
| T-10-08 | Tampering | `_InfoIcon` tap leaks card-tap target | mitigate | `behavior: HitTestBehavior.opaque` on `_InfoIcon`'s GestureDetector absorbs the tap — Pitfall #3 binding |
| T-10-09 | Spoofing | `showDialog<void>` content includes ARB strings | accept | ARB strings are project-controlled; no user-supplied content rendered in tooltips |
</threat_model>

<verification>
- `flutter analyze lib/features/home/presentation/widgets/home_hero_card.dart` returns 0 issues
- `grep -c "_InfoIcon(" lib/features/home/presentation/widgets/home_hero_card.dart` returns exactly 2
- `grep -c "Icons.info_outline" lib/features/home/presentation/widgets/home_hero_card.dart` returns exactly 1 (only inside _InfoIcon)
- `grep -q "TODO(plan-10-07b)" lib/features/home/presentation/widgets/home_hero_card.dart` returns exit code 1 (all stubs filled)
- `grep -c "'JPY'" lib/features/home/presentation/widgets/home_hero_card.dart` returns exactly 0 (B4 strict guard)
- File compiles cleanly under `flutter analyze`
</verification>

<success_criteria>
- All 8 D-02 regions of HomeHeroCard rendered
- Private `_InfoIcon` widget owns tap-to-explain dialog
- `_TooltipKey` enum private and exhaustive
- FAMILY-03 minimum gate (group + non-empty shadowBooks) enforced
- Best Joy strip empty state handled
- HOMEUI-04 ≤2 ⓘ cap honored across both 10-07a + 10-07b plans
- Pure StatelessWidget — no Riverpod refs inside
- All ARB strings consumed via `S.of(context).<key>`; no hardcoded literals
</success_criteria>

<output>
After completion, create `.planning/phases/10-homepage-soulfullnesscard-redesign/10-07b-SUMMARY.md` recording: pre/post line counts (10-07a delivered → 10-07b delivered), the 2 `_InfoIcon` placement positions, the Best Joy strip empty-state handling, and confirmation that the constructor signature was unchanged.
</output>
