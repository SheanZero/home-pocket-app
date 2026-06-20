import 'package:flutter/painting.dart';

/// 分类支出环 + 小确幸日历热力的 mock 专属配色（round5 r5）。
/// 裸 hex 仅允许在 lib/core/theme/（color_literal_scan 白名单按目录）。
abstract final class AnalyticsCategoryPalette {
  /// 生存(日常)系分类环色，按金额降序轮转分配。绿/蓝系，避开樱粉(留给悦己)。
  /// food绿 / house蓝 / transit浅绿 / daily柚绿 / comm浅蓝
  static const List<Color> survivalSequence = [
    Color(0xFF5FAE72), Color(0xFF5B8AC4), Color(0xFF86C79A),
    Color(0xFF9FBF8A), Color(0xFF86A9D6),
  ];

  /// 悦己(soul)系分类环色 —— 樱粉，账本暗示。
  static const Color joy = Color(0xFFD98CA0);

  /// 长尾「其他」/未知分类 —— 中性藕灰。
  static const Color other = Color(0xFFC4B6AD);

  /// 日历热力 4 档离散色 heat0..heat3（0笔→heat0；1→heat1；2→heat2；≥3→heat3）。
  static const List<Color> heat = [
    Color(0xFFF3ECEA), Color(0xFFF4D2DC), Color(0xFFE8A9BC), Color(0xFFD98CA0),
  ];

  static Color survivalAt(int i) => survivalSequence[i % survivalSequence.length];

  static Color heatForCount(int count) =>
      count <= 0 ? heat[0] : count == 1 ? heat[1] : count == 2 ? heat[2] : heat[3];
}
