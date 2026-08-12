# Provenance

- 制作日期：2026-08-12
- 视觉参考：用户提供的两张白色极简 App 介绍图
- UI 来源：`docs/mockup/v17/index.html` 的 V17 日文 mockup 页面
- 手机画面：在本地浏览器中以 4× 分辨率分段渲染 V17 页面，再无缝拼合为完整 1560 × 3376 px 画面，保存在 `screens/`
- 宣传版式：由 `build_exports.py` 以 Pillow 确定性排版；未使用生成式模型重绘文字或 UI
- 最终导出：2580 × 5592 px PNG 高清母版，保存在 `exports/`
- 整组预览：`build_contact_sheet.py` 从最终 PNG 生成 `preview-contact-sheet.png`

用户提供的参考图片仅用于风格方向，不被直接嵌入最终成品。
