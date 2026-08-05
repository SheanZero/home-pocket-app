# 法律物料

`current-drafts/` 是 2026-08-04 从 `assets/legal/` 复制的发布审阅快照，共 9 份：Privacy Policy、Terms、特商法，分别为日语、简体中文、英语。

它们仍包含草案标记、示例邮箱和运营者占位，因此不可上线，也不可直接托管为 App Store Privacy Policy URL。

## 定稿清单

- [ ] 日本法务负责人确认适用主体、准据法、管辖、免责、服务变更、终止和争议处理。
- [ ] 替换事业者名、所在地、电话、运营责任人、支持邮箱。
- [ ] 用真实流程描述 family relay：加密消息的暂存、ACK/过期删除、不可解密内容、设备/组元数据、日志和保留期。
- [ ] 披露 APNs token、汇率请求、WebSocket/relay、语音 on-device 与可选网络降级。
- [ ] 删除“设备直连”“服务器不保存”“Never sent to cloud”等与事实不符的绝对表述。
- [ ] 明确数据删除：本地数据、家庭成员/组、relay 元数据、pending encrypted message、push token 的删除路径与时限。
- [ ] 打赏页与特商法口径一致；无数字商品、会员、功能解锁或购买诱导。
- [ ] 三语版本含义一致，生效日期、版本号和联系方式完全相同。
- [ ] 删除所有 DRAFT/草案/`support@example.com`/`[上线前填真实值]` 标记。
- [ ] 将定稿同步回 `assets/legal/`，通过 app 内页面测试和占位符扫描。
- [ ] 将最终文档发布到 HTTPS 公共 URL，并逐语言验证无登录、无地区限制、可移动端阅读。
- [ ] 用最终 URL 更新 `metadata/*/privacy_url.txt` 和 App Store Connect。

定稿后应重新生成本目录快照，并记录法务 reviewer、日期和文档 hash。
