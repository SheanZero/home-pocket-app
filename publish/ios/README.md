# Happy Pocket — iOS App Store 发布包

生成日期：2026-08-04（Asia/Tokyo）

这个目录是 Happy Pocket（ハピポケ家族家計簿）首次 App Store 发布的统一交付入口。它包含发布步骤、App Store Connect 三语文案、审核说明、隐私与加密答题稿、App Icon、法律文本快照、截图采集规范和自动校验脚本。

## 当前结论

**物料框架和可确定内容已准备好，但当前版本仍是 NO-GO，不能直接提交审核。** 账号、法务和真实运行行为相关的信息不能靠占位值代替；请先关闭 [RELEASE_GATES.md](RELEASE_GATES.md) 中的阻断项。

已确认的工程信息：

| 项目 | 当前值 |
|---|---|
| Bundle ID | `com.sheanzero.happypocket.app` |
| Apple Team ID | `6Y64KR8RLP` |
| pubspec 版本 | `0.1.0+1` |
| iOS Deployment Target | iOS 15.0 |
| 支持设备 | iPhone + iPad（`TARGETED_DEVICE_FAMILY = 1,2`） |
| Xcode | `26.2`，满足 2026-04-28 起的 Xcode 26 / iOS 26 SDK 上传要求 |
| App Icon | `assets/app-icon/AppIcon-1024.png`，1024×1024、无 Alpha，可用于商店 |
| 推送 | 首版停用；通知入口、自动注册与 iOS push capability 已关闭 |

## 目录说明

- `RELEASE_GATES.md`：提交前必须关闭的阻断项。
- `RELEASE_STEPS.md`：从账号准备、构建、TestFlight 到送审和发布的逐步操作。
- `REQUIRED_VALUES.env.example`：需要发布负责人填写的真实信息，不含密码或证书。
- `metadata/`：日语、简体中文、英语 App Store Connect 文案。
- `review/`：App Review Notes、审核测试路径与 TestFlight 测试说明。
- `privacy/`：App Privacy 保守答题稿、加密出口合规判断清单、隐私清单模板。
- `assets/`：1024 App Icon 与品牌源文件。
- `legal/current/`：与 `assets/legal/` 同步的三语正式文本快照；运营方已批准，尚待专业法务复核。
- `screenshots/`：截图分镜、规格、采集路径与规范化脚本。
- `scripts/validate_materials.sh`：本地发布物料门禁。
- `SOURCES.md`：本包采用的 Apple 官方依据。

## 推荐使用顺序

1. 复制 `REQUIRED_VALUES.env.example` 为本地私有工作表，补齐真实联系人、App 专用支持/隐私 URL、版权主体、版本和发布地区；不要提交凭据。
2. 关闭 `RELEASE_GATES.md` 中的 P0 项，并同步修正 app 内文案、隐私政策与实际网络行为。
3. 按 `screenshots/README.md` 用最终 Release build 和非敏感演示数据采集 iPhone、iPad 三语截图。
4. 运行 `bash publish/ios/scripts/validate_materials.sh`。
5. 按 `RELEASE_STEPS.md` 上传 TestFlight、验收、填 App Store Connect 并提交审核。

## 边界

本包不包含 Apple ID、App Store Connect API key、分发证书、私钥、provisioning profile、真实手机号或任何其他秘密。出口管制和日本法务结论也不能由模板代替，必须由账号持有人/法务负责人确认。
