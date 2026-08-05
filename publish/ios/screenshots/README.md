# App Store 截图交付规范

## 当前状态

`reference-only/` 中的图片来自 Flutter golden，只能用于确认页面选择和构图。测试环境中部分图标/字体使用替身，**禁止上传 App Store**。

最终图应从通过 TestFlight 验收的 Release build 采集，放入 `raw/`，再用规范化脚本导出到 `ready/`。

## 必需设备规格

当前 Xcode target 为 iPhone + iPad，因此两类都必需：

| 目录 | 推荐像素（portrait） | 说明 |
|---|---:|---|
| `iphone-6.9` | 1320×2868 | Apple 当前 6.9 英寸主规格之一 |
| `ipad-13` | 2064×2752 | Apple 当前 13 英寸 iPad 主规格之一 |

每个 device/localization 可上传 1–10 张，格式为 PNG/JPEG，不能含 Alpha。这里规划 5 张。

## 目录结构

```text
raw/
  ja/
    iphone-6.9/01-home.png ... 05-shopping.png
    ipad-13/01-home.png ... 05-shopping.png
  zh-Hans/
    iphone-6.9/...
    ipad-13/...
  en-US/
    iphone-6.9/...
    ipad-13/...
```

截图文件名和内容顺序见 `storyboard.csv`。

## 采集原则

1. 只用最终 Release/TestFlight build，不用 mockup、golden、Figma 或 Debug banner。
2. 三种语言分别在 app 内切换并重启确认，不把日语 UI 放进英语/中文 localization。
3. 使用完全虚构且一致的演示数据；不得出现真实姓名、账目、邀请码、设备 ID、token、邮箱、照片或通知内容。
4. 状态栏时间、电量、网络保持一致；隐藏无关系统通知。
5. 不展示 OCR，因为当前 `kOcrEntryEnabled = false`。
6. 不展示 Joy/¥、ROI、density、streak、achievement、100% 达标庆祝等已废弃/禁止口径。
7. Family screenshot 不露出可复用的真实邀请码；如需显示，使用专门 demo backend/已失效代码并在提交前复核。
8. 截图中的功能、颜色、文案必须与提交 build 一致。不要加无法在 app 中验证的卖点。
9. 尽量直接使用干净的 app 截图。若后续增加营销标题，标题不能遮挡关键 UI，并需三语母语复核。

## 建议演示数据

- Household：青木家 / Aoki Family / 青木家
- Members：あおい、花子 / Aoi, Hanako / 小葵、花子
- Month：固定到审核前最近一个完整月份
- Currency：日本站使用 JPY；多币种页面使用公开、无敏感性的示例 USD/CNY
- Transactions：超市、交通、书籍、咖啡、家庭用品等普通类别
- Joy：使用自然分布，不刻意做满 100%，不制造庆祝事件
- Shopping：牛乳、りんご、洗剤等一般商品；private item 明确但不敏感

## 采集后规范化

安装 Pillow 后运行：

```bash
python3 publish/ios/scripts/normalize_screenshots.py \
  --input publish/ios/screenshots/raw \
  --output publish/ios/screenshots/ready
```

脚本会拒绝错误像素、错误命名、缺页和超过 10 张的集合，并统一输出无 Alpha、无 EXIF 的 RGB PNG。它不会拉伸或伪造尺寸。

最后运行：

```bash
bash publish/ios/scripts/validate_materials.sh
```
