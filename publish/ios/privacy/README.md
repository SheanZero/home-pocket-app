# Privacy deliverables

- `app_privacy_answers.md` 是基于客户端代码的保守 App Store Connect 答题稿。
- `export_compliance.md` 是出口合规判断流程，不是法律结论。
- `PrivacyInfo.xcprivacy.template` 与 `ios/Runner/PrivacyInfo.xcprivacy` 保持同一份代码证据口径：可由 relay 读取的姓名/显示名、用户 ID、设备 ID 和其他用户内容；不申报照片、交易金融内容或 tracking。
- Runner manifest 已作为 Runner resource 打包。第三方 SDK 的 manifest 由其自身 bundle 提供，不能把 SDK 的 Required Reason API 复制到 app manifest。

使用模板前必须：

1. 从最终 Archive 生成 Xcode Privacy Report。
2. 核对生产 relay、反向代理和第三方服务的真实数据与保留策略。
3. 确认所有 Required Reason API 由 app 或相应 SDK manifest 正确声明。当前 Runner 原生代码没有 Required Reason API；最终 Swift Package 依赖的 `shared_preferences_foundation` 声明 User Defaults / `1C8F.1`，`firebase_messaging` 与 `flutter_local_notifications` 声明 User Defaults / `CA92.1`。
4. 不要因为 relay 的 E2EE 密文而推测申报 Financial Info。其是否属于 App Store Connect 的 Collect 定义必须由运营/法务以最终服务端保留和 Apple 最新指引确认；这一未决项不写入本 app manifest。
5. 让 App Privacy、最终 `PrivacyInfo.xcprivacy`、三语政策和 App Review Notes 完全一致。
6. 用 `plutil -lint` 验证，并从最终 Archive 生成 Privacy Report。
