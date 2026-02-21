# ARCH-009: I18N 更新总结

**文档编号:** ARCH-009  
**文档版本:** 2.0  
**最后更新:** 2026-02-21  
**状态:** 生效中（迁移后）

---

## 1. 总结

国际化能力已从功能模块文档迁移到基础能力文档，并与当前代码结构对齐。

### 迁移结果

- `MOD-014_i18n.md`：本地文档已删除，Notion 标记为 `DEPRECATED_MOD-014_i18n`。
- i18n 规范主文档：`BASIC-003_I18N_Infrastructure.md`。

---

## 2. 当前能力清单

| 能力 | 代码位置 |
|---|---|
| Locale 状态模型 | `lib/infrastructure/i18n/models/locale_settings.dart` |
| 日期格式化 | `lib/infrastructure/i18n/formatters/date_formatter.dart` |
| 数字/货币格式化 | `lib/infrastructure/i18n/formatters/number_formatter.dart` |
| 运行时语言切换 | `lib/features/settings/presentation/providers/locale_provider.dart` |
| 翻译资源 | `lib/l10n/app_ja.arb`, `lib/l10n/app_zh.arb`, `lib/l10n/app_en.arb` |

---

## 3. 规则

1. 所有用户文案通过 `S.of(context)` 访问。  
2. 日期必须使用 `DateFormatter`。  
3. 货币必须使用 `NumberFormatter` 并传入 locale。  
4. ARB 修改后必须执行 `flutter gen-l10n`。

---

## 4. 关联文档

- 本地：`docs/arch/04-basic/BASIC-003_I18N_Infrastructure.md`
- 本地：`docs/arch/01-core-architecture/ARCH-001_Complete_Guide.md`
- Notion: [ARCH-009_I18N_Update_Summary](https://www.notion.so/30e0a19b391981a984e2f33fd9085a79)
- Notion: [BASIC-003_I18N_Infrastructure](https://www.notion.so/30e0a19b391981a9b66ccb5aff0c7f84)
