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
| Age Rating | 由 2026 新问卷计算 | 待账号持有人填写；预计低龄但不预设结果 |
| Content Rights | No third-party content requiring rights | 待负责人确认 |
| Copyright | `2026 __REQUIRED_LEGAL_OWNER__` | Blocker |
| Release | Manual | 推荐首发采用 |
| Sign-in required | No | Ready；本地 profile 不是远程登录账号 |
| Privacy Policy URLs | 各语言公开 URL | Blocker |
| Support URL | `https://www.sheanzero.com/#contact` | Candidate only；2026-08-04 返回 200 且有表单，但不是 App 专用支持页，仍属 Blocker |
| Marketing URL | `https://www.sheanzero.com/` | Optional；2026-08-04 返回 200，但页面仍称 Home Pocket “in Development”，上线前更新 |

## Localization 映射

| App Store locale | 目录 | App name | Subtitle |
|---|---|---|---|
| Japanese | `ja/` | まもる家計簿 | 家族と育てる、私らしい家計簿 |
| Simplified Chinese | `zh-Hans/` | 守护家计簿 | 本地优先的家庭记账本 |
| English (U.S.) | `en-US/` | Home Pocket | Private family budgeting |

## 产品口径

- “日常 / 悦己（ときめき）/ Daily / Joy”遵循 ADR-015/016，不使用 Joy/¥、ROI、密度、streak、achievement 或庆祝式达标文案。
- 描述 family sync 时使用“端到端加密 + 零知识中继”，不使用“设备直连”“服务器从不保存”等不准确绝对表述。
- 不承诺 cloud-free。多币种汇率、family relay、APNs 和可选的语音网络降级均可能产生对外通信。
- 不宣称绝对安全、不可破解或零风险。

## URL 核验快照

- `https://www.sheanzero.com/`：2026-08-04 HTTP 200。
- `https://www.sheanzero.com/#contact`：同一页面的联系表单锚点；有 name/email/message 表单。
- 当前不足：没有 Home Pocket 专用支持说明、已确认支持邮箱、隐私请求/删除说明和三语隐私政策链接；主页还显示产品处于开发中。
- 结论：metadata 中的 Support/Marketing URL 是候选值，发布负责人完成页面更新并人工复核后才能录入 App Store Connect。
