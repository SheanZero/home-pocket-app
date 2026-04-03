# HomeScreen Wa-Modern Layout Rewrite (Task 13)

**日期:** 2026-04-02
**時間:** 12:07
**任務類型:** 重構
**状態:** 已完成
**相関模組:** Home Feature - presentation/screens

---

## 任務概要

Task 13 of 16 in the Wa-Modern home screen redesign. Rewrote the HomeScreen main assembly to remove the old hero Stack + blue background pattern and replace it with a flat vertical scroll layout that wires all the new widgets built in Tasks 3-12.

---

## 完成的工作

### 1. 主要変更

- Removed `_HeroWithCard` inner widget class entirely (old blue hero Stack pattern)
- Removed `OhtaniConverter` reference and `ohtaniConverterVisibleProvider` watch
- Replaced Stack-based layout with flat `SingleChildScrollView > SafeArea > Padding > Column`
- Added `SectionDivider` between content sections ("今月の支出" and "帳 本")
- Wired `LedgerComparisonSection` with data from `monthlyReportProvider` via `_buildLedgerRows()`
- Wired `SoulFullnessCard` with computed satisfaction, happiness ROI, and soul total
- Wired `TransactionListCard` + `HomeTransactionTile` with tag data (ledger type in solo, member initial in group)
- Conditional rendering: `FamilyInviteBanner` (solo mode) vs `GroupBar` placeholder (group mode)
- Added transactions header row with "最近の取引" and "すべて見る" labels

### 2. 技術決策

- `MonthComparison` model lacks `previousSurvival`/`previousSoul` fields, so used `previousExpenses` as subtitle fallback for both ledger rows
- Used `deviceId[0]` as member initial placeholder in group mode until real member data is available
- Computed satisfaction from soul transaction `soulSatisfaction` scores, ROI from soul/total ratio
- Kept hardcoded Japanese for section labels since these are design-specified and l10n keys don't exist yet

### 3. 代碼変更統計

- Modified: 1 file (`lib/features/home/presentation/screens/home_screen.dart`)
- Created: 1 file (`test/features/home/presentation/screens/home_screen_test.dart`)
- Updated: 1 file (`test/widget/features/home/presentation/screens/home_screen_test.dart`)
- 703 additions, 207 deletions across 3 files

---

## テスト検証

- [x] 20 unit tests in `test/features/home/presentation/screens/home_screen_test.dart` - all pass
- [x] 11 widget tests in `test/widget/features/home/presentation/screens/home_screen_test.dart` - all pass
- [x] `flutter analyze lib/features/home/` - 0 issues
- [x] All existing home widget tests unaffected (pre-existing nav bar failures only)

---

## Git 提交記録

```
Commit: 0866715
refactor(home): complete HomeScreen redesign with Wa-Modern layout
```

---

## 後續工作

- [ ] Add l10n keys for "最近の取引" and "すべて見る" section labels
- [ ] Wire GroupBar with actual group/member data from providers
- [ ] Add "view all" navigation to full transaction list
- [ ] Add date picker functionality for month selection
- [ ] Add `previousSurvival`/`previousSoul` fields to MonthComparison model for accurate per-ledger comparison

---

**作成時間:** 2026-04-02 12:07
**作者:** Claude Opus 4.6
