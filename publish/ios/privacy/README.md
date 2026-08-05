# Privacy deliverables

- `app_privacy_answers.md` 是基于客户端代码的保守 App Store Connect 答题稿。
- `export_compliance.md` 是出口合规判断流程，不是法律结论。
- `PrivacyInfo.xcprivacy.template` 是**未接入 target 的讨论稿**，不是最终 manifest。

使用模板前必须：

1. 从最终 Archive 生成 Xcode Privacy Report。
2. 核对生产 relay、反向代理和第三方服务的真实数据与保留策略。
3. 确认所有 Required Reason API 由 app 或相应 SDK manifest 正确声明。
4. 让 App Privacy、最终 `PrivacyInfo.xcprivacy`、三语政策和 App Review Notes 完全一致。
5. 用 `plutil -lint` 验证，加入 Runner target resources，再重新 Archive 验证。
