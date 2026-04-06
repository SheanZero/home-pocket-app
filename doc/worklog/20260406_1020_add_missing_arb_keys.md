# Add Missing ARB Keys for Hardcoded UI Strings

**日期:** 2026-04-06
**时间:** 10:20
**任务类型:** 功能开发
**状态:** 已完成
**相关模块:** MOD-014 i18n

---

## 任务概述

向所有 3 个 ARB 文件（en/ja/zh）中添加 7 个缺失的翻译 key，这些 key 对应 UI 中曾被硬编码的字符串。同时更新 `initializationError` key 以支持 `{error}` 占位符。

---

## 完成的工作

### 1. 主要变更

**`lib/l10n/app_en.arb`:**
- 更新 `initializationError` 值为 `"Initialization failed: {error}"`，并添加 placeholder 元数据
- 更新 `@error` description 为更准确的描述
- 新增 5 个 key（带 `@` 元数据）：`listTab`、`todoTab`、`datePickerComingSoon`、`selectLanguage`、`languageSystem`

**`lib/l10n/app_ja.arb`:**
- 更新 `initializationError` 值为 `"初期化に失敗しました: {error}"`
- 新增 5 个 key（仅翻译值）：`listTab`、`todoTab`、`datePickerComingSoon`、`selectLanguage`、`languageSystem`

**`lib/l10n/app_zh.arb`:**
- 更新 `initializationError` 值为 `"初始化失败: {error}"`
- 新增 5 个 key（仅翻译值）：`listTab`、`todoTab`、`datePickerComingSoon`、`selectLanguage`、`languageSystem`

### 2. 新增翻译 Keys 汇总

| Key | EN | JA | ZH |
|-----|----|----|-----|
| `listTab` | List | リスト | 列表 |
| `todoTab` | Todo | やること | 待办 |
| `datePickerComingSoon` | Date picker coming soon | 日付選択は近日公開 | 日期选择即将推出 |
| `selectLanguage` | Select Language | 言語を選択 | 选择语言 |
| `languageSystem` | Follow System | システム設定に従う | 跟随系统设置 |

### 3. 代码变更统计
- 修改文件数：4（3 个 ARB + 1 个 CSV）
- CSV 导出 key 总数：331（含新增的 7 个）

---

## 遇到的问题与解决方案

无特殊问题。`error` 和 `initializationError` key 已存在但需更新。

---

## 测试验证

- [x] `flutter gen-l10n` 无错误
- [x] `flutter test` 全部通过（878 个测试）
- [x] CSV 重新导出成功

---

## Git 提交记录

```bash
Commit: 4d4b7a7
Date: 2026-04-06

feat: add missing i18n keys for hardcoded UI strings
```

---

## 后续工作

- [ ] 在 UI 代码中将对应硬编码字符串替换为 `S.of(context).listTab` 等调用

---

**创建时间:** 2026-04-06 10:20
**作者:** Claude Sonnet 4.6
