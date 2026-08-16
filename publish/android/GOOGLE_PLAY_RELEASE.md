# Happy Pocket 首次发布到 Google Play

更新日期：2026-08-12

这份文档说明把当前 Android App 提交到 Google Play 并正式上线所需的操作。默认目标是一人运营、免费首发、日本地区、日语主商店页，并提供简体中文和英语本地化。

## 当前发布信息

| 项目 | 当前值 |
|---|---|
| App | Happy Pocket（ハピポケ家族家計簿） |
| Package name | `com.sheanzero.happypocket.app` |
| 首发版本 | `1.0.0` |
| 当前 versionCode | `3`，来自 `pubspec.yaml` 的 `1.0.0+3` |
| 最低 Android | API 24（项目基线；最终 AAB 再确认） |
| 目标 Android | API 36（项目 Flutter 3.44.8 基线；最终 AAB 与 Play Console 再确认） |
| 主要语言 | Japanese |
| 商店语言 | 日语、简体中文、英语 |
| 分类 | Finance |
| 价格 | Free；当前无 IAP、订阅或广告 |
| 首发地区 | Japan |
| 上传格式 | Android App Bundle (`.aab`) |
| 发布方式 | 建议 Managed publishing，审核通过后人工上线 |

Google Play 自 2026-08-31 起要求新 App 和更新 target Android 16 / API 36 或更高。本项目基线已选择 API 36，但是否合规以最终上传 AAB 的 Play Console 检查为准。

## 当前仓库就绪度

| 项目 | 状态 |
|---|---|
| Package name / Firebase Android client | 已统一为 `com.sheanzero.happypocket.app` |
| Release signing 接线 | 已完成；缺密钥或使用 Android Debug certificate 会失败 |
| Upload key | 未在仓库确认；必须由发布者安全创建/保管 |
| AAB/APK release preflight | 已有 `scripts/release_preflight.sh`；最终候选尚须实际执行 |
| 三语 App 内法律文本 | 已有 |
| Hosted Privacy/Terms/Support | URL 已配置；送审前须确认公网部署、内容与最终 App 一致 |
| Data safety 基线 | 已整理到 `privacy/data_safety_answers.md`；需生产复核 |
| Android 真机 | 历史状态为 `NOT_PERFORMED_NOT_CLAIMED`；发布前必须补做 |
| Play Console App / 商店页 / 声明 | 未在仓库确认 |
| Closed test / production access | 取决于开发者账号类型和创建日期 |
| 最终法律审核 | 未完成，属于 pre-store gate |

## 全流程总览

1. 完成 Play Developer 账号、身份验证、协议和 package registration。
2. 创建 Play Console App，并锁定 package name、免费/付费选择和主语言。
3. 创建 upload key，启用 Play App Signing，并离线备份密钥。
4. 完成商店页、Privacy URL、Data safety 和全部 App content 声明。
5. 提高 versionCode，运行项目质量门和签名 release preflight，生成 AAB。
6. 上传到 Internal testing，从 Google Play 安装并在 Android 真机完成测试。
7. 若账号适用，完成 12 名测试者连续 14 天 closed test，申请 production access。
8. 创建 Production release、处理全部错误/警告并送审。
9. 审核通过后用 Managed publishing 人工上线。
10. 上线后检查产品页、安装、Android vitals、服务和隐私链接。

## 0. 发布前不可跳过的门槛

- [ ] `https://happypocket.app/privacy`、`/terms`、`/support` 在无登录、普通移动网络下可访问。
- [ ] 三语隐私政策、App 内法律页、生产 relay/日志/保留策略与 Data safety 一致。
- [ ] Tokusho/operator identity/contact 和最终法律审核已由发布负责人确认。
- [ ] 生产 family relay、汇率服务和支持邮箱可用。
- [ ] 当前候选 commit 固定且工作树干净；不在构建和送审之间换代码。
- [ ] Android API 36 `google_apis` arm64 Emulator 的项目 release gate 已执行，或任何缺失证据被明确阻止发布而不是视为通过。
- [ ] 至少一台受支持 Android 真机使用 Play 分发构建完成首次启动、加密数据库、语音、备份、App Lock 和双设备同步测试。
- [ ] 最终 AAB 在 Play Console 没有 target API、16 KB page size、SDK、权限或设备兼容 blocker。

## 1. 账号和身份准备

1. 登录 [Google Play Console](https://play.google.com/console/)。
2. 确认账号类型是 Organization 还是 Personal，并完成邮箱、电话、地址和付款资料验证。
3. Organization 账号按 Console 要求确认 D-U-N-S、组织名称、网站和联系人一致。
4. 接受当前 Developer Distribution Agreement、Play App Signing 和其他待处理协议。
5. 打开 Android developer verification 页面，确认身份已验证，并确认 package `com.sheanzero.happypocket.app` 已注册或可由 Play 自动注册。
6. 2026-09-30 前完成 package registration；不要等到正式上线当天处理身份差异。

### 新个人账号的额外测试门槛

如果是 **2023-11-13 之后创建的 Personal developer account**：

- 必须运行 closed test；
- 至少 12 名测试者连续 opt-in 14 天；
- 申请 production access 时仍须至少 12 人保持 opt-in；
- 需要回答测试方式、反馈和 production readiness 问题。

Organization 账号或较早的个人账号不要机械套用这条；以当前 Dashboard 显示的 production access 要求为准。

## 2. 创建 Play Console App

在 **Home → Create app**：

1. Default language：`Japanese`。
2. App name：`Happy Pocket`。
3. App or game：`App`。
4. Free or paid：`Free`。
5. Contact email：`support@napu.co.jp`。
6. 接受政策、出口法律和 Play App Signing 声明。
7. 点击 **Create app**。

重要：

- 第一次上传后 `applicationId`/package name 不能更改。
- Free App 可以继续免费，但不能在同一个 App record 中从 Free 改为 Paid；将来收费功能应使用 Google Play Billing 并另行规划。
- 首发仅选择 Japan，减少本次地区合规范围；以后扩区时重新核对隐私、消费者、金融和开发者展示要求。

## 3. 创建并保管 upload key

Play App Signing 使用两把不同用途的密钥：Google 保管用于最终设备 APK 的 app signing key；发布者保管 upload key，用它签署上传的 AAB。首发建议让 Google 生成 app signing key，并使用独立 upload key。

如果还没有 upload key，可用 JDK 17 的 `keytool` 在仓库外创建：

```bash
keytool -genkeypair -v \
  -keystore /secure/offline/path/happy-pocket-upload.jks \
  -keyalg RSA \
  -keysize 4096 \
  -validity 10000 \
  -alias happy-pocket-upload
```

要求：

- 有效期至少 25 年。
- keystore 与密码放入两个独立、加密、可恢复的位置；至少做一份离线备份。
- 不要复用 Android debug keystore。
- 不要提交 `.jks`、`key.properties`、密码或服务账号 JSON。
- 记录 upload certificate 的 SHA-256 指纹；首传后与 Play Console → **App integrity / App signing** 对照。

本地签名配置：

```bash
cp android/key.properties.example android/key.properties
```

然后只在被 Git 忽略的 `android/key.properties` 中填写真实值，或使用 CI secret 提供：

```text
ANDROID_KEYSTORE_PATH
ANDROID_KEYSTORE_PASSWORD
ANDROID_KEY_ALIAS
ANDROID_KEY_PASSWORD
```

项目的 Gradle 配置会拒绝缺失值、不存在的 keystore 和 `CN=Android Debug` 证书，不会回退到 debug 签名。

## 4. 完成商店页面

在 **Grow users → Store presence → Main store listing**（名称可能随 Console UI 调整）填写三种语言：

- App name：最多 30 字符。
- Short description：最多 80 字符。
- Full description：最多 4,000 字符。
- App icon：512 × 512、32-bit PNG、最多 1,024 KB。
- Feature graphic：1024 × 500、JPEG 或无 Alpha 的 24-bit PNG。
- Phone screenshots：至少准备能真实展示当前版本核心流程的截图；可上传最多 8 张。

文案可以从现有 `publish/ios/metadata/{ja,zh-Hans,en-US}/description.txt` 改写，但必须检查 Google 的字符限制和 metadata policy，不能原样假定合规。

截图要求：

- 使用最终 Android UI，不把 iPhone 状态栏、Face ID 文案或 Apple 设备框当作 Android 截图。
- 不出现真实姓名、邀请码、财务数据、设备 ID 或通知内容。
- 日语为默认商店页；简体中文和英语分别建立本地化。
- 不写“#1”“Best”“限时免费”等排名、奖项或价格营销词。
- 图片和描述必须只展示已在最终 AAB 中存在的功能。

联系方式：

- Website：`https://happypocket.app/`
- Email：`support@napu.co.jp`
- Privacy policy：`https://happypocket.app/privacy`

## 5. 完成 App content 与政策声明

打开 **Policy and programs → App content**，清空所有 **Needs attention**。至少处理：

### Privacy policy

- 填入公开、有效、无需登录的 Privacy URL。
- App 请求麦克风且处理家庭同步元数据，隐私政策必须与最终行为一致。

### Ads

- 当前选择 **No**。最终 AAB 不能包含实际展示广告的 SDK 或 house ad 行为。

### App access

- 当前选择“不限制访问/无需登录”。
- 补充 `review/reviewer_test_plan.md` 的说明：本地功能无需账号；App Lock PIN 由审核员本机创建；双设备同步是可选测试路径。
- 若以后加入远程登录、一次性邀请码或付费墙，必须提供长期有效、英语、可重复使用的审核访问方式。

### Target audience and content

- 本产品面向成年人进行家庭财务记录，不要选择儿童年龄段，除非产品和商店素材真的面向儿童并准备满足 Families policy。
- 以 Console 当前可选年龄段和实际营销定位为准，不在仓库中预填一个可能变化的精确年龄组合。

### Content rating

- 如实完成 IARC 问卷。不要预设最终等级；保存后核对商店页等级与功能一致。

### Data safety

- 使用 `privacy/data_safety_answers.md` 作为基线。
- 不选择“完全不收集数据”：relay 可读 display name、device/group identifiers 和运营日志。
- 不把 E2EE 账本正文错误申报为开发者可读明文；Google 明确允许满足条件的 E2EE 数据排除。
- 核对 encryption in transit、deletion URL、service provider、cloud speech fallback 和全部 SDK。

### Financial features

- 所有 App 都必须完成该声明，即使没有 Google 列出的金融功能。
- Happy Pocket 是财务管理/记账工具，但 Console 的选项与 Google “financial features” 分类会更新。逐项检查 banking、loans、payments、wallet、trading、financial advice、insurance、other 等当前选项，按实际选择。
- App 不放贷、不撮合贷款、不转账、不提供投资交易或个性化金融建议；不要误选这些受监管功能。

### 其他 Dashboard 卡片

按当前 Console 提示完成 News、Government、Health、Ads ID、敏感权限等声明。当前 manifest 有 `RECORD_AUDIO`，但没有 SMS、Call Log 或 location 权限；上传 AAB 后以 Play 检出的 merged manifest 为准。

## 6. 定版与版本号

Flutter 从 `pubspec.yaml` 读取：

```yaml
version: 1.0.0+3
```

- `1.0.0` → Android `versionName`。
- `3` → Android `versionCode`。
- 每次向 Play 上传新 AAB，`versionCode` 必须严格增加，即使前一个 AAB 只在 Internal testing 或被拒绝。
- 不要在同一候选中混用 `pubspec.yaml` 版本和临时 `--build-number`，除非发布记录明确保存了覆盖值。
- 商店 release notes、审核测试说明和 AAB 必须对应同一 commit。

## 7. 运行质量门并生成正式 AAB

### 7.1 候选检查

```bash
git status -sb
flutter pub get --enforce-lockfile
flutter gen-l10n
flutter analyze
flutter test --concurrency=1
```

如果本次修改了 Riverpod、Freezed、Drift 或其他 generated inputs，先按项目规则运行受控 codegen，再确认 tracked generated files 与候选一致。

### 7.2 签名预检与打包

配置 JDK 17 和真实 upload key 后运行：

```bash
bash scripts/release_preflight.sh --platform android --package
```

如果本次确实修改了 generator inputs：

```bash
bash scripts/release_preflight.sh --platform android --regenerate --package
```

脚本会：

1. `flutter clean`；
2. 清理可能污染 release 的 dev-only plugin registrant；
3. 重新解析依赖并按需生成代码；
4. 做 Android release metadata smoke compile；
5. 校验 JDK 17；
6. 强制生产签名，生成 AAB 和 APK；
7. 扫描两种产物，拒绝 `integration_test` 污染。

Play 上传文件：

```text
build/app/outputs/bundle/release/app-release.aab
```

APK 只用于本地签名/安装辅助验证，不作为本次 Play 首发上传格式。

### 7.3 产物核对

```bash
jarsigner -verify -verbose -certs build/app/outputs/bundle/release/app-release.aab
shasum -a 256 build/app/outputs/bundle/release/app-release.aab
```

保存候选 commit、versionName/versionCode、AAB SHA-256、upload certificate SHA-256、构建时间和质量门结果。不要在日志中保存 keystore 路径、密码、用户名或设备标识。

如本机已有官方 `bundletool`：

```bash
bundletool dump config \
  --bundle=build/app/outputs/bundle/release/app-release.aab
```

检查输出包含 `PAGE_ALIGNMENT_16K`。本项目包含 Flutter/SQLCipher 等 native libraries，因此 16 KB 兼容必须在 Play Console 和至少一个 16 KB 环境中验证，不能只根据 AGP 版本推断。

## 8. Internal testing：先测试 Play 实际分发包

1. **Testing → Internal testing → Create new release**。
2. 首次 release 启用 Play App Signing。建议让 Google 生成 app signing key；本地签名键成为 upload key。
3. 上传 `app-release.aab`。
4. 查看 App Bundle Explorer：
   - package 为 `com.sheanzero.happypocket.app`；
   - versionCode 正确且未使用过；
   - target API 合规；
   - 64-bit 与 16 KB page size 无 blocker；
   - 权限只包含最终功能需要的项；
   - download size 未超限；
   - SDK warnings 已逐项处理。
5. 填写 release name 和三语 release notes。
6. 添加内部测试邮箱/Google Group，保存 opt-in URL。
7. Review release → Start rollout to Internal testing。
8. 从 Play opt-in URL 安装，不用本地 sideload APK 代替这一步。

### 真机最低测试集

- 全新安装、升级安装、卸载后重装。
- API 24 最低系统代表机/模拟器，以及当前主流 Android 版本真机。
- 首次启动、三语切换、Daily/Joy 新增编辑删除和统计。
- SQLCipher 首开/重开、App Lock、生物识别失败后 PIN fallback。
- 麦克风允许/拒绝、端内语音、用户允许时的 cloud fallback。
- 加密备份导出/恢复和 Android 文件选择/分享面板。
- 双设备建组、邀请、批准、同步、离线恢复、离组；private 内容不泄露。
- 汇率在线、离线缓存和手动汇率。
- Privacy/Terms/Support URL。
- 首版不请求通知权限、不注册 FCM token。
- Android 15/16 edge-to-edge、返回手势、键盘、深色模式和 16 KB 环境。

发现问题后修复、提高 versionCode、重新运行全部 release gate，再上传新 AAB。

## 9. Closed testing 与 production access

如果 Dashboard 要求新个人账号测试：

1. 完成商店设置和 App content 后创建 Closed testing track。
2. 上传已经通过 Internal testing 的新 AAB 或 promote 对应 release。
3. 邀请至少 12 名真实测试者，并确认每个人通过 opt-in 链接加入。
4. 连续保持至少 12 人 opt-in 14 天；不要中途移除或让人数低于 12。
5. 收集并记录反馈、测试设备/Android 版本、发现的问题和修复版本。
6. 条件满足后从 Dashboard 申请 production access，如实回答测试招募、参与、反馈和 readiness。
7. 等待 Google 批准 production access，再创建 Production release。

不要用虚假账号、购买测试者或不可验证的测试记录绕过门槛。

## 10. 创建 Production release 并送审

1. 建议先开启 **Managed publishing**。
2. 打开 **Production → Create new release**。
3. 选择已通过测试的 AAB，或从测试轨道 promote 同一 artifact。
4. 确认 Play App Signing 的 app signing/upload certificate 指纹已安全记录。
5. 填写 release name 和 What’s new。
6. 点击 **Next / Review release**，解决 Errors summary 中全部错误。
7. 逐项检查国家/地区仅 Japan、免费价格、设备目录排除、商店页、本地化、Data safety、App content 和审核访问说明。
8. 点击 **Start rollout to Production / Send for review**（实际文案以当前 Console 为准）。
9. 在 Publishing overview 确认所有需要审核的变更已一并提交。

审核期间：

- 保持 relay、Privacy/Terms/Support、汇率服务和支持邮箱在线。
- 关注 Policy status、Publishing overview 和账号邮箱。
- 只需改元数据时按 Console 允许的方式更新；需要改二进制时提高 versionCode 并重走构建/测试流程。
- 不要因为 Internal track 能安装就认为 Production 审核已通过。

## 11. 审核通过和上线

使用 Managed publishing 时，审核通过不会立即公开：

1. 在 Publishing overview 检查所有变更显示 ready to publish。
2. 再次确认 Japan、Free、三语页面、隐私标签、权限和最终 artifact。
3. 确认生产服务与支持渠道健康。
4. 点击 **Publish changes**。
5. 等待商店传播完成，在日本区 Google Play 搜索并打开正式产品页。
6. 用未加入测试轨道的账号/设备验证公开可见性、安装和首次启动。
7. 记录正式 Play URL，并替换官网临时 Google Play 链接。

## 12. 上线后 72 小时

- 检查 Android vitals：crash、ANR、启动、权限拒绝和受影响设备。
- 检查 Play Console Policy status、用户评论和支持邮箱。
- 检查 relay error rate、清理任务、数据库/日志保留和汇率服务，不查看或记录用户财务正文。
- 验证隐私/支持 URL 与商店 Data safety 仍一致。
- 保留 AAB、SHA-256、source commit、Play release/versionCode、签名证书指纹和质量门报告；不要把私钥或密码放进 release evidence。
- 如出现严重问题，使用 Play 的停止 rollout/新修复版能力；已公开的 versionCode 不能复用。

## 最终发布清单

- [ ] Play Developer 身份、协议和 package registration 完成。
- [ ] App record 使用 `com.sheanzero.happypocket.app`、Japanese、App、Free。
- [ ] Upload key 已双重加密备份；Play App Signing 已启用。
- [ ] Hosted Privacy/Terms/Support、operator values、支持邮箱和最终法律审核完成。
- [ ] 日/中/英商店文案、512 icon、1024×500 feature graphic、Android 截图完成。
- [ ] Ads、App access、Target audience、Content rating、Data safety、Financial features 等 App content 全部完成。
- [ ] versionCode 高于所有历史上传值。
- [ ] `flutter analyze`、完整测试、release preflight 和签名验证通过。
- [ ] Play Console 的 API 36、64-bit、16 KB、SDK、权限和设备检查无 blocker。
- [ ] Internal testing 使用 Play 分发包在 Android 真机完成。
- [ ] 如账号适用，12 名测试者连续 14 天 closed test 和 production access 完成。
- [ ] Production release 已送审，Managed publishing 已开启。
- [ ] 审核通过后已人工发布，并完成日本区公开安装检查。
