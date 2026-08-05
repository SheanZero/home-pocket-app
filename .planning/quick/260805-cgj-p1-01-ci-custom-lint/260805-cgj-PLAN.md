---
quick_id: 260805-cgj
description: 修复 P1-01：主分支 CI 的 custom_lint 门禁必定失败
date: 2026-08-05
status: planned
---

# Quick Task 260805-cgj: 修复 P1-01 custom_lint CI 门禁

## Problem

`dart run custom_lint --no-fatal-infos` 以退出码 1 报告 11 个
`import_guard` warning。逐项检查确认，10 个是同一 domain 层的模型依赖，
另 1 个是内存 repository 实现计算 UTF-8 字节数所需的 `dart:convert`。
它们没有跨越架构禁止边界，只是 5 个目录级 allowlist 未随代码更新。

## Task

在以下 5 个 `import_guard.yaml` 中补齐精确白名单，不扩大上层 deny 规则：

1. accounting domain models：2 个 sibling policy model。
2. accounting domain repositories：1 个 category snapshot model。
3. family_sync domain repositories：3 个 domain model 和 `dart:convert`。
4. shopping_list domain models：1 个 sibling unit model。
5. shopping_list domain repositories：1 个 unit model。
6. domain import meta-test：精确允许纯 Dart SDK 的 `dart:convert`，继续拒绝其他未经批准的 `dart:*`。

- **action:** 仅增加当前 11 个 warning 对应的精确 allow entry。
- **verify:** `dart run custom_lint --no-fatal-infos`、domain/layer/CI 架构测试、`flutter analyze`。
- **done:** custom_lint 退出 0，CI 使用的命令恢复绿色。

## Out of scope

- 不修改合法的 Dart import。
- 不移除或降低 feature/domain 层 deny 规则。
- 不触碰当前工作区中的 UI、主题和 Golden 改动。
