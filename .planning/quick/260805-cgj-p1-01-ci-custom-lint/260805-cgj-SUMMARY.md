---
quick_id: 260805-cgj
description: 修复 P1-01：主分支 CI 的 custom_lint 门禁必定失败
date: 2026-08-05
status: complete
commit: a361b1bf
---

# Quick Task 260805-cgj: 修复 P1-01 custom_lint CI 门禁

## What

复现 CI 命令后确认共有 11 个 `import_guard` warning。10 个是合法的
domain 模型依赖，另一个是 family-sync 内存隔离仓库准确计算 UTF-8
载荷大小所需的 `dart:convert`。根因是目录级 allowlist 没有随已提交代码演进，
不是 Dart 源码的跨层违规。

## Changes

- 在 accounting models/repositories allowlist 中补齐 3 个精确模型路径。
- 在 family_sync repositories allowlist 中补齐 3 个模型路径和
  `dart:convert`。
- 在 shopping_list models/repositories allowlist 中补齐 `shopping_unit.dart`。
- 架构 meta-test 仅将 `dart:convert` 加入批准的纯 Dart SDK 集合；其他
  未批准的 `dart:*` 以及原有跨层 deny 规则仍会失败。

共修改 5 个 allowlist 和 1 个架构测试，没有改动业务源码或 CI hard-fail 配置。

## Verification

- `dart run custom_lint --no-fatal-infos` → exit 0，`No issues found!`
- domain/layer/audit-yml 架构测试 → 28/28 passed
- `flutter analyze` → 0 issues
- `git diff --check` → passed

## Commit

- `a361b1bf` — `fix(260805-cgj): restore custom_lint import allowlists`
