import 'package:flutter/painting.dart';

/// 分类支出环 + 小确幸日历热力的 mock 专属配色（round5 r5）。
/// 裸 hex 仅允许在 lib/core/theme/（color_literal_scan 白名单按目录）。
abstract final class AnalyticsCategoryPalette {
  /// 生存(日常)系分类环色，按金额降序轮转分配。绿/蓝系，避开樱粉(留给悦己)。
  /// food绿 / house蓝 / transit浅绿 / daily柚绿 / comm浅蓝
  static const List<Color> survivalSequence = [
    Color(0xFF69A873),
    Color(0xFF5F8DCA),
    Color(0xFF86C994),
    Color(0xFF9FBF8A),
    Color(0xFF86A9D6),
  ];

  /// 悦己(soul)系分类环色 —— 樱粉，账本暗示。
  static const Color joy = Color(0xFFD98CA0);

  /// 满足度柱渐变底色（mock `.bar` 渐变 var(--joy)→#E7A6B6）。顶色用运行时 palette.joy。
  static const Color histoBarBottom = Color(0xFFE7A6B6);

  /// 长尾「其他」/未知分类 —— 中性藕灰。
  static const Color other = Color(0xFFC4B6AD);

  /// 日历热力 4 档离散色 heat0..heat3（0笔→heat0；1→heat1；2→heat2；≥3→heat3）。
  static const List<Color> heat = [
    Color(0xFFF3ECEA),
    Color(0xFFF4D2DC),
    Color(0xFFE8A9BC),
    Color(0xFFD98CA0),
  ];

  static Color survivalAt(int i) =>
      survivalSequence[i % survivalSequence.length];

  static Color heatForCount(int count) => count <= 0
      ? heat[0]
      : count == 1
      ? heat[1]
      : count == 2
      ? heat[2]
      : heat[3];

  /// 成员环色阶（260620-v2m / D1）—— ADR-019 协调色：若叶绿/钢蓝/柚绿/浅蓝 + 琥珀衍生，
  /// 避开 error 红，把樱粉留给悦己语义。按 deviceId 稳定哈希映射，保证同一成员跨刷新颜色稳定。
  /// 深色经 context.palette 不受影响（与 donut 分类色阶同策略——固定环色，非语义色）。
  static const List<Color> memberSequence = [
    Color(0xFF6FA36F),
    Color(0xFF5B8AC4),
    Color(0xFF86C79A),
    Color(0xFF86A9D6),
    Color(0xFFC8841A),
    Color(0xFF9FBF8A),
  ];

  /// 同一 deviceId 跨刷新映射到稳定的环色（D1）。用 deviceId 的稳定哈希取模色阶长度。
  static Color memberColorFor(String deviceId) =>
      memberSequence[deviceId.hashCode.abs() % memberSequence.length];
}
