import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../features/accounting/domain/models/transaction.dart';
import '../../../../generated/app_localizations.dart';
import '../providers/state_list_filter.dart';

/// Ledger tone used to colour an active segment.
enum _SegmentTone { all, daily, joy }

/// Full-width ledger segmented control — v15 `.list-ledger-segments`.
///
/// Three mutually-exclusive segments (すべて / 日常 / ときめき) bound to
/// [ListFilter.ledgerType]. Faithfully ports the mockup `.segmented-control`:
/// - all active   → [AppPalette.accentPrimary] fill, [AppPalette.card] label
/// - daily active → [AppPalette.dailyLight] fill, [AppPalette.daily] label + inset border
/// - joy active   → [AppPalette.joyLight] fill, [AppPalette.joy] label + inset border
/// - inactive     → transparent fill, [AppPalette.textPrimary] label
///
/// Unlike the previous ledger chips this control is single-select (tapping the
/// active segment is a no-op); "すべて" clears the filter (`setLedgerFilter(null)`).
class ListLedgerSegments extends ConsumerWidget {
  const ListLedgerSegments({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final l10n = S.of(context);
    final ledger = ref.watch(listFilterProvider.select((f) => f.ledgerType));

    void select(LedgerType? type) =>
        ref.read(listFilterProvider.notifier).setLedgerFilter(type);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: palette.backgroundMuted,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.borderDefault, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Segment(
              label: l10n.listLedgerAll,
              tone: _SegmentTone.all,
              active: ledger == null,
              onTap: () => select(null),
            ),
          ),
          Expanded(
            child: _Segment(
              label: l10n.listLedgerDaily,
              tone: _SegmentTone.daily,
              active: ledger == LedgerType.daily,
              onTap: () => select(LedgerType.daily),
            ),
          ),
          Expanded(
            child: _Segment(
              label: l10n.listLedgerJoy,
              tone: _SegmentTone.joy,
              active: ledger == LedgerType.joy,
              onTap: () => select(LedgerType.joy),
            ),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.tone,
    required this.active,
    required this.onTap,
  });

  final String label;
  final _SegmentTone tone;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    Color background = Colors.transparent;
    Color foreground = palette.textPrimary;
    BoxBorder? border;

    if (active) {
      switch (tone) {
        case _SegmentTone.all:
          background = palette.accentPrimary;
          foreground = palette.card;
        case _SegmentTone.daily:
          background = palette.dailyLight;
          foreground = palette.daily;
          border = Border.all(color: palette.daily, width: 1.5);
        case _SegmentTone.joy:
          background = palette.joyLight;
          foreground = palette.joy;
          border = Border.all(color: palette.joy, width: 1.5);
      }
    }

    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(999),
            border: border,
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.label.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
