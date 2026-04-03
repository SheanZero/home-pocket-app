# Fix Visual Issues and Add Dark Mode Support

**日期:** 2026-04-02
**時間:** 13:34
**任務類型:** Bug修復
**状態:** 已完成
**相関模块:** Home Screen (Wa-Modern Redesign)

---

## 任務概述

修復 Home Screen Wa-Modern 重設計中發現的 4 個視覺問題：main.dart 未使用 AppTheme、缺少暗黑模式支援、字體過小、FamilyInviteBanner 使用 emoji 而非設計稿中的圖標。

---

## 完成的工作

### 1. 主要變更

**Fix 1: Wire AppTheme + Add Dark Theme**
- `lib/main.dart`: 替換 inline `Colors.deepPurple` ThemeData 為 `AppTheme.light` / `AppTheme.dark`
- `lib/core/theme/app_colors.dart`: 新增 `AppColorsDark` 類，包含完整暗黑模式色票
- `lib/core/theme/app_theme.dart`: 新增 `AppTheme.dark` getter

**Fix 2: Theme-aware widgets**
- `lib/core/theme/app_theme_colors.dart`: 新增 `AppThemeColors` extension on BuildContext
- 更新 11 個 home widget，將硬編碼 `AppColors.*` 替換為 `context.wm*`

**Fix 3: Increase font sizes**
- `lib/core/theme/app_text_styles.dart`: bodySmall 11->12, caption 10->11, overline 9->10, micro 8->9, dividerLabel 11->12, navLabel/navLabelActive 9->10

**Fix 4: FamilyInviteBanner redesign**
- 移除 emoji avatars，改用 Material icon circles (Icons.face, Icons.face_2)
- 2 個圓形而非 3 個，46x46 尺寸，2.5px 白邊
- 更新文字內容匹配 Pencil 設計稿
- CTA button 新增 heart icon

### 2. 技術決策
- 使用 BuildContext extension 而非直接在 widget 中判斷 brightness，保持代碼簡潔
- 保持 accent colors (accentPrimary, survival, soul, olive) 在兩個主題中不變
- 只有 background, card, text, border 類顏色隨主題變化

### 3. 代碼變更統計
- 修改 15 個生產文件 + 2 個測試文件
- 新增 1 個文件 (`app_theme_colors.dart`)
- +535 / -336 行

---

## 遇到的問題與解決方案

### 問題 1: _buildLeftInfo 無法訪問 context
**症狀:** `context` undefined in `_buildLeftInfo()` method
**原因:** 私有方法未接收 BuildContext 參數
**解決方案:** 將 context 作為參數傳遞給所有需要訪問 theme 的私有方法

### 問題 2: 舊測試檢查 emoji avatars
**症狀:** 兩個測試文件中的 FamilyInviteBanner 測試失敗
**原因:** 測試期望 emoji 文字 (😊😄🥰) 而新實現使用 Material icons
**解決方案:** 更新兩個測試文件匹配新實現

---

## 測試驗證

- [x] flutter analyze: 0 新問題
- [x] 101 個 home widget 測試全部通過
- [ ] 手動測試驗證 (需要在設備上運行)
- [x] 代碼審查完成
- [x] 文檔已更新

---

## Git 提交記錄

```bash
Commit: 858624b
Date: 2026-04-02

fix(home): wire AppTheme, add dark mode support, fix visual issues
```

---

## 後續工作

- [ ] 在設備上驗證亮色/暗色模式切換效果
- [ ] 確認 Outfit 字體在暗色模式下的可讀性
- [ ] 其他 screen (非 home) 也需要遷移到 context.wm* 模式

---

## 参考資源

- Wa-Modern 設計稿 (Pencil file)
- `lib/core/theme/app_theme_colors.dart` - 新增的 theme extension

---

**創建時間:** 2026-04-02 13:34
**作者:** Claude Opus 4.6
