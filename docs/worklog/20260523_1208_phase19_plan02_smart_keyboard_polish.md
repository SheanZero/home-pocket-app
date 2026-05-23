# Phase 19 Plan 02: SmartKeyboard Polish — Responsive Height + Rename + Goldens

**日期:** 2026-05-23
**时间:** 12:08
**任务类型:** 重构 + 测试
**状态:** 已完成
**相关模块:** Phase 19 — Manual One-Step + Keypad Polish (Plan 02 — SmartKeyboard)

---

## 任务概述

执行 Phase 19 的第二个计划 (19-02-PLAN.md)。该计划针对 SmartKeyboard 组件进行三项核心改造：响应式高度（带 48 dp 安全底线）、构造参数重命名（`nextLabel` → `actionLabel`，移除 `'Next'` 默认值）、以及 6 张 golden 基线 PNG 作为视觉回归保护。

主要目标：
1. **Task 1（TDD）：** 先写失败测试，再重构 SmartKeyboard — 加入 `math.max(48.0, computed)` clamp、重命名参数、修改间距（行 8→12 dp，列 4→3 dp 每边）、统一 action row 高度（D-08）、digit glyph 加入 tabular figures
2. **Task 2：** 创建 golden test 脚手架 + 6 张基线 PNG（`{ja, zh, en} × {light, dark}`）
3. **Task 3：** Human-verify checkpoint — 用户视觉确认 6 张基线 PNG

---

## 完成的工作

### 1. Task 1 (TDD) — SmartKeyboard 重构

**RED 阶段（c5e77f7）：**

- 创建 `test/widget/features/accounting/presentation/widgets/smart_keyboard_test.dart`（300 行）
- 5 个 test body / 7 个断言（TEST 1 在 3 个设备尺寸上参数化执行）
- 测试覆盖：
  - **TEST 1：** 48 dp 高度底线在 iPhone SE (375×667) / iPhone 14 (390×844) / Pro Max (428×926) 三种设备上的强制断言
  - **TEST 2（P19-B3 修正）：** 列间距 = 6 dp 总可视间距（每键 3 dp horizontal padding × 2 = 6 dp 总）；行间距 = 12 dp
  - **TEST 3：** `actionLabel` 显示渲染；`'Next'` 字符串无泄漏（RESEARCH §Pitfall 6）
  - **TEST 4：** Digit glyph 文本样式包含 `FontFeature.tabularFigures()`（UI-SPEC Typography）
  - **TEST 5：** Action row 三个键（backspace, ¥JPY, Save）高度统一（D-08）
- 编译失败：当前 `SmartKeyboard` 没有 `actionLabel:` 参数

**GREEN 阶段（3d3604c）：**

- 修改 `lib/features/accounting/presentation/widgets/smart_keyboard.dart`（~88 行新增 / 36 行删除）
- 关键变更：
  - 新增 `import 'dart:math' as math;`
  - 参数重命名：`nextLabel = 'Next'` → `required String actionLabel`（移除默认值）
  - `build()` 中加入响应式高度计算：
    ```dart
    final available = mq.size.height * 0.40 - mq.padding.bottom - (4 * 12.0);
    final rawKeyHeight = available / 5;
    final keyHeight = math.max(48.0, rawKeyHeight); // §Pitfall 1 NON-NEGOTIABLE
    ```
  - 4 个 `SizedBox(height: 8)` → `SizedBox(height: 12)`（D-07 行间距）
  - 7 处 `EdgeInsets.symmetric(horizontal: 4)` → `EdgeInsets.symmetric(horizontal: 3)`（P19-B3 修正：3+3=6 dp 总可视列间距）
  - `_DigitKey` 硬编码 `Container(height: 48)` → `Container(height: keyHeight)`
  - `_ActionKey` / `_CurrencyKey` / `_GradientKey` 默认 `height: 50` → 必填 `required this.height`，从 `_buildActionRow` 传入 `keyHeight`（D-08）
  - `_DigitKey` text style 从 `AppTextStyles.amountLarge.copyWith(...)` 改为 `AppTextStyles.labelMedium.copyWith(fontFeatures: const [FontFeature.tabularFigures()], ...)`
- 7 个测试全部通过

### 2. Task 2 — Golden 测试脚手架 + 6 张基线 PNG（191a605）

- 创建 `test/widget/features/accounting/presentation/widgets/smart_keyboard_golden_test.dart`
  - `_wrap()` helper 模仿 `test/golden/amount_display_golden_test.dart` 的 MaterialApp + 三种本地化 delegate 模式，扩展接受 `themeMode` 参数
  - 主体使用 `ThemeData.light()` + `ThemeData.dark()` + `themeMode` 切换
  - `home:` 包装 `Scaffold(body: Align(alignment: Alignment.bottomCenter, child: SizedBox(width: 390, child: child)))`，让键盘贴底渲染在 iPhone-14 宽度（390 dp）
  - 双 for 循环：`{ja, zh, en} × {light, dark}` = 6 个 testWidgets
  - 每个测试调用 `await tester.binding.setSurfaceSize(const Size(390, 844))` 设置 iPhone-14 surface，然后 `expectLater(find.byType(SmartKeyboard), matchesGoldenFile(...))`
- 运行 `flutter test --update-goldens` 生成 6 张基线 PNG：
  - `smart_keyboard_ja_light.png`、`smart_keyboard_ja_dark.png`
  - `smart_keyboard_zh_light.png`、`smart_keyboard_zh_dark.png`
  - `smart_keyboard_en_light.png`、`smart_keyboard_en_dark.png`
- 路径：`test/widget/features/accounting/presentation/widgets/goldens/`（D-09 锁定路径）
- 文件大小：每张 ~8 KB（light 8183 字节 / dark 8565 字节）
- 不带 `--update-goldens` 重跑 — 6 个测试全部 pass

### 3. Task 3 — Human-Verify Checkpoint

- 暂停执行，返回 checkpoint 状态给 orchestrator
- 用户视觉检查 6 张基线 PNG（key 分隔、Save 渐变、light/dark 对比、action row 统一高度）
- 用户确认 approved
- 注：digit glyph 在 PNG 中显示为小方块（'Outfit' 字体在 headless test 环境未加载，符合 RESEARCH §Pitfall 7 预期 — "CI font baseline mismatch — acceptable rhythm: run on Mac, commit, observe CI"）

### 4. 文档

- 创建 `.planning/phases/19-manual-one-step-keypad-polish/19-02-SUMMARY.md`（提交 3ed35a7）
- 创建本 worklog（提交待办）

---

## 技术决策

### 1. 移除 `actionLabel` 默认值，改为 `required`

- **方案 A（已采用）：** `required String actionLabel`，无默认值。任何忘记传值的调用站点都会编译失败。
- **方案 B（已拒绝）：** `String actionLabel = 'Save'`。仍然保留默认字符串可能泄漏的隐患，且不符合 i18n 强制（CLAUDE.md i18n 规则要求所有 UI 文本通过 `S.of(context)`）。
- **理由：** 编译时强制是最强保证，符合 RESEARCH §Pitfall 6 的 "no 'Next' leak" 意图。Plan 01 的 `AmountEditBottomSheet` 和 Plan 03 的 `ManualOneStepScreen` 都会传 `S.of(context).record`，所以没有默认值不会带来生产环境麻烦。

### 2. 在 `build()` 中直接用 `MediaQuery.of(context)` 而非 LayoutBuilder

- **方案 A（已采用）：** `final mq = MediaQuery.of(context);` 直接在 build 中算 `keyHeight`。
- **方案 B（计划建议）：** 用 `LayoutBuilder` 包裹整个 Container。
- **理由：** SmartKeyboard 的根 `Container` 本身就是 host 提供的 slot 的根 widget，`keyHeight` 计算仅依赖 `MediaQuery.size.height` 和 `padding.bottom`，不需要 `constraints.maxWidth`。LayoutBuilder 会增加一层 Builder 嵌套但不带来额外信息。Flutter 的 `MediaQuery.of` 是 `O(1)` lookup（InheritedWidget 缓存），无性能成本。

### 3. 移除 `dart:ui` import（与计划相反）

- **方案 A（已采用）：** 仅 `import 'dart:math' as math;`。`FontFeature` 由 `package:flutter/material.dart` 重新导出。
- **方案 B（计划要求）：** `import 'dart:ui' show FontFeature;`
- **理由：** 项目 analyzer 触发 `unnecessary_import` 警告。CLAUDE.md 明确要求 "Zero analyzer warnings before commit"，且 CLAUDE.md 优先级高于 plan 指示。这是 deviation Rule 1 自动修正（项目规则覆盖 plan 细节）。

### 4. Golden test 中 `setSurfaceSize` 必须 `await`

- **问题：** 计划样例代码 `tester.binding.setSurfaceSize(const Size(390, 844));` 没有 `await`，首次运行报 "Guarded function conflict. You must use 'await' with all Future-returning test APIs"。
- **方案：** 加 `await` + `addTearDown(() async => tester.binding.setSurfaceSize(null))`
- **理由：** Flutter `setSurfaceSize` 是 guarded async — 必须等其完成才能 `pumpWidget`。这是 Rule 3 自动修正（blocking issue）。

### 5. 代码变更统计

- **修改文件：** 1 个生产文件（`smart_keyboard.dart`）
- **新增文件：** 2 个测试文件 + 6 张 PNG
- **新增代码：** ~398 行（300 行 widget test + 98 行 golden test + 60 行 SmartKeyboard 重构）
- **删除代码：** 36 行（旧 SmartKeyboard 参数与硬编码）

---

## 遇到的问题与解决方案

### 问题 1: Worktree 与主仓 cwd 漂移导致首次 Write 落到错位置

**症状:** 首次写 `smart_keyboard_test.dart` 时使用绝对路径 `/Users/xinz/Development/home-pocket-app/test/...`，文件落到了**主仓**而非 worktree。`flutter test` 报错 "Does not exist"。

**原因:** Bash 工具在 worktree 模式下 cwd 会重置，但 Write 工具拿到的绝对路径来自 prompt context（主仓路径）。

**解决方案:** 通过 `git rev-parse --show-toplevel` 获取 worktree 根目录后，使用 worktree 路径重新写入文件。原主仓位置的文件被同名 Write 覆盖（无 commit 影响）。

### 问题 2: 计划中 `dart:ui` 导入触发 analyzer 警告

**症状:** `import 'dart:ui' show FontFeature;` 被 `flutter analyze` 标记为 `unnecessary_import`。

**原因:** `package:flutter/material.dart` 已经重新导出 `FontFeature`，所以 `dart:ui` 重复导入。

**解决方案:** 移除 `dart:ui` import；测试文件同步移除。CLAUDE.md "Zero analyzer warnings before commit" 优先于 plan 文本。

### 问题 3: Golden test `setSurfaceSize` 没有 await 导致 Guarded function conflict

**症状:** 首次运行 `flutter test --update-goldens` 6 个测试全部失败，错误：
```
Guarded function conflict. You must use "await" with all Future-returning test APIs.
The guarded method "setSurfaceSize" from class TestWidgetsFlutterBinding was called from ...
Then, the "pumpWidget" method from class WidgetTester was called from ...
```

**原因:** `tester.binding.setSurfaceSize(...)` 是 async-guarded，必须等待其完成才能调用 `pumpWidget`。

**解决方案:** 加 `await tester.binding.setSurfaceSize(const Size(390, 844));` + `addTearDown(() async => tester.binding.setSurfaceSize(null))`。所有 6 个测试通过。

### 问题 4: Golden PNG 中的文字渲染为小方块

**症状:** 6 张 PNG 中 digit glyph 和 'Record' label 显示为小方块（placeholder boxes）。

**原因:** 项目自定义字体 'Outfit' 在 headless test 环境未加载（标准 Flutter 测试行为）。

**解决方案:** 这是 RESEARCH §Pitfall 7 明确预期的行为 — "CI font baseline mismatch — acceptable rhythm: run on Mac, commit, observe CI"。结构布局（按键分隔、Save 渐变、亮/暗对比、action row 统一）在 PNG 中清晰可见且正确。用户视觉确认 approved。

---

## 测试验证

- [x] 单元/Widget 测试通过（7/7 in `smart_keyboard_test.dart`）
- [x] Golden 测试通过（6/6 in `smart_keyboard_golden_test.dart` 不带 `--update-goldens`）
- [x] `flutter analyze lib/features/accounting/presentation/widgets/smart_keyboard.dart` — 0 issues
- [x] `flutter analyze test/widget/features/accounting/presentation/widgets/smart_keyboard_test.dart` — 0 issues
- [x] `git diff pubspec.yaml pubspec.lock` 为空（零新依赖，D-12 保留）
- [x] 用户视觉审核 6 张 PNG — approved
- [x] 文档已更新（19-02-SUMMARY.md + 本 worklog）

**未运行项（intentional）：**

- 全树 `flutter analyze`：`transaction_entry_screen.dart:338` 仍调用 `nextLabel: l10n.next`，在本 wave 提交后到 Plan 03 wave-2 删除之间会编译失败。这是 P19-B1 修正明确接受的 intra-wave window。
- `flutter test --coverage`：本 plan 只新增 1 个测试文件，全树覆盖率由 wave 合并后的整体计算决定。

---

## Git 提交记录

```bash
Commit: c5e77f7  test(19-02): add failing widget tests for SmartKeyboard responsive height + 48dp floor + spacing + tabular figures
Commit: 3d3604c  feat(19-02): refactor SmartKeyboard — responsive 48dp-floor height + rename nextLabel->actionLabel + 6dp total gap
Commit: 191a605  feat(19-02): add SmartKeyboard golden test scaffold + 6 baseline PNGs (SC-3 / D-09)
Commit: 3ed35a7  docs(19-02): complete plan 02 summary — SmartKeyboard responsive height + rename + goldens
Commit: (pending)  docs(worklog): log Phase 19 Plan 02 — SmartKeyboard polish
```

---

## 后续工作

- [ ] **Plan 03 (wave 2)：** `ManualOneStepScreen` 创建 + `transaction_entry_screen.dart` / `transaction_confirm_screen.dart` 删除。Plan 03 会调用 `SmartKeyboard(actionLabel: S.of(context).record, ...)` — 本 plan 已经准备好这个 API。
- [ ] **Plan 03 收尾 P19-B1 window：** `transaction_entry_screen.dart` 在本 wave 与 Plan 03 wave-2 之间编译失败。Plan 03 删除此文件后全树 analyzer 恢复绿色。
- [ ] **Plan 04 (wave 3)：** Phase 18 host adoption — `TransactionEditScreen` + `OcrReviewScreen` 渲染自己的 `AmountDisplay` + 通过 `AmountEditBottomSheet.show` 处理 amount 编辑。不直接触碰 `SmartKeyboard`。
- [ ] **orchestrator 后续：** 在 wave 合并后更新 `.planning/STATE.md` 和 `.planning/ROADMAP.md`（本 agent 不写这两个文件）。

---

## 参考资源

- 计划文件：`.planning/phases/19-manual-one-step-keypad-polish/19-02-PLAN.md`
- 上下文文件：`.planning/phases/19-manual-one-step-keypad-polish/19-CONTEXT.md`（D-06, D-07, D-08, D-09）
- 研究文件：`.planning/phases/19-manual-one-step-keypad-polish/19-RESEARCH.md`（§Pitfall 1 NON-NEGOTIABLE 48 dp, §Pitfall 6 nextLabel 重命名, §Pitfall 7 CI 字体基线）
- Pattern 文件：`.planning/phases/19-manual-one-step-keypad-polish/19-PATTERNS.md`（§3 smart_keyboard.dart 修改, §14 smart_keyboard_golden_test.dart）
- UI 规范：`.planning/phases/19-manual-one-step-keypad-polish/19-UI-SPEC.md`（Typography section, Color invariants）
- 验证策略：`.planning/phases/19-manual-one-step-keypad-polish/19-VALIDATION.md`（SC-2, SC-3）
- 上一 plan 的 worklog：`docs/worklog/20260523_1146_phase19_plan01_form_refactor.md`
- 本 plan 的 summary：`.planning/phases/19-manual-one-step-keypad-polish/19-02-SUMMARY.md`
- CLAUDE.md "Amount Display Style" 节（FontFeature.tabularFigures() 规则）
- CLAUDE.md "Riverpod 3 conventions" 节（未触发，但参考遵守）

---

**创建时间:** 2026-05-23 12:08
**作者:** Claude Opus 4.7 (1M context)
