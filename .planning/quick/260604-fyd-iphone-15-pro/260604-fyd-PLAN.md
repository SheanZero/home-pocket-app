---
quick_id: 260604-fyd
slug: iphone-15-pro
date: 2026-06-04
mode: quick
---

# Quick Task 260604-fyd: iPhone 15 Pro 大字体适配修复

## 背景

`MaterialApp`（`lib/main.dart:150`）没有 `builder:`，全工程零 `textScaler` 处理。
iOS Dynamic Type / 辅助功能「更大字体」最高可放大到 ~3.1×（AX5），文字无上限放大，
撑爆首页的固定横向 `Row`（最先出事的是 `home_hero_card.dart` 的 ときめき/日常 分账条）。

## 决策（用户拍板，基于 textscale-preview.html 四档对比）

- **全局 textScaler 钳制上限 = 1.2**
- 不改造分账条（最小改动）

## 任务

### Task 1 — 全局 textScaler 钳制（TDD）
- **files:**
  - `lib/core/theme/text_scale_clamp.dart`（新建）— `kMaxTextScaleFactor = 1.2` + `clampTextScaling` builder
  - `lib/main.dart` — `MaterialApp(builder: clampTextScaling, ...)`
  - `test/core/theme/text_scale_clamp_test.dart`（新建）
- **action:** 用 `MediaQuery.withClampedTextScaling(maxScaleFactor: 1.2)` 包裹 MaterialApp 子树。
- **verify:** `flutter test test/core/theme/text_scale_clamp_test.dart` 全绿；`flutter analyze` 0 issues。
- **done:** 环境字号 3.0× 时，子树 `MediaQuery.textScalerOf` 被钳到 1.2；1.0× 时透传不变。

## must_haves
- truths:
  - 大字体下首页不再因无上限缩放而溢出（上限 1.2）。
  - 低于 1.2 的用户字号设置仍被尊重（透传）。
- artifacts:
  - `lib/core/theme/text_scale_clamp.dart`
  - `test/core/theme/text_scale_clamp_test.dart`
- key_links:
  - `lib/main.dart` MaterialApp.builder
