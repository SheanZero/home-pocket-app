# Home Polish Bucket A — Quick Task 260518-pf5

**日期:** 2026-05-18
**时间:** 20:19
**任务类型:** 功能开发（UI 打磨）
**状态:** 已完成
**相关模块:** Home UI, Analytics UI, i18n

---

## 任务概述

实现 2026-05-18 首页审查中 Bucket A 的 7 项 UI 打磨。涉及排版间距、悦己/日常双账本分段 bar 颜色、已评分 caption 移除、家族邀请 banner 中文 i18n、最近交易展示优化，以及统计页标题间距对齐。

---

## 完成的工作

### 1. 主要变更

**Task 1 — HomeHeroCard 排版 + 分段 bar + caption 移除**
- `_hero()`: label→金额、金额→上月 SizedBox 从 4→8px
- `_buildBestJoyStrip()`: tag 行换用 `AppTextStyles.overline`；中间行换用 `titleSmall` w400；小字行换用 `caption` + tabularFigures
- `_splitBar()`: 底层 Stack 颜色从 `wmBackgroundDivider` 改为 `AppColors.survival` (#5A9CC8)
- `_legendSingle()`: 移除 `homeCoverageCaption` 块和 `_rated()` 方法
- 三语 ARB 文件删除 `homeCoverageCaption` key
- 更新 home_hero_card_test.dart 中的 thin-sample 测试断言
- 再生成 5 个 golden PNG

**Task 2 — ARB ledger label 修剪 + 家族邀请 banner i18n**
- zh/en: `soulLedger`/`survivalLedger` 去掉"账本"/"Ledger"后缀
- 三语 ARB 新增 `homeFamilyBannerTitle` + `homeFamilyBannerSubtitle`
- `FamilyInviteBanner`: 3 处硬编码日文 → `S.of(context).xxx`
- 更新两处测试文件加入 `localizationsDelegates`

**Task 3 — 最近交易展示修复 + 统计页间距**
- `_formatAmount()` 去掉 expense 的 `-` 前缀
- `HomeTransactionTile` amountColor 统一为 `wmTextPrimary`
- 新增 `_satisfactionIcon()` 按 ADR-014 映射返回 `IconData?`
- `HomeTransactionTile` 新增 optional `satisfactionIcon` param；soul 行显示 14px 满意度图标
- `AnalyticsScreen` body top padding 24→16px

### 2. 技术决策

- `soulLedger`/`survivalLedger` 确认单一调用点后直接修改 ARB 值（不引入新 key）
- FamilyInviteBanner CTA "家族を招待する" 复用已有 `homeFamilyInviteTitle` key（避免重复）
- 满意度图标使用 `Icons.*` 与 `satisfaction_emoji_picker.dart` 相同，保持 ADR-014 一致性

### 3. 代码变更统计

- 修改文件：20
- 新增行：~335；删除行：~339
- 主要文件：home_hero_card.dart, family_invite_banner.dart, home_screen.dart, home_transaction_tile.dart, analytics_screen.dart, app_ja/zh/en.arb

---

## 遇到的问题与解决方案

### 问题 1: 重复测试文件未在 plan 中
**症状:** `flutter test` 全套跑出 7 失败，全在 `test/features/home/...family_invite_banner_test.dart`
**原因:** 项目中有两个位置的同名测试文件（`test/features/` 和 `test/widget/features/`）；plan 只提到了后者
**解决方案:** Rule 3 auto-fix — 给 `test/features/...` 版本也加上 `localizationsDelegates` + `pumpAndSettle` + 更新字符串断言

---

## 测试验证

- [x] 单元测试通过（flutter test 1414 tests, 0 failures）
- [x] flutter analyze 0 issues
- [x] flutter gen-l10n 成功
- [x] dart format 无 diff（plan 所涉文件）
- [x] Golden 再生成（5 个 PNG）
- [ ] 手动 UI 验证（待人工确认）

---

## Git 提交记录

```
8f1369d fix(260518-pf5): items 1+2b+5+6 HomeHeroCard typography, splitbar, caption removal
ac3fc4b fix(260518-pf5): items 2a+7 ARB ledger label trim and family invite i18n
5b7b6ee fix(260518-pf5): items 8+9a recent-tx display fixes and analytics spacing
6d59ef3 fix(260518-pf5): update duplicate family invite banner test for i18n change
```

---

## 后续工作

- [ ] 人工 UI 验证 (checkpoint:human-verify — 手动 checklist 见 SUMMARY.md)
- [ ] Bucket B: items 3, 4, 9b 待 ADR-016 决议后实施

---

**创建时间:** 2026-05-18 20:19
**作者:** Claude Sonnet 4.6
