# 日本赞助平台接入操作手册（開発を応援する）

**文档版本:** 1.0
**创建日期:** 2026-07-06
**适用对象:** Home Pocket（まもる家計簿）运营者
**前置状态:** Phase 56 已交付 app 侧全部代码，仅剩 `LegalUrls.donation` 占位符待填真实 URL

---

## 1. 背景与现状

app 的商业化入口是设置页「法的情報・応援」组里的「開発を応援する」行（`lib/features/settings/presentation/widgets/legal_sponsor_section.dart`）。点击后用 `url_launcher` 在**外部浏览器**打开 `LegalUrls.donation` 指向的赞助页面。

Phase 56 定下的四条约束（接入时不得破坏）：

| 约束 | 含义 |
|---|---|
| DONATE-01 | 非交易性——app 内不出现金额、不承诺任何回报，纯「応援」 |
| DONATE-02 | 跳转必须走外部浏览器（`LaunchMode.externalApplication`） |
| DONATE-03 | 禁止 in-app WebView、禁止 IAP、禁止 app 内支付表单 |
| DONATE-04 | URL 唯一来源是 `lib/core/config/legal_urls.dart` 的 `LegalUrls.donation` |

跳转失败路径已处理（一次中性 SnackBar，不重试不崩溃）。**接入工作 = 选平台 → 开通账号 → 把真实 URL 填进一行常量 → 测试。**

---

## 2. 平台选型

### 2.1 对比表（2026-07 核实，费率以各官网为准）

| 平台 | 平台手续费 | 出金 | KYC/门槛 | 日语体验 | 适合度 |
|---|---|---|---|---|---|
| **OFUSE**（日本） | 无料プラン 5% + 30円/笔（税別，2026-04 改定；有料プラン更低） | 月末締め翌月10日自动振込；最低 3,000円；出金手数料 275円；日本国内银行 | 本人确认（日本居住者向け） | ◎ 全日语，日本用户心理门槛最低 | 日本受众主力 ★推荐 |
| **Ko-fi**（国际） | 打赏 0%（Free plan；Shop/会员 5%，Gold 0%） | PayPal 或 Stripe **直连即时到账**，平台不代管资金 | 需自备 PayPal/Stripe 账户（Stripe 日本卡费率约 3.6%） | ○ 界面部分日语化，支付页偏英文 | 国际受众备选 |
| Buy Me a Coffee（国际） | 5% + Stripe 处理费 + 0.5% 出金费 | Stripe Standard Connect，日本在支持列表；即时转出另收 1% | Stripe KYC | △ 英文为主 | 与 Ko-fi 同定位但费率更高，一般不选 |
| pixivFANBOX（日本） | 约 10%（月费制订阅） | 日本银行 | pixiv 账号 | ◎ | 持续月费支援模式；单次打赏不适合 |
| GitHub Sponsors | 0%（GitHub 承担） | Stripe | 需公开的开发者身份 | △ | 仓库非开源，适配度低 |
| Patreon | 8–12%（月费制） | Payoneer/银行 | — | △ | 费率高、月费制，不适合本场景 |

### 2.2 推荐结论

- **主选 OFUSE**：目标用户是日本家庭，全日语的「ファンレター+チップ」模式与「応援」文案天然契合；虽有 5%+30 円手续费，但对小额打赏的心理转化率远比英文页面高。
- **可选并行 Ko-fi**：若想同时覆盖海外用户（app 支持 zh/en），Ko-fi 打赏 0% 平台费 + 即时到账。但 `LegalUrls.donation` 只有一个 URL——并行方案见 §5.3。
- 单次打赏（都度制）先行；月费制（FANBOX/OFUSE メンバーシップ）等有稳定粉丝后再考虑。

---

## 3. OFUSE 开通操作（主选）

1. **注册**：https://ofuse.me/ → 「クリエイター登録」，邮箱或 SNS 账号注册。
2. **创建者资料**：
   - 显示名建议与 App Store 开发者名一致（例：Home Pocket 開発者），头像可用 app icon（注意 §6.3 商标一致性）。
   - 自我介绍写明「まもる家計簿の開発・運営を応援いただけると嬉しいです」，并注明打赏不解锁任何 app 功能（呼应 DONATE-01）。
3. **本人确认（KYC）**：按平台指引提交身份信息。日本居住者向け服务。
4. **收款账户**：登录后在出金設定里绑定日本国内银行账户。记住出金规则：**月末締め→翌月 10 日自动振込、最低 3,000 円、每次出金 275 円手续费**——余额不足 3,000 円会滚存。
5. **拿 URL**：个人页地址形如 `https://ofuse.me/<username>`。这就是要填进代码的值。
6. **页面自检**：
   - [ ] 手机浏览器打开个人页，确认无需登录即可看到打赏入口
   - [ ] 打赏金额档位合理（OFUSE 按「文字数」计价的信件模式，确认默认档）
   - [ ] 个人页没有指向其他付费内容的误导性链接

## 4. Ko-fi 开通操作（国际受众备选）

1. **前置**：先开通 Stripe（https://stripe.com/jp，个人事业主可开）或 PayPal Business 日本账户——Ko-fi 不代管资金，没有收款账户就收不了钱。
2. **注册**：https://ko-fi.com/ → Sign up，选 creator 类型。
3. **连接收款**：Settings → Payment options → 连接 Stripe/PayPal。
4. **页面设置**：Page 名、简介（建议中日英三语各一句）、打赏单价（默认 ¥ 档位可设 300/500 円级）。
5. **拿 URL**：`https://ko-fi.com/<username>`。
6. **费用认知**：平台 0%，但 Stripe 日本约 3.6% 卡费率从每笔扣除；到账即时。

---

## 5. 代码接入操作

### 5.1 修改（一行）

`lib/core/config/legal_urls.dart`：

```dart
static const String donation =
    'https://ofuse.me/<username>'; // 2026-07 OFUSE 正式页
```

同时删除该行的 `// TODO 上线前填真实值 (DONATE-04)` 标记（保留 `(DONATE-04)` 溯源标识可以，但 TODO 必须摘除，否则上线检查脚本/评审会再次拦截）。

### 5.2 测试清单

- [ ] `flutter analyze` 0 issues
- [ ] 既有测试 `legal_sponsor_section` 相关套件绿（plan 56-05 对 URI 有 downstream 断言，改 URL 后如有钉死 example.com 的断言需同步更新——先跑 `flutter test test/widget/features/settings/` 确认）
- [ ] 真机：设置 →「開発を応援する」→ 外部浏览器（非 in-app WebView）打开 OFUSE 页
- [ ] 真机飞行模式：点击后出现一次中性 SnackBar，app 不崩溃
- [ ] dark mode 下入口行视觉正常

### 5.3 双平台并行（可选，需少量开发）

现架构只有一个 URL。若要 OFUSE+Ko-fi 并行，两个方案：

- **零开发**：`donation` 指向一个自建的中转页（如 GitHub Pages 一页两个按钮）。缺点：多一跳，转化率降。
- **小开发**：设置区加第二行「海外からの応援 (Ko-fi)」，`LegalUrls` 加第二个常量。走一个新的 quick task（约束沿用 DONATE-01..04），需加 3 语言 ARB key。

先单平台上线验证转化，再决定是否并行。

### 5.4 提交规范

```
feat: fill production sponsor URL (OFUSE) for DONATE-04
```

`legal_urls.dart` 属 `lib/core/config`——纯常量改动无需 build_runner。

---

## 6. 应用商店合规

### 6.1 iOS / App Store

- **日本 storefront（主市场）**：スマホ新法（スマートフォン競争促進法，2025-12-18 全面施行）后，Apple 在日本**必须允许 app 内引导至外部网站完成交易**。纯捐赠外链的历史灰色地带在日本已彻底消除。
- **其他 storefront**（app 若全球发行）：继续沿用保守设计即可——Guideline 3.2.1 对「给个人的自愿赠与且 100% 归受赠方、不解锁功能」是宽容的；关键红线是**不得暗示打赏可换取功能/内容**（DONATE-01 已经钉死这一点）。
- **审核被拒应对**：若被引用 3.1.1（数字商品必须 IAP）拒审，在 Resolution Center 回复三点事实：①链接仅为对开发者的自愿捐赠（voluntary donation to the developer）；②不解锁任何功能或内容；③交易完全发生在外部浏览器。必要时引用日本 storefront 的 JSCPA 合规义务。

### 6.2 Google Play

- Play Billing 政策针对的是 app 内数字商品销售；**不解锁功能的对开发者捐赠走外链**一直是政策允许区，且 Google 同受スマホ新法约束。
- 注意：打赏页本身不要放在 app 内 WebView 渲染（DONATE-03 已禁止）。

### 6.3 平台页面与 app 的一致性

- OFUSE/Ko-fi 个人页的名称、头像若使用「まもる家計簿」品牌素材，确保与 App Store 开发者身份一致，避免审核方怀疑第三方冒名。
- 打赏页简介中**不要**出现「解锁」「Premium」「限定機能」等字眼。

---

## 7. 税务与法务备忘

> 本节为备忘，不构成税务建议；规模化前请咨询税理士。

- **所得分类**：个人收到的打赏一般计入**雑所得**（持续经营化后可为事业所得）。工薪族副业年 20 万円以下免确定申告（住民税申告仍需要）；超过则需确定申告。OFUSE 后台可导出年间明细。
- **消費税**：OFUSE 手续费为税別计价；打赏收入本身在年销售额 1,000 万円以下为免税事业者，通常无需インボイス登録（打赏方是消费者，不需要发票抵扣）。
- **特商法**：无对价的应援不构成通信販売，app 侧不需要为打赏追加特商法表记（Phase 56 已有的 tokusho 页覆盖既有义务）；平台侧的特商法表记由 OFUSE/Ko-fi 自行承担。
- **隐私政策**：打赏发生在外部平台，app 不经手任何支付数据——**现有隐私政策无需修改**，「クラウドには送信しません」承诺不受影响。这是打赏模式相对广告模式的核心优势。

---

## 8. 附录：未来若考虑广告变现（展望）

打赏收入天花板低。若未来评估 app 内广告，先认清一个根本张力：**onboarding 第二屏刚向用户承诺「すべて端末の中だけで完結。クラウドには送信しません」**——任何广告 SDK 都会采集设备信号并回传，直接违背该承诺，需要重写隐私政策、加 ATT 弹窗（iOS）、并承受品牌信任损耗。建议仅在打赏+买断制都验证失败后再考虑。

届时的选型参考（AdMob 为主 + 日系对比）：

| 平台 | Flutter 支持 | 特点 | 适合 |
|---|---|---|---|
| **Google AdMob** | ◎ 官方 `google_mobile_ads` | 日本 fill rate 最高、eCPM 稳定、文档全 | 首选主力 |
| LINE広告（LAP） | △ 无官方 Flutter SDK | 日本用户覆盖极广，但接入门槛高（需代理商） | 大规模后 |
| nend（FANCOMI） | △ 原生 SDK 需自写 bridge | 日本老牌、小额起步友好 | 补充填充 |
| Zucks | △ 同上 | 日系性能型广告 | 补充填充 |
| i-mobile | △ 同上 | 日系老牌 | 补充填充 |
| AppLovin MAX | ○ 有 Flutter 插件 | 聚合中介，可同时吃多家日系源 | 中介层方案 |

技术路线届时另立专项手册；本手册不再展开。

---

## 参考来源（2026-07-06 核实）

- OFUSE 2026-04 费率改定解说: https://app-tatsujin.com/ofuse-free-plan-fee-2026/ / 官方费用 FAQ: https://support.ofuse.me/hc/ja/articles/4408196935193 / 出金手续费: https://support.ofuse.me/hc/ja/articles/4408207215641
- Ko-fi 定价: https://ko-fi.com/pricing / Stripe 对应国家: https://help.ko-fi.com/hc/en-us/articles/360009265834
- Buy Me a Coffee 手续费计算: https://help.buymeacoffee.com/en/articles/8105744 / 出金支持国家（含日本）: https://help.buymeacoffee.com/en/articles/6258038
- スマホ新法与 app 外課金解说: https://pay.jp/column/external-payment / https://repro.io/contents/real-external-payment-guidelines/
- Apple App Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- Stripe 日本定价: https://stripe.com/en-jp/pricing

---

**维护:** 平台费率/商店政策随时间变化，每次实际操作前以官网为准；本手册重大变更时更新版本号并在 worklog 记录。
