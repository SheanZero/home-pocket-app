# 修复启动「初始化失败」— 回退 keychain accessibility 改动

**日期:** 2026-06-10
**时间:** 20:47
**任务类型:** Bug修复
**状态:** 已完成（代码侧；待设备侧确认）
**相关模块:** MOD-006 Security / 加密密钥管理 + App 初始化
**Quick 任务:** 260610-ss7
**承接:** `20260610_1833_fix_ios_release_upgrade_data_loss.md`（① 守卫 + ② accessibility）

---

## 任务概述

18:33 那次「iOS 升级数据丢失」修复（未提交）含两部分：① 数据丢失守卫、② keychain
accessibility 改动。用户重新 build 含改动的版本后，iOS 启动停在通用「初始化失败」屏。
本任务定位为 ② 与 ① 在存量安装上的互咬，回退 ②、保留 ①。

---

## 根因

`flutter_secure_storage ^10.2.0`（darwin 0.3.1）的 `read()` 经共享 `baseQuery` 把
`kSecAttrAccessible` 注入**读取查询**（`FlutterSecureStorage.swift:218-220`，`read()`
at `:462`，且无忽略 accessibility 的回退路径）。

- 存量 master key 用旧值 `unlocked_this_device`（`WhenUnlockedThisDeviceOnly`）存储。
- ② 把 accessibility 改成 `first_unlock_this_device` 后，读取查询的 accessibility 与
  存储项不匹配 → `SecItemCopyMatching` 返回 `errSecItemNotFound` → `hasMasterKey()`
  返回 false。
- 磁盘上加密 DB 仍在 → ① 守卫触发 → 返回 `masterKeyMissingWithData` → 初始化失败屏。

即 **② 制造「读不到 key」，① 忠实拦下**。9.x 无此问题（旧读查询不带 accessibility），是
10.x darwin 重写引入。

---

## 决策（用户确认）

- **需保住真实数据** → 走非破坏性「让旧 key 重新可读」路线，回退 ②，绝不加重置/清库。
- **保留 ① 守卫**。① 存在后，② 想解决的「锁屏后台启动读不到 key → 误判首装铸新 key 覆盖
  数据」已被安全兜底（① fail-loud + 解锁后 retry，而非铸新 key），故 ② 非必要。

---

## 完成的工作

### 回退 ②（accessibility `first_unlock_this_device` → `unlocked_this_device`）
- `lib/infrastructure/security/providers.dart`（master key 实际走这条）
- `lib/infrastructure/security/secure_storage_service.dart`（device key / pin / recovery hash）
- 两处注释改写：明确 10.x「读查询按 accessibility 过滤」的坑 + 与 ① 守卫的关系 +
  「改 accessibility 必须配读-改-写 keychain 迁移，否则 bricks 存量安装」的警告。

### 保留不动
- ① 守卫全部文件与测试（`app_initializer` / `init_result` / `encrypted_database` /
  `main` + 对应单测）。

---

## 测试验证

- [x] `flutter analyze` 0 issues
- [x] 受影响套件 `test/infrastructure/security/` + `test/core/initialization/` 105/105 通过
- [x] 全量 `flutter test` **2565/2565** 通过，无回归
- [x] `grep first_unlock lib/ test/` = 0（无残留）
- [x] **设备侧已确认（Verified 2026-06-10）**：`flutter run --release` 两次安装到「Xin
  Zhang」的 iPhone（00008130，签名 team 6Y64KR8RLP 不变 → keychain access group 不变）；
  第二次为**覆盖安装=升级路径**（未卸载）→ 正常启动越过初始化失败屏 + 数据保留。回退 ②
  使旧 key 重新可读，原 bug（升级丢数据 + 启动初始化失败）确认修复。

---

## 重要边界

1. **若设备 key 因过往开发期重装致 keychain access group 变化而物理不可达**：回退 ②
   也救不回（已非 accessibility 不匹配，而是 item 真不可达）。用户场景含「开发期反复重装」，
   故存在此可能。此时超出本次范围，需另议 recovery kit 恢复路径。
2. **锁屏后台启动**：回退后这类启动读不到 key 会停在初始化失败屏（不可见的后台启动），
   前台（解锁）启动正常；① 保证此过程绝不丢数据。这是相对 ② 的已知取舍。

---

## 后续工作（沿用 18:33 worklog 的建议）

- [ ] 为「key 不可读但 DB 存在」做专门 UI：recovery kit 恢复，或显式「重置重来」逃生出口
      （需 l10n 三语 + deliberate reset 路径）。
- [ ] 如确需 ② 的锁屏可读性：实现 read-then-rewrite keychain 迁移（旧 accessibility 读到
      → 新 accessibility 重写），而非直接换值。

---

**创建时间:** 2026-06-10 20:47
**作者:** Claude Opus 4.8
