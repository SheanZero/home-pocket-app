---
phase: 33-color-token-system-consolidation
plan: "05b"
type: execute
wave: 2
depends_on:
  - "33-02"
files_modified:
  - lib/features/settings/presentation/screens/settings_screen.dart
  - lib/features/list/presentation/screens/list_screen.dart
  - lib/features/list/presentation/widgets/list_transaction_tile.dart
  - lib/features/list/presentation/widgets/list_empty_state.dart
  - lib/features/list/presentation/widgets/list_calendar_header.dart
  - lib/features/list/presentation/widgets/list_sort_filter_bar.dart
  - lib/features/list/presentation/widgets/list_day_group_header.dart
  - lib/features/list/presentation/widgets/list_category_filter_sheet.dart
autonomous: true
requirements:
  - COLOR-01
  - COLOR-02
  - COLOR-03

must_haves:
    truths:
      - "D-02/D-07: All AppColors.* and context.wm* references in lib/features/settings/ and lib/features/list/ are replaced by context.palette.* (per D-02)"
      - "D-07: list_calendar_header.dart Bucket F literals replaced: _weekendColor → palette.info (#2A8FB8), _todayColor → palette.error (#E5484D) per ADR-018 (per D-07)"
      - "D-07: settings_screen.dart and all 6 list/ widgets/screen respond to dark mode via context.palette (previously no dark adaptation, per D-07)"
      - "COLOR-02: The transaction list renders 日常 entries with palette.daily teal-navy (#1C7A86) and 悦己 entries with palette.joy gold (#F0A81E) per ADR-018; amount text uses palette.dailyText/joyText for WCAG compliance"
      - "grep -rn 'Color(0x' lib/features/settings/ lib/features/list/ returns 0 after this plan"
      - "grep -rn 'AppColors\\.' lib/features/settings/ lib/features/list/ returns 0 after this plan"
  artifacts:
    - path: lib/features/list/presentation/widgets/list_calendar_header.dart
      provides: Calendar header with palette.info weekend + palette.error today tokens
    - path: lib/features/list/presentation/widgets/list_transaction_tile.dart
      provides: Transaction tile using palette.dailyText/joyText/sharedText for amounts (WCAG)
  key_links:
    - from: lib/features/list/presentation/widgets/list_transaction_tile.dart
      to: lib/core/theme/app_palette.dart
      via: context.palette
      pattern: "palette\\.dailyText"
---

<objective>
Migrate all color references in lib/features/settings/ (1 file) and lib/features/list/ (6 widgets + 1 screen = 7 files) to context.palette.*. Key targets: replace Bucket F calendar header literals with palette.info/error tokens, enforce WCAG-compliant *Text color variants for amount text in list_transaction_tile.dart, and bring settings and list screens into full dark-mode support.

This plan runs in parallel with Plans 33-03, 33-04, 33-05a, and 33-06 (Wave 2). No file overlap with any of those plans.

Purpose: settings/ and list/ are user-facing daily-use surfaces — migrating them delivers the visible Teal Clarity palette to the two most-used screens outside of home.

Output: 8 modified files. grep gates for settings/ and list/ return 0.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/phases/33-color-token-system-consolidation/33-CONTEXT.md
@.planning/phases/33-color-token-system-consolidation/33-PATTERNS.md
@docs/arch/03-adr/ADR-018_Palette_Selection_v1_5.md
@lib/core/theme/app_palette.dart
@lib/core/theme/app_colors.dart
@lib/features/list/presentation/widgets/list_transaction_tile.dart
@lib/features/list/presentation/widgets/list_calendar_header.dart
</context>

<tasks>

<task type="auto">
  <name>Task 1: Migrate list_transaction_tile.dart + list_calendar_header.dart (Bucket F + WCAG amounts)</name>
  <files>
    lib/features/list/presentation/widgets/list_transaction_tile.dart,
    lib/features/list/presentation/widgets/list_calendar_header.dart
  </files>
  <read_first>
    lib/features/list/presentation/widgets/list_transaction_tile.dart — full file; canonical mixed wm*/AppColors.* pattern per 33-PATTERNS.md §"list_transaction_tile.dart". lib/features/list/presentation/widgets/list_calendar_header.dart — full file; Bucket F literals _weekendColor and _todayColor per 33-PATTERNS.md §"list_calendar_header.dart". 33-PATTERNS.md §"Shared Patterns" — context.wm* → context.palette.* rename table. 33-PATTERNS.md §"Pattern: Amount text with *Text color" — WCAG constraint. lib/core/theme/app_palette.dart — info and error token names; dailyText/joyText/sharedText fields.
  </read_first>
  <action>
    For list_transaction_tile.dart:

    Step 1 — Import swap: Remove app_colors.dart / app_theme_colors.dart imports; add app_palette.dart.

    Step 2 — In build() method, add final palette = context.palette.

    Step 3 — Replace context.wm* getters using the rename table from 33-PATTERNS.md §"Shared Patterns": wmCard → palette.card, wmTextPrimary → palette.textPrimary, wmTextSecondary → palette.textSecondary, wmBorderDefault → palette.borderDefault, wmBorderDivider → palette.borderDivider, wmBackgroundDivider → palette.backgroundDivider, wmSurvivalTagBg → palette.dailyLight, wmSoulTagBg → palette.joyLight, wmSharedTagBg → palette.sharedLight, etc.

    Step 4 — Replace AppColors.* static refs: AppColors.daily → palette.daily, AppColors.joy → palette.joy, AppColors.shared → palette.shared, AppColors.sharedLight → palette.sharedLight, AppColors.olive → palette.success (D-06), AppColors.oliveLight → palette.successLight, etc.

    Step 5 — CRITICAL: Amount text WCAG enforcement. If AppColors.daily or palette.daily is applied to an AppTextStyles.amount* style, change to palette.dailyText. Same for joy → palette.joyText, shared → palette.sharedText. This enforces CLAUDE.md Amount Display Style + ADR-018 WCAG constraint (joy #F0A81E fails 4.5:1 on white; dailyText #145E68 passes).

    For list_calendar_header.dart:

    Step 6 — Import swap: Remove app_colors.dart; add app_palette.dart.

    Step 7 — Bucket F replacement: Remove static const _weekendColor and _todayColor declarations. Replace their usages in build() with palette.info and palette.error directly. (Static const cannot reference palette; use the palette field directly in the build method body where context is available.)

    Step 8 — Replace any remaining AppColors.* refs with context.palette.* equivalents.
  </action>
  <verify>
    <automated>cd /Users/xinz/Development/home-pocket-app && grep -n 'AppColors\.\|AppColorsDark\.\|context\.wm\|Color(0x\|_weekendColor\|_todayColor' lib/features/list/presentation/widgets/list_transaction_tile.dart lib/features/list/presentation/widgets/list_calendar_header.dart && flutter analyze lib/features/list/presentation/widgets/ 2>&1 | grep -E '(error|warning|hint|issues)' | head -20</automated>
  </verify>
  <done>grep returns 0 hits across both files. flutter analyze returns 0 issues for list/presentation/widgets/.</done>
</task>

<task type="auto">
  <name>Task 2: Migrate settings_screen.dart + remaining 5 list/ widgets and list_screen.dart</name>
  <files>
    lib/features/settings/presentation/screens/settings_screen.dart,
    lib/features/list/presentation/screens/list_screen.dart,
    lib/features/list/presentation/widgets/list_empty_state.dart,
    lib/features/list/presentation/widgets/list_sort_filter_bar.dart,
    lib/features/list/presentation/widgets/list_day_group_header.dart,
    lib/features/list/presentation/widgets/list_category_filter_sheet.dart
  </files>
  <read_first>
    33-RESEARCH.md §"Screens with NO dark adaptation" — list_screen.dart and settings_screen.dart are both on the no-dark list; action: replace AppColors.* with context.palette.*. 33-RESEARCH.md §"Widgets with AppColors but NO dark adaptation" — list_empty_state, list_sort_filter_bar, list_day_group_header, list_category_filter_sheet. 33-PATTERNS.md §"Shared Patterns" — context.wm* → context.palette.* rename table and AppColors.* replacement mapping. lib/core/theme/app_palette.dart — available token names.
  </read_first>
  <action>
    For ALL 6 files (settings_screen.dart, list_screen.dart, and 4 list widgets):

    Step 1 — Import swap: Remove app_colors.dart / app_theme_colors.dart imports; add app_palette.dart.

    Step 2 — In each build() method, add final palette = context.palette.

    Step 3 — Replace context.wm* getters with context.palette.* using the rename table from 33-PATTERNS.md §"Shared Patterns".

    Step 4 — Replace AppColors.* static refs: AppColors.background → palette.background, AppColors.textPrimary → palette.textPrimary, AppColors.textSecondary → palette.textSecondary, AppColors.accentPrimary → palette.accentPrimary, AppColors.borderDefault → palette.borderDefault, AppColors.daily → palette.daily, AppColors.joy → palette.joy, AppColors.shared → palette.shared, AppColors.olive → palette.success (D-06), etc.

    Step 5 — Do NOT use isDark ternary anywhere. context.palette resolves both modes automatically. All 6 files are on the "no dark adaptation" list — after migration they get full dark support for free.
  </action>
  <verify>
    <automated>cd /Users/xinz/Development/home-pocket-app && grep -rn 'AppColors\.\|AppColorsDark\.\|context\.wm\|Color(0x' lib/features/settings/ lib/features/list/ && flutter analyze lib/features/settings/ lib/features/list/ 2>&1 | grep -E '(error|warning|hint|issues)' | head -20</automated>
  </verify>
  <done>grep returns 0 hits for AppColors., AppColorsDark., context.wm, Color(0x across lib/features/settings/ and lib/features/list/. flutter analyze returns 0 issues for both directories.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| (none new) | Presentation layer color-constant substitution only |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-33-SC | Tampering | No package installs | accept | No new dependencies |

Pure cosmetic migration. No new input handling, network, storage, or auth. No high or medium threats.
</threat_model>

<verification>
```bash
cd /Users/xinz/Development/home-pocket-app
grep -rn 'AppColors\.\|AppColorsDark\.\|context\.wm\|Color(0x' lib/features/settings/ lib/features/list/
flutter analyze lib/features/settings/ lib/features/list/
flutter test --exclude-tags golden test/widget/features/list/ 2>&1 | tail -10
```

Expected: all grep commands return 0 hits; analyze 0 issues; list widget tests pass.
</verification>

<success_criteria>
- grep -rn 'Color(0x' lib/features/settings/ lib/features/list/ returns 0 hits
- grep -rn 'AppColors\.\|AppColorsDark\.' lib/features/settings/ lib/features/list/ returns 0 hits
- grep -rn 'context\.wm' lib/features/settings/ lib/features/list/ returns 0 hits
- flutter analyze lib/features/settings/ lib/features/list/ returns 0 issues
</success_criteria>

<output>
Create `.planning/phases/33-color-token-system-consolidation/33-05b-SUMMARY.md` when done.
</output>
