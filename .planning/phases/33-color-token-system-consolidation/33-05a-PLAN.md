---
phase: 33-color-token-system-consolidation
plan: "05a"
type: execute
wave: 2
depends_on:
  - "33-02"
files_modified:
  - lib/features/family_sync/presentation/screens/create_group_screen.dart
  - lib/features/family_sync/presentation/screens/member_approval_screen.dart
  - lib/features/family_sync/presentation/screens/join_group_screen.dart
  - lib/features/family_sync/presentation/screens/confirm_join_screen.dart
  - lib/features/family_sync/presentation/screens/group_choice_screen.dart
  - lib/features/family_sync/presentation/screens/group_management_screen.dart
  - lib/features/family_sync/presentation/screens/waiting_approval_screen.dart
  - lib/features/family_sync/presentation/widgets/member_list_tile.dart
autonomous: true
requirements:
  - COLOR-01
  - COLOR-02
  - COLOR-03

must_haves:
    truths:
      - "D-02/D-07: All AppColors.* and context.wm* references in lib/features/family_sync/ are replaced by context.palette.* (per D-02)"
      - "D-03/D-04: Bucket B coral gradient literals (Color(0xFFE85A4F), Color(0xFFF08070), Color(0x28E85A4F)) in 4 family_sync screens replaced by palette.fabGradientEnd/fabGradientStart/actionShadow (per D-03)"
      - "D-04: Bucket C member gradient purple literals (Color(0xFFE8D5F5), Color(0xFFF3EAF9), Color(0xFFFAF5FD)) replaced by palette.memberGradientA/B/C (teal-family, per D-04)"
      - "D-07: All 7 family_sync screens and member_list_tile.dart respond to dark mode via context.palette — previously had no dark adaptation (per D-07)"
      - "COLOR-02: The family sync FAB/action buttons render teal gradient (#2BB6C2 → #0E9AA7 light / #4FCDD9 → #3FC2CE dark) instead of the old coral gradient per ADR-018"
      - "grep -rn 'Color(0x' lib/features/family_sync/ returns 0 after this plan (except pure-alpha Color(0x0A000000) which is palette.surfaceScrimMedium)"
      - "grep -rn 'AppColors\\.' lib/features/family_sync/ returns 0 after this plan"
  artifacts:
    - path: lib/features/family_sync/presentation/screens/create_group_screen.dart
      provides: Family sync screens using palette teal gradient (not coral)
    - path: lib/features/family_sync/presentation/widgets/member_list_tile.dart
      provides: Member tile with palette.memberGradient* teal-family tokens
  key_links:
    - from: lib/features/family_sync/presentation/screens/create_group_screen.dart
      to: lib/core/theme/app_palette.dart
      via: context.palette
      pattern: "palette\\.fabGradient"
---

<objective>
Migrate all color references in lib/features/family_sync/ (7 screens + 1 widget) to context.palette.*. Key targets: replace the 4-screen coral gradient copy-paste (Bucket B) with teal palette tokens, re-hue the purple member gradient presets (Bucket C) to teal-family memberGradient* tokens (D-04).

This plan runs in parallel with Plans 33-03, 33-04, 33-05b, and 33-06 (Wave 2). No file overlap with any of those plans.

Purpose: family_sync is the largest single bucket migration (Bucket B: 12 coral literals across 4 screens). Isolating it to its own plan ensures the context budget stays within ~50% while giving the executor the full file set and all cross-screen patterns at once.

Output: 8 modified files. grep gates for lib/features/family_sync/ return 0.
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
@lib/features/family_sync/presentation/screens/create_group_screen.dart
</context>

<tasks>

<task type="auto">
  <name>Task 1: Migrate 4 Bucket B screens (coral gradient replacement)</name>
  <files>
    lib/features/family_sync/presentation/screens/create_group_screen.dart,
    lib/features/family_sync/presentation/screens/member_approval_screen.dart,
    lib/features/family_sync/presentation/screens/join_group_screen.dart,
    lib/features/family_sync/presentation/screens/confirm_join_screen.dart
  </files>
  <read_first>
    lib/features/family_sync/presentation/screens/create_group_screen.dart — full file; canonical Bucket B pattern (coral gradient literals). 33-PATTERNS.md §"Family Sync Screens — Bucket B/C Pattern" — exact before/after for all 4 Bucket B screens including the EXCEPTION for pure-alpha Color(0x0A000000) which becomes palette.surfaceScrimMedium (named token). 33-RESEARCH.md §"Bucket B" — lists the 12 literals across 4 screens. 33-RESEARCH.md §"Bucket C" — purple gradient presets in member_approval_screen. lib/core/theme/app_palette.dart — fabGradientEnd/Start, actionShadow, surfaceScrimMedium token names.
  </read_first>
  <action>
    For ALL 4 Bucket B screens (create_group, member_approval, join_group, confirm_join):

    Step 1 — Import swap: Remove import of app_colors.dart (and app_theme_colors.dart if present); add import of app_palette.dart.

    Step 2 — In each build() method, add final palette = context.palette.

    Step 3 — Replace AppColors.* static refs using the mapping from 33-PATTERNS.md §"Shared Patterns": AppColors.background → palette.background, AppColors.accentPrimary → palette.accentPrimary, AppColors.textPrimary → palette.textPrimary, AppColors.borderDefault → palette.borderDefault, etc.

    Step 4 — Replace context.wm* getters with context.palette.* equivalents.

    Step 5 — Bucket B literal replacement (all 4 screens): Color(0xFFE85A4F) → palette.fabGradientEnd; Color(0xFFF08070) → palette.fabGradientStart; Color(0x28E85A4F) → palette.actionShadow; Color(0x0A000000) → palette.surfaceScrimMedium.

    Step 6 — member_approval_screen.dart Bucket C: Color(0xFFE8D5F5) → palette.memberGradientA; Color(0xFFF3EAF9) → palette.memberGradientB; Color(0xFFFAF5FD) → palette.memberGradientC.

    CRITICAL: Do NOT use isDark ternary anywhere. context.palette resolves both modes automatically. All 4 screens are on the "no dark adaptation" list — after migration they get full dark support for free via ThemeExtension.
  </action>
  <verify>
    <automated>cd /Users/xinz/Development/home-pocket-app && grep -rn 'AppColors\.\|AppColorsDark\.\|context\.wm\|Color(0x' lib/features/family_sync/presentation/screens/create_group_screen.dart lib/features/family_sync/presentation/screens/member_approval_screen.dart lib/features/family_sync/presentation/screens/join_group_screen.dart lib/features/family_sync/presentation/screens/confirm_join_screen.dart && flutter analyze lib/features/family_sync/ 2>&1 | grep -E '(error|warning|hint|issues)' | head -20</automated>
  </verify>
  <done>grep returns 0 hits for AppColors., AppColorsDark., context.wm, Color(0x across the 4 Bucket B screens. flutter analyze returns 0 issues for family_sync/.</done>
</task>

<task type="auto">
  <name>Task 2: Migrate group_choice, group_management, waiting_approval screens + member_list_tile.dart</name>
  <files>
    lib/features/family_sync/presentation/screens/group_choice_screen.dart,
    lib/features/family_sync/presentation/screens/group_management_screen.dart,
    lib/features/family_sync/presentation/screens/waiting_approval_screen.dart,
    lib/features/family_sync/presentation/widgets/member_list_tile.dart
  </files>
  <read_first>
    lib/features/family_sync/presentation/screens/group_choice_screen.dart — full file; Bucket F: _greenGradient [Color(0xFFD4E8CC), Color(0xFFF0F8EC)] and iconBackgroundColor Color(0xFFFEF5F4). lib/features/family_sync/presentation/widgets/member_list_tile.dart — full file; Bucket C purple presets [0xFFE8D5F5, 0xFFF3EAF9, 0xFFFAF5FD]. 33-RESEARCH.md §"Bucket C" — member tile purple presets. 33-PATTERNS.md §"Shared Patterns" — AppColors.* → palette.* rename table. lib/core/theme/app_palette.dart — memberGradientA/B/C, accentPrimaryLight token names.
  </read_first>
  <action>
    For ALL 4 files:

    Step 1 — Import swap: Remove app_colors.dart / app_theme_colors.dart imports; add app_palette.dart import.

    Step 2 — In each build() method, add final palette = context.palette.

    Step 3 — Replace AppColors.* static refs and context.wm* getters using the rename table from 33-PATTERNS.md §"Shared Patterns".

    Step 4 — group_choice_screen.dart Bucket F literals: _greenGradient [Color(0xFFD4E8CC), Color(0xFFF0F8EC)] → [palette.successLight, palette.card] (D-04: re-hue green tint to teal-family; successLight is the closest teal-adjacent light). iconBackgroundColor Color(0xFFFEF5F4) → palette.accentPrimaryLight. If _greenGradient is a static const field, remove it and use the palette values inline in build().

    Step 5 — member_list_tile.dart Bucket C: Color(0xFFE8D5F5) → palette.memberGradientA; Color(0xFFF3EAF9) → palette.memberGradientB; Color(0xFFFAF5FD) → palette.memberGradientC.

    Step 6 — group_management_screen.dart and waiting_approval_screen.dart (no-dark, pure AppColors.* refs): replace all AppColors.* with context.palette.* equivalents.

    CRITICAL: Do NOT use isDark ternary anywhere. All 4 files get full dark support for free after migration via ThemeExtension.
  </action>
  <verify>
    <automated>cd /Users/xinz/Development/home-pocket-app && grep -rn 'AppColors\.\|AppColorsDark\.\|context\.wm\|Color(0x' lib/features/family_sync/ && flutter analyze lib/features/family_sync/ 2>&1 | grep -E '(error|warning|hint|issues)' | head -20</automated>
  </verify>
  <done>grep returns 0 hits for AppColors., AppColorsDark., context.wm, Color(0x across ALL of lib/features/family_sync/. flutter analyze returns 0 issues for family_sync/.</done>
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
grep -rn 'AppColors\.\|AppColorsDark\.\|context\.wm\|Color(0x' lib/features/family_sync/
flutter analyze lib/features/family_sync/
flutter test --exclude-tags golden test/widget/features/family_sync/ 2>&1 | tail -10
```

Expected: all grep commands return 0 hits; analyze 0 issues; family_sync widget tests pass.
</verification>

<success_criteria>
- grep -rn 'Color(0x' lib/features/family_sync/ returns 0 hits
- grep -rn 'AppColors\.\|AppColorsDark\.' lib/features/family_sync/ returns 0 hits
- grep -rn 'context\.wm' lib/features/family_sync/ returns 0 hits
- flutter analyze lib/features/family_sync/ returns 0 issues
</success_criteria>

<output>
Create `.planning/phases/33-color-token-system-consolidation/33-05a-SUMMARY.md` when done.
</output>
