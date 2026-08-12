# Happy Pocket — App Store 发布资料

这里保存 Happy Pocket 首次发布到 Apple App Store 时要使用的操作指南和现成物料。

当前 App 最低支持 iOS 15，最终上传使用 Xcode 26 或更高版本构建。

发布时从 [`APP_STORE_RELEASE.md`](APP_STORE_RELEASE.md) 开始。它是唯一的发布流程文档，按一人公司可以直接执行的方式编写。

## 目录

- `APP_STORE_RELEASE.md`：从 Apple 账号准备、App Store Connect、Archive、TestFlight 自测、送审到正式上线的完整流程。
- `REQUIRED_VALUES.env.example`：App Store Connect 字段速查，不含密码或证书。
- `metadata/`：日语、简体中文、英语商店文案。
- `screenshots/`：截图规格、分镜、采集命令和校验脚本。
- `review/`：App Review Notes、审核复现路径和 TestFlight 自测说明。
- `privacy/`：App Privacy 填写基线、加密问卷技术基线和 Privacy Manifest 模板。
- `legal/current/`：与 App 内置版本一致的隐私政策、条款和特商法页面快照。
- `assets/`：1024×1024 App Store Icon 和品牌资源。
- `scripts/validate_materials.sh`：检查版本、图标、元数据、隐私清单和截图。
- `SOURCES.md`：Apple 官方资料链接。

## 当前还要在 App Store Connect 完成的事项

- 上传 `docs/mockup/v17/marketing/ja/exports/` 的 10 张日语 iPhone 营销截图；其他语言使用主语言回退。
- 用 Apple Distribution 正式签名生成 Archive，Validate App 后上传。
- 根据最终 App、SDK 和生产服务填写 App Privacy。
- 完成加密/出口合规问卷并清除 build 的 Missing Compliance。
- 选择 build，填写审核信息并提交审核。

账号密码、证书私钥、provisioning profile 和 API key 不存放在本目录。
