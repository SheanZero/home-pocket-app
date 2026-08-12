# Happy Pocket V17 · 日本語 App 紹介画像

- 输出尺寸：2580 × 5592 px（1290 × 2796 版式的 2× 高清母版）
- 语言：日文，包括主标题、卖点与手机内 mockup
- 风格：参考图的白色极简背景、左侧功能说明、右侧倾斜手机构图
- 内容：使用 V17 mockup 的实际页面截图，未使用生成式模型重绘 UI 或文字

最终 PNG 位于 `exports/01-home.png` 至 `exports/10-privacy-backup.png`。

在 `docs/mockup/v17` 启动静态服务器后预览单张设计：

`http://127.0.0.1:<port>/marketing/ja/index.html?slide=1`

将 `slide` 改为 1–10 可查看整组。

整组缩略预览见 `preview-contact-sheet.png`，逐张内容清单见
`manifest.json`，素材与导出方式见 `PROVENANCE.md`。

重新生成：先以 V17 的 `capture=4` 模式采集三段页面并运行
`build_screens.py`，再运行 `build_exports.py` 和
`build_contact_sheet.py`。
