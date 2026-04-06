# ARB Translation Audit and Bug Fix

**日期:** 2026-04-06
**时间:** 10:16
**任务类型:** Bug修复
**状态:** 已完成
**相关模块:** [MOD-014] i18n

---

## 任务概述

对三个 ARB 文件（app_en.arb、app_ja.arb、app_zh.arb）进行系统性审计，修复已知翻译 bug 并扫描所有 key 寻找语言错误、未翻译内容及不一致问题。修复后重新导出 CSV 并运行 flutter gen-l10n 验证。

---

## 完成的工作

### 1. 修复的翻译错误（共 10 处）

**app_ja.arb（日文文件）：**

| key | 旧值 | 新值 | 问题类型 |
|-----|------|------|----------|
| `addTransaction` | `添加账目` | `取引を追加` | 中文误入日文文件 |
| `next` | `Next` | `次へ` | 英文未翻译 |

**app_zh.arb（中文文件）：**

| key | 旧值 | 新值 | 问题类型 |
|-----|------|------|----------|
| `next` | `Next` | `下一步` | 英文未翻译 |
| `groupCreate` | `创建 Group` | `创建群组` | 英文混入 |
| `groupName` | `Group 名` | `群组名称` | 英文混入 |
| `groupOwner` | `Owner` | `群主` | 英文未翻译 |
| `groupJoinTarget` | `你要加入的 Group` | `你要加入的群组` | 英文混入 |
| `groupWaitingApproval` | `等待 Owner 审批...` | `等待群主审批...` | 英文混入 |
| `groupRename` | `修改 Group 名` | `修改群组名称` | 英文混入 |
| `groupEnterGroup` | `进入 Group` | `进入群组` | 英文混入 |
| `groupDisband` | `解散 Group` | `解散群组` | 英文混入 |
| `groupCodeHint` | `请向群组的 Owner 索取邀请码` | `请向群组的群主索取邀请码` | 英文混入 |

### 2. 验证

- `flutter gen-l10n` 无错误
- `dart run scripts/arb_to_csv.dart` 成功导出 326 个 key

### 3. 修改的文件

- `lib/l10n/app_ja.arb` — 2 处修复
- `lib/l10n/app_zh.arb` — 9 处修复（含 3 个已知 bug + 6 个额外发现的 group* 系列问题）
- `docs/i18n/translations.csv` — 重新导出

---

## 遇到的问题与解决方案

### 问题 1: zh 文件中 group* 系列大量英文混入
**症状:** groupCreate、groupOwner、groupName、groupJoinTarget 等 9 个 key 中混有英文词 "Group"、"Owner"
**原因:** 初次添加这些 key 时疏漏翻译
**解决方案:** 逐一替换为对应中文词，"Group" → "群组"，"Owner" → "群主"

---

## 测试验证

- [x] flutter gen-l10n 通过（无错误输出）
- [x] arb_to_csv.dart 成功导出 326 keys
- [ ] 手动 UI 测试（需端到端验证）

---

## Git 提交记录

```
Commit: 260c39a
Date: 2026-04-06

fix: audit and correct translation errors across all ARB files
```

---

## 后续工作

- [ ] 手动检查 group 管理页面的 UI 渲染（中文显示）
- [ ] 考虑添加 lint 规则防止 ARB 文件中出现未翻译的英文

---

**创建时间:** 2026-04-06 10:16
**作者:** Claude Sonnet 4.6
