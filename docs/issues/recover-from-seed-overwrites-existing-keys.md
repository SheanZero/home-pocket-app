# ISSUE: recoverFromSeed 覆盖已有密钥风险

**状态:** 待检查  
**优先级:** 🔴 高（存在不可逆数据丢失风险）  
**来源:** 代码审查反馈（2026-02-10）  
**关联文件:** `lib/infrastructure/crypto/repositories/key_repository_impl.dart:53`

---

## 问题描述

`recoverFromSeed()` 当前仅校验 `seed.length == 32`，未检查是否已存在设备密钥。  
在已有密钥场景下调用该方法，会直接覆盖：

- `device_private_key`
- `device_public_key`
- `device_id`

这与 `generateKeyPair()` 的保护行为不一致（`generateKeyPair()` 在已有密钥时会抛 `StateError`）。

## 风险影响

- 旧私钥被覆盖后不可恢复
- 既有加密/签名数据可能无法继续使用
- 可能引发用户不可逆资产/账本数据访问问题

## 待检查项

- [ ] 确认 `recoverFromSeed()` 的产品语义是否允许“覆盖恢复”
- [ ] 若不允许覆盖：增加 `hasKeyPair()` 防护并抛 `StateError`
- [ ] 对齐 `generateKeyPair()` 与 `recoverFromSeed()` 的错误语义与提示文案
- [ ] 增加单元测试：已有密钥时拒绝恢复且不写入 storage
- [ ] 增加单元测试：合法 seed 且无已有密钥时恢复成功

## 建议验收标准

- [ ] `recoverFromSeed()` 在已有密钥时不会执行任何写入
- [ ] 相关测试覆盖拒绝覆盖与正常恢复路径
- [ ] 行为约束记录到接口注释或模块文档
