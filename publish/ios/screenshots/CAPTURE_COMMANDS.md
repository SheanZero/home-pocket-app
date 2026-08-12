# iOS App Store 营销截图准备命令

本次不采集 iPad 或三语真机截图。使用已批准的 V17 日语营销导出图，并仅上传到日语产品页。

## 来源与输出

- 来源：`docs/mockup/v17/marketing/ja/exports/`，10 张 `2580×5592` RGB PNG。
- 输出：`publish/ios/screenshots/ready/ja/iphone-6.9/`，10 张 `1290×2796` RGB PNG。

## 规范化

```bash
/Users/xinz/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 \
  publish/ios/scripts/normalize_screenshots.py \
  --input docs/mockup/v17/marketing/ja/exports \
  --output publish/ios/screenshots/ready
```

脚本只接受当前精确 2x 来源，按一半尺寸等比缩放，输出 RGB PNG，并移除 Alpha 和图片元数据。

## 校验与上传

```bash
bash publish/ios/scripts/validate_materials.sh
```

校验通过后，把 10 张输出图按编号顺序上传到 App Store Connect 的日语 iPhone 截图栏。简体中文和英语不单独上传截图，使用主语言截图回退。
