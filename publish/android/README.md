# Happy Pocket — Google Play 发布资料

这里保存 Happy Pocket 首次发布到 Google Play 时使用的操作流程与填写基线。

从 [`GOOGLE_PLAY_RELEASE.md`](GOOGLE_PLAY_RELEASE.md) 开始。它是 Android 发布的主流程，覆盖账号、Play App Signing、AAB 构建、商店资料、Data safety、测试轨道、送审和上线后检查。

## 目录

- `GOOGLE_PLAY_RELEASE.md`：Google Play 首次发布的完整执行流程。
- `REQUIRED_VALUES.env.example`：Play Console 字段速查；不包含密码、私钥或服务账号密钥。
- `privacy/data_safety_answers.md`：基于当前客户端、隐私政策与 family relay 行为整理的 Data safety 填写基线。
- `review/reviewer_test_plan.md`：Play 审核员和内部测试人员可执行的英文测试路径。
- `SOURCES.md`：本流程核对过的 Google、Android 和 Flutter 官方资料。

## 当前不能自动完成的事项

- Google Play Developer 账号的组织/个人身份验证和协议接受。
- 在 Play Console 创建 App，并确认 `com.sheanzero.happypocket.app` 从未被其他 App 占用。
- 创建并离线备份生产 upload key；仓库只提供签名接线，不保存真实密钥。
- 确认公开 Privacy、Terms、Support 页面可从公网稳定访问，并完成最终法律审核。
- 在最终 AAB 上通过 Play Console 的 target API、16 KB page size、权限和设备兼容检查。
- 使用 Play 分发的构建完成 Android 真机测试。
- 若账号适用，完成 12 名测试者连续 14 天的 closed test，再申请 production access。
- 在 Play Console 完成 Data safety、Financial features、Content rating、Target audience、Ads 和 App access 等声明。

upload keystore、密码、Play Console 服务账号 JSON 和任何 API 凭据不得放入本目录或提交 Git。
