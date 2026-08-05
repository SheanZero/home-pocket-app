# Apple App Store 发布步骤

## 0. 先完成发布门禁

1. 逐项关闭 [RELEASE_GATES.md](RELEASE_GATES.md) 的 P0。
2. 将首发 commit/tag、版本号、Build Number、支持地区、发布负责人写入发布记录。
3. 运行：

   ```bash
   bash publish/ios/scripts/validate_materials.sh
   ```

4. 确认输出为 `PASS`；任何 `BLOCKER` 都不得带入送审。

## 1. Apple Developer / App Store Connect 准备

1. 确认 Apple Developer Program 会员有效，最新协议已接受。
2. Certificates, Identifiers & Profiles 中确认 App ID：
   - Bundle ID：`com.sheanzero.happypocket.app`
   - Push Notifications：首版不启用
   - Team ID：`6Y64KR8RLP`
3. 在 App Store Connect 创建 App record：
   - Platforms：iOS
   - Primary language：Japanese
   - Bundle ID：上面的显式 App ID
   - SKU：建议 `home-pocket-ios`（创建后不可修改，最终值由负责人确认）
   - User Access：按团队权限选择
4. 完成 App Information：
   - Primary Category：Finance
   - Secondary Category：Lifestyle（可选）
   - Content Rights：不展示未经授权的第三方内容
   - Age Rating：按新问卷如实填写；预计为低龄级别，但以 App Store Connect 计算为准，不标记 Made for Kids
   - DSA / 地区监管项：仅对计划上架地区填写

## 2. 定版元数据、法务和隐私

1. 将 `metadata/{ja,zh-Hans,en-US}/` 的内容逐语言录入 App Store Connect。
2. 填写真实 Support URL、Marketing URL、Privacy Policy URL；Support URL 必须能看到实际联系方式。
3. 对照最终生产行为完成 App Privacy：
   - 以 `privacy/app_privacy_answers.md` 为起点；
   - 包含 app 自身及所有第三方 SDK；
   - 明确 linked / tracking / purpose；
   - Publish App Privacy answers。
4. 完成出口合规问卷；若 Apple 要求文件，先获批并绑定到 build。
5. 完成 Age Rating 新问卷。
6. 免费首发建议：Price = Free；不配置 IAP/Subscription。

## 3. 最终构建前 QA

1. 确认工作区只包含预期发布改动，并锁定发布 commit。
2. 更新版本，例如首发决定为 `1.0.0+1` 时修改 `pubspec.yaml`；后续每次上传必须增加 Build Number。
3. 若 ARB、Riverpod、Freezed、Drift 输入有变化，按项目规范重新生成。
4. 执行质量门禁：

   ```bash
   flutter pub get
   flutter gen-l10n
   flutter analyze
   flutter test --concurrency=1
   ```

5. 先运行确定性的 clean preflight；它会重新生成 plugin registrant、用
   `--no-codesign` 做 profile smoke compile，并拒绝残留的
   `integration_test` dev plugin：

   ```bash
   bash scripts/release_preflight.sh --platform ios
   ```
6. 在 iOS 15 与 iOS 26、iPhone 与 iPad 上完成关键路径真机/模拟器测试。
7. 用最终 Release build、固定演示数据采集 `screenshots/` 要求的三语截图。

## 4. 生成 Archive / IPA

推荐优先用 Xcode Organizer，以便查看签名、Privacy Report 和上传诊断。

### 方式 A：Xcode Organizer

1. 打开 `ios/Runner.xcworkspace`。
2. Scheme 选择 Runner，Destination 选择 Any iOS Device (arm64)。
3. Runner > Signing & Capabilities：确认 Team、Bundle ID、Release provisioning，并确认首版没有 Push Notifications capability。
4. Product > Archive。
5. 在 Organizer 中：
   - Validate App；
   - 生成并检查 Privacy Report；
   - 检查 app thinning / symbols / signing；
   - Distribute App > App Store Connect > Upload。

### 方式 B：Flutter CLI 生成 IPA

在版本号已定版后运行：

```bash
# Preflight first; add --regenerate if this release changed ARB/Riverpod/
# Freezed/Drift generator inputs. --package is the separately signed IPA step.
bash scripts/release_preflight.sh --platform ios --package
```

上传前仍需在 Xcode Organizer 或 `xcrun altool`/Transporter 中验证签名和合规结果。不要把无签名的 `--no-codesign` 产物用于 App Store。

## 5. TestFlight 验收

1. 等待 build processing 完成并检查所有 warning；超过 24 小时仍 Processing 时联系 Apple。
2. 处理 Missing Compliance（加密）状态。
3. 填写 `review/testflight_what_to_test.txt`。
4. 先内部测试，再视需要提交 TestFlight 外部测试审核。
5. 至少验证：
   - 全新安装与三语 onboarding；
   - 本地记账、编辑、删除、备份/恢复；
   - 日常/悦己口径、统计、购物清单；
   - 语音 on-device 与网络降级开关；
   - Face ID/PIN；
   - 双设备家庭加入、批准、同步、离线恢复、退出；
   - 首版不请求通知权限、不注册 APNs token，家庭同步仍正常；
   - 隐私/条款/支持外链；
   - iPad 布局和旋转；
   - 删除本地数据与组成员数据的实际效果。

## 6. 填写版本页面

1. 上传 iPhone 6.9 英寸和 iPad 13 英寸截图；当前 target 同时支持两类设备。
2. 录入 Promotional Text、Description、Keywords、Support URL、Marketing URL。
3. 首次版本不显示 “What’s New”；后续版本再填写。
4. 填写 Copyright。
5. 选择已验收 build。
6. 填写 App Review Information：真实姓名、邮箱、电话和 `review/app_review_notes_en.txt`。
7. Sign-in Required：No。若审核家庭同步需要第二设备，上传双设备操作视频，并确保后端在审核期间可用。
8. Version Release 建议首发选择 Manual，获批后由负责人确认再放量。

## 7. 提交审核

1. 在版本页右上角点击 **Add for Review**。
2. 在 Draft Submission 中复核版本、build、截图、隐私、加密和审核说明。
3. 点击 **Submit for Review**。
4. Waiting for Review 后截图不可再编辑；如发现错误，先 Remove from Review 再修正。
5. 审核消息统一由发布负责人响应，任何补充说明都与隐私政策和实际行为保持一致。

## 8. 获批与发布

1. Pending Developer Release 时再次验证生产后端、支持页、隐私页和商店展示。
2. 由发布负责人手动 Release。
3. 发布后在日本/中国大陆以外目标区分别检查本地化、下载、首次启动和深色/浅色展示。
4. 记录 App Store version、build、Apple ID、发布日期、审核往返、已知问题和回滚方案。
5. 监控崩溃、评论、支持邮箱和同步服务；隐私处理变化时立即更新 App Privacy answers 与政策。
