import 'dart:ui';

import '../../infrastructure/i18n/formatters/number_formatter.dart';
import 'currency_conversion.dart';

/// The formatted amounts a transaction row needs to render.
///
/// This deliberately accepts persisted primitive fields rather than a feature
/// transaction model so List, Analytics, and Home can share the same display
/// policy without coupling their presentation layers.
class TransactionDisplayAmounts {
  const TransactionDisplayAmounts({
    required this.primaryAmount,
    required this.foreignAnnotation,
  });

  /// The amount stored in the transaction's display currency.
  final String primaryAmount;

  /// The optional, pre-formatted original-currency value for foreign rows.
  final String? foreignAnnotation;
}

/// Formats the primary transaction amount and its optional foreign annotation.
///
/// A missing original amount or an original currency of JPY is a domestic row,
/// so [foreignAnnotation] is null. Foreign amounts are persisted in their
/// currency's minor units; whole values omit an all-zero fraction while real
/// fractions retain the precision set by [NumberFormatter].
TransactionDisplayAmounts formatTransactionDisplayAmounts({
  required int amountMinorUnits,
  required String amountCurrencyCode,
  required String? originalCurrencyCode,
  required int? originalAmountMinorUnits,
  required Locale locale,
}) {
  final foreignAnnotation =
      originalCurrencyCode != null &&
          originalCurrencyCode.toUpperCase() != 'JPY' &&
          originalAmountMinorUnits != null
      ? NumberFormatter.formatCurrency(
          originalAmountMinorUnits / subunitToUnitFor(originalCurrencyCode),
          originalCurrencyCode,
          locale,
          trimWholeFraction: true,
        )
      : null;

  return TransactionDisplayAmounts(
    primaryAmount: NumberFormatter.formatCurrency(
      amountMinorUnits,
      amountCurrencyCode,
      locale,
    ),
    foreignAnnotation: foreignAnnotation,
  );
}
