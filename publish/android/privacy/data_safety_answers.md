# Google Play Data safety — 运营确认基线

状态：**基于 2026-08-12 的客户端、公开隐私政策和 relay 协议整理；提交前必须与最终 AAB、生产服务、日志、SDK 清单和 Play Console 提示逐项核对。**

Google Play 的 “collected” 指数据从设备传出。纯端内处理不用申报；只有发送方和接收方能读取的真正端到端加密内容也不属于 collection 范围。Happy Pocket 的账本同步正文符合 E2EE 排除条件，但 family relay 可读的运营元数据和日志不应被误写成“零收集”。

## 当前数据流

| 流程 | 传出设备的数据 | 开发者/服务端可读 | 建议处理 |
|---|---|---:|---|
| 本地账本、照片、private shopping | 不传出设备 | 否 | 不申报 collection |
| Family sync 正文 | 交易、金额、备注、shared shopping 等 E2EE 密文 | 否 | 满足最终密钥与服务端实现前提时，使用 E2EE 排除 |
| Family sync 元数据 | device ID/public key、group ID/state、display name、membership state | 是 | 申报相关数据类型 |
| Relay 日志 | method、path、status、latency、device ID；错误时可能含 group ID | 是 | 纳入相同 identifiers 数据类型与安全/防滥用用途 |
| 汇率查询 | 日期、base/target currency | 第三方可读 | 当前不含姓名、device ID、交易或金额；核对第三方日志是否产生需申报的数据类型 |
| 语音 | 优先端内；用户允许 cloud fallback 时由 Android/Google speech service 处理音频 | 取决于系统服务 | 以最终 speech 设置、SDK 行为和 Play 指引复核 Audio data |
| Push | 首版停用，不注册或发送 FCM token | 否 | 最终 AAB 仍无 push 行为时不申报 token |
| Support | 用户从外部网页/邮件主动联系 | 取决于支持流程 | 按最终网页、邮件保存和工单行为复核 |

## 建议的 Play Console 回答

### Data collection and security

- Does your app collect or share any of the required user data types? **Yes**。
- Is all user data collected by your app encrypted in transit? **Yes**，前提是最终所有相关端点均使用 TLS，且生产检查通过。
- Do you provide a way for users to request deletion? **Yes**。公开隐私政策提供 `support@napu.co.jp`，并说明一般在 30 日内处理；在 Play Console 填入当前公开、无需登录即可访问的删除请求 URL。若 Console 要求 URL，不要只填邮箱。
- Data sharing: **No（待生产合同与实际用途确认）**。仅当 Tencent Cloud 等确实作为按开发者指示处理的 service provider，且没有广告、出售、独立画像或其他第三方用途时成立。
- Independent security review: **No**，除非已完成 Play 接受的独立评估并持有有效证据。
- Payments policy badges / UPI 等其他区域项目：不适用时如实选择 No。

### 建议申报的数据类型

| Google Play data type | Collected | Shared | Required/optional | Purpose | 当前依据 |
|---|---:|---:|---|---|---|
| Personal info → Name | Yes | No* | Family sync 可选 | App functionality、Account management | nickname/display name 可由 relay 读取；可能是真实姓名 |
| Device or other IDs | Yes | No* | Family sync 启用后需要 | App functionality、Security and compliance、Fraud prevention | app-generated device ID、group ID、public-key identity、相关日志 |
| App activity → Other user-generated content | **需在 Console 逐项确认定义** | No* | Family sync 可选 | App functionality | group name、avatar emoji、membership/control metadata；如果 Console 当前分类不匹配，不要强行套用 |

`No*` 的前提是基础设施供应商满足 Google 对 service provider 的排除条件，且数据不用于其独立目的。

### 当前通常不申报为 collected 的类型

- Financial info：交易、金额、预算、分类和备注只以 relay 无法读取的 E2EE 密文中转；必须确认生产端没有明文、密钥、请求正文或 bind parameter 日志。
- Photos and videos：收据照片留在创建它的设备上，不进入 family sync 或备份。
- Audio files：开发者 relay 不接收音频；但 cloud speech fallback 必须按最终系统服务行为重新判断。
- App activity / Analytics、Diagnostics：当前没有广告或行为分析 SDK；仍须以最终依赖、merged manifest、Play SDK 提示和生产日志为准。
- Location：App 不请求位置；若生产方通过 IP 推导并保留位置，必须更新。

## 保留与删除核对

- E2EE message：ACK 后提前删除，否则创建后 7 天过期；清理任务通常每小时运行。
- Anti-duplication record：7 天。
- Group control event：90 天。
- Inactive device：最后访问 90 天后可删除。
- Online database backup：删除后最多再保留 14 天。
- Access/error/slow-query logs：30 天自动轮转永久删除。
- 用户可通过 App 内删除/离组/解散组控制部分数据，并通过公开支持渠道请求服务端个人信息删除。

## 提交前证据

- [ ] 最终 AAB 的 merged manifest 与 SDK 列表已复核。
- [ ] 首版仍无广告、tracking、analytics、crash-reporting 和 FCM token 注册。
- [ ] 生产 relay 不记录 request body、E2EE body、public key、signature 或 financial data。
- [ ] TLS、7/14/30/90 日清理和 ACK 删除任务在生产环境实际启用。
- [ ] Tencent Cloud/其他处理方的合同角色和独立用途已确认，能支持 “not shared”。
- [ ] Cloud speech fallback 的 Audio data 判断已按 Android/Google 当前行为复核。
- [ ] 删除请求 URL 已公开、无需登录、可用，并与 Play Console 和隐私政策一致。
- [ ] Data safety answers 与三语隐私政策、App 实际 UI 和审核说明一致。

本文件是填写基线，不替代 Google Play 政策原文或法律意见。
