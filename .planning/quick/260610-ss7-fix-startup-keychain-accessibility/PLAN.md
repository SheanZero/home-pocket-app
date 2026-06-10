---
quick_id: 260610-ss7
slug: fix-startup-keychain-accessibility
date: 2026-06-10
type: fix
---

# Fix: iOS 启动「初始化失败」— 回退 keychain accessibility 改动

## 问题

设备升级后启动停在「初始化失败」通用 retry 屏（截图 20:22）。崩溃发生在
已包含今天 18:33 未提交修复（①数据丢失守卫 + ②keychain accessibility 改动）的 build 上。

## 根因

②把 iOS keychain accessibility 从 `unlocked_this_device` 改成 `first_unlock_this_device`。
本项目用 `flutter_secure_storage ^10.2.0`（darwin 0.3.1），其 `read()` 经由共享的
`baseQuery` 把 `kSecAttrAccessible` 塞进**读取查询**（FlutterSecureStorage.swift:218-220 /
read() at :462，且无忽略 accessibility 的回退）。存量 master key 是用旧值
`unlocked_this_device` 存的 → 新查询 accessibility 不匹配 → `SecItemCopyMatching`
返回 `errSecItemNotFound` → `hasMasterKey()` 返回 false → 磁盘 DB 仍在 → **①守卫触发**
→ 初始化失败屏。即 ②制造「读不到 key」，①忠实拦下。

## 决策（用户确认）

- 需保住真实数据 → 走非破坏性「让旧 key 重新可读」路线，**不加任何重置/清库**。
- 保留 ①守卫（数据丢失保护）。①存在后，②想解决的「锁屏后台启动读不到 key」已被安全兜底
  （fail-loud + 解锁后 retry，而非铸新 key），故 ②非必要。

## 变更

1. `lib/infrastructure/security/providers.dart` — accessibility 回退
   `first_unlock_this_device` → `unlocked_this_device`，注释说明 10.x 读查询会按
   accessibility 过滤的坑 + 与守卫的关系。
2. `lib/infrastructure/security/secure_storage_service.dart` — 同样回退 + 注释。

不动：① 守卫相关文件（app_initializer / init_result / encrypted_database / main）及其测试。

## 验证

- `flutter analyze` 0 issues
- 受影响 + 全量 `flutter test` 绿（无测试断言 accessibility 值）
- 设备侧：用户重新 build → 应能正常启动且数据恢复（若仍失败 → 该设备 key 因过往开发期
  重装致 keychain access group 变化而物理不可达，超出本次范围，另议 recovery kit）。
