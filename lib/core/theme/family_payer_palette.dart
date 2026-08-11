import 'package:flutter/material.dart';

/// Stable identity roles for payer chips in a family group.
///
/// The current device owner always uses [self]. The next seven members receive
/// [memberA] through [memberG], so a family of up to eight people has no
/// repeated identity color.
enum FamilyPayerTone {
  self,
  memberA,
  memberB,
  memberC,
  memberD,
  memberE,
  memberF,
  memberG,
}

/// Background and foreground pair for a compact family payer label.
@immutable
final class FamilyPayerColors {
  const FamilyPayerColors({required this.background, required this.foreground});

  final Color background;
  final Color foreground;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FamilyPayerColors &&
          other.background == background &&
          other.foreground == foreground;

  @override
  int get hashCode => Object.hash(background, foreground);
}

/// Brightness-aware member identity colors.
///
/// These colors deliberately avoid the Sakura-pink Joy and leaf-green Daily
/// ledger semantics. Every foreground/background pair meets WCAG AA (4.5:1)
/// for compact label text.
abstract final class FamilyPayerPalette {
  static const _light = <FamilyPayerColors>[
    FamilyPayerColors(
      background: Color(0xFFE7EEF6),
      foreground: Color(0xFF3F6078),
    ),
    FamilyPayerColors(
      background: Color(0xFFEEEAF7),
      foreground: Color(0xFF675A8C),
    ),
    FamilyPayerColors(
      background: Color(0xFFF4E8CF),
      foreground: Color(0xFF76551F),
    ),
    FamilyPayerColors(
      background: Color(0xFFE2EEF1),
      foreground: Color(0xFF35636E),
    ),
    FamilyPayerColors(
      background: Color(0xFFF3E5DC),
      foreground: Color(0xFF774F3C),
    ),
    FamilyPayerColors(
      background: Color(0xFFE7E9F4),
      foreground: Color(0xFF4A5885),
    ),
    FamilyPayerColors(
      background: Color(0xFFEEE6E1),
      foreground: Color(0xFF6B5448),
    ),
    FamilyPayerColors(
      background: Color(0xFFE8EBEC),
      foreground: Color(0xFF4F5F64),
    ),
  ];

  static const _dark = <FamilyPayerColors>[
    FamilyPayerColors(
      background: Color(0xFF293B47),
      foreground: Color(0xFFB8D4E5),
    ),
    FamilyPayerColors(
      background: Color(0xFF342F46),
      foreground: Color(0xFFD1C4EE),
    ),
    FamilyPayerColors(
      background: Color(0xFF433821),
      foreground: Color(0xFFE7CB8F),
    ),
    FamilyPayerColors(
      background: Color(0xFF233D43),
      foreground: Color(0xFFB5D5DC),
    ),
    FamilyPayerColors(
      background: Color(0xFF432F27),
      foreground: Color(0xFFE7BFA9),
    ),
    FamilyPayerColors(
      background: Color(0xFF2D334D),
      foreground: Color(0xFFC5CEF2),
    ),
    FamilyPayerColors(
      background: Color(0xFF3D322D),
      foreground: Color(0xFFD8C3B7),
    ),
    FamilyPayerColors(
      background: Color(0xFF2E383B),
      foreground: Color(0xFFC4D0D3),
    ),
  ];

  static FamilyPayerColors resolve(
    Brightness brightness,
    FamilyPayerTone tone,
  ) => (brightness == Brightness.light ? _light : _dark)[tone.index];
}
