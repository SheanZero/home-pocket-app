# App Store Connect — 共享信息

| 字段 | 建议值 | 状态 |
|---|---|---|
| Primary Language | Japanese | Ready |
| Bundle ID | `com.sheanzero.happypocket.app` | Ready；必须与 archive 一致 |
| SKU | `home-pocket-ios` | 建议值；创建后不可修改 |
| Primary Category | Finance | Ready |
| Secondary Category | Lifestyle | Optional |
| Price | Free | Ready；当前无 IAP/Subscription |
| Made for Kids | No | Ready |
| Age Rating | 由当前问卷计算 | 待在 App Store Connect 按实际功能填写；不预设结果 |
| Content Rights | No third-party content requiring rights | 提交前按实际内容确认 |
| Copyright | `2026 ナープ株式会社` | Ready |
| Release | Manual | 推荐首发采用 |
| Sign-in required | No | Ready；本地 profile 不是远程登录账号 |
| Privacy Policy URLs | 日语 `/privacy`；中文 `/zh/privacy`；英文 `/en/privacy` | 页面已定稿，待公开可访问性核验 |
| Support URL | 日语 `/support`；中文 `/zh/support`；英文 `/en/support` | 页面已补齐联系与隐私请求流程 |
| Marketing URL | 日语 `/`；中文 `/zh/`；英文 `/en/` | Ready |

## Localization 映射

| App Store locale | 目录 | App name | Subtitle |
|---|---|---|---|
| Japanese | `ja/` | Happy Pocket | 家族で共有できる安心の家計簿 |
| Simplified Chinese | `zh-Hans/` | 快乐账本 | 本地优先的家庭共享记账本 |
| English (U.S.) | `en-US/` | Happy Pocket: Home Ledger | Secure, shared family budget |

## 产品口径

- “日常 / 悦己（ときめき）/ Daily / Joy”遵循 ADR-015/016，不使用 Joy/¥、ROI、密度、streak、achievement 或庆祝式达标文案。
- 描述 family sync 时使用“端到端加密 + 零知识中继”，不使用“设备直连”“服务器从不保存”等不准确绝对表述。
- 不承诺 cloud-free。多币种汇率、family relay 和可选语音网络降级会产生对外通信；首版停用 APNs/FCM。
- 不宣称绝对安全、不可破解或零风险。

## URL 核验快照

- `https://happypocket.app/`：Happy Pocket 正式产品域名；日语使用根路径，简体中文使用 `/zh/`，英语使用 `/en/`。
- 三语 Support URL 与 Privacy URL 均使用 App 专用页面，不再引用开发者个人主页。
- 上架前确认公开 DNS、TLS 和各页面在日本可访问。
