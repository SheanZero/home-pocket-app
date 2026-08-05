# iOS 发布门禁（当前：NO-GO）

以下结论基于 2026-08-05 的工作区快照。P0 未全部关闭前，不要上传生产候选包或点击 Submit for Review。

## P0 — 必须关闭

- [x] **法律文本定稿。** `legal/current/` 与 `assets/legal/` 的 9 份三语文本已替换真实主体、地址、电话、邮箱和生效规则，并通过草案/占位符扫描。
- [ ] **专业法务复核。** 运营方已批准首发正式版本，但尚未由日本执业法律专业人士审阅；送审前决定接受该风险或取得书面复核。
- [ ] **托管隐私政策 URL 上线。** 日语 `https://happypocket.app/privacy`、中文 `/zh/privacy`、英文 `/en/privacy` 已定稿，但仍需确认正式 DNS、TLS 和目标地区可访问性。
- [ ] **App 专用 Support URL 上线。** 三语页面已写入运营方邮箱和30日隐私请求流程，但仍需确认正式 DNS、TLS 和目标地区可访问性。
- [x] **隐私政策与 relay 口径对齐。** 文本已披露 E2EE 消息暂存、ACK/过期删除、运用元数据、30日日志、14日备份与腾讯云日本东京区域。
- [ ] **生产 relay 配置核验。** 上线环境必须实际关闭 PostgreSQL bind 参数日志，并落实30日自动永久删除日志；仓库内不含生产服务器配置，需部署证据。
- [x] **修正 onboarding 的绝对隐私声明。** 三语文案改为“明文账务留在设备、选定共享数据加密同步”。
- [x] **披露语音识别降级路径。** 三语隐私政策说明用户允许时 Apple/Google OS 语音服务可能处理音频。
- [ ] **App Privacy 最终确认。** 以 `privacy/app_privacy_answers.md` 为运营确认基线，结合生产 relay 的数据保留、日志、IP 和第三方 SDK 行为完成最终申报；首版不收集推送 token。
- [ ] **出口合规结论。** App 自带 SQLCipher、AES-256-GCM、ChaCha20-Poly1305、Ed25519/E2EE，不是“仅使用 Apple OS 加密”。按 `privacy/export_compliance.md` 完成 Apple 问卷及必要的自分类/文件审查；结论未确认前不要添加 `ITSAppUsesNonExemptEncryption=false`。
- [ ] **版本号定版。** 当前 `pubspec.yaml` 为 `0.1.0+1`，而项目文档描述多个已完成里程碑。发布负责人需决定首发 Marketing Version 与递增 Build Number，并让 pubspec、归档和 App Store Connect 一致。
- [ ] **iPad 发布策略定版。** 当前 target 同时支持 iPhone 和 iPad，因此 App Store 必须提交 13 英寸 iPad 截图。若产品未做 iPad 真机/模拟器验收，先决定是完成适配和截图，还是在代码变更中正式改为 iPhone-only。
- [ ] **最终商店截图。** 现有 golden 使用测试字体/图标替身，只能作布局参考，不能上传。必须从最终 Release build 采集无敏感数据的 iPhone 6.9 英寸和 iPad 13 英寸截图。
- [x] **照片权限说明。** App 的头像选择使用 `ImageSource.gallery`；`Info.plist` 和 `ja` / `zh-Hans` / `en` `InfoPlist.strings` 均已提供最小化的 `NSPhotoLibraryUsageDescription`。不请求 add-only 权限；照片选择真机验证仍属于下方 P1 设备验收。
- [ ] **Xcode Privacy Report / manifest 通过。** `ios/Runner/PrivacyInfo.xcprivacy` 已作为 Runner resource 打包，且仅声明代码证实的 relay 元数据、无 tracking 和无 app-owned Required Reason API。仍须从最终 Archive 生成 Privacy Report，核对 SDK manifests、最终服务端保留和 App Store Connect 收集口径；不要仅凭 E2EE 密文推测 Financial Info 申报。
- [ ] **全量质量门禁绿色。** 当前代码健康报告记录全量测试、golden/架构契约和部分 lint/覆盖率门禁仍有失败。发布候选 commit 必须通过 `flutter analyze`、目标测试、全量测试及 iOS Release 构建。
- [ ] **生产后端可审核。** `https://sync.happypocket.app` 和汇率服务在审核期间稳定可用；准备双设备操作视频或审核附件说明家庭同步流程。首版不使用推送。

## P1 — 强烈建议首发前关闭

- [x] `CFBundleDisplayName` 三语统一为 `Happy Pocket`；麦克风、语音识别、Face ID 权限说明保持 `ja`、`zh-Hans`、`en` 本地化，并由架构测试锁定 key parity 与 Xcode Resources 引用。
- [x] iOS 最低版本已统一为 15.0：Podfile、Xcode、项目文档、官网、商店介绍和真机测试矩阵口径一致。
- [ ] 在真机验证 Face ID、麦克风、语音识别、照片选择、加密数据库、备份导入导出、家庭加入/退出/删除；APNs/FCM 延至后续版本。
- [ ] 若在 EU 上架，完成 Digital Services Act trader/non-trader 状态与展示信息；若首发不需要，先缩小地区范围。
- [x] 首版隐藏“开发を応援する”入口，且不提供付费、捐助、赞助、数字商品或功能解锁。
- [ ] 建立发布后支持流程：可联系邮箱、隐私请求、崩溃反馈、紧急下架/回滚负责人。

## 已通过的基础项

- [x] 当前分支为 `main`；本包只新增 `publish/ios/`，未覆盖工作区既有改动。
- [x] App Store 1024 图标存在，1024×1024、RGB、无 Alpha。
- [x] Bundle ID 在 Runner Release 配置中一致：`com.sheanzero.happypocket.app`。
- [x] 当前机器 Xcode 26.2，满足 2026-04-28 起的最低上传工具链要求。
- [x] 首版已移除 iOS push entitlement/background mode，并关闭 Firebase Messaging 自动注册；实现代码保留供后续版本升级。
