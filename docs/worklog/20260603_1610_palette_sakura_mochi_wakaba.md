# 桜餅×若葉 配色迁移 (ADR-019)

**日期:** 2026-06-03
**时间:** 16:10
**任务类型:** 功能开发 + 架构决策
**状态:** 已完成
**相关模块:** lib/core/theme/app_palette.dart — Color Token System

---

## 任务概述

将整个 App 的配色从 ADR-018 "Teal Clarity"（青色主色）迁移至 ADR-019 "Sakura Mochi × Wakaba"（若葉绿主色 + 桜粉 FAB + 暖琥珀悦己 + 暖奶油背景）。这是继 Phase 33/34 Teal Clarity 落地、quick 260602-jcl 丁香 Mauve 迭代之后的第三次配色演进，由用户从 Pencil 节点 soqKs 选定方向。

---

## 完成的工作

### 1. 主要变更

- `lib/core/theme/app_palette.dart`: 全量更新 light/dark 两套约 60 个 token（背景、文字、边框、primary、FAB、daily、joy、shared、语义色、装饰色）
- `lib/core/theme/app_theme.dart`: 更新 AppTheme.light/dark 中硬编码的 ADR-018 hex 值改为引用 AppPalette token
- `docs/arch/03-adr/ADR-019_Palette_Selection_v1_6.md`: 新建 ADR，记录 v1.6 决策，含完整明暗逐角色 hex 表
- `docs/arch/03-adr/ADR-018_Palette_Selection_v1_5.md`: append-only 追加 Update 章节，标注被 ADR-019 取代
- `docs/arch/03-adr/ADR-000_INDEX.md`: 新增 ADR-019 条目，统计更新为 18 个 ADR
- `CLAUDE.md`: 新增 `## App Color Scheme (v1.6 — ADR-019 桜餅×若葉)` 章节
- `test/core/theme/app_palette_test.dart`: 契约测试更新为 ADR-019 hex 值
- `test/widget/theme_dark_mode_coverage_test.dart`: 更新 dark background 断言
- 80 张 golden master PNG 全量 re-baseline（73 in `test/golden/goldens/` + 7 in `test/widget/`）

### 2. 技术决策

- 直接依照 PLAN.md 中的 token mapping 表逐字段更新，未重新推导
- `app_theme.dart` 改为动态引用 `AppPalette.*` 而非继续硬编码，避免下次配色迁移时遗漏
- `joyRoiBg/joyRoiBorder` 保持绿色（ROI/success 语义，不跟随 joy 身份色变化）
- `happiness_ring_palette.dart` 充盈环配色保持独立，本次不触碰

### 3. 代码变更统计

- 修改文件: 87 个（2 源文件 + 2 测试文件 + 3 ADR/docs + 80 PNG）
- 新建文件: 1 个（ADR-019 + SUMMARY.md）
- 删除文件: 0 个

---

## 遇到的问题与解决方案

### 问题 1: app_theme.dart 中的硬编码 hex 导致测试失败

**症状:** `app_theme_test.dart` 断言 `theme.scaffoldBackgroundColor == AppPalette.light.background` 失败，两者数值不一致。
**原因:** `AppTheme.light` 的 `scaffoldBackgroundColor: const Color(0xFFF8FCFD)` 是 ADR-018 旧值，未随 `app_palette.dart` 更新。
**解决方案:** 将 `AppTheme.light/dark` 中所有颜色字段改为引用 `AppPalette.light.*` / `AppPalette.dark.*` token（Rule 1 auto-fix）。

### 问题 2: test/widget/ 子目录也有 golden 测试需要更新

**症状:** 全量 `flutter test` 后发现 `voice_input_screen_mic_button_golden_test.dart` 和 `smart_keyboard_golden_test.dart` 失败。
**原因:** 这些 golden 存储在 `test/widget/` 而非 `test/golden/`，计划中 `flutter test test/golden/ --update-goldens` 未覆盖它们。
**解决方案:** 额外对 `test/widget/` 下的 golden 测试运行 `--update-goldens`，更新了 7 张 PNG。

### 问题 3: theme_dark_mode_coverage_test.dart 中硬编码 ADR-018 dark 背景

**症状:** 该测试断言 dark background == `Color(0xFF0C1719)`（ADR-018 teal-dark），但新值为 `#171210`。
**原因:** 测试未通过 `AppPalette.dark.background` 动态引用，而是直接写死旧色值。
**解决方案:** 更新断言为 `Color(0xFF171210)` 并更新描述从 "ADR-018" 到 "ADR-019"。

---

## 测试验证

- [x] 单元测试通过（app_palette_test.dart ADR-019 合约更新）
- [x] 集成测试通过（app_theme_test.dart）
- [x] Golden 测试通过（80 张全量 re-baseline）
- [x] 全量测试通过（2297/2297）
- [x] flutter analyze: 无新增 issue（4 个 pre-existing info 级问题不在本次修改文件中）
- [x] 文档已更新（ADR-019 + INDEX + CLAUDE.md）

---

## Git 提交记录

```
Commit: 0e37262e
Date: 2026-06-03
feat(260603-lr5-01): re-value AppPalette to 桜餅×若葉 v1.6 (ADR-019)

Commit: d148f6e7
Date: 2026-06-03
feat(260603-lr5-02): re-baseline all 80 golden masters for 桜餅×若葉 palette

Commit: 9d9f227e
Date: 2026-06-03
docs(260603-lr5): complete 桜餅×若葉 palette quick task
```

---

## 后续工作

- [ ] 视觉确认：daily_vs_joy_card 和 home_hero_card golden 应显示清晰可辨的若葉绿 daily vs 琥珀 joy（WCAG 视觉抽查）
- [ ] Phase 34 WR-01（dark list_transaction_tile 内部日期显示 ja 语言）仍为 pre-existing 未修问题，延续至未来任务
- [ ] MEMORY.md 更新由 orchestrator 处理（D-03b accepted-deferred）

---

## 参考资源

- `docs/arch/03-adr/ADR-019_Palette_Selection_v1_6.md` — 本次配色决策权威文档
- `docs/arch/03-adr/ADR-018_Palette_Selection_v1_5.md` — 上一版配色（已被取代）
- `.planning/quick/260603-lr5-pencil-soqks-app/260603-lr5-PLAN.md` — 执行计划

---

**创建时间:** 2026-06-03 16:10
**作者:** Claude Sonnet 4.6
