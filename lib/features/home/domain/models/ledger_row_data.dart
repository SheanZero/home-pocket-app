import 'dart:ui';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'ledger_row_data.freezed.dart';

@freezed
abstract class LedgerRowData with _$LedgerRowData {
  const factory LedgerRowData({
    required String tagText,
    required Color tagBgColor,
    required Color tagTextColor,
    required String title,
    required Color titleColor,
    required String subtitle,
    required String formattedAmount,
    required Color amountColor,
    required Color chevronColor,
    Color? borderColor,
  }) = _LedgerRowData;
}
