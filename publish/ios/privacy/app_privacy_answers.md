# App Store Connect App Privacy — 运营确认基线

状态：**已按首版产品行为更新；提交前仍须与生产配置和 Xcode Privacy Report 逐项核对。**

Apple 将“Collect”定义为：数据被传出设备，并允许开发者或第三方在完成实时请求所需时间之外访问。Happy Pocket 的 family relay 会保留设备/组元数据，并暂存消息，因此总问题应答 **Yes, we collect data from this app**。首版不启用 APNs/FCM，收集判断来自 relay 数据流，而不是推送令牌。

## 已从客户端代码确认的数据流

| 流程 | 发送内容 | 目的 | 保留/可读性 |
|---|---|---|---|
| Device registration | device ID、公钥、device name、platform | 设备身份与安全认证 | relay 可读；不活跃设备记录保留90日 |
| Family group | group ID/name、display name、avatar emoji/hash、邀请/成员状态 | 家庭组创建与成员管理 | relay 可读；组控制事件保留90日 |
| Push | 首版不注册或发送 APNs/FCM token | — | 首版停用 |
| Sync | 加密 payload、vector clock、operation count、group/device identifiers | 家庭同步 | 内容 E2EE 不可解密；消息最多7日并在 ACK 后提前删除；备份14日、幂等记录7日 |
| Exchange rate | currency/date 等查询参数 | 多币种换算 | 不包含交易金额、备注或身份；第三方日志/IP 仍需核对 |
| Voice | 优先 on-device；可选 system network fallback | 语音转文字 | 开发者不存储音频；Apple/system 行为与用户开关需核对 |
| Local-only | 照片、未共享账本、private shopping item | 端内功能 | 不传出设备 |

## 建议的 App Privacy 选择

以下采用“宁可多披露，不把中继传输误写成纯端内”的保守口径。最终答案要与生产服务端保留策略和 Xcode Privacy Report 对齐。

| Apple data type | Collected | Linked to user | Tracking | Purpose | 依据/备注 |
|---|---:|---:|---:|---|---|
| Contact Info > Name | Yes | Yes | No | App Functionality | app 要求 nickname/display name，family relay 接收 display/device name；用户可能填写真实姓名 |
| Identifiers > User ID | Yes | Yes | No | App Functionality | group/account-level identifiers、group membership |
| Identifiers > Device ID | Yes | Yes | No | App Functionality | app-generated device ID、公钥标识；首版不收集 APNs/FCM token |
| User Content > Other User Content | Yes | Yes | No | App Functionality | group name/avatar metadata 明文；notes/merchant/shopping 等共享内容以 E2EE payload 传输 |
| Financial Info > Purchase History | No | — | — | — | 家庭交易记录仅以 E2EE 密文暂存；中继没有密钥，无法以可读形式访问内容，不符合 Apple 对“Collect”的定义 |
| Financial Info > Other Financial Info | No | — | — | — | 收支、预算等仅以 E2EE 密文暂存；中继无法以可读形式访问内容 |
| Photos or Videos | No | — | — | — | 头像图片在客户端以 hash/本地内容处理；receipt photo 不同步。确认服务端从不接收图像本体 |
| Audio Data | No by developer | — | — | — | 开发者不存储音频；system network speech fallback 需按 Apple framework 指引和最终设置复核 |
| Product Interaction / Usage | No | — | — | — | iOS 未发现 analytics 使用；以 archive/SDK report 为准 |
| Crash / Performance / Diagnostics | No | — | — | — | 未集成 crash analytics；核对所有 SDK manifest 与服务端日志 |
| Location | No | — | — | — | app 不请求位置；若服务端长期保存 IP 并推导位置，必须更新 |
| Customer Support | 视支持页流程 | 视流程 | No | App Functionality | 当前支持在 app 外部网页；若开发者保存邮件/表单内容，应按实际支持流程申报 |

## Tracking / ATT

- Tracking：**No**。
- `NSPrivacyTracking`：false。
- Tracking domains：none。
- ATT prompt：不需要，前提是最终 archive 没有广告/跨 app tracking SDK 或 advertising identifier 使用。

## App Store Connect 操作

1. App Privacy > Get Started > **Yes, we collect data from this app**。
2. 添加 4 类最终确认的数据：Name、User ID、Device ID、Other User Content。
3. 每一类填写：App Functionality、Linked to User、Not used for Tracking。
4. 录入各语言公开 Privacy Policy URL。
5. 在 Product Page Preview 检查最终标签。
6. 点击 Publish；首发 app 会随产品页上线。

## 送审前证据

- [ ] 生产 relay 数据库 schema 与已确认的 7/14/7/90/90 日保留及 ACK 提前删除任务一致。
- [ ] 反向代理/application logs 与政策一致：不记录请求正文，日志30日自动轮转并永久删除。
- [x] 首版 APNs/FCM 自动注册、通知权限和 push capability 已停用。
- [ ] 汇率供应商及请求参数、日志/隐私条款。
- [ ] iOS archive 的 Xcode Privacy Report 与所有第三方 SDK manifests。
- [ ] `Podfile.lock` / Flutter plugins 中是否出现 analytics、ads、crash reporting。
- [ ] voice on-device fallback 的默认值、用户控制与 Apple Speech 数据处理。
- [x] App Store Connect 草稿已与 Build 3 的 `PrivacyInfo.xcprivacy` 对齐：4 类数据，均用于 App Functionality、Linked to User、Not used for Tracking。
- [ ] 最终三语隐私政策与上述表格逐行一致。

## 关键原则

零知识/E2EE 说明的是**内容不可被中继解密**。按 Apple 当前口径，App Privacy 的“收集”要求数据以可读形式被保留，因此不把中继无法解密的账本密文申报为 Purchase History 或 Other Financial Info；中继可读的姓名、标识符和其他用户内容仍须申报。App Privacy、隐私政策、审核 Notes 和服务端真实行为必须同时成立。
