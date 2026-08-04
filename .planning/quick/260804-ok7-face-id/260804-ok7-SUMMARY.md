---
quick_id: 260804-ok7
status: complete
commit: 32ccec3a
date: 2026-08-04
---

# Quick Task 260804-ok7 Summary

修复首次 Face ID 授权前 Home Pocket 不出现在系统“其他 App”列表、同时应用把生物识别错误置灰的问题。

## Delivered

- 当设备确认具备生物识别能力、但授权前暂时拿不到已录入类型时，按“类型未知但可认证”处理，不再误判为未录入。
- 初始设置启用或选择生物识别时主动发起系统认证；只有成功才选择生物识别，取消、拒绝或失败自动保留 PIN。
- 常规设置的生物识别开关采用相同的先认证后持久化规则。
- 新增服务层和两处 UI 回归测试，覆盖首次授权成功与失败路径。

## Verification

- `flutter analyze`: 0 issues
- 相关安全/初始设置/设置页测试: 55/55 passed
- `flutter test`: 4403 passed, 11 skipped, 0 failed
- 真机系统授权弹窗与“设置 → Face ID 与密码 → 其他 App”条目待安装构建后人工确认。
