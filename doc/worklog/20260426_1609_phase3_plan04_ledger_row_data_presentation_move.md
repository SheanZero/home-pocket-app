# Phase 3 Plan 04: ledger_row_data 移至 presentation/models (LV-022 关闭)

**日期:** 2026-04-26
**时间:** 16:09
**任务类型:** 重构
**状态:** 已完成
**相关模块:** [Phase 3 CRITICAL Fixes] LV-022 — ledger_row_data dart:ui 层级违规

---

## 任务概述

Plan 03-04 关闭 LV-022：将 `lib/features/home/domain/models/ledger_row_data.dart` 移至 `lib/features/home/presentation/models/ledger_row_data.dart`。该文件包含 10 个 `Color` 字段和格式化显示字符串，本质上是 presentation 层的视图模型，不是领域实体。移动后 `dart:ui` import 从 domain 层违规变为 presentation 层的合法使用。此次移动同时建立了项目约定 D-12：组合 `dart:ui` 类型的视图模型归属于 `features/<f>/presentation/models/`。

---

## 完成的工作

### 1. Task 0 — Pre-move 特征化测试（移动前在 domain/ 路径编写）

- 创建 `test/features/home/domain/models/ledger_row_data_test.dart`（在源文件的原始路径）
- 测试覆盖：
  - 构造函数对全部 10 个字段的 byte 等价性断言
  - `borderColor` 可选性（默认为 null）
  - 两个具有相同字段的实例相等
  - 10 个 `copyWith` 微测试（每个字段各 1 个），确保改变一个字段不影响其余 9 个字段
- 测试在原始 domain/ 路径运行 GREEN（13/13 通过）
- 提交 SHA: `d8b9144`

### 2. Task 1 — 原子移动操作

操作步骤：
1. `git mv` 源文件到新路径：`lib/features/home/presentation/models/ledger_row_data.dart`
2. `git mv` Task-0 测试文件到新路径：`test/features/home/presentation/models/ledger_row_data_test.dart`
3. `git rm` 旧的 `.freezed.dart` artifact（在 domain/ 路径的 stale 版本）
4. 运行 `build_runner` 在新路径重新生成 `ledger_row_data.freezed.dart`
5. 更新 3 个调用者的 import：
   - `lib/features/home/presentation/screens/home_screen.dart`: `../models/ledger_row_data.dart`
   - `lib/features/home/presentation/widgets/ledger_comparison_section.dart`: `../models/ledger_row_data.dart`
   - `test/features/home/presentation/widgets/ledger_comparison_section_test.dart`: `package:home_pocket/features/home/presentation/models/ledger_row_data.dart`
6. 更新已移动的 Task-0 测试文件的 import 为新路径
7. 提交 SHA: `c549794`

### 3. LV-022 关闭

- 更新 `.planning/audit/issues.json`：将 LV-022 `status: "open"` 改为 `"closed"`
- 添加 `"closed_in_phase": 3`, `"closed_commit": "c549794"`
- 提交 SHA: `a423e7f`

### 4. 代码变更统计

| 文件 | 变更类型 |
|------|---------|
| `lib/features/home/domain/models/ledger_row_data.dart` | 删除（移走） |
| `lib/features/home/domain/models/ledger_row_data.freezed.dart` | 删除（stale artifact） |
| `lib/features/home/presentation/models/ledger_row_data.dart` | 新增（R100 rename） |
| `lib/features/home/presentation/models/ledger_row_data.freezed.dart` | 新增（R100 rename，重新生成） |
| `lib/features/home/presentation/screens/home_screen.dart` | 修改（import 更新） |
| `lib/features/home/presentation/widgets/ledger_comparison_section.dart` | 修改（import 更新） |
| `test/features/home/domain/models/ledger_row_data_test.dart` | 删除（移走） |
| `test/features/home/presentation/models/ledger_row_data_test.dart` | 新增（R099 rename，import 更新） |
| `test/features/home/presentation/widgets/ledger_comparison_section_test.dart` | 修改（import 更新） |
| `.planning/audit/issues.json` | 修改（LV-022 关闭） |

---

## 遇到的问题与解决方案

### 问题 1: `flutter test --no-pub` 触发 Flutter 工具 crash

**症状:** `flutter test --no-pub` 报 `Bad state: No element`（native assets builder 问题）
**原因:** Flutter 3.41.4 的 native assets builder 在 `--no-pub` 模式下有 bug
**解决方案:** 直接使用 `flutter test`（不带 `--no-pub`），正常触发 pub 检查

### 问题 2: coverage_gate 对 Freezed 注解文件报告 0% 失败

**症状:** `coverage_gate.dart` 报告 `ledger_row_data.dart` 0/0 行，标记 FAIL
**原因:** Dart 的 LCOV 工具不为只含 Freezed annotations + `part` 指令的文件生成覆盖数据（无可执行代码行）
**影响:** coverage gate 对该文件返回 false positive 失败
**处理:** 记录为已知 Dart 工具限制，不影响实际测试覆盖。业务逻辑全在 `.freezed.dart` 中，已被 filter 规则过滤。测试套件全部 987 个测试通过。

### 问题 3: `dart run custom_lint` 退出码为 1

**症状:** custom_lint 有 WARNING 级别问题（其他 LV 违规）退出码 1
**原因:** Wave 1 并行执行中，Plan 03-01（处理其他 LV 违规）尚未合并到 main
**影响:** 无。LV-022 (`dart:ui` in domain/) 在 custom_lint 输出中已清除，退出码 1 来自 Plan 03-01 范围内的其他问题
**处理:** 属于 Wave 1 并行执行的正常状态，worktree 隔离执行

---

## 测试验证

- [x] Task-0 特征化测试在原始 domain/ 路径运行 GREEN（13/13）
- [x] Task-0 特征化测试在新 presentation/ 路径运行 GREEN（13/13，证明移动字节等价）
- [x] `ledger_comparison_section_test.dart` 5/5 通过
- [x] 完整测试套件 987/987 通过（`flutter test --coverage`）
- [x] `flutter analyze --no-fatal-infos` 退出 0
- [x] `dart run custom_lint` — LV-022 在输出中不再出现
- [x] AUDIT-10 通过：`flutter pub run build_runner build` 后 `git diff --exit-code lib/` 退出 0
- [x] Rename scores: ledger_row_data.dart R100, ledger_row_data_test.dart R099（均 ≥95）

---

## Git 提交记录

```bash
Commit: d8b9144
test(03-04): add ledger_row_data characterization test (pre-move, LV-022)

Commit: c549794
refactor(03-04): move ledger_row_data to presentation/models (LV-022, D-11/D-12)

Commit: a423e7f
chore(03-04): close LV-022 in issues.json (ledger_row_data moved to presentation)
```

---

## 后续工作

- [ ] Phase 7 文档 sweep：在 CLAUDE.md 中记录 D-12 约定（dart:ui 视图模型 → presentation/models/）
- [ ] Plan 03-05 可补充 ledger_row_data.dart 的覆盖率（如 coverage_gate 工具改进后需要）
- [ ] Wave 1 其余 Plan（03-01, 03-03, 03-05）合并后，custom_lint 退出码应降至 0

---

## 参考资源

- Phase 3 CONTEXT.md D-11/D-12：移动决策
- Phase 3 RESEARCH.md Pitfall 5：原子移动规则
- `.planning/audit/issues.json` LV-022：关闭记录

---

**创建时间:** 2026-04-26 16:09
**作者:** Claude Sonnet 4.6
