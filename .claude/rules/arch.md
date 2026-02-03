# Claude Code Rules for Home Pocket Project

## 开发前必读规则 (CRITICAL)

**在开始任何功能开发之前，MUST 遵循以下步骤：**

1. **Review 架构文档 (doc/arch/)**
   - 阅读相关的 ARCH 文档（整体架构）
   - 阅读相关的 MOD 文档（模块规范）
   - 阅读相关的 ADR 文档（架构决策）

2. **Review 需求文档**
   - 检查 PRD (Product Requirements Document)
   - 检查 BRD (Business Requirements Document)
   - 检查开发计划 (PROJECT_DEVELOPMENT_PLAN.md)

3. **确认理解后再开始编码**
   - 确保理解架构约束和设计模式
   - 确保理解模块接口和依赖关系
   - 确保理解技术决策的上下文和后果

**违反此规则的后果：**
- 可能违反架构设计原则
- 可能引入不一致的实现
- 可能需要大量返工

---

## 架构文档管理规则 (doc/arch/)

### 目录结构

```
doc/arch/
├── 01-core-architecture/    # 整体架构文档
├── 02-module-specs/          # 模块功能架构文档
├── 03-adr/                   # 架构决策记录 (ADR)
└── README.md                 # 总索引
```

### 文件命名规则

#### 1. 整体架构文档 (01-core-architecture/)
- **格式:** `ARCH-{编号}_{名称}.md`
- **编号规则:** 3位数字（000-999），从 000 开始，按创建顺序递增
- **编号 000:** 保留给索引文件 `ARCH-000_INDEX.md`
- **命名规范:** 名称使用 PascalCase（每个单词首字母大写），单词间用下划线连接
- **示例:**
  - `ARCH-000_INDEX.md` - 架构文档总索引
  - `ARCH-001_Complete_Guide.md` - 完整架构指南
  - `ARCH-002_Data_Architecture.md` - 数据架构
  - `ARCH-003_Security_Architecture.md` - 安全架构

#### 2. 模块功能架构文档 (02-module-specs/)
- **格式:** `MOD-{编号}_{模块名称}.md`
- **编号规则:** 3位数字（001-999），从 001 开始，按模块开发优先级排序
- **命名规范:** 模块名称使用 PascalCase，反映模块的核心功能
- **示例:**
  - `MOD-001_BasicAccounting.md` - 基础记账模块
  - `MOD-002_DualLedger.md` - 双轨账本模块
  - `MOD-003_FamilySync.md` - 家庭同步模块
  - `MOD-004_OCR.md` - OCR扫描模块

#### 3. 架构决策记录 (03-adr/)
- **格式:** `ADR-{编号}_{决策主题}.md`
- **编号规则:** 3位数字（000-999），从 000 开始，按决策时间顺序递增
- **编号 000:** 保留给索引文件 `ADR-000_INDEX.md`
- **命名规范:** 决策主题使用 PascalCase，简洁描述决策内容
- **示例:**
  - `ADR-000_INDEX.md` - ADR 总索引
  - `ADR-001_State_Management.md` - 状态管理方案决策
  - `ADR-002_Database_Solution.md` - 数据库解决方案决策
  - `ADR-003_Multi_Layer_Encryption.md` - 多层加密策略决策

### 添加新文档的工作流程

当需要添加新的架构文档时，**必须**按照以下步骤操作：

#### Step 1: 确定文档类型
确定新文档属于哪个类别：
- 整体架构文档 (ARCH-)
- 模块功能文档 (MOD-)
- 架构决策记录 (ADR-)

#### Step 2: 检查当前文件编号
**重要:** 在创建新文档之前，必须先检查对应目录下的现有文件，确定最大编号。

```bash
# 检查整体架构文档的最大编号
ls -1 doc/arch/01-core-architecture/ARCH-*.md | sort | tail -1

# 检查模块功能文档的最大编号
ls -1 doc/arch/02-module-specs/MOD-*.md | sort | tail -1

# 检查 ADR 文档的最大编号
ls -1 doc/arch/03-adr/ADR-*.md | sort | tail -1
```

#### Step 3: 分配新编号
使用 `最大编号 + 1` 作为新文档的编号，确保编号连续，避免重复。

**示例:**
- 如果最大编号是 `ARCH-009`，新文档应该使用 `ARCH-010`
- 如果最大编号是 `MOD-009`，新文档应该使用 `MOD-010`
- 如果最大编号是 `ADR-007`，新文档应该使用 `ADR-008`

#### Step 4: 创建文档
按照命名规则创建新文档文件。

#### Step 5: 更新索引文件
在对应目录的 `*-000_INDEX.md` 文件中添加新文档的索引条目。

### 文档内容规范

每个架构文档应包含以下标准章节：

#### 文档头部信息
```markdown
# 文档标题

**文档编号:** ARCH-XXX / MOD-XXX / ADR-XXX
**文档版本:** 1.0
**创建日期:** YYYY-MM-DD
**最后更新:** YYYY-MM-DD
**状态:** 草稿 / 审核中 / 已批准 / 已实施 / 已废弃
**作者:** [作者名称]
```

#### 架构文档 (ARCH-) 必需章节
1. 概述 (Overview)
2. 技术栈 (Tech Stack)
3. 架构设计 (Architecture Design)
4. 实现细节 (Implementation Details)
5. 测试策略 (Testing Strategy)
6. 参考资源 (References)

#### 模块文档 (MOD-) 必需章节
1. 模块概述 (Module Overview)
2. 功能需求 (Requirements)
3. 技术设计 (Technical Design)
4. 接口定义 (Interface Definition)
5. 数据模型 (Data Model)
6. 实现示例 (Implementation Examples)
7. 测试用例 (Test Cases)
8. 开发时间估算 (Time Estimation)

#### ADR 文档必需章节
1. 标题和编号
2. 状态 (Status)
3. 背景 (Context)
4. 考虑的方案 (Considered Options)
5. 决策 (Decision)
6. 决策理由 (Rationale)
7. 后果 (Consequences)
8. 实施计划 (Implementation Plan)

### 文档更新规则

1. **小改动:** 直接修改文档，更新版本号的修订版（如 1.0 → 1.1）
2. **重大改动:** 更新版本号的主版本（如 1.x → 2.0）
3. **文档废弃:** 不删除文件，在文档头部添加 `[已废弃]` 标记，并注明替代文档

### 禁止操作

❌ **禁止手动指定编号** - 必须基于现有文件的最大编号分配
❌ **禁止跳号** - 编号必须连续递增
❌ **禁止重复编号** - 创建前必须检查现有编号
❌ **禁止删除已有编号的文档** - 只能标记为废弃
❌ **禁止使用非标准命名格式** - 必须严格遵循命名规则

### Claude 执行规范

当收到添加或更新架构文档的请求时：

1. ✅ **必须先执行:** 使用 `ls` 或 `find` 命令列出对应目录下的现有文件
2. ✅ **必须分析:** 确定当前最大编号是多少
3. ✅ **必须验证:** 确认新编号不会与现有编号冲突
4. ✅ **必须更新:** 创建文档后，同步更新对应的 INDEX.md 文件
5. ✅ **必须检查:** 完成后，列出目录内容验证文件创建成功

### 示例工作流

```bash
# 示例：添加新的 ADR 文档

# Step 1: 检查现有 ADR 文档
ls -1 doc/arch/03-adr/ADR-*.md

# 输出:
# doc/arch/03-adr/ADR-000_INDEX.md
# doc/arch/03-adr/ADR-001_State_Management.md
# ...
# doc/arch/03-adr/ADR-007_Layer_Responsibilities.md

# Step 2: 确定最大编号是 007
# Step 3: 新文档使用编号 008
# Step 4: 创建文档 ADR-008_New_Decision.md
# Step 5: 更新 ADR-000_INDEX.md

# Step 6: 验证
ls -1 doc/arch/03-adr/ADR-*.md
```

### 版本控制

- 所有架构文档变更必须通过 Git 进行版本控制
- 提交信息格式：`docs(arch): 简短描述`
  - 示例: `docs(arch): add ADR-008 for authentication strategy`
  - 示例: `docs(arch): update ARCH-002 data architecture`
  - 示例: `docs(arch): deprecate ADR-003 in favor of ADR-010`

---

**规则版本:** 2.0
**创建日期:** 2026-02-03
**最后更新:** 2026-02-03
**更新内容:**
- 迁移架构文档目录从 arch2/ 到 doc/arch/
- 添加开发前必读规则（CRITICAL）
**适用范围:** doc/arch/ 目录下的所有架构文档
