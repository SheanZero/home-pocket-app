# AGENTS.md — Home Pocket (まもる家計簿)

> Local-first, privacy-focused family accounting app with dual-ledger system.
> Phase 1 Infrastructure Layer (v0.1.0) · Flutter · iOS 14+ / Android 7+

---

## Architecture

**Clean Architecture (5 Layers) + "Thin Feature" Rule:**

- `lib/infrastructure/` — 技术基础设施（crypto, ML, sync, i18n, security, platform）
- `lib/features/{feature}/` — 业务逻辑 Use Cases + domain models + repository interfaces
- `lib/application/` — UI 层 (screens, widgets, providers)
- `lib/data/` — 所有 Drift tables, DAOs, repository 实现（跨功能共享）
- `lib/core/` — config, router, theme, constants, AppInitializer
- `lib/shared/` — 公共 widgets, extensions, utils

**关键约束 / Key Constraints:**
- Feature 目录包含业务逻辑，禁止包含 `infrastructure/`, `data/tables/`, `data/daos/`
- Features contain business logic; NEVER contain infrastructure/, data/tables/, data/daos/
- 依赖方向 / Dependency direction: Application(UI) → Features(业务逻辑) ← Data ← Infrastructure
- Domain 层完全独立，无外部依赖 / Domain layer is completely independent

**能力分类决策树 / Capability Classification Decision Tree:**
1. 技术/平台能力? Technology/platform capability? → `lib/infrastructure/`
2. 业务逻辑/Use Case/Domain models? → `lib/features/{feature}/`
3. 数据访问 (tables, DAOs, repo impl)? Data access? → `lib/data/`
4. UI (screens, widgets, providers)? → `lib/application/`
5. 不确定? Not sure? → 放 `lib/` 对应层级 (safer, easier to refactor)

---

## Build & Dev Commands

```bash
flutter pub get                                              # 安装依赖
flutter pub run build_runner build --delete-conflicting-outputs  # 代码生成
flutter pub run build_runner watch                           # 持续生成
flutter gen-l10n                                             # 国际化
flutter run [-d <device_id>]                                 # 运行
flutter analyze                                              # 静态分析 (必须 0 warnings)
dart format .                                                # 格式化
flutter test                                                 # 全部测试
flutter test --coverage                                      # 覆盖率 (≥80%)
flutter test integration_test/                               # 集成测试
```

**代码生成触发时机 / Code generation triggers:**
修改 `@riverpod`/`@freezed`/Drift tables/ARB 文件后必须运行 build_runner。
After modifying @riverpod/@freezed/Drift tables/ARB files, MUST run build_runner.

**Git 操作后 / After git operations** (merge/rebase/switch branch) 也必须重新生成。
MUST regenerate after merge/rebase/branch switch.

---

## Coding Patterns

### State Management
- **Riverpod 2.4+** with `@riverpod` code gen
- **Freezed** for immutable models (`copyWith`, 禁止 mutation / mutation forbidden)
- **Drift** + SQLCipher (加密数据库 / encrypted database)
- **GoRouter** declarative routing

### Provider 组织规则 / Provider Organization Rules
- 每个功能模块一个 `repository_providers.dart`（单一来源）
  One `repository_providers.dart` per module (single source of truth)
- Use Case providers 在 `lib/features/` 中定义，UI providers 在 `lib/application/` 中引用
  Use Case providers defined in features/, UI providers reference them in application/
- 禁止重复定义 repository provider
  NEVER duplicate repository provider definitions

### Widget 参数模式 / Widget Parameter Pattern
- 使用 nullable 参数 + provider fallback，禁止硬编码默认值
  Use nullable params + provider fallback, NEVER hardcode defaults
- 优先级 / Priority: 显式参数 explicit > 当前选择 current selection > 用户默认 user default > null

---

## Security (4-Layer Encryption / 4层加密)

1. **Database:** SQLCipher AES-256-CBC (256k PBKDF2)
2. **Field:** ChaCha20-Poly1305 AEAD
3. **File:** AES-256-GCM (photos)
4. **Transport:** TLS 1.3 + E2EE (P2P sync)

**强制规则 / Mandatory Rules:**
- 所有加密操作必须使用 `lib/infrastructure/crypto/`
  All crypto operations MUST use `lib/infrastructure/crypto/`
- 禁止直接访问 flutter_secure_storage
  NEVER access flutter_secure_storage directly for keys
- 敏感字段必须加密 (amounts, notes, merchant names)
  Sensitive fields MUST be encrypted
- 禁止明文存储密钥或日志记录敏感数据
  NEVER store keys in plaintext or log sensitive data
- 使用 `sqlcipher_flutter_libs`，禁止 `sqlite3_flutter_libs`
  Use sqlcipher_flutter_libs, NEVER sqlite3_flutter_libs

---

## Initialization / 初始化

必须在 `runApp()` 前通过 `AppInitializer.initialize()` 初始化:
MUST initialize before runApp() via AppInitializer.initialize():

1. KeyManager（加载/生成设备密钥 / load or generate device keys）
2. Database（加密数据库就绪 / encrypted DB ready）
3. 其他服务 / Other services

使用 `UncontrolledProviderScope` 传递已初始化的 container。
Use UncontrolledProviderScope to pass initialized container.

---

## i18n (ja/zh/en)

- 所有用户文本用 `S.of(context)`，禁止硬编码
  All user text via S.of(context), NEVER hardcode strings
- 日期用 `DateFormatter`，货币用 `NumberFormatter`（传 locale）
  Dates via DateFormatter, currency via NumberFormatter (pass locale)
- 修改 ARB 后必须更新全部 3 个文件 + 运行 `flutter gen-l10n`
  After ARB changes, update all 3 files + run flutter gen-l10n
- JPY: 0 位小数 / 0 decimals; USD/CNY/EUR/GBP: 2 位小数 / 2 decimals

---

## Drift Database Indexes / Drift 数据库索引

- 使用 `TableIndex` (非 `Index`) / Use TableIndex (not Index)
- Symbol 语法 / Symbol syntax: `columns: {#columnName}`
- 不加 `@override` / No @override annotation
- 命名 / Naming: `idx_{table}_{columns}`

---

## Testing (TDD)

1. RED: 先写测试 / Write test first
2. GREEN: 最小实现 / Minimal implementation
3. IMPROVE: 重构 / Refactor
4. 覆盖率 ≥80% / Coverage ≥80%

测试目录 / Test directories: `test/unit/`, `test/widget/`, `test/infrastructure/`, `integration_test/`

---

## Codex Branch Rule (MANDATORY)

- **All Codex development MUST be done on the `codex-dev` branch.**
- Before starting any work, check out `codex-dev`: `git checkout codex-dev` (create if not exists: `git checkout -b codex-dev`).
- NEVER commit directly to `main` from Codex.
- After work is complete, changes on `codex-dev` will be reviewed and merged to `main` manually.

---

## Git Workflow

```
<type>(<scope>): <description>

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```

Types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`
Branches: `main` (stable), `feature/MOD-XXX-description`, `codex-dev` (Codex exclusive)

---

## Pre-Commit Checklist / 提交前检查

- [ ] `flutter analyze` → 0 issues
- [ ] `dart format .`
- [ ] `flutter test` → all pass
- [ ] 不提交生成文件 / Don't commit generated files (`.g.dart`, `.freezed.dart`)
- [ ] 不使用 `// ignore:` 压制警告 / Don't suppress warnings with // ignore:

---

## Architecture Docs / 架构文档

路径 / Path: `doc/arch/` (01-core-architecture, 02-module-specs, 03-adr)

添加新文档前必须检查最大编号，使用下一个序号，更新 INDEX.md。
Before adding new docs, check max number, use next sequential, update INDEX.md.

---

## iOS Build Notes / iOS 构建说明

- 使用 `sqlcipher_flutter_libs`（禁止 `sqlite3_flutter_libs`）
- Podfile 需保留 ML Kit simulator EXCLUDED_ARCHS fix
- 遇到问题 / Troubleshooting:
  `flutter clean && cd ios && rm -rf Pods Podfile.lock .symlinks && cd .. && flutter pub get && cd ios && pod install`

---

## Development Phase / 开发阶段

**当前 / Current: Phase 1 Infrastructure (v0.1.0)**
- MOD-006 Security & Privacy → MOD-014 i18n → MOD-001 Basic Accounting → ...

详见 / See: `doc/worklog/PROJECT_DEVELOPMENT_PLAN.md`
