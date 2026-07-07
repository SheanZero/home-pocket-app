# Quick 260707-hb8 — HANDOFF（给一个干净的新 session）

## 为什么有这个文件
本 session 的工具执行层**间歇性 no-op**：Bash/Read/Edit/Write 在"坏窗口"里既不返回、也不落盘、还不报错。这是本 session 里 `gsd-executor` **两次"幻觉完成"**（编造 commit hash + 编造 grep 证据，实际零改动）以及我自己 Edit no-op 的**共同根因**——不是权限、不是模型撒谎，是环境。故换干净 session 重来，此文件是接力包。

## 现状（git 确证，可靠）
- 工作区**完全干净**：`HEAD=6a517ec4`，零 hb8 改动，零非 doc 未提交改动，无任何半成品
- PLAN 完好在磁盘：`260707-hb8-PLAN.md`（3 tasks）
- init 数据：quick_id `260707-hb8`，`use_worktrees=false`（直接在 main 顺序原子 commit），branch=main

## Scope & 方向（用户已锁定，勿重议）
- **B**：只做 P2-1（搜索防抖）+ P2-3（成员聚合下沉）；**P2-2 分页明确排除**（另排正式 phase）
- **C**：对齐声明 + 补 `*→data` 测试 + 只修真违规（**不无差别重构**）

## 超出 PLAN 的关键洞察（这一路挖的，务必带上）

### Task 1 / P2-1（B 搜索）
- searchQuery **已是纯内存过滤**（`state_list_transactions.dart` Step 6b, :103-120）；真浪费是 `:40 ref.watch(listFilterProvider)` watch **整个**对象 → searchQuery 一变 → 整个 provider 重建 → Step 4 SQL + 全行 ChaCha20 解密白跑
- 修法：**分层**，SQL 层 `ref.watch(listFilterProvider.select((f) => f.copyWith(searchQuery: '')))` 对 search 免疫（**行为等价**，因 SQL 本就不含 searchQuery）；debounce 300ms 加在 `list_sort_filter_bar.dart:337` 的 onChanged（`_searchController:35`、`dispose:41`；clear at :370 保持**即时**不 debounce）
- notifier: `state_list_filter.dart`（`@Riverpod(keepAlive:true) ListFilter`，`setSearch` :67）
- 改 @riverpod 新 provider → 要 `build_runner`

### Task 1 / P2-3（B 成员聚合）
- `memberFilteredCategoryBreakdown`（`state_analytics.dart:102`）走 `transactionRepository.findByBookIds` 拉全行 Dart 循环累加，**不是** `getCategoryTotals`
- 下沉**三层**：`AnalyticsDao` 加带 `deviceId` 的聚合方法（`analytics_dao.dart`，参照 `getCategoryTotalsByLedger`:201 / `getMemberSpending`:360）→ `AnalyticsRepository` 接口+impl → provider 改用它
- 铁律：必保 `type='expense'` 过滤（memory: analytics reuse trap，findByBookIds 返回所有 tx 类型）+ `deviceId=null` 字节等价 + **数值与旧 Dart 循环一致**（回归风险点）

### Task 2 / C 架构测试（低风险，已想清）
- `application→data` 全库**仅 5 处**：`accounting/profile/currency/analytics` 四个 `repository_providers.dart`（组合根，**合法**）+ `demo_data_service.dart`（真违规）
- 规则加到 `test/architecture/layer_import_rules_test.dart` 的 `_rules`（:85 起，在 domain 规则后）：
  ```dart
  _Rule(
    'application (non composition-root) must not depend on the data layer',
    (f) => f.startsWith('lib/application/') && !f.endsWith('_providers.dart'),
    (t) => t.startsWith('lib/data/'),
  ),
  ```
  这样**只抓 demo，不误伤 4 个组合根**（`_allowlist` 机制在 :28）

### ⚠️ demo_data_service 重构 = 高风险，建议改为正式豁免（需用户拍板）
- `TransactionRepositoryImpl.insert` **不自动算 hash chain**（直接透传 `currentHash/prevHash`）→ 重构要为 130 行逐条插入手工构造完整 `Transaction` domain 对象 + enum 转换（'income'→TransactionType / 'daily'→LedgerType）+ hash 链维护
- `_setBudgets` 走 `_db.customUpdate` 直接 SQL，`CategoryRepository` **无 budget 更新方法** → 重构它要么再动接口（波及所有 impl/mock，触发 invalid_override）要么另辟蹊径
- **0 测试覆盖**，无保护网
- **决策点**：正式豁免（加入 `_allowlist` :28 + 明确理由注释）vs 重构。**建议豁免**——它是非生产的演示/截图数据生成器（"invoked only from a debug affordance"）。用户原本选"重构真违规"，但那是在不知道上述复杂度时定的，值得复核。

### Task 3 / C yaml + 文档（低风险）
- deny-mode `import_guard.yaml` 加 `# INERT: relative imports bypass package: prefix; enforced by layer_import_rules_test.dart`（不删规则，保留意图）+ 组合根 allow
- 补 `lib/features/applock/import_guard.yaml` + `lib/features/onboarding/import_guard.yaml`（参照 `lib/features/accounting/import_guard.yaml` / `settings/`）
- CLAUDE.md Pitfall #2 措辞：标注 `layer_import_rules_test.dart` 是 `*→data` 与其它方向的**实际**执法点

## 验证铁律（orchestrator 亲跑，别信 scoped）
- 全量 `flutter analyze` 0 + 全量 `flutter test` 绿 + `dart run custom_lint` 0
- **不要** tail flutter test（mask exit code）；每步 `git` 核验（本项目 scoped verify 反复漏：invalid_override / boot-provider gap）
- **不要用 `gsd-executor` subagent** 除非确认新环境工具稳定——本 session 它两次幻觉。orchestrator 亲自实现 + 逐步 git 核验最稳。
- `use_worktrees=false`，直接在 main 顺序原子 commit（`perf` / `refactor` / `chore` 前缀，quick-260707-hb8）

## 建议启动
```
/gsd-quick resume 260707-hb8-b-list-search-debounce-member-aggregate-sql-pushdo
```
或直接按本文件 + PLAN 自己实现（工具正常时一两轮可完）。第一步先跑 `git status` 确认工作区仍干净（`6a517ec4`）。
