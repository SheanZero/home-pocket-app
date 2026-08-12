# App Encryption / Export Compliance 判断清单

状态：**Build 3 已在 App Store Connect 完成问卷。本文不是法律意见。**

2026-08-12 实际填写结果：

- 加密类型：与 Apple 操作系统加密同时使用的标准加密算法。
- 法国分发：否（首发仅日本）。
- App Store Connect 结果：无需上传法国声明或 CCATS；Build 3 的 Missing Compliance 已解除。
- Build 3 已关联 App Store 版本 1.0，并加入 TestFlight 内部群组“首发自测”。
- 当前二进制未加入 `ITSAppUsesNonExemptEncryption`；后续版本如需用该键跳过问卷，应继续按当时算法、地区和 Apple 结论复核。

## 已确认的加密能力

Happy Pocket 不只使用 Apple 系统提供的 TLS：

- SQLCipher database encryption（AES-256 系列）
- ChaCha20-Poly1305 field/E2EE encryption
- AES-256-GCM file/backup encryption
- Ed25519 request/device authentication
- secure key storage / biometric-gated app lock
- TLS / WebSocket TLS

因此：

- “Does your app use encryption?” → **Yes**
- “Is the encryption limited to Apple OS encryption?” → **No**
- 不要在未完成判断前把 `ITSAppUsesNonExemptEncryption` 写成 `false`

## App Store Connect 操作

1. App Information > App Encryption Documentation > `+`，或在 build 的 Missing Compliance 处点击 Manage。
2. 逐项按标准算法、用途、销售地区回答 Apple 问卷。
3. 若 Apple 判断无需文件，保存问卷结果，并根据 Apple 给出的结论设置 Info.plist。
4. 若需要文件，上传自分类/CCATS/其他要求文件，等待批准后把 approval key 绑定到 build。
5. 若发行地区包含法国等有额外要求的市场，单独确认进口/申报义务。
6. 保存本次问卷结果和 Apple approval key（如有），但不要把账号敏感信息写入仓库。

## 提交时需要确认

- [ ] 加密是否全部为已公开标准算法，无 proprietary/non-standard crypto？
- [ ] app 的主要功能是否被 Apple/BIS 视为 information security / encrypted communications？
- [ ] mass-market / ENC exemption 或其他分类是否适用？
- [ ] 是否需要 BIS annual self-classification report？
- [ ] 首发销售地区是否触发法国或其他国家/地区的额外加密申报？
- [ ] App Store Connect 是否返回 documentation required？
- [ ] 最终应使用 `ITSAppUsesNonExemptEncryption`、Apple approval key，还是每个 build 回答问卷？

Apple 官方入口：

- https://developer.apple.com/help/app-store-connect/manage-app-information/overview-of-export-compliance
- https://developer.apple.com/help/app-store-connect/manage-app-information/determine-and-upload-app-encryption-documentation
