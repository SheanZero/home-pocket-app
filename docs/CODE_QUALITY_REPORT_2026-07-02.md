# Home Pocket 代码质量报告

**日期:** 2026-07-02
**范围:** `lib/` 全部手写代码（455 文件 / ~67k 行，不含生成文件）+ `test/`（428 文件）+ CI 配置 + 平台配置
**方法:** 6 个独立维度并行审查（架构分层 / 代码质量 / 安全加密 / 测试体系 / i18n 与 UI / 数据层与性能），叠加 `flutter analyze` 与全量 `flutter test` 基线验证。所有发现均带 file:line 证据，未经证实的猜测不收录。

---

## 修复状态（2026-07-05 更新）

**P0 与 P1 全部修复完毕**，每项独立提交、TDD（失败测试先行）、修复后全量 `flutter test` **3561/3561 通过**、`flutter analyze` 0 issues：

| 项 | 状态 | Commit | 备注 |
|---|---|---|---|
| P0-1 kDebugMode 守卫 | ✅ 已修 | `3bc599b5` | 报告发布当日已单独修复，main 回绿 |
| P0-2 备份恢复非原子 | ✅ 已修 | `f422c78e` | 新增 `UnitOfWork` domain 抽象（data 层 Drift 事务实现）；restore 与 clear-all 均事务化，real-DB 回滚测试守护 |
| P1-1 索引缺失 19+6 | ✅ 已修 | `2cb07b08` | schemaVersion 22→23，`_createAllDeclaredIndexes()` 同挂 onCreate 与 from<23；新守卫测试从源码解析 TableIndex 声明逐一对账 sqlite_master |
| P1-4 v≤6 groups 迁移缝隙 | ✅ 已修 | `2cb07b08` | `createTable(groups)` 条件放宽为 `from < 8`（sync_queue 重建保持 v7-only 守卫）；配手搭 v6 schema 的真实 v6→v23 全链条迁移测试 |
| P1-3 备份加密自实现 + KDF 弱 | ✅ 已修 | `84eb8f7a` | 新 `BackupCryptoService`（infrastructure/crypto）：Argon2id（OWASP 参数，同 pin_kdf）+ 版本化自描述文件头；旧 PBKDF2 100k `.hpb` 保持可导入（自动识别）；恶意头参数有上限 |
| P1-2 import_guard 失效 + 反向依赖 | ✅ 已修 | `e811a219` | 新 `layer_import_rules_test.dart` 扫描真实 import（相对路径归一化）；appLockService/seedAllUseCase 接线各归位组合根；**额外发现并修复第 3 处反向依赖**（`RateResult` 从 application/currency 移入 currency domain）；CLAUDE.md 不实的 Structurally enforced 标注已更正 |

P1-2 的 yaml 侧（deny-mode pattern 补相对路径形式、组合根 DAO import 的 allow 例外）未随本轮修改——`layer_import_rules_test` 已成为实际执法点，yaml 对齐留作 P2 级清理项。

---

## 1. 总体结论

**总评：B+。** 这是一个纪律性很强的代码库：Domain 层纯净度、provider 组合根模式、i18n 三语对齐、颜色 token 化、mock 策略统一、`// ignore:` 零容忍——这些在同规模 Flutter 项目里都属于少见的执行水准。16 个架构守卫测试把规则变成了可执行断言，是全项目最亮眼的工程实践。

但存在 **1 个 P0 数据安全隐患**（备份恢复先删后插、无事务，中途失败即数据丢失）和 **1 组 P1 性能硬伤**（35 个声明索引中 19 个从未真正创建，包括 transactions 表全部 6 个），以及 **1 个执法体系漏洞**（import_guard 的 deny 规则被相对 import 整体绕过，CLAUDE.md 中多条 "Structurally enforced" 声明实际未生效）。另外 main 分支当前有 1 个失败测试。

| 维度 | 评级 | 一句话 |
|---|---|---|
| 架构与分层 | B+ | Domain 零违规、组合根统一；但守卫执法有洞，存在 2 处反向层依赖 |
| 代码质量 | B+ | 零 `// ignore:`、日志纪律好；4 个超大 UI 文件待拆 |
| 安全与加密 | A- | 密钥/PIN/注入/日志全部验证通过；备份加密偏离 crypto 层规范 |
| 测试体系 | A- | 3492 用例、16 个架构守卫、0 skip；覆盖率门槛降级未回收、真机 E2E 仅 1 条 |
| i18n 与 UI | A- | 737 key 三语零缺口、0 硬编码色值；6 处 joy 文字色违反对比度规则 |
| 数据层与性能 | C+ | 索引大面积缺失 + 恢复非原子是硬伤；SQL 聚合下沉与注入防护做得好 |

---

## 2. 基线验证（2026-07-02 实测）

| 检查 | 结果 |
|---|---|
| `flutter analyze` | ✅ 0 issues |
| `flutter test`（全量） | ❌ **3492 通过 / 1 失败** |
| 失败用例 | `test/architecture/production_logging_privacy_test.dart` — `lib/features/settings/presentation/widgets/legal_sponsor_section.dart:50` 的 `debugPrint` 未包 `kDebugMode` 守卫（commit `1ef10af6` IN-03 修复引入的回归） |

---

## 3. 问题清单（按优先级）

### P0 — 立即处理

**P0-1. main 分支测试红：日志隐私守卫失败**
`lib/features/settings/presentation/widgets/legal_sponsor_section.dart:50`
`debugPrint('sponsor launch failed: $e')` 是全库 52 处 debugPrint 中唯一未包 `kDebugMode` 的一处，触发 `production_logging_privacy_test` 失败。修复是一行事：包上 `if (kDebugMode)`。

**P0-2. 备份恢复非原子——中途失败即不可恢复的数据丢失**
`lib/application/settings/import_backup_use_case.dart:131-160`
`_restoreData` 先 `deleteAllByBook` / `categoryRepo.deleteAll()` / `bookRepo.deleteAll()` 删光现有数据，再对 books/categories/transactions 逐条 `for + await insert`，全程无 `transaction()` 包裹。损坏或恶意构造的备份文件中任一行 `fromJson`/insert 抛异常，就会留下"旧数据已删、新数据只有一半"的状态且无法回滚。逐条 insert 还意味着每行一次独立隐式事务（每行 fsync），大备份导入极慢。
**建议：** 整个 `_restoreData` 包进一个 Drift `transaction()`，插入改 `batch.insertAll`。同类问题（较轻）：`clear_all_data_use_case.dart:29-56` 的全量清除同样无事务。

### P1 — 高优先级

**P1-1. 35 个声明索引中 19 个从未创建，另 6 个新装机缺失**
`lib/data/tables/transactions_table.dart:60-67`、`lib/data/app_database.dart`
Drift 的 `customIndices` getter 是装饰性的（Phase 36 CR-01 已知教训），但补救只回填到了 Phase 36 之后的新表（shopping_items / exchange_rates / merchants），存量表从未反向补齐：

| 缺失类型 | 涉及 |
|---|---|
| 任何路径都未创建（19 个） | **transactions 全部 6 个**（含 idx_tx_book_timestamp 等热查询索引）、books 4、categories 3、group_members 2、groups 1、sync_queue 1、category_keyword_preferences 1、merchant_category_preferences 1 |
| 仅升级路径创建、新装机缺失（6 个） | audit_logs 3、user_profiles 1、category_ledger_configs 2（只在 `from < 15` 等迁移步里 CREATE，onCreate 不建——升级老用户反而比新装用户索引更全） |

交易列表、日历、分析页的核心查询全部落在无索引的 transactions 表上。
**建议：** 提炼 `_createAllIndexes()` helper，同时挂 onCreate 与一个 `from < 23` 迁移步（配合 schemaVersion 22→23），一次性补齐 25 条 CREATE INDEX。

**P1-2. import_guard 执法漏洞：deny 规则被相对 import 整体绕过**
影响全局（39 个 import_guard.yaml 中约 12 个 deny-mode 失效）
import_guard 的 deny pattern 以 `package:` 前缀做原样字符串匹配，而项目强制 `prefer_relative_imports: true`——相对 import 永远不会命中 `package:` 前缀，因此所有 deny-only 守卫对项目内 import **完全不生效**。CI 的 `dart run custom_lint` 一直是绿的，但下面这些真实违规都是带着相对 import 穿过守卫的：
- `lib/infrastructure/security/providers.dart:5-7` — Infrastructure → Application/Presentation 反向依赖（import settings 的 repository_providers）
- `lib/application/seed/seed_providers.dart:3` — Application → Presentation 反向依赖
- 13 处 presentation 组合根 import `data/daos/`（与其自身 yaml 的 deny 声明直接矛盾）

**建议：** ① 守卫 yaml 补相对路径 pattern，或升级 lint 先把相对 import 归一化为 package URI；② 新增一个不依赖 yaml/custom_lint、直接扫描 import 语句并归一化路径的分层架构测试；③ 修正上述 2 处反向依赖（appLockService 接线移到 application 或 feature 侧；seedAllUseCase 接线移到 accounting presentation）；④ 13 处组合根 DAO import 属既定模式，给 providers/ 目录加 allow 例外使声明与现实一致；⑤ 同步修正 CLAUDE.md 中不实的 "Structurally enforced" 标注。

**P1-3. 备份加密自实现在 application 层，KDF 强度偏低**
`lib/application/settings/export_backup_use_case.dart:116-154`、`import_backup_use_case.dart:94-129`
PBKDF2 + AES-256-GCM 整套加密（含手拼 `salt+nonce+ciphertext+mac` 二进制格式）直接写在两个 use case 里且互相重复，违反"所有 crypto 操作必须走 `lib/infrastructure/crypto/`"铁律。且 PBKDF2 仅 100,000 次迭代——低于 OWASP 现行建议（600k），也低于项目自身 SQLCipher 的 256k；`.hpb` 文件会经 share sheet 离开设备，离线暴破正是其威胁模型，而密码下限只有 8 字符。
**建议：** 抽成 `infrastructure/crypto/services/backup_crypto_service.dart`；迭代升至 ≥600k 或改用 Argon2id（项目已有 `pin_kdf.dart` 先例）；文件头加 KDF 参数/版本字节以便未来迁移。

**P1-4. 迁移链缝隙：v≤6 数据库升级后永远没有 groups 表**
`lib/data/app_database.dart:129-131`
`createTable(groups/groupMembers)` 只在 `from >= 7 && from < 8` 条件内执行，v1–v6 的库升到 v22 不会建这两张表，任何 group 查询直接 SQL 报错。实际风险取决于野外是否还有 v≤6 设备——若确认没有，也应在迁移代码注释里记录该决定。
**建议：** 条件改 `from < 8`，配 `IF NOT EXISTS` 幂等防护。

### P2 — 中优先级

**P2-1. 搜索无防抖，每个按键触发全量重查+全行重解密**
`lib/features/list/presentation/widgets/list_sort_filter_bar.dart:336-337`
`onChanged` 直写 `listFilterProvider`，而 `state_list_transactions.dart:40` watch 整个 filter 对象——每个按键重跑无 LIMIT 的整月 SQL，并对每行 note 重做 ChaCha20 解密。
**建议：** 加 300ms debounce；searchQuery 从 SQL 重查依赖中剥离（`select` 或分层 provider），文本过滤只在内存重算。

**P2-2. `findByBookIds` 无分页（D-02 承诺未兑现）**
`lib/data/daos/transaction_dao.dart:242-243`
注释自认 "Pagination is deferred to v1.5"，现已 v2.x。交易列表与多个 analytics provider 直接消费，家庭模式下跨多 book 拉整月全行。建议实现 keyset pagination（timestamp+id）。

**P2-3. 成员筛选分类聚合拉全行到 Dart 侧算**
`lib/features/analytics/presentation/providers/state_analytics.dart:101-162`
`memberFilteredCategoryBreakdown` 拉双账本全行（每行白白解密 note）在 Dart 循环累加，而 `analytics_dao` 已有 SQL GROUP BY 模式，只差 deviceId 过滤参数。建议给 `getCategoryTotals` 加可选 `deviceId` 参数下沉 SQL。

**P2-4. CI 覆盖率门槛 70% 与项目规则 80% 持续背离**
`.github/workflows/audit.yml:124-133`
Phase 8（2026-04-28）临时降到 70%，注明 "revisited after v1 feature work completes"——v1 已到 Phase 56，backlog `coverage-baseline-review` 该兑现了：要么回升门槛，要么修订 testing.md，消除双重标准。

**P2-5. 6 处用原始 `palette.joy` 作文字色，违反 ADR-019 对比度规则**
raw joy `#D98CA0` 在白/浅底上对比度约 2.2:1（AA 要求 4.5:1），ADR-019 明确金额/文字必须用 `joyText #A53D5E`：
- `joy_celebration_overlay.dart:124-128`（'Joy!' 同时还是硬编码文案）
- `list_screen.dart:265-267` 与 `category_drill_down_screen.dart:148-150`（悦己 tag pill）
- `list_sort_filter_bar.dart:271-274`（ActionChip 选中态）
- `satisfaction_emoji_picker.dart:63-68`（12px 小字，最不达标）
- `home_screen.dart:329-331`（同 tile 内 categoryColor 用 joy、amountColor 用 joyText，双标准）
- `best_joy_story_strip.dart:46`（大字号边缘达标，但与全库写法不一致）
统一改 `palette.joyText` 即可。

**P2-6. 4 处漏网硬编码 UI 字符串**
- `home_screen.dart:443` — `'Error: $message'`（home 两处调用）
- `settings_screen.dart:165` — `'Error: $error'`
- `joy_celebration_overlay.dart:124` — `'Joy!'`
- `shopping_item_form_screen.dart:629` — `'¥'`（Phase 40 后已多币种，应从 currency code 派生）
ARB 已有 `error` 等现成 key，改 `S.of(context)` 即可。

**P2-7. 超大 UI 文件（4 个 >800 行，含命令式表单 API）**

| 文件 | 行数 | 拆分思路 |
|---|---|---|
| `transaction_details_form.dart` | 1370 | 最高优先。`TransactionDetailsFormState` 暴露 ~20 个公共成员由宿主经 GlobalKey 命令式驱动（`submit()` 169 行、`build()` 220 行）；拆 form-core / 外币联动 / 识别 band 三块，命令式 API 收敛为一个 handle/controller 对象 |
| `home_hero_card.dart` | 1155 | 5 个独立视觉区块 + 25 个 `_xxx` build 方法；按区块拆 `widgets/home_hero/` 下 4-5 文件，best-joy strip 最独立 |
| `manual_one_step_screen.dart` | 1033 | 外币 triple 推送/汇率信号提为 helper，`build()`（232 行）分段提方法 |
| `voice_ptt_session_mixin.dart` | 833 | 温和拆分："识别结果→表单回填"段提独立类；录音状态机因 260622-nhs 时序修复宜整体保留 |

（`default_categories.dart` 1273 行为纯种子数据，不需拆。）另 `shopping_item_form_screen.dart:374` 的 `build()` 长 349 行，4 个 Zone 应各提为私有 widget 类。

**P2-8. 关键同步路径静默吞错**
- `lib/application/family_sync/pull_sync_use_case.dart:204` — E2EE group key 解密失败 `catch (_) { return false; }` 零日志，成员将"静默地永远同步不上"，这是排查同步假死的关键路径
- `lib/infrastructure/exchange_rate/exchange_rate_api_client.dart:122,148` — 两级 API fallback 全挂时零输出
- `voice_ptt_session_mixin.dart:650` — 语音回填异常吞掉，"识别了却没填进表单"难排查
三处都只需补 `kDebugMode + debugPrint` 诊断（降级行为本身合理）。

**P2-9. 测试覆盖缺口（按风险排序）**
- 真机 E2E：`integration_test/` 仅 1 个加密迁移测试；记账保存、applock 解锁至少各补一条冒烟路径（applock 的三个已知故障模式全部只在真机复现）
- `application/family_sync/` 群组生命周期三件套（check_group_validity / handle_group_dissolved / handle_member_left）无专属单测——多设备一致性边界路径
- `demo_data_service.dart` 188 行 0% 覆盖（同时其逐行 insert 也无 batch 包裹）
- applock widget 测试仅 4 个：补 PIN 输错、`startOnPinPage` 分支
- `get_user_profile_use_case.dart` 读路径无测试（写路径有）

### P3 — 低优先级

| # | 位置 | 问题 | 建议 |
|---|---|---|---|
| P3-1 | `groups_table.dart:11` | 家庭同步 groupKey（对称密钥）明文列存 Drift，仅靠 SQLCipher 库级加密，待遇低于其他密钥 | 走 FieldEncryptionService 或移 secure storage |
| P3-2 | `pin_kdf.dart:10-12` | PIN 无失败次数限制/退避（D-06 accepted risk） | 后续版本加失败计数 + 指数退避（持久化在 keychain） |
| P3-3 | `export_backup_use_case.dart:104-108` | 备份写 Documents 目录，分享后不删除，长期累积且随 iCloud 备份上传 | 写临时目录，share 回调后删除 |
| P3-4 | `infrastructure/sync/e2ee_service.dart` | pinenacl NaCl Box 实现在 sync/ 而非 crypto/，第 3 个 crypto 实现点 | 迁入 crypto/ 或在 CLAUDE.md 明示豁免 |
| P3-5 | `app_database.dart:294-302` | from<14 迁移用字符串插值拼 SQL（当前数据无 `'` 不炸，未来会） | 改绑定参数 |
| P3-6 | 全库 59 处 `'JPY'` 字面量（7 处同一谓词变体） | 基准货币散落 | `currency_conversion.dart` 加 `kBaseCurrency` + `isForeignCurrency()` |
| P3-7 | `recognition_reconciler.dart:9` ↔ `parse_voice_input_use_case.dart:19` | `kMerchantAutoFillFloor = 0.85` 双份定义（有意镜像但无防漂移测试） | 加一条 parity test |
| P3-8 | `get_list_transactions_use_case.dart:70-88` | `watch()` 响应式路径生产代码零消费者（死代码，含全行重解密路径） | 接上 stream 或删除 |
| P3-9 | `shopping_list/.../repository_providers.dart:110-121` | filter 任意字段变化都整体重建 Drift stream | stream source 只 `select` 影响 SQL 的字段 |
| P3-10 | feature↔feature 双向耦合 9 对（37 对有向 import） | home 的 `state_shadow_books.dart` 被 analytics/list 至少 5 处反向引用 | 共享 state 上提到 shared 层 |
| P3-11 | applock/onboarding/list/shopping_list/currency 不在架构守卫测试 feature 列表 | 新 feature 未纳入守卫体系（applock/onboarding 连 import_guard.yaml 都没有） | 守卫测试 feature 列表补全，或改为自动发现 |
| P3-12 | `audit_logger_test.dart:123,146` | 真实 `Future.delayed(seconds: 2)` 每次全量跑固定烧 ~2s | 注入 clock |
| P3-13 | `app_zh.arb` | 2 处 zh 文案混入日文中点 `・`（应为 `·`） | 替换标点 |
| P3-14 | `home_hero_card.dart:873` | 直接 `DateFormat('E')` 绕过 `DateFormatter.formatShortWeekday` | 替换调用 |
| P3-15 | `legal_urls.dart:19-23` | 3 个 `example.com` 占位 URL（已知 TODO） | 挂 release checklist |
| P3-16 | `voice/domain/services/` 与 `analytics/domain/category_l1_rollup.dart` | 偏离 "domain ONLY models/ + repositories/" 字面规则（前者是 Phase 51 有意的纯域服务） | 更新 CLAUDE.md 承认 pure domain service 例外；裸文件移入 models/ |
| P3-17 | `.planning/audit/files-needing-tests.txt` 等 | 覆盖率基线副本停留在 2026-04-28，多条已过时 | 定期回写或文件头标注生成日期 |
| P3-18 | CLAUDE.md | schemaVersion 写 21，实际已是 **22** | 文档更新 |

---

## 4. 明确验证通过的关键检查点

安全维度逐项核验，以下全部通过（列出以免重复排查）：

- **PIN 存储（Phase 55）**：Argon2id（OWASP 参数）→ PHC 字符串入 keychain，常数时间比较；SharedPreferences 只有布尔开关，无 PIN 材料 ✅
- **flutter_secure_storage 收敛**：直接使用点仅 4 个文件，全部在 infrastructure/crypto 与 infrastructure/security ✅
- **keychain accessibility**：两处一致保持 `unlocked_this_device`，带完整 rationale 注释 ✅
- **随机数**：所有安全场景均 `Random.secure()`；`Random()` 仅 UI 动画/demo ✅
- **SQL 注入**：全部 customSelect/customUpdate 用 `?` 绑定；ORDER BY 列名经 enum 编译期 switch；加密列（note）从不进 WHERE/ORDER BY ✅
- **硬编码 secrets**：lib/ + iOS/Android 配置扫描零命中；relay 鉴权为 Ed25519 请求签名 ✅
- **敏感数据日志**：crypto/security 目录零 log 调用；无 key/seed/mnemonic/pin/金额入日志 ✅
- **零知识同步**：push 前 E2EE 加密 payload，relay 只见密文 ✅
- **ARB 三语 parity**：737 key × 3 语零缺口，placeholder 集合零不匹配（有架构测试守护）✅
- **色值 token 化**：features/ + shared/ 硬编码 `Color(0x...)` 为 0（有架构测试守护）✅

---

## 5. 值得保持的优点

1. **架构守卫测试体系**：16 个测试把分层规则、provider 卫生、ARB parity、CJK 扫描、色值扫描、日志隐私、甚至 CI 配置本身（`audit_yml_invariants_test`）都变成可执行断言。本次发现的 P0-1 正是这套体系抓住的。
2. **Domain 层实测零违规**：全部 features/*/domain 无任何 data/infrastructure/drift import——Clean Architecture 最核心的一条守住了。
3. **代码卫生**：~67k 行手写代码 **0 个 `// ignore:`**、0 裸 `print`、0 FIXME/HACK、TODO 仅 5 条且都有归属；52 处 debugPrint 有 51 处规范守卫。
4. **PIN KDF 实现质量高于同类移动应用**：Argon2id + 自描述 PHC 格式 + off-isolate + 常数时间比较。
5. **测试基建**：mocktail-only 全库统一（0 mockito）、golden 体系为跨平台精心设计（macOS 基线 + CI 存在性比较器）、0 个 skip 测试、核心 use case 错误路径覆盖充分（create_transaction 有 ~20 条错误路径用例）。
6. **横向复用控制得好**：金额键盘、PIN 键盘、日期选择、JPY 换算均有单一实现点；问题主要是纵向"单文件过胖"而非横向复制粘贴。
7. **决策可追溯**：关键代码普遍带 D-xx / Phase / CR 编号注释，迁移历史陷阱有详尽记录。

---

## 6. 建议执行顺序

| 批次 | 内容 | 预估工作量 |
|---|---|---|
| 立即 | P0-1 一行修复（kDebugMode 守卫）让 main 回绿 | 5 分钟 |
| 本周 | P0-2 恢复事务化 + P1-1 索引补齐（schemaVersion 22→23 一个迁移步同时解决）+ P1-4 迁移缝隙 | 0.5-1 天 |
| 本迭代 | P1-2 守卫漏洞（补 pattern + 新增归一化分层测试 + 修 2 处反向依赖）+ P1-3 备份加密下沉 crypto 层与 KDF 升级 | 1-2 天 |
| 下迭代 | P2-1/2/3 性能三件套（防抖、分页、聚合下沉）+ P2-5/6 UI 合规批量修 + P2-8 补诊断日志 | 1-2 天 |
| 持续 | P2-7 大文件拆分（transaction_details_form 优先）+ P2-9 测试缺口 + P2-4 覆盖率门槛决议 + P3 清单 | 按容量安排 |

**索引补齐（P1-1）注意事项**：CREATE INDEX 对存量大表有一次性构建成本，迁移步建议放 `beforeOpen` 之外的标准 onUpgrade 流程并保持幂等（`IF NOT EXISTS`）；补齐后建议用 `EXPLAIN QUERY PLAN` 抽查交易列表/日历/分析页的热查询确认索引命中。

---

*报告由 6 维度并行代码审查生成；所有 file:line 引用截至 commit `11c1e045`（main, 2026-07-02）。*
