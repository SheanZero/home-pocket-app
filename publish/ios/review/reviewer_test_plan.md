# 审核测试准备

## 送审前准备

- [ ] 如审核需要，提供一个仍在有效期内的测试邀请码；不要把短时效邀请码永久写进 Notes。
- [ ] 说明无需远程账号登录，本地 nickname/profile 不等同于账号。
- [ ] 确保生产 relay 和汇率服务在整个审核期可用；首版不依赖 APNs/FCM。

## 单设备审核路径

1. 全新安装并启动。
2. `Get started` → Initial Setup，输入任意 nickname，选择语言和币种。
3. 可跳过 app lock，或用测试设备的 Face ID/PIN 设置。
4. 新增一笔 Daily 交易和一笔 Joy 交易。
5. 查看 Home ring、交易列表和 Analytics。
6. 新增 public/private shopping item，确认 private 标识。
7. Settings 中验证 backup/restore、Privacy Policy、Terms 和 licenses；确认通知配置与赞助入口均不显示。

## 双设备审核路径

1. A：Settings > Family > Create a new family。
2. B：Settings > Family > Join family，输入 A 的 6 位邀请码。
3. A：批准 B 的请求。
4. A 新增共享交易 / public shopping item；B 验证同步。
5. B 新增 private shopping item；A 不应收到。
6. 验证断网后恢复、退出/移除成员，并确认不请求通知权限。

## 权限预期

| 权限 | 触发点 | 拒绝后 |
|---|---|---|
| Microphone | Voice entry | 回到手动输入，不阻塞核心记账 |
| Speech Recognition | Voice entry | 回到手动输入；需说明 on-device 与可选网络降级 |
| Face ID | App lock | 可使用 PIN 或不启用 app lock |
| Photos | Profile avatar | 可继续使用 emoji/avatar；送审前确认用途说明 |

## 不应出现

- OCR/receipt scanning 入口（本版本 feature flag 为 false）。
- Joy/¥、ROI、density、streak、achievement、100% 达标庆祝。
- 任何广告、订阅、付费功能解锁或强制打赏。
- 通知配置、通知权限请求或赞助入口。
- 未定稿法律占位符或“草案”标记。
