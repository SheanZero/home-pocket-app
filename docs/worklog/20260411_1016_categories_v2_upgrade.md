# Categories v2 Upgrade (Japan-optimized)

**日期:** 2026-04-11
**時間:** 10:16
**任務類型:** 功能開發 + 數據遷移
**狀態:** 已完成
**相關模組:** MOD-001 Basic Accounting

---

## 任務概述

基於 `docs/dev/categories_recommended.md` 研究結論，把 seed categories 從
19×103 升級到 19×138（删 2 L1 / 新增 2 L1 / 净增 35 L2），加入 Schema v14
migration 保証用戶數據無損升級。

---

## 完成的工作

### 1. 主要変更

- **`lib/shared/constants/default_categories.dart`** — 重寫 seed 數據：L1 列表 +pet +allowance -cash_card -uncategorized；食品/日用/交通/娛樂/衣物/社交/健康/教育/公用事業/通信/住房/汽車/稅務/保險/特殊場合/資產/寵物/零花錢各 L2 分類全面更新，共 138 L2 條目
- **`lib/infrastructure/category/category_service.dart`** — 新增 57 條 v2 分類翻譯（ja/zh/en），刪除 cash_card、uncategorized 的舊翻譯；meal-time L2（breakfast/lunch/dinner）整體重命名為 cat_food_dining_out 系列
- **`lib/data/app_database.dart`** — Schema version 升至 14；新增 `MigrationStepV14` 實現（重命名 L1 IDs、刪除廢棄 L2、插入新 L2 記錄，保留所有用戶交易引用完整性）
- **`lib/application/dual_ledger/rule_engine.dart`** — 更新分類 ID 引用以匹配 v2 命名（cat_food_dining_out 等）
- **`lib/application/analytics/demo_data_service.dart`** — 更新演示數據使用的分類 ID
- **`lib/application/voice/fuzzy_category_matcher.dart`** — 同步 v2 分類 ID 更新
- **`docs/dev/categories.md`** — 更新為 v14 狀態的完整分類樹文檔（19 L1 / 138 L2）
- **`test/unit/data/migrations/category_v14_migration_test.dart`** — 新增 532 行遷移測試，含 15 個測試案例，覆蓋 L1 重命名、L2 新增/刪除、用戶交易完整性驗證

### 2. 技術決策

- **CategoryService 持有分類翻譯（非 ARB 文件）：** 所有新分類名稱加入 static Dart maps；初始計劃以為 ARB files 包含分類翻譯，實際確認後調整 Tasks 3、11 的目標
- **遷移測試使用 NativeDatabase.memory() + raw SQL：** 專案無 drift_schemas/ 快照歷史，採用內存數據庫 + helper function `_runV14MigrationSteps()` 作為測試執行器，同時成為實現合約
- **cat_food meal-time L2 統一重命名：** breakfast/lunch/dinner 全面重映射為 cat_food_dining_out 系列，保持 ID 命名語義一致性

### 3. 代碼変更統計

- 修改文件數：20 個
- 代碼行數：+1970 / -371（淨增 1599 行）
- 主要文件：
  - `lib/shared/constants/default_categories.dart` (+436 行)
  - `test/unit/data/migrations/category_v14_migration_test.dart` (+532 行，新增)
  - `lib/infrastructure/category/category_service.dart` (+249 行)
  - `docs/dev/categories.md` (+306 行，新增)

---

## 遇到的問題與解決方案

### 問題 1: ARB files don't contain category translations
**症狀:** 初始計劃假設 ARB files（`lib/l10n/`）包含分類名稱翻譯（categoryCashCard 等）
**原因:** CategoryService 以 static Dart maps 持有所有翻譯，而非 ARB 字符串
**解決方案:** 更新 Tasks 3、11 目標為 CategoryService；直接在 Dart maps 中新增/刪除翻譯條目

### 問題 2: No drift_schemas/ for migration testing
**原因:** 專案無架構快照歷史（`drift_schemas/` 目錄不存在），無法使用標準 Drift 遷移測試模式
**解決方案:** 採用 `NativeDatabase.memory()` + helper function `_runV14MigrationSteps()` 包含完整 migration SQL，既作測試執行器，也確保實現合約可驗證

---

## 測試驗証

- [x] 單位測試通過（921/921）
- [x] 遷移測試通過（15/15，含 `category_v14_migration_test.dart`）
- [x] Analyzer 0 issues
- [x] Build runner clean

---

## Git 提交記錄

```
d24a77e test: add failing spec for categories v2 (Japan-optimized)
ea2ef1e feat(i18n): add Japan-optimized category translations to CategoryService (v2)
7c92c4f feat(seed): update L1 list (+pet +allowance -cash_card -uncategorized)
4fa432b feat(seed): update food/daily/transport/hobbies L2 categories
162c93f feat(seed): update clothing/social/health/education L2 categories
55de6f5 feat(seed): update utilities/communication/housing/car L2 categories
288bb63 feat(seed): update tax/insurance/special + add allowance L2 categories
f0e4862 docs: update categories.md to v14 state (19 L1 / 138 L2)
ea2ef1e feat(i18n): add Japan-optimized category translations to CategoryService (v2)  [already listed]
76cfe60 feat(seed): add asset/pet L2 categories (completes v2 seed)
3f95b37 feat(i18n): remove deprecated category translations from CategoryService
2120b80 fix: update code references after category ID changes (v2 upgrade)
b575c5e test: add failing v14 migration tests for category upgrade
10d7073 feat(data): add v14 migration for categories upgrade
f0e4862 docs: update categories.md to v14 state (19 L1 / 138 L2)
```

完整有序提交列表（從舊到新）：

```
d24a77e test: add failing spec for categories v2 (Japan-optimized)
ea2ef1e feat(i18n): add Japan-optimized category translations to CategoryService (v2)
7c92c4f feat(seed): update L1 list (+pet +allowance -cash_card -uncategorized)
4fa432b feat(seed): update food/daily/transport/hobbies L2 categories
162c93f feat(seed): update clothing/social/health/education L2 categories
55de6f5 feat(seed): update utilities/communication/housing/car L2 categories
288bb63 feat(seed): update tax/insurance/special + add allowance L2 categories
76cfe60 feat(seed): add asset/pet L2 categories (completes v2 seed)
3f95b37 feat(i18n): remove deprecated category translations from CategoryService
2120b80 fix: update code references after category ID changes (v2 upgrade)
b575c5e test: add failing v14 migration tests for category upgrade
10d7073 feat(data): add v14 migration for categories upgrade
f0e4862 docs: update categories.md to v14 state (19 L1 / 138 L2)
```

---

## 後続工作

- Schema v14 migration 將在既有用戶下次啟動應用時自動執行
- Drift migration testing 基礎設施已建立（未來可在需要時加入 schema snapshots）
- CategoryService 現有 57 條新增 v2 分類翻譯

---

**創建時間:** 2026-04-11 10:16
**作者:** Claude Sonnet 4.6
