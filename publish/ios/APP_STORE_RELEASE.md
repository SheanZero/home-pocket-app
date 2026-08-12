# Happy Pocket 首次发布到 Apple App Store

更新日期：2026-08-12

这份文档只说明把当前 iOS App 提交到 Apple App Store 并正式上线所需的操作，按一人公司可以直接执行的方式编写。

## 当前发布信息

| 项目 | 当前值 |
|---|---|
| App | Happy Pocket（ハピポケ家族家計簿） |
| Bundle ID | `com.sheanzero.happypocket.app` |
| Apple Team ID | `6Y64KR8RLP` |
| 首发版本 | `1.0.0` |
| 当前 Build Number | `3`；Build `1`、`2` 均不用于送审 |
| 最低系统 | iOS 15.0 |
| 设备 | iPhone only |
| 主要语言 | Japanese |
| 商店语言 | 日语、简体中文、英语 |
| 分类 | Finance；Secondary 可选 Lifestyle |
| 价格 | Free；当前无 IAP 或订阅 |
| 首发地区 | Japan |
| 发布方式 | 建议手动发布 |

Apple 从 2026-04-28 起要求 iOS/iPadOS App 使用 iOS/iPadOS 26 SDK 或更高版本构建。本项目应使用 Xcode 26 或更高版本生成最终 Archive。

## 本次执行状态（2026-08-12）

| 项目 | 状态 |
|---|---|
| App record、三语名称与商店文案 | 已保存 |
| 分类、年龄分级、免费价格、仅日本销售 | 已保存 |
| 设备分发设置 | 仅 iPhone；iPad、Mac 与 Vision Pro 不支持 |
| 审核联系人、备注、无需登录、手动发布 | 已保存 |
| App Privacy URL 与问卷 | 已发布：姓名、用户 ID、设备 ID、其他用户内容 |
| Build `1.0.0 (1)` | Apple 拒收：缺少相机用途说明；同时包含 iPad 支持，不用于送审 |
| Build `1.0.0 (2)` | 已上传但使用相同的旧 Info.plist，预计会命中相同隐私扫描，不用于送审 |
| Build `1.0.0 (3)` | Apple 处理完成；仅支持 iPhone，出口合规已完成，已关联版本 1.0 并加入“首发自测”内部群组 |
| TestFlight | Build 3 已加入“首发自测”内部群组并完成 iPhone 实机自测；用户确认通过，无已知问题 |
| Xcode Privacy Report | 已生成到 `publish/ios/privacy/Runner-PrivacyReport-2026-08-12.pdf` |
| 截图 | 使用 `docs/mockup/v17/marketing/ja/exports/` 的 10 张日语 iPhone 营销图 |
| 送审 | 版本 1.0 / Build 3 已于 2026-08-12 提交；当前状态“正在等待审核” |

## 全流程总览

1. 准备 Apple Developer 账号、App ID 和签名。
2. 在 App Store Connect 创建 App。
3. 填写商店信息、隐私、年龄分级、加密合规和日本销售范围。
4. 用最终版本生成截图。
5. 生成正式签名 Archive，验证并上传。
6. 等待 build 处理完成；用 TestFlight 自测一次。
7. 选择 build，填写审核信息并提交审核。
8. 回复审核问题；通过后手动发布。
9. 上线后检查日本商店页面、下载安装和服务状态。

## 1. 只需做一次的 Apple 账号准备

### 1.1 Apple Developer Program

- 确认公司 Apple Developer Program 会员仍有效。
- 登录 [App Store Connect](https://appstoreconnect.apple.com/)，在 **Business** 中接受当前必须接受的协议。未接受最新协议时不能创建 App。
- 当前 App 免费且没有 IAP/订阅，不需要为了本次免费首发额外创建付费商品。将来收费时再完成 Paid Apps Agreement、税务和银行信息。

### 1.2 App ID 与签名

在 Apple Developer 的 **Certificates, Identifiers & Profiles** 中确认：

- Identifiers 中存在显式 App ID：`com.sheanzero.happypocket.app`。
- Xcode 登录的账号选择 Team `6Y64KR8RLP`。
- 有可用于 App Store 分发的 `Apple Distribution` 证书。
- Xcode 的 **Automatically manage signing** 可以自动生成 App Store provisioning profile；若自动签名失败，再手动创建 profile。
- Runner 的 Bundle ID、Team 和 capabilities 与 Apple Developer 后台一致。首版不启用 Push Notifications capability。

私钥、证书、provisioning profile 和 App Store Connect API key 不要提交到仓库。

## 2. 在 App Store Connect 创建 App

如果 App 已经创建，直接进入下一节。否则：

1. 打开 **Apps**，点击左上角 `+` → **New App**。
2. Platforms：`iOS`。
3. Name：`Happy Pocket`。
4. Primary Language：`Japanese`。
5. Bundle ID：`com.sheanzero.happypocket.app`。
6. SKU：`home-pocket-ios`。SKU 创建后不能修改，但不会向用户展示。
7. User Access：一人公司直接选 `Full Access`。
8. 点击 **Create**。

## 3. 填写 App Store Connect 的共享信息

在 **App Information** 填写：

- Primary Category：`Finance`。
- Secondary Category：可选 `Lifestyle`。
- Content Rights：根据 App 是否展示或访问第三方内容如实回答；当前产品不依赖需要授权的第三方内容。
- Age Rating：点击 **Set Up Age Ratings**，按 App 实际功能回答新问卷。不要预设具体等级，也不要选择 Made for Kids。

在 **Pricing and Availability** 填写：

- Distribution：`Public Distribution`。
- Price：`Free`。
- Availability：`Specific Countries or Regions` → 只选择 `Japan`。
- 本次不做 Pre-Order。

只在日本发布时，不需要为本次首发完成欧盟 DSA trader 展示。以后增加欧盟地区时，再按 App Store Connect 提示补充 DSA 信息。

## 4. 填写商店页面

项目已经准备好三种语言的字段：

- 日语：`publish/ios/metadata/ja/`
- 简体中文：`publish/ios/metadata/zh-Hans/`
- 英语：`publish/ios/metadata/en-US/`
- 共享字段参考：`publish/ios/metadata/app_information.md`

在 **App Information** 添加日语、简体中文和英语本地化，录入 App Name 和 Subtitle。

在 iOS 版本页面逐语言录入：

- Promotional Text；
- Description；
- Keywords；
- Support URL；
- Marketing URL；
- Screenshots。

在版本页面填写 Copyright：`2026 ナープ株式会社`。Privacy Policy URL 在下一节的 **App Privacy** 页面逐语言填写。

首次发布没有 **What’s New in This Version**；这个字段从第二个版本开始填写。

### 截图

当前 target 仅支持 iPhone，所以只需要 iPhone 截图：

- iPhone 6.9 英寸：使用 Apple 接受的 6.9 英寸尺寸之一；当前脚本使用 `1290 × 2796` 竖屏。
- 每个本地化可上传 1–10 张；PNG/JPEG，不能含 Alpha。

本次使用 `docs/mockup/v17/marketing/ja/exports/` 的 10 张日语营销图，规范化为 `1290 × 2796` 后上传日语产品页。简体中文和英语沿用主语言截图回退。

按文件名前缀 `01` 至 `10` 上传；不要上传 golden、Debug 截图或含真实个人数据的图片。本次已人工确认并批准使用上述 V17 营销图。

## 5. 完成 App Privacy 和加密问卷

### 5.1 App Privacy

1. 打开 **App Privacy** → **Get Started**。
2. 以 `publish/ios/privacy/app_privacy_answers.md` 为填写基线，并与最终 App、第三方 SDK 和生产服务的实际行为核对。
3. 本 App 有 family relay 数据流，因此不能选择“No data collected”。
4. 对每种数据填写用途、是否 Linked to User、是否用于 Tracking。
5. Tracking 选择 `No`，前提是最终 Archive 没有广告或跨 App tracking SDK。
6. 填写三种语言的 Privacy Policy URL，预览标签后点击 **Publish**。

### 5.2 加密与出口合规

本 App 自带 SQLCipher、ChaCha20-Poly1305、AES-256-GCM 和 E2EE，不能回答“只使用 Apple 系统加密”。

1. 打开 **App Information** → **App Encryption Documentation** → `+`，或在 build 的 **Missing Compliance** 处点击 **Manage**。
2. 按实际算法、用途和销售地区回答 Apple 问卷。
3. 如果 Apple 判断不需要文件，保存结果，并按 Apple 给出的结论设置 `Info.plist`。
4. 如果 Apple 要求文件，上传所需资料，等待批准后把结果关联到本次 build。
5. `Missing Compliance` 消失后，才能使用该 build 提交审核。

不要自行猜测 `ITSAppUsesNonExemptEncryption=false`。详细技术基线见 `publish/ios/privacy/export_compliance.md`。

## 6. 生成并上传最终 build

### 6.1 定版

1. 确认 `pubspec.yaml` 的版本。当前首发构建为 `1.0.0+3`。
2. Build `1`、`2` 均不用于送审；后续每次重新上传都使用更大的 Build Number。
3. 确保商店截图、描述和审核说明描述的是同一个最终版本。

### 6.2 本地检查

在项目根目录运行：

```bash
flutter pub get
flutter gen-l10n
flutter analyze
flutter test --concurrency=1
bash scripts/release_preflight.sh --platform ios
bash publish/ios/scripts/validate_materials.sh
```

`validate_materials.sh` 在最终截图未准备好时会失败；先补齐截图再继续。

### 6.3 Xcode Archive 与上传

1. 打开 `ios/Runner.xcworkspace`，不要打开 `Runner.xcodeproj`。
2. Scheme 选择 `Runner`，Destination 选择 **Any iOS Device (arm64)**。
3. 在 **Signing & Capabilities** 确认 Team、Bundle ID 和 Release signing。
4. 选择 **Product → Archive**。
5. 在 Organizer 中选择刚生成的 Archive：
   - 先运行 **Validate App**；
   - 查看签名、entitlements、warnings 和 Xcode Privacy Report；
   - 选择 **Distribute App → App Store Connect → Upload**。
6. 等待 App Store Connect 处理 build。处理成功后 build 会出现在 **TestFlight** 和版本页的 Build 选择器中。

无签名的 `--no-codesign` 产物不能上传 App Store。

## 7. TestFlight：只做最终自测

TestFlight 不是提交 App Review 的强制步骤，外部测试审核也不是首次上架的必经步骤。对一人公司，最简单的做法是把已上传 build 加入 Internal Testing，然后自己安装验证一次；不需要组织复杂的内测流程。

至少确认：

- 全新安装、首次启动和三种语言；
- 新增/编辑/删除交易，Daily/Joy、统计和购物清单；
- Face ID/PIN、备份与恢复、照片和语音权限；
- iPhone 布局；
- 双设备创建/加入家庭、批准、同步、离线恢复、退出；
- Privacy、Terms、Support 链接可打开；
- 首版不会请求通知权限；
- 生产 relay 和汇率回退服务可用。

如果 build 显示 `Processing`，先等待；超过 24 小时仍未完成再联系 Apple。出现 `Missing Compliance` 时完成第 5.2 节。

## 8. 选择 build 并提交审核

在 iOS 版本页面：

1. 确认版本号为 `1.0.0`。
2. 选择刚完成自测的 build。
3. 填写 App Review Information：真实姓名、邮箱、电话。
4. Sign-in Required：`No`。本地 nickname/profile 不是远程登录账号。
5. Notes 使用 `publish/ios/review/app_review_notes_en.txt`。确保说明审核员如何体验主要功能和双设备家庭同步。
6. 若邀请码会过期，不要永久写入 Notes；需要时在提交前换成有效测试码，或在审核消息中补充。
7. App Store Version Release 选择 **Manually release this version**。
8. 保存所有字段，解决页面显示的每一个必填错误或 warning。
9. 点击右上角 **Add for Review**。
10. 打开 **Draft Submission**，再次确认版本、build、截图、隐私、加密和审核信息。
11. 点击 **Submit for Review**。

只有点击 **Submit for Review** 后才真正送到 App Review。`Add for Review` 只是把版本加入草稿提交。

## 9. 审核期间怎么处理

- `Waiting for Review`：Apple 已收到但尚未开始。
- `In Review`：正在审核。
- 收到问题或拒绝：在 **App Review** 的消息页面直接回复，说明具体复现步骤。
- 只需修改文字或审核说明时，按 Apple 页面允许的字段直接修改。
- 需要改代码时，修复后提高 Build Number，重新 Archive、上传并选择新 build。
- 如果截图或二进制有误，先从审核中移除，再修正后重新提交。
- 审核期间保持 `sync.happypocket.app`、支持页、隐私页和汇率服务可访问。

## 10. 通过后发布

选择手动发布后，审核通过会进入 `Pending Developer Release`：

1. 最后检查日本商店的名称、截图、隐私标签、价格和 Availability。
2. 确认生产 relay、支持页和隐私页在线。
3. 点击 **Release This Version** → **Confirm**。
4. Apple 说明发布后最多可能需要 24 小时才会在 App Store 出现。
5. 在日本区 App Store 检查产品页，实际下载安装并完成一次首次启动。
6. 取得正式产品页 URL 后，替换官网目前的临时 App Store 搜索链接。

## 最终只看这张清单

- [ ] Apple Developer 会员有效，最新协议已接受。
- [ ] App Store Connect 已创建 App，Bundle ID 正确。
- [ ] 价格为 Free，Public Distribution，只选 Japan。
- [ ] 三语名称、描述、关键词、URL 和截图已填写。
- [x] Age Rating、Content Rights、App Privacy 已完成。
- [x] 加密问卷已完成，build 不再显示 Missing Compliance。
- [x] 最终 build 使用 Xcode 26+、正式签名，Validate App 通过并成功上传。
- [x] TestFlight 自测完成，iPhone 实机验证正常；用户确认无已知问题。
- [x] 已选择 Build 3，审核联系人和 Notes 已填写。
- [x] 已点击 Add for Review，再点击 Submit for Review；当前正在等待审核。
- [ ] 审核通过后已手动 Release，并验证日本商店可下载。

## Apple 官方入口

- [提交 App 的当前工具链要求](https://developer.apple.com/app-store/submitting/)
- [创建 App record](https://developer.apple.com/help/app-store-connect/create-an-app-record/add-a-new-app/)
- [上传 build](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/)
- [App Privacy](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/)
- [加密与出口合规](https://developer.apple.com/help/app-store-connect/manage-app-information/overview-of-export-compliance/)
- [截图规格](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/)
- [提交审核](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-app/)
- [选择发布方式](https://developer.apple.com/help/app-store-connect/manage-your-apps-availability/select-an-app-store-version-release-option/)
