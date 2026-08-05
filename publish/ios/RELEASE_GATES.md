# iOS 发布门禁（当前：NO-GO）

以下结论基于 2026-08-05 的工作区快照。P0 未全部关闭前，不要上传生产候选包或点击 Submit for Review。

## P0 — 必须关闭

- [ ] **法律文本定稿。** `legal/current-drafts/` 的 9 份文件仍含“草案”、`support@example.com`、`[上线前填真实值]` 等内容。完成日本法务复核，替换真实主体、地址、电话、邮箱、生效日期，并同步回 `assets/legal/`。
- [ ] **托管隐私政策 URL 上线。** 三语页面已配置为 `https://happypocket.app/{locale}/privacy/`，但仍需确认正式 DNS、TLS、目标地区可访问性和法务定稿；App 内离线文档不能替代已验证的公开 URL。
- [ ] **App 专用 Support URL 上线。** 三语页面已配置为 `https://happypocket.app/{locale}/support/`，但正式 DNS 尚待验证，页面也仍需补齐已确认的运营方邮箱与隐私请求流程。
- [ ] **隐私政策与 relay 实际行为一致。** 当前政策写“设备直连、服务器不保存”，而客户端使用 `sync.happypocket.app` 中继，并在服务端暂存加密消息直至 ACK/过期；服务端还接收 device ID、公钥、设备名、显示名、组名、头像摘要和 APNs token。必须改为真实、可验证的保留与删除口径。
- [ ] **修正 onboarding 的绝对隐私声明。** `onboardingPrivacySubtitle` / `onboardingPrivacyCardLocalBody` 仍含“Everything stays on your device / Never sent to the cloud”等绝对表述，与家庭同步、汇率请求及可选云端语音识别不一致。
- [ ] **披露语音识别降级路径。** 代码优先使用 on-device speech recognition，但允许在设备侧识别失败时降级到网络识别。最终隐私政策、权限前置说明和 App Review Notes 必须与最终开关一致。
- [ ] **App Privacy 最终确认。** 以 `privacy/app_privacy_answers.md` 为保守起点，结合生产 relay 的数据保留、日志、IP、推送 token 和第三方 SDK 行为完成最终申报。不要直接沿用旧的“只申报 push token”清单。
- [ ] **出口合规结论。** App 自带 SQLCipher、AES-256-GCM、ChaCha20-Poly1305、Ed25519/E2EE，不是“仅使用 Apple OS 加密”。按 `privacy/export_compliance.md` 完成 Apple 问卷及必要的自分类/文件审查；结论未确认前不要添加 `ITSAppUsesNonExemptEncryption=false`。
- [ ] **版本号定版。** 当前 `pubspec.yaml` 为 `0.1.0+1`，而项目文档描述多个已完成里程碑。发布负责人需决定首发 Marketing Version 与递增 Build Number，并让 pubspec、归档和 App Store Connect 一致。
- [ ] **iPad 发布策略定版。** 当前 target 同时支持 iPhone 和 iPad，因此 App Store 必须提交 13 英寸 iPad 截图。若产品未做 iPad 真机/模拟器验收，先决定是完成适配和截图，还是在代码变更中正式改为 iPhone-only。
- [ ] **最终商店截图。** 现有 golden 使用测试字体/图标替身，只能作布局参考，不能上传。必须从最终 Release build 采集无敏感数据的 iPhone 6.9 英寸和 iPad 13 英寸截图。
- [ ] **照片权限核对。** App 的头像选择使用 `ImageSource.gallery`，但 `Info.plist` 当前没有 `NSPhotoLibraryUsageDescription`。以最终 `image_picker` 行为在 iOS 15+/iOS 26 真机验证；如果系统请求权限，补齐三语用途说明后再构建。
- [ ] **Xcode Privacy Report / manifest 通过。** `ios/Runner/` 当前没有 app-level `PrivacyInfo.xcprivacy`。先从 Archive 生成 Privacy Report，核对所有 SDK manifest、Required Reason API 和收集类型；`privacy/PrivacyInfo.xcprivacy.template` 只能作为初稿，不能直接复制后送审。
- [ ] **全量质量门禁绿色。** 当前代码健康报告记录全量测试、golden/架构契约和部分 lint/覆盖率门禁仍有失败。发布候选 commit 必须通过 `flutter analyze`、目标测试、全量测试及 iOS Release 构建。
- [ ] **生产后端可审核。** `https://sync.happypocket.app`、推送和汇率服务在审核期间稳定可用；准备双设备操作视频或审核附件说明家庭同步流程。

## P1 — 强烈建议首发前关闭

- [x] `CFBundleDisplayName` 三语统一为 `Happy Pocket`；麦克风、语音识别、Face ID 权限说明保持 `ja`、`zh-Hans`、`en` 本地化，并由架构测试锁定 key parity 与 Xcode Resources 引用。
- [x] iOS 最低版本已统一为 15.0：Podfile、Xcode、项目文档、官网、商店介绍和真机测试矩阵口径一致。
- [ ] 在真机验证 Face ID、麦克风、语音识别、照片选择、APNs、后台推送、加密数据库、备份导入导出、家庭加入/退出/删除。
- [ ] 若在 EU 上架，完成 Digital Services Act trader/non-trader 状态与展示信息；若首发不需要，先缩小地区范围。
- [ ] 确认“开发を応援する”外链仅为无权益打赏，不销售数字商品，不绕过 IAP；让审核说明与实际落地页一致。
- [ ] 建立发布后支持流程：可联系邮箱、隐私请求、崩溃反馈、紧急下架/回滚负责人。

## 已通过的基础项

- [x] 当前分支为 `main`；本包只新增 `publish/ios/`，未覆盖工作区既有改动。
- [x] App Store 1024 图标存在，1024×1024、RGB、无 Alpha。
- [x] Bundle ID 在 Runner Release 配置中一致：`com.sheanzero.happypocket.app`。
- [x] 当前机器 Xcode 26.2，满足 2026-04-28 起的最低上传工具链要求。
- [x] Release configuration 使用 production APNs environment。
