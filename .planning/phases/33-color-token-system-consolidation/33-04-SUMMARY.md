---
phase: 33-color-token-system-consolidation
plan: "04"
subsystem: accounting-presentation
tags: [color-migration, dark-mode, palette, isDark-removal, accounting]
dependency_graph:
  requires:
    - 33-02
  provides:
    - accounting-color-tokens-complete
  affects:
    - lib/features/accounting/presentation/
tech_stack:
  patterns:
    - context.palette.* ThemeExtension access
    - isDark ternary removal pattern
    - Nullable color param with context fallback (VoiceWaveform)
key_files:
  modified:
    - lib/features/accounting/presentation/screens/transaction_edit_screen.dart
    - lib/features/accounting/presentation/screens/ocr_review_screen.dart
    - lib/features/accounting/presentation/screens/category_selection_screen.dart
    - lib/features/accounting/presentation/screens/ocr_scanner_screen.dart
    - lib/features/accounting/presentation/screens/manual_one_step_screen.dart
    - lib/features/accounting/presentation/screens/voice_input_screen.dart
    - lib/features/accounting/presentation/widgets/soft_toast.dart
    - lib/features/accounting/presentation/widgets/amount_display.dart
    - lib/features/accounting/presentation/widgets/amount_edit_bottom_sheet.dart
    - lib/features/accounting/presentation/widgets/category_reorder_row.dart
    - lib/features/accounting/presentation/widgets/detail_info_card.dart
    - lib/features/accounting/presentation/widgets/input_mode_tabs.dart
    - lib/features/accounting/presentation/widgets/keyboard_toolbar.dart
    - lib/features/accounting/presentation/widgets/ledger_type_selector.dart
    - lib/features/accounting/presentation/widgets/satisfaction_emoji_picker.dart
    - lib/features/accounting/presentation/widgets/smart_keyboard.dart
    - lib/features/accounting/presentation/widgets/transaction_details_form.dart
    - lib/features/accounting/presentation/widgets/voice_waveform.dart
decisions:
  - "Migrated 18 files (vs 5 in plan files_modified) to achieve the plan's success criteria of 0 grep hits across all of lib/features/accounting/"
  - "Bucket F literal Color(0xFFABABAB) default category color fallback → palette.textSecondary (semantic match)"
  - "Bucket A Color(0xFF1A2530) OCR scanner dark background → palette.card (dark: Color(0xFF162527), close match)"
  - "VoiceWaveform color param changed from const default AppColors.daily to nullable Color? with context.palette.daily fallback"
  - "isDark params removed from _CategoryGroup, _L1ReorderTile, _DetailInfoCardRow sub-widgets — now read context.palette directly"
  - "AppColors.tagGreen (joyLight alias) → palette.joyLight for satisfaction emoji picker selected state"
metrics:
  duration: "~25 minutes"
  completed: "2026-06-01T11:28:47Z"
  tasks_completed: 2
  files_modified: 18
---

# Phase 33 Plan 04: Accounting Feature Color Token Migration Summary

Migrated all color references in `lib/features/accounting/` screens and widgets from legacy `AppColors.*` / `AppColorsDark.*` static refs and `isDark` ternaries to `context.palette.*` ThemeExtension access (ADR-018 Teal Clarity palette).

## Task Results

### Task 1: Migrate 3 partial-dark accounting screens (isDark ternary removal)

Removed all `isDark` local variables and `AppColorsDark.*` ternaries from the 3 canonical "partial dark" screens:

- **transaction_edit_screen.dart**: `isDark` removed, 6 ternaries → `palette.*`, save button gradient → `palette.fabGradientStart/End/actionShadow`
- **ocr_review_screen.dart**: Same pattern — `isDark` + ternaries → `palette.*`
- **category_selection_screen.dart**: `isDark` removed, ternaries replaced, `isDark` prop removed from all 3 sub-widgets (`_CategoryGroup`, `_L1ReorderTile`, `_buildHintBanner`), Bucket F literal `Color(0xFFABABAB)` → `palette.textSecondary`

**Commit:** `25a7f48b`

### Task 2: soft_toast.dart (Bucket E) + ocr_scanner_screen.dart (Bucket A) + all remaining files

- **soft_toast.dart**: 7 Bucket E literals replaced — `errorSurface`, `errorBorder`, `errorShadow` (x1 each), `error` (x4 usages). Error toast now uses ADR-018 error red `#E5484D` light / `#F0676B` dark via ThemeExtension (D-03 / COLOR-02 satisfied).
- **ocr_scanner_screen.dart**: Bucket A literal `Color(0xFF1A2530)` → `palette.card` (dark value `0xFF162527` — close match preserving dark camera UI). `AppColors.daily` → `palette.daily`.
- **manual_one_step_screen.dart**: `isDark` ternaries → `palette.*`
- **voice_input_screen.dart**: `isDark` ternaries + `AppColors.recordingGradientStart/End`, `AppColors.actionGradientStart/End`, `AppColors.actionShadow`, `AppColors.daily` → `palette.*`
- **All widgets** (8 files): `amount_display`, `amount_edit_bottom_sheet`, `category_reorder_row`, `detail_info_card`, `input_mode_tabs`, `keyboard_toolbar`, `ledger_type_selector`, `satisfaction_emoji_picker`, `smart_keyboard`, `transaction_details_form`, `voice_waveform` — all `AppColors.*` and `AppColorsDark.*` refs replaced with `context.palette.*`.

**Commit:** `b1421e4c`

## Deviations from Plan

### Auto-added: Migrated 13 additional files beyond plan's files_modified list

**Rule 2 - Auto-add missing critical functionality**

- **Found during:** Task 2 — grep scan of `lib/features/accounting/` revealed 13 files beyond the plan's 5 `files_modified` that had `AppColors.*` / `AppColorsDark.*` refs.
- **Issue:** Plan `files_modified` listed only 5 files but the `success_criteria` required `grep -rn 'Color(0x' lib/features/accounting/` to return 0. Remaining files would have blocked the gate.
- **Fix:** Migrated all 18 affected files in accounting/ — screens: `manual_one_step_screen.dart`, `voice_input_screen.dart`; widgets: `amount_display.dart`, `amount_edit_bottom_sheet.dart`, `category_reorder_row.dart`, `detail_info_card.dart`, `input_mode_tabs.dart`, `keyboard_toolbar.dart`, `ledger_type_selector.dart`, `satisfaction_emoji_picker.dart`, `smart_keyboard.dart`, `transaction_details_form.dart`, `voice_waveform.dart`.
- **Files modified:** 13 additional files (included in Task 2 commit)

### Auto-fixed: Sub-widget isDark param removal

**Rule 1 - Auto-fix bugs**

- `_DetailInfoCardRow` in `detail_info_card.dart` previously received `isDark: isDark` as a constructor param — removed the param; widget now reads `context.palette` directly, consistent with the migration pattern.
- `_CategoryGroup` and `_L1ReorderTile` in `category_selection_screen.dart` had `isDark` constructor params — removed; both now read `context.palette` from BuildContext.

### VoiceWaveform color param: const default → nullable

- `voice_waveform.dart` had `this.color = AppColors.daily` as a const default. Changed to `Color? color` (nullable) with `context.palette.daily` fallback in `build()`. Voice input screen's explicit `color: AppColors.daily` call site was simultaneously migrated to `color: palette.daily`.

## Verification Results

| Gate | Result |
|------|--------|
| `grep -rn 'Color(0x' lib/features/accounting/` | 0 hits |
| `grep -rn 'AppColors\.\|AppColorsDark\.' lib/features/accounting/` | 0 hits |
| `grep -rn 'isDark' lib/features/accounting/` | 0 hits |
| `flutter analyze lib/features/accounting/` | 2 `info` hints only (pre-existing `onReorder` deprecation in category_selection_screen.dart — out of scope) |

## Known Stubs

None — all palette references are wired to real AppPalette token values.

## Threat Flags

None — pure color constant substitution in presentation layer. No new network endpoints, auth paths, file access patterns, or schema changes.

## Self-Check: PASSED

- Task 1 commit `25a7f48b` exists: verified
- Task 2 commit `b1421e4c` exists: verified
- All 18 modified files verified present
- All grep gates return 0
- flutter analyze accounting/ returns 0 errors/warnings (2 pre-existing info hints)
