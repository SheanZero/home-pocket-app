# BASIC-004: Category 基础能力规范

**文档编号:** BASIC-004  
**文档版本:** 1.4  
**创建日期:** 2026-02-18  
**最后更新:** 2026-02-21  
**状态:** 生效中（基础能力规范）

---

## 1. 背景

分类能力原先散落在 `MOD-001/002` 等功能模块文档。现统一下沉为基础能力规范，作为记账、统计、双轨账本、家庭同步的共同契约。

---

## 2. 核心规则

1. Category 最大层级为 2（L1/L2），禁止 L3。  
2. 记账可直接选择 L1 或 L2。  
3. 统计口径固定按 L1 聚合。  
4. 分类结构可家庭共享；分类 ledger 类型为个人配置（L1 默认、L2 可覆盖）。  
5. 同名自动合并，近似名必须人工确认。

---

## 3. 数据边界

### 3.1 共享结构（可同步）

- `CategoryNode`: id、name、level、parentId、sortOrder、isArchived...

### 3.2 个人偏好（不共享）

- `CategoryLedgerPreference`（L1）
- `CategoryLedgerOverride`（L2）

---

## 4. 与代码的对应关系

| 能力 | 代码位置 |
|---|---|
| 分类显示映射（多语言） | `lib/infrastructure/category/category_service.dart` |
| 分类领域模型/仓储接口 | `lib/features/accounting/domain/models/category.dart`、`lib/features/accounting/domain/repositories/category_repository.dart` |
| 分类选择 UI | `lib/features/accounting/presentation/screens/category_selection_screen.dart` |

---

## 5. 迁移结果

- 已将“分类基础规则”从模块文档语义上迁移到 BASIC-004。
- `MOD-001_BasicAccounting` 仅保留业务流程与界面交互，不再定义分类基础契约。

---

## 6. 当前缺口

1. 近似名冲突阈值与确认流程需要在同步实现层落地（目前规范已定义，工程实现需对齐）。
2. 分类结构共享与个人类型覆盖的冲突回放测试需要补齐自动化用例。

---

## 7. 验收标准（保留）

1. 无法创建第 3 层分类。  
2. 记账可选 L1/L2 且保存成功。  
3. 统计聚合按 L1 生效。  
4. L1 类型必填，L2 可覆盖并可清除覆盖。  
5. 家庭同步同名自动合并、近似名弹出确认。  
6. 不同成员的分类类型设置互不覆盖。

---

## 8. 关联文档

- 本地：`docs/arch/02-module-specs/MOD-001_BasicAccounting.md`
- 本地：`docs/arch/02-module-specs/MOD-002_DualLedger.md`
- Notion: [BASIC-004_Category_PRD](https://www.notion.so/30e0a19b391981139e98e4c486f9f35c)
