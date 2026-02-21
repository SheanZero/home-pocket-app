# BASIC-003: 国际化基础设施 (I18N Infrastructure)

**文档编号:** BASIC-003  
**文档版本:** 1.1  
**创建日期:** 2026-02-06  
**最后更新:** 2026-02-21  
**状态:** 已实施（v0.1.0）

---

## 1. 目标与边界

本文件定义 Home Pocket 国际化基础能力：语言状态模型、本地化格式化、翻译资源生成规则。

### 1.1 本文档覆盖

- `LocaleSettings`（基础 Locale 状态模型）
- `DateFormatter` / `NumberFormatter`
- `locale_provider`（运行时切换）
- `flutter gen-l10n` 工作流

### 1.2 不在本文档范围

- 具体页面文案设计与产品语义
- 模块业务逻辑（如分类、账本规则）

---

## 2. 当前实现状态（与代码一致）

| 能力 | 状态 | 代码位置 |
|---|---|---|
| LocaleSettings | 已实施 | `lib/infrastructure/i18n/models/locale_settings.dart` |
| DateFormatter | 已实施 | `lib/infrastructure/i18n/formatters/date_formatter.dart` |
| NumberFormatter | 已实施 | `lib/infrastructure/i18n/formatters/number_formatter.dart` |
| Runtime locale provider | 已实施 | `lib/features/settings/presentation/providers/locale_provider.dart` |
| ARB 三语资源 | 已实施 | `lib/l10n/app_{ja,en,zh}.arb` |

---

## 3. 从功能模块迁移后的对齐结果

来源文档：`MOD-014_i18n.md`（已废弃）。

| 原模块能力 | 当前归属 |
|---|---|
| Locale 状态模型与切换 | BASIC-003 |
| 日期/数值/货币格式化 | BASIC-003 |
| ARB 维护与生成流程 | BASIC-003 |

结论：i18n 能力已经基础化，`MOD-014` 不再作为独立功能模块保留。

---

## 4. 强制规范

- 所有用户可见文本必须使用 `S.of(context)`。
- 日期格式必须使用 `DateFormatter`。
- 货币和数字格式必须使用 `NumberFormatter`，并显式传入 locale。
- 修改 ARB 后必须执行 `flutter gen-l10n`。

---

## 5. 当前缺口与后续建议

### 5.1 语言偏好持久化尚未落地

`LocaleNotifier` 当前在运行期内生效，但未落地到持久层。建议新增 `LocalePreferenceRepository` 或直接在设置模块中调用安全/本地存储。

### 5.2 动态 key 文本解析限制

Flutter 生成的 `S` 不支持动态 key 反射，因此类别等动态映射由 `CategoryService` 维护静态映射表（见 `lib/infrastructure/category/category_service.dart`）。

### 5.3 文案治理机制可补强

建议建立 ARB key lint（重复 key、遗漏 key、跨语言不一致检查）。

---

## 6. 关联文档

- 本地：`docs/arch/04-basic/BASIC-004_Category_PRD.md`
- 本地：`docs/arch/01-core-architecture/ARCH-009_I18N_Update_Summary.md`
- Notion: [BASIC-003_I18N_Infrastructure](https://www.notion.so/30e0a19b391981a9b66ccb5aff0c7f84)
