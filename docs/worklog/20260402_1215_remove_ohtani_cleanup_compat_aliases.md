# Remove OhtaniConverter and Cleanup Unused Compat Aliases

**日期:** 2026-04-02
**時間:** 12:15
**任務類型:** 重構
**狀態:** 已完成
**相關模組:** Home Feature (Task 15 of 16)

---

## 任務概述

Remove the OhtaniConverter widget (gyudon bowl equivalent joke display) and clean up unused compatibility color aliases in app_colors.dart after all home widgets have been rewritten to the Wa-Modern design system.

---

## 完成的工作

### 1. 主要變更

- Deleted `lib/features/home/presentation/widgets/ohtani_converter.dart`
- Removed `OhtaniConverterVisible` provider from `home_providers.dart`
- Regenerated `home_providers.g.dart` via build_runner
- Deleted `test/widget/features/home/presentation/widgets/ohtani_converter_test.dart`
- Removed OhtaniConverterVisible test group from `home_providers_test.dart`

### 2. Compat Alias Cleanup in app_colors.dart

Removed 24 unused compatibility color aliases across 5 categories:

**Ohtani converter (3):** `ohtaniBackground`, `ohtaniText`, `ohtaniClose`

**Hero header (2):** `heroBackground`, `textOnPrimary`

**Month overview card (4):** `modeBadgeBg`, `survivalBarBg`, `previousBarSurvival`, `previousBarSoul`, `currentBarSoul`

**Family invite banner (1):** `familyInviteBackground`

**Soul fullness card (8):** `soulCardBg`, `soulMetricBg1`, `soulMetricBg2`, `soulProgressBg`, `soulBadgeBg`, `soulTextDark`, `soulTextMuted`, `soulQuoteText`

**General unreferenced aliases (5):** `primary`, `textMuted`, `inactiveTab`, `comparisonPositive`, `survivalBorder`

Kept `divider` and `tabBarBackground` as they are still referenced in other features.

### 3. Test Fixes

- Updated `app_colors_test.dart`: replaced stale `primary` reference with `accentPrimary`, corrected expected hex values for `background` and `textPrimary`
- Updated `home_bottom_nav_bar_test.dart`: replaced `AppColors.inactiveTab` with `AppColors.textTertiary`

### 4. 代碼變更統計
- 刪除文件: 2
- 修改文件: 6
- 刪除代碼行數: ~217
- 添加代碼行數: ~7

---

## 測試驗證

- [x] build_runner 成功 (187 outputs)
- [x] flutter analyze 通過 (0 new issues; 4 pre-existing unrelated errors in voice_providers_clean.dart)
- [x] 修改的測試全部通過 (app_colors_test, home_providers_test)
- [x] 全套測試 804 passed, 2 pre-existing failures (home_bottom_nav_bar stale widget tests)

---

## Git 提交記錄

```
Commit: a1cf12f
chore(home): remove OhtaniConverter and cleanup unused compat aliases
```

---

## 後續工作

- [ ] Task 16 (final task in the series)
- [ ] Fix pre-existing home_bottom_nav_bar_test.dart failures (stale widget expectations)

---

**創建時間:** 2026-04-02 12:15
**作者:** Claude Opus 4.6
