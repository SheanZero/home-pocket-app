// Pre-move characterization test for LedgerRowData.
//
// Per Phase 3 CONTEXT.md D-11/D-12 + VALIDATION.md "Wave 0 Requirements":
// this test is written at the CURRENT (domain/) path BEFORE Plan 03-04
// Task 1 moves the source. Task 1 also `git mv`s this test alongside,
// so post-move it lives at:
//   test/features/home/presentation/models/ledger_row_data_test.dart
//
// The same assertions stay GREEN before AND after the move, proving:
//   1. The move is byte-equivalent (no field accidentally edited)
//   2. The Freezed `copyWith` semantics preserve every field independently
//   3. The 10 Color fields + formatted-string fields all round-trip cleanly
//
// This complements `ledger_comparison_section_test.dart` (widget-level
// exercise) by giving the model itself dedicated unit coverage that the
// coverage_gate can attribute to `ledger_row_data.dart` directly.

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/home/domain/models/ledger_row_data.dart';

void main() {
  group('LedgerRowData characterization (Phase 3 D-11 / LV-022)', () {
    const _tagBg = Color(0xFFE8F5E9);
    const _tagText = Color(0xFF2E7D32);
    const _title = Color(0xFF1E2432);
    const _amount = Color(0xFF47B88A);
    const _chevron = Color(0xFFB0BEC5);
    const _border = Color(0xFFFAFAFA);

    LedgerRowData _seed({Color? borderColor}) => LedgerRowData(
          tagText: 'Soul',
          tagBgColor: _tagBg,
          tagTextColor: _tagText,
          title: 'Concert ticket',
          titleColor: _title,
          subtitle: '2026-04-26 · Music',
          formattedAmount: '¥8,500',
          amountColor: _amount,
          chevronColor: _chevron,
          borderColor: borderColor,
        );

    test('constructor preserves every supplied field byte-equivalently', () {
      final row = _seed(borderColor: _border);
      expect(row.tagText, 'Soul');
      expect(row.tagBgColor, _tagBg);
      expect(row.tagTextColor, _tagText);
      expect(row.title, 'Concert ticket');
      expect(row.titleColor, _title);
      expect(row.subtitle, '2026-04-26 · Music');
      expect(row.formattedAmount, '¥8,500');
      expect(row.amountColor, _amount);
      expect(row.chevronColor, _chevron);
      expect(row.borderColor, _border);
    });

    test('borderColor is optional and defaults to null', () {
      final row = _seed();
      expect(row.borderColor, isNull);
    });

    test('two LedgerRowData with identical fields are equal', () {
      final a = _seed(borderColor: _border);
      final b = _seed(borderColor: _border);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    group('copyWith preserves untouched fields when ONE field changes', () {
      // For each field, mutate it and verify the other 9 stay intact.
      test('copyWith(tagText: ...) preserves all other fields', () {
        final base = _seed(borderColor: _border);
        final next = base.copyWith(tagText: 'Survival');
        expect(next.tagText, 'Survival');
        expect(next.tagBgColor, base.tagBgColor);
        expect(next.tagTextColor, base.tagTextColor);
        expect(next.title, base.title);
        expect(next.titleColor, base.titleColor);
        expect(next.subtitle, base.subtitle);
        expect(next.formattedAmount, base.formattedAmount);
        expect(next.amountColor, base.amountColor);
        expect(next.chevronColor, base.chevronColor);
        expect(next.borderColor, base.borderColor);
      });

      test('copyWith(tagBgColor: ...) preserves all other fields', () {
        final base = _seed(borderColor: _border);
        final next = base.copyWith(tagBgColor: const Color(0xFFFFEBEE));
        expect(next.tagBgColor, const Color(0xFFFFEBEE));
        expect(next.tagText, base.tagText);
        expect(next.tagTextColor, base.tagTextColor);
        expect(next.title, base.title);
        expect(next.titleColor, base.titleColor);
        expect(next.subtitle, base.subtitle);
        expect(next.formattedAmount, base.formattedAmount);
        expect(next.amountColor, base.amountColor);
        expect(next.chevronColor, base.chevronColor);
        expect(next.borderColor, base.borderColor);
      });

      test('copyWith(tagTextColor: ...) preserves all other fields', () {
        final base = _seed(borderColor: _border);
        final next = base.copyWith(tagTextColor: const Color(0xFFC62828));
        expect(next.tagTextColor, const Color(0xFFC62828));
        expect(next.tagText, base.tagText);
        expect(next.tagBgColor, base.tagBgColor);
        expect(next.title, base.title);
        expect(next.titleColor, base.titleColor);
        expect(next.subtitle, base.subtitle);
        expect(next.formattedAmount, base.formattedAmount);
        expect(next.amountColor, base.amountColor);
        expect(next.chevronColor, base.chevronColor);
        expect(next.borderColor, base.borderColor);
      });

      test('copyWith(title: ...) preserves all other fields', () {
        final base = _seed(borderColor: _border);
        final next = base.copyWith(title: 'Different');
        expect(next.title, 'Different');
        expect(next.tagText, base.tagText);
        expect(next.tagBgColor, base.tagBgColor);
        expect(next.tagTextColor, base.tagTextColor);
        expect(next.titleColor, base.titleColor);
        expect(next.subtitle, base.subtitle);
        expect(next.formattedAmount, base.formattedAmount);
        expect(next.amountColor, base.amountColor);
        expect(next.chevronColor, base.chevronColor);
        expect(next.borderColor, base.borderColor);
      });

      test('copyWith(titleColor: ...) preserves all other fields', () {
        final base = _seed(borderColor: _border);
        final next = base.copyWith(titleColor: const Color(0xFF000000));
        expect(next.titleColor, const Color(0xFF000000));
        expect(next.tagText, base.tagText);
        expect(next.tagBgColor, base.tagBgColor);
        expect(next.tagTextColor, base.tagTextColor);
        expect(next.title, base.title);
        expect(next.subtitle, base.subtitle);
        expect(next.formattedAmount, base.formattedAmount);
        expect(next.amountColor, base.amountColor);
        expect(next.chevronColor, base.chevronColor);
        expect(next.borderColor, base.borderColor);
      });

      test('copyWith(subtitle: ...) preserves all other fields', () {
        final base = _seed(borderColor: _border);
        final next = base.copyWith(subtitle: 'Other date');
        expect(next.subtitle, 'Other date');
        expect(next.tagText, base.tagText);
        expect(next.tagBgColor, base.tagBgColor);
        expect(next.tagTextColor, base.tagTextColor);
        expect(next.title, base.title);
        expect(next.titleColor, base.titleColor);
        expect(next.formattedAmount, base.formattedAmount);
        expect(next.amountColor, base.amountColor);
        expect(next.chevronColor, base.chevronColor);
        expect(next.borderColor, base.borderColor);
      });

      test('copyWith(formattedAmount: ...) preserves all other fields', () {
        final base = _seed(borderColor: _border);
        final next = base.copyWith(formattedAmount: '¥1,000');
        expect(next.formattedAmount, '¥1,000');
        expect(next.tagText, base.tagText);
        expect(next.tagBgColor, base.tagBgColor);
        expect(next.tagTextColor, base.tagTextColor);
        expect(next.title, base.title);
        expect(next.titleColor, base.titleColor);
        expect(next.subtitle, base.subtitle);
        expect(next.amountColor, base.amountColor);
        expect(next.chevronColor, base.chevronColor);
        expect(next.borderColor, base.borderColor);
      });

      test('copyWith(amountColor: ...) preserves all other fields', () {
        final base = _seed(borderColor: _border);
        final next = base.copyWith(amountColor: const Color(0xFF5A9CC8));
        expect(next.amountColor, const Color(0xFF5A9CC8));
        expect(next.tagText, base.tagText);
        expect(next.tagBgColor, base.tagBgColor);
        expect(next.tagTextColor, base.tagTextColor);
        expect(next.title, base.title);
        expect(next.titleColor, base.titleColor);
        expect(next.subtitle, base.subtitle);
        expect(next.formattedAmount, base.formattedAmount);
        expect(next.chevronColor, base.chevronColor);
        expect(next.borderColor, base.borderColor);
      });

      test('copyWith(chevronColor: ...) preserves all other fields', () {
        final base = _seed(borderColor: _border);
        final next = base.copyWith(chevronColor: const Color(0xFF000000));
        expect(next.chevronColor, const Color(0xFF000000));
        expect(next.tagText, base.tagText);
        expect(next.tagBgColor, base.tagBgColor);
        expect(next.tagTextColor, base.tagTextColor);
        expect(next.title, base.title);
        expect(next.titleColor, base.titleColor);
        expect(next.subtitle, base.subtitle);
        expect(next.formattedAmount, base.formattedAmount);
        expect(next.amountColor, base.amountColor);
        expect(next.borderColor, base.borderColor);
      });

      test('copyWith(borderColor: ...) preserves all other fields', () {
        final base = _seed(borderColor: _border);
        final next = base.copyWith(borderColor: const Color(0xFFFAFAFB));
        expect(next.borderColor, const Color(0xFFFAFAFB));
        expect(next.tagText, base.tagText);
        expect(next.tagBgColor, base.tagBgColor);
        expect(next.tagTextColor, base.tagTextColor);
        expect(next.title, base.title);
        expect(next.titleColor, base.titleColor);
        expect(next.subtitle, base.subtitle);
        expect(next.formattedAmount, base.formattedAmount);
        expect(next.amountColor, base.amountColor);
        expect(next.chevronColor, base.chevronColor);
      });
    });
  });
}
