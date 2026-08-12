# App Store 截图交付规范

## 当前状态

本次按发布决定使用 `docs/mockup/v17/marketing/ja/exports/` 中的 10 张日语营销图。规范化脚本会把 2x 导出图从 `2580×5592` 等比缩小为 Apple 接受的 `1290×2796`，并移除 Alpha 和元数据后输出到 `ready/`。

## 必需设备规格

当前 Xcode target 仅支持 iPhone，因此不需要 iPad 截图：

| 目录 | 推荐像素（portrait） | 说明 |
|---|---:|---|
| `iphone-6.9` | 1290×2796 | Apple 接受的 6.9 英寸规格；营销图 2x 导出的一半 |

每个 localization 可上传 1–10 张，格式为 PNG/JPEG，不能含 Alpha。本次上传 10 张日语营销图。

## 目录结构

```text
ready/
  ja/
    iphone-6.9/01-home.png ... 10-privacy-backup.png
```

上传顺序按文件名前缀 `01` 至 `10`。

## 采集原则

1. 使用已批准的 V17 日语营销导出图，不上传 golden 或 Debug 截图。
2. 只上传到日语 localization；简中和英语使用主语言截图回退。
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
/Users/xinz/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 \
  publish/ios/scripts/normalize_screenshots.py \
  --input docs/mockup/v17/marketing/ja/exports \
  --output publish/ios/screenshots/ready
```

脚本会拒绝错误像素、错误命名、缺图或多图，并统一输出无 Alpha、无 EXIF 的 RGB PNG。缩放仅接受当前精确 2x 来源。

最后运行：

```bash
bash publish/ios/scripts/validate_materials.sh
```
