# ARCH-001: Complete Guide（完整架构指南）

**文档编号:** ARCH-001  
**文档版本:** 3.0  
**创建日期:** 2026-02-03  
**最后更新:** 2026-02-21  
**状态:** 生效中（迁移后重构版）

---

## 1. 文档目标

本指南定义 Home Pocket v0.1.0 的当前架构真相源：

- 统一分层与依赖方向
- 明确“功能模块能力”与“基础能力”边界
- 同步本地文档与 Notion 文档命名
- 标记已迁移并废弃的模块文档

---

## 2. 系统定位

- 产品：本地优先、隐私优先的家庭记账应用
- 目标平台：iOS 14+ / Android 7+
- 当前阶段：Phase 1 Infrastructure

核心原则：

1. Local-first：默认离线可用，本地为主。  
2. Privacy by design：加密与最小暴露。  
3. Clean Architecture：清晰层次、依赖单向。  
4. Thin Feature：Feature 只承载业务逻辑与 UI，不承载基础设施。

---

## 3. 分层架构

### 3.1 层次与职责

- `lib/application/`: UI 页面、widgets、providers（UI 状态）。
- `lib/features/{feature}/`: 业务逻辑（Use Case、Domain model、Repository interface）。
- `lib/data/`: Drift tables、DAOs、Repository 实现。
- `lib/infrastructure/`: 技术能力（crypto/security/i18n/sync/ml/platform）。
- `lib/core/` + `lib/shared/`: 全局配置、路由、主题、公共组件。

### 3.2 依赖方向（强制）

`Application(UI) → Features(业务逻辑) ← Data ← Infrastructure`

补充约束：

- Domain 层必须独立，不依赖外部库。
- Feature 目录禁止出现 `infrastructure/`、`data/tables/`、`data/daos/`。
- Infrastructure 只能提供技术能力，不实现 feature 业务流程。

---

## 4. 迁移后能力版图

### 4.1 基础能力（BASIC）

| 文档 | 本地文件 | Notion |
|---|---|---|
| BASIC-001_Crypto_Infrastructure | `docs/arch/04-basic/BASIC-001_Crypto_Infrastructure.md` | [Link](https://www.notion.so/30e0a19b391981a8a47be7b84c0a899c) |
| BASIC-002_Security_Infrastructure | `docs/arch/04-basic/BASIC-002_Security_Infrastructure.md` | [Link](https://www.notion.so/30e0a19b391981db8528eeb4812833d5) |
| BASIC-003_I18N_Infrastructure | `docs/arch/04-basic/BASIC-003_I18N_Infrastructure.md` | [Link](https://www.notion.so/30e0a19b391981a9b66ccb5aff0c7f84) |
| BASIC-004_Category_PRD | `docs/arch/04-basic/BASIC-004_Category_PRD.md` | [Link](https://www.notion.so/30e0a19b391981139e98e4c486f9f35c) |

### 4.2 功能模块（MOD，保留）

| 模块 | 本地文件 | Notion |
|---|---|---|
| MOD-001_BasicAccounting | `docs/arch/02-module-specs/MOD-001_BasicAccounting.md` | [Link](https://www.notion.so/30e0a19b391981ad80b2ffe2b2e75406) |
| MOD-002_DualLedger | `docs/arch/02-module-specs/MOD-002_DualLedger.md` | [Link](https://www.notion.so/30e0a19b39198169a541cfbd131c9805) |
| MOD-003_FamilySync | `docs/arch/02-module-specs/MOD-003_FamilySync.md` | [Link](https://www.notion.so/30e0a19b3919812ea5f7ed1d6db56aee) |
| MOD-004_OCR | `docs/arch/02-module-specs/MOD-004_OCR.md` | [Link](https://www.notion.so/30e0a19b391981c3bf7ece5208450b90) |
| MOD-006_Analytics | `docs/arch/02-module-specs/MOD-006_Analytics.md` | [Link](https://www.notion.so/30e0a19b39198167ac45dcb3179a89c7) |
| MOD-007_Settings | `docs/arch/02-module-specs/MOD-007_Settings.md` | [Link](https://www.notion.so/30e0a19b391981378d5bfbbd30732514) |
| MOD-008_Gamification | `docs/arch/02-module-specs/MOD-008_Gamification.md` | [Link](https://www.notion.so/30e0a19b391981cf8aa7fecdc90f0e8e) |

### 4.3 已废弃模块（迁移到 BASIC）

| 原模块 | 处理结果 | Notion状态 |
|---|---|---|
| MOD-005_Security | 本地文档已删除，能力拆分到 BASIC-001/002 | `DEPRECATED_MOD-005_Security` |
| MOD-014_i18n | 本地文档已删除，能力迁移到 BASIC-003 | `DEPRECATED_MOD-014_i18n` |

---

## 5. 初始化架构

`runApp()` 前必须通过 `AppInitializer.initialize()` 完成：

1. KeyManager / MasterKey 初始化。  
2. SQLCipher 数据库 executor 初始化。  
3. 依赖数据库的 security provider override。  
4. 以 `UncontrolledProviderScope` 注入容器。

---

## 6. 安全与 i18n 的最新边界

### 6.1 Security

- 算法与密钥派生：BASIC-001。
- 平台认证与安全存储：BASIC-002。
- UI 引导/设置流程：对应 feature/application 层。

### 6.2 I18N

- Locale 模型与格式化：BASIC-003。
- 文案资源：`lib/l10n/*.arb` + `flutter gen-l10n`。
- 页面文本调用：统一 `S.of(context)`。

---

## 7. 质量门禁

提交前强制：

1. `flutter analyze` 零告警。  
2. `dart format .`。  
3. `flutter test` 全通过。  
4. 不提交生成文件（`.g.dart` / `.freezed.dart`）。

---

## 8. 快速导航

- 总索引：`docs/arch/01-core-architecture/ARCH-000_INDEX.md`
- ADR 索引：`docs/arch/03-adr/ADR-000_INDEX.md`
- Notion ARCH-001: [ARCH-001_Complete_Guide](https://www.notion.so/30e0a19b391981e29b7ee90c78058ebc)
