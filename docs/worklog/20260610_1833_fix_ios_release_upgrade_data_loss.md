# 修复 iOS release 升级后数据丢失

**日期:** 2026-06-10
**时间:** 18:33
**任务类型:** Bug修复
**状态:** 已完成（核心修复 ①+②）
**相关模块:** MOD-006 Security / 加密密钥管理 + App 初始化

---

## 任务概述

用户反馈：iOS 上 release 升级 release 后"已有的资料被删掉"。系统化排查确认数据库文件本身没丢，丢的是解开它的 master key —— 初始化逻辑把"keychain 读不到 key"错当成"首次安装"，于是铸一把新随机 key 覆盖写回，导致旧的加密数据库永久解不开（表现就是数据全没）。

---

## 根因分析

排除了两个嫌疑：
- **Drift 迁移** —— 链式迁移完整、无破坏性操作（DROP/DELETE 只针对临时表与已下线的系统分类）。排除。
- **DB 文件路径** —— 库在 `getApplicationDocumentsDirectory()/databases/home_pocket.db`，Documents 跨升级持久、不被 iOS 清理。排除。

确认根因（密钥）：
- `lib/core/initialization/app_initializer.dart`：`if (!await hasMasterKey()) { initializeMasterKey(); }` —— 把"读不到 key"等同于"首次安装"。
- `master_key_repository_impl.dart`：`hasMasterKey()` 仅判断 `read()` 是否返回 null/空；`initializeMasterKey()` 用 `Random.secure()` 生成全新随机 key（与 BIP39 无关，覆盖后不可逆）。
- `infrastructure/security/providers.dart` / `secure_storage_service.dart`：iOS keychain accessibility 用了 `unlocked_this_device`（`WhenUnlockedThisDeviceOnly`）。设备锁屏时读 key 会失败；release 升级后 iOS 可能在解锁前因推送/后台拉起 app 跑初始化，或两次 build 签名/team 变化导致 keychain access group 变化 → `read` 返回 null → 触发上面的"铸新 key"。

子 agent 最初把锅扣在"ThisDeviceOnly 不进备份"上 —— 已纠正：ThisDeviceOnly 只影响换机/从备份恢复，对同设备升级不成立。真正机制是 `WhenUnlocked` 锁屏不可读 + "读不到就铸新 key"。

---

## 完成的工作（TDD：RED → GREEN）

### ① 数据丢失守卫（最关键）
初始化时若 `hasMasterKey()` 为 false 但磁盘上已存在加密 DB → 判定为**非首次安装**，绝不生成新 key，改为 fail-loud 返回新失败类型 `InitFailureType.masterKeyMissingWithData`（携带 `MasterKeyMissingWithExistingDataError`）。

- `lib/core/initialization/init_result.dart`：新增枚举值 + 守卫异常类。
- `lib/infrastructure/crypto/database/encrypted_database.dart`：抽出 `_databaseFilePath()`，新增只读的 `encryptedDatabaseExists()`（不创建目录）。
- `lib/core/initialization/app_initializer.dart`：新增可注入谓词 `EncryptedDatabaseExists`（保持单测不碰 path_provider），在铸 key 前插入守卫。
- `lib/main.dart`：生产侧注入 `encryptedDatabaseExists()`（in-memory 模式恒为 false）。

### ② keychain accessibility 修正
`unlocked_this_device` → `first_unlock_this_device`（`AfterFirstUnlockThisDeviceOnly`），让 key 在开机首次解锁后即使再次锁屏/后台拉起也能读到，堵住"锁屏启动读不到 key"这条触发路径。保留 `ThisDeviceOnly`（零知识：库密钥不进 iCloud 备份，换机靠 BIP39 恢复套件）。

- `lib/infrastructure/security/providers.dart`（master key 实际走这条）
- `lib/infrastructure/security/secure_storage_service.dart`（其余 device key / pin / recovery hash）

### 测试
- `test/core/initialization/app_initializer_test.dart`：新增守卫测试组（DB 存在时不铸 key + 携带正确错误 + 首次安装仍正常铸 key）。
- `test/core/initialization/init_result_test.dart`：枚举变体 4 → 5。
- `test/main_characterization_smoke_test.dart`：补 `databaseExists` 必填参数。

---

## 测试验证

- [x] RED 已观察（新测试因缺 API 编译失败）
- [x] GREEN：受影响套件 51/51 通过
- [x] 全量 `flutter test` 2565/2565 通过，无回归
- [x] `flutter analyze` 0 issues
- [x] 无残留 `unlocked_this_device` 引用，无测试断言旧值

---

## 重要边界与后续工作

1. **存量用户**：② 只对**之后写入**的 key 生效，旧 item 仍是 `unlocked_this_device` 直到被重写；但 ① 守卫对存量数据立即生效，已堵死丢失路径。
2. **已经丢了数据的用户**：旧随机 key 已被覆盖，物理不可逆，本修复只防未来。
3. **守卫副作用**：若某用户 key 真的永久不可读，现在会停在初始化失败屏（通用 retry）而非静默清空。锁屏导致的瞬时失败解锁后 retry 即恢复（配合 ②）。
   - [ ] **建议后续**：为"key 不可读但 DB 存在"场景做专门 UI —— 走 recovery kit 恢复，或提供显式"我知道旧数据已丢，重置重来"的逃生出口（需 l10n 三语 + 一条 deliberate reset 路径）。本次属 ①+② 范围外。
   - [ ] **建议后续**：评估把 master key 改为可由 BIP39 恢复短语派生（当前是纯随机，recovery kit 只存哈希，救不回库密钥）。

---

## 变更文件

- lib/core/initialization/init_result.dart
- lib/core/initialization/app_initializer.dart
- lib/infrastructure/crypto/database/encrypted_database.dart
- lib/main.dart
- lib/infrastructure/security/providers.dart
- lib/infrastructure/security/secure_storage_service.dart
- test/core/initialization/app_initializer_test.dart
- test/core/initialization/init_result_test.dart
- test/main_characterization_smoke_test.dart

---

**创建时间:** 2026-06-10 18:33
**作者:** Claude Opus 4.8

---

## Update 2026-06-10 20:47: ② 已回退（startup 修复）

设备重新 build 含本修复的版本后启动停在「初始化失败」。定位为 **② 与 ① 互咬**：
`flutter_secure_storage 10.x`（darwin 0.3.1）的 `read()` 会把 `kSecAttrAccessible` 注入
**读取查询**，所以把 accessibility 从 `unlocked_this_device` 改成 `first_unlock_this_device`
后，存量 key（旧 accessibility 存储）读取不匹配 → `errSecItemNotFound` → `hasMasterKey()`
为 false → ① 守卫触发 → 失败屏。即 ② 制造「读不到 key」、① 忠实拦下。

**处置（quick 260610-ss7）：回退 ②、保留 ①。**
- `providers.dart` / `secure_storage_service.dart` accessibility 改回 `unlocked_this_device`。
- ① 守卫已使「读不到就铸新 key 覆盖数据」不可能发生，故 ② 的锁屏可读性非必要。
- 全量 `flutter test` 2565/2565 绿，analyze 0。
- 详见 `20260610_2047_fix_startup_keychain_accessibility_revert.md`。

本节为 append 更正，不改上方原决策正文。
