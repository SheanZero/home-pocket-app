# 修复 iPhone 15 Pro 大字体首页布局溢出（textScaler 全局钳制 1.2）

**日期:** 2026-06-04
**时间:** 11:35
**任务类型:** Bug修复
**状态:** 已完成
**相关模块:** 首页 (home) / 全局主题 (core/theme)

---

## 任务概述

用户截图反馈：iPhone 15 Pro 选择大字体后首页适配/布局异常。目标是定位根因并修复。

---

## 完成的工作

### 1. 根因定位
- `grep textScaler|textScaleFactor lib/` = **0 命中** → 全工程从未处理字体缩放。
- `lib/main.dart` 的 `MaterialApp` 没有 `builder:`，因此 iOS Dynamic Type / 辅助功能
  「更大字体」（最高 ~3.1× / AX5）会无上限放大所有文字。
- 首页固定横向 `Row` 被撑爆——最先出事的是 `home_hero_card.dart` 的 ときめき/日常
  分账条（两组「文字 + 金额」左右对开、`Row` 默认 nowrap）。

### 2. 决策（HTML 对比稿驱动）
- 产出 `.planning/quick/260604-fyd-iphone-15-pro/textscale-preview.html`（+ PNG 截图）：
  按真实 iPhone 15 Pro 393pt 宽裁切，将 Flutter `Row` 建模为 nowrap flex、`Expanded`
  建模为 `flex:1 + min-width:0`，渲染 1.0 / 1.15 / 1.20 / 1.30 四档。
- 对比结论：1.30 切「日常」字、1.20 偏紧、1.15 几乎不放大。
- **用户拍板：全局钳制上限 1.2，不加固分账条（最小改动）。**

### 3. 主要变更
- 新建 `lib/core/theme/text_scale_clamp.dart`：
  - `const double kMaxTextScaleFactor = 1.2;`
  - `Widget clampTextScaling(BuildContext, Widget?)` = `MediaQuery.withClampedTextScaling(maxScaleFactor: 1.2)`，child==null → `SizedBox.shrink()`。
- 改 `lib/main.dart`：`MaterialApp(builder: clampTextScaling, ...)` + import。
- 新建 `test/core/theme/text_scale_clamp_test.dart`（4 测试）。

### 4. 代码变更统计
- 新增文件 2（实现 + 测试）、修改文件 1（main.dart）。

---

## 遇到的问题与解决方案

### 问题 1: 如何在测试里注入超大环境字号
**症状:** `MaterialApp` 内部用 `MediaQuery.fromView` 覆盖祖先 MediaQuery，无法从上方注入 textScaler。
**解决方案:** 直接对 `clampTextScaling(context, child)` builder 函数做单元测试——用外层
`MediaQuery(data: textScaler: TextScaler.linear(3.0))` 包裹，断言钳制后 `scale(10)==12`。

---

## 测试验证

- [x] TDD：先 RED（`clampTextScaling`/`kMaxTextScaleFactor` 未定义编译失败）→ GREEN
- [x] `flutter test test/core/theme/text_scale_clamp_test.dart` → 4/4 绿
- [x] `flutter test test/main_characterization_smoke_test.dart` → 8/8 绿（app-boot 未回归）
- [x] `flutter analyze`（改动文件）→ No issues found
- [x] 代码审查完成

---

## Git 提交记录

```bash
Commit: f156d721
fix(260604-fyd): clamp global textScaler to 1.2 — large iOS Dynamic Type no longer overflows home
```

---

## 后续工作

- [ ] （可选）若日后要支持更高无障碍字号上限，把 `home_hero_card.dart` 分账条两侧改
      `Flexible`/允许换行，再放宽 `kMaxTextScaleFactor`。

---

## 参考资源

- 决策对比稿：`.planning/quick/260604-fyd-iphone-15-pro/textscale-preview.html`
- 任务摘要：`.planning/quick/260604-fyd-iphone-15-pro/260604-fyd-SUMMARY.md`

---

**创建时间:** 2026-06-04 11:35
**作者:** Claude Opus 4.8
