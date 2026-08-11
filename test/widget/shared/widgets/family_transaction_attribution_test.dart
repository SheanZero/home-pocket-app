import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/theme/app_palette.dart';
import 'package:home_pocket/core/theme/family_payer_palette.dart';
import 'package:home_pocket/shared/widgets/family_transaction_attribution.dart';

void main() {
  test('self and the first seven family members receive unique tones', () {
    final tones = <FamilyPayerTone>[
      FamilyPayerTone.self,
      for (var index = 0; index < 7; index++)
        familyPayerToneForShadowIndex(index),
    ];

    expect(tones.toSet(), hasLength(8));
    expect(familyPayerToneForShadowIndex(0), FamilyPayerTone.memberA);
    expect(familyPayerToneForShadowIndex(1), FamilyPayerTone.memberB);
    expect(familyPayerToneForShadowIndex(2), FamilyPayerTone.memberC);
    expect(familyPayerToneForShadowIndex(3), FamilyPayerTone.memberD);
    expect(familyPayerToneForShadowIndex(4), FamilyPayerTone.memberE);
    expect(familyPayerToneForShadowIndex(5), FamilyPayerTone.memberF);
    expect(familyPayerToneForShadowIndex(6), FamilyPayerTone.memberG);
  });

  test('member colors cycle after all eight family slots are used', () {
    expect(familyPayerToneForShadowIndex(7), FamilyPayerTone.self);
    expect(familyPayerToneForShadowIndex(8), FamilyPayerTone.memberA);
    expect(familyPayerToneForShadowIndex(15), FamilyPayerTone.self);
  });

  test('option 1 exposes the selected light and dark member colors', () {
    expect(
      FamilyPayerPalette.resolve(Brightness.light, FamilyPayerTone.self),
      const FamilyPayerColors(
        background: Color(0xFFE7EEF6),
        foreground: Color(0xFF3F6078),
      ),
    );
    expect(
      FamilyPayerPalette.resolve(Brightness.light, FamilyPayerTone.memberA),
      const FamilyPayerColors(
        background: Color(0xFFEEEAF7),
        foreground: Color(0xFF675A8C),
      ),
    );
    expect(
      FamilyPayerPalette.resolve(Brightness.light, FamilyPayerTone.memberB),
      const FamilyPayerColors(
        background: Color(0xFFF4E8CF),
        foreground: Color(0xFF76551F),
      ),
    );
    expect(
      FamilyPayerPalette.resolve(Brightness.dark, FamilyPayerTone.self),
      const FamilyPayerColors(
        background: Color(0xFF293B47),
        foreground: Color(0xFFB8D4E5),
      ),
    );
    expect(
      FamilyPayerPalette.resolve(Brightness.dark, FamilyPayerTone.memberA),
      const FamilyPayerColors(
        background: Color(0xFF342F46),
        foreground: Color(0xFFD1C4EE),
      ),
    );
    expect(
      FamilyPayerPalette.resolve(Brightness.dark, FamilyPayerTone.memberB),
      const FamilyPayerColors(
        background: Color(0xFF433821),
        foreground: Color(0xFFE7CB8F),
      ),
    );

    const addedLightColors = <FamilyPayerTone, FamilyPayerColors>{
      FamilyPayerTone.memberC: FamilyPayerColors(
        background: Color(0xFFE2EEF1),
        foreground: Color(0xFF35636E),
      ),
      FamilyPayerTone.memberD: FamilyPayerColors(
        background: Color(0xFFF3E5DC),
        foreground: Color(0xFF774F3C),
      ),
      FamilyPayerTone.memberE: FamilyPayerColors(
        background: Color(0xFFE7E9F4),
        foreground: Color(0xFF4A5885),
      ),
      FamilyPayerTone.memberF: FamilyPayerColors(
        background: Color(0xFFEEE6E1),
        foreground: Color(0xFF6B5448),
      ),
      FamilyPayerTone.memberG: FamilyPayerColors(
        background: Color(0xFFE8EBEC),
        foreground: Color(0xFF4F5F64),
      ),
    };
    const addedDarkColors = <FamilyPayerTone, FamilyPayerColors>{
      FamilyPayerTone.memberC: FamilyPayerColors(
        background: Color(0xFF233D43),
        foreground: Color(0xFFB5D5DC),
      ),
      FamilyPayerTone.memberD: FamilyPayerColors(
        background: Color(0xFF432F27),
        foreground: Color(0xFFE7BFA9),
      ),
      FamilyPayerTone.memberE: FamilyPayerColors(
        background: Color(0xFF2D334D),
        foreground: Color(0xFFC5CEF2),
      ),
      FamilyPayerTone.memberF: FamilyPayerColors(
        background: Color(0xFF3D322D),
        foreground: Color(0xFFD8C3B7),
      ),
      FamilyPayerTone.memberG: FamilyPayerColors(
        background: Color(0xFF2E383B),
        foreground: Color(0xFFC4D0D3),
      ),
    };

    for (final entry in addedLightColors.entries) {
      expect(
        FamilyPayerPalette.resolve(Brightness.light, entry.key),
        entry.value,
      );
    }
    for (final entry in addedDarkColors.entries) {
      expect(
        FamilyPayerPalette.resolve(Brightness.dark, entry.key),
        entry.value,
      );
    }
  });

  test('member chips stay distinct from ledger semantics and meet AA', () {
    for (final brightness in Brightness.values) {
      final palette = brightness == Brightness.light
          ? AppPalette.light
          : AppPalette.dark;
      final colors = FamilyPayerTone.values
          .map((tone) => FamilyPayerPalette.resolve(brightness, tone))
          .toList();

      expect(colors.map((value) => value.background).toSet(), hasLength(8));
      expect(colors.map((value) => value.foreground).toSet(), hasLength(8));

      for (final color in colors) {
        expect(color.background, isNot(palette.joyLight));
        expect(color.background, isNot(palette.dailyLight));
        expect(color.foreground, isNot(palette.joyText));
        expect(color.foreground, isNot(palette.dailyText));
        expect(
          _contrastRatio(color.background, color.foreground),
          greaterThanOrEqualTo(4.5),
        );
      }
    }
  });

  for (final brightness in Brightness.values) {
    testWidgets('payer chip resolves $brightness member colors', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            brightness: brightness,
            extensions: [
              brightness == Brightness.light
                  ? AppPalette.light
                  : AppPalette.dark,
            ],
          ),
          home: const Scaffold(
            body: FamilyPayerChip(
              label: 'Shean',
              tone: FamilyPayerTone.memberA,
            ),
          ),
        ),
      );

      final expected = FamilyPayerPalette.resolve(
        brightness,
        FamilyPayerTone.memberA,
      );
      final decoratedBox = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byType(FamilyPayerChip),
          matching: find.byType(DecoratedBox),
        ),
      );
      final decoration = decoratedBox.decoration as BoxDecoration;
      final text = tester.widget<Text>(find.text('Shean'));

      expect(decoration.color, expected.background);
      expect(text.style?.color, expected.foreground);
    });
  }
}

double _contrastRatio(Color first, Color second) {
  final firstLuminance = first.computeLuminance();
  final secondLuminance = second.computeLuminance();
  final lighter = firstLuminance > secondLuminance
      ? firstLuminance
      : secondLuminance;
  final darker = firstLuminance > secondLuminance
      ? secondLuminance
      : firstLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}
