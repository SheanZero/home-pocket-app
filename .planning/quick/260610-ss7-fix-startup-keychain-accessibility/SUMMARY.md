---
quick_id: 260610-ss7
slug: fix-startup-keychain-accessibility
date: 2026-06-10
type: fix
status: complete
---

# Summary — 260610-ss7

## 问题
iOS 启动停在通用「初始化失败」屏。崩溃发生在已含今天 18:33 未提交修复（①铸 key 守卫 +
②keychain accessibility 改动）的 build 上。

## 根因
`flutter_secure_storage ^10.2.0`（darwin 0.3.1）`read()` 经共享 `baseQuery` 把
`kSecAttrAccessible` 注入读取查询（`FlutterSecureStorage.swift:218-220`，`read()`:462，
无忽略 accessibility 的回退）。② 把 accessibility 从 `unlocked_this_device` 改成
`first_unlock_this_device` 后，存量 master key（旧 accessibility 存储）读取不匹配 →
`SecItemCopyMatching` 返回 `errSecItemNotFound` → `hasMasterKey()`=false → 磁盘 DB 仍在
→ ① 守卫触发 → 失败屏。**② 制造「读不到 key」，① 忠实拦下。**

## 处置
用户确认需保住真实数据 → 非破坏性路线：**回退 ②、保留 ①**。
- `lib/infrastructure/security/providers.dart` accessibility → `unlocked_this_device`
- `lib/infrastructure/security/secure_storage_service.dart` 同上
- 两处注释加警告：10.x 读查询按 accessibility 过滤；改值必配 read-then-rewrite keychain
  迁移，否则 bricks 存量安装。
- ① 守卫文件与测试不动（① 已使「读不到就铸新 key 覆盖」不可能，故 ② 非必要）。

## 验证
- `flutter analyze` 0 issues
- `test/infrastructure/security/` + `test/core/initialization/` 105/105
- 全量 `flutter test` 2565/2565 全绿
- `grep first_unlock lib/ test/` = 0

## 待办 / 边界
- [ ] 设备侧确认：重新 build → 正常启动且数据恢复。
- 若该设备 key 因过往开发期重装致 keychain access group 变化而物理不可达，回退也救不回
  （非 accessibility 不匹配，而是 item 真不可达）→ 另议 recovery kit。
- 后续（沿用 18:33 worklog）：①「key 不可读但 DB 存在」专门 UI（recovery / deliberate
  reset 逃生出口，需 l10n×3）；②如需锁屏可读性，实现 read-then-rewrite keychain 迁移。
