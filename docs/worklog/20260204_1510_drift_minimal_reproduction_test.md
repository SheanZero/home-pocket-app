# Drift Code Generation Minimal Reproduction Test (Task 1)

**日期:** 2026-02-04
**时间:** 15:10
**任务类型:** 架构决策 | 测试
**状态:** 已完成
**相关模块:** [MOD-001] Basic Accounting

---

## 任务概述

执行 Drift blocker 调查计划的 Task 1: 创建最小复现用例，以隔离 Drift 代码生成问题是由 Drift 本身引起还是主项目配置引起。

**背景:**
- 主项目中 Drift 生成 DAO `.g.dart` 文件，但 **无法生成** `AppDatabase.g.dart`
- 这是 MOD-001 (Basic Accounting) 的关键阻塞问题
- 需要确定问题根源以采取正确的解决方案

---

## 完成的工作

### 1. 创建最小测试项目
**位置:** `/tmp/test_drift_minimal`

**项目结构:**
```
/tmp/test_drift_minimal/
├── lib/
│   ├── tables/
│   │   └── users_table.dart
│   ├── daos/
│   │   ├── user_dao.dart
│   │   └── user_dao.g.dart (generated)
│   ├── database.dart
│   └── database.g.dart (generated ✅)
└── pubspec.yaml
```

**依赖配置:**
```yaml
dependencies:
  drift: ^2.14.0  # (实际安装: 2.31.0)
  sqlite3_flutter_libs: ^0.5.18

dev_dependencies:
  drift_dev: ^2.14.0  # (实际安装: 2.31.0)
  build_runner: ^2.4.7  # (实际安装: 2.10.5)
```

### 2. 最小代码实现

**UsersTable (lib/tables/users_table.dart):**
```dart
import 'package:drift/drift.dart';

class UsersTable extends Table {
  @override
  String get tableName => 'users';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get email => text()();
}
```

**UserDao (lib/daos/user_dao.dart):**
```dart
import 'package:drift/drift.dart';
import 'package:test_drift_minimal/database.dart';
import 'package:test_drift_minimal/tables/users_table.dart';

part 'user_dao.g.dart';

@DriftAccessor(tables: [UsersTable])
class UserDao extends DatabaseAccessor<AppDatabase> with _$UserDao {
  UserDao(AppDatabase db) : super(db);

  Future<List<UsersTableData>> getAllUsers() => select(usersTable).get();
}
```

**AppDatabase (lib/database.dart):**
```dart
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:test_drift_minimal/daos/user_dao.dart';
import 'package:test_drift_minimal/tables/users_table.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [UsersTable],
  daos: [UserDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1;
}
```

### 3. 执行代码生成

**命令:**
```bash
cd /tmp/test_drift_minimal
dart run build_runner build --delete-conflicting-outputs
```

**输出:**
```
  1s compiling builders/jit
  2s compiling builders/jit
  2s compiling builders/jit
  0s drift_dev on 16 inputs; lib/daos/user_dao.dart
  3s drift_dev on 16 inputs: 1 output; spent 2s sdk; lib/database.dart
  6s drift_dev on 16 inputs: 3 output; spent 3s analyzing, 2s sdk; lib/tables/users_table.dart
  6s drift_dev on 16 inputs: 4 skipped, 10 output, 2 no-op; spent 3s analyzing, 2s sdk
  0s source_gen:combining_builder on 8 inputs; lib/daos/user_dao.dart
  0s source_gen:combining_builder on 8 inputs: 4 skipped, 2 output, 2 no-op
  Built with build_runner/jit in 9s; wrote 12 outputs.
```

### 4. 验证生成结果

**生成的文件:**
- ✅ `lib/daos/user_dao.g.dart` - **485 bytes** (成功)
- ✅ `lib/database.g.dart` - **12,501 bytes** (成功 ← **关键文件**)

**database.g.dart 内容验证:**
```dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $UsersTableTable extends UsersTable
    with TableInfo<$UsersTableTable, UsersTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTableTable(this.attachedDatabase, [this._alias]);
  // ... (12,501 bytes total)
```

---

## 技术决策

### 决策 1: Drift 本身没有问题
**结论:** ✅ Drift 2.31.0 在隔离环境下工作正常

**理由:**
- 最小测试项目成功生成 `database.g.dart` (12,501 bytes)
- DAO 文件也正常生成
- 代码生成过程无错误或警告

**后果:**
- 主项目的问题出在项目配置或文件结构上
- 无需降级 Drift 版本或寻求社区支持
- 应集中精力调查主项目的配置差异

### 决策 2: 下一步测试方向
**选择:** 测试文件位置假设 (Task 2)

**备选方案:**
1. ~~测试 Drift 版本降级~~ (已排除，Drift 本身无问题)
2. ✅ 测试文件位置深度 (最有可能的原因)
3. 测试文件命名约定 (备选)

**理由:**
- 最小测试: `lib/database.dart` (1 层深) → **成功**
- 主项目: `lib/features/accounting/data/database/app_database.dart` (4 层深) → **失败**
- 文件路径深度是最显著的差异

---

## 遇到的问题与解决方案

### 问题 1: 依赖版本差异
**症状:** pubspec.yaml 指定 `drift: ^2.14.0`，实际安装 `drift: 2.31.0`

**原因:** Caret (^) 版本约束允许次版本升级

**解决方案:** 接受最新版本 (2.31.0)，因为测试目标是验证 Drift 是否工作

**影响:** 无，测试依然有效

### 问题 2: 如何确认测试成功
**症状:** 需要明确的成功标准

**解决方案:**
- 关键文件 `database.g.dart` 必须生成
- 文件大小应该合理 (>10KB)
- 内容应包含 `part of 'database.dart'`

**验证结果:** ✅ 所有标准满足

---

## 测试验证

- [x] 最小项目创建成功
- [x] 依赖安装成功
- [x] 代码生成无错误
- [x] DAO .g.dart 文件生成
- [x] **database.g.dart 文件生成** ← **关键验证点**
- [x] 生成内容有效 (12,501 bytes)
- [x] 结果文档已创建
- [x] 文档已提交到主项目

---

## 关键发现与对比

### 最小测试 vs 主项目

| 维度 | 最小测试 (成功) | 主项目 (失败) |
|------|-----------------|---------------|
| **Database 文件路径** | `lib/database.dart` | `lib/features/accounting/data/database/app_database.dart` |
| **目录层级** | 1 层 | 4 层 |
| **文件名** | `database.dart` | `app_database.dart` |
| **表数量** | 1 (UsersTable) | 3 (TransactionsTable, BooksTable, TagsTable) |
| **DAO 数量** | 1 (UserDao) | 3 (TransactionDao, BookDao, TagDao) |
| **Drift 版本** | 2.31.0 | 2.31.0 |
| **结果** | ✅ 生成成功 | ❌ 生成失败 |

### 最可能的原因
🎯 **文件位置深度** (4 层 vs 1 层)

### 次要可能原因
- 文件命名 (`app_database.dart` vs `database.dart`)
- 项目复杂度 (多个 feature 模块)

---

## Git 提交记录

```bash
Commit: 66c226a
Author: 张欣 <xinz@zhangxindeMacBook-Pro.local>
Date: 2026-02-04 15:15

docs: document minimal Drift reproduction test result - PASSED

Task 1 of Drift blocker investigation completed successfully.

Key Findings:
- Minimal test project PASSES code generation
- database.g.dart generated correctly (12,501 bytes)
- Confirms Drift 2.31.0 works in isolation
- Problem is in Home Pocket project configuration, NOT Drift itself

Critical Differences Identified:
- Minimal: lib/database.dart (1 level deep)
- Main project: lib/features/accounting/data/database/app_database.dart (4 levels deep)
- File name: database.dart vs app_database.dart

Next Steps:
- Proceed to Task 2: Test file location hypothesis
- Most likely culprit: deeply nested file path

Test Location: /tmp/test_drift_minimal
Result: ✅ PASS - Drift code generation works correctly

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```

---

## 后续工作

### 立即执行 (Task 2)
- [ ] 在主项目中将 `app_database.dart` 移动到 `lib/` 目录
- [ ] 重新运行代码生成
- [ ] 验证 `database.g.dart` 是否生成

### 备选方案 (如果 Task 2 失败)
- [ ] Task 3: 测试文件命名假设 (重命名为 `database.dart`)
- [ ] Task 4: 测试 Drift 版本降级 (已不太可能需要)

### 最终后续
- [ ] 更新 MOD-001 实现计划
- [ ] 解除 Drift blocker
- [ ] 恢复 MOD-001 开发

---

## 参考资源

- **调查报告:** `doc/report/drift-blocker-problem-report.md`
- **最小测试项目:** `/tmp/test_drift_minimal`
- **Drift 文档:** https://drift.simonbinder.eu/
- **主项目 Database 文件:** `lib/features/accounting/data/database/app_database.dart`
- **MOD-001 规范:** `doc/arch/02-module-specs/MOD-001_BasicAccounting.md`

---

## 测试结果总结

**✅ PASS - Drift 代码生成在隔离环境下正常工作**

**关键结论:**
1. **Drift 本身无问题** - 不是 Drift 的 bug
2. **问题在主项目配置** - 需要调查文件结构差异
3. **文件位置深度** - 最有可能的原因 (4 层 vs 1 层)
4. **下一步明确** - 执行 Task 2 (文件位置假设测试)

**影响:**
- 节省了大量调试时间 (排除了 Drift bug 假设)
- 明确了调查方向 (配置问题，非版本问题)
- 无需降级 Drift 或寻求社区支持
- 预计可以快速解决 (移动文件位置即可)

---

**创建时间:** 2026-02-04 15:10
**作者:** Claude Sonnet 4.5
**总耗时:** ~25 分钟 (创建项目 + 代码生成 + 验证 + 文档)
