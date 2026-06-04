---
quick_id: 260604-fyd
slug: iphone-15-pro
date: 2026-06-04
status: complete
commit: f156d721
---

# Quick Task 260604-fyd — iPhone 15 Pro 大字体适配修复

## 结果

全局 `textScaler` 钳制上限 **1.2**，修复 iOS 大字体（Dynamic Type / 辅助功能更大字体）
下首页布局溢出。

## 根因

`MaterialApp`（`lib/main.dart`）没有 `builder:`，全工程零 `textScaler` 处理
（`grep textScaler|textScaleFactor lib/` = 0 命中）。iOS 大字体最高 ~3.1×（AX5）无上限
放大文字，撑爆首页固定横向 `Row`——最先出事的是 `home_hero_card.dart` 的
ときめき/日常 分账条（两组「文字+金额」左右对开、不换行）。

## 决策依据

产出 4 档对比 HTML（`textscale-preview.html` + `.png`，按真实 393pt 宽裁切，
Row=nowrap / Expanded=flex:1+min-width:0 建模 Flutter 语义）：1.0 / 1.15 / 1.20 / 1.30。
对比显示分账条在 1.30 切字、1.20 偏紧、1.15 几乎不放大。**用户选 1.2**（不加固分账条）。

## 改动

- **新建** `lib/core/theme/text_scale_clamp.dart` — `const kMaxTextScaleFactor = 1.2` +
  `clampTextScaling(context, child)` builder（`MediaQuery.withClampedTextScaling`，
  child==null → `SizedBox.shrink()`）。
- **改** `lib/main.dart` — `MaterialApp(builder: clampTextScaling, ...)` + import。
- **新建** `test/core/theme/text_scale_clamp_test.dart` — 4 测试（3.0×→钳 1.2 / 1.0×透传 /
  null child 不抛 / 常量=1.2）。

## 验证

- TDD：先 RED（符号未定义编译失败）→ GREEN。
- `flutter test test/core/theme/text_scale_clamp_test.dart` → 4/4 绿。
- `flutter test test/main_characterization_smoke_test.dart` → 8/8 绿（app-boot 未回归）。
- `flutter analyze`（改动文件）→ No issues found。

## 提交

- 代码：`f156d721` fix(260604-fyd): clamp global textScaler to 1.2

## 备注 / 后续

- 仅做全局钳制，未加固分账条；理论上极端长金额（如百万级）在 1.2 下分账条仍可能偏紧——
  用户已知并接受最小改动方案。若日后需更高无障碍上限，可再把分账条两侧改 `Flexible`/换行。
